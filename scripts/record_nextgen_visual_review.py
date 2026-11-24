#!/usr/bin/env python3
"""Record an already completed image review from a verified native CI ZIP.

The selection JSON contains module, artifact_entry and the reviewer's findings
for each image they actually inspected. This command does not inspect or approve
the art itself. It refuses failed workflows, changed ZIP bytes or other sources.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import struct
import tempfile
import zipfile

from release_pipeline_gates import sha256_file
from verify_nextgen_delivery import read_json, require, verify_visual_review


def record_review(root: Path, archive: Path, artifact: dict, workflow: dict, jobs: dict,
                  selection: list, reviewer: str, notes: str) -> dict:
    digest = sha256_file(archive)
    require(artifact.get('digest') == 'sha256:' + digest, 'Downloaded native archive digest differs')
    native = artifact.get('workflow_run', {}).get('head_sha', '')
    require(bool(re.fullmatch(r'[a-f0-9]{40}', native)), 'Missing exact native source')
    receipt = {'schema': 1, 'status': 'approved', 'versionCode': 2018, 'native_revision': native,
               'native_workflow_run_id': workflow.get('id'), 'native_artifact_id': artifact.get('id'),
               'native_artifact_sha256': digest, 'reviewed_by': reviewer,
               'reviewed_at': datetime.now(timezone.utc).isoformat(), 'notes': notes, 'images': []}
    require(isinstance(selection, list) and bool(selection), 'An inspected image selection is required')
    with tempfile.TemporaryDirectory(prefix='lumo-review-') as temporary, zipfile.ZipFile(archive) as zipped:
        staging = Path(temporary)
        source = zipped.read('nextgen-evidence/nextgen/source-sha.txt').decode().strip()
        require(source == native, 'Archive source metadata differs from the reviewed native commit')
        dirty = zipped.read('nextgen-evidence/nextgen/source-dirty.txt').decode().strip()
        require(not dirty, 'Native screenshots were captured from modified tracked source')
        for choice in selection:
            require(isinstance(choice, dict), 'Invalid inspected image selection')
            entry = str(choice.get('artifact_entry', ''))
            archive_path = PurePosixPath(entry)
            require(not archive_path.is_absolute() and '..' not in archive_path.parts and
                    archive_path.parts[:3] == ('nextgen-evidence', 'nextgen', 'captures') and
                    archive_path.suffix == '.png', 'Only original current production-scene PNGs may be reviewed')
            module = str(choice.get('module', ''))
            require(bool(re.fullmatch('[a-z]+', module)), 'Invalid image module')
            data = zipped.read(entry)
            require(data[:8] == b'\x89PNG\r\n\x1a\n' and data[12:16] == b'IHDR' and len(data) > 32,
                    'Selected archive entry is not an original PNG')
            image_digest = hashlib.sha256(data).hexdigest()
            # Corrected pixels get a new immutable path; unchanged pixels remain
            # reusable even when reviewers reorder the selected originals.
            relative = f'docs/evidence/nextgen-2018-reviewed/{module}-{image_digest}-{archive_path.name}'
            path = staging / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            receipt['images'].append({'path': relative, 'module': module, 'artifact_entry': entry,
                                      'sha256': image_digest,
                                      'dimensions': list(struct.unpack('>II', data[16:24])),
                                      'findings': choice.get('findings')})
        verify_visual_review(staging, receipt, native, artifact, workflow, jobs)
        # Check the entire set before touching the destination. Never silently
        # replace a previously recorded, different original screenshot.
        for item in receipt['images']:
            destination = root / item['path']
            require(not destination.exists() or sha256_file(destination) == item['sha256'],
                    'A different reviewed image already exists: ' + item['path'])
        for item in receipt['images']:
            destination = root / item['path']
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes((staging / item['path']).read_bytes())
    output = root / 'config/nextgen-2018-visual-review.json'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(receipt, indent=2, ensure_ascii=False) + '\n')
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--archive', type=Path, required=True)
    parser.add_argument('--artifact-metadata', type=Path, required=True)
    parser.add_argument('--workflow-metadata', type=Path, required=True)
    parser.add_argument('--jobs-metadata', type=Path, required=True)
    parser.add_argument('--selection', type=Path, required=True)
    parser.add_argument('--reviewer', required=True)
    parser.add_argument('--notes', required=True)
    args = parser.parse_args()
    receipt = record_review(args.root, args.archive, read_json(args.artifact_metadata),
                             read_json(args.workflow_metadata), read_json(args.jobs_metadata),
                             json.loads(args.selection.read_text()), args.reviewer, args.notes)
    print(json.dumps({'status': receipt['status'], 'native_revision': receipt['native_revision'],
                      'images': len(receipt['images']), 'publication_enabled': False}, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
