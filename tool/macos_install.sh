#!/usr/bin/env bash
#
# Installs the two macOS apps this machine is supposed to have, and only
# those two:
#
#   /Applications/PreppSuite.app        the one that holds the real household
#   /Applications/PreppSuite Test.app   the same build under its own bundle
#                                       identifier, so trying something out
#                                       cannot touch the real data
#
# Both come from the same build. The test one differs in exactly two
# fields — its identifier and its name — which is enough for macOS to give
# it a database, a preferences file and a shared folder of its own.
#
# It also takes the app out of the build directory afterwards. A .app
# sitting in `build/` is indexed by Spotlight like any other, and a menu
# offering three PreppSuites, two of which are staging copies, is worse
# than useless when somebody is looking for the one with their inventory
# in it.
#
# Usage:
#   tool/macos_install.sh                        # the last build
#   tool/macos_install.sh path/to/PreppSuite.app
#   tool/macos_install.sh path/to/PreppSuite-x.y.z-macos-universal.zip
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BUILD_APP="$REPO_ROOT/preppsuite_flutter/build/macos/Build/Products/Release/PreppSuite.app"

readonly PROD_APP="/Applications/PreppSuite.app"
readonly TEST_APP="/Applications/PreppSuite Test.app"
readonly TEST_ID="de.status403.preppsuite.test"
readonly TEST_NAME="PreppSuite Test"

die() { echo "FEHLER: $*" >&2; exit 1; }

source="${1:-$BUILD_APP}"
[ -e "$source" ] || die "nichts unter $source"

workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT

# A zip is unpacked; anything else has to be a bundle already.
if [[ "$source" == *.zip ]]; then
  echo "== Paket auspacken =="
  ditto -x -k "$source" "$workspace/unpacked"
  source="$(find "$workspace/unpacked" -maxdepth 2 -name '*.app' -type d | head -1)"
  [ -n "$source" ] || die "im Paket ist kein .app-Bündel"
fi
[ -d "$source/Contents/MacOS" ] || die "$source ist kein App-Bündel"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$source/Contents/Info.plist")"
echo "Quelle: $source (Fassung $version)"

# Replacing a running app leaves the running one on a deleted bundle,
# which is how you get a version number that lies.
for id in de.status403.preppsuite "$TEST_ID"; do
  osascript -e "quit app id \"$id\"" >/dev/null 2>&1 || true
done

echo "== $PROD_APP =="
rm -rf "$PROD_APP"
ditto "$source" "$PROD_APP"

echo "== $TEST_APP =="
# The entitlements have to be carried over by hand: re-signing without
# them would silently drop the camera, the location and the file access,
# and the test app would fail at exactly the features worth testing.
entitlements="$workspace/entitlements.plist"
codesign -d --entitlements :- "$source" 2>/dev/null > "$entitlements" \
  || die "die Berechtigungen des Bündels sind nicht lesbar"

rm -rf "$TEST_APP"
ditto "$source" "$TEST_APP"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $TEST_ID" \
  "$TEST_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $TEST_NAME" \
  "$TEST_APP/Contents/Info.plist"

# Editing Info.plist invalidates the signature, and macOS kills a bundle
# whose signature does not match rather than explaining itself. Ad-hoc,
# like the build itself: there is no Developer ID here.
codesign --force --deep --sign - --entitlements "$entitlements" \
  "$TEST_APP" >/dev/null 2>&1 || die "das Test-Bündel liess sich nicht signieren"
codesign --verify --deep --strict "$TEST_APP" \
  || die "die Signatur des Test-Bündels hält nicht"

# Nothing should be left where Spotlight would offer it as a third app.
if [ -d "$BUILD_APP" ] && [ "$BUILD_APP" != "$source" ]; then
  rm -rf "$BUILD_APP"
elif [ -d "$BUILD_APP" ]; then
  rm -rf "$BUILD_APP"
fi

echo
echo "== installiert =="
for app in "$PROD_APP" "$TEST_APP"; do
  printf '%-34s %-30s %s\n' \
    "$(basename "$app")" \
    "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" \
    "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
done
