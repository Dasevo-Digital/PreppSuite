#!/usr/bin/env bash
# Proves that Flutter and Dart do not inherit the invoking worktree's Git
# environment from the pre-push hook.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/preppsuite-pre-push-check.XXXXXX")
cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

REPO="$TEST_ROOT/repo"
BIN="$TEST_ROOT/bin"
mkdir -p "$REPO/.githooks" "$REPO/tool" "$REPO/preppsuite_flutter" "$BIN"
cp "$ROOT/.githooks/pre-push" "$REPO/.githooks/"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$REPO/tool/repo_privacy_check.sh"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'for name in GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE; do' \
  '  if [[ -n "${!name-}" ]]; then' \
  '    printf "%s was inherited by %s.\\n" "$name" "${0##*/}" >&2' \
  '    exit 70' \
  '  fi' \
  'done' \
  >"$BIN/check-git-environment"
chmod +x "$REPO/.githooks/pre-push" "$REPO/tool/repo_privacy_check.sh" \
  "$BIN/check-git-environment"
cp "$BIN/check-git-environment" "$BIN/flutter"
cp "$BIN/check-git-environment" "$BIN/dart"

cd "$REPO"
git init -q
git config user.name superkuh86
neutral_email='335995236+superkuh86'@'users.noreply.github.com'
git config user.email "$neutral_email"
git add .
git commit -q -m initial
commit=$(git rev-parse HEAD)

printf 'refs/heads/main %s refs/heads/main %s\n' "$commit" "$commit" |
  GIT_DIR="$REPO/.git" \
  GIT_WORK_TREE="$REPO" \
  GIT_INDEX_FILE="$REPO/.git/index" \
  PATH="$BIN:$PATH" \
  "$REPO/.githooks/pre-push" >/dev/null

printf 'Pre-push worktree environment regression test passed.\n'
