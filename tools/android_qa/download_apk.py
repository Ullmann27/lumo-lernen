#!/usr/bin/env python3
"""Download one release APK via gh and verify the exact requested SHA-256.

Only reads the release; no upload, rebuild, signing or publishing operation.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import quote
import zipfile


def download(repository, tag, expected, output):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('Invalid GitHub repository')
    if not re.fullmatch(r'[0-9a-fA-F]{64}', expected):
        raise ValueError('apkSha must be exactly 64 hexadecimal characters')
    endpoint = f'repos/{repository}/releases/tags/{quote(tag, safe="")}'
    release = json.loads(subprocess.check_output(['gh', 'api', endpoint], text=True))
    if not release.get('draft'):
        raise ValueError('This integration check expects an existing draft release')
    assets = [asset for asset in release.get('assets', []) if asset['name'].lower().endswith('.apk')]
    if len(assets) != 1:
        raise ValueError('The requested release must have exactly one APK asset')
    asset = assets[0]
    output.mkdir(parents=True, exist_ok=True)
    path = output/'tested.apk'
    with path.open('wb') as target:
        subprocess.run(['gh', 'api', f'repos/{repository}/releases/assets/{int(asset["id"])}',
                        '--header', 'Accept: application/octet-stream'], stdout=target, check=True)
    with path.open('rb') as source:
        actual = hashlib.file_digest(source, 'sha256').hexdigest()
    if actual != expected.lower():
        raise ValueError(f'APK SHA-256 mismatch: expected {expected.lower()}, received {actual}')
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
             'bytes': path.stat().st_size, 'sha256': actual}
    (output/'download-proof.json').write_text(json.dumps(proof, indent=2)+'\n')
    print(json.dumps(proof, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    download(args.repository, args.release_tag, args.sha256, args.out)
