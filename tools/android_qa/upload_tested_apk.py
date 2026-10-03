#!/usr/bin/env python3
"""Upload only a successfully tested frozen APK into the existing draft."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from download_apk import download
from release_lookup import resolve_draft


def upload(args):
    result = json.loads((args.evidence/'result.json').read_text())
    build = json.loads((args.evidence/'runner-build-proof.json').read_text())
    if result.get('passed') is not True:
        raise ValueError('No passing Android usage proof; APK upload refused')
    expected = build['apk']['sha256']
    path = args.evidence/'tested.apk'
    with path.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != expected or result['sha256'] != expected:
        raise ValueError('Build, usage test and upload APK hashes must be identical')
    # Require a still-unpublished, empty draft immediately before upload.
    release = resolve_draft(args.repository, args.release_tag)
    if any(asset['name'].lower().endswith('.apk') for asset in release.get('assets', [])):
        raise ValueError('The requested draft must still exist unpublished without another APK')
    named = args.evidence.parent/'Lumo-Lernen-Neu.apk'
    # A byte-identical copy gives the release its child-facing filename.
    import shutil
    shutil.copyfile(path, named)
    subprocess.run(['gh', 'release', 'upload', args.release_tag, str(named), '--repo', args.repository], check=True)
    # Verify the uploaded download, not just the request body, against the
    # tested input. No uploaded APK is overwritten or published on failure.
    with tempfile.TemporaryDirectory() as directory:
        downloaded = Path(directory)
        download(args.repository, args.release_tag, expected, downloaded)
        proof = json.loads((downloaded/'download-proof.json').read_text())
    proof['passing_test_sha256'] = result['sha256']
    proof['flutter_source_commit'] = build['flutter_source_commit']
    proof['release_published'] = False
    (args.evidence/'uploaded-apk-download-proof.json').write_text(json.dumps(proof, indent=2)+'\n')
    print(json.dumps(proof, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    upload(parser.parse_args())
