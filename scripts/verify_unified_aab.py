"""Bind a signed staging AAB to the verified APKs and exact source commit."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

from verify_android_apk import find_java_tool, run_tool

ROOT = Path(__file__).resolve().parents[1]


def compare_payloads(bundle: Path, apks: list[Path]) -> dict:
    """Every asset and native library must match the already verified APKs."""
    expected = {}
    for apk in apks:
        with zipfile.ZipFile(apk) as archive:
            for name in archive.namelist():
                if name.startswith(('assets/', 'lib/')) and not name.endswith('/'):
                    digest = hashlib.sha256(archive.read(name)).hexdigest()
                    if name in expected and expected[name] != digest:
                        raise RuntimeError(f'APK inputs disagree: {name}')
                    expected[name] = digest
    with zipfile.ZipFile(bundle) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or archive.testzip() is not None:
            raise RuntimeError('Duplicated or corrupt AAB entries')
        actual = {name.removeprefix('base/'): hashlib.sha256(archive.read(name)).hexdigest()
                  for name in names if name.startswith(('base/assets/', 'base/lib/'))
                  and not name.endswith('/')}
    if not expected or actual != expected:
        changed = sorted(name for name in actual.keys() | expected.keys()
                         if actual.get(name) != expected.get(name))
        raise RuntimeError(f'AAB assets/native code differ from verified APKs: {changed[:20]}')
    return {'asset_and_native_file_count': len(expected), 'exact_apk_payload_match': True}


def verify(bundle: Path, derived_verification: Path) -> dict:
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    if subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], text=True).strip():
        raise RuntimeError('Tracked sources changed before AAB verification')
    paths = [Path('dist/Lumo-Lernen-Neu.apk')]
    if Path('dist/x86_64/Lumo-Lernen-Neu.apk').exists():
        paths.append(Path('dist/x86_64/Lumo-Lernen-Neu.apk'))
    proof = json.loads(Path('dist/BUILD-PROVENANCE.json').read_text())
    derived = json.loads(derived_verification.read_text())
    for field in ('package', 'versionCode', 'versionName', 'signingCertificateSha256', 'godot', 'offlineVoice'):
        if proof[field] != derived[field]:
            raise RuntimeError(f'AAB-derived APK identity differs: {field}')
    if proof['flutter_source_commit'] != head or proof['tracked_source_clean'] is not True:
        raise RuntimeError('APK candidate was built from a different source')
    certificate = run_tool([find_java_tool('keytool'), '-exportcert', '-alias', 'androiddebugkey',
                            '-keystore', str(ROOT / 'tools/lumo-debug.keystore'), '-storepass', 'android'])
    digest = hashlib.sha256(certificate).hexdigest()
    confirmation = run_tool([find_java_tool('java'), str(ROOT / 'scripts/LumoAabCertificateVerifier.java'),
                             str(bundle), digest]).decode().strip()
    if confirmation != f'Verified stable AAB signing certificate (SHA-256): {digest}':
        raise RuntimeError('AAB signature was not verified')
    result = dict(proof)
    result.update(compare_payloads(bundle, paths))
    result.update({'kind': 'Lumo staging AAB; public TEST signing; NOT a Play release',
                   'sha256': hashlib.file_digest(bundle.open('rb'), 'sha256').hexdigest(),
                   'bytes': bundle.stat().st_size, 'abis': derived['abis'],
                   'bundletool_version': '1.18.3', 'derived_apk_verification': derived,
                   'signingCertificateSha256': digest, 'play_upload_authorized': False})
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    parser.add_argument('derived_verification', type=Path)
    args = parser.parse_args()
    print(json.dumps(verify(args.bundle, args.derived_verification), indent=2))
