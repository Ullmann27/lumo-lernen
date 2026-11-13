#!/usr/bin/env python3
"""Read-only, source-bound Android diagnostics. Never a native FPS approval.

Uses the existing strict /proc and native meminfo parsers, but deliberately not
the emulator/root/install orchestration. Only Python's standard library is used.
"""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess
import time
import zipfile

if __package__:
    from .runtime_resource_evidence import PROCESS, parse_meminfo, parse_proc_stat
else:
    from runtime_resource_evidence import PROCESS, parse_meminfo, parse_proc_stat

PACKAGE = PROCESS.removesuffix(':lumo_game')
CERTIFICATE = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
PROPERTIES = ('ro.product.manufacturer', 'ro.product.model', 'ro.build.version.sdk',
              'ro.build.version.release', 'ro.build.fingerprint',
              'ro.product.cpu.abilist', 'ro.kernel.qemu')
MAX_PARSE_BYTES = 8 * 1024 * 1024
UNAVAILABLE = re.compile(r"(?im)^(?:Error:|Permission Denial:|Permission denied|"
                         r"Can't find service:|No process found|.*: not found$|"
                         r".*: Permission denied$|.*: No such file or directory$)")


def require(value, message):
    if not value:
        raise ValueError(message)


def digest(path):
    with Path(path).open('rb') as stream:
        return stream_digest(stream)


def stream_digest(stream):
    result = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        result.update(chunk)
    return result.hexdigest()


def utc():
    return datetime.now(timezone.utc).isoformat()


def unique_json(raw):
    def pairs(items):
        result = {}
        for key, value in items:
            require(key not in result, 'Duplicate JSON key: ' + key)
            result[key] = value
        return result
    return json.loads(raw, object_pairs_hook=pairs)


def validate_local_artifact(args, provenance_raw=None):
    """Bind explicit trusted expectations, original build metadata and APK bytes.

    Certificate metadata is checked, not independently reverified with apksigner;
    the supplied expected APK digest must come from the verified delivery.
    """
    for value, width in ((args.source, 40), (args.native_source, 40),
                         (args.expected_apk_sha256, 64)):
        require(re.fullmatch('[0-9a-f]{%d}' % width, value), 'Full lowercase source/digest required')
    require(args.package == PACKAGE, 'This collector accepts the explicit LUMO host package only')
    info = unique_json(args.provenance.read_bytes() if provenance_raw is None else provenance_raw)
    require(isinstance(info, dict), 'Build provenance must be an object')
    checksum = digest(args.apk)
    require(info.get('sha256') == checksum == args.expected_apk_sha256, 'Local APK digest mismatch')
    require(type(info.get('bytes')) is int and info['bytes'] == args.apk.stat().st_size,
            'Local APK byte count mismatch')
    require(info.get('package') == args.package and info.get('flutter_source_commit') == args.source
            and info.get('tracked_source_clean') is True, 'Host/package source provenance mismatch')
    require(info.get('signingCertificateSha256') == CERTIFICATE,
            'Original build certificate metadata differs from the installed-family policy')
    require(info.get('abis') == ['arm64-v8a'], 'The physical-device input must be the ARM64 APK')
    require(type(info.get('versionCode')) is int and info['versionCode'] > 0
            and isinstance(info.get('versionName'), str) and bool(info['versionName']),
            'Missing exact package version')
    native = info.get('godot', {})
    require(isinstance(native, dict) and native.get('revision') == args.native_source
            and re.fullmatch('[0-9a-f]{64}', str(native.get('pck_sha256', ''))),
            'Native source/PCK provenance mismatch')
    with zipfile.ZipFile(args.apk) as archive:
        names = archive.namelist()
        for name in ('assets/lumo_game_source.json', 'assets/lumo_game.pck'):
            require(names.count(name) == 1, 'Missing/duplicate embedded source asset: ' + name)
        embedded = unique_json(archive.read('assets/lumo_game_source.json'))
        require(isinstance(embedded, dict) and embedded.get('revision') == args.native_source
                and embedded.get('pck_sha256') == native['pck_sha256'], 'Embedded native identity differs')
        with archive.open('assets/lumo_game.pck') as pack:
            require(stream_digest(pack) == native['pck_sha256'], 'Actual embedded PCK digest differs')
    return info


def base_apk_path(raw):
    lines = raw.strip().splitlines()
    require(len(lines) == 1 and lines[0].startswith('package:'),
            'Require one installed monolithic base APK; split installations are outside this collector')
    path = lines[0][8:]
    require(re.fullmatch(r'/data/app/[A-Za-z0-9_./~+=@-]+/base\.apk', path)
            and '..' not in path.split('/'), 'Unsafe/unrecognized installed APK path')
    return path


def thermal_observation(raw):
    values = {}
    for key, pattern in [('override', r'^\s*IsStatusOverride: (true|false)\s*$'),
                         ('hal_ready', r'^\s*HAL Ready: (true|false)\s*$'),
                         ('severity', r'^\s*Thermal Status: ([0-6])\s*$')]:
        found = re.findall(pattern, raw, re.M)
        if len(found) != 1:
            return {'status': 'UNSUPPORTED', 'reason': 'Unrecognized/ambiguous thermalservice format'}
        values[key] = found[0]
    if values['override'] != 'false' or values['hal_ready'] != 'true':
        return {'status': 'UNSUITABLE', 'reason': 'Override active or HAL not ready', 'observed': values}
    # Preserve all sensor values in raw output. Sensor types have different units;
    # never relabel battery/current/skin/CPU values as a single device temperature.
    return {'status': 'OBSERVED', 'thermal_severity': int(values['severity']),
            'sensor_values': 'RAW_ONLY', 'scope': 'Device-wide status, not per-app temperature'}


def hwui_observation(raw):
    rows, header = 0, None
    for line in raw.splitlines():
        fields = next(csv.reader([line]))
        if {'Flags', 'IntendedVsync', 'FrameCompleted'} <= set(fields):
            header = fields
        elif header and len(fields) == len(header) and all(re.fullmatch('[0-9]+', x) for x in fields):
            rows += 1
    return {'status': 'RAW_HWUI_ONLY' if rows else 'NOT_MEASURED', 'recognized_hwui_rows': rows,
            'native_fps': None, 'reason': 'HWUI does not establish Godot/SurfaceView frame delivery; no FPS computed'}


def allowed_read(words):
    """Fail closed even if a future caller accidentally supplies a mutating verb."""
    words = tuple(words)
    fixed = {('id', '-u'), ('wm', 'size'), ('wm', 'density'), ('cat', '/proc/uptime'),
             ('pm', 'path', PACKAGE), ('dumpsys', '-l'), ('dumpsys', 'package', PACKAGE),
             ('dumpsys', 'gfxinfo', PACKAGE, 'framestats'),
             ('dumpsys', 'SurfaceFlinger', '--list')}
    fixed.update(('dumpsys', name) for name in
                 ('display', 'window', 'input', 'cpuinfo', 'thermalservice', 'battery'))
    if words in fixed or words in {('getprop', name) for name in PROPERTIES}:
        return True
    if words in {('pidof', PACKAGE), ('pidof', PROCESS)}:
        return True
    if len(words) == 2 and words[0] == 'cat':
        return bool(re.fullmatch(r'/proc/[1-9][0-9]*/(?:stat|cmdline)', words[1]))
    if len(words) == 3 and words[:2] == ('dumpsys', 'meminfo'):
        return bool(re.fullmatch('[1-9][0-9]*', words[2]))
    if words[:2] == ('toybox', 'sha256sum') and len(words) == 3:
        try:
            return base_apk_path('package:' + words[2]) == words[2]
        except ValueError:
            return False
    if words[:4] == ('toybox', 'stat', '-c', '%s') and len(words) == 5:
        return allowed_read(('toybox', 'sha256sum', words[4]))
    if len(words) == 4 and words[:3] == ('dumpsys', 'SurfaceFlinger', '--latency'):
        return (PACKAGE in words[3] and 'SurfaceView' in words[3] and len(words[3]) <= 1024
                and not any(ord(c) < 32 for c in words[3]))
    return False


class Recorder:
    def __init__(self, args, *, runner=subprocess.run, clock=time.monotonic):
        require(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.:-]{0,254}', args.serial), 'Explicit safe serial required')
        self.args, self.runner, self.clock = args, runner, clock
        self.deadline = clock() + args.budget
        self.rows = []
        (args.out / 'raw').mkdir()

    def read(self, label, *words, adb_command=False):
        require(re.fullmatch('[a-z0-9_-]+', label), 'Invalid evidence label')
        require(tuple(words) in {('get-state',), ('get-serialno',)} if adb_command else allowed_read(words),
                'Not an approved read-only command')
        suffix = list(words) if adb_command else ['shell', shlex.join(words)]
        argv = [self.args.adb, '-s', self.args.serial, *suffix]
        stem = 'raw/%04d-%s' % (len(self.rows), label)
        stdout, stderr = self.args.out / (stem + '.stdout'), self.args.out / (stem + '.stderr')
        began = self.clock()
        interrupted = False
        row = {'label': label, 'argv': argv, 'device_words': list(words), 'started_utc': utc(),
               'started_monotonic': began, 'status': 'NOT_EXECUTED', 'exit_code': None}
        with stdout.open('xb') as out, stderr.open('xb') as err:
            try:
                remaining = self.deadline - began
                if remaining <= 0:
                    raise TimeoutError('Overall capture budget exhausted')
                completed = self.runner(argv, stdin=subprocess.DEVNULL, stdout=out, stderr=err,
                                        timeout=min(self.args.command_timeout, remaining), check=False)
                row.update(status='OBSERVED' if completed.returncode == 0 else 'UNSUPPORTED_OR_ERROR',
                           exit_code=completed.returncode)
            except (subprocess.TimeoutExpired, TimeoutError) as error:
                row.update(status='TIMEOUT', error=str(error))
            except OSError as error:
                row.update(status='ERROR', error=str(error))
            except KeyboardInterrupt:
                row.update(status='INTERRUPTED', error='Capture interrupted during this read')
                interrupted = True
        if row['status'] == 'OBSERVED' and self.clock() > self.deadline:
            row.update(status='TIMEOUT', error='Read completed after the overall capture budget')
        row.update(finished_utc=utc(), elapsed_seconds=self.clock() - began)
        for kind, path in [('stdout', stdout), ('stderr', stderr)]:
            row[kind] = {'path': str(path.relative_to(self.args.out)),
                         'bytes': path.stat().st_size, 'sha256': digest(path)}
        text = ''
        if stdout.stat().st_size <= MAX_PARSE_BYTES and stderr.stat().st_size <= MAX_PARSE_BYTES:
            text = stdout.read_text(errors='replace')
            error_text = stderr.read_text(errors='replace')
            if row['status'] == 'OBSERVED' and (not text.strip() or UNAVAILABLE.search(text + '\n' + error_text)):
                row['status'] = 'UNSUPPORTED_OR_EMPTY'
        else:
            row['parsing'] = 'RAW_TOO_LARGE_UNPARSED'
            if row['status'] == 'OBSERVED':
                row['status'] = 'RAW_TOO_LARGE_UNPARSED'
        self.rows.append(row)
        with (self.args.out / 'commands.jsonl').open('a') as stream:
            stream.write(json.dumps(row) + '\n')
        if interrupted:
            raise KeyboardInterrupt
        return row, text

    def required(self, label, *words, adb_command=False):
        row, text = self.read(label, *words, adb_command=adb_command)
        require(row['status'] == 'OBSERVED', 'Required identity read failed: ' + label)
        return text.strip()


def installed_binding(rec, info, phase):
    require(rec.required(phase + '-serial', 'get-serialno', adb_command=True) == rec.args.serial,
            'ADB returned a different serial')
    require(rec.required(phase + '-state', 'get-state', adb_command=True) == 'device', 'Device unavailable')
    require(rec.required(phase + '-uid', 'id', '-u') == '2000', 'Require ordinary non-root ADB shell UID2000')
    # Exact installed bytes plus pm's explicit package lookup bind identity
    # without depending on an OEM-specific dumpsys package text format.
    path = base_apk_path(rec.required(phase + '-apk-path', 'pm', 'path', PACKAGE))
    checksum = rec.required(phase + '-apk-sha', 'toybox', 'sha256sum', path)
    match = re.fullmatch(r'([0-9a-f]{64})\s+\*?' + re.escape(path), checksum)
    require(match and match[1] == info['sha256'], 'Installed base.apk SHA256 differs from the expected APK')
    size = rec.required(phase + '-apk-size', 'toybox', 'stat', '-c', '%s', path)
    require(re.fullmatch('[0-9]+', size) and int(size) == info['bytes'], 'Installed APK byte count differs')
    fingerprint = rec.required(phase + '-fingerprint', 'getprop', 'ro.build.fingerprint')
    return {'status': 'MATCHED', 'serial': rec.args.serial, 'remote_path': path,
            'sha256': match[1], 'bytes': int(size), 'fingerprint': fingerprint, 'shell_uid': 2000}


def process_sample(rec, label, process):
    row, pid = rec.read(label + '-pid', 'pidof', process)
    result = {'process': process, 'status': 'NOT_MEASURED', 'cpu_percent': None}
    if row['status'] != 'OBSERVED' or not re.fullmatch('[1-9][0-9]*', pid.strip()):
        result['reason'] = 'No unique readable PID'
        return result
    pid = pid.strip()
    result['pid'] = int(pid)
    cmd_row, cmd = rec.read(label + '-cmdline', 'cat', '/proc/' + pid + '/cmdline')
    stat_row, before = rec.read(label + '-stat-before', 'cat', '/proc/' + pid + '/stat')
    mem_row, memory = rec.read(label + '-meminfo', 'dumpsys', 'meminfo', pid)
    end_row, after = rec.read(label + '-stat-after', 'cat', '/proc/' + pid + '/stat')
    lifetime = 'NOT_MEASURED'
    try:
        require(cmd_row['status'] == stat_row['status'] == end_row['status'] == 'OBSERVED'
                and cmd.split('\0')[0] == process, 'Process identity/counters unavailable')
        first, last = parse_proc_stat(before, pid), parse_proc_stat(after, pid)
        lifetime = 'STABLE' if first['process_start_ticks'] == last['process_start_ticks'] else 'CHANGED'
        require(lifetime == 'STABLE', 'PID was reused during sample')
        result.update(status='OBSERVED_COUNTERS', counters=last,
                      conversion='OS Hz/page size not sampled; no CPU percentage or RSS-byte conversion')
    except ValueError as error:
        result['reason'] = str(error)
    if process == PROCESS and mem_row['status'] == 'OBSERVED' and lifetime != 'CHANGED':
        try:
            result['native_memory'] = {'status': 'OBSERVED_SINGLE_READ',
                                       'pid_lifetime_check': lifetime, **parse_meminfo(memory, pid)}
        except ValueError as error:
            result['native_memory'] = {'status': 'UNSUPPORTED', 'reason': str(error)}
    else:
        result['memory'] = {'status': 'RAW_ONLY', 'command_status': mem_row['status']}
    return result


def snapshot(rec, index):
    tag = 'sample-%03d' % index
    result = {'index': index, 'started_utc': utc(), 'observations': {}}
    commands = {'uptime': ('cat', '/proc/uptime'), 'size': ('wm', 'size'), 'density': ('wm', 'density'),
                **{name: ('dumpsys', name) for name in
                   ('display', 'window', 'input', 'cpuinfo', 'thermalservice', 'battery')},
                'hwui': ('dumpsys', 'gfxinfo', PACKAGE, 'framestats'),
                'layers': ('dumpsys', 'SurfaceFlinger', '--list')}
    if rec.args.surface_layer:
        commands['layer-latency'] = ('dumpsys', 'SurfaceFlinger', '--latency', rec.args.surface_layer)
    for name, words in commands.items():
        row, text = rec.read(tag + '-' + name, *words)
        parsed = {'status': row['status'], 'raw_command': row['label']}
        if row['status'] == 'OBSERVED' and name in ('thermalservice', 'hwui'):
            parsed['interpretation'] = thermal_observation(text) if name == 'thermalservice' else hwui_observation(text)
        result['observations'][name] = parsed
    result['processes'] = [process_sample(rec, tag + '-host', PACKAGE),
                           process_sample(rec, tag + '-native', PROCESS)]
    result['finished_utc'] = utc()
    return result


def collect(args, *, runner=subprocess.run, clock=time.monotonic, sleeper=time.sleep):
    require(1 <= args.samples <= 120 and 1 <= args.interval <= 60
            and 1 <= args.command_timeout <= 30 and 10 <= args.budget <= 1800,
            'Samples/interval/timeout/budget outside bounded limits')
    require(type(args.expected_api) is int and args.expected_api > 0, 'Positive expected SDK required')
    require(not args.surface_layer or allowed_read(('dumpsys', 'SurfaceFlinger', '--latency', args.surface_layer)),
            'Optional SurfaceView layer must name this package and contain no control characters')
    args.out.mkdir(parents=True, exist_ok=False, mode=0o700)
    report = {'schema': 1, 'status': 'RUNNING', 'started_utc': utc(), 'samples': [],
              'requested': {'serial': args.serial, 'package': args.package, 'source': args.source,
                            'native_source': args.native_source, 'apk_sha256': args.expected_apk_sha256,
                            'expected_api': args.expected_api, 'samples': args.samples,
                            'interval_seconds': args.interval, 'command_timeout_seconds': args.command_timeout,
                            'adb_budget_seconds': args.budget, 'surface_layer': args.surface_layer},
              'native_fps': {'status': 'NOT_MEASURED', 'value': None},
              'gpu_frame_time': {'status': 'NOT_MEASURED', 'value': None},
              'touch_latency': {'status': 'NOT_MEASURED', 'value': None},
              'scope': 'Read-only diagnostic samples; no performance, gameplay or release approval',
              'limits': ['Sequential diagnostics perturb load; sample cadence is not a frame cadence.',
                         'HWUI data is never attributed to Godot/SurfaceView FPS.',
                         'SurfaceFlinger buffers are unreset, may be old/incomplete, and are raw only.',
                         'No installation, root, force-stop, input injection, settings or app/save writes.',
                         'Certificate field comes from trusted original provenance, not a new signature verification.']}
    rec = None
    try:
        provenance_raw = args.provenance.read_bytes()
        info = validate_local_artifact(args, provenance_raw)
        (args.out / 'BUILD-PROVENANCE.original.json').write_bytes(provenance_raw)
        report['provenance'] = {'bytes': len(provenance_raw),
                                'sha256': hashlib.sha256(provenance_raw).hexdigest()}
        report['artifact'] = info
        report['collector_sources'] = {str(path.name): digest(path) for path in
                                       (Path(__file__), Path(__file__).with_name('runtime_resource_evidence.py'))}
        rec = Recorder(args, runner=runner, clock=clock)
        report['binding_before'] = installed_binding(rec, info, 'before')
        rec.read('available-services', 'dumpsys', '-l')
        rec.read('installed-package-description', 'dumpsys', 'package', PACKAGE)
        report['device'] = {name: rec.required('property-' + name.replace('.', '-'), 'getprop', name)
                            for name in PROPERTIES if name != 'ro.kernel.qemu'}
        _, qemu = rec.read('property-qemu', 'getprop', 'ro.kernel.qemu')
        report['device']['ro.kernel.qemu'] = qemu.strip() or None
        require(report['device']['ro.build.version.sdk'] == str(args.expected_api), 'Unexpected actual Android SDK')
        if args.expected_api == 37:
            require(report['device']['ro.build.version.release'].split('.')[0] == '17', 'API37 requires Android17')
        require('arm64-v8a' in report['device']['ro.product.cpu.abilist'].split(','), 'Device lacks ARM64 ABI')
        for index in range(args.samples):
            require(clock() < rec.deadline, 'Capture budget expired before all requested samples')
            began = clock()
            report['samples'].append(snapshot(rec, index))
            if index + 1 < args.samples:
                sleeper(max(0, min(args.interval - (clock() - began), rec.deadline - clock())))
        report['binding_after'] = installed_binding(rec, info, 'after')
        require(report['binding_before'] == report['binding_after'], 'Installed package/device changed during collection')
        report['status'] = 'RECORDED_WITH_LIMITATIONS'
    except KeyboardInterrupt:
        report.update(status='INTERRUPTED_UNVERIFIED_END', error='Original partial diagnostics retained')
    except (ValueError, OSError, zipfile.BadZipFile, KeyError, TypeError) as error:
        report.update(status='FAILED_BINDING_OR_COLLECTION', error=str(error))
    finally:
        report['finished_utc'] = utc()
        report['command_status_counts'] = {name: sum(r['status'] == name for r in rec.rows)
                                           for name in sorted({r['status'] for r in rec.rows})} if rec else {}
        (args.out / 'capture.json').write_text(json.dumps(report, indent=2) + '\n')
        files = [{'path': str(p.relative_to(args.out)), 'bytes': p.stat().st_size, 'sha256': digest(p)}
                 for p in sorted(args.out.rglob('*')) if p.is_file()]
        (args.out / 'MANIFEST.json').write_text(json.dumps({'schema': 1, 'files': files}, indent=2) + '\n')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('serial', 'package', 'source', 'native-source', 'expected-apk-sha256'):
        parser.add_argument('--' + name, required=True)
    for name in ('apk', 'provenance', 'out'):
        parser.add_argument('--' + name, required=True, type=Path)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--expected-api', type=int, default=37)
    parser.add_argument('--samples', type=int, default=3)
    parser.add_argument('--interval', type=float, default=5)
    parser.add_argument('--command-timeout', type=float, default=10)
    parser.add_argument('--budget', type=float, default=180)
    parser.add_argument('--surface-layer', help='Exact observed package SurfaceView layer; raw timing only')
    args = parser.parse_args()
    try:
        report = collect(args)
    except (ValueError, OSError) as error:
        parser.exit(2, str(error) + '\n')
    print(json.dumps({'status': report['status'], 'out': str(args.out), 'native_fps': 'NOT_MEASURED'}))
    return 0 if report['status'] == 'RECORDED_WITH_LIMITATIONS' else 130 if report['status'].startswith('INTERRUPTED') else 2


if __name__ == '__main__':
    raise SystemExit(main())
