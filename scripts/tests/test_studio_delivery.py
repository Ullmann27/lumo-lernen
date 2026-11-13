"""Studio release gates: synthetic parser fixtures, never release approval.

The PNGs and receipts here exist only in TemporaryDirectory instances. Actual
Android Cards pixel checks reuse the historical test's verified renderer bytes;
their synthetic session data does not represent a device acceptance run.
"""
from __future__ import annotations

import ast
import copy
import hashlib
import inspect
import json
from pathlib import Path
import stat
import sys
import tempfile
import unittest
import warnings
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_nextgen_delivery as historical_tests
import verify_nextgen_delivery as historical
import verify_studio_delivery as delivery
from record_studio_visual_review import record_review


class StudioDeliveryTests(unittest.TestCase):
    cards_pixel_fixture = historical_tests.NextgenDeliveryTests.cards_pixel_fixture
    write_pixel_reports = staticmethod(historical_tests.NextgenDeliveryTests.write_pixel_reports)

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='studio-delivery-unit-')
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)

    def proof_fixture(self):
        # Only synthetic parser inputs are constructed for the new release.
        # Production verification never edits or normalizes evidence versions.
        args = historical_tests.NextgenDeliveryTests.proof_fixture(self)
        args[2] = '0.13.7'
        for info in (args[5], args[6], args[7], args[8]['candidate'],
                     args[9]['steps'][0], args[10]['apk_identity']):
            info.update(versionCode=2019, versionName='0.13.7')
        return args

    def review_fixture(self, *, portrait=True):
        root, native = self.base / 'fixture-images', 'b' * 40
        receipt = {'schema': 1, 'status': 'approved', 'versionCode': 2019, 'native_revision': native,
                   'native_workflow_run_id': 100, 'native_artifact_id': 200,
                   'reviewed_by': 'Synthetic unit-test reviewer',
                   'reviewed_at': '2026-11-13T00:00:00+00:00',
                   'notes': 'Synthetic parser fixture, not visual approval', 'images': []}
        members = {}
        for prefix in delivery.CAPTURE_SOURCES:
            members[prefix + '/source-sha.txt'] = (native + '\n').encode()
            members[prefix + '/source-dirty.txt'] = b''
        for index, (probe, module) in enumerate(sorted(delivery.CAPTURE_MODULES.items())):
            dimensions = (320, 600) if portrait and index == 0 else (640, 360)
            entry = probe + '/actual.png'
            data = historical_tests.fixture_png(*dimensions, index + 10)
            digest = hashlib.sha256(data).hexdigest()
            relative = delivery.reviewed_relative_path(digest, module, entry)
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            members[entry] = data
            receipt['images'].append({'path': relative, 'dimensions': list(dimensions), 'module': module,
                                      'sha256': digest, 'artifact_entry': entry,
                                      'findings': 'Synthetic original-image parser fixture only'})
        archive = self.base / 'native-fixture.zip'
        with zipfile.ZipFile(archive, 'w') as zipped:
            for name, data in members.items():
                zipped.writestr(name, data)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        receipt['native_artifact_sha256'] = digest
        artifact = {'id': 200, 'name': delivery.NATIVE_ARTIFACT, 'expired': False,
                    'digest': 'sha256:' + digest, 'workflow_run': {'id': 100, 'head_sha': native}}
        run = {'id': 100, 'head_sha': native, 'status': 'completed', 'conclusion': 'success',
               'path': delivery.NATIVE_WORKFLOW}
        jobs = {'jobs': [{'name': name, 'run_id': 100, 'head_sha': native,
                          'status': 'completed', 'conclusion': 'success'}
                         for name in sorted(delivery.NATIVE_JOBS)]}
        return [root, receipt, native, artifact, run, jobs, archive]

    @staticmethod
    def archive_change(args, changes):
        archive = args[6]
        with zipfile.ZipFile(archive) as zipped:
            members = {item.filename: zipped.read(item) for item in zipped.infolist()}
        for name, value in changes.items():
            if value is None:
                members.pop(name, None)
            else:
                members[name] = value
        with zipfile.ZipFile(archive, 'w') as zipped:
            for name, data in members.items():
                zipped.writestr(name, data)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        args[1]['native_artifact_sha256'] = digest
        args[3]['digest'] = 'sha256:' + digest

    @staticmethod
    def selection(args):
        return [{key: item[key] for key in ('module', 'artifact_entry', 'findings')}
                for item in args[1]['images']]

    def record(self, args, destination=None, selection=None):
        return record_review(destination or self.base / 'recorded', args[6], args[3], args[4], args[5],
                             self.selection(args) if selection is None else selection,
                             'Synthetic unit-test reviewer', 'Synthetic fixture, never production approval')

    def test_android_gate_body_is_preserved_without_rewriting_evidence(self):
        old = ast.parse(inspect.getsource(historical.verify_proofs)).body[0]
        new = ast.parse(inspect.getsource(delivery.verify_proofs)).body[0]
        self.assertIn('VERSION_NAME', ast.dump(new.body[0]))
        new.body.pop(0)  # Additional exact 0.13.7 guard.

        class HistoricalBuild(ast.NodeTransformer):
            def visit_Name(self, node):
                return ast.copy_location(ast.Constant(value=2018), node) if node.id == 'VERSION_CODE' else node

        new = HistoricalBuild().visit(new)
        self.assertEqual(ast.dump(new, include_attributes=False), ast.dump(old, include_attributes=False))
        self.assertIs(delivery.verify_cards_front_faces, historical.verify_cards_front_faces)
        self.assertEqual(delivery.BASELINE_SOURCE, historical.BASELINE_SOURCE)
        self.assertEqual(delivery.BASELINE_NATIVE, historical.BASELINE_NATIVE)

    def test_same_source_2019_fixture_retains_real_cards_pixel_recomputation(self):
        args = self.proof_fixture()
        before = copy.deepcopy(args[:-1])
        facts = delivery.verify_proofs(*args)
        self.assertEqual(args[:-1], before, 'Verifier must not rewrite input proof values')
        self.assertEqual((facts['versionName'], facts['versionCode']), ('0.13.7', 2019))
        self.assertEqual(len(facts['cardsFrontFacePixels']['stages']), 4)
        self.assertIn('not measured', facts['deviceScope'])

    def test_2018_or_wrong_version_identity_never_satisfies_2019(self):
        original = self.proof_fixture()
        for position in (5, 6, 7):
            for field, value in (('versionCode', 2018), ('versionName', '0.13.6')):
                args = copy.deepcopy(original)
                args[position][field] = value
                with self.subTest(position=position, field=field), self.assertRaises(ValueError):
                    delivery.verify_proofs(*args)
        for position in ('candidate', 'tour', 'surface', 'argument'):
            args = copy.deepcopy(original)
            if position == 'candidate': args[8]['candidate']['versionCode'] = 2018
            if position == 'tour': args[9]['steps'][0]['versionCode'] = 2018
            if position == 'surface': args[10]['apk_identity']['versionCode'] = 2018
            if position == 'argument': args[2] = '0.13.8'
            with self.subTest(position=position), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def test_package_signature_apk_bytes_source_and_abi_gates_remain_mandatory(self):
        original = self.proof_fixture()
        for position, field, value in ((5, 'tracked_source_clean', False),
                (5, 'flutter_source_commit', '0' * 40), (5, 'package', 'wrong.package'),
                (6, 'signingCertificateSha256', '0' * 64), (7, 'sha256', '0' * 64),
                (7, 'bytes', 12344), (6, 'abis', ['x86_64']), (7, 'godot', {'revision': '0' * 40})):
            args = copy.deepcopy(original)
            args[position][field] = value
            with self.subTest(position=position, field=field), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def test_real_2017_upgrade_current_android_cards_speech_and_host_remain_mandatory(self):
        original = self.proof_fixture()
        for mutation in ('baseline-version', 'baseline-source', 'baseline-native', 'candidate-source',
                         'candidate-pck', 'offline', 'crash', 'android-failed', 'old-tour',
                         'learning-mastery', 'speech-consent', 'speech-completion', 'cards-idle',
                         'cards-round', 'cards-pixels', 'host-source', 'host-bytecode'):
            args = copy.deepcopy(original)
            update, tour, surfaces, host = args[8:12]
            if mutation == 'baseline-version': update['baseline']['versionCode'] = 2018
            if mutation == 'baseline-source': update['baseline']['flutter_source_commit'] = '0' * 40
            if mutation == 'baseline-native': update['baseline']['godot']['revision'] = '0' * 40
            if mutation == 'candidate-source': update['candidate']['flutter_source_commit'] = '0' * 40
            if mutation == 'candidate-pck': update['candidate']['godot']['pck_sha256'] = '0' * 64
            if mutation == 'offline': update['offline'] = False
            if mutation == 'crash': tour['fatal_crashes'] = 1
            if mutation == 'android-failed': surfaces['status'] = 'FAIL'
            if mutation == 'old-tour': tour['apk_sha256'] = '0' * 64
            if mutation == 'learning-mastery': surfaces['learning']['illustration_did_not_award_mastery'] = False
            if mutation == 'speech-consent': surfaces['local_voice_permission']['local_model_assent'] = False
            if mutation == 'speech-completion': surfaces['learning']['speech']['result']['completed_utterance_ids'] = []
            if mutation == 'cards-idle': surfaces['cards']['visible_idle_seconds'] = 1
            if mutation == 'cards-round': surfaces['cards']['draw_after_visible_idle']['round_id'] = 'cards-' + 'f' * 32
            if mutation == 'cards-pixels': surfaces['cards']['front_face_pixels'] = []
            if mutation == 'host-source': host['flutter_source_commit'] = '0' * 40
            if mutation == 'host-bytecode': del host['classes']['CardsAuthorityService']
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def test_current_complete_original_archive_covers_nine_modules_and_four_jobs(self):
        args = self.review_fixture()
        result = delivery.verify_visual_review(*args)
        self.assertEqual(set(result['modules']), delivery.REVIEW_MODULES)
        self.assertEqual(set(result['native_acceptance_jobs']), delivery.NATIVE_JOBS)
        self.assertEqual(set(result['native_capture_sources']), set(delivery.CAPTURE_SOURCES))
        self.assertEqual(result['images'], 10)

    def test_old_pending_or_undated_receipts_fail(self):
        original = self.review_fixture()
        for field, value in (('versionCode', 2018), ('native_revision', '0' * 40),
                ('status', 'pending'), ('native_artifact_id', 199), ('native_workflow_run_id', 99),
                ('reviewed_by', ''), ('notes', ''), ('reviewed_at', '2026-11-13T00:00:00')):
            args = copy.deepcopy(original)
            args[1][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                delivery.verify_visual_review(*args)

    def test_current_artifact_workflow_and_exact_sha_are_mandatory(self):
        original = self.review_fixture()
        for mutation in ('old-artifact', 'expired', 'artifact-source', 'artifact-run', 'artifact-digest',
                         'workflow-source', 'workflow-path', 'workflow-failed', 'workflow-pending'):
            args = copy.deepcopy(original)
            artifact, run = args[3:5]
            if mutation == 'old-artifact': artifact['name'] = 'lumo-nextgen-2018-native-evidence'
            if mutation == 'expired': artifact['expired'] = True
            if mutation == 'artifact-source': artifact['workflow_run']['head_sha'] = '0' * 40
            if mutation == 'artifact-run': artifact['workflow_run']['id'] = 99
            if mutation == 'artifact-digest': artifact['digest'] = 'sha256:' + '0' * 64
            if mutation == 'workflow-source': run['head_sha'] = '0' * 40
            if mutation == 'workflow-path': run['path'] = '.github/workflows/lumo-nextgen-2018.yml'
            if mutation == 'workflow-failed': run['conclusion'] = 'failure'
            if mutation == 'workflow-pending': run['status'] = 'in_progress'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_visual_review(*args)

    def test_every_native_job_must_succeed_at_same_sha_and_run(self):
        original = self.review_fixture()
        for name in delivery.NATIVE_JOBS:
            for mutation in ('missing', 'duplicate', 'failed', 'skipped', 'pending', 'old-source', 'old-run'):
                args = copy.deepcopy(original)
                jobs = args[5]['jobs']
                job = next(item for item in jobs if item['name'] == name)
                if mutation == 'missing': jobs.remove(job)
                if mutation == 'duplicate': jobs.append(copy.deepcopy(job))
                if mutation == 'failed': job['conclusion'] = 'failure'
                if mutation == 'skipped': job['conclusion'] = 'skipped'
                if mutation == 'pending': job['status'] = 'in_progress'
                if mutation == 'old-source': job['head_sha'] = '0' * 40
                if mutation == 'old-run': job['run_id'] = 99
                with self.subTest(name=name, mutation=mutation), self.assertRaises(ValueError):
                    delivery.verify_visual_review(*args)

    def test_both_capture_sources_must_exist_match_and_be_clean(self):
        for prefix in delivery.CAPTURE_SOURCES:
            for mutation in ('old-sha', 'missing-sha', 'dirty', 'missing-dirty', 'bad-utf8'):
                args = self.review_fixture()
                changes = {}
                if mutation == 'old-sha': changes[prefix + '/source-sha.txt'] = b'0' * 40
                if mutation == 'missing-sha': changes[prefix + '/source-sha.txt'] = None
                if mutation == 'dirty': changes[prefix + '/source-dirty.txt'] = b' M scripts/changed.gd\n'
                if mutation == 'missing-dirty': changes[prefix + '/source-dirty.txt'] = None
                if mutation == 'bad-utf8': changes[prefix + '/source-sha.txt'] = b'\xff'
                self.archive_change(args, changes)
                with self.subTest(prefix=prefix, mutation=mutation), self.assertRaises(ValueError):
                    delivery.verify_visual_review(*args)

    def test_archive_is_rechecked_instead_of_trusting_receipt_and_metadata(self):
        args = self.review_fixture()
        args[6].write_bytes(args[6].read_bytes() + b'changed-after-review')
        with self.assertRaisesRegex(ValueError, 'archive digest differs'):
            delivery.verify_visual_review(*args)
        args[6].unlink()
        with self.assertRaisesRegex(ValueError, 'archive digest differs'):
            delivery.verify_visual_review(*args)

    def test_png_must_match_both_committed_bytes_and_original_current_artifact(self):
        args = self.review_fixture()
        item = args[1]['images'][0]
        path = args[0] / item['path']
        path.write_bytes(path.read_bytes() + b'changed')
        with self.assertRaisesRegex(ValueError, 'bytes changed'):
            delivery.verify_visual_review(*args)
        # Even a new full hash and plausible dimensions cannot bind different
        # bytes to the same unchanged original archive entry.
        item['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
        new_path = delivery.reviewed_relative_path(item['sha256'], item['module'], item['artifact_entry'])
        path.rename(args[0] / new_path)
        item['path'] = new_path
        with self.assertRaisesRegex(ValueError, 'differs from the original'):
            delivery.verify_visual_review(*args)

    def test_corrupt_png_with_forged_hashes_is_rejected_by_actual_decode(self):
        args = self.review_fixture()
        item = args[1]['images'][0]
        old_path = args[0] / item['path']
        data = old_path.read_bytes()[:40]
        item['sha256'] = hashlib.sha256(data).hexdigest()
        item['path'] = delivery.reviewed_relative_path(item['sha256'], item['module'], item['artifact_entry'])
        (args[0] / item['path']).write_bytes(data)
        self.archive_change(args, {item['artifact_entry']: data})
        with self.assertRaisesRegex(ValueError, 'corrupt or incomplete'):
            delivery.verify_visual_review(*args)

    def test_every_production_module_and_both_orientations_remain_required(self):
        original = self.review_fixture()
        for module in delivery.REVIEW_MODULES:
            args = copy.deepcopy(original)
            args[1]['images'] = [item for item in args[1]['images'] if item['module'] != module]
            with self.subTest(module=module), self.assertRaisesRegex(ValueError, 'all nine'):
                delivery.verify_visual_review(*args)
        with self.assertRaisesRegex(ValueError, 'Phone and landscape'):
            delivery.verify_visual_review(*self.review_fixture(portrait=False))

    def test_unknown_mislabeled_and_pose_studio_images_do_not_count_as_products(self):
        original = self.review_fixture()
        for mutation in ('wrong-module', 'unknown-module', 'pose-studio', 'outside-entry'):
            args = copy.deepcopy(original)
            image = args[1]['images'][0]
            if mutation == 'wrong-module': image['module'] = 'cards' if image['module'] != 'cards' else 'jump'
            if mutation == 'unknown-module': image['module'] = 'studio'
            if mutation == 'pose-studio': image['artifact_entry'] = 'studio-evidence/captures/lumo_studio_motion_capture/actual.png'
            if mutation == 'outside-entry': image['artifact_entry'] = 'studio-evidence/captures/../actual.png'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_visual_review(*args)

    def test_png_filename_dimensions_findings_and_duplicate_paths_are_checked(self):
        original = self.review_fixture()
        for mutation in ('old-name', 'wrong-dimensions', 'empty-findings', 'duplicate'):
            args = copy.deepcopy(original)
            image = args[1]['images'][0]
            if mutation == 'old-name': image['path'] = 'docs/evidence/studio-2019-reviewed/01-learning-actual.png'
            if mutation == 'wrong-dimensions': image['dimensions'] = [321, 600]
            if mutation == 'empty-findings': image['findings'] = ' '
            if mutation == 'duplicate': args[1]['images'].append(copy.deepcopy(image))
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_visual_review(*args)

    def test_committed_png_symlink_cannot_satisfy_review(self):
        args = self.review_fixture()
        image = args[1]['images'][0]
        path = args[0] / image['path']
        saved = self.base / 'outside.png'
        path.rename(saved)
        path.symlink_to(saved)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            delivery.verify_visual_review(*args)

    def test_duplicate_zip_source_stamp_or_capture_is_ambiguous(self):
        for name in ('studio-evidence/source-sha.txt', 'nextgen-evidence/nextgen/captures/cards_table_capture/actual.png'):
            args = self.review_fixture()
            with zipfile.ZipFile(args[6], 'a') as zipped, warnings.catch_warnings():
                warnings.simplefilter('ignore', UserWarning)
                zipped.writestr(name, zipped.read(name))
            digest = hashlib.sha256(args[6].read_bytes()).hexdigest()
            args[1]['native_artifact_sha256'] = digest
            args[3]['digest'] = 'sha256:' + digest
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, 'duplicate original'):
                delivery.verify_visual_review(*args)

    def test_archive_symlink_is_not_an_original_png(self):
        args = self.review_fixture()
        target = args[1]['images'][0]['artifact_entry']
        with zipfile.ZipFile(args[6]) as zipped:
            members = {item.filename: zipped.read(item) for item in zipped.infolist()}
        with zipfile.ZipFile(args[6], 'w') as zipped:
            for name, data in members.items():
                entry = zipfile.ZipInfo(name)
                if name == target:
                    entry.create_system = 3
                    entry.external_attr = (stat.S_IFLNK | 0o777) << 16
                zipped.writestr(entry, data)
        digest = hashlib.sha256(args[6].read_bytes()).hexdigest()
        args[1]['native_artifact_sha256'] = digest
        args[3]['digest'] = 'sha256:' + digest
        with self.assertRaisesRegex(ValueError, 'original regular file'):
            delivery.verify_visual_review(*args)

    def test_recording_copies_only_hash_bound_originals_into_separate_2019_paths(self):
        args = self.review_fixture()
        output = self.record(args)
        root = self.base / 'recorded'
        self.assertEqual(output['versionCode'], 2019)
        self.assertTrue((root / delivery.REVIEW_RECEIPT).is_file())
        self.assertFalse((root / 'config/nextgen-2018-visual-review.json').exists())
        for item in output['images']:
            self.assertEqual(hashlib.sha256((root / item['path']).read_bytes()).hexdigest(), item['sha256'])
            self.assertTrue(Path(item['path']).name.startswith(item['sha256'] + '-' + item['module'] + '-'))
        delivery.verify_visual_review(root, output, args[2], args[3], args[4], args[5], args[6])

    def test_reordered_reviews_and_new_bytes_never_overwrite_previous_originals(self):
        args = self.review_fixture()
        first = self.record(args)
        original_bytes = {item['path']: (self.base / 'recorded' / item['path']).read_bytes()
                          for item in first['images']}
        reordered = self.record(args, selection=list(reversed(self.selection(args))))
        self.assertEqual({item['path'] for item in reordered['images']}, set(original_bytes))
        changed = args[1]['images'][0]
        fresh_png = historical_tests.fixture_png(*changed['dimensions'], 90)
        self.archive_change(args, {changed['artifact_entry']: fresh_png})
        second = self.record(args)
        self.assertEqual(len(set(original_bytes) | {item['path'] for item in second['images']}), 11)
        for relative, data in original_bytes.items():
            self.assertEqual((self.base / 'recorded' / relative).read_bytes(), data)

    def test_destination_collision_is_rejected_before_receipt_or_other_images_are_written(self):
        args = self.review_fixture()
        root = self.base / 'recorded'
        path = root / args[1]['images'][-1]['path']
        path.parent.mkdir(parents=True)
        path.write_bytes(b'Existing different bytes must remain unchanged')
        with self.assertRaisesRegex(ValueError, 'different reviewed image already exists'):
            self.record(args)
        self.assertEqual(path.read_bytes(), b'Existing different bytes must remain unchanged')
        self.assertFalse((root / delivery.REVIEW_RECEIPT).exists())
        self.assertEqual(len(list((root / delivery.REVIEW_DIRECTORY).glob('*.png'))), 1)

    def test_failed_acceptance_or_modified_source_never_records_an_approved_receipt(self):
        for mutation in ('failed-job', 'dirty-studio', 'dirty-nextgen', 'unreviewed-module'):
            args = self.review_fixture()
            selection = self.selection(args)
            if mutation == 'failed-job': args[5]['jobs'][0]['conclusion'] = 'failure'
            if mutation == 'dirty-studio': self.archive_change(args, {'studio-evidence/source-dirty.txt': b' M actual.gd'})
            if mutation == 'dirty-nextgen': self.archive_change(args, {'nextgen-evidence/nextgen/source-dirty.txt': b' M actual.gd'})
            if mutation == 'unreviewed-module': selection = [item for item in selection if item['module'] != 'treasure']
            destination = self.base / mutation
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.record(args, destination, selection)
            self.assertFalse((destination / delivery.REVIEW_RECEIPT).exists())
            self.assertFalse((destination / delivery.REVIEW_DIRECTORY).exists())


if __name__ == '__main__':
    unittest.main()
