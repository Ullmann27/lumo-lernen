#!/usr/bin/env python3
"""Record an explicitly completed Studio 2019 review from the original CI ZIP.

Selection entries contain module, artifact_entry and the reviewer's findings
for PNGs they actually inspected. This command does not inspect the art. Every
review is bound to all eight required native jobs and five clean capture sources;
the three repaired touch surfaces each need an inspected current renderer image.
original images are stored under their full content hash without replacing an
older review's different PNG bytes. Recording never publishes an APK.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import tempfile
import zipfile

from release_pipeline_gates import sha256_file
from verify_studio_delivery import (REVIEW_RECEIPT, VERSION_CODE, archive_member,
                                    png_dimensions, read_json, require,
                                    reviewed_file, reviewed_relative_path,
                                    verify_archive_sources, verify_native_acceptance,
                                    verify_visual_review)


def record_review(root: Path, archive: Path, artifact: dict, workflow: dict, jobs: dict,
                  selection: list, reviewer: str, notes: str) -> dict:
    require(archive.is_file() and not archive.is_symlink(), 'Missing original downloaded native archive')
    digest = sha256_file(archive)
    require(artifact.get('digest') == 'sha256:' + digest, 'Downloaded native archive digest differs')
    native = artifact.get('workflow_run', {}).get('head_sha', '')
    verify_native_acceptance(native, artifact, workflow, jobs)
    require(isinstance(selection, list) and bool(selection), 'An inspected image selection is required')
    receipt = {'schema': 1, 'status': 'approved', 'versionCode': VERSION_CODE, 'native_revision': native,
               'native_workflow_run_id': workflow['id'], 'native_artifact_id': artifact['id'],
               'native_artifact_sha256': digest, 'reviewed_by': reviewer,
               'reviewed_at': datetime.now(timezone.utc).isoformat(), 'notes': notes, 'images': []}
    with tempfile.TemporaryDirectory(prefix='lumo-studio-review-') as temporary, zipfile.ZipFile(archive) as zipped:
        staging = Path(temporary)
        verify_archive_sources(zipped, native)
        for choice in selection:
            require(isinstance(choice, dict), 'Invalid inspected image selection')
            entry, module = choice.get('artifact_entry'), choice.get('module')
            # Validate the production module/path before reading any archive member.
            reviewed_relative_path('0' * 64, module, entry)
            data = archive_member(zipped, entry)
            image_digest = hashlib.sha256(data).hexdigest()
            dimensions = png_dimensions(data)
            relative = reviewed_relative_path(image_digest, module, entry)
            path = staging / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            receipt['images'].append({'path': relative, 'module': module, 'artifact_entry': entry,
                                      'sha256': image_digest, 'dimensions': dimensions,
                                      'findings': choice.get('findings')})
        verify_visual_review(staging, receipt, native, artifact, workflow, jobs, archive)
        output = root / REVIEW_RECEIPT
        require(not output.is_symlink() and not output.parent.is_symlink(),
                'Visual review receipt must not be written through a symlink')
        # Validate the complete set first. A new run or a changed selection order
        # cannot collide with a different original image from an older receipt.
        for item in receipt['images']:
            destination = reviewed_file(root, item['path'])
            require(not destination.exists() or
                    (destination.is_file() and sha256_file(destination) == item['sha256']),
                    'A different reviewed image already exists: ' + item['path'])
        for item in receipt['images']:
            destination = reviewed_file(root, item['path'])
            if not destination.exists():
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes((staging / item['path']).read_bytes())
        output.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', prefix='studio-review-',
                                         suffix='.json', dir=output.parent, delete=False) as pending:
            pending.write(json.dumps(receipt, indent=2, ensure_ascii=False) + '\n')
            pending_path = Path(pending.name)
        pending_path.replace(output)
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
