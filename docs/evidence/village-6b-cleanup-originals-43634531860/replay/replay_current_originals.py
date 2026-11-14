"""Read current diagnostic originals using unchanged, exactly bound readers."""
from __future__ import annotations
import ast
import hashlib
import importlib.util
import json
import platform
from pathlib import Path
import re
import stat
import sys
import time
import traceback
import PIL

ROOT = Path(__file__).resolve().parents[1]
ORIGINALS = ROOT / 'originals'
READER = ROOT / 'reader'
QA = '3cae9c407a6eef1970e24bc9a61516b13fe0af52'
QA_TREE = '16dbaa5024c0bba79c9ab8a9d23b9025a0c2f5d7'
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
    def reject(value):
        raise ValueError('Nonfinite JSON: ' + value)
    return json.loads(path.read_text(), object_pairs_hook=unique, parse_constant=reject)


def record(path):
    require(path.is_file() and not path.is_symlink(), 'Regular original file required: ' + str(path))
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()}


def snapshot(root, include_blob=False):
    rows = {}
    for path in sorted(root.rglob('*')):
        require(not path.is_symlink(), 'Unexpected symlink')
        if path.is_file():
            row = record(path)
            if not include_blob:
                row.pop('git_blob')
            row['mode'] = stat.S_IMODE(path.stat().st_mode)
            rows[path.relative_to(root).as_posix()] = row
    return rows


def save(name, value):
    (ROOT / 'replay' / name).write_text(json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + '\n')


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def cleanup_rounds(c4, report, observations):
    root = ORIGINALS / 'c4'
    expected_find = ['adb', 'shell', 'find', f'/data/user/0/{c4.PACKAGE}/files/lumo_connect_four_session_v1',
                     '-maxdepth', '2', '-type', 'f', '-name', 'state.json']
    rows = []
    for returned in report['returns']:
        tag = returned['touch'].removesuffix('-touch.json')
        before = observations[returned['before']]
        polls = []
        for path in sorted((root / 'commands').glob('*-' + tag + '-closed-mailbox.stdout')):
            sequence = int(path.name.split('-')[0])
            name = path.relative_to(root).as_posix()
            pid_name = f'commands/{sequence - 2:04d}-{tag}-native-exit.stdout'
            activity_name = f'commands/{sequence - 1:04d}-{tag}-return-activity.stdout'
            raw_find = c4.read_original(root, name, empty_ok=True, command=expected_find)
            activity = c4.read_original(root, activity_name,
                command=['adb', 'shell', 'dumpsys', 'activity', 'activities'])
            pid_path = root / pid_name
            pid_meta = read(pid_path.with_suffix('.json'))
            pid_data = pid_path.read_bytes()
            require(pid_meta['command'] == ['adb', 'shell', 'pidof', c4.PACKAGE + ':lumo_game']
                    and pid_meta['stdout_bytes'] == len(pid_data)
                    and pid_meta['stdout_sha256'] == hashlib.sha256(pid_data).hexdigest()
                    and not pid_path.with_suffix('.stderr').read_bytes(), 'Original PID command differs')
            native_gone = not pid_data and pid_meta['returncode'] == 1
            if pid_data:
                require(pid_meta['returncode'] == 0 and pid_data.decode().strip() == str(before['pid']),
                        'Negative return poll names another native process')
            active = [line.strip() for line in activity.splitlines()
                      if 'mResumedActivity' in line or 'topResumedActivity' in line]
            correct_activity = bool(active) and all('MainActivity' in line and c4.PACKAGE in line for line in active)
            ready = native_gone and correct_activity and not raw_find.strip()
            accepted = name == returned['closed_mailbox']
            if accepted:
                require(ready and returned['native_exit'] == pid_name and returned['activity'] == activity_name,
                        'Accepted return does not use a complete successful original observation round')
            polls.append({'find_original': name, 'pid_original': pid_name, 'activity_original': activity_name,
                'find_stdout': raw_find, 'find_record': record(path),
                'find_returncode': read(path.with_suffix('.json'))['returncode'],
                'native_pid_stdout': pid_data.decode(), 'native_gone': native_gone,
                'actual_resumed_activity': active, 'correct_main_activity': correct_activity,
                'all_conditions_met': ready, 'accepted': accepted})
        require(polls and polls[-1]['accepted'] and sum(row['accepted'] for row in polls) == 1,
                'Actual return does not end at its single accepted poll')
        require(all(not row['all_conditions_met'] for row in polls[:-1]),
                'An earlier successful round was inconsistently ignored')
        rows.append({'tag': tag, 'session_token': before['state']['token'], 'native_pid': before['pid'],
            'host_pid': before['host_pid'], 'polls': polls,
            'nonempty_mailbox_polls': sum(bool(row['find_stdout'].strip()) for row in polls),
            'pid_absent_but_mailbox_present_polls': sum(row['native_gone'] and bool(row['find_stdout'].strip()) for row in polls),
            'final_mailbox_empty': True, 'final_native_process_gone': True,
            'returned_frame': returned['frame'], 'returned_ui': returned['returned_ui']})
    return rows


def main():
    started = time.monotonic()
    before_originals = snapshot(ORIGINALS)
    before_readers = snapshot(READER, include_blob=True)
    require(before_originals == read(ROOT / 'replay/original-files-before.json'), 'Original bytes/modes changed before replay')
    require(before_readers == read(ROOT / 'replay/reader-source-before.json')['files'], 'Reader bytes/modes changed before replay')
    result = {'schema': 1, 'scope': 'Independent original replay of the separate QA3cae diagnostic on unchanged APK6b.',
        'diagnostic_run': 43634531860, 'attempt': 1, 'android_job': 132568698911,
        'qa_source': QA, 'qa_tree': QA_TREE, 'apk_source': HOST, 'native_source': NATIVE,
        'artifact_id': 14130249406, 'new_device_engine_or_capture_runs': 0, 'seven_job_acceptance': False,
        'runtime': {'python': platform.python_version(), 'pillow': PIL.__version__, 'ci_pillow': '12.3.0'},
        'limits': ['Separate old6b APK diagnostic, not acceptance of current central Hostec or seven jobs.',
                   'No newly downloaded APK or fresh local apksigner run; exact original APK/PCK receipts are independently cross-bound.',
                   'Small source materialization contains exact Git blobs; it is not a Git checkout and has no Git-index claim.',
                   'Two actual child/bot pairs, pause/resume, reopen and two returns; no completed win, reward, physical-device or FPS claim.']}
    try:
        tree = read(ROOT / 'metadata/qa-fulltree-original.json')
        require(tree['sha'] == QA_TREE and tree['truncated'] is False, 'Source tree is wrong or truncated')
        blobs = {row['path']: row for row in tree['tree'] if row['type'] == 'blob'}
        source_files = read(ROOT / 'metadata/reader-source-binding.json')['files']
        for row in source_files:
            actual = record(READER / row['path'])
            require(all(actual[key] == row[key] for key in ('bytes', 'sha256', 'git_blob'))
                    and blobs[row['path']]['sha'] == row['git_blob']
                    and blobs[row['path']]['mode'] == row['mode'], 'Local source is not exact QA3cae: ' + row['path'])
        sys.path.insert(0, str(READER / 'tools/android_qa'))
        import connect_four_android_evidence as c4
        import village_android_evidence as village
        binder = module('current_diagnostic_binding', READER / 'scripts/verify_unchanged_6b_village_diagnostic.py')
        before = read(ORIGINALS / 'candidate-and-probe-binding.json')
        after = read(ORIGINALS / 'candidate-and-probe-binding-after.json')
        require(before == after and before['status'] == 'BOUND', 'Current pre/post source and APK binding differs')
        candidate = binder.verify_candidate(read(ORIGINALS / 'binding-inputs/candidate/run.json'),
            read(ORIGINALS / 'binding-inputs/candidate/jobs.json'), read(ORIGINALS / 'binding-inputs/candidate/artifacts.json'), c4)
        qa = binder.verify_qa(read(ORIGINALS / 'binding-inputs/qa/run.json'),
            read(ORIGINALS / 'binding-inputs/qa/jobs.json'), source=QA, run_id=43634531860,
            attempt=1, job_name='unchanged-6b-main-api35')
        require(candidate == before['candidate_build'] and qa == before['diagnostic_qa']
                and qa['tree'] == QA_TREE and qa['job_id'] == 132568698911, 'Current run/job/source binding differs')
        expected = read(ROOT / 'metadata/expected-79-observer-source-files.json')['source_files']
        actual = before['source_files']['qa']
        require(len(actual) == len(expected) == 79 and len({row['path'] for row in actual}) == 79,
                'Observer inventory is incomplete or duplicated')
        expected_map = {row['path']: row for row in expected}
        require(set(expected_map) == {row['path'] for row in actual}, 'Observer inventory paths differ')
        for row in actual:
            require(row['git_blob'] == expected_map[row['path']]['git_blob']
                    and row['bytes'] == expected_map[row['path']]['bytes'], 'Actual QA observer blob differs: ' + row['path'])
        for name, commit, expected_tree in [('qa', QA, QA_TREE), ('candidate', HOST, HOST_TREE)]:
            item = before['git_sources'][name]
            require(item['commit'] == commit and item['tree'] == expected_tree
                    and item['tracked_source_clean'] is True, 'Original source receipt differs')
        for name, row in before['input_hashes'].items():
            path = ORIGINALS / 'binding-inputs' / name
            if path.exists():
                current = record(path)
                require(current['bytes'] == row['bytes'] and current['sha256'] == row['sha256'], 'Original binding input differs')
        identity = {'apk_sha256': APK, 'flutter_source_commit': HOST, 'godot_revision': NATIVE,
            'godot_pck_sha256': PCK, 'versionName': '0.13.8', 'versionCode': 2020,
            'signingCertificateSha256': 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702',
            'checks': {key: True for key in ('sha256_matches_provenance', 'sha256_matches_build_sums',
                'flutter_source_is_this_commit', 'tracked_source_clean', 'godot_revision_is_pinned',
                'signing_certificate', 'version_matches_pubspec', 'x86_64_native_code')}}
        require(before['apk']['existing_apk_identity'] == identity and before['apk']['apk_bytes'] == 334516947
                and before['apk']['pck_bytes'] == 75401304, 'Exact old6b APK/PCK receipt differs')
        require((ORIGINALS / 'tested-apk-sha256.txt').read_text().split()[0] == APK
                and (ORIGINALS / 'apk-source-sha.txt').read_text().strip() == HOST
                and (ORIGINALS / 'probe-source-sha.txt').read_text().strip() == QA, 'Actual tested APK/QA receipts differ')
        main_report = read(ORIGINALS / 'main/tour-result.json')
        syntax = ast.parse((READER / '.github/probes/modernization_android_tour.py').read_text())
        hard_steps = next(ast.literal_eval(node.value) for node in syntax.body if isinstance(node, ast.Assign)
            and any(getattr(target, 'id', '') == 'HARD_STEPS' for target in node.targets))
        require(len(hard_steps) == 18 and main_report['status'] == 'PASS' and main_report['apk_sha256'] == APK
                and main_report['fatal_crashes'] == 0 and main_report['android_sdk'] == '35', 'Current main tour failed')
        for name in hard_steps:
            rows = [row for row in main_report['steps'] if row['step'] == name]
            require(len(rows) == 1 and rows[0]['ok'] is True, 'Main required step failed: ' + name)
        actual_identity = next(row for row in main_report['steps'] if row['step'] == 'apk-identity')
        require({key: value for key, value in actual_identity.items() if key not in ('step', 'ok')} == identity,
                'Main APK identity differs')
        expected_diagnostic = {'qa_source': QA, 'apk_source': HOST, 'apk_sha256': APK,
            'binding_sha256': record(ORIGINALS / 'candidate-and-probe-binding.json')['sha256'],
            'seven_job_acceptance': False,
            'scope': 'Actual unchanged-APK diagnostic, separate QA source; no publication approval'}
        for name in ('village', 'c4'):
            report = read(ORIGINALS / name / (name + '-result.json'))
            require(report['diagnostic_binding'] == expected_diagnostic and report['identity'] == identity
                    and report['binding'] == candidate['existing_c4_binding']
                    and report['prior_tour']['sha256'] == record(ORIGINALS / 'main/tour-result.json')['sha256'],
                    'Current roundtrip is not bound to this QA/APK/main tour')
        diagnostic = read(ORIGINALS / 'diagnostic-result.json')
        require(diagnostic['status'] == 'PASS' and diagnostic['probe_exit_code'] == 0
                and diagnostic['postflight_binding_exit_code'] == 0 and diagnostic['seven_job_acceptance'] is False,
                'Overall separate diagnostic did not pass')
        result['binding_review'] = {'status': 'PASS', 'pre_post_receipts_identical': True,
            'observer_inventory': 79, 'exact_local_qa_files': len(source_files), 'candidate': candidate,
            'qa': qa, 'identity': identity, 'main_required_steps_passed': len(hard_steps),
            'main_total_steps_passed': sum(row.get('ok') is True for row in main_report['steps'])}
        result['village_original_reader'] = village.verify_report(ORIGINALS / 'village', candidate['existing_c4_binding'], identity)
        result['c4_original_reader'] = c4.verify_report(ORIGINALS / 'c4', candidate['existing_c4_binding'], identity)
        require(result['c4_original_reader'] == read(ORIGINALS / 'c4-diagnostic-replay.json'),
                'Independent full C4 result differs from original CI replay')
        report = read(ORIGINALS / 'c4/c4-result.json')
        observations = {name: read(ORIGINALS / 'c4/observations' / (name + '.json')) for name in report['observations']}
        result['actual_cleanup_rounds'] = cleanup_rounds(c4, report, observations)
        closed, opened = (observations[report['reopen'][key]] for key in ('closed', 'opened'))
        keys = ['token', 'owner', 'roundId', 'revision', 'recordRevision', 'ack', 'paused', 'columns', 'rewarded']
        result['actual_reopen'] = {'closed_observation': closed['id'], 'opened_observation': opened['id'],
            'closed_pid': closed['pid'], 'opened_pid': opened['pid'], 'host_pid': opened['host_pid'],
            'closed_state': {key: closed['state'][key] for key in keys},
            'opened_state': {key: opened['state'][key] for key in keys},
            'same_round_and_owner': closed['state']['roundId'] == opened['state']['roundId']
                and closed['state']['owner'] == opened['state']['owner'],
            'same_board': closed['state']['board'] == opened['state']['board'],
            'new_token': closed['state']['token'] != opened['state']['token'], 'new_pid': closed['pid'] != opened['pid']}
        result['all_board_observations'] = [{'id': row['id'], 'frame': row['frame'],
            'frame_sha256': row['frame_sha256'], 'columns': row['state']['columns'],
            'paused': row['state']['paused'], 'ack': row['state']['ack'], 'pid': row['pid'],
            'token': row['state']['token'], 'pixels_verified_by_unchanged_reader': True} for row in observations.values()]
        result['review_status'] = 'PASS_SEPARATE_UNCHANGED_APK_DIAGNOSTIC'
    except Exception as error:
        result['review_status'] = 'REPLAY_ERROR'
        result['error'] = type(error).__name__ + ': ' + str(error)
        result['traceback'] = traceback.format_exc()
        raise
    finally:
        after_originals = snapshot(ORIGINALS)
        after_readers = snapshot(READER, include_blob=True)
        save('original-files-after.json', after_originals)
        save('reader-source-after.json', {'files': after_readers})
        result['preservation'] = {'original_files': len(after_originals),
            'all_original_bytes_and_modes_unchanged': before_originals == after_originals,
            'all_reader_bytes_and_modes_unchanged': before_readers == after_readers}
        result['elapsed_seconds'] = time.monotonic() - started
        save('independent-reader-result.json', result)
        require(before_originals == after_originals and before_readers == after_readers, 'Read-only boundary changed')
    print(json.dumps({'status': result['review_status'], 'village': result['village_original_reader']['status'],
        'c4': result['c4_original_reader']['status'], 'observations': result['c4_original_reader']['observations'],
        'returns': result['c4_original_reader']['native_returns'],
        'cleanup_poll_counts': [len(row['polls']) for row in result['actual_cleanup_rounds']],
        'negative_mailbox_poll_counts': [row['nonempty_mailbox_polls'] for row in result['actual_cleanup_rounds']],
        'elapsed_seconds': result['elapsed_seconds'], 'originals_unchanged': True}, sort_keys=True))


if __name__ == '__main__':
    main()
