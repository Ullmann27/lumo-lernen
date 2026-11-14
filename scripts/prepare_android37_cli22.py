#!/usr/bin/env python3
"""Compare a real original-tools AVD with the official, fixed CLI22 installation.

The original tools and their unbooted AVD stay on disk. Only the canonical SDK
tools link changes. No generated target, image, GPU or partition value is edited.
The action creates its own new AVD; the strict framework guard verifies that AVD
and the actual installed tools independently of the action's advisory pre-hook.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import signal
import stat
import subprocess
import tempfile
import time
import zipfile
import xml.etree.ElementTree as ET

TOOLS_URL = 'https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip'
TOOLS_SHA256 = '4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583'
ACTION_REVISION = 'a421e43855164a8197daf9d8d40fe71c6996bb0d'
MANAGER_SHA256 = 'a63db8fe9ffb4fb3651e9a2c97f8bac5ca4ce0078a7bbe61ef2e02019082c577'
IMAGE_PACKAGE = 'system-images;android-37.0;google_apis;x86_64'
IMAGE_RELATIVE = 'system-images/android-37.0/google_apis/x86_64'
EXPECTED_TARGET = 'android-37.0'
EXPECTED_EMULATOR = '37.2.13'
EXPECTED_IMAGE_REVISION = '8'


def digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n')


def properties(path: Path) -> dict:
    values = {}
    for line in path.read_text().splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            key, value = line.split('=', 1)
            values[key.strip()] = value.strip()
    return values


class Commands:
    def __init__(self, out: Path):
        self.out, self.counter = out, 0

    def run(self, name: str, argv: list[str], *, environment=None, stdin=None, timeout=180) -> str:
        self.counter += 1
        directory = self.out / 'commands' / f'{self.counter:02d}-{name}'
        directory.mkdir(parents=True, exist_ok=False)
        overrides = environment or {}
        record = {'argv': argv, 'environment_overrides': overrides, 'timeout_seconds': timeout,
                  'started_at': datetime.now(timezone.utc).isoformat()}
        started = time.monotonic()
        with (directory / 'stdout').open('wb') as stdout, (directory / 'stderr').open('wb') as stderr:
            process = subprocess.Popen(argv, stdin=subprocess.PIPE if stdin is not None else subprocess.DEVNULL,
                                       stdout=stdout, stderr=stderr, env={**os.environ, **overrides},
                                       start_new_session=True)
            timed_out = False
            try:
                process.communicate(input=stdin, timeout=timeout)
            except subprocess.TimeoutExpired:
                timed_out = True
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.communicate()
        record.update(returncode=process.returncode, timed_out=timed_out,
                      elapsed_seconds=time.monotonic() - started)
        write_json(directory / 'result.json', record)
        if process.returncode or timed_out:
            raise RuntimeError(f'Command failed; original diagnostics: {directory}')
        return (directory / 'stdout').read_text(errors='replace').strip()


def file_record(path: Path) -> dict:
    info = path.stat()
    return {'path': str(path), 'bytes': info.st_size, 'sha256': digest(path)}


def tools_manifest(folder: Path) -> dict:
    if folder.is_symlink() or not folder.is_dir():
        raise ValueError('Installed command-line tools must be a real directory')
    files = {}
    for path in sorted(folder.rglob('*')):
        if path.is_symlink():
            raise ValueError('Unexpected symlink within official command-line tools')
        if path.is_file():
            files[str(path.relative_to(folder))] = {'bytes': path.stat().st_size, 'sha256': digest(path)}
    if not all(name in files for name in ('source.properties', 'bin/sdkmanager', 'bin/avdmanager')):
        raise ValueError('Incomplete official command-line tools')
    return files


def require_official_tools(folder: Path, expected: dict) -> dict:
    actual = tools_manifest(folder)
    # sdkmanager may register this already verified ZIP installation by adding
    # package.xml. It is SDK metadata, not a replacement for any archive byte.
    extra = set(actual) - set(expected)
    if extra - {'package.xml'} or any(actual.get(name) != info for name, info in expected.items()):
        raise ValueError('Actual canonical command-line tool bytes changed')
    return actual


def snapshot_avd(out: Path, name: str, avd_home: Path) -> dict:
    if not re.fullmatch(r'[A-Za-z0-9_-]+', name):
        raise ValueError('Invalid AVD name')
    out.mkdir(parents=True, exist_ok=False)
    pointer = avd_home / (name + '.ini')
    raw = pointer.read_bytes()
    (out / 'avd.ini').write_bytes(raw)
    pointer_values = properties(pointer)
    folder = Path(pointer_values['path']).resolve(strict=True)
    expected = (avd_home / (name + '.avd')).resolve(strict=True)
    if folder != expected or not folder.is_dir():
        raise ValueError('Actual AVD pointer does not select the observed private AVD')
    records = []
    for path in sorted(folder.rglob('*')):
        if path.is_symlink():
            records.append({'path': str(path.relative_to(folder)), 'symlink': os.readlink(path)})
            continue
        if not path.is_file():
            continue
        info = path.stat()
        item = {'path': str(path.relative_to(folder)), 'bytes': info.st_size,
                'allocated_bytes': info.st_blocks * 512}
        if path.suffix in ('.ini', '.properties', '.xml', '.txt'):
            data = path.read_bytes()
            copied = out / 'configuration' / path.relative_to(folder)
            copied.parent.mkdir(parents=True, exist_ok=True)
            copied.write_bytes(data)
            item['sha256'] = hashlib.sha256(data).hexdigest()
            item['copied'] = str(copied.relative_to(out))
        records.append(item)
    config = properties(folder / 'config.ini')
    result = {'avd_name': name, 'avd_home': str(avd_home), 'avd_directory': str(folder),
              'pointer_sha256': hashlib.sha256(raw).hexdigest(), 'pointer': pointer_values,
              'configuration': config, 'files': records,
              'scope': 'Configuration bytes copied verbatim; unmodified AVD disk files remain on the runner, with apparent and allocated sizes recorded. No AVD disk image is uploaded.'}
    write_json(out / 'snapshot.json', result)
    return result


def installed_package(path: Path, expected_path: str) -> dict:
    """Read the installed SDK descriptor; bundled properties are separate data."""
    def name(element):
        return element.tag.rsplit('}', 1)[-1]

    packages = [element for element in ET.parse(path).getroot() if name(element) == 'localPackage']
    if len(packages) != 1 or packages[0].get('path') != expected_path:
        raise ValueError('Installed SDK descriptor must identify exactly the expected localPackage: ' + expected_path)
    revisions = [element for element in packages[0] if name(element) == 'revision']
    if len(revisions) != 1:
        raise ValueError('Installed SDK descriptor needs exactly one package revision')
    revision = dict.fromkeys(('major', 'minor', 'micro', 'preview'), 0)
    seen = set()
    for element in revisions[0]:
        field, value = name(element), (element.text or '').strip()
        if field not in revision or field in seen or len(element) or not re.fullmatch(r'[0-9]+', value):
            raise ValueError('Malformed installed SDK package revision')
        revision[field] = int(value)
        seen.add(field)
    if 'major' not in seen:
        raise ValueError('Installed SDK package revision has no major component')
    return {'path': packages[0].get('path'), 'revision': revision}


def package_records(sdk: Path, destination: Path, *, enforce_versions=True) -> dict:
    destination.mkdir(parents=True, exist_ok=False)
    records = {}
    for label, relative in (('platform', 'platforms/android-37.0'), ('image', IMAGE_RELATIVE),
                            ('emulator', 'emulator'), ('platform-tools', 'platform-tools')):
        directory = sdk / relative
        entry = {'path': str(directory), 'properties': properties(directory / 'source.properties'), 'files': {}}
        for name in ('source.properties', 'package.xml'):
            path = directory / name
            if path.is_file():
                copied = destination / label / name
                copied.parent.mkdir(parents=True, exist_ok=True)
                copied.write_bytes(path.read_bytes())
                entry['files'][name] = file_record(path)
        records[label] = entry
    # Preserve every original raw descriptor/property file before validation.
    # The r08 image actually bundles Pkg.Revision=7; package.xml identifies the
    # installed package revision8. Neither original field is rewritten.
    write_json(destination / 'packages.json', records)
    for label, package in (('platform', 'platforms;android-37.0'), ('image', IMAGE_PACKAGE),
                           ('emulator', 'emulator'), ('platform-tools', 'platform-tools')):
        records[label]['installed_package'] = installed_package(destination / label / 'package.xml', package)
    write_json(destination / 'packages.json', records)
    if enforce_versions and records['emulator']['properties'].get('Pkg.Revision') != EXPECTED_EMULATOR:
        raise ValueError('Actual emulator revision differs from the observed failing run; refuse a second configuration change')
    if enforce_versions and records['image']['installed_package']['revision'] != {
            'major': int(EXPECTED_IMAGE_REVISION), 'minor': 0, 'micro': 0, 'preview': 0}:
        raise ValueError('Actual installed image package revision differs from the observed failing run')
    return records


def extract_verified_tools(archive: Path, destination: Path) -> Path:
    if digest(archive) != TOOLS_SHA256:
        raise ValueError('Official CLI22 ZIP SHA256 mismatch; no downloaded tool executed')
    with zipfile.ZipFile(archive) as zipped:
        for entry in zipped.infolist():
            path = PurePosixPath(entry.filename)
            if path.is_absolute() or '..' in path.parts or not path.parts or path.parts[0] != 'cmdline-tools':
                raise ValueError('Unsafe official-tools archive member')
            if stat.S_ISLNK(entry.external_attr >> 16):
                raise ValueError('Unexpected link in official-tools archive')
        zipped.extractall(destination)
        for entry in zipped.infolist():
            path = destination / entry.filename
            if path.is_file():
                path.chmod((entry.external_attr >> 16) & 0o777 or 0o644)
    tools = destination / 'cmdline-tools'
    if properties(tools / 'source.properties').get('Pkg.Revision') != '22.0':
        raise ValueError('Verified archive does not identify CLI22.0')
    if not all(os.access(tools / 'bin' / binary, os.X_OK) for binary in ('sdkmanager', 'avdmanager')):
        raise ValueError('Official tools are not executable')
    return tools


def prepare(out: Path, sdk: Path, action: Path) -> dict:
    if (out / 'prepared.json').exists():
        raise ValueError('Refusing to replace the original CLI/AVD comparison')
    out.mkdir(parents=True, exist_ok=True)
    commands = Commands(out)
    latest = sdk / 'cmdline-tools/latest'
    original = latest.resolve(strict=True)
    source_sha = subprocess.check_output(['git', '--no-replace-objects', 'rev-parse', 'HEAD'], text=True).strip()
    if subprocess.check_output(['git', '--no-replace-objects', '-C', str(action), 'rev-parse', 'HEAD'], text=True).strip() != ACTION_REVISION:
        raise ValueError('Original AVD must use the exact reviewed upstream action')
    manager = action / 'lib/emulator-manager.js'
    if digest(manager) != MANAGER_SHA256:
        raise ValueError('Run CLI setup before the additive action patch; original createAvd bytes required')
    original_files = tools_manifest(original)
    write_json(out / 'original-tools.json', {'canonical_path': str(latest), 'resolved_path': str(original),
               'properties': properties(original / 'source.properties'), 'files': original_files})
    (out / 'original-source.properties').write_bytes((original / 'source.properties').read_bytes())
    commands.run('original-cli-version', [str(original / 'bin/sdkmanager'), '--version'])
    commands.run('install-same-sdk-packages', [str(original / 'bin/sdkmanager'), '--sdk_root=' + str(sdk),
                 '--install', 'platform-tools', 'emulator', 'platforms;android-37.0', IMAGE_PACKAGE, '--channel=0'],
                 stdin=b'y\n' * 100, timeout=600)
    packages = package_records(sdk, out / 'packages-original')
    commands.run('original-emulator-version', [str(sdk / 'emulator/emulator'), '-version'])
    temporary = Path(tempfile.mkdtemp(prefix='lumo-cli-avd-comparison-', dir=os.environ.get('RUNNER_TEMP')))
    original_avd_home = temporary / 'original-avd'
    original_avd_home.mkdir()
    # Execute the pinned action's actual AVD creator, including its original
    # CPU/RAM/heap appends. No target or partition entry is repaired here.
    node = ('const m=require(process.argv[1]);'
            'm.createAvd("x86_64","lumo_original_cli","2","",false,true,"512M","pixel_5","4096M","","37.0","google_apis")'
            '.catch(e=>{console.error(e);process.exit(1)});')
    commands.run('original-real-avd', ['node', '-e', node, str(manager)],
                 environment={'ANDROID_HOME': str(sdk), 'ANDROID_SDK_ROOT': str(sdk),
                              'ANDROID_AVD_HOME': str(original_avd_home),
                              'PATH': str(original / 'bin') + os.pathsep + os.environ['PATH']})
    original_avd = snapshot_avd(out / 'avd-original', 'lumo_original_cli', original_avd_home)
    archive = temporary / 'commandlinetools-linux-15859902.zip'
    commands.run('download-official-cli22', ['curl', '--fail', '--location', '--retry', '3',
                 TOOLS_URL, '--output', str(archive)], timeout=300)
    unpacked = extract_verified_tools(archive, temporary / 'verified-unpacked')
    official_files = tools_manifest(unpacked)
    installed = sdk / 'cmdline-tools/22.0'
    if installed.exists() or installed.is_symlink():
        require_official_tools(installed, official_files)
    else:
        shutil.move(str(unpacked), str(installed))
    preserved = sdk / 'cmdline-tools/lumo-original-latest'
    if preserved.exists() or preserved.is_symlink():
        raise ValueError('Original latest preservation path already exists')
    latest.rename(preserved)
    latest.symlink_to('22.0', target_is_directory=True)
    require_official_tools(latest.resolve(strict=True), official_files)
    version = commands.run('installed-cli22-version', [str(latest / 'bin/sdkmanager'), '--version'])
    if version != '22.0':
        raise ValueError('Actually executed SDK manager is not CLI22.0')
    result = {'schema': 1, 'status': 'OFFICIAL_CLI22_INSTALLED_AVD_AND_ANDROID_NOT_YET_APPROVED',
              'source_commit': source_sha, 'sdk_root': str(sdk), 'tools_url': TOOLS_URL,
              'tools_zip_sha256': digest(archive), 'canonical_tools': str(latest),
              'installed_tools': str(installed), 'installed_tools_files': official_files,
              'original_tools_preserved_at': str(preserved), 'original_tools_files': original_files,
              'original_avd_directory': original_avd['avd_directory'], 'packages': packages,
              'action_revision': ACTION_REVISION, 'action_manager_sha256': MANAGER_SHA256,
              'expected_actual_avd_name': 'test', 'expected_target': EXPECTED_TARGET,
              'expected_image_directory': str((sdk / IMAGE_RELATIVE).resolve()),
              'configuration_changes': ['Official SHA256-pinned CLI22 at canonical cmdline-tools/latest'],
              'unchanged': ['API37.0', 'google_apis x86_64 installed package revision8', 'emulator37.2.13',
                            'requested pixel_5', 'requested 2 cores', 'requested 4096M RAM',
                            'requested 512M heap', 'original partition defaults',
                            'framework identity-change rejection', 'original APK and tour gates'],
              'runtime_configuration_scope': (
                  'This preparation does not observe the running GPU or effective VM heap. '
                  'The invoking workflow declares the renderer; original emulator startup logs '
                  'and generated hardware-qemu.ini must establish the actual runtime values. '
                  'Both image package.xml and source.properties remain separate original evidence.')}
    write_json(out / 'prepared.json', result)
    return result


def observe_current_avd(out: Path, phase: str, avd_home: Path | None = None) -> dict:
    if not re.fullmatch(r'[a-z-]+', phase):
        raise ValueError('Invalid observation phase')
    binding = json.loads((out / 'prepared.json').read_text())
    sdk = Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT']).resolve(strict=True)
    home = avd_home or Path(os.environ.get('ANDROID_AVD_HOME', str(Path.home() / '.android/avd')))
    observation = snapshot_avd(out / ('avd-' + phase), binding['expected_actual_avd_name'], home.resolve())
    observation['packages'] = package_records(sdk, out / ('packages-' + phase), enforce_versions=False)
    observation['status'] = 'OBSERVED_ONLY_NO_FRAMEWORK_OR_APP_APPROVAL'
    write_json(out / ('observed-' + phase + '.json'), observation)
    return observation


def memory_mb(value: str) -> int:
    found = re.fullmatch(r'([1-9][0-9]*)([MG]?)', value)
    if not found:
        raise ValueError('Unrecognized actual AVD memory value')
    return int(found[1]) * (1024 if found[2] == 'G' else 1)


def verify_current_avd(out: Path, phase: str = 'guard', avd_home: Path | None = None) -> dict:
    binding = json.loads((out / 'prepared.json').read_text())
    sdk = Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT']).resolve(strict=True)
    observation = observe_current_avd(out, phase, avd_home)
    if str(sdk) != binding['sdk_root'] or binding['tools_zip_sha256'] != TOOLS_SHA256:
        raise ValueError('CLI22 proof belongs to another SDK or official archive')
    actual_source = subprocess.check_output(['git', '--no-replace-objects', 'rev-parse', 'HEAD'], text=True).strip()
    if actual_source != binding['source_commit']:
        raise ValueError('CLI22 preparation belongs to another probe source')
    if properties(sdk / 'cmdline-tools/latest/source.properties').get('Pkg.Revision') != '22.0':
        raise ValueError('The action did not retain CLI22 as its canonical tools')
    observation['actual_tools_files'] = require_official_tools((sdk / 'cmdline-tools/latest').resolve(strict=True), binding['installed_tools_files'])
    if observation['pointer'].get('target') != EXPECTED_TARGET:
        raise ValueError('Actual generated AVD target is not android-37.0; no target rewrite is permitted')
    image = Path(observation['configuration'].get('image.sysdir.1', ''))
    image = image if image.is_absolute() else sdk / image
    if image.resolve() != (sdk / IMAGE_RELATIVE).resolve():
        raise ValueError('Actual AVD uses another system image')
    if observation['configuration'].get('hw.cpu.ncore') != '2':
        raise ValueError('Actual AVD differs from original two-core input')
    for key, value in (('hw.ramSize', 4096), ('hw.heapSize', 512)):
        if memory_mb(observation['configuration'].get(key, '')) != value:
            raise ValueError('Actual AVD differs from original action input: ' + key)
    packages = observation['packages']
    for label in ('image', 'emulator'):
        if packages[label]['properties'] != binding['packages'][label]['properties']:
            raise ValueError('Action changed the actual image/emulator properties')
        if packages[label]['installed_package'] != binding['packages'][label]['installed_package']:
            raise ValueError('Action changed the actual installed image/emulator package descriptor')
    observation['status'] = 'ACTUAL_CLI22_AVD_BINDING_VERIFIED'
    observation['official_tools_sha256'] = TOOLS_SHA256
    write_json(out / ('verified-' + phase + '.json'), observation)
    return observation


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('prepare', 'inspect', 'verify'))
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--action-dir', type=Path)
    parser.add_argument('--phase', default='before-boot')
    args = parser.parse_args()
    out = args.out.resolve()
    if args.mode == 'prepare':
        if not args.action_dir:
            parser.error('--action-dir is required for prepare')
        sdk = Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT']).resolve(strict=True)
        result = prepare(out, sdk, args.action_dir.resolve(strict=True))
    elif args.mode == 'verify':
        result = verify_current_avd(out, args.phase)
    else:
        result = observe_current_avd(out, args.phase)
    print(json.dumps({'status': result['status']}))


if __name__ == '__main__':
    main()
