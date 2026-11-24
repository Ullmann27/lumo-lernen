"""Immutable review recovery; every PNG and CI record here is synthetic.

These fixtures test evidence storage, not the app, renderer, or Android.
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
import zipfile
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from record_nextgen_visual_review import record_review
from verify_nextgen_delivery import REVIEW_MODULES, verify_visual_review


def fixture_png(width: int, height: int, color: int) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return (struct.pack('>I', len(data)) + kind + data +
                struct.pack('>I', zlib.crc32(kind + data)))
    raw = (b'\0' + bytes((color, 20, 30)) * width) * height
    return (b'\x89PNG\r\n\x1a\n' +
            chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


class NextgenReviewRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.root = self.base / 'checkout'
        self.archive_number = 0

    def bundle(self, native='a' * 40, changed_module=None):
        self.archive_number += 1
        run_id = 100 + self.archive_number
        artifact_id = 200 + self.archive_number
        archive = self.base / ('synthetic-' + str(run_id) + '.zip')
        selection = []
        with zipfile.ZipFile(archive, 'w') as zipped:
            zipped.writestr('nextgen-evidence/nextgen/source-sha.txt', native + '\n')
            zipped.writestr('nextgen-evidence/nextgen/source-dirty.txt', '')
            for index, module in enumerate(sorted(REVIEW_MODULES)):
                color = index + (100 if module == changed_module else 10)
                dimensions = (320, 600) if index == 0 else (640, 360)
                entry = ('nextgen-evidence/nextgen/captures/puzzle_rotation_regression/puzzle_rotation_table.png'
                         if module == 'puzzle' else
                         'nextgen-evidence/nextgen/captures/' + module + '/scene.png')
                zipped.writestr(entry, fixture_png(*dimensions, color))
                selection.append({'module': module, 'artifact_entry': entry,
                                  'findings': 'Synthetic storage regression, not visual approval'})
        artifact = {'id': artifact_id, 'name': 'lumo-nextgen-2018-native-evidence',
                    'expired': False, 'digest': 'sha256:' + self.digest(archive),
                    'workflow_run': {'id': run_id, 'head_sha': native}}
        workflow = {'id': run_id, 'head_sha': native,
                    'status': 'completed', 'conclusion': 'success'}
        jobs = {'jobs': [{'name': name, 'run_id': run_id,
                         'status': 'completed', 'conclusion': 'success'}
                        for name in ('gameplay', 'new-worlds')]}
        return [archive, artifact, workflow, jobs, selection]

    @staticmethod
    def digest(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def record(self, bundle):
        return record_review(self.root, *bundle, 'Synthetic test reviewer',
                             'Unit-test fixture only; no visual or release approval')

    def snapshot(self):
        if not self.root.exists():
            return {}
        return {str(p.relative_to(self.root)): p.read_bytes()
                for p in self.root.rglob('*') if p.is_file()}

    def assert_images_preserved(self, receipt):
        for image in receipt['images']:
            self.assertEqual(self.digest(self.root / image['path']), image['sha256'])

    def test_same_archive_is_idempotent(self):
        bundle = self.bundle()
        first = self.record(bundle)
        second = self.record(bundle)
        self.assertEqual(first['images'], second['images'])
        self.assert_images_preserved(first)

    def test_new_native_review_preserves_previous_originals(self):
        first = self.record(self.bundle())
        bundle = self.bundle(native='b' * 40, changed_module='cards')
        second = self.record(bundle)
        self.assert_images_preserved(first)
        self.assert_images_preserved(second)
        previous = {x['module']: x for x in first['images']}
        current = {x['module']: x for x in second['images']}
        self.assertNotEqual(previous['cards']['path'], current['cards']['path'])
        for module in REVIEW_MODULES - {'cards'}:
            self.assertEqual(previous[module]['path'], current[module]['path'])
        self.assertEqual(second['native_revision'], 'b' * 40)
        verify_visual_review(self.root, second, 'b' * 40, *bundle[1:4])

    def test_selection_order_does_not_rename_or_overwrite_images(self):
        bundle = self.bundle()
        first = self.record(bundle)
        bundle[-1] = list(reversed(bundle[-1]))
        second = self.record(bundle)
        self.assertEqual({x['module']: x['path'] for x in first['images']},
                         {x['module']: x['path'] for x in second['images']})
        self.assert_images_preserved(first)

    def test_repeated_capture_at_same_source_preserves_changed_pixels(self):
        first = self.record(self.bundle())
        second = self.record(self.bundle(changed_module='cards'))
        self.assertNotEqual(first['native_artifact_id'], second['native_artifact_id'])
        self.assertEqual(first['native_revision'], second['native_revision'])
        self.assert_images_preserved(first)
        self.assert_images_preserved(second)

    def test_existing_ordinal_named_evidence_is_never_replaced(self):
        bundle = self.bundle()
        legacy = {}
        for index, choice in enumerate(bundle[-1]):
            path = self.root / ('docs/evidence/nextgen-2018-reviewed/' +
                               f'{index + 1:02d}-{choice["module"]}-scene.png')
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(fixture_png(640, 360, index + 150))
            legacy[path] = path.read_bytes()
        receipt = self.record(bundle)
        for path, data in legacy.items():
            self.assertEqual(path.read_bytes(), data)
        self.assert_images_preserved(receipt)

    def test_tampered_existing_target_fails_without_replacing_receipt(self):
        bundle = self.bundle()
        first = self.record(bundle)
        path = self.root / first['images'][0]['path']
        path.write_bytes(path.read_bytes() + b'tampered')
        before = self.snapshot()
        with self.assertRaisesRegex(ValueError, 'different reviewed image'):
            self.record(bundle)
        self.assertEqual(before, self.snapshot())

    def test_failed_or_wrong_source_archive_keeps_previous_review_intact(self):
        self.record(self.bundle())
        for mutation in ('failed-run', 'wrong-source', 'expired', 'wrong-digest', 'dirty'):
            bundle = self.bundle(native='b' * 40, changed_module='cards')
            archive, artifact, workflow, _, _ = bundle
            if mutation == 'failed-run':
                workflow['conclusion'] = 'failure'
            elif mutation == 'wrong-source':
                artifact['workflow_run']['head_sha'] = 'c' * 40
            elif mutation == 'expired':
                artifact['expired'] = True
            elif mutation == 'wrong-digest':
                artifact['digest'] = 'sha256:' + '0' * 64
            else:
                with zipfile.ZipFile(archive) as zipped:
                    members = {n: zipped.read(n) for n in zipped.namelist()}
                members['nextgen-evidence/nextgen/source-dirty.txt'] = b'M scene.gd\n'
                with zipfile.ZipFile(archive, 'w') as zipped:
                    for name, data in members.items():
                        zipped.writestr(name, data)
                artifact['digest'] = 'sha256:' + self.digest(archive)
            before = self.snapshot()
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.record(bundle)
            self.assertEqual(before, self.snapshot())

    def test_incomplete_module_set_does_not_write_partial_evidence(self):
        self.record(self.bundle())
        for missing_module in ('settlement', 'puzzle'):
            bundle = self.bundle(native='b' * 40, changed_module='cards')
            bundle[-1] = [item for item in bundle[-1] if item['module'] != missing_module]
            before = self.snapshot()
            with self.subTest(missing_module=missing_module):
                with self.assertRaisesRegex(ValueError, 'every changed production scene'):
                    self.record(bundle)
                self.assertEqual(before, self.snapshot())


if __name__ == '__main__':
    unittest.main()
