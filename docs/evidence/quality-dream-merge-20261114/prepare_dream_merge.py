from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path('/home/agent/lumo-host-preflight-2708')
OUT = Path('/home/agent/lumo-host-dream-merge-2708')
BASE = '32e7efbff427fef64e90b3a1fcecd3b52f00af42'
OURS = '38c2fe8cb9e1b1021842e886c1a7cfa199e687ca'
THEIRS = '3d91bd8355a539c3c2413760959684cd3fee985a'
PATHS = (
    '.github/workflows/lumo-connect-four-2020.yml',
    'config/godot-source.json',
    'scripts/tests/test_candidate_2011_pin.py',
    'scripts/tests/test_connect_four_delivery.py',
    'scripts/verify_connect_four_delivery.py',
    'scripts/verify_legacy_release_pin.py',
    'tools/android_qa/tests/test_kart_garage_evidence.py',
)

def git(*args: str) -> bytes:
    return subprocess.check_output(['git', *args], cwd=ROOT)

assert git('rev-parse', 'HEAD').decode().strip() == OURS
assert not git('status', '--porcelain', '--untracked-files=no').strip()
assert git('merge-base', OURS, THEIRS).decode().strip() == BASE
OUT.mkdir(exist_ok=False)
records = []
for relative in PATHS:
    originals = {}
    for label, commit in (('base', BASE), ('ours', OURS), ('theirs', THEIRS)):
        raw = git('show', commit + ':' + relative)
        target = OUT / label / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        originals[label] = {'commit': commit, 'bytes': len(raw),
                            'blob': git('rev-parse', commit + ':' + relative).decode().strip(),
                            'sha256': hashlib.sha256(raw).hexdigest()}
    result = subprocess.run(['git', 'merge-file', '-p',
                             str(OUT/'ours'/relative), str(OUT/'base'/relative),
                             str(OUT/'theirs'/relative)], cwd=ROOT, capture_output=True)
    assert result.returncode >= 0 and result.returncode < 128, (relative, result.stderr)
    target = OUT/'automatic'/relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(result.stdout)
    row = {'path': relative, 'originals': originals,
           'merge_file_exit_code': result.returncode,
           'automatic_sha256': hashlib.sha256(result.stdout).hexdigest(),
           'automatic_bytes': len(result.stdout)}
    records.append(row)
    print(json.dumps({'path': relative, 'merge_exit': result.returncode,
                      'same_ours_theirs': originals['ours']['blob'] == originals['theirs']['blob']}), flush=True)
(OUT/'source-records.json').write_text(json.dumps({
    'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'base': BASE, 'ours': OURS, 'theirs': THEIRS, 'records': records,
    'scope': 'Original source materialization and actual git merge-file output; no product source modified or test acceptance claimed.'
}, indent=2) + '\n')
