#!/usr/bin/env python3
"""
predator-button — Daemon that maps the PredatorSense physical button
to toggle between turbo/balanced modes on Linux.

The button generates EV_KEY code 425 (KEY_PRESENTATION, scan 0xF5)
on the internal AT keyboard (bustype 0x11 / i8042).
"""
import evdev
from evdev import InputDevice, ecodes
import subprocess
import sys
import os

SCRIPT = '/usr/local/bin/predator-mode'
KEY_PREDATORSENSE = 425  # KEY_PRESENTATION — scan code 0xF5


def find_predator_device():
    """Find the internal AT keyboard that generates the PredatorSense button event."""
    for path in evdev.list_devices():
        try:
            dev = InputDevice(path)
            # bustype 0x11 = PS/2 (i8042) — internal laptop keyboard only
            if dev.info.bustype == 0x11 and 'AT Translated' in dev.name:
                caps = dev.capabilities()
                if ecodes.EV_KEY in caps and KEY_PREDATORSENSE in caps[ecodes.EV_KEY]:
                    print(f"Found: {dev.name} ({path})")
                    return dev
        except Exception:
            continue
    return None


def main():
    if os.geteuid() != 0:
        print("Must run as root.")
        sys.exit(1)

    dev = find_predator_device()
    if dev is None:
        print("Device not found by search — falling back to /dev/input/event2")
        try:
            dev = InputDevice('/dev/input/event2')
        except Exception as e:
            print(f"ERROR: {e}")
            sys.exit(1)

    print(f"Monitoring: {dev.name} ({dev.path})")
    print(f"Waiting for KEY_PRESENTATION (code {KEY_PREDATORSENSE})...", flush=True)

    for event in dev.read_loop():
        if (event.type == ecodes.EV_KEY
                and event.code == KEY_PREDATORSENSE
                and event.value == 1):  # 1=press, 0=release, 2=repeat
            print("PredatorSense button pressed — toggling mode...", flush=True)
            try:
                result = subprocess.run(
                    ['bash', SCRIPT, 'toggle'],
                    capture_output=True, text=True, timeout=10
                )
                print(result.stdout.strip(), flush=True)
                if result.returncode != 0:
                    print(f"Error: {result.stderr.strip()}", file=sys.stderr, flush=True)
            except subprocess.TimeoutExpired:
                print("Timeout executing mode script", file=sys.stderr)
            except Exception as e:
                print(f"Error: {e}", file=sys.stderr)


if __name__ == '__main__':
    main()
