#!/usr/bin/env python3
"""Save immutable verified APK bytes as a private draft candidate before UI QA."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from download_apk import CANDIDATE_NAME, PROVENANCE_NAME, download, require_empty_build_draft
from release_lookup import resolve_draft


def cache(args):
    release = resolve_draft(args.repository, args.release_tag)
    require_empty_build_draft(release)
    build = json.loads((args.evidence/'runner-build-proof.json').read_text())
    path = args.evidence/'tested.apk'
    with path.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if (build.get('repository') != args.repository or build.get('draft_release') != args.release_tag
            or build.get('tracked_source_clean') is not True or build.get('release_published') is not False
            or build['apk']['sha256'] != actual or build['apk']['bytes'] != path.stat().st_size):
        raise ValueError('Only the frozen verified build can become a cached candidate')
    provenance = {**build, 'cached_release_id': release['id'], 'ui_tested': False}
    binary = args.evidence.parent/CANDIDATE_NAME
    origin = args.evidence.parent/PROVENANCE_NAME
    shutil.copyfile(path, binary)
    origin.write_text(json.dumps(provenance, indent=2)+'\n')
    # No clobber, update, delete or publish operation: duplicates fail closed.
    subprocess.run(['gh', 'release', 'upload', args.release_tag, str(binary), str(origin),
                    '--repo', args.repository], check=True)
    with tempfile.TemporaryDirectory() as directory:
        checked = Path(directory)
        download(args.repository, args.release_tag, actual, checked, write_output=False)
        restored = json.loads((checked/'runner-build-proof.json').read_text())
        if restored != provenance:
            raise ValueError('Downloaded candidate provenance differs from the frozen build')
        proof = json.loads((checked/'download-proof.json').read_text())
    proof.update(ui_tested=False, final_apk_uploaded=False, release_published=False)
    (args.evidence/'candidate-cache-proof.json').write_text(json.dumps(proof, indent=2)+'\n')
    print(json.dumps(proof, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    cache(parser.parse_args())
