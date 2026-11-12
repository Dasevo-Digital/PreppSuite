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
#   de.dasevo.preppsuite.asc-key      the .p8 key itself, as text
# The key is written to a file only for the length of the run, readable by
# this user alone, and removed again however the run ends.
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
[[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] ||
  fail "Version angeben, etwa 3.0.1"
# The build number of every package (release.sh): 3.0.1 is 301.
build=$((BASH_REMATCH[1] * 100 + BASH_REMATCH[2] * 10 + BASH_REMATCH[3]))
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

secret() { security find-generic-password -s "$1" -w 2>/dev/null || true; }

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
    secret de.dasevo.preppsuite.asc-key >"$work/AuthKey.p8"
  )
  [ -s "$work/AuthKey.p8" ] || fail "API-Schlüssel fehlt (de.dasevo.preppsuite.asc-key)"
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
# The translator's build directory comes along as a clone, so its engine
# sources and toolchain are not fetched again; build_ios.sh starts the
# device directory over itself where its settings differ.
if [ -d "$ROOT/preppsuite_flutter/native/translate/build" ]; then
  cp -cR "$ROOT/preppsuite_flutter/native/translate/build" \
    "$app/native/translate/build"
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
  { grep -E "error:|BUILD FAILED|ARCHIVE FAILED" "$work/archive.log" | head -20; fail "xcodebuild archive"; }

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
  { grep -E "error|Error|FAILED" "$work/upload.log" | head -20; fail "Hochladen"; }
grep -E "Upload succeeded|EXPORT SUCCEEDED|Uploaded" "$work/upload.log" | tail -3
step "Hochgeladen"
echo "$version ($build) erscheint nach Apples Verarbeitung in TestFlight."
