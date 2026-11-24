#!/usr/bin/env python3
"""Verify both frozen parts and atomically recreate the original evidence archive."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile

EXPECTED = {
    'path': 'host-studio-integration-evidence.tar.gz',
    'bytes': 16935599,
    'sha256': 'df58f8725f38135f8bdc594850365474033b9fdcd8c338362a8abd807422ec60',
    'git_blob': '801fe04f32dc80c5fee6cdfd479ad4ad06e82b78',
}
PART_LENGTHS = (8467800, 8467799)
CHUNK = 1024 * 1024


def regular_file(path):
    if not stat.S_ISREG(path.lstat().st_mode):
        raise ValueError(f'Refusing a symlink or non-regular file: {path}')


def hashes(path):
    regular_file(path)
    size = path.stat().st_size
    sha = hashlib.sha256()
    blob = hashlib.sha1(b'blob ' + str(size).encode('ascii') + b'\0')
    actual = 0
    with path.open('rb') as source:
        while data := source.read(CHUNK):
            actual += len(data)
            sha.update(data)
            blob.update(data)
    if actual != size:
        raise ValueError(f'File changed while reading: {path}')
    return {'bytes': actual, 'sha256': sha.hexdigest(), 'git_blob': blob.hexdigest()}


def expected_identity(row):
    return {key: row[key] for key in ('bytes', 'sha256', 'git_blob')}


def verify_existing(path):
    if hashes(path) != expected_identity(EXPECTED):
        raise ValueError(f'Existing target differs; it was not overwritten: {path}')


def load_manifest(folder):
    path = folder / 'transport-manifest.json'
    regular_file(path)
    manifest = json.loads(path.read_bytes())
    if manifest.get('schema') != 1 or manifest.get('archive') != EXPECTED:
        raise ValueError('Manifest does not identify the exact frozen archive')
    parts = manifest.get('parts')
    if not isinstance(parts, list) or len(parts) != 2:
        raise ValueError('Exactly two ordered parts are required')
    offset = 0
    for index, (part, length) in enumerate(zip(parts, PART_LENGTHS), start=1):
        name = EXPECTED['path'] + f'.part-{index:02d}'
        if (not isinstance(part, dict) or part.get('path') != name or
                type(part.get('bytes')) is not int or part['bytes'] != length or
                type(part.get('offset')) is not int or part['offset'] != offset or
                not re.fullmatch(r'[0-9a-f]{64}', str(part.get('sha256', ''))) or
                not re.fullmatch(r'[0-9a-f]{40}', str(part.get('git_blob', '')))):
            raise ValueError(f'Invalid exact part contract: {index}')
        offset += length
    if offset != EXPECTED['bytes']:
        raise ValueError('Part lengths do not match the original archive')
    return parts


def join_verified(folder, parts, output=None):
    total_sha = hashlib.sha256()
    total_blob = hashlib.sha1(b'blob ' + str(EXPECTED['bytes']).encode('ascii') + b'\0')
    total_bytes = 0
    for part in parts:
        path = folder / part['path']
        regular_file(path)
        if path.stat().st_size != part['bytes']:
            raise ValueError(f'Wrong part length: {path}')
        sha = hashlib.sha256()
        blob = hashlib.sha1(b'blob ' + str(part['bytes']).encode('ascii') + b'\0')
        size = 0
        with path.open('rb') as source:
            while data := source.read(CHUNK):
                size += len(data)
                total_bytes += len(data)
                sha.update(data)
                blob.update(data)
                total_sha.update(data)
                total_blob.update(data)
                if output is not None:
                    output.write(data)
        actual = {'bytes': size, 'sha256': sha.hexdigest(), 'git_blob': blob.hexdigest()}
        if actual != expected_identity(part):
            raise ValueError(f'Part content differs: {path}')
    actual = {'bytes': total_bytes, 'sha256': total_sha.hexdigest(), 'git_blob': total_blob.hexdigest()}
    if actual != expected_identity(EXPECTED):
        raise ValueError('Concatenated bytes differ from the frozen archive')


def reassemble(folder, destination):
    parts = load_manifest(folder)
    destination = destination.absolute()
    if not destination.parent.is_dir():
        raise ValueError('The output parent directory must already exist')
    if os.path.lexists(destination):
        verify_existing(destination)
        join_verified(folder, parts)
        return 'EXISTING_TARGET_VERIFIED'
    descriptor, temporary = tempfile.mkstemp(prefix='.' + destination.name + '.',
                                             suffix='.assembling', dir=destination.parent)
    temporary_path = Path(temporary)
    try:
        with os.fdopen(descriptor, 'wb') as output:
            join_verified(folder, parts, output)
            output.flush()
            os.fsync(output.fileno())
        # A hard-link publishes the complete verified file atomically and refuses
        # to replace anything created by another process in the meantime.
        try:
            os.link(temporary_path, destination)
            state = 'CREATED_ATOMICALLY'
        except FileExistsError:
            verify_existing(destination)
            state = 'CONCURRENT_EXISTING_TARGET_VERIFIED'
        directory_fd = os.open(destination.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
        return state
    finally:
        temporary_path.unlink(missing_ok=True)


def main():
    folder = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=folder / EXPECTED['path'],
                        help='Output file; an existing parent directory is required')
    args = parser.parse_args()
    try:
        state = reassemble(folder, args.output)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f'Reassembly failed: {error}', file=sys.stderr)
        return 1
    print(json.dumps({'state': state, 'output': str(args.output.absolute()), **EXPECTED}, sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
