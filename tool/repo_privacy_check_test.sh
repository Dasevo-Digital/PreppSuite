#!/usr/bin/env bash
# Regression tests for the tracked-file part of repo_privacy_check.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/preppsuite-privacy-check.XXXXXX")
cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

mkdir -p "$TEST_ROOT/repo/tool"
cp "$ROOT/tool/repo_privacy_check.sh" "$TEST_ROOT/repo/tool/"
cd "$TEST_ROOT/repo"
git init -q
git config user.name superkuh86
neutral_email='335995236+superkuh86'@'users.noreply.github.com'
git config user.email "$neutral_email"
printf 'clean\n' >clean.txt
git add .
git commit -q -m initial

bash tool/repo_privacy_check.sh >/dev/null

# Keep the address split in this source file, or the real repository check
# would correctly reject its own regression fixture.
bad_address='lowercase'@'example.invalid'
printf '%s\n' "$bad_address" >leak.txt
git add leak.txt
if output=$(bash tool/repo_privacy_check.sh 2>&1); then
  printf 'Lower-case email address was not rejected.\n' >&2
  exit 1
fi
if ! grep -Fq 'leak.txt:1' <<<"$output"; then
  printf 'Rejected address did not report its location.\n' >&2
  exit 1
fi
if grep -Fq "$bad_address" <<<"$output"; then
  printf 'Rejected address was copied into the diagnostic.\n' >&2
  exit 1
fi
git reset -q HEAD -- leak.txt
rm leak.txt

# These are public upstream metadata and an Xcode scale suffix, not project
# contact addresses. Their exact paths are the deliberately narrow allowlist.
mkdir -p third_party/flutter_tts/ios
printf '%s\n' "$bad_address" >third_party/flutter_tts/ios/flutter_tts.podspec
mkdir -p preppsuite_flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset
asset_name='AppIcon'@'2x.png'
printf '%s\n' "{\"filename\":\"$asset_name\"}" \
  >preppsuite_flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
git add .
bash tool/repo_privacy_check.sh >/dev/null

printf 'Repository privacy check regression tests passed.\n'
