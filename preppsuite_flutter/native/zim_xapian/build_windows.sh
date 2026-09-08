#!/usr/bin/env bash
#
# Builds the Xapian shim for Windows — from Linux, with mingw-w64.
#
# Not with MSVC, because xapian-core 1.4 no longer ships project files for
# it: the win32 directory is gone and building it that way would mean
# writing them. Its configure, on the other hand, handles mingw at a
# dozen places on purpose. Cross-building also puts the Windows library
# in the same place as the Linux one — one machine, one toolchain to keep.
#
# Ubuntu needs two packages:
#   sudo apt install mingw-w64 libz-mingw-w64-dev
#
# Usage:
#   native/zim_xapian/build_windows.sh          # build if not already built
#   native/zim_xapian/build_windows.sh --clean  # from scratch
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"
# shellcheck source=xapian_source.sh
. "$HERE/xapian_source.sh"

readonly HOST=x86_64-w64-mingw32

for tool in "$HOST-g++" "$HOST-gcc"; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "FEHLER: $tool fehlt. sudo apt install mingw-w64 libz-mingw-w64-dev" >&2
    exit 1
  }
done

[ "${1:-}" = "--clean" ] && rm -rf "$BUILD"
mkdir -p "$BUILD"

source_dir="$(xapian_source "$BUILD")"

readonly PREFIX="$BUILD/xapian-windows-x64"

if [ ! -f "$PREFIX/lib/libxapian.a" ]; then
  echo "== xapian fuer Windows bauen =="
  work="$BUILD/work-windows-x64"
  rm -rf "$work"
  mkdir -p "$work"
  (
    cd "$work"
    "$source_dir/configure" \
      --host="$HOST" \
      --prefix="$PREFIX" \
      "${XAPIAN_FLAGS[@]}" \
      CXXFLAGS="-O2 -fvisibility=hidden -fvisibility-inlines-hidden" \
      >"$work/configure.log" 2>&1 || { tail -40 "$work/configure.log"; exit 1; }
    make -j"$(nproc)" >"$work/make.log" 2>&1 \
      || { tail -40 "$work/make.log"; exit 1; }
    make install >>"$work/make.log" 2>&1
  )
fi

echo "== Schicht bauen =="
# What the extra libraries are for: ws2_32 gives htonl and friends,
# rpcrt4 gives UuidCreate, which is what xapian uses on Windows in place
# of libuuid. -static-lib* is what keeps the result from needing a GCC
# runtime that no Windows machine has.
"$HOST-g++" -std=c++17 -O2 \
  -shared -Wall -Wextra \
  -static-libgcc -static-libstdc++ \
  -Wl,--no-undefined \
  -I"$PREFIX/include" \
  -o "$BUILD/zim_xapian.dll" \
  "$HERE/zim_xapian.cpp" \
  "$PREFIX/lib/libxapian.a" \
  -l:libz.a \
  -lws2_32 -lrpcrt4

echo "== Selbsttest bauen =="
# Next to the DLL, because that is where Windows looks first.
"$HOST-gcc" -O2 -Wall -Wextra -I"$HERE" \
  -o "$BUILD/selftest.exe" "$HERE/selftest.c" \
  -L"$BUILD" -l:zim_xapian.dll \
  -static-libgcc

echo
echo "== fertig =="
ls -lh "$BUILD/zim_xapian.dll" | awk '{print $5, $9}'
echo
echo "haengt an:"
"$HOST-objdump" -p "$BUILD/zim_xapian.dll" \
  | awk '/DLL Name:/ {print "  " $3}'
echo
echo "gibt heraus:"
"$HOST-objdump" -p "$BUILD/zim_xapian.dll" \
  | awk '/Ordinal\/Name Pointer/ {listing = 1; next}
         listing && /^\t\[/ {print "  " $NF}
         listing && /^$/ {exit}'
