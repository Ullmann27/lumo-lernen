"""Verify a locally built Play AAB; never publish or infer Play Console acceptance."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

from prepare_android import DISTRIBUTION_METADATA, validate_play_signing
from verify_android_apk import find_java_tool
from verify_unified_apk import SUPPORTED_ABIS, validate_abis, validate_offline_voice

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = 'dev.ullmann.lumo.lumo_lernen'
ANDROID = '{http://schemas.android.com/apk/res/android}'
JAVA_SOURCE = Path(__file__).with_name('LumoPlayBundleVerifier.java')


def digest_file(path: Path) -> str:
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def run_tool(command: list[str], label: str, timeout: int = 180) -> str:
    try:
        result = subprocess.run(command, capture_output=True, text=True,
                                check=False, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(label + ' timed out') from error
    if result.returncode:
        # Signing-provider diagnostics can contain private paths. The command,
        # environment and raw output are intentionally absent from this error.
        raise RuntimeError(f'{label} failed (exit {result.returncode})')
    return result.stdout.strip()


def java_json(java: str, arguments: list[str], label: str) -> dict:
    result = json.loads(run_tool([java, str(JAVA_SOURCE), *arguments], label))
    if not isinstance(result, dict):
        raise RuntimeError(label + ' did not return a JSON object')
    return result


def preflight(root: Path, bundletool: Path) -> dict:
    """Check real tools and upload-key possession before changing the host."""
    validate_play_signing(root)
    if not bundletool.is_file() or bundletool.suffix.lower() != '.jar':
        raise RuntimeError('--bundletool must name an existing bundletool JAR')
    if not zipfile.is_zipfile(bundletool):
        raise RuntimeError('The bundletool file is not a JAR archive')
    java = find_java_tool('java')
    signer = java_json(java, ['preflight'], 'Upload-key preflight')
    if (signer.get('privateKeyReadable') is not True
            or not isinstance(signer.get('javaFeature'), int)
            or signer['javaFeature'] < 17
            or not re.fullmatch(r'[0-9a-f]{64}', signer.get('uploadCertificateSha256', ''))):
        raise RuntimeError('Upload-key preflight evidence is incomplete')
    version = run_tool([java, '-jar', str(bundletool.resolve()), 'version'],
                       'bundletool version')
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?', version):
        raise RuntimeError('bundletool did not report an identifiable version')
    return {
        'kind': 'play-build-preflight', 'artifactBuilt': False, 'package': PACKAGE,
        **signer, 'bundletoolVersion': version, 'bundletoolSha256': digest_file(bundletool),
    }


def source_identity(root: Path) -> str:
    git = ['git', '--no-replace-objects', '-C', str(root)]
    commit = run_tool(git + ['rev-parse', 'HEAD'], 'Source identity')
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise RuntimeError('Source must identify an exact Git commit')
    if run_tool(git + ['status', '--porcelain', '--untracked-files=no'], 'Tracked source check'):
        raise RuntimeError('Tracked source differs from the candidate commit')
    untracked = run_tool(git + [
        'ls-files', '--others', '--exclude-standard', '--',
        'lib', 'assets', 'scripts', 'tools', 'config', 'pubspec.yaml', 'pubspec.lock',
    ], 'Untracked source check')
    if untracked:
        raise RuntimeError('Untracked application or build inputs are present')
    return commit


def expected_version(root: Path) -> tuple[str, int]:
    versions = re.findall(
        r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([1-9][0-9]*)\s*$',
        (root / 'pubspec.yaml').read_text(encoding='utf-8'), re.MULTILINE)
    if len(versions) != 1:
        raise RuntimeError('Expected one committed semantic version and positive build number')
    return versions[0][0], int(versions[0][1])


def validate_manifest(xml: str, version_name: str, version_code: int) -> dict:
    """Validate XML produced by bundletool, not source-template declarations."""
    manifest = ET.fromstring(xml)
    if manifest.tag != 'manifest' or manifest.get('package') != PACKAGE:
        raise RuntimeError('Play bundle must use the canonical application package')
    if (manifest.get(ANDROID + 'versionName') != version_name
            or manifest.get(ANDROID + 'versionCode') != str(version_code)):
        raise RuntimeError('Play bundle version differs from committed source')
    sdk = manifest.findall('uses-sdk')
    if (len(sdk) != 1 or sdk[0].get(ANDROID + 'minSdkVersion') != '24'
            or sdk[0].get(ANDROID + 'targetSdkVersion') != '36'):
        raise RuntimeError('Play bundle must retain the reviewed minSdk 24 and targetSdk 36')
    permissions = sorted({entry.get(ANDROID + 'name', '')
                          for tag in ('uses-permission', 'uses-permission-sdk-23')
                          for entry in manifest.findall(tag)})
    if 'android.permission.REQUEST_INSTALL_PACKAGES' in permissions:
        raise RuntimeError('Play bundle requests the APK installer permission')
    applications = manifest.findall('application')
    if len(applications) != 1:
        raise RuntimeError('Play bundle must contain exactly one application')
    application = applications[0]
    if application.get(ANDROID + 'debuggable', 'false') != 'false':
        raise RuntimeError('Play bundle application must not be debuggable')
    channels = [entry.get(ANDROID + 'value')
                for entry in application.findall('meta-data')
                if entry.get(ANDROID + 'name') == DISTRIBUTION_METADATA]
    if channels != ['play']:
        raise RuntimeError('Play distribution metadata is missing or ambiguous')
    activities = [entry for entry in application.findall('activity')
                  if entry.get(ANDROID + 'name') in ('.LumoGameActivity',
                                                    PACKAGE + '.LumoGameActivity')]
    if (len(activities) != 1
            or activities[0].get(ANDROID + 'exported') != 'false'
            or activities[0].get(ANDROID + 'process') != ':lumo_game'):
        raise RuntimeError('Private embedded Godot activity identity is missing')
    return {'package': PACKAGE, 'versionName': version_name, 'versionCode': version_code,
            'minSdk': 24, 'targetSdk': 36, 'distribution': 'play', 'permissions': permissions}


def archive_inventory(archive: zipfile.ZipFile) -> dict[str, zipfile.ZipInfo]:
    entries = {}
    for info in archive.infolist():
        name = info.filename
        parts = name.rstrip('/').split('/')
        if (not name or name.startswith('/') or '\\' in name
                or any(part in ('', '.', '..') for part in parts)):
            raise RuntimeError('Bundle contains an unsafe archive entry')
        if name in entries:
            raise RuntimeError('Bundle contains duplicate archive entries')
        entries[name] = info
    for name in ('BundleConfig.pb', 'base/manifest/AndroidManifest.xml',
                 'base/resources.pb', 'base/dex/classes.dex'):
        if name not in entries or entries[name].file_size <= 0:
            raise RuntimeError('Bundle is missing required application data: ' + name)
    modules = {name.split('/')[0] for name in entries
               if name.endswith('/manifest/AndroidManifest.xml')}
    if modules != {'base'}:
        raise RuntimeError('Unreviewed feature or asset modules require explicit validation')
    return entries


def member_digest(archive: zipfile.ZipFile, name: str) -> str:
    with archive.open(name) as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def validate_native_library(archive: zipfile.ZipFile, name: str, abi: str) -> dict:
    info = archive.getinfo(name)
    with archive.open(name) as source:
        header = source.read(64)
        if (len(header) != 64 or header[:7] != b'\x7fELF\x02\x01\x01'
                or struct.unpack_from('<H', header, 16)[0] != 3
                or struct.unpack_from('<H', header, 18)[0] !=
                {'arm64-v8a': 183, 'x86_64': 62}[abi]):
            raise RuntimeError('Expected the matching ELF64 shared library: ' + name)
        phoff = struct.unpack_from('<Q', header, 32)[0]
        stride, count = struct.unpack_from('<HH', header, 54)
        if (phoff < 64 or stride < 56 or not 0 < count < 65535
                or phoff + stride * count > info.file_size):
            raise RuntimeError('Invalid ELF program-header bounds: ' + name)
        loads = 0
        for index in range(count):
            source.seek(phoff + index * stride)
            program = source.read(56)
            if len(program) != 56:
                raise RuntimeError('Truncated ELF program header: ' + name)
            kind, _, offset, address, _, file_size, memory_size, alignment = struct.unpack(
                '<IIQQQQQQ', program)
            if kind != 1:
                continue
            loads += 1
            if (alignment < 16384 or alignment & (alignment - 1)
                    or offset % alignment != address % alignment
                    or file_size > memory_size or offset + file_size > info.file_size):
                raise RuntimeError('Invalid or insufficient 16-KiB PT_LOAD alignment: ' + name)
        if not loads:
            raise RuntimeError('Native library has no loadable segments: ' + name)
    return {'path': name, 'bytes': info.file_size,
            'sha256': member_digest(archive, name), 'loadSegments': loads}


class BaseModuleArchive:
    """Adapt the base module paths to the existing strict offline-voice checks."""
    def __init__(self, archive: zipfile.ZipFile):
        self.archive = archive

    def namelist(self):
        return [name.removeprefix('base/') for name in self.archive.namelist()
                if name.startswith('base/')]

    def read(self, name):
        return self.archive.read('base/' + name)


def validate_payload(archive: zipfile.ZipFile, root: Path) -> dict:
    entries = archive_inventory(archive)
    libraries = sorted(name for name in entries
                       if re.fullmatch(r'base/lib/[^/]+/[^/]+\.so', name))
    abis = {name.split('/')[2] for name in libraries}
    validate_abis(abis)
    for abi in SUPPORTED_ABIS:
        for library in ('libapp.so', 'libflutter.so', 'libgodot_android.so',
                        'libonnxruntime.so', 'libonnxruntime4j_jni.so'):
            if f'base/lib/{abi}/{library}' not in entries:
                raise RuntimeError(f'Missing required {abi} library: {library}')
    native = [validate_native_library(archive, name, name.split('/')[2])
              for name in libraries]
    source = json.loads((root / 'config/godot-source.json').read_text(encoding='utf-8'))
    if not re.fullmatch(r'[0-9a-f]{40}', source.get('revision', '')):
        raise RuntimeError('Godot source is not pinned to an immutable revision')
    proof = json.loads(archive.read('base/assets/lumo_game_source.json'))
    if any(proof.get(key) != value for key, value in source.items()):
        raise RuntimeError('Packaged Godot source identity differs from committed source')
    pack_name = 'base/assets/lumo_game.pck'
    with archive.open(pack_name) as pack:
        header = pack.read(20)
    if len(header) != 20 or header[:4] != b'GDPC':
        raise RuntimeError('Embedded Godot PCK has an invalid header')
    _, _, major, minor, patch = struct.unpack('<4s4I', header)
    if f'{major}.{minor}.{patch}' != source.get('engine'):
        raise RuntimeError('Embedded Godot PCK engine differs from committed source')
    if (entries[pack_name].file_size != proof.get('bytes')
            or member_digest(archive, pack_name) != proof.get('pck_sha256')):
        raise RuntimeError('Embedded Godot PCK bytes differ from its packaged receipt')
    config = json.loads((root / 'config/lumo-offline-voice.json').read_text(encoding='utf-8'))
    catalog = json.loads((root / 'assets/audio/voice/lumo_free/catalog.json').read_text(encoding='utf-8'))
    voice = validate_offline_voice(BaseModuleArchive(archive), abis, config, catalog)
    voice['scope'] = 'Actual AAB package validation, not audible playback acceptance'
    return {
        'abis': sorted(abis), 'nativeLibraries': native, 'elfLoadSegments16KiBAligned': True,
        'godot': proof, 'offlineVoice': voice,
        'baseArchiveCompressedBytes': sum(info.compress_size for name, info in entries.items()
                                          if name.startswith('base/')),
        'baseSizeScope': 'ZIP compressed bytes; not the Play per-device download estimate',
    }


def verify(aab: Path, bundletool: Path, root: Path = ROOT) -> dict:
    if (not aab.is_file() or aab.suffix.lower() != '.aab'
            or aab.stat().st_size <= 0 or not zipfile.is_zipfile(aab)):
        raise RuntimeError('Expected an existing nonempty Android App Bundle')
    commit = source_identity(root)
    version_name, version_code = expected_version(root)
    checked = preflight(root, bundletool)
    before = digest_file(aab)
    java = find_java_tool('java')
    command = [java, '-jar', str(bundletool.resolve())]
    run_tool(command + ['validate', '--bundle=' + str(aab.resolve())],
             'bundletool validate', timeout=600)
    manifest = run_tool(command + ['dump', 'manifest', '--bundle=' + str(aab.resolve()),
                                  '--module=base'], 'bundletool dump manifest')
    identity = validate_manifest(manifest, version_name, version_code)
    with zipfile.ZipFile(aab) as archive:
        payload = validate_payload(archive, root)
    certificate = checked['uploadCertificateSha256']
    signing = java_json(java, ['verify', str(aab.resolve()), certificate],
                        'AAB JAR signature verification')
    if (signing.get('uploadCertificateSha256') != certificate
            or not isinstance(signing.get('verifiedEntries'), int)
            or signing['verifiedEntries'] <= 0):
        raise RuntimeError('AAB signing evidence is incomplete')
    if digest_file(aab) != before or source_identity(root) != commit:
        raise RuntimeError('Bundle or application source changed during verification')
    if digest_file(bundletool) != checked['bundletoolSha256']:
        raise RuntimeError('bundletool changed during verification')
    return {
        'kind': 'verified-play-upload-bundle', **identity, **payload,
        'flutterSourceCommit': commit, 'trackedSourceClean': True,
        'sha256': before, 'bytes': aab.stat().st_size,
        'uploadCertificateSha256': certificate, 'signedPayloadEntries': signing['verifiedEntries'],
        'bundletoolVersion': checked['bundletoolVersion'],
        'bundletoolSha256': checked['bundletoolSha256'], 'javaFeature': checked['javaFeature'],
        'playConsoleAccepted': False, 'playDownloadSizeVerified': False,
        'aabDerivedApksTested': False, 'runtime16KiBTested': False,
    }


def main(arguments=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('aab', nargs='?', type=Path)
    parser.add_argument('--bundletool', required=True, type=Path,
                        help='Existing official bundletool all-in-one JAR; never downloaded implicitly')
    parser.add_argument('--preflight', action='store_true',
                        help='Check real tools and external signing inputs before host preparation')
    parser.add_argument('--output-json', type=Path)
    args = parser.parse_args(arguments)
    if args.preflight == (args.aab is not None):
        parser.error('Choose either --preflight or an actual AAB path')
    try:
        if args.output_json is not None:
            if args.output_json.exists() or args.output_json.is_symlink():
                raise RuntimeError('Refusing to overwrite existing verification evidence')
            if not args.output_json.parent.is_dir():
                raise RuntimeError('Verification output directory must already exist')
        result = preflight(ROOT, args.bundletool) if args.preflight else verify(args.aab, args.bundletool)
        output = json.dumps(result, indent=2, sort_keys=True) + '\n'
        if args.output_json is not None:
            with args.output_json.open('x', encoding='utf-8') as destination:
                destination.write(output)
        print(output, end='')
        return 0
    except (RuntimeError, ValueError, OSError, KeyError, zipfile.BadZipFile,
            struct.error, ET.ParseError) as error:
        print('Play bundle verification failed: ' + str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
