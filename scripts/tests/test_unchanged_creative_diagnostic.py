"""Offline counterexamples for the separate Creative source boundary.

Metadata, Git replies, native text files and the tiny APK marker are explicit
test doubles. Real file hashes and the real metadata/source validators execute.
No test represents an Android run, an APK build or a successful game.
"""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import sys

from scripts.tests.test_verify_unchanged_apk_diagnostic import (
    QA_RUN, QA_SOURCE, QA_TREE, candidate_metadata, qa_metadata,
)


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'test_creative_diagnostic_runner',
    ROOT / 'scripts/run_unchanged_creative_diagnostic.py')
runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runner)
common = runner.common


def creative_metadata():
    run, jobs = qa_metadata()
    run.update(path=common.CREATIVE_QA_WORKFLOW, head_branch=common.CREATIVE_QA_BRANCH)
    job = copy.deepcopy(jobs['jobs'][0])
    job['name'] = common.CREATIVE_QA_JOB
    return run, {'total_count': 1, 'jobs': [job]}


def verify_qa(run, jobs, job=common.CREATIVE_QA_JOB):
    return common.verify_qa(run, jobs, source=QA_SOURCE, run_id=QA_RUN,
                            attempt=1, job_name=job)


class SeparateRouteContracts(unittest.TestCase):
    def test_creative_route_requires_its_own_exact_workflow_branch_and_job(self):
        result = verify_qa(*creative_metadata())
        self.assertEqual(result['workflow_path'], common.CREATIVE_QA_WORKFLOW)
        self.assertEqual(result['branch'], common.CREATIVE_QA_BRANCH)
        self.assertEqual(result['job_name'], common.CREATIVE_QA_JOB)
        self.assertNotEqual(result['source'], common.HOST)
        self.assertEqual(result['job_status'], 'in_progress')

    def test_creative_job_cannot_borrow_the_runtime_workflow_or_branch(self):
        for key, wrong in (('path', common.QA_WORKFLOW),
                           ('head_branch', common.QA_BRANCH),
                           ('head_branch', 'main')):
            run, jobs = creative_metadata()
            run[key] = wrong
            with self.subTest(field=key, value=wrong), self.assertRaises(RuntimeError):
                verify_qa(run, jobs)
        run, jobs = creative_metadata()
        jobs['jobs'].append(copy.deepcopy(jobs['jobs'][0]))
        jobs['total_count'] = 2
        with self.assertRaises(RuntimeError):
            verify_qa(run, jobs)

    def test_all_four_runtime_routes_stay_separate_from_creative(self):
        self.assertEqual(len(common.QA_JOBS), 4)
        for name in common.QA_JOBS:
            with self.subTest(name=name):
                result = verify_qa(*qa_metadata(), job=name)
                self.assertEqual((result['workflow_path'], result['branch']),
                                 (common.QA_WORKFLOW, common.QA_BRANCH))
                run, jobs = creative_metadata()
                jobs['jobs'][0]['name'] = name
                with self.assertRaises(RuntimeError):
                    verify_qa(run, jobs, job=name)


class TourContextContracts(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='creative-context-contract-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.qa, self.candidate, self.native = (
            self.root / name for name in ('qa', 'candidate', 'native'))
        self.committed = {}
        for source, names in (
            (self.qa, runner.QA_FILES),
            (self.candidate, ('config/godot-source.json', 'pubspec.yaml')),
            (self.native, runner.NATIVE_FILES),
        ):
            source.mkdir()
            for name in names:
                target = source / name
                target.parent.mkdir(parents=True, exist_ok=True)
                data = ((ROOT / name).read_bytes() if source == self.qa
                        else ('Explicit synthetic context file: ' + name + '\n').encode())
                target.write_bytes(data)
                self.committed[(source, name)] = data
        self.identities = {
            self.qa: (QA_SOURCE, QA_TREE),
            self.candidate: (common.HOST, common.HOST_TREE),
            self.native: (common.NATIVE, runner.NATIVE_TREE),
        }
        self.addCleanup(patch.stopall)
        patch.object(runner, 'ROOT', self.qa).start()
        patch.object(common, 'git', side_effect=self.git_reply).start()
        apk = self.root / 'synthetic-apk-marker'
        apk.write_bytes(b'Not an APK. Context test only.\n')
        patch.object(common, 'APK_BYTES', apk.stat().st_size).start()
        self.args = SimpleNamespace(
            qa_source=self.qa, probe_source=self.qa, candidate_source=self.candidate,
            native_source=self.native, qa_job_name=common.CREATIVE_QA_JOB,
            expected_qa_source=QA_SOURCE, expected_qa_run=QA_RUN,
            expected_qa_attempt=1, candidate_metadata_dir=self.root / 'candidate-meta',
            qa_metadata_dir=self.root / 'qa-meta', apk=apk,
            provenance=self.root / 'provenance.json', sums=self.root / 'sums.txt',
            diagnostic_report=self.root / 'context.json')
        self.args.candidate_metadata_dir.mkdir()
        self.args.qa_metadata_dir.mkdir()
        build_run, build_jobs, artifacts = candidate_metadata()
        qa_run, qa_jobs = creative_metadata()
        for directory, values in (
            (self.args.candidate_metadata_dir,
             {'run.json': build_run, 'jobs.json': build_jobs, 'artifacts.json': artifacts}),
            (self.args.qa_metadata_dir, {'run.json': qa_run, 'jobs.json': qa_jobs}),
        ):
            for name, value in values.items():
                (directory / name).write_text(json.dumps(value))
        self.args.provenance.write_text('{"synthetic":"preflight-context-only"}\n')
        self.args.sums.write_text('Synthetic context input, not build sums.\n')
        creative = common.load_module(
            'context_fixture_creative', self.qa / '.github/probes/studio_creative_android_probe.py')
        self.args.binding = creative.verify_candidate_metadata(
            build_run, artifacts, build_jobs, runner.expected_candidate())
        self.context = {
            'schema': 1, 'status': 'BOUND',
            'diagnostic_qa': verify_qa(qa_run, qa_jobs),
            'candidate_build': common.verify_candidate(build_run, build_jobs, artifacts, creative),
            'candidate_binding': self.args.binding,
            'input_hashes': {
                name: {'path': str(path.resolve()), 'bytes': path.stat().st_size,
                       'sha256': common.file_digest(path)}
                for name, path in runner.input_files(self.args).items()},
            'git_sources': {
                name: common.source_identity(source, *self.identities[source])
                for name, source in (('qa', self.qa), ('candidate', self.candidate),
                                     ('native', self.native))},
            'source_files': {
                name: [common.committed_file(source, relative) for relative in names]
                for name, source, names in (
                    ('qa', self.qa, runner.QA_FILES),
                    ('candidate', self.candidate, ('config/godot-source.json', 'pubspec.yaml')),
                    ('native', self.native, runner.NATIVE_FILES))},
            'apk': {'apk_sha256': common.APK_SHA256, 'apk_bytes': common.APK_BYTES,
                    'pck_sha256': common.PCK_SHA256, 'pck_bytes': common.PCK_BYTES},
        }
        self.save()

    def git_reply(self, source, *arguments):
        commit, tree = self.identities[source]
        if arguments == ('rev-parse', '--show-toplevel'):
            return str(source).encode()
        if arguments == ('rev-parse', 'HEAD'):
            return commit.encode()
        if arguments == ('rev-parse', 'HEAD^{tree}'):
            return tree.encode()
        if arguments == ('status', '--porcelain', '--untracked-files=no'):
            return b''
        if len(arguments) == 2 and arguments[1].startswith('HEAD:'):
            data = self.committed[(source, arguments[1][5:])]
            if arguments[0] == 'show':
                return data
            if arguments[0] == 'rev-parse':
                return hashlib.sha1(
                    b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest().encode()
        self.fail('Unexpected read-only Git request: ' + repr(arguments))

    def save(self):
        self.args.diagnostic_report.write_text(json.dumps(self.context))

    def verify(self):
        return runner.validate_tour_context(self.args, self.context)

    def test_complete_context_returns_only_the_separate_qa_head(self):
        self.assertEqual(self.verify(), QA_SOURCE)
        self.assertEqual(self.context['status'], 'BOUND')
        self.assertNotEqual(self.context['diagnostic_qa']['source'],
                            self.context['candidate_build']['host_source'])

    def test_changed_original_metadata_is_rejected_even_with_same_record_count(self):
        target = self.args.qa_metadata_dir / 'run.json'
        data = json.loads(target.read_text())
        data['head_sha'] = 'e' * 40
        target.write_text(json.dumps(data))
        with self.assertRaisesRegex(RuntimeError, 'metadata/provenance changed'):
            self.verify()

    def test_forged_qa_or_candidate_bindings_cannot_replace_original_metadata(self):
        for section, key in (('diagnostic_qa', 'source'),
                             ('candidate_build', 'host_source'),
                             ('candidate_binding', 'host_source')):
            original = copy.deepcopy(self.context)
            self.context[section][key] = 'e' * 40
            self.save()
            with self.subTest(section=section), self.assertRaises(RuntimeError):
                self.verify()
            self.context = original
            self.save()

    def test_changed_qa_helper_or_native_scene_is_rejected_against_committed_bytes(self):
        for source, name in ((self.qa, '.github/probes/creative_android_probe.py'),
                             (self.native, 'scripts/creative/puzzle_world.gd')):
            target = source / name
            original = target.read_bytes()
            target.write_bytes(original + b'\nchanged\n')
            with self.subTest(file=name), self.assertRaisesRegex(RuntimeError, 'committed bytes'):
                self.verify()
            target.write_bytes(original)

    def test_missing_or_duplicate_helper_records_are_rejected(self):
        for operation in ('missing', 'duplicate'):
            original = copy.deepcopy(self.context)
            records = self.context['source_files']['qa']
            if operation == 'missing':
                records.pop()
            else:
                records[-1] = copy.deepcopy(records[0])
            self.save()
            with self.subTest(operation=operation), self.assertRaises(RuntimeError):
                self.verify()
            self.context = original
            self.save()

    def test_borrowed_runtime_job_and_modified_apk_binding_are_rejected(self):
        self.args.qa_job_name = common.QA_JOBS[0]
        with self.assertRaises(RuntimeError):
            self.verify()
        self.args.qa_job_name = common.CREATIVE_QA_JOB
        self.context['apk']['pck_sha256'] = '0' * 64
        self.save()
        with self.assertRaisesRegex(RuntimeError, 'unchanged APK/PCK'):
            self.verify()


class TourAdapterContracts(unittest.TestCase):
    """Exercise source routing and fail-before-device order with explicit doubles."""

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='creative-adapter-contract-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.args = SimpleNamespace(
            candidate_source=self.root / 'candidate', probe_source=self.root / 'qa',
            out=self.root / 'tour', binding={'host_source': common.HOST})
        self.creative = common.load_module(
            'adapter_test_creative', ROOT / '.github/probes/studio_creative_android_probe.py')
        self.device = Mock(side_effect=AssertionError('No device is available in this contract'))
        self.probe = SimpleNamespace(base=SimpleNamespace(adb=self.device), live=object())
        self.original = object()
        self.paths = sys.path.copy()
        self.addCleanup(lambda: sys.path.__setitem__(slice(None), self.paths))

    def imports(self, name):
        return {'creative_android_probe': self.probe,
                'modernization_android_tour': self.original}[name]

    def diagnostic_module(self, error=None):
        validator = Mock(return_value=QA_SOURCE, side_effect=error)
        module = SimpleNamespace(validate_tour_context=validator)
        spec = SimpleNamespace(loader=SimpleNamespace(exec_module=Mock()))
        return module, spec

    def test_original_mode_still_uses_candidate_without_loading_a_diagnostic(self):
        with patch.object(self.creative.importlib, 'import_module', side_effect=self.imports), \
                patch.object(self.creative.importlib.util, 'spec_from_file_location') as loader:
            tour = self.creative.Tour(self.args)
        self.assertEqual(tour.helper_source, self.args.candidate_source)
        self.assertEqual(tour.expected_probe_source, common.HOST)
        self.assertIsNone(tour.diagnostic_context)
        loader.assert_not_called()
        self.device.assert_not_called()

    def test_bound_diagnostic_routes_helpers_to_qa_before_any_device_call(self):
        self.args.diagnostic_context = {'explicit': 'synthetic constructor context'}
        module, spec = self.diagnostic_module()
        with patch.object(self.creative.importlib.util, 'spec_from_file_location', return_value=spec), \
                patch.object(self.creative.importlib.util, 'module_from_spec', return_value=module), \
                patch.object(self.creative, 'committed_helper') as committed, \
                patch.object(self.creative.importlib, 'import_module', side_effect=self.imports):
            tour = self.creative.Tour(self.args)
        committed.assert_called_once_with(self.args.probe_source, module, runner.RUNNER)
        module.validate_tour_context.assert_called_once_with(self.args, self.args.diagnostic_context)
        self.assertEqual(tour.helper_source, self.args.probe_source)
        self.assertEqual(tour.expected_probe_source, QA_SOURCE)
        self.assertIs(tour.diagnostic_context, self.args.diagnostic_context)
        self.device.assert_not_called()

    def test_explicit_invalid_context_cannot_fall_back_to_candidate_mode(self):
        for context in (None, {}, {'status': 'FORGED'}):
            self.args.diagnostic_context = context
            module, spec = self.diagnostic_module(RuntimeError('Invalid original context'))
            with self.subTest(context=context), \
                    patch.object(self.creative.importlib.util, 'spec_from_file_location', return_value=spec), \
                    patch.object(self.creative.importlib.util, 'module_from_spec', return_value=module), \
                    patch.object(self.creative, 'committed_helper'), \
                    patch.object(self.creative.importlib, 'import_module') as live_import, \
                    self.assertRaisesRegex(RuntimeError, 'Invalid original context'):
                self.creative.Tour(self.args)
            live_import.assert_not_called()
        self.device.assert_not_called()

    def test_uncommitted_diagnostic_runner_fails_before_context_or_live_imports(self):
        self.args.diagnostic_context = {'explicit': 'synthetic constructor context'}
        module, spec = self.diagnostic_module()
        with patch.object(self.creative.importlib.util, 'spec_from_file_location', return_value=spec), \
                patch.object(self.creative.importlib.util, 'module_from_spec', return_value=module), \
                patch.object(self.creative, 'committed_helper', side_effect=RuntimeError('Uncommitted runner')), \
                patch.object(self.creative.importlib, 'import_module') as live_import, \
                self.assertRaisesRegex(RuntimeError, 'Uncommitted runner'):
            self.creative.Tour(self.args)
        module.validate_tour_context.assert_not_called()
        live_import.assert_not_called()
        self.device.assert_not_called()


if __name__ == '__main__':
    unittest.main()
