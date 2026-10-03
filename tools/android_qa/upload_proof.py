#!/usr/bin/env python3
"""Attach test evidence to the existing draft; never uploads an APK or publishes."""
import argparse
import json
from pathlib import Path
import subprocess
import zipfile

from release_lookup import resolve_draft


def upload(repository, tag, evidence, run_id, attempt):
    release = resolve_draft(repository, tag)
    evidence.mkdir(parents=True, exist_ok=True)
    (evidence/'workflow-run.json').write_text(json.dumps({
        'run_id': int(run_id), 'attempt': int(attempt), 'repository': repository,
        'release_tag': tag, 'proof_only': True,
        'run_url': f'https://github.com/{repository}/actions/runs/{int(run_id)}',
    }, indent=2)+'\n')
    output = evidence.parent/f'android-api35-qa-{int(run_id)}-{int(attempt)}.zip'
    allowed = {'.png', '.xml', '.txt', '.tsv', '.json', '.jsonl', '.log'}
    files = [path for path in evidence.rglob('*') if path.is_file() and path.suffix in allowed]
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(files):
            archive.write(path, path.relative_to(evidence))
    with zipfile.ZipFile(output) as archive:
        if any(name.lower().endswith('.apk') for name in archive.namelist()):
            raise ValueError('Proof ZIP must not contain an APK')
    subprocess.run(['gh', 'release', 'upload', tag, str(output), '--repo', repository], check=True)
    print(json.dumps({'proof_zip': output.name, 'entries': len(files),
                      'existing_draft': tag, 'apk_uploaded': False, 'release_published': False}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--run-id', required=True)
    parser.add_argument('--attempt', required=True)
    args = parser.parse_args()
    upload(args.repository, args.release_tag, args.evidence, args.run_id, args.attempt)
