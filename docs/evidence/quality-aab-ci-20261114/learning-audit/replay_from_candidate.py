from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path('/home/agent/lumo-host-preflight-2708')
OUT = Path('/home/agent/lumo-aab-learning-audit-2708')
ORIGINALS = OUT/'originals'
EXPECTED = 'aab09275ec6b5808de9be539ca4e1a7e70921249'

def git(*args: str) -> str:
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()

def originals() -> dict:
    return {p.relative_to(ORIGINALS).as_posix(): {'bytes': p.stat().st_size,
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in sorted(ORIGINALS.rglob('*')) if p.is_file()}

def source() -> dict:
    index = ROOT/git('rev-parse', '--git-path', 'index')
    return {'commit': git('rev-parse', 'HEAD'), 'tree': git('rev-parse', 'HEAD^{tree}'),
            'tracked_status': git('status', '--porcelain', '--untracked-files=no'),
            'index_sha256': hashlib.sha256(index.read_bytes()).hexdigest()}

before_source, before_originals = source(), originals()
assert before_source['commit'] == EXPECTED and not before_source['tracked_status']
helper = ROOT/'scripts/verify_connect_four_delivery.py'
raw = helper.read_bytes()
assert raw == subprocess.check_output(['git', 'show', EXPECTED+':scripts/verify_connect_four_delivery.py'], cwd=ROOT)
assert hashlib.sha256(raw).hexdigest() == 'f1237d9f4e48ed0cf3253b67768d1d4aad947be32da2158be7df6b1f8cb6dc2a'
sys.path.insert(0, str(ROOT/'scripts'))
spec = importlib.util.spec_from_file_location('actual_candidate_delivery', helper)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
started = time.monotonic()
result = module.checked_learning_audit(ORIGINALS, {
    'host_source': EXPECTED, 'run_id': 43590864772, 'run_attempt': 1,
})
after_source, after_originals = source(), originals()
assert before_source == after_source and before_originals == after_originals
record = {
    'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'seconds': time.monotonic()-started,
    'helper_git_blob': git('rev-parse', EXPECTED+':scripts/verify_connect_four_delivery.py'),
    'helper_sha256': hashlib.sha256(raw).hexdigest(),
    'before_source': before_source, 'after_source': after_source,
    'before_originals': before_originals, 'after_originals': after_originals,
    'source_and_originals_unchanged': True, 'recomputed_result': result,
    'scope': 'Actual read-only replay of the original current-candidate audit using its committed source verifier. No new Dart generation, semantic curriculum or Android approval.'
}
(OUT/'root-replay.json').write_text(json.dumps(record, indent=2)+'\n')
print(json.dumps({'status':'PASS','family_count':result['family_count'],
                  'generated_samples':result['generated_samples'],
                  'structural_issues':result['structural_issues'],
                  'source_and_originals_unchanged':True,'seconds':record['seconds']}))
