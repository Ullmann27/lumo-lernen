"""Copy unchanged source notices into Android assets and verify APK/AAB bytes."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re

POLICY_PATH = 'config/lumo-notices.json'
ASSET_PREFIX = 'assets/lumo_notices/'
MANIFEST_PATH = ASSET_PREFIX + 'manifest.json'
REQUIRED_SOURCES = frozenset({
    ('host', 'assets/fonts/OFL.txt'),
    ('native', 'assets/fonts/Nunito-LICENSE.txt'),
    ('native', 'assets/characters/lumo_animated/ATTRIBUTION.md'),
    ('native', 'assets/characters/lumo_facial/ATTRIBUTION.md'),
    ('native', 'THIRD_PARTY_NOTICES.md'),
})


def binding(data: bytes) -> dict:
    return {
        'bytes': len(data),
        'sha256': hashlib.sha256(data).hexdigest(),
        'git_blob': hashlib.sha1(
            b'blob ' + str(len(data)).encode('ascii') + b'\0' + data).hexdigest(),
    }


def policy_entries(raw: bytes) -> list[dict]:
    """The committed policy may bind these five originals, never omit one."""
    policy = json.loads(raw)
    if not isinstance(policy, dict) or set(policy) != {'schema', 'notices'}:
        raise RuntimeError('Invalid packaged-notice policy fields')
    if type(policy['schema']) is not int or policy['schema'] != 1:
        raise RuntimeError('Unsupported packaged-notice policy schema')
    entries = policy['notices']
    if not isinstance(entries, list) or len(entries) != len(REQUIRED_SOURCES):
        raise RuntimeError('Packaged-notice policy must contain all five originals')
    seen = set()
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {
                'source', 'path', 'bytes', 'sha256', 'git_blob'}:
            raise RuntimeError('Invalid packaged-notice entry fields')
        source, path = entry['source'], entry['path']
        if not isinstance(source, str) or not isinstance(path, str):
            raise RuntimeError('Invalid packaged-notice source path')
        key = (source, path)
        if key not in REQUIRED_SOURCES or key in seen:
            raise RuntimeError('Missing, duplicate or unexpected original notice source')
        seen.add(key)
        if (type(entry['bytes']) is not int or not 0 < entry['bytes'] <= 1_000_000
                or not isinstance(entry['sha256'], str)
                or not re.fullmatch(r'[0-9a-f]{64}', entry['sha256'])
                or not isinstance(entry['git_blob'], str)
                or not re.fullmatch(r'[0-9a-f]{40}', entry['git_blob'])):
            raise RuntimeError('Invalid packaged-notice source identity')
    if seen != REQUIRED_SOURCES:
        raise RuntimeError('Original notice source inventory is incomplete')
    return sorted(entries, key=lambda entry: (entry['source'], entry['path']))


def expected_manifest(policy: bytes, native_source: dict) -> dict:
    if (not isinstance(native_source, dict)
            or not isinstance(native_source.get('repository'), str)
            or not native_source['repository']
            or not isinstance(native_source.get('revision'), str)
            or not re.fullmatch(r'[0-9a-f]{40}', native_source['revision'])):
        raise RuntimeError('Packaged notices require an immutable native source identity')
    entries = policy_entries(policy)
    return {
        'schema': 1,
        'policy_sha256': hashlib.sha256(policy).hexdigest(),
        'native_source': native_source,
        'notices': [
            {**entry, 'entry': ASSET_PREFIX + entry['source'] + '/' + entry['path']}
            for entry in entries
        ],
    }


def manifest_bytes(manifest: dict) -> bytes:
    return (json.dumps(manifest, indent=2, sort_keys=True) + '\n').encode('utf-8')


def bundle_notices(root: Path, native: Path) -> dict:
    """Called only after export has verified the clean, pinned native checkout."""
    policy = (root / POLICY_PATH).read_bytes()
    native_source = json.loads((root / 'config/godot-source.json').read_bytes())
    manifest = expected_manifest(policy, native_source)
    payloads = {}
    for entry in manifest['notices']:
        source_root = root if entry['source'] == 'host' else native
        source = source_root / entry['path']
        if source.is_symlink() or not source.is_file():
            raise RuntimeError('Missing or unsafe original notice: ' + entry['path'])
        data = source.read_bytes()
        if binding(data) != {key: entry[key] for key in ('bytes', 'sha256', 'git_blob')}:
            raise RuntimeError('Original notice bytes differ from the committed policy: '
                               + entry['path'])
        payloads[entry['entry'].removeprefix(ASSET_PREFIX)] = data
    payloads['manifest.json'] = manifest_bytes(manifest)
    target = root / 'android/app/src/main/assets/lumo_notices'
    if target.is_symlink() or (target.exists() and not target.is_dir()):
        raise RuntimeError('Packaged-notice output must be a regular directory')
    if target.exists():
        for path in target.rglob('*'):
            relative = path.relative_to(target).as_posix()
            if (path.is_symlink() or (not path.is_dir() and
                                     (not path.is_file() or relative not in payloads))):
                raise RuntimeError('Unexpected existing packaged-notice output: ' + relative)
    for relative, data in payloads.items():
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
    return manifest


def validate_packaged_notices(archive, policy: bytes, native_source: dict) -> dict:
    """Require exact outer-package assets; does not claim PCK contents or rights."""
    expected = expected_manifest(policy, native_source)
    names = archive.namelist()
    expected_names = {MANIFEST_PATH, *(entry['entry'] for entry in expected['notices'])}
    notice_names = {name for name in names if name.startswith(ASSET_PREFIX)
                    and not name.endswith('/')}
    if notice_names != expected_names:
        raise RuntimeError('Packaged-notice asset inventory differs from source policy')

    def payload(name: str) -> bytes:
        if names.count(name) != 1:
            raise RuntimeError('Missing or duplicated packaged notice: ' + name)
        return archive.read(name)

    if payload(MANIFEST_PATH) != manifest_bytes(expected):
        raise RuntimeError('Packaged-notice manifest, policy or native source differs')
    for entry in expected['notices']:
        if binding(payload(entry['entry'])) != {
                key: entry[key] for key in ('bytes', 'sha256', 'git_blob')}:
            raise RuntimeError('Packaged original notice missing or changed: ' + entry['entry'])
    return {
        'status': 'verified',
        'policySha256': expected['policy_sha256'],
        'nativeRevision': native_source['revision'],
        'files': expected['notices'],
        'scope': 'Exact original outer-package assets; no rights or PCK-content approval',
    }
