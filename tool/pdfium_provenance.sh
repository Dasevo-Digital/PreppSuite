#!/usr/bin/env bash
#
# Checks that the PDFium inside a built package is the one upstream signed.
#
# PDFium is the only foreign binary that walks into a PreppSuite package
# without being built here: it is fetched over the network while the app
# compiles, and nothing on that path verifies it. The sqlite3mc asset next
# to it is signed and says so in the root pubspec; this one was not
# checked at all.
#
# What this compares against lives in tool/pdfium_provenance.txt, and what
# is written there was taken from the SLSA provenance attestation GitHub
# signs for the upstream release -- not from a download somebody happened
# to make.
#
# Usage:
#   tool/pdfium_provenance.sh <paket> [<paket> ...]
#   tool/pdfium_provenance.sh --help
#
# Understood packages: a .app bundle, a macOS .zip, a Linux .tar.gz, a
# Windows .zip and an .apk. Anything else is refused rather than passed.
set -uo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TABLE="$ROOT/tool/pdfium_provenance.txt"

usage() {
  cat <<'TEXT'
tool/pdfium_provenance.sh <paket> [<paket> ...]

Prueft die PDFium-Bibliothek in einem gebauten Paket gegen die Werte in
tool/pdfium_provenance.txt.

Die Tabelle nach einem Wechsel von pdfium_dart neu erzeugen:

  1. Fassung ablesen:
     grep _pdfiumRelease ~/.pub-cache/hosted/pub.dev/pdfium_dart-*/hook/build.dart
  2. Attestation dieser Fassung holen:
     curl -sL -o att.json \
       "https://github.com/bblanchon/pdfium-binaries/releases/download/<release>/pdfium-attestation.json"
  3. Digests entnehmen -- die Nutzlast ist base64 im dsseEnvelope:
     python3 -c "import json,base64;d=json.load(open('att.json'));\
p=json.loads(base64.b64decode(d['dsseEnvelope']['payload']));\
print('\n'.join(f\"{s['name']} {s['digest']['sha256']}\" for s in p['subject']))"
  4. Jedes Archiv laden, gegen den Digest pruefen, die Bibliothek daraus
     hashen (macOS: dwarfdump --uuid statt Hash) und hier eintragen.

Ein Archiv, das nicht zur Attestation passt, gehoert nicht ins Paket --
und nicht in diese Tabelle.
TEXT
}

case "${1:-}" in
  ''|--help|-h) usage; [ -z "${1:-}" ] && exit 2 || exit 0 ;;
esac

[ -r "$TABLE" ] || { echo "FEHLER: $TABLE fehlt." >&2; exit 1; }

# The table is read once into two maps: hashes for the platforms whose
# library is copied verbatim, UUIDs for macOS where signing rewrites it.
declare -a LIB_NAMES LIB_HASHES UUID_ARCHES UUID_VALUES
while IFS=$'\t' read -r kind platform archive archive_sha fifth sixth; do
  case "$kind" in
    lib)  LIB_NAMES+=("$platform");  LIB_HASHES+=("$sixth") ;;
    uuid) UUID_ARCHES+=("$fifth");   UUID_VALUES+=("$sixth") ;;
  esac
done < <(grep -v '^#' "$TABLE" | grep -v '^[[:space:]]*$')

readonly RELEASE="$(awk '/^release\t/ {print $2}' "$TABLE")"
[ -n "$RELEASE" ] || { echo "FEHLER: keine Release-Zeile in $TABLE." >&2; exit 1; }

hash_for() {
  local want="$1" i
  for i in "${!LIB_NAMES[@]}"; do
    [ "${LIB_NAMES[$i]}" = "$want" ] && { printf '%s' "${LIB_HASHES[$i]}"; return 0; }
  done
  return 1
}

sha256() { shasum -a 256 "$1" | cut -d' ' -f1; }

fail=0
report() { echo "  $1"; }
bad() { report "$1"; fail=1; }

# Compares one extracted library against the table.
check_library() {
  local file="$1" platform="$2"
  local want got
  want="$(hash_for "$platform")" || { bad "keine Zeile fuer $platform in der Tabelle"; return; }
  got="$(sha256 "$file")"
  if [ "$got" = "$want" ]; then
    report "$platform: PDFium stimmt mit der Attestation ueberein"
  else
    bad "$platform: PDFium WEICHT AB"
    bad "  erwartet $want"
    bad "  gefunden $got"
  fi
}

# macOS only: the framework is ad-hoc signed during the build, so its bytes
# cannot match upstream. A Mach-O UUID survives signing, and the framework
# is universal, so both slices are checked and both have to be there.
check_macos_framework() {
  local binary="$1" out i arch want
  command -v dwarfdump >/dev/null || { bad "macOS: dwarfdump fehlt"; return; }
  out="$(dwarfdump --uuid "$binary" 2>/dev/null)"
  for i in "${!UUID_ARCHES[@]}"; do
    arch="${UUID_ARCHES[$i]}"
    want="${UUID_VALUES[$i]}"
    if grep -q "UUID: $want ($arch)" <<<"$out"; then
      report "macOS/$arch: PDFium stimmt mit der Attestation ueberein"
    else
      bad "macOS/$arch: erwartete UUID $want nicht gefunden"
    fi
  done
}

workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT

check_package() {
  local package="$1"
  echo "== $(basename "$package") =="
  [ -e "$package" ] || { bad "nicht gefunden"; return; }

  local room; room="$(mktemp -d "$workspace/XXXXXX")"

  case "$package" in
    *.app)
      check_macos_framework "$package/Contents/Frameworks/PDFium.framework/Versions/A/PDFium"
      ;;
    *macos*.zip)
      ditto -x -k "$package" "$room" || { bad "liess sich nicht auspacken"; return; }
      local app; app="$(find "$room" -maxdepth 2 -name '*.app' -type d | head -1)"
      [ -n "$app" ] || { bad "kein .app im Paket"; return; }
      check_macos_framework "$app/Contents/Frameworks/PDFium.framework/Versions/A/PDFium"
      ;;
    *linux*.tar.gz)
      tar xzf "$package" -C "$room" || { bad "liess sich nicht auspacken"; return; }
      local so; so="$(find "$room" -name 'libpdfium.so' | head -1)"
      [ -n "$so" ] || { bad "kein libpdfium.so im Paket"; return; }
      check_library "$so" linux-x64
      ;;
    *windows*.zip)
      unzip -q -o "$package" -d "$room" || { bad "liess sich nicht auspacken"; return; }
      local dll; dll="$(find "$room" -iname 'pdfium.dll' | head -1)"
      [ -n "$dll" ] || { bad "keine pdfium.dll im Paket"; return; }
      check_library "$dll" windows-x64
      ;;
    *.apk)
      unzip -q -o "$package" 'lib/*/libpdfium.so' -d "$room" 2>/dev/null
      local found=0 so abi platform
      while IFS= read -r so; do
        [ -n "$so" ] || continue
        found=1
        abi="$(basename "$(dirname "$so")")"
        case "$abi" in
          arm64-v8a)   platform=android-arm64 ;;
          armeabi-v7a) platform=android-arm ;;
          *)           bad "unbekannte Architektur $abi"; continue ;;
        esac
        check_library "$so" "$platform"
      done < <(find "$room" -name 'libpdfium.so')
      [ "$found" = 1 ] || bad "kein libpdfium.so in der APK"
      ;;
    *)
      bad "unbekannte Paketform -- siehe --help"
      ;;
  esac
}

echo "PDFium-Herkunft, Release $RELEASE"
echo
for package in "$@"; do
  check_package "$package"
  echo
done

if [ "$fail" = 0 ]; then
  echo "Alles geprueft und in Ordnung."
else
  echo "FEHLGESCHLAGEN: mindestens ein Paket traegt ein anderes PDFium." >&2
fi
exit "$fail"
