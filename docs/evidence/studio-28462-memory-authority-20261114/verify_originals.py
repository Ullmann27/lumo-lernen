from pathlib import Path
from collections import Counter
import hashlib
import json
import math
import re
import struct
import zipfile
from PIL import Image
from io import BytesIO

ROOT = Path('/workspace/scratch/5987865ae883/qa/studio-28462-memory-authority-20261114')
OUT = ROOT / 'verification'
OUT.mkdir(parents=True, exist_ok=True)
ORIGINALS = ROOT / 'originals'
ARCHIVE = ROOT / 'original-artifact.zip'
EXPECTED_SHA = '50ab9d04aa2067e149097811f366043f73aaa0e26594c10a8622013ed3895908'
EXPECTED_BYTES = 3943937
EXPECTED_SOURCE = {
    'host': {
        'commit': '28462a7547048b75fa114e6f5832248e54c94faa',
        'tree': '21cc39c37c96c8d76d46434b42b172e88ffb745e',
    },
    'native': {
        'commit': '29080ef8cd1a5b385eeeec97976fbefd31280427',
        'tree': '5ddbea2b1d5e76ed592a27c36079632d7f26cada',
    },
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(relative):
    return json.loads((ORIGINALS / relative).read_text())


def write(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


archive_data = ARCHIVE.read_bytes()
assert len(archive_data) == EXPECTED_BYTES
assert sha(archive_data) == EXPECTED_SHA
inventory = []
with zipfile.ZipFile(ARCHIVE) as archive:
    members = archive.infolist()
    assert len(members) == 73
    assert len({entry.filename for entry in members}) == len(members)
    for entry in members:
        assert not entry.is_dir()
        relative = Path(entry.filename)
        assert not relative.is_absolute() and '..' not in relative.parts
        data = archive.read(entry)  # zipfile verifies this exact member's CRC.
        local = (ORIGINALS / relative).read_bytes()
        assert local == data, entry.filename
        row = {
            'artifact_entry': entry.filename,
            'bytes': len(data),
            'sha256': sha(data),
            'archive_crc': format(entry.CRC, '08x'),
            'crc_read_verified': True,
            'local_bytes_equal_original_member': True,
        }
        if relative.suffix == '.png':
            assert data[:8] == b'\x89PNG\r\n\x1a\n'
            assert data[12:16] == b'IHDR'
            row['width'], row['height'] = struct.unpack('>II', data[16:24])
            with Image.open(BytesIO(data)) as decoded:
                decoded.load()
                assert decoded.size == (row['width'], row['height'])
                row['fully_decoded'] = True
        inventory.append(row)
assert len([row for row in inventory if 'width' in row]) == 28
by_entry = {row['artifact_entry']: row for row in inventory}

metadata = json.loads((ROOT / 'selected-artifact-metadata.json').read_text())
assert metadata['id'] == 14126945691 and metadata['size_in_bytes'] == EXPECTED_BYTES
assert metadata['digest'] == 'sha256:' + EXPECTED_SHA and metadata['expired'] is False
assert metadata['workflow_run']['id'] == 43626348519
assert metadata['workflow_run']['head_sha'] == EXPECTED_SOURCE['host']['commit']
job = next(row for row in json.loads((ROOT / 'terminal-jobs-original.json').read_text())['jobs'] if row['id'] == 132543177183)
assert job['status'] == 'completed' and job['conclusion'] == 'success'
assert job['run_id'] == 43626348519 and job['head_sha'] == EXPECTED_SOURCE['host']['commit']
for stamp, expected in [('HOST-SOURCE.txt', EXPECTED_SOURCE['host']['commit']), ('HOST-TREE.txt', EXPECTED_SOURCE['host']['tree']), ('NATIVE-SOURCE.txt', EXPECTED_SOURCE['native']['commit']), ('NATIVE-TREE.txt', EXPECTED_SOURCE['native']['tree'])]:
    assert (ORIGINALS / stamp).read_text().strip() == expected
messages = []
for log_path in ORIGINALS.rglob('*.log'):
    for line_number, line in enumerate(log_path.read_text().splitlines(), 1):
        if re.search(r'ERROR:|SCRIPT ERROR|Parse Error|WARNING:|ObjectDB|leaked', line):
            messages.append({'file': str(log_path.relative_to(ORIGINALS)), 'line': line_number, 'text': line})
assert not any(re.search(r'ERROR:|SCRIPT ERROR|Parse Error', item['text']) for item in messages)
write('engine-message-inventory.json', {'messages': messages, 'engine_errors': 0, 'warning_lines': len(messages)})

pair = read('memory-pair/pair-result.json')
authority = read('memory-pair/authority/authority-result.json')
native = read('memory-pair/native/memory-runtime-report.json')
view = read('memory-view/memory-view-result.json')
assert pair['success'] and authority['success'] and native['success']
assert pair['source_before'] == pair['source_after'] == EXPECTED_SOURCE
assert read('memory-pair/source-identity.json') == EXPECTED_SOURCE
assert pair['process_exit_codes'] == {'DartAuthority': 0, 'GodotMemory': 0}
assert native == read('memory-pair/authority/native-result.json')
assert pair['checks'] == native['checks'] == 243
assert isinstance(native['failures'], list) and not native['failures']
assert view['status'] == 'PASS' and isinstance(view['errors'], list) and not view['errors'] and view['checks'] == 7020

native_raw = native['native_original_requests']
requests = authority['requests']
inputs = native['inputs']
assert len(requests) == len(native_raw) == 19
assert len(inputs) == 57
assert len(authority['states']) == 32
states = {row['input_id']: row['state'] for row in authority['states']}
assert len(states) == 32
assert len(authority['tokens']) == len(set(authority['tokens'])) == 3
owner = authority['owner']
assert owner == 'a' * 64
last_sequences = {}
correlations = []
for index, row in enumerate(requests):
    raw = native_raw[index]
    request = json.loads(raw)
    assert raw == row['raw']
    assert request == row['request']
    down, up, emitted = inputs[index * 3:index * 3 + 3]
    assert down['pressed'] is True and up['pressed'] is False
    assert down['point'] == up['point']
    assert down['revision'] == up['revision'] == request['revision']
    assert down['clock_ms'] == up['clock_ms']
    assert down['label'] == up['label'] == emitted['label']
    assert emitted['original_request'] == raw
    point = down['point']
    assert len(point) == 2 and all(isinstance(v, (int, float)) and math.isfinite(v) for v in point)
    assert 0 <= point[0] < 960 and 0 <= point[1] < 540
    token = request['token']
    sequence = request['sequence']
    assert token in authority['tokens'] and re.fullmatch('[a-f0-9]{32}', token)
    assert type(sequence) is int and sequence == last_sequences.get(token, 0) + 1
    last_sequences[token] = sequence
    assert row['ack'] == sequence and row['rejected'] == 0
    state = states[row['input_id']]
    assert state['owner'] == owner and state['token'] == token
    assert state['ack'] == sequence and state['rejected'] == 0
    assert state['recordRevision'] == row['recordRevision']
    assert state['revision'] > request['revision']
    if request['action'] not in ('restart', 'difficulty', 'pack'):
        assert state['roundId'] == request['roundId']
    correlations.append({
        'ordinal': index + 1,
        'authority_input_id': row['input_id'],
        'label': down['label'],
        'point': point,
        'raw_sha256': sha(raw.encode()),
        'token': token,
        'round_id_before': request['roundId'],
        'round_id_after': state['roundId'],
        'action': request['action'],
        'sequence': sequence,
        'ack': row['ack'],
        'rejected': row['rejected'],
        'record_revision': row['recordRevision'],
        'exact_raw_equal_in_native_inputs_native_requests_and_authority': True,
        'matched_down_and_up_events': True,
    })

for row in authority['states']:
    state = row['state']
    assert state['owner'] == owner
    for card in state['cards']:
        if not card['faceUp'] and not card['matched']:
            assert card['motif'] is None

unfinished = authority['unfinished_reopen']
assert unfinished['roundId'] == unfinished['restoredRoundId'] == authority['initial_round']
assert unfinished['oldToken'] != unfinished['newToken']
assert unfinished['paused'] is True and unfinished['remainingMs'] == 550
completed = authority['completed_round']
assert completed['owner'] == owner and completed['rewarded'] is True
assert completed['rules']['kindPairs'] == 4 and completed['rules']['lumoPairs'] == 0
paid = authority['paid_reopen']
assert paid['completedRoundId'] == completed['id']
assert paid['newRoundId'] != paid['completedRoundId']
assert paid['newToken'] != paid['oldToken']
assert paid['difficulty'] == 'leicht' and paid['pack'] == 'alle'
assert paid['best'] == {'schwer': 17, 'leicht': 4}
assert authority['wallet'] == {
    'stars': 2,
    'xp': 16,
    'ids': ['memory:' + owner + ':' + completed['id']],
}
assert authority['award_calls'] == 1 and pair['qa_award_calls'] == 1
assert len(authority['closed_tokens']) == 3
assert set(authority['closed_tokens']) == set(authority['tokens'])

captures = native['captures'] + native['motion_frames']
assert len(native['captures']) == 8 and len(native['motion_frames']) == 12
for capture in captures:
    image = by_entry['memory-pair/native/' + capture['file']]
    assert image['sha256'] == capture['sha256']
    assert image['width'] == capture['width'] and image['height'] == capture['height']

terminal = (ORIGINALS / 'memory-pair/godot-runtime.log').read_text()
assert '[MemoryTableRuntime] PASS checks=244 inputs=57' in terminal
contract_text = (ORIGINALS / 'memory-authority-contract.log').read_text()
scheduler_text = (ORIGINALS / 'memory-scheduler-contract.log').read_text()
contract = json.loads(next(line.split(' ', 1)[1] for line in contract_text.splitlines()
                           if line.startswith('MEMORY_ROUND_CONTRACT ')))
scheduler = json.loads(next(line.split(' ', 1)[1] for line in scheduler_text.splitlines()
                            if line.startswith('MEMORY_TURN_SCHEDULER ')))
assert (contract['passed'], contract['checks'], contract['skipped']) == (30, 1694, 0)
assert (scheduler['passed'], scheduler['checks'], scheduler['skipped']) == (7, 13, 0)

notes = json.loads((ROOT / 'personal-visual-observations.json').read_text())
assert len(notes['findings']) == 19
assert len({row['artifact_entry'] for row in notes['findings']}) == 19
reviewed = []
for old in notes['findings']:
    assert old['reviewed'] is True
    row = by_entry[old['artifact_entry']]
    reviewed.append({
        **old,
        'sha256': row['sha256'],
        'bytes': row['bytes'],
        'width': row['width'],
        'height': row['height'],
        'original_member_byte_equality_verified': True,
        'visual_observation_time': 'Personally opened during this current 28462 review on 2026-11-14',
        'personally_opened_in_current_review': True,
    })

write('complete-original-member-hashes.json', {
    'schema': 1,
    'artifact_id': 14126945691,
    'archive_bytes': len(archive_data),
    'archive_sha256': EXPECTED_SHA,
    'members': inventory,
    'download_count_total': 1,
    'new_downloads': 0,
})
write('reviewed-original-images.json', {
    'schema': 1,
    'count': 19,
    'unique_artifact_entries': 19,
    'unique_png_hashes': len({row['sha256'] for row in reviewed}),
    'images': reviewed,
    'scope': 'Nineteen current original entries personally opened in this review; one shared PNG hash occurs under two artifact paths. No Android or FPS claim.',
})
report = {
    'schema': 1,
    'status': 'PASS_ORIGINAL_EVIDENCE_CORRELATION',
    'run_id': 43626348519,
    'job_id': 132543177183,
    'artifact_id': 14126945691,
    'sources': EXPECTED_SOURCE,
    'source_before_after_equal': True,
    'process_exit_codes': pair['process_exit_codes'],
    'archive_bytes': len(archive_data),
    'archive_sha256': EXPECTED_SHA,
    'members_crc_and_extracted_bytes_checked': len(inventory),
    'png_ihdr_hashes_and_full_decodes_checked': 28,
    'personally_opened_unique_png_hashes': len({row['sha256'] for row in reviewed}),
    'engine_messages': messages,
    'job_status': {'id': job['id'], 'status': job['status'], 'conclusion': job['conclusion'], 'completed_at': job['completed_at']},
    'personally_opened_current_original_entries': 19,
    'new_personal_openings_in_this_script': 0,
    'authority_contract': contract,
    'scheduler_contract': scheduler,
    'view_report_checks': view['checks'],
    'pair_report_checks_before_report_write_check': native['checks'],
    'pair_terminal_checks_including_report_write_check': 244,
    'native_inputs': len(inputs),
    'touch_pairs': 19,
    'exact_correlated_requests': correlations,
    'states': len(states),
    'tokens': authority['tokens'],
    'unfinished_reopen': unfinished,
    'paid_reopen': paid,
    'qa_wallet': authority['wallet'],
    'qa_award_calls': authority['award_calls'],
    'bounded_scope': pair['scope'],
    'shared_preferences_durability_fix_validation': False,
    'android_binder_or_two_child_migration_validation': False,
    'physical_fps_validation': False,
    'local_application_tests_executed': False,
    'this_execution': 'Read-only current original-byte and journal verification; no local renderer/Dart/Flutter invocation.',
}
write('original-journal-verification.json', report)
print(json.dumps({
    'status': report['status'],
    'archive_members': len(inventory),
    'request_correlations': len(correlations),
    'touch_pairs': 19,
    'states': len(states),
    'tokens': len(authority['tokens']),
    'current_personally_opened_entries_now_hash_bound': len(reviewed),
    'source_before_after_equal': True,
    'process_exit_codes': pair['process_exit_codes'],
    'new_execution_scope': 'Read-only original-byte/journal verification only',
}, ensure_ascii=False, indent=2))
