#!/usr/bin/env python3
"""Run the frozen PCM/installer candidate in four small isolated source views."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time


PACK = Path(__file__).resolve().parent


def digest(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}


def record(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(value, indent=2) + '\n')


def source_map(root):
    return {str(path.relative_to(root)): digest(path)
            for path in sorted(root.rglob('*')) if path.is_file()}


def main():
    final = PACK / 'final-source'
    freeze = json.loads((PACK / 'source-freeze.json').read_text())
    for entry in freeze['files']:
        if digest(final / entry['path']) != {key: entry[key] for key in ('bytes', 'sha256')}:
            raise RuntimeError('Frozen source changed: ' + entry['path'])
    validation = PACK / 'validation'
    validation.mkdir(exist_ok=False)
    env = dict(os.environ)
    env['PYTHONDONTWRITEBYTECODE'] = '1'
    results = []
    plans = (
        ('installer-red',
         'scripts.tests.test_prepare_android.AndroidHostTest.test_actual_local_voice_templates_preserve_host_namespace_and_user_files',
         ('scripts/prepare_android.py', PACK / 'before/scripts/prepare_android.py'),
         1, 'FileNotFoundError', 'LumoSpeechEnvelope.kt'),
        ('installer-green', 'scripts.tests.test_prepare_android', None, 0, 'Ran 3 tests', '\nOK\n'),
        ('producer-learning-only-red',
         'scripts.tests.test_speech_envelope_contract.SpeechEnvelopeContractTest.test_build_consent_rate_and_activity_contract',
         ('tools/auto_install/LumoLearningSpeech.kt',
          PACK / 'producer-originals/host/tools/auto_install/LumoLearningSpeech.kt'),
         1, 'Licensed active build accepts the original speech request', 'FAILED'),
        ('merged-pcm-green', 'scripts.tests.test_speech_envelope_contract', None, 0,
         'LUMO_SPEECH_ENVELOPE_PASS checks=23', 'LUMO_SPEECH_LIFECYCLE_PASS checks=17',
         'LUMO_BUILD_SPEECH_PASS checks=30', 'Ran 3 tests', '\nOK\n'),
    )
    for name, module, substitution, expected, *markers in plans:
        view = validation / name / 'source'
        shutil.copytree(final, view)
        shutil.copytree(PACK / 'unchanged-test-inputs', view, dirs_exist_ok=True)
        if substitution is not None:
            relative, original = substitution
            (view / relative).write_bytes(original.read_bytes())
        before = source_map(view)
        command = [sys.executable, '-B', '-m', 'unittest', '-v', module]
        start = time.monotonic()
        with (view.parent / 'original.log').open('xb') as log:
            result = subprocess.run(command, cwd=view, env=env, stdout=log,
                                    stderr=subprocess.STDOUT, timeout=180)
        seconds = time.monotonic() - start
        after = source_map(view)
        raw = (view.parent / 'original.log').read_text()
        outcome = {
            'name': name, 'command': command, 'cwd': str(view),
            'returncode': result.returncode, 'expected_returncode': expected,
            'seconds': seconds, 'expected_markers': markers,
            'markers_observed': all(marker in raw for marker in markers),
            'original_log': digest(view.parent / 'original.log'),
            'source_before': before, 'source_after': after,
            'sources_unchanged': before == after,
            'scope': 'Isolated local installer or synthetic JVM boundary only; no Android result',
        }
        record(view.parent / 'result.json', outcome)
        results.append(outcome)
        if result.returncode != expected or not outcome['markers_observed'] or before != after:
            record(validation / 'result.json', {'status': 'FAIL', 'runs': results})
            raise RuntimeError('Unexpected targeted result: ' + name)
    for entry in freeze['files']:
        if digest(final / entry['path']) != {key: entry[key] for key in ('bytes', 'sha256')}:
            raise RuntimeError('Final source changed during validation: ' + entry['path'])
    record(validation / 'result.json', {
        'status': 'PASS', 'scope': 'Expected red counterexamples and focused local green gates only',
        'producer_original_checks': 40, 'integration_neighbor_checks': 30,
        'installer_methods': 3, 'jvm_methods': 3, 'source_paths': len(freeze['files']),
        'source_freeze': digest(PACK / 'source-freeze.json'), 'runs': results,
        'no_android_or_device_claim': True,
    })
    print('PCM_TARGETED_VALIDATION_PASS original_checks=40 build_neighbor_checks=30 installer_methods=3 jvm_methods=3')


if __name__ == '__main__':
    main()
