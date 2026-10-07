#!/usr/bin/env bash
# Runs the device tests on the CI Android emulator, one file at a time
# (#121).
#
# The emulator on a hosted runner drops off adb now and then -- "device
# offline" while waiting for boot, "Service connection disposed" while a
# test loads -- and each time a different file fails. Nothing in the code
# changes between those runs. So every file waits for a device that has
# finished booting, and a file that fails is run once more after adb has
# been reconnected. A file that fails twice fails the job; that is a
# finding, not the emulator.
set -uo pipefail

device="${ANDROID_DEVICE:-emulator-5554}"

wait_for_device() {
  adb -s "$device" wait-for-device
  for _ in $(seq 1 60); do
    [ "$(adb -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && return 0
    sleep 2
  done
  return 1
}

failed=()
for test in integration_test/*_test.dart; do
  passed=false
  for attempt in 1 2; do
    if [ "$attempt" = 2 ]; then
      echo "::warning::$test failed on attempt 1, reconnecting adb and retrying"
      adb reconnect offline >/dev/null 2>&1 || true
      sleep 5
    fi
    wait_for_device || { echo "device $device not ready"; continue; }
    if flutter test --no-pub "$test" -d "$device"; then
      passed=true
      break
    fi
  done
  $passed || failed+=("$test")
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "::error::failed twice: ${failed[*]}"
  exit 1
fi
