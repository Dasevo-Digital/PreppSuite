#!/usr/bin/env bash
# Builds every package of one release and checks it, in one run (#125).
#
#   tool/release.sh 2.4.6             build, test and checksum
#   tool/release.sh 2.4.6 --publish   … and create the release and upload
#   tool/release.sh 2.4.6 --publish-only   publish a folder built before
#   tool/release.sh 2.4.6 --resume    pick up a run that stopped while
#                                     waiting for Linux: the Mac, Android
#                                     and device-check results in the
#                                     upload folder are kept, the Linux
#                                     machine's run is waited for again
#
# Before it: the version is raised in pubspec.yaml, committed, tagged
# v<version> and pushed -- this script builds what the tag says and refuses
# a working tree that differs from it. The release text is written by hand
# into RELEASE-TEXT-v<version>.md in the upload folder; --publish takes it
# from there. The text names the device check's result, which only exists
# once the build has run -- so the usual order is a build without
# --publish, then the text, then --publish-only, which builds nothing and
# publishes what the folder holds after checking it against SHA256SUMS.txt.
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
# runs the device check in the iPhone simulator. Linux and Windows each
# run the start test (integration_test/app_start_test.dart) after their
# build, and a release whose start test did not pass is not published. The Windows build needs
# the translator DLL the Linux machine cross-compiles, so it comes last.
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP_DIR="$ROOT/preppsuite_flutter"

version="${1:-}"
publish=false
publish_only=false
resume=false
usage="Usage: $0 <version> [--publish|--publish-only|--resume]"
case "${2:-}" in
  "") ;;
  --publish) publish=true ;;
  --publish-only) publish=true publish_only=true ;;
  --resume) resume=true ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "$usage" >&2
  exit 2
}

linux="${RELEASE_LINUX_HOST:-TestKubuntu}"
windows="${RELEASE_WINDOWS_HOST:-TestWindows}"
out="${RELEASE_DIR:-$HOME/Desktop/PreppSuite-Release-v$version-Upload}"
tag="v$version"
log="$(mktemp -d)"

step() { printf '\n== %s ==\n' "$*"; }
fail() { echo "FEHLER: $*" >&2; echo "Protokolle: $log" >&2; exit 1; }

# --- Publish ----------------------------------------------------------------
publish_release() {
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
}

if $publish_only; then
  [ -f "$out/SHA256SUMS.txt" ] || fail "$out/SHA256SUMS.txt fehlt – erst bauen"
  (cd "$out" && shasum -a 256 -c SHA256SUMS.txt) || fail "Prüfsummen stimmen nicht"
  publish_release
  exit 0
fi

# --- What is being built -------------------------------------------------
cd "$ROOT"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "Tag $tag fehlt"
# A resumed run builds nothing more on this Mac; what it still sends out
# is the tag's own archive, whatever is checked out now.
if ! $resume; then
  [ "$(git rev-parse HEAD)" = "$(git rev-list -n 1 "$tag")" ] ||
    fail "HEAD ist nicht $tag – erst auschecken"
  [ -z "$(git status --porcelain -- preppsuite_flutter)" ] ||
    fail "Arbeitsverzeichnis nicht sauber"
fi
line="$(git show "$tag:preppsuite_flutter/pubspec.yaml" | sed -n 's/^version:[[:space:]]*//p' | head -1)"
[ "${line%%+*}" = "$version" ] || fail "pubspec.yaml sagt $line, nicht $version"
build="${line#*+}"
[[ "$build" =~ ^[0-9]+$ ]] || fail "ungültige Build-Nummer in pubspec.yaml"

mkdir -p "$out"
archive="$log/src-$version.tar.gz"
git archive --format=tar.gz --prefix=src/ -o "$archive" "$tag"

remote_linux="preppsuite-release/$version"
if $resume; then
  for kept in "PreppSuite-$version-macos-local-ad-hoc.zip" \
    "PreppSuite-$version-Android-arm64-v8a.apk" \
    "PreppSuite-$version-Android-armeabi-v7a.apk" "GERAETETEST-v$version.txt"; do
    [ -f "$out/$kept" ] || fail "$kept fehlt – ohne --resume neu bauen"
  done
  grep -qE '^Ergebnis:[[:space:]]+BESTANDEN$' "$out/GERAETETEST-v$version.txt" ||
    fail "Gerätetest im Upload-Ordner nicht bestanden"
  ssh "$linux" "test -f ~/$remote_linux/build.log" ||
    fail "kein Linux-Lauf für $version auf $linux – ohne --resume neu bauen"
  step "Fortsetzen: Mac, Android und Gerätetest liegen schon vor"
else
# --- Linux, in the background -------------------------------------------
step "Linux auf $linux starten"
ssh "$linux" "rm -rf ~/$remote_linux && mkdir -p ~/$remote_linux"
scp -q "$archive" "$linux:$remote_linux/src.tar.gz"
scp -q "$ROOT/tool/linux_release.sh" "$linux:$remote_linux/linux_release.sh"
ssh "$linux" "cd ~/$remote_linux && tar xzf src.tar.gz && \
  (nohup bash linux_release.sh \$HOME/$remote_linux $version $build \
   > build.log 2>&1 < /dev/null &)"

# --- macOS ----------------------------------------------------------------
step "macOS"
app="$APP_DIR/build/macos/Build/Products/Release/PreppSuite.app"
# The translator library first: the Xcode build only copies it, and skips
# it with a warning when it is missing. Incremental, so a run with nothing
# changed takes a second.
"$APP_DIR/native/translate/build_macos.sh" > "$log/translate.log" 2>&1 ||
  fail "Übersetzer-Bibliothek"
(cd "$APP_DIR" && flutter build macos --release --build-name "$version" \
  --build-number "$build") > "$log/macos.log" 2>&1 || fail "macOS-Build"
[ -f "$app/Contents/Frameworks/libpreppsuite_translate.dylib" ] ||
  fail "Mac-Paket ohne Übersetzer-Bibliothek"
"$ROOT/tool/macos_sign.sh" "$app" --allow-ad-hoc > "$log/sign.log" 2>&1 ||
  fail "macOS-Signatur"
codesign --verify --deep --strict "$app" || fail "Signatur ungültig"
[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$app/Contents/Info.plist")" = "$version" ] || fail "falsche Version im Mac-Paket"
ditto -c -k --keepParent "$app" "$out/PreppSuite-$version-macos-local-ad-hoc.zip"
rm -rf "$app"

# --- Android --------------------------------------------------------------
step "Android"
# The translator for arm64 first; Gradle picks it up when it is there
# (#185). 32-bit ARM gets none: the engine's ARM kernels are AArch64 only.
"$APP_DIR/native/translate/build_android.sh" > "$log/translate-android.log" 2>&1 ||
  fail "Übersetzer für Android"
"$ROOT/tool/android_release.sh" > "$log/android.log" 2>&1 || fail "Android-Build"
apks="$APP_DIR/build/app/outputs/flutter-apk"
cp "$apks/app-arm64-v8a-release-rotated.apk" "$out/PreppSuite-$version-Android-arm64-v8a.apk"
cp "$apks/app-armeabi-v7a-release-rotated.apk" "$out/PreppSuite-$version-Android-armeabi-v7a.apk"
# Listed into a file, not piped into grep -q: under pipefail the early
# close of the pipe fails unzip, and with it the check.
unzip -l "$out/PreppSuite-$version-Android-arm64-v8a.apk" > "$log/apk-arm64.txt"
grep -q 'lib/arm64-v8a/libpreppsuite_translate.so' "$log/apk-arm64.txt" ||
  fail "arm64-APK ohne Übersetzer-Bibliothek"
# The shrunk package, started once on the project's emulator (#206):
# 2.6.0 and 2.6.1 opened on "the household cannot be loaded", and nothing
# before this ran a release build. Never a phone.
step "Android-Start auf dem Emulator"
"$ROOT/tool/android_start_check.sh" "$out/PreppSuite-$version-Android-arm64-v8a.apk" \
  > "$log/android-start.log" 2>&1 || {
  tail -3 "$log/android-start.log"
  fail "Android-Paket startet nicht"
}
tail -1 "$log/android-start.log"

# --- Device check in the iPhone simulator ---------------------------------
step "Gerätetest im iPhone-Simulator"
python3 "$ROOT/tool/release_device_check.py" "$out" > "$log/device.log" 2>&1 || true
grep -E "Ergebnis|Stand|Tests:" "$log/device.log" || true
# The result line itself: "NICHT BESTANDEN" contains "BESTANDEN", and a
# plain grep let 2.5.8's first, failed device check through.
grep -qE '^Ergebnis:[[:space:]]+BESTANDEN$' "$log/device.log" ||
  fail "Gerätetest nicht bestanden"
# Bundles under build/ show up in Spotlight and can open the real data.
find "$APP_DIR/build" \( -name '*.app' -o -name '*.appex' \) -prune -exec rm -rf {} +
fi

# --- Linux result ---------------------------------------------------------
step "Auf Linux warten"
# Two hours: since the translator (#184) the Linux machine also compiles
# Mozilla's engine twice, for Linux and for Windows.
keyring_told=false
for _ in $(seq 1 720); do
  ssh "$linux" "grep -q ALLES-FERTIG ~/$remote_linux/build.log" && break
  # The start test reads the desktop keyring, which waits for somebody to
  # unlock it; linux_release.sh says so in its log rather than hanging.
  if ! $keyring_told &&
    ssh "$linux" "grep -q SCHLUESSELBUND-GESPERRT ~/$remote_linux/build.log"; then
    echo "Linux wartet: Schlüsselbund auf $linux am Desktop entsperren."
    keyring_told=true
  fi
  sleep 10
done
ssh "$linux" "grep -q ALLES-FERTIG ~/$remote_linux/build.log" ||
  fail "Linux-Build nicht fertig, siehe ~/$remote_linux/build.log"
ssh "$linux" "grep -q 'STARTTEST: BESTANDEN' ~/$remote_linux/build.log" ||
  fail "Starttest unter Linux nicht bestanden, siehe ~/$remote_linux/build.log"
ssh "$linux" "grep -q 'lib/libpdfium.so' ~/$remote_linux/inhalt.txt" ||
  fail "Linux-Paket ohne PDFium"
ssh "$linux" "grep -q 'lib/libpreppsuite_translate.so' ~/$remote_linux/inhalt.txt" ||
  fail "Linux-Paket ohne Übersetzer-Bibliothek, siehe ~/$remote_linux/translate-linux.log"
scp -q "$linux:$remote_linux/PreppSuite-$version-linux-x64.tar.gz" "$out/"
scp -q "$linux:$remote_linux/src/preppsuite_flutter/native/translate/build/preppsuite_translate.dll" \
  "$log/preppsuite_translate.dll" ||
  fail "Übersetzer-DLL fehlt, siehe ~/$remote_linux/translate-win.log"

# --- Windows --------------------------------------------------------------
step "Windows auf $windows"
win="C:/src/preppsuite-release/$version"
winback="C:\\src\\preppsuite-release\\$version"
ssh "$windows" "cmd /c \"if exist $winback rmdir /s /q $winback\"" || true
ssh "$windows" "cmd /c \"mkdir $winback\""
scp -q "$archive" "$windows:$win/src.tar.gz"
ssh "$windows" "cmd /c \"cd /d $winback && tar -xzf src.tar.gz && \
  mkdir src\\preppsuite_flutter\\native\\translate\\build\""
scp -q "$log/preppsuite_translate.dll" \
  "$windows:$win/src/preppsuite_flutter/native/translate/build/preppsuite_translate.dll"
scp -q "$ROOT/tool/windows_build.ps1" "$windows:$win/windows_build.ps1"
ssh "$windows" "powershell -NoProfile -ExecutionPolicy Bypass -File \
  $winback\\windows_build.ps1 -Work $winback -Version $version \
  -BuildNumber $build" > "$log/windows.log" 2>&1 ||
  fail "Windows-Build, siehe $log/windows.log"
grep -q "== FERTIG ==" "$log/windows.log" || fail "Windows-Build unvollständig"
grep -q "STARTTEST: BESTANDEN" "$log/windows.log" ||
  fail "Starttest unter Windows nicht bestanden, siehe $log/windows.log"
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

publish_release
