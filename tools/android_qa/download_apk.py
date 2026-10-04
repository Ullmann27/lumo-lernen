#!/usr/bin/env python3
"""Download one release APK via gh and verify the exact requested SHA-256.

Only reads the release; no upload, rebuild, signing or publishing operation.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

from release_lookup import resolve_draft

CANDIDATE_NAME = 'Lumo-Lernen-Pruefkandidat.bin'
PROVENANCE_NAME = 'Lumo-Lernen-Pruefkandidat-Provenienz.json'


def require_empty_build_draft(release):
    protected = {CANDIDATE_NAME.casefold(), PROVENANCE_NAME.casefold()}
    if any(asset['name'].lower().endswith('.apk') or asset['name'].casefold() in protected
           for asset in release.get('assets', [])):
        raise ValueError('Build mode refuses to replace an existing APK or cached candidate; use download mode')


def read_asset(repository, asset, target):
    with target.open('wb') as output:
        subprocess.run(['gh', 'api', f'repos/{repository}/releases/assets/{int(asset["id"])}',
                        '--header', 'Accept: application/octet-stream'], stdout=output, check=True)


def download(repository, tag, expected, output, write_output=True):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('Invalid GitHub repository')
    if not re.fullmatch(r'[0-9a-fA-F]{64}', expected):
        raise ValueError('apkSha must be exactly 64 hexadecimal characters')
    release = resolve_draft(repository, tag)
    assets = [asset for asset in release.get('assets', []) if asset['name'].lower().endswith('.apk')]
    provenance = None
    if assets:
        if len(assets) != 1:
            raise ValueError('The requested release must have exactly one APK asset')
        asset = assets[0]
    else:
        candidates = [asset for asset in release.get('assets', []) if asset['name'].lower().endswith('.bin')]
        origins = [asset for asset in release.get('assets', [])
                   if asset['name'].casefold() == PROVENANCE_NAME.casefold()]
        if (len(candidates) != 1 or candidates[0]['name'] != CANDIDATE_NAME
                or len(origins) != 1 or origins[0]['name'] != PROVENANCE_NAME):
            raise ValueError('Download requires one unique cached candidate and its provenance when no final APK exists')
        asset = candidates[0]
        output.mkdir(parents=True, exist_ok=True)
        origin_path = output/PROVENANCE_NAME
        read_asset(repository, origins[0], origin_path)
        provenance = json.loads(origin_path.read_text())
        if (provenance.get('repository') != repository or provenance.get('draft_release') != tag
                or provenance.get('cached_release_id') != release['id']
                or provenance.get('tracked_source_clean') is not True
                or provenance.get('release_published') is not False
                or provenance.get('mode') != 'runner-build' or provenance.get('ui_tested') is not False
                or not re.fullmatch(r'[0-9a-f]{40}', provenance.get('flutter_source_commit', ''))
                or not re.fullmatch(r'[0-9a-f]{64}', provenance.get('apk', {}).get('signingCertificateSha256', ''))
                or provenance.get('apk', {}).get('sha256') != expected.lower()):
            raise ValueError('Cached candidate provenance does not match the requested draft/source/SHA')
    output.mkdir(parents=True, exist_ok=True)
    path = output/'tested.apk'
    read_asset(repository, asset, path)
    with path.open('rb') as source:
        actual = hashlib.file_digest(source, 'sha256').hexdigest()
    if actual != expected.lower():
        raise ValueError(f'APK SHA-256 mismatch: expected {expected.lower()}, received {actual}')
    if provenance:
        if provenance['apk'].get('bytes') != path.stat().st_size:
            raise ValueError('Cached candidate bytes differ from the verified build provenance')
        # Preserve the original APK source when a newer QA harness tests it.
        (output/'runner-build-proof.json').write_text(json.dumps(provenance, indent=2)+'\n')
    with zipfile.ZipFile(path) as archive:
        files = set(archive.namelist())
        required = {'AndroidManifest.xml', 'resources.arsc', 'assets/lumo_game.pck',
                    'lib/x86_64/libgodot_android.so', 'lib/x86_64/libflutter.so'}
        if not required.issubset(files):
            raise ValueError(f'Missing unified Android x86_64 APK files: {sorted(required-files)}')
        if archive.getinfo('resources.arsc').compress_type != zipfile.ZIP_STORED:
            raise ValueError('resources.arsc must remain uncompressed for this Android APK')
        bad = archive.testzip()
        if bad:
            raise ValueError(f'Corrupt APK ZIP entry: {bad}')
    proof = {'repository': repository, 'release_tag': release['tag_name'],
             'release_id': release['id'], 'draft': release['draft'],
             'asset_id': asset['id'], 'asset_name': asset['name'],
             'bytes': path.stat().st_size, 'sha256': actual,
             'source_kind': 'cached-candidate' if provenance else 'final-apk',
             'flutter_source_commit': provenance['flutter_source_commit'] if provenance else None,
             'qa_harness_commit': os.environ.get('GITHUB_SHA')}
    (output/'download-proof.json').write_text(json.dumps(proof, indent=2)+'\n')
    if write_output and os.environ.get('GITHUB_OUTPUT'):
        with Path(os.environ['GITHUB_OUTPUT']).open('a') as stream:
            stream.write(f'sha256={actual}\n')
    print(json.dumps(proof, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    download(args.repository, args.release_tag, args.sha256, args.out)
