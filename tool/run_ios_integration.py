#!/usr/bin/env python3
"""Run mobile integration tests on an available iPhone simulator.

One file at a time, under a watchdog (#165). On the hosted macOS runners
`flutter test` now and then stopped right after "Xcode build done." and
stayed silent until the job's time limit cut it off, an hour later: the
simulator never finished installing or starting the app, and the tool
waits on `simctl install` and `simctl launch` with no timeout of its own.
A `simctl` was still running when the runner cleaned up. Of four such
runs, two hung on the first file, one on the second and one on the third,
and the same code passed on the next push.

A passing file prints its next line at most two minutes after its build
on those runners (1.9 was the longest, measured over four runs in October
2026). So eight minutes of silence after the build is a stuck simulator,
not a slow test: the run is stopped, the simulator is shut down and booted
again, and the file runs once more. A file that fails, or hangs twice,
fails the job; that is a finding, not the runner. A failure is not
retried -- only the hang has been seen to be the runner's.
"""

import json
import os
from pathlib import Path
import queue
import signal
import subprocess
import sys
import threading
import time

APP = Path(__file__).resolve().parents[1] / "preppsuite_flutter"
ON_CI = os.environ.get("GITHUB_ACTIONS") == "true"

SILENCE_AFTER_BUILD = 8 * 60
# Covers the build too. The first file builds from scratch, which took up
# to ten minutes on a slow runner; a later file takes two or three.
ATTEMPT_LIMIT = 30 * 60


def note(message, level="warning"):
    print(f"::{level}::{message}" if ON_CI else message, flush=True)


def pick_phone():
    inventory = json.loads(subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "--json"], text=True
    ))
    phones = [
        device
        for runtime, devices in inventory["devices"].items()
        if ".iOS-" in runtime
        for device in devices
        if device.get("isAvailable") and device["name"].startswith("iPhone")
    ]
    if not phones:
        sys.exit("No available iPhone simulator. Install an iOS runtime in Xcode.")
    return next((phone for phone in phones if phone["state"] == "Booted"), phones[0])


def boot(udid):
    """Boots the simulator if it is not running and waits until it is up."""
    subprocess.run(["xcrun", "simctl", "bootstatus", udid, "-b"], check=True,
                   stdout=subprocess.DEVNULL, timeout=15 * 60)


def shutdown(udid):
    try:
        subprocess.run(["xcrun", "simctl", "shutdown", udid], check=False,
                       timeout=120)
    except subprocess.TimeoutExpired:
        note(f"simulator {udid} did not shut down within two minutes")


def restart(udid):
    shutdown(udid)
    if ON_CI:
        # What hung is the service behind every simulator. On a runner that
        # is thrown away afterwards it can simply go; launchd starts it
        # again with the next simctl call. Never on a desk, where other
        # simulators may be in use.
        subprocess.run(["killall", "-9", "com.apple.CoreSimulator.CoreSimulatorService"],
                       check=False, stderr=subprocess.DEVNULL)
    boot(udid)


def flutter_test(test, udid):
    return ["flutter", "test", "--no-pub", str(test.relative_to(APP)), "-d", udid]


def stop(process):
    """Ends flutter and everything it started, the stuck simctl included."""
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=20)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        pass
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()


def run_file(test, udid):
    """The file's exit code, or None when it hung."""
    process = subprocess.Popen(
        flutter_test(test, udid), cwd=APP, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, start_new_session=True,
    )
    lines = queue.Queue()

    def pump():
        for line in process.stdout:
            lines.put(line)
        lines.put(None)

    threading.Thread(target=pump, daemon=True).start()
    started = time.monotonic()
    built = False
    while True:
        wait = ATTEMPT_LIMIT - (time.monotonic() - started)
        if built:
            wait = min(wait, SILENCE_AFTER_BUILD)
        try:
            line = lines.get(timeout=max(wait, 0))
        except queue.Empty:
            stop(process)
            return None
        if line is None:
            return process.wait()
        sys.stdout.buffer.write(line)
        sys.stdout.buffer.flush()
        if line.startswith(b"Xcode build done"):
            built = True


def main():
    device = pick_phone()
    udid = device["udid"]
    started_here = device["state"] != "Booted"
    failed = []
    try:
        boot(udid)
        for test in sorted((APP / "integration_test").glob("*_test.dart")):
            for attempt in (1, 2):
                code = run_file(test, udid)
                if code is not None:
                    break
                note(f"{test.name} stopped answering (attempt {attempt}), "
                     "restarting the simulator")
                # Shutting down a simulator somebody else booted is not this
                # script's call; then the retry has to do without.
                if started_here:
                    restart(udid)
            if code is None:
                failed.append(f"{test.name} (hung twice)")
            elif code != 0:
                failed.append(test.name)
    finally:
        if started_here:
            shutdown(udid)
    if failed:
        note("failed: " + ", ".join(failed), level="error")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
