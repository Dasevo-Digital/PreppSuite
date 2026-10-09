#!/usr/bin/env bash
# Fails when a personal identifier slips into tracked source or Git history.
# Use neutral examples such as `testuser` and the project-owned noreply
# address; third-party licence texts are explicitly excluded below.
set -euo pipefail

# Every commit in the reachable history carries the maintainer's GitHub login
# and its noreply address, so GitHub attributes it to that account without a
# real name or mailbox.
readonly AUTHOR_EMAIL='335995236+superkuh86'@'users.noreply.github.com'
readonly IDENTITY="superkuh86 <$AUTHOR_EMAIL>"
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

# The history was rewritten on 2026-10-07 to this identity throughout, so the
# whole reachable history is checked.
if identities=$(git log HEAD --format='%aN <%aE>%n%cN <%cE>' | sort -u | grep -vFx "$IDENTITY" || true); then
  if [[ -n "$identities" ]]; then
    report "Personal author or committer identity in reachable Git history:"
    printf '%s\n' "$identities" >&2
  fi
fi

# Commit and tag messages are published to GitHub along with the code, and
# the checks above never read them: an address once sat in a message while
# this script reported success (#73). The same rules apply to them, plus
# the trailers and tool names that writing aids add to a message. One
# historical commit names an instruction file by its former name; it is
# published, and rewriting public history is not an option, so it alone is
# let through.
if ! python3 - "$AUTHOR_EMAIL" <<'PY'
import re
import subprocess
import sys

noreply = sys.argv[1]
known = {"409ec6d91adb8a3fcea46f435985e65974f03f20"}
email = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
names = re.compile("ma" "rco|guen" "ther|leonardo" "gamar", re.I)
tools = re.compile(
    r"co-authored-by|generated with|\b(?:cla" r"ude|anthr" r"opic|chat" r"gpt|open" r"ai|copi" r"lot)\b",
    re.I,
)


def messages():
    log = subprocess.run(
        ["git", "log", "HEAD", "--format=%H%x00%B%x1e"],
        capture_output=True, text=True, check=True).stdout
    tags = subprocess.run(
        ["git", "for-each-ref", "refs/tags",
         "--format=%(objectname)%00%(contents)%1e"],
        capture_output=True, text=True, check=True).stdout
    for record in (log + tags).split("\x1e"):
        if "\x00" in record:
            sha, text = record.strip("\n").split("\x00", 1)
            yield sha, text


bad = []
for sha, text in messages():
    for line in text.splitlines():
        found = [a for a in email.findall(line) if a.lower() != noreply.lower()]
        if found or names.search(line) or (tools.search(line) and sha not in known):
            bad.append(f"{sha[:10]}: {line.strip()}")
for entry in bad:
    print(entry, file=sys.stderr)
sys.exit(1 if bad else 0)
PY
then
  report "Personal identifier or tool reference in a commit or tag message (above)."
fi

if (( fail )); then
  exit 1
fi
printf 'Repository privacy check passed.\n'
