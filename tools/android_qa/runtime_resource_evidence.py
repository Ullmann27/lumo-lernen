"""Read-only native-process snapshots; never infer FPS/GPU time from them.

Formats: https://www.kernel.org/doc/html/latest/filesystems/proc.html
https://developer.android.com/tools/dumpsys#meminfo . No external code copied.
"""
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import time

PROCESS = 'dev.ullmann.lumo.lumo_lernen.coachpreview:lumo_game'


def parse_proc_stat(raw, pid):
    match = re.fullmatch(r'(\d+) \(([^\n]+)\) (\S.*)', raw.strip())
    if not match or match[1] != str(pid):
        raise ValueError('Native /proc/stat PID or format differs')
    fields = match[3].split()  # field 3 onward; comm can contain spaces/parentheses.
    keys = {'user_cpu_ticks': 11, 'system_cpu_ticks': 12,
            'process_start_ticks': 19, 'rss_pages': 21}
    if len(fields) < 22 or fields[0] not in tuple('RSDZTWtXxKWPI'):
        raise ValueError('Native /proc/stat is truncated or has invalid state')
    if any(not re.fullmatch(r'\d+', fields[i]) for i in keys.values()):
        raise ValueError('Native /proc/stat resource field is malformed')
    return {key: int(fields[i]) for key, i in keys.items()}


def parse_meminfo(raw, pid):
    header = rf'\*\* MEMINFO in pid {pid} \[{re.escape(PROCESS)}\] \*\*'
    if len(re.findall(header, raw)) != 1:
        raise ValueError('meminfo does not identify exactly this native process')
    result = {}
    for key, caption in (('pss_kib', 'TOTAL PSS'), ('rss_kib', 'TOTAL RSS')):
        values = re.findall(r'\b' + caption + r':\s*(\S+)', raw)
        if len(values) > 1 or any(not re.fullmatch(r'\d+', x) for x in values):
            raise ValueError('Malformed or ambiguous meminfo ' + caption)
        result[key] = int(values[0]) if values else None
    if result['pss_kib'] is None:
        totals = re.findall(r'^\s*TOTAL\s+(\d+)(?:\s+\d+){3,}\s*$', raw, re.M)
        if len(totals) != 1 or not re.search(r'\bPss\b', raw) or not re.search(r'\bTotal\b', raw):
            raise ValueError('Unrecognized meminfo PSS totals')
        result['pss_kib'] = int(totals[0])
    result['rss_kib_status'] = 'PASS' if result['rss_kib'] is not None else 'UNAVAILABLE'
    return result


def capture_resources(adb, out: Path, label: str, identity: dict, readiness: dict,
                      *, timeout=20, clock=time.monotonic):
    """Three reads within one budget, bound to the already verified emulator."""
    state = {'status': 'FAIL', 'identity': dict(identity), 'phase': label, 'reads': [],
             'scope': 'Emulator native CPU counters/memory snapshot only; hardware/GPU/FPS NOT EXECUTED',
             'cpu_ticks_per_second': None, 'page_size_bytes': None,
             'conversion_status': 'UNAVAILABLE: no OS Hz/page-size value captured'}
    began = clock()
    serial = readiness.get('serial')

    def read(name, command, cap):
        remaining = timeout - (clock() - began)
        if remaining <= 0:
            raise TimeoutError('Resource snapshot shared deadline expired')
        row = {'name': name, 'arguments': ['-s', serial, *command],
               'started_utc': datetime.now(timezone.utc).isoformat()}
        state['reads'].append(row)
        try:
            row['raw'] = adb(*row['arguments'], timeout=min(cap, remaining))
            if clock() - began >= timeout:
                raise TimeoutError('Resource read exceeded shared deadline')
            return row['raw']
        except Exception as error:
            row['error'] = str(error)
            raise
        finally:
            row['finished_utc'] = datetime.now(timezone.utc).isoformat()

    try:
        if type(timeout) not in (int, float) or not 0 < timeout <= 20 or not re.fullmatch(r'[a-z0-9_-]+', label):
            raise ValueError('Resource phase or deadline invalid')
        if (readiness.get('status') != 'PASS' or type(readiness.get('shell_uid')) is not int
                or readiness['shell_uid'] != 0 or readiness.get('boot_completed') is not True
                or not isinstance(serial, str) or not re.fullmatch(r'emulator-\d+', serial)
                or identity.get('serial') != serial or type(identity.get('android_sdk')) is not int
                or identity['android_sdk'] < 24 or not all(re.fullmatch(pattern, identity.get(key, ''))
                for key, pattern in [('source', r'[0-9a-f]{40}'), ('godot', r'[0-9a-f]{40}'),
                                     ('apk_sha256', r'[0-9a-f]{64}')])):
            raise ValueError('Resource snapshot requires prior verified emulator/provenance')
        pid = read('pid', ['shell', 'pidof', PROCESS], 5).strip()
        if not re.fullmatch(r'[1-9]\d*', pid):
            raise ValueError('Exactly one actual native PID required')
        state['pid'] = int(pid)
        state.update(parse_proc_stat(read('proc_stat', ['shell', 'cat', f'/proc/{pid}/stat'], 5), pid))
        state.update(parse_meminfo(read('meminfo', ['shell', 'dumpsys', 'meminfo', pid], 10), pid))
        state['status'] = 'PASS'
    except Exception as error:
        state['error'] = str(error)
    state['elapsed_seconds'] = round(clock() - began, 6)
    out.mkdir(parents=True, exist_ok=True)
    safe_label = label if isinstance(label, str) and re.fullmatch(r'[a-z0-9_-]+', label) else 'invalid-phase'
    (out / ('resources-' + safe_label + '.json')).write_text(json.dumps(state, indent=2) + '\n')
    return state
