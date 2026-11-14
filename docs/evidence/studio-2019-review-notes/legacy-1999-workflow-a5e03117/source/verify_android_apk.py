"""Verify an APK against Lumo's stable signing certificate before publishing."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


class VerificationError(RuntimeError):
    pass


def find_apksigner() -> str:
    on_path = shutil.which('apksigner')
    if on_path:
        return on_path
    sdk_paths = [os.environ.get(name) for name in ('ANDROID_SDK_ROOT', 'ANDROID_HOME')]
    sdk_paths.append(str(Path.home() / 'Android/Sdk'))
    for sdk in filter(None, sdk_paths):
        build_tools = Path(sdk) / 'build-tools'
        if not build_tools.is_dir():
            continue
        versions = sorted(
            build_tools.iterdir(),
            key=lambda path: tuple(int(part) for part in re.findall(r'\d+', path.name)),
            reverse=True,
        )
        for version in versions:
            candidate = version / 'apksigner'
            if candidate.is_file() and os.access(candidate, os.X_OK):
                return str(candidate)
    raise VerificationError('apksigner missing; install Android SDK build-tools or set ANDROID_SDK_ROOT.')


def run_tool(command: list[str]) -> bytes:
    result = subprocess.run(command, capture_output=True, check=False)
    if result.returncode:
        detail = result.stderr.decode('utf-8', errors='replace')[-3000:].strip()
        raise VerificationError(f'{Path(command[0]).name} failed with exit code {result.returncode}: {detail}')
    return result.stdout


def find_java_tool(name: str) -> str:
    java_home = os.environ.get('JAVA_HOME')
    candidate = Path(java_home) / 'bin' / name if java_home else None
    if candidate and candidate.is_file():
        return str(candidate)
    on_path = shutil.which(name)
    if on_path:
        return on_path
    raise VerificationError(f'{name} missing; install a JDK and set JAVA_HOME.')


def verify_apk(apk: Path) -> str:
    if not apk.is_file():
        raise VerificationError('APK file does not exist.')
    keystore = Path(__file__).resolve().parents[1] / 'tools/lumo-debug.keystore'
    if not keystore.is_file():
        raise VerificationError('Stable Lumo signing keystore is missing.')
    sdk_tool = Path(find_apksigner()).resolve()
    jar = sdk_tool.parent / 'lib' / 'apksigner.jar'
    if not jar.is_file():
        raise VerificationError(f'Android APK verifier library missing beside {sdk_tool.name}.')
    certificate = run_tool([
        find_java_tool('keytool'), '-exportcert', '-alias', 'androiddebugkey',
        '-keystore', str(keystore), '-storepass', 'android',
    ])
    if not certificate:
        raise VerificationError('The stable signing certificate could not be exported.')
    digest = hashlib.sha256(certificate).hexdigest()
    source = Path(__file__).with_name('LumoApkCertificateVerifier.java')
    output = run_tool([
        find_java_tool('java'), '-cp', str(jar), str(source), str(apk.resolve()), digest,
    ]).decode('utf-8', errors='replace').strip()
    if output != f'Verified stable APK signing certificate (SHA-256): {digest}':
        raise VerificationError('APK verifier did not confirm the expected certificate.')
    return digest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path, help='APK to verify before publishing')
    args = parser.parse_args()
    try:
        digest = verify_apk(args.apk)
    except (VerificationError, OSError) as error:
        print(f'APK verification failed: {error}', file=sys.stderr)
        return 1
    print(f'Verified stable APK signing certificate (SHA-256): {digest}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
