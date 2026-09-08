#!/usr/bin/env bash
#
# Regenerates test/features/knowledge/german_stems.csv — the fixture the
# Dart stemmer is measured against.
#
# The pairs come from Xapian's own German stemmer, which is the standard
# the Dart one has to meet: where the archive carries an index, Xapian
# does the stemming, and where it does not, the app does. The two
# disagreeing would mean the same search finding different articles
# depending on which platform someone is on.
#
# The words are a whole German dictionary, 356 006 of them, from Debian's
# wngerman package. The committed fixture is every 89th pair of that run —
# enough to hit every rule several times without putting seven megabytes
# in the repository. The full run is what the number in the test's
# comment refers to, and this script prints it.
#
# Needs the static xapian-core that native/zim_xapian/build_macos.sh
# builds. Run that first.
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly XAPIAN="$ROOT/preppsuite_flutter/native/zim_xapian/build/xapian-macos-arm64"
readonly FIXTURE="$ROOT/preppsuite_flutter/test/features/knowledge/german_stems.csv"

readonly WORDLIST_URL="http://deb.debian.org/debian/pool/main/i/igerman98/wngerman_20161207-16_all.deb"
readonly WORDLIST_SHA256=54bfe90ed226ec12804ea06adff0597aae3293a5b1caf96f2e4c2dc4e131b661

# Every 89th pair. A prime, so the sample does not fall into step with
# any alphabetical pattern in the dictionary.
readonly EVERY=89

[ -f "$XAPIAN/lib/libxapian.a" ] || {
  echo "FEHLER: erst native/zim_xapian/build_macos.sh laufen lassen" >&2
  exit 1
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "== Woerterbuch laden =="
curl -fsSL --retry 3 -o "$work/wngerman.deb" "$WORDLIST_URL"

# Checked before unpacking: a .deb is a list of paths to write, and this
# one comes over plain HTTP.
actual="$(shasum -a 256 "$work/wngerman.deb" | cut -d' ' -f1)"
if [ "$actual" != "$WORDLIST_SHA256" ]; then
  echo "FEHLER: Pruefsumme des Woerterbuchs passt nicht" >&2
  echo "  erwartet: $WORDLIST_SHA256" >&2
  echo "  bekommen: $actual" >&2
  exit 1
fi

(cd "$work" && ar x wngerman.deb && tar -xf data.tar.xz ./usr/share/dict/ngerman)

echo "== Xapians Stemmer bauen =="
cat > "$work/stemref.cpp" <<'CPP'
#include <xapian.h>
#include <iostream>
#include <string>
int main() {
  Xapian::Stem stemmer("german");
  std::string line;
  while (std::getline(std::cin, line)) {
    while (!line.empty() && (line.back() == '\r' || line.back() == '\n')) {
      line.pop_back();
    }
    if (line.empty()) continue;
    std::cout << line << ';' << stemmer(line) << '\n';
  }
  return 0;
}
CPP
clang++ -std=c++17 -O2 -I"$XAPIAN/include" -o "$work/stemref" \
  "$work/stemref.cpp" "$XAPIAN/lib/libxapian.a" -lz

echo "== stemmen =="
# Lowercased first, because that is the state the stemmer is defined for
# and the state the search reaches it in.
python3 - "$work/usr/share/dict/ngerman" "$work/woerter.txt" <<'PY'
import sys

seen = set()
words = []
for line in open(sys.argv[1], encoding='utf-8'):
    word = line.strip().lower()
    if not word or word in seen:
        continue
    if not all(c.isalpha() or c in 'äöüß' for c in word):
        continue
    seen.add(word)
    words.append(word)
open(sys.argv[2], 'w', encoding='utf-8').write('\n'.join(words) + '\n')
print(f'{len(words)} Woerter')
PY

"$work/stemref" < "$work/woerter.txt" > "$work/stems.csv"

{
  echo "# wort;stamm - erzeugt von tool/german_stems.sh"
  awk "NR % $EVERY == 1" "$work/stems.csv"
} > "$FIXTURE"

echo
echo "vollstaendig: $(wc -l < "$work/stems.csv" | tr -d ' ') Paare"
echo "im Repository: $(( $(wc -l < "$FIXTURE") - 1 )) Paare"
