from __future__ import annotations

import difflib
import hashlib
import json
import subprocess
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent
RELATIVE = Path('.github/workflows/lumo-unified-integration-2026.yml')
BASE = ROOT / 'baseline' / RELATIVE
PATCHED = ROOT / 'patched' / RELATIVE
EVIDENCE = ROOT / 'evidence'


def identity(data: bytes) -> dict:
    return {
        'bytes': len(data),
        'sha256': hashlib.sha256(data).hexdigest(),
        'git_blob_sha': hashlib.sha1(
            b'blob ' + str(len(data)).encode() + b'\0' + data
        ).hexdigest(),
    }


original = BASE.read_bytes()
assert identity(original)['git_blob_sha'] == 'b393e64d87874794742be4a44052fb188aef6b95'
source = original.decode('utf-8')
compile_line = '          python3 -m py_compile .github/probes/modernization_android_tour.py\n'
contracts = (
    '          test -s tools/android_qa/tests/test_kart_preview_skip.py\n'
    '          python3 -B -m unittest discover -s tools/android_qa/tests -p test_kart_preview_skip.py -v\n'
)
invocation = (
    '          script: .probe-venv/bin/python .github/probes/modernization_android_tour.py '
    '--apk candidate/dist/x86_64/Lumo-Lernen-Neu.apk '
    '--provenance candidate/dist/x86_64/BUILD-PROVENANCE.json '
    '--sums candidate/dist/ANDROID-TOUR-SHA256SUMS.txt --out tour\n'
)
assert source.count(compile_line) == 1
assert source.count(invocation) == 1
updated_invocation = invocation.replace(' --out tour\n', ' --skip-observed-kart-preview --out tour\n')
changed = source.replace(compile_line, compile_line + contracts).replace(invocation, updated_invocation)
assert changed.replace(contracts, '').replace(updated_invocation, invocation) == source
assert changed.count('--skip-observed-kart-preview') == 1

old = yaml.load(source, Loader=yaml.BaseLoader)
new = yaml.load(changed, Loader=yaml.BaseLoader)
assert isinstance(old, dict) and isinstance(new, dict)
assert old.keys() == new.keys()
for name in old:
    if name != 'jobs':
        assert old[name] == new[name], name
assert old['jobs'].keys() == new['jobs'].keys()
for name in old['jobs']:
    if name != 'android-tour':
        assert old['jobs'][name] == new['jobs'][name], name
before_job = old['jobs']['android-tour']
after_job = new['jobs']['android-tour']
assert before_job.keys() == after_job.keys()
for name in before_job:
    if name != 'steps':
        assert before_job[name] == after_job[name], name
assert len(before_job['steps']) == len(after_job['steps'])
changed_steps = []
for before, after in zip(before_job['steps'], after_job['steps']):
    if before == after:
        continue
    name = before['name']
    changed_steps.append(name)
    if name == 'Live UI reader':
        assert before['timeout-minutes'] == after['timeout-minutes'] == '8'
        assert after['run'].startswith('set -euo pipefail\n')
        assert after['run'].replace(contracts.replace('          ', ''), '') == before['run']
        assert {k: v for k, v in before.items() if k != 'run'} == {
            k: v for k, v in after.items() if k != 'run'
        }
    elif name == 'Install and tour the exact APK':
        assert after['with']['script'].replace(' --skip-observed-kart-preview', '') == before['with']['script']
        expected = dict(after)
        expected['with'] = dict(after['with'])
        expected['with']['script'] = before['with']['script']
        assert expected == before
    else:
        raise AssertionError(f'Unexpected modified step: {name}')
assert changed_steps == ['Live UI reader', 'Install and tour the exact APK']
assert after_job['timeout-minutes'] == before_job['timeout-minutes'] == '50'

frozen_root = ROOT.parent / 'unified-kart-preview-skip-078774dd-20261114' / 'followup-v2' / 'patched'
dependencies = []
for relative, sha, blob in (
    ('.github/probes/modernization_android_tour.py',
     '35a726e08e0614b22d6488ef8d6a57969078bf6e2fa1da8646b16324afcd1c53',
     '481c19f8c9b9ed15ee205a534d1cfc8797d06aa8'),
    ('tools/android_qa/tests/test_kart_preview_skip.py',
     '4e7bc4dc1b0af3430009705840e3ee52b1cec987cb2a5c802b6c74ccef358a1a',
     'ca2477afc4708385e705645613d45e3374f829f7'),
):
    info = identity((frozen_root / relative).read_bytes())
    assert info['sha256'] == sha and info['git_blob_sha'] == blob
    dependencies.append({'path': relative, **info, 'unchanged': True})

PATCHED.parent.mkdir(parents=True, exist_ok=True)
assert not PATCHED.exists()
PATCHED.write_bytes(changed.encode('utf-8'))
EVIDENCE.mkdir(exist_ok=True)
delta = ''.join(difflib.unified_diff(source.splitlines(True), changed.splitlines(True),
                                  fromfile='078774dd/' + str(RELATIVE),
                                  tofile='patched/' + str(RELATIVE)))
(ROOT / 'implementation-against-exact-078774dd.patch').write_text(delta, encoding='utf-8')
run = next(step['run'] for step in after_job['steps'] if step.get('name') == 'Live UI reader')
result = subprocess.run(['bash', '-n'], input=run, text=True, capture_output=True, check=False)
(EVIDENCE / 'bash-syntax.stdout').write_text(result.stdout, encoding='utf-8')
(EVIDENCE / 'bash-syntax.stderr').write_text(result.stderr, encoding='utf-8')
assert result.returncode == 0
assert BASE.read_bytes() == original
report = {
    'schema': 1,
    'status': 'PASS_STATIC_INTEGRATION',
    'repository': 'Ullmann27/lumo-lernen',
    'base_commit': '078774ddaf64808addaa4c6406f6a3c85b1f239a',
    'path': str(RELATIVE),
    'baseline': identity(original),
    'patched': identity(PATCHED.read_bytes()),
    'inverse_text_equality': True,
    'yaml_loader': 'PyYAML BaseLoader',
    'yaml_version': yaml.__version__,
    'top_level_non_jobs_equal': True,
    'all_other_jobs_equal': True,
    'other_jobs_count': len(old['jobs']) - 1,
    'changed_steps': changed_steps,
    'existing_step_count_preserved': len(before_job['steps']),
    'job_timeout_minutes_unchanged': 50,
    'preparation_timeout_minutes_unchanged': 8,
    'exact_frozen_dependencies': dependencies,
    'bash_syntax': {'command': ['bash', '-n'], 'stdin': 'Exact patched Live UI reader run body',
                    'returncode': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr},
    'new_tests_or_android_runs': False,
    'limitation': 'Static workflow integration only; actual 23 contracts and API35 result belong to QA3f89/run43587032836. No API37 result is inferred.',
}
(EVIDENCE / 'validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
