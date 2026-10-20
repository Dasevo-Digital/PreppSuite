#!/usr/bin/env bash
#
# Starts a release APK once on the project's own emulator and checks that
# it gets past loading the household (#206).
#
#   tool/android_start_check.sh <apk>
#
# Why a start and not a test: only a release build is shrunk by R8, and
# what R8 breaks shows nowhere else. 2.6.0 and 2.6.1 opened on "the
# household cannot be loaded" because R8 had removed the Kotlin classes
# shared_preferences_android 2.5 looks up over JNI; every test and every
# debug build was fine. The app catches that failure and says so on the
# screen, so the log stays clean -- the screen is what is read, through
# the accessibility tree, in every language the app has.
#
# The emulator is the AVD preppsuite_test on port 5584. One that is not
# running is started here, headless, and stopped again afterwards; one
# that is running is left as it is. Never a phone: the serial has to be an
# emulator's. The app is uninstalled before and after, so it starts like a
# first install and no versionCode stands in the way.
#
#   PREPPSUITE_ANDROID_EMULATOR  serial (default emulator-5584)
#   PREPPSUITE_ANDROID_AVD       AVD to start (default preppsuite_test)
set -euo pipefail

apk="${1:?Aufruf: tool/android_start_check.sh <apk>}"
[ -s "$apk" ] || { echo "FEHLER: $apk fehlt" >&2; exit 1; }

SDK="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
ADB="$SDK/platform-tools/adb"
EMULATOR="$SDK/emulator/emulator"
serial="${PREPPSUITE_ANDROID_EMULATOR:-emulator-5584}"
avd="${PREPPSUITE_ANDROID_AVD:-preppsuite_test}"
readonly package=de.dasevo.preppsuite

die() { echo "FEHLER: $*" >&2; exit 1; }
adb() { "$ADB" -s "$serial" "$@"; }

[[ "$serial" =~ ^emulator-([0-9]+)$ ]] || die "$serial ist kein Emulator"
port="${BASH_REMATCH[1]}"

started=""
cleanup() {
  adb uninstall "$package" > /dev/null 2>&1 || true
  if [ -n "$started" ]; then
    adb emu kill > /dev/null 2>&1 || kill "$started" 2> /dev/null || true
  fi
}
trap cleanup EXIT

if [ "$(adb get-state 2> /dev/null)" != device ]; then
  "$EMULATOR" -avd "$avd" -no-window -no-audio -no-snapshot -no-boot-anim \
    -gpu swiftshader_indirect -port "$port" > /dev/null 2>&1 &
  started=$!
  adb wait-for-device
fi
for _ in $(seq 1 90); do
  [ "$(adb shell getprop sys.boot_completed 2> /dev/null | tr -d '\r')" = 1 ] && break
  sleep 2
done
[ "$(adb shell getprop sys.boot_completed 2> /dev/null | tr -d '\r')" = 1 ] ||
  die "$serial bootet nicht"

adb uninstall "$package" > /dev/null 2>&1 || true
adb install "$apk" > /dev/null || die "Installation auf $serial"
adb shell am start -W -n "$package/.MainActivity" > /dev/null

# A first install ends on the setup screen; a household that cannot be
# loaded ends on its own error screen. Either is there within a minute.
readonly reached='Haushalt einrichten|Set up a household|Configurar un hogar'
readonly failed='Der Haushalt lässt sich gerade nicht laden|The household cannot be loaded right now|El hogar no se puede cargar ahora'
for _ in $(seq 1 30); do
  sleep 3
  [ -n "$(adb shell pidof "$package" | tr -d '\r')" ] ||
    die "das Paket ist nach dem Start nicht mehr da (abgestürzt)"
  adb shell uiautomator dump /sdcard/preppsuite-start.xml > /dev/null 2>&1 || continue
  screen="$(adb shell cat /sdcard/preppsuite-start.xml 2> /dev/null || true)"
  if grep -qE "$failed" <<< "$screen"; then
    die "das Paket öffnet auf „Der Haushalt lässt sich gerade nicht laden“"
  fi
  if grep -qE "$reached" <<< "$screen"; then
    echo "Start auf $serial: Einrichtung erreicht"
    exit 0
  fi
done
die "nach 90 s weder Einrichtung noch Fehlermeldung auf dem Bildschirm"
