"""Explicit 2020 update contracts; synthetic policy fixtures never approve a release.

The shared preservation checks reuse the unchanged original 2017/2018 evidence.
The real 2020 wrapper and identity validators run until a deliberately blocked
Android boundary. Production version, native policy and receipts stay untouched.
"""
import contextlib
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import runpy
import sys
import tempfile
import types
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_update_preservation as legacy
from update_preservation import (reviewed_migration_versions,
                                 require_learning_preserved,
                                 require_post_update_learning_preserved)

_ROOT = Path(__file__).resolve().parents[3]


class Reviewed2020MigrationTests(unittest.TestCase):
    def test_2020_is_explicit_and_existing_version_pairs_are_preserved(self):
        self.assertIsNone(reviewed_migration_versions(2017, 2020))
        for version, flag in ((2018, 'allow_2018'), (2019, 'allow_2019'), (2020, 'allow_2020')):
            with self.subTest(version=version):
                self.assertEqual(reviewed_migration_versions(2017, version, **{flag: True}),
                                 (2017, version))

    def test_2020_opt_in_rejects_foreign_pairs_wrong_types_and_multiple_flags(self):
        for baseline, candidate, flags in (
            (2018, 2020, {'allow_2020': True}),
            (2017, 2019, {'allow_2020': True}),
            (2017, 2018, {'allow_2020': True}),
            (2017, 2021, {'allow_2020': True}),
            ('2017', 2020, {'allow_2020': True}),
            (2017, '2020', {'allow_2020': True}),
            (2017.0, 2020, {'allow_2020': True}),
            (True, 2020, {'allow_2020': True}),
            (2017, 2020, {'allow_2020': 1}),
            (2017, 2020, {'allow_2020': 0}),
            (2017, 2020, {'allow_2020': None}),
            (2017, 2020, {'allow_2020': 'true'}),
            (2017, 2020, {'allow_2020': True, 'allow_2018': True}),
            (2017, 2020, {'allow_2020': True, 'allow_2019': True}),
            (2017, 2020, {'allow_2018': True, 'allow_2019': True}),
        ):
            with self.subTest(pair=(baseline, candidate), flags=flags), self.assertRaises(RuntimeError):
                reviewed_migration_versions(baseline, candidate, **flags)

    def test_real_policy_rejects_unreviewed_2020_source_before_android(self):
        namespace = runpy.run_path(str(_ROOT / '.github/probes/lumo_2020_update_android_probe.py'),
                                  run_name='unreviewed_2020_contract')
        with self.assertRaisesRegex(ValueError, 'no reviewed native pin|revision mismatch'):
            namespace['reviewed_candidate_native']('version: 0.13.8+2020\n', json.dumps({
                'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                'revision': '0' * 40, 'engine': '4.6.3',
            }))


class Build2020IndependentEvidenceMigrationTests(legacy.Build2018IndependentEvidenceMigrationTests):
    def require(self, after=None, before=None, versions=(2017, 2020)):
        return require_learning_preserved(
            self.before if before is None else before,
            self.after if after is None else after, migration_versions=versions)

    def test_report_binds_the_2020_pair_without_changing_old_input(self):
        before, after = copy.deepcopy(self.before), copy.deepcopy(self.after)
        report = self.require()
        self.assertEqual((report['approved_migration']['from_version'],
                          report['approved_migration']['to_version']), (2017, 2020))
        self.assertEqual((self.before, self.after), (before, after))
        self.assertEqual(report['approved_migration']['records'],
                         self.require(versions=(2017, 2018))['approved_migration']['records'])

    def test_2020_restart_snapshots_still_require_exact_preserved_history(self):
        report = require_post_update_learning_preserved(
            self.before, self.after, self.after, migration_versions=(2017, 2020))
        self.assertEqual(report['after_update_exact']['correct_answers_preserved'], 1)
        self.assertEqual(report['baseline_history']['approved_migration']['to_version'], 2020)
        reformatted = dict(self.after)
        reformatted[self.key] = json.dumps(json.loads(self.after[self.key]), indent=2)
        self.require(reformatted)
        for later in (reformatted, self.before, self.change_record('correct', 2),
                      self.change_record('independentEvidence', dict(
                          version=1, correct=0, wrong=0, correctStreak=0, wrongStreak=0))):
            with self.subTest(snapshot=later[self.key]), self.assertRaises(RuntimeError):
                require_post_update_learning_preserved(
                    self.before, self.after, later, migration_versions=(2017, 2020))


class Nextgen2020UpdateWrapperExecutionTests(unittest.TestCase):
    """Execute the real wrapper and identity gates; stop before Android I/O."""
    source = 'a' * 40
    baseline_source = '47889f74a651b073965def70743417cf320b1eb9'
    baseline_native = '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57'
    package = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
    certificate = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
    boundary = 'TEST BOUNDARY: no Android device was contacted'

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.native = 'f' * 40  # Synthetic reviewed fixture, never a production pin.
        # Run byte-identical wrapper code against a temporary source fixture.
        # The real policy code is retained; only this isolated test fixture adds
        # a synthetic reviewed 2020 identity. Production APPROVED is untouched.
        source_fixture = self.directory / 'synthetic-reviewed-source'
        policy = source_fixture / 'scripts/verify_legacy_release_pin.py'
        policy.parent.mkdir(parents=True)
        policy.write_bytes((_ROOT / 'scripts/verify_legacy_release_pin.py').read_bytes()
                           + ("\n# Synthetic test-only identity; never production approval.\n"
                              f"APPROVED[2020] = {self.native!r}\n").encode())
        (source_fixture / 'pubspec.yaml').write_text('version: 0.13.8+2020\n')
        (source_fixture / 'config').mkdir()
        (source_fixture / 'config/godot-source.json').write_text(json.dumps({
            'repository': 'https://github.com/Ullmann27/lumo-godot.git',
            'revision': self.native, 'engine': '4.6.3',
        }))
        self.wrapper = source_fixture / '.github/probes/lumo_2020_update_android_probe.py'
        self.wrapper.parent.mkdir(parents=True)
        self.wrapper.write_bytes((_ROOT / '.github/probes/lumo_2020_update_android_probe.py').read_bytes())
        self.paths = {}
        for label, version, source, native in (
            ('baseline', 2017, self.baseline_source, self.baseline_native),
            ('candidate', 2020, self.source, self.native),
        ):
            folder = self.directory / label
            folder.mkdir()
            apk = folder / 'synthetic-metadata-fixture.apk'
            apk.write_bytes(f'METADATA VALIDATOR FIXTURE {version}; NOT AN APK'.encode())
            (folder / 'BUILD-PROVENANCE.json').write_text(json.dumps({
                'flutter_source_commit': source, 'tracked_source_clean': True,
                'versionCode': version, 'package': self.package,
                'signingCertificateSha256': self.certificate,
                'sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
                'abis': ['x86_64'], 'godot': {'revision': native},
            }))
            self.paths[label] = apk

    def run_wrapper(self):
        # Only external device boundaries are replaced. The real wrapper,
        # reviewed-pin policy, main() and APK identity validators all execute.
        tour = types.ModuleType('modernization_android_tour')
        tour.PACKAGE = self.package
        tour.probe = types.SimpleNamespace(
            CERT=self.certificate,
            ensure_rooted_emulator=mock.Mock(side_effect=RuntimeError(self.boundary)),
            capture=mock.Mock(),
        )
        tour.base = types.SimpleNamespace(adb=mock.Mock(return_value=''))
        tour.live = types.SimpleNamespace()
        name = 'lumo_2003_update_android_probe'
        spec = importlib.util.spec_from_file_location(
            name, _ROOT / '.github/probes/lumo_2003_update_android_probe.py')
        module = importlib.util.module_from_spec(spec)
        output = self.directory / 'result'
        arguments = ['lumo_2020_update_android_probe.py',
                     '--baseline', str(self.paths['baseline']),
                     '--candidate', str(self.paths['candidate']), '--out', str(output)]
        with mock.patch.dict(sys.modules, {'modernization_android_tour': tour, name: module}), \
                mock.patch.dict(os.environ, {'LUMO_CANDIDATE_SOURCE_SHA': self.source}), \
                mock.patch.object(sys, 'argv', arguments), \
                contextlib.redirect_stdout(io.StringIO()):
            spec.loader.exec_module(module)
            with self.assertRaises(SystemExit) as stopped:
                runpy.run_path(str(self.wrapper),
                               run_name='__main__')
        # This unit probe deliberately cannot issue Android PASS.
        self.assertEqual(stopped.exception.code, 1)
        tour.base.adb.assert_called_once_with('logcat', '-d', timeout=60)
        report = json.loads((output / 'update-result.json').read_text())
        self.assertEqual(report['status'], 'FAIL')
        return report, tour.probe.ensure_rooted_emulator

    def test_actual_2020_wrapper_validates_both_artifacts_before_device_boundary(self):
        report, boundary = self.run_wrapper()
        self.assertEqual(report['error'], self.boundary)
        self.assertEqual(report['baseline']['versionCode'], 2017)
        self.assertEqual(report['candidate']['versionCode'], 2020)
        self.assertEqual(report['candidate_source'], self.source)
        boundary.assert_called_once()

    def test_actual_wrapper_does_not_bypass_baseline_or_candidate_identity(self):
        invalid = [
            ('baseline', {'versionCode': 2016}),
            ('baseline', {'flutter_source_commit': 'b' * 40}),
            ('candidate', {'versionCode': 2018}),
            ('candidate', {'tracked_source_clean': False}),
            ('candidate', {'flutter_source_commit': 'b' * 40}),
            ('candidate', {'signingCertificateSha256': 'untrusted'}),
            ('candidate', {'package': 'another.app'}),
            ('candidate', {'sha256': '0' * 64}),
            ('candidate', {'abis': ['arm64-v8a']}),
            ('candidate', {'godot': {'revision': self.baseline_native}}),
        ]
        for label, changes in invalid:
            path = self.paths[label].parent / 'BUILD-PROVENANCE.json'
            original = path.read_bytes()
            with self.subTest(label=label, changes=changes):
                try:
                    path.write_text(json.dumps({**json.loads(original), **changes}))
                    report, boundary = self.run_wrapper()
                    self.assertIn(report['error'], (
                        'Artifact provenance does not identify the expected APK',
                        'Update gate requires the actual x86_64 native APK',
                        'Native source is not the reviewed pin',
                    ))
                    boundary.assert_not_called()
                finally:
                    path.write_bytes(original)


if __name__ == '__main__':
    unittest.main()
