#!/usr/bin/env bash
#
# Fails when the arm64 code in a library uses instructions an M1 does not
# have (#375): the 8-bit matrix multiplies (i8mm), bfloat16, SVE and SME.
# An M1 that meets one stops the app with SIGILL, and a build machine with
# a newer chip runs it without complaint, so only looking finds it.
#
# Disassembled with every extension switched on, so that what is there is
# named rather than shown as an unknown word.
#
# Usage: native/translate/check_arm64_baseline.sh <library>
set -euo pipefail

lib="${1:?Bibliothek angeben}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

slice="$work/arm64"
if lipo -archs "$lib" | tr ' ' '\n' | grep -qx arm64; then
  lipo -thin arm64 "$lib" -output "$slice" 2>/dev/null || cp "$lib" "$slice"
else
  echo "FEHLER: $lib enthält kein arm64" >&2
  exit 1
fi

objdump -d --mattr=+all "$slice" >"$work/disassembly"
# Mnemonics after the tab objdump puts before them. Apple's objdump
# writes the arrangement onto the mnemonic ("bfdot.4s") and may print
# nothing after it ("smmla"), so both ends are allowed for. SVE and SME
# by their registers, which nothing before them has: z (also as the
# first operand, "movprfx z0, z1"), the predicates p ("ptrue p0.s",
# "p1/z") and za ("zero {za}", "za0h.s"), and by the few that touch only
# general registers ("cntw x3", "rdvl", "addvl").
found="$(grep -oE $'\t(smmla|ummla|usmmla|usdot|sudot|bfdot|bfmmla|bfmlalb|bfmlalt|bfcvtn2|bfcvtn|bfcvt|smstart|smstop|cnt[bhwd]|rdvl|addvl|addpl|rdsvl|addsvl|addspl)(\\.[0-9a-z]+)?(\t|$)|[\t {,]z[0-9]{1,2}(\\.[bhsdq]|,|$|[ }])|[\t {,]p[0-9]{1,2}(\\.[bhsdq]|/[zm]|,|$)|[\t {,]za([0-9]+[hv]?)?([.[}]|$)' "$work/disassembly" |
  tr -d '\t {},' | sed -E 's/[./].*$//' | sort | uniq -c | sort -rn || true)"
if [ -n "$found" ]; then
  echo "FEHLER: $lib nutzt Befehle, die ein M1 nicht kennt:" >&2
  echo "$found" | head -20 >&2
  exit 1
fi
instructions="$(grep -cE $'^ +[0-9a-f]+: [0-9a-f]{8} +\t' "$work/disassembly" || true)"
# Nothing counted is nothing checked: an objdump that prints another
# layout would otherwise pass every library.
if [ "${instructions:-0}" -eq 0 ]; then
  echo "FEHLER: in $lib keine Befehle gefunden; Ausgabe von objdump unerwartet" >&2
  exit 1
fi
echo "arm64-Grundlinie: $instructions Befehle geprüft, keiner jenseits von armv8.4-a"
