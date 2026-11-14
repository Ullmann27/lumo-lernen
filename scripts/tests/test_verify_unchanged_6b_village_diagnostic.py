"""Synthetic offline counterexamples; no downloaded APK or Android acceptance."""
from __future__ import annotations

from contextlib import ExitStack, redirect_stderr, redirect_stdout
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch
import warnings
import zipfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('unchanged_2020_apk_diagnostic', ROOT / 'scripts/verify_unchanged_6b_village_diagnostic.py')
diagnostic = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(diagnostic)
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
c4 = diagnostic.load_module('diagnostic_2020_test_c4', ROOT / 'tools/android_qa/connect_four_android_evidence.py')
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
           'event': 'pull_request', 'head_branch': 'integration/lumo-live-connections-20261114',
           'repository': {'full_name': diagnostic.REPOSITORY, 'id': diagnostic.REPOSITORY_ID},
           'head_commit': {'id': diagnostic.HOST, 'tree_id': diagnostic.HOST_TREE}}
    job = {'id': diagnostic.BUILD_JOB, 'run_id': diagnostic.BUILD_RUN, 'run_attempt': 1,
           'name': 'verify-and-build', 'head_sha': diagnostic.HOST,
           'status': 'completed', 'conclusion': 'success',
           'steps': [{'name': name, 'status': 'completed', 'conclusion': 'success'}
                     for name in diagnostic.BUILD_STEPS]}
    artifact = {'id': diagnostic.ARTIFACT_ID, 'name': 'lumo-connect-four-2020-candidate',
                'size_in_bytes': diagnostic.ARTIFACT_BYTES, 'digest': diagnostic.ARTIFACT_DIGEST,
                'expired': False, 'workflow_run': {'id': diagnostic.BUILD_RUN,
                    'head_sha': diagnostic.HOST, 'repository_id': diagnostic.REPOSITORY_ID,
                    'head_repository_id': diagnostic.REPOSITORY_ID}}
    prerequisites = [
        {'id': 900200 + index, 'run_id': diagnostic.BUILD_RUN, 'run_attempt': 1,
         'name': name, 'head_sha': diagnostic.HOST, 'status': 'completed', 'conclusion': 'success'}
        for index, name in enumerate(('android-host-compile', 'connect-four-runtime'))
    ]
    return run, {'total_count': 3, 'jobs': [job, *prerequisites]}, {'total_count': 1, 'artifacts': [artifact]}


def qa_metadata():
    run = {'id': QA_RUN, 'head_sha': QA_SOURCE, 'run_attempt': 1,
           'status': 'in_progress', 'conclusion': None, 'path': diagnostic.QA_WORKFLOW,
           'head_branch': diagnostic.QA_BRANCH, 'event': 'push',
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
        result = diagnostic.verify_candidate(*candidate_metadata(), c4)
        self.assertEqual(result['run_conclusion'], 'failure')
        self.assertEqual(result['build_conclusion'], 'success')
        self.assertEqual(result['build_job_id'], diagnostic.BUILD_JOB)
        self.assertIn('ZIP is not read', result['archive_validation'])
        run, jobs, artifacts = candidate_metadata()
        run.update(status='in_progress', conclusion=None)
        self.assertIsNone(diagnostic.verify_candidate(run, jobs, artifacts, c4)['run_conclusion'])

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
                with self.assertRaises((RuntimeError, ValueError)):
                    diagnostic.verify_candidate(*values, c4)

    def test_failed_different_or_incomplete_build_is_not_accepted(self):
        for key, wrong in (('conclusion', 'failure'), ('status', 'in_progress'),
                           ('id', diagnostic.BUILD_JOB + 1), ('run_attempt', 2)):
            with self.subTest(key=key):
                run, jobs, artifacts = candidate_metadata()
                jobs['jobs'][0][key] = wrong
                with self.assertRaises((RuntimeError, ValueError)):
                    diagnostic.verify_candidate(run, jobs, artifacts, c4)
        for name in diagnostic.BUILD_STEPS:
            run, jobs, artifacts = candidate_metadata()
            for step in jobs['jobs'][0]['steps']:
                if step['name'] == name:
                    step['conclusion'] = 'skipped'
            with self.subTest(step=name), self.assertRaises((RuntimeError, ValueError)):
                diagnostic.verify_candidate(run, jobs, artifacts, c4)

    def test_incomplete_or_duplicate_original_collections_are_rejected(self):
        for key in ('jobs', 'artifacts'):
            row = {'id': 1}
            for rows, count in (([row], 2), ([row, row], 2), ([{'id': True}], 1)):
                with self.subTest(key=key, count=count), self.assertRaises((RuntimeError, ValueError)):
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
        (self.candidate / 'pubspec.yaml').write_text('version: 0.13.8+2020\n')
        self.qa_pin = self.root / 'synthetic-qa-godot-source.json'
        self.qa_pin.write_bytes((self.candidate / 'config/godot-source.json').read_bytes())
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
            'versionName': '0.13.8', 'versionCode': 2020,
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


    def test_real_git_checkouts_and_actual_imports_bind_both_sources(self):
        qa = self.root / 'committed-qa'
        shutil.copytree(ROOT, qa, ignore=shutil.ignore_patterns('__pycache__', '.git'))
        def commit(path):
            for arguments in (('init', '--quiet'), ('add', '--', '.'),
                              ('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                               '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', 'Synthetic offline source')):
                subprocess.run(['git', '-C', str(path), *arguments], check=True, capture_output=True)
            head = subprocess.check_output(['git', '-C', str(path), 'rev-parse', 'HEAD'], text=True).strip()
            tree = subprocess.check_output(['git', '-C', str(path), 'rev-parse', 'HEAD^{tree}'], text=True).strip()
            return head, tree
        qa_head, qa_tree = commit(qa)
        host, host_tree = commit(self.candidate)
        self.provenance['flutter_source_commit'] = host
        self.write_inputs()
        candidate_meta, qa_meta = self.root / 'build-meta', self.root / 'qa-meta'
        candidate_meta.mkdir()
        qa_meta.mkdir()
        with patch.object(diagnostic, 'HOST', host), patch.object(diagnostic, 'HOST_TREE', host_tree):
            candidate = candidate_metadata()
        qr, qj = qa_metadata()
        qr.update(head_sha=qa_head, head_commit={'id': qa_head, 'tree_id': qa_tree})
        for row in qj['jobs']:
            row['head_sha'] = qa_head
        for folder, names, values in (
                (candidate_meta, ('run.json', 'jobs.json', 'artifacts.json'), candidate),
                (qa_meta, ('run.json', 'jobs.json'), (qr, qj))):
            for name, value in zip(names, values):
                (folder / name).write_text(json.dumps(value))
        configuration = {
            'qa_source': str(qa), 'candidate_source': str(self.candidate),
            'candidate_metadata_dir': str(candidate_meta), 'qa_metadata_dir': str(qa_meta),
            'expected_qa_source': qa_head, 'expected_qa_run': QA_RUN, 'expected_qa_attempt': 1,
            'qa_job_name': diagnostic.QA_JOBS[0], 'apk': str(self.apk),
            'provenance': str(self.provenance_path), 'sums': str(self.sums_path),
            'baseline': None, 'baseline_metadata_dir': None,
            'synthetic_constants': {'HOST': host, 'HOST_TREE': host_tree,
                'APK_BYTES': self.provenance['bytes'], 'APK_SHA256': self.provenance['sha256'],
                'PCK_BYTES': len(self.pck), 'PCK_SHA256': hashlib.sha256(self.pck).hexdigest()},
        }
        config = self.root / 'offline-fixture.json'
        config.write_text(json.dumps(configuration))
        program = """import importlib.util,json,sys,types
from pathlib import Path
from types import SimpleNamespace
data=json.loads(Path(sys.argv[1]).read_text())
spec=importlib.util.spec_from_file_location('fixture_diagnostic',Path(data['qa_source'])/'scripts/verify_unchanged_6b_village_diagnostic.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
for key,value in data.pop('synthetic_constants').items():setattr(module,key,value)
for key in ('qa_source','candidate_source','candidate_metadata_dir','qa_metadata_dir','apk','provenance','sums'):
 data[key]=Path(data[key])
# The real source-bound UI module is imported; this unused external device library cannot connect.
sys.modules['uiautomator2']=types.ModuleType('uiautomator2')
print(json.dumps(module.bind(SimpleNamespace(**data))))
"""
        command = [sys.executable, '-B', '-c', program, str(config)]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=60,
                                   env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'})
        self.assertEqual(completed.returncode, 0, completed.stderr)
        report = json.loads(completed.stdout)
        self.assertEqual(report['status'], 'BOUND')
        self.assertEqual(report['git_sources']['qa']['commit'], qa_head)
        self.assertEqual(report['git_sources']['candidate']['commit'], host)
        self.assertEqual(report['candidate_build']['run_conclusion'], 'failure')
        paths = {row['path'] for row in report['source_files']['qa']}
        self.assertIn('tools/android_qa/kart_garage_evidence.py', paths)
        self.assertIn('.github/probes/lumo_learning_journey_probe.py', paths)
        self.assertIn('scripts/run_unchanged_6b_village_diagnostic.sh', paths)
        self.assertIsNone(report['baseline'])
        with (qa / 'tools/android_qa/kart_garage_evidence.py').open('a') as stream:
            stream.write('\n# Synthetic unauthorized change.\n')
        changed = subprocess.run(command, capture_output=True, text=True, timeout=60)
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn('Tracked source checkout is dirty', changed.stderr)


class BaselineContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.apk = self.root / 'baseline.apk'
        self.pck = b'Synthetic 2017 PCK fixture; no installed application.'
        with zipfile.ZipFile(self.apk, 'w', compression=zipfile.ZIP_STORED) as archive:
            archive.writestr(diagnostic.PCK_MEMBER, self.pck)
        self.baseline = {**diagnostic.BASELINE,
            'apk_bytes': self.apk.stat().st_size, 'apk_sha256': diagnostic.file_digest(self.apk),
            'pck_bytes': len(self.pck), 'pck_sha256': hashlib.sha256(self.pck).hexdigest()}
        self.patch = patch.object(diagnostic, 'BASELINE', self.baseline)
        self.patch.start()
        self.addCleanup(self.patch.stop)
        b = self.baseline
        self.run = {'id': b['run'], 'head_sha': b['host'], 'run_attempt': b['attempt'],
            'path': b['workflow'], 'status': 'completed', 'conclusion': 'failure',
            'head_commit': {'id': b['host'], 'tree_id': b['tree']},
            'repository': {'id': diagnostic.REPOSITORY_ID, 'full_name': diagnostic.REPOSITORY}}
        self.jobs = {'total_count': 1, 'jobs': [{
            'id': b['job'], 'name': 'verify-and-build', 'run_id': b['run'],
            'head_sha': b['host'], 'run_attempt': b['attempt'],
            'status': 'completed', 'conclusion': 'success',
            'steps': [{'name': name, 'status': 'completed', 'conclusion': 'success'}
                      for name in diagnostic.BUILD_STEPS]}]}
        self.artifacts = {'total_count': 1, 'artifacts': [{
            'id': b['artifact'], 'name': b['artifact_name'], 'size_in_bytes': b['artifact_bytes'],
            'digest': b['artifact_digest'], 'expired': False,
            'workflow_run': {'id': b['run'], 'head_sha': b['host'],
                'repository_id': diagnostic.REPOSITORY_ID, 'head_repository_id': diagnostic.REPOSITORY_ID}}]}
        self.provenance = {
            'package': diagnostic.PACKAGE, 'versionCode': 2017, 'versionName': '0.13.5',
            'abis': ['x86_64'], 'bytes': b['apk_bytes'], 'sha256': b['apk_sha256'],
            'flutter_source_commit': b['host'], 'signingCertificateSha256': diagnostic.CERTIFICATE,
            'tracked_source_clean': True, 'elf16KiBAligned': True, 'resourcesArscAligned': True,
            'godot': {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                'revision': b['native'], 'engine': '4.6.3', 'pck_sha256': b['pck_sha256'], 'bytes': b['pck_bytes']}}
        self.write()

    def write(self):
        for name, value in [('run.json', self.run), ('jobs.json', self.jobs),
                            ('artifacts.json', self.artifacts), ('BUILD-PROVENANCE.json', self.provenance)]:
            (self.root / name).write_text(json.dumps(value))

    def test_failed_historical_publisher_does_not_replace_original_successful_build(self):
        report = diagnostic.verify_baseline(self.apk, self.root)
        self.assertEqual(report['run_conclusion'], 'failure')
        self.assertEqual(report['build_conclusion'], 'success')
        self.assertTrue(report['apk_and_pck_bytes_verified'])

    def test_wrong_source_artifact_attempt_and_build_are_rejected(self):
        originals = copy.deepcopy((self.run, self.jobs, self.artifacts))
        cases = ((0, ('head_sha',), '0' * 40), (0, ('run_attempt',), 2),
                 (0, ('head_commit', 'tree_id'), '0' * 40),
                 (1, ('jobs', 0, 'id'), 7), (1, ('jobs', 0, 'conclusion'), 'failure'),
                 (1, ('jobs', 0, 'steps', 0, 'conclusion'), 'skipped'),
                 (2, ('artifacts', 0, 'digest'), 'sha256:' + '0' * 64),
                 (2, ('artifacts', 0, 'size_in_bytes'), 1),
                 (2, ('artifacts', 0, 'expired'), True),
                 (2, ('artifacts', 0, 'workflow_run', 'head_repository_id'), 7))
        for index, path, bad in cases:
            values = copy.deepcopy(originals)
            target = values[index]
            for key in path[:-1]:
                target = target[key]
            target[path[-1]] = bad
            self.run, self.jobs, self.artifacts = values
            self.write()
            with self.subTest(path=path), self.assertRaises(RuntimeError):
                diagnostic.verify_baseline(self.apk, self.root)

    def test_modified_apk_and_duplicate_pck_are_rejected(self):
        original = self.apk.read_bytes()
        self.apk.write_bytes(original.replace(b'Synthetic', b'SynthEtic', 1))
        with self.assertRaisesRegex(RuntimeError, 'APK bytes differ'):
            diagnostic.verify_baseline(self.apk, self.root)
        self.apk.write_bytes(original)
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(self.apk, 'a') as archive:
                archive.writestr(diagnostic.PCK_MEMBER, self.pck)
        updated = {**self.baseline, 'apk_bytes': self.apk.stat().st_size,
                   'apk_sha256': diagnostic.file_digest(self.apk)}
        self.provenance.update(bytes=updated['apk_bytes'], sha256=updated['apk_sha256'])
        self.write()
        with patch.object(diagnostic, 'BASELINE', updated), self.assertRaisesRegex(RuntimeError, 'PCK member differs'):
            diagnostic.verify_baseline(self.apk, self.root)


class DiagnosticScopeContracts(unittest.TestCase):
    def test_only_main_roundtrip_case_and_immutable_source_downloads(self):
        source = (ROOT / diagnostic.QA_WORKFLOW).read_text()
        self.assertIn('artifact-ids: \'14125990109\'', source)
        self.assertIn('run-id: 43616038272', source)
        self.assertIn('ref: ' + diagnostic.HOST, source)
        self.assertIn('case: main', source)
        self.assertNotIn('case: update2017', source)
        self.assertEqual(source.count('api-level: 35'), 1)
        self.assertNotIn('api37', source)
        self.assertNotIn('contents: write', source)
        runner = (ROOT / 'scripts/run_unchanged_6b_village_diagnostic.sh').read_text()
        self.assertIn('candidate-and-probe-binding-after.json', runner)
        self.assertIn('modernization_android_tour.py', runner)
        self.assertIn('lumo_2020_update_android_probe.py', runner)
        self.assertIn("'seven_job_acceptance': False", runner)

    def test_nonfinite_json_and_foreign_qa_event_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'input.json'
            path.write_text('{"value":NaN}')
            with self.assertRaises(ValueError):
                diagnostic.read_json(path)
        run, jobs = qa_metadata()
        run['event'] = 'pull_request'
        with self.assertRaises(RuntimeError):
            verify_qa(run, jobs)


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

