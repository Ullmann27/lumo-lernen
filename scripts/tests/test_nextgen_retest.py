"""Fail-closed source and archive tests for the unchanged-a31 APK recovery.

All generated JSON, ZIPs and file bytes below are parser fixtures, never actual
Android evidence. The recovery job separately fetches and hashes original API
artifacts and then reruns the complete live tour and update gates.
"""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import stat
import tempfile
import unittest
from unittest.mock import patch
import zipfile


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('nextgen_retest', ROOT / 'scripts/verify_nextgen_retest.py')
RETEST = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RETEST)
QA_SOURCE = 'b' * 40


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value))


class NextgenRetestTests(unittest.TestCase):
    def setUp(self):
        self.run = {'id': RETEST.ORIGINAL_RUN, 'head_sha': RETEST.APK_SOURCE,
                    'status': 'completed', 'conclusion': 'failure', 'event': 'pull_request',
                    'head_branch': RETEST.PRODUCT_BRANCH, 'repository': {'full_name': RETEST.REPO}}
        self.jobs = {'total_count': 3, 'jobs': [
            {'id': 131739877430, 'run_id': RETEST.ORIGINAL_RUN, 'name': 'verify-and-build',
             'status': 'completed', 'conclusion': 'success',
             'steps': [{'name': name, 'conclusion': 'success'} for name in RETEST.REQUIRED_BUILD_STEPS]},
            {'id': 131739877829, 'run_id': RETEST.ORIGINAL_RUN, 'name': 'android-host-compile',
             'status': 'completed', 'conclusion': 'success', 'steps': [{
                 'name': 'Compile actual current Android host before native release pin approval',
                 'conclusion': 'success'}]},
            {'id': 131762099939, 'run_id': RETEST.ORIGINAL_RUN, 'name': 'android-tour',
             'status': 'completed', 'conclusion': 'failure'},
        ]}
        self.app_tree = {path: '100644 blob ' + '1' * 40 for path in
                         RETEST.PROBE_FILES | {'pubspec.yaml', 'lib/app/app_shell.dart'}}
        self.qa_tree = dict(self.app_tree)
        self.qa_tree.update({path: '100644 blob ' + '2' * 40 for path in RETEST.ALLOWED_CHANGES})

    def test_completed_build_and_compile_reuse_keeps_original_tour_failure(self):
        RETEST.verify_upstream(self.run, self.jobs)
        for conclusion in ('success', 'skipped', 'cancelled'):
            jobs = copy.deepcopy(self.jobs)
            jobs['jobs'][2]['conclusion'] = conclusion
            with self.subTest(conclusion=conclusion), self.assertRaises(ValueError):
                RETEST.verify_upstream(self.run, jobs)

    def test_foreign_or_relabelled_original_workflow_is_rejected(self):
        for field, value in (('id', 123), ('head_sha', QA_SOURCE), ('status', 'in_progress'),
                             ('conclusion', 'success'), ('event', 'push'), ('head_branch', RETEST.QA_BRANCH),
                             ('repository', {'full_name': 'other/repo'})):
            with self.subTest(field=field), self.assertRaises(ValueError):
                RETEST.verify_upstream(dict(self.run, **{field: value}), self.jobs)

    def test_failed_skipped_missing_or_foreign_original_job_is_rejected(self):
        for index in (0, 1):
            for field, value in (('conclusion', 'failure'), ('conclusion', 'skipped'),
                                 ('status', 'in_progress'), ('id', 0), ('run_id', 1), ('steps', [])):
                jobs = copy.deepcopy(self.jobs)
                jobs['jobs'][index][field] = value
                with self.subTest(index=index, field=field, value=value), self.assertRaises(ValueError):
                    RETEST.verify_upstream(self.run, jobs)
        with self.assertRaises(ValueError):
            RETEST.verify_upstream(self.run, {'total_count': 3, 'jobs': self.jobs['jobs'][1:]})

    def test_each_mandatory_build_step_must_actually_pass(self):
        for step in RETEST.REQUIRED_BUILD_STEPS:
            jobs = copy.deepcopy(self.jobs)
            next(s for s in jobs['jobs'][0]['steps'] if s['name'] == step)['conclusion'] = 'skipped'
            with self.subTest(step=step), self.assertRaises(ValueError):
                RETEST.verify_upstream(self.run, jobs)

    def test_all_fixed_artifacts_require_exact_id_source_size_and_digest(self):
        for kind, (identifier, name, size, digest, run, source) in RETEST.ARTIFACTS.items():
            metadata = {'id': identifier, 'name': name, 'size_in_bytes': size, 'expired': False,
                        'digest': 'sha256:' + digest, 'workflow_run': {'id': run, 'head_sha': source,
                        'repository_id': 1222433959, 'head_repository_id': 1222433959}}
            RETEST.verify_artifact(kind, metadata)
            for field, value in (('id', 0), ('name', 'other'), ('size_in_bytes', size + 1),
                                 ('expired', True), ('digest', 'sha256:' + 'a' * 64)):
                with self.subTest(kind=kind, field=field), self.assertRaises(ValueError):
                    RETEST.verify_artifact(kind, dict(metadata, **{field: value}))
            for field, value in (('id', 1), ('head_sha', QA_SOURCE), ('repository_id', 2),
                                 ('head_repository_id', 2)):
                changed = copy.deepcopy(metadata)
                changed['workflow_run'][field] = value
                with self.subTest(kind=kind, workflow_field=field), self.assertRaises(ValueError):
                    RETEST.verify_artifact(kind, changed)

    def test_only_explicit_regular_qa_files_can_differ_from_apk_checkout(self):
        changed = RETEST.verify_tree_scope(RETEST.APK_SOURCE, QA_SOURCE,
                                           self.app_tree, self.qa_tree, True, True)
        self.assertEqual(set(changed), RETEST.ALLOWED_CHANGES)
        for field in ('lib/app/app_shell.dart', 'pubspec.yaml', 'config/godot-source.json',
                      'tools/auto_install/LumoGameActivity.kt', 'scripts/verify_nextgen_delivery.py',
                      'scripts/verify_unified_apk.py', 'lib/core/progress_repository.dart',
                      'lib/domain/learning/independent_evidence.dart',
                      'tools/android_qa/kart_tour_evidence.py'):
            changed_tree = dict(self.qa_tree, **{field: '100644 blob ' + '3' * 40})
            with self.subTest(field=field), self.assertRaises(ValueError):
                RETEST.verify_tree_scope(RETEST.APK_SOURCE, QA_SOURCE,
                                         self.app_tree, changed_tree, True, True)

    def test_deletions_renames_symlinks_and_gitlinks_are_rejected(self):
        key = next(iter(RETEST.PROBE_FILES))
        for replacement in (None, '120000 blob ' + '3' * 40, '160000 commit ' + '3' * 40,
                            '100644 blob invalid'):
            changed = dict(self.qa_tree)
            if replacement is None:
                del changed[key]
            else:
                changed[key] = replacement
            with self.subTest(replacement=replacement), self.assertRaises(ValueError):
                RETEST.verify_tree_scope(RETEST.APK_SOURCE, QA_SOURCE, self.app_tree, changed, True, True)
        renamed = dict(self.qa_tree)
        renamed[key + '.renamed'] = renamed.pop(key)
        with self.assertRaises(ValueError):
            RETEST.verify_tree_scope(RETEST.APK_SOURCE, QA_SOURCE, self.app_tree, renamed, True, True)

    def test_dirty_wrong_checkout_or_missing_corrected_probe_never_passes(self):
        for app, qa, app_clean, qa_clean in ((RETEST.APK_SOURCE, RETEST.APK_SOURCE, True, True),
                                            (QA_SOURCE, 'c' * 40, True, True),
                                            (RETEST.APK_SOURCE, QA_SOURCE, False, True),
                                            (RETEST.APK_SOURCE, QA_SOURCE, True, False),
                                            (RETEST.APK_SOURCE, 'invalid', True, True)):
            with self.subTest(app=app, qa=qa, clean=(app_clean, qa_clean)), self.assertRaises(ValueError):
                RETEST.verify_tree_scope(app, qa, self.app_tree, self.qa_tree, app_clean, qa_clean)
        for key in RETEST.PROBE_FILES:
            qa_tree = dict(self.qa_tree)
            qa_tree[key] = self.app_tree[key]
            with self.subTest(key=key), self.assertRaises(ValueError):
                RETEST.verify_tree_scope(RETEST.APK_SOURCE, QA_SOURCE, self.app_tree, qa_tree, True, True)

    def product_fixture(self):
        pull = {'number': 461, 'state': 'open', 'merged': False,
                'head': {'sha': RETEST.APK_SOURCE, 'ref': RETEST.PRODUCT_BRANCH,
                         'repo': {'full_name': RETEST.REPO}},
                'base': {'ref': 'chatgpt/lumo-spielewelt-stage-20261112',
                         'repo': {'full_name': RETEST.REPO}}}
        branch = {'ref': 'refs/heads/' + RETEST.PRODUCT_BRANCH,
                  'object': {'type': 'commit', 'sha': RETEST.APK_SOURCE}}
        kwargs = {'repository': RETEST.REPO, 'number': 461, 'source': RETEST.APK_SOURCE,
                  'base': 'chatgpt/lumo-spielewelt-stage-20261112'}
        return pull, branch, kwargs

    def test_product_head_check_rejects_advanced_closed_merged_foreign_or_rebased_pr(self):
        pull, branch, kwargs = self.product_fixture()
        RETEST.verify_product_head(pull, branch, **kwargs)
        for section, field, value in ((None, 'state', 'closed'), (None, 'merged', True),
                                      (None, 'number', 462), ('head', 'sha', QA_SOURCE),
                                      ('head', 'ref', 'other'), ('base', 'ref', 'main'),
                                      ('head', 'repo', {'full_name': 'other/repo'})):
            changed = copy.deepcopy(pull)
            (changed if section is None else changed[section])[field] = value
            with self.subTest(section=section, field=field), self.assertRaises(ValueError):
                RETEST.verify_product_head(changed, branch, **kwargs)
        for field, value in (('sha', QA_SOURCE), ('type', 'tag')):
            changed = copy.deepcopy(branch)
            changed['object'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                RETEST.verify_product_head(pull, changed, **kwargs)

    def test_automation_head_is_separate_current_internal_pr(self):
        run = {'id': 42, 'head_sha': QA_SOURCE, 'head_branch': RETEST.QA_BRANCH,
               'event': 'pull_request', 'path': RETEST.WORKFLOW_PATH,
               'repository': {'full_name': RETEST.REPO}}
        branch = {'ref': 'refs/heads/' + RETEST.QA_BRANCH, 'object': {'type': 'commit', 'sha': QA_SOURCE}}
        RETEST.verify_automation(run, branch, QA_SOURCE, 42)
        for key, value in (('head_sha', RETEST.APK_SOURCE), ('head_branch', RETEST.PRODUCT_BRANCH),
                           ('event', 'push'), ('id', 43), ('path', '.github/workflows/other.yml')):
            with self.subTest(key=key), self.assertRaises(ValueError):
                RETEST.verify_automation(dict(run, **{key: value}), branch, QA_SOURCE, 42)
        branch['object']['sha'] = 'c' * 40
        with self.assertRaises(ValueError):
            RETEST.verify_automation(run, branch, QA_SOURCE, 42)

    def test_current_artifact_requires_this_automation_run_and_real_digest(self):
        metadata = {'id': 12, 'name': RETEST.CURRENT_ARTIFACTS['tour'], 'size_in_bytes': 50,
                    'digest': 'sha256:' + 'a' * 64, 'expired': False,
                    'workflow_run': {'id': 42, 'head_sha': QA_SOURCE,
                                     'repository_id': 1222433959, 'head_repository_id': 1222433959}}
        RETEST.verify_current_artifact('tour', metadata, 42, QA_SOURCE)
        for field, value in (('id', 0), ('size_in_bytes', 0), ('expired', True), ('digest', 'missing'),
                             ('name', RETEST.ARTIFACTS['failed-tour'][1])):
            with self.subTest(field=field), self.assertRaises(ValueError):
                RETEST.verify_current_artifact('tour', dict(metadata, **{field: value}), 42, QA_SOURCE)
        for field, value in (('id', RETEST.ORIGINAL_RUN), ('head_sha', RETEST.APK_SOURCE),
                             ('repository_id', 1), ('head_repository_id', 2)):
            changed = copy.deepcopy(metadata)
            changed['workflow_run'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                RETEST.verify_current_artifact('tour', changed, 42, QA_SOURCE)

    def test_archive_real_hash_crc_and_empty_destination_are_required(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            archive = root / 'parser-fixture.zip'
            with zipfile.ZipFile(archive, 'w') as zipped:
                zipped.writestr('x86_64/identity.json', '{"parser_fixture":true}')
            size, digest = archive.stat().st_size, RETEST.sha256(archive)
            RETEST.extract_verified(archive, root / 'out', size, digest)
            self.assertEqual((root / 'out/x86_64/identity.json').read_text(), '{"parser_fixture":true}')
            for bad_size, bad_digest in ((size + 1, digest), (size, 'a' * 64)):
                with self.subTest(size=bad_size, digest=bad_digest), self.assertRaises(ValueError):
                    RETEST.extract_verified(archive, root / 'bad', bad_size, bad_digest)
            with self.assertRaises(ValueError):
                RETEST.extract_verified(archive, root / 'out', size, digest)
            broken = archive.read_bytes().replace(b'{"parser_fixture":true}', b'{"parser_fixture":FAIL}')
            archive.write_bytes(broken)
            with self.assertRaises(ValueError):
                RETEST.extract_verified(archive, root / 'crc', len(broken), RETEST.sha256(archive))

    def test_archive_rejects_traversal_duplicate_names_and_symlink_entries(self):
        for members in (('../escape',), ('/absolute',), ('directory\\escape',),
                        ('normal', 'normal'), ('a//b',), ('a/./b',), ('link',)):
            with self.subTest(members=members), tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                archive = root / 'bad.zip'
                with zipfile.ZipFile(archive, 'w') as zipped:
                    for name in members:
                        info = zipfile.ZipInfo(name)
                        if name == 'link':
                            info.external_attr = (stat.S_IFLNK | 0o777) << 16
                        zipped.writestr(info, 'parser fixture')
                with self.assertRaises(ValueError):
                    RETEST.extract_verified(archive, root / 'out', archive.stat().st_size, RETEST.sha256(archive))

    def test_foreign_apk_bytes_rejected_even_if_native_pin_would_match(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'Lumo-Lernen-Neu.apk').write_bytes(b'not the exact APK')
            for abi in ('arm64-v8a', 'x86_64'):
                with self.subTest(abi=abi), self.assertRaisesRegex(ValueError, 'APK differs'):
                    RETEST.verify_apk_payload(root, abi)

    def failure_fixture(self, root):
        prior, qa = root / 'prior', root / 'qa'
        write_json(prior / 'tour-result.json', {'status': 'PASS', 'apk_sha256': RETEST.APK_X86_SHA256})
        write_json(prior / 'nextgen/native-surfaces-result.json', {
            'status': 'FAIL', 'error': 'TimeoutError: Current native surface/target did not settle before touch: Ein Objekt zeigen',
            'apk_identity': {'apk_sha256': RETEST.APK_X86_SHA256, 'flutter_source_commit': RETEST.APK_SOURCE}})
        frames = [{'pixels': [1080, 2400], 'acceptable_for_target_sampling': False,
                   'reasons': ['native landscape surface has not arrived']} for _ in range(37)]
        for index, suffix in ((0, '00'), (36, '36')):
            recorded = prior / 'nextgen' / f'learning-move-1-{index}.png'
            recorded.write_bytes(b'parser fixture only: ' + str(index).encode())
            fixture = qa / 'tools/android_qa/tests/fixtures' / f'android_2018_learning_portrait_a31_{suffix}.png'
            fixture.parent.mkdir(parents=True, exist_ok=True)
            fixture.write_bytes(recorded.read_bytes())
            frames[index]['source_sha256'] = RETEST.sha256(recorded)
        write_json(prior / 'nextgen/learning-move-1-surface-readiness.json',
                   {'status': 'FAIL', 'timeout_seconds': 120, 'frames': frames})
        return prior, qa

    def test_original_failure_must_remain_the_exact_pre_touch_portrait_diagnosis(self):
        with tempfile.TemporaryDirectory() as folder:
            prior, qa = self.failure_fixture(Path(folder))
            proof = RETEST.verify_failed_original(prior, qa)
            self.assertFalse(proof['first_learning_touch_performed'])
            readiness_path = prior / 'nextgen/learning-move-1-surface-readiness.json'
            original = json.loads(readiness_path.read_text())
            for key, value in (('status', 'PASS'), ('timeout_seconds', 30), ('frames', []), ('touch', [1, 2])):
                write_json(readiness_path, dict(original, **{key: value}))
                with self.subTest(key=key), self.assertRaises(ValueError):
                    RETEST.verify_failed_original(prior, qa)
            write_json(readiness_path, original)
            next((qa / 'tools/android_qa/tests/fixtures').glob('*.png')).write_bytes(b'changed')
            with self.assertRaisesRegex(ValueError, 'fixture differs'):
                RETEST.verify_failed_original(prior, qa)

    def test_old_navigation_failure_or_claimed_surface_success_cannot_be_reused(self):
        with tempfile.TemporaryDirectory() as folder:
            prior, qa = self.failure_fixture(Path(folder))
            path = prior / 'nextgen/native-surfaces-result.json'
            original = json.loads(path.read_text())
            for key, value in (('status', 'PASS'), ('error', "No live Flutter route: ['Lumo erklärt es mir']"),
                               ('apk_identity', {'apk_sha256': '0' * 64})):
                write_json(path, dict(original, **{key: value}))
                with self.subTest(key=key), self.assertRaises(ValueError):
                    RETEST.verify_failed_original(prior, qa)

    def test_missing_failed_or_old_current_android_update_jobs_block_publication(self):
        names = ('verify-reused-source', 'android-tour', 'update-2018-from-2017')
        jobs = {'total_count': 3, 'jobs': [{'name': name, 'run_id': 42, 'status': 'completed',
                                          'conclusion': 'success'} for name in names]}
        RETEST.verify_recovery_jobs(jobs, 42)
        for index in range(3):
            for key, value in (('conclusion', 'failure'), ('conclusion', 'skipped'),
                               ('status', 'in_progress'), ('run_id', RETEST.ORIGINAL_RUN)):
                changed = copy.deepcopy(jobs)
                changed['jobs'][index][key] = value
                with self.subTest(index=index, key=key), self.assertRaises(ValueError):
                    RETEST.verify_recovery_jobs(changed, 42)
        with self.assertRaises(ValueError):
            RETEST.verify_recovery_jobs({'jobs': jobs['jobs'][:2]}, 42)

    def test_publication_facts_cannot_use_automation_source_or_another_apk(self):
        identity = {'qa_workflow_run_id': 42, 'apk_source_commit': RETEST.APK_SOURCE}
        jobs = {'jobs': [{'name': name, 'run_id': 42, 'status': 'completed', 'conclusion': 'success'}
                         for name in ('verify-reused-source', 'android-tour', 'update-2018-from-2017')]}
        facts = {'flutterSourceCommit': RETEST.APK_SOURCE, 'godotSourceCommit': RETEST.NATIVE_SOURCE,
                 'apkSha256': RETEST.APK_ARM64_SHA256, 'apkBytes': 321298305,
                 'androidTourApkSha256': RETEST.APK_X86_SHA256, 'versionCode': 2018}
        with tempfile.TemporaryDirectory() as folder, patch.object(RETEST, 'verify_receipt', return_value=identity), \
                patch.object(RETEST, 'api', return_value=jobs):
            root = Path(folder)
            path = root / 'facts.json'
            write_json(path, facts)
            RETEST.authorize_publication(root, root, root, path, root / 'receipt')
            self.assertTrue((root / 'receipt/RECOVERY-AUTHORIZATION.json').is_file())
            for key, value in (('flutterSourceCommit', QA_SOURCE), ('godotSourceCommit', '0' * 40),
                               ('apkSha256', '0' * 64), ('apkBytes', 1),
                               ('androidTourApkSha256', '0' * 64), ('versionCode', 2017)):
                write_json(path, dict(facts, **{key: value}))
                with self.subTest(key=key), self.assertRaises(ValueError):
                    RETEST.authorize_publication(root, root, root, path, root / 'rejected')
            self.assertFalse((root / 'rejected/RECOVERY-AUTHORIZATION.json').exists())


class RecoveryWorkflowContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = (ROOT / RETEST.WORKFLOW_PATH).read_text()

    def test_two_checkouts_keep_product_source_and_automation_separate_without_rebuilding(self):
        self.assertIn('APP_SOURCE_SHA: ' + RETEST.APK_SOURCE, self.workflow)
        self.assertEqual(self.workflow.count('ref: ${{ env.APP_SOURCE_SHA }}'), 4)
        self.assertEqual(self.workflow.count('ref: ${{ env.QA_SOURCE_SHA }}'), 4)
        self.assertIn('defaults:\n  run:\n    working-directory: app', self.workflow)
        for forbidden in ('flutter build', 'build_unified_apk.py', './gradlew', 'git reset', 'git checkout',
                          'actions/download-artifact', 'pull_request_target:', '  push:', 'workflow_dispatch:'):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, self.workflow)
        self.assertIn("github.head_ref == '" + RETEST.QA_BRANCH + "'", self.workflow)
        self.assertIn("github.event.pull_request.head.repo.full_name == github.repository", self.workflow)

    def test_emulator_cwd_binds_apk_source_and_update_uses_reviewed_qa_helper(self):
        self.assertEqual(self.workflow.count('        working-directory: app'), 2)
        self.assertIn('.probe-venv/bin/python .github/probes/modernization_android_tour.py --apk', self.workflow)
        self.assertIn('"$GITHUB_WORKSPACE/acceptance/.github/probes/lumo_nextgen_surfaces_android_probe.py" --apk',
                      self.workflow)
        self.assertIn('.probe-venv/bin/python "$GITHUB_WORKSPACE/acceptance/.github/probes/lumo_2018_update_android_probe.py" --baseline', self.workflow)
        self.assertNotIn('.probe-venv/bin/python .github/probes/lumo_2018_update_android_probe.py --baseline', self.workflow)
        self.assertIn('"$GITHUB_WORKSPACE/acceptance/tools/android_qa/update_preservation.py"', self.workflow)
        self.assertIn('-s "$GITHUB_WORKSPACE/acceptance/tools/android_qa/tests" -p test_update_preservation.py -v', self.workflow)
        self.assertIn('LUMO_CANDIDATE_SOURCE_SHA: ${{ env.APP_SOURCE_SHA }}', self.workflow)
        self.assertNotIn('LUMO_CANDIDATE_SOURCE_SHA: ${{ env.QA_SOURCE_SHA }}', self.workflow)
        self.assertNotIn('LUMO_CANDIDATE_SOURCE_SHA: ${{ github.sha }}', self.workflow)

    def test_full_ocr_probe_tests_follow_mandatory_dependencies_and_reject_skips(self):
        dependency = self.workflow.index('install -y tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng')
        tests = self.workflow.index('-m unittest discover -s tools/android_qa/tests -p \'test_*.py\'')
        self.assertLess(dependency, tests)
        self.assertIn('Pillow==12.3.0', self.workflow)
        self.assertIn('Recovery acceptance rejects skipped tests.', self.workflow)
        self.assertIn('set -euo pipefail', self.workflow)

    def test_downloads_and_release_require_current_gates_and_original_byte_validators(self):
        for kind in ('candidate', 'arm64', 'compile', 'baseline'):
            with self.subTest(kind=kind):
                self.assertIn('download --kind ' + kind, self.workflow)
        for kind in ('prerequisites', 'tour', 'update'):
            self.assertIn('download-current --kind ' + kind, self.workflow)
        for gate in ('verify-reused-source', 'android-tour', 'update-2018-from-2017'):
            self.assertIn("needs." + gate + ".result == 'success'", self.workflow)
        for unchanged in ('scripts/verify_legacy_release_pin.py', 'scripts/verify_unified_apk.py',
                          'scripts/verify_nextgen_delivery.py', 'scripts/release_pipeline_gates.py'):
            self.assertIn('python3 ' + unchanged, self.workflow)
            self.assertNotIn(unchanged, RETEST.ALLOWED_CHANGES)
        self.assertEqual(self.workflow.count('authorize-publication --app'), 3)
        self.assertIn('--target "$SOURCE_SHA"', self.workflow)
        self.assertIn('SOURCE_SHA: ${{ env.APP_SOURCE_SHA }}', self.workflow)
        self.assertIn('Public download bytes differ', self.workflow)
        self.assertIn('original workflow 43381440720 remains failed', self.workflow)

    def test_disposable_tour_and_update_run_in_parallel_but_publisher_requires_both(self):
        update = self.workflow.split('  update-2018-from-2017:\n', 1)[1].split('    permissions:', 1)[0]
        self.assertEqual(update.strip(), 'needs:\n    - verify-reused-source')
        publisher = self.workflow.split('  publish-reviewed-2018:\n', 1)[1]
        self.assertIn('    - android-tour\n    - update-2018-from-2017\n', publisher)
        self.assertIn("needs.android-tour.result == 'success'", publisher)
        self.assertIn("needs.update-2018-from-2017.result == 'success'", publisher)


if __name__ == '__main__':
    unittest.main()
