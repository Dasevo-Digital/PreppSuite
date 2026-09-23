#!/usr/bin/env bash
# Builds a distributable macOS release. It intentionally has no ad-hoc path:
# a package intended for another machine needs a Developer ID signature and a
# notarization ticket, otherwise Gatekeeper has no trustworthy provenance.
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP_DIR="$ROOT/preppsuite_flutter"
readonly APP="$APP_DIR/build/macos/Build/Products/Release/PreppSuite.app"

identity=""
profile=""
while [ $# -gt 0 ]; do
  case "$1" in
    --identity) identity="$2"; shift 2 ;;
    --notary-profile) profile="$2"; shift 2 ;;
    *) echo "Usage: $0 --identity <Developer-ID> --notary-profile <keychain-profile>" >&2; exit 2 ;;
  esac
done

[ -n "$identity" ] || { echo "FEHLER: Developer-ID fehlt." >&2; exit 2; }
[ -n "$profile" ] || { echo "FEHLER: Notarytool-Keychain-Profil fehlt." >&2; exit 2; }
command -v xcrun >/dev/null || { echo "FEHLER: Xcode command line tools fehlen." >&2; exit 1; }

version_line="$(sed -n 's/^version:[[:space:]]*//p' "$APP_DIR/pubspec.yaml" | head -1)"
version_name="${version_line%%+*}"
version_code="${version_line#*+}"
[ -n "$version_name" ] && [ "$version_code" != "$version_line" ] && \
  [[ "$version_code" =~ ^[0-9]+$ ]] || { echo "FEHLER: ungueltige Version in $APP_DIR/pubspec.yaml" >&2; exit 1; }

cd "$ROOT"
flutter build macos --release --build-name "$version_name" --build-number "$version_code"
"$ROOT/tool/macos_sign.sh" "$APP" --identity "$identity"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
out="$ROOT/releases/PreppSuite-$version-macos-universal.zip"
mkdir -p "$(dirname "$out")"
rm -f "$out"
ditto -c -k --keepParent "$APP" "$out"
xcrun notarytool submit "$out" --keychain-profile "$profile" --wait
xcrun stapler staple "$APP"
spctl --assess --type execute --verbose=4 "$APP"

# Stapling changes the bundle, so package it only after the ticket has landed.
rm -f "$out"
ditto -c -k --keepParent "$APP" "$out"
shasum -a 256 "$out" > "$out.sha256"
echo "Fertig: $out"
