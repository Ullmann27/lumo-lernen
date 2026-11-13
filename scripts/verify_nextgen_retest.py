#!/usr/bin/env python3
"""Bind a corrected QA-only tour to the unchanged, already built 2018 APK.

This does not turn the failed original workflow into a passing workflow. Its
successful build/compile jobs and immutable artifacts are verified separately;
new Android, update and publication gates must run against those exact bytes.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import tempfile
import urllib.request
import zipfile


REPO = 'Ullmann27/lumo-lernen'
APK_SOURCE = 'a31c0070a9c1e9dfbea08f123d7ed77e5f0a8ad9'
NATIVE_SOURCE = '51fb026f0b0e7a43b3aad30cc0fcdc144050c724'
ORIGINAL_RUN = 43381440720
APK_X86_SHA256 = '768364f33ac3280f39da74db8f75f9d77fca0986050f2da6a0b831508266cf50'
APK_ARM64_SHA256 = 'e588eb822eee44ccc0ed6e0f9232cf6c61d449b65a63c9538949ba78a7b16899'
QA_BRANCH = 'chatgpt/lumo-2018-android-acceptance-20261113'
PRODUCT_BRANCH = 'chatgpt/lumo-nextgen-20261113'
WORKFLOW_PATH = '.github/workflows/lumo-nextgen-2018-android-retest.yml'
PCK_SHA256 = 'e1bb847cb2410a8ce81fbcc319520ec823e27c38690aad123dff5513e329b2b2'
CURRENT_ARTIFACTS = {
    'prerequisites': 'lumo-2018-recovery-prerequisites',
    'tour': 'lumo-2018-recovery-android-tour',
    'update': 'lumo-2018-recovery-update-proof',
}
PROBE_FILES = frozenset({
    'tools/android_qa/native_surface_readiness.py',
    '.github/probes/creative_android_probe.py',
    '.github/probes/lumo_nextgen_surfaces_android_probe.py',
    '.github/probes/lumo_2003_update_android_probe.py',
    '.github/probes/lumo_2018_update_android_probe.py',
    'tools/android_qa/update_preservation.py',
    'tools/android_qa/nextgen_evidence.py',
})
ALLOWED_CHANGES = PROBE_FILES | frozenset({
    '.github/workflows/lumo-nextgen-2018-android-retest.yml',
    'scripts/verify_nextgen_retest.py',
    'scripts/tests/test_nextgen_retest.py',
    'tools/android_qa/tests/test_nextgen_cards_readiness.py',
    'tools/android_qa/tests/test_nextgen_responsive_surface.py',
    'tools/android_qa/tests/test_update_preservation.py',
    'tools/android_qa/tests/test_nextgen_evidence.py',
    'tools/android_qa/tests/fixtures/android_2018_cards_authority_recorded.txt',
    'tools/android_qa/tests/fixtures/android_2018_cards_authority_recorded.json',
    'tools/android_qa/tests/fixtures/update_2017_2018_independent_evidence.json',
    'test/tutoring/build2018_update_migration_test.dart',
    'tools/android_qa/tests/fixtures/android_2018_learning_portrait_a31_00.png',
    'tools/android_qa/tests/fixtures/android_2018_learning_portrait_a31_36.png',
    'tools/android_qa/tests/fixtures/android_2018_learning_portrait_a31.json',
    'docs/qa/2026-11-13-build2018-portrait-probe.md',
    'docs/qa/2026-11-13-build2018-update-preservation.md',
    'docs/evidence/build2018-portrait-recovery-20261113/contracts.log',
    'docs/evidence/build2018-portrait-recovery-20261113/RESULT.json',
})
ARTIFACTS = {
    'candidate': (14019148742, 'lumo-nextgen-2018-candidate', 645769405,
                  '3bc81ba8a020ac38bffdca7b21da00d308177801bdb8bf5fa8bc6635d63a5dd7', ORIGINAL_RUN, APK_SOURCE),
    'arm64': (14019805993, 'lumo-nextgen-2018-arm64-verified', 321308718,
              '097bf5bcb4c08a44931ce034442e545003f8949cc7a9707b1dd4fdeb33de79d7', ORIGINAL_RUN, APK_SOURCE),
    'compile': (14017266187, 'lumo-nextgen-2018-android-host-compile', 5388,
                '89654287b33aa20586cf8cfd02f14013b6a670e6c5d26a3d9f8c255a074c5762', ORIGINAL_RUN, APK_SOURCE),
    'failed-tour': (14019739556, 'lumo-nextgen-2018-android-tour', 101498893,
                    '5fe39dc2d931b4b2f58a82446cb75770f0e761a6960957b6ecbacd4fa060bbf2', ORIGINAL_RUN, APK_SOURCE),
    'flutter': (14017038047, 'lumo-candidate-all-flutter-tests-and-captures', 332920698,
                'bdc0c8b6a86e7ec7f14775ea15c91cf2a32276b5429b790a6ba9cdc2dcd8fa32', ORIGINAL_RUN, APK_SOURCE),
    'native': (14018733084, 'lumo-candidate-pinned-native-gameplay', 106113895,
               'dc9792af9906c70d734f916cc7d6814b8478f726604d387d0abdab2c6c0527c7', ORIGINAL_RUN, APK_SOURCE),
    'baseline': (13948686178, 'lumo-lernen-kart-unified-2026-candidate', 640684233,
                 '4b4fa4e7de52d75f385fc4d7e398f571d86363ad17cc22ac41ef95aab61d08ff',
                 43220602252, '47889f74a651b073965def70743417cf320b1eb9'),
}
REQUIRED_BUILD_STEPS = {
    'Full Flutter regression suite including every capture',
    'Verify all build and preservation contracts',
    'Code-level Android probe regression with verified image dependencies',
    'Require actual gameplay gates on the exact pinned native source',
    'Build unified real Android APK',
    'Verify APK archive and collect reproducible source hashes',
    'Upload exact candidate (no release or synthetic screenshots)',
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def save(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def api(suffix: str, repository: str = REPO) -> dict:
    headers = {'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'}
    token = os.environ.get('GH_TOKEN')
    if token:
        headers['Authorization'] = 'Bearer ' + token
    require(repository in (REPO, 'Ullmann27/lumo-godot'), 'Unexpected metadata repository')
    request = urllib.request.Request(f'https://api.github.com/repos/{repository}/{suffix}', headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        value = json.load(response)
    require(isinstance(value, dict), 'GitHub metadata must be an object')
    return value


def verify_product_head(pull: dict, branch: dict, *, repository: str, number: int,
                        source: str, base: str) -> None:
    require(pull.get('number') == number and pull.get('state') == 'open' and
            pull.get('merged') is False, 'Reviewed product PR is no longer open and unmerged')
    head, target = pull.get('head', {}), pull.get('base', {})
    require(head.get('sha') == source and head.get('ref') == PRODUCT_BRANCH and
            head.get('repo', {}).get('full_name') == repository and
            target.get('ref') == base and target.get('repo', {}).get('full_name') == repository,
            'Reviewed product PR advanced or changed repository/branch/base')
    require(branch.get('ref') == 'refs/heads/' + PRODUCT_BRANCH and
            branch.get('object', {}).get('type') == 'commit' and
            branch['object'].get('sha') == source, 'Reviewed product branch advanced')


def verify_live_heads(evidence: Path) -> None:
    for repository, number, source, base in (
            (REPO, 461, APK_SOURCE, 'chatgpt/lumo-spielewelt-stage-20261112'),
            ('Ullmann27/lumo-godot', 157, NATIVE_SOURCE, 'chatgpt/lumo-action-stage-20261112')):
        pull = api(f'pulls/{number}', repository)
        branch = api('git/ref/heads/' + PRODUCT_BRANCH, repository)
        verify_product_head(pull, branch, repository=repository, number=number, source=source, base=base)
        save(evidence / f'product-pr-{number}.json', pull)
        save(evidence / f'product-branch-{number}.json', branch)


def verify_automation(run: dict, branch: dict, source: str, run_id: int) -> None:
    require(run.get('id') == run_id and run.get('head_sha') == source and
            run.get('head_branch') == QA_BRANCH and run.get('event') == 'pull_request' and
            run.get('path') == WORKFLOW_PATH and
            run.get('repository', {}).get('full_name') == REPO,
            'Recovery is not this exact internal PR workflow/source')
    require(branch.get('ref') == 'refs/heads/' + QA_BRANCH and
            branch.get('object', {}).get('type') == 'commit' and
            branch['object'].get('sha') == source, 'Recovery automation branch advanced')


def live_automation(source: str, evidence: Path) -> tuple[dict, dict]:
    run_id = int(os.environ['GITHUB_RUN_ID'])
    run = api(f'actions/runs/{run_id}')
    branch = api('git/ref/heads/' + QA_BRANCH)
    verify_automation(run, branch, source, run_id)
    save(evidence / 'automation-workflow.json', run)
    save(evidence / 'automation-branch.json', branch)
    return run, branch


def verify_upstream(run: dict, jobs: dict) -> None:
    require(run.get('id') == ORIGINAL_RUN and run.get('head_sha') == APK_SOURCE and
            run.get('status') == 'completed' and run.get('conclusion') == 'failure',
            'The original failed run/source must remain explicitly identified')
    require(run.get('repository', {}).get('full_name') == REPO and
            run.get('event') == 'pull_request' and run.get('head_branch') == PRODUCT_BRANCH,
            'Original workflow belongs to another repository')
    require(jobs.get('total_count', len(jobs.get('jobs', []))) == len(jobs.get('jobs', [])),
            'Original job inventory was truncated')
    by_name = {job.get('name'): job for job in jobs.get('jobs', [])}
    for name, job_id in (('verify-and-build', 131739877430), ('android-host-compile', 131739877829)):
        job = by_name.get(name, {})
        require(job.get('id') == job_id and job.get('run_id') == ORIGINAL_RUN and
                job.get('status') == 'completed' and job.get('conclusion') == 'success',
                'Original mandatory job did not pass: ' + name)
        steps = {step.get('name'): step for step in job.get('steps', [])}
        required = REQUIRED_BUILD_STEPS if name == 'verify-and-build' else {
            'Compile actual current Android host before native release pin approval'}
        require(all(steps.get(key, {}).get('conclusion') == 'success' for key in required),
                'Original mandatory job steps are missing or failed: ' + name)
    original_tour = by_name.get('android-tour', {})
    require(original_tour.get('id') == 131762099939 and
            original_tour.get('run_id') == ORIGINAL_RUN and
            original_tour.get('conclusion') == 'failure',
            'The original Android failure must not be represented as success')


def verify_artifact(kind: str, metadata: dict) -> None:
    artifact_id, name, size, digest, run, source = ARTIFACTS[kind]
    require(metadata.get('id') == artifact_id and metadata.get('name') == name and
            metadata.get('size_in_bytes') == size and metadata.get('expired') is False and
            metadata.get('digest') == 'sha256:' + digest,
            'Original artifact identity or digest mismatch: ' + kind)
    workflow = metadata.get('workflow_run', {})
    require(workflow.get('id') == run and workflow.get('head_sha') == source and
            workflow.get('repository_id') == 1222433959 and
            workflow.get('head_repository_id') == 1222433959,
            'Artifact belongs to another source/run/repository: ' + kind)


def extract_verified(archive: Path, destination: Path, expected_size: int, digest: str) -> None:
    require(archive.stat().st_size == expected_size and sha256(archive) == digest,
            'Downloaded archive bytes do not match the immutable artifact')
    require(not destination.exists() or not any(destination.iterdir()),
            'Refusing to mix artifact files with existing content')
    with zipfile.ZipFile(archive) as zipped:
        require(zipped.testzip() is None, 'Artifact archive CRC failure')
        names = set()
        for info in zipped.infolist():
            path = PurePosixPath(info.filename)
            require(not path.is_absolute() and '..' not in path.parts and '\\' not in info.filename and
                    path.as_posix() not in names and bool(path.parts) and
                    str(path) == info.filename.rstrip('/') and not stat.S_ISLNK(info.external_attr >> 16),
                    'Unsafe or duplicate artifact entry')
            names.add(path.as_posix())
        destination.mkdir(parents=True, exist_ok=True)
        zipped.extractall(destination)


def download_bytes(metadata: dict, destination: Path, evidence: Path, label: str) -> None:
    artifact_id = metadata['id']
    size, digest = metadata['size_in_bytes'], metadata['digest'].removeprefix('sha256:')
    with tempfile.TemporaryDirectory(prefix='lumo-2018-verified-artifact-') as temporary:
        archive = Path(temporary) / (label + '.zip')
        with archive.open('wb') as output:
            subprocess.run(['gh', 'api', f'repos/{REPO}/actions/artifacts/{artifact_id}/zip'],
                           stdout=output, check=True, timeout=600)
        extract_verified(archive, destination, size, digest)
    save(evidence / (label + '-artifact.json'), metadata)
    save(evidence / (label + '-download.json'), {
        'status': 'PASS', 'artifact_id': artifact_id, 'archive_bytes': size,
        'archive_sha256': digest, 'crc_verified': True, 'destination': str(destination),
        'scope': 'Actual archive bytes and CRC, not Android gameplay acceptance'})


def verify_apk_payload(directory: Path, abi: str) -> dict:
    expected = {'arm64-v8a': (321298305, APK_ARM64_SHA256),
                'x86_64': (324444578, APK_X86_SHA256)}[abi]
    apk = directory / 'Lumo-Lernen-Neu.apk'
    require(apk.stat().st_size == expected[0] and sha256(apk) == expected[1],
            'Downloaded APK differs from the exact accepted build bytes: ' + abi)
    proof = json.loads((directory / 'BUILD-PROVENANCE.json').read_text())
    require(proof.get('flutter_source_commit') == APK_SOURCE and
            proof.get('tracked_source_clean') is True and proof.get('abis') == [abi] and
            proof.get('bytes') == expected[0] and proof.get('sha256') == expected[1] and
            proof.get('versionCode') == 2018 and proof.get('versionName') == '0.13.6' and
            proof.get('package') == 'dev.ullmann.lumo.lumo_lernen.coachpreview' and
            proof.get('signingCertificateSha256') ==
            'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702',
            'Downloaded APK/provenance source, signature, version or ABI differs')
    require(proof.get('godot', {}).get('revision') == NATIVE_SOURCE and
            proof['godot'].get('pck_sha256') == PCK_SHA256 and
            proof['godot'].get('bytes') == 65411764, 'Wrong candidate native pack provenance')
    with zipfile.ZipFile(apk) as package:
        require(package.testzip() is None, 'Actual APK CRC failure')
        entries = [info for info in package.infolist() if info.filename.endswith('.pck')]
        require(len(entries) == 1 and entries[0].filename == 'assets/lumo_game.pck' and
                entries[0].file_size == 65411764, 'Actual APK contains another native pack')
        digest = hashlib.sha256()
        with package.open(entries[0]) as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(block)
        require(digest.hexdigest() == PCK_SHA256, 'Actual embedded PCK bytes changed')
    return proof


def download(kind: str, destination: Path, evidence: Path) -> dict:
    metadata = api(f'actions/artifacts/{ARTIFACTS[kind][0]}')
    verify_artifact(kind, metadata)
    download_bytes(metadata, destination, evidence, kind)
    if kind in ('candidate', 'arm64'):
        arm = verify_apk_payload(destination, 'arm64-v8a')
        if kind == 'candidate':
            x86 = verify_apk_payload(destination / 'x86_64', 'x86_64')
            require(arm['godot'] == x86['godot'] and arm['offlineVoice'] == x86['offlineVoice'],
                    'Native pack/voice differs between actual emulator and delivery APKs')
    return metadata


def verify_current_artifact(kind: str, metadata: dict, run_id: int, source: str) -> None:
    require(metadata.get('name') == CURRENT_ARTIFACTS[kind] and metadata.get('expired') is False and
            type(metadata.get('id')) is int and metadata['id'] > 0 and
            type(metadata.get('size_in_bytes')) is int and metadata['size_in_bytes'] > 0 and
            bool(re.fullmatch(r'sha256:[a-f0-9]{64}', str(metadata.get('digest')))),
            'Current recovery artifact is missing, expired or lacks an exact digest')
    run = metadata.get('workflow_run', {})
    require(run.get('id') == run_id and run.get('head_sha') == source and
            run.get('repository_id') == run.get('head_repository_id') == 1222433959,
            'Current acceptance artifact belongs to another run, source or repository')


def download_current(kind: str, destination: Path, evidence: Path, qa: Path) -> None:
    run_id, source = int(os.environ['GITHUB_RUN_ID']), git(qa, 'rev-parse', 'HEAD')
    listing = api(f'actions/runs/{run_id}/artifacts?per_page=100')
    require(listing.get('total_count') == len(listing.get('artifacts', [])), 'Artifact list was truncated')
    matches = [a for a in listing['artifacts'] if a.get('name') == CURRENT_ARTIFACTS[kind]]
    require(len(matches) == 1, 'Current recovery proof is missing or ambiguous: ' + kind)
    verify_current_artifact(kind, matches[0], run_id, source)
    download_bytes(matches[0], destination, evidence, 'current-' + kind)


def git(root: Path, *arguments: str) -> str:
    return subprocess.run(['git', '-C', str(root), *arguments], check=True,
                          capture_output=True, text=True).stdout.strip()


def tree(root: Path) -> dict:
    raw = subprocess.run(['git', '-C', str(root), 'ls-tree', '-r', '-z', 'HEAD'],
                         check=True, capture_output=True).stdout.decode()
    return {entry.split('\t', 1)[1]: entry.split('\t', 1)[0]
            for entry in raw.split('\0') if entry}


def verify_tree_scope(app_source: str, qa_source: str, app_tree: dict, qa_tree: dict,
                      app_clean: bool, qa_clean: bool) -> dict:
    require(app_source == APK_SOURCE, 'App checkout is not the built APK source')
    require(bool(re.fullmatch(r'[a-f0-9]{40}', qa_source)) and qa_source != APK_SOURCE,
            'Missing separate immutable QA workflow source')
    require(app_clean and qa_clean, 'Tracked source changed after checkout')
    changed = {path for path in app_tree.keys() | qa_tree.keys() if app_tree.get(path) != qa_tree.get(path)}
    require(changed <= ALLOWED_CHANGES and
            PROBE_FILES <= changed and WORKFLOW_PATH in changed,
            'Retest changed application/native/policy files or lacks its corrected probe/workflow')
    require(all(path in qa_tree for path in ALLOWED_CHANGES), 'Retest QA files are incomplete')
    require(all(re.fullmatch(r'100(?:644|755) blob [0-9a-f]{40}', qa_tree[path])
                for path in ALLOWED_CHANGES), 'QA allowlist may contain only regular file blobs')
    return {path: {'app_blob': app_tree.get(path), 'qa_blob': qa_tree.get(path)} for path in sorted(changed)}


def checkout_identity(app: Path, qa: Path) -> dict:
    app_source, qa_source = git(app, 'rev-parse', 'HEAD'), git(qa, 'rev-parse', 'HEAD')
    changes = verify_tree_scope(app_source, qa_source, tree(app), tree(qa),
                               not git(app, 'status', '--porcelain', '--untracked-files=no'),
                               not git(qa, 'status', '--porcelain', '--untracked-files=no'))
    run_id = os.environ.get('GITHUB_RUN_ID', '')
    require(run_id.isdigit() and int(run_id) > 0, 'Missing actual QA workflow run ID')
    return {'status': 'PASS', 'apk_source_commit': app_source, 'qa_workflow_source_commit': qa_source,
            'qa_workflow_run_id': int(run_id), 'original_workflow_run_id': ORIGINAL_RUN,
            'original_workflow_status': 'failure', 'original_build_job_id': 131739877430,
            'original_android_host_compile_job_id': 131739877829, 'native_source': NATIVE_SOURCE,
            'changed_qa_files': changes, 'app_product_source_unchanged': True,
            'arm64_apk_sha256': APK_ARM64_SHA256, 'x86_apk_sha256': APK_X86_SHA256}


def verify_failed_original(prior: Path, qa: Path) -> dict:
    original = json.loads((prior / 'tour-result.json').read_text())
    surfaces = json.loads((prior / 'nextgen/native-surfaces-result.json').read_text())
    readiness = json.loads((prior / 'nextgen/learning-move-1-surface-readiness.json').read_text())
    require(original.get('status') == 'PASS' and original.get('apk_sha256') == APK_X86_SHA256,
            'The original successful Kart tour/actual APK identity is missing')
    require(surfaces.get('status') == 'FAIL' and surfaces.get('error') ==
            'TimeoutError: Current native surface/target did not settle before touch: Ein Objekt zeigen' and
            surfaces.get('apk_identity', {}).get('apk_sha256') == APK_X86_SHA256 and
            surfaces['apk_identity'].get('flutter_source_commit') == APK_SOURCE,
            'Original failure differs from the actual a31 portrait diagnosis')
    frames = readiness.get('frames', [])
    require(readiness.get('status') == 'FAIL' and readiness.get('timeout_seconds') == 120 and
            len(frames) == 37 and 'touch' not in readiness,
            'Original failure did not precede the first touch with 37 observations')
    require(all(frame.get('pixels') == [1080, 2400] and
                frame.get('acceptable_for_target_sampling') is False and
                frame.get('reasons') == ['native landscape surface has not arrived']
                for frame in frames), 'Original frame rejection had another cause')
    fixtures = {}
    for index, suffix in ((0, '00'), (36, '36')):
        recorded = prior / 'nextgen' / f'learning-move-1-{index}.png'
        fixture = qa / 'tools/android_qa/tests/fixtures' / f'android_2018_learning_portrait_a31_{suffix}.png'
        digest = sha256(recorded)
        require(digest == frames[index].get('source_sha256') == sha256(fixture),
                'Portrait regression fixture differs from the unchanged actual Android frame')
        fixtures[fixture.name] = digest
    return {'original_tour_status': 'PASS', 'original_new_surfaces_status': 'FAIL',
            'failure': surfaces['error'], 'rejected_portrait_frames': 37,
            'first_learning_touch_performed': False, 'fixture_sha256': fixtures}


def verify_flutter(directory: Path) -> dict:
    summary = json.loads((directory / 'acceptance-summary.json').read_text())
    require(summary.get('status') == 'PASS' and summary.get('passed') == 2472 and
            summary.get('failed') == [] and summary.get('skipped') == [] and
            summary.get('capture_error_files') == [] and summary.get('runner_errors') == [] and
            summary.get('flutter_exit_code') == 0 and summary.get('runner_completed_successfully') is True and
            summary.get('rendered_png_count') == 542 and len(list(directory.rglob('*.png'))) == 542,
            'Original full Flutter acceptance is incomplete')
    events = []
    for line in (directory / 'flutter-machine.jsonl').read_text().splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict):
            events.append(event)
    suites = {event['suite']['id']: event['suite'] for event in events if event.get('type') == 'suite'}
    tests = {event['test']['id']: event['test'] for event in events if event.get('type') == 'testStart'}
    done = {event['testID']: event for event in events if event.get('type') == 'testDone'}
    returns = [done.get(identifier, {}) for identifier, test in tests.items()
               if suites.get(test.get('suiteID'), {}).get('path', '').endswith('/lumo_native_origin_return_test.dart')
               and not done.get(identifier, {}).get('hidden')]
    require(len(returns) == 10 and all(case.get('result') == 'success' and case.get('skipped') is False
                                     for case in returns), 'Actual caller-return regressions are missing')
    return summary


def verify_native(directory: Path) -> dict:
    sources = sorted(directory.rglob('source-sha.txt'))
    require(len(sources) == 4 and all(path.read_text().strip() == NATIVE_SOURCE for path in sources),
            'Original native acceptance belongs to another source')
    require(not (directory / 'nextgen/source-dirty.txt').read_text().strip(), 'Original native source was dirty')
    with (directory / 'nextgen/results.tsv').open() as stream:
        results = list(csv.DictReader(stream, delimiter='\t'))
    require(len(results) == 25 and all(row.get('result') == 'PASS' for row in results) and
            len(list((directory / 'nextgen').rglob('*.png'))) == 66,
            'Original full Nextgen acceptance/captures are incomplete')
    return {'source': NATIVE_SOURCE, 'nextgen_results': results, 'nextgen_pngs': 66,
            'scope': 'Original successful native job; existing legacy exit warnings remain in original raw logs.'}


def verify_recovery_jobs(jobs: dict, run_id: int) -> None:
    require(jobs.get('total_count', len(jobs.get('jobs', []))) == len(jobs.get('jobs', [])),
            'Recovery job inventory was truncated')
    for name in ('verify-reused-source', 'android-tour', 'update-2018-from-2017'):
        matches = [job for job in jobs.get('jobs', []) if job.get('name') == name]
        require(len(matches) == 1 and matches[0].get('run_id') == run_id and
                matches[0].get('status') == 'completed' and matches[0].get('conclusion') == 'success',
                'New actual recovery gate did not pass: ' + name)


def preflight(app: Path, qa: Path, out: Path) -> None:
    identity = checkout_identity(app, qa)
    verify_live_heads(out)
    live_automation(identity['qa_workflow_source_commit'], out)
    run, jobs = api(f'actions/runs/{ORIGINAL_RUN}'), api(f'actions/runs/{ORIGINAL_RUN}/jobs?per_page=100')
    verify_upstream(run, jobs)
    save(out / 'original-workflow.json', run)
    save(out / 'original-jobs.json', jobs)
    for kind, (artifact_id, *_rest) in ARTIFACTS.items():
        metadata = api(f'actions/artifacts/{artifact_id}')
        verify_artifact(kind, metadata)
        save(out / (kind + '-artifact.json'), metadata)
    with tempfile.TemporaryDirectory(prefix='lumo-2018-original-proofs-') as temporary:
        directory = Path(temporary)
        download('compile', directory / 'host', out)
        host = json.loads((directory / 'host/result.json').read_text())
        from verify_nextgen_delivery import COMPILED_CLASSES
        require(host.get('status') == 'PASS' and host.get('flutter_source_commit') == APK_SOURCE and
                COMPILED_CLASSES <= set(host.get('classes', {})), 'Original bytecode proof is incomplete')
        save(out / 'host/result.json', host)
        download('failed-tour', directory / 'prior', out)
        identity['original_failure'] = verify_failed_original(directory / 'prior', qa)
        save(out / 'original-failed-surfaces-result.json',
             json.loads((directory / 'prior/nextgen/native-surfaces-result.json').read_text()))
        download('flutter', directory / 'flutter', out)
        save(out / 'full-flutter-summary.json', verify_flutter(directory / 'flutter'))
        download('native', directory / 'native', out)
        save(out / 'native-summary.json', verify_native(directory / 'native'))
    save(out / 'RETEST-IDENTITY.json', identity)
    print(json.dumps(identity, indent=2))


def verify_receipt(app: Path, qa: Path, receipt: Path, out: Path) -> dict:
    expected = json.loads(receipt.read_text())
    current = checkout_identity(app, qa)
    require(all(expected.get(key) == value for key, value in current.items()),
            'QA receipt belongs to another workflow, source, artifact or source tree')
    verify_live_heads(out)
    live_automation(current['qa_workflow_source_commit'], out)
    return current


def authorize_publication(app: Path, qa: Path, receipt: Path, facts_path: Path, out: Path) -> None:
    identity = verify_receipt(app, qa, receipt, out)
    run_id = identity['qa_workflow_run_id']
    jobs = api(f'actions/runs/{run_id}/jobs?per_page=100')
    verify_recovery_jobs(jobs, run_id)
    save(out / 'recovery-jobs-before-publication.json', jobs)
    facts = json.loads(facts_path.read_text())
    require(facts.get('flutterSourceCommit') == APK_SOURCE and facts.get('godotSourceCommit') == NATIVE_SOURCE and
            facts.get('apkSha256') == APK_ARM64_SHA256 and facts.get('apkBytes') == 321298305 and
            facts.get('androidTourApkSha256') == APK_X86_SHA256 and facts.get('versionCode') == 2018,
            'Unmodified delivery verifier did not bind all actual proofs to the original APK')
    identity['all_new_recovery_jobs_succeeded'] = True
    identity['release_facts_sha256'] = sha256(facts_path)
    save(out / 'RECOVERY-AUTHORIZATION.json', identity)
    print('Exact a31 APK and separate current recovery automation authorized after all new live gates')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    check = sub.add_parser('preflight')
    check.add_argument('--app', type=Path, required=True)
    check.add_argument('--qa', type=Path, required=True)
    check.add_argument('--out', type=Path, required=True)
    fetch = sub.add_parser('download')
    fetch.add_argument('--kind', choices=ARTIFACTS, required=True)
    fetch.add_argument('--out', type=Path, required=True)
    fetch.add_argument('--evidence', type=Path, required=True)
    current = sub.add_parser('download-current')
    current.add_argument('--kind', choices=CURRENT_ARTIFACTS, required=True)
    current.add_argument('--qa', type=Path, required=True)
    current.add_argument('--out', type=Path, required=True)
    current.add_argument('--evidence', type=Path, required=True)
    for name in ('identity', 'authorize-publication'):
        command = sub.add_parser(name)
        command.add_argument('--app', type=Path, required=True)
        command.add_argument('--qa', type=Path, required=True)
        command.add_argument('--receipt', type=Path, required=True)
        command.add_argument('--out', type=Path, required=True)
        if name == 'authorize-publication':
            command.add_argument('--facts', type=Path, required=True)
    args = parser.parse_args()
    if args.command == 'download':
        download(args.kind, args.out, args.evidence)
    elif args.command == 'download-current':
        download_current(args.kind, args.out, args.evidence, args.qa)
    elif args.command == 'preflight':
        preflight(args.app, args.qa, args.out)
    elif args.command == 'authorize-publication':
        authorize_publication(args.app, args.qa, args.receipt, args.facts, args.out)
    else:
        verify_receipt(args.app, args.qa, args.receipt, args.out)
        print('Verified current product heads, unchanged App and separate QA workflow identity')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
