"""Bind the three new activity proofs to the same 2021 source and installed APK.

These checks supplement the complete C4, Village, learning, update and native
gates. They never accept an older activity artifact or turn desktop captures
into Android evidence.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess

from PIL import Image

from integrated_candidate_profile import AUTHORITY_STEPS, PREFIX, VERSION_CODE


def require(condition, message):
    if not condition:
        raise ValueError(message)


def record(path):
    require(path.is_file() and not path.is_symlink(), 'Missing regular activity evidence: ' + str(path))
    with path.open('rb') as source:
        return {'bytes': path.stat().st_size,
                'sha256': hashlib.file_digest(source, 'sha256').hexdigest()}


def read(path):
    record(path)
    result = json.loads(path.read_text())
    require(isinstance(result, dict), 'Activity evidence must be an object')
    return result


def inventory(root, rows):
    require(isinstance(rows, list) and rows, 'Original authority file inventory missing')
    seen = set()
    for row in rows:
        require(isinstance(row, dict) and isinstance(row.get('path'), str),
                'Invalid original authority file record')
        path = PurePosixPath(row['path'])
        require(not path.is_absolute() and path.parts and '..' not in path.parts
                and str(path) == row['path'] and '\\' not in row['path']
                and row['path'] not in seen, 'Unsafe or duplicate authority evidence path')
        seen.add(row['path'])
        require(record(root / row['path']) == {key: row[key] for key in ('bytes', 'sha256')},
                'Original authority bytes changed: ' + row['path'])
    return len(seen)


def checked_pair(root, activity, source, native, host_tree, native_tree):
    report = read(root / 'pair-result.json')
    expected = {'host': {'commit': source, 'tree': host_tree},
                'native': {'commit': native, 'tree': native_tree}}
    require(report.get('success') is True and report.get('capture_requested') is True
            and report.get('source_before') == report.get('source_after') == expected,
            'Authority pair failed, changed source, or used another candidate: ' + activity)
    codes = report.get('process_exit_codes', {})
    require(codes == {'DartAuthority': 0, 'Godot' + activity.title(): 0},
            'Both real authority processes must exit successfully: ' + activity)
    files = inventory(root, report.get('evidence'))
    require(type(report.get('checks')) is int and report['checks'] > 0,
            'Missing actual authority checks: ' + activity)
    return {'report': record(root / 'pair-result.json'), 'original_files': files,
            'process_exit_codes': codes}


def checked_android(root, activity, source, native, apk):
    result = read(root / 'result.json')
    binding = result.get('source_binding', {})
    require(result.get('status') == 'PASS' and binding.get('host') == source
            and binding.get('native') == native,
            'The actual Android activity did not pass on the current source: ' + activity)
    require(binding == read(root / 'binding-before.json') == read(root / 'binding-after.json'),
            'Android source or installed binary changed during the activity: ' + activity)
    identity = binding.get('apk', {})
    require(identity.get('apk_sha256') == apk['sha256']
            and identity.get('flutter_source_commit') == source
            and identity.get('godot_revision') == native
            and identity.get('godot_pck_sha256') == apk['godot']['pck_sha256']
            and identity.get('versionCode') == VERSION_CODE
            and identity.get('versionName') == apk['versionName']
            and identity.get('signingCertificateSha256') == apk['signingCertificateSha256'],
            'Android activity belongs to another signed APK/PCK: ' + activity)
    installed = binding.get('installed_apk_sha256') if activity == 'english' else binding.get('actual_installed_apk_sha256')
    require(installed == apk['sha256'] and result.get('android_runtime', {}).get('sdk') == 35,
            'Actual installed Android activity identity differs: ' + activity)
    require('fatal_crashes' not in result or result['fatal_crashes'] == 0,
            'Actual activity reported a fatal Android crash: ' + activity)
    require(result.get('not_tested'), 'Activity evidence must preserve its observation limits')
    hashes = binding.get('source_hashes')
    require(isinstance(hashes, dict) and hashes
            and all(re.fullmatch('[a-f0-9]{64}', str(value)) for value in hashes.values()),
            'Activity source byte identities are missing: ' + activity)
    if activity == 'memory':
        require(len(result.get('child_actions', [])) == 4 and result.get('bot_receipt')
                and result.get('pause') and result.get('resume')
                and result.get('old_token') != result.get('new_token'),
                'Actual Memory actions, bot, pause or reopen sequence is incomplete')
    elif activity == 'quiz':
        require(result.get('actual_transitions') and len(result.get('returns', [])) == 2
                and result.get('reopen') and result.get('startup') and result.get('reopen_startup'),
                'Actual Quiz authority or return sequence is incomplete')
    else:
        require(result.get('transitions') and result.get('same_actual_task_returned') is True
                and result.get('no_answer_or_mastery_submitted') is True,
                'Actual English task/return evidence is incomplete')
    return {'result': record(root / 'result.json'),
            'binding_before': record(root / 'binding-before.json'),
            'binding_after': record(root / 'binding-after.json'),
            'not_tested': result['not_tested']}


def verify_activities(args, candidate, metadata):
    require(args.authorities is not None and args.authorities.is_dir(),
            'All three original activity authority artifacts are required')
    run, artifacts, jobs = metadata
    source, native = candidate['binding']['host_source'], candidate['binding']['native_source']
    root = Path(__file__).resolve().parents[1]
    host_tree = subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=root, text=True).strip()
    checked = {}
    for activity, steps in AUTHORITY_STEPS.items():
        name = f'Nextgen {activity} actual authority'
        matches = [job for job in jobs.get('jobs', []) if job.get('name') == name]
        require(len(matches) == 1 and matches[0].get('run_id') == run['id']
                and matches[0].get('head_sha') == source
                and matches[0].get('run_attempt') == candidate['binding']['run_attempt']
                and matches[0].get('status') == 'completed' and matches[0].get('conclusion') == 'success',
                'Missing current successful authority job: ' + name)
        for label in ('Exercise the actual authority for this activity', *steps):
            observed = [step for step in matches[0].get('steps', []) if step.get('name') == label]
            require(len(observed) == 1 and observed[0].get('conclusion') == 'success',
                    'Mandatory activity authority step was skipped or failed: ' + label)
        artifact_name = PREFIX + '-nextgen-authority-' + activity
        rows = [row for row in artifacts.get('artifacts', []) if row.get('name') == artifact_name]
        require(len(rows) == 1 and rows[0].get('expired') is False
                and rows[0].get('workflow_run', {}).get('id') == run['id']
                and rows[0].get('workflow_run', {}).get('head_sha') == source
                and re.fullmatch('sha256:[a-f0-9]{64}', str(rows[0].get('digest'))),
                'Activity artifact is stale, missing or unbound: ' + activity)
        folder = args.authorities / artifact_name
        require((folder / 'HOST-SOURCE.txt').read_text().strip() == source
                and (folder / 'NATIVE-SOURCE.txt').read_text().strip() == native
                and (folder / 'HOST-TREE.txt').read_text().strip() == host_tree,
                'Authority artifact source files differ from this candidate: ' + activity)
        native_tree = (folder / 'NATIVE-TREE.txt').read_text().strip()
        require(re.fullmatch('[a-f0-9]{40}', native_tree), 'Missing native authority source tree')
        if activity in ('quiz', 'memory'):
            authority = checked_pair(folder / (activity + '-pair'), activity, source, native, host_tree, native_tree)
        else:
            report_path = folder / 'english-native/learning-english-report.json'
            report = read(report_path)
            require(report.get('fixture_kind') == 'actual_dart_producer_report'
                    and report.get('task_fixture_sha256') == record(folder / 'english-activity.json')['sha256']
                    and report.get('failures') == [] and report.get('renderer') not in (None, 'headless'),
                    'English renderer did not consume the current actual Dart producer')
            images = sorted((folder / 'english-native').glob('*.png'))
            require(len(images) == 17, 'Incomplete actual English renderer capture set')
            for path in images:
                with Image.open(path) as image:
                    image.verify()
            authority = {'report': record(report_path), 'captures': len(images),
                         'producer': record(folder / 'english-activity.json')}
        checked[activity] = {'authority': authority,
            'artifact': {key: rows[0][key] for key in ('id', 'name', 'digest', 'size_in_bytes')},
            'android': checked_android(args.android / activity, activity, source, native, candidate['apks']['x86_64'])}
    return {'versionCode': VERSION_CODE, 'host_source': source, 'native_source': native,
            'activities': checked, 'physical_arm64_tested': False}
