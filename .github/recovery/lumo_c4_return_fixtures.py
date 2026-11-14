#!/usr/bin/env python3
"""Recover frozen C4 fixtures from one immutable failed diagnostic artifact.

This script performs no product tests and creates no Git refs, trees, commits,
branches or releases. Its only API mutations are verified Git blob creations.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import zipfile

REPO = 'Ullmann27/lumo-lernen'
RECOVERY_BRANCH = 'recovery/lumo-c4-return-fixtures-20261114'
SCRIPT_PATH = '.github/recovery/lumo_c4_return_fixtures.py'
RUN = 43616584326
ATTEMPT = 1
JOB = 132512855551
ARTIFACT = 14122019894
ARTIFACT_NAME = 'diagnostic-only-51ec-c4-preferences-and-return'
ARCHIVE_BYTES = 140850732
ARCHIVE_SHA = '03dbde65dba65c00d3b36f0283d3d66fee7778d9bd176005c66e470c16eeaaaa'
DIAGNOSTIC = 'cd03e1e2da22efa2e982795cddc12217f821b14b'
DIAGNOSTIC_TREE = '98a726ff45bafaf21479b6023b3d411d794d8920'
DIAGNOSTIC_BRANCH = 'diagnostic/lumo-c4-preferences-51ec-20261114'
DIAGNOSTIC_WORKFLOW = '.github/workflows/lumo-c4-preferences-51ec-diagnostic.yml'
APP = '51ec0ac43f3e2aaac065e285e13cf5db5b5875d2'
APP_TREE = 'e922f8d01fe31b07ac3c5cb196451dcbedb269d0'
OBSERVER = '7c5bef2bc39024fc2c1018523cabc651820cf76b'
OBSERVER_TREE = '10af7af91d03e2c768e574fd0b79be3f3011a8d4'
NATIVE = 'bebf7bba48f09afc834469db0ea3c5541a184f55'
FIXTURE_PREFIX = 'tools/android_qa/tests/fixtures/c4-final-return-7c5/'
EMPTY = 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'
SOURCE_BLOB = '96c86759bf0279dfc15876a39e8f4683162786c0'
SOURCE_BYTES = 8626
SOURCE_SHA = 'a6afefa3c64b811792639e770edd1352e5807361fa9fe204b137b60e806185fb'
TOKEN = '8a54abd67d7e9f0ea13f23f09d2708d9'
ROUND = 'b20d2224f8417b12803c2034b431e3ca'

# Tuples are the exact frozen (metadata JSON, stdout, stderr) Git blob IDs.
FROZEN_RAW = {
    '0392-return-final-second-000-state': (
        'b7f5994338dbf7fa4ad7361b4468e17d224b8093',
        'f6f8b58d6044c6a4b4f1507796a1b38abb92e1fe', EMPTY),
    '0400-return-final-second-000-preferences': (
        '931a9558e803937127b3cb6abc15b0f3a6d1a1f4',
        'da8d7b3b81547d5360591eb82cacd706a59afede', EMPTY),
    '0404-return-final-touch': (
        '5abd77f44d4be4587b3470e2e4ec486a3b754a6c', EMPTY, EMPTY),
    '0405-return-final-native-exit': (
        '5c879535e4ea68cb86bfe699ab07b7c5d39a0318',
        '4a6d39c9e590db4479960c263e2bacac6466e85b', EMPTY),
    '0406-return-final-return-activity': (
        '5232b76398e642b02aad884537ec897965c8c388',
        'd61ddcec907789a34f9f333774396275fabf92c6', EMPTY),
    '0407-return-final-native-exit': (
        '3c0705ae48d723ba5c826f9ef18bae7f99e5ea1f', EMPTY, EMPTY),
    '0408-return-final-return-activity': (
        'be6f3a964f7935ee4706f18ebebd685b980056ca',
        '7fc543c55d9882f14fd5250179e2d99cf9535dbe', EMPTY),
    '0409-return-final-closed-mailbox': (
        'd66a7a54987756f72f5a8e863d450a8e9d0b193f',
        '5310f3a196464be800f85c4ba0ab66294f194761', EMPTY),
}
EXISTING = {
    '.github/probes/lumo_connect_four_android_probe.py': {
        'git_sha1': '585af5913ac8ec24216bd7eb877415da8c886025',
        'bytes': 29187,
        'sha256': 'df9148ab323e6e3255a23449d5342c5a033c9a20361d3d1e4a615b7eb5043583'},
    'tools/android_qa/tests/test_connect_four_return_observation.py': {
        'git_sha1': '2cb7163b257e997af5597e11fc2f10dec69daffb',
        'bytes': 18191,
        'sha256': 'bd03248a177a33df7f399c90984c995e3f0352cfe14ef7f1974a9e3f590cfb53'},
}

def require(condition, message):
    if not condition:
        raise ValueError(message)

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def git_blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def json_bytes(value):
    return (json.dumps(value, indent=2, ensure_ascii=False) + '\n').encode()

def write_new(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(data)

def safe_path(name):
    require(isinstance(name, str) and name, 'Missing original member path')
    value = PurePosixPath(name)
    require(not value.is_absolute() and '..' not in value.parts
            and str(value) == name, 'Noncanonical original member path')
    return value

class GitHub:
    def __init__(self, out):
        self.out = out
        self.counter = 0
        self.records = []
        self.post_enabled = False
        self.allowed_blobs = set()
        self.env = os.environ.copy()
        self.env.pop('GH_DEBUG', None)
        self.env['GH_PROMPT_DISABLED'] = '1'

    def request(self, method, suffix, label, body=None):
        require(method in ('GET', 'POST'), 'Forbidden API method')
        endpoint = 'repos/' + REPO + '/' + suffix
        if method == 'POST':
            require(self.post_enabled and suffix == 'git/blobs'
                    and isinstance(body, dict)
                    and set(body) == {'content', 'encoding'}
                    and body['encoding'] == 'base64', 'Forbidden API mutation')
            decoded = base64.b64decode(body['content'], validate=True)
            require(git_blob(decoded) in self.allowed_blobs, 'Unreviewed blob payload')
        else:
            require(body is None, 'GET must not carry an API payload')
        args = ['gh', 'api', '--method', method, endpoint]
        payload = None
        if body is not None:
            args += ['--input', '-']
            payload = json.dumps(body).encode()
        process = subprocess.run(args, input=payload, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, env=self.env, check=False)
        require(process.returncode == 0, 'GitHub API request failed: ' + label
                + '; exit=' + str(process.returncode))
        value = json.loads(process.stdout)
        self.counter += 1
        relative = 'api/' + f'{self.counter:03d}-' + label + '.json'
        write_new(self.out / relative, process.stdout)
        self.records.append({'method': method, 'endpoint': endpoint,
                             'response': relative, 'bytes': len(process.stdout),
                             'sha256': sha256(process.stdout)})
        return value

    def get_blob(self, expected, label):
        record = self.request('GET', 'git/blobs/' + expected, label)
        require(record.get('sha') == expected and record.get('encoding') == 'base64',
                'Existing Git blob identity differs: ' + label)
        data = base64.b64decode(''.join(record['content'].split()), validate=True)
        require(record.get('size') == len(data) and git_blob(data) == expected,
                'Existing Git blob bytes differ: ' + label)
        return data

    def post_blob(self, data, expected):
        require(git_blob(data) == expected, 'Blob changed before POST')
        result = self.request('POST', 'git/blobs', 'created-' + expected,
                              {'encoding': 'base64',
                               'content': base64.b64encode(data).decode()})
        require(result.get('sha') == expected, 'GitHub returned a different blob ID')
        return result['sha']

def reconstruct_source(result, raw_files, inventory):
    files = []
    for name, data in raw_files.items():
        original = 'c4/commands/' + name
        item = inventory[original]
        require(len(data) == item['bytes'] and sha256(data) == item['sha256'],
                'Raw fixture differs from original inventory')
        files.append({'path': name, 'archive_path': original, 'bytes': len(data),
                      'sha256': sha256(data), 'original_inventory_verified': True})
    files.sort(key=lambda item: item['path'])
    source = {
        'schema': 1, 'source_type': 'actual_failed_diagnostic_return',
        'repository': REPO, 'diagnostic_source': DIAGNOSTIC,
        'app_source': result['apk_source'], 'observer_source': result['observer_source'],
        'native_source': result['native_source'],
        'run_id': RUN, 'run_attempt': ATTEMPT, 'job_id': JOB,
        'artifact_id': ARTIFACT, 'artifact_bytes': ARCHIVE_BYTES,
        'artifact_sha256': ARCHIVE_SHA,
        'full_archive_sha256_and_all_member_crcs_verified': True,
        'c4_inventory_files_verified': 1335,
        'status_of_original_diagnostic': result['status'],
        'session_token': TOKEN, 'round_id': ROUND,
        'native_pid_before_return': 7113, 'host_pid': 5689, 'files': files,
        'chronology': [
            '0404: one actual stationary 120ms Back touch, returncode 0.',
            '0405/0406: native process still present, first Activity observation.',
            '0407: native process absent; pidof returncode 1, empty stdout and stderr.',
            '0408: MainActivity resumed and focused.',
            '0409: find returns the current session state.json path; returncode 0, stderr empty.'],
        'truth_limit': 'This run contains no later mailbox query, empty-find response or completed second return. Any later successful cleanup response in a regression is synthetic.'}
    source['pre_touch_fixture_scope'] = '0392 and0400 are the actual last pre-Back-touch state and matching valid preferences. Later reuse in any replay is synthetic, not an observed post-return read.'
    data = json_bytes(source)
    require(len(data) == SOURCE_BYTES and sha256(data) == SOURCE_SHA
            and git_blob(data) == SOURCE_BLOB, 'Reconstructed source.json differs')
    return data

def original_metadata(api):
    run = api.request('GET', f'actions/runs/{RUN}', 'original-run')
    require(run.get('id') == RUN and run.get('run_attempt') == ATTEMPT
            and run.get('repository', {}).get('full_name') == REPO
            and run.get('head_sha') == DIAGNOSTIC
            and run.get('head_branch') == DIAGNOSTIC_BRANCH
            and run.get('path') == DIAGNOSTIC_WORKFLOW
            and run.get('status') == 'completed' and run.get('conclusion') == 'failure',
            'Original diagnostic run identity/status differs')
    job = api.request('GET', f'actions/jobs/{JOB}', 'original-job')
    require(job.get('id') == JOB and job.get('run_id') == RUN
            and job.get('run_attempt') == ATTEMPT and job.get('head_sha') == DIAGNOSTIC
            and job.get('name') == 'unchanged-apk-preferences-diagnostic'
            and job.get('status') == 'completed' and job.get('conclusion') == 'failure',
            'Original diagnostic job identity/status differs')
    artifact = api.request('GET', f'actions/artifacts/{ARTIFACT}', 'original-artifact')
    require(artifact.get('id') == ARTIFACT and artifact.get('name') == ARTIFACT_NAME
            and artifact.get('size_in_bytes') == ARCHIVE_BYTES
            and artifact.get('digest') == 'sha256:' + ARCHIVE_SHA
            and artifact.get('expired') is False
            and artifact.get('workflow_run', {}).get('id') == RUN
            and artifact['workflow_run'].get('head_sha') == DIAGNOSTIC,
            'Original artifact identity differs')
    commit = api.request('GET', 'git/commits/' + DIAGNOSTIC, 'original-diagnostic-commit')
    require(commit.get('sha') == DIAGNOSTIC
            and commit.get('tree', {}).get('sha') == DIAGNOSTIC_TREE,
            'Original diagnostic source tree differs')

def download_archive(api, archive_path):
    require(not archive_path.exists(), 'Refusing to overwrite an existing archive')
    with archive_path.open('xb') as stream:
        process = subprocess.run(
            ['gh', 'api', f'repos/{REPO}/actions/artifacts/{ARTIFACT}/zip'],
            stdout=stream, stderr=subprocess.PIPE, env=api.env, check=False)
    require(process.returncode == 0, 'Original artifact download failed')
    require(archive_path.stat().st_size == ARCHIVE_BYTES, 'Archive byte count differs')
    with archive_path.open('rb') as stream:
        require(hashlib.file_digest(stream, 'sha256').hexdigest() == ARCHIVE_SHA,
                'Full archive SHA256 differs')

def check_archive(archive, receipt):
    infos = archive.infolist()
    require(len(infos) == len({info.filename for info in infos}), 'Duplicate ZIP members')
    for info in infos:
        safe_path(info.filename.rstrip('/') if info.is_dir() else info.filename)
        require((info.external_attr >> 16) & 0o170000 != 0o120000, 'ZIP symlink rejected')
    require(archive.testzip() is None, 'Original ZIP member CRC failed')
    result = json.loads(archive.read('diagnostic-result.json'))
    require(result.get('status') == 'FAIL' and result.get('diagnostic_only') is True
            and result.get('eligible_for_candidate_acceptance') is False
            and result.get('apk_source') == APP and result.get('observer_source') == OBSERVER
            and result.get('native_source') == NATIVE
            and result.get('error') == 'ValueError: Closed C4 mailbox still exists',
            'Original failed diagnostic was changed or rebound')
    rows = result['originals']
    require(len(rows) == len({row['path'] for row in rows}), 'Duplicate inventory entries')
    inventory = {row['path']: row for row in rows}
    c4_rows = [row for row in rows if row['path'].startswith('c4/')]
    require(len(c4_rows) == 1335, 'Original C4 inventory count differs')
    archive_c4 = {i.filename for i in infos if not i.is_dir() and i.filename.startswith('c4/')}
    require(archive_c4 == {row['path'] for row in c4_rows}, 'C4 inventory membership differs')
    for row in c4_rows:
        safe_path(row['path'])
        data = archive.read(row['path'])
        require(len(data) == row['bytes'] and sha256(data) == row['sha256'],
                'C4 inventory bytes differ: ' + row['path'])
    checked_metadata = ('diagnostic-binding.json', 'metadata/diagnostic-run.json',
                        'metadata/driver-source.json')
    for name in checked_metadata:
        data = archive.read(name)
        require(len(data) == inventory[name]['bytes']
                and sha256(data) == inventory[name]['sha256'],
                'Original bound metadata changed')
    binding = json.loads(archive.read('diagnostic-binding.json'))
    require(binding == result['binding'] and binding.get('diagnostic_only') is True
            and binding.get('eligible_for_candidate_acceptance') is False,
            'Diagnostic binding differs')
    sources = binding['sources']
    require(sources['app'] == {'commit': APP, 'tree': APP_TREE, 'tracked_source_clean': True}
            and sources['observer'] == {'commit': OBSERVER, 'tree': OBSERVER_TREE,
                                       'tracked_source_clean': True},
            'App and observer source trees differ')
    diagnostic = binding['diagnostic']
    require(diagnostic['source'] == DIAGNOSTIC and diagnostic['run_id'] == RUN
            and diagnostic['run_attempt'] == ATTEMPT
            and diagnostic['workflow'] == DIAGNOSTIC_WORKFLOW
            and diagnostic['driver_blob'] == '10229a7625c1bac0daa4c5d6d8da89301c1a6fc1',
            'Original diagnostic driver binding differs')
    old_run = json.loads(archive.read('metadata/diagnostic-run.json'))
    require(old_run['id'] == RUN and old_run['run_attempt'] == ATTEMPT
            and old_run['head_sha'] == DIAGNOSTIC, 'Embedded original run differs')
    old_driver = json.loads(archive.read('metadata/driver-source.json'))
    require(old_driver.get('encoding') == 'base64', 'Original driver encoding differs')
    driver_data = base64.b64decode(''.join(old_driver['content'].split()), validate=True)
    require(git_blob(driver_data) == diagnostic['driver_blob']
            and sha256(driver_data) == '36a628a360083406515efbff8e86117ef3e9b4685420634ca7a6b567704faae2',
            'Original diagnostic driver bytes differ')
    xvfb = archive.read('xvfb.log')
    old_xvfb = inventory['xvfb.log']
    require(old_xvfb['bytes'] == 3522
            and old_xvfb['sha256'] == 'f55e2a6894d1dfbec3e5fcb281a8d1d729dfe04923cdfe02ca3a4e801739b3f2'
            and len(xvfb) == 4696
            and sha256(xvfb) == '7e8bd482a1d194c3fbc6b40b7ee1cb73794641aee10985e05e87173f9ae1aabc',
            'Known external live-log difference is not the reviewed original')
    require(sha256(xvfb[:old_xvfb['bytes']]) == old_xvfb['sha256'],
            'Original live-log prefix differs from the frozen inventory')
    receipt['original_archive'] = {
        'artifact_id': ARTIFACT, 'bytes': ARCHIVE_BYTES, 'sha256': ARCHIVE_SHA,
        'full_archive_sha256_checked': True, 'all_member_crcs_checked': True,
        'c4_inventory_files_checked': 1335,
        'original_diagnostic_status': 'FAIL',
        'known_xvfb_difference': {'inventory_bytes': old_xvfb['bytes'],
            'inventory_sha256': old_xvfb['sha256'], 'archive_bytes': len(xvfb),
            'archive_sha256': sha256(xvfb),
            'prefix_bytes': old_xvfb['bytes'],
            'prefix_sha256': sha256(xvfb[:old_xvfb['bytes']]),
            'prefix_matches_inventory': True,
            'appended_bytes': len(xvfb) - old_xvfb['bytes'],
            'not_established_as_c4_failure_cause': True}}
    raw_files = {}
    frozen = {}
    for stem, shas in FROZEN_RAW.items():
        for extension, expected in zip(('json', 'stdout', 'stderr'), shas):
            name = stem + '.' + extension
            data = archive.read('c4/commands/' + name)
            require(git_blob(data) == expected, 'Frozen fixture Git SHA1 differs: ' + name)
            raw_files[name] = data
            frozen[FIXTURE_PREFIX + name] = expected
    require(len(raw_files) == 24 and sum(not value for value in raw_files.values()) == 10,
            'Frozen raw fixture set differs')
    state = json.loads(raw_files['0392-return-final-second-000-state.stdout'])
    require(state['token'] == TOKEN and state['roundId'] == ROUND and state['paused']
            and state['columns'] == [3, 3, 2, 1], 'Original pre-return state differs')
    expected_remainder = ('/data/user/0/dev.ullmann.lumo.lumo_lernen.coachpreview/files/'
                          'lumo_connect_four_session_v1/' + TOKEN + '/state.json\n').encode()
    require(raw_files['0409-return-final-closed-mailbox.stdout'] == expected_remainder,
            'Original current-session remainder differs')
    files = {FIXTURE_PREFIX + name: data for name, data in raw_files.items()}
    files[FIXTURE_PREFIX + 'source.json'] = reconstruct_source(result, raw_files, inventory)
    frozen[FIXTURE_PREFIX + 'source.json'] = SOURCE_BLOB
    return files, frozen, archive.read('diagnostic-result.json')

def current_recovery_identity(api):
    require(os.environ.get('GITHUB_REPOSITORY') == REPO
            and os.environ.get('GITHUB_REF') == 'refs/heads/' + RECOVERY_BRANCH,
            'Recovery must run on its exact repository and branch')
    run_id = int(os.environ['GITHUB_RUN_ID'])
    attempt = int(os.environ['GITHUB_RUN_ATTEMPT'])
    source = os.environ['GITHUB_SHA']
    require(re.fullmatch('[a-f0-9]{40}', source) is not None, 'Invalid recovery source')
    run = api.request('GET', f'actions/runs/{run_id}', 'recovery-run')
    require(run['id'] == run_id and run['run_attempt'] == attempt
            and run['head_sha'] == source and run['head_branch'] == RECOVERY_BRANCH
            and run['repository']['full_name'] == REPO, 'Recovery API identity differs')
    record = api.request('GET', 'contents/' + SCRIPT_PATH + '?ref=' + source, 'recovery-script')
    require(record.get('type') == 'file' and record.get('path') == SCRIPT_PATH
            and record.get('encoding') == 'base64', 'Recovery script source response differs')
    published = base64.b64decode(''.join(record['content'].split()), validate=True)
    actual = Path(__file__).read_bytes()
    require(published == actual and record['sha'] == git_blob(actual),
            'Executing recovery script differs from its published bytes')
    return {'run_id': run_id, 'run_attempt': attempt, 'source': source,
            'script_git_sha1': git_blob(actual), 'script_sha256': sha256(actual)}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    require(not args.out.is_symlink(), 'Output must not be a symlink')
    out = args.out.resolve()
    require(not out.exists() or not any(out.iterdir()), 'Refusing to overwrite recovery evidence')
    out.mkdir(parents=True, exist_ok=True)
    receipt = {'status': 'FAILED', 'scope': 'Frozen-source recovery only; no product tests or acceptance',
               'repository': REPO, 'original_run': RUN, 'original_attempt': ATTEMPT,
               'original_job': JOB, 'original_artifact': ARTIFACT,
               'original_sources': {'diagnostic': DIAGNOSTIC, 'diagnostic_tree': DIAGNOSTIC_TREE,
                                    'app': APP, 'app_tree': APP_TREE,
                                    'observer': OBSERVER, 'observer_tree': OBSERVER_TREE,
                                    'native': NATIVE},
               'candidate_acceptance': False, 'files': [], 'created_blobs': []}
    api = GitHub(out)
    try:
        receipt['recovery'] = current_recovery_identity(api)
        require(len(FROZEN_RAW) == 8, 'Frozen fixture mapping incomplete')
        for shas in FROZEN_RAW.values():
            require(len(shas) == 3 and all(re.fullmatch('[a-f0-9]{40}', s) for s in shas),
                    'Frozen fixture hash invalid')
        original_metadata(api)
        temp = Path(os.environ['RUNNER_TEMP']).resolve()
        require(temp.is_dir(), 'Missing runner temporary directory')
        archive_path = temp / 'lumo-c4-return-fixtures-original-14122019894.zip'
        require(out not in archive_path.parents and archive_path != out,
                'Large archive must remain outside the evidence output')
        download_archive(api, archive_path)
        with zipfile.ZipFile(archive_path) as archive:
            files, frozen, diagnostic_result = check_archive(archive, receipt)
        write_new(out / 'original-diagnostic-result.json', diagnostic_result)
        require(api.get_blob(EMPTY, 'existing-empty-blob') == b'', 'Existing empty blob differs')
        existing_shas = {EMPTY}
        for path, expected in EXISTING.items():
            data = api.get_blob(expected['git_sha1'], 'existing-' + expected['git_sha1'])
            require(len(data) == expected['bytes'] and sha256(data) == expected['sha256'],
                    'Frozen existing source bytes differ: ' + path)
            files[path] = data
            frozen[path] = expected['git_sha1']
            existing_shas.add(expected['git_sha1'])
        require(len(files) == len(frozen) == 27, 'The exact frozen 27-file set is incomplete')
        for path in sorted(files):
            safe_path(path)
            data = files[path]
            require(git_blob(data) == frozen[path], 'A prepared file differs from the frozen manifest')
            destination = out / 'source' / path
            write_new(destination, data)
            require(destination.read_bytes() == data, 'Saved recovery bytes differ')
            receipt['files'].append({'path': path, 'bytes': len(data),
                                     'sha256': sha256(data), 'git_sha1': frozen[path]})
        write_new(out / 'verified-inputs.json', json_bytes({
            'all_input_checks_completed_before_any_post': True,
            'files': receipt['files'], 'original_archive': receipt['original_archive']}))
        # No API mutation is possible until every original and frozen file check above succeeded.
        api.allowed_blobs = set(frozen.values())
        api.post_enabled = True
        ensured = set(existing_shas)
        for path in sorted(files):
            expected = frozen[path]
            if expected in ensured:
                continue
            api.post_blob(files[path], expected)
            ensured.add(expected)
            receipt['created_blobs'].append(expected)
        require(set(frozen.values()) <= ensured, 'Some frozen blobs were not secured')
        receipt['status'] = 'RECOVERED_FROZEN_SOURCE'
        receipt['all_27_files_secured'] = True
        receipt['empty_blob_reused'] = EMPTY
        receipt['mutating_endpoint'] = 'repos/' + REPO + '/git/blobs'
    except Exception as error:
        receipt['error'] = type(error).__name__ + ': ' + str(error)
    finally:
        receipt['api_provenance'] = api.records
        write_new(out / 'receipt.json', json_bytes(receipt))
        print('[C4FixtureRecoveryReceipt] ' + json.dumps(receipt, separators=(',', ':'),
                                                      ensure_ascii=True), flush=True)
    return 0 if receipt['status'] == 'RECOVERED_FROZEN_SOURCE' else 1

if __name__ == '__main__':
    raise SystemExit(main())
