from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
root = Path(__file__).resolve().parent
artifact = root / 'artifact'
expected = {entry['path']: entry for entry in json.loads((root / 'expected-source-tree.json').read_text())}
head = '7136fd69d7343d6be1ff2171c26fa9d496665fda'
tree = 'e30bf5e130b41e8ca5588163d1e86de57b5ce6e3'
run = json.loads((root / 'run.original.json').read_text())
assert run['id'] == 43591310250 and run['head_sha'] == head
assert run['status'] == 'completed' and run['conclusion'] == 'success' and run['run_attempt'] == 1
assert run['event'] == 'push' and run['path'] == '.github/workflows/lumo-feature-connections.yml'
before = json.loads((artifact / 'source-before.json').read_text())
after = json.loads((artifact / 'source-after.json').read_text())
for value in (before, after):
    assert value['head'] == head and value['tree'] == tree
    assert value['expected_source_sha'] == head and not value['errors']
    assert int(value['run_id']) == 43591310250 and int(value['run_attempt']) == 1
    assert value['ref'] == 'refs/heads/integration/lumo-feature-connections-20261114'
    records = value['files']
    assert len(records) == len(expected) == len({entry['path'] for entry in records})
    for entry in records:
        original = expected[entry['path']]
        assert entry['mode'] == original['mode']
        assert entry['blob'] == entry['actual_blob'] == original['sha']
    phase = value['phase']
    index = (artifact / f'git-index-{phase}.original').read_bytes()
    assert hashlib.sha256(index).hexdigest() == value['index_sha256']
    entries = {}
    for row in index.split(b'\0'):
        if not row:
            continue
        metadata, raw_path = row.split(b'\t', 1)
        mode, sha, stage = metadata.decode().split()
        path = raw_path.decode()
        assert stage == '0' and path not in entries
        entries[path] = {'mode': mode, 'sha': sha}
    assert entries == {path: {'mode': entry['mode'], 'sha': entry['sha']} for path, entry in expected.items()}
    assert (artifact / f'git-status-{phase}.txt').read_bytes() == b''
for field in ('head', 'tree', 'index_sha256', 'files'):
    assert before[field] == after[field]

reader = Path('/tmp/lumo-root-recovery-1105/host-c4/scripts/run_full_flutter_acceptance.py')
data = reader.read_bytes()
blob = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
assert blob == expected['scripts/run_full_flutter_acceptance.py']['sha'] == '8d17cf8175ce13ef1d756526fa13c306c846ac72'
spec = importlib.util.spec_from_file_location('bound_flutter_summary', reader)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
events = []
non_event_lines = []
for number, line in enumerate((artifact / 'flutter.stdout.jsonl').read_text().splitlines(), 1):
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        non_event_lines.append(number)
        continue
    if isinstance(event, dict):
        events.append(event)
    else:
        non_event_lines.append(number)
exit_code = json.loads((artifact / 'flutter-result.json').read_text())['exit_code']
replay = module.summarize(events, exit_code, [])
original = json.loads((artifact / 'feature-test-summary.json').read_text())
assert all(original[key] == value for key, value in replay.items())
assert replay['status'] == 'PASS' and replay['passed'] == 22
assert replay['failed'] == [] and replay['skipped'] == [] and replay['runner_completed_successfully'] is True
assert original['source_sha'] == head and original['expected_cases'] == 22
assert original['non_event_stdout_lines'] == non_event_lines
assert original['event_errors'] == [] and not any(event.get('type') == 'error' for event in events)
assert json.loads((artifact / 'setup-result.json').read_text())['exit_code'] == 0
assets = json.loads((artifact / 'assets.stdout.log').read_text())['original_assets']
assert len(assets) == 6 and len({entry['path'] for entry in assets}) == 6
for entry in assets:
    assert entry['git_blob'] == expected[entry['path']]['sha']

result = {'schema': 1, 'status': 'EXACT_ORIGINALS_REPLAY_PASS', 'host': head, 'tree': tree,
          'run_id': 43591310250, 'attempt': 1, 'job_id': 132436420801,
          'passed_widget_cases': 22, 'skipped_cases': 0, 'failed_cases': 0,
          'all_tracked_source_records_bound_to_original_git_tree': len(expected),
          'source_and_serialized_index_before_after_equal': True,
          'original_asset_blobs': len(assets), 'raw_machine_events': len(events),
          'original_non_json_stdout_lines_retained': non_event_lines,
          'summary_replayed_with_exact_published_reader_blob': blob,
          'tests_rerun_by_reviewer': False, 'apk_or_device_acceptance': 'NOT_RUN'}
(root / 'independent-replay.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
