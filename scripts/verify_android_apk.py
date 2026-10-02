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
        # Tool output can include unrelated host details; report only the failure.
        raise VerificationError(f'{Path(command[0]).name} failed with exit code {result.returncode}.')
    return result.stdout


def verify_certificate_digest(signer_output: str, trusted_certificate: bytes) -> str:
    # AOSP ApkSignerTool.verify prints SDK ranges for v3.1 signatures instead
    # of numbered signers, possibly repeating one certificate across ranges.
    label_pattern = r'Signer (?:#\d+|\(minSdkVersion=\d+(?: \(dev release=true\))?, maxSdkVersion=\d+\))'
    entries = []
    for line in signer_output.splitlines():
        line = line.strip()
        if line.startswith('Signer ') and ' certificate SHA-256 digest:' in line:
            label, digest = line.split(' certificate SHA-256 digest:', 1)
            entries.append((label, digest.strip()))

    # Print only bounded labels and public certificate digests on failure.
    # Never dump certificate DNs, public-key details, or arbitrary tool output.
    diagnostic = '; '.join(
        re.sub(r'[^A-Za-z0-9 #()=,._-]', '?', label)[:120] + ': ' +
        (digest.lower() if re.fullmatch(r'[0-9a-fA-F]{64}', digest) else '<invalid digest>')
        for label, digest in entries[:8]
    ) or '<no signer certificate SHA-256 lines>'
    if not entries or any(
        re.fullmatch(label_pattern, label) is None or
        re.fullmatch(r'[0-9a-fA-F]{64}', digest) is None
        for label, digest in entries
    ):
        raise VerificationError(f'Unrecognized APK signing certificate output. Public digest labels: {diagnostic}')
    digests = {digest.lower() for _, digest in entries}
    numbered_signers = {label for label, _ in entries if label.startswith('Signer #')}
    if len(digests) != 1 or len(numbered_signers) > 1:
        raise VerificationError(f'APK must use one signing certificate. Public digest labels: {diagnostic}')
    if not trusted_certificate:
        raise VerificationError('The stable signing certificate could not be exported.')
    digest = next(iter(digests))
    if digest != hashlib.sha256(trusted_certificate).hexdigest():
        raise VerificationError(f'APK certificate does not match the stable Lumo signing certificate. Public digest labels: {diagnostic}')
    return digest


def verify_apk(apk: Path) -> str:
    if not apk.is_file():
        raise VerificationError('APK file does not exist.')
    keystore = Path(__file__).resolve().parents[1] / 'tools/lumo-debug.keystore'
    if not keystore.is_file():
        raise VerificationError('Stable Lumo signing keystore is missing.')
    keytool = shutil.which('keytool')
    if keytool is None:
        raise VerificationError('keytool missing; install a JDK and add its bin directory to PATH.')
    signer_output = run_tool([find_apksigner(), 'verify', '--print-certs', str(apk.resolve())])
    certificate = run_tool([
        keytool, '-exportcert', '-alias', 'androiddebugkey',
        '-keystore', str(keystore), '-storepass', 'android',
    ])
    return verify_certificate_digest(signer_output.decode('utf-8', errors='replace'), certificate)


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
