#!/usr/bin/env python3
"""Publish only the reviewed, unchanged 2070 candidate; never build or sign."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.error import HTTPError
from urllib.parse import quote, urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener, urlopen
import zipfile

from verify_native_start_diagnostics import verify as verify_native_starts


REQUEST = Path('config/lumo-world-reviewed-publish.json')
ROOT = Path('reviewed')
EXPECTED = {
    'schema': 1, 'repository': 'Ullmann27/lumo-lernen',
    'branch': 'feature/logic-world-20261123', 'build_run_id': 45186225313,
    'flutter_commit': '11c0711f23f887796a7281ddfc6ee7a2aa56ac67',
    'godot_commit': '90648b0639391c88d3c2da0e3f235d30f725256d',
    'apk_artifact_id': 14826480557, 'metadata_artifact_id': 14826031651,
    'apk_file': 'Lumo-Lernen-Test-0.14.1-2070.apk', 'apk_bytes': 537159895,
    'apk_sha256': '8dca425b869b91b18956ecd848ed993ffbd5e21d114fe489b83f78fea6aff6ff',
    'certificate_sha256': 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702',
    'pck_sha256': '9a91ed2b428e086fd0d2c813fc9f55aaac5e65aa75944736a94af55673416fd6',
    'pck_bytes': 279880864, 'version_name': '0.14.1', 'version_code': 2070,
    'release_tag': 'lumo-test-0.14.1-2070-reviewed-45186225313',
}
VARIABLE = {'build_run_attempt', 'build_job_id', 'android_job_id',
            'android_artifact_id', 'publisher_login', 'publisher_user_id'}
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
WORKFLOW = '.github/workflows/lumo-logic-world-apk.yml'
JOB_NAMES = {'build_job_id': 'Signierte Test-APK bauen',
             'android_job_id': 'Installierte APK im Android-Emulator prüfen'}
BACKUP_STEPS = {'apk-identity', 'fictional-profile', 'saf-export', 'export-archive',
                'changed-setting', 'saf-review', 'process-closed', 'restore-and-preservation'}
TOUR_STEPS = {'apk-identity', 'launch', 'onboarding', 'navigate-start', 'navigate-lernen',
              'atelier-roundtrip', 'navigate-spiele', 'open-kart', 'start-kart-race',
              'race-running', 'race-hud', 'race-drive', 'pause-menu', 'return-from-kart',
              'learning-state-after-kart', 'lernen-usable-after-kart', 'profile-after-kart',
              'restart-keeps-learning-state', 'showroom-after-race', 'skypost-roundtrip'}
IDENTITY_CHECKS = {'sha256_matches_provenance', 'sha256_matches_build_sums',
                   'flutter_source_is_this_commit', 'tracked_source_clean',
                   'godot_revision_is_pinned', 'signing_certificate',
                   'version_matches_pubspec', 'x86_64_native_code'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def same(actual, expected, label):
    require(type(actual) is type(expected) and actual == expected, label + ' differs')


def decode(raw):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate JSON field: ' + key)
            result[key] = value
        return result
    return json.loads(raw, object_pairs_hook=unique,
                      parse_constant=lambda value: require(False, 'Non-finite JSON: ' + value))


def read(path):
    require(path.is_file() and path.stat().st_size <= 8 * 1024 * 1024,
            'Missing or oversized JSON: ' + str(path))
    return decode(path.read_bytes())


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def validate_request(request):
    require(isinstance(request, dict) and set(request) == set(EXPECTED) | VARIABLE,
            'Publication order has missing or unknown fields')
    for key, expected in EXPECTED.items():
        same(request[key], expected, 'Order ' + key)
    for key in VARIABLE - {'publisher_login'}:
        require(type(request[key]) is int and request[key] > 0, 'Invalid order ' + key)
    login = request['publisher_login']
    require(isinstance(login, str) and re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]{0,38}', login),
            'An explicitly approved GitHub user login is required')
    require(len({request[k] for k in ('apk_artifact_id', 'metadata_artifact_id',
                                     'android_artifact_id')}) == 3, 'Artifact IDs must differ')
    require(request['build_job_id'] != request['android_job_id'], 'Job IDs must differ')
    return request


def github_json(path, token, *, absent_ok=False):
    require(bool(token), 'Required authenticated identity is unavailable')
    request = Request('https://api.github.com/' + path, headers={
        'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'lumo-reviewed-publisher'})
    try:
        with urlopen(request, timeout=60) as response:
            return decode(response.read(8 * 1024 * 1024))
    except HTTPError as error:
        if absent_ok and error.code == 404:
            return None
        raise ValueError(f'GitHub GET {path}: HTTP {error.code}; no alternate credential or endpoint') from None


def verify_api(request, evidence):
    run = evidence['run']
    for key, expected in {'id': request['build_run_id'], 'head_sha': request['flutter_commit'],
                          'head_branch': request['branch'], 'event': 'push',
                          'path': WORKFLOW, 'run_attempt': request['build_run_attempt'],
                          'status': 'completed'}.items():
        same(run.get(key), expected, 'Original run ' + key)
    for key in ('repository', 'head_repository'):
        same(run[key]['full_name'], request['repository'], 'Original run ' + key)
    same(run['repository'].get('private'), False, 'Public download repository')
    jobs = evidence['jobs']
    same(jobs['total_count'], len(jobs['jobs']), 'Complete job list')
    for field, name in JOB_NAMES.items():
        matches = [job for job in jobs['jobs'] if job.get('id') == request[field]]
        require(len(matches) == 1, 'Missing bound job: ' + field)
        for key, expected in {'run_id': request['build_run_id'], 'head_sha': request['flutter_commit'],
                              'name': name, 'status': 'completed', 'conclusion': 'success'}.items():
            same(matches[0].get(key), expected, field + ' ' + key)
    for field, prefix in [('apk_artifact_id', 'LUMO-WORLD-APK'),
                          ('metadata_artifact_id', 'LUMO-WORLD-METADATA'),
                          ('android_artifact_id', 'LUMO-ANDROID-TOUR')]:
        artifact = evidence['artifacts'][field]
        same(artifact['id'], request[field], field)
        same(artifact['expired'], False, field + ' expired')
        same(artifact['name'], f'{prefix}-{request["build_run_id"]}', field + ' name')
        owner = artifact['workflow_run']
        for key, expected in {'id': request['build_run_id'], 'head_sha': request['flutter_commit'],
                              'head_branch': request['branch'], 'repository_id': run['repository']['id'],
                              'head_repository_id': run['repository']['id']}.items():
            same(owner.get(key), expected, field + ' owner ' + key)


def prepare(request):
    same(os.environ.get('GITHUB_REPOSITORY'), request['repository'], 'Publisher repository')
    same(os.environ.get('GITHUB_REF'), 'refs/heads/' + request['branch'], 'Publisher branch')
    token = os.environ.get('GH_TOKEN', '')  # Read-only Actions token, never a publisher fallback.
    base = 'repos/' + request['repository']
    run = f'{base}/actions/runs/{request["build_run_id"]}'
    evidence = {'run': github_json(run, token),
                'jobs': github_json(f'{run}/attempts/{request["build_run_attempt"]}/jobs?per_page=100', token),
                'artifacts': {field: github_json(f'{base}/actions/artifacts/{request[field]}', token)
                              for field in ('apk_artifact_id', 'metadata_artifact_id', 'android_artifact_id')}}
    verify_api(request, evidence)
    save(ROOT / 'proof/ORIGINAL-RUN-AND-ARTIFACTS.json', evidence)
    save(ROOT / 'proof/PUBLICATION-ORDER.json', request)
    with Path(os.environ['GITHUB_OUTPUT']).open('a') as output:
        for field in ('build_run_id', 'apk_artifact_id', 'metadata_artifact_id', 'android_artifact_id'):
            output.write(f'{field}={request[field]}\n')


def verify_identity(request, identity, emulator_hash):
    for key, expected in {'apk_sha256': emulator_hash, 'flutter_source_commit': request['flutter_commit'],
                          'godot_revision': request['godot_commit'], 'godot_pck_sha256': request['pck_sha256'],
                          'versionName': request['version_name'], 'versionCode': request['version_code'],
                          'signingCertificateSha256': request['certificate_sha256']}.items():
        same(identity.get(key), expected, 'Android identity ' + key)
    checks = identity.get('checks', {})
    require(IDENTITY_CHECKS <= checks.keys() and all(value is True for value in checks.values()),
            'Android identity checks are incomplete or failed')


def passed_steps(report, required, label):
    same(report.get('status'), 'PASS', label + ' status')
    rows = report.get('steps', [])
    for name in required:
        matches = [row for row in rows if row.get('step') == name]
        require(len(matches) == 1 and matches[0].get('ok') is True, label + ' step: ' + name)
    return {row['step']: row for row in rows}


def verify_android(request, split, tour, backup, native, gate):
    emulator_hash = split['packages']['x86_64']['sha256']
    same(tour.get('apk_sha256'), emulator_hash, 'Tour emulator APK')
    same(tour.get('installed_package'), PACKAGE, 'Tour installed package')
    same(tour.get('fatal_crashes'), 0, 'Tour fatal crashes')
    steps = passed_steps(tour, TOUR_STEPS, 'Tour')
    verify_identity(request, steps['apk-identity'], emulator_hash)
    steps = passed_steps(backup, BACKUP_STEPS, 'Backup')
    verify_identity(request, backup.get('identity', {}), emulator_hash)
    same(steps['apk-identity'].get('installed_sha256'), emulator_hash, 'Backup installed APK')
    for key in ('installed', 'installed_after'):
        same(backup.get(key, {}).get('sha256'), emulator_hash, 'Backup ' + key)
    same(native.get('package'), PACKAGE, 'Native diagnostics package')
    same(gate, verify_native_starts(native), 'Original native-start gate')


def verify_metadata(request, provenance, verification, split):
    shared = {'package': PACKAGE, 'versionCode': request['version_code'],
              'versionName': request['version_name'], 'abis': ['arm64-v8a'],
              'bytes': request['apk_bytes'], 'sha256': request['apk_sha256'],
              'signingCertificateSha256': request['certificate_sha256'],
              'elf16KiBAligned': True, 'resourcesArscAligned': True}
    godot = {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
             'revision': request['godot_commit'], 'engine': '4.6.3',
             'pck_sha256': request['pck_sha256'], 'bytes': request['pck_bytes']}
    for label, document in [('Provenance', provenance), ('APK verification', verification)]:
        for key, expected in shared.items():
            same(document.get(key), expected, label + ' ' + key)
        same(document.get('godot'), godot, label + ' Godot')
    same(provenance.get('flutter_source_commit'), request['flutter_commit'], 'Provenance source')
    same(provenance.get('tracked_source_clean'), True, 'Provenance clean source')
    for key, expected in {'flutter_source_commit': request['flutter_commit'],
                          'versionName': request['version_name'], 'versionCode': request['version_code'],
                          'same_pck': True}.items():
        same(split.get(key), expected, 'Split ' + key)
    same(split.get('godot'), {k: godot[k] for k in ('repository', 'revision', 'engine')}, 'Split Godot')
    same(set(split['packages']), {'arm64-v8a', 'x86_64'}, 'Split ABIs')
    for abi, item in split['packages'].items():
        for key, expected in {'abi': abi, 'signingCertificateSha256': request['certificate_sha256'],
                              'godot_pck_sha256': request['pck_sha256'],
                              'godot_pck_bytes': request['pck_bytes']}.items():
            same(item.get(key), expected, 'Split ' + abi + ' ' + key)
        require(type(item.get('bytes')) is int and item['bytes'] > 0 and
                re.fullmatch(r'[0-9a-f]{64}', item.get('sha256', '')), 'Invalid split APK identity')
    same(split['packages']['arm64-v8a']['sha256'], request['apk_sha256'], 'Split ARM64 digest')
    same(split['packages']['arm64-v8a']['bytes'], request['apk_bytes'], 'Split ARM64 bytes')
    return godot


def archive_matches(path, files):
    with zipfile.ZipFile(path) as archive:
        require(len(archive.namelist()) == len(set(archive.namelist())), 'Duplicate archive member')
        for name, original in files.items():
            with archive.open(name) as stream:
                same(hashlib.file_digest(stream, 'sha256').hexdigest(), digest(original), 'Archived ' + name)


def release_files(request):
    return [ROOT / 'apk' / request['apk_file'],
            *(ROOT / 'metadata' / name for name in ('SHA256SUMS.txt', 'BUILD-PROVENANCE.json',
                'APK-VERIFICATION.json', 'SPLIT-APK-IDENTITY.json', 'LUMO-WORLD-LOGIK-BELEGE.zip', 'LIESMICH.txt')),
            ROOT / 'android/LUMO-ANDROID-PRUEFBELEGE.zip', ROOT / 'proof/PUBLICATION-ORDER.json']


def verify_files(request, build_tools):
    verify_api(request, read(ROOT / 'proof/ORIGINAL-RUN-AND-ARTIFACTS.json'))
    same(read(ROOT / 'proof/PUBLICATION-ORDER.json'), request, 'Saved order')
    metadata, android = ROOT / 'metadata', ROOT / 'android/tour'
    apk = ROOT / 'apk' / request['apk_file']
    same(apk.stat().st_size, request['apk_bytes'], 'Actual APK bytes')
    same(digest(apk), request['apk_sha256'], 'Actual APK digest')
    same((metadata / 'SHA256SUMS.txt').read_text().split(),
         [request['apk_sha256'], request['apk_file']], 'Original SHA256SUMS')
    provenance, verification, split = [read(metadata / name) for name in
        ('BUILD-PROVENANCE.json', 'APK-VERIFICATION.json', 'SPLIT-APK-IDENTITY.json')]
    godot = verify_metadata(request, provenance, verification, split)
    with zipfile.ZipFile(apk) as archive:
        require(len(archive.namelist()) == len(set(archive.namelist())), 'Duplicate APK member')
        same(decode(archive.read('assets/lumo_game_source.json')), godot, 'Packaged Godot identity')
        same(archive.getinfo('assets/lumo_game.pck').file_size, request['pck_bytes'], 'Packaged PCK bytes')
        with archive.open('assets/lumo_game.pck') as stream:
            same(hashlib.file_digest(stream, 'sha256').hexdigest(), request['pck_sha256'], 'Packaged PCK digest')
        same({name.split('/')[1] for name in archive.namelist() if name.startswith('lib/') and name.endswith('.so')},
             {'arm64-v8a'}, 'Actual packaged ABIs')
    # Public certificate verification needs neither a keystore nor a signing operation.
    subprocess.run(['java', '-cp', str(build_tools / 'lib/apksigner.jar'),
                    'scripts/LumoApkCertificateVerifier.java', str(apk.resolve()),
                    request['certificate_sha256']], check=True, capture_output=True, text=True)
    badging = subprocess.run([str(build_tools / 'aapt'), 'dump', 'badging', str(apk)],
                             check=True, capture_output=True, text=True).stdout
    match = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    require(match is not None, 'APK manifest is unreadable')
    same(list(match.groups()), [PACKAGE, str(request['version_code']), request['version_name']], 'Actual APK manifest')
    same(read(android / 'SPLIT-APK-IDENTITY.json'), split, 'Android original split identity')
    verify_android(request, split, read(android / 'tour-result.json'),
                   read(android / 'local-backup/backup-result.json'),
                   read(android / 'native-starts.json'), read(android / 'NATIVE-GAME-STARTS.json'))
    archive_matches(ROOT / 'android/LUMO-ANDROID-PRUEFBELEGE.zip', {
        'tour/' + name: android / name for name in ('tour-result.json', 'local-backup/backup-result.json',
            'native-starts.json', 'NATIVE-GAME-STARTS.json', 'SPLIT-APK-IDENTITY.json')})
    archive_matches(metadata / 'LUMO-WORLD-LOGIK-BELEGE.zip', {
        'build-proof/' + name: metadata / name for name in ('APK-VERIFICATION.json', 'SPLIT-APK-IDENTITY.json')})
    files = release_files(request)
    save(ROOT / 'proof/PREPUBLICATION-VERIFICATION.json', {
        'status': 'PASS', 'request': request,
        'assets': {str(path): {'bytes': path.stat().st_size, 'sha256': digest(path)} for path in files},
        'scope': 'Original ARM64 bytes and signature; x86_64 Android tour and backup with identical PCK. '
                 'No physical ARM64 performance or 60-FPS claim.'})


class HttpsRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        require(urlparse(newurl).scheme == 'https', 'Public download redirected away from HTTPS')
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def anonymous_download(url, target, expected_bytes, expected_sha):
    require(urlparse(url).scheme == 'https', 'Public download must use HTTPS')
    # No Authorization header, cookies, GitHub token, credential helper or curl config.
    opener = build_opener(HttpsRedirects())
    total, checksum = 0, hashlib.sha256()
    with opener.open(Request(url, headers={'User-Agent': 'lumo-public-download-check'}), timeout=120) as response:
        same(response.status, 200, 'Anonymous download HTTP status')
        with target.open('wb') as output:
            while block := response.read(1024 * 1024):
                total += len(block)
                require(total <= expected_bytes, 'Public download is larger than the verified APK')
                checksum.update(block)
                output.write(block)
    same(total, expected_bytes, 'Anonymous download bytes')
    same(checksum.hexdigest(), expected_sha, 'Anonymous download SHA-256')


def publish(request):
    token = os.environ.get('LUMO_RELEASE_PUBLISH_TOKEN', '')
    require(bool(token), 'LUMO_RELEASE_PUBLISH_TOKEN is missing; no GITHUB_TOKEN fallback')
    identity = github_json('user', token)
    same(identity.get('login'), request['publisher_login'], 'Approved publisher login')
    same(identity.get('id'), request['publisher_user_id'], 'Approved publisher user ID')
    proof = read(ROOT / 'proof/PREPUBLICATION-VERIFICATION.json')
    same(proof.get('status'), 'PASS', 'Prepublication gate')
    same(proof.get('request'), request, 'Verified publication order')
    files = release_files(request)
    same(set(proof['assets']), {str(path) for path in files}, 'Verified release asset set')
    for path in files:
        same({'bytes': path.stat().st_size, 'sha256': digest(path)}, proof['assets'][str(path)],
             'Unchanged release asset ' + path.name)
    base, tag = 'repos/' + request['repository'], quote(request['release_tag'], safe='')
    require(github_json(f'{base}/releases/tags/{tag}', token, absent_ok=True) is None,
            'Release already exists; it will not be changed')
    require(github_json(f'{base}/git/ref/tags/{tag}', token, absent_ok=True) is None,
            'Tag already exists; it will not be changed')
    notes = ROOT / 'proof/RELEASE-NOTES.md'
    notes.write_text(f'# Lumo World und Logikspiele 0.14.1+2070\n\n'
        f'Unveränderte, signierte ARM64-Test-APK aus Run {request["build_run_id"]}.\n\n'
        f'Flutter: `{request["flutter_commit"]}`\n\nGodot: `{request["godot_commit"]}`\n\n'
        f'APK SHA-256: `{request["apk_sha256"]}`\n\n'
        f'Zertifikat SHA-256: `{request["certificate_sha256"]}`\n\n'
        f'PCK SHA-256: `{request["pck_sha256"]}`\n\n'
        'Bau, Paketprüfung, Android-Rundgang, alle nativen Spielstarts einschließlich World '
        'und Datensicherungs-Rückspielung sind bestanden. Android wurde auf x86_64 '
        'mit derselben PCK geprüft; dies ist kein Test auf einem physischen ARM64-Handy '
        'und keine Bestätigung von 60 FPS. Die Originalbelege liegen unverändert bei.\n')
    environment = {key: value for key, value in os.environ.items()
                   if key not in ('GH_TOKEN', 'GITHUB_TOKEN', 'LUMO_RELEASE_PUBLISH_TOKEN')}
    environment['GH_TOKEN'] = token
    subprocess.run(['gh', 'release', 'create', request['release_tag'], *map(str, files),
                    str(ROOT / 'proof/PREPUBLICATION-VERIFICATION.json'),
                    '--repo', request['repository'], '--target', request['flutter_commit'],
                    '--title', 'Lumo World und Logikspiele 0.14.1+2070',
                    '--notes-file', str(notes), '--prerelease', '--latest=false'],
                   env=environment, check=True, capture_output=True, text=True)
    release = github_json(f'{base}/releases/tags/{tag}', token)
    save(ROOT / 'proof/CREATED-RELEASE.json', release)
    same(release.get('draft'), False, 'Published release')
    same(release.get('prerelease'), True, 'Prerelease classification')
    same(release.get('target_commitish'), request['flutter_commit'], 'Release source commit')
    same(release.get('author', {}).get('id'), request['publisher_user_id'], 'Release publisher')
    ref = github_json(f'{base}/git/ref/tags/{tag}', token)
    same(ref.get('object'), {'type': 'commit', 'sha': request['flutter_commit'],
                           'url': f'https://api.github.com/{base}/git/commits/{request["flutter_commit"]}'},
         'Release tag target')
    assets = [asset for asset in release['assets'] if asset.get('name') == request['apk_file']]
    require(len(assets) == 1, 'Exactly one original APK asset is required')
    asset = assets[0]
    same(asset.get('size'), request['apk_bytes'], 'Published APK size')
    same(asset.get('state'), 'uploaded', 'Published APK upload state')
    url = asset.get('browser_download_url', '')
    expected_url = f'https://github.com/{request["repository"]}/releases/download/{tag}/{request["apk_file"]}'
    same(url, expected_url, 'Returned direct APK URL')
    downloaded = ROOT / 'public-download.apk'
    try:
        anonymous_download(url, downloaded, request['apk_bytes'], request['apk_sha256'])
    finally:
        downloaded.unlink(missing_ok=True)
    result = {'status': 'PASS', 'release_url': release['html_url'], 'download_url': url,
              'bytes': request['apk_bytes'], 'sha256': request['apk_sha256'],
              'anonymous_https_download_verified': True, 'release_id': release['id'], 'asset_id': asset['id']}
    save(ROOT / 'proof/PUBLIC-DOWNLOAD-VERIFICATION.json', result)
    print(json.dumps(result, indent=2))
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with Path(summary).open('a') as output:
            output.write(f'## Original-APK veröffentlicht und anonym geprüft\n\n[APK herunterladen]({url})\n\n'
                         f'{request["apk_bytes"]} Bytes · SHA-256 `{request["apk_sha256"]}`\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('prepare', 'verify', 'publish', 'template'))
    parser.add_argument('--build-tools', type=Path)
    for field in sorted(VARIABLE):
        parser.add_argument('--' + field.replace('_', '-'), type=str if field == 'publisher_login' else int)
    args = parser.parse_args()
    if args.mode == 'template':
        request = validate_request({**EXPECTED, **{key: getattr(args, key) for key in sorted(VARIABLE)}})
        print(json.dumps(request, indent=2))
        return
    request = validate_request(read(REQUEST))
    if args.mode == 'prepare':
        prepare(request)
    elif args.mode == 'verify':
        require(args.build_tools is not None, '--build-tools is required')
        verify_files(request, args.build_tools)
    else:
        publish(request)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        # No response body, subprocess output or environment containing credentials.
        print(f'Publication stopped: {type(error).__name__}: {error}', file=sys.stderr)
        raise SystemExit(1)
