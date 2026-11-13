#!/usr/bin/env bash
#
# Builds the iPhone and iPad app of a release tag as an App Store archive
# and, with --upload, sends it to App Store Connect for TestFlight (#379).
#
# Until then every version reached the iPad and the other iPhone by cable,
# from a build signed for those devices alone. TestFlight lets them fetch
# each new one themselves, and a new device needs no new build.
#
# Built from the tag, in a worktree of its own, never from the checkout:
# what goes out is what was tagged, whatever else is lying about here. The
# translator goes in as in every device build (PREPPSUITE_REQUIRE_TRANSLATOR
# turns its absence into an error).
#
# Nothing of the account is in the repository. From the login keychain:
#   de.dasevo.preppsuite.team-id      the team id (or PREPPSUITE_TEAM_ID)
#   de.dasevo.preppsuite.asc-key-id   App Store Connect API key id
#   de.dasevo.preppsuite.asc-issuer   its issuer id
#   de.dasevo.preppsuite.asc-key      the .p8 key itself, base64-encoded
# Base64, because `security find-generic-password -w` hands back a secret
# with a line break in it as hex, and a .p8 file has several: stored as
# text, the key came back as a hex string xcodebuild cannot read. A key
# stored that way anyway is turned back from hex. It is written to a file
# only for the length of the run, readable by this user alone, and
# removed again however the run ends.
#
# Usage:
#   tool/ios_testflight.sh 3.0.1            # archive and check
#   tool/ios_testflight.sh 3.0.1 --upload   # and send it to TestFlight
#   TESTFLIGHT_REF=main tool/ios_testflight.sh 3.0.1
#       # a trial from another commit; never uploaded
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FEHLER: $*" >&2
  exit 1
}
step() { printf '\n== %s ==\n' "$1"; }

version="${1:-}"
upload=false
[ "${2:-}" = "--upload" ] && upload=true
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail "Version angeben, etwa 3.0.1"
tag="v$version"
ref="${TESTFLIGHT_REF:-$tag}"
if [ "$ref" = "$tag" ]; then
  git -C "$ROOT" rev-parse -q --verify "refs/tags/$tag" >/dev/null ||
    fail "Tag $tag fehlt"
else
  # What goes to testers is what was tagged, and nothing else.
  $upload && fail "hochgeladen wird nur der Tag $tag, nicht $ref"
  git -C "$ROOT" rev-parse -q --verify "$ref^{commit}" >/dev/null ||
    fail "$ref ist kein Commit"
fi
# The build number as release.sh takes it: from the pubspec of what is
# built, whose version has to be the one asked for. Not worked out from
# the version -- it was not always that, and App Store Connect refuses a
# number it has had before.
line="$(git -C "$ROOT" show "$ref:preppsuite_flutter/pubspec.yaml" |
  sed -n 's/^version:[[:space:]]*//p')"
[ "${line%%+*}" = "$version" ] || fail "pubspec.yaml von $ref sagt $line, nicht $version"
build="${line#*+}"
[[ "$build" =~ ^[0-9]+$ ]] || fail "ungültige Build-Nummer in pubspec.yaml von $ref"

secret() { security find-generic-password -s "$1" -w 2>/dev/null || true; }

# The API key as the .p8 text, from base64 or, stored straight from the
# file, from the hex `security -w` turns it into.
api_key() {
  local raw
  raw="$(secret de.dasevo.preppsuite.asc-key)"
  if [[ "$raw" =~ ^([0-9a-f][0-9a-f])+$ ]]; then
    printf '%s' "$raw" | xxd -r -p
  elif [[ "$raw" == -----BEGIN* ]]; then
    printf '%s\n' "$raw"
  elif [ -n "$raw" ]; then
    printf '%s' "$raw" | base64 -D
  fi
}

team="${PREPPSUITE_TEAM_ID:-$(secret de.dasevo.preppsuite.team-id)}"
[ -n "$team" ] || fail "Team-ID fehlt (Schlüsselbund de.dasevo.preppsuite.team-id oder PREPPSUITE_TEAM_ID)"

work="$(mktemp -d "${TMPDIR:-/tmp}/preppsuite-testflight.XXXXXX")"
cleanup() {
  git -C "$ROOT" worktree remove --force "$work/src" >/dev/null 2>&1 || true
  case "$work" in
    "${TMPDIR:-/tmp}"/preppsuite-testflight.*) rm -rf -- "$work" ;;
  esac
}
trap cleanup EXIT

auth=()
key_id="$(secret de.dasevo.preppsuite.asc-key-id)"
issuer="$(secret de.dasevo.preppsuite.asc-issuer)"
if [ -n "$key_id" ] && [ -n "$issuer" ]; then
  (
    umask 077
    api_key >"$work/AuthKey.p8"
  ) || fail "API-Schlüssel nicht lesbar (de.dasevo.preppsuite.asc-key)"
  [ -s "$work/AuthKey.p8" ] || fail "API-Schlüssel fehlt (de.dasevo.preppsuite.asc-key)"
  grep -q -- "-----BEGIN PRIVATE KEY-----" "$work/AuthKey.p8" ||
    fail "de.dasevo.preppsuite.asc-key ist kein .p8-Schlüssel (siehe docs/testflight.md)"
  auth=(
    -authenticationKeyPath "$work/AuthKey.p8"
    -authenticationKeyID "$key_id"
    -authenticationKeyIssuerID "$issuer"
  )
elif $upload; then
  fail "zum Hochladen fehlt der API-Schlüssel (de.dasevo.preppsuite.asc-key-id, -asc-issuer, -asc-key)"
fi

step "Quellen von $ref"
git -C "$ROOT" worktree add --detach "$work/src" "$ref" >/dev/null
app="$work/src/preppsuite_flutter"
# The translator's engine sources come along, so they are not fetched
# again: the checkout, the pinned PCRE2 tarball and the mark that both are
# ready. Not the build directories: the device one starts over anyway,
# since its stamp names this worktree's path, and copying all of them
# across volumes was 1.4 GB for nothing.
translate_build="$ROOT/preppsuite_flutter/native/translate/build"
if [ -d "$translate_build/translations" ]; then
  mkdir -p "$app/native/translate/build"
  for kept in "$translate_build"/translations "$translate_build"/pcre2-*.tar.gz \
    "$translate_build"/.source-ready-*; do
    [ -e "$kept" ] && cp -cR "$kept" "$app/native/translate/build/"
  done
fi

step "Übersetzer für iPhone und iPad"
"$app/native/translate/build_ios.sh" iphoneos >"$work/translate.log" 2>&1 ||
  { tail -20 "$work/translate.log"; fail "Übersetzer"; }

step "Flutter $version ($build)"
(cd "$app" && flutter pub get >/dev/null &&
  flutter build ios --release --config-only \
    --build-name "$version" --build-number "$build") >"$work/flutter.log" 2>&1 ||
  { tail -20 "$work/flutter.log"; fail "flutter build ios"; }

step "Archiv"
# Derived data inside the run's own folder: Xcode's default keeps the
# built app under ~/Library, where it outlives the run (see the cleanup).
archive="$work/PreppSuite.xcarchive"
(cd "$app/ios" && xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Release -destination generic/platform=iOS \
  -archivePath "$archive" -allowProvisioningUpdates \
  -derivedDataPath "$work/dd" \
  ${auth[@]+"${auth[@]}"} \
  DEVELOPMENT_TEAM="$team" PREPPSUITE_REQUIRE_TRANSLATOR=1 \
  archive) >"$work/archive.log" 2>&1 ||
  {
    grep -E "error:|BUILD FAILED|ARCHIVE FAILED" "$work/archive.log" | head -20 || true
    fail "xcodebuild archive"
  }

step "Prüfen"
bundle="$archive/Products/Applications/Runner.app"
[ -d "$bundle" ] || fail "kein Runner.app im Archiv"
plist() { /usr/libexec/PlistBuddy -c "Print $2" "$1/Info.plist"; }
[ "$(plist "$bundle" CFBundleShortVersionString)" = "$version" ] ||
  fail "Version im Archiv ist nicht $version"
[ "$(plist "$bundle" CFBundleVersion)" = "$build" ] ||
  fail "Build-Nummer im Archiv ist nicht $build"
[ -f "$bundle/Frameworks/preppsuite_translate.framework/preppsuite_translate" ] ||
  fail "Archiv ohne Übersetzer"
[ -f "$bundle/PrivacyInfo.xcprivacy" ] || fail "App ohne Privacy-Manifest"
widget="$bundle/PlugIns/PreppSuiteWidget.appex"
[ -f "$widget/PrivacyInfo.xcprivacy" ] || fail "Widget ohne Privacy-Manifest"
codesign -d --entitlements :- "$bundle" 2>/dev/null |
  grep -q usernotifications.time-sensitive ||
  fail "Archiv ohne Berechtigung für zeitkritische Mitteilungen"
echo "Version $version ($build), Übersetzer, Widget, Privacy-Manifeste, zeitkritische Mitteilungen: in Ordnung"

if ! $upload; then
  step "Fertig, nicht hochgeladen"
  if [ "$ref" = "$tag" ]; then
    echo "Hochladen mit: tool/ios_testflight.sh $version --upload"
  else
    echo "Probe von $ref; hochgeladen wird erst ein Tag mit diesem Stand."
  fi
  exit 0
fi

step "Hochladen zu App Store Connect"
cat >"$work/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>upload</string>
	<key>teamID</key>
	<string>$team</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
	<key>testFlightInternalTestingOnly</key>
	<true/>
</dict>
</plist>
PLIST
xcodebuild -exportArchive -archivePath "$archive" \
  -exportOptionsPlist "$work/ExportOptions.plist" \
  -exportPath "$work/export" -allowProvisioningUpdates \
  "${auth[@]}" >"$work/upload.log" 2>&1 ||
  {
    grep -E "error|Error|FAILED" "$work/upload.log" | head -20 || true
    fail "Hochladen"
  }
grep -E "Upload succeeded|EXPORT SUCCEEDED|Uploaded" "$work/upload.log" | tail -3 || true
step "Hochgeladen"
echo "$version ($build) erscheint nach Apples Verarbeitung in TestFlight."
