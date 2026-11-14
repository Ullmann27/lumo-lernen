#!/usr/bin/env python3
"""Run the fixed package-free Dart contract against two exact source snapshots."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent
DART = Path('/workspace/scratch/e0abce7d2838/toolchain/flutter/bin/cache/dart-sdk/bin/dart')
CONTRACT = 'test/support/math_exact_topic_selection_contract.dart'
EXPECTED = {
  "lib/core/school_exercise_generator.dart": "ae96f9d4e7c0a2d0fa4dca661c7873dc6d716d65",
  "lib/core/math_task_templates.dart": "f5febd9c1e65516eef23b3d1ba40d670f62a2f89",
  "lib/core/german_task_templates.dart": "47843a70ed106d25001481c995b339fc31894f5d",
  "lib/core/shape_question_data.dart": "1234048061f3b187aeaf59cbb3b4a07324045395",
  "lib/core/adventure/lumo_adventure_tasks.dart": "cd28cf0f81903bbd0a68a462782c853feadc27e7",
  "lib/core/english_vocabulary_extensions.dart": "13f29bd61dc325bd351cd98dc4bf619abf8f292f",
  "lib/core/primary_school_word_data.dart": "1288d888554349b5d84ea9b96cf63e98b4965f0e",
  "lib/core/reading_comprehension_data.dart": "25e9a13d147ed023a4e4615f58bb490b40f41f4d",
  "lib/core/science_task_data.dart": "41f7f14751d328d54de28b122f67fe53cd9427fa",
  "lib/core/science_quality_extension.dart": "952999462e8424e1cb33bd2c31633884b39f1d8a",
  "lib/core/spelling_context_data.dart": "061ccc33862ef610e1589ee54cd2628755105265",
  "lib/core/german_curriculum_extensions.dart": "2d0cc7d168606dd82e7e808d6fcf9bfcbb0cd732",
  "lib/core/adventure/adventure_word_data.dart": "b98029abd17aed104d4c79fe948c18d96bb4811f"
}
EXPECTED[CONTRACT] = 'becda7215230494989c04a71ee9f0b6a09c4fda2'
EXPECTED['test/math_exact_topic_selection_test.dart'] = 'f82604a4239bd8982ac666b97aa478b65a8fa2e8'
PATCHED_MATH = '85fbad4a0b09753a7f22663690a9660f98382f39'

def stamp():
    return datetime.now(timezone.utc).isoformat()

def identity(path):
    raw = path.read_bytes()
    return {
        'bytes': len(raw),
        'sha256': hashlib.sha256(raw).hexdigest(),
        'git_blob': hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest(),
    }

def snapshot(stage):
    expected = dict(EXPECTED)
    if stage == 'patched':
        expected['lib/core/math_task_templates.dart'] = PATCHED_MATH
    result = {}
    for relative, blob in expected.items():
        path = ROOT / stage / relative
        if path.is_symlink() or not path.is_file():
            raise RuntimeError('Missing or linked source: ' + str(path))
        value = identity(path)
        if value['git_blob'] != blob:
            raise RuntimeError('Unexpected source: ' + str(path))
        result[relative] = value
    return result

def save(path, raw):
    with path.open('xb') as target:
        target.write(raw)

def main():
    started = stamp()
    before = {stage: snapshot(stage) for stage in ('original', 'patched')}
    differences = [path for path in before['original']
                   if before['original'][path] != before['patched'][path]]
    if differences != ['lib/core/math_task_templates.dart']:
        raise RuntimeError('Unexpected differences between fixtures: ' + repr(differences))
    temp = ROOT / 'tmp'
    temp.mkdir(exist_ok=False)
    env = dict(os.environ, TMPDIR=str(temp))
    version = subprocess.run([str(DART), '--version'], capture_output=True,
                             timeout=10, env=env)
    save(ROOT / 'dart-version.stdout.log', version.stdout)
    save(ROOT / 'dart-version.stderr.log', version.stderr)
    if version.returncode != 0:
        raise RuntimeError('Dart SDK version check failed')
    runs = []
    for stage in ('original', 'patched'):
        command = [str(DART), CONTRACT]
        began = stamp()
        clock = time.monotonic()
        completed = subprocess.run(command, cwd=ROOT / stage, capture_output=True,
                                   timeout=60, env=env)
        duration = time.monotonic() - clock
        stdout_path = ROOT / (stage + '.stdout.log')
        stderr_path = ROOT / (stage + '.stderr.log')
        save(stdout_path, completed.stdout)
        save(stderr_path, completed.stderr)
        report = json.loads(completed.stdout.decode('utf-8'))
        runs.append({
            'stage': stage, 'started_at_utc': began, 'finished_at_utc': stamp(),
            'duration_seconds': duration, 'command': command,
            'cwd': str(ROOT / stage), 'exit_code': completed.returncode,
            'stdout': identity(stdout_path), 'stderr': identity(stderr_path),
            'checks': report['checks'], 'template_calls': report['template_calls'],
            'factory_calls': report['factory_calls'],
            'cumulative_topic_count': report['cumulative_topic_count'],
            'seeds_per_cumulative_topic': report['seeds_per_cumulative_topic'],
            'failure_count': report['failure_count'],
            'fixed_cases': report['fixed_cases'],
            'same_topic_observed_grades': report['same_topic_observed_grades'],
            'scope': report['scope'],
        })
    after = {stage: snapshot(stage) for stage in ('original', 'patched')}
    unchanged = before == after
    report = {
        'schema': 1, 'scope': 'Actual identical pure Dart contract; no Flutter, widget, Android, or full repository test run.',
        'source_context': {
            'baseline_host': 'f4df466ed004879fc56284b024475a0ab0661259',
            'later_host_checkpoint_reported_by_root': 'dfc3e0a1ea20f1491e4844ecfa913c598e1c6c5f',
            'staging': 'Isolated exact 13-file production dependency closure plus test helper and unexecuted Flutter wrapper; not a full host checkout.',
        },
        'started_at_utc': started, 'finished_at_utc': stamp(),
        'dart_version': {'exit_code': version.returncode,
                         'stdout': version.stdout.decode('utf-8'),
                         'stderr': version.stderr.decode('utf-8')},
        'source_differences': differences, 'source_before': before,
        'source_after': after, 'all_source_bytes_unchanged': unchanged,
        'same_contract_blob': EXPECTED[CONTRACT], 'runs': runs,
        'expected_red_green_observed': (
            runs[0]['exit_code'] == 1 and runs[0]['failure_count'] > 0
            and runs[1]['exit_code'] == 0 and runs[1]['failure_count'] == 0
            and unchanged),
    }
    save(ROOT / 'execution.json', (json.dumps(report, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({
        'runs': runs, 'all_source_bytes_unchanged': unchanged,
        'source_differences': differences,
        'expected_red_green_observed': report['expected_red_green_observed'],
    }, ensure_ascii=False))
    return 0 if report['expected_red_green_observed'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
