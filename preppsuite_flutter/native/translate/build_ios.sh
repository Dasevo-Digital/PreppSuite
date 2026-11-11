#!/usr/bin/env bash
#
# Builds the translator shim for iPhone and iPad (#374): one framework for
# the devices and one for the simulator, each arm64 only.
#
# The engine is the one the Mac gets, linked in statically the same way,
# and multiplies the way it does on Apple silicon there: Ruy for int8,
# Accelerate for float. What differs is the CPU baseline. The Mac build
# leaves Marian at "native", which asks the compiler about the machine
# doing the building; for a phone that is the wrong machine, so this pins
# armv8-a, as the Android build does. Ruy picks its dot-product kernels
# at run time where the chip has them.
#
# iOS loads code only from signed frameworks inside the app, not from a
# loose library, so each build is wrapped as
# build/ios/<sdk>/preppsuite_translate.framework. The Runner's "Embed
# Translator" phase copies the one for the SDK it builds for and signs it;
# without it the app builds, runs, and the screen says the translator is
# not part of this build.
#
# The simulator framework is arm64 too: that is what the simulator runs
# on Apple silicon, and an Intel simulator only goes without.
#
# Usage:
#   native/translate/build_ios.sh                  # both, what changed
#   native/translate/build_ios.sh iphonesimulator  # only the simulator
#   native/translate/build_ios.sh --clean          # from scratch
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"
# shellcheck source=translate_source.sh
. "$HERE/translate_source.sh"

# Matches the Runner's own target and the Podfile.
readonly IOS_TARGET=15.0
export CMAKE_POLICY_VERSION_MINIMUM=3.5

if [ "${1:-}" = "--clean" ]; then
  rm -rf "$BUILD"
  shift
fi
sdks=("$@")
[ ${#sdks[@]} -eq 0 ] && sdks=(iphoneos iphonesimulator)
for sdk in "${sdks[@]}"; do
  case "$sdk" in
    iphoneos | iphonesimulator) ;;
    *) echo "FEHLER: unbekanntes SDK $sdk (iphoneos oder iphonesimulator)" >&2; exit 1 ;;
  esac
done
mkdir -p "$BUILD"

if ! command -v cmake >/dev/null || ! command -v ninja >/dev/null; then
  if [ ! -x "$BUILD/tools/bin/cmake" ]; then
    python3 -m venv "$BUILD/tools"
    "$BUILD/tools/bin/pip" install --quiet cmake==4.4.4 ninja==1.13.0
  fi
  export PATH="$BUILD/tools/bin:$PATH"
fi

engine="$(translate_source "$BUILD")"

for sdk in "${sdks[@]}"; do
  out="$BUILD/ios-$sdk"
  echo "== $sdk =="
  mkdir -p "$out"
  if [ ! -f "$out/build.ninja" ]; then
    # A toolchain file, as on the Mac: PCRE2 is built as an external
    # project, which only the toolchain file reaches. CMake makes every
    # executable an app bundle on iOS, and SentencePiece's command-line
    # tools then have nowhere to be installed to; none of them is built.
    #
    # And no JIT for the sentence splitter's regular expressions: an iOS
    # app may not write code into memory and run it, and PCRE2's JIT needs
    # __clear_cache, which iOS does not link. The splitter asks PCRE2
    # whether it has one and matches without it otherwise. Forced, because
    # the engine passes -DPCRE2_SUPPORT_JIT=ON to PCRE2's build and this
    # file is read after that, at its project().
    cat >"$out/toolchain.cmake" <<TOOLCHAIN
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_OSX_SYSROOT $sdk)
set(CMAKE_OSX_ARCHITECTURES arm64 CACHE STRING "")
set(CMAKE_OSX_DEPLOYMENT_TARGET $IOS_TARGET)
set(CMAKE_SYSTEM_PROCESSOR arm64)
set(CMAKE_MACOSX_BUNDLE OFF)
set(PCRE2_SUPPORT_JIT OFF CACHE BOOL "" FORCE)
TOOLCHAIN
    cmake -S "$HERE" -B "$out" -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE="$out/toolchain.cmake" \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DBUILD_ARCH=armv8-a \
      -DBERGAMOT_SOURCE="$engine" \
      -DUSE_FBGEMM=OFF \
      -DUSE_MKL=OFF \
      -DSSPLIT_USE_INTERNAL_PCRE2=ON >"$out/configure.log" 2>&1 ||
      { tail -30 "$out/configure.log"; exit 1; }
  fi
  ninja -C "$out" preppsuite_translate >"$out/build.log" 2>&1 ||
    { grep -E "error:|FAILED" "$out/build.log" | head -20; exit 1; }

  framework="$BUILD/ios/$sdk/preppsuite_translate.framework"
  rm -rf "$framework"
  mkdir -p "$framework"
  # Local symbols out; the six exported functions stay.
  strip -x -o "$framework/preppsuite_translate" "$out/libpreppsuite_translate.dylib"
  install_name_tool -id @rpath/preppsuite_translate.framework/preppsuite_translate \
    "$framework/preppsuite_translate" 2>/dev/null
  case "$sdk" in
    iphoneos) platform=iPhoneOS ;;
    iphonesimulator) platform=iPhoneSimulator ;;
  esac
  cat >"$framework/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>preppsuite_translate</string>
	<key>CFBundleIdentifier</key>
	<string>de.dasevo.preppsuite.translate</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>preppsuite_translate</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>$platform</string>
	</array>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>MinimumOSVersion</key>
	<string>$IOS_TARGET</string>
</dict>
</plist>
PLIST
  plutil -lint "$framework/Info.plist" >/dev/null

  echo "== $sdk: gebaut für =="
  vtool -show-build "$framework/preppsuite_translate" | grep -E "platform|minos"
  ls -l "$framework/preppsuite_translate"
  echo "== $sdk: exportiert =="
  nm -gU "$framework/preppsuite_translate" | grep " T " | awk '{print $3}' | sort -u
  echo "== $sdk: hängt ab von =="
  otool -L "$framework/preppsuite_translate" | tail -n +2
done
