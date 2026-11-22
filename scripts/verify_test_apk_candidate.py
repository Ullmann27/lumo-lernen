#!/usr/bin/env python3
"""Bind a test-APK request and both verified ABI packages to one candidate.

The existing verify_unified_apk.py remains responsible for Android signatures,
manifest, libraries and voice assets. This gate additionally rejects mixed
builds and extracts the PCK from the actual ARM64 APK for the runtime probe.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import zipfile


PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
APK_NAME = 'Lumo-Lernen-Neu.apk'


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def source_identity(root: Path, expected_commit: str | None = None) -> dict:
    root = root.resolve()
    commit = subprocess.check_output(
        ['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip()
    require(bool(re.fullmatch(r'[0-9a-f]{40}', commit)), 'Invalid Flutter commit')
    if expected_commit is not None:
        require(commit == expected_commit, 'Checkout differs from the requested Flutter commit')
    dirty = subprocess.check_output(
        ['git', '-C', str(root), 'status', '--porcelain', '--untracked-files=no'],
        text=True).strip()
    require(not dirty, 'Tracked candidate sources have uncommitted changes')
    version = re.search(r'^version:\s*([^\s+]+)\+([1-9][0-9]*)\s*$',
                        (root / 'pubspec.yaml').read_text(), re.MULTILINE)
    require(version is not None, 'pubspec.yaml must declare version: name+build')
    version_name, version_code = version.group(1), int(version.group(2))
    requested = json.loads((root / 'config/test-apk-request.json').read_text())
    require(requested.get('version') == f'{version_name}+{version_code}',
            'Test-APK request version differs from pubspec.yaml')
    godot = json.loads((root / 'config/godot-source.json').read_text())
    require(godot.get('repository') == 'https://github.com/Ullmann27/lumo-godot.git',
            'Unexpected Godot source repository')
    require(bool(re.fullmatch(r'[0-9a-f]{40}', godot.get('revision', ''))),
            'Godot source must be pinned to a full commit SHA')
    require(godot.get('engine') == '4.6.3', 'Unexpected Godot engine for this build pipeline')
    return {'flutter_source_commit': commit, 'versionName': version_name,
            'versionCode': version_code, 'godot': godot}


def package_identity(directory: Path, abi: str, expected: dict) -> dict:
    apk = directory / APK_NAME
    provenance = json.loads((directory / 'BUILD-PROVENANCE.json').read_text())
    verified = json.loads((directory / 'APK-VERIFICATION.json').read_text())
    for key, value in verified.items():
        require(provenance.get(key) == value,
                f'{abi}: provenance differs from the APK verification for {key}')
    require(provenance.get('package') == PACKAGE, f'{abi}: wrong Android package')
    require(provenance.get('abis') == [abi], f'{abi}: wrong or mixed native architectures')
    require(provenance.get('tracked_source_clean') is True, f'{abi}: source was not clean')
    for key in ('flutter_source_commit', 'versionName', 'versionCode'):
        require(provenance.get(key) == expected[key], f'{abi}: candidate {key} mismatch')
    require(type(provenance.get('versionCode')) is int, f'{abi}: invalid versionCode')
    require(provenance.get('minSdk') == 24 and provenance.get('targetSdk') == 36,
            f'{abi}: unexpected Android SDK levels')
    for key in ('elf16KiBAligned', 'resourcesArscAligned'):
        require(provenance.get(key) is True, f'{abi}: missing {key} verification')
    certificate = provenance.get('signingCertificateSha256', '')
    require(bool(re.fullmatch(r'[0-9a-f]{64}', certificate)),
            f'{abi}: missing signing certificate verification')
    with apk.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    require(provenance.get('sha256') == digest, f'{abi}: actual APK digest mismatch')
    require(provenance.get('bytes') == apk.stat().st_size, f'{abi}: actual APK size mismatch')
    sums = [line.split() for line in (directory / 'SHA256SUMS.txt').read_text().splitlines()
            if line.strip()]
    require(sums == [[digest, APK_NAME]], f'{abi}: SHA256SUMS does not name this exact APK')
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        for name in ('assets/lumo_game.pck', 'assets/lumo_game_source.json'):
            require(names.count(name) == 1, f'{abi}: missing or duplicated {name}')
        actual_abis = {name.split('/')[1] for name in names
                       if name.startswith('lib/') and name.endswith('.so')}
        require(actual_abis == {abi}, f'{abi}: actual APK native architectures mismatch')
        with archive.open('assets/lumo_game_source.json') as stream:
            packaged_godot = json.load(stream)
        require(packaged_godot == provenance.get('godot'),
                f'{abi}: packaged Godot provenance differs from build provenance')
        for key, value in expected['godot'].items():
            require(packaged_godot.get(key) == value, f'{abi}: Godot {key} mismatch')
        with archive.open('assets/lumo_game.pck') as stream:
            pck_digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        require(packaged_godot.get('pck_sha256') == pck_digest,
                f'{abi}: packaged PCK digest mismatch')
        pck_bytes = archive.getinfo('assets/lumo_game.pck').file_size
        require(packaged_godot.get('bytes') == pck_bytes, f'{abi}: packaged PCK size mismatch')
    return {'abi': abi, 'sha256': digest, 'bytes': apk.stat().st_size,
            'signingCertificateSha256': certificate, 'godot_pck_sha256': pck_digest,
            'godot_pck_bytes': pck_bytes}


def verify_pair(root: Path, arm64_directory: Path, emulator_directory: Path,
                expected_commit: str | None = None, extract_pck: Path | None = None) -> dict:
    expected = source_identity(root, expected_commit)
    arm64 = package_identity(arm64_directory, 'arm64-v8a', expected)
    emulator = package_identity(emulator_directory, 'x86_64', expected)
    for key in ('signingCertificateSha256', 'godot_pck_sha256', 'godot_pck_bytes'):
        require(arm64[key] == emulator[key], f'ARM64/emulator {key} mismatch')
    if extract_pck is not None:
        extract_pck.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(arm64_directory / APK_NAME) as archive:
            with archive.open('assets/lumo_game.pck') as stream, extract_pck.open('wb') as out:
                shutil.copyfileobj(stream, out)
        with extract_pck.open('rb') as stream:
            require(hashlib.file_digest(stream, 'sha256').hexdigest() == arm64['godot_pck_sha256'],
                    'Extracted ARM64 PCK digest mismatch')
    return {**expected, 'packages': {'arm64-v8a': arm64, 'x86_64': emulator},
            'same_pck': True,
            'runtime_scope': 'The Android tour executes the x86_64 package in an emulator; '
                             'this identity check is not a physical ARM64 device test.'}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('source', 'packages'))
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--expected-commit')
    parser.add_argument('--arm64-directory', type=Path, default=Path('dist'))
    parser.add_argument('--emulator-directory', type=Path, default=Path('dist/x86_64'))
    parser.add_argument('--extract-pck', type=Path)
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    if args.mode == 'source':
        if args.extract_pck is not None:
            parser.error('--extract-pck requires packages mode')
        result = source_identity(args.root, args.expected_commit)
    else:
        result = verify_pair(args.root, args.arm64_directory, args.emulator_directory,
                             args.expected_commit, args.extract_pck)
    encoded = json.dumps(result, indent=2) + '\n'
    if args.out is not None:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(encoded)
    print(encoded, end='')


if __name__ == '__main__':
    main()
