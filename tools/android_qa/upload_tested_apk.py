#!/usr/bin/env python3
"""Upload only a successfully tested frozen APK into the existing draft."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from download_apk import download
from release_lookup import resolve_draft


def upload(args):
    result = json.loads((args.evidence/'result.json').read_text())
    if result.get('passed') is not True:
        raise ValueError('No passing Android usage proof; APK upload refused')
    build_path = args.evidence/'runner-build-proof.json'
    build = json.loads(build_path.read_text()) if build_path.exists() else None
    expected = result['sha256']
    path = args.evidence/'tested.apk'
    with path.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != expected or (build and build['apk']['sha256'] != expected):
        raise ValueError('Build, usage test and upload APK hashes must be identical')
    # Require a still-unpublished, empty draft immediately before upload.
    release = resolve_draft(args.repository, args.release_tag)
    finals = [asset for asset in release.get('assets', []) if asset['name'].lower().endswith('.apk')]
    if len(finals) > 1:
        raise ValueError('The requested draft has ambiguous final APK assets')
    if not finals and not build:
        raise ValueError('Promoting a candidate requires its verified build provenance')
    named = args.evidence.parent/'Lumo-Lernen-Neu.apk'
    # A byte-identical copy gives the release its child-facing filename.
    import shutil
    if not finals:
        shutil.copyfile(path, named)
        subprocess.run(['gh', 'release', 'upload', args.release_tag, str(named), '--repo', args.repository], check=True)
    # Verify the uploaded download, not just the request body, against the
    # tested input. No uploaded APK is overwritten or published on failure.
    with tempfile.TemporaryDirectory() as directory:
        downloaded = Path(directory)
        download(args.repository, args.release_tag, expected, downloaded)
        proof = json.loads((downloaded/'download-proof.json').read_text())
    proof['passing_test_sha256'] = result['sha256']
    proof['flutter_source_commit'] = build['flutter_source_commit'] if build else None
    proof['qa_harness_commit'] = os.environ.get('GITHUB_SHA')
    proof['final_apk_already_present'] = bool(finals)
    proof['release_published'] = False
    (args.evidence/'uploaded-apk-download-proof.json').write_text(json.dumps(proof, indent=2)+'\n')
    print(json.dumps(proof, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    upload(parser.parse_args())
