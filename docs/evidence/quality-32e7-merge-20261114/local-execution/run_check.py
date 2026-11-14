from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

import yaml


ROOT = Path('/home/agent/lumo-host-preflight-2708')
OUT = Path('/home/agent/lumo-host-merged-check-2708')
EXPECTED = 'dfc3e0a1ea20f1491e4844ecfa913c598e1c6c5f'


def git(*args: str) -> str:
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()


def snapshot() -> dict:
    index = ROOT / git('rev-parse', '--git-path', 'index')
    return {
        'head': git('rev-parse', 'HEAD'),
        'tree': git('rev-parse', 'HEAD^{tree}'),
        'tracked_status': git('status', '--porcelain', '--untracked-files=no'),
        'index_sha256': hashlib.sha256(index.read_bytes()).hexdigest(),
    }


def run(label: str, argv: list[str]) -> dict:
    path = OUT / (label + '.log')
    start = time.monotonic()
    with path.open('xb') as log:
        process = subprocess.run(argv, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=300)
    raw = path.read_bytes()
    text = raw.decode('utf-8')
    totals = re.findall(r'^Ran (\d+) tests? in ([0-9.]+)s$', text, flags=re.M)
    result = {
        'label': label,
        'argv': argv,
        'exit_code': process.returncode,
        'seconds': time.monotonic() - start,
        'log_bytes': len(raw),
        'log_sha256': hashlib.sha256(raw).hexdigest(),
        'reported_test_totals': totals,
    }
    print(json.dumps(result), flush=True)
    if process.returncode:
        print(text[-10000:], flush=True)
    return result


before = snapshot()
assert before['head'] == EXPECTED and not before['tracked_status'], before
assert json.loads((ROOT / 'config/godot-source.json').read_text())['revision'] == 'f052c2795b765265dbb6f5c27b9e92b557d39a39'
modules = [
    'scripts.tests.test_legacy_release_pin',
    'scripts.tests.test_candidate_2011_pin',
    'scripts.tests.test_connect_four_pipeline',
    'scripts.tests.test_connect_four_delivery',
    'scripts.tests.test_verify_unchanged_apk_diagnostic',
    'scripts.tests.test_connect_four_return_gate',
    'tools.android_qa.tests.test_connect_four_android_evidence',
    'tools.android_qa.tests.test_kart_continue_caption',
    'tools.android_qa.tests.test_kart_garage_evidence',
    'tools.android_qa.tests.test_update_2019_preservation',
]
results = [run('combined-contracts', ['python3', '-m', 'unittest', *modules, '-v'])]
results.append(run('actionlint', ['/workspace/scratch/e0abce7d2838/toolchain/actionlint/actionlint', '.github/workflows/lumo-connect-four-2020.yml']))
workflow = yaml.safe_load((ROOT / '.github/workflows/lumo-connect-four-2020.yml').read_text())
labels = (
    'Retry the acknowledged native exit after a transient Android refusal',
    'Require the additional pinned native Treasure wisp regression',
    'Require actual gameplay gates on the exact pinned native source',
    'Require acknowledged Connect Four return retry',
)
for index, label in enumerate(labels):
    matches = [step for job in workflow['jobs'].values() for step in job.get('steps', []) if step.get('name') == label]
    assert len(matches) == 1, label
    script = OUT / ('actual-step-' + str(index) + '.sh')
    script.write_text(matches[0]['run'])
    results.append(run('step-' + str(index) + '-bash-n', ['bash', '-n', str(script)]))
after = snapshot()
record = {
    'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'scope': 'Actual focused Python contracts and actual merged workflow syntax. No new full Flutter, native, APK, Android or device acceptance.',
    'before': before,
    'after': after,
    'source_and_index_unchanged': before == after,
    'results': results,
}
(OUT / 'result.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps({'source_and_index_unchanged': before == after, 'all_exits_zero': all(r['exit_code'] == 0 for r in results)}), flush=True)
raise SystemExit(0 if before == after and all(r['exit_code'] == 0 for r in results) else 1)
