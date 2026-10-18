#!/usr/bin/env bash
#
# Regenerates the fixtures the Dart stemmers are measured against (#194):
# test/fixtures/stems/{english,spanish,french,german_snowball}_stems.csv.
#
# The standard is Snowball's own: its test vocabulary for each language
# and the output its reference implementation gives for every word, from
# the snowball-data repository at the last commit before the 2025
# algorithm changes -- Snowball 2, the version the German stemmer has
# followed since 0.15.0 and the one indexes are built with. The files are
# pinned by commit and checked by SHA-256.
#
# Each fixture is every Nth pair of the full list (a prime, so the sample
# does not fall into step with an alphabetical pattern). The script also
# prints the size of each full list; the counts in the stemmers' comments
# refer to those, over which the Dart stemmers agree on every word.
#
# The data is under the BSD licence of the Snowball project; each fixture
# repeats the notice. They live under test/fixtures/, which the privacy
# check leaves out: a dictionary of real words holds words that look like
# names.
#
# Usage: tool/snowball_stems.sh
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly OUT="$ROOT/preppsuite_flutter/test/fixtures/stems"
readonly BASE="https://raw.githubusercontent.com/snowballstem/snowball-data"

# language  commit  every  voc.txt sha256  output.txt sha256  fixture
readonly SOURCES="
english 2837d237a19f1e44c52d7c81f105e7c14809f7d6 7 ee41dc46a87d1564f96711c4f442ea6eb37eeca7877987e269df5f9d02c22b20 eac27b4d2406e0d429127faa8b9ae572a31025dec5b29b2f596a123e85669073 english_stems.csv
spanish 9fa59c4d552c9abc739b0508a225c0a07f016658 7 c2ea573edbe1fc5afe62dfc4c3986ed0e66c250e8e5d3887f923e20455709f58 ec801d7bc2e78caa5a4204708e32e081db307e0a58c3655d6f849e31ba8a432d spanish_stems.csv
french 1d45f4696c9145c7c762f6ca90090f76372e01fa 5 4ad03e5b7e632b997fc69f0cd140e48ffdbcfdb5f5958403dcd9c274355b2b10 feb1c29b7e166c6f9d9ae56ab1f745513d7ffc67ce48ec253e0aecfaa6b2a571 french_stems.csv
german 8d35251e456139167a394ea315e4855247fa2471 11 f680b1d49eb56bd6145a0ca03484fa489f0c79073ec406e80fef71d924c475af 926d096d73280f3bcd2dcc9aaf9945a1b460c121c043e93978ca04d364c546f8 german_snowball_stems.csv
"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

echo "$SOURCES" | while read -r lang commit every voc_sha out_sha fixture; do
  [ -n "$lang" ] || continue
  for file in voc.txt output.txt; do
    curl -fsSL --retry 3 -o "$work/$lang-$file" "$BASE/$commit/$lang/$file"
  done
  [ "$(sha256 "$work/$lang-voc.txt")" = "$voc_sha" ] ||
    { echo "FEHLER: $lang/voc.txt hat eine andere Prüfsumme" >&2; exit 1; }
  [ "$(sha256 "$work/$lang-output.txt")" = "$out_sha" ] ||
    { echo "FEHLER: $lang/output.txt hat eine andere Prüfsumme" >&2; exit 1; }

  python3 -I - "$work/$lang-voc.txt" "$work/$lang-output.txt" "$every" \
    "$OUT/$fixture" "$lang" "$commit" <<'PY'
import sys
voc_path, out_path, every, fixture, lang, commit = sys.argv[1:]
words = open(voc_path, encoding="utf-8").read().splitlines()
stems = open(out_path, encoding="utf-8").read().splitlines()
assert len(words) == len(stems), "voc and output differ in length"
every = int(every)
with open(fixture, "w", encoding="utf-8") as out:
    out.write(f"# Snowball {lang} stemmer, test vocabulary and expected output\n")
    out.write(f"# from snowball-data {commit}, every {every}th of {len(words)} pairs.\n")
    out.write("# Written by tool/snowball_stems.sh.\n")
    out.write("#\n")
    out.write("# Copyright (c) 2001, Dr Martin Porter\n")
    out.write("# Copyright (c) 2004,2005, Richard Boulton\n")
    out.write("# BSD licence of the Snowball project (3-clause); see THIRD_PARTY_NOTICES.md.\n")
    kept = 0
    for i in range(0, len(words), every):
        word, stem = words[i], stems[i]
        if not word or ";" in word or ";" in stem:
            continue
        out.write(f"{word};{stem}\n")
        kept += 1
print(f"{lang}: {len(words)} Paare, {kept} im Fixture {fixture.rsplit('/', 1)[-1]}")
PY
done
