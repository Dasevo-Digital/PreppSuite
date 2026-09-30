#!/usr/bin/env bash
# Fails when a personal identifier slips into tracked source or Git history.
# Use neutral examples such as `testuser` and the project-owned noreply
# address; third-party licence texts are explicitly excluded below.
set -euo pipefail

readonly PROJECT_EMAIL='noreply'@'preppsuite.invalid'
readonly IDENTITY="PreppSuite Contributors <$PROJECT_EMAIL>"
# Commits through this already published Gitea revision are immutable here.
# New release commits must use the neutral project identity.
readonly PUBLISHED_IDENTITY_BASE='86b0c03c0e6ea7ebdea3f3ce947d14f25462de1a'
readonly EXCLUDED=(
  ':(exclude)preppsuite_flutter/assets/fonts/OFL.txt'
  ':(exclude)preppsuite_flutter/ios/**/Package.resolved'
  ':(exclude)preppsuite_flutter/test/fixtures/**'
)

fail=0
report() {
  printf '%s\n' "$1" >&2
  fail=1
}

# Names from development machines and earlier project metadata must never
# return. This is deliberately a small denylist: names cannot be recognized
# reliably by a generic regular expression.
if matches=$(git grep -n -I -i -E 'ma'""'rco|guen'""'ther|Leonardo'""'Gamar' -- . "${EXCLUDED[@]}" || true); then
  if [[ -n "$matches" ]]; then
    report "Personal identifier in a tracked file:"
    printf '%s\n' "$matches" >&2
  fi
fi

# The project contains no contact address. An address in product code or a
# document must be the generic project identity, never an individual's.
if matches=$(git grep -n -I -E '[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}' -- . "${EXCLUDED[@]}" || true); then
  if [[ -n "$matches" ]]; then
    report "Email address in a tracked file:"
    printf '%s\n' "$matches" >&2
  fi
fi

# The published base contains one earlier, non-personal localhost identity.
# Rewriting that public history would disrupt existing clones, so enforce the
# neutral identity strictly for every commit added after the recorded base.
if ! git merge-base --is-ancestor "$PUBLISHED_IDENTITY_BASE" HEAD; then
  report "Published identity baseline is not an ancestor of HEAD."
fi
if identities=$(git log "$PUBLISHED_IDENTITY_BASE"..HEAD --format='%aN <%aE>%n%cN <%cE>' | sort -u | grep -vFx "$IDENTITY" || true); then
  if [[ -n "$identities" ]]; then
    report "Personal author or committer identity in reachable Git history:"
    printf '%s\n' "$identities" >&2
  fi
fi

if (( fail )); then
  exit 1
fi
printf 'Repository privacy check passed.\n'
