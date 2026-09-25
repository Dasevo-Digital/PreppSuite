#!/usr/bin/env bash
#
# Builds the three probes and measures one PDF with them.
#
# Nothing here is part of PreppSuite. It answers one question before any
# of it is built in: what would an offline text recognition on this
# machine cost, and how much of a scanned page would it actually read.
# The numbers of the first run are written down in
# `docs/texterkennung-messung.md`.
#
# Usage:
#   tool/ocr_probe/run.sh <datei.pdf> [Seiten] [dpi] [Sprache]
#   tool/ocr_probe/run.sh --self-test        # baut sich seine Seite selbst
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly HERE="$ROOT/tool/ocr_probe"
readonly OUT="${TMPDIR:-/tmp}/preppsuite-ocr-probe"

command -v swiftc >/dev/null || { echo "FEHLER: swiftc fehlt (nur macOS)" >&2; exit 1; }

mkdir -p "$OUT"
for tool in ocr_probe make_scan make_page; do
  if [ ! -x "$OUT/$tool" ] || [ "$HERE/$tool.swift" -nt "$OUT/$tool" ]; then
    echo "baue $tool"
    swiftc -O "$HERE/$tool.swift" -o "$OUT/$tool"
  fi
done

if [ "${1:-}" = "--self-test" ]; then
  # Eine Seite mit bekanntem Wortlaut, daraus ein Scan, und der Vergleich
  # zwischen beidem -- ohne fremde Datei und ohne fremde Inhalte.
  sed -n '/^## Eigene Dokumente/,/^## Grenzen/p' "$ROOT/docs/wissen-offline.md" \
    | sed 's/[*_#`]//g' > "$OUT/gt.txt"
  "$OUT/make_page" "$OUT/gt.txt" "$OUT/gt.pdf" --font Helvetica --size 11
  "$OUT/make_scan" "$OUT/gt.pdf" "$OUT/scan.pdf" --dpi 200 --quality 0.5
  mkdir -p "$OUT/text"
  "$OUT/ocr_probe" "$OUT/scan.pdf" --pages 1 --dpi 72 --dump "$OUT/text"
  python3 - "$OUT/gt.txt" "$OUT/text/page-1.txt" <<'PY'
import difflib, re, sys
norm = lambda t: re.sub(r'\s+', ' ', t).strip()
truth = norm(open(sys.argv[1], encoding='utf-8').read())
read = norm(open(sys.argv[2], encoding='utf-8').read())
print('Grundwahrheit %d Zeichen, erkannt %d, Aehnlichkeit %.3f'
      % (len(truth), len(read), difflib.SequenceMatcher(None, truth, read, autojunk=False).ratio()))
PY
  exit 0
fi

[ $# -ge 1 ] || { echo "Usage: $0 <datei.pdf> [Seiten] [dpi] [Sprache]" >&2; exit 1; }
exec /usr/bin/time -l "$OUT/ocr_probe" "$1" \
  --pages "${2:-10}" --dpi "${3:-200}" --language "${4:-de-DE}"
