#!/usr/bin/env python3
"""Run mobile integration tests on an available iPhone simulator."""

import json
from pathlib import Path
import subprocess
import sys


def main():
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
    device = next((phone for phone in phones if phone["state"] == "Booted"), phones[0])
    udid = device["udid"]
    started_here = device["state"] != "Booted"
    try:
        if started_here:
            subprocess.run(["xcrun", "simctl", "boot", udid], check=True)
        subprocess.run(["xcrun", "simctl", "bootstatus", udid, "-b"], check=True)
        result = subprocess.run(
            ["flutter", "test", "--no-pub", "integration_test/", "-d", udid],
            cwd=Path(__file__).resolve().parents[1] / "preppsuite_flutter",
        )
        return result.returncode
    finally:
        if started_here:
            subprocess.run(["xcrun", "simctl", "shutdown", udid], check=True)


if __name__ == "__main__":
    sys.exit(main())
