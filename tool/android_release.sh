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
AAPT2="${AAPT2:-/opt/homebrew/share/android-commandlinetools/build-tools/36.0.0/aapt2}"
DEBUG_KEYSTORE="${DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
export JAVA_HOME

die() { echo "FEHLER: $*" >&2; exit 1; }

[ -x "$APKSIGNER" ] || die "apksigner nicht unter $APKSIGNER — Pfad ueber APKSIGNER setzen."
[ -x "$AAPT2" ] || die "aapt2 nicht unter $AAPT2 — Pfad ueber AAPT2 setzen."
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

readonly OUT_DIR="$APP_DIR/build/app/outputs/flutter-apk"

# One package per architecture instead of one holding both.
#
# A universal APK was 64.7 MB, of which 60.2 MB was native code for two
# architectures -- so every phone downloaded and installed roughly 29 MB it
# can never execute. Split and measured: arm64 35.9 MB, arm32 32.9 MB, so
# 45 percent off for anybody with a phone from the last several years.
#
# The cost is a question the user now has to answer, and the answer is
# "arm64" for every phone made in the last several years. The release notes
# say so; arm32 is there for the handful of older ones minSdk 24 still
# admits. x86 and x86_64 stay out either way: they are the emulator and
# reach no device this app is handed to.
readonly ABIS=(arm64-v8a armeabi-v7a)
readonly TARGET_PLATFORMS=android-arm64,android-arm

# Generated, git-ignored, and poison if it is stale.
#
# `flutter test integration_test/` writes this file with the
# integration_test plugin registered in it, because for that run the plugin
# has to be. It stays behind in the source tree afterwards, and the next
# release build compiles it against a classpath that has no
# integration_test -- so the build dies on "Package
# dev.flutter.plugins.integration_test ist nicht vorhanden", pointing at a
# file nobody wrote and nobody tracks.
#
# The build regenerates it correctly when it is absent, so removing it
# costs nothing. Whoever runs the integration tests should not have to
# remember this.
readonly STALE_REGISTRANT="$ANDROID_DIR/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
if [ -f "$STALE_REGISTRANT" ]; then
  echo "== 0/5 erzeugten Plugin-Registrant entfernen =="
  rm -f "$STALE_REGISTRANT"
fi

echo "== 1/5 bauen =="
( cd "$APP_DIR" && flutter build apk --release --split-per-abi \
    --target-platform "$TARGET_PLATFORMS" )

for abi in "${ABIS[@]}"; do
  [ -s "$OUT_DIR/app-$abi-release.apk" ] \
    || die "Gradle hat kein APK fuer $abi abgelegt."
done

verify_at() {
  "$APKSIGNER" verify --print-certs --min-sdk-version "$2" \
    --max-sdk-version "$3" "$1"
}

# Every package goes through the same signing and the same four proofs.
# A loop rather than a copy: two packages checked by two blocks of script
# is how one of them quietly stops being checked.
for abi in "${ABIS[@]}"; do
  built="$OUT_DIR/app-$abi-release.apk"
  signed="$OUT_DIR/app-$abi-release-rotated.apk"

  echo "== 2/5 $abi mit Lineage neu signieren =="
  rm -f "$signed"
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
    --out "$signed" "$built"
  [ -s "$signed" ] || die "apksigner hat fuer $abi nichts abgelegt."

  echo "== 3/5 $abi signatur pruefen =="
  # It has to verify at all, over the whole range the app claims to support.
  "$APKSIGNER" verify --min-sdk-version 24 "$signed" \
    || die "$abi verifiziert nicht ueber die ganze unterstuetzte Spanne."

  # Android 7-12: the old certificate has to be the one in force, and the
  # new one must not appear at all — if it did, every existing install
  # would be locked out of the update on those versions.
  old_out="$(verify_at "$signed" 24 32)"
  grep -qi "SHA-256 digest: $DEBUG_SHA256" <<<"$old_out" \
    || { echo "$old_out"; die "$abi API 24-32 traegt nicht das Debug-Zertifikat."; }
  if grep -qi "SHA-256 digest: $RELEASE_SHA256" <<<"$old_out"; then
    echo "$old_out"; die "$abi API 24-32 traegt bereits das neue Zertifikat."
  fi

  # Android 13+: the rotated certificate is in force from here on.
  new_out="$(verify_at "$signed" 33 36)"
  grep -qi "minSdkVersion=33.*SHA-256 digest: $RELEASE_SHA256" <<<"$new_out" \
    || { echo "$new_out"; die "$abi API 33+ traegt nicht das PreppSuite-Zertifikat."; }

  # And the proof-of-rotation has to have survived into the APK itself.
  lineage_out="$("$APKSIGNER" lineage --print-certs --in "$signed")"
  grep -qi "$DEBUG_SHA256" <<<"$lineage_out" && grep -qi "$RELEASE_SHA256" <<<"$lineage_out" \
    || { echo "$lineage_out"; die "In $abi steckt keine vollstaendige Lineage."; }
  grep -qi "Has installed data capability: true" <<<"$lineage_out" \
    || die "$abi: der alte Signierer darf keine bestehende Installation abloesen."

  echo "== 4/5 $abi architekturen pruefen =="
  # Exactly its own, and nothing else. A split package that quietly
  # carried both would put the 29 MB straight back, and one carrying the
  # wrong one would install and then not start.
  abis_in="$(unzip -Z1 "$signed" 'lib/*' | cut -d/ -f2 | sort -u | tr '\n' ' ')"
  echo "   enthalten: $abis_in"
  [ "$abis_in" = "$abi " ] \
    || die "$abi-Paket enthaelt >$abis_in< statt nur $abi."

  echo "== 4b/5 $abi versionscode pruefen =="
  # --split-per-abi does not leave versionCode alone: Flutter adds 1000 per
  # architecture, so pubspec's +22 ships as 1022 for armeabi-v7a and 2022
  # for arm64-v8a. That is what makes both installable over the universal
  # 22 that is out there -- and it is a one-way door. A later universal
  # build would carry a plain 23, which every phone now on 2022 refuses as
  # a downgrade, and the only way out for the user is uninstalling and
  # losing their data.
  #
  # So the offset is asserted rather than assumed: whoever drops
  # --split-per-abi finds out here instead of finding out from the people
  # whose update stopped arriving.
  code="$("$AAPT2" dump badging "$signed" \
    | sed -n "s/^package:.*versionCode='\([0-9]*\)'.*/\1/p")"
  echo "   versionCode: $code"
  case "$abi" in
    arm64-v8a)   expected_prefix=2 ;;
    armeabi-v7a) expected_prefix=1 ;;
    *)           die "unbekannte Architektur $abi" ;;
  esac
  [ -n "$code" ] || die "$abi: versionCode nicht auslesbar."
  [ "$code" -gt 1000 ] \
    || die "$abi: versionCode $code ohne ABI-Offset -- wurde --split-per-abi entfernt? Siehe Kommentar."
  [ "${code:0:1}" = "$expected_prefix" ] \
    || die "$abi: versionCode $code passt nicht zum erwarteten Offset ${expected_prefix}000."

  echo "== 5/5 $abi fertig =="
  echo "API 24-32:"; grep -i "certificate DN:\|certificate SHA-256 digest:" <<<"$old_out" | sed 's/^/  /'
  echo "API 33+:"
  grep -i "minSdkVersion=33.*certificate DN:\|minSdkVersion=33.*certificate SHA-256 digest:" <<<"$new_out" | sed 's/^/  /'
  echo
  ls -la "$signed"
  echo
done
