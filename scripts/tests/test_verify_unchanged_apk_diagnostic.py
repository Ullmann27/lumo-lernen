"""Synthetic offline counterexamples; no downloaded APK or Android acceptance."""
from __future__ import annotations

from contextlib import ExitStack, redirect_stderr, redirect_stdout
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sys
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch
import warnings
import zipfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('unchanged_apk_diagnostic', ROOT / 'scripts/verify_unchanged_apk_diagnostic.py')
diagnostic = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(diagnostic)
creative = diagnostic.load_module('diagnostic_test_creative', ROOT / '.github/probes/studio_creative_android_probe.py')
Image.preinit()


def forbidden_device_call(*args, **kwargs):
    raise AssertionError('Offline binding tests must not access a device')


# Match the existing TourApkIdentityTests import boundary. The actual identity
# function is used; only its unused device adapter is absent from this runtime.
with patch.dict(sys.modules, {'pr207_android_ui_probe': SimpleNamespace(
        live_nodes=forbidden_device_call, live_tap_label=forbidden_device_call)}):
    tour = diagnostic.load_module('diagnostic_test_tour', ROOT / '.github/probes/modernization_android_tour.py')
QA_SOURCE, QA_TREE, QA_RUN = 'a' * 40, 'b' * 40, 900001


def candidate_metadata():
    run = {'id': diagnostic.BUILD_RUN, 'head_sha': diagnostic.HOST,
           'run_attempt': 1, 'status': 'completed', 'conclusion': 'failure',
           'path': diagnostic.CANDIDATE_WORKFLOW,
           'repository': {'full_name': diagnostic.REPOSITORY, 'id': diagnostic.REPOSITORY_ID},
           'head_commit': {'id': diagnostic.HOST, 'tree_id': diagnostic.HOST_TREE}}
    job = {'id': diagnostic.BUILD_JOB, 'run_id': diagnostic.BUILD_RUN, 'run_attempt': 1,
           'name': 'verify-and-build', 'head_sha': diagnostic.HOST,
           'status': 'completed', 'conclusion': 'success',
           'steps': [{'name': name, 'status': 'completed', 'conclusion': 'success'}
                     for name in diagnostic.BUILD_STEPS]}
    artifact = {'id': diagnostic.ARTIFACT_ID, 'name': 'lumo-kart-graphics-2019-candidate',
                'size_in_bytes': diagnostic.ARTIFACT_BYTES, 'digest': diagnostic.ARTIFACT_DIGEST,
                'expired': False, 'workflow_run': {'id': diagnostic.BUILD_RUN,
                    'head_sha': diagnostic.HOST, 'repository_id': diagnostic.REPOSITORY_ID,
                    'head_repository_id': diagnostic.REPOSITORY_ID}}
    return run, {'total_count': 1, 'jobs': [job]}, {'total_count': 1, 'artifacts': [artifact]}


def qa_metadata():
    run = {'id': QA_RUN, 'head_sha': QA_SOURCE, 'run_attempt': 1,
           'status': 'in_progress', 'conclusion': None, 'path': diagnostic.QA_WORKFLOW,
           'head_branch': diagnostic.QA_BRANCH,
           'repository': {'full_name': diagnostic.REPOSITORY, 'id': diagnostic.REPOSITORY_ID},
           'head_commit': {'id': QA_SOURCE, 'tree_id': QA_TREE}}
    jobs = [{'id': 900100 + i, 'run_id': QA_RUN, 'run_attempt': 1, 'head_sha': QA_SOURCE,
             'name': name, 'status': 'in_progress', 'conclusion': None}
            for i, name in enumerate(diagnostic.QA_JOBS)]
    return run, {'total_count': len(jobs), 'jobs': jobs}


def verify_qa(run, jobs, **overrides):
    arguments = {'source': QA_SOURCE, 'run_id': QA_RUN, 'attempt': 1,
                 'job_name': diagnostic.QA_JOBS[0], **overrides}
    return diagnostic.verify_qa(run, jobs, **arguments)


class MetadataContracts(unittest.TestCase):
    def test_failed_original_android_run_retains_exact_successful_build(self):
        result = diagnostic.verify_candidate(*candidate_metadata(), creative)
        self.assertEqual(result['run_conclusion'], 'failure')
        self.assertEqual(result['build_conclusion'], 'success')
        self.assertEqual(result['build_job_id'], diagnostic.BUILD_JOB)
        self.assertIn('ZIP is not read', result['archive_validation'])
        run, jobs, artifacts = candidate_metadata()
        run.update(status='in_progress', conclusion=None)
        self.assertIsNone(diagnostic.verify_candidate(run, jobs, artifacts, creative)['run_conclusion'])

    def test_original_source_attempt_tree_and_artifact_mismatches_are_rejected(self):
        cases = (
            (0, ('head_sha',), QA_SOURCE), (0, ('run_attempt',), 2),
            (0, ('run_attempt',), True), (0, ('head_commit', 'tree_id'), QA_TREE),
            (0, ('repository', 'id'), 13),
            (2, ('artifacts', 0, 'id'), 1), (2, ('artifacts', 0, 'digest'), 'sha256:' + '0' * 64),
            (2, ('artifacts', 0, 'size_in_bytes'), diagnostic.ARTIFACT_BYTES - 1),
            (2, ('artifacts', 0, 'expired'), True),
            (2, ('artifacts', 0, 'workflow_run', 'head_repository_id'), 13),
        )
        for index, keys, wrong in cases:
            with self.subTest(keys=keys, wrong=wrong):
                values = list(candidate_metadata())
                target = values[index]
                for key in keys[:-1]:
                    target = target[key]
                target[keys[-1]] = wrong
                with self.assertRaises(RuntimeError):
                    diagnostic.verify_candidate(*values, creative)

    def test_failed_different_or_incomplete_build_is_not_accepted(self):
        for key, wrong in (('conclusion', 'failure'), ('status', 'in_progress'),
                           ('id', diagnostic.BUILD_JOB + 1), ('run_attempt', 2)):
            with self.subTest(key=key):
                run, jobs, artifacts = candidate_metadata()
                jobs['jobs'][0][key] = wrong
                with self.assertRaises(RuntimeError):
                    diagnostic.verify_candidate(run, jobs, artifacts, creative)
        for name in diagnostic.BUILD_STEPS:
            run, jobs, artifacts = candidate_metadata()
            for step in jobs['jobs'][0]['steps']:
                if step['name'] == name:
                    step['conclusion'] = 'skipped'
            with self.subTest(step=name), self.assertRaises(RuntimeError):
                diagnostic.verify_candidate(run, jobs, artifacts, creative)

    def test_incomplete_or_duplicate_original_collections_are_rejected(self):
        for key in ('jobs', 'artifacts'):
            row = {'id': 1}
            for rows, count in (([row], 2), ([row, row], 2), ([{'id': True}], 1)):
                with self.subTest(key=key, count=count), self.assertRaises(RuntimeError):
                    diagnostic.complete_rows({key: rows, 'total_count': count}, key)

    def test_qa_run_and_each_allowed_job_are_distinct_from_apk_source(self):
        for name in diagnostic.QA_JOBS:
            result = verify_qa(*qa_metadata(), job_name=name)
            self.assertEqual(result['source'], QA_SOURCE)
            self.assertNotEqual(result['source'], diagnostic.HOST)
            self.assertEqual(result['job_name'], name)
            self.assertEqual(result['job_status'], 'in_progress')
            self.assertIsNone(result['job_conclusion'])

    def test_pr_merge_sha_other_workflow_and_stale_qa_attempt_are_rejected(self):
        cases = (('source', 'c' * 40), ('source', diagnostic.HOST),
                 ('run_id', diagnostic.BUILD_RUN), ('attempt', 2), ('attempt', True),
                 ('job_name', 'verify-and-build'))
        for key, wrong in cases:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                verify_qa(*qa_metadata(), **{key: wrong})
        for key, wrong in (('path', diagnostic.CANDIDATE_WORKFLOW),
                           ('head_branch', 'main'), ('head_sha', diagnostic.HOST)):
            run, jobs = qa_metadata()
            run[key] = wrong
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                verify_qa(run, jobs)
        run, jobs = qa_metadata()
        jobs['jobs'][0]['run_attempt'] = 2
        with self.assertRaises(RuntimeError):
            verify_qa(run, jobs)


class SourceContracts(unittest.TestCase):
    def test_actual_git_root_sha_tree_and_tracked_clean_are_required(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            replies = [str(root).encode(), QA_SOURCE.encode(), QA_TREE.encode(), b'']
            with patch.object(diagnostic, 'git', side_effect=replies) as calls:
                result = diagnostic.source_identity(root, QA_SOURCE, QA_TREE)
            self.assertTrue(result['tracked_source_clean'])
            self.assertEqual(calls.call_args_list[-1].args[1:], ('status', '--porcelain', '--untracked-files=no'))
            for index, bad in ((0, str(root.parent).encode()), (1, diagnostic.HOST.encode()),
                               (2, diagnostic.HOST_TREE.encode()), (3, b' M config/godot-source.json')):
                changed = replies.copy()
                changed[index] = bad
                with self.subTest(index=index), patch.object(diagnostic, 'git', side_effect=changed), self.assertRaises(RuntimeError):
                    diagnostic.source_identity(root, QA_SOURCE, QA_TREE)

    def test_committed_helper_rejects_changed_working_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'helper.py').write_bytes(b'original\n')
            with patch.object(diagnostic, 'git', side_effect=[b'original\n', b'a' * 40]):
                self.assertEqual(diagnostic.committed_file(root, 'helper.py')['bytes'], 9)
            with patch.object(diagnostic, 'git', return_value=b'other\n'), self.assertRaises(RuntimeError):
                diagnostic.committed_file(root, 'helper.py')

    def test_json_duplicates_and_input_symlinks_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'input.json'
            path.write_text('{"id":1,"id":2}')
            with self.assertRaises(RuntimeError):
                diagnostic.read_json(path)
            link = root / 'link.json'
            link.symlink_to(path)
            with self.assertRaises(RuntimeError):
                diagnostic.read_json(link)


class ApkContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.candidate = self.root / 'candidate-source'
        (self.candidate / 'config').mkdir(parents=True)
        (self.candidate / 'config/godot-source.json').write_text(json.dumps({
            'repository': 'https://github.com/Ullmann27/lumo-godot.git', 'revision': diagnostic.NATIVE}))
        (self.candidate / 'pubspec.yaml').write_text('version: 0.13.7+2019\n')
        self.apk = self.root / 'synthetic.apk'
        self.pck = b'Explicitly synthetic PCK bytes, not a native render or APK build.'
        with zipfile.ZipFile(self.apk, 'w', compression=zipfile.ZIP_STORED) as archive:
            archive.writestr(diagnostic.PCK_MEMBER, self.pck)
        self.provenance_path = self.root / 'BUILD-PROVENANCE.json'
        self.sums_path = self.root / 'ANDROID-TOUR-SHA256SUMS.txt'
        self.provenance = {
            'package': diagnostic.PACKAGE, 'abis': ['x86_64'],
            'bytes': self.apk.stat().st_size, 'sha256': diagnostic.file_digest(self.apk),
            'flutter_source_commit': diagnostic.HOST, 'tracked_source_clean': True,
            'versionName': '0.13.7', 'versionCode': 2019,
            'signingCertificateSha256': diagnostic.CERTIFICATE,
            'elf16KiBAligned': True, 'resourcesArscAligned': True,
            'godot': {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                      'revision': diagnostic.NATIVE, 'engine': '4.6.3', 'bytes': len(self.pck),
                      'pck_sha256': hashlib.sha256(self.pck).hexdigest()},
        }
        self.write_inputs()
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        for name, value in (('APK_BYTES', self.provenance['bytes']),
                            ('APK_SHA256', self.provenance['sha256']),
                            ('PCK_BYTES', len(self.pck)), ('PCK_SHA256', self.provenance['godot']['pck_sha256'])):
            self.stack.enter_context(patch.object(diagnostic, name, value))

        def actual_git_context(*arguments, **kwargs):
            self.assertEqual(arguments, ('git', 'rev-parse', 'HEAD'))
            self.assertEqual(Path.cwd(), self.candidate)
            return diagnostic.HOST + '\n'
        self.stack.enter_context(patch.object(tour.base, 'command', side_effect=actual_git_context))

    def write_inputs(self):
        self.provenance_path.write_text(json.dumps(self.provenance))
        self.sums_path.write_text(self.provenance['sha256'] + '  ' + diagnostic.SUM_MEMBER + '\n')

    def verify(self):
        return diagnostic.verify_apk(self.apk, self.provenance_path, self.sums_path, self.candidate, tour)

    def test_existing_identity_verifier_uses_candidate_cwd_and_actual_pck_bytes(self):
        before = Path.cwd()
        result = self.verify()
        self.assertEqual(Path.cwd(), before)
        self.assertEqual(result['pck_sha256'], hashlib.sha256(self.pck).hexdigest())
        self.assertTrue(all(result['existing_apk_identity']['checks'].values()))
        self.assertEqual(result['existing_apk_identity']['flutter_source_commit'], diagnostic.HOST)

    def test_another_apk_digest_fails_without_relabeling_qa_source(self):
        raw = self.apk.read_bytes()
        self.apk.write_bytes(raw.replace(b'Explicitly', b'Implicitly', 1))
        before = Path.cwd()
        with self.assertRaisesRegex(RuntimeError, 'verified build'):
            self.verify()
        self.assertEqual(Path.cwd(), before)

    def test_wrong_provenance_source_native_abi_or_signer_is_rejected(self):
        original = copy.deepcopy(self.provenance)
        for key, bad in (('flutter_source_commit', QA_SOURCE), ('abis', ['arm64-v8a']),
                         ('package', 'another.package'), ('signingCertificateSha256', '0' * 64),
                         ('tracked_source_clean', False)):
            self.provenance = {**original, key: bad}
            self.write_inputs()
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.verify()
        self.provenance = copy.deepcopy(original)
        self.provenance['godot']['revision'] = QA_SOURCE
        self.write_inputs()
        with self.assertRaises(RuntimeError):
            self.verify()

    def test_duplicate_checksum_and_missing_pck_are_rejected(self):
        self.sums_path.write_text(self.sums_path.read_text() * 2)
        with self.assertRaisesRegex(RuntimeError, 'exactly one'):
            self.verify()
        self.write_inputs()
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('assets/another.pck', self.pck)
        self.provenance.update(bytes=self.apk.stat().st_size, sha256=diagnostic.file_digest(self.apk))
        self.write_inputs()
        with patch.object(diagnostic, 'APK_BYTES', self.provenance['bytes']), patch.object(diagnostic, 'APK_SHA256', self.provenance['sha256']):
            with self.assertRaisesRegex(RuntimeError, 'one unambiguous'):
                self.verify()

    def test_duplicate_pck_and_crc_corruption_are_rejected(self):
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(self.apk, 'a') as archive:
                archive.writestr(diagnostic.PCK_MEMBER, self.pck)
        self.provenance.update(bytes=self.apk.stat().st_size, sha256=diagnostic.file_digest(self.apk))
        self.write_inputs()
        with patch.object(diagnostic, 'APK_BYTES', self.provenance['bytes']), patch.object(diagnostic, 'APK_SHA256', self.provenance['sha256']):
            with self.assertRaisesRegex(RuntimeError, 'one unambiguous'):
                self.verify()
        with zipfile.ZipFile(self.apk, 'w', compression=zipfile.ZIP_STORED) as archive:
            archive.writestr(diagnostic.PCK_MEMBER, self.pck)
        raw = self.apk.read_bytes()
        self.apk.write_bytes(raw.replace(b'Explicitly', b'Implicitly', 1))
        self.provenance.update(bytes=self.apk.stat().st_size, sha256=diagnostic.file_digest(self.apk))
        self.write_inputs()
        with patch.object(diagnostic, 'APK_BYTES', self.provenance['bytes']), patch.object(diagnostic, 'APK_SHA256', self.provenance['sha256']):
            with self.assertRaises(zipfile.BadZipFile):
                self.verify()

    def test_changed_pck_bytes_fail_even_when_synthetic_outer_apk_matches(self):
        with zipfile.ZipFile(self.apk, 'w', compression=zipfile.ZIP_STORED) as archive:
            archive.writestr(diagnostic.PCK_MEMBER, self.pck.replace(b'Explicitly', b'Implicitly'))
        self.provenance.update(bytes=self.apk.stat().st_size, sha256=diagnostic.file_digest(self.apk))
        self.write_inputs()
        with patch.object(diagnostic, 'APK_BYTES', self.provenance['bytes']), patch.object(diagnostic, 'APK_SHA256', self.provenance['sha256']):
            with self.assertRaisesRegex(RuntimeError, 'Actual embedded PCK bytes differ'):
                self.verify()

    def test_full_preflight_keeps_qa_run_and_apk_source_separate(self):
        candidate_metadata_dir, qa_metadata_dir = self.root / 'build-meta', self.root / 'qa-meta'
        candidate_metadata_dir.mkdir()
        qa_metadata_dir.mkdir()
        for name, value in zip(('run.json', 'jobs.json', 'artifacts.json'), candidate_metadata()):
            (candidate_metadata_dir / name).write_text(json.dumps(value))
        for name, value in zip(('run.json', 'jobs.json'), qa_metadata()):
            (qa_metadata_dir / name).write_text(json.dumps(value))

        def synthetic_checkout(path, source, tree):
            # Only Git identity is synthetic. Inputs, original helper bytes,
            # the existing APK verifier and embedded ZIP reads remain real.
            expected = (QA_SOURCE, QA_TREE) if path == ROOT else (diagnostic.HOST, diagnostic.HOST_TREE)
            self.assertEqual((source, tree), expected)
            return {'path': str(path), 'commit': source, 'tree': tree, 'tracked_source_clean': True}

        def synthetic_committed_file(path, relative):
            data = (path / relative).read_bytes()
            return {'path': relative, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                    'git_blob': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()}

        args = SimpleNamespace(qa_source=ROOT, candidate_source=self.candidate,
            candidate_metadata_dir=candidate_metadata_dir, qa_metadata_dir=qa_metadata_dir,
            expected_qa_source=QA_SOURCE, expected_qa_run=QA_RUN, expected_qa_attempt=1,
            qa_job_name=diagnostic.QA_JOBS[0], apk=self.apk,
            provenance=self.provenance_path, sums=self.sums_path)
        with patch.object(diagnostic, 'source_identity', side_effect=synthetic_checkout), \
                patch.object(diagnostic, 'committed_file', side_effect=synthetic_committed_file), \
                patch.object(diagnostic, 'load_module', side_effect=[creative, tour]):
            result = diagnostic.bind(args)
        self.assertEqual(result['diagnostic_qa']['source'], QA_SOURCE)
        self.assertEqual(result['candidate_build']['host_source'], diagnostic.HOST)
        self.assertEqual(result['candidate_build']['run_conclusion'], 'failure')
        self.assertEqual(result['required_probe_cwd'], str(self.candidate))
        self.assertEqual(result['required_update_source_env'], diagnostic.HOST)
        self.assertEqual(len(result['input_hashes']), 7)
        self.assertEqual(result['status'], 'BOUND')
        self.assertIn('no Android or release acceptance', result['scope'])


class OutputContracts(unittest.TestCase):
    def test_atomic_report_never_overwrites_existing_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'binding.json'
            diagnostic.write_report(path, {'scope': 'synthetic', 'status': 'BOUND'})
            original = path.read_bytes()
            with self.assertRaises(RuntimeError):
                diagnostic.write_report(path, {'status': 'other'})
            self.assertEqual(path.read_bytes(), original)
            self.assertEqual(sorted(p.name for p in path.parent.iterdir()), ['binding.json'])

    def test_cli_failure_creates_no_report_or_bound_marker(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'binding.json'
            arguments = []
            for name in ('qa-source', 'candidate-source', 'candidate-metadata-dir', 'qa-metadata-dir',
                         'apk', 'provenance', 'sums'):
                arguments += ['--' + name, directory]
            arguments += ['--out', str(output), '--expected-qa-source', QA_SOURCE,
                          '--expected-qa-run', str(QA_RUN), '--expected-qa-attempt', '1',
                          '--qa-job-name', diagnostic.QA_JOBS[0]]
            stdout, stderr = io.StringIO(), io.StringIO()
            with patch.object(diagnostic, 'bind', side_effect=RuntimeError('synthetic mismatch')), redirect_stdout(stdout), redirect_stderr(stderr):
                self.assertEqual(diagnostic.main(arguments), 1)
            self.assertFalse(output.exists())
            self.assertNotIn('BOUND', stdout.getvalue())
            self.assertIn('FAIL: synthetic mismatch', stderr.getvalue())


if __name__ == '__main__':
    unittest.main()
