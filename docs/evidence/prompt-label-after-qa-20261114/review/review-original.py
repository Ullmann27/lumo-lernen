#!/usr/bin/env python3
"""Read the original focused QA artifact; never execute a test or archive code."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import shlex
import struct
import sys

BASE = Path('/workspace/scratch/2708c7907f28/prompt-label-original-43603068259')
ORIGINAL = BASE / 'original'
HEAD = '21e0368603e38d1dfd063485f5307ec201f0d872'
TREE = '0a5042254cd27c70597952842fdc8d71b089b417'
PARENT = '1375da193af0152af64f91d86577aa9768cd50db'
PARENT_TREE = 'ebaf259b92a4c7923782e195c3a932112ce81027'
TEST = 'test/design/lumo_modernization_capture_test.dart'
RUN = '43603068259'
WORKFLOW = '.github/workflows/lumo-prompt-label-contrast-qa.yml'
PROMPT = 'lib/widgets/lumo/lumo_prompt_card.dart'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(data):
    return {
        'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
        'git_blob': hashlib.sha1(
            b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest(),
    }


def inventory():
    return {
        str(path.relative_to(ORIGINAL)): identity(path.read_bytes())
        for path in sorted(ORIGINAL.rglob('*')) if path.is_file()
    }


def parse_tree(data):
    entries = {}
    for line in data.splitlines():
        metadata, path = line.split(b'\t', 1)
        require(path not in entries, 'Repeated tracked source entry')
        entries[path] = metadata
    return entries


def read_json(path):
    return json.loads(path.read_text())


def main():
    before_inventory = inventory()
    archive = read_json(BASE / 'archive-index.json')
    require(archive['archive']['bytes'] == 37588911, 'Archive size mismatch')
    require(archive['archive']['sha256'] ==
            'a56100f13efd22974046aa94ec1d2d67549d92a025701b47e47d37e3ff0e6bc7',
            'Archive digest mismatch')
    require(archive['zip_crc_valid'] is True and archive['canonical_paths'] is True,
            'Missing completed ZIP integrity review')
    archive_members = {
        item['path']: {key: item[key] for key in ['bytes', 'sha256', 'git_blob']}
        for item in archive['members']
    }
    require(len(archive_members) == 60 and archive_members == before_inventory,
            'Extracted bytes differ from the verified original ZIP')

    original_index = read_json(ORIGINAL / 'original-index.json')
    require(original_index['repository'] == 'Ullmann27/lumo-lernen' and
            original_index['head_sha'] == HEAD and
            original_index['run_id'] == RUN and original_index['run_attempt'] == '1',
            'Original index source or run binding mismatch')
    listed = {item['path']: item for item in original_index['files']}
    require(len(listed) == len(original_index['files']) == 59 and
            set(listed) == set(before_inventory) - {'original-index.json'},
            'Original index roster mismatch')
    for path, row in listed.items():
        require(row['bytes'] == before_inventory[path]['bytes'] and
                row['sha256'] == before_inventory[path]['sha256'],
                'Original index byte identity mismatch: ' + path)

    source_before_bytes = (ORIGINAL / 'source-before.json').read_bytes()
    source_after_bytes = (ORIGINAL / 'source-after.json').read_bytes()
    require(source_before_bytes == source_after_bytes,
            'Before/after source snapshots differ')
    source = json.loads(source_before_bytes)
    expected_metadata = {
        'repository': 'Ullmann27/lumo-lernen',
        'ref': 'refs/heads/qa/lumo-prompt-label-contrast-20261114-2708',
        'run_id': RUN, 'run_attempt': '1', 'head_commit': HEAD, 'head_tree': TREE,
        'sole_parent': PARENT, 'base_tree': PARENT_TREE,
        'changes': ['A\t' + WORKFLOW, 'M\t' + PROMPT],
        'tracked_changes': '', 'untracked_source_inputs': [],
    }
    for key, value in expected_metadata.items():
        require(source.get(key) == value, 'Source metadata mismatch: ' + key)
    require(source['files'] == read_json(BASE / 'expected-source-bindings.json'),
            'Original source bindings differ from the reviewed immutable bytes')
    source_gate = read_json(ORIGINAL / 'source-verification.json')
    require(source_gate == {
        'status': 'PASS', 'source_before_after_identical': True,
        'head_commit': HEAD, 'head_tree': TREE,
    }, 'Original source gate mismatch')

    expected_tree = parse_tree((BASE / 'baseline-tracked-source-tree.txt').read_bytes())
    expected_tree[WORKFLOW.encode()] = b'100644 blob bfd93a088d3181444248e57e0ea5b7599921c242'
    expected_tree[PROMPT.encode()] = b'100644 blob 643c3bd6868da34550bbc9fa7761818c7b1e6afb'
    actual_tree = parse_tree((ORIGINAL / 'tracked-source-tree.txt').read_bytes())
    require(actual_tree == expected_tree,
            'Complete tracked-source inventory differs from exact baseline plus two reviewed changes')

    old_prompt = (ORIGINAL / 'prompt-card-before.dart').read_bytes()
    new_prompt = (ORIGINAL / 'prompt-card-after.dart').read_bytes()
    require(identity(old_prompt)['git_blob'] == '033fb56a1033b7659d6ca7e7386e7ae9cd1074fd' and
            identity(new_prompt)['git_blob'] == '643c3bd6868da34550bbc9fa7761818c7b1e6afb',
            'Original before/after product blobs differ')
    require(old_prompt.count(b'color: LumoColors.ink600,') == 1 and
            old_prompt.replace(b'color: LumoColors.ink600,', b'color: LumoColors.ink100,') == new_prompt,
            'Product change is not the sole reviewed color line')

    command = shlex.split((ORIGINAL / 'command.txt').read_text())
    require(len(command) == 7 and command[:3] == [
        'python3', 'scripts/run_full_flutter_acceptance.py', '--output'] and
        command[3].endswith('/focused') and command[4] == '--flutter' and
        command[5].endswith('/flutter') and command[6] == TEST,
        'Recorded runner command has a different scope')
    version = read_json(ORIGINAL / 'flutter-version.json')
    require(version['frameworkVersion'] == '3.44.9', 'Unexpected actual Flutter version')
    exit_code = int((ORIGINAL / 'runner-exit-code.txt').read_text())
    events = []
    non_json_lines = 0
    for line in (ORIGINAL / 'focused/flutter-machine.jsonl').read_text().splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            non_json_lines += 1
            continue
        if isinstance(event, dict):
            events.append(event)
    suites = [event['suite'] for event in events if event.get('type') == 'suite']
    require(len(suites) == 1 and suites[0]['path'].endswith('/' + TEST),
            'Actual Flutter suite differs from the one approved focus')
    helper = BASE / 'original-acceptance-reader.py'
    require(identity(helper.read_bytes())['git_blob'] ==
            '8d17cf8175ce13ef1d756526fa13c306c846ac72', 'Acceptance reader source mismatch')
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location('immutable_focus_acceptance_reader', helper)
    reader = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(reader)
    error_files = sorted(str(path.relative_to(ORIGINAL / 'focused'))
                         for path in (ORIGINAL / 'focused').rglob('*.error.txt'))
    replay = reader.summarize(events, exit_code, error_files)
    summary = read_json(ORIGINAL / 'focused/acceptance-summary.json')
    for key, value in replay.items():
        require(summary.get(key) == value, 'Original summary disagrees with exact reader: ' + key)
    require(replay['status'] == 'PASS' and replay['passed'] == 36 and
            not replay['failed'] and not replay['skipped'] and not error_files and
            exit_code == 0 and summary['scope'] == [TEST] and
            summary['runner_errors'] == [], 'Focused execution did not pass')
    sizes = {'fold-cover': (688, 1764), 'phone': (824, 1830), 'fold-open': (1380, 1658)}
    screens = ['rechentricks', 'achievements', 'journal', 'lumo_welt', 'foto_lektion',
               'reading_buddy', 'lumo_quest', 'lumo_magic', 'schreibcoach', 'schreibaufgabe']
    expected_pngs = {
        f'modernization/{screen}_{size}.png': dimensions
        for size, dimensions in sizes.items() for screen in screens
    }
    expected_pngs.update({
        f'modernization/trainer_{symbol}_{size}_{state}.png': dimensions
        for size, dimensions in sizes.items()
        for symbol in ['B', 'klein_a'] for state in ['leer', 'geuebt']
    })
    actual_pngs = {str(path.relative_to(ORIGINAL / 'focused')): path
                   for path in (ORIGINAL / 'focused').rglob('*.png')}
    require(set(actual_pngs) == set(expected_pngs) and len(actual_pngs) == 42 and
            summary['rendered_png_count'] == 42, 'Original focused PNG roster mismatch')
    frames = []
    for path, dimensions in sorted(expected_pngs.items()):
        data = actual_pngs[path].read_bytes()
        require(data[:16] == b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR' and
                struct.unpack('>II', data[16:24]) == dimensions,
                'Unexpected PNG dimensions/header: ' + path)
        frames.append({'path': path, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                       'width': dimensions[0], 'height': dimensions[1]})
    capture_gate = read_json(ORIGINAL / 'capture-verification.json')
    require(capture_gate['status'] == 'PASS' and capture_gate['scope'] == [TEST] and
            capture_gate['expected_passed'] == capture_gate['passed'] == 36 and
            capture_gate['expected_pngs'] == 42 and capture_gate['originals'] == frames,
            'Original capture gate does not match actual PNG bytes')
    after_inventory = inventory()
    require(before_inventory == after_inventory, 'An original was modified during read-only review')
    report = {
        'status': 'PASS', 'scope': 'Read-only original artifact verification and exact pure summary-reader replay; no tests or renderer executed',
        'host_commit': HEAD, 'host_tree': TREE, 'sole_parent': PARENT,
        'native_pin_unchanged_not_executed_here': 'e2d15dbc5f3709306decb139eeb70a1cf30c0b73',
        'run_id': int(RUN), 'run_attempt': 1, 'job_id': 132471773636,
        'artifact_id': 14116624494, 'archive_identity': archive['archive'],
        'archive_files_verified': len(before_inventory), 'original_index_entries_verified': len(listed),
        'complete_tracked_source_entries_verified': len(actual_tree),
        'specific_source_bindings_verified': len(source['files']),
        'source_before_after_identical': True, 'source_snapshot_identity': identity(source_before_bytes),
        'exact_acceptance_reader_blob': identity(helper.read_bytes())['git_blob'],
        'replayed_summary': replay, 'machine_json_events': len(events),
        'machine_non_json_lines': non_json_lines, 'actual_suite_paths': [row['path'] for row in suites],
        'actual_flutter_version': version['frameworkVersion'],
        'original_pngs_verified': len(frames),
        'all_original_files_unchanged_during_review': True,
        'visual_review': 'Separate independent review limited to three Schreibcoach before/after pairs',
        'limitations': [
            'No new tests, dependency install, renderer or Android execution',
            'No new visual WordCoach acceptance; unchanged focus does not render that screen',
            'No emoji-helper or emoji-font correction',
            'No claim that all42 PNGs received visual review',
            'No change to the frozen main1375/e2 candidate or PR491',
        ],
    }
    (BASE / 'read-only-original-review.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
