#!/usr/bin/env bash
#
# Notarizes a Developer ID signed PreppSuite.app and staples the ticket to
# it (#387). Without a ticket Gatekeeper stops a downloaded app with "the
# developer cannot be verified", and the only way past was ctrl-click and
# Open.
#
# The App Store Connect API key is the one tool/ios_testflight.sh uses,
# read from the same keychain items (tool/macos_developer_id.py asc-key);
# it is a file only for the length of the run, readable by this user
# alone. Nothing of the account is in the repository.
#
# Stapling changes the bundle, so the caller zips it only afterwards. The
# check at the end is Gatekeeper's own: "source=Notarized Developer ID".
#
# Usage: tool/macos_notarize.sh <path to .app>
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FEHLER: $*" >&2
  exit 1
}

app="${1:?App-Bündel angeben}"
[ -d "$app/Contents/MacOS" ] || fail "$app ist kein App-Bündel"
# Read into a variable first: `codesign … | grep -q` under pipefail fails
# whenever grep stops at its match while codesign is still writing, and
# the pipeline then ends in SIGPIPE (141) on a perfectly good signature.
signature="$(codesign -dv --verbose=2 "$app" 2>&1)" || fail "$app ist nicht signiert"
grep -q '^Authority=Developer ID Application' <<<"$signature" ||
  fail "$app ist nicht mit Developer ID signiert"

work="$(mktemp -d)"
cleanup() {
  case "$work" in
    "${TMPDIR:-/tmp}"*) rm -rf -- "$work" ;;
  esac
}
trap cleanup EXIT

read -r key_id issuer < <(python3 "$ROOT/tool/macos_developer_id.py" asc-key "$work") ||
  fail "API-Schlüssel nicht lesbar"
[ -s "$work/AuthKey.p8" ] || fail "API-Schlüssel fehlt"
auth=(--key "$work/AuthKey.p8" --key-id "$key_id" --issuer "$issuer")

echo "== Notarisieren =="
ditto -c -k --keepParent "$app" "$work/submit.zip"
xcrun notarytool submit "$work/submit.zip" "${auth[@]}" --wait --timeout 45m \
  --output-format json >"$work/result.json" 2>"$work/submit.err" ||
  { cat "$work/submit.err" >&2; fail "notarytool submit"; }
read -r id status < <(python3 -I -c '
import json, sys
r = json.load(open(sys.argv[1]))
print(r.get("id", "?"), r.get("status", "?"))
' "$work/result.json")
echo "Vorgang $id: $status"
if [ "$status" != "Accepted" ]; then
  xcrun notarytool log "$id" "${auth[@]}" >&2 || true
  fail "Apple hat die App nicht notarisiert ($status)"
fi

echo "== Ticket anheften =="
xcrun stapler staple "$app" >/dev/null || fail "stapler staple"
xcrun stapler validate "$app" >/dev/null || fail "stapler validate"

assessment="$(spctl --assess --type execute --verbose=4 "$app" 2>&1)" ||
  { echo "$assessment" >&2; fail "Gatekeeper lehnt die App ab"; }
grep -q 'source=Notarized Developer ID' <<<"$assessment" ||
  { echo "$assessment" >&2; fail "Gatekeeper sieht keine Notarisierung"; }
echo "Gatekeeper: angenommen, notarisiert"
