import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
ORIGINALS = ROOT / 'originals'
SOURCE = '6b3047b7979dfb86d837e74a21b0fd890e4f9e66'
TREE = '8b0c31a26207068c28658e14c6535c39a51cf95b'
RUN = 43616035099
JOB = 132511176199


def read_json(path):
    return json.loads(path.read_text())


def identity(path):
    data = path.read_bytes()
    return {
        'bytes': len(data),
        'sha256': hashlib.sha256(data).hexdigest(),
        'git_blob': hashlib.sha1(
            b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest(),
    }


api = read_json(ROOT / 'original-api-bindings.json')
assert api['run']['id'] == RUN and api['run']['head_sha'] == SOURCE
assert api['run']['run_attempt'] == 1 and api['run']['conclusion'] == 'success'
job = api['jobs']['jobs'][0]
assert job['id'] == JOB and job['head_sha'] == SOURCE
assert job['run_attempt'] == 1 and job['conclusion'] == 'success'
assert api['artifact']['workflow_run']['head_sha'] == SOURCE
assert api['artifact']['workflow_run']['id'] == RUN
before = read_json(ORIGINALS / 'source-before.json')
after = read_json(ORIGINALS / 'source-after.json')
assert before['head'] == SOURCE and before['tree'] == TREE
assert before['run_id'] == str(RUN) and before['run_attempt'] == '1'
assert not before['errors'] and not after['errors']
assert all(before[k] == after[k] for k in ('head', 'tree', 'index_sha256', 'files'))
assert (ORIGINALS / 'git-index-before.original').read_bytes() == (
    ORIGINALS / 'git-index-after.original').read_bytes()
source_files = {entry['path']: entry for entry in before['files']}
assert source_files['test/feature_permission_regression_test.dart']['blob'] == api['expected_test_blob']
assert source_files['lib/features/live/lumo_live_pro_screen.dart']['blob'] == api['expected_product_blob']

events, non_events = [], []
for line_number, line in enumerate(
        (ORIGINALS / 'flutter.stdout.jsonl').read_text().splitlines(), 1):
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        event = None
    if isinstance(event, dict):
        events.append((line_number, event))
    else:
        non_events.append(line_number)
starts = {}
for line_number, event in events:
    if event.get('type') == 'testStart':
        test = event['test']
        assert test['id'] not in starts
        starts[test['id']] = {'start_line': line_number, **test}
cases, finished_ids = [], set()
for line_number, event in events:
    if event.get('type') != 'testDone' or event.get('hidden'):
        continue
    test_id = event['testID']
    assert test_id not in finished_ids
    finished_ids.add(test_id)
    test = starts[test_id]
    cases.append({
        'name': test['name'], 'test_id': test_id,
        'result': event['result'], 'skipped': event['skipped'],
        'start_line': test['start_line'], 'done_line': line_number,
        'suite_id': test['suiteID'],
    })
assert len(cases) == 30
assert all(c['result'] == 'success' and not c['skipped'] for c in cases)
assert not [e for _, e in events if e.get('type') == 'error']
done = [e for _, e in events if e.get('type') == 'done']
assert len(done) == 1 and done[0]['success'] is True
summary = read_json(ORIGINALS / 'feature-test-summary.json')
assert summary['status'] == 'PASS' and summary['passed'] == len(cases)
assert not summary['failed'] and not summary['skipped'] and not summary['event_errors']
assert summary['source_sha'] == SOURCE and summary['expected_cases'] == 30
assert summary['runner_completed_successfully'] is True
assert summary['flutter_exit_code'] == 0
assert read_json(ORIGINALS / 'flutter-result.json')['exit_code'] == 0
safari = []
for name in api['expected_safari']:
    matches = [c for c in cases if c['name'] == name]
    assert len(matches) == 1
    safari.append(matches[0])
assert len(safari) == 8
report = {
    'status': 'PASS', 'scope': 'The actual 30 focused feature cases only',
    'source_sha': SOURCE, 'tree': TREE, 'run_id': RUN, 'run_attempt': 1,
    'job_id': JOB, 'passed': len(cases), 'failed': [], 'skipped': [],
    'cases': cases, 'safari_cases': safari, 'non_event_lines': non_events,
    'source_unchanged': True, 'tracked_files': len(before['files']),
    'bound_product_blob': api['expected_product_blob'],
    'bound_test_blob': api['expected_test_blob'],
    'red_evidence_commit': api['red_evidence_commit'],
    'one_line_repair_commit': api['repair_commit'],
    'limitations': 'No full Flutter, Native, Android or release acceptance is inferred from this focused feature result.',
}
(ROOT / 'independent-recount.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n')
manifest = {
    'source_sha': SOURCE, 'source_tree': TREE, 'run_id': RUN, 'run_attempt': 1,
    'job_id': JOB, 'artifact': api['artifact'],
    'archive': identity(ROOT / 'original-artifact-14122252221.zip'),
    'job_log': identity(ROOT / 'job-132511176199-original.log'),
    'original_members': [
        {'path': p.relative_to(ORIGINALS).as_posix(), **identity(p)}
        for p in sorted(ORIGINALS.rglob('*')) if p.is_file()
    ],
    'crc_check': 'PASS', 'source_snapshot_equality': 'PASS',
    'widget_result': 'PASS: 30 passed, 0 failed, 0 skipped',
}
assert manifest['archive']['sha256'] == api['artifact']['digest'].split(':', 1)[1]
assert manifest['archive']['bytes'] == api['artifact']['size_in_bytes']
(ROOT / 'artifact-and-source-manifest.json').write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ('status', 'source_sha', 'run_id', 'run_attempt', 'passed', 'failed', 'skipped', 'tracked_files')}))
