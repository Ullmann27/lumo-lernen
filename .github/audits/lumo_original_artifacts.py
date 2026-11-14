#!/usr/bin/env python3
"""Read fixed original LUMO artifacts; never run a game, test suite or publisher.

Only GET requests are allowed. Original archives stay in RUNNER_TEMP. Exported
base64 records preserve exact original bytes; they are not acceptance receipts.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
import time
import traceback
import xml.etree.ElementTree as ET
import zipfile

REPOSITORY = 'Ullmann27/lumo-lernen'
AUDIT_BRANCH = 'audit/lumo-originals-9de-20261114'
AUDIT_WORKFLOW = '.github/workflows/lumo-originals-9de-audit.yml'
AUDIT_SCRIPT = '.github/audits/lumo_original_artifacts.py'
AUDIT_MANIFEST = '.github/audits/lumo-original-artifacts.json'
HOST = '9deaa3f24561bc65caba898585c0c00f1c77162b'
HOST_TREE = 'c0a9e29c831113ea8e49e632bc7959a15079bc94'
NATIVE = 'bebf7bba48f09afc834469db0ea3c5541a184f55'
NATIVE_TREE = '35492eec16cac6774bc546b6e57628900bef61cb'
APP = '51ec0ac43f3e2aaac065e285e13cf5db5b5875d2'
MAIN_RUN = 43622379532
DIAGNOSTIC_RUN = 43622794130
DIAGNOSTIC_HEAD = '2322632c4adca243cea2ebdc5ecbfaa01c7e51cd'
CONTEXTS = {
    'early': (MAIN_RUN, HOST, '.github/workflows/lumo-connect-four-2020.yml', 'pull_request'),
    'late': (MAIN_RUN, HOST, '.github/workflows/lumo-connect-four-2020.yml', 'pull_request'),
    'diagnostic': (DIAGNOSTIC_RUN, DIAGNOSTIC_HEAD,
                   '.github/workflows/lumo-c4-return-51ec-diagnostic.yml', 'push'),
}
KINDS = {
    'flutter': ('early', 'lumo-candidate-all-flutter-tests-and-captures', 'verify-and-build'),
    'desktop': ('early', 'lumo-connect-four-2020-desktop-runtime', 'connect-four-runtime'),
    'compile': ('early', 'lumo-connect-four-2020-android-host-compile', 'android-host-compile'),
    'contracts': ('early', 'lumo-connect-four-2020-build-contracts', 'verify-and-build'),
    'learning': ('early', 'lumo-connect-four-2020-learning-curriculum-audit', 'verify-and-build'),
    'native': ('late', 'lumo-candidate-pinned-native-gameplay', 'verify-and-build'),
    'c4': ('late', 'lumo-connect-four-2020-android-c4', 'android-c4'),
    'update': ('late', 'lumo-connect-four-2020-in-place-update-proof', 'update-2020-from-2017'),
    'bundle': ('late', 'lumo-connect-four-2020-delivery-bundle', 'prepare-c4-delivery'),
    'diagnostic': ('diagnostic', 'diagnostic-only-51ec-c4-bounded-return',
                   'unchanged-apk-preferences-diagnostic'),
    'diagnostic_live': ('diagnostic', 'diagnostic-only-51ec-c4-bounded-return-live-log',
                        'unchanged-apk-preferences-diagnostic'),
}
HOST_READERS = {
    'candidate': ('scripts/verify_connect_four_candidate.py', '67ae17290e898a995003f065ce3a7c97202509ab'),
    'delivery': ('scripts/verify_connect_four_delivery.py', '28601267bc5d317244598b4304314bbd77107e0f'),
    'desktop': ('scripts/run_connect_four_runtime.py', '36d93ed0908705e339346bf5ef451cf047b641b5'),
    'c4': ('tools/android_qa/connect_four_android_evidence.py', 'd577691946a3c4100c6665efcc934eab6b7fe9aa'),
}
MAX_ARCHIVE = 2 * 1024**3
MAX_UNPACKED_TOTAL = 8 * 1024**3
MAX_EXPORT_FILE = 8 * 1024**2
MAX_EXPORT_TOTAL = 24 * 1024**2
RAW_CHUNK = 12 * 1024

def require(ok, message):
    if not ok:
        raise ValueError(message)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def strict_json(data):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate JSON key: ' + key)
            result[key] = value
        return result
    def invalid(value):
        raise ValueError('Nonfinite JSON constant: ' + value)
    return json.loads(data, object_pairs_hook=unique, parse_constant=invalid)

def json_bytes(value):
    return (json.dumps(value, indent=2, ensure_ascii=False) + '\n').encode()

def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(data)

def regular(path):
    require(path.is_file() and not path.is_symlink(), 'Missing regular original: ' + str(path))
    return path

def record(path):
    path = regular(path)
    with path.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    return {'bytes': path.stat().st_size, 'sha256': digest}

def read(path):
    return strict_json(regular(path).read_bytes())

def member(root, name):
    require(isinstance(name, str) and name and '\\' not in name, 'Invalid relative original path')
    rel = PurePosixPath(name)
    require(not rel.is_absolute() and '..' not in rel.parts and rel.as_posix() == name,
            'Noncanonical original path: ' + name)
    path = root.joinpath(*rel.parts)
    require(path.resolve().is_relative_to(root.resolve()), 'Original path escapes archive')
    return path

def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()

def checkout(root, revision, tree=None):
    require(root.is_dir() and not root.is_symlink()
            and Path(git(root, 'rev-parse', '--show-toplevel')).resolve() == root,
            'Expected a separate real checkout')
    require(git(root, 'rev-parse', 'HEAD') == revision, 'Checkout head differs')
    actual_tree = git(root, 'rev-parse', 'HEAD^{tree}')
    require(tree is None or actual_tree == tree, 'Checkout tree differs')
    require(not git(root, 'status', '--porcelain', '--untracked-files=no'), 'Tracked checkout changed')
    return {'commit': revision, 'tree': actual_tree, 'tracked_source_clean': True}

class API:
    def __init__(self, out):
        self.out, self.records, self.downloaded = out, [], set()
        self.env = os.environ.copy()
        self.env.pop('GH_DEBUG', None)
        self.env['GH_PROMPT_DISABLED'] = '1'

    def get(self, suffix, label):
        require(not suffix.startswith('/') and '..' not in suffix, 'Invalid GET suffix')
        endpoint = 'repos/' + REPOSITORY + '/' + suffix
        result = subprocess.run(['gh', 'api', '--method', 'GET', endpoint],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=self.env, check=False)
        require(result.returncode == 0, 'GitHub GET failed: ' + label)
        value = strict_json(result.stdout)
        path = 'api/' + f'{len(self.records)+1:03d}-' + label + '.json'
        save(self.out / path, result.stdout)
        self.records.append({'method': 'GET', 'endpoint': endpoint, 'path': path,
                             'bytes': len(result.stdout), 'sha256': sha(result.stdout)})
        return value

    def download(self, item, temporary):
        identifier = item['artifact_id']
        require(identifier not in self.downloaded, 'Duplicate artifact download requested')
        self.downloaded.add(identifier)
        path = temporary / (str(identifier) + '.zip')
        endpoint = f'repos/{REPOSITORY}/actions/artifacts/{identifier}/zip'
        with path.open('xb') as stream:
            result = subprocess.run(['gh', 'api', '--method', 'GET', endpoint],
                stdout=stream, stderr=subprocess.PIPE, env=self.env, check=False)
        require(result.returncode == 0, 'Original archive download failed')
        checked = record(path)
        require(checked == {'bytes': item['bytes'], 'sha256': item['sha256']},
                'Full original archive bytes differ')
        self.records.append({'method': 'GET', 'endpoint': endpoint,
                             'response_scope': 'RUNNER_TEMP only', **checked})
        return path

def extract_original(archive, root, inventory_path, remaining_budget):
    require(not root.exists(), 'Refusing to overwrite original archive contents')
    root.mkdir(parents=True)
    rows, seen, total = [], set(), 0
    with zipfile.ZipFile(archive) as zipped:
        infos = zipped.infolist()
        require(infos and sum(x.file_size for x in infos) <= remaining_budget,
                'Original archive exceeds reviewed extraction budget')
        for info in infos:
            name = info.filename.rstrip('/') if info.is_dir() else info.filename
            path = member(root, name)
            require(name not in seen and not info.flag_bits & 1,
                    'Duplicate or encrypted original ZIP member')
            seen.add(name)
            mode = stat.S_IFMT(info.external_attr >> 16)
            if info.is_dir():
                require(mode in (0, stat.S_IFDIR) and info.file_size == 0, 'Invalid ZIP directory')
                require(zipped.read(info) == b'', 'ZIP directory payload differs')
                path.mkdir(parents=True, exist_ok=True)
                continue
            require(mode in (0, stat.S_IFREG), 'Nonregular original ZIP member')
            path.parent.mkdir(parents=True, exist_ok=True)
            count, digest = 0, hashlib.sha256()
            with zipped.open(info) as source, path.open('xb') as target:
                for data in iter(lambda: source.read(1024 * 1024), b''):
                    count += len(data)
                    digest.update(data)
                    target.write(data)
            # Reaching EOF above verifies this member's original ZIP CRC.
            require(count == info.file_size, 'Truncated original ZIP member')
            total += count
            rows.append({'path': name, 'bytes': count, 'sha256': digest.hexdigest(),
                         'zip_crc32': f'{info.CRC:08x}'})
    rows.sort(key=lambda row: row['path'])
    save(inventory_path, json_bytes({
        'kind': 'new_read_only_audit_member_inventory',
        'original_inventory_claim': False, 'all_zip_member_crcs_checked': True,
        'archive_member_count': len(infos), 'file_count': len(rows), 'files': rows}))
    return rows, total

def load_readers(host):
    for path in (host/'scripts', host/'tools/android_qa', host/'.github/probes'):
        sys.path.insert(0, str(path))
    readers = {}
    for name, (relative, expected) in HOST_READERS.items():
        path = regular(host / relative)
        require(blob(path.read_bytes()) == expected, 'Reviewed reader changed: ' + relative)
        module_name = 'connect_four_android_evidence' if name == 'c4' else 'lumo_original_audit_' + name
        if module_name in sys.modules:
            module = sys.modules[module_name]
            require(Path(module.__file__).resolve() == path.resolve(), 'Reader imported from another checkout')
        else:
            spec = importlib.util.spec_from_file_location(module_name, path)
            require(spec is not None and spec.loader is not None, 'Cannot load original reader')
            module = importlib.util.module_from_spec(spec)
            sys.modules[module_name] = module
            spec.loader.exec_module(module)
        readers[name] = module
    return readers


def audit_identity(api, audit_root, manifest_path):
    require(os.environ.get('GITHUB_REPOSITORY') == REPOSITORY
            and os.environ.get('GITHUB_REF') == 'refs/heads/' + AUDIT_BRANCH,
            'Wrong audit repository or branch')
    head = os.environ['GITHUB_SHA']
    checked = checkout(audit_root, head)
    run_id, attempt = int(os.environ['GITHUB_RUN_ID']), int(os.environ['GITHUB_RUN_ATTEMPT'])
    run = api.get(f'actions/runs/{run_id}', 'audit-run')
    require(run['id'] == run_id and run['run_attempt'] == attempt
            and run['head_sha'] == head and run['head_branch'] == AUDIT_BRANCH
            and run['repository']['full_name'] == REPOSITORY
            and run['event'] == 'push' and run['path'] == AUDIT_WORKFLOW,
            'Audit run identity differs')
    require(manifest_path == audit_root / AUDIT_MANIFEST, 'Unexpected audit manifest path')
    identities = {}
    for relative in (AUDIT_SCRIPT, AUDIT_MANIFEST):
        original = api.get('contents/' + relative + '?ref=' + head,
                           'audit-script' if relative == AUDIT_SCRIPT else 'audit-manifest')
        raw = regular(audit_root / relative).read_bytes()
        require(original.get('type') == 'file' and original.get('path') == relative
                and original.get('encoding') == 'base64'
                and base64.b64decode(''.join(original['content'].split()), validate=True) == raw
                and original.get('sha') == blob(raw), 'Audit source bytes differ from GitHub')
        identities[relative] = {'bytes': len(raw), 'sha256': sha(raw), 'git_sha1': blob(raw)}
    return {'run_id': run_id, 'run_attempt': attempt, 'source': checked, 'files': identities}

def validate_manifest(value):
    require(isinstance(value, dict) and set(value) ==
            {'schema', 'phase', 'source', 'native', 'run_id', 'run_attempt', 'archives', 'candidate'},
            'Unexpected frozen manifest schema')
    phase = value['phase']
    require(value['schema'] == 1 and phase in CONTEXTS and value['source'] == HOST
            and value['native'] == NATIVE and type(value['run_attempt']) is int
            and value['run_attempt'] == 1 and value['run_id'] == CONTEXTS[phase][0],
            'Frozen manifest source/run differs')
    entries = value['archives']
    require(isinstance(entries, list) and entries and len(entries) <= 5,
            'Expected a bounded explicit archive list')
    require(len({x['kind'] for x in entries}) == len(entries)
            and len({x['artifact_id'] for x in entries}) == len(entries),
            'Duplicate archive kind or artifact ID')
    for item in entries:
        require(isinstance(item, dict) and set(item) ==
                {'kind', 'artifact_id', 'name', 'bytes', 'sha256', 'job_id', 'job_name', 'exports'},
                'Unexpected archive manifest schema')
        require(item['kind'] in KINDS
                and (phase, item['name'], item['job_name']) == KINDS[item['kind']],
                'Archive role/name/job differs from the reviewed workflow')
        require(type(item['artifact_id']) is int and item['artifact_id'] > 0
                and type(item['job_id']) is int and item['job_id'] > 0
                and type(item['bytes']) is int and 0 < item['bytes'] <= MAX_ARCHIVE
                and re.fullmatch('[a-f0-9]{64}', str(item['sha256'])), 'Invalid fixed archive identity')
        exports = item['exports']
        require(isinstance(exports, list) and len(exports) <= 12
                and len({x['path'] for x in exports}) == len(exports), 'Invalid explicit export list')
        require(sum(x.get('media') == 'png' for x in exports) <= 3, 'Too many selected original PNGs')
        for export in exports:
            require(set(export) == {'path', 'media', 'required'}
                    and export['media'] in ('json', 'text', 'png')
                    and type(export['required']) is bool, 'Invalid original export specification')
            member(Path('/audited-originals'), export['path'])
    if any(item['kind'] in ('c4', 'update', 'bundle') for item in entries):
        candidate = value['candidate']
        require(isinstance(candidate, dict) and set(candidate) ==
                {'artifact_id', 'bytes', 'sha256', 'apk'}, 'Expected frozen current APK provenance')
        require(type(candidate['artifact_id']) is int and candidate['artifact_id'] > 0
                and type(candidate['bytes']) is int and 0 < candidate['bytes'] <= MAX_ARCHIVE
                and re.fullmatch('[a-f0-9]{64}', str(candidate['sha256'])),
                'Invalid fixed current candidate artifact')
        apk = candidate['apk']
        require(isinstance(apk, dict) and re.fullmatch('[a-f0-9]{64}', str(apk.get('sha256')))
                and type(apk.get('bytes')) is int and apk['bytes'] > 0
                and apk.get('versionCode') == 2020 and apk.get('versionName') == '0.13.8'
                and apk.get('flutter_source_commit') == HOST
                and apk.get('signingCertificateSha256') ==
                    'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
                and isinstance(apk.get('godot'), dict)
                and apk['godot'].get('revision') == NATIVE
                and re.fullmatch('[a-f0-9]{64}', str(apk['godot'].get('pck_sha256'))),
                'Current expected x86 APK/native identity differs')
    else:
        require(value['candidate'] is None, 'This phase must not invent a candidate APK identity')
    return value

def original_metadata(api, manifest):
    run_id, head, workflow, event = CONTEXTS[manifest['phase']]
    run = api.get(f'actions/runs/{run_id}', 'original-run')
    jobs = api.get(f'actions/runs/{run_id}/attempts/1/jobs?per_page=100', 'original-jobs')
    artifacts = api.get(f'actions/runs/{run_id}/artifacts?per_page=100', 'original-artifacts')
    require(run.get('id') == run_id and run.get('run_attempt') == 1
            and run.get('head_sha') == head and run.get('path') == workflow
            and run.get('event') == event and run.get('repository', {}).get('full_name') == REPOSITORY,
            'Original source/run/attempt/workflow differs')
    for doc, key in ((jobs, 'jobs'), (artifacts, 'artifacts')):
        require(isinstance(doc.get(key), list) and doc.get('total_count') == len(doc[key]),
                'Truncated original API collection')
    bound = {}
    for item in manifest['archives']:
        found = [x for x in artifacts['artifacts'] if x.get('id') == item['artifact_id']]
        producer = [x for x in jobs['jobs'] if x.get('id') == item['job_id']]
        require(len(found) == len(producer) == 1, 'Missing exact artifact or producer job')
        row, job = found[0], producer[0]
        require(row.get('name') == item['name'] and row.get('size_in_bytes') == item['bytes']
                and row.get('digest') == 'sha256:' + item['sha256'] and row.get('expired') is False
                and row.get('workflow_run', {}).get('id') == run_id
                and row['workflow_run'].get('head_sha') == head, 'Original artifact API binding differs')
        require(job.get('name') == item['job_name'] and job.get('run_id') == run_id
                and job.get('run_attempt') == 1 and job.get('head_sha') == head
                and job.get('status') in ('in_progress', 'completed'),
                'Original producer job binding differs')
        bound[item['kind']] = {'artifact_id': row['id'], 'name': row['name'],
            'bytes': row['size_in_bytes'], 'sha256': item['sha256'],
            'producer_job_id': job['id'], 'producer_job_name': job['name'],
            'producer_status_at_read': job['status'], 'producer_conclusion_at_read': job['conclusion']}
    candidate = manifest['candidate']
    if candidate is not None:
        found = [x for x in artifacts['artifacts'] if x.get('id') == candidate['artifact_id']]
        require(len(found) == 1 and found[0].get('name') == 'lumo-connect-four-2020-candidate'
                and found[0].get('size_in_bytes') == candidate['bytes']
                and found[0].get('digest') == 'sha256:' + candidate['sha256']
                and found[0].get('workflow_run', {}).get('id') == MAIN_RUN
                and found[0]['workflow_run'].get('head_sha') == HOST
                and found[0].get('expired') is False, 'Current candidate upload binding differs')
    return {'run': run, 'jobs': jobs, 'artifacts': artifacts, 'bound_archives': bound}

class Exporter:
    def __init__(self, out):
        self.out, self.total, self.records, self.keys = out, 0, [], set()

    def emit(self, data, key, scope, media, original):
        require(key not in self.keys and len(data) <= MAX_EXPORT_FILE
                and self.total + len(data) <= MAX_EXPORT_TOTAL, 'Duplicate or oversized exact-byte export')
        self.keys.add(key)
        self.total += len(data)
        checksum = sha(data)
        destination = 'exports/' + f'{len(self.records)+1:03d}.bin'
        save(self.out / destination, data)
        checked = {'key': key, 'scope': scope, 'media': media, 'original_bytes': original,
                   'bytes': len(data), 'sha256': checksum, 'saved_path': destination}
        if media == 'png':
            from PIL import Image
            import io
            try:
                with Image.open(io.BytesIO(data)) as picture:
                    picture.load()
                    require(picture.format == 'PNG', 'Selected original export is not a PNG')
                    checked['pixels'] = list(picture.size)
            except Exception as error:
                # Preserve exact malformed originals too; never lose later exports.
                checked['png_decode_error'] = type(error).__name__ + ': ' + str(error)
        self.records.append(checked)
        pieces = [data[i:i+RAW_CHUNK] for i in range(0, len(data), RAW_CHUNK)] or [b'']
        for index, piece in enumerate(pieces, 1):
            encoded = base64.b64encode(piece).decode('ascii')
            require(len(encoded) <= 16 * 1024, 'Export chunk exceeds 16 KiB')
            print('[LumoOriginalExport] ' + json.dumps({
                'key': key, 'scope': scope, 'media': media, 'original_bytes': original,
                'encoding': 'base64', 'seq': index, 'total': len(pieces),
                'bytes': len(data), 'sha256': checksum, 'content': encoded},
                separators=(',', ':')), flush=True)
        return checked

def unchanged_members(root, rows):
    expected = {x['path']: {'bytes': x['bytes'], 'sha256': x['sha256']} for x in rows}
    actual = {}
    for path in sorted(root.rglob('*')):
        require(not path.is_symlink(), 'Reader created an evidence symlink')
        if path.is_file():
            actual[path.relative_to(root).as_posix()] = record(path)
    require(actual == expected, 'A read-only verifier changed the original archive contents')


def current_binding(readers, metadata, manifest):
    candidate = manifest['candidate']
    require(candidate is not None, 'No fixed current candidate provenance')
    return readers['c4'].artifact_binding(metadata['run'], metadata['artifacts'], metadata['jobs'],
        source=HOST, run_id=MAIN_RUN, attempt=1, artifact_id=candidate['artifact_id'],
        digest='sha256:' + candidate['sha256'], native=NATIVE, version_name='0.13.8')

def diagnostic_contract(root, report, c4):
    """Replay completed actual observations without creating a candidate report."""
    directory = root / 'c4'
    inventory = [{**row, 'path': row['path'][3:]} for row in report['originals']
                 if row['path'].startswith('c4/')]
    if not directory.is_dir():
        require(not inventory and not report.get('observations') and not report.get('transitions')
                and not report.get('returns') and report['status'] == 'FAIL',
                'Diagnostic C4 originals are missing unexpectedly')
        return {'status': 'C4_NOT_REACHED', 'observations': 0, 'transitions': 0, 'returns': 0,
                'complete_diagnostic_sequence': False, 'candidate_acceptance': False}
    require(inventory, 'No original C4 inventory available for replay')
    c4.verify_inventory(directory, inventory)
    observations = {name: c4.checked_observation(directory, name)
                    for name in report.get('observations', [])}
    require(len(observations) == len(report.get('observations', [])), 'Duplicate diagnostic observations')
    initial = observations.get(report.get('initial'))
    if initial is not None:
        require(initial['state']['columns'] == [] and initial['state']['twoPlayers'] is False,
                'Diagnostic initial round is not untouched')
        c4.checked_flutter_touch(directory, report['entry_touch'], c4.PORTAL)
    expected_actions = ['drop', 'pause', 'resume', 'drop', 'pause', 'pause']
    transitions = report.get('transitions', [])
    require([row.get('action') for row in transitions] == expected_actions[:len(transitions)],
            'Completed diagnostic transitions are not the required sequence prefix')
    previous = initial
    for index, step in enumerate(transitions):
        if index == 5:
            previous = observations[report['reopen']['opened']]
        before, after = observations[step['before']], observations[step['after']]
        require(previous is not None and before['state'] == previous['state']
                and before['pid'] == previous['pid']
                and before['host_pid'] == initial['host_pid'], 'Diagnostic transition authority differs')
        request = strict_json(c4.read_original(directory, step['request']))
        c4.acknowledged(before['state'], after['state'], request, step['action'])
        control = {'drop': 'column_' + str(request.get('column')),
                   'pause': 'pause', 'resume': 'resume'}[step['action']]
        c4.checked_native_touch(directory, step['touch'], observations, before, control)
        previous = after
    if 'pause_hold' in report:
        hold = report['pause_hold']
        require(len(transitions) >= 2 and hold['first'] == transitions[1]['after'],
                'Diagnostic pause hold belongs to another transition')
        first, second = observations[hold['first']], observations[hold['second']]
        require(hold['elapsed'] == second['observed_monotonic'] - first['observed_monotonic'],
                'Diagnostic pause duration differs')
        c4.paused_unchanged(first, second, hold['elapsed'])
    if 'reopen' in report:
        route = report['reopen']
        closed, opened = observations[route['closed']], observations[route['opened']]
        c4.reopened(closed['state'], opened['state'])
        require(closed['pid'] != opened['pid'] and len(closed['state']['columns']) == 4
                and opened['host_pid'] == initial['host_pid'], 'Diagnostic reopen authority differs')
        c4.checked_flutter_touch(directory, route['touch'], c4.PORTAL)
    returns = report.get('returns', [])
    require(len(returns) <= 2, 'Unexpected diagnostic return count')
    for index, returned in enumerate(returns):
        before = observations[returned['before']]
        expected = observations[transitions[4 if index == 0 else 5]['after']]
        require(before['state']['paused'] and before['state'] == expected['state']
                and before['pid'] == expected['pid'], 'Diagnostic return belongs to another sequence')
        if index == 0 and 'reopen' in report:
            require(returned['before'] == report['reopen']['closed'], 'Reopen precedes a different return')
        c4.checked_native_touch(directory, returned['touch'], observations, before, 'back')
        pid = c4.safe_member(directory, returned['native_exit'])
        meta = read(c4.safe_member(directory, returned['native_exit'][:-7]+'.json'))
        stderr = c4.safe_member(directory, returned['native_exit'][:-7]+'.stderr')
        require(pid.read_bytes() == stderr.read_bytes() == b'' and meta['returncode'] == 1
                and meta['command'] == ['adb', 'shell', 'pidof', c4.PACKAGE+':lumo_game'],
                'Diagnostic native absence was not actually observed')
        require(not c4.read_original(directory, returned['closed_mailbox'], empty_ok=True).strip(),
                'Diagnostic mailbox is still present')
        activity = c4.read_original(directory, returned['activity'])
        resumed = [line for line in activity.splitlines()
                   if 'mResumedActivity' in line or 'topResumedActivity' in line]
        require(resumed and all('MainActivity' in line and c4.PACKAGE in line for line in resumed),
                'Diagnostic Flutter foreground missing')
        require(c4.persisted_round(c4.preferences(c4.read_original(directory, returned['preferences'])),
                                  before['state']) == returned['round'],
                'Diagnostic returned persistence differs')
        ui = ET.fromstring(c4.safe_member(directory, returned['returned_ui']).read_bytes())
        labels = '\n'.join(n.get('text', '')+'\n'+n.get('content-desc', '') for n in ui.iter('node'))
        require('Spiel pausiert' in labels and 'Fortsetzen' in labels, 'Paused Flutter UI missing')
        frame = c4.safe_member(directory, returned['frame']['file'])
        require(c4.sha256(frame) == returned['frame']['sha256'], 'Returned original frame differs')
        from PIL import Image
        with Image.open(frame) as png:
            png.load()
            require(png.format == 'PNG' and min(png.size) > 100, 'Invalid original return PNG')
        c4.checked_flutter_touch(directory, returned['to_games_touch'], 'Zur Spieleauswahl')
    learning_checked = False
    if 'preferences_before' in report and 'preferences_after' in report:
        c4.learning_unchanged(c4.preferences(c4.read_original(directory, report['preferences_before'])),
                             c4.preferences(c4.read_original(directory, report['preferences_after'])))
        learning_checked = True
    if 'original_logcat' in report:
        relative = report['original_logcat']
        require(relative.startswith('c4/'), 'Unexpected diagnostic logcat root')
        errors = c4.runtime_errors(c4.read_original(directory, relative[3:]))
        require(errors == report.get('fatal_entries'), 'Diagnostic runtime error replay differs')
    if 'android_sdk_original' in report:
        require(c4.read_original(directory, report['android_sdk_original']).strip() == '35',
                'Diagnostic API differs')
    complete = (initial is not None and len(transitions) == 6 and len(returns) == 2
                and 'pause_hold' in report and 'reopen' in report and learning_checked
                and report.get('fatal_entries') == [] and 'original_logcat' in report)
    require(report['status'] != 'PASS' or complete, 'PASS diagnostic is missing mandatory actual evidence')
    return {'status': 'COMPLETED_ORIGINAL_PARTS_REPLAYED', 'observations': len(observations),
            'transitions': len(transitions), 'returns': len(returns),
            'complete_diagnostic_sequence': complete, 'learning_preservation_checked': learning_checked,
            'candidate_acceptance': False, 'original_status': report['status']}

def check_diagnostic(root, c4):
    report = read(root / 'diagnostic-result.json')
    require(report.get('status') in ('PASS', 'FAIL') and report.get('diagnostic_only') is True
            and report.get('eligible_for_candidate_acceptance') is False
            and report.get('apk_source') == APP and report.get('observer_source') == HOST
            and report.get('native_source') == NATIVE, 'Original diagnostic identity differs')
    binding = report.get('binding', {})
    require(binding.get('diagnostic', {}).get('source') == DIAGNOSTIC_HEAD
            and binding['diagnostic'].get('run_id') == DIAGNOSTIC_RUN
            and binding['diagnostic'].get('run_attempt') == 1,
            'Original diagnostic driver/run binding differs')
    require(binding.get('diagnostic_only') is True
            and binding.get('eligible_for_candidate_acceptance') is False
            and binding['diagnostic'].get('driver_blob') == '549fce8c61fe5dbdf7ebf4fb3409cc40af391daa'
            and binding['diagnostic'].get('driver_sha256') == '1a99362f0229f34060d6f0980afd281879bc0f1b7b2895a924e7b32b1b4977f3',
            'Original reviewed diagnostic driver differs')
    sources = binding.get('sources', {})
    require(sources.get('app') == {'commit': APP, 'tree': 'e922f8d01fe31b07ac3c5cb196451dcbedb269d0', 'tracked_source_clean': True}
            and sources.get('observer') == {'commit': HOST, 'tree': HOST_TREE, 'tracked_source_clean': True}
            and sources.get('observer_ancestry') == [HOST, '7c5bef2bc39024fc2c1018523cabc651820cf76b', APP],
            'Diagnostic app and observer were conflated')
    apk = binding.get('apk', {})
    require(apk.get('flutter_source_commit') == APP
            and apk.get('apk_sha256') == '70dcdf23005390ed5f3b8b4ffe92f987801ecf45dba1a51344a091e2ef6ffd9c'
            and apk.get('godot_revision') == NATIVE
            and apk.get('godot_pck_sha256') == '80d83d9baf67344f56ac235a38d3e829f112740eeb2520ece50afb6d81479787',
            'Diagnostic old APK/native identity differs')
    rows = report.get('originals')
    require(isinstance(rows, list) and rows and len(rows) == len({row['path'] for row in rows}),
            'Missing or duplicate original diagnostic inventory')
    expected = {}
    for row in rows:
        path = member(root, row['path'])
        require(record(path) == {'bytes': row['bytes'], 'sha256': row['sha256']},
                'Original diagnostic inventory mismatch: ' + row['path'])
        expected[row['path']] = True
    actual = {p.relative_to(root).as_posix() for p in root.rglob('*')
              if p.is_file() and p != root / 'diagnostic-result.json'}
    require(set(expected) == actual, 'Original diagnostic inventory is incomplete')
    result = {'original_status': report['status'], 'original_error': report.get('error'),
              'original_inventory_files': len(rows), 'candidate_acceptance': False}
    result['contract'] = diagnostic_contract(root, report, c4)
    return result

def check_kind(kind, root, readers, host, native, manifest, metadata):
    c4 = readers['c4']
    if kind == 'flutter':
        return checked_flutter_originals(root, host)
    if kind == 'contracts':
        return readers['delivery'].checked_pcm_log(root/'build-contracts.log')
    if kind == 'learning':
        return readers['delivery'].checked_learning_audit(root,
            {'host_source': HOST, 'run_id': MAIN_RUN, 'run_attempt': 1})
    if kind == 'desktop':
        directory = root / 'runtime'
        report = read(directory / 'runtime-gate.json')
        before, after = read(directory/'source-before.json'), read(directory/'source-after.json')
        require(report.get('passed') is True and report.get('exit_codes') == {'dart': 0, 'godot': 0}
                and before == after and before.get('host', {}).get('head') == HOST
                and before.get('native', {}).get('head') == NATIVE,
                'Original desktop source/process result differs')
        log = readers['desktop'].validate_native_log(directory / 'original-godot.log')
        checked = readers['desktop'].validate_results(directory, report['session'])
        require(log == report.get('original_godot_log') and checked == report.get('results'),
                'Original desktop log/state/raster replay differs')
        return {'status': 'ORIGINAL_DESKTOP_REPLAY_PASS',
                'results': {key: value for key, value in checked.items() if key != 'images'},
                'verified_original_pngs': len(checked['images']),
                'original_godot_log': log, 'android_or_device_fps_acceptance': False}
    if kind == 'compile':
        summary, classes = read(root/'result.json'), read(root/'connect-four-classes.json')
        require(summary.get('flutter_source_commit') == classes.get('source') == HOST,
                'Original compile source binding differs')
        return {'status': 'SOURCE_BOUND_ORIGINAL_SUMMARIES_ONLY',
                'original_compile_status': summary.get('status'),
                'original_classes_status': classes.get('status'),
                'limitation': 'No standalone existing host-bytecode replay reader; original reports exported. No recompilation.'}
    if kind == 'native':
        result = readers['delivery'].checked_native(root, native, NATIVE)
        return {**result, 'legacy_replay_limit': 'This helper replays 52 Nextgen modes and raster/movie rosters. Other Legacy/2014/TechnicalArt/Action logs are preserved as originals, not counted as additional replayed modes.'}
    if kind == 'c4':
        report = read(root/'c4/c4-result.json')
        identity, apk = report.get('identity', {}), manifest['candidate']['apk']
        require(identity.get('apk_sha256') == apk['sha256']
                and identity.get('flutter_source_commit') == HOST
                and identity.get('godot_revision') == NATIVE
                and identity.get('godot_pck_sha256') == apk['godot']['pck_sha256']
                and identity.get('versionCode') == 2020 and identity.get('versionName') == '0.13.8'
                and identity.get('signingCertificateSha256') == apk['signingCertificateSha256']
                and identity.get('checks') and all(x is True for x in identity['checks'].values()),
                'Original C4 identity differs from frozen current build provenance')
        main = read(root/'main/tour-result.json')
        require(main.get('status') == 'PASS' and main.get('apk_sha256') == apk['sha256']
                and main.get('fatal_crashes') == 0
                and c4.sha256(root/'main/tour-result.json') == report['prior_tour']['sha256'],
                'Original preceding main tour differs')
        c4.verify_inventory(root/'c4', report['originals'])
        return c4.verify_report(root/'c4', current_binding(readers, metadata, manifest), identity)
    if kind == 'update':
        result = readers['candidate'].update_proof(root, manifest['candidate']['apk'], HOST)
        return {**result, 'original_complete_member_inventory': False,
                'inventory_limit': 'The original update runner emitted no complete member-hash inventory; the separate audit inventory is newly generated.',
                'apk_binary_reopened_by_this_audit': False}
    if kind == 'bundle':
        plan = readers['delivery'].checked_plan(root)
        facts = read(root/'assets/C4-DELIVERY-FACTS.json')
        require(plan.get('host_source') == facts.get('host_source') == HOST
                and facts.get('host_tree') == HOST_TREE
                and facts.get('status') == 'VERIFIED_TEST_BUNDLE_NOT_PUBLISHED'
                and facts.get('published') is False and facts.get('release_approved') is False,
                'Original prepared bundle identity/status differs')
        return {'status': 'ORIGINAL_PLAN_AND_ASSET_HASHES_REPLAYED',
                'original_delivery_status': facts['status'], 'published': False,
                'candidate_acceptance': False,
                'limitation': 'Only immutable bundle/plan/assets replay; the unchanged mandatory delivery/publisher policy remains separate.'}
    if kind == 'diagnostic':
        return check_diagnostic(root, c4)
    if kind == 'diagnostic_live':
        return {'status': 'EXACT_ARCHIVE_ONLY', 'scope': 'Separate original live end log; cross-check against immutable prefix follows.'}
    raise ValueError('Unsupported fixed artifact role')

DEFAULT_EXPORTS = {
    'flutter': ['acceptance-summary.json', 'flutter-machine.jsonl'],
    'desktop': ['runtime/runtime-gate.json', 'runtime/source-before.json', 'runtime/source-after.json',
                'runtime/dart-result.json', 'runtime/native-result.json'],
    'compile': ['result.json', 'connect-four-classes.json'],
    'contracts': ['build-contracts.log'],
    'learning': ['source-binding.json', 'summary.json', 'task-families.json', 'issues.json'],
    'native': ['source-sha.txt', 'project.log', 'legacy-gameplay.log', 'nextgen-runner.log',
               'nextgen/results.tsv', 'nextgen/studio-2020-images.json',
               'nextgen/renderer-images.json', 'nextgen/village-images.json',
               'nextgen/puzzle-menu-images.json', 'nextgen/safe-area-images.json'],
    'c4': ['c4/c4-result.json', 'main/tour-result.json'],
    'update': ['update-result.json'],
    'bundle': ['publication-plan.json', 'assets/C4-DELIVERY-FACTS.json',
               'assets/C4-CANDIDATE-FACTS.json', 'assets/C4-ANDROID-RESULT.json',
               'assets/UPDATE-2020-RESULT.json'],
    'diagnostic': ['diagnostic-result.json', 'diagnostic-binding.json', 'main/tour-result.json'],
    'diagnostic_live': ['xvfb.log'],
}

def check_live_prefix(roots):
    require('diagnostic' in roots and 'diagnostic_live' in roots,
            'A full diagnostic prefix comparison requires both fixed original artifacts')
    report = read(roots['diagnostic']/'diagnostic-result.json')
    snapshot = report['live_log_snapshot']
    prefix = regular(member(roots['diagnostic'], snapshot['snapshot_path'])).read_bytes()
    live = regular(roots['diagnostic_live']/'xvfb.log').read_bytes()
    require(snapshot['source_path'] == 'live-logs/xvfb.log'
            and snapshot['snapshot_bytes'] == snapshot['source_bytes_at_open'] == len(prefix)
            and snapshot['snapshot_sha256'] == sha(prefix)
            and len(live) >= snapshot['source_bytes_after_read'] >= len(prefix)
            and live[:len(prefix)] == prefix, 'Original separate live log does not preserve observed prefix')
    return {'status': 'ORIGINAL_PREFIX_MATCHES_SEPARATE_END_LOG', 'prefix_bytes': len(prefix),
            'prefix_sha256': sha(prefix), 'live_end_bytes': len(live), 'live_end_sha256': sha(live),
            'later_appended_bytes': len(live)-len(prefix), 'c4_cause_claim': False}


def checked_flutter_originals(evidence_root, candidate_root):
    """Read the full original machine log; never launch Flutter or render."""
    import collections
    root = Path(evidence_root)
    require(root.is_dir() and not root.is_symlink(), 'Missing regular Flutter evidence directory')
    root = root.resolve(strict=True)
    helper = regular(Path(candidate_root) / 'scripts/run_full_flutter_acceptance.py')
    helper_bytes = helper.read_bytes()
    helper_blob = blob(helper_bytes)
    require(helper_blob == '8d17cf8175ce13ef1d756526fa13c306c846ac72',
            'The reviewed actual Flutter summarizer changed')
    spec = importlib.util.spec_from_file_location('lumo_readonly_flutter_summary', helper)
    require(spec is not None and spec.loader is not None, 'Cannot load candidate summarizer')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    files = {}
    for path in sorted(root.rglob('*')):
        mode = path.lstat().st_mode
        require(not stat.S_ISLNK(mode) and (stat.S_ISREG(mode) or stat.S_ISDIR(mode)),
                'Nonregular Flutter evidence member')
        if stat.S_ISREG(mode):
            files[path.relative_to(root).as_posix()] = path
    require('acceptance-summary.json' in files and 'flutter-machine.jsonl' in files,
            'Missing original full Flutter report or complete machine log')
    summary = read(files['acceptance-summary.json'])
    require(isinstance(summary, dict) and type(summary.get('flutter_exit_code')) is int
            and summary['flutter_exit_code'] == 0, 'Original Flutter did not exit successfully')
    require(type(summary.get('passed')) is int and summary['passed'] > 0,
            'Original Flutter has no positive integer test count')
    require(summary.get('runner_completed_successfully') is True
            and summary.get('runner_errors') == [], 'Original Flutter runner was incomplete or stalled')
    require(summary.get('scope') == ['complete Flutter suite; capture outputs recorded below'],
            'This is not the complete original Flutter suite')
    events, starts, finished = [], {}, {}
    event_types = collections.Counter()
    process_notifications = blank_separators = line_count = done_count = 0
    with files['flutter-machine.jsonl'].open(encoding='utf-8') as stream:
        for line_count, line in enumerate(stream, 1):
            if not line.strip():
                blank_separators += 1
                continue
            value = strict_json(line)
            if isinstance(value, list):
                require(len(value) == 1 and isinstance(value[0], dict),
                        'Unknown boxed Flutter protocol event')
                notification = value[0]
                require(set(notification) == {'event', 'params'}
                        and notification['event'] == 'test.startedProcess'
                        and isinstance(notification['params'], dict)
                        and set(notification['params']) == {'vmServiceUri'}
                        and (notification['params']['vmServiceUri'] is None
                             or isinstance(notification['params']['vmServiceUri'], str)),
                        'Unknown Flutter process notification')
                process_notifications += 1
                continue
            require(isinstance(value, dict) and isinstance(value.get('type'), str)
                    and value['type'], 'Unknown original Flutter machine record')
            kind = value['type']
            event_types[kind] += 1
            require(kind != 'error', 'Original Flutter error event at line ' + str(line_count))
            if kind == 'testStart':
                require(done_count == 0 and isinstance(value.get('test'), dict),
                        'Invalid or late Flutter test start')
                test = value['test']
                identifier = test.get('id')
                require(type(identifier) is int and identifier not in starts
                        and isinstance(test.get('name'), str), 'Duplicate or invalid Flutter test ID')
                starts[identifier] = test['name']
            elif kind == 'testDone':
                identifier = value.get('testID')
                require(done_count == 0 and type(identifier) is int and identifier in starts
                        and identifier not in finished, 'Duplicate, late or unmatched Flutter outcome')
                require(value.get('result') in ('success', 'failure', 'error'),
                        'Unknown original Flutter test result')
                require(all(key not in value or type(value[key]) is bool
                            for key in ('hidden', 'skipped')), 'Invalid Flutter result flags')
                finished[identifier] = value
            elif kind == 'done':
                done_count += 1
                require(done_count == 1 and value.get('success') is True,
                        'Flutter completion missing, duplicated or unsuccessful')
            events.append(value)
    require(done_count == 1 and starts and set(starts) == set(finished),
            'Original Flutter log has unfinished tests or no terminal success')
    capture_errors = sorted(name for name in files if name.endswith('.error.txt'))
    measured = module.summarize(events, summary['flutter_exit_code'], capture_errors)
    require(measured['status'] == 'PASS', 'Actual Flutter events or capture-error files do not pass')
    require(all(summary.get(key) == value for key, value in measured.items()),
            'Original Flutter summary differs from its complete machine log')
    expected_keys = set(measured) | {'runner_errors', 'scope', 'capture_png_counts',
                                    'capture_file_outputs', 'rendered_png_count'}
    require(set(summary) == expected_keys, 'Original Flutter summary schema differs')
    pngs = sorted(name for name in files if name.endswith('.png'))
    measured_directories = {
        key: {'directory': directory, 'pngs': sum(name.startswith(directory + '/') for name in pngs)}
        for key, directory in module.CAPTURE_DIRECTORIES.items()}
    recorded_directories = summary.get('capture_png_counts')
    require(isinstance(recorded_directories, dict)
            and all(isinstance(row, dict) and type(row.get('pngs')) is int
                    for row in recorded_directories.values())
            and recorded_directories == measured_directories,
            'Flutter capture-directory counts differ from actual files')
    measured_files = {key: {'path': relative, 'created': relative in files}
                      for key, relative in module.CAPTURE_FILES.items()}
    recorded_files = summary.get('capture_file_outputs')
    require(isinstance(recorded_files, dict)
            and all(isinstance(row, dict) and type(row.get('created')) is bool
                    for row in recorded_files.values())
            and recorded_files == measured_files, 'Flutter named outputs differ from actual files')
    require(type(summary.get('rendered_png_count')) is int
            and summary['rendered_png_count'] == len(pngs), 'Flutter total PNG count differs')
    return {'status': 'ORIGINAL_FULL_FLUTTER_REPLAY_PASS',
        'scope': 'Read-only original machine-log and capture-count verification; no new tests, render or human visual review',
        'summarizer_git_blob': helper_blob,
        'passed': measured['passed'], 'failed': measured['failed'], 'skipped': measured['skipped'],
        'completed_test_records': len(finished),
        'hidden_completed_records': sum(item.get('hidden') is True for item in finished.values()),
        'event_type_counts': dict(sorted(event_types.items())),
        'process_notifications': process_notifications, 'blank_protocol_separators': blank_separators,
        'machine_lines': line_count, 'nonempty_unparsed_lines': 0, 'done_success': True,
        'flutter_exit_code': summary['flutter_exit_code'], 'capture_error_files': capture_errors,
        'capture_png_counts': measured_directories, 'capture_file_outputs': measured_files,
        'rendered_png_count': len(pngs), 'png_decode_performed_by_this_function': False,
        'originals': [{'path': name, **record(files[name])}
                      for name in ('acceptance-summary.json', 'flutter-machine.jsonl')]}


def original_status(kind, root):
    paths = {'flutter': 'acceptance-summary.json', 'learning': 'summary.json',
             'compile': 'result.json', 'c4': 'c4/c4-result.json', 'update': 'update-result.json',
             'bundle': 'assets/C4-DELIVERY-FACTS.json', 'diagnostic': 'diagnostic-result.json'}
    if kind in paths:
        path = member(root, paths[kind])
        return read(path).get('status') if path.is_file() else 'REPORT_NOT_PRESENT'
    if kind == 'desktop':
        return 'PASS' if read(root/'runtime/runtime-gate.json').get('passed') is True else 'FAIL'
    return 'CHECK_READER_AND_ORIGINAL_LOGS'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('host-source', 'native-source', 'manifest', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    for key, value in vars(args).items():
        setattr(args, key, value.resolve())
    sys.dont_write_bytecode = True
    audit_root = Path(__file__).resolve().parents[2]
    out = args.out
    require(not out.exists(), 'Refusing to replace existing audit evidence')
    require(not any(out.is_relative_to(path) or path.is_relative_to(out)
                    for path in (audit_root, args.host_source, args.native_source)),
            'Audit output must be separate from every source checkout')
    out.mkdir(parents=True)
    api, exporter = API(out), Exporter(out)
    receipt = {'schema': 1, 'kind': 'read_only_original_artifact_audit',
               'status': 'AUDIT_FAILED', 'candidate_acceptance': False,
               'publication_authorization': False, 'product_tests_executed': False,
               'git_writes_performed': False, 'archives': [], 'errors': []}
    roots, snapshots = {}, {}
    try:
        receipt['audit_identity'] = audit_identity(api, audit_root, args.manifest)
        manifest = validate_manifest(read(args.manifest))
        receipt['manifest'] = manifest
        receipt['original_context'] = {'phase': manifest['phase'],
            'run_id': CONTEXTS[manifest['phase']][0], 'run_attempt': 1,
            'workflow_head': CONTEXTS[manifest['phase']][1], 'qa_source': HOST,
            'app_source': APP if manifest['phase'] == 'diagnostic' else HOST, 'native_source': NATIVE}
        receipt['source_before'] = {
            'host': checkout(args.host_source, HOST, HOST_TREE),
            'native': checkout(args.native_source, NATIVE, NATIVE_TREE)}
        readers = load_readers(args.host_source)
        metadata = original_metadata(api, manifest)
        receipt['current_candidate_identity_limit'] = (
            'If supplied, APK identities are frozen original build-provenance inputs bound to the original candidate upload. '
            'This audit does not reopen APK binaries or replace the mandatory APK/candidate/delivery verifiers.')
        temporary_root = Path(os.environ['RUNNER_TEMP']).resolve()
        require(temporary_root.is_dir(), 'Missing runner temporary directory')
        temporary = temporary_root / ('lumo-original-audit-' + os.environ['GITHUB_RUN_ID']
                                       + '-' + os.environ['GITHUB_RUN_ATTEMPT'])
        require(not temporary.exists() and not temporary.is_relative_to(out),
                'Temporary originals must be new and outside exported evidence')
        temporary.mkdir()
        remaining_budget = MAX_UNPACKED_TOTAL
        for item in manifest['archives']:
            kind = item['kind']
            entry = {'kind': kind, **metadata['bound_archives'][kind],
                     'archive_integrity': 'NOT_CHECKED', 'semantic_replay': 'NOT_CHECKED',
                     'original_status': 'NOT_READ', 'missing_export_members': []}
            receipt['archives'].append(entry)
            root = temporary / kind
            rows = None
            try:
                archive = api.download(item, temporary)
                inventory_path = out/'new-member-inventories'/(kind+'.json')
                rows, amount = extract_original(archive, root, inventory_path, remaining_budget)
                remaining_budget -= amount
                roots[kind], snapshots[kind] = root, rows
                entry['archive_integrity'] = 'FULL_SHA256_AND_ALL_MEMBER_CRCS_MATCH'
                entry['new_member_inventory'] = {'path': str(inventory_path.relative_to(out)),
                    'original_inventory_claim': False, 'file_count': len(rows), **record(inventory_path)}
                exporter.emit(inventory_path.read_bytes(), 'new-inventory/'+kind,
                    'new_read_only_audit_inventory', 'json', False)
                entry['original_status'] = original_status(kind, root)
                try:
                    checked = check_kind(kind, root, readers, args.host_source, args.native_source, manifest, metadata)
                    semantic_path = out/'semantic-replays'/(kind+'.json')
                    save(semantic_path, json_bytes(checked))
                    entry['semantic_replay'] = 'COMPLETED_WITH_STATED_SCOPE'
                    entry['reader_result'] = checked
                except Exception as error:
                    entry['semantic_replay'] = 'FAILED'
                    entry['semantic_error'] = type(error).__name__ + ': ' + str(error)
                    receipt['errors'].append({'kind': kind, 'stage': 'semantic_replay',
                                              'error': entry['semantic_error']})
            except Exception as error:
                entry['integrity_error'] = type(error).__name__ + ': ' + str(error)
                receipt['errors'].append({'kind': kind, 'stage': 'archive_or_report',
                                          'error': entry['integrity_error']})
            finally:
                if rows is not None:
                    try:
                        unchanged_members(root, rows)
                        entry['original_members_unchanged_after_readers'] = True
                    except Exception as error:
                        receipt['errors'].append({'kind': kind, 'stage': 'original_immutability',
                            'error': type(error).__name__ + ': ' + str(error)})
                    selections = {name: {'path': name, 'media': 'json' if name.endswith('.json') else 'text',
                                         'required': False} for name in DEFAULT_EXPORTS[kind]}
                    selections.update({x['path']: x for x in item['exports']})
                    if kind == 'diagnostic':
                        # Root requested every small original OCR/gesture journal for this exact failed selector.
                        for row in rows:
                            name = row['path']
                            if (name.startswith('main/21_stage_select_gecko_velo')
                                    and Path(name).suffix in ('.json', '.tsv', '.txt', '.log')
                                    and row['bytes'] <= 512 * 1024):
                                selections.setdefault(name, {'path': name,
                                    'media': 'json' if name.endswith('.json') else 'text', 'required': True})
                    for name, selected in selections.items():
                        try:
                            path = member(root, name)
                            if not path.is_file():
                                entry['missing_export_members'].append(name)
                                require(not selected['required'], 'Required original export missing: ' + name)
                                continue
                            original_row = next((row for row in rows if row['path'] == name), None)
                            raw = regular(path).read_bytes()
                            require(original_row is not None and len(raw) == original_row['bytes']
                                    and sha(raw) == original_row['sha256'],
                                    'Original selected export changed after extraction')
                            exported = exporter.emit(raw,
                                str(item['artifact_id'])+'/'+name, 'original_archive_member',
                                selected['media'], True)
                            if 'png_decode_error' in exported:
                                receipt['errors'].append({'kind': kind, 'stage': 'selected_png_decode',
                                    'path': name, 'error': exported['png_decode_error']})
                        except Exception as error:
                            receipt['errors'].append({'kind': kind, 'stage': 'exact_byte_export',
                                'path': name, 'error': type(error).__name__ + ': ' + str(error)})
        if manifest['phase'] == 'diagnostic':
            try:
                receipt['live_prefix_replay'] = check_live_prefix(roots)
            except Exception as error:
                receipt['errors'].append({'stage': 'live_prefix_replay',
                    'error': type(error).__name__ + ': ' + str(error)})
        receipt['source_after'] = {
            'host': checkout(args.host_source, HOST, HOST_TREE),
            'native': checkout(args.native_source, NATIVE, NATIVE_TREE)}
        require(receipt['source_after'] == receipt['source_before'], 'Read-only source checkouts changed')
        for provenance in api.records:
            if 'path' in provenance:
                exporter.emit(regular(out/provenance['path']).read_bytes(),
                    'provenance/'+provenance['path'], 'original_github_api_response', 'json', True)
        original_failures = [row['kind'] for row in receipt['archives']
                             if row['original_status'] in ('FAIL', 'FAILED', 'REPORT_NOT_PRESENT')]
        receipt['original_failures_preserved'] = original_failures
        receipt['archive_integrity_complete'] = all(row['archive_integrity'] ==
            'FULL_SHA256_AND_ALL_MEMBER_CRCS_MATCH' for row in receipt['archives'])
        if not receipt['errors']:
            receipt['status'] = ('ORIGINAL_FAILURE_PRESERVED' if original_failures
                                 else 'ORIGINALS_CHECKED_WITH_DECLARED_SCOPE')
    except Exception as error:
        receipt['errors'].append({'stage': 'audit_binding_or_completion',
                                  'error': type(error).__name__ + ': ' + str(error)})
    finally:
        receipt['exports'] = exporter.records
        receipt['api_provenance'] = api.records
        receipt['archive_downloads'] = sorted(api.downloaded)
        save(out/'audit-receipt.json', json_bytes(receipt))
        print('[LumoOriginalAuditReceipt] ' + json.dumps(receipt, ensure_ascii=True,
                                                       separators=(',', ':')), flush=True)
    return 0 if receipt['status'] == 'ORIGINALS_CHECKED_WITH_DECLARED_SCOPE' else 1

if __name__ == '__main__':
    raise SystemExit(main())
