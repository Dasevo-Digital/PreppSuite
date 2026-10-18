#!/usr/bin/env bash
# Runs on the Linux build machine (#125). Called by tool/release.sh with the
# directory the source archive was unpacked into and the version.
#
# Builds the translator library for Linux, the app, and the Linux package;
# runs the start test; then cross-builds the translator DLL the Windows
# build needs, because the Windows machine has no MinGW. Ends with
# ALLES-FERTIG on its own line, which is what the caller waits for.
set -euo pipefail

work="$1"
version="$2"
build_number="$3"

export PATH="$HOME/flutter/bin:$PATH"
cd "$work/src/preppsuite_flutter"
# Before the app, or CMake has nothing to bundle; whether it arrived is
# checked by the caller in the package listing.
native/translate/build_linux.sh > "$work/translate-linux.log" 2>&1 ||
  { echo "UEBERSETZER-LINUX: FEHLGESCHLAGEN"; tail -n 20 "$work/translate-linux.log"; }
flutter pub get
flutter build linux --release --build-name "$version" --build-number "$build_number"

cd "$work"
rm -rf paket && mkdir -p paket/PreppSuite-x64
cp -a src/preppsuite_flutter/build/linux/x64/release/bundle paket/PreppSuite-x64/bundle
cd paket
tar czf "$work/PreppSuite-$version-linux-x64.tar.gz" PreppSuite-x64
# Listed into a file, not piped into head: under pipefail the early close
# of the pipe failed the script here and the Windows step below never ran.
tar tzf "$work/PreppSuite-$version-linux-x64.tar.gz" > "$work/inhalt.txt"

# The start test (#142): the package's native libraries, loaded for real
# in a running app. It needs a display; the build machine's own desktop
# session is used -- the user this runs as is signed in to it -- so no
# virtual one has to be installed. Without a session it is reported as
# not run, which the caller treats as a failure.
cd "$work/src/preppsuite_flutter"
runtime="/run/user/$(id -u)"
# The app reads the desktop keyring before its first frame (it takes over
# the former identity's entry), and a locked keyring answers with an
# unlock dialog on that desktop -- the test then hangs without a word.
# Said in the log, and waited for, so the caller can tell somebody.
keyring_locked() {
  busctl --user call org.freedesktop.secrets \
    /org/freedesktop/secrets/aliases/default \
    org.freedesktop.DBus.Properties Get ss \
    org.freedesktop.Secret.Collection Locked 2>/dev/null | grep -q true
}
if keyring_locked; then
  echo "SCHLUESSELBUND-GESPERRT: auf dem Desktop entsperren, der Starttest wartet"
  while keyring_locked; do sleep 30; done
  echo "Schlüsselbund entsperrt"
fi
if [ -S "$runtime/wayland-0" ]; then
  if XDG_RUNTIME_DIR="$runtime" WAYLAND_DISPLAY=wayland-0 \
    flutter test integration_test/app_start_test.dart -d linux \
    > "$work/starttest.log" 2>&1; then
    echo "STARTTEST: BESTANDEN"
  else
    echo "STARTTEST: FEHLGESCHLAGEN"
    tail -n 40 "$work/starttest.log"
  fi
else
  echo "STARTTEST: NICHT GELAUFEN (keine Desktop-Sitzung)"
fi

native/translate/build_windows.sh > "$work/translate-win.log" 2>&1 || true
echo ALLES-FERTIG
