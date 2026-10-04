#!/usr/bin/env python3
"""Build and install a read-only snapshot helper on the selected API-35 emulator."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile

REMOTE = '/data/local/tmp/lumo-ui-snapshot.jar'


def sha256(path: Path) -> str:
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def check_emulator_identity(serial: str, qemu: str, sdk: str) -> None:
    if not re.fullmatch(r'emulator-[0-9]+', serial) or qemu.strip() != '1' or sdk.strip() != '35':
        raise ValueError('The snapshot helper is restricted to the selected API-35 Android emulator')


def checked_remote_hash(output: str, expected: str) -> None:
    match = re.fullmatch(r'([0-9a-f]{64})[ \t]+'+re.escape(REMOTE), output.strip())
    if not match or match.group(1) != expected:
        raise ValueError('Installed snapshot helper does not match the locally compiled jar')


def build(out: Path, sdk: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    source = Path(__file__).with_name('java')/'LumoUiSnapshot.java'
    jar = out/'lumo-ui-snapshot.jar'
    if jar.exists():
        raise ValueError('Refusing to overwrite a compiled snapshot helper')
    android = sdk/'platforms/android-36/android.jar'
    d8 = sdk/'build-tools/35.0.0/d8'
    if not android.is_file() or not d8.is_file():
        raise ValueError('Android API-36 library and build-tools 35.0.0 are required')
    with tempfile.TemporaryDirectory() as temporary:
        classes = Path(temporary)
        subprocess.run(['javac', '--release', '8', '-d', str(classes), str(source)],
                       check=True, timeout=60)
        subprocess.run([str(d8), '--min-api', '24', '--lib', str(android), '--output', str(jar),
                        str(classes/'LumoUiSnapshot.class')], check=True, timeout=60)
    with zipfile.ZipFile(jar) as archive:
        if archive.testzip() is not None or not archive.read('classes.dex').startswith(b'dex\n'):
            raise ValueError('Compiled snapshot helper is not a valid DEX jar')
    proof = {'jar_sha256': sha256(jar), 'java_source_sha256': sha256(source),
             'scope': 'read-only emulator accessibility, not application code',
             'waits_for_global_idle': False, 'apk_changed': False}
    (out/'live-snapshot-build.json').write_text(json.dumps(proof, indent=2)+'\n')
    print(json.dumps(proof, indent=2))


def install(jar: Path, out: Path, serial: str, adb_binary: str) -> None:
    out.mkdir(parents=True, exist_ok=True)
    def adb(*arguments, timeout=30):
        result = subprocess.run([adb_binary, '-s', serial, *map(str, arguments)],
                                capture_output=True, text=True, timeout=timeout)
        if result.returncode:
            raise RuntimeError(result.stderr+result.stdout)
        return result.stdout
    # Verify the emulator before writing even this isolated test-helper file.
    qemu = adb('shell', 'getprop', 'ro.kernel.qemu')
    sdk = adb('shell', 'getprop', 'ro.build.version.sdk')
    check_emulator_identity(serial, qemu, sdk)
    with zipfile.ZipFile(jar) as archive:
        if archive.testzip() is not None or not archive.read('classes.dex').startswith(b'dex\n'):
            raise ValueError('The supplied snapshot helper is not a valid DEX jar')
    expected = sha256(jar)
    adb('push', str(jar), REMOTE)
    adb('shell', 'chmod', '444', REMOTE)
    checked_remote_hash(adb('shell', 'toybox', 'sha256sum', REMOTE), expected)
    from fresh_ui_hierarchy import read_fresh_hierarchy
    root = read_fresh_hierarchy(adb, out, snapshot_remote=REMOTE)
    import xml.etree.ElementTree as ET
    ET.ElementTree(root).write(out/'live-snapshot-smoke.xml', encoding='utf-8', xml_declaration=True)
    proof = {'serial': serial, 'api': 35, 'qemu': True, 'remote': REMOTE,
             'jar_sha256': expected, 'live_smoke_read_passed': True,
             'root_nodes': len(list(root.iter('node'))), 'apk_changed': False,
             'application_settings_changed': False, 'waits_for_global_idle': False}
    (out/'live-snapshot-installation.json').write_text(json.dumps(proof, indent=2)+'\n')
    print(json.dumps(proof, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('build'); p.add_argument('--out', type=Path, required=True)
    p.add_argument('--sdk', type=Path, default=Path(os.environ.get('ANDROID_HOME', '.')))
    p = sub.add_parser('install'); p.add_argument('--jar', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True); p.add_argument('--serial', default='emulator-5554')
    p.add_argument('--adb', default='adb')
    args = parser.parse_args()
    if args.command == 'build':
        build(args.out, args.sdk)
    else:
        install(args.jar, args.out, args.serial, args.adb)
