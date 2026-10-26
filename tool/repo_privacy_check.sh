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
  ':(exclude)preppsuite_flutter/ios/Runner/Assets.xcassets/**/Contents.json'
  ':(exclude)preppsuite_flutter/test/fixtures/**'
  # Unchanged upstream metadata in the patched, vendored packages. These
  # addresses name their public maintainers, not anybody working on this repo.
  ':(exclude)third_party/flutter_tts/CODE_OF_CONDUCT.md'
  ':(exclude)third_party/flutter_tts/ios/flutter_tts.podspec'
  ':(exclude)third_party/flutter_tts/macos/flutter_tts.podspec'
  ':(exclude)third_party/zstandard_ios/ios/zstandard_ios.podspec'
  ':(exclude)third_party/zstandard_macos/macos/zstandard_macos.podspec'
)

fail=0
report() {
  printf '%s\n' "$1" >&2
  fail=1
}

# Findings are reported by where they are -- file and line, or commit --
# and never with what was found. The check also runs in the CI on GitHub,
# whose logs are public, and a check that printed a leaked name or
# address there would publish it a second time.
locations() { sed -E 's/^([^:]+:[0-9]+):.*$/\1/'; }

# Names from development machines and earlier project metadata must never
# return. This is deliberately a small denylist: names cannot be recognized
# reliably by a generic regular expression.
if matches=$(git grep -n -I -i -E 'ma'""'rco|guen'""'ther|Leonardo'""'Gamar' -- . "${EXCLUDED[@]}" || true); then
  if [[ -n "$matches" ]]; then
    report "Personal identifier in a tracked file:"
    printf '%s\n' "$matches" | locations >&2
  fi
fi

# The project contains no contact address. An address in product code or a
# document must be the generic project identity, never an individual's. Match
# without regard to case: addresses are normally lower-case.
if matches=$(git grep -n -I -i -E '[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}' -- . "${EXCLUDED[@]}" || true); then
  if [[ -n "$matches" ]]; then
    report "Email address in a tracked file:"
    printf '%s\n' "$matches" | locations >&2
  fi
fi

# The history was rewritten on 2026-10-07 to this identity throughout, so the
# whole reachable history is checked.
foreign=$(git log HEAD --format='%h%x09%aN <%aE>%x09%cN <%cE>' |
  awk -F '\t' -v id="$IDENTITY" '$2 != id || $3 != id { print $1 }')
if [[ -n "$foreign" ]]; then
  report "Another author or committer identity in reachable Git history, in:"
  printf '%s\n' "$foreign" >&2
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


bad = {}
for sha, text in messages():
    for line in text.splitlines():
        kinds = bad.setdefault(sha[:10], set())
        if [a for a in email.findall(line) if a.lower() != noreply.lower()]:
            kinds.add("address")
        if names.search(line):
            kinds.add("name")
        if tools.search(line) and sha not in known:
            kinds.add("tool reference")
bad = {sha: kinds for sha, kinds in bad.items() if kinds}
# What kind, not the line: see the note on locations above.
for sha, kinds in bad.items():
    print(f"{sha}: {', '.join(sorted(kinds))}", file=sys.stderr)
sys.exit(1 if bad else 0)
PY
then
  report "Personal identifier or tool reference in a commit or tag message (above)."
fi

if (( fail )); then
  exit 1
fi
printf 'Repository privacy check passed.\n'
