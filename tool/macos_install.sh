#!/usr/bin/env bash
#
# Installs the two macOS apps this machine is supposed to have, and only
# those two:
#
#   /Applications/PreppSuite.app        the one that holds the real household
#   /Applications/PreppSuite Test.app   the same build under its own bundle
#                                       identifier, so trying something out
#                                       cannot touch the real data
#
# Both come from the same build. The test one differs in exactly two
# fields — its identifier and its name — which is enough for macOS to give
# it a sandbox container of its own: its own database, its own settings,
# its own shared folder. The migration inside the app reads the identifier
# from the running bundle, so the test copy looks for a predecessor of its
# own and never finds the real household.
#
# It also runs tool/macos_spotlight_clean.sh afterwards, so the machine is
# left knowing these two and nothing else. A .app sitting in `build/` is
# indexed like any other, and a menu offering three PreppSuites, two of
# which are staging copies, is worse than useless when somebody is looking
# for the one with their inventory in it.
#
# Usage:
#   tool/macos_install.sh                        # the last build
#   tool/macos_install.sh path/to/PreppSuite.app
#   tool/macos_install.sh path/to/PreppSuite-x.y.z-macos-universal.zip
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BUILD_APP="$REPO_ROOT/preppsuite_flutter/build/macos/Build/Products/Release/PreppSuite.app"

readonly PROD_APP="/Applications/PreppSuite.app"
readonly TEST_APP="/Applications/PreppSuite Test.app"
readonly TEST_ID="de.dasevo.preppsuite.test"
readonly TEST_NAME="PreppSuite Test"

die() { echo "FEHLER: $*" >&2; exit 1; }

source="${1:-$BUILD_APP}"
[ -e "$source" ] || die "nichts unter $source"

workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT

# A zip is unpacked; anything else has to be a bundle already.
if [[ "$source" == *.zip ]]; then
  echo "== Paket auspacken =="
  ditto -x -k "$source" "$workspace/unpacked"
  source="$(find "$workspace/unpacked" -maxdepth 2 -name '*.app' -type d | head -1)"
  [ -n "$source" ] || die "im Paket ist kein .app-Bündel"
fi
[ -d "$source/Contents/MacOS" ] || die "$source ist kein App-Bündel"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$source/Contents/Info.plist")"
echo "Quelle: $source (Fassung $version)"

# Replacing a running app leaves the running one on a deleted bundle,
# which is how you get a version number that lies — and worse.
#
# Worse, on 26.09.2026: quitting is an Apple Event, not a promise.
# `osascript` returns as soon as the app has been *asked*, and this went
# straight on to `rm -rf`. Five seconds after the new files landed, the
# still-quitting app segfaulted: a worker isolate branched to address
# zero inside `sqlite3Close`, with sqlite3mc mapped **twice** in the one
# process — the deleted copy it started with and the new one it faulted
# a page in from.
#
# Our own `ClosesDatabasesOnExit` made that window wider rather than
# narrower. It spends up to five seconds closing the databases before the
# app goes, which is exactly the stretch this script used to spend
# deleting the bundle out from under it.
#
# So: ask, then wait until it is really gone, and refuse rather than
# replace a bundle somebody is still running out of.
# Overridable so the waiting itself can be tested without waiting.
QUIT_GRACE="${QUIT_GRACE:-30}"

# The former identifiers too: the first install under the new ones
# replaces apps that still carry the old.
for id in de.dasevo.preppsuite "$TEST_ID" de.status403.preppsuite de.status403.preppsuite.test; do
  osascript -e "quit app id \"$id\"" >/dev/null 2>&1 || true
done

# Matches on the executable path, so it cannot mistake this script — or a
# build sitting somewhere else — for the installed app.
still_running() { pgrep -f "$1/Contents/MacOS/" >/dev/null 2>&1; }

for app in "$PROD_APP" "$TEST_APP"; do
  [ -e "$app" ] || continue
  still_running "$app" || continue
  echo "== warte, bis $(basename "$app") beendet ist =="
  waited=0
  while still_running "$app"; do
    if [ "$waited" -ge "$QUIT_GRACE" ]; then
      die "$(basename "$app") laeuft nach $QUIT_GRACE s immer noch. Beende es von Hand und starte noch einmal — das Buendel jetzt zu ersetzen bringt den laufenden Vorgang zum Absturz."
    fi
    sleep 1
    waited=$((waited + 1))
  done
  echo "   nach ${waited} s beendet"
done

# Both are signed from the repository's Release.entitlements rather than
# from whatever the source bundle happens to carry. That is deliberate:
# `flutter build macos` writes get-task-allow into the Release bundle, a
# debug entitlement that lets any process attach to the app. Signing from
# the file drops it.
sign="$REPO_ROOT/tool/macos_sign.sh"
[ -x "$sign" ] || die "tool/macos_sign.sh fehlt"

echo "== $PROD_APP =="
rm -rf "$PROD_APP"
ditto "$source" "$PROD_APP"
"$sign" "$PROD_APP" --allow-ad-hoc >/dev/null || die "$PROD_APP liess sich nicht signieren"

echo "== $TEST_APP =="
rm -rf "$TEST_APP"
ditto "$source" "$TEST_APP"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $TEST_ID" \
  "$TEST_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $TEST_NAME" \
  "$TEST_APP/Contents/Info.plist"

# Editing Info.plist invalidates the signature, and macOS kills a bundle
# whose signature does not match rather than explaining itself. Ad-hoc,
# like the build itself: there is no Developer ID here.
"$sign" "$TEST_APP" --allow-ad-hoc >/dev/null || die "das Test-Bündel liess sich nicht signieren"

# Nothing should be left where Spotlight would offer it as a third app,
# and removing the bundle is only half of that: Launch Services keeps its
# entry afterwards and goes on offering it. The cleanup does both.
echo
"$REPO_ROOT/tool/macos_spotlight_clean.sh"

echo
echo "== installiert =="
for app in "$PROD_APP" "$TEST_APP"; do
  printf '%-34s %-30s %s\n' \
    "$(basename "$app")" \
    "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" \
    "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
done
