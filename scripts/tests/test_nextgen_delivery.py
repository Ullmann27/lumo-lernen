"""Reject mixed sources, stale/forged Cards pixels and unreviewed renderer files.

Release records and draw sequences are synthetic parser fixtures, never device
proof. Pixel checks additionally reuse hash-verified original renderer images;
replaying them with synthetic states does not constitute Android acceptance.
"""
from __future__ import annotations

import copy
import hashlib
import json
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
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools/android_qa'))
from nextgen_evidence import require_cards_face_pixels


def fixture_png(width: int, height: int, color: int) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    raw = (b'\0' + bytes((color, 20, 30)) * width) * height
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


class NextgenDeliveryTests(unittest.TestCase):
    def cards_pixel_fixture(self, cards):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        output = Path(temporary.name)
        fixtures = Path(__file__).resolve().parents[2] / 'tools/android_qa/tests/fixtures/cards_faces_2018'
        manifest = json.loads((fixtures / 'manifest.json').read_text())
        case = next(item for item in manifest['cases'] if item['name'] == 'native_412x915')
        raw = (fixtures / case['image']).read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(), case['sha256'])
        observation = json.loads((fixtures / 'observations.json').read_text())[case['name']]
        public = copy.deepcopy(case['public'])
        public.update(roundId=cards['draw']['round_id'], token='a' * 32, viewer=0, current=0,
                      revision=5, ack=1, drawCount=97)
        states = []
        for index, revision in enumerate((5, 7, 7, 9)):
            if index in (1, 3):
                public['hand'].append({'id': f'fixture-drawn-{index}', 'type': 'number',
                                       'number': 4, 'color': 'orange', 'playable': True})
                public['drawCount'] -= 1
                public['ack'] += 1
                public['players'][0]['count'] = len(public['hand'])
            public['revision'] = revision
            states.append(copy.deepcopy(public))
        reports = []
        for stage, state in zip(delivery.CARDS_FACE_STAGES, states):
            frames = []
            for index in range(2):
                path = output / f'{stage}-face-check-{index:02d}.png'
                path.write_bytes(raw)
                pixels = require_cards_face_pixels(path, state, density=case['density'], observations=observation)
                frames.append({'source': path.name, 'source_sha256': case['sha256'],
                               'revision': state['revision'], 'public_before': copy.deepcopy(state),
                               'public_after': copy.deepcopy(state), 'status': 'VISIBLE_FRONT_ARTWORK',
                               'observations': copy.deepcopy(observation), 'pixels': pixels})
            (output / (stage + '.png')).write_bytes(raw)
            reports.append({'stage': stage, 'status': 'PASS', 'consecutive_same_revision_frames': 2,
                            'token': public['token'], 'roundId': public['roundId'], 'viewer': 0,
                            'revision': state['revision'], 'page': '1/3', 'source': stage + '.png',
                            'source_sha256': case['sha256'], 'frames': frames, 'elapsed_seconds': 1,
                            'scope': 'Synthetic parser replay of real renderer pixels; not Android proof'})
        cards['front_face_pixels'] = reports
        self.write_pixel_reports(cards, output)
        return output

    @staticmethod
    def write_pixel_reports(cards, output):
        for report in cards.get('front_face_pixels', []):
            if isinstance(report, dict) and report.get('stage') in delivery.CARDS_FACE_STAGES:
                (output / (report['stage'] + '-face-evidence.json')).write_text(json.dumps(report))

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
        draw = {'cards_conserved': 112, 'child_cards_added': 1, 'owner': 'f' * 64,
                'round_id': 'cards-' + 'a' * 32, 'sequence': 2, 'revision_before': 5,
                'revision_after': 7, 'draw_count_before': 97, 'draw_count_after': 96}
        late_draw = dict(draw, sequence=3, revision_before=7, revision_after=9,
                         draw_count_before=96, draw_count_after=95)
        binding = {'bound': True, 'main_process_pid': 10, 'native_process_pid': 11}
        surfaces = {'status': 'PASS', 'apk_identity': copy.deepcopy(identity), 'fatal_crashes': 0,
                    'learning': {'moves': {'complete': True, 'moved_objects': 5},
                                 'same_lesson_after_return': True, 'illustration_did_not_award_mastery': True},
                    'cards': {'draw': copy.deepcopy(draw), 'draw_after_visible_idle': late_draw,
                              'visible_idle_seconds': 35, 'android_authority_binding': [binding, binding],
                              'pause_saved_state_unchanged': True, 'reopened_same_round': True,
                              'new_mailbox_token': True}}
        surfaces['offline'] = True
        surfaces['local_voice_permission'] = {'local_model_assent': True, 'voice_enabled': True,
            'auto_read': True, 'unrelated_permissions_unchanged': True}
        voice = {'native_process_pid': 11, 'completed_utterance_ids': [4],
                 'profile': 'lumo-free-supertonic-de-v1', 'preset': 'F2',
                 'audible_quality_verified': False, 'lip_sync_verified': False}
        surfaces['learning']['speech'] = {'initial': voice,
            'result': dict(voice, completed_utterance_ids=[16]), 'native_process_gone_on_return': True}
        host = {'status': 'PASS', 'flutter_source_commit': source,
                'classes': {name: [{'sha256': '1' * 64}] for name in delivery.COMPILED_CLASSES}}
        return [source, native, '0.13.6', digest, 12345, proof, copy.deepcopy(proof),
                copy.deepcopy(proof), update, tour, surfaces, host,
                self.cards_pixel_fixture(surfaces['cards'])]

    def test_only_same_source_apk_and_real_surface_proofs_can_form_delivery_facts(self):
        facts = delivery.verify_proofs(*self.proof_fixture())
        self.assertEqual(facts['versionCode'], 2018)
        self.assertEqual(facts['package'], delivery.PACKAGE_ID)
        self.assertIn('not measured', facts['deviceScope'])
        self.assertEqual(len(facts['cardsFrontFacePixels']['stages']), 4)
        self.assertTrue(all(len(stage['frames']) == 2 for stage in facts['cardsFrontFacePixels']['stages']))

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
                         'different-child', 'host-old-source', 'service-not-compiled', 'registry-not-compiled',
                         'no-voice-consent', 'speech-incomplete', 'old-speech-id', 'different-speaker', 'false-audible-claim'):
            args = self.proof_fixture()
            update, tour, surfaces, host = args[8:12]
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
            if mutation == 'no-voice-consent': surfaces['local_voice_permission']['local_model_assent'] = False
            if mutation == 'speech-incomplete': surfaces['learning']['speech']['result']['completed_utterance_ids'] = []
            if mutation == 'old-speech-id': surfaces['learning']['speech']['result']['completed_utterance_ids'] = [4]
            if mutation == 'different-speaker': surfaces['learning']['speech']['result']['profile'] = 'other-voice'
            if mutation == 'false-audible-claim': surfaces['learning']['speech']['initial']['audible_quality_verified'] = True
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def test_missing_failed_stale_or_mutated_cards_reports_cannot_publish(self):
        for mutation in ('missing', 'three-stages', 'failed', 'reordered', 'wrong-round', 'wrong-token',
                         'stale-revision', 'different-viewer', 'one-frame', 'last-rejected', 'duplicate-frame',
                         'changed-during-ocr', 'changed-between-frames', 'wrong-public-round', 'stale-public-revision',
                         'different-page', 'forged-metrics', 'forged-source-hash', 'different-ui-source',
                         'missing-disk-report', 'different-disk-report', 'missing-original', 'symlink-original',
                         'outside-original', 'changed-main-image', 'different-draw-count', 'old-ack'):
            args = self.proof_fixture()
            cards, output = args[10]['cards'], args[12]
            reports = cards['front_face_pixels']
            report, frame = reports[0], reports[0]['frames'][-1]
            if mutation == 'missing': del cards['front_face_pixels']
            if mutation == 'three-stages': reports.pop()
            if mutation == 'failed': report['status'] = 'FAIL'
            if mutation == 'reordered': reports.reverse()
            if mutation == 'wrong-round': report['roundId'] = 'cards-' + 'b' * 32
            if mutation == 'wrong-token': reports[1]['token'] = 'b' * 32
            if mutation == 'stale-revision': report['revision'] = 4
            if mutation == 'different-viewer': report['viewer'] = 1
            if mutation == 'one-frame': report['frames'].pop(0)
            if mutation == 'last-rejected': frame['status'] = 'REJECTED'
            if mutation == 'duplicate-frame': report['frames'][-1] = copy.deepcopy(report['frames'][0])
            if mutation == 'changed-during-ocr': frame['public_before']['drawCount'] -= 1
            if mutation == 'changed-between-frames':
                frame['public_before']['message'] = frame['public_after']['message'] = 'different observed turn'
            if mutation == 'wrong-public-round':
                frame['public_before']['roundId'] = frame['public_after']['roundId'] = 'cards-' + 'b' * 32
            if mutation == 'stale-public-revision':
                frame['public_before']['revision'] = frame['public_after']['revision'] = 4
            if mutation == 'different-page': report['page'] = '2/3'
            if mutation == 'forged-metrics': frame['pixels']['faces'][0]['colored_fraction'] = 1
            if mutation == 'forged-source-hash': frame['source_sha256'] = '0' * 64
            if mutation == 'different-ui-source': frame['observations']['source_sha256'] = '0' * 64
            if mutation == 'outside-original': frame['source'] = '../other.png'
            if mutation == 'different-draw-count': cards['draw']['draw_count_before'] = 96
            if mutation == 'old-ack': cards['draw']['sequence'] = 1
            self.write_pixel_reports(cards, output)
            if mutation == 'missing-disk-report': (output / (report['stage'] + '-face-evidence.json')).unlink()
            if mutation == 'different-disk-report':
                (output / (report['stage'] + '-face-evidence.json')).write_text('{}')
            if mutation == 'missing-original': (output / frame['source']).unlink()
            if mutation == 'symlink-original':
                (output / frame['source']).unlink()
                (output / frame['source']).symlink_to(output / report['source'])
            if mutation == 'changed-main-image':
                with (output / report['source']).open('ab') as stream: stream.write(b'changed')
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                delivery.verify_proofs(*args)

    def test_blank_fronts_with_forged_pass_metrics_fail_actual_png_recomputation(self):
        from PIL import Image, ImageDraw
        args = self.proof_fixture()
        cards, output = args[10]['cards'], args[12]
        report = cards['front_face_pixels'][0]
        frame = report['frames'][-1]
        image = Image.open(output / frame['source']).convert('RGB')
        quad = frame['pixels']['faces'][0]['quad']
        ImageDraw.Draw(image).polygon([tuple(point) for point in quad], fill='white')
        path = output / frame['source']
        image.save(path)
        changed_hash = hashlib.sha256(path.read_bytes()).hexdigest()
        # A forged writer updates every SHA/PASS field but leaves plausible
        # old positive metrics. Actual PNG remeasurement must still reject it.
        frame['source_sha256'] = frame['observations']['source_sha256'] = changed_hash
        frame['pixels']['source_sha256'] = report['source_sha256'] = changed_hash
        (output / report['source']).write_bytes(path.read_bytes())
        self.write_pixel_reports(cards, output)
        with self.assertRaisesRegex(ValueError, 'blank or lacks visible artwork'):
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
            self.assertEqual(result['images'], 8)
            self.assertEqual(set(result['modules']),
                             {'learning', 'jump', 'build', 'settlement', 'garage', 'cards', 'rhythm', 'puzzle'})
            path = args[0] / args[1]['images'][0]['path']
            path.write_bytes(path.read_bytes() + b'changed')
            with self.assertRaisesRegex(ValueError, 'bytes changed'):
                delivery.verify_visual_review(*args)

    def test_pending_old_partial_or_failed_visual_review_never_approves_release(self):
        with tempfile.TemporaryDirectory() as directory:
            original = self.review_fixture(Path(directory))
            for mutation in ('pending', 'old-native', 'artifact-source', 'artifact-digest', 'expired',
                             'run-failed', 'missing-full-gate', 'missing-module', 'missing-puzzle',
                             'outside-path', 'bad-dimensions'):
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
                if mutation == 'missing-puzzle':
                    receipt['images'] = [item for item in receipt['images'] if item['module'] != 'puzzle']
                    self.assertEqual(len(receipt['images']), 7)
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
                    entry = ('nextgen-evidence/nextgen/captures/puzzle_rotation_regression/puzzle_rotation_table.png'
                             if item['module'] == 'puzzle' else
                             'nextgen-evidence/nextgen/captures/' + item['module'] + '/actual.png')
                    zipped.writestr(entry, (fixture_root / item['path']).read_bytes())
                    selection.append({'module': item['module'], 'artifact_entry': entry,
                                      'findings': 'Synthetic unit-test fixture only'})
            artifact['digest'] = 'sha256:' + hashlib.sha256(archive.read_bytes()).hexdigest()
            root = base / 'recorded'
            output = record_review(root, archive, artifact, run, jobs, selection,
                                   'Synthetic unit-test reviewer', 'Synthetic fixture, not visual approval')
            self.assertEqual(len(output['images']), 8)
            puzzle = next(item for item in output['images'] if item['module'] == 'puzzle')
            self.assertEqual(puzzle['artifact_entry'],
                             'nextgen-evidence/nextgen/captures/puzzle_rotation_regression/puzzle_rotation_table.png')
            self.assertTrue(puzzle['path'].endswith('-puzzle_rotation_table.png'))
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
