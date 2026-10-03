#!/usr/bin/env python3
"""The device half of the release gate: run the native integration tests on
an iPhone simulator and write down that it happened.

    tool/release_device_check.py <release folder>

`tool/pre_release_check.sh` runs everything that needs no device. The four
tests in `preppsuite_flutter/integration_test/` check the Swift side of the
storage bridge, the photo vault, the archive reader and the web view --
nothing else notices if there is nobody on the other end of a channel. There
is no runner on Gitea to do this (#79), so it is done here, before a release,
and the folder gets a protocol that says so:

    GERAETETEST-v<version>.txt   summary, uploaded with the release
    geraetetest-v<version>.log   the full output, stays on this machine

The log stays because it carries absolute paths of this machine, which have
no business on a public release page. The summary carries none.

Only the simulator, never this Mac: `flutter test -d macos` would build and
start the app under its production identifier, next to the household's real
data. The simulator has its own container and nothing in it is anybody's.

Exits non-zero when a test failed, and writes the protocol either way: a
failed run is a fact about the release as well.
"""

import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "preppsuite_flutter"


def version():
    line = next(
        l for l in (APP / "pubspec.yaml").read_text().splitlines()
        if l.startswith("version:")
    )
    return line.split(":", 1)[1].strip().split("+")[0]


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def pick_simulator():
    inventory = json.loads(subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "--json"], text=True
    ))
    phones = [
        (runtime, device)
        for runtime, devices in inventory["devices"].items()
        if ".iOS-" in runtime
        for device in devices
        if device.get("isAvailable") and device["name"].startswith("iPhone")
    ]
    if not phones:
        sys.exit("Kein iPhone-Simulator verfügbar. In Xcode eine iOS-Laufzeit installieren.")
    booted = [p for p in phones if p[1]["state"] == "Booted"]
    runtime, device = (booted or phones)[0]
    ios = runtime.rsplit(".", 1)[-1].replace("iOS-", "iOS ").replace("-", ".")
    return device, ios


def flutter_version():
    out = subprocess.check_output(["flutter", "--version", "--machine"], cwd=APP, text=True)
    return json.loads(out[out.index("{"):]).get("frameworkVersion", "?")


# zstandard_ios copies its zstd sources in with a build phase and deletes
# them again in another ("Remove synced zstd"), so the next incremental
# build finds its inputs gone and fails -- every second build, exactly. A
# release build starts clean and never meets it; a run of four test files
# builds four times. Measured on 2026-10-03: files one and three failed with
# this message, two and four passed. One retry on exactly this message, and
# on nothing else.
_PLUGIN_RACE = "Build input file cannot be found"


def run_tests(udid, log_path):
    """Each test file on its own, so one retry costs one file."""
    code = 0
    with log_path.open("w") as log:
        for test in sorted((APP / "integration_test").glob("*_test.dart")):
            for attempt in (1, 2):
                result = subprocess.run(
                    ["flutter", "test", "--no-pub", "--reporter", "json",
                     str(test.relative_to(APP)), "-d", udid],
                    cwd=APP, capture_output=True, text=True,
                )
                output = result.stdout + result.stderr
                log.write(f"=== {test.name}, Versuch {attempt} ===\n{output}\n")
                if result.returncode == 0 or _PLUGIN_RACE not in output:
                    break
            code = code or result.returncode
    return code, log_path.read_text(errors="replace")


def summarise(output):
    """Each test with its outcome, from the JSON reporter's events.

    The reporter emits one JSON object per line: `testStart` names a test,
    `testDone` gives its result and whether it was skipped. Only the test
    file's own name and the test's name are taken over -- never a path,
    never a stack. Each file is judged by its last attempt, so a build the
    plugin broke and the retry fixed does not count twice.
    """
    attempts = {}
    for file, text in re.findall(
        r"^=== (\S+_test\.dart), Versuch \d ===\n(.*?)(?=^=== |\Z)",
        output, flags=re.M | re.S,
    ):
        attempts[file] = text  # the later attempt replaces the earlier
    seen = {}
    for file, text in attempts.items():
        names, done = {}, 0
        for line in text.splitlines():
            if not line.startswith("{"):
                continue
            try:
                event = json.loads(line)
            except ValueError:
                continue
            if event.get("type") == "testStart":
                test = event["test"]
                # Loading a file and the setUpAll/tearDownAll hooks are
                # reported as tests too; they are not what was checked.
                if test.get("url") is None and not test["name"].startswith("loading"):
                    continue
                if test["name"].startswith(("loading ", "(")):
                    continue
                names[test["id"]] = test["name"]
            elif event.get("type") == "testDone" and event["testID"] in names:
                done += 1
                name = f"{file}: {names[event['testID']]}"
                if event.get("skipped"):
                    seen[name] = "übersprungen"
                else:
                    seen[name] = "ok" if event["result"] == "success" else "FEHLER"
        if done == 0:
            seen[f"{file}: (ließ sich nicht starten)"] = "FEHLER"
    return seen


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    folder = Path(sys.argv[1]).expanduser()
    folder.mkdir(parents=True, exist_ok=True)
    v = version()

    device, ios = pick_simulator()
    udid = device["udid"]
    started_here = device["state"] != "Booted"
    try:
        if started_here:
            subprocess.run(["xcrun", "simctl", "boot", udid], check=True)
        subprocess.run(["xcrun", "simctl", "bootstatus", udid, "-b"],
                       check=True, stdout=subprocess.DEVNULL)
        code, output = run_tests(udid, folder / f"geraetetest-v{v}.log")
    finally:
        if started_here:
            subprocess.run(["xcrun", "simctl", "shutdown", udid], check=False)

    results = summarise(output)
    # Skipped is not failed: one archive test needs a real Kiwix file and
    # says so. It is listed, so nobody reads "all passed" as "all ran".
    passed = code == 0 and results and all(o != "FEHLER" for o in results.values())
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        f"PreppSuite {v} – Gerätetest",
        "",
        f"Ergebnis:   {'BESTANDEN' if passed else 'NICHT BESTANDEN'}",
        f"Zeitpunkt:  {stamp}",
        f"Stand:      {git('describe', '--tags', '--always', '--dirty')} ({git('rev-parse', 'HEAD')})",
        f"Gerät:      {device['name']}, {ios} (Simulator)",
        f"Flutter:    {flutter_version()}",
        f"Tests:      {sum(o == 'ok' for o in results.values())} bestanden, "
        f"{sum(o == 'übersprungen' for o in results.values())} übersprungen, "
        f"{sum(o == 'FEHLER' for o in results.values())} fehlgeschlagen",
        "",
        "Geprüft werden die nativen Kanäle, die kein Unit-Test erreicht:",
        "Speicherbrücke, Foto-Tresor, Archivleser und Artikelansicht",
        "(preppsuite_flutter/integration_test/).",
        "",
    ] + [f"  [{o}] {name}" for name, o in results.items()]
    protocol = folder / f"GERAETETEST-v{v}.txt"
    protocol.write_text("\n".join(lines) + "\n")
    print(protocol.read_text())
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
