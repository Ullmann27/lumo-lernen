#!/usr/bin/env python3
"""Publish the exact accepted 2081 ARM64 artifact; never rebuild or re-sign it."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener
import zipfile

from lumo_team_b_reviewed_publish import (
    archive_matches, decode, digest, read, require, same, save,
    verify_android, verify_metadata,
)

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools/nextgen'))
from public_learning_download import download_public

REPOSITORY = 'Ullmann27/lumo-lernen'
OWNER_ID = 64243701
PUBLISHER_BRANCH = 'support/lumo-2081-reviewed-publish'
SOURCE_BRANCH = 'lumo-abschluss/integration-20261124'
SOURCE = '5c086af2fa967f743d5801b4be23c15efbbb88ba'
NATIVE = 'c814e35249e4038f903d1fca3e19bb4751040a43'
RUN = 45433091440
TAG = f'lumo-0.14.8-2081-{RUN}'
APK = 'Lumo-Lernen-Test-0.14.8-2081.apk'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
ROOT = Path('reviewed-2081')
REQUEST = Path('config/lumo-2081-reviewed-publish.json')
FIXED = {
    'schema': 1, 'repository': REPOSITORY, 'branch': SOURCE_BRANCH,
    'build_run_id': RUN, 'flutter_commit': SOURCE, 'godot_commit': NATIVE,
    'version_name': '0.14.8', 'version_code': 2081,
    'apk_file': APK, 'certificate_sha256': CERT, 'release_tag': TAG,
    'publisher_login': 'Ullmann27', 'publisher_user_id': OWNER_ID,
}
INTEGER_FIELDS = {
    'build_run_attempt', 'build_job_id', 'android_job_id',
    'apk_artifact_id', 'android_artifact_id', 'apk_bytes', 'pck_bytes',
    'apk_artifact_bytes', 'android_artifact_bytes',
}
HASH_FIELDS = {'apk_sha256', 'pck_sha256', 'apk_artifact_sha256', 'android_artifact_sha256'}
JOB_NAMES = {
    'build_job_id': 'Signierte Test-APK bauen',
    'android_job_id': 'Installierte APK im Android-Emulator prüfen',
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


def validate_order(order):
    same(set(order), set(FIXED) | INTEGER_FIELDS | HASH_FIELDS, 'Order fields')
    for key, value in FIXED.items():
        same(order[key], value, 'Order ' + key)
    for key in INTEGER_FIELDS:
        require(type(order[key]) is int and order[key] > 0, 'Invalid integer: ' + key)
    for key in HASH_FIELDS:
        require(isinstance(order[key], str) and re.fullmatch(r'[0-9a-f]{64}', order[key]),
                'Invalid SHA256: ' + key)
    require(order['build_job_id'] != order['android_job_id'], 'Distinct quality jobs required')
    require(order['apk_artifact_id'] != order['android_artifact_id'], 'Distinct artifacts required')
    return order


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


API_OPENER = build_opener(ProxyHandler({}), NoRedirects())


def github_json(path, token, *, absent_ok=False):
    require(bool(token), 'Required GitHub credential unavailable')
    base = 'repos/' + REPOSITORY
    require(path == 'user' or path == base or path.startswith(base + '/'),
            'API path outside fixed repository')
    request = Request('https://api.github.com/' + path, headers={
        'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'lumo-2081-reviewed-publisher'})
    try:
        with API_OPENER.open(request, timeout=60) as response:
            data = response.read(8 * 1024 * 1024 + 1)
        require(len(data) <= 8 * 1024 * 1024, 'Oversized API metadata')
        return decode(data)
    except HTTPError as error:
        if absent_ok and error.code == 404:
            return None
        raise ValueError('GitHub GET failed: HTTP ' + str(error.code)) from None
    except (URLError, OSError) as error:
        raise ValueError('GitHub GET failed: ' + type(error).__name__) from None


def verify_owner(identity):
    same(identity.get('login'), 'Ullmann27', 'Publisher login')
    same(identity.get('id'), OWNER_ID, 'Publisher user ID')


def verify_api(order, evidence):
    run = evidence['run']
    for key, expected in {
        'id': RUN, 'head_sha': SOURCE, 'head_branch': SOURCE_BRANCH, 'event': 'push',
        'path': '.github/workflows/lumo-abschluss-apk.yml',
        'run_attempt': order['build_run_attempt'], 'status': 'completed', 'conclusion': 'success',
    }.items():
        same(run.get(key), expected, 'Source run ' + key)
    for field in ('repository', 'head_repository'):
        same(run[field]['full_name'], REPOSITORY, 'Source repository')
        same(run[field]['id'], 1222433959, 'Source repository ID')
    same(run['repository']['private'], False, 'Public repository')
    listing = evidence['jobs']
    same(listing['total_count'], 2, 'Source job count')
    same(len(listing['jobs']), 2, 'Complete source job listing')
    for field, name in JOB_NAMES.items():
        jobs = [job for job in listing['jobs'] if job.get('id') == order[field]]
        require(len(jobs) == 1, 'Missing bound quality job')
        job = jobs[0]
        for key, expected in {'run_id': RUN, 'head_sha': SOURCE, 'name': name,
                              'status': 'completed', 'conclusion': 'success'}.items():
            same(job.get(key), expected, 'Quality job ' + key)
        required = BUILD_STEPS if field == 'build_job_id' else ANDROID_STEPS
        for step_name in required:
            found = [step for step in job.get('steps', []) if step.get('name') == step_name]
            require(len(found) == 1 and found[0].get('status') == 'completed'
                    and found[0].get('conclusion') == 'success', 'Missing passed step: ' + step_name)
    for label, prefix in (('apk', 'LUMO-TEST-APK'), ('android', 'LUMO-ANDROID-TOUR')):
        artifact = evidence['artifacts'][label]
        for key, expected in {
            'id': order[label + '_artifact_id'], 'name': f'{prefix}-{RUN}', 'expired': False,
            'size_in_bytes': order[label + '_artifact_bytes'],
            'digest': 'sha256:' + order[label + '_artifact_sha256'],
        }.items():
            same(artifact.get(key), expected, 'Artifact ' + label + ' ' + key)
        for key, expected in {'id': RUN, 'head_sha': SOURCE, 'head_branch': SOURCE_BRANCH,
                              'repository_id': 1222433959, 'head_repository_id': 1222433959}.items():
            same(artifact['workflow_run'].get(key), expected, 'Artifact owner ' + key)


def observe_api(order, token):
    base = 'repos/' + REPOSITORY
    run = f'{base}/actions/runs/{RUN}'
    evidence = {
        'run': github_json(run, token),
        'jobs': github_json(f'{run}/attempts/{order["build_run_attempt"]}/jobs?per_page=100', token),
        'artifacts': {label: github_json(f'{base}/actions/artifacts/{order[label + "_artifact_id"]}', token)
                      for label in ('apk', 'android')},
    }
    verify_api(order, evidence)
    return evidence


def prepare(order):
    same(os.environ.get('GITHUB_REPOSITORY'), REPOSITORY, 'Publisher repository')
    same(os.environ.get('GITHUB_REF'), 'refs/heads/' + PUBLISHER_BRANCH, 'Publisher branch')
    changed = subprocess.check_output(
        ['git', 'diff', '--name-status', 'HEAD^', 'HEAD', '--', str(REQUEST)], text=True).strip()
    same(changed, 'A\t' + str(REQUEST), 'Only a newly added publication order can activate this workflow')
    evidence = observe_api(order, os.environ.get('GH_TOKEN', ''))
    save(ROOT / 'proof/ORIGINAL-RUN-AND-ARTIFACTS.json', evidence)
    save(ROOT / 'proof/PUBLICATION-ORDER.json', order)
    with Path(os.environ['GITHUB_OUTPUT']).open('a') as output:
        for field in ('build_run_id', 'apk_artifact_id', 'android_artifact_id'):
            output.write(f'{field}={order[field]}\n')


def verify_files(order, build_tools):
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
    same(list(match.groups()), [PACKAGE, '2081', '0.14.8'], 'Actual APK package and version')
    same(read(android / 'SPLIT-APK-IDENTITY.json'), split, 'Original Android split identity')
    tour, backup = read(android / 'tour-result.json'), read(android / 'local-backup/backup-result.json')
    for report in (tour, backup):
        rows = report.get('steps', [])
        require(rows and all(row.get('ok') is True for row in rows), 'No failed Android step may be omitted')
        require(len({row['step'] for row in rows}) == len(rows), 'Duplicate Android step')
    verify_android(order, split, tour, backup, read(android / 'native-starts.json'),
                   read(android / 'NATIVE-GAME-STARTS.json'))
    archive_matches(ROOT / 'android/LUMO-ANDROID-PRUEFBELEGE.zip', {
        'tour/' + name: android / name for name in ('tour-result.json', 'local-backup/backup-result.json',
            'native-starts.json', 'NATIVE-GAME-STARTS.json', 'SPLIT-APK-IDENTITY.json')})
    archive_matches(metadata / 'LUMO-INTEGRATIONSBELEGE.zip', {
        'build-proof/' + name: metadata / name for name in ('APK-VERIFICATION.json', 'SPLIT-APK-IDENTITY.json')})
    release = ROOT / 'release'
    release.mkdir(parents=True, exist_ok=False)
    os.link(apk, release / APK)
    for name in ('SHA256SUMS.txt', 'BUILD-PROVENANCE.json', 'APK-VERIFICATION.json',
                 'SPLIT-APK-IDENTITY.json', 'LUMO-INTEGRATIONSBELEGE.zip'):
        shutil.copyfile(metadata / name, release / name)
    shutil.copyfile(ROOT / 'android/LUMO-ANDROID-PRUEFBELEGE.zip', release / 'LUMO-ANDROID-PRUEFBELEGE.zip')
    for name in ('PUBLICATION-ORDER.json', 'ORIGINAL-RUN-AND-ARTIFACTS.json'):
        shutil.copyfile(ROOT / 'proof' / name, release / name)
    notes = (f'# Lumo 0.14.8+2081 – integrierte Android-Testversion\n\n'
             'Adaptive Nachhilfe und Zehnerwerkstatt, World-Orte/Originalfiguren/Missionen/Karten, '
             'Kart-Führung und Bodenkontakt, Schach-Startschutz und bedienbare Intro-Prüfung. '
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
    save(ROOT / 'proof/PREPUBLICATION-VERIFICATION.json', {'status': 'PASS', 'order': order, 'assets': assets})


def publisher_cli(token, arguments, payload=None):
    environment = {key: value for key, value in os.environ.items()
                   if not key.startswith('GH_') and not key.lower().endswith('_proxy')
                   and key not in ('GITHUB_TOKEN', 'GITHUB_ENTERPRISE_TOKEN', 'LUMO_RELEASE_PUBLISH_TOKEN',
                                   'LUMO_SOURCE_READ_TOKEN')}
    config = ROOT / 'gh-client'
    config.mkdir(parents=True, exist_ok=True, mode=0o700)
    environment.update({'GH_TOKEN': token, 'GH_HOST': 'github.com', 'GH_PROMPT_DISABLED': '1',
                        'GH_CONFIG_DIR': str(config.resolve()), 'GH_NO_UPDATE_NOTIFIER': '1'})
    result = subprocess.run(['gh', *arguments], input=json.dumps(payload) if payload is not None else None,
                            text=True, capture_output=True, env=environment, timeout=900)
    require(result.returncode == 0, 'Publisher command failed; no retry or alternate credential')
    return decode(result.stdout) if payload is not None else None


def verify_release(release, ref, assets, draft):
    same(ref['ref'], 'refs/tags/' + TAG, 'Published tag')
    same(ref['object']['type'], 'commit', 'Lightweight tag')
    same(ref['object']['sha'], SOURCE, 'Tag source')
    same(release['tag_name'], TAG, 'Release tag')
    same(release['draft'], draft, 'Release draft state')
    same(release['prerelease'], True, 'Test release classification')
    verify_owner(release['author'])
    same({asset['name'] for asset in release['assets']}, set(assets), 'Release asset set')
    same(len(release['assets']), len(assets), 'Unique release assets')
    if not draft:
        same(release['html_url'], f'https://github.com/{REPOSITORY}/releases/tag/{TAG}', 'Release URL')
    for asset in release['assets']:
        expected = assets[asset['name']]
        verify_owner(asset['uploader'])
        same(asset['state'], 'uploaded', 'Asset upload state')
        same(asset['size'], expected['bytes'], 'Asset byte count')
        same(asset.get('digest'), 'sha256:' + expected['sha256'], 'Asset server SHA256')
        if not draft:
            same(asset['browser_download_url'],
                 f'https://github.com/{REPOSITORY}/releases/download/{TAG}/{asset["name"]}', 'Public asset URL')
    return next(asset for asset in release['assets'] if asset['name'] == APK)


def publish(order):
    token = os.environ.get('LUMO_RELEASE_PUBLISH_TOKEN', '')
    require(bool(token), 'Publisher credential unavailable; no GITHUB_TOKEN fallback')
    verify_owner(github_json('user', token))
    base = 'repos/' + REPOSITORY
    repo = github_json(base, token)
    same(repo['full_name'], REPOSITORY, 'Publisher repository')
    same(repo['private'], False, 'Public publication repository')
    verify_owner(repo['owner'])
    # Re-observe source gates immediately before the first external mutation.
    observe_api(order, os.environ.get('LUMO_SOURCE_READ_TOKEN', ''))
    proof = read(ROOT / 'proof/PREPUBLICATION-VERIFICATION.json')
    same(proof['status'], 'PASS', 'Prepublication gate')
    same(proof['order'], order, 'Verified order')
    assets = proof['assets']
    release_dir = ROOT / 'release'
    same({p.name for p in release_dir.iterdir()}, set(assets), 'Unchanged local asset set')
    same(assets[APK], {'bytes': order['apk_bytes'], 'sha256': order['apk_sha256']}, 'Approved APK')
    for name, expected in assets.items():
        path = release_dir / name
        require(path.is_file() and not path.is_symlink(), 'Nonregular release asset')
        same({'bytes': path.stat().st_size, 'sha256': digest(path)}, expected, 'Unchanged asset ' + name)
    for endpoint in ('releases/tags/' + TAG, 'git/ref/tags/' + TAG):
        require(github_json(base + '/' + endpoint, token, absent_ok=True) is None,
                'Tag or release already exists; no overwrite')
    publisher_cli(token, ['api', '--method', 'POST', base + '/git/refs', '--input', '-'],
                  {'ref': 'refs/tags/' + TAG, 'sha': SOURCE})
    ref = github_json(base + '/git/ref/tags/' + TAG, token)
    same(ref['object']['sha'], SOURCE, 'New tag source')
    created = publisher_cli(token, ['api', '--method', 'POST', base + '/releases', '--input', '-'], {
        'tag_name': TAG, 'target_commitish': SOURCE, 'name': 'Lumo 0.14.8+2081 – signierte Android-Testversion',
        'body': (release_dir / 'LIESMICH.md').read_text(), 'draft': True,
        'prerelease': True, 'make_latest': 'false',
    })
    require(type(created['id']) is int and created['id'] > 0, 'Created release ID')
    same(created['draft'], True, 'Upload into new draft')
    verify_owner(created['author'])
    save(ROOT / 'proof/CREATED-RELEASE.json', created)
    publisher_cli(token, ['release', 'upload', TAG, '--repo', REPOSITORY,
                          *[str(release_dir / name) for name in sorted(assets)]])
    release = github_json(base + '/releases/' + str(created['id']), token)
    ref = github_json(base + '/git/ref/tags/' + TAG, token)
    verify_release(release, ref, assets, draft=True)
    publisher_cli(token, ['api', '--method', 'PATCH', base + '/releases/' + str(created['id']), '--input', '-'],
                  {'draft': False, 'prerelease': True, 'make_latest': 'false'})
    release = github_json(base + '/releases/' + str(created['id']), token)
    ref = github_json(base + '/git/ref/tags/' + TAG, token)
    asset = verify_release(release, ref, assets, draft=False)
    save(ROOT / 'proof/PUBLISHED-RELEASE.json', release)
    save(ROOT / 'proof/PUBLISHED-TAG.json', ref)
    observation = download_public({'url': asset['browser_download_url'],
                                   'bytes': order['apk_bytes'], 'sha256': order['apk_sha256']})
    result = {'status': 'PASS', 'source': SOURCE, 'native': NATIVE, 'source_run': RUN,
              'release_id': release['id'], 'asset_id': asset['id'],
              'release_url': release['html_url'], 'download': observation,
              'server_immutable_observed': release.get('immutable')}
    save(ROOT / 'proof/PUBLIC-DOWNLOAD-VERIFICATION.json', result)
    print(json.dumps(result, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('prepare', 'verify', 'publish'))
    parser.add_argument('--build-tools', type=Path)
    args = parser.parse_args()
    order = validate_order(read(REQUEST))
    if args.mode == 'prepare':
        prepare(order)
    elif args.mode == 'verify':
        require(args.build_tools is not None, '--build-tools required')
        verify_files(order, args.build_tools)
    else:
        publish(order)


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Never print response bodies, subprocess output, secrets or CDN URLs.
        print('2081 publication stopped: ' + type(error).__name__, file=sys.stderr)
        raise SystemExit(1) from None
