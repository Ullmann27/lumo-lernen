#!/usr/bin/env python3
"""Focused, read-only QA of the exact f365 LUMO source union.

This runs existing offline contracts. It does not run Flutter, Android, a
renderer, an APK build, a release, or any remote mutation.
"""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

import PIL
import yaml

ROOT = Path('/workspace/scratch/909ddb52fe7b/lumo-integration')
OUT = Path(__file__).resolve().parent
EXPECTED_HEAD = 'f36579a3a7e06045eaecea7c00e497ac06930100'
EXPECTED_TREE = 'ed67b3939bb3caeb69231a2c70387860155b1a83'
NATIVE = 'e9a9f60f20403ffa6b2b26d1437f958b2704d2aa'
TARGETS = (
    ('scripts/tests', 'test_candidate_2011_pin.py'),
    ('scripts/tests', 'test_legacy_release_pin.py'),
    ('scripts/tests', 'test_connect_four_delivery.py'),
    ('scripts/tests', 'test_connect_four_pipeline.py'),
    ('scripts/tests', 'test_connect_four_return_gate.py'),
    ('scripts/tests', 'test_verify_unchanged_apk_diagnostic.py'),
    ('scripts/tests', 'test_runtime_followup_workflow.py'),
    ('scripts/tests', 'test_android_runtime_wait_notification.py'),
    ('scripts/tests', 'test_verify_android_runtime_anr.py'),
    ('scripts/tests', 'test_android_runtime_device_logger.py'),
    ('tools/android_qa/tests', 'test_connect_four_android_evidence.py'),
    ('tools/android_qa/tests', 'test_village_android_evidence.py'),
    ('tools/android_qa/tests', 'test_kart_continue_caption.py'),
    ('tools/android_qa/tests', 'test_kart_garage_evidence.py'),
    ('tools/android_qa/tests', 'test_update_2019_preservation.py'),
    ('tools/android_qa/tests', 'test_update_2020_preservation.py'),
)
WORKFLOWS = (
    '.github/workflows/lumo-connect-four-2020.yml',
    '.github/workflows/lumo-unified-integration-2026.yml',
    '.github/workflows/lumo-learning-curriculum-audit.yml',
    '.github/workflows/lumo-astra-script-recovery.yml',
    '.github/workflows/lumo-unchanged-apk-diagnostic.yml',
    '.github/workflows/lumo-android-runtime-7b16-followup.yml',
)
NATIVE_STEPS = (
    ('connect-four-runtime', 'Retry the acknowledged native exit after a transient Android refusal'),
    ('connect-four-runtime', 'Require the additional pinned native Treasure wisp regression'),
    ('verify-and-build', 'Require actual gameplay gates on the exact pinned native source'),
    ('verify-and-build', 'Require acknowledged Connect Four return retry'),
    ('verify-and-build', 'Require actual Dream gates on the exact pinned native source'),
    ('verify-and-build', 'Verify connected dream ambience and garden on exact native source'),
)
ENV = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', GIT_OPTIONAL_LOCKS='0',
           TMPDIR=str(OUT / 'temporary-test-fixtures'))


def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def write(name, value):
    (OUT / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, env=ENV).decode()


def record(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()}


def identity():
    head = git('rev-parse', 'HEAD').strip()
    tree = git('rev-parse', 'HEAD^{tree}').strip()
    status = git('status', '--porcelain=v1', '--untracked-files=all')
    entries = git('ls-files', '--stage', '-z').split('\0')
    digest = hashlib.sha256()
    count = size = 0
    for entry in entries:
        if not entry:
            continue
        meta, name = entry.split('\t', 1)
        mode, expected_blob, stage = meta.split()
        if stage != '0' or mode == '160000':
            raise AssertionError('Unsupported or conflicted tracked entry: ' + entry)
        path = ROOT / name
        data = os.readlink(path).encode() if mode == '120000' else path.read_bytes()
        actual_blob = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
        if actual_blob != expected_blob:
            raise AssertionError('Tracked bytes differ from committed Git blob: ' + name)
        row = [name, mode, expected_blob, len(data), hashlib.sha256(data).hexdigest()]
        digest.update((json.dumps(row, ensure_ascii=False, separators=(',', ':'))+'\n').encode())
        count += 1
        size += len(data)
    if (head, tree, status) != (EXPECTED_HEAD, EXPECTED_TREE, ''):
        raise AssertionError('Unexpected source identity or dirty source: '+repr((head, tree, status)))
    pin = json.loads((ROOT / 'config/godot-source.json').read_bytes())
    if pin['revision'] != NATIVE:
        raise AssertionError('Unexpected native pin: '+repr(pin))
    paths = [directory+'/'+pattern for directory, pattern in TARGETS] + list(WORKFLOWS)
    return {'head': head, 'tree': tree, 'native_source': NATIVE, 'status_porcelain': status,
            'tracked_files': count, 'tracked_bytes': size,
            'all_tracked_git_blobs_match': True, 'tracked_identity_sha256': digest.hexdigest(),
            'selected_sources': {name: record(ROOT / name) for name in paths}}


def command(command_line, log_name):
    start = time.monotonic()
    with (OUT / log_name).open('xb') as output:
        completed = subprocess.run(command_line, cwd=ROOT, env=ENV, stdout=output,
                                   stderr=subprocess.STDOUT, check=False)
    return {'command': command_line, 'cwd': str(ROOT), 'returncode': completed.returncode,
            'elapsed_seconds': round(time.monotonic()-start, 6), 'log': log_name,
            'log_identity': record(OUT / log_name)}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'temporary-test-fixtures').mkdir(exist_ok=True)
    summary = {'schema': 1, 'scope': 'Existing offline source, shell and fixture contracts only',
               'started_utc': stamp(), 'status': 'RUNNING',
               'tools': {'python': sys.version, 'python_executable': sys.executable,
                         'pyyaml': yaml.__version__, 'pillow': PIL.__version__},
               'runtime_claims': {'flutter': False, 'android': False, 'native_renderer': False,
                                  'apk_build': False, 'publication': False},
               'planned_tests': [directory+'/'+pattern for directory, pattern in TARGETS],
               'syntax': [], 'tests': []}
    before = identity()
    write('source-before.json', before)
    print('SOURCE VERIFIED', EXPECTED_HEAD, EXPECTED_TREE, 'files', before['tracked_files'], flush=True)
    failure = None
    try:
        parsed = {}
        for name in WORKFLOWS:
            value = yaml.safe_load((ROOT / name).read_bytes())
            if not isinstance(value, dict) or not isinstance(value.get('jobs'), dict):
                raise AssertionError('Workflow did not parse into its job mapping: '+name)
            parsed[name] = value
            summary['syntax'].append({'kind': 'yaml.safe_load', 'path': name,
                                      'jobs': list(value['jobs']), 'status': 'PASS'})
        native_dir = OUT / 'native-step-shells'
        native_dir.mkdir()
        workflow = parsed[WORKFLOWS[0]]
        for number, (job, step_name) in enumerate(NATIVE_STEPS, 1):
            steps = [s for s in workflow['jobs'][job]['steps'] if s.get('name') == step_name]
            if len(steps) != 1 or not isinstance(steps[0].get('run'), str):
                raise AssertionError('Exact native step is absent or ambiguous: '+step_name)
            path = native_dir / (str(number).zfill(2)+'.sh')
            path.write_text(steps[0]['run'])
            result = command(['bash', '-n', str(path)], 'bash-native-'+str(number).zfill(2)+'.log')
            summary['syntax'].append({'kind': 'bash -n', 'job': job, 'step': step_name,
                                      'extracted_shell': str(path.relative_to(OUT)), **result})
            if result['returncode'] != 0:
                raise AssertionError('Bash syntax failed: '+step_name)
        result = command(['bash', '-n', 'scripts/run_unchanged_apk_diagnostic.sh'], 'bash-diagnostic.log')
        summary['syntax'].append({'kind': 'bash -n', **result})
        if result['returncode'] != 0:
            raise AssertionError('Bash syntax failed: unchanged diagnostic')
        print('SYNTAX PASS: 6 YAML workflows, 6 exact Native run blocks, 1 original shell script', flush=True)
        for index, (directory, pattern) in enumerate(TARGETS, 1):
            print('START', index, directory+'/'+pattern, flush=True)
            row = command([sys.executable, '-B', '-m', 'unittest', 'discover', '-s', directory,
                           '-p', pattern, '-v'], 'unittest-'+str(index).zfill(2)+'-'+pattern[:-3]+'.log')
            raw = (OUT / row['log']).read_text(errors='strict')
            totals = re.findall(r'^Ran (\d+) tests? in ([0-9.]+)s$', raw, re.M)
            row.update(test_file=directory+'/'+pattern,
                       test_count=int(totals[-1][0]) if len(totals) == 1 else None,
                       unittest_seconds=float(totals[-1][1]) if len(totals) == 1 else None,
                       skipped_count=len(re.findall(r'^test_.* \.\.\. skipped ', raw, re.M)))
            row['status'] = 'PASS' if row['returncode'] == 0 and row['test_count'] and row['skipped_count'] == 0 and re.search(r'^OK$', raw, re.M) else 'FAIL'
            summary['tests'].append(row)
            write('preflight-report.json', summary)
            print(row['status'], row['test_file'], 'tests', row['test_count'],
                  'exit', row['returncode'], 'seconds', row['elapsed_seconds'], flush=True)
            if row['status'] != 'PASS':
                raise AssertionError('Original failure retained in '+row['log'])
    except BaseException as exc:
        failure = repr(exc)
        summary['error'] = failure
    finally:
        after = identity()
        write('source-after.json', after)
        summary['source_unchanged'] = before == after
        summary['completed_utc'] = stamp()
        summary['status'] = 'PASS' if failure is None and before == after and len(summary['tests']) == len(TARGETS) else 'FAIL'
        summary['total_tests'] = sum(row['test_count'] or 0 for row in summary['tests'])
        summary['total_skipped'] = sum(row['skipped_count'] for row in summary['tests'])
        summary['driver_identity'] = record(Path(__file__))
        write('preflight-report.json', summary)
        print(json.dumps({key: summary[key] for key in ('status', 'total_tests', 'total_skipped', 'source_unchanged')}, sort_keys=True), flush=True)
        if failure:
            print(failure, flush=True)
    return 0 if summary['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
