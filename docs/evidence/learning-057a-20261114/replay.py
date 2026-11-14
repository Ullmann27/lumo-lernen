#!/usr/bin/env python3
"""Replay the unchanged current delivery reader on original learning-audit bytes."""
import datetime
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ORIGINAL = BASE / 'original'
REPO = Path('/workspace/scratch/2708c7907f28/lumo-host-current')
SOURCE = '057a4e8d067872c4f3514b126aa04c3706d2e5b5'
TREE = 'a2ae17af283a76fb3b99f1a0899a0898e7157230'
RUN = 43607156921

def git(*args):
    return subprocess.check_output(['git', *args], cwd=REPO, text=True).strip()

def identity(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()}

assert git('rev-parse', 'HEAD') == SOURCE
assert git('rev-parse', 'HEAD^{tree}') == TREE
assert not git('diff', '--name-only', 'HEAD')
reader = REPO / 'scripts/verify_connect_four_delivery.py'
reader_before = identity(reader)
assert reader_before['git_blob'] == '214e21a6300b361985615c0a90b79d48a43ca2fd'
assert reader_before['git_blob'] == git('rev-parse', SOURCE + ':scripts/verify_connect_four_delivery.py')
index = json.loads((BASE / 'archive-index.json').read_text())
assert index['file_count'] == 7
before = {row['path']: identity(ORIGINAL / row['path']) for row in index['members']}
for row in index['members']:
    assert all(before[row['path']][key] == row[key] for key in ('bytes', 'sha256', 'git_blob'))
sys.path.insert(0, str(REPO / 'scripts'))
import verify_connect_four_delivery as delivery

started = datetime.datetime.now(datetime.timezone.utc).isoformat()
timer = time.monotonic()
result = delivery.checked_learning_audit(ORIGINAL, {
    'host_source': SOURCE, 'run_id': RUN, 'run_attempt': 1,
})
elapsed = time.monotonic() - timer
after = {path: identity(ORIGINAL / path) for path in before}
assert after == before
assert identity(reader) == reader_before
assert git('rev-parse', 'HEAD') == SOURCE and not git('diff', '--name-only', 'HEAD')
report = {
    'schema': 1, 'kind': 'original_current_learning_reader_replay',
    'performed': True, 'passed': True, 'started_at_utc': started,
    'reader_elapsed_seconds': elapsed, 'python': sys.version,
    'host': SOURCE, 'tree': TREE, 'run_id': RUN, 'run_attempt': 1,
    'artifact_id': 14119441036, 'archive': index['archive'],
    'reader': reader_before, 'result': result,
    'originals_before_and_after_identical': True,
    'original_files': before, 'reader_and_tracked_source_unchanged': True,
    'limitations': [
        'Replays original structural audit evidence using the unchanged committed reader.',
        'No new Dart, Flutter, Android, engine, renderer or application test was executed.',
        'No semantic teaching quality, official curriculum approval or enumeration of every variant is inferred.',
    ],
}
with (BASE / 'ROOT_READONLY_REPLAY.json').open('x') as output:
    output.write(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'passed': True, 'source': SOURCE, 'run': RUN,
                 'family_count': result['family_count'], 'samples': result['generated_samples'],
                 'structural_issues': result['structural_issues'], 'seconds': elapsed,
                 'original_files_unchanged': len(before)}, indent=2))
