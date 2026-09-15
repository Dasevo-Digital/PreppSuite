#!/usr/bin/env bash
#
# Builds a first aid video pack: the paket.json the app reads, and a zip
# of the whole thing for a memory stick.
#
# The app ships no videos and no address for any. That is deliberate --
# see lib/features/first_aid/application/first_aid_video_pack.dart -- so
# whoever wants videos assembles a pack themselves, and this is the tool
# for it.
#
# What you provide is a folder holding the video files and one tab
# separated file, videos.tsv, with a line per clip:
#
#   datei<TAB>anleitung<TAB>titel<TAB>urheber<TAB>lizenz<TAB>sekunden
#
#   hdm.mp4	cpr-adult	Herzdruckmassage	Jane Doe	CC BY-SA 4.0	95
#
# `anleitung` is the id of the guide the clip belongs to. The ids are the
# `id:` values in first_aid_guides_de.dart; --ids prints them.
#
# Lines beginning with # and blank lines are skipped, so the file can be
# commented.
#
# What comes out:
#
#   <ordner>/paket.json                      the description, with the
#                                            exact byte count and the
#                                            sha256 of every file filled in
#   <ordner>/ErsteHilfe-Videopaket.zip       description and videos together
#
# Usage:
#   tool/erste_hilfe_paket.sh <ordner> [basis-url] [paketname]
#   tool/erste_hilfe_paket.sh --ids
#
# With a basis-url the description carries a `baseUrl`, and every clip
# gets a relative address under it -- that is what makes the pack
# fetchable over the network. Without one the pack has no addresses at
# all, which is fine: a zip on a stick needs none.
#
# Only the zip and paket.json are written; nothing else in the folder is
# touched.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
guides="$here/preppsuite_flutter/lib/features/first_aid/application/first_aid_guides_de.dart"

if [[ "${1:-}" == "--ids" ]]; then
  # The single source of truth is the Dart file; printing from it means
  # this can never list an id the app does not have.
  grep -o "id: '[a-z-]*'" "$guides" | sed "s/id: '//;s/'//"
  exit 0
fi

folder="${1:-}"
base_url="${2:-}"
pack_name="${3:-Erste Hilfe – Videopaket}"

if [[ -z "$folder" || ! -d "$folder" ]]; then
  echo "Usage: tool/erste_hilfe_paket.sh <ordner> [basis-url] [paketname]" >&2
  echo "       tool/erste_hilfe_paket.sh --ids" >&2
  exit 2
fi

folder="$(cd "$folder" && pwd)"
list="$folder/videos.tsv"
if [[ ! -f "$list" ]]; then
  echo "Es fehlt $list. Aufbau steht oben in dieser Datei." >&2
  exit 2
fi

known_ids="$(grep -o "id: '[a-z-]*'" "$guides" | sed "s/id: '//;s/'//")"

manifest="$folder/paket.json"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  echo '{'
  echo '  "format": 1,'
  printf '  "name": %s,\n' "$(printf '%s' "$pack_name" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/')"
  echo '  "language": "de",'
  if [[ -n "$base_url" ]]; then
    printf '  "baseUrl": "%s",\n' "$base_url"
  fi
  echo '  "videos": ['
} > "$tmp"

count=0
first=1
while IFS=$'\t' read -r file guide title credit licence seconds || [[ -n "${file:-}" ]]; do
  [[ -z "${file:-}" ]] && continue
  [[ "$file" == \#* ]] && continue

  path="$folder/$file"
  if [[ ! -f "$path" ]]; then
    echo "Fehlt: $file" >&2
    exit 1
  fi
  # A guide id that does not exist would produce a clip the app keeps and
  # never shows -- silently. Better to say so here.
  if ! printf '%s\n' "$known_ids" | grep -qx "$guide"; then
    echo "Unbekannte Anleitung '$guide' bei $file. tool/erste_hilfe_paket.sh --ids" >&2
    exit 1
  fi

  bytes="$(wc -c < "$path" | tr -d ' ')"
  sha="$(shasum -a 256 "$path" | cut -d' ' -f1)"

  [[ $first -eq 0 ]] && echo ',' >> "$tmp"
  first=0
  {
    printf '    {\n'
    printf '      "id": "%s",\n' "${file%.*}"
    printf '      "guide": "%s",\n' "$guide"
    printf '      "title": %s,\n' "$(printf '%s' "$title" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/')"
    printf '      "file": "%s",\n' "$file"
    printf '      "credit": %s,\n' "$(printf '%s' "${credit:-}" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/')"
    printf '      "licence": %s,\n' "$(printf '%s' "${licence:-}" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/')"
    if [[ -n "$base_url" ]]; then
      printf '      "url": "%s",\n' "$file"
    fi
    if [[ -n "${seconds:-}" ]]; then
      printf '      "seconds": %s,\n' "$seconds"
    fi
    printf '      "bytes": %s,\n' "$bytes"
    printf '      "sha256": "%s"\n' "$sha"
    printf '    }'
  } >> "$tmp"
  count=$((count + 1))
done < "$list"

{
  echo ''
  echo '  ]'
  echo '}'
} >> "$tmp"

if [[ $count -eq 0 ]]; then
  echo "Keine Videos in $list." >&2
  exit 1
fi

# Checked before it is put in place, so a broken generator never
# overwrites a working description.
if command -v jq >/dev/null 2>&1; then
  jq -e . "$tmp" > /dev/null
fi
mv "$tmp" "$manifest"
trap - EXIT

zip_name="ErsteHilfe-Videopaket.zip"
(
  cd "$folder"
  rm -f "$zip_name"
  # Only the description and the files it names: the app refuses
  # everything else anyway, and a stray file in the zip is a file
  # somebody carries around for nothing.
  files=(paket.json)
  while IFS=$'\t' read -r file _ || [[ -n "${file:-}" ]]; do
    [[ -z "${file:-}" || "$file" == \#* ]] && continue
    files+=("$file")
  done < videos.tsv
  zip -q -X "$zip_name" "${files[@]}"
)

total="$(wc -c < "$folder/$zip_name" | tr -d ' ')"
echo "paket.json: $count Videos"
echo "$folder/$zip_name: $((total / 1000000)) MB"
echo
echo "Ueber das Netz: paket.json und die Videos an eine Adresse legen und"
echo "die Adresse der paket.json in der App unter Erste Hilfe > Videopaket"
echo "eintragen."
echo "Ohne Netz: die Zip auf einen Stick und in der App ueber"
echo "\"Paketdatei waehlen\" oeffnen."
