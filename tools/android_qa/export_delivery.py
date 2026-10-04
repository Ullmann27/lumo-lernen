#!/usr/bin/env python3
"""Read-only transfer of finished QA evidence and, only after success, its exact APK."""
import argparse
import json
from pathlib import Path
import re
import tempfile
import zipfile


def validate_run(run, repository, run_id, expected_head):
    if (run.get('id') != run_id or run.get('head_sha') != expected_head
            or run.get('head_branch') != 'codex/lumo-unified-android-2026-10-03'
            or run.get('path') != '.github/workflows/android-integration-qa.yml'
            or run.get('repository', {}).get('full_name') != repository
            or run.get('status') != 'completed'
            or type(run.get('run_attempt')) is not int):
        raise ValueError('The selected Android QA run has not completed or does not match its saved source')


def validate_proof(run, metadata, result, uploaded, emulator, repository, tag, expected):
    if (metadata.get('run_id') != run['id'] or metadata.get('attempt') != run['run_attempt']
            or metadata.get('repository') != repository or metadata.get('release_tag') != tag):
        raise ValueError('Evidence ZIP belongs to another run, attempt, repository or draft')
    if run.get('conclusion') != 'success':
        return False
    if (result.get('passed') is not True or result.get('sha256') != expected
            or uploaded.get('sha256') != expected
            or uploaded.get('passing_test_sha256') != expected
            or uploaded.get('qa_harness_commit') != run['head_sha']
            or uploaded.get('source_kind') != 'final-apk'
            or uploaded.get('asset_name') != 'Lumo-Lernen-Neu.apk'
            or uploaded.get('release_published') is not False
            or emulator.get('passed') is not True or emulator.get('headless') is not True):
        raise ValueError('Final APK delivery requires matching successful usage, upload and emulator proofs')
    return True


def export(args):
    # Keep connector/CLI dependencies out of the pure validation functions.
    from download_apk import download, read_asset
    from release_lookup import _get, resolve_draft
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', args.repository):
        raise ValueError('Invalid repository')
    if not re.fullmatch(r'[0-9a-f]{40}', args.expected_head):
        raise ValueError('Expected QA commit must be a full lowercase SHA')
    if not re.fullmatch(r'[0-9a-f]{64}', args.sha256):
        raise ValueError('Expected APK SHA-256 must be explicit')
    if args.out.exists() and any(args.out.iterdir()):
        raise ValueError('Delivery directory must be empty; no stale APK is allowed')
    run = _get(f'repos/{args.repository}/actions/runs/{args.run_id}')
    validate_run(run, args.repository, args.run_id, args.expected_head)
    release = resolve_draft(args.repository, args.release_tag)
    name = f'android-api35-qa-{args.run_id}-{run["run_attempt"]}.zip'
    assets = [asset for asset in release.get('assets', []) if asset.get('name') == name]
    if len(assets) != 1:
        raise ValueError('The exact completed QA evidence ZIP is missing or ambiguous')
    args.out.mkdir(parents=True, exist_ok=True)
    archive_path = args.out/name
    read_asset(args.repository, assets[0], archive_path)
    with zipfile.ZipFile(archive_path) as archive:
        if any(name.lower().endswith('.apk') for name in archive.namelist()):
            raise ValueError('QA evidence must not smuggle an unvalidated APK')
        def read_json(name):
            if name not in archive.namelist():
                return {}
            if archive.getinfo(name).file_size > 2_000_000:
                raise ValueError('Unexpectedly large proof JSON')
            value = json.loads(archive.read(name))
            if not isinstance(value, dict):
                raise ValueError('Proof must be a JSON object')
            return value
        allowed = validate_proof(run, read_json('workflow-run.json'), read_json('result.json'),
                                 read_json('uploaded-apk-download-proof.json'),
                                 read_json('emulator-version-proof.json'),
                                 args.repository, args.release_tag, args.sha256)
    if allowed:
        with tempfile.TemporaryDirectory() as temporary:
            downloaded = Path(temporary)
            download(args.repository, args.release_tag, args.sha256, downloaded, write_output=False)
            proof = json.loads((downloaded/'download-proof.json').read_text())
            if proof.get('source_kind') != 'final-apk' or proof.get('asset_name') != 'Lumo-Lernen-Neu.apk':
                raise ValueError('Only the successful final APK may be transferred, never the candidate')
            import shutil
            shutil.copyfile(downloaded/'tested.apk', args.out/'Lumo-Lernen-Neu.apk')
            shutil.copyfile(downloaded/'download-proof.json', args.out/'apk-download-proof.json')
    status = {'repository': args.repository, 'qa_run_id': args.run_id,
              'qa_commit': args.expected_head, 'qa_conclusion': run.get('conclusion'),
              'apk_included': allowed, 'apk_sha256': args.sha256 if allowed else None,
              'evidence_zip': name, 'release_published': False}
    (args.out/'STATUS.json').write_text(json.dumps(status, indent=2)+'\n')
    print(json.dumps(status, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--run-id', type=int, required=True)
    parser.add_argument('--expected-head', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--out', type=Path, required=True)
    export(parser.parse_args())
