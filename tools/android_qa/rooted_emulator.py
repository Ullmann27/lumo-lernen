"""Verify real root/boot readiness across the observed adbd restart disconnect.

AOSP documents that `adb root` restarts adbd:
https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/docs/dev/root.md
No external code is copied. Only the exact recorded rc1/closed response is
recoverable after root. Initial device-offline is recoverable only for the one
emulator already verified by the preceding probe, with a strict live inventory.
APK/gameplay checks still require an actual UID0 shell and boot1.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import time

ROOT_CLOSED = 'adb: unable to connect for root: closed'
ROOT_REFUSED = 'adbd cannot run as root in production builds'
INITIAL_OFFLINE = 'error: device offline'


def observed_root_disconnect(error: Exception, serial: str) -> bool:
    """The existing strict ADB wrapper preserves return code and full output."""
    expected = 'Command failed (1): ' + repr(('adb', '-s', serial, 'root')) + '\n' + ROOT_CLOSED
    return str(error).strip() == expected


def observed_initial_offline(error: Exception) -> bool:
    expected = "Command failed (1): ('adb', 'get-serialno')\n" + INITIAL_OFFLINE
    return str(error).strip() == expected


def ensure_rooted_emulator(adb, out: Path, *, timeout: float = 60,
                           previous_readiness: Path | None = None,
                           clock=time.monotonic, sleep=time.sleep) -> dict:
    if not 10 <= timeout <= 120:
        raise ValueError('Root readiness timeout must be between 10 and 120 seconds')
    began = clock()
    deadline = began + timeout
    state = {'status': 'RUNNING', 'attempts': [], 'root_transport_recovered': False,
             'initial_offline_recovered': False,
             'verification': 'actual shell id -u == 0 and sys.boot_completed == 1',
             'scope': 'disposable emulator setup; this does not pass installation or gameplay'}
    out.mkdir(parents=True, exist_ok=True)
    serial = None

    def save():
        (out / 'rooted-emulator.json').write_text(json.dumps(state, indent=2) + '\n')

    def run(*args, unbound=False):
        remaining = deadline - clock()
        if remaining <= 0:
            raise TimeoutError('Root/boot readiness deadline expired')
        commands = ('-s', serial, *args) if serial and not unbound else args
        record = {'arguments': list(commands), 'elapsed_seconds': round(clock() - began, 3)}
        try:
            output = adb(*commands, timeout=min(15, remaining))
            record.update(status='PASS', return_code=0, output=output)
            if clock() >= deadline:
                raise TimeoutError('Root/boot readiness command exceeded its total deadline')
            return output.strip()
        except Exception as error:
            record.update(status='FAIL', error=str(error))
            if args == ('root',) and observed_root_disconnect(error, serial):
                record.update(return_code=1, output=ROOT_CLOSED,
                              classification='exact observed adbd root-restart transport disconnect')
            elif args == ('get-serialno',) and serial is None and observed_initial_offline(error):
                record.update(return_code=1, output=INITIAL_OFFLINE,
                              classification='exact observed initial device-offline response; not readiness')
            raise
        finally:
            state['attempts'].append(record)
            save()

    def only_expected_transport(expected, *, ready=False):
        output = run('devices', unbound=True)
        lines = [line.strip() for line in output.splitlines() if line.strip()]
        if len(lines) != 2 or lines[0] != 'List of devices attached':
            raise RuntimeError('Initial offline bootstrap requires exactly one observed transport')
        fields = lines[1].split()
        if len(fields) != 2 or fields[0] != expected or fields[1] not in ('offline', 'device'):
            raise RuntimeError('Initial offline bootstrap transport differs from the previously verified emulator')
        if ready and fields[1] != 'device':
            raise RuntimeError('Known emulator remained offline after its bounded wait')
        state.setdefault('transport_inventories', []).append({'serial': fields[0], 'state': fields[1]})
        save()

    def prior_serial():
        raw = previous_readiness.read_bytes()
        retained = out / 'previous-rooted-emulator.json'
        retained.write_bytes(raw)
        state['previous_readiness'] = {'source_file': str(previous_readiness),
                                      'retained_file': retained.name, 'bytes': len(raw),
                                      'sha256': hashlib.sha256(raw).hexdigest()}
        save()

        def unique_object(pairs):
            value = {}
            for key, item in pairs:
                if key in value:
                    raise RuntimeError('Previous emulator readiness contains ambiguous duplicate keys')
                value[key] = item
            return value

        previous = json.loads(raw, object_pairs_hook=unique_object)
        expected = previous.get('serial') if isinstance(previous, dict) else None
        if (not isinstance(expected, str) or not re.fullmatch(r'emulator-\d+', expected) or
                previous.get('status') != 'PASS' or type(previous.get('shell_uid')) is not int or
                previous.get('shell_uid') != 0 or previous.get('boot_completed') is not True or
                previous.get('last_shell_uid') != '0' or previous.get('last_boot_completed') != '1'):
            raise RuntimeError('Previous probe must have verified one emulator with actual UID0 and boot1')
        return expected

    try:
        expected = prior_serial() if previous_readiness is not None else None
        try:
            serial = run('get-serialno')
        except RuntimeError as error:
            if expected is None or not observed_initial_offline(error):
                raise
            only_expected_transport(expected)
            serial = expected
            run('wait-for-device')
            if run('get-serialno') != expected:
                raise RuntimeError('Recovered emulator identity differs from the previously verified serial')
            only_expected_transport(expected, ready=True)
            state['initial_offline_recovered'] = True
        if not re.fullmatch(r'emulator-\d+', serial):
            raise RuntimeError('Required root setup is restricted to a disposable emulator')
        if expected is not None and serial != expected:
            raise RuntimeError('Initial emulator serial differs from the previously verified probe')
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
