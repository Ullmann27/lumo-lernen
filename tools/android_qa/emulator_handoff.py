"""Bounded readiness between two probes on the same verified disposable emulator.

The recorded APK1903 API35 failure was `adb get-serialno` rc1/device offline.
AOSP documents reconnect offline and wait-for-device independently of boot:
https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/docs/user/adb.1.md
No installation, app launch, root request, reboot, save or gameplay is performed.
"""
from __future__ import annotations

import json
from pathlib import Path
import re
import time


OFFLINE_ERROR = "Command failed (1): ('adb', 'get-serialno')\nerror: device offline"


def ensure_emulator_handoff(adb, out: Path, previous: dict, expected: dict, *,
                            timeout: float = 60, clock=time.monotonic,
                            sleep=time.sleep) -> dict:
    if not 10 <= timeout <= 120:
        raise ValueError('Handoff readiness timeout must be between 10 and 120 seconds')
    began, state = clock(), {'status': 'RUNNING', 'attempts': [],
                            'observed_offline': False, 'offline_reconnects': 0,
                            'scope': 'same disposable emulator transport/boot only; gameplay remains untested'}
    deadline = began + timeout
    out.mkdir(parents=True, exist_ok=True)

    def save():
        (out / 'emulator-handoff.json').write_text(json.dumps(state, indent=2) + '\n')

    def run(*args, wait=False):
        remaining = deadline - clock()
        if remaining <= 0:
            raise TimeoutError('Same-emulator handoff readiness deadline expired')
        record = {'arguments': list(args), 'elapsed_seconds': round(clock()-began, 3)}
        try:
            output = adb(*args, timeout=min(remaining, 60 if wait else 15)).strip()
            record.update(status='PASS', output=output)
            return output
        except Exception as error:
            record.update(status='FAIL', error=str(error))
            raise
        finally:
            state['attempts'].append(record)
            save()

    def inventory(serial):
        lines = run('devices', '-l').splitlines()
        if not lines or lines[0].strip() != 'List of devices attached':
            raise RuntimeError('Malformed actual ADB device inventory')
        rows = [line.split() for line in lines[1:] if line.strip()]
        if len(rows) != 1 or len(rows[0]) < 2 or rows[0][0] != serial:
            raise RuntimeError('Handoff requires exactly the previously verified emulator')
        device_state = rows[0][1]
        if device_state not in ('device', 'offline'):
            raise RuntimeError('Unauthorised or unexpected emulator state cannot be recovered')
        return device_state

    try:
        root = previous.get('emulator_root_readiness', {})
        serial = root.get('serial', '')
        if (previous.get('status') != 'PASS' or root.get('status') != 'PASS' or
                not re.fullmatch(r'emulator-\d+', serial) or
                type(root.get('shell_uid')) is not int or root.get('shell_uid') != 0 or
                root.get('boot_completed') is not True or
                any(previous.get(key) != value for key, value in expected.items())):
            raise RuntimeError('Prior successful probe identity/provenance is required for handoff')
        state['serial'] = serial
        try:
            observed = run('get-serialno')
        except RuntimeError as error:
            if str(error).strip() != OFFLINE_ERROR:
                raise
            state['observed_offline'] = True
            observed = serial
        if observed != serial:
            raise RuntimeError('Actual emulator serial changed between probes')
        current = inventory(serial)
        if current == 'offline':
            if not state['observed_offline']:
                raise RuntimeError('Offline transition differs from the recorded handoff failure')
            # ADB reconnect offline is global; permit it only with one exact
            # previously observed emulator and no other attached device.
            run('reconnect', 'offline')
            state['offline_reconnects'] = 1
        run('-s', serial, 'wait-for-device', wait=True)
        if run('-s', serial, 'get-serialno') != serial or run('-s', serial, 'get-state') != 'device':
            raise RuntimeError('Same online emulator was not independently verified')
        while clock() < deadline:
            uid = run('-s', serial, 'shell', 'id', '-u')
            boot = run('-s', serial, 'shell', 'getprop', 'sys.boot_completed')
            state.update(last_shell_uid=uid, last_boot_completed=boot)
            if uid != '0' or boot not in ('', '0', '1'):
                raise RuntimeError('Actual root UID or boot-completed response differs from the prior emulator')
            if boot == '1':
                break
            sleep(min(.5, max(0, deadline-clock())))
        else:
            raise TimeoutError('Actual emulator boot did not complete before the handoff deadline')
        sdk = run('-s', serial, 'shell', 'getprop', 'ro.build.version.sdk')
        if not sdk.isdigit() or int(sdk) != expected['android_sdk'] or inventory(serial) != 'device':
            raise RuntimeError('Actual Android API or final unique emulator inventory changed')
        state.update(status='PASS', shell_uid=0, boot_completed=True, android_sdk=int(sdk),
                     elapsed_seconds=round(clock()-began, 3))
        return state
    except Exception as error:
        state.update(status='FAIL', error=str(error), elapsed_seconds=round(clock()-began, 3))
        raise
    finally:
        save()
