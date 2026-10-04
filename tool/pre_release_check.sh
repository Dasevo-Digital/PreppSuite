#!/usr/bin/env bash
# The local release gate. It is deliberately runnable without a hosted CI
# runner, so a tagged package cannot skip the privacy, formatting and test
# checks just because an external forge worker is unavailable.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/preppsuite_flutter"

"$ROOT/tool/repo_privacy_check.sh"

# The whole repository, as the pre-push hook checks it: third_party/
# carries Dart too, and a gate narrower than the hook only moves the
# surprise to the push.
dart format --output=none --set-exit-if-changed "$ROOT"
cd "$APP"
flutter analyze
flutter test --no-pub
