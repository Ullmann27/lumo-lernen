"""Verify real root/boot readiness across the observed adbd restart disconnect.

AOSP documents that `adb root` restarts adbd:
https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/docs/dev/root.md
No external code is copied. Only the exact recorded rc1/closed response is
recoverable; APK/gameplay checks still require an actual UID0 shell and boot1.
"""
from __future__ import annotations

import json
from pathlib import Path
import re
import time

ROOT_CLOSED = 'adb: unable to connect for root: closed'
ROOT_REFUSED = 'adbd cannot run as root in production builds'


def observed_root_disconnect(error: Exception, serial: str) -> bool:
    """The existing strict ADB wrapper preserves return code and full output."""
    expected = 'Command failed (1): ' + repr(('adb', '-s', serial, 'root')) + '\n' + ROOT_CLOSED
    return str(error).strip() == expected


def ensure_rooted_emulator(adb, out: Path, *, timeout: float = 60,
                           clock=time.monotonic, sleep=time.sleep) -> dict:
    if not 10 <= timeout <= 120:
        raise ValueError('Root readiness timeout must be between 10 and 120 seconds')
    began = clock()
    deadline = began + timeout
    state = {'status': 'RUNNING', 'attempts': [], 'root_transport_recovered': False,
             'verification': 'actual shell id -u == 0 and sys.boot_completed == 1',
             'scope': 'disposable emulator setup; this does not pass installation or gameplay'}
    out.mkdir(parents=True, exist_ok=True)
    serial = None

    def save():
        (out / 'rooted-emulator.json').write_text(json.dumps(state, indent=2) + '\n')

    def run(*args):
        remaining = deadline - clock()
        if remaining <= 0:
            raise TimeoutError('Root/boot readiness deadline expired')
        commands = ('-s', serial, *args) if serial else args
        record = {'arguments': list(commands), 'elapsed_seconds': round(clock() - began, 3)}
        try:
            output = adb(*commands, timeout=min(15, remaining))
            record.update(status='PASS', return_code=0, output=output)
            return output.strip()
        except Exception as error:
            record.update(status='FAIL', error=str(error))
            if args == ('root',) and observed_root_disconnect(error, serial):
                record.update(return_code=1, output=ROOT_CLOSED,
                              classification='exact observed adbd root-restart transport disconnect')
            raise
        finally:
            state['attempts'].append(record)
            save()

    try:
        serial = run('get-serialno')
        if not re.fullmatch(r'emulator-\d+', serial):
            raise RuntimeError('Required root setup is restricted to a disposable emulator')
        state['serial'] = serial
        try:
            root_output = run('root')
        except RuntimeError as error:
            if not observed_root_disconnect(error, serial):
                raise
            state['root_transport_recovered'] = True
        else:
            if ROOT_REFUSED in root_output:
                raise RuntimeError('Emulator image explicitly refuses the required adb root')
        # One root request only. The accepted restart may disconnect its caller;
        # reconnect to the same serial and independently prove the new shell.
        run('wait-for-device')
        while clock() < deadline:
            uid = run('shell', 'id', '-u')
            boot = run('shell', 'getprop', 'sys.boot_completed')
            if uid not in ('0', '2000') or boot not in ('', '0', '1'):
                raise RuntimeError('Malformed actual root UID or boot-completed response')
            state.update(last_shell_uid=uid, last_boot_completed=boot)
            if uid == '0' and boot == '1':
                state.update(status='PASS', shell_uid=0, boot_completed=True,
                             elapsed_seconds=round(clock() - began, 3))
                return state
            sleep(min(.5, max(0, deadline - clock())))
        raise TimeoutError('Required root UID0 and boot1 were not both verified before the deadline')
    except Exception as error:
        state.update(status='FAIL', error=str(error), elapsed_seconds=round(clock() - began, 3))
        raise
    finally:
        save()
