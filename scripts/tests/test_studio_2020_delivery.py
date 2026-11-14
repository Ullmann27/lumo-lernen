"""Explicit 2020 parser contracts; synthetic fixtures are never release proof."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_studio_delivery as previous
import verify_studio_delivery as delivery
from record_studio_visual_review import record_review


class Studio2020DeliveryTests(unittest.TestCase):
    cards_pixel_fixture = previous.StudioDeliveryTests.cards_pixel_fixture
    write_pixel_reports = staticmethod(previous.StudioDeliveryTests.write_pixel_reports)
    setUp = previous.StudioDeliveryTests.setUp

    def proof_fixture(self):
        args = previous.StudioDeliveryTests.proof_fixture(self)
        args[2] = '0.13.8'
        for info in (args[5], args[6], args[7], args[8]['candidate'],
                     args[9]['steps'][0], args[10]['apk_identity']):
            info.update(versionCode=2020, versionName='0.13.8')
        return args

    def review_fixture(self):
        args = previous.StudioDeliveryTests.review_fixture(self)
        root, receipt, native, artifact, run, jobs, archive = args
        release = delivery.studio_release(2020)
        receipt['versionCode'] = 2020
        artifact['name'] = release.native_artifact
        run['path'] = release.native_workflow
        with zipfile.ZipFile(archive) as zipped:
            members = {item.filename: zipped.read(item) for item in zipped.infolist()}
        for item in receipt['images']:
            relative = delivery.reviewed_relative_path(
                item['sha256'], item['module'], item['artifact_entry'], studio_version=2020)
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(members[item['artifact_entry']])
            item['path'] = relative
        for index, entry in enumerate(sorted(release.required_images)):
            module = delivery.capture_module(entry, studio_version=2020)
            dimensions = (412, 915) if 'playing-phone' in entry else (640, 640)
            data = previous.historical_tests.fixture_png(*dimensions, 80 + index)
            digest = hashlib.sha256(data).hexdigest()
            relative = delivery.reviewed_relative_path(digest, module, entry, studio_version=2020)
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            members[entry] = data
            receipt['images'].append({
                'path': relative, 'dimensions': list(dimensions), 'module': module,
                'sha256': digest, 'artifact_entry': entry,
                'findings': 'Synthetic complete parser fixture, not an actual rendered review'})
        with zipfile.ZipFile(archive, 'w') as zipped:
            for name, data in members.items():
                zipped.writestr(name, data)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        artifact['digest'] = 'sha256:' + digest
        receipt['native_artifact_sha256'] = digest
        return args

    def test_only_explicit_immutable_contracts_are_selectable(self):
        old = delivery.studio_release()
        new = delivery.studio_release(2020)
        self.assertEqual((old.version_code, old.version_name), (2019, '0.13.7'))
        self.assertEqual((new.version_code, new.version_name), (2020, '0.13.8'))
        for value in (True, False, 2018, 2021, '2020', 2020.0, None):
            with self.subTest(value=value), self.assertRaises(ValueError):
                delivery.studio_release(value)
        with self.assertRaises(AttributeError):
            new.version_code = 2019
        with self.assertRaises(TypeError):
            new.capture_modules['forged'] = 'connect_four'

    def test_old_policy_and_module_exports_remain_exact(self):
        old = delivery.studio_release(2019)
        self.assertEqual(old.review_modules, delivery.REVIEW_MODULES)
        self.assertEqual(dict(old.capture_modules), delivery.CAPTURE_MODULES)
        self.assertEqual(old.review_directory, delivery.REVIEW_DIRECTORY)
        self.assertEqual(old.review_receipt, delivery.REVIEW_RECEIPT)
        self.assertEqual(old.required_images, frozenset())
        self.assertEqual(len(delivery.CAPTURE_MODULES), 15)

    def test_new_proof_keeps_actual_identity_save_cards_and_voice_guards(self):
        args = self.proof_fixture()
        untouched = copy.deepcopy(args[:-1])
        facts = delivery.verify_proofs(*args, studio_version=2020)
        self.assertEqual(facts['versionCode'], 2020)
        self.assertEqual(facts['versionName'], '0.13.8')
        self.assertEqual(args[:-1], untouched)
        for index, key, value in ((5, 'versionCode', 2019), (6, 'versionName', '0.13.7')):
            changed = list(args)
            changed[index] = {**args[index], key: value}
            with self.subTest(index=index, field=key), self.assertRaises(ValueError):
                delivery.verify_proofs(*changed, studio_version=2020)
        broken = copy.deepcopy(args[10])
        broken['cards']['reopened_same_round'] = False
        changed = list(args)
        changed[10] = broken
        with self.assertRaisesRegex(ValueError, 'lifecycle'):
            delivery.verify_proofs(*changed, studio_version=2020)

    def test_2019_default_cannot_accept_2020_reports(self):
        with self.assertRaises(ValueError):
            delivery.verify_proofs(*self.proof_fixture())

    def test_2020_still_requires_both_separate_android_platforms(self):
        args = previous.StudioDeliveryTests.dual_platform_fixture(self)
        facts = delivery.verify_android_platforms(*args, studio_version=2020)
        self.assertEqual([item['android_runtime']['sdk'] for item in facts['androidEmulatorAcceptance']], [35, 37])
        path = args[-1] / 'nextgen/native-surfaces-result.json'
        wrong = json.loads(path.read_text())
        wrong['apk_identity']['godot_pck_sha256'] = '9' * 64
        path.write_text(json.dumps(wrong))
        with self.assertRaisesRegex(ValueError, 'PCK'):
            delivery.verify_android_platforms(*args, studio_version=2020)

    def test_2020_receipt_covers_all_previous_modules_and_new_scene(self):
        args = self.review_fixture()
        result = delivery.verify_visual_review(*args, studio_version=2020)
        self.assertEqual(set(result['modules']), delivery.REVIEW_MODULES | {'connect_four'})
        self.assertEqual(set(result['native_acceptance_jobs']), delivery.NATIVE_JOBS)
        self.assertTrue(all(item['path'].startswith('docs/evidence/studio-2020-reviewed/')
                            for item in args[1]['images']))

    def test_each_current_c4_facial_and_treasure_image_is_mandatory(self):
        args = self.review_fixture()
        original = args[1]['images']
        for entry in sorted(delivery.STUDIO_2020_REQUIRED_IMAGES):
            args[1]['images'] = [item for item in original if item['artifact_entry'] != entry]
            with self.subTest(missing=entry), self.assertRaisesRegex(ValueError, 'C4 and facial'):
                delivery.verify_visual_review(*args, studio_version=2020)
        args[1]['images'] = original

    def test_receipt_artifact_and_workflow_cannot_cross_versions(self):
        old = previous.StudioDeliveryTests.review_fixture(self)
        with self.assertRaisesRegex(ValueError, 'another native source or version'):
            delivery.verify_visual_review(*old, studio_version=2020)
        args = self.review_fixture()
        with self.assertRaises(ValueError):
            delivery.verify_visual_review(*args)
        for index, key, value in ((3, 'name', delivery.NATIVE_ARTIFACT),
                                  (4, 'path', delivery.NATIVE_WORKFLOW)):
            original = args[index][key]
            args[index][key] = value
            with self.subTest(index=index), self.assertRaises(ValueError):
                delivery.verify_visual_review(*args, studio_version=2020)
            args[index][key] = original

    def test_treasure_cutout_visibility_cannot_reuse_only_four_title_views(self):
        args = self.review_fixture()
        probe = delivery.TREASURE_TITLE_CAPTURE_PROBE
        cutout = probe + '/treasure-title-landscape-cutout.png'
        args[1]['images'] = [item for item in args[1]['images']
                             if item['artifact_entry'] != cutout]
        retained = {item['artifact_entry'] for item in args[1]['images']
                    if item['artifact_entry'].startswith(probe + '/')}
        self.assertEqual(retained, {
            probe + '/treasure-title-' + name + '.png'
            for name in ('landscape', 'compact', 'portrait', 'fold')})
        with self.assertRaisesRegex(ValueError, 'C4 and facial'):
            delivery.verify_visual_review(*args, studio_version=2020)

    def test_new_capture_cannot_satisfy_the_legacy_review(self):
        entry = delivery.C4_CAPTURE_PROBE + '/c4-win-landscape.png'
        with self.assertRaises(ValueError):
            delivery.capture_module(entry)
        self.assertEqual(delivery.capture_module(entry, studio_version=2020), 'connect_four')
        with self.assertRaises(ValueError):
            delivery.reviewed_file(self.base, 'docs/evidence/studio-2019-reviewed/image.png', studio_version=2020)

    def test_recorder_uses_distinct_current_receipt_without_relabeling_old(self):
        args = self.review_fixture()
        destination = self.base / 'recorded2020'
        result = record_review(destination, args[6], args[3], args[4], args[5],
                               previous.StudioDeliveryTests.selection(args),
                               'Synthetic parser reviewer', 'Synthetic parser fixture only', studio_version=2020)
        self.assertEqual(result['versionCode'], 2020)
        self.assertTrue((destination / delivery.studio_release(2020).review_receipt).is_file())
        self.assertFalse((destination / delivery.REVIEW_RECEIPT).exists())


if __name__ == '__main__':
    unittest.main()
