# The xapian-core source, once, for every platform's build script.
#
# Sourced, not run. It exists so that the version and its checksum live in
# one file: three scripts pinning the same tarball separately is three
# chances to pin different ones.

# 1.4 is the stable series and the one that writes and reads glass, the
# format Kiwix's indexes are in. 2.x still reads glass but is a
# development series; there is nothing here that wants it.
XAPIAN_VERSION=1.4.32
XAPIAN_SHA256=c4fd64e81127311756adf5579268d14a79f285ce8ac4ead0930c96195897aece
# Upstream's own host was unreachable from here; Debian's pool carries the
# unmodified upstream tarball, and the checksum above is the one its
# signed .dsc lists.
XAPIAN_URL="http://deb.debian.org/debian/pool/main/x/xapian-core/xapian-core_${XAPIAN_VERSION}.orig.tar.xz"

# What every platform builds: static, no documentation, and only the
# backends a ZIM index can be in. Chert stays because archives from
# before 2017 are in it.
XAPIAN_FLAGS=(
  --enable-static --disable-shared
  --disable-documentation
  --disable-backend-inmemory --disable-backend-remote
)

# Unpacks the source under <build dir>/vendor and echoes where it went.
xapian_source() {
  local build="$1"
  local tarball="$build/vendor/xapian-core-$XAPIAN_VERSION.tar.xz"
  local source_dir="$build/vendor/xapian-core-$XAPIAN_VERSION"

  if [ -d "$source_dir" ]; then
    echo "$source_dir"
    return 0
  fi

  mkdir -p "$build/vendor"
  if [ ! -f "$tarball" ]; then
    echo "== xapian-core $XAPIAN_VERSION laden ==" >&2
    curl -fsSL --retry 3 -o "$tarball.part" "$XAPIAN_URL"
    mv "$tarball.part" "$tarball"
  fi

  # Checked before unpacking, not after: a tarball is a list of paths to
  # write, and this one comes over plain HTTP from a mirror.
  local actual
  actual="$(sha256_of "$tarball")"
  if [ "$actual" != "$XAPIAN_SHA256" ]; then
    echo "FEHLER: Pruefsumme passt nicht" >&2
    echo "  erwartet: $XAPIAN_SHA256" >&2
    echo "  bekommen: $actual" >&2
    return 1
  fi

  echo "== auspacken ==" >&2
  tar -xJf "$tarball" -C "$build/vendor"
  echo "$source_dir"
}

# macOS has shasum, Linux has both but sha256sum everywhere.
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}
