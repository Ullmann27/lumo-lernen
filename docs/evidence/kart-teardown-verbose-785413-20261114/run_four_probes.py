#!/usr/bin/env python3
"""Four unchanged 785413 Kart probes, with verbose teardown diagnostics only."""
from __future__ import annotations

import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
RUNTIME = Path('/tmp/lumo-attention-8be3-20261114/runtime')
PRIVATE = Path('/tmp/lumo-kart-verbose-785413-20261114')
EXPECTED = json.loads((OUT / 'expected-source-tree.json').read_text())
GODOT = shutil.which('godot')
LAUNCHER = ROOT / 'lumo-godot/tools/run_local_renderer.py'
PROBES = (
    ('kart_ai_behavior_regression', 180, 'headless', '[KartAI] PASS'),
    ('kart_racecraft_regression', 240, 'headless', '[KartRacecraft] PASS'),
    ('kart_full_field_regression', 240, 'headless', '[KartFullField] PASS'),
    ('kart_harbor_race_hook_regression', 240, 'rendered', '[HarborRaceHook] PASS'),
)


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def identity(path):
    data = path.read_bytes()
    return {'path': str(path), 'bytes': len(data),
            'sha256': hashlib.sha256(data).hexdigest()}


def bind_sources(label):
    rows = []
    for expected in EXPECTED['files']:
        path = RUNTIME / expected['path']
        data = path.read_bytes()
        blob = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
        if blob != expected['sha']:
            raise RuntimeError('Runtime source mismatch: ' + expected['path'])
        rows.append({'path': expected['path'], 'bytes': len(data),
                     'sha256': hashlib.sha256(data).hexdigest(), 'git_blob_sha': blob})
    result = {'label': label, 'time_utc': utc(), 'source_sha': EXPECTED['source'],
              'tree': EXPECTED['tree'], 'runtime': str(RUNTIME), 'files': rows,
              'scope': 'All tracked runtime-source paths; no complete checkout or device claim.'}
    (OUT / (label + '.json')).write_text(json.dumps(result, indent=2) + '\n')
    return result


def environment(folder):
    env = os.environ.copy()
    for key, child in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'),
                       ('XDG_CACHE_HOME', 'cache')]:
        path = folder / child
        path.mkdir(parents=True, exist_ok=True)
        env[key] = str(path)
    return env


def command_run(command, log_path, budget, env):
    start = time.monotonic()
    started = utc()
    with log_path.open('wb') as log:
        try:
            p = subprocess.run(command, cwd=RUNTIME, env=env, stdout=log,
                               stderr=subprocess.STDOUT, timeout=budget)
            code, timed_out = p.returncode, False
        except subprocess.TimeoutExpired:
            code, timed_out = 124, True
    return {'command': command, 'cwd': str(RUNTIME), 'started_utc': started,
            'finished_utc': utc(), 'elapsed_seconds': time.monotonic() - start,
            'exit_code': code, 'timed_out': timed_out, 'deadline_seconds': budget,
            'original_log': identity(log_path)}


def main():
    if not GODOT:
        raise RuntimeError('Godot is required')
    PRIVATE.mkdir(exist_ok=False)
    before = bind_sources('source-before-execution')
    binary = Path(GODOT).resolve()
    version = subprocess.run([GODOT, '--version'], check=True, capture_output=True,
                             text=True, timeout=10).stdout.strip()
    if not version.startswith('4.6.3.stable.official.7d41c59c4'):
        raise RuntimeError('Unexpected Godot version: ' + version)
    (OUT / 'engine.json').write_text(json.dumps({'version': version,
        'binary': identity(binary), 'launcher': identity(LAUNCHER)}, indent=2) + '\n')
    # Original native harness also imports before the probes. This preparation
    # refreshes only private generated caches, including the previously absent icon.
    prep = command_run([GODOT, '--headless', '--editor', '--import', '--quit'],
                       OUT / 'private-import.log', 120, environment(PRIVATE / 'import'))
    (OUT / 'private-import.json').write_text(json.dumps(prep, indent=2) + '\n')
    if prep['exit_code'] != 0:
        raise RuntimeError('Private import failed; no Kart probes were executed')
    bind_sources('source-after-private-import')
    results = []
    for name, budget, mode, marker in PROBES:
        print('START ' + name, flush=True)
        if mode == 'headless':
            command = [GODOT, '--headless', '--verbose', '--path', str(RUNTIME)]
            if name != 'kart_ai_behavior_regression':
                command += ['--audio-driver', 'Dummy']
            command += ['--script', 'scripts/tests/' + name + '.gd']
            result = command_run(command, OUT / (name + '.log'), budget,
                                 environment(PRIVATE / name))
        else:
            rendered = PRIVATE / name
            command = [sys.executable, str(LAUNCHER), '--display', '106',
                       '--output', str(rendered), '--timeout', str(budget),
                       '--project', str(RUNTIME), '--', '--verbose',
                       '--script', 'scripts/tests/' + name + '.gd']
            result = command_run(command, OUT / (name + '-launcher.log'), budget + 12,
                                 os.environ.copy())
            if (rendered / 'run.json').exists():
                native_result = json.loads((rendered / 'run.json').read_text())
                result['renderer_run'] = native_result
                result['engine_deadline_seconds'] = budget
                result['wrapper_deadline_seconds'] = budget + 12
                result['exit_code'] = native_result['exit_code']
                result['timed_out'] = native_result['timed_out']
                shutil.copyfile(rendered / 'run.json', OUT / (name + '-renderer-run.json'))
            if (rendered / 'godot.log').exists():
                shutil.copyfile(rendered / 'godot.log', OUT / (name + '.log'))
                result['original_log'] = identity(OUT / (name + '.log'))
        result.update(probe=name, mode=mode, required_marker=marker,
                      source_sha=EXPECTED['source'], code_unchanged=True)
        text = Path(result['original_log']['path']).read_text(errors='replace')
        result['marker_present'] = marker in text
        result['error_lines'] = [x for x in text.splitlines() if 'ERROR:' in x or 'WARNING:' in x]
        results.append(result)
        (OUT / (name + '-execution.json')).write_text(json.dumps(result, indent=2) + '\n')
        (OUT / 'execution-results.json').write_text(json.dumps(results, indent=2) + '\n')
        print('END ' + name + ' exit=' + str(result['exit_code']) +
              ' marker=' + str(result['marker_present']), flush=True)
        bind_sources('source-after-' + name)
    after = bind_sources('source-after-execution')
    if before['files'] != after['files']:
        raise RuntimeError('Runtime sources changed during execution')
    print('FOUR_UNCHANGED_PROBES_COMPLETE', flush=True)
    return 0 if all(r['exit_code'] == 0 and r['marker_present'] for r in results) else 1


if __name__ == '__main__':
    raise SystemExit(main())
