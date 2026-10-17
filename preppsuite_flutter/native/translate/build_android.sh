#!/usr/bin/env bash
#
# Builds the translator shim for Android with the NDK (#185), for
# arm64-v8a only.
#
# Not for armeabi-v7a: Marian's ARM kernels (simd_utils, sse2neon) use
# types and instructions only 64-bit ARM has -- float64x2_t, vfmaq_f32 --
# and the engine was written for AArch64. A 32-bit phone gets the APK
# without the translator, which says so; the phrasebook works there.
#
# On ARM the engine multiplies with Ruy -- int8 and float alike -- which
# is what Mozilla's ARM path was written for. The libraries land in
# build/android-jni/<abi>/, which the app's Gradle build adds to its
# native libraries when the folder is there; without it the APK has no
# translator and the screen says so.
#
# Usage:
#   native/translate/build_android.sh          # build what changed
#   native/translate/build_android.sh --clean  # from scratch
#
# The NDK is $ANDROID_NDK_HOME, or the version Flutter asks for under the
# Android SDK.
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"
# shellcheck source=translate_source.sh
. "$HERE/translate_source.sh"

export CMAKE_POLICY_VERSION_MINIMUM=3.5

# Android 9, not the app's minSdk of 24: Marian's path library calls
# iconv, nl_langinfo and glob, which Bionic has from API 28 (iconv, glob)
# and 26 (nl_langinfo). On Android 7 and 8 the library then fails to load,
# which the app reads as "not part of this build" -- the phrasebook still
# works there.
readonly API=28
readonly NDK_VERSION="28.2.13676358"

ndk="${ANDROID_NDK_HOME:-}"
if [ -z "$ndk" ]; then
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" \
    "$HOME/Library/Android/sdk" "/opt/homebrew/share/android-commandlinetools" \
    "$HOME/Android/Sdk"; do
    if [ -n "$sdk" ] && [ -d "$sdk/ndk/$NDK_VERSION" ]; then
      ndk="$sdk/ndk/$NDK_VERSION"
      break
    fi
  done
fi
[ -f "$ndk/build/cmake/android.toolchain.cmake" ] || {
  echo "FEHLER: NDK $NDK_VERSION nicht gefunden (ANDROID_NDK_HOME setzen)" >&2
  exit 1
}

if [ "${1:-}" = "--clean" ]; then
  rm -rf "$BUILD"
  shift
fi
mkdir -p "$BUILD"
abis=(arm64-v8a)

if ! command -v cmake >/dev/null || ! command -v ninja >/dev/null; then
  if [ ! -x "$BUILD/tools/bin/cmake" ]; then
    python3 -m venv "$BUILD/tools"
    "$BUILD/tools/bin/pip" install --quiet cmake==4.4.4 ninja==1.13.0
  fi
  export PATH="$BUILD/tools/bin:$PATH"
fi

engine="$(translate_source "$BUILD")"

for abi in "${abis[@]}"; do
  out="$BUILD/android-$abi"
  echo "== $abi =="
  mkdir -p "$out"
  # Marian's default is "native", which probes the machine doing the
  # building -- a Mac -- and passes its SSE flags to the ARM compiler.
  case "$abi" in
    arm64-v8a) arch="armv8-a" ;;
    *) echo "FEHLER: unbekannte ABI $abi" >&2; exit 1 ;;
  esac
  if [ ! -f "$out/build.ninja" ]; then
    cmake -S "$HERE" -B "$out" -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" \
      -DBUILD_ARCH="$arch" \
      -DANDROID_ABI="$abi" \
      -DANDROID_PLATFORM="android-$API" \
      -DANDROID_STL=c++_static \
      -DBERGAMOT_SOURCE="$engine" \
      -DUSE_FBGEMM=OFF \
      -DUSE_MKL=OFF \
      -DSSPLIT_USE_INTERNAL_PCRE2=ON >"$out/configure.log" 2>&1 ||
      { tail -30 "$out/configure.log"; exit 1; }
  fi
  ninja -C "$out" preppsuite_translate >"$out/build.log" 2>&1 ||
    { grep -E "error:|FAILED" "$out/build.log" | head -20; exit 1; }
  mkdir -p "$BUILD/android-jni/$abi"
  "$ndk/toolchains/llvm/prebuilt/"*/bin/llvm-strip --strip-unneeded \
    -o "$BUILD/android-jni/$abi/libpreppsuite_translate.so" \
    "$out/libpreppsuite_translate.so"
  ls -l "$BUILD/android-jni/$abi/libpreppsuite_translate.so"
done
