#!/usr/bin/env bash
#
# Baut die Mess-App, spielt sie auf ein angeschlossenes Android-Gerät und
# misst eine PDF-Datei damit.
#
# Gemessen wird dasselbe wie auf macOS: Seite rendern, erkennen lassen,
# Zeit und Speicher mitschreiben. Der Unterschied ist die Erkennung —
# hier ML Kit mit mitgeliefertem Modell, also ohne Netz und ohne
# Play-Dienste.
#
#   tool/ocr_probe/android/run.sh <datei.pdf> [Seiten] [dpi]
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE=de.status403.ocrprobe
readonly REMOTE=/sdcard/Download/ocr-probe.pdf

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

[ $# -ge 1 ] || { echo "Usage: $0 <datei.pdf> [Seiten] [dpi]" >&2; exit 1; }
readonly PDF="$1"
readonly PAGES="${2:-26}"
readonly DPI="${3:-200}"
[ -f "$PDF" ] || { echo "FEHLER: $PDF gibt es nicht" >&2; exit 1; }

command -v adb >/dev/null || { echo "FEHLER: adb nicht gefunden" >&2; exit 1; }
if [ -z "$(adb devices | sed '1d' | grep -w device || true)" ]; then
  echo "FEHLER: kein Android-Geraet angeschlossen." >&2
  echo "        USB-Debugging einschalten und den Rechner bestaetigen." >&2
  exit 1
fi

# Der Wrapper liegt nicht im Repository, genau wie beim Flutter-Projekt
# daneben, das ihn sich beim Bauen selbst holt. Von dort wird er geborgt.
if [ ! -x "$HERE/gradlew" ]; then
  readonly SOURCE="$HERE/../../../preppsuite_flutter/android"
  [ -x "$SOURCE/gradlew" ] || {
    echo "FEHLER: kein gradlew. Einmal 'flutter build apk' im Projekt laufen lassen." >&2
    exit 1
  }
  cp "$SOURCE/gradlew" "$HERE/gradlew"
  cp "$SOURCE/gradle/wrapper/gradle-wrapper.jar" "$HERE/gradle/wrapper/" 2>/dev/null || true
  chmod +x "$HERE/gradlew"
fi

echo "== bauen =="
"$HERE/gradlew" -p "$HERE" --no-daemon assembleRelease -q

echo "== aufspielen =="
adb install -r "$HERE/app/build/outputs/apk/release/app-release.apk" >/dev/null
adb push "$PDF" "$REMOTE" >/dev/null

echo "== messen: $PAGES Seiten bei $DPI dpi =="
adb shell am force-stop "$PACKAGE" >/dev/null
adb shell am start -n "$PACKAGE/.MeasureActivity" \
  -e pdf "$REMOTE" -e pages "$PAGES" -e dpi "$DPI" >/dev/null

# Die App schreibt Zeile für Zeile; gewartet wird auf die Schlusszeile,
# die als einzige `pss_peak_kb` traegt.
for _ in $(seq 1 120); do
  if adb shell run-as "$PACKAGE" cat files/ocr-probe.jsonl 2>/dev/null | grep -q pss_peak_kb; then
    break
  fi
  sleep 2
done

echo
adb shell run-as "$PACKAGE" cat files/ocr-probe.jsonl 2>/dev/null || {
  echo "Keine Ausgabe. Mit 'adb logcat -s ocr-probe' nachsehen." >&2
  exit 1
}
