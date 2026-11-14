"""Keep the unchanged-APK diagnostic distinct from release acceptance."""
from __future__ import annotations

import ast
from contextlib import ExitStack
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import textwrap
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / '.github/probes'))
sys.path.insert(0, str(ROOT / 'scripts'))
spec = importlib.util.spec_from_file_location(
    'roundtrip_diagnostic_tested', ROOT / '.github/probes/lumo_6b_roundtrip_diagnostic.py')
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)


def source_method(path, class_name, method):
    text = path.read_text()
    tree = ast.parse(text)
    owner = next(node for node in tree.body if isinstance(node, ast.ClassDef) and node.name == class_name)
    function = next(node for node in owner.body if isinstance(node, ast.FunctionDef) and node.name == method)
    return '\n'.join(text.splitlines()[function.lineno - 1:function.end_lineno])


class DiagnosticJourneyPreservationTests(unittest.TestCase):
    def test_actual_original_apk_bindings_are_exact(self):
        expected = {
            'HOST': '6b3047b7979dfb86d837e74a21b0fd890e4f9e66',
            'HOST_TREE': '8b0c31a26207068c28658e14c6535c39a51cf95b',
            'NATIVE': '84789d0c2c6fb4b6ecd2897ce1951b89f958b604',
            'BUILD_RUN': 43616038272, 'BUILD_JOB': 132512734271,
            'BUILD_ATTEMPT': 1, 'ARTIFACT_ID': 14125990109,
            'ARTIFACT_BYTES': 665918783,
            'ARTIFACT_DIGEST': 'sha256:1332b1d6604ae45c622bc70fa08a6d40991f5e8c9332466c17622135b81b11a6',
            'APK_BYTES': 334516947,
            'APK_SHA256': '9c64ae2f866c1eee832a96baba56d8d3dc314cec79c69c7c1781bb803111a765',
            'PCK_BYTES': 75401304,
            'PCK_SHA256': '99c68b1d68e4c8701c7e7e69f13137ff2b7f4d4a204c1a4a8f1bb0766e2720a4',
        }
        for name, value in expected.items():
            with self.subTest(name=name):
                self.assertIs(type(getattr(adapter.diagnostic, name)), type(value))
                self.assertEqual(getattr(adapter.diagnostic, name), value)

    def assert_preserved(self, kind, filename, class_name):
        original = textwrap.dedent(source_method(ROOT / '.github/probes' / filename, class_name, 'run'))
        text = (ROOT / '.github/probes/lumo_6b_roundtrip_diagnostic.py').read_text()
        function = next(node for node in ast.parse(text).body
                        if isinstance(node, ast.FunctionDef) and node.name == '_' + kind + '_run')
        actual = ast.get_source_segment(text, function)
        actual = actual.replace('def _' + kind + '_run(self)', 'def run(self)')
        self.assertEqual(actual.count("        result['diagnostic_binding'] = require_bound_diagnostic(self.args)\n"), 1)
        actual = actual.replace("        result['diagnostic_binding'] = require_bound_diagnostic(self.args)\n", '')
        actual = actual.replace('source == self.args.expected_qa_source', 'source == self.args.expected_source')
        actual = actual.replace('source=self.args.expected_source,', 'source=source,')
        if kind == 'village':
            actual = actual.replace("identity['flutter_source_commit'] == self.args.expected_source",
                                    "identity['flutter_source_commit'] == source")
            actual = actual.replace('Diagnostic actual 6b APK Village roundtrip with separately bound QA; no seven-job acceptance',
                                    'Actual API35 direct Flutter Village roundtrip; no physical ARM64/FPS claim')
            actual = actual.replace("print('[DiagnosticVillageAndroid]'", "print('[VillageAndroid]'")
        else:
            actual = actual.replace("identity['versionCode'] == 2020 and identity['godot_revision'] == native\n"
                                    "                        and identity['flutter_source_commit'] == self.args.expected_source,",
                                    "identity['versionCode'] == 2020 and identity['godot_revision'] == native,")
            actual = actual.replace('Diagnostic actual 6b APK C4 test with separately bound QA; no seven-job acceptance',
                                    'Actual API35 C4 candidate test; no release/FPS/API37 claim')
            actual = actual.replace("print('[DiagnosticConnectFourAndroid]'", "print('[ConnectFourAndroid]'")
        self.assertEqual(ast.dump(ast.parse(actual), include_attributes=False),
                         ast.dump(ast.parse(original), include_attributes=False))

    def test_village_keeps_every_original_touch_process_profile_and_final_evidence_check(self):
        self.assert_preserved('village', 'lumo_village_android_probe.py', 'VillageProbe')

    def test_c4_keeps_every_original_drop_bot_pause_reopen_and_return_check(self):
        self.assert_preserved('c4', 'lumo_connect_four_android_probe.py', 'Probe')

    def test_workflow_only_runs_main_village_c4_and_cannot_publish(self):
        workflow = (ROOT / adapter.diagnostic.QA_WORKFLOW).read_text()
        self.assertIn('case: main', workflow)
        self.assertNotIn('case: update2017', workflow)
        self.assertNotIn('contents: write', workflow)
        self.assertNotIn('continue-on-error', workflow)
        runner = (ROOT / 'scripts/run_unchanged_6b_village_diagnostic.sh').read_text()
        self.assertLess(runner.index('modernization_android_tour.py'), runner.index('for diagnostic_mode in village c4'))
        self.assertIn('c4-diagnostic-replay.json', runner)
        self.assertIn("'seven_job_acceptance': False", runner)


class DiagnosticBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.candidate = self.root / 'candidate'
        self.candidate.mkdir()
        self.apk = self.root / 'synthetic-unit-fixture.apk'
        self.apk.write_bytes(b'diagnostic unit fixture, not an Android APK')
        self.receipt = self.root / 'synthetic-binding.json'
        self.qa = 'a' * 40
        d = adapter.diagnostic
        self.binding = {
            'status': 'BOUND', 'diagnostic_qa': {'source': self.qa},
            'candidate_build': {'host_source': d.HOST, 'run_id': d.BUILD_RUN, 'artifact_id': d.ARTIFACT_ID},
            'git_sources': {'qa': {'commit': self.qa, 'tree': 'b' * 40},
                           'candidate': {'commit': d.HOST, 'path': str(self.candidate)}},
            'source_files': {'qa': [{'path': 'synthetic-observer.py', 'sha256': 'c' * 64}]},
        }
        self.args = SimpleNamespace(
            expected_source=d.HOST, expected_native=d.NATIVE, expected_qa_source=self.qa,
            build_run=d.BUILD_RUN, run_attempt=d.BUILD_ATTEMPT, artifact_id=d.ARTIFACT_ID,
            artifact_digest=d.ARTIFACT_DIGEST, diagnostic_binding=self.receipt, apk=self.apk)
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(patch.object(d, 'APK_BYTES', self.apk.stat().st_size))
        self.stack.enter_context(patch.object(d, 'APK_SHA256', hashlib.sha256(self.apk.read_bytes()).hexdigest()))
        self.stack.enter_context(patch.object(d, 'source_identity'))
        self.helper = self.stack.enter_context(patch.object(d, 'committed_file', return_value=self.binding['source_files']['qa'][0]))
        self.stack.enter_context(patch.object(adapter.Path, 'cwd', return_value=self.candidate))

    def check(self):
        self.receipt.write_text(json.dumps(self.binding))
        return adapter.require_bound_diagnostic(self.args)

    def test_actual_fixture_bytes_and_distinct_sources_produce_diagnostic_only_scope(self):
        result = self.check()
        self.assertEqual(result['qa_source'], self.qa)
        self.assertEqual(result['apk_source'], adapter.diagnostic.HOST)
        self.assertIs(result['seven_job_acceptance'], False)

    def test_source_attempt_artifact_digest_and_boolean_integer_substitutions_are_rejected(self):
        for name, value in [('expected_source', self.qa), ('expected_native', self.qa),
                            ('build_run', 1), ('run_attempt', True), ('artifact_id', 1),
                            ('artifact_digest', 'sha256:' + '0' * 64)]:
            before = getattr(self.args, name)
            with self.subTest(name=name):
                setattr(self.args, name, value)
                with self.assertRaises(RuntimeError):
                    self.check()
                setattr(self.args, name, before)

    def test_missing_failed_foreign_or_relabelled_binding_is_rejected(self):
        original = copy.deepcopy(self.binding)
        for group, key, value in [(None, 'status', 'FAIL'), ('diagnostic_qa', 'source', 'd' * 40),
                                  ('candidate_build', 'host_source', self.qa),
                                  ('candidate_build', 'run_id', 1), ('candidate_build', 'artifact_id', 1)]:
            self.binding = copy.deepcopy(original)
            (self.binding if group is None else self.binding[group])[key] = value
            with self.subTest(group=group, key=key), self.assertRaises(RuntimeError):
                self.check()

    def test_modified_actual_fixture_apk_bytes_are_rejected(self):
        self.apk.write_bytes(b'x' * self.apk.stat().st_size)
        with self.assertRaisesRegex(RuntimeError, 'Original APK changed'):
            self.check()

    def test_apk_symlink_is_rejected_even_when_target_bytes_match(self):
        link = self.root / 'linked.apk'
        link.symlink_to(self.apk)
        self.args.apk = link
        with self.assertRaisesRegex(RuntimeError, 'non-symlink'):
            self.check()

    def test_changed_observer_receipt_cannot_drive_a_diagnostic(self):
        self.helper.return_value = {'path': 'synthetic-observer.py', 'sha256': 'd' * 64}
        with self.assertRaisesRegex(RuntimeError, 'observer changed'):
            self.check()

    def test_wrong_candidate_working_directory_is_rejected(self):
        with patch.object(adapter.Path, 'cwd', return_value=self.root), self.assertRaisesRegex(RuntimeError, 'candidate checkout'):
            self.check()

    def test_same_source_cannot_impersonate_separate_qa(self):
        self.args.expected_qa_source = adapter.diagnostic.HOST
        self.binding['diagnostic_qa']['source'] = adapter.diagnostic.HOST
        with self.assertRaisesRegex(RuntimeError, 'separate QA'):
            self.check()


if __name__ == '__main__':
    unittest.main()
