from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

ROOT = Path('/home/agent/lumo-host-preflight-2708')
OUT = Path('/home/agent/lumo-aab-flutter-2708')
EXPECTED = 'aab09275ec6b5808de9be539ca4e1a7e70921249'


def git(*args: str) -> str:
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()


def source_state() -> dict:
    index = ROOT / git('rev-parse', '--git-path', 'index')
    status = git('status', '--porcelain', '--untracked-files=no')
    return {'head': git('rev-parse', 'HEAD'), 'tree': git('rev-parse', 'HEAD^{tree}'),
            'tracked_status': status, 'index_sha256': hashlib.sha256(index.read_bytes()).hexdigest()}


def original_state() -> dict:
    return {name: hashlib.sha256((OUT/'originals'/name).read_bytes()).hexdigest()
            for name in ('acceptance-summary.json', 'flutter-machine.jsonl')}


before_source, before_originals = source_state(), original_state()
assert before_source['head'] == EXPECTED and not before_source['tracked_status']
helper = ROOT/'scripts/run_full_flutter_acceptance.py'
helper_bytes = helper.read_bytes()
assert helper_bytes == subprocess.check_output(['git', 'show', EXPECTED+':scripts/run_full_flutter_acceptance.py'], cwd=ROOT)
spec = importlib.util.spec_from_file_location('actual_frozen_flutter_runner', helper)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
summary = json.loads((OUT/'originals/acceptance-summary.json').read_text())
inventory = json.loads((OUT/'archive-inspection.json').read_text())
assert inventory['candidate_host'] == EXPECTED and inventory['run_id'] == 43590864772
assert inventory['artifact_id'] == 14112921501 and inventory['crc_verified']
members = {entry['path']: entry for entry in inventory['members']}
assert len(members) == len(inventory['members']) == 548
for name, digest in before_originals.items():
    assert digest == members[name]['sha256']
events, non_json_lines = [], []
for number, line in enumerate((OUT/'originals/flutter-machine.jsonl').read_text().splitlines(), start=1):
    try:
        value = json.loads(line)
    except json.JSONDecodeError:
        non_json_lines.append({'line_number': number, 'text': line})
        continue
    if isinstance(value, dict):
        events.append(value)
    else:
        non_json_lines.append({'line_number': number, 'text': line})
errors = sorted(path for path in members if path.endswith('.error.txt'))
recomputed = module.summarize(events, summary['flutter_exit_code'], errors)
for key, value in recomputed.items():
    assert summary[key] == value, (key, summary[key], value)
assert recomputed['status'] == 'PASS' and recomputed['passed'] == 2586
assert summary['runner_errors'] == []
pngs = [path for path in members if path.endswith('.png')]
assert len(pngs) == summary['rendered_png_count'] == 546
for capture in summary['capture_png_counts'].values():
    assert sum(path.startswith(capture['directory']+'/') for path in pngs) == capture['pngs']
for capture in summary['capture_file_outputs'].values():
    assert (capture['path'] in members) == capture['created']
names, finished = {}, {}
for event in events:
    if event.get('type') == 'testStart':
        names[event['test']['id']] = event['test']
    elif event.get('type') == 'testDone':
        assert event['testID'] not in finished, 'Duplicate testDone event'
        finished[event['testID']] = event
target = [(key, value) for key, value in names.items()
          if value['name'] == 'all allowed cumulative math topics preserve exact selection']
assert len(target) == 1
math_id, math_start = target[0]
math_done = finished[math_id]
assert math_done['result'] == 'success' and not math_done.get('skipped') and not math_done.get('hidden')
done_events = [event for event in events if event.get('type') == 'done']
assert len(done_events) == 1 and done_events[0]['success'] is True
assert not [event for event in events if event.get('type') == 'error']
after_source, after_originals = source_state(), original_state()
assert before_source == after_source and before_originals == after_originals
record = {
    'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'artifact_id': 14112921501, 'run_id': 43590864772, 'run_attempt': 1,
    'artifact_sha256': inventory['archive_sha256'],
    'helper_git_blob': git('rev-parse', EXPECTED+':scripts/run_full_flutter_acceptance.py'),
    'helper_sha256': hashlib.sha256(helper_bytes).hexdigest(),
    'before_source': before_source, 'after_source': after_source,
    'before_originals': before_originals, 'after_originals': after_originals,
    'source_and_originals_unchanged': True, 'recomputed_summary': recomputed,
    'event_counts': dict(Counter(event.get('type') for event in events)),
    'terminal_done_event': done_events[0], 'non_json_lines': non_json_lines,
    'math_exact_topic_test': {'start': math_start, 'done': math_done},
    'capture_inventory_matches_summary': True, 'rendered_png_count': len(pngs),
    'process_exit_code_source': 'Original CI acceptance-summary.json; not a new local Flutter process.',
    'scope': 'Read-only replay of the exact committed parser against the original machine event stream and original archive inventory. No tests rerun, no physical-device or whole-image visual approval.'
}
(OUT/'root-replay.json').write_text(json.dumps(record, indent=2, ensure_ascii=False)+'\n')
print(json.dumps({'status':recomputed['status'],'passed':recomputed['passed'],
                  'failed':len(recomputed['failed']),'skipped':len(recomputed['skipped']),
                  'pngs':len(pngs),'math_exact_topic_test_success':True,
                  'source_and_originals_unchanged':True,'non_json_line_count':len(non_json_lines)}))
