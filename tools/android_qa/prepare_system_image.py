"""Prepare only the existing API35/36 Google APIs x86_64 image before QA.

Official syntax: https://developer.android.com/tools/sdkmanager
Existing runner a421e43855164a8197daf9d8d40fe71c6996bb0d installs this exact
package once after its license flow. This preflight uses already accepted SDK
licenses, adds no license answers/dependencies and copies no external code.
Only its recorded rc1/ZipFile warning permits another bounded install.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import xml.etree.ElementTree as ET

ZIP_WARNING = ('Warning: An error occurred while preparing SDK package Google APIs Intel '
               'x86_64 Atom System Image: Error on ZipFile unknown archive.')
IMAGE_FILES = ('system.img', 'vendor.img', 'kernel-ranchu', 'ramdisk.img', 'userdata.img')
ERROR_OUTPUT = re.compile(r'warning:|error|exception|not accepted|refused|denied|failed', re.I)


def package_name(api: int) -> str:
    if type(api) is not int or api not in (35, 36):
        raise ValueError('Only the existing API35/36 google_apis x86_64 packages are supported')
    return f'system-images;android-{api};google_apis;x86_64'


def revision(value: str) -> tuple[int, ...]:
    if not re.fullmatch(r'[1-9]\d*(?:\.\d+){0,2}', value):
        raise RuntimeError('Malformed or preview system-image revision')
    parts = [int(x) for x in value.split('.')]
    while len(parts) > 1 and parts[-1] == 0:
        parts.pop()
    return tuple(parts)


def safe_target(sdk: Path, target: Path):
    # No symlinked image/component can redirect inspection or quarantine.
    for path in (sdk, *target.relative_to(sdk).parents):
        candidate = path if path == sdk else sdk / path
        if candidate.is_symlink():
            raise RuntimeError('Refusing a symlinked system-image path')
    if target.is_symlink() or any(p.is_symlink() for p in target.rglob('*')):
        raise RuntimeError('Refusing a symlinked system-image component')


def metadata(target: Path, api: int, *, complete=True) -> dict:
    expected = package_name(api)
    props_path, xml_path = target / 'source.properties', target / 'package.xml'
    props = {}
    if props_path.exists() or props_path.is_symlink():
        if props_path.is_symlink() or not props_path.is_file():
            raise RuntimeError('System-image source.properties must be a regular non-symlink file')
        for line in props_path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' not in line:
                raise RuntimeError('Malformed system-image source.properties')
            key, value = (x.strip() for x in line.split('=', 1))
            if key in props:
                raise RuntimeError('Duplicate system-image property')
            props[key] = value
        required = {'AndroidVersion.ApiLevel': str(api), 'SystemImage.Abi': 'x86_64',
                    'SystemImage.TagId': 'google_apis'}
        if any(props.get(k) != v for k, v in required.items()):
            raise RuntimeError('System-image properties differ from the exact requested package')
        if props.get('Pkg.Path', expected) != expected or props.get('AndroidVersion.CodeName', 'REL') != 'REL':
            raise RuntimeError('Wrong or preview system-image package')
        prop_revision = revision(props.get('Pkg.Revision', ''))
    elif complete:
        raise RuntimeError('System-image source.properties is missing')

    xml_revision = None
    if xml_path.exists() or xml_path.is_symlink():
        if xml_path.is_symlink() or not xml_path.is_file():
            raise RuntimeError('System-image package.xml must be a regular non-symlink file')
        root = ET.parse(xml_path).getroot()
        local = [x for x in root.iter() if x.tag.split('}')[-1] == 'localPackage']
        if len(local) != 1 or local[0].get('path') != expected:
            raise RuntimeError('Installed package.xml path is ambiguous or wrong')
        def exactly(node, name):
            matches = [x for x in node if x.tag.split('}')[-1] == name]
            if len(matches) != 1:
                raise RuntimeError('Missing or duplicate installed package metadata: ' + name)
            return matches[0]
        details = exactly(local[0], 'type-details')
        if exactly(local[0], 'uses-license').get('ref') != 'android-sdk-license':
            raise RuntimeError('Unexpected system-image license reference')
        if (exactly(details, 'api-level').text != str(api) or
                exactly(details, 'abi').text != 'x86_64' or
                exactly(exactly(details, 'tag'), 'id').text != 'google_apis'):
            raise RuntimeError('Installed package.xml platform identity differs')
        rev = exactly(local[0], 'revision')
        if any(x.tag.split('}')[-1] not in ('major', 'minor', 'micro') for x in rev):
            raise RuntimeError('Malformed or preview installed revision')
        fields = [exactly(rev, 'major').text]
        for name in ('minor', 'micro'):
            values = [x for x in rev if x.tag.split('}')[-1] == name]
            if len(values) > 1:
                raise RuntimeError('Duplicate installed revision field')
            fields.append(values[0].text if values else '0')
        xml_revision = revision('.'.join(fields))
        if props and xml_revision != prop_revision:
            raise RuntimeError('Installed revision differs from source.properties')
    elif complete:
        raise RuntimeError('Installed package.xml is missing')
    if not complete:
        return {'partial_identity_checked': True}
    files = []
    for name in IMAGE_FILES:
        path = target / name
        if not path.is_file() or path.stat().st_size <= 0:
            raise RuntimeError('Required nonempty system-image file is missing: ' + name)
        files.append({'file': name, 'bytes': path.stat().st_size})
    return {'package': expected, 'revision': props['Pkg.Revision'], 'files': files,
            'metadata': [{'file': p.name, 'bytes': p.stat().st_size,
                          'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                         for p in (props_path, xml_path)]}


def prepare_system_image(api: int, out: Path, *, sdk: Path | None = None,
                         timeout: float = 600, runner=subprocess.run,
                         clock=time.monotonic) -> dict:
    package = package_name(api)
    if type(timeout) not in (int, float) or not 10 <= timeout <= 600:
        raise ValueError('Shared installer deadline must be between 10 and 600 seconds')
    if sdk is None:
        home, alternate = os.environ.get('ANDROID_HOME'), os.environ.get('ANDROID_SDK_ROOT')
        if not home or (alternate and Path(alternate).resolve() != Path(home).resolve()):
            raise RuntimeError('One existing ANDROID_HOME SDK and matching optional ANDROID_SDK_ROOT required')
        sdk = Path(home)
    if not sdk.is_absolute() or not sdk.is_dir() or sdk.resolve() == Path('/'):
        raise RuntimeError('Existing absolute Android SDK directory required')
    sdk = sdk.resolve()
    manager = sdk / 'cmdline-tools/latest/bin/sdkmanager'
    if not manager.is_file() or not os.access(manager, os.X_OK) or not manager.resolve().is_relative_to(sdk):
        raise RuntimeError('Existing official SDK-local sdkmanager required')
    license_file = sdk / 'licenses/android-sdk-license'
    if (license_file.parent.is_symlink() or not license_file.parent.is_dir() or
            not license_file.resolve().is_relative_to(sdk)):
        raise RuntimeError('Existing license directory and file must remain inside the SDK without symlinks')
    if (license_file.is_symlink() or not license_file.is_file() or license_file.stat().st_size == 0):
        raise RuntimeError('Existing accepted android-sdk-license is required; no license answers supplied')
    out = Path(out).absolute()
    if out.resolve().is_relative_to(sdk):
        raise RuntimeError('Evidence directory must be outside the Android SDK')
    out.mkdir(parents=True, exist_ok=True)
    evidence = Path(tempfile.mkdtemp(prefix=f'system-image-{api}-', dir=out))
    began = clock()
    deadline = began + timeout
    target = sdk / f'system-images/android-{api}/google_apis/x86_64'
    state = {'status': 'RUNNING', 'package': package, 'sdk': str(sdk), 'attempts': [],
             'evidence_directory': str(evidence), 'shared_timeout_seconds': timeout,
             'scope': 'SDK preparation only; no emulator/APK/gameplay success',
             'license_policy': 'existing accepted licenses only; no answers or license changes'}
    def save():
        (evidence / 'result.json').write_text(json.dumps(state, indent=2) + '\n')
    def remaining():
        value = deadline - clock()
        if value <= 0:
            raise TimeoutError('Shared system-image preparation deadline exhausted')
        return value
    def command(label, arguments, cap):
        limit = min(cap, remaining())
        stdout, stderr = evidence / (label + '.stdout.log'), evidence / (label + '.stderr.log')
        record = {'arguments': arguments, 'timeout_seconds': limit,
                  'elapsed_seconds': round(clock() - began, 3),
                  'stdout': stdout.name, 'stderr': stderr.name}
        try:
            with stdout.open('w') as so, stderr.open('w') as se:
                process = runner([str(manager), f'--sdk_root={sdk}', *arguments],
                                 stdin=subprocess.DEVNULL, stdout=so, stderr=se, timeout=limit)
            record['return_code'] = process.returncode
            remaining()
            return process.returncode, stdout.read_text(), stderr.read_text()
        except Exception as error:
            record['error'] = str(error)
            raise
        finally:
            record['logs'] = [{'file': p.name, 'bytes': p.stat().st_size,
                               'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                              for p in (stdout, stderr) if p.exists()]
            state['attempts'].append(record)
            save()
    def verify():
        remaining()
        safe_target(sdk, target)
        observed = metadata(target, api)
        status, output, error = command('installed-packages', ['--list', '--channel=0'], 60)
        if status != 0 or error.strip() or ERROR_OUTPUT.search(output):
            raise RuntimeError('SDK installed-package listing failed; no recovery')
        if output.count('Installed packages:') != 1:
            raise RuntimeError('Actual SDK installed-package section is ambiguous or missing')
        section = output.split('Installed packages:', 1)
        if len(section) != 2:
            raise RuntimeError('Actual SDK installed-package section is missing')
        installed = re.split(r'\n\s*(?:Available Packages:|Available Updates:)', section[1], maxsplit=1)[0]
        rows = [[x.strip() for x in line.split('|')] for line in installed.splitlines()]
        rows = [x for x in rows if x[0] == package]
        if (len(rows) != 1 or len(rows[0]) != 4 or revision(rows[0][1]) != revision(observed['revision']) or
                rows[0][3].rstrip('/') != f'system-images/android-{api}/google_apis/x86_64'):
            raise RuntimeError('Actual installed package/revision/location does not match image metadata')
        remaining()
        return observed
    try:
        safe_target(sdk, target)
        if target.exists():
            state.update(verified_package=verify(), reused=True)
        else:
            for number in range(1, 4):
                status, output, error = command(f'install-{number}', ['--install', package, '--channel=0'], 180)
                if status == 0 and not error.strip() and not ERROR_OUTPUT.search(output):
                    state.update(verified_package=verify(), reused=False)
                    break
                exact_zip = status == 1 and error.strip() == ZIP_WARNING and not ERROR_OUTPUT.search(output)
                if not exact_zip or number == 3:
                    raise RuntimeError('SDK install failed; only recorded rc1/ZipFile fault is retryable (max3)')
                safe_target(sdk, target)
                if target.exists():
                    # Only a directory created by this attempt may be preserved.
                    # Pre-existing wrong/partial packages are rejected above.
                    metadata(target, api, complete=False)
                    retained = evidence / f'partial-image-after-{number}'
                    target.rename(retained)
                    state.setdefault('retained_partial_packages', []).append(retained.name)
                remaining()
        state.update(status='PASS', elapsed_seconds=round(clock() - began, 3))
        return state
    except Exception as error:
        state.update(status='FAIL', error=str(error), elapsed_seconds=round(clock() - began, 3))
        raise
    finally:
        save()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--api', required=True, type=int, choices=(35, 36))
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--timeout', default=600, type=int)
    args = parser.parse_args()
    try:
        state = prepare_system_image(args.api, args.out, timeout=args.timeout)
    except Exception as error:
        print('[SystemImage] FAIL: ' + str(error), flush=True)
        return 1
    print('[SystemImage] PASS: ' + state['package'] + '; evidence=' + state['evidence_directory'], flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
