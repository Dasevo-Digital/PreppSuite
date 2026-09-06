#!/usr/bin/env bash
#
# Builds the distributable Android package.
#
# `flutter build apk --release` on its own is NOT enough. The Android Gradle
# Plugin can sign with the release key, but it cannot attach a
# SigningCertificateLineage — and without that proof-of-rotation Android
# refuses to update the 0.8.0-0.10.0 installs that carry the debug key. This
# script builds, re-signs with the lineage, and then proves both regimes:
#
#   Android 7-12 (API 24-32) -> debug certificate
#   Android 13+  (API 33+)   -> PreppSuite certificate, accepted over an
#                               existing debug-key install via the lineage
#
# The cut is at 33 and not at 28 because apksigner puts a rotation into a v3.1
# block by default, which only Android 13 reads. Android 9 through 12 can be
# reached with --rotation-min-sdk-version 28, but their v3 rotation handling is
# what v3.1 exists to work around, and a broken install on a sideloaded app has
# no recourse. Left at the safe default on purpose; see README.
#
# It refuses to leave an APK behind that fails either check. Distributing an
# unrotated one is not a cosmetic mistake: it bricks the update path silently,
# and the only way out for the user is uninstalling and losing their data.
set -euo pipefail

readonly DEBUG_SHA256=697fe6d2a7617f7464f498636338b71364d9ff403a173e4ff0dc51626982c8cd
readonly RELEASE_SHA256=386ee032a1135ce9ea8065a8e702dc9826cb2e6060dd07fd0c6599569d3c1ffe

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP_DIR="$REPO_ROOT/preppsuite_flutter"
readonly ANDROID_DIR="$APP_DIR/android"
readonly LINEAGE="$ANDROID_DIR/signing-lineage.bin"
readonly KEY_PROPERTIES="$ANDROID_DIR/key.properties"

# Overridable so this is not welded to one machine.
JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21}"
APKSIGNER="${APKSIGNER:-/opt/homebrew/share/android-commandlinetools/build-tools/36.0.0/apksigner}"
DEBUG_KEYSTORE="${DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
export JAVA_HOME

die() { echo "FEHLER: $*" >&2; exit 1; }

[ -x "$APKSIGNER" ] || die "apksigner nicht unter $APKSIGNER — Pfad ueber APKSIGNER setzen."
[ -x "$JAVA_HOME/bin/java" ] || die "kein JDK unter $JAVA_HOME — Pfad ueber JAVA_HOME setzen."
[ -s "$LINEAGE" ] || die "Lineage fehlt: $LINEAGE"
[ -s "$KEY_PROPERTIES" ] || die "key.properties fehlt: $KEY_PROPERTIES"
# The debug key is not a leftover here, it is the first link of the lineage:
# without it there is no v2 signature that Android 7 and 8 will accept.
[ -s "$DEBUG_KEYSTORE" ] || die "Debug-Keystore fehlt: $DEBUG_KEYSTORE"

prop() { grep "^$1=" "$KEY_PROPERTIES" | cut -d= -f2-; }
readonly STORE_FILE="$(prop storeFile)"
readonly STORE_PASSWORD="$(prop storePassword)"
readonly KEY_ALIAS="$(prop keyAlias)"
[ -n "$STORE_FILE" ] && [ -n "$STORE_PASSWORD" ] && [ -n "$KEY_ALIAS" ] \
  || die "key.properties unvollstaendig."
[ -s "$STORE_FILE" ] || die "Keystore fehlt: $STORE_FILE"

readonly BUILT="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
readonly SIGNED="$APP_DIR/build/app/outputs/flutter-apk/app-release-rotated.apk"

# arm64 is every Android phone made in the last several years, arm32 the
# handful of older ones minSdk 24 still admits. x86 and x86_64 are the
# emulator: they were a third of a 96.7 MB package and reach no real device
# this app is handed to.
readonly TARGET_PLATFORMS=android-arm,android-arm64

echo "== 1/5 bauen =="
( cd "$APP_DIR" && flutter build apk --release \
    --target-platform "$TARGET_PLATFORMS" )
[ -s "$BUILT" ] || die "Gradle hat kein APK abgelegt: $BUILT"

echo "== 2/5 mit Lineage neu signieren =="
rm -f "$SIGNED"
"$APKSIGNER" sign \
  --lineage "$LINEAGE" \
  --ks "$DEBUG_KEYSTORE" --ks-key-alias androiddebugkey \
  --ks-pass pass:android --key-pass pass:android \
  --next-signer --ks "$STORE_FILE" --ks-key-alias "$KEY_ALIAS" \
  --ks-pass "pass:$STORE_PASSWORD" --key-pass "pass:$STORE_PASSWORD" \
  --v1-signing-enabled false \
  --v2-signing-enabled true \
  --v3-signing-enabled true \
  --v4-signing-enabled false \
  --out "$SIGNED" "$BUILT"
[ -s "$SIGNED" ] || die "apksigner hat nichts abgelegt."

echo "== 3/5 signatur pruefen =="
verify_at() {
  "$APKSIGNER" verify --print-certs --min-sdk-version "$1" --max-sdk-version "$2" "$SIGNED"
}

# It has to verify at all, over the whole range the app claims to support.
"$APKSIGNER" verify --min-sdk-version 24 "$SIGNED" \
  || die "Das Paket verifiziert nicht ueber die ganze unterstuetzte Spanne."

# Android 7-12: the old certificate has to be the one in force, and the new one
# must not appear at all — if it did, every existing install would be locked
# out of the update on those versions.
old_out="$(verify_at 24 32)"
grep -qi "SHA-256 digest: $DEBUG_SHA256" <<<"$old_out" \
  || { echo "$old_out"; die "API 24-32 traegt nicht das Debug-Zertifikat."; }
if grep -qi "SHA-256 digest: $RELEASE_SHA256" <<<"$old_out"; then
  echo "$old_out"; die "API 24-32 traegt bereits das neue Zertifikat."
fi

# Android 13+: the rotated certificate is in force from here on.
new_out="$(verify_at 33 36)"
grep -qi "minSdkVersion=33.*SHA-256 digest: $RELEASE_SHA256" <<<"$new_out" \
  || { echo "$new_out"; die "API 33+ traegt nicht das PreppSuite-Zertifikat."; }

# And the proof-of-rotation has to have survived into the APK itself.
lineage_out="$("$APKSIGNER" lineage --print-certs --in "$SIGNED")"
grep -qi "$DEBUG_SHA256" <<<"$lineage_out" && grep -qi "$RELEASE_SHA256" <<<"$lineage_out" \
  || { echo "$lineage_out"; die "Im APK steckt keine vollstaendige Lineage."; }
grep -qi "Has installed data capability: true" <<<"$lineage_out" \
  || die "Der alte Signierer darf keine bestehende Installation abloesen."

echo "== 4/5 architekturen pruefen =="
# A silent return of the emulator architectures would put 32 MB back into a
# package nobody can check by looking at it.
abis="$(unzip -Z1 "$SIGNED" 'lib/*' | cut -d/ -f2 | sort -u | tr '\n' ' ')"
echo "   enthalten: $abis"
case "$abis" in
  *x86*) die "Das Paket enthaelt wieder eine x86-Architektur: $abis" ;;
esac
grep -q "arm64-v8a" <<<"$abis" || die "arm64-v8a fehlt im Paket."

echo "== 5/5 fertig =="
echo
echo "API 24-32:"; grep -i "certificate DN:\|certificate SHA-256 digest:" <<<"$old_out" | sed 's/^/  /'
echo "API 33+:"
grep -i "minSdkVersion=33.*certificate DN:\|minSdkVersion=33.*certificate SHA-256 digest:" <<<"$new_out" | sed 's/^/  /'
echo
ls -la "$SIGNED"
