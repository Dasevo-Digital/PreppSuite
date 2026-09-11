#!/usr/bin/env bash
#
# Leaves macOS knowing exactly two PreppSuites, and no others:
#
#   /Applications/PreppSuite.app        the one that holds the real household
#   /Applications/PreppSuite Test.app   the staging copy under its own id
#
# Why this is needed at all: Spotlight's "Programme" section, the Open-With
# menu and the Dock's icon lookup do not read the disk, they read Launch
# Services' database. That database keeps an entry for every bundle macOS
# has ever seen — a build in `build/`, a copy in an old release folder on
# the Desktop, a bundle that went to the Trash and out of it. The entry
# survives the bundle: seventeen of the twenty PreppSuites registered here
# pointed at paths that no longer existed, and Spotlight still offered
# them. Deleting a copy therefore does not remove it from the search; it
# has to be unregistered.
#
# `.metadata_never_index` is not a way out. On macOS 26 the marker is
# ignored — a probe file dropped next to it in `build/` was indexed within
# seconds — so the only reliable way to keep a build out of the file index
# is not to leave one lying around, which is what the first step does.
#
# Usage:
#   tool/macos_spotlight_clean.sh              # clean up
#   tool/macos_spotlight_clean.sh --dry-run    # only show what it would do
set -uo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

# The two that are allowed to stay. Everything else that answers to the
# name is a leftover, whether it still exists or not.
readonly PROD_APP="/Applications/PreppSuite.app"
readonly TEST_APP="/Applications/PreppSuite Test.app"

dry_run=false
[ "${1:-}" = "--dry-run" ] && dry_run=true

[ -x "$LSREGISTER" ] || { echo "FEHLER: lsregister nicht gefunden" >&2; exit 1; }

echo "== Baureste im Projekt =="
found_build=false
while IFS= read -r app; do
  found_build=true
  echo "  loeschen: ${app#"$REPO_ROOT"/}"
  $dry_run || rm -rf "$app"
done < <(find "$REPO_ROOT/preppsuite_flutter/build" -maxdepth 6 -name '*.app' -type d 2>/dev/null)
$found_build || echo "  nichts gefunden"

echo
echo "== Eintraege in Launch Services =="
removed=0
kept=0
while IFS= read -r path; do
  case "$path" in
    "$PROD_APP"|"$TEST_APP") kept=$((kept + 1)); echo "  behalten:      $path"; continue ;;
  esac
  state="verwaist"
  [ -e "$path" ] && state="vorhanden"
  echo "  abmelden ($state): $path"
  $dry_run || "$LSREGISTER" -u "$path" >/dev/null 2>&1
  removed=$((removed + 1))
done < <("$LSREGISTER" -dump 2>/dev/null \
  | grep -iE '^[[:space:]]*path:.*prepp' \
  | sed -E 's/^[[:space:]]*path:[[:space:]]+//; s/ \(0x[0-9a-f]+\)$//' \
  | sort -u)

echo
if $dry_run; then
  echo "Probelauf: $removed abzumelden, $kept bleiben."
  exit 0
fi

# Saying it worked is not the same as it having worked, and this is
# exactly the kind of thing that silently does not.
echo "== verbleibend =="
"$LSREGISTER" -dump 2>/dev/null \
  | grep -iE '^[[:space:]]*path:.*prepp' \
  | sed -E 's/^[[:space:]]*path:[[:space:]]+//; s/ \(0x[0-9a-f]+\)$//' \
  | sort -u \
  | sed 's/^/  /'

echo
echo "Im Dateiindex:"
mdfind "kMDItemContentType == 'com.apple.application-bundle'" 2>/dev/null \
  | grep -i prepp \
  | sed 's/^/  /'

# Ordner, die Spotlight fuer Programme haelt.
#
# Nicht jeder Eintrag oben ist eine App. Auf diesem Mac wird ein sichtbarer
# Ordner, dessen Name auf `.0` endet, als com.apple.application-bundle
# geführt, Art "Programm" -- die Release-Ordner v1.4.0 und v1.5.0 standen so
# in Spotlights Programme-Abschnitt, v1.3.1 nicht. Dreimal mit sichtbaren
# Probeordnern reproduziert. Es ist nicht die UTI (`.0` loest auf einen
# undeklarierten dynamischen Typ auf, der weder Paket noch Programm ist) und
# nicht der Inode (frische Verzeichnisse verhalten sich gleich).
#
# lsregister hilft dagegen nicht: der Eintrag steht nicht in Launch Services,
# sondern im Dateiindex. Was hilft, ist ein anderer Name. Deshalb wird hier
# nur gemeldet und nicht umbenannt -- Ordner auf dem Schreibtisch gehoeren
# dem Nutzer.
mislabelled=0
while IFS= read -r path; do
  [ -e "$path/Contents/Info.plist" ] && continue
  if [ "$mislabelled" = 0 ]; then
    echo
    echo "Als Programm gefuehrt, aber keine App:"
  fi
  mislabelled=$((mislabelled + 1))
  echo "  $path"
done < <(mdfind "kMDItemContentType == 'com.apple.application-bundle'" 2>/dev/null \
  | grep -i prepp)

if [ "$mislabelled" != 0 ]; then
  echo
  echo "  Abhilfe: umbenennen, sodass der Name nicht auf .0 endet."
  echo "  Ein angehaengtes -Upload genuegt."
fi
