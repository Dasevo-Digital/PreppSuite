#!/usr/bin/env bash
#
# Builds the translator shim for Windows -- from Linux, with mingw-w64
# (#184).
#
# The posix flavour of the compiler, because the engine uses std::thread
# and std::mutex, which the win32 flavour of mingw's libstdc++ does not
# provide. Everything is linked statically, winpthread included, so the
# DLL needs nothing beside it that a Windows machine does not have. The
# float products go through Ruy and the int8 products through intgemm,
# as on Linux.
#
# Ubuntu needs: sudo apt install mingw-w64 cmake ninja-build
#
# Usage:
#   native/translate/build_windows.sh          # build what changed
#   native/translate/build_windows.sh --clean  # from scratch
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"
# shellcheck source=translate_source.sh
. "$HERE/translate_source.sh"

readonly HOST=x86_64-w64-mingw32
export CMAKE_POLICY_VERSION_MINIMUM=3.5

for tool in "$HOST-g++-posix" "$HOST-gcc-posix" cmake ninja; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "FEHLER: $tool fehlt. sudo apt install mingw-w64 cmake ninja-build" >&2
    exit 1
  }
done

[ "${1:-}" = "--clean" ] && rm -rf "$BUILD"
mkdir -p "$BUILD"

engine="$(translate_source "$BUILD")"

out="$BUILD/windows-x64"
mkdir -p "$out"
if [ ! -f "$out/build.ninja" ]; then
  # A toolchain file rather than flags: the engine builds PCRE2 as an
  # external project, which only the toolchain file reaches.
  cat >"$out/toolchain.cmake" <<TOOLCHAIN
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_COMPILER $HOST-gcc-posix)
set(CMAKE_CXX_COMPILER $HOST-g++-posix)
set(CMAKE_RC_COMPILER $HOST-windres)
set(CMAKE_FIND_ROOT_PATH /usr/$HOST)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-static -static-libgcc -static-libstdc++ -Wl,--no-undefined")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static -static-libgcc -static-libstdc++")
TOOLCHAIN
  cmake -S "$HERE" -B "$out" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$out/toolchain.cmake" \
    -DBERGAMOT_SOURCE="$engine" \
    -DBUILD_ARCH=x86-64-v2 \
    -DUSE_RUY=ON \
    -DUSE_RUY_SGEMM=ON \
    -DUSE_FBGEMM=OFF \
    -DUSE_MKL=OFF \
    -DSSPLIT_USE_INTERNAL_PCRE2=ON >"$out/configure.log" 2>&1 ||
    { tail -30 "$out/configure.log"; exit 1; }
fi
ninja -C "$out" preppsuite_translate translate_selftest >"$out/build.log" 2>&1 ||
  { grep -E "error:|FAILED|undefined reference" "$out/build.log" | head -20; exit 1; }

cp "$out/preppsuite_translate.dll" "$BUILD/preppsuite_translate.dll"
"$HOST-strip" --strip-unneeded "$BUILD/preppsuite_translate.dll" 2>/dev/null || true
echo "== exportiert =="
"$HOST-objdump" -p "$BUILD/preppsuite_translate.dll" | sed -n '/\[Ordinal\/Name Pointer\] Table/,/^$/p'
echo "== hängt ab von =="
"$HOST-objdump" -p "$BUILD/preppsuite_translate.dll" | grep "DLL Name"
ls -l "$BUILD/preppsuite_translate.dll"
