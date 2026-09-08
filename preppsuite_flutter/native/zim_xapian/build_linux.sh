#!/usr/bin/env bash
#
# Builds the Xapian shim for Linux, statically linked against a
# xapian-core it compiles itself.
#
# Against the distribution's libxapian would be one apt line, but then the
# tar.gz the app ships as would have a dependency that most desktops do
# not have installed. Statically linked it carries what it needs, and the
# glibc it wants is the one of the machine that built the app anyway.
#
# Usage:
#   native/zim_xapian/build_linux.sh          # build if not already built
#   native/zim_xapian/build_linux.sh --clean  # from scratch
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"
# shellcheck source=xapian_source.sh
. "$HERE/xapian_source.sh"

[ "${1:-}" = "--clean" ] && rm -rf "$BUILD"
mkdir -p "$BUILD"

source_dir="$(xapian_source "$BUILD")"

readonly ARCH="$(uname -m)"
readonly PREFIX="$BUILD/xapian-linux-$ARCH"

# Whichever C++ compiler this machine has. The Flutter Linux toolchain
# brings clang and not necessarily g++, so preferring one and failing on
# its absence would refuse to build on a machine that can build the app.
CXX="${CXX:-}"
if [ -z "$CXX" ]; then
  for candidate in g++ c++ clang++; do
    if command -v "$candidate" >/dev/null 2>&1; then CXX="$candidate"; break; fi
  done
fi
[ -n "$CXX" ] || { echo "FEHLER: kein C++-Compiler gefunden" >&2; exit 1; }
readonly CXX
readonly CC="${CC:-cc}"
echo "Compiler: $CXX"

if [ ! -f "$PREFIX/lib/libxapian.a" ]; then
  echo "== xapian $ARCH bauen =="
  work="$BUILD/work-linux-$ARCH"
  rm -rf "$work"
  mkdir -p "$work"
  (
    cd "$work"
    # -fPIC because a static archive is about to be linked into a shared
    # object, which is the one thing a default static build cannot do.
    "$source_dir/configure" \
      --prefix="$PREFIX" \
      "${XAPIAN_FLAGS[@]}" \
      CXX="$CXX" \
      CXXFLAGS="-O2 -fPIC -fvisibility=hidden -fvisibility-inlines-hidden -D_FILE_OFFSET_BITS=64" \
      >"$work/configure.log" 2>&1 || { tail -30 "$work/configure.log"; exit 1; }
    make -j"$(nproc)" >"$work/make.log" 2>&1 \
      || { tail -30 "$work/make.log"; exit 1; }
    make install >>"$work/make.log" 2>&1
  )
fi

echo "== Schicht bauen =="
# --exclude-libs keeps xapian's own symbols out of the dynamic table, so
# the library's ABI is the header and nothing else. --no-undefined turns
# a missing library into a link error here rather than into a program
# that starts and then cannot open anything: -luuid was forgotten once,
# and a shared object happily keeps an undefined symbol.
"$CXX" -std=c++17 -O2 -fPIC \
  -fvisibility=hidden -fvisibility-inlines-hidden \
  -D_FILE_OFFSET_BITS=64 \
  -shared -Wall -Wextra \
  -Wl,-soname,libzim_xapian.so \
  -Wl,--exclude-libs,ALL \
  -Wl,--no-undefined \
  -Wl,--version-script="$HERE/zim_xapian.map" \
  -I"$PREFIX/include" \
  -o "$BUILD/libzim_xapian.so" \
  "$HERE/zim_xapian.cpp" \
  "$PREFIX/lib/libxapian.a" \
  -lz -luuid

echo "== Selbsttest bauen =="
"$CC" -O2 -Wall -Wextra -I"$HERE" \
  -o "$BUILD/selftest" "$HERE/selftest.c" \
  -L"$BUILD" -lzim_xapian -Wl,-rpath,'$ORIGIN'

echo
echo "== fertig =="
ls -lh "$BUILD/libzim_xapian.so" | awk '{print $5, $9}'
echo
echo "haengt an:"
ldd "$BUILD/libzim_xapian.so" | sed 's/^/ /'
echo
echo "gibt heraus:"
nm -D --defined-only "$BUILD/libzim_xapian.so" | awk '{print "  " $3}'
