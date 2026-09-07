#!/usr/bin/env bash
#
# Builds the Xapian shim for macOS as a universal library that depends on
# nothing but the system.
#
# xapian-core is compiled from source and linked in statically. Linking
# against Homebrew's copy would be a great deal less work and would run
# only on a machine that has Homebrew, with the same Xapian, in the same
# place — which is to say it would run here and nowhere else. The library
# ends up inside the app bundle, so it has to carry what it needs.
#
# Both architectures, because the app ships universal and a bundle whose
# main binary is universal and whose library is not simply fails to load
# on the other kind of machine.
#
# Usage:
#   native/zim_xapian/build_macos.sh          # build if not already built
#   native/zim_xapian/build_macos.sh --clean  # from scratch
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD="$HERE/build"

# 1.4 is the stable series and the one that writes and reads glass, the
# format Kiwix's indexes are in. 2.x still reads glass but is a
# development series; there is nothing here that wants it.
readonly XAPIAN_VERSION=1.4.32
readonly XAPIAN_SHA256=c4fd64e81127311756adf5579268d14a79f285ce8ac4ead0930c96195897aece
# Upstream's own host was unreachable from here; Debian's pool carries the
# unmodified upstream tarball, and the checksum above is the one its
# signed .dsc lists.
readonly XAPIAN_URL="http://deb.debian.org/debian/pool/main/x/xapian-core/xapian-core_${XAPIAN_VERSION}.orig.tar.xz"

# Matches the Runner's own target. A library built for something newer
# would load on this machine and refuse on an older one.
export MACOSX_DEPLOYMENT_TARGET=10.15

[ "${1:-}" = "--clean" ] && rm -rf "$BUILD"
mkdir -p "$BUILD/vendor"

tarball="$BUILD/vendor/xapian-core-$XAPIAN_VERSION.tar.xz"
source_dir="$BUILD/vendor/xapian-core-$XAPIAN_VERSION"

if [ ! -d "$source_dir" ]; then
  if [ ! -f "$tarball" ]; then
    echo "== xapian-core $XAPIAN_VERSION laden =="
    curl -fsSL --retry 3 -o "$tarball.part" "$XAPIAN_URL"
    mv "$tarball.part" "$tarball"
  fi

  # Checked before unpacking, not after: a tarball is a list of paths to
  # write, and this one is fetched over plain HTTP from a mirror.
  actual="$(shasum -a 256 "$tarball" | cut -d' ' -f1)"
  if [ "$actual" != "$XAPIAN_SHA256" ]; then
    echo "FEHLER: Pruefsumme passt nicht" >&2
    echo "  erwartet: $XAPIAN_SHA256" >&2
    echo "  bekommen: $actual" >&2
    exit 1
  fi

  echo "== auspacken =="
  tar -xJf "$tarball" -C "$BUILD/vendor"
fi

# One prefix per architecture, because the two static libraries cannot
# share a directory and configure writes a config header per build.
for arch in arm64 x86_64; do
  prefix="$BUILD/xapian-$arch"
  if [ -f "$prefix/lib/libxapian.a" ]; then
    echo "== xapian $arch liegt schon =="
    continue
  fi

  echo "== xapian $arch bauen =="
  work="$BUILD/work-$arch"
  rm -rf "$work"
  mkdir -p "$work"
  (
    cd "$work"
    # --host makes this a cross build for the architecture that is not
    # this machine's, which is what stops configure from trying to run
    # what it just compiled.
    "$source_dir/configure" \
      --host="$arch-apple-darwin" \
      --prefix="$prefix" \
      --enable-static --disable-shared \
      --disable-documentation \
      --disable-backend-inmemory --disable-backend-remote \
      CC="clang -arch $arch" \
      CXX="clang++ -arch $arch" \
      CXXFLAGS="-O2 -fvisibility=hidden -fvisibility-inlines-hidden" \
      >"$work/configure.log" 2>&1 || { tail -30 "$work/configure.log"; exit 1; }
    make -j"$(sysctl -n hw.ncpu)" >"$work/make.log" 2>&1 \
      || { tail -30 "$work/make.log"; exit 1; }
    make install >>"$work/make.log" 2>&1
  )
done

# The shim itself, once per architecture, then joined.
for arch in arm64 x86_64; do
  prefix="$BUILD/xapian-$arch"
  echo "== Schicht $arch bauen =="
  clang++ -std=c++17 -O2 -arch "$arch" \
    -fvisibility=hidden -fvisibility-inlines-hidden \
    -dynamiclib -Wall -Wextra \
    -install_name '@rpath/libzim_xapian.dylib' \
    -I"$prefix/include" \
    -o "$BUILD/libzim_xapian-$arch.dylib" \
    "$HERE/zim_xapian.cpp" \
    "$prefix/lib/libxapian.a" \
    -lz
done

lipo -create \
  "$BUILD/libzim_xapian-arm64.dylib" \
  "$BUILD/libzim_xapian-x86_64.dylib" \
  -output "$BUILD/libzim_xapian.dylib"

echo
echo "== fertig =="
lipo -info "$BUILD/libzim_xapian.dylib"
ls -lh "$BUILD/libzim_xapian.dylib" | awk '{print $5, $9}'

# Anything beyond the system here would be a library that is not in the
# app bundle, which is the one mistake this script exists to prevent.
echo
echo "haengt an:"
otool -L "$BUILD/libzim_xapian.dylib" | tail -n +2 | sed 's/^/ /'
