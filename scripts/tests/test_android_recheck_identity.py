"""Synthetic byte/source contracts for the diagnostic; no Android PASS is implied."""
import ast
from copy import deepcopy
from dataclasses import replace
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import verify_android_recheck_identity as gate


class RecheckIdentityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.dist = self.root / 'dist'
        (self.dist / 'x86_64').mkdir(parents=True)
        self.pack = struct.pack('<4s4I', b'GDPC', 2, 4, 6, 3) + b'synthetic unit fixture'
        self.native = {'revision': gate.EXPECTED.native, 'engine': '4.6.3',
                       'pck_sha256': hashlib.sha256(self.pack).hexdigest(), 'bytes': len(self.pack)}
        self.apk = self.dist / 'x86_64/Lumo-Lernen-Neu.apk'
        self.write_apk(self.pack)
        self.expected = replace(gate.EXPECTED, apk_bytes=self.apk.stat().st_size,
                                apk_sha256=gate.digest(self.apk), pck_bytes=len(self.pack),
                                pck_sha256=self.native['pck_sha256'])
        self.proof = {'flutter_source_commit': self.expected.source, 'tracked_source_clean': True,
                      'package': self.expected.package, 'versionCode': 2019, 'versionName': '0.13.7',
                      'abis': ['x86_64'], 'bytes': self.expected.apk_bytes,
                      'sha256': self.expected.apk_sha256,
                      'signingCertificateSha256': self.expected.certificate, 'godot': self.native}
        self.save_proof()
        (self.dist / 'ANDROID-TOUR-SHA256SUMS.txt').write_text(
            self.expected.apk_sha256 + '  dist/x86_64/Lumo-Lernen-Neu.apk\n')

    def write_apk(self, pack):
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('assets/lumo_game.pck', pack)
            archive.writestr('assets/lumo_game_source.json', json.dumps(self.native))

    def save_proof(self):
        (self.dist / 'x86_64/BUILD-PROVENANCE.json').write_text(json.dumps(self.proof))

    def metadata(self):
        e = self.expected
        artifact = {'id': e.artifact, 'name': e.artifact_name, 'size_in_bytes': e.artifact_bytes,
                    'digest': 'sha256:' + e.artifact_sha256, 'expired': False,
                    'workflow_run': {'id': e.run, 'head_sha': e.source}}
        run = {'id': e.run, 'head_sha': e.source, 'repository': {'full_name': e.repository},
               'path': '.github/workflows/lumo-studio-2019.yml', 'conclusion': 'failure'}
        job = {'id': e.build_job, 'run_id': e.run, 'head_sha': e.source,
               'name': 'verify-and-build', 'status': 'completed', 'conclusion': 'success',
               'steps': [{'name': name, 'status': 'completed', 'conclusion': 'success'} for name in (
                   'Build unified real Android APK',
                   'Verify APK archive and collect reproducible source hashes',
                   'Upload exact candidate (no release or synthetic screenshots)')]}
        return artifact, run, job

    def test_exact_bytes_can_be_rechecked_after_a_later_android_job_failed(self):
        gate.verify_original_metadata(*self.metadata(), self.expected)
        result = gate.verify_candidate(self.dist, self.expected)
        self.assertEqual(result['apk_source_commit'], self.expected.source)
        self.assertEqual(result['pck_sha256'], self.native['pck_sha256'])

    def test_wrong_artifact_origin_digest_or_failed_build_is_rejected(self):
        cases = [('artifact-id', 0, 'id', 1), ('artifact-digest', 0, 'digest', 'sha256:' + '0' * 64),
                 ('expired', 0, 'expired', True), ('run-source', 1, 'head_sha', 'f' * 40),
                 ('build-source', 2, 'head_sha', 'f' * 40), ('build-failed', 2, 'conclusion', 'failure')]
        for name, index, key, value in cases:
            with self.subTest(name=name):
                values = self.metadata()
                values[index][key] = value
                with self.assertRaises(RuntimeError):
                    gate.verify_original_metadata(*values, self.expected)
        values = self.metadata()
        values[2]['steps'].pop()
        with self.assertRaisesRegex(RuntimeError, 'successful step'):
            gate.verify_original_metadata(*values, self.expected)

    def test_wrong_app_source_native_version_signature_or_actual_apk_fails(self):
        original = deepcopy(self.proof)
        for key, value in [('flutter_source_commit', 'f' * 40), ('tracked_source_clean', False),
                           ('versionCode', 2018), ('versionName', '0.13.6'),
                           ('signingCertificateSha256', '0' * 64), ('abis', ['arm64-v8a']),
                           ('godot', {**self.native, 'revision': 'f' * 40})]:
            with self.subTest(field=key):
                self.proof = {**original, key: value}
                self.save_proof()
                with self.assertRaises(RuntimeError):
                    gate.verify_candidate(self.dist, self.expected)
        self.proof = original
        self.save_proof()
        with self.apk.open('ab') as output:
            output.write(b'changed bytes')
        with self.assertRaisesRegex(RuntimeError, 'Actual x86 APK bytes'):
            gate.verify_candidate(self.dist, self.expected)

    def test_pack_bytes_are_read_even_when_new_apk_metadata_agrees(self):
        self.write_apk(self.pack[:-1] + b'!')
        altered = replace(self.expected, apk_bytes=self.apk.stat().st_size,
                          apk_sha256=gate.digest(self.apk))
        self.proof.update(sha256=altered.apk_sha256, bytes=altered.apk_bytes)
        self.save_proof()
        (self.dist / 'ANDROID-TOUR-SHA256SUMS.txt').write_text(
            altered.apk_sha256 + '  dist/x86_64/Lumo-Lernen-Neu.apk\n')
        with self.assertRaisesRegex(RuntimeError, 'Actual embedded PCK bytes'):
            gate.verify_candidate(self.dist, altered)

    def checkout(self, name):
        path = self.root / name
        path.mkdir()
        (path / 'config').mkdir()
        (path / 'pubspec.yaml').write_text('version: 0.13.7+2019\n')
        (path / 'config/godot-source.json').write_text(json.dumps({'revision': self.expected.native}))
        (path / 'identity.txt').write_text(name)
        subprocess.run(['git', 'init', '-q', str(path)], check=True)
        subprocess.run(['git', '-C', str(path), 'add', '.'], check=True)
        subprocess.run(['git', '-C', str(path), '-c', 'user.name=Fixture',
                        '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'fixture'], check=True)
        head = subprocess.check_output(['git', '-C', str(path), 'rev-parse', 'HEAD'], text=True).strip()
        return path, head

    def test_source_check_requires_real_head_and_unchanged_tracked_files(self):
        path, head = self.checkout('identity')
        self.assertEqual(gate.source_checkout(path, head)['revision'], head)
        with self.assertRaisesRegex(RuntimeError, 'declared commit'):
            gate.source_checkout(path, 'f' * 40)
        (path / 'identity.txt').write_text('dirty')
        with self.assertRaisesRegex(RuntimeError, 'Tracked source changed'):
            gate.source_checkout(path, head)

    def test_unchanged_original_tour_reads_the_real_apk_checkout_head(self):
        apk_source, apk_head = self.checkout('apk-source')
        probe_source, probe_head = self.checkout('probe-source')
        self.assertNotEqual(apk_head, probe_head)
        self.proof['flutter_source_commit'] = apk_head
        self.save_proof()
        source = ROOT / '.github/probes/modernization_android_tour.py'
        function = next(node for node in ast.parse(source.read_text()).body
                        if isinstance(node, ast.FunctionDef) and node.name == 'verify_apk_identity')
        scope = {'Path': Path, 'json': json, 're': re,
                 'probe': SimpleNamespace(digest=gate.digest, CERT=self.expected.certificate),
                 'base': SimpleNamespace(command=lambda *argv: subprocess.check_output(argv, text=True))}
        exec(compile(ast.Module(body=[function], type_ignores=[]), str(source), 'exec'), scope)
        original_cwd = Path.cwd()
        try:
            os.chdir(apk_source)
            accepted = scope['verify_apk_identity'](
                self.apk, self.dist / 'x86_64/BUILD-PROVENANCE.json',
                self.dist / 'ANDROID-TOUR-SHA256SUMS.txt')
            self.assertTrue(accepted['checks']['flutter_source_is_this_commit'])
            os.chdir(probe_source)
            with self.assertRaisesRegex(RuntimeError, 'flutter_source_is_this_commit'):
                scope['verify_apk_identity'](
                    self.apk, self.dist / 'x86_64/BUILD-PROVENANCE.json',
                    self.dist / 'ANDROID-TOUR-SHA256SUMS.txt')
        finally:
            os.chdir(original_cwd)


if __name__ == '__main__':
    unittest.main()
