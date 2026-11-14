"""Read unchanged, bound diagnostic evidence; never invoke ADB or a renderer."""
from __future__ import annotations
import ast
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import stat
import subprocess
import sys
import time
import traceback
import PIL

ROOT = Path(__file__).resolve().parents[1]
ORIGINALS = ROOT / 'originals'
READER = ROOT / 'reader'
PARENT_SOURCE = Path('/workspace/scratch/909ddb52fe7b/lumo-village-return-diagnostic')
QA = '91b5aece4060cd625b27e4cfa967122b5d4b5b92'
QA_TREE = 'b3fecc83c5e58471fb2be25dc1d1015937505961'
HOST = '6b3047b7979dfb86d837e74a21b0fd890e4f9e66'
HOST_TREE = '8b0c31a26207068c28658e14c6535c39a51cf95b'
NATIVE = '84789d0c2c6fb4b6ecd2897ce1951b89f958b604'
APK = '9c64ae2f866c1eee832a96baba56d8d3dc314cec79c69c7c1781bb803111a765'
PCK = '99c68b1d68e4c8701c7e7e69f13137ff2b7f4d4a204c1a4a8f1bb0766e2720a4'


def require(value, message):
    if not value:
        raise ValueError(message)


def read(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate JSON key: ' + key)
            result[key] = value
        return result
    def nonfinite(value):
        raise ValueError('Nonfinite JSON: ' + value)
    return json.loads(path.read_text(), object_pairs_hook=unique, parse_constant=nonfinite)


def record(path):
    require(path.is_file() and not path.is_symlink(), 'Not a regular original: ' + str(path))
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()}


def snapshot(root):
    result = {}
    for path in sorted(root.rglob('*')):
        require(not path.is_symlink(), 'Unexpected symlink: ' + str(path))
        if path.is_file():
            row = record(path)
            result[path.relative_to(root).as_posix()] = {
                'bytes': row['bytes'], 'mode': stat.S_IMODE(path.stat().st_mode), 'sha256': row['sha256']}
    return result


def save(name, data):
    (ROOT / 'replay' / name).write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + '\n')


def git(*arguments):
    return subprocess.check_output(['git', '-C', str(PARENT_SOURCE), *arguments],
                                   env=dict(os.environ, GIT_OPTIONAL_LOCKS='0')).decode().strip()


def parent_snapshot(source_binding):
    index = Path(git('rev-parse', '--git-path', 'index'))
    if not index.is_absolute():
        index = PARENT_SOURCE / index
    return {'actual_head': git('rev-parse', 'HEAD'), 'actual_tree': git('rev-parse', 'HEAD^{tree}'),
            'tracked_status': git('status', '--porcelain', '--untracked-files=no'),
            'raw_index': record(index),
            'files': {row['path']: record(PARENT_SOURCE / row['path']) for row in source_binding['files']}}


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    started = time.monotonic()
    source_binding = read(ROOT / 'metadata/qa-reader-source-binding.json')
    original_before = snapshot(ORIGINALS)
    require(original_before == read(ROOT / 'replay/original-files-before.json'), 'Original snapshot changed before replay')
    reader_before = snapshot(READER)
    parent_before = parent_snapshot(source_binding)
    save('reader-source-before.json', reader_before)
    save('parent-source-before.json', parent_before)
    result = {
        'schema': 1, 'scope': 'Independent offline reading of actual unchanged-6b API35 diagnostic originals',
        'qa_source': QA, 'qa_tree': QA_TREE, 'qa_run': 43629575654, 'qa_attempt': 1,
        'android_job': 132553315080, 'apk_source': HOST, 'apk_tree': HOST_TREE, 'native_source': NATIVE,
        'artifact_id': 14128089386, 'seven_job_acceptance': False,
        'runtime': {'python': platform.python_version(), 'pillow': PIL.__version__,
                    'platform': platform.platform(), 'ci_pillow': '12.3.0'},
        'new_engine_emulator_adb_or_capture_runs': 0,
        'limits': ['No new APK binary download or apksigner invocation; prior exact APK/PCK receipts are cross-bound.',
                   'QA source is QA91; the read-only local materialization has actual HEAD325, not QA91.',
                   'The unchanged full C4 reader must reject the original FAIL report.',
                   'No later original mailbox observation exists; persistent leak and later cleanup remain unproved.',
                   'No C4 reopen, second return, completed win, physical-device performance or release acceptance.']}
    try:
        tree = read(ROOT / 'metadata/qa-fulltree-original.json')
        require(tree['sha'] == QA_TREE and tree['truncated'] is False, 'QA full tree is not exact/untruncated')
        blobs = {row['path']: row for row in tree['tree'] if row['type'] == 'blob'}
        for row in source_binding['files']:
            actual = record(READER / row['path'])
            require(all(actual[key] == row[key] for key in ('bytes', 'sha256', 'git_blob')), 'Reader bytes differ: ' + row['path'])
            require(blobs[row['path']]['sha'] == row['git_blob'] and blobs[row['path']]['mode'] == row['mode'],
                    'Reader is not bound to QA91 blob/mode: ' + row['path'])
            require(parent_before['files'][row['path']] == actual, 'Parent materialized source differs: ' + row['path'])
        sys.path.insert(0, str(READER / 'tools/android_qa'))
        import connect_four_android_evidence as c4
        import village_android_evidence as village
        binding_reader = load_module('diagnostic_binding', READER / 'scripts/verify_unchanged_6b_village_diagnostic.py')
        before = read(ORIGINALS / 'candidate-and-probe-binding.json')
        after = read(ORIGINALS / 'candidate-and-probe-binding-after.json')
        require(before == after and before['status'] == 'BOUND', 'Pre/post source/APK receipts differ or are unbound')
        candidate = binding_reader.verify_candidate(
            read(ORIGINALS / 'binding-inputs/candidate/run.json'),
            read(ORIGINALS / 'binding-inputs/candidate/jobs.json'),
            read(ORIGINALS / 'binding-inputs/candidate/artifacts.json'), c4)
        qa = binding_reader.verify_qa(
            read(ORIGINALS / 'binding-inputs/qa/run.json'), read(ORIGINALS / 'binding-inputs/qa/jobs.json'),
            source=QA, run_id=43629575654, attempt=1, job_name='unchanged-6b-main-api35')
        require(candidate == before['candidate_build'] and qa == before['diagnostic_qa'], 'Original metadata binding differs')
        require(qa['tree'] == QA_TREE and qa['job_id'] == 132553315080, 'Diagnostic job/tree differs')
        for name, commit, expected_tree in [('qa', QA, QA_TREE), ('candidate', HOST, HOST_TREE)]:
            receipt = before['git_sources'][name]
            require(receipt['commit'] == commit and receipt['tree'] == expected_tree
                    and receipt['tracked_source_clean'] is True, 'Recorded source cleanliness or identity differs')
        expected_qa_paths = set(binding_reader.QA_FILES) | {'config/godot-source.json', 'pubspec.yaml'}
        expected_qa_paths.update(path for path in blobs if path.endswith('.py') and '/tests/' not in path
                                and path.startswith(('.github/probes/', 'scripts/probes/', 'tools/android_qa/')))
        actual_qa = before['source_files']['qa']
        require(len({row['path'] for row in actual_qa}) == len(actual_qa)
                and {row['path'] for row in actual_qa} == expected_qa_paths, 'Diagnostic source inventory is incomplete')
        for row in actual_qa:
            require(blobs[row['path']]['sha'] == row['git_blob']
                    and blobs[row['path']]['size'] == row['bytes'], 'Recorded QA blob differs: ' + row['path'])
        candidate_files = before['source_files']['candidate']
        require([row['path'] for row in candidate_files] == ['config/godot-source.json', 'pubspec.yaml'],
                'Candidate source file list differs')
        for i, row in enumerate(candidate_files):
            fetched = read(ROOT / f'metadata/candidate-source-{i}-original.json')['structuredContent']
            require(HOST in fetched['url'], 'Remote candidate source is not exact6b')
            data = fetched['content'].encode()
            require(len(data) == row['bytes'] and hashlib.sha256(data).hexdigest() == row['sha256']
                    and hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest() == row['git_blob'],
                    'Remote candidate source bytes differ')
        pin = json.loads(read(ROOT / 'metadata/candidate-source-0-original.json')['structuredContent']['content'])
        require(pin['revision'] == NATIVE, 'Candidate native pin differs')
        for name, row in before['input_hashes'].items():
            path = ORIGINALS / 'binding-inputs' / name
            if path.exists():
                actual = record(path)
                require(actual['bytes'] == row['bytes'] and actual['sha256'] == row['sha256'], 'Original input differs: ' + name)
        identity = {
            'apk_sha256': APK, 'flutter_source_commit': HOST, 'godot_revision': NATIVE, 'godot_pck_sha256': PCK,
            'versionName': '0.13.8', 'versionCode': 2020,
            'signingCertificateSha256': 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702',
            'checks': {key: True for key in ('sha256_matches_provenance', 'sha256_matches_build_sums',
                'flutter_source_is_this_commit', 'tracked_source_clean', 'godot_revision_is_pinned',
                'signing_certificate', 'version_matches_pubspec', 'x86_64_native_code')}}
        require(before['apk']['existing_apk_identity'] == identity and before['apk']['apk_bytes'] == 334516947
                and before['apk']['pck_bytes'] == 75401304, 'Original APK/PCK identity differs')
        require((ORIGINALS / 'tested-apk-sha256.txt').read_text().split()[0] == APK
                and (ORIGINALS / 'apk-source-sha.txt').read_text().strip() == HOST, 'Original tested APK receipt differs')
        main_report = read(ORIGINALS / 'main/tour-result.json')
        tour_ast = ast.parse((READER / '.github/probes/modernization_android_tour.py').read_text())
        hard_steps = None
        for node in tour_ast.body:
            if isinstance(node, ast.Assign) and any(getattr(target, 'id', '') == 'HARD_STEPS' for target in node.targets):
                hard_steps = ast.literal_eval(node.value)
        require(hard_steps is not None and len(hard_steps) == 18, 'Original hard-step contract missing')
        steps = main_report['steps']
        require(main_report['status'] == 'PASS' and main_report['apk_sha256'] == APK
                and main_report['fatal_crashes'] == 0 and main_report['android_sdk'] == '35', 'Main diagnostic failed')
        for name in hard_steps:
            matches = [step for step in steps if step.get('step') == name]
            require(len(matches) == 1 and matches[0]['ok'] is True, 'Main required step missing or failed: ' + name)
        main_identity = next(step for step in steps if step['step'] == 'apk-identity')
        require({key: value for key, value in main_identity.items() if key not in ('step', 'ok')} == identity,
                'Main APK identity differs')
        diagnostic_binding = {'qa_source': QA, 'apk_source': HOST, 'apk_sha256': APK,
            'binding_sha256': record(ORIGINALS / 'candidate-and-probe-binding.json')['sha256'],
            'seven_job_acceptance': False,
            'scope': 'Actual unchanged-APK diagnostic, separate QA source; no publication approval'}
        for name in ('village', 'c4'):
            report = read(ORIGINALS / name / (name + '-result.json'))
            require(report['diagnostic_binding'] == diagnostic_binding and report['identity'] == identity
                    and report['binding'] == candidate['existing_c4_binding'], 'Roundtrip source/APK binding differs')
            require(report['prior_tour']['sha256'] == record(ORIGINALS / 'main/tour-result.json')['sha256'],
                    'Roundtrip did not follow the same actual main tour')
        result['binding_review'] = {'status': 'PASS', 'pre_post_receipts_identical': True,
            'recorded_qa_source_files': len(actual_qa), 'local_exact_reader_files': len(source_binding['files']),
            'candidate_source_files_remote_rechecked': 2, 'candidate': candidate, 'qa': qa,
            'apk_identity': identity, 'main_required_steps_passed': len(hard_steps),
            'main_total_steps_passed': sum(step.get('ok') is True for step in steps)}
        result['village_original_reader'] = village.verify_report(ORIGINALS / 'village', candidate['existing_c4_binding'], identity)
        c4_report = read(ORIGINALS / 'c4/c4-result.json')
        require(c4_report['status'] == 'FAIL' and c4_report['error'] == 'ValueError: Closed C4 mailbox still exists',
                'Unexpected actual C4 diagnostic outcome')
        try:
            c4.verify_report(ORIGINALS / 'c4', candidate['existing_c4_binding'], identity)
        except ValueError as error:
            require(str(error) == 'C4 report is missing, failed or bound to a different candidate',
                    'Unexpected full C4 reader error')
            result['c4_full_original_reader'] = {'accepted': False, 'expected_fail_closed': True,
                                               'error': type(error).__name__ + ': ' + str(error)}
        else:
            raise ValueError('Original full C4 reader unexpectedly accepted a failed diagnostic')
        c4.verify_inventory(ORIGINALS / 'c4', c4_report['originals'])
        observations = {name: c4.checked_observation(ORIGINALS / 'c4', name) for name in c4_report['observations']}
        require(len(observations) == len(c4_report['observations']) == 19, 'C4 observation count differs')
        c4.checked_flutter_touch(ORIGINALS / 'c4', c4_report['entry_touch'], c4.PORTAL)
        initial = observations[c4_report['initial']]
        require(initial['state']['columns'] == [] and initial['state']['twoPlayers'] is False, 'Actual initial C4 round differs')
        previous = initial
        transitions = []
        for step in c4_report['transitions']:
            before_state, after_state = observations[step['before']], observations[step['after']]
            require(before_state['state'] == previous['state'] and before_state['pid'] == previous['pid']
                    and before_state['host_pid'] == initial['host_pid'], 'Reached transition chain changed authority')
            request = json.loads(c4.read_original(ORIGINALS / 'c4', step['request']))
            c4.acknowledged(before_state['state'], after_state['state'], request, step['action'])
            control = {'drop': 'column_' + str(request.get('column')), 'pause': 'pause', 'resume': 'resume'}[step['action']]
            c4.checked_native_touch(ORIGINALS / 'c4', step['touch'], observations, before_state, control)
            transitions.append({'action': step['action'], 'ack': after_state['state']['ack'],
                'revision': after_state['state']['revision'], 'columns': after_state['state']['columns']})
            previous = after_state
        require([step['action'] for step in transitions] == ['drop', 'pause', 'resume', 'drop', 'pause'],
                'Actual reached C4 prefix differs')
        hold = c4_report['pause_hold']
        require(hold['first'] == c4_report['transitions'][1]['after']
                and hold['elapsed'] == observations[hold['second']]['observed_monotonic']
                    - observations[hold['first']]['observed_monotonic'], 'Original pause interval differs')
        c4.paused_unchanged(observations[hold['first']], observations[hold['second']], hold['elapsed'])
        c4.checked_native_touch(ORIGINALS / 'c4', 'return-first-touch.json', observations,
                               observations['return-first-second-000'], 'back')
        require(c4_report['returns'] == [] and c4_report['fatal_entries'] == [], 'Unexpected C4 return/error inventory')
        current_token = observations['return-first-second-000']['state']['token']
        find_path = ORIGINALS / 'c4/commands/0322-return-first-closed-mailbox.stdout'
        find_meta = read(find_path.with_suffix('.json'))
        require(find_path.read_text().strip() == f'/data/user/0/{c4.PACKAGE}/files/lumo_connect_four_session_v1/{current_token}/state.json',
                'Actual found file is not the current closed session')
        result['c4_reached_prefix_only'] = {'status': 'PASS_FOR_REACHED_PREFIX_ONLY', 'complete_c4_acceptance': False,
            'observations_replayed': len(observations), 'transitions_replayed': transitions,
            'pause_hold_seconds': hold['elapsed'], 'actual_back_touch_replayed': True,
            'full_returns_recorded': 0, 'host_pid': initial['host_pid'], 'native_pid': initial['pid'],
            'session_token': current_token, 'same_session_found': find_path.read_text(),
            'find_stdout': record(find_path), 'original_error': c4_report['error']}
        result['review_status'] = 'COMPLETE_WITH_ORIGINAL_C4_FAILURE_PRESERVED'
    except Exception as error:
        result['review_status'] = 'REPLAY_ERROR'
        result['error'] = type(error).__name__ + ': ' + str(error)
        result['traceback'] = traceback.format_exc()
        raise
    finally:
        original_after = snapshot(ORIGINALS)
        reader_after = snapshot(READER)
        parent_after = parent_snapshot(source_binding)
        save('original-files-after.json', original_after)
        save('reader-source-after.json', reader_after)
        save('parent-source-after.json', parent_after)
        unchanged = original_before == original_after and reader_before == reader_after and parent_before == parent_after
        result['preservation'] = {'original_files': len(original_after),
            'original_bytes_and_modes_unchanged': original_before == original_after,
            'reader_bytes_and_modes_unchanged': reader_before == reader_after,
            'parent_source_subset_head_tree_status_and_raw_index_unchanged': parent_before == parent_after,
            'actual_parent_head': parent_before['actual_head']}
        result['elapsed_seconds'] = time.monotonic() - started
        save('independent-reader-result.json', result)
        require(unchanged, 'Originals, readers or parent source/index changed during replay')
    print(json.dumps({'review_status': result['review_status'], 'village': result['village_original_reader']['status'],
        'c4_full_accepted': result['c4_full_original_reader']['accepted'],
        'c4_reached_observations': result['c4_reached_prefix_only']['observations_replayed'],
        'c4_reached_transitions': len(result['c4_reached_prefix_only']['transitions_replayed']),
        'originals_unchanged': result['preservation']['original_bytes_and_modes_unchanged'],
        'elapsed_seconds': result['elapsed_seconds']}, sort_keys=True))


if __name__ == '__main__':
    main()
