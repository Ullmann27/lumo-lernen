import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
ORIGINALS = ROOT / 'originals'
SOURCE = '93bd9b7804e2c352303d58552cc48e0a89a1c3cb'
TREE = 'ad9c129f91bd2ec8a7ee010be49ab626481f77d8'
RUN = 43615128301
JOB = 132508389205


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
assert api['run']['id'] == RUN
assert api['run']['head_sha'] == SOURCE
assert api['run']['run_attempt'] == 1
assert api['run']['conclusion'] == 'failure'
assert api['jobs']['jobs'][0]['id'] == JOB
assert api['jobs']['jobs'][0]['conclusion'] == 'failure'
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
failed = [c['name'] for c in cases if c['result'] != 'success']
passed = [c['name'] for c in cases if c['result'] == 'success' and not c['skipped']]
skipped = [c['name'] for c in cases if c['skipped']]
assert len(cases) == 30 and len(passed) == 26 and len(failed) == 4 and not skipped
summary = read_json(ORIGINALS / 'feature-test-summary.json')
assert summary['status'] == 'FAIL' and summary['passed'] == len(passed)
assert summary['failed'] == failed and summary['skipped'] == skipped
assert summary['source_sha'] == SOURCE and summary['expected_cases'] == 30
assert read_json(ORIGINALS / 'flutter-result.json')['exit_code'] == 1
safari = [next(c for c in cases if c['name'] == name)
          for name in api['expected_safari']]
assert len(safari) == 8
for case in safari:
    expected = 'error' if ' correct answer ' in case['name'] else 'success'
    assert case['result'] == expected and not case['skipped']
exceptions = []
for line_number, event in events:
    if event.get('type') == 'print' and 'EXCEPTION CAUGHT' in event.get('message', ''):
        assert event['testID'] in [c['test_id'] for c in safari if c['result'] == 'error']
        assert 'feature_permission_regression_test.dart:599:9' in event['message']
        exceptions.append({'line': line_number, **event})
assert len(exceptions) == 4
report = {
    'status': 'ORIGINAL_FAILURE_CONFIRMED', 'source_sha': SOURCE, 'tree': TREE,
    'run_id': RUN, 'run_attempt': 1, 'job_id': JOB, 'passed': len(passed),
    'failed': failed, 'skipped': skipped, 'cases': cases, 'safari_cases': safari,
    'exceptions': exceptions, 'non_event_lines': non_events,
    'source_unchanged': True, 'tracked_files': len(before['files']),
    'scope_limit': 'All four correct cases stop at the common reward-route removal assertion before the continuation-specific mode/profile action. No corrected widget run has occurred.',
    'runtime_review': {
        'sdk': 'Flutter 3.44.9', 'sources': api['sdk'],
        'mechanism': 'An idle-started ticker first records its start timestamp in its first frame. Automated pump(duration) advances fake time before drawing that frame. A zero-duration pump after the actual tap starts the reverse route before the unchanged 300ms pump.',
        'forward_route_ms': 250, 'default_reverse_route_ms': 300,
    },
}
(ROOT / 'independent-recount.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n')
manifest = {
    'source_sha': SOURCE, 'source_tree': TREE, 'run_id': RUN, 'run_attempt': 1,
    'job_id': JOB, 'artifact': api['artifact'],
    'archive': identity(ROOT / 'original-artifact-14121736536.zip'),
    'job_log': identity(ROOT / 'job-132508389205-original.log'),
    'original_members': [
        {'path': p.relative_to(ORIGINALS).as_posix(), **identity(p)}
        for p in sorted(ORIGINALS.rglob('*')) if p.is_file()
    ],
    'crc_check': 'PASS', 'source_snapshot_equality': 'PASS',
    'widget_result': 'FAIL: 26 passed, 4 failed, 0 skipped',
}
assert manifest['archive']['sha256'] == api['artifact']['digest'].split(':', 1)[1]
assert manifest['archive']['bytes'] == api['artifact']['size_in_bytes']
(ROOT / 'artifact-and-source-manifest.json').write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ('status', 'source_sha', 'run_id', 'run_attempt', 'passed', 'failed', 'skipped', 'tracked_files')}))
