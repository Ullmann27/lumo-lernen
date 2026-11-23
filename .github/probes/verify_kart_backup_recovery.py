#!/usr/bin/env python3
"""Bind a focused Android backup rerun to the unchanged, already signed APK."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import runpy
import subprocess
import urllib.request

BASE = 'c6edb5ac1f7808ba5d994696ea803a364cbe6500'
GODOT = 'c9619c589e3a9faa0b56f190fb38a61bf44bb1d6'
RUN = 45154258300
REPO = 'Ullmann27/lumo-lernen'
ARM = '26454377ce203dd17a4322f1b421439553d2b028450c97622c89576949e0e7c2'
X86 = '26641eba29e31f432032d83d8d1f05356e0ac20ec9f7df6131a4f914574adc6c'
PCK = 'f7db19ec6ebabe4db5cb605e9c5d4fe78662af1392823ad4cc4e6f19db3e912f'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
IDENTITY_CHECKS = {
    'sha256_matches_provenance', 'sha256_matches_build_sums',
    'flutter_source_is_this_commit', 'tracked_source_clean',
    'godot_revision_is_pinned', 'signing_certificate',
    'version_matches_pubspec', 'x86_64_native_code',
}
PRIOR_FILES = {
    'tour/tour-result.json': '4d39a82a19edfb7b95433e5107f11e94ad81e1aea1858743fef5d97363653adc',
    'tour/native-starts.json': '5de5fbdfe3e1e8bf6a9e9eefd8c9520557e87646848e68ef9486bfc4c9fd683f',
    'tour/local-backup/backup-result.json': '84918bd1289ea7ffcc676964e5e46e8332b412191ee08fdc0a7b1ee3ab26fdde',
    'tour/local-backup/export-suggested-name.xml': '31bf803dbf2029a6fee21223412b5b08872ef6d59fb093cc1eb7b683fa23be85',
    'tour/local-backup/backup-failure.xml': '3fe938ca4eaa81741897325da94c0bb10a7c3325e8c95c33c2e7955a6f4f45e3',
}
ALLOWED = {
    '.github/probes/lumo_local_backup_android_probe.py',
    'tools/android_qa/tests/test_local_backup_android_probe.py',
    '.github/probes/verify_kart_backup_recovery.py',
    '.github/workflows/lumo-kart-backup-recovery.yml',
}
ARTIFACTS = {
    'LUMO-KART-APK-45154258300': (14808576742, 523534799,
        'sha256:ecf82b0e28fa3b87d411b9a3321432dd252ebf68ab7a8fc145f4f00e8f13863a'),
    'LUMO-EMULATOR-APK-45154258300': (14808238028, 526715997,
        'sha256:95a40c2f46d3ff5f90e7b95ef1e433a7e6be56cdcade52c7798c45d200c59647'),
    'LUMO-KART-METADATA-45154258300': (14807913906, 2665799,
        'sha256:d9960757af81fa0b3cf215f2eded197a15664b8ae0462c9f4e903843e5a18751'),
    'LUMO-ANDROID-TOUR-45154258300': (14810313567, 73587363,
        'sha256:dc6f59eedf4c4dff2cd3ff43fcdb6bb0eca158336d611436881a17b2f562aff4'),
}
TOUR_STEPS = {
    'apk-identity', 'launch', 'onboarding', 'navigate-start', 'atelier-roundtrip',
    'navigate-lernen', 'navigate-spiele', 'open-kart', 'start-kart-race',
    'race-running', 'race-hud', 'race-drive', 'pause-menu', 'showroom-after-race',
    'return-from-kart', 'learning-state-after-kart', 'lernen-usable-after-kart',
    'profile-after-kart', 'restart-keeps-learning-state', 'display-fold_offen',
    'display-fold_aussen', 'display-quer', 'skypost-roundtrip',
}
BACKUP_STEPS = (
    'apk-identity', 'fictional-profile', 'saf-export', 'export-archive',
    'changed-setting', 'saf-review', 'process-closed', 'restore-and-preservation',
)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(path):
    result = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            result.update(chunk)
    return result.hexdigest()


def read(path):
    return json.loads(Path(path).read_text())


def git(root, *arguments):
    return subprocess.check_output(['git', '-C', str(root), *arguments], text=True).strip()


def api(path):
    url = 'https://api.github.com/repos/' + REPO + path
    request = urllib.request.Request(url, headers={
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer ' + os.environ['GH_TOKEN'],
        'X-GitHub-Api-Version': '2022-11-28',
    })
    with urllib.request.urlopen(request, timeout=45) as response:
        return json.load(response)


def tree(root, ref):
    rows = {}
    for line in git(root, 'ls-tree', '-r', ref).splitlines():
        metadata, path = line.split('\t', 1)
        rows[path] = metadata
    return rows


def verify_source(harness, candidate):
    head = git(harness, 'rev-parse', 'HEAD')
    require(head == os.environ['GITHUB_SHA'], 'Harness checkout differs from this workflow commit')
    require(not git(harness, 'status', '--porcelain', '--untracked-files=no'),
            'Executed harness has tracked modifications')
    require(git(candidate, 'rev-parse', 'HEAD') == BASE, 'Candidate source is not the signed APK source')
    require(not git(candidate, 'status', '--porcelain', '--untracked-files=no'),
            'Candidate source has tracked modifications')
    before, after = tree(harness, BASE), tree(harness, head)
    changed = {path for path in before.keys() | after.keys() if before.get(path) != after.get(path)}
    require(changed == ALLOWED, 'Unexpected product or harness changes: ' + repr(sorted(changed)))
    product = {path: value for path, value in before.items() if path not in ALLOWED}
    require(product == {path: value for path, value in after.items() if path not in ALLOWED},
            'Product tree changed')
    require(tree(candidate, 'HEAD') == before, 'Candidate checkout tree differs from APK source')
    return {
        'harness_commit': head, 'candidate_commit': BASE,
        'allowed_changed_paths': sorted(changed),
        'unchanged_entries': len(product),
        'unchanged_product_sha256': hashlib.sha256(
            json.dumps(product, sort_keys=True, separators=(',', ':')).encode()).hexdigest(),
    }


def verify_prior():
    run = api('/actions/runs/' + str(RUN))
    require(run.get('head_sha') == BASE and run.get('status') == 'completed'
            and run.get('conclusion') == 'failure', 'Unexpected baseline workflow result')
    jobs = api('/actions/runs/' + str(RUN) + '/jobs')['jobs']
    by_id = {job['id']: job for job in jobs}
    require(by_id.get(137623234341, {}).get('conclusion') == 'success',
            'The signed APK build job did not succeed')
    require(by_id.get(137628365087, {}).get('conclusion') == 'failure',
            'Unexpected baseline Android job')
    require(by_id.get(137645672038, {}).get('conclusion') == 'skipped',
            'The baseline publish job was not skipped')
    artifacts = api('/actions/runs/' + str(RUN) + '/artifacts')['artifacts']
    verified = []
    for name, (artifact_id, size, sha) in ARTIFACTS.items():
        matches = [row for row in artifacts if row.get('id') == artifact_id and row.get('name') == name]
        require(len(matches) == 1, 'Missing or ambiguous original artifact: ' + name)
        row = matches[0]
        require(row.get('size_in_bytes') == size and row.get('digest') == sha
                and row.get('expired') is False, 'Original artifact identity changed: ' + name)
        require(row.get('workflow_run', {}).get('head_sha') == BASE,
                'Artifact source differs: ' + name)
        verified.append({'id': artifact_id, 'name': name, 'bytes': size, 'sha256': sha})
    return {'run_id': RUN, 'build_job': 137623234341, 'artifacts': verified}


def verify_apks(x86_dir, arm_dir):
    for directory, expected, size in ((x86_dir, X86, 538256234), (arm_dir, ARM, 535089633)):
        provenance = read(directory / 'BUILD-PROVENANCE.json')
        paths = list(directory.glob('*.apk'))
        require(len(paths) == 1 and paths[0].stat().st_size == size,
                'Unexpected original APK file or size')
        require(digest(paths[0]) == expected == provenance.get('sha256'),
                'Original APK bytes differ')
        require(provenance.get('flutter_source_commit') == BASE
                and provenance.get('versionName') == '0.13.56'
                and provenance.get('versionCode') == 2068
                and provenance.get('signingCertificateSha256') == CERT,
                'Original APK provenance differs')
        require(provenance.get('godot', {}).get('revision') == GODOT
                and provenance.get('godot', {}).get('pck_sha256') == PCK,
                'Embedded game provenance differs')
    return {'arm64_sha256': ARM, 'x86_64_sha256': X86, 'pck_sha256': PCK,
            'godot_commit': GODOT, 'signing_certificate_sha256': CERT}


def verify_tour(tour):
    require(tour.get('status') == 'PASS' and tour.get('apk_sha256') == X86,
            'Installed Android tour did not pass for this exact APK')
    steps = tour.get('steps', [])
    require(len(steps) == len(TOUR_STEPS)
            and {step.get('step') for step in steps} == TOUR_STEPS
            and all(step.get('ok') is True for step in steps), 'Incomplete Android tour')
    require(tour.get('fatal_crashes') == 0, 'Android tour recorded fatal crashes')
    identity = next(step for step in steps if step['step'] == 'apk-identity')
    checks = identity.get('checks')
    require(isinstance(checks, dict) and set(checks) == IDENTITY_CHECKS
            and all(value is True for value in checks.values()),
            'Tour identity checks are incomplete or failed')
    require(identity.get('apk_sha256') == X86
            and identity.get('flutter_source_commit') == BASE
            and identity.get('godot_revision') == GODOT
            and identity.get('godot_pck_sha256') == PCK
            and identity.get('versionName') == '0.13.56'
            and identity.get('versionCode') == 2068
            and identity.get('signingCertificateSha256') == CERT,
            'Tour identity mismatch')
    return {'steps': len(steps), 'not_tested': tour.get('not_tested', [])}


def verify_prior_files(prior):
    for name, expected in PRIOR_FILES.items():
        require(digest(prior / name) == expected, 'Original evidence bytes differ: ' + name)
    return dict(PRIOR_FILES)


def prepare(args):
    source = verify_source(args.harness, args.candidate)
    prior = verify_prior()
    packages = verify_apks(args.x86, args.arm)
    evidence = verify_prior_files(args.prior)
    prior_tour = verify_tour(read(args.prior / 'tour/tour-result.json'))
    failed = read(args.prior / 'tour/local-backup/backup-result.json')
    require(failed.get('status') == 'FAIL'
            and failed.get('error') == 'RuntimeError: Exactly one current suggested backup filename is required',
            'Unexpected original backup failure')
    require([(step.get('step'), step.get('ok')) for step in failed.get('steps', [])]
            == [('apk-identity', True), ('fictional-profile', True), ('saf-export', False)],
            'Unexpected original backup progress')
    return {
        'status': 'PASS', 'phase': 'PREPARED',
        'scope': 'Identical signed APK; test harness change only',
        'source': source, 'prior': prior, 'packages': packages,
        'prior_evidence_files': evidence,
        'prior_tour': prior_tour, 'native_starts_reused_from_run': RUN,
        'fresh_required': ['23-step installed Android tour',
                           'complete SAF export, review and restore roundtrip'],
        'original_backup_failure_preserved': True,
    }


def complete(args):
    prepared = read(args.out)
    require(prepared.get('status') == 'PASS' and prepared.get('phase') == 'PREPARED',
            'Preparation was not verified')
    require(prepared.get('source') == verify_source(args.harness, args.candidate),
            'Prepared harness and candidate source differ')
    require(prepared.get('packages') == verify_apks(args.x86, args.arm),
            'Prepared packages differ')
    require(prepared.get('prior_evidence_files') == verify_prior_files(args.prior),
            'Prepared original evidence differs')
    fresh = verify_tour(read(args.tour / 'tour-result.json'))
    backup = read(args.tour / 'local-backup/backup-result.json')
    require(backup.get('status') == 'PASS', 'Fresh backup did not pass')
    require([step.get('step') for step in backup.get('steps', [])] == list(BACKUP_STEPS)
            and all(step.get('ok') is True for step in backup['steps']), 'Incomplete fresh backup')
    identity = backup.get('identity', {})
    require(identity.get('apk_sha256') == X86 and identity.get('flutter_source_commit') == BASE
            and identity.get('godot_revision') == GODOT and identity.get('godot_pck_sha256') == PCK,
            'Backup tested a different package')
    checks = identity.get('checks')
    require(isinstance(checks, dict) and set(checks) == IDENTITY_CHECKS
            and all(value is True for value in checks.values()),
            'Backup identity checks are incomplete or failed')
    for key in ('installed', 'installed_after'):
        require(backup.get(key, {}).get('sha256') == X86, 'Installed APK changed during restore')
    native = read(args.tour / 'NATIVE-GAME-STARTS.json')
    require(digest(args.tour / 'native-starts.json') == PRIOR_FILES['tour/native-starts.json'],
            'Final native-start evidence is not the original observed file')
    verifier = runpy.run_path(str(args.candidate / 'scripts/verify_native_start_diagnostics.py'))
    expected_native = verifier['verify'](read(args.tour / 'native-starts.json'))
    require(native == expected_native, 'Native gate report differs from the unchanged verifier')
    prepared.update({
        'phase': 'COMPLETED', 'android_status': 'PASS',
        'android_workflow_run': int(os.environ['GITHUB_RUN_ID']),
        'fresh_tour': fresh, 'fresh_backup_steps': len(BACKUP_STEPS),
        'fresh_backup_status': 'PASS',
        'native_start_evidence_sha256': digest(args.tour / 'native-starts.json'),
        'native_required_ui_starts': sorted(expected_native['required_scenes']),
        'native_observed_cases': len(read(args.tour / 'native-starts.json')['scenes']),
        'physical_device_test': False, 'public_multiplayer_server_deployed': False,
    })
    return prepared


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=('prepare', 'complete'))
    for name in ('harness', 'candidate', 'x86', 'arm', 'prior', 'tour', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    result = prepare(args) if args.phase == 'prepare' else complete(args)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()

