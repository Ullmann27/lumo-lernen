"""Historical expectation contracts; synthetic ZIPs, not signed Android proof.

Only the external APK signature and aapt readers are stubbed. Git commit reads,
the current verifier, voice hashes, PCK, ABI and resource checks execute normally.
"""
from contextlib import redirect_stdout
import hashlib
import io
import json
import os
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_android_apk
import verify_unified_apk as verifier
import test_unified_apk_voice as voice_fixtures

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
HISTORICAL_COMMIT = 'c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf'
HISTORICAL_CHECKOUT = 'historical-1999-source'


class HistoricalApkExpectationsTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.source = self.directory / 'source'
        self.source.mkdir()
        self.files, config, catalog = voice_fixtures.UnifiedApkVoiceTest().fixture()
        self.pin = '4d0fd40fdf188be6ca86057596c7b51f41701fa3'
        expected = {
            'pubspec.yaml': 'name: synthetic_fixture\nversion: 0.12.87+1999\n',
            'config/godot-source.json': json.dumps({'revision': self.pin}),
            'config/lumo-offline-voice.json': json.dumps(config),
            'assets/audio/voice/lumo_free/catalog.json': json.dumps(catalog),
        }
        for name, content in expected.items():
            destination = self.source / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(content)
        self.real_check_output = subprocess.check_output
        self.git('init', '-q')
        self.git('add', '.')
        self.git('-c', 'user.name=Contract Fixture', '-c',
                 'user.email=fixture@example.invalid', 'commit', '-qm', 'Synthetic historical inputs')
        self.revision = self.git('rev-parse', 'HEAD').strip()
        self.package = PACKAGE
        self.version_name = '0.12.87'
        self.version_code = '1999'
        self.xml = 'LumoGameActivity :lumo_game'
        self.resource_compression = zipfile.ZIP_STORED
        self.pack = struct.pack('<4s4I', b'GDPC', 3, 4, 6, 3) + b'synthetic PCK payload'
        self.files['assets/lumo_game.pck'] = self.pack
        self.files['assets/lumo_game_source.json'] = json.dumps({
            'revision': self.pin, 'pck_sha256': hashlib.sha256(self.pack).hexdigest(),
        }).encode()
        self.files['resources.arsc'] = b'synthetic resources, not an Android application'
        self.certificate = self.enterContext(patch.object(
            verifier, 'verify_apk', return_value=verifier.EXPECTED_SIGNING_CERT_SHA256))
        self.enterContext(patch.object(verifier, 'find_apksigner', return_value='/fixture-tools/apksigner'))
        self.enterContext(patch.object(verifier.subprocess, 'check_output', side_effect=self.tool_output))
        self.enterContext(patch.dict(os.environ))
        os.environ.pop('LUMO_BUILD_NUMBER', None)
        os.environ.pop('LUMO_VERSION_NAME', None)

    def git(self, *arguments):
        return self.real_check_output(['git', '-C', str(self.source), *arguments], text=True)

    def tool_output(self, command, **kwargs):
        if command[0] == 'git':
            return self.real_check_output(command, **kwargs)
        if command[:3] == ['/fixture-tools/aapt', 'dump', 'badging']:
            return (f"package: name='{self.package}' versionCode='{self.version_code}' "
                    f"versionName='{self.version_name}'\nsdkVersion:'24'\ntargetSdkVersion:'36'\n")
        if command[:3] == ['/fixture-tools/aapt', 'dump', 'xmltree']:
            return self.xml
        raise AssertionError(f'Unexpected external command: {command}')

    @staticmethod
    def elf(alignment=16384):
        data = bytearray(120)
        data[:6] = b'\x7fELF\x02\x01'
        struct.pack_into('<Q', data, 32, 64)
        struct.pack_into('<HH', data, 54, 56, 1)
        struct.pack_into('<I', data, 64, 1)
        struct.pack_into('<Q', data, 112, alignment)
        return data

    def apk(self, abi='arm64-v8a', *, omitted_library=None, alignment=16384):
        files = {key: value for key, value in self.files.items() if not key.startswith('lib/')}
        for library in ('libflutter.so', 'libapp.so', 'libgodot_android.so',
                        'libonnxruntime.so', 'libonnxruntime4j_jni.so'):
            if library != omitted_library:
                files[f'lib/{abi}/{library}'] = self.elf(alignment)
        path = self.directory / f'fixture-{abi}.apk'
        with zipfile.ZipFile(path, 'w') as archive:
            # The first local header is 30 + 14 bytes: a real 4-byte alignment.
            archive.writestr('resources.arsc', files.pop('resources.arsc'),
                             compress_type=self.resource_compression)
            for name, content in files.items():
                archive.writestr(name, content)
        return path

    def verify(self, abi='arm64-v8a', *, apk=None, **overrides):
        arguments = dict(expectations_repository=self.source, expectations_revision=self.revision)
        arguments.update(overrides)
        with redirect_stdout(io.StringIO()):
            return verifier.verify(apk or self.apk(abi), {abi}, **arguments)

    def test_original_default_reproduces_current_version_mismatch(self):
        with self.assertRaisesRegex(RuntimeError, r'Wrong Android version: 0\.12\.87\+1999, expected'):
            verifier.verify(self.apk(), {'arm64-v8a'})

    def test_exact_commit_inputs_allow_both_historical_abis(self):
        for abi in ('arm64-v8a', 'x86_64'):
            with self.subTest(abi=abi):
                result = self.verify(abi)
                self.assertEqual(result['versionCode'], 1999)
                self.assertEqual(result['versionName'], '0.12.87')
                self.assertEqual(result['godot']['revision'], self.pin)
                self.assertEqual(result['signingCertificateSha256'], verifier.EXPECTED_SIGNING_CERT_SHA256)
                self.assertEqual(result['expectationsSource']['revision'], self.revision)
                self.assertEqual(len(result['expectationsSource']['files']), 4)
                self.assertEqual(result['offlineVoice']['clipCount'], 150)
                self.assertTrue(result['elf16KiBAligned'] and result['resourcesArscAligned'])

    def test_changed_working_copy_cannot_replace_committed_expectations(self):
        (self.source / 'pubspec.yaml').write_text('version: 0.13.7+2019\n')
        (self.source / 'config/godot-source.json').write_text(json.dumps({'revision': 'f' * 40}))
        result = self.verify()
        self.assertEqual(result['versionCode'], 1999)
        self.assertEqual(result['godot']['revision'], self.pin)

    def test_revision_must_be_a_full_immutable_commit(self):
        for revision in ('HEAD', 'main', self.revision[:8], '0' * 40):
            with self.subTest(revision=revision), self.assertRaises((RuntimeError, subprocess.CalledProcessError)):
                self.verify(expectations_revision=revision)

    def test_repository_and_revision_must_be_supplied_together(self):
        for missing in ('expectations_repository', 'expectations_revision'):
            with self.subTest(missing=missing), self.assertRaisesRegex(RuntimeError, 'together'):
                self.verify(**{missing: None})

    def test_environment_cannot_replace_source_bound_version(self):
        for name, value in (('LUMO_BUILD_NUMBER', '2019'), ('LUMO_VERSION_NAME', '0.13.7')):
            with self.subTest(name=name), patch.dict(os.environ, {name: value}):
                with self.assertRaisesRegex(RuntimeError, 'source-bound'):
                    self.verify()

    def test_wrong_package_or_version_is_still_rejected(self):
        for attribute, value, message in (
            ('package', 'org.example.unrelated', 'Wrong package'),
            ('version_code', '2019', 'Wrong Android version'),
            ('version_name', '0.13.7', 'Wrong Android version'),
        ):
            with self.subTest(attribute=attribute), patch.object(self, attribute, value):
                with self.assertRaisesRegex(RuntimeError, message):
                    self.verify()

    def test_fixed_family_certificate_is_still_required(self):
        self.certificate.return_value = 'd' * 64
        with self.assertRaisesRegex(RuntimeError, 'Signing certificate SHA-256'):
            self.verify()

    def test_exact_abi_and_embedded_godot_library_are_still_required(self):
        with self.assertRaisesRegex(RuntimeError, 'Unexpected native architectures'):
            self.verify(apk=self.apk('x86_64'))
        with self.assertRaisesRegex(RuntimeError, 'libgodot_android'):
            self.verify(apk=self.apk(omitted_library='libgodot_android.so'))

    def test_voice_weights_clips_and_original_license_are_still_pinned(self):
        for name in ('assets/lumo_offline_voice/model.onnx',
                     'assets/flutter_assets/assets/audio/voice/lumo_free/free_0000000000000000.m4a',
                     'assets/lumo_offline_voice/LICENSE-MODEL.txt'):
            with self.subTest(file=name), patch.dict(self.files, {name: b'changed bytes'}):
                with self.assertRaisesRegex(RuntimeError, 'digest mismatch|license missing or changed'):
                    self.verify()

    def test_pck_digest_and_historical_native_revision_are_still_required(self):
        for field, value, message in (
            ('revision', 'f' * 40, 'Wrong Godot source revision'),
            ('pck_sha256', 'f' * 64, 'Embedded PCK digest mismatch'),
        ):
            content = json.loads(self.files['assets/lumo_game_source.json'])
            content[field] = value
            with self.subTest(field=field), patch.dict(self.files, {
                    'assets/lumo_game_source.json': json.dumps(content).encode()}):
                with self.assertRaisesRegex(RuntimeError, message):
                    self.verify()

    def test_native_page_alignment_and_resource_packaging_are_still_required(self):
        with self.assertRaisesRegex(RuntimeError, '16-KiB load alignment'):
            self.verify(apk=self.apk(alignment=4096))
        self.resource_compression = zipfile.ZIP_DEFLATED
        with self.assertRaisesRegex(RuntimeError, 'uncompressed resources'):
            self.verify()

    def test_private_activity_and_release_manifest_are_still_required(self):
        for xml, message in (('unrelated activity', 'Private embedded'),
                             ('LumoGameActivity :lumo_game android:debuggable 0xffffffff', 'debuggable')):
            with self.subTest(xml=xml), patch.object(self, 'xml', xml):
                with self.assertRaisesRegex(RuntimeError, message):
                    self.verify()

    def test_actual_cli_passes_commit_bound_inputs_to_the_current_verifier(self):
        apk = self.apk()
        arguments = [str(ROOT / 'scripts/verify_unified_apk.py'), str(apk), '--abi', 'arm64-v8a',
                     '--expectations-repository', str(self.source),
                     '--expectations-revision', self.revision]
        with patch.object(verify_android_apk, 'verify_apk', return_value=verifier.EXPECTED_SIGNING_CERT_SHA256), \
                patch.object(verify_android_apk, 'find_apksigner', return_value='/fixture-tools/apksigner'), \
                patch.object(sys, 'argv', arguments), redirect_stdout(io.StringIO()) as output:
            runpy.run_path(str(ROOT / 'scripts/verify_unified_apk.py'), run_name='__main__')
        result = json.loads(output.getvalue())
        self.assertEqual(result['versionCode'], 1999)
        self.assertEqual(result['expectationsSource']['revision'], self.revision)


class HistoricalWorkflowContractTest(unittest.TestCase):
    def test_only_expectations_are_pinned_while_current_probes_and_guards_remain(self):
        source = (ROOT / '.github/workflows/lumo-1999-update-gate.yml').read_text()
        self.assertIn(f'ref: {HISTORICAL_COMMIT}', source)
        self.assertIn(f'path: {HISTORICAL_CHECKOUT}', source)
        calls = re.findall(r'^\s*python3 scripts/verify_unified_apk.py (.+)$', source, re.M)
        self.assertEqual(len(calls), 2)
        for call, abi in zip(calls, ('arm64-v8a', 'x86_64')):
            self.assertIn(f'--abi {abi}', call)
            self.assertIn(f'--expectations-repository {HISTORICAL_CHECKOUT}', call)
            self.assertIn(f'--expectations-revision {HISTORICAL_COMMIT}', call)
        for preserved in (
            'run-id: 40096024152', 'run-id: 39755153883',
            'python3 scripts/verify_android_apk.py baseline/dist/x86_64/Lumo-Lernen-Neu.apk',
            'test_update_preservation.py', 'test_kart_tour_evidence.py', 'test_modernization_tour_identity.py',
            'script: .update-python/bin/python .github/probes/candidate_update_android_probe.py --baseline baseline/dist/x86_64/Lumo-Lernen-Neu.apk --candidate candidate/dist/x86_64/Lumo-Lernen-Neu.apk --out update-proof',
        ):
            self.assertIn(preserved, source)
        self.assertNotIn('continue-on-error:', source)
        self.assertNotIn('LUMO_BUILD_NUMBER:', source)
        self.assertNotIn('LUMO_VERSION_NAME:', source)


if __name__ == '__main__':
    unittest.main()
