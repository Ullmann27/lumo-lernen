from collections import Counter
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SOURCE = '04a8e850d4c198e16ff758df614ce6e53eab4524'
TREE = '80a797c2b547ed72fc496600f7959f6ac4f5f9e6'
RUN = 43628840534
JOB = 132551912578


def read_json(path):
    return json.loads(path.read_text())


def identity(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()}


binding = read_json(ROOT / 'original-run-job-binding.json')
assert binding['expected_head'] == SOURCE and binding['expected_tree'] == TREE
assert binding['run']['id'] == RUN and binding['run']['head_sha'] == SOURCE
assert binding['run']['run_attempt'] == 1 and binding['attempt'] == 1
job = next(j for j in binding['jobs']['jobs'] if j['id'] == JOB)
assert job['run_id'] == RUN and job['head_sha'] == SOURCE and job['run_attempt'] == 1
full_step = next(s for s in job['steps'] if s['name'] == 'Full Flutter regression suite including every capture')
assert full_step['conclusion'] == 'success'
inventory = read_json(ROOT / 'archive-manifest.json')
assert inventory['source_sha'] == SOURCE and inventory['run_id'] == RUN
assert inventory['run_attempt'] == 1 and inventory['original_metadata'] == binding['artifact']
assert inventory['archive']['sha256'] == binding['artifact']['digest'].split(':', 1)[1]
assert inventory['archive']['bytes'] == binding['artifact']['size_in_bytes']
assert inventory['all_zip_member_crcs'] == 'PASS'

summary_path = ROOT / 'originals/acceptance-summary.json'
raw_path = ROOT / 'originals/flutter-machine.jsonl'
summary = read_json(summary_path)
events, auxiliary = [], []
for number, line in enumerate(raw_path.read_text().splitlines(), 1):
    try:
        parsed = json.loads(line)
    except json.JSONDecodeError:
        parsed = None
    if isinstance(parsed, dict):
        events.append((number, parsed))
    else:
        kind = 'blank' if not line.strip() else 'protocol_array' if isinstance(parsed, list) else 'other_text'
        auxiliary.append({'line': number, 'kind': kind})
starts = {}
for number, event in events:
    if event.get('type') == 'testStart':
        test = event['test']
        assert test['id'] not in starts
        starts[test['id']] = {'start_line': number, **test}
cases, completed_ids = [], set()
for number, event in events:
    if event.get('type') != 'testDone' or event.get('hidden'):
        continue
    test_id = event['testID']
    assert test_id not in completed_ids
    completed_ids.add(test_id)
    test = starts[test_id]
    cases.append({'name': test['name'], 'test_id': test_id,
                  'result': event['result'], 'skipped': event['skipped'],
                  'start_line': test['start_line'], 'done_line': number})
failed = [c for c in cases if c['result'] != 'success']
skipped = [c for c in cases if c['skipped']]
event_errors = [e for _, e in events if e.get('type') == 'error']
done = [e for _, e in events if e.get('type') == 'done']
assert not failed and not skipped and not event_errors
all_done = [e for _, e in events if e.get('type') == 'testDone']
assert len({e['testID'] for e in all_done}) == len(all_done)
assert set(starts) == {e['testID'] for e in all_done}
assert all(e['result'] == 'success' and not e['skipped'] for e in all_done)
assert len(done) == 1 and done[0]['success'] is True
assert summary['status'] == 'PASS' and summary['passed'] == len(cases)
assert summary['failed'] == [] and summary['skipped'] == []
assert summary['capture_error_files'] == [] and summary['runner_errors'] == []
assert summary['runner_completed_successfully'] is True and summary['flutter_exit_code'] == 0

expected_safari = [
    f'Live safari {answer} answer keeps its delayed continuation bound during {context}'
    for answer in ('correct', 'wrong')
    for context in ('word magic', 'safari round trip', 'unchanged safari', 'profile change')
]
required = expected_safari + [
    'd1_woerter real registry answer persists its exact subject and topic',
    'actual Diktat canvas and duplicate self-ratings persist one correct and one wrong word',
    'two complete actual Diktat sessions show twenty words and award each earned bonus without extra Daily',
    'routing table lists eleven unique portals and unique covers',
    'all eleven game portals dispatch each accessibility and touch tap once',
    'Spielewelt zeigt alle elf Spiele einschließlich Dorfwirtschaft',
]
critical = []
for name in required:
    matches = [c for c in cases if c['name'] == name]
    assert len(matches) == 1
    critical.append(matches[0])
village = [c for c in cases if c['name'].startswith('Actual games hub includes a direct village ')]
assert len(village) == 6

pngs = {m['path']: m for m in inventory['members'] if m['path'].lower().endswith('.png')}
assert len(pngs) == summary['rendered_png_count'] == inventory['png_count']
covered = set()
capture_groups = {}
for environment, group in summary['capture_png_counts'].items():
    prefix = group['directory'].rstrip('/') + '/'
    observed = {p for p in pngs if p.startswith(prefix)}
    assert len(observed) == group['pngs'], (environment, len(observed), group['pngs'])
    assert not (covered & observed)
    covered.update(observed)
    capture_groups[environment] = {'directory': group['directory'], 'pngs': len(observed)}
for environment, item in summary['capture_file_outputs'].items():
    assert item['created'] and item['path'] in pngs
    assert item['path'] not in covered
    covered.add(item['path'])
assert covered == set(pngs)
member_map = {m['path']: m for m in inventory['members']}
for path in (summary_path, raw_path):
    recorded = member_map[path.name]
    observed = identity(path)
    assert recorded['sha256'] == observed['sha256'] and recorded['bytes'] == observed['bytes']

report = {
    'status': 'PASS', 'source_sha': SOURCE, 'source_tree': TREE,
    'run_id': RUN, 'run_attempt': 1, 'job_id': JOB,
    'full_flutter_step': full_step,
    'passed': len(cases), 'failed': failed, 'skipped': skipped,
    'error_event_count': len(event_errors), 'terminal_done_events': done,
    'original_summary': identity(summary_path), 'original_jsonl': identity(raw_path),
    'original_artifact': binding['artifact'],
    'all_members_count': len(inventory['members']), 'rendered_png_count': len(pngs),
    'capture_groups': capture_groups, 'capture_file_outputs': summary['capture_file_outputs'],
    'critical_test_results': critical, 'six_village_capture_cases': village,
    'event_type_counts': dict(Counter(event.get('type') for _, event in events)),
    'all_started_and_completed_event_ids_match': True,
    'hidden_loading_completions': sum(bool(e.get('hidden')) for e in all_done),
    'auxiliary_line_counts': dict(Counter(row['kind'] for row in auxiliary)),
    'auxiliary_line_numbers': [row['line'] for row in auxiliary],
    'visual_scope': 'Image hashes, dimensions and inventory are not a visual review of all 566 images. Separate selected-original visual reviews record the pictures actually inspected.',
    'legacy_connect_capture_limit': 'The four games/connect_overview_* and games/connect_winglow_* fixture images are excluded as proof of played board or victory state. Current dedicated C4 captures require their own later artifact review.',
    'acceptance_limit': 'This report accepts the completed Flutter suite only. Native, Android, update and delivery results remain separate.',
}
(ROOT / 'independent-recount.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ('status', 'source_sha', 'run_id', 'run_attempt', 'passed', 'failed', 'skipped', 'error_event_count', 'rendered_png_count', 'auxiliary_line_counts')}))
