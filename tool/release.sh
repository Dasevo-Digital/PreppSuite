#!/usr/bin/env bash
# Builds every package of one release and checks it, in one run (#125).
#
#   tool/release.sh 2.4.6             build, test and checksum
#   tool/release.sh 2.4.6 --publish   … and create the release and upload
#
# Before it: the version is raised in pubspec.yaml, committed, tagged
# v<version> and pushed -- this script builds what the tag says and refuses
# a working tree that differs from it. The release text is written by hand
# into RELEASE-TEXT-v<version>.md in the upload folder; --publish takes it
# from there.
#
# The machines and the upload target come from the environment, never from
# this file:
#   RELEASE_LINUX_HOST    ssh name of the Linux machine   (default TestKubuntu)
#   RELEASE_WINDOWS_HOST  ssh name of the Windows machine (default TestWindows)
#   RELEASE_DIR           upload folder (default ~/Desktop/PreppSuite-Release-v<version>-Upload)
#   RELEASE_API           https://<host>/api/v1/repos/<owner>/<repo>  (--publish)
#   RELEASE_TOKEN         access token for it                          (--publish)
#
# What it does, in the order that keeps the slow machines busy: the Linux
# build starts first and runs while the Mac builds macOS and Android and
# runs the device check in the iPhone simulator. The Windows build needs
# the Xapian DLL the Linux machine cross-compiles, so it comes last.
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP_DIR="$ROOT/preppsuite_flutter"

version="${1:-}"
publish=false
[ "${2:-}" = "--publish" ] && publish=true
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Usage: $0 <version> [--publish]" >&2
  exit 2
}

linux="${RELEASE_LINUX_HOST:-TestKubuntu}"
windows="${RELEASE_WINDOWS_HOST:-TestWindows}"
out="${RELEASE_DIR:-$HOME/Desktop/PreppSuite-Release-v$version-Upload}"
tag="v$version"
log="$(mktemp -d)"

step() { printf '\n== %s ==\n' "$*"; }
fail() { echo "FEHLER: $*" >&2; echo "Protokolle: $log" >&2; exit 1; }

# --- What is being built -------------------------------------------------
cd "$ROOT"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "Tag $tag fehlt"
[ "$(git rev-parse HEAD)" = "$(git rev-list -n 1 "$tag")" ] ||
  fail "HEAD ist nicht $tag – erst auschecken"
[ -z "$(git status --porcelain -- preppsuite_flutter)" ] ||
  fail "Arbeitsverzeichnis nicht sauber"
line="$(sed -n 's/^version:[[:space:]]*//p' "$APP_DIR/pubspec.yaml" | head -1)"
[ "${line%%+*}" = "$version" ] || fail "pubspec.yaml sagt $line, nicht $version"
build="${line#*+}"
[[ "$build" =~ ^[0-9]+$ ]] || fail "ungültige Build-Nummer in pubspec.yaml"

mkdir -p "$out"
archive="$log/src-$version.tar.gz"
git archive --format=tar.gz --prefix=src/ -o "$archive" "$tag"

# --- Linux, in the background -------------------------------------------
step "Linux auf $linux starten"
remote_linux="preppsuite-release/$version"
ssh "$linux" "rm -rf ~/$remote_linux && mkdir -p ~/$remote_linux"
scp -q "$archive" "$linux:$remote_linux/src.tar.gz"
scp -q "$ROOT/tool/linux_release.sh" "$linux:$remote_linux/linux_release.sh"
ssh "$linux" "cd ~/$remote_linux && tar xzf src.tar.gz && \
  (nohup bash linux_release.sh \$HOME/$remote_linux $version $build \
   > build.log 2>&1 < /dev/null &)"

# --- macOS ----------------------------------------------------------------
step "macOS"
app="$APP_DIR/build/macos/Build/Products/Release/PreppSuite.app"
(cd "$APP_DIR" && flutter build macos --release --build-name "$version" \
  --build-number "$build") > "$log/macos.log" 2>&1 || fail "macOS-Build"
"$ROOT/tool/macos_sign.sh" "$app" --allow-ad-hoc > "$log/sign.log" 2>&1 ||
  fail "macOS-Signatur"
codesign --verify --deep --strict "$app" || fail "Signatur ungültig"
[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$app/Contents/Info.plist")" = "$version" ] || fail "falsche Version im Mac-Paket"
ditto -c -k --keepParent "$app" "$out/PreppSuite-$version-macos-local-ad-hoc.zip"
rm -rf "$app"

# --- Android --------------------------------------------------------------
step "Android"
"$ROOT/tool/android_release.sh" > "$log/android.log" 2>&1 || fail "Android-Build"
apks="$APP_DIR/build/app/outputs/flutter-apk"
cp "$apks/app-arm64-v8a-release-rotated.apk" "$out/PreppSuite-$version-Android-arm64-v8a.apk"
cp "$apks/app-armeabi-v7a-release-rotated.apk" "$out/PreppSuite-$version-Android-armeabi-v7a.apk"

# --- Device check in the iPhone simulator ---------------------------------
step "Gerätetest im iPhone-Simulator"
python3 "$ROOT/tool/release_device_check.py" "$out" > "$log/device.log" 2>&1 || true
grep -E "Ergebnis|Stand|Tests:" "$log/device.log" || true
grep -q "BESTANDEN" "$log/device.log" || fail "Gerätetest nicht bestanden"
# Bundles under build/ show up in Spotlight and can open the real data.
find "$APP_DIR/build" \( -name '*.app' -o -name '*.appex' \) -prune -exec rm -rf {} +

# --- Linux result ---------------------------------------------------------
step "Auf Linux warten"
for _ in $(seq 1 360); do
  ssh "$linux" "grep -q ALLES-FERTIG ~/$remote_linux/build.log" && break
  sleep 10
done
ssh "$linux" "grep -q ALLES-FERTIG ~/$remote_linux/build.log" ||
  fail "Linux-Build nicht fertig, siehe ~/$remote_linux/build.log"
ssh "$linux" "grep -q 'lib/libzim_xapian.so' ~/$remote_linux/inhalt.txt && \
  grep -q 'lib/libpdfium.so' ~/$remote_linux/inhalt.txt" ||
  fail "Linux-Paket ohne Xapian oder PDFium"
scp -q "$linux:$remote_linux/PreppSuite-$version-linux-x64.tar.gz" "$out/"
scp -q "$linux:$remote_linux/src/preppsuite_flutter/native/zim_xapian/build/zim_xapian.dll" \
  "$log/zim_xapian.dll" || fail "Xapian-DLL fehlt"

# --- Windows --------------------------------------------------------------
step "Windows auf $windows"
win="C:/src/preppsuite-release/$version"
winback="C:\\src\\preppsuite-release\\$version"
ssh "$windows" "cmd /c \"if exist $winback rmdir /s /q $winback\"" || true
ssh "$windows" "cmd /c \"mkdir $winback\""
scp -q "$archive" "$windows:$win/src.tar.gz"
ssh "$windows" "cmd /c \"cd /d $winback && tar -xzf src.tar.gz && \
  mkdir src\\preppsuite_flutter\\native\\zim_xapian\\build\""
scp -q "$log/zim_xapian.dll" \
  "$windows:$win/src/preppsuite_flutter/native/zim_xapian/build/zim_xapian.dll"
scp -q "$ROOT/tool/windows_build.ps1" "$windows:$win/windows_build.ps1"
ssh "$windows" "powershell -NoProfile -ExecutionPolicy Bypass -File \
  $winback\\windows_build.ps1 -Work $winback -Version $version \
  -BuildNumber $build" > "$log/windows.log" 2>&1 ||
  fail "Windows-Build, siehe $log/windows.log"
grep -q "== FERTIG ==" "$log/windows.log" || fail "Windows-Build unvollständig"
scp -q "$windows:$win/PreppSuite-$version-windows-x64-unsigned-test.zip" "$out/"

# --- Checks on the finished packages --------------------------------------
step "PDFium-Herkunft"
chmod 644 "$out"/*
"$ROOT/tool/pdfium_provenance.sh" "$out"/*.zip "$out"/*.apk "$out"/*.tar.gz \
  > "$log/pdfium.log" 2>&1 || true
grep "stimmt" "$log/pdfium.log" || true
[ "$(grep -c "stimmt" "$log/pdfium.log")" -eq 6 ] ||
  fail "PDFium nicht in allen sechs Paketen bestätigt"

step "Prüfsummen"
(cd "$out" && shasum -a 256 PreppSuite-"$version"-* "GERAETETEST-v$version.txt" \
  > SHA256SUMS.txt)
cat "$out/SHA256SUMS.txt"

if ! $publish; then
  step "Fertig, nicht veröffentlicht"
  echo "Upload-Ordner: $out"
  exit 0
fi

# --- Publish --------------------------------------------------------------
step "Veröffentlichen"
[ -f "$out/RELEASE-TEXT-v$version.md" ] || fail "RELEASE-TEXT-v$version.md fehlt"
[ -n "${RELEASE_API:-}" ] && [ -n "${RELEASE_TOKEN:-}" ] ||
  fail "RELEASE_API und RELEASE_TOKEN setzen"
OUT="$out" VERSION="$version" python3 - <<'PY'
import glob, hashlib, json, os, urllib.parse, urllib.request

api, token = os.environ["RELEASE_API"], os.environ["RELEASE_TOKEN"]
out, version = os.environ["OUT"], os.environ["VERSION"]

def call(method, url, data=None, kind="application/json", raw=False):
    request = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "token " + token, "Content-Type": kind,
        "Accept": "application/json"})
    with urllib.request.urlopen(request, timeout=900) as response:
        body = response.read()
        return body if raw else json.loads(body or b"null")

text = open(f"{out}/RELEASE-TEXT-v{version}.md", encoding="utf-8").read()
release = call("POST", api + "/releases", json.dumps({
    "tag_name": f"v{version}", "name": f"PreppSuite {version}", "body": text,
    "draft": False, "prerelease": False}).encode())
print(release["html_url"])
files = sorted(glob.glob(f"{out}/PreppSuite-{version}-*"))
files += [f"{out}/GERAETETEST-v{version}.txt", f"{out}/SHA256SUMS.txt"]
for path in files:
    data = open(path, "rb").read()
    name = os.path.basename(path)
    asset = call("POST", f"{api}/releases/{release['id']}/assets?name="
                 + urllib.parse.quote(name), data, "application/octet-stream")
    back = call("GET", asset["browser_download_url"], raw=True)
    same = hashlib.sha256(back).digest() == hashlib.sha256(data).digest()
    print(" ", name, "ok" if same else "ABWEICHUNG")
    if not same:
        raise SystemExit(1)
PY
step "Veröffentlicht"
