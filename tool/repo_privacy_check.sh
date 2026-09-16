#!/usr/bin/env bash
# Fails when a personal identifier slips into tracked source or Git history.
# Use neutral examples such as `testuser` and the project-owned noreply
# address; third-party licence texts are explicitly excluded below.
set -euo pipefail

readonly PROJECT_EMAIL='noreply'@'preppsuite.invalid'
readonly IDENTITY="PreppSuite Contributors <$PROJECT_EMAIL>"
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

# Public history is part of the repository. Every reachable commit must carry
# the project identity, otherwise a clone still exposes the former author.
if identities=$(git log --all --format='%aN <%aE>%n%cN <%cE>' | sort -u | grep -vFx "$IDENTITY" || true); then
  if [[ -n "$identities" ]]; then
    report "Personal author or committer identity in reachable Git history:"
    printf '%s\n' "$identities" >&2
  fi
fi

if (( fail )); then
  exit 1
fi
printf 'Repository privacy check passed.\n'
