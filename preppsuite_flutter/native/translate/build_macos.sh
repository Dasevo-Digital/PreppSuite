#!/usr/bin/env bash
#
# Builds the translator shim for macOS as a universal library that
# depends on nothing but the system (#182).
#
# The engine is compiled from source and linked in statically: the
# library goes inside the app bundle and has to carry what it needs. Each architecture is its own build, because they do not
# share code paths -- arm64 multiplies with Ruy and Accelerate, x86_64
# with intgemm -- and lipo joins them.
#
# CMake and Ninja come from the PATH, or, where there are none, from a
# Python environment inside build/ with pinned versions; nothing is
# installed into the system.
#
# Usage:
#   native/translate/build_macos.sh          # build what changed
#   native/translate/build_macos.sh --clean  # from scratch
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"
# shellcheck source=translate_source.sh
. "$HERE/translate_source.sh"

# Matches the Runner's own target.
export MACOSX_DEPLOYMENT_TARGET=12.0
# CMake 4 refuses projects that ask for compatibility with anything older
# than 3.5, which PCRE2 and Ruy's cpuinfo still do. Through the
# environment, so that the external projects the engine starts see it too.
export CMAKE_POLICY_VERSION_MINIMUM=3.5

[ "${1:-}" = "--clean" ] && rm -rf "$BUILD"
mkdir -p "$BUILD"

if ! command -v cmake >/dev/null || ! command -v ninja >/dev/null; then
  if [ ! -x "$BUILD/tools/bin/cmake" ]; then
    python3 -m venv "$BUILD/tools"
    "$BUILD/tools/bin/pip" install --quiet cmake==4.4.4 ninja==1.13.0
  fi
  export PATH="$BUILD/tools/bin:$PATH"
fi

engine="$(translate_source "$BUILD")"

for arch in arm64 x86_64; do
  out="$BUILD/macos-$arch"
  echo "== $arch =="
  # A toolchain file rather than flags alone: the engine builds PCRE2 as
  # an external project, which only the toolchain file reaches.
  toolchain="set(CMAKE_OSX_ARCHITECTURES $arch CACHE STRING \"\")
set(CMAKE_OSX_DEPLOYMENT_TARGET $MACOSX_DEPLOYMENT_TARGET)
set(CMAKE_SYSTEM_PROCESSOR $arch)"
  # A fixed CPU baseline for both (#375). Marian's default is "native",
  # which asks the compiler about the machine doing the building: on the
  # M5 this is built on, Apple clang made that apple-m1 plus v8.7, i8mm
  # and bf16 -- instructions an M1 does not have. None was in the library
  # yet, but a newer compiler vectorising a loop with one of them would
  # have crashed the translator on every M1 with SIGILL, and
  # nothing here would have noticed. armv8.4-a is what every Apple silicon
  # Mac runs, dot product included; Ruy still picks its kernels at run
  # time. Intel Macs without AVX2 still exist; intgemm picks the widest
  # instructions at run time, so that baseline only has to run anywhere.
  case "$arch" in
    arm64) cpu=armv8.4-a ;;
    x86_64) cpu=x86-64-v2 ;;
  esac
  configure=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_TOOLCHAIN_FILE="$out/toolchain.cmake"
    -DCMAKE_OSX_ARCHITECTURES="$arch"
    -DBUILD_ARCH="$cpu"
    -DBERGAMOT_SOURCE="$engine"
    -DUSE_FBGEMM=OFF
    -DSSPLIT_USE_INTERNAL_PCRE2=ON
  )
  # Configured once; Ninja then rebuilds only what changed, so a run after
  # an edit to the shim takes seconds and a run with nothing changed none.
  # A directory configured with other settings -- an SDK an Xcode update
  # renamed, or the baseline above -- starts over, as on iOS (#378):
  # Ninja never reconfigures on its own, and the new baseline would
  # otherwise only have reached a clean checkout.
  stamp="$(xcrun --sdk macosx --show-sdk-path)
$(xcrun --sdk macosx --show-sdk-version)
$toolchain
${configure[*]}"
  if [ -f "$out/build.ninja" ] && [ "$(cat "$out/.configured" 2>/dev/null)" != "$stamp" ]; then
    echo "  neu konfigurieren: SDK oder Einstellungen geändert"
    rm -rf "$out"
  fi
  mkdir -p "$out"
  if [ ! -f "$out/build.ninja" ]; then
    printf '%s\n' "$toolchain" >"$out/toolchain.cmake"
    cmake -S "$HERE" -B "$out" -G Ninja "${configure[@]}" >"$out/configure.log" 2>&1 ||
      { tail -30 "$out/configure.log"; exit 1; }
    printf '%s' "$stamp" >"$out/.configured"
  fi
  ninja -C "$out" preppsuite_translate translate_selftest >"$out/build.log" 2>&1 ||
    { grep -E "error:|FAILED" "$out/build.log" | head -20; exit 1; }
done

lipo -create \
  "$BUILD/macos-arm64/libpreppsuite_translate.dylib" \
  "$BUILD/macos-x86_64/libpreppsuite_translate.dylib" \
  -output "$BUILD/libpreppsuite_translate.dylib"
install_name_tool -id @rpath/libpreppsuite_translate.dylib \
  "$BUILD/libpreppsuite_translate.dylib"
lipo -info "$BUILD/libpreppsuite_translate.dylib"
# The baseline holds only if nothing beyond it is in the library: an
# intrinsic or a flag in the engine could still bring one in (#375).
"$HERE/check_arm64_baseline.sh" "$BUILD/libpreppsuite_translate.dylib"
echo "== exportiert =="
nm -gU "$BUILD/libpreppsuite_translate.dylib" | grep " T " | awk '{print $3}' | sort -u
echo "== hängt ab von =="
otool -L "$BUILD/libpreppsuite_translate.dylib" | tail -n +2
