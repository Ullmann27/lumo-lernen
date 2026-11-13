"""Synthetic transferred-evidence parser cases; none are visual or Android approval."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_kart_graphics_review as review
from test_nextgen_delivery import fixture_png


class KartGraphicsReviewTests(unittest.TestCase):
    def fixture(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        proofs = root / 'proofs/native-graphics'
        proofs.mkdir(parents=True)
        original_metadata = root.joinpath(*review.PROOF_DIRECTORY, 'metadata')
        original_metadata.mkdir(parents=True)
        native, run_id = 'b' * 40, 100
        receipt = {
            'schema': 1, 'status': 'approved', 'versionCode': 2019,
            'native_revision': native, 'native_workflow_run_id': run_id,
            'reviewed_by': 'Synthetic parser fixture only',
            'reviewed_at': '2026-11-13T00:00:00+00:00',
            'notes': 'Synthetic unit test input; not actual image approval',
            'artifacts': [], 'images': [],
        }
        run = {'id': run_id, 'head_sha': native, 'path': review.WORKFLOW_PATH,
               'name': review.WORKFLOW_NAME, 'repository': {'full_name': review.NATIVE_REPOSITORY},
               'status': 'completed', 'conclusion': 'success'}
        self.write_json(proofs / 'run.json', run)
        self.write_json(proofs / 'jobs.json', {'total_count': 3, 'jobs': [
            {'id': 300 + index, 'name': 'Actual ' + key + ' scene and interaction', 'run_id': run_id,
             'status': 'completed', 'conclusion': 'success'}
            for index, key in enumerate(review.ARTIFACT_NAMES)
        ]})
        receipt['workflow_metadata_sha256'] = {}
        for name in review.WORKFLOW_FILES:
            data = (proofs / name).read_bytes()
            (original_metadata / name).write_bytes(data)
            receipt['workflow_metadata_sha256'][name] = hashlib.sha256(data).hexdigest()
        color = 30
        for index, (key, name) in enumerate(review.ARTIFACT_NAMES.items()):
            artifact_id = 200 + index
            areas = ['winter_sprint', 'crystal_canyon'] if key == 'worlds' else [key]
            entries = {
                'source-sha.txt': (native + '\n').encode(),
                'source-tree.txt': ('c' * 40 + '\n').encode(),
                'source-dirty.txt': b'',
                'engine.txt': b'4.6.3.stable.fixture\n',
            }
            for filename, marker in review.REQUIRED_LOGS[key].items():
                entries[filename] = ('OpenGL API fixture, not a real renderer\n' + marker + '\n').encode()
                if filename == 'winter-visibility.log':
                    entries[filename] += b'[KartWorldExpansionCapture] PASS track=winter_sprint views=0\n'
            manifest = []
            for area in areas:
                orientations = [(640, 360), (360, 640)] if key == 'home' else [(640, 360)]
                for shot, dimensions in enumerate(orientations):
                    color += 1
                    original = f'images/{area}/fixture-{shot}.png'
                    relative = f'docs/evidence/kart-graphics-2019-reviewed/{area}/fixture-{shot}.png'
                    data = fixture_png(*dimensions, color)
                    digest = hashlib.sha256(data).hexdigest()
                    entries[original] = data
                    path = root / relative
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(data)
                    manifest.append({'file': original, 'bytes': len(data), 'sha256': digest})
                    receipt['images'].append({
                        'path': relative, 'area': area, 'artifact_id': artifact_id, 'native_revision': native,
                        'artifact_entry': original, 'sha256': digest, 'dimensions': list(dimensions),
                        'findings': 'Synthetic parser fixture, not actual visual findings',
                    })
            entries['image-manifest.json'] = json.dumps(manifest).encode()
            archive = proofs / (key + '.zip')
            with zipfile.ZipFile(archive, 'w') as zipped:
                for filename, data in entries.items():
                    zipped.writestr(filename, data)
            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            artifact = {
                'id': artifact_id, 'name': name, 'expired': False, 'digest': 'sha256:' + digest,
                'workflow_run': {'id': run_id, 'head_sha': native},
            }
            self.write_json(proofs / (key + '-artifact.json'), artifact)
            entries['artifact.json'] = (proofs / (key + '-artifact.json')).read_bytes()
            metadata_hashes = {}
            (original_metadata / key).mkdir()
            for filename in (*review.SOURCE_FILES, *review.REQUIRED_LOGS[key]):
                data = entries[filename]
                (original_metadata / key / filename).write_bytes(data)
                metadata_hashes[filename] = hashlib.sha256(data).hexdigest()
            receipt['artifacts'].append({'area': key, 'id': artifact_id, 'name': name,
                                         'sha256': digest, 'metadata_sha256': metadata_hashes})
        return [root, receipt, native, proofs]

    @staticmethod
    def write_json(path, value):
        path.write_text(json.dumps(value))

    def mutate_json(self, path, mutation):
        data = json.loads(path.read_text())
        mutation(data)
        self.write_json(path, data)

    def rewrite_metadata(self, args, key, change):
        root, receipt, _, _ = args
        directory = root.joinpath(*review.PROOF_DIRECTORY, 'metadata', key)
        artifact = next(item for item in receipt['artifacts'] if item['area'] == key)
        entries = {name: (directory / name).read_bytes() for name in artifact['metadata_sha256']}
        change(entries)
        for name, data in entries.items():
            (directory / name).write_bytes(data)
            artifact['metadata_sha256'][name] = hashlib.sha256(data).hexdigest()

    def test_all_three_transferred_artifacts_and_four_reviewed_areas_are_bound(self):
        result = review.verify_visual_review(*self.fixture())
        self.assertEqual(result['areas'], sorted(review.REVIEW_AREAS))
        self.assertEqual(len(result['artifacts']), 3)
        self.assertEqual(len(result['images']), 5)
        self.assertEqual(result['native_source_tree'], 'c' * 40)

    def test_pending_old_partial_or_undated_receipts_fail(self):
        for mutation in ('pending', '2018', 'old-source', 'missing-artifact',
                         'duplicate-artifact', 'naive-date', 'missing-findings', 'missing-area',
                         'missing-portrait'):
            args = self.fixture()
            receipt = args[1]
            if mutation == 'pending':
                receipt['status'] = 'pending'
            if mutation == '2018':
                receipt['versionCode'] = 2018
            if mutation == 'old-source':
                receipt['native_revision'] = 'a' * 40
            if mutation == 'missing-artifact':
                receipt['artifacts'].pop()
            if mutation == 'duplicate-artifact':
                receipt['artifacts'][2] = copy.deepcopy(receipt['artifacts'][0])
            if mutation == 'naive-date':
                receipt['reviewed_at'] = '2026-11-13T00:00:00'
            if mutation == 'missing-findings':
                receipt['images'][0]['findings'] = ''
            if mutation == 'missing-area':
                receipt['images'] = [item for item in receipt['images'] if item['area'] != 'winter_sprint']
            if mutation == 'missing-portrait':
                receipt['images'] = [item for item in receipt['images']
                                     if item['dimensions'][0] > item['dimensions'][1]]
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                review.verify_visual_review(*args)

    def test_wrong_workflow_failed_or_missing_jobs_and_mixed_run_ids_fail(self):
        for mutation in ('foreign-workflow', 'foreign-repository', 'failed-run', 'old-run-source',
                         'failed-job', 'missing-job', 'job-other-run', 'wrong-job-name'):
            args = self.fixture()
            proofs = args[3]
            if mutation == 'foreign-workflow':
                self.mutate_json(proofs / 'run.json', lambda row: row.update(path='other.yml'))
            if mutation == 'foreign-repository':
                self.mutate_json(proofs / 'run.json', lambda row: row.update(repository={'full_name': 'other/repo'}))
            if mutation == 'failed-run':
                self.mutate_json(proofs / 'run.json', lambda row: row.update(conclusion='failure'))
            if mutation == 'old-run-source':
                self.mutate_json(proofs / 'run.json', lambda row: row.update(head_sha='a' * 40))
            if mutation == 'failed-job':
                self.mutate_json(proofs / 'jobs.json', lambda row: row['jobs'][0].update(conclusion='failure'))
            if mutation == 'missing-job':
                self.mutate_json(proofs / 'jobs.json', lambda row: row['jobs'].pop())
            if mutation == 'job-other-run':
                self.mutate_json(proofs / 'jobs.json', lambda row: row['jobs'][0].update(run_id=99))
            if mutation == 'wrong-job-name':
                self.mutate_json(proofs / 'jobs.json', lambda row: row['jobs'][0].update(name='gameplay'))
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                review.verify_visual_review(*args)

    def test_old_expired_or_changed_archive_metadata_and_original_bytes_fail(self):
        for mutation in ('2018-name', 'expired', 'old-source', 'old-run', 'digest', 'changed-original'):
            args = self.fixture()
            proofs = args[3]
            metadata = proofs / 'feedback-artifact.json'
            if mutation == '2018-name':
                self.mutate_json(metadata, lambda row: row.update(name='lumo-nextgen-2018-native-evidence'))
            if mutation == 'expired':
                self.mutate_json(metadata, lambda row: row.update(expired=True))
            if mutation == 'old-source':
                self.mutate_json(metadata, lambda row: row['workflow_run'].update(head_sha='a' * 40))
            if mutation == 'old-run':
                self.mutate_json(metadata, lambda row: row['workflow_run'].update(id=99))
            if mutation == 'digest':
                self.mutate_json(metadata, lambda row: row.update(digest='sha256:' + '0' * 64))
            if mutation == 'changed-original':
                original = args[0].joinpath(*review.PROOF_DIRECTORY, 'metadata/feedback/source-sha.txt')
                original.write_bytes(original.read_bytes() + b'changed')
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                review.verify_visual_review(*args)

    def test_preserved_source_dirty_tree_engine_and_late_renderer_errors_fail(self):
        for filename, data in (
            ('source-sha.txt', b'old-source'),
            ('source-dirty.txt', b' M scripts/games/kart_island.gd\n'),
            ('source-tree.txt', b'd' * 40),
            ('engine.txt', b'4.7.stable'),
            ('regression.log', b'OpenGL API fixture\n[KartDriveFeedback] LOGIC_PASS\n'),
            ('regression.log', b'[KartDriveFeedback] PASS\n'),
            ('render.log', b'OpenGL API fixture\n[KartDriveFeedbackCapture] PASS\nERROR: late error\n'),
            ('render.log', b'OpenGL API fixture\n[KartDriveFeedbackCapture] PASS\nWARNING: ObjectDB instances leaked at exit\n'),
        ):
            args = self.fixture()
            self.rewrite_metadata(args, 'feedback', lambda entries: entries.update({filename: data}))
            with self.subTest(filename=filename, data=data), self.assertRaises(ValueError):
                review.verify_visual_review(*args)

    def test_camera_visibility_without_completed_scene_teardown_fails(self):
        args = self.fixture()
        self.rewrite_metadata(args, 'worlds', lambda entries: entries.update({
            'winter-visibility.log': b'[KartWinterVisibility] PASS checks=49\n',
        }))
        with self.assertRaisesRegex(ValueError, 'scene/audio teardown'):
            review.verify_visual_review(*args)

    def test_baseline_outside_missing_changed_and_manifest_mismatched_images_fail(self):
        for mutation in ('baseline', 'outside', 'missing', 'changed', 'manifest', 'dimensions',
                         'wrong-artifact', 'duplicate-image'):
            args = self.fixture()
            root, receipt, _, _ = args
            item = receipt['images'][0]
            if mutation == 'baseline':
                item['artifact_entry'] = 'baseline/' + item['artifact_entry']
            if mutation == 'outside':
                item['path'] = '../outside.png'
            if mutation == 'missing':
                (root / item['path']).unlink()
            if mutation == 'changed':
                with (root / item['path']).open('ab') as stream:
                    stream.write(b'changed')
            if mutation == 'manifest':
                self.rewrite_metadata(args, 'home', lambda rows: rows.update({
                    'image-manifest.json': json.dumps([{'file': item['artifact_entry'],
                                                       'sha256': '0' * 64, 'bytes': 123}]).encode()}))
            if mutation == 'dimensions':
                item['dimensions'] = [1000, 1000]
            if mutation == 'wrong-artifact':
                item['artifact_id'] = receipt['artifacts'][-1]['id']
            if mutation == 'duplicate-image':
                receipt['images'].append(copy.deepcopy(item))
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                review.verify_visual_review(*args)


if __name__ == '__main__':
    unittest.main()
