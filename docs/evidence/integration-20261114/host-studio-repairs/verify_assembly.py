#!/usr/bin/env python3
"""Verify a standalone evidence archive entirely from its contained bytes."""
from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import tarfile
from datetime import datetime, timezone


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def safe_path(name):
    p = PurePosixPath(name)
    if p.is_absolute() or '..' in p.parts or not p.parts:
        raise ValueError(f'Unsafe archive name: {name}')


def read_tar(data):
    result = {}
    with tarfile.open(fileobj=io.BytesIO(data), mode='r:gz') as tf:
        for member in tf:
            safe_path(member.name)
            if not member.isfile() or member.name in result:
                raise ValueError(f'Duplicate or non-regular member: {member.name}')
            payload = tf.extractfile(member).read()
            if len(payload) != member.size:
                raise ValueError(f'Short archive member: {member.name}')
            result[member.name] = payload
    # Force complete gzip EOF/CRC verification, including possible trailing data.
    gzip.decompress(data)
    return result


def verify(archive):
    archive_bytes = archive.read_bytes()
    outer = read_tar(archive_bytes)
    manifest = json.loads(outer['package-manifest.json'])
    if set(outer) != set(manifest['files']) | {'package-manifest.json'}:
        raise ValueError('Outer archive has missing/unindexed files')
    for name, expected in manifest['files'].items():
        data = outer[name]
        if len(data) != expected['bytes'] or sha256(data) != expected['sha256']:
            raise ValueError(f'Outer byte identity mismatch: {name}')

    objects = json.loads(outer['objects.json'])['objects']
    containers = json.loads(outer['containers.json'])['containers']
    logical = json.loads(outer['index.json'])['files']
    raw_bytes, nested = {}, {}
    for sha, row in objects.items():
        storage = row['storage']
        if storage['kind'] == 'object':
            canonical_name = f'objects/sha256/{sha[:2]}/{sha}'
            if storage['path'] != canonical_name:
                raise ValueError('Noncanonical SHA256 object path')
            data = outer[canonical_name]
            if sha256(data) != sha or len(data) != row['bytes']:
                raise ValueError(f'Content-addressed object mismatch: {sha}')
            raw_bytes[sha] = data
    physical_paths = {r['storage']['path'] for r in objects.values() if r['storage']['kind'] == 'object'}
    if physical_paths != {name for name in outer if name.startswith('objects/')}:
        raise ValueError('Unindexed or missing physical SHA256 object')

    member_count = 0
    for container in containers:
        sha = container['sha256']
        data = raw_bytes[sha]
        if len(data) != container['bytes']:
            raise ValueError('Container size mismatch')
        members = read_tar(data)
        expected = {row['member']: row for row in container['members']}
        if len(expected) != container['member_count'] or set(members) != set(expected):
            raise ValueError('Container membership mismatch')
        for name, row in expected.items():
            content = members[name]
            if sha256(content) != row['sha256'] or len(content) != row['bytes']:
                raise ValueError(f'Original compact member mismatch: {name}')
            index_row = logical[row['logical_path']]
            if index_row['sha256'] != row['sha256'] or index_row['bytes'] != row['bytes']:
                raise ValueError('Compact-member to logical-path mismatch')
            member_count += 1
        nested[sha] = members

    canonical = {}
    for sha, row in objects.items():
        storage = row['storage']
        if storage['kind'] == 'object':
            data = raw_bytes[sha]
        elif storage['kind'] == 'tar-member':
            data = nested[storage['container_sha256']][storage['member']]
        else:
            raise ValueError('Unknown storage kind')
        if sha256(data) != sha or len(data) != row['bytes']:
            raise ValueError('Canonical nested payload mismatch')
        canonical[sha] = data
    for name, row in logical.items():
        safe_path(name)
        data = canonical[row['sha256']]
        if len(data) != row['bytes'] or sha256(data) != row['sha256']:
            raise ValueError(f'Logical mapping failed: {name}')
        for origin in row['origins']:
            if origin['kind'] == 'verified-original-compact-member':
                other = nested[origin['container_sha256']][origin['member']]
                if other != data:
                    raise ValueError('An alternate original compact alias disagrees')

    inputs = json.loads(outer['input-manifest.json'])['files']
    for name, row in inputs.items():
        actual = logical[name]
        if actual['sha256'] != row['sha256'] or actual['bytes'] != row['bytes']:
            raise ValueError('Original input missing or mismatched in logical index')
    handoff = json.loads(outer['handoff.json'])
    if handoff['state'] != 'EVIDENCE_ASSEMBLED_INTEGRATION_ACCEPTANCE_PENDING':
        raise ValueError('Assembly scope changed')
    return {
        'schema': 1, 'verified_at_utc': datetime.now(timezone.utc).isoformat(),
        'archive': {'path': archive.name, 'bytes': len(archive_bytes), 'sha256': sha256(archive_bytes)},
        'full_readback': True,
        'outer_regular_files_verified': len(outer),
        'physical_sha256_objects_verified': len(raw_bytes),
        'unique_content_hashes_verified': len(canonical),
        'original_compact_containers_verified': len(containers),
        'original_compact_members_verified': member_count,
        'logical_path_mappings_verified': len(logical),
        'original_input_bindings_verified': len(inputs),
        'duplicate_names_or_unsafe_paths': 0,
        'unindexed_outer_objects': 0, 'errors': [],
        'index_sha256': sha256(outer['index.json']),
        'handoff_sha256': sha256(outer['handoff.json']),
        'package_manifest_sha256': sha256(outer['package-manifest.json']),
        'source_or_ci_tests_executed': False,
        'meaning': 'PASS for complete archive byte/mapping verification only; original CI/local failures and pending acceptance remain unchanged.'
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.archive)
    text = json.dumps(result, ensure_ascii=False, sort_keys=True, indent=2) + '\n'
    if args.output:
        if args.output.exists():
            raise FileExistsError('Refusing to overwrite an existing verification report')
        args.output.write_text(text)
    print(text, end='')


if __name__ == '__main__':
    main()
