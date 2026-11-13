"""Reject mixed-source publication, old APK proof and unreviewed renderer files.

All JSON and PNG data here are explicitly synthetic parser fixtures. None is
stored as an application screenshot, device result or publication receipt.
"""
from __future__ import annotations

import copy
import hashlib
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zlib
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_nextgen_delivery as delivery
from record_nextgen_visual_review import record_review


def fixture_png(width: int, height: int, color: int) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    raw = (b'\0' + bytes((color, 20, 30)) * width) * height
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


class NextgenDeliveryTests(unittest.TestCase):
    def proof_fixture(self):
        source, native, digest, pck = 'a' * 40, 'b' * 40, 'c' * 64, 'd' * 64
        proof = {'flutter_source_commit': source, 'tracked_source_clean': True,
                 'versionName': '0.13.6', 'versionCode': 2018, 'package': delivery.PACKAGE_ID,
                 'signingCertificateSha256': delivery.EXPECTED_CERT_SHA256,
                 'abis': ['arm64-v8a'], 'sha256': digest, 'bytes': 12345,
                 'godot': {'revision': native, 'pck_sha256': pck}}
        candidate = copy.deepcopy(proof)
        candidate.update(abis=['x86_64'], sha256='e' * 64)
        update = {'status': 'PASS', 'candidate_source': source,
                  'baseline': {'versionCode': 2017, 'flutter_source_commit': delivery.BASELINE_SOURCE,
                               'godot': {'revision': delivery.BASELINE_NATIVE}},
                  'candidate': candidate, 'offline': True, 'fatal_crashes': 0}
        identity = {'step': 'apk-identity', 'ok': True, 'flutter_source_commit': source,
                    'godot_revision': native, 'godot_pck_sha256': pck, 'versionName': '0.13.6',
                    'versionCode': 2018, 'signingCertificateSha256': delivery.EXPECTED_CERT_SHA256,
                    'apk_sha256': candidate['sha256']}
        tour = {'status': 'PASS', 'apk_sha256': candidate['sha256'], 'fatal_crashes': 0,
                'steps': [identity, {'step': 'start-kart-race', 'ok': True,
                                    'spatial_menu_navigation': {'status': 'PASS', 'selected_mode': 'cup',
                                        'sections': [{'section': 'garage'}, {'section': 'driver'}]}}]}
        draw = {'cards_conserved': 112, 'child_cards_added': 1, 'owner': 'f' * 64, 'round_id': 'cards-' + 'a' * 32}
        binding = {'bound': True, 'main_process_pid': 10, 'native_process_pid': 11}
        surfaces = {'status': 'PASS', 'apk_identity': copy.deepcopy(identity), 'fatal_crashes': 0,
                    'learning': {'moves': {'complete': True, 'moved_objects': 5},
                                 'same_lesson_after_return': True, 'illustration_did_not_award_mastery': True},
                    'cards': {'draw': copy.deepcopy(draw), 'draw_after_visible_idle': copy.deepcopy(draw),
                              'visible_idle_seconds': 35, 'android_authority_binding': [binding, binding],
                              'pause_saved_state_unchanged': True, 'reopened_same_round': True,
                              'new_mailbox_token': True}}
        host = {'status': 'PASS', 'flutter_source_commit': source,
                'classes': {name: [{'sha256': '1' * 64}] for name in delivery.COMPILED_CLASSES}}
        return [source, native, '0.13.6', digest, 12345, proof, copy.deepcopy(proof),
                copy.deepcopy(proof), update, tour, surfaces, host]

    def test_only_same_source_apk_and_real_surface_proofs_can_form_delivery_facts(self):
        facts = delivery.verify_proofs(*self.proof_fixture())
        self.assertEqual(facts['versionCode'], 2018)
        self.assertEqual(facts['package'], delivery.PACKAGE_ID)
        self.assertIn('not measured', facts['deviceScope'])

    def test_old_certificate_changed_bytes_or_native_source_fail_closed(self):
        for position, field, value in ((5, 'tracked_source_clean', False), (5, 'flutter_source_commit', '0' * 40),
                                      (6, 'signingCertificateSha256', '0' * 64), (7, 'sha256', '0' * 64),
                                      (7, 'bytes', 12344), (6, 'abis', ['x86_64']), (7, 'versionCode', 2017)):
            args = self.proof_fixture()
            args[position][field] = value
            with self.subTest(position=position, field=field), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)
        args = self.proof_fixture()
        args[8]['candidate']['godot']['pck_sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'PCK differs'):
            delivery.verify_proofs(*args)

    def test_old_tour_unbound_authority_and_missing_lifecycle_proof_fail(self):
        for mutation in ('old-tour', 'wrong-baseline', 'surface-failed', 'mastery-awarded',
                         'old-surface-source', 'draw-not-persisted', 'short-idle', 'authority-restart',
                         'different-child', 'host-old-source', 'service-not-compiled', 'registry-not-compiled'):
            args = self.proof_fixture()
            update, tour, surfaces, host = args[8:]
            if mutation == 'old-tour': tour['apk_sha256'] = '0' * 64
            if mutation == 'wrong-baseline': update['baseline']['versionCode'] = 2015
            if mutation == 'surface-failed': surfaces['status'] = 'FAIL'
            if mutation == 'mastery-awarded': surfaces['learning']['illustration_did_not_award_mastery'] = False
            if mutation == 'old-surface-source': surfaces['apk_identity']['flutter_source_commit'] = '0' * 40
            if mutation == 'draw-not-persisted': surfaces['cards']['draw_after_visible_idle']['cards_conserved'] = 111
            if mutation == 'short-idle': surfaces['cards']['visible_idle_seconds'] = 1
            if mutation == 'authority-restart': surfaces['cards']['android_authority_binding'][1] = {'bound': False}
            if mutation == 'different-child': surfaces['cards']['draw_after_visible_idle']['owner'] = '0' * 64
            if mutation == 'host-old-source': host['flutter_source_commit'] = '0' * 40
            if mutation == 'service-not-compiled': del host['classes']['CardsAuthorityService']
            if mutation == 'registry-not-compiled': del host['classes']['CardsAuthorityRegistry']
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def review_fixture(self, root: Path):
        native = 'b' * 40
        receipt = {'schema': 1, 'status': 'approved', 'versionCode': 2018, 'native_revision': native,
                   'native_workflow_run_id': 100, 'native_artifact_id': 200,
                   'native_artifact_sha256': 'e' * 64, 'reviewed_by': 'unit test fixture only',
                   'reviewed_at': '2026-11-13T00:00:00+00:00', 'notes': 'Synthetic unit-test fixture', 'images': []}
        for index, module in enumerate(sorted(delivery.REVIEW_MODULES)):
            dimensions = (320, 600) if index == 0 else (640, 360)
            relative = 'docs/evidence/nextgen-2018-reviewed/' + module + '.png'
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            data = fixture_png(*dimensions, index + 10)
            path.write_bytes(data)
            receipt['images'].append({'path': relative, 'dimensions': list(dimensions), 'module': module,
                                      'sha256': hashlib.sha256(data).hexdigest(),
                                      'artifact_entry': 'fixture/' + module + '.png',
                                      'findings': 'Synthetic parser fixture, not actual renderer proof'})
        artifact = {'id': 200, 'name': 'lumo-nextgen-2018-native-evidence', 'expired': False,
                    'digest': 'sha256:' + 'e' * 64, 'workflow_run': {'id': 100, 'head_sha': native}}
        run = {'id': 100, 'head_sha': native, 'status': 'completed', 'conclusion': 'success'}
        jobs = {'jobs': [{'name': name, 'run_id': 100, 'status': 'completed', 'conclusion': 'success'}
                         for name in ('gameplay', 'new-worlds')]}
        return [root, receipt, native, artifact, run, jobs]

    def test_visual_receipt_checks_actual_files_and_complete_module_coverage(self):
        with tempfile.TemporaryDirectory() as directory:
            args = self.review_fixture(Path(directory))
            result = delivery.verify_visual_review(*args)
            self.assertEqual(result['images'], 7)
            self.assertEqual(set(result['modules']), delivery.REVIEW_MODULES)
            path = args[0] / args[1]['images'][0]['path']
            path.write_bytes(path.read_bytes() + b'changed')
            with self.assertRaisesRegex(ValueError, 'bytes changed'):
                delivery.verify_visual_review(*args)

    def test_pending_old_partial_or_failed_visual_review_never_approves_release(self):
        with tempfile.TemporaryDirectory() as directory:
            original = self.review_fixture(Path(directory))
            for mutation in ('pending', 'old-native', 'artifact-source', 'artifact-digest', 'expired',
                             'run-failed', 'missing-full-gate', 'missing-module', 'outside-path', 'bad-dimensions'):
                args = copy.deepcopy(original)
                _, receipt, _, artifact, run, jobs = args
                if mutation == 'pending': receipt['status'] = 'pending'
                if mutation == 'old-native': receipt['native_revision'] = '0' * 40
                if mutation == 'artifact-source': artifact['workflow_run']['head_sha'] = '0' * 40
                if mutation == 'artifact-digest': artifact['digest'] = 'sha256:' + '0' * 64
                if mutation == 'expired': artifact['expired'] = True
                if mutation == 'run-failed': run['conclusion'] = 'failure'
                if mutation == 'missing-full-gate': jobs['jobs'].pop()
                if mutation == 'missing-module': receipt['images'].pop()
                if mutation == 'outside-path': receipt['images'][0]['path'] = '../outside.png'
                if mutation == 'bad-dimensions': receipt['images'][0]['dimensions'] = [1, 1]
                with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                    delivery.verify_visual_review(*args)

    def test_recording_copies_only_exact_members_of_the_verified_original_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            args = self.review_fixture(base / 'fixtures')
            fixture_root, receipt, native, artifact, run, jobs = args
            archive = base / 'native-fixture.zip'
            selection = []
            with zipfile.ZipFile(archive, 'w') as zipped:
                zipped.writestr('nextgen-evidence/nextgen/source-sha.txt', native + '\n')
                zipped.writestr('nextgen-evidence/nextgen/source-dirty.txt', '')
                for item in receipt['images']:
                    entry = 'nextgen-evidence/nextgen/captures/' + item['module'] + '/actual.png'
                    zipped.writestr(entry, (fixture_root / item['path']).read_bytes())
                    selection.append({'module': item['module'], 'artifact_entry': entry,
                                      'findings': 'Synthetic unit-test fixture only'})
            artifact['digest'] = 'sha256:' + hashlib.sha256(archive.read_bytes()).hexdigest()
            root = base / 'recorded'
            output = record_review(root, archive, artifact, run, jobs, selection,
                                   'Synthetic unit-test reviewer', 'Synthetic fixture, not visual approval')
            self.assertEqual(len(output['images']), 7)
            self.assertTrue((root / 'config/nextgen-2018-visual-review.json').is_file())
            for item in output['images']:
                self.assertEqual(hashlib.sha256((root / item['path']).read_bytes()).hexdigest(), item['sha256'])
            archive.write_bytes(archive.read_bytes() + b'changed')
            with self.assertRaisesRegex(ValueError, 'archive digest differs'):
                record_review(base / 'rejected', archive, artifact, run, jobs, selection,
                              'Fixture', 'Fixture')
            self.assertFalse((base / 'rejected/config/nextgen-2018-visual-review.json').exists())


if __name__ == '__main__':
    unittest.main()
