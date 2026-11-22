"""Reject stale or mixed builds before publishing or starting an APK tour."""

import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile


spec = importlib.util.spec_from_file_location(
    'verify_test_apk_candidate', Path(__file__).resolve().parents[1] / 'verify_test_apk_candidate.py')
candidate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(candidate)


class TestApkCandidateTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / 'config').mkdir()
        (self.root / 'pubspec.yaml').write_text('name: test_candidate\nversion: 0.13.54+2066\n')
        (self.root / 'config/test-apk-request.json').write_text(json.dumps({'version': '0.13.54+2066'}))
        self.pin = {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                    'revision': 'a' * 40, 'engine': '4.6.3'}
        (self.root / 'config/godot-source.json').write_text(json.dumps(self.pin))
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        self.commit()
        self.expected = candidate.source_identity(self.root)
        self.arm64 = self.root / 'dist'
        self.emulator = self.arm64 / 'x86_64'
        self.make_package(self.arm64, 'arm64-v8a')
        self.make_package(self.emulator, 'x86_64')

    def commit(self):
        subprocess.run(['git', '-C', str(self.root), 'add', 'pubspec.yaml', 'config'], check=True)
        subprocess.run(['git', '-C', str(self.root), '-c', 'user.name=Candidate regression',
                        '-c', 'user.email=regression@example.invalid', 'commit', '-qm', 'Fixture'],
                       check=True)

    def make_package(self, directory, abi, *, pck=b'GDPC candidate test payload', actual_abi=None):
        directory.mkdir(parents=True, exist_ok=True)
        godot = {**self.pin, 'pck_sha256': hashlib.sha256(pck).hexdigest(), 'bytes': len(pck)}
        apk = directory / candidate.APK_NAME
        with zipfile.ZipFile(apk, 'w') as archive:
            archive.writestr('assets/lumo_game.pck', pck)
            archive.writestr('assets/lumo_game_source.json', json.dumps(godot))
            archive.writestr(f'lib/{actual_abi or abi}/libapp.so', b'ABI linkage fixture')
        digest = hashlib.sha256(apk.read_bytes()).hexdigest()
        verified = {'package': candidate.PACKAGE, 'versionName': '0.13.54', 'versionCode': 2066,
                    'abis': [abi], 'minSdk': 24, 'targetSdk': 36, 'elf16KiBAligned': True,
                    'resourcesArscAligned': True, 'sha256': digest, 'bytes': apk.stat().st_size,
                    'signingCertificateSha256': '1' * 64, 'godot': godot}
        provenance = {**verified, 'flutter_source_commit': self.expected['flutter_source_commit'],
                      'tracked_source_clean': True}
        self.write_reports(directory, verified, provenance)
        (directory / 'SHA256SUMS.txt').write_text(f'{digest}  {candidate.APK_NAME}\n')

    def write_reports(self, directory, verified, provenance):
        (directory / 'APK-VERIFICATION.json').write_text(json.dumps(verified))
        (directory / 'BUILD-PROVENANCE.json').write_text(json.dumps(provenance))

    def change_report(self, directory, key, value, *, both=False):
        files = ['BUILD-PROVENANCE.json']
        if both:
            files.append('APK-VERIFICATION.json')
        for name in files:
            path = directory / name
            data = json.loads(path.read_text())
            data[key] = value
            path.write_text(json.dumps(data))

    def verify(self, **kwargs):
        return candidate.verify_pair(self.root, self.arm64, self.emulator, **kwargs)

    def test_pair_links_distinct_apks_to_one_source_and_extracts_actual_arm64_pck(self):
        extracted = self.root / 'probe/game.pck'
        report = self.verify(expected_commit=self.expected['flutter_source_commit'], extract_pck=extracted)
        self.assertTrue(report['same_pck'])
        self.assertNotEqual(report['packages']['arm64-v8a']['sha256'], report['packages']['x86_64']['sha256'])
        self.assertEqual(extracted.read_bytes(), b'GDPC candidate test payload')
        self.assertIn('not a physical ARM64 device test', report['runtime_scope'])

    def test_old_build_request_cannot_label_new_sources(self):
        (self.root / 'config/test-apk-request.json').write_text(json.dumps({'version': '0.13.53+2065'}))
        self.commit()
        with self.assertRaisesRegex(ValueError, 'request version differs'):
            candidate.source_identity(self.root)

    def test_wrong_checkout_or_modified_sources_fail_before_build(self):
        with self.assertRaisesRegex(ValueError, 'requested Flutter commit'):
            candidate.source_identity(self.root, 'b' * 40)
        (self.root / 'pubspec.yaml').write_text('version: 0.13.55+2067\n')
        with self.assertRaisesRegex(ValueError, 'uncommitted changes'):
            candidate.source_identity(self.root)

    def test_previous_emulator_build_is_not_evidence_for_new_arm64_build(self):
        self.change_report(self.emulator, 'flutter_source_commit', 'b' * 40)
        with self.assertRaisesRegex(ValueError, 'candidate flutter_source_commit mismatch'):
            self.verify()

    def test_different_pck_is_rejected_even_with_internally_consistent_apk_reports(self):
        self.make_package(self.emulator, 'x86_64', pck=b'GDPC other game payload')
        with self.assertRaisesRegex(ValueError, 'ARM64/emulator godot_pck_sha256 mismatch'):
            self.verify()

    def test_mutated_apk_bytes_cannot_reuse_verified_provenance(self):
        with (self.arm64 / candidate.APK_NAME).open('ab') as stream:
            stream.write(b'changed after verification')
        with self.assertRaisesRegex(ValueError, 'actual APK digest mismatch'):
            self.verify()

    def test_actual_abi_is_checked_inside_apk(self):
        self.make_package(self.arm64, 'arm64-v8a', actual_abi='x86_64')
        with self.assertRaisesRegex(ValueError, 'actual APK native architectures mismatch'):
            self.verify()

    def test_changed_verification_cannot_be_hidden_by_provenance(self):
        self.change_report(self.emulator, 'versionCode', 2065)
        with self.assertRaisesRegex(ValueError, 'differs from the APK verification'):
            self.verify()

    def test_consistent_but_old_version_is_still_rejected(self):
        self.change_report(self.emulator, 'versionCode', 2065, both=True)
        with self.assertRaisesRegex(ValueError, 'candidate versionCode mismatch'):
            self.verify()

    def test_both_packages_must_use_same_verified_signing_certificate(self):
        self.change_report(self.emulator, 'signingCertificateSha256', '2' * 64, both=True)
        with self.assertRaisesRegex(ValueError, 'ARM64/emulator signingCertificateSha256 mismatch'):
            self.verify()


if __name__ == '__main__':
    unittest.main()
