#!/usr/bin/env bash
# The local release gate. It is deliberately runnable without a hosted CI
# runner, so a tagged package cannot skip the privacy, formatting and test
# checks just because an external forge worker is unavailable.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/preppsuite_flutter"

"$ROOT/tool/repo_privacy_check.sh"

cd "$APP"
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --no-pub
