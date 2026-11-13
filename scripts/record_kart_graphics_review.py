#!/usr/bin/env python3
"""Record an explicitly completed Graphics 2019 review from three original ZIPs.

The reviewer supplies a JSON list of {area, artifact_entry, findings} for images
they actually inspected. This tool never evaluates the art. --proofs contains
the unchanged run.json, jobs.json and home/worlds/feedback-artifact.json API
responses. ZIPs, all manifested PNG bytes and original metadata are checked
before the existing graphics verifier accepts a staged review. Original PNGs
are content-addressed; output files are replaced atomically with the receipt
last, and a failed installation rolls back. No APK is published.
"""
from __future__ import annotations

import argparse
from contextlib import ExitStack
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import tempfile
import zipfile

from release_pipeline_gates import sha256_file
from verify_kart_graphics_review import (
    AREA_ARTIFACT, ARTIFACT_NAMES, PROOF_DIRECTORY, REQUIRED_LOGS,
    REVIEW_AREAS, SOURCE_FILES, WORKFLOW_FILES, _png_dimensions, _relative,
    require, verify_visual_review,
)


REVIEW_RECEIPT = PurePosixPath('config/kart-graphics-2019-visual-review.json')


def _input_bytes(path: Path, limit: int) -> bytes:
    require(path.is_file() and not path.is_symlink() and path.stat().st_size <= limit,
            'Missing or invalid original metadata: ' + str(path))
    return path.read_bytes()


def _zip_index(zipped: zipfile.ZipFile) -> dict[str, zipfile.ZipInfo]:
    entries = {}
    for info in zipped.infolist():
        name = str(_relative(info.filename[:-1] if info.is_dir() else info.filename))
        require(name not in entries, 'Duplicate original ZIP member: ' + name)
        mode = stat.S_IFMT(info.external_attr >> 16)
        expected = stat.S_IFDIR if info.is_dir() else stat.S_IFREG
        require(mode in (0, expected) and not (info.flag_bits & 1),
                'Original ZIP contains a non-regular or encrypted member: ' + name)
        entries[name] = info
    require(zipped.testzip() is None, 'Original ZIP failed its CRC check')
    return entries


def _member(zipped: zipfile.ZipFile, entries: dict, name: str,
            limit: int = 16 * 1024 * 1024) -> bytes:
    info = entries.get(name)
    require(info is not None and not info.is_dir() and info.file_size <= limit,
            'Missing or invalid original ZIP member: ' + name)
    return zipped.read(info)


def _check_manifest(zipped: zipfile.ZipFile, entries: dict, raw: bytes) -> None:
    manifest = json.loads(raw)
    require(isinstance(manifest, list) and bool(manifest), 'Missing original PNG manifest')
    seen = set()
    for row in manifest:
        require(isinstance(row, dict), 'Invalid original PNG manifest entry')
        name = str(_relative(row.get('file')))
        require(name.endswith('.png') and name not in seen and
                type(row.get('bytes')) is int and row['bytes'] > 0 and
                bool(re.fullmatch(r'[a-f0-9]{64}', str(row.get('sha256', '')))),
                'Invalid or duplicate original PNG manifest entry')
        seen.add(name)
        data = _member(zipped, entries, name, 64 * 1024 * 1024)
        require(len(data) == row['bytes'] and hashlib.sha256(data).hexdigest() == row['sha256'],
                'Original PNG differs from its archive manifest: ' + name)


def _destination(root: Path, relative: PurePosixPath) -> Path:
    require(not root.is_symlink(), 'Review root must not be a symlink')
    destination = root
    for component in relative.parts:
        require(not destination.exists() or destination.is_dir(), 'Review parent is not a directory')
        destination = destination / component
        require(not destination.is_symlink(), 'Review output must not pass through a symlink')
    require(not destination.exists() or destination.is_file(), 'Review output is not a regular file')
    return destination


def _pending_file(destination: Path, data: bytes) -> Path:
    with tempfile.NamedTemporaryFile(prefix='.graphics-review-', dir=destination.parent,
                                     delete=False) as pending:
        path = Path(pending.name)
        try:
            pending.write(data)
            pending.flush()
            os.fsync(pending.fileno())
        except BaseException:
            path.unlink(missing_ok=True)
            raise
    return path


def _install(root: Path, outputs: dict[PurePosixPath, bytes], images: set[PurePosixPath]) -> None:
    # Preflight every destination before creating even a parent directory.
    planned = []
    for relative, data in outputs.items():
        destination = _destination(root, relative)
        previous = destination.read_bytes() if destination.exists() else None
        require(relative not in images or previous is None or previous == data,
                'A different original already occupies a content-addressed PNG: ' + str(relative))
        if previous != data:
            planned.append((destination, data, previous))
    pending, installed, created_directories, rollback_errors = [], [], [], []
    try:
        # Prepare all complete replacements and backups on their destination
        # filesystems before changing any existing evidence or receipt.
        for destination, data, previous in planned:
            missing = []
            parent = destination.parent
            while not parent.exists():
                missing.append(parent)
                parent = parent.parent
            for directory in reversed(missing):
                directory.mkdir()
                created_directories.append(directory)
            replacement = _pending_file(destination, data)
            pending.append((destination, replacement, None))
            backup = _pending_file(destination, previous) if previous is not None else None
            pending[-1] = (destination, replacement, backup)
        for destination, replacement, backup in pending:
            os.replace(replacement, destination)
            installed.append((destination, backup))
    except BaseException as error:
        for destination, backup in reversed(installed):
            try:
                if backup is None:
                    destination.unlink(missing_ok=True)
                else:
                    os.replace(backup, destination)
            except OSError as rollback_error:
                rollback_errors.append(str(destination) + ': ' + str(rollback_error))
        if rollback_errors:
            raise OSError('Review rollback incomplete; transaction backups retained: ' +
                          '; '.join(rollback_errors)) from error
        raise
    finally:
        if not rollback_errors:
            for _, replacement, backup in pending:
                replacement.unlink(missing_ok=True)
                if backup is not None:
                    backup.unlink(missing_ok=True)
        for directory in reversed(created_directories):
            if directory.exists() and not any(directory.iterdir()):
                directory.rmdir()


def record_review(root: Path, archives: dict[str, Path], proofs: Path,
                  selection: list, reviewer: str, notes: str) -> dict:
    require(set(archives) == set(ARTIFACT_NAMES), 'All three original graphics ZIPs are required')
    require(isinstance(selection, list) and bool(selection), 'An actually inspected image selection is required')
    raw_proofs = {name: _input_bytes(proofs / name, 8 * 1024 * 1024)
                  for name in (*WORKFLOW_FILES, *(key + '-artifact.json' for key in ARTIFACT_NAMES))}
    workflow = json.loads(raw_proofs['run.json'])
    require(isinstance(workflow, dict), 'Invalid original graphics workflow metadata')
    native = workflow.get('head_sha')
    require(isinstance(native, str) and bool(re.fullmatch(r'[a-f0-9]{40}', native)),
            'Missing exact native graphics source')
    receipt = {
        'schema': 1, 'status': 'approved', 'versionCode': 2019,
        'native_revision': native, 'native_workflow_run_id': workflow.get('id'),
        'reviewed_by': reviewer, 'reviewed_at': datetime.now(timezone.utc).isoformat(),
        'notes': notes, 'workflow_metadata_sha256': {}, 'artifacts': [], 'images': [],
    }
    outputs, image_paths = {}, set()
    evidence = PurePosixPath(*PROOF_DIRECTORY, 'metadata')
    for name in WORKFLOW_FILES:
        data = raw_proofs[name]
        outputs[evidence / name] = data
        receipt['workflow_metadata_sha256'][name] = hashlib.sha256(data).hexdigest()
    with ExitStack() as stack:
        opened, artifact_ids = {}, {}
        for key, expected_name in ARTIFACT_NAMES.items():
            archive = archives[key]
            require(archive.is_file() and not archive.is_symlink(), 'Missing original graphics ZIP: ' + key)
            artifact_bytes = raw_proofs[key + '-artifact.json']
            artifact = json.loads(artifact_bytes)
            digest = sha256_file(archive)
            require(isinstance(artifact, dict) and artifact.get('digest') == 'sha256:' + digest,
                    'Original graphics ZIP digest differs: ' + key)
            zipped = stack.enter_context(zipfile.ZipFile(archive))
            entries = _zip_index(zipped)
            metadata = {name: artifact_bytes if name == 'artifact.json' else _member(zipped, entries, name)
                        for name in (*SOURCE_FILES, *REQUIRED_LOGS[key])}
            _check_manifest(zipped, entries, metadata['image-manifest.json'])
            hashes = {}
            for name, data in metadata.items():
                outputs[evidence / key / name] = data
                hashes[name] = hashlib.sha256(data).hexdigest()
            artifact_ids[key] = artifact.get('id')
            opened[key] = zipped, entries
            receipt['artifacts'].append({'area': key, 'id': artifact.get('id'), 'name': expected_name,
                                         'sha256': digest, 'metadata_sha256': hashes})
        for choice in selection:
            require(isinstance(choice, dict) and set(choice) == {'area', 'artifact_entry', 'findings'},
                    'Selection requires only area, artifact_entry and actual findings')
            area, entry = choice['area'], choice['artifact_entry']
            require(isinstance(area, str) and area in REVIEW_AREAS, 'Unknown reviewed graphics area')
            original = _relative(entry)
            key = AREA_ARTIFACT[area]
            prefix = ('images', area) if key == 'worlds' else ('images',)
            require(original.parts[:len(prefix)] == prefix and original.suffix == '.png',
                    'Only original current graphics PNGs may be selected')
            require(isinstance(choice['findings'], str) and bool(choice['findings'].strip()),
                    'Missing actual image review findings')
            zipped, entries = opened[key]
            data = _member(zipped, entries, entry, 64 * 1024 * 1024)
            digest = hashlib.sha256(data).hexdigest()
            relative = PurePosixPath(*PROOF_DIRECTORY, area, digest + '-' + original.name)
            image_paths.add(relative)
            outputs[relative] = data
            receipt['images'].append({
                'path': str(relative), 'area': area, 'artifact_id': artifact_ids[key],
                'artifact_entry': entry, 'native_revision': native, 'sha256': digest,
                'dimensions': _png_dimensions(data), 'findings': choice['findings'],
            })
        with tempfile.TemporaryDirectory(prefix='lumo-graphics-review-') as temporary:
            staging = Path(temporary)
            for relative, data in outputs.items():
                destination = staging / str(relative)
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(data)
            staged_proofs = staging / 'original-api'
            staged_proofs.mkdir()
            for name, data in raw_proofs.items():
                (staged_proofs / name).write_bytes(data)
            verify_visual_review(staging, receipt, native, staged_proofs)
    # The existing verifier must succeed before any destination is changed.
    # Dict insertion order deliberately commits the complete receipt last.
    outputs[REVIEW_RECEIPT] = (json.dumps(receipt, indent=2, ensure_ascii=False) + '\n').encode('utf-8')
    _install(root, outputs, image_paths)
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--proofs', type=Path, required=True)
    for key in ARTIFACT_NAMES:
        parser.add_argument('--' + key + '-archive', type=Path, required=True)
    parser.add_argument('--selection', type=Path, required=True)
    parser.add_argument('--reviewer', required=True)
    parser.add_argument('--notes', required=True)
    args = parser.parse_args()
    try:
        receipt = record_review(args.root, {key: getattr(args, key + '_archive') for key in ARTIFACT_NAMES},
                                args.proofs, json.loads(_input_bytes(args.selection, 8 * 1024 * 1024)),
                                args.reviewer, args.notes)
    except (OSError, ValueError, RuntimeError, zipfile.BadZipFile) as error:
        parser.exit(1, 'Graphics review not recorded: ' + str(error) + '\n')
    print(json.dumps({'status': receipt['status'], 'native_revision': receipt['native_revision'],
                      'images': len(receipt['images']), 'publication_enabled': False}, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
