#!/usr/bin/env bash
#
# Signs a built macOS bundle with the hardened runtime switched on.
#
# Usage:
#   tool/macos_sign.sh <path to .app> [--entitlements <plist>]
#                                     [--identity <signing identity>]
#                                     [--allow-ad-hoc]
#
# Why at all: the Flutter build signs ad-hoc and WITHOUT the hardened
# runtime. Without it there is no library validation and no protection
# against DYLD_INSERT_LIBRARIES — and this app runs unsandboxed, so
# nothing else catches either.
#
# Signed inside out. Apple's `--deep` does that too but is explicitly no
# longer recommended: it gives every nested part the same entitlements as
# the app, which is wrong here — the entitlements belong on the outer
# bundle alone.
#
# The verification at the end is not ceremony. The hardened runtime turns
# on library validation, and from then on the app loads only libraries
# carrying the same signature as itself. With everything ad-hoc that works
# out — but "works out" is not evidence, so it is checked, and launching
# the app by hand still belongs after it.
set -uo pipefail

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; OFF=$'\033[0m'
heading() { printf '\n%s\n' "$1"; printf '%.0s─' $(seq 1 ${#1}); printf '\n'; }
bad()  { printf '  %s✗%s %s\n' "$RED" "$OFF" "$1"; }
good() { printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$1"; }
note() { printf '  %s•%s %s\n' "$YELLOW" "$OFF" "$1"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP=""
ENTITLEMENTS="$ROOT/preppsuite_flutter/macos/Runner/Release.entitlements"
IDENTITY=""
ALLOW_AD_HOC=false

while [ $# -gt 0 ]; do
  case "$1" in
    --entitlements) ENTITLEMENTS="$2"; shift 2 ;;
    --identity)     IDENTITY="$2"; shift 2 ;;
    --allow-ad-hoc) ALLOW_AD_HOC=true; shift ;;
    -*) printf '%sUnknown option: %s%s\n' "$RED" "$1" "$OFF"; exit 2 ;;
    *)  APP="$1"; shift ;;
  esac
done

[ -n "$APP" ] || { printf 'Usage: %s <path to .app> [--entitlements <plist>] [--identity <name>]\n' "$0"; exit 2; }
[ -d "$APP" ] || { bad "no bundle at $APP"; exit 1; }
[ -f "$ENTITLEMENTS" ] || { bad "no entitlements file at $ENTITLEMENTS"; exit 1; }
[ -n "$IDENTITY" ] || $ALLOW_AD_HOC || {
  bad "a distributable build requires --identity 'Developer ID Application: …'"
  note "For a local production/test installation only, pass --allow-ad-hoc explicitly."
  exit 2
}
[ -n "$IDENTITY" ] || IDENTITY="-"

heading "Starting point"
note "Bundle:       $APP"
note "Entitlements: ${ENTITLEMENTS#$ROOT/}"
note "Identity:     $([ "$IDENTITY" = "-" ] && echo "ad-hoc" || echo "$IDENTITY")"

# With an ad-hoc signature library validation MUST be off. It compares
# team identifiers, and an ad-hoc signature has none — every bundled
# framework would count as foreign and dyld would refuse to load it:
#   not valid for use in process: mapping process and mapped file
#   (non-platform) have different Team IDs
#
# What remains is the reason to do this at all: with the runtime hardened,
# DYLD_INSERT_LIBRARIES is ignored even without library validation.
#
# A real Developer ID removes the exception — then every part carries the
# same team identifier and validation holds. That is why this hangs off
# --identity instead of sitting in Release.entitlements.
if [ "$IDENTITY" = "-" ]; then
  RELAXED="$(mktemp -t preppsuite-entitlements).plist"
  cp "$ENTITLEMENTS" "$RELAXED"
  /usr/libexec/PlistBuddy -c \
    'Add :com.apple.security.cs.disable-library-validation bool true' \
    "$RELAXED" >/dev/null 2>&1
  ENTITLEMENTS="$RELAXED"
  trap 'rm -f "$RELAXED"' EXIT
  note "ad-hoc: library validation switched off (see comment in this script)"
fi

heading "Signing inside out"

sign() { # path [extra arguments]
  local target="$1"; shift
  # --timestamp=none because an ad-hoc signature gets no timestamp server
  # and the attempt only runs a minute into a timeout.
  local stamp=(--timestamp=none)
  [ "$IDENTITY" = "-" ] || stamp=(--timestamp)
  if codesign --force --options runtime "${stamp[@]}" \
       --sign "$IDENTITY" "$@" "$target" 2>/dev/null; then
    return 0
  fi
  bad "$(basename "$target")"
  return 1
}

count=0
failed=0

# Everything loose inside the frameworks first (dylibs, .so), then the
# framework bundles themselves. The other way round the bundle signature
# would be invalidated again the moment its contents changed.
while IFS= read -r file; do
  sign "$file" || failed=$((failed + 1))
  count=$((count + 1))
done < <(find "$APP/Contents/Frameworks" -type f \( -name '*.dylib' -o -name '*.so' \) 2>/dev/null)

while IFS= read -r framework; do
  sign "$framework" || failed=$((failed + 1))
  count=$((count + 1))
done < <(find "$APP/Contents/Frameworks" -maxdepth 1 -name '*.framework' 2>/dev/null)

# Helper executables next to the main one, if there are any.
executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist" 2>/dev/null)"
while IFS= read -r helper; do
  sign "$helper" || failed=$((failed + 1))
  count=$((count + 1))
done < <(find "$APP/Contents/MacOS" -type f -perm +111 2>/dev/null |
         grep -v "^$APP/Contents/MacOS/$executable$")

# The outer bundle last — the entitlements belong here and nowhere else.
sign "$APP" --entitlements "$ENTITLEMENTS" || failed=$((failed + 1))
count=$((count + 1))

if [ "$failed" -ne 0 ]; then
  bad "$failed of $count signatures failed"
  exit 1
fi
good "$count parts signed"

heading "Checking"

flags="$(codesign -dv "$APP" 2>&1 | grep '^CodeDirectory' | sed 's/.*flags=\([^ ]*\).*/\1/')"
if printf '%s' "$flags" | grep -q 'runtime'; then
  good "hardened runtime active ($flags)"
else
  bad "hardened runtime NOT active ($flags)"
  exit 1
fi

if codesign --verify --deep --strict "$APP" 2>/dev/null; then
  good "signature valid throughout (--deep --strict)"
else
  bad "signature not valid throughout:"
  codesign --verify --deep --strict "$APP" 2>&1 | sed 's/^/      /'
  exit 1
fi

# --verify --deep --strict is NOT enough on its own, which is the whole
# reason for this section: a framework loop that silently does not run
# leaves the frameworks with their old, still valid signatures — and the
# check passes. Valid is not the same as hardened. So look at each nested
# part separately.
unhardened=""
while IFS= read -r part; do
  f="$(codesign -dv "$part" 2>&1 | grep '^CodeDirectory' | sed 's/.*flags=\([^ ]*\).*/\1/')"
  printf '%s' "$f" | grep -q 'runtime' || \
    unhardened="$unhardened      $(basename "$part") ($f)"$'\n'
done < <(find "$APP/Contents/Frameworks" -maxdepth 1 -name '*.framework' 2>/dev/null)

if [ -z "$unhardened" ]; then
  good "every framework carries the hardened runtime"
else
  bad "these frameworks do NOT:"
  printf '%s' "$unhardened"
  exit 1
fi

# A signed bundle can still be an unusable one. zstandard_macos is meant to
# carry zstd compiled into it, and when CocoaPods collected its file list
# without the C sources present it produces a perfectly valid framework of
# 228 KB containing the Swift registrar and nothing else. Nothing fails at
# build, nothing fails at signing, nothing fails at launch — the app only
# says "a ZIM archive is expected" for every archive there is, because a ZIM
# keeps even its title in a compressed cluster. 1.7.0 and 1.7.1 shipped like
# that. Three symbols are what the reader actually calls.
zstd_lib="$APP/Contents/Frameworks/zstandard_macos.framework/Versions/A/zstandard_macos"
if [ ! -f "$zstd_lib" ]; then
  bad "zstandard_macos.framework is missing entirely"
  exit 1
fi
missing=""
for symbol in _ZSTD_decompress _ZSTD_compressBound _ZSTD_getFrameContentSize; do
  nm -gU "$zstd_lib" 2>/dev/null | grep -qE "[[:space:]]${symbol}$" || \
    missing="$missing $symbol"
done
if [ -z "$missing" ]; then
  good "zstd is compiled in ($(nm -gU "$zstd_lib" 2>/dev/null | grep -c 'ZSTD_') symbols)"
else
  bad "zstandard_macos carries no zstd —$missing"
  note "cd preppsuite_flutter/macos && pod install, then build again."
  exit 1
fi

# The entitlements have to be the same ones afterwards. A typo in the path
# would otherwise only surface when the app could no longer reach the
# user's folder.
heading "Entitlements in the finished bundle"
codesign -d --entitlements - --xml "$APP" 2>/dev/null | plutil -p - | sed 's/^/  /'

heading "Still to do by hand"
note "Launch it: open an article, load a map tile, scan a barcode."
note "Library validation only shows itself at load time, not here."
printf '\n'
