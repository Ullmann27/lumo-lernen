from pathlib import Path
import hashlib
import json

ROOT = Path("/workspace/scratch/5987865ae883/qa/studio-28462-memory-authority-20261114")
ORIGINALS = ROOT / 'originals'
OUT = ROOT / 'verification'
def read(name):
    return json.loads((ORIGINALS / name).read_text())
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

authority = read('memory-pair/authority/authority-result.json')
native = read('memory-pair/native/memory-runtime-report.json')
owner = authority['owner']
saved_unfinished = read('memory-pair/authority/unfinished-reopen-before-round.json')
saved_completed = read('memory-pair/authority/paid-reopen-before-round.json')
saved_final = read('memory-pair/authority/round-' + owner + '.json')
stats = read('memory-pair/authority/stats-' + owner + '.json')
wallet = read('memory-pair/authority/wallet.json')
for item in [saved_unfinished, saved_completed, saved_final]:
    assert item['schema'] == 1 and item['game'] == 'memory' and item['owner'] == owner
unfinished = authority['unfinished_reopen']
assert saved_unfinished['id'] == unfinished['roundId'] == unfinished['restoredRoundId']
assert saved_unfinished['revision'] == 6 and saved_unfinished['paused'] is True
assert saved_unfinished['rewarded'] is False
assert saved_unfinished['rules']['phase'] == 'resolve'
assert saved_unfinished['rules']['remainingMs'] == unfinished['remainingMs'] == 550
assert saved_unfinished['rules']['faceUp'] == [True, True, False, False, False, False, False, False]
assert saved_completed == authority['completed_round']
assert saved_completed['paused'] is True and saved_completed['rewarded'] is True
assert saved_completed['rules']['phase'] == 'complete'
assert all(saved_completed['rules']['matched']) and all(saved_completed['rules']['faceUp'])
paid = authority['paid_reopen']
assert saved_final['id'] == paid['newRoundId'] and saved_final['id'] != saved_completed['id']
assert saved_final['revision'] == 29 and saved_final['paused'] is True and saved_final['rewarded'] is False
assert saved_final['rules']['phase'] == 'select'
assert saved_final['rules']['kindPairs'] == saved_final['rules']['lumoPairs'] == saved_final['rules']['kindMoves'] == 0
assert not any(saved_final['rules']['faceUp']) and not any(saved_final['rules']['matched'])
assert saved_final['rules']['difficulty'] == paid['difficulty'] == 'leicht'
assert saved_final['rules']['pack'] == paid['pack'] == 'alle'
assert stats == {'difficulty': 'leicht', 'best': {'schwer': 17, 'leicht': 4}, 'retained': 'original-field'}
assert wallet == authority['wallet']
assert wallet['stars'] == 2 and wallet['xp'] == 16 and len(wallet['ids']) == authority['award_calls'] == 1
assert wallet['ids'][0] == 'memory:' + owner + ':' + saved_completed['id']
sentinel = ORIGINALS / 'memory-pair/authority/other-child.json'
assert sentinel.read_bytes() == b'{"schema":1,"unrelatedChild":"preserve exact bytes"}'

fields = ['owner', 'token', 'roundId', 'revision', 'recordRevision', 'ack', 'rejected', 'paused', 'phase', 'turn', 'difficulty', 'pack']
bindings = []
for capture in native['captures']:
    name = 'memory-pair/native/' + capture['file'].replace('.png', '.layout.json')
    layout = read(name)
    assert layout['schema'] == 1 and layout['game'] == 'memory'
    assert layout['settled'] is True and layout['pending'] == 0
    assert layout['observation_source'] == 'platform_fixture'
    assert layout['window_px'] == layout['viewport_px'] == [960, 540]
    assert all(layout[k] == capture[k] for k in ['token', 'roundId', 'revision'])
    matches = [row['input_id'] for row in authority['states'] if all(row['state'].get(k) == layout.get(k) for k in fields)]
    assert matches, name
    bindings.append({'png': capture['file'], 'layout_entry': name, 'layout_sha256': sha(ORIGINALS / name), 'matching_authority_input_ids': matches, 'identity_fields': {k: layout[k] for k in fields}, 'settled': True, 'pending': 0, 'observation_source': layout['observation_source']})
assert len(bindings) == 8
assert native['return_observed'] == 3
report = {
    'schema': 1,
    'status': 'PASS_CURRENT_ORIGINAL_SAVES_AND_LAYOUT_BINDING',
    'host_sha': '28462a7547048b75fa114e6f5832248e54c94faa',
    'native_sha': '29080ef8cd1a5b385eeeec97976fbefd31280427',
    'run_id': 43626348519,
    'job_id': 132543177183,
    'artifact_id': 14126945691,
    'driver_path': 'tools/android_qa/memory_native_authority.dart',
    'driver_git_blob': '1126cbb3c26c7f4f4b48eb58910cdb30d73d1f0d',
    'driver_sha256': 'e3de35b76215e65923d7f45787f2b1351e9bc08c791741c016d8cc9ed4fecf9b',
    'unfinished_round': {'id': saved_unfinished['id'], 'revision': saved_unfinished['revision'], 'paused': True, 'phase': 'resolve', 'remaining_ms': 550},
    'completed_round': {'id': saved_completed['id'], 'revision': saved_completed['revision'], 'rewarded': True, 'kind_pairs': 4, 'lumo_pairs': 0},
    'final_new_round': {'id': saved_final['id'], 'revision': saved_final['revision'], 'paused_on_final_return': True, 'moves': 0, 'rewarded': False},
    'stats': stats,
    'qa_wallet': wallet,
    'other_child_fixture_byte_equality': True,
    'other_child_sha256': sha(sentinel),
    'layout_to_authority_bindings': bindings,
    'return_count': 3,
    'limits': ['QA file store and QA reward ledger; no Android SharedPreferences or real wallet test.', 'Synthetic owner and other-child sentinel; no real two-child migration.', 'Fixed simulation clock and desktop renderer; no physical frame-rate measurement.', 'No local Flutter, Dart or renderer invocation during this read-only review.'],
}
(OUT / 'saved-round-and-layout-binding.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'status': report['status'], 'layout_bindings': len(bindings), 'original_saved_round_snapshots': 3, 'qa_awards': 1, 'return_count': 3, 'other_child_fixture_byte_equality': True}, indent=2))
