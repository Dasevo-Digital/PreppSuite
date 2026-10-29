#!/usr/bin/env bash
# The local release gate. It is deliberately runnable without a hosted CI
# runner, so a tagged package cannot skip the privacy, formatting and test
# checks just because an external forge worker is unavailable.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/preppsuite_flutter"

"$ROOT/tool/repo_privacy_check.sh"
bash "$ROOT/tool/repo_privacy_check_test.sh"
bash "$ROOT/tool/pre_push_hook_test.sh"

if [[ "$(uname -s)" == Darwin ]]; then
  python3 "$ROOT/tool/storage_bridge_check.py"
fi

# The hosted checks build with the Flutter pinned in the workflows, the
# release machines with their own. A release built with another one than
# the checks used is not what they tested (#218).
flutter_version=$(flutter --version --machine |
  python3 -c 'import json, sys; print(json.load(sys.stdin)["frameworkVersion"])')
pinned=$(grep -rnoE "flutter-version: '[^']*'|--branch [0-9][^ ]*" \
  "$ROOT/.github/workflows" "$ROOT/tool/docker/linux.Dockerfile" || true)
if [[ -z "$pinned" ]]; then
  printf 'No Flutter pin found in the workflows; this check needs updating.\n' >&2
  exit 1
fi
stale=$(printf '%s\n' "$pinned" |
  awk -v v="$flutter_version" '{ n = $NF; gsub("\047", "", n); if (n != v) print }')
if [[ -n "$stale" ]]; then
  printf 'Flutter %s here, another version pinned in:\n%s\n' \
    "$flutter_version" "$stale" >&2
  exit 1
fi

# The whole repository, as the pre-push hook checks it: third_party/
# carries Dart too, and a gate narrower than the hook only moves the
# surprise to the push.
dart format --output=none --set-exit-if-changed "$ROOT"
cd "$APP"
flutter analyze
TZ=Europe/Berlin flutter test --no-pub \
  test/features/inventory/inventory_calendar_export_test.dart \
  test/core/calendar_days_test.dart
flutter test --no-pub
