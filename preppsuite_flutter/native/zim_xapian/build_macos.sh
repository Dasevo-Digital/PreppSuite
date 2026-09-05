#!/usr/bin/env bash
#
# Builds the Xapian shim for macOS, against whatever libxapian Homebrew
# has. That is deliberate for now: this is the proof that the approach
# works at all, not something shippable. A release build needs xapian-core
# compiled and linked statically — see docs/volltextsuche-xapian.md.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="$(command -v xapian-config || echo /opt/homebrew/opt/xapian/bin/xapian-config)"

if [ ! -x "$config" ]; then
  echo "xapian-config not found. brew install xapian" >&2
  exit 1
fi

mkdir -p "$here/build"
# shellcheck disable=SC2046  # both need to expand into separate arguments
clang++ -std=c++17 -O2 -fvisibility=hidden -dynamiclib \
  -Wall -Wextra \
  -o "$here/build/libzim_xapian.dylib" \
  "$here/zim_xapian.cpp" \
  $("$config" --cxxflags) $("$config" --libs)

echo "built $here/build/libzim_xapian.dylib"
