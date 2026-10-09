#!/usr/bin/env bash
# Runs on the Linux build machine (#125). Called by tool/release.sh with the
# directory the source archive was unpacked into and the version.
#
# Builds the Xapian library for Linux, the app, and the Linux package; runs
# the start test; then cross-builds the Xapian DLL the Windows build needs, because the Windows
# machine has no MinGW. Ends with ALLES-FERTIG on its own line, which is
# what the caller waits for.
set -euo pipefail

work="$1"
version="$2"
build_number="$3"

export PATH="$HOME/flutter/bin:$PATH"
cd "$work/src/preppsuite_flutter"
native/zim_xapian/build_linux.sh
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

native/zim_xapian/build_windows.sh > "$work/xapian-win.log" 2>&1 || true
echo ALLES-FERTIG
