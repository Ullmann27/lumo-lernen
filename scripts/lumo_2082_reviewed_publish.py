#!/usr/bin/env python3
"""Publish one reviewed 2082 ARM64 candidate without rebuilding or re-signing it."""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener
import zipfile

from lumo_team_b_reviewed_publish import (
    BACKUP_STEPS, TOUR_STEPS,
    archive_matches, decode, digest, read, require, same, save,
    passed_steps, verify_identity, verify_metadata,
)
from verify_native_start_diagnostics import verify as verify_native_starts

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools/nextgen'))
from public_learning_download import AnonymousRedirect, download_public, require_https

REPOSITORY = 'Ullmann27/lumo-lernen'
REPOSITORY_ID = 1222433959
OWNER_ID = 64243701
PUBLISHER_BRANCH = 'support/lumo-2082-reviewed-publication'
PUBLISHER_WORKFLOW = '.github/workflows/lumo-2082-reviewed-publish.yml'
SOURCE_BRANCH = 'integration/lumo-intelligence-2082-20261125'
SOURCE_WORKFLOW = '.github/workflows/lumo-intelligence-2082.yml'
APK = 'Lumo-Lernen-Test-0.14.9-2082.apk'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
ROOT = Path('reviewed-2082')
REQUEST = Path('config/lumo-2082-reviewed-publish.json')
FIXED = {
    'schema': 2, 'repository': REPOSITORY, 'repository_id': REPOSITORY_ID,
    'repository_owner_id': OWNER_ID, 'branch': SOURCE_BRANCH,
    'build_workflow': SOURCE_WORKFLOW,
    'version_name': '0.14.9', 'version_code': 2082,
    'apk_file': APK, 'certificate_sha256': CERT,
    'publisher_authentication': 'github-actions-installation-token',
}
ARTIFACT_PREFIXES = {
    'apk': 'LUMO-TEST-APK', 'android': 'LUMO-ANDROID-TOUR',
    'intelligence': 'LUMO-INTELLIGENCE-TESTS',
}
INTEGER_FIELDS = {
    'build_run_id', 'build_run_attempt', 'intelligence_job_id',
    'build_job_id', 'android_job_id', 'apk_bytes', 'pck_bytes',
    *(label + suffix for label in ARTIFACT_PREFIXES
      for suffix in ('_artifact_id', '_artifact_bytes')),
}
HASH_FIELDS = {
    'apk_sha256', 'pck_sha256',
    *(label + '_artifact_sha256' for label in ARTIFACT_PREFIXES),
}
COMMIT_FIELDS = {'flutter_commit', 'godot_commit'}
JOB_NAMES = {
    'intelligence_job_id': 'Echte Lernanalysen, Lernhilfe und Hausaufgaben prüfen',
    'build_job_id': 'Signierte Test-APK bauen',
    'android_job_id': 'Installierte APK im Android-Emulator prüfen',
}
INTELLIGENCE_STEPS = {
    'Abhängigkeiten und neue Lernwege prüfen',
    'Tatsächliche Prüfergebnisse sichern',
}
BUILD_STEPS = {
    'Quellstand und Godot-Pin festhalten',
    'Native Sprache, Lerndialog und Datensicherung – JVM-Verträge',
    'Flutter – Analyse und vollständige Testsuite',
    'Godot – gepinnter Spielstand startet und besteht seine Kernprüfungen',
    'World – integrierte Missionen, Kart, Figuren und Spielstand',
    'Eine signierte Flutter-Godot-APK bauen',
    'Paketname und Signaturzertifikat gegen die installierte 2078 prüfen',
    'APK und Belege als Artefakt sichern',
}
ANDROID_STEPS = {
    'Run reactivecircus/android-emulator-runner@v2',
    'Beobachtete native Spielstarts verbindlich prüfen',
    'Abgeschlossene Android-Prüfbelege zum selben Kandidaten bereitstellen',
}
PHASES = {
    'initialization', 'prepare', 'download', 'verify', 'stage', 'publish', 'publisher-identity',
    'publisher-repository', 'source-gates', 'local-assets', 'release-absence',
    'tag-absence', 'create-tag', 'verify-created-tag', 'create-draft',
    'upload-assets', 'verify-draft', 'publish-draft', 'verify-public-release',
    'anonymous-download', 'complete',
}
FAILURE_REASONS = {
    'workflow_scope', 'permission', 'rate_limit', 'authentication',
    'conflict', 'validation', 'service', 'http_error', 'command_error',
    'transport', 'timeout', 'cli_unavailable',
}
CURRENT_PHASE = 'initialization'


class PublicationOperationError(ValueError):
    """Only allowlisted diagnostics; never retain a response body or command output."""
    def __init__(self, reason, *, http_status=None, exit_code=None):
        require(reason in FAILURE_REASONS, 'Unknown publication failure classification')
        require(http_status is None or type(http_status) is int and 100 <= http_status <= 599,
                'Invalid diagnostic HTTP status')
        require(exit_code is None or type(exit_code) is int and -255 <= exit_code <= 255,
                'Invalid diagnostic command exit code')
        self.reason, self.http_status, self.exit_code = reason, http_status, exit_code
        super().__init__(reason)


def failure_reason(text, http_status=None):
    message = text[:65536].lower()
    if 'workflow' in message and any(term in message for term in ('scope', 'permission', 'refusing')):
        return 'workflow_scope'
    if any(term in message for term in ('rate limit', 'rate-limit', 'secondary rate')):
        return 'rate_limit'
    if http_status == 401 or 'bad credentials' in message or 'authentication failed' in message:
        return 'authentication'
    if http_status == 403 or 'resource not accessible' in message or 'permission denied' in message:
        return 'permission'
    if http_status == 409:
        return 'conflict'
    if http_status == 422:
        return 'validation'
    if http_status is not None and http_status >= 500:
        return 'service'
    return 'http_error' if http_status is not None else 'command_error'


def publication_phase(name):
    global CURRENT_PHASE
    require(name in PHASES, 'Unknown publication phase')
    CURRENT_PHASE = name
    save(ROOT / 'proof/PUBLICATION-PROGRESS.json', {'phase': name})
    print('[LumoPublicationPhase] ' + name, flush=True)


def report_failure(error):
    # Exception messages, request headers, URLs and process output are excluded.
    error_type = type(error).__name__
    allowed_types = {'ValueError', 'KeyError', 'OSError', 'FileNotFoundError',
                     'BadZipFile', 'JSONDecodeError', 'PublicationOperationError'}
    result = {'status': 'FAIL', 'phase': CURRENT_PHASE,
              'exception': error_type if error_type in allowed_types else 'unexpected'}
    if isinstance(error, PublicationOperationError):
        result['reason'] = error.reason
        if error.http_status is not None:
            result['http_status'] = error.http_status
        if error.exit_code is not None:
            result['exit_code'] = error.exit_code
    try:
        save(ROOT / 'proof/PUBLICATION-FAILURE.json', result)
    except OSError:
        result['failure_artifact_written'] = False
    print(json.dumps(result, sort_keys=True), file=sys.stderr)
    return result


def validate_order(order):
    require(isinstance(order, dict), 'Publication order must be an object')
    same(set(order), set(FIXED) | INTEGER_FIELDS | HASH_FIELDS | COMMIT_FIELDS | {'release_tag'},
         'Order fields')
    for key, value in FIXED.items():
        same(order[key], value, 'Order ' + key)
    for key in INTEGER_FIELDS:
        require(type(order[key]) is int and order[key] > 0, 'Invalid integer: ' + key)
    for fields, length in ((HASH_FIELDS, 64), (COMMIT_FIELDS, 40)):
        for key in fields:
            require(isinstance(order[key], str)
                    and re.fullmatch(r'[0-9a-f]{' + str(length) + r'}', order[key]),
                    'Invalid digest: ' + key)
    same(order['release_tag'],
         f'lumo-{order["version_name"]}-{order["version_code"]}-{order["build_run_id"]}',
         'Version and run-bound tag')
    require(len({order[key] for key in JOB_NAMES}) == len(JOB_NAMES),
            'Distinct quality jobs required')
    require(len({order[label + '_artifact_id'] for label in ARTIFACT_PREFIXES})
            == len(ARTIFACT_PREFIXES), 'Distinct artifacts required')
    return order


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


API_OPENER = build_opener(ProxyHandler({}), NoRedirects())


def github_json(path, token, *, absent_ok=False):
    require(bool(token), 'Required GitHub credential unavailable')
    base = 'repos/' + REPOSITORY
    require(path == base or path.startswith(base + '/'),
            'API path outside fixed repository')
    request = Request('https://api.github.com/' + path, headers={
        'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'lumo-2082-reviewed-publisher'})
    try:
        with API_OPENER.open(request, timeout=60) as response:
            data = response.read(8 * 1024 * 1024 + 1)
        require(len(data) <= 8 * 1024 * 1024, 'Oversized API metadata')
        return decode(data)
    except HTTPError as error:
        if absent_ok and error.code == 404:
            return None
        try:
            message = error.read(65536).decode('utf-8', errors='replace')
        except (OSError, AttributeError):
            message = ''
        raise PublicationOperationError(failure_reason(message, error.code),
                                        http_status=error.code) from None
    except (URLError, OSError) as error:
        raise PublicationOperationError('transport') from None


def verify_owner(identity):
    same(identity.get('login'), 'Ullmann27', 'Publisher login')
    same(identity.get('id'), OWNER_ID, 'Repository owner ID')
    same(identity.get('type'), 'User', 'Repository owner type')


def verify_actions_identity(identity):
    # GITHUB_TOKEN is an installation token, not the owner's OAuth/PAT.
    # /user does not authenticate installation tokens. Bind the resulting
    # release/asset actor to GitHub Actions, independently of repository owner.
    same(identity.get('login'), 'github-actions[bot]', 'Actions bot login')
    same(identity.get('id'), 41898282, 'Actions bot ID')
    same(identity.get('type'), 'Bot', 'Actions bot type')


def verify_repository(repository):
    same(repository.get('full_name'), REPOSITORY, 'Repository name')
    same(repository.get('id'), REPOSITORY_ID, 'Repository ID')
    same(repository.get('private'), False, 'Public repository')
    verify_owner(repository.get('owner', {}))


def context():
    expected = {
        'GITHUB_ACTIONS': 'true', 'GITHUB_REPOSITORY': REPOSITORY,
        'GITHUB_REPOSITORY_ID': str(REPOSITORY_ID),
        'GITHUB_REPOSITORY_OWNER': 'Ullmann27', 'GITHUB_REPOSITORY_OWNER_ID': str(OWNER_ID),
        'GITHUB_REF': 'refs/heads/' + PUBLISHER_BRANCH,
        'GITHUB_EVENT_NAME': 'push', 'GITHUB_SERVER_URL': 'https://github.com',
        'GITHUB_API_URL': 'https://api.github.com',
        'GITHUB_WORKFLOW_REF': REPOSITORY + '/' + PUBLISHER_WORKFLOW
                               + '@refs/heads/' + PUBLISHER_BRANCH,
    }
    for key, value in expected.items():
        same(os.environ.get(key), value, 'Publisher context ' + key)
    sha = os.environ.get('GITHUB_SHA', '')
    require(re.fullmatch(r'[0-9a-f]{40}', sha), 'Invalid publisher commit')
    same(os.environ.get('GITHUB_WORKFLOW_SHA'), sha, 'Workflow source commit')
    result = {'repository': REPOSITORY, 'publisher_commit': sha,
              'workflow': PUBLISHER_WORKFLOW, 'branch': PUBLISHER_BRANCH}
    for key, field in (('GITHUB_RUN_ID', 'publisher_run_id'),
                       ('GITHUB_RUN_ATTEMPT', 'publisher_run_attempt')):
        value = os.environ.get(key, '')
        require(re.fullmatch(r'[1-9][0-9]*', value), 'Invalid publisher run context')
        result[field] = int(value)
    return result


def verify_api(order, evidence):
    run_id, source = order['build_run_id'], order['flutter_commit']
    run = evidence['run']
    for key, expected in {
        'id': run_id, 'head_sha': source, 'head_branch': SOURCE_BRANCH, 'event': 'push',
        'path': SOURCE_WORKFLOW,
        'run_attempt': order['build_run_attempt'], 'status': 'completed', 'conclusion': 'success',
    }.items():
        same(run.get(key), expected, 'Source run ' + key)
    for field in ('repository', 'head_repository'):
        verify_repository(run[field])
    listing = evidence['jobs']
    same(listing['total_count'], len(JOB_NAMES), 'Source job count')
    same(len(listing['jobs']), len(JOB_NAMES), 'Complete source job listing')
    for field, name in JOB_NAMES.items():
        jobs = [job for job in listing['jobs'] if job.get('id') == order[field]]
        require(len(jobs) == 1, 'Missing bound quality job')
        job = jobs[0]
        for key, expected in {'run_id': run_id, 'head_sha': source, 'name': name,
                              'status': 'completed', 'conclusion': 'success'}.items():
            same(job.get(key), expected, 'Quality job ' + key)
        required = {'intelligence_job_id': INTELLIGENCE_STEPS,
                    'build_job_id': BUILD_STEPS, 'android_job_id': ANDROID_STEPS}[field]
        for step_name in required:
            found = [step for step in job.get('steps', []) if step.get('name') == step_name]
            require(len(found) == 1 and found[0].get('status') == 'completed'
                    and found[0].get('conclusion') == 'success', 'Missing passed step: ' + step_name)
    same(set(evidence['artifacts']), set(ARTIFACT_PREFIXES), 'Source artifact set')
    for label, prefix in ARTIFACT_PREFIXES.items():
        artifact = evidence['artifacts'][label]
        for key, expected in {
            'id': order[label + '_artifact_id'], 'name': f'{prefix}-{run_id}', 'expired': False,
            'size_in_bytes': order[label + '_artifact_bytes'],
            'digest': 'sha256:' + order[label + '_artifact_sha256'],
        }.items():
            same(artifact.get(key), expected, 'Artifact ' + label + ' ' + key)
        for key, expected in {'id': run_id, 'head_sha': source, 'head_branch': SOURCE_BRANCH,
                              'repository_id': REPOSITORY_ID, 'head_repository_id': REPOSITORY_ID}.items():
            same(artifact['workflow_run'].get(key), expected, 'Artifact owner ' + key)


def observe_api(order, token):
    base = 'repos/' + REPOSITORY
    run = f'{base}/actions/runs/{order["build_run_id"]}'
    evidence = {
        'run': github_json(run, token),
        'jobs': github_json(f'{run}/attempts/{order["build_run_attempt"]}/jobs?per_page=100', token),
        'artifacts': {label: github_json(f'{base}/actions/artifacts/{order[label + "_artifact_id"]}', token)
                      for label in ARTIFACT_PREFIXES},
    }
    verify_api(order, evidence)
    return evidence


def source_document(path, source, token):
    resource = github_json(f'repos/{REPOSITORY}/contents/{path}?ref={source}', token)
    same(resource.get('type'), 'file', 'Source document type')
    same(resource.get('path'), path, 'Source document path')
    same(resource.get('encoding'), 'base64', 'Source document encoding')
    encoded = ''.join(resource['content'].splitlines())
    return base64.b64decode(encoded, validate=True).decode('utf-8')


def prepare(order):
    publisher = context()
    same(os.environ.get('GITHUB_JOB'), 'verify', 'Read-only verification job')
    same(subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
         publisher['publisher_commit'], 'Checked out publisher commit')
    changed = subprocess.check_output(
        ['git', 'diff', '--name-status', 'HEAD^', 'HEAD', '--', str(REQUEST)], text=True).strip()
    same(changed, 'A\t' + str(REQUEST), 'Only a newly added publication order can activate this workflow')
    token = os.environ.get('GH_TOKEN', '')
    evidence = observe_api(order, token)
    source = order['flutter_commit']
    pubspec = source_document('pubspec.yaml', source, token)
    same(re.findall(r'^version:\s*(\S+)\s*$', pubspec, re.MULTILINE),
         [f'{order["version_name"]}+{order["version_code"]}'], 'Source pubspec version')
    godot = decode(source_document('config/godot-source.json', source, token))
    same(godot, {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                 'revision': order['godot_commit'], 'engine': '4.6.3'}, 'Source Godot pin')
    save(ROOT / 'proof/ORIGINAL-RUN-AND-ARTIFACTS.json', evidence)
    save(ROOT / 'proof/PUBLICATION-ORDER.json', order)
    save(ROOT / 'proof/PUBLISHER-CONTEXT.json', publisher)


def download_archive(artifact_id, expected_bytes, expected_sha256, destination, token):
    """Hash the complete Actions ZIP; never forward the API credential to storage."""
    require(type(artifact_id) is int and artifact_id > 0, 'Invalid download artifact ID')
    require(type(expected_bytes) is int and expected_bytes > 0, 'Invalid archive byte count')
    require(re.fullmatch(r'[0-9a-f]{64}', expected_sha256), 'Invalid archive SHA256')
    require(bool(token), 'Artifact read credential unavailable')
    request = Request(
        f'https://api.github.com/repos/{REPOSITORY}/actions/artifacts/{artifact_id}/zip',
        headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
                 'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'lumo-2082-reviewed-publisher'})
    try:
        with API_OPENER.open(request, timeout=60):
            raise ValueError('Expected the GitHub artifact download redirect')
    except HTTPError as error:
        if error.code != 302:
            raise PublicationOperationError(failure_reason('', error.code),
                                            http_status=error.code) from None
        location = error.headers.get('Location', '')
    except (URLError, OSError):
        raise PublicationOperationError('transport') from None
    require_https(location)
    opener = build_opener(ProxyHandler({}), AnonymousRedirect())
    anonymous = Request(location, headers={'User-Agent': 'lumo-2082-artifact-verification',
                                            'Accept-Encoding': 'identity'})
    destination.parent.mkdir(parents=True, exist_ok=True)
    size, sha = 0, hashlib.sha256()
    try:
        with opener.open(anonymous, timeout=60) as response, destination.open('xb') as output:
            same(response.status, 200, 'Artifact storage HTTP status')
            require_https(response.geturl())
            while block := response.read(4 * 1024 * 1024):
                size += len(block)
                require(size <= expected_bytes, 'Artifact archive exceeds approved byte count')
                sha.update(block)
                output.write(block)
    except HTTPError as error:
        raise PublicationOperationError(failure_reason('', error.code),
                                        http_status=error.code) from None
    except (URLError, OSError):
        raise PublicationOperationError('transport') from None
    same(size, expected_bytes, 'Downloaded artifact archive bytes')
    same(sha.hexdigest(), expected_sha256, 'Downloaded artifact archive SHA256')
    return {'artifact_id': artifact_id, 'bytes': size, 'sha256': sha.hexdigest(),
            'storage_authorization_header_sent': False}


def extract_archive(archive_path, destination):
    """Reject aliases, traversal, special files and oversized archives before writing."""
    require(not destination.exists(), 'Artifact extraction must use a new directory')
    with zipfile.ZipFile(archive_path) as archive:
        infos = archive.infolist()
        require(0 < len(infos) <= 20000, 'Invalid archive entry count')
        seen, expanded = set(), 0
        for info in infos:
            name = info.filename
            path = PurePosixPath(name.rstrip('/'))
            require(name and '\\' not in name and '\x00' not in name
                    and not path.is_absolute() and path.parts
                    and all(part not in ('.', '..') for part in path.parts)
                    and str(path) == name.rstrip('/'), 'Unsafe archive member')
            require(str(path) not in seen, 'Duplicate archive member')
            seen.add(str(path))
            kind = stat.S_IFMT(info.external_attr >> 16)
            require(kind in (0, stat.S_IFREG, stat.S_IFDIR)
                    and not (info.flag_bits & 1), 'Special or encrypted archive member')
            require((info.is_dir() and kind != stat.S_IFREG)
                    or (not info.is_dir() and kind != stat.S_IFDIR), 'Archive member type differs')
            expanded += info.file_size
        require(expanded <= 4 * 1024 * 1024 * 1024, 'Oversized expanded archive')
        destination.mkdir(parents=True, exist_ok=False)
        for info in infos:
            target = destination / info.filename
            if info.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(info) as source, target.open('xb') as output:
                    shutil.copyfileobj(source, output, length=4 * 1024 * 1024)


def download(order):
    same(context(), read(ROOT / 'proof/PUBLISHER-CONTEXT.json'), 'Prepared publisher context')
    same(os.environ.get('GITHUB_JOB'), 'verify', 'Artifact download verification job')
    same(read(ROOT / 'proof/PUBLICATION-ORDER.json'), order, 'Prepared publication order')
    observe_api(order, os.environ.get('GH_TOKEN', ''))
    observed = {}
    for label in ARTIFACT_PREFIXES:
        archive = ROOT / 'downloads' / (label + '.zip')
        observed[label] = download_archive(
            order[label + '_artifact_id'], order[label + '_artifact_bytes'],
            order[label + '_artifact_sha256'], archive, os.environ.get('GH_TOKEN', ''))
        extract_archive(archive, ROOT / label)
    save(ROOT / 'proof/DOWNLOADED-ARTIFACTS.json', observed)


def verify_downloads(order):
    observed = read(ROOT / 'proof/DOWNLOADED-ARTIFACTS.json')
    same(set(observed), set(ARTIFACT_PREFIXES), 'Downloaded archive set')
    for label in ARTIFACT_PREFIXES:
        expected = {'artifact_id': order[label + '_artifact_id'],
                    'bytes': order[label + '_artifact_bytes'],
                    'sha256': order[label + '_artifact_sha256'],
                    'storage_authorization_header_sent': False}
        same(observed[label], expected, 'Download observation ' + label)
        archive = ROOT / 'downloads' / (label + '.zip')
        require(archive.is_file() and not archive.is_symlink(), 'Missing original artifact ZIP')
        same(archive.stat().st_size, expected['bytes'], 'Retained archive size')
        same(digest(archive), expected['sha256'], 'Retained archive SHA256')


def stage(order, artifact_id, artifact_sha256, manifest_sha256):
    publisher = context()
    same(os.environ.get('GITHUB_JOB'), 'publish', 'Isolated publisher job')
    require(type(artifact_id) is int and artifact_id > 0, 'Invalid stage artifact ID')
    if artifact_sha256.startswith('sha256:'):
        artifact_sha256 = artifact_sha256[len('sha256:'):]
    require(re.fullmatch(r'[0-9a-f]{64}', artifact_sha256), 'Invalid stage archive SHA256')
    require(re.fullmatch(r'[0-9a-f]{64}', manifest_sha256), 'Invalid stage manifest SHA256')
    token = os.environ.get('GITHUB_TOKEN', '')
    artifact = github_json(f'repos/{REPOSITORY}/actions/artifacts/{artifact_id}', token)
    for key, expected in {
        'id': artifact_id, 'expired': False, 'digest': 'sha256:' + artifact_sha256,
        'name': f'LUMO-2082-REVIEWED-STAGE-{publisher["publisher_run_id"]}-{publisher["publisher_run_attempt"]}',
    }.items():
        same(artifact.get(key), expected, 'Verified stage ' + key)
    owner = artifact['workflow_run']
    for key, expected in {'id': publisher['publisher_run_id'], 'head_sha': publisher['publisher_commit'],
                          'head_branch': PUBLISHER_BRANCH, 'repository_id': REPOSITORY_ID,
                          'head_repository_id': REPOSITORY_ID}.items():
        same(owner.get(key), expected, 'Stage owner ' + key)
    archive = ROOT / 'downloads/stage.zip'
    observed = download_archive(artifact_id, artifact['size_in_bytes'], artifact_sha256, archive, token)
    directory = ROOT / 'stage-download'
    extract_archive(archive, directory)
    same({path.name for path in directory.iterdir()}, {'proof', 'release'}, 'Stage directory set')
    manifest = directory / 'proof/PREPUBLICATION-VERIFICATION.json'
    same(digest(manifest), manifest_sha256, 'Read-only verification output SHA256')
    proof = read(manifest)
    same(proof['status'], 'PASS', 'Read-only verification outcome')
    same(proof['order'], order, 'Read-only verification order')
    same(read(directory / 'proof/PUBLISHER-CONTEXT.json'), publisher, 'Stage publisher context')
    require(not (ROOT / 'release').exists(), 'Refusing to replace a staged release')
    for name in ('PREPUBLICATION-VERIFICATION.json', 'PUBLISHER-CONTEXT.json'):
        target = ROOT / 'proof' / name
        require(not target.exists(), 'Refusing to replace publisher evidence')
        shutil.copyfile(directory / 'proof' / name, target)
    shutil.move(str(directory / 'release'), str(ROOT / 'release'))
    save(ROOT / 'proof/STAGE-ARTIFACT-VERIFICATION.json',
         {'archive': observed, 'manifest_sha256': manifest_sha256, 'publisher': publisher})
    verify_local_assets(order)


def verify_installed_package(order, installed, uid_output):
    """Check the unmodified PackageManager records emitted by the Android tour."""
    require(isinstance(installed, dict), 'Tour installed package must be a PackageManager record')
    same(set(installed), {'userId', 'firstInstallTime', 'versionCode', 'versionName'},
         'Tour installed package fields')
    same(installed['versionCode'], f'{order["version_code"]} minSdk=24 targetSdk=36',
         'Tour installed versionCode and SDKs')
    same(installed['versionName'], order['version_name'], 'Tour installed versionName')
    require(isinstance(installed['firstInstallTime'], str)
            and bool(installed['firstInstallTime'].strip()), 'Tour install time missing')
    match = re.fullmatch(r'package:' + re.escape(PACKAGE) + r'\s+uid:([1-9][0-9]*)\s*', uid_output)
    require(match is not None, 'Tour PackageManager package and UID missing or different')
    same(installed['userId'], match[1], 'Tour installed package UID')


def verify_android(order, split, tour, backup, native, gate, installed_uid):
    # The current producer writes installed_package as dumpsys metadata, not a
    # package-name string. Retain the raw report and bind its UID to the separate
    # unmodified `cmd package list packages -U PACKAGE` capture.
    emulator_hash = split['packages']['x86_64']['sha256']
    same(tour.get('apk_sha256'), emulator_hash, 'Tour emulator APK')
    verify_installed_package(order, tour.get('installed_package'), installed_uid)
    same(tour.get('fatal_crashes'), 0, 'Tour fatal crashes')
    steps = passed_steps(tour, TOUR_STEPS, 'Tour')
    verify_identity(order, steps['apk-identity'], emulator_hash)
    steps = passed_steps(backup, BACKUP_STEPS, 'Backup')
    verify_identity(order, backup.get('identity', {}), emulator_hash)
    same(steps['apk-identity'].get('installed_sha256'), emulator_hash, 'Backup installed APK')
    for key in ('installed', 'installed_after'):
        same(backup.get(key, {}).get('sha256'), emulator_hash, 'Backup ' + key)
    same(native.get('package'), PACKAGE, 'Native diagnostics package')
    same(gate, verify_native_starts(native), 'Original native-start gate')


def verify_files(order, build_tools):
    SOURCE, NATIVE, RUN = order['flutter_commit'], order['godot_commit'], order['build_run_id']
    same(context(), read(ROOT / 'proof/PUBLISHER-CONTEXT.json'), 'Verifier publisher context')
    same(os.environ.get('GITHUB_JOB'), 'verify', 'Read-only verifier job')
    verify_downloads(order)
    verify_api(order, read(ROOT / 'proof/ORIGINAL-RUN-AND-ARTIFACTS.json'))
    same(read(ROOT / 'proof/PUBLICATION-ORDER.json'), order, 'Prepared order')
    metadata, android = ROOT / 'apk/release', ROOT / 'android/tour'
    apk = metadata / APK
    require(apk.is_file() and not apk.is_symlink(), 'APK must be a regular file')
    same(apk.stat().st_size, order['apk_bytes'], 'Actual APK bytes')
    same(digest(apk), order['apk_sha256'], 'Actual APK SHA256')
    same((metadata / 'SHA256SUMS.txt').read_text().split(), [order['apk_sha256'], APK], 'APK sums')
    provenance, verification, split = [read(metadata / name) for name in
                                      ('BUILD-PROVENANCE.json', 'APK-VERIFICATION.json', 'SPLIT-APK-IDENTITY.json')]
    godot = verify_metadata(order, provenance, verification, split)
    for document in (provenance, verification):
        same(document.get('minSdk'), 24, 'Minimum Android SDK')
        same(document.get('targetSdk'), 36, 'Target Android SDK')
    with zipfile.ZipFile(apk) as archive:
        require(len(archive.namelist()) == len(set(archive.namelist())), 'Duplicate APK entry')
        same(decode(archive.read('assets/lumo_game_source.json')), godot, 'Actual packaged Godot source')
        same(archive.getinfo('assets/lumo_game.pck').file_size, order['pck_bytes'], 'Actual PCK bytes')
        with archive.open('assets/lumo_game.pck') as stream:
            same(hashlib.file_digest(stream, 'sha256').hexdigest(), order['pck_sha256'], 'Actual PCK SHA256')
        same({name.split('/')[1] for name in archive.namelist() if name.startswith('lib/') and name.endswith('.so')},
             {'arm64-v8a'}, 'Actual native architectures')
    subprocess.run(['java', '-cp', str(build_tools / 'lib/apksigner.jar'),
                    'scripts/LumoApkCertificateVerifier.java', str(apk.resolve()), CERT],
                   check=True, capture_output=True, text=True)
    badging = subprocess.run([str(build_tools / 'aapt'), 'dump', 'badging', str(apk)],
                             check=True, capture_output=True, text=True).stdout
    match = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    require(match is not None, 'Unreadable actual APK manifest')
    same(list(match.groups()), [PACKAGE, str(order['version_code']), order['version_name']], 'Actual APK package and version')
    same(read(android / 'SPLIT-APK-IDENTITY.json'), split, 'Original Android split identity')
    tour, backup = read(android / 'tour-result.json'), read(android / 'local-backup/backup-result.json')
    for report in (tour, backup):
        rows = report.get('steps', [])
        require(rows and all(row.get('ok') is True for row in rows), 'No failed Android step may be omitted')
        require(len({row['step'] for row in rows}) == len(rows), 'Duplicate Android step')
    verify_android(order, split, tour, backup, read(android / 'native-starts.json'),
                   read(android / 'NATIVE-GAME-STARTS.json'),
                   (android / 'installed-package-uid.txt').read_text())
    archive_matches(ROOT / 'android/LUMO-ANDROID-PRUEFBELEGE.zip', {
        'tour/' + name: android / name for name in ('tour-result.json', 'local-backup/backup-result.json',
            'native-starts.json', 'NATIVE-GAME-STARTS.json', 'SPLIT-APK-IDENTITY.json',
            'installed-package-uid.txt')})
    archive_matches(metadata / 'LUMO-INTEGRATIONSBELEGE.zip', {
        'build-proof/' + name: metadata / name for name in ('APK-VERIFICATION.json', 'SPLIT-APK-IDENTITY.json')})
    release = ROOT / 'release'
    release.mkdir(parents=True, exist_ok=False)
    os.link(apk, release / APK)
    for name in ('SHA256SUMS.txt', 'BUILD-PROVENANCE.json', 'APK-VERIFICATION.json',
                 'SPLIT-APK-IDENTITY.json', 'LUMO-INTEGRATIONSBELEGE.zip'):
        shutil.copyfile(metadata / name, release / name)
    shutil.copyfile(ROOT / 'android/LUMO-ANDROID-PRUEFBELEGE.zip', release / 'LUMO-ANDROID-PRUEFBELEGE.zip')
    intelligence = ROOT / 'intelligence'
    for name in ('FLUTTER-ANALYSIS.txt', 'FLUTTER-FOCUSED-TESTS.txt'):
        path = intelligence / name
        require(path.is_file() and 0 < path.stat().st_size <= 16 * 1024 * 1024,
                'Missing or oversized Intelligence test evidence')
    require('All tests passed!' in (intelligence / 'FLUTTER-FOCUSED-TESTS.txt').read_text(),
            'Intelligence test completion missing')
    shutil.copyfile(ROOT / 'downloads/intelligence.zip', release / 'LUMO-INTELLIGENCE-TESTS.zip')
    for name in ('PUBLICATION-ORDER.json', 'ORIGINAL-RUN-AND-ARTIFACTS.json',
                 'DOWNLOADED-ARTIFACTS.json', 'PUBLISHER-CONTEXT.json'):
        shutil.copyfile(ROOT / 'proof' / name, release / name)
    notes = (f'# Lumo {order["version_name"]}+{order["version_code"]} – Intelligence 2.0 Testversion\n\n'
             'Echte profilgebundene Lernanalysen, individuelle Lernhilfe und Hausaufgabenbelege, '
             'angepasste Wiederholungen sowie Tagesabläufe und Dialoge in der Spielwelt. '
             'Bestehende Sprach-/3D-Nachhilfe und ursprüngliche Figuren bleiben erhalten.\n\n'
             f'Flutter: `{SOURCE}`\n\nGodot: `{NATIVE}`\n\nOriginal-Baulauf: {RUN}\n\n'
             f'APK: {order["apk_bytes"]} Bytes; SHA-256 `{order["apk_sha256"]}`\n\n'
             f'Paket: `{PACKAGE}`\n\nSignatur SHA-256: `{CERT}`\n\n'
             'Die vollständige Flutter-Suite, native Kern-/World-Prüfungen, APK-Signatur und '
             'echte Android-Tour mit sieben nativen Spielstarts und Datensicherungs-Rückspielung '
             'sind bestanden. Die x86_64-Emulator-APK enthält exakt denselben geprüften PCK wie '
             'die ARM64-Datei. Dies ist kein Nachweis von 60 FPS oder eines physischen Fold7-Tests. '
             'Familien-Testsignatur, keine Play-Produktionssignatur. Alle hier veröffentlichten '
             'APK-Bytes stammen unverändert aus dem geprüften Originalartefakt.\n')
    (release / 'LIESMICH.md').write_text(notes)
    assets = {p.name: {'bytes': p.stat().st_size, 'sha256': digest(p)} for p in release.iterdir()}
    manifest = ROOT / 'proof/PREPUBLICATION-VERIFICATION.json'
    save(manifest, {'status': 'PASS', 'order': order, 'assets': assets})
    with Path(os.environ['GITHUB_OUTPUT']).open('a') as output:
        output.write('manifest_sha256=' + digest(manifest) + '\n')


def publisher_cli(token, arguments, payload=None):
    environment = {key: value for key, value in os.environ.items()
                   if not key.startswith('GH_') and not key.lower().endswith('_proxy')
                   and key not in ('GITHUB_TOKEN', 'GITHUB_ENTERPRISE_TOKEN', 'LUMO_RELEASE_PUBLISH_TOKEN',
                                   'LUMO_SOURCE_READ_TOKEN')}
    config = ROOT / 'gh-client'
    config.mkdir(parents=True, exist_ok=True, mode=0o700)
    environment.update({'GH_TOKEN': token, 'GH_HOST': 'github.com', 'GH_PROMPT_DISABLED': '1',
                        'GH_CONFIG_DIR': str(config.resolve()), 'GH_NO_UPDATE_NOTIFIER': '1'})
    try:
        result = subprocess.run(['gh', *arguments], input=json.dumps(payload) if payload is not None else None,
                                text=True, capture_output=True, env=environment, timeout=900)
    except subprocess.TimeoutExpired:
        raise PublicationOperationError('timeout') from None
    except FileNotFoundError:
        raise PublicationOperationError('cli_unavailable') from None
    if result.returncode != 0:
        # Recognize a small set of causes without disclosing any original text.
        message = (result.stderr or '')[:32768] + '\n' + (result.stdout or '')[:32768]
        match = re.search(r'\bHTTP(?:/\S+\s+|\s+)([1-5][0-9]{2})\b', message)
        status = int(match[1]) if match else None
        raise PublicationOperationError(failure_reason(message, status),
                                        http_status=status, exit_code=result.returncode)
    return decode(result.stdout) if payload is not None else None


def verify_release(order, release, ref, assets, draft):
    tag, source = order['release_tag'], order['flutter_commit']
    same(ref['ref'], 'refs/tags/' + tag, 'Published tag')
    same(ref['object']['type'], 'commit', 'Lightweight tag')
    same(ref['object']['sha'], source, 'Tag source')
    same(release['tag_name'], tag, 'Release tag')
    same(release['target_commitish'], source, 'Release source')
    same(release['draft'], draft, 'Release draft state')
    same(release['prerelease'], True, 'Test release classification')
    require(type(release.get('id')) is int and release['id'] > 0, 'Release ID')
    verify_actions_identity(release['author'])
    same({asset['name'] for asset in release['assets']}, set(assets), 'Release asset set')
    same(len(release['assets']), len(assets), 'Unique release assets')
    if not draft:
        same(release['html_url'], f'https://github.com/{REPOSITORY}/releases/tag/{tag}', 'Release URL')
    for asset in release['assets']:
        expected = assets[asset['name']]
        require(type(asset.get('id')) is int and asset['id'] > 0, 'Asset ID')
        verify_actions_identity(asset['uploader'])
        same(asset['state'], 'uploaded', 'Asset upload state')
        same(asset['size'], expected['bytes'], 'Asset byte count')
        same(asset.get('digest'), 'sha256:' + expected['sha256'], 'Asset server SHA256')
        if not draft:
            same(asset['browser_download_url'],
                 f'https://github.com/{REPOSITORY}/releases/download/{tag}/{asset["name"]}', 'Public asset URL')
    return next(asset for asset in release['assets'] if asset['name'] == APK)


def verify_local_assets(order):
    proof = read(ROOT / 'proof/PREPUBLICATION-VERIFICATION.json')
    same(proof['status'], 'PASS', 'Prepublication gate')
    same(proof['order'], order, 'Verified order')
    assets = proof['assets']
    require(isinstance(assets, dict) and assets, 'Missing approved assets')
    require(all(isinstance(name, str) and re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*', name)
                for name in assets), 'Unsafe asset name')
    release_dir = ROOT / 'release'
    same({p.name for p in release_dir.iterdir()}, set(assets), 'Unchanged local asset set')
    same(assets[APK], {'bytes': order['apk_bytes'], 'sha256': order['apk_sha256']}, 'Approved APK')
    for name, expected in assets.items():
        path = release_dir / name
        require(path.is_file() and not path.is_symlink(), 'Nonregular release asset')
        same({'bytes': path.stat().st_size, 'sha256': digest(path)}, expected, 'Unchanged asset ' + name)
    return assets


def publish(order):
    token = os.environ.get('GITHUB_TOKEN', '')
    require(bool(token), 'Workflow GITHUB_TOKEN unavailable; no alternate credential')
    SOURCE, NATIVE, RUN = order['flutter_commit'], order['godot_commit'], order['build_run_id']
    TAG = order['release_tag']
    publication_phase('publisher-identity')
    publisher = context()
    same(os.environ.get('GITHUB_JOB'), 'publish', 'Isolated publisher job')
    same(read(ROOT / 'proof/PUBLISHER-CONTEXT.json'), publisher, 'Verified publisher context')
    stage_proof = read(ROOT / 'proof/STAGE-ARTIFACT-VERIFICATION.json')
    same(stage_proof['publisher'], publisher, 'Stage verification publisher')
    same(stage_proof['manifest_sha256'], digest(ROOT / 'proof/PREPUBLICATION-VERIFICATION.json'),
         'Unchanged staged verification')
    base = 'repos/' + REPOSITORY
    publication_phase('publisher-repository')
    verify_repository(github_json(base, token))
    current = github_json(f'{base}/actions/runs/{publisher["publisher_run_id"]}', token)
    for key, expected in {'id': publisher['publisher_run_id'],
                          'run_attempt': publisher['publisher_run_attempt'],
                          'head_sha': publisher['publisher_commit'], 'head_branch': PUBLISHER_BRANCH,
                          'event': 'push', 'path': PUBLISHER_WORKFLOW, 'status': 'in_progress'}.items():
        same(current.get(key), expected, 'Current publisher run ' + key)
    for field in ('repository', 'head_repository'):
        verify_repository(current[field])
    # Re-observe source gates immediately before the first external mutation.
    publication_phase('source-gates')
    observe_api(order, token)
    publication_phase('local-assets')
    assets = verify_local_assets(order)
    release_dir = ROOT / 'release'
    for endpoint in ('releases/tags/' + TAG, 'git/ref/tags/' + TAG):
        publication_phase('release-absence' if endpoint.startswith('releases/') else 'tag-absence')
        require(github_json(base + '/' + endpoint, token, absent_ok=True) is None,
                'Tag or release already exists; no overwrite')
    publication_phase('create-tag')
    publisher_cli(token, ['api', '--method', 'POST', base + '/git/refs', '--input', '-'],
                  {'ref': 'refs/tags/' + TAG, 'sha': SOURCE})
    publication_phase('verify-created-tag')
    ref = github_json(base + '/git/ref/tags/' + TAG, token)
    same(ref['ref'], 'refs/tags/' + TAG, 'New tag name')
    same(ref['object']['type'], 'commit', 'New lightweight tag')
    same(ref['object']['sha'], SOURCE, 'New tag source')
    save(ROOT / 'proof/CREATED-TAG.json', ref)
    publication_phase('create-draft')
    created = publisher_cli(token, ['api', '--method', 'POST', base + '/releases', '--input', '-'], {
        'tag_name': TAG, 'target_commitish': SOURCE, 'name': f'Lumo {order["version_name"]}+{order["version_code"]} – signierte Android-Testversion',
        'body': (release_dir / 'LIESMICH.md').read_text(), 'draft': True,
        'prerelease': True, 'make_latest': 'false',
    })
    require(type(created['id']) is int and created['id'] > 0, 'Created release ID')
    same(created['draft'], True, 'Upload into new draft')
    same(created.get('tag_name'), TAG, 'Created draft tag')
    same(created.get('target_commitish'), SOURCE, 'Created draft source')
    same(created.get('prerelease'), True, 'Created draft test classification')
    same(created.get('assets'), [], 'New draft must start without assets')
    verify_actions_identity(created['author'])
    save(ROOT / 'proof/CREATED-RELEASE.json', created)
    publication_phase('upload-assets')
    publisher_cli(token, ['release', 'upload', TAG, '--repo', REPOSITORY,
                          *[str(release_dir / name) for name in sorted(assets)]])
    publication_phase('verify-draft')
    release = github_json(base + '/releases/' + str(created['id']), token)
    ref = github_json(base + '/git/ref/tags/' + TAG, token)
    same(release.get('id'), created['id'], 'Observed draft ID')
    verify_release(order, release, ref, assets, draft=True)
    publication_phase('publish-draft')
    publisher_cli(token, ['api', '--method', 'PATCH', base + '/releases/' + str(created['id']), '--input', '-'],
                  {'draft': False, 'prerelease': True, 'make_latest': 'false'})
    publication_phase('verify-public-release')
    release = github_json(base + '/releases/' + str(created['id']), token)
    ref = github_json(base + '/git/ref/tags/' + TAG, token)
    same(release.get('id'), created['id'], 'Observed published release ID')
    asset = verify_release(order, release, ref, assets, draft=False)
    save(ROOT / 'proof/PUBLISHED-RELEASE.json', release)
    save(ROOT / 'proof/PUBLISHED-TAG.json', ref)
    publication_phase('anonymous-download')
    observation = download_public({'url': asset['browser_download_url'],
                                   'bytes': order['apk_bytes'], 'sha256': order['apk_sha256']})
    result = {'status': 'PASS', 'source': SOURCE, 'native': NATIVE, 'source_run': RUN,
              'release_id': release['id'], 'asset_id': asset['id'],
              'release_url': release['html_url'], 'download': observation,
              'server_immutable_observed': release.get('immutable'),
              'publication_policy': 'new-tag-new-release-no-overwrite',
              'publisher': publisher}
    save(ROOT / 'proof/PUBLIC-DOWNLOAD-VERIFICATION.json', result)
    publication_phase('complete')
    print(json.dumps(result, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('prepare', 'download', 'verify', 'stage', 'publish'))
    parser.add_argument('--build-tools', type=Path)
    parser.add_argument('--stage-artifact-id', type=int)
    parser.add_argument('--stage-artifact-sha256')
    parser.add_argument('--manifest-sha256')
    args = parser.parse_args()
    publication_phase(args.mode)
    order = validate_order(read(REQUEST))
    if args.mode == 'prepare':
        prepare(order)
    elif args.mode == 'download':
        download(order)
    elif args.mode == 'verify':
        require(args.build_tools is not None, '--build-tools required')
        verify_files(order, args.build_tools)
    elif args.mode == 'stage':
        require(args.stage_artifact_id is not None and args.stage_artifact_sha256 is not None
                and args.manifest_sha256 is not None, 'Bound stage identity required')
        stage(order, args.stage_artifact_id, args.stage_artifact_sha256, args.manifest_sha256)
    else:
        publish(order)


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        report_failure(error)
        raise SystemExit(1) from None
