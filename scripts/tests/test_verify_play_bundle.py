"""Synthetic counterexamples and real JDK rejection checks; no signed AAB acceptance."""
from contextlib import redirect_stderr, redirect_stdout
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import warnings
import xml.etree.ElementTree as ET
import zipfile

SCRIPTS = Path(__file__).resolve().parents[1]
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))
import verify_play_bundle as verifier


def synthetic_manifest():
    return (
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android" '
        'package="dev.ullmann.lumo.lumo_lernen" android:versionName="1.2.3" android:versionCode="7">'
        '<uses-sdk android:minSdkVersion="24" android:targetSdkVersion="36"/>'
        '<uses-permission android:name="android.permission.INTERNET"/>'
        '<application android:debuggable="false">'
        '<meta-data android:name="dev.ullmann.lumo.DISTRIBUTION" android:value="play"/>'
        '<activity android:name="dev.ullmann.lumo.lumo_lernen.LumoGameActivity" '
        'android:exported="false" android:process=":lumo_game"/>'
        '</application></manifest>')


def synthetic_elf(machine=183, alignment=16384):
    data = bytearray(256)
    data[:7] = b'\x7fELF\x02\x01\x01'
    struct.pack_into('<HHIQQQIHHHHHH', data, 16,
                     3, machine, 1, 0, 64, 0, 0, 64, 56, 1, 0, 0, 0)
    struct.pack_into('<IIQQQQQQ', data, 64,
                     1, 5, 0, 0, 0, len(data), len(data), alignment)
    return bytes(data)


def archive_bytes(entries):
    buffer = io.BytesIO()
    with warnings.catch_warnings():
        warnings.simplefilter('ignore', UserWarning)
        with zipfile.ZipFile(buffer, 'w') as archive:
            for name, data in entries:
                archive.writestr(name, data)
    buffer.seek(0)
    return buffer


def required_entries():
    return [(name, b'explicit synthetic data')
            for name in ('BundleConfig.pb', 'base/manifest/AndroidManifest.xml',
                         'base/resources.pb', 'base/dex/classes.dex')]


class PreflightContracts(unittest.TestCase):
    def test_missing_signing_inputs_fail_before_any_tool_or_scaffold(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'source'
            root.mkdir()
            with patch.dict(os.environ, {}, clear=True), patch.object(verifier, 'run_tool') as run:
                with self.assertRaisesRegex(ValueError, 'Play upload signing is missing'):
                    verifier.preflight(root, root / 'missing.jar')
            run.assert_not_called()
            self.assertEqual(list(root.iterdir()), [])

    def test_scaffold_independent_guard_rejects_repository_key_and_public_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory)
            root = parent / 'source'
            (root / 'tools').mkdir(parents=True)
            public = root / 'tools/lumo-debug.keystore'
            public.write_bytes(b'explicit synthetic public key')
            outside = parent / 'copy.keystore'
            outside.write_bytes(public.read_bytes())
            environment = {
                'LUMO_PLAY_STORE_FILE': str(outside),
                'LUMO_PLAY_STORE_PASSWORD': 'synthetic-store-secret',
                'LUMO_PLAY_KEY_ALIAS': 'synthetic-upload',
                'LUMO_PLAY_KEY_PASSWORD': 'synthetic-key-secret',
            }
            with patch.dict(os.environ, environment, clear=True):
                with self.assertRaisesRegex(ValueError, 'public family test key'):
                    verifier.validate_play_signing(root)
            environment['LUMO_PLAY_STORE_FILE'] = str(public)
            with patch.dict(os.environ, environment, clear=True):
                with self.assertRaisesRegex(ValueError, 'outside the repository'):
                    verifier.validate_play_signing(root)
            self.assertFalse((root / 'android').exists())

    def test_subprocess_failure_does_not_expose_provider_diagnostics(self):
        response = subprocess.CompletedProcess(
            ['java'], 1, stdout='private alias', stderr='synthetic-password')
        with patch.object(verifier.subprocess, 'run', return_value=response):
            with self.assertRaisesRegex(RuntimeError, r'Upload-key preflight failed \(exit 1\)') as caught:
                verifier.run_tool(['java'], 'Upload-key preflight')
        self.assertNotIn('synthetic-password', str(caught.exception))
        self.assertNotIn('private alias', str(caught.exception))

    def test_source_identity_rejects_tracked_and_untracked_inputs(self):
        with patch.object(verifier, 'run_tool', side_effect=['a' * 40, ' M lib/app.dart']):
            with self.assertRaisesRegex(RuntimeError, 'Tracked source differs'):
                verifier.source_identity(Path('/synthetic'))
        with patch.object(verifier, 'run_tool', side_effect=['a' * 40, '', 'lib/extra.dart']):
            with self.assertRaisesRegex(RuntimeError, 'Untracked application'):
                verifier.source_identity(Path('/synthetic'))

    def test_cli_failure_creates_no_evidence_and_never_overwrites_existing(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'evidence.json'
            arguments = ['--preflight', '--bundletool', 'synthetic.jar',
                         '--output-json', str(output)]
            with patch.object(verifier, 'preflight', side_effect=RuntimeError('synthetic failure')), \
                    redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                self.assertEqual(verifier.main(arguments), 1)
            self.assertFalse(output.exists())
            output.write_text('existing evidence')
            with patch.object(verifier, 'preflight') as preflight, \
                    redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                self.assertEqual(verifier.main(arguments), 1)
            preflight.assert_not_called()
            self.assertEqual(output.read_text(), 'existing evidence')


class ManifestContracts(unittest.TestCase):
    def test_reviewed_synthetic_manifest_and_version_are_accepted_by_parser_only(self):
        result = verifier.validate_manifest(synthetic_manifest(), '1.2.3', 7)
        self.assertEqual(result['package'], verifier.PACKAGE)
        self.assertEqual(result['distribution'], 'play')
        self.assertEqual(result['permissions'], ['android.permission.INTERNET'])

    def test_wrong_identity_version_sdk_channel_and_export_are_rejected(self):
        replacements = (
            ('package="dev.ullmann.lumo.lumo_lernen"',
             'package="dev.ullmann.lumo.lumo_lernen.coachpreview"'),
            ('android:versionName="1.2.3"', 'android:versionName="1.2.4"'),
            ('android:versionCode="7"', 'android:versionCode="8"'),
            ('android:targetSdkVersion="36"', 'android:targetSdkVersion="35"'),
            ('android:minSdkVersion="24"', 'android:minSdkVersion="23"'),
            ('android:value="play"', 'android:value="family"'),
            ('android:debuggable="false"', 'android:debuggable="true"'),
            ('android:exported="false"', 'android:exported="true"'),
            ('android:process=":lumo_game"', 'android:process=":other"'),
        )
        for old, new in replacements:
            with self.subTest(attribute=old), self.assertRaises(RuntimeError):
                verifier.validate_manifest(synthetic_manifest().replace(old, new), '1.2.3', 7)

    def test_installer_permission_in_either_declaration_is_rejected(self):
        for tag in ('uses-permission', 'uses-permission-sdk-23'):
            declaration = f'<{tag} android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>'
            xml = synthetic_manifest().replace('<application ', declaration + '<application ')
            with self.subTest(tag=tag), self.assertRaisesRegex(RuntimeError, 'installer permission'):
                verifier.validate_manifest(xml, '1.2.3', 7)

    def test_duplicate_distribution_metadata_is_rejected(self):
        doc = ET.fromstring(synthetic_manifest())
        ET.SubElement(doc.find('application'), 'meta-data', {
            verifier.ANDROID + 'name': verifier.DISTRIBUTION_METADATA,
            verifier.ANDROID + 'value': 'play'})
        with self.assertRaisesRegex(RuntimeError, 'metadata'):
            verifier.validate_manifest(ET.tostring(doc, encoding='unicode'), '1.2.3', 7)


class ArchiveContracts(unittest.TestCase):
    def test_duplicate_unsafe_missing_and_additional_modules_are_rejected(self):
        cases = (
            required_entries() + [('base/dex/classes.dex', b'duplicate')],
            required_entries() + [('../outside', b'unsafe')],
            required_entries() + [('base//unsafe', b'unsafe')],
            required_entries() + [('feature/manifest/AndroidManifest.xml', b'new module')],
            required_entries()[1:],
        )
        for entries in cases:
            with self.subTest(names=[item[0] for item in entries]):
                with zipfile.ZipFile(archive_bytes(entries)) as archive:
                    with self.assertRaises(RuntimeError):
                        verifier.archive_inventory(archive)

    def test_synthetic_16k_elf_and_wrong_arch_alignment_or_bounds(self):
        name = 'base/lib/arm64-v8a/libsynthetic.so'
        valid = synthetic_elf()
        with zipfile.ZipFile(archive_bytes([(name, valid)])) as archive:
            result = verifier.validate_native_library(archive, name, 'arm64-v8a')
        self.assertEqual(result['sha256'], hashlib.sha256(valid).hexdigest())
        self.assertEqual(result['loadSegments'], 1)
        out_of_bounds = bytearray(valid)
        struct.pack_into('<Q', out_of_bounds, 32, 4000)
        no_load = bytearray(valid)
        struct.pack_into('<I', no_load, 64, 4)
        mismatched_offset = bytearray(valid)
        struct.pack_into('<Q', mismatched_offset, 72, 1)
        for data in (synthetic_elf(alignment=4096), synthetic_elf(machine=62),
                     bytes(out_of_bounds), bytes(no_load), bytes(mismatched_offset), valid[:50]):
            with self.subTest(prefix=data[:24]):
                with zipfile.ZipFile(archive_bytes([(name, data)])) as archive:
                    with self.assertRaises(RuntimeError):
                        verifier.validate_native_library(archive, name, 'arm64-v8a')


class SyntheticPayloadContracts(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / 'config').mkdir()
        (self.root / 'assets/audio/voice/lumo_free').mkdir(parents=True)
        self.pin = {'repository': 'https://example.invalid/synthetic-native.git',
                    'revision': 'a' * 40, 'engine': '4.6.3'}
        license_bytes = b'synthetic model license'
        model_bytes = b'synthetic model bytes, not a usable model'
        self.config = {
            'profile': 'synthetic-free-profile', 'preset': 'F2', 'speaker_id': 1,
            'sample_rate': 44100, 'onnxruntime_version': 'synthetic',
            'file_sha256': {'synthetic.onnx': hashlib.sha256(model_bytes).hexdigest()},
            'model_license_sha256': hashlib.sha256(license_bytes).hexdigest(),
        }
        clips = {f'clip-{i}': {'id': f'free_{i:016x}',
                             'asset_sha256': hashlib.sha256(f'clip-{i}'.encode()).hexdigest()}
                 for i in range(150)}
        self.catalog = {'variant': self.config['profile'], 'preset': 'F2',
                        'speaker_id': 1, 'machine_generated': True, 'clips': clips}
        (self.root / 'config/godot-source.json').write_text(json.dumps(self.pin))
        (self.root / 'config/lumo-offline-voice.json').write_text(json.dumps(self.config))
        (self.root / 'assets/audio/voice/lumo_free/catalog.json').write_text(json.dumps(self.catalog))
        self.pack = struct.pack('<4s4I', b'GDPC', 3, 4, 6, 3) + b'synthetic pack'
        receipt = {**self.pin, 'bytes': len(self.pack),
                   'pck_sha256': hashlib.sha256(self.pack).hexdigest()}
        self.entries = dict(required_entries())
        self.entries.update({
            'base/assets/lumo_game.pck': self.pack,
            'base/assets/lumo_game_source.json': json.dumps(receipt).encode(),
            'base/assets/lumo_offline_voice/model-manifest.json': json.dumps(self.config).encode(),
            'base/assets/lumo_offline_voice/synthetic.onnx': model_bytes,
            'base/assets/flutter_assets/assets/audio/voice/lumo_free/catalog.json':
                json.dumps(self.catalog).encode(),
        })
        for prefix in ('base/assets/lumo_offline_voice/',
                       'base/assets/flutter_assets/assets/audio/voice/lumo_free/'):
            self.entries[prefix + 'LICENSE-MODEL.txt'] = license_bytes
            self.entries[prefix + 'LICENSE-CODE.txt'] = b'synthetic code license'
        for i, clip in enumerate(clips.values()):
            self.entries['base/assets/flutter_assets/assets/audio/voice/lumo_free/'
                         + clip['id'] + '.m4a'] = f'clip-{i}'.encode()
        for abi, machine in (('arm64-v8a', 183), ('x86_64', 62)):
            for library in ('libapp.so', 'libflutter.so', 'libgodot_android.so',
                            'libonnxruntime.so', 'libonnxruntime4j_jni.so'):
                self.entries[f'base/lib/{abi}/{library}'] = synthetic_elf(machine=machine)

    def validate(self):
        with zipfile.ZipFile(archive_bytes(self.entries.items())) as archive:
            return verifier.validate_payload(archive, self.root)

    def test_complete_synthetic_payload_runs_real_byte_and_identity_guards(self):
        result = self.validate()
        self.assertEqual(result['godot']['revision'], self.pin['revision'])
        self.assertEqual(result['offlineVoice']['clipCount'], 150)
        self.assertEqual(len(result['nativeLibraries']), 10)
        self.assertIn('not the Play', result['baseSizeScope'])

    def test_changed_pck_and_voice_bytes_are_rejected(self):
        for name in ('base/assets/lumo_game.pck',
                     'base/assets/lumo_offline_voice/synthetic.onnx',
                     'base/assets/flutter_assets/assets/audio/voice/lumo_free/free_0000000000000000.m4a'):
            original = self.entries[name]
            with self.subTest(member=name):
                self.entries[name] += b'changed'
                try:
                    with self.assertRaises(RuntimeError):
                        self.validate()
                finally:
                    self.entries[name] = original

    def test_wrong_native_pin_missing_library_or_unexpected_abi_are_rejected(self):
        original = self.entries['base/assets/lumo_game_source.json']
        wrong = json.loads(original)
        wrong['revision'] = 'b' * 40
        self.entries['base/assets/lumo_game_source.json'] = json.dumps(wrong).encode()
        with self.assertRaisesRegex(RuntimeError, 'Godot source identity'):
            self.validate()
        self.entries['base/assets/lumo_game_source.json'] = original
        library = 'base/lib/x86_64/libgodot_android.so'
        original_library = self.entries.pop(library)
        with self.assertRaisesRegex(RuntimeError, 'Missing required'):
            self.validate()
        self.entries[library] = original_library
        self.entries['base/lib/armeabi-v7a/libapp.so'] = synthetic_elf()
        with self.assertRaisesRegex(RuntimeError, 'Unexpected native architectures'):
            self.validate()


class RealJdkRejectionContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.java = shutil.which('java')
        if cls.java is None:
            raise unittest.SkipTest('JDK unavailable; real Java rejection checks were not run')

    def java_call(self, *arguments, environment=None):
        return subprocess.run(
            [self.java, str(verifier.JAVA_SOURCE), *arguments],
            capture_output=True, text=True, check=False, timeout=60, env=environment)

    def test_actual_java_source_rejects_invalid_command(self):
        result = self.java_call('invalid-command')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Expected preflight or verify', result.stderr)
        self.assertEqual(result.stdout, '')

    def test_actual_java_source_rejects_unsigned_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'unsigned-synthetic.aab'
            with zipfile.ZipFile(path, 'w') as archive:
                archive.writestr('META-INF/MANIFEST.MF', 'Manifest-Version: 1.0\r\n\r\n')
                archive.writestr('base/dex/classes.dex', b'explicit synthetic payload')
            result = self.java_call('verify', str(path), '1' * 64)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('unsigned or ambiguously signed', result.stderr)
        self.assertEqual(result.stdout, '')

    def test_actual_java_source_rejects_standard_debug_alias_without_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'not-a-real-key'
            path.write_bytes(b'no key is generated')
            environment = {**os.environ,
                           'LUMO_PLAY_STORE_FILE': str(path),
                           'LUMO_PLAY_KEY_ALIAS': 'androiddebugkey',
                           'LUMO_PLAY_STORE_PASSWORD': 'synthetic-secret',
                           'LUMO_PLAY_KEY_PASSWORD': 'synthetic-secret'}
            result = self.java_call('preflight', environment=environment)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('standard Android debug alias', result.stderr)
        self.assertNotIn('synthetic-secret', result.stderr)
        self.assertEqual(result.stdout, '')


if __name__ == '__main__':
    unittest.main()
