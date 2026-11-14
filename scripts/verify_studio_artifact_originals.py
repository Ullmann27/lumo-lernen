#!/usr/bin/env python3
"""Bind three downloaded Studio2020 directories to their original GitHub ZIPs.

Original directories are only read. Each original archive is downloaded once
into its own temporary directory, fully checked and then removed. No archive
is extracted, and neither credentials nor redirect/error-response bodies are
logged. The game/probe acceptance remains the separate C4 publisher's task.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import zipfile

REPOSITORY = 'Ullmann27/lumo-lernen'
WORKFLOW = '.github/workflows/lumo-studio-2020.yml'
NAMES = {
    'api35': 'lumo-studio-2020-android-tour',
    'api37': 'lumo-studio-2020-android-17-tour',
    'runtime': 'lumo-candidate-pinned-native-gameplay',
}
CHUNK_BYTES = 1024 * 1024
DOWNLOAD_SECONDS = 900


class VerificationError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise VerificationError(message)


def sha256(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'Duplicate metadata JSON key')
        result[key] = value
    return result


def invalid_number(_value):
    raise VerificationError('Nonfinite metadata number')


def load_metadata(path: Path) -> dict:
    require(path.is_file() and not path.is_symlink(), 'Missing/nonregular original metadata')
    require(path.stat().st_size <= 32 * 1024 * 1024, 'Oversized metadata')
    value = json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=unique_object,
                       parse_constant=invalid_number)
    require(type(value) is dict, 'Original metadata object required')
    return value


def positive_integer(value):
    return type(value) is int and value > 0


def select_artifacts(metadata: Path, source: str, run_id: int) -> tuple[dict, dict]:
    require(re.fullmatch(r'[a-f0-9]{40}', source) is not None, 'Full source SHA required')
    require(positive_integer(run_id), 'Positive actual run ID required')
    run = load_metadata(metadata / 'run.json')
    collection = load_metadata(metadata / 'artifacts.json')
    require(run.get('id') == run_id and type(run.get('id')) is int
            and run.get('head_sha') == source and run.get('path') == WORKFLOW
            and run.get('repository', {}).get('full_name') == REPOSITORY
            and positive_integer(run.get('run_attempt')), 'Wrong current run/source/workflow/repository')
    artifacts = collection.get('artifacts')
    require(type(artifacts) is list and type(collection.get('total_count')) is int
            and collection['total_count'] == len(artifacts), 'Complete original artifact list required')
    require(all(type(item) is dict for item in artifacts), 'Invalid original artifact entry')
    selected = {}
    for role, name in NAMES.items():
        matching = [item for item in artifacts if item.get('name') == name]
        require(len(matching) == 1, 'Missing or duplicate artifact name: ' + name)
        item = matching[0]
        require(positive_integer(item.get('id')) and positive_integer(item.get('size_in_bytes'))
                and item.get('expired') is False, 'Missing/expired/empty artifact: ' + name)
        digest = item.get('digest')
        require(type(digest) is str and re.fullmatch(r'sha256:[a-f0-9]{64}', digest) is not None,
                'Full original artifact SHA256 required: ' + name)
        origin = item.get('workflow_run', {})
        require(type(origin) is dict and type(origin.get('id')) is int
                and origin['id'] == run_id and origin.get('head_sha') == source,
                'Artifact belongs to another actual source/run: ' + name)
        selected[role] = item
    require(len({item['id'] for item in selected.values()}) == len(NAMES), 'Distinct original artifact IDs required')
    return run, selected


def directory(root: Path) -> Path:
    root = root.absolute()
    for part in (root, *root.parents):
        require(not part.is_symlink() and part.is_dir(), 'Original directory/ancestor must not be a symlink')
    return root


def inventory(root: Path) -> set[str]:
    files = set()
    def failed_walk(_error):
        raise VerificationError('Original artifact directory could not be fully enumerated')
    for parent, directories, filenames in os.walk(root, followlinks=False, onerror=failed_walk):
        for name in directories:
            path = Path(parent) / name
            require(stat.S_ISDIR(path.lstat().st_mode), 'Symlink/non-directory in original artifact directory')
        for name in filenames:
            path = Path(parent) / name
            require(stat.S_ISREG(path.lstat().st_mode), 'Symlink/nonregular original artifact file')
            files.add(path.relative_to(root).as_posix())
    return files


def member_name(info: zipfile.ZipInfo) -> str:
    name = info.filename
    require(info.orig_filename == name and bool(name)
            and not any(ord(character) < 32 or ord(character) == 127 for character in name)
            and '\\' not in name and ':' not in name and not name.startswith('/'),
            'Unsafe original ZIP member path')
    clean = name[:-1] if info.is_dir() else name
    require(clean and all(part not in ('', '.', '..') for part in clean.split('/')),
            'Original ZIP traversal/ambiguous path')
    mode = (info.external_attr >> 16) & 0xFFFF
    kind = stat.S_IFMT(mode)
    expected = stat.S_IFDIR if info.is_dir() else stat.S_IFREG
    require(kind in (0, expected), 'Original ZIP symlink/special/mismatched entry')
    require(not (info.flag_bits & 1), 'Encrypted original ZIP is not a readable artifact')
    return clean


@contextmanager
def original_file(root: Path, name: str):
    """Open each component without following symlinks, including last-minute swaps."""
    descriptors = []
    try:
        current = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        descriptors.append(current)
        parts = name.split('/')
        for part in parts[:-1]:
            current = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=current)
            descriptors.append(current)
        descriptor = os.open(parts[-1], os.O_RDONLY | os.O_NOFOLLOW, dir_fd=current)
        with os.fdopen(descriptor, 'rb') as stream:
            require(stat.S_ISREG(os.fstat(stream.fileno()).st_mode), 'Nonregular original file at comparison time')
            yield stream
    finally:
        for descriptor in reversed(descriptors):
            os.close(descriptor)


def unchanged_stat(value):
    return value.st_dev, value.st_ino, value.st_size, value.st_mtime_ns, value.st_ctime_ns


def compare_archive(archive_path: Path, root: Path, metadata: dict) -> dict:
    root = directory(root)
    require(archive_path.is_file() and not archive_path.is_symlink(), 'Missing regular original ZIP')
    require(archive_path.stat().st_size == metadata['size_in_bytes'], 'Original ZIP size differs from GitHub metadata')
    archive_hash = sha256(archive_path)
    require('sha256:' + archive_hash == metadata['digest'], 'Original ZIP SHA256 differs from GitHub metadata')
    before = inventory(root)
    members = []
    try:
        with zipfile.ZipFile(archive_path) as archive:
            all_names = set()
            files = {}
            for info in archive.infolist():
                name = member_name(info)
                require(name not in all_names, 'Duplicate original ZIP member')
                all_names.add(name)
                if info.is_dir():
                    require(info.file_size == 0, 'Original ZIP directory carries file bytes')
                    # Read even explicit empty directory records to validate their CRC.
                    with archive.open(info) as stream:
                        require(stream.read(1) == b'', 'Unexpected ZIP directory data')
                else:
                    files[name] = info
            require(files, 'Original artifact ZIP contains no files')
            for name in all_names:
                parts = name.split('/')
                require(not any('/'.join(parts[:i]) in files for i in range(1, len(parts))),
                        'Original ZIP file/directory prefix collision')
            require(before == set(files), 'Missing or additional downloaded artifact files')
            for name, info in sorted(files.items()):
                digest = hashlib.sha256()
                size = 0
                mismatch = False
                with archive.open(info) as zipped, original_file(root, name) as actual:
                    initial = os.fstat(actual.fileno())
                    require(initial.st_size == info.file_size, 'Uncompressed original file size differs')
                    while True:
                        data = zipped.read(CHUNK_BYTES)
                        if not data:
                            break
                        digest.update(data)
                        size += len(data)
                        if actual.read(len(data)) != data:
                            mismatch = True
                    require(actual.read(1) == b'' and size == info.file_size and not mismatch,
                            'Uncompressed original file bytes differ')
                    require(unchanged_stat(initial) == unchanged_stat(os.fstat(actual.fileno())),
                            'Original file changed during comparison')
                members.append({'path': name, 'bytes': size, 'sha256': digest.hexdigest()})
    except (zipfile.BadZipFile, zipfile.LargeZipFile, NotImplementedError) as error:
        raise VerificationError('Original ZIP structure/compression/CRC verification failed') from error
    require(inventory(root) == before, 'Original directory inventory changed during comparison')
    canonical = json.dumps(members, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()
    return {'id': metadata['id'], 'name': metadata['name'], 'digest': metadata['digest'],
            'archive_bytes': archive_path.stat().st_size, 'archive_sha256': archive_hash,
            'file_count': len(members), 'uncompressed_bytes': sum(row['bytes'] for row in members),
            'member_manifest_sha256': hashlib.sha256(canonical).hexdigest(),
            'zip_crc': 'PASS', 'every_file_stream_compared': True,
            'original_directory': str(root), 'original_directory_mutated': False}


def download_archive(artifact_id: int, destination: Path):
    command = ['gh', 'api', f'repos/{REPOSITORY}/actions/artifacts/{artifact_id}/zip']
    try:
        with destination.open('xb') as stream:
            completed = subprocess.run(command, stdout=stream, stderr=subprocess.PIPE,
                                       timeout=DOWNLOAD_SECONDS, check=False)
    except subprocess.TimeoutExpired:
        raise VerificationError(f'Original artifact download timed out (artifact {artifact_id})') from None
    except FileNotFoundError:
        raise VerificationError('GitHub CLI is unavailable for original archive download') from None
    # Deliberately never log stderr: it can contain authentication/redirect details.
    require(completed.returncode == 0,
            f'Original artifact download failed (artifact {artifact_id}, exit {completed.returncode})')


def verify(source: str, run_id: int, metadata: Path, roots: dict[str, Path]) -> dict:
    require(set(roots) == set(NAMES), 'Exactly API35/API37/runtime destinations required')
    run, selected = select_artifacts(metadata, source, run_id)
    folders = {key: directory(value) for key, value in roots.items()}
    for role, root in folders.items():
        require(not any(root == other or root in other.parents or other in root.parents
                        for key, other in folders.items() if key != role),
                'Original artifact directories must be distinct and nonoverlapping')
    results = {}
    for role, item in selected.items():
        with tempfile.TemporaryDirectory(prefix='lumo-studio-original-') as temporary:
            path = Path(temporary) / 'original.zip'
            download_archive(item['id'], path)
            results[role] = compare_archive(path, folders[role], item)
        require(not Path(temporary).exists(), 'Temporary original archive was not removed')
        results[role]['temporary_archive_removed'] = True
    return {'schema': 1, 'status': 'PASS', 'source_sha': source, 'build_run': run_id,
            'run_attempt': run['run_attempt'], 'repository': REPOSITORY, 'workflow': WORKFLOW,
            'verified_utc': datetime.now(timezone.utc).isoformat(),
            'metadata_sha256': {name: sha256(metadata/name) for name in ('run.json', 'artifacts.json')},
            'artifacts': results, 'archive_extraction_performed': False,
            'scope': 'Original archive bytes and all downloaded member bytes; gameplay acceptance is separate',
            'verifier_sha256': sha256(Path(__file__))}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-sha', required=True)
    parser.add_argument('--build-run', required=True, type=int)
    for name in ('metadata-dir', 'api35', 'api37', 'runtime', 'out'):
        parser.add_argument('--'+name, required=True, type=Path)
    args = parser.parse_args(argv)
    roots = {role: getattr(args, role) for role in NAMES}
    output = args.out.absolute()
    require(not output.exists() and not output.is_symlink(), 'Refusing to replace original verification evidence')
    require(not any(output.resolve().is_relative_to(directory(root)) for root in roots.values()),
            'Verification output must be outside original artifact directories')
    facts = verify(args.source_sha, args.build_run, args.metadata_dir, roots)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('x', encoding='utf-8') as stream:
        json.dump(facts, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'status': 'PASS', 'source_sha': args.source_sha, 'build_run': args.build_run,
                      'artifacts': {key: {'id': value['id'], 'file_count': value['file_count']}
                                    for key, value in facts['artifacts'].items()}, 'output': str(output)}))
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (VerificationError, OSError, ValueError, KeyError) as error:
        print('Original artifact verification failed: '+str(error), file=sys.stderr)
        raise SystemExit(1) from None
