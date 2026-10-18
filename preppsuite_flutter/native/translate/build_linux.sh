#!/usr/bin/env bash
#
# Builds the translator shim for Linux, with the engine linked in
# statically (#184).
#
# On a Mac the engine multiplies floats with Accelerate; Linux has no
# such library everywhere, and a dependency on OpenBLAS would be one the
# tar.gz the app ships as cannot assume. So the float products go through
# Ruy, which the engine already brings for ARM and which also runs on
# x86, and the int8 products through intgemm as on an Intel Mac.
#
# Usage:
#   native/translate/build_linux.sh          # build what changed
#   native/translate/build_linux.sh --clean  # from scratch
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"
# shellcheck source=translate_source.sh
. "$HERE/translate_source.sh"

# CMake 4 refuses projects that ask for compatibility with anything older
# than 3.5, which PCRE2 and Ruy's cpuinfo still do.
export CMAKE_POLICY_VERSION_MINIMUM=3.5

[ "${1:-}" = "--clean" ] && rm -rf "$BUILD"
mkdir -p "$BUILD"

for tool in cmake ninja; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "FEHLER: $tool fehlt (sudo apt install cmake ninja-build)" >&2
    exit 1
  }
done

# Whichever compilers this machine has; the Flutter Linux toolchain
# brings clang and not necessarily g++.
CXX="${CXX:-}"
if [ -z "$CXX" ]; then
  for candidate in g++ clang++ c++; do
    if command -v "$candidate" >/dev/null 2>&1; then CXX="$candidate"; break; fi
  done
fi
[ -n "$CXX" ] || { echo "FEHLER: kein C++-Compiler gefunden" >&2; exit 1; }
CC="${CC:-}"
if [ -z "$CC" ]; then
  case "$CXX" in
    *clang++*) CC="${CXX%++}" ;;
    *g++*) CC="${CXX%++}cc" ;;
    *) CC=cc ;;
  esac
fi
echo "Compiler: $CXX / $CC"

engine="$(translate_source "$BUILD")"

arch="$(uname -m)"
out="$BUILD/linux-$arch"
mkdir -p "$out"
extra=()
case "$arch" in
  x86_64)
    # The baseline only has to run anywhere; intgemm picks the widest
    # instructions at run time.
    extra+=(-DBUILD_ARCH=x86-64-v2 -DUSE_RUY=ON -DUSE_RUY_SGEMM=ON)
    ;;
esac

if [ ! -f "$out/build.ninja" ]; then
  cmake -S "$HERE" -B "$out" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DBERGAMOT_SOURCE="$engine" \
    -DUSE_FBGEMM=OFF \
    -DUSE_MKL=OFF \
    -DSSPLIT_USE_INTERNAL_PCRE2=ON \
    ${extra[@]+"${extra[@]}"} >"$out/configure.log" 2>&1 ||
    { tail -30 "$out/configure.log"; exit 1; }
fi
ninja -C "$out" preppsuite_translate translate_selftest >"$out/build.log" 2>&1 ||
  { grep -E "error:|FAILED" "$out/build.log" | head -20; exit 1; }

cp "$out/libpreppsuite_translate.so" "$BUILD/libpreppsuite_translate.so"
strip --strip-unneeded "$BUILD/libpreppsuite_translate.so" 2>/dev/null || true
echo "== exportiert =="
nm -D --defined-only "$BUILD/libpreppsuite_translate.so" | awk '$2 == "T" {print $3}' | sort -u
echo "== hängt ab von =="
ldd "$BUILD/libpreppsuite_translate.so" | sed 's/ (0x[0-9a-f]*)//'
ls -l "$BUILD/libpreppsuite_translate.so"
