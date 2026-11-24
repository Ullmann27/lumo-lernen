"""Original-archive recorder tests; synthetic inputs never approve real graphics."""
from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import warnings
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import record_kart_graphics_review as recorder
import test_kart_graphics_review as original_tests
import verify_kart_graphics_review as review
from test_nextgen_delivery import fixture_png


class RecordKartGraphicsReviewTests(unittest.TestCase):
    fixture = original_tests.KartGraphicsReviewTests.fixture
    write_json = staticmethod(original_tests.KartGraphicsReviewTests.write_json)

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='graphics-recorder-unit-')
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.output = self.base / 'recorded'

    @staticmethod
    def selection(args):
        return [{key: item[key] for key in ('area', 'artifact_entry', 'findings')}
                for item in args[1]['images']]

    @staticmethod
    def snapshot(root):
        return {str(path.relative_to(root)): path.read_bytes()
                for path in root.rglob('*') if path.is_file()} if root.exists() else {}

    def record(self, args, *, selection=None, root=None):
        return recorder.record_review(
            root or self.output, {key: args[3] / (key + '.zip') for key in review.ARTIFACT_NAMES},
            args[3], self.selection(args) if selection is None else selection,
            'Synthetic recorder test only', 'Synthetic parser inputs, never actual visual approval')

    def run_cli(self, args, selection=None):
        path = self.base / 'selection.json'
        path.write_text(json.dumps(self.selection(args) if selection is None else selection))
        command = [sys.executable, str(Path(recorder.__file__)), '--root', str(self.output),
                   '--proofs', str(args[3]), '--selection', str(path),
                   '--reviewer', 'Synthetic CLI test only',
                   '--notes', 'Synthetic parser inputs, never actual visual approval']
        for key in review.ARTIFACT_NAMES:
            command.extend(['--' + key + '-archive', str(args[3] / (key + '.zip'))])
        return subprocess.run(command, capture_output=True, text=True)

    def update_archive_digest(self, args, key):
        metadata = args[3] / (key + '-artifact.json')
        artifact = json.loads(metadata.read_bytes())
        artifact['digest'] = 'sha256:' + hashlib.sha256((args[3] / (key + '.zip')).read_bytes()).hexdigest()
        self.write_json(metadata, artifact)

    def change_zip(self, args, key, changes, extras=()):
        archive = args[3] / (key + '.zip')
        with zipfile.ZipFile(archive) as zipped:
            members = {entry.filename: zipped.read(entry) for entry in zipped.infolist()}
        for name, data in changes.items():
            if data is None:
                members.pop(name, None)
            else:
                members[name] = data
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(archive, 'w') as zipped:
                for name, data in members.items():
                    zipped.writestr(name, data)
                for name, data in extras:
                    zipped.writestr(name, data)
        self.update_archive_digest(args, key)

    def fresh_run_metadata(self, args):
        path = args[3] / 'run.json'
        run = json.loads(path.read_bytes())
        run['id'] += 1
        self.write_json(path, run)
        path = args[3] / 'jobs.json'
        jobs = json.loads(path.read_bytes())
        for job in jobs['jobs']:
            job['run_id'] = run['id']
            job['id'] += 1000
        self.write_json(path, jobs)
        for key in review.ARTIFACT_NAMES:
            path = args[3] / (key + '-artifact.json')
            artifact = json.loads(path.read_bytes())
            artifact['workflow_run']['id'] = run['id']
            artifact['id'] += 1000
            self.write_json(path, artifact)

    def test_real_cli_preserves_original_bytes_and_passes_existing_verifier(self):
        args = self.fixture()
        # Original formatting, including whitespace, must survive unchanged.
        for path in args[3].glob('*.json'):
            path.write_text(json.dumps(json.loads(path.read_bytes()), indent=1) + '\n\n')
        original = self.snapshot(args[3])
        result = self.run_cli(args)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            'status': 'approved', 'native_revision': args[2], 'images': 5, 'publication_enabled': False})
        receipt = json.loads((self.output / str(recorder.REVIEW_RECEIPT)).read_bytes())
        facts = review.verify_visual_review(self.output, receipt, args[2], args[3])
        self.assertEqual(facts['areas'], sorted(review.REVIEW_AREAS))
        self.assertEqual(self.snapshot(args[3]), original, 'Original ZIP/API inputs are immutable')
        metadata = self.output.joinpath(*review.PROOF_DIRECTORY, 'metadata')
        for name in review.WORKFLOW_FILES:
            self.assertEqual((metadata / name).read_bytes(), original[name])
        for key in review.ARTIFACT_NAMES:
            self.assertEqual((metadata / key / 'artifact.json').read_bytes(), original[key + '-artifact.json'])
            with zipfile.ZipFile(args[3] / (key + '.zip')) as zipped:
                for name in (*review.SOURCE_FILES, *review.REQUIRED_LOGS[key]):
                    if name != 'artifact.json':
                        self.assertEqual((metadata / key / name).read_bytes(), zipped.read(name))
        for item in receipt['images']:
            self.assertTrue(Path(item['path']).name.startswith(item['sha256'] + '-'))
            with zipfile.ZipFile(args[3] / (review.AREA_ARTIFACT[item['area']] + '.zip')) as zipped:
                self.assertEqual((self.output / item['path']).read_bytes(), zipped.read(item['artifact_entry']))
        self.assertFalse(list(self.output.rglob('.graphics-review-*')))

    def test_real_cli_rejects_invalid_selection_without_touching_previous_review(self):
        args = self.fixture()
        self.record(args)
        original = self.snapshot(self.output)
        selection = self.selection(args)
        selection[-1]['findings'] = ' '
        result = self.run_cli(args, selection)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing actual image review findings', result.stderr)
        self.assertEqual(self.snapshot(self.output), original)

    def test_each_zip_must_exist_and_match_its_original_api_digest(self):
        for key in review.ARTIFACT_NAMES:
            for mutation in ('missing', 'digest'):
                args = self.fixture()
                archive = args[3] / (key + '.zip')
                if mutation == 'missing':
                    archive.unlink()
                else:
                    archive.write_bytes(archive.read_bytes() + b'changed-original-archive')
                with self.subTest(key=key, mutation=mutation), self.assertRaises(ValueError):
                    self.record(args)
                self.assertFalse(self.output.exists())

    def test_missing_original_metadata_or_gate_logs_cannot_leave_output(self):
        for key, name in ((None, 'run.json'), (None, 'jobs.json'), (None, 'home-artifact.json'),
                          ('home', 'preview-resolution.log'), ('home', 'cards-header.log'),
                          ('worlds', 'winter-visibility.log'), ('feedback', 'source-dirty.txt')):
            args = self.fixture()
            if key is None:
                (args[3] / name).unlink()
            else:
                self.change_zip(args, key, {name: None})
            with self.subTest(key=key, name=name), self.assertRaises(ValueError):
                self.record(args)
            self.assertFalse(self.output.exists())

    def test_wrong_sources_jobs_dirty_trees_and_late_errors_use_existing_gates(self):
        args = self.fixture()
        self.record(args)
        original = self.snapshot(self.output)
        for mutation in ('artifact-source', 'run-failed', 'job-failed', 'source', 'tree', 'dirty', 'late-error'):
            changed = self.fixture()
            if mutation == 'artifact-source':
                path = changed[3] / 'worlds-artifact.json'
                data = json.loads(path.read_bytes())
                data['workflow_run']['head_sha'] = 'a' * 40
                self.write_json(path, data)
            if mutation == 'run-failed':
                path = changed[3] / 'run.json'
                data = json.loads(path.read_bytes())
                data['conclusion'] = 'failure'
                self.write_json(path, data)
            if mutation == 'job-failed':
                path = changed[3] / 'jobs.json'
                data = json.loads(path.read_bytes())
                data['jobs'][0]['conclusion'] = 'failure'
                self.write_json(path, data)
            alterations = {
                'source': ('source-sha.txt', b'a' * 40),
                'tree': ('source-tree.txt', b'd' * 40),
                'dirty': ('source-dirty.txt', b' M changed.gd\n'),
                'late-error': ('render.log', b'OpenGL API fixture\n[KartDriveFeedbackCapture] PASS\nERROR: late\n'),
            }
            if mutation in alterations:
                name, data = alterations[mutation]
                self.change_zip(changed, 'feedback', {name: data})
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.record(changed)
            self.assertEqual(self.snapshot(self.output), original)

    def test_duplicate_traversal_and_symlink_zip_entries_are_rejected(self):
        linked = zipfile.ZipInfo('unused-link')
        linked.create_system = 3
        linked.external_attr = (stat.S_IFLNK | 0o777) << 16
        for name, data in (('source-sha.txt', b'b' * 40), ('../outside.txt', b'outside'),
                           (linked, b'/outside')):
            args = self.fixture()
            self.change_zip(args, 'home', {}, [(name, data)])
            with self.subTest(member=str(name)), self.assertRaises(ValueError):
                self.record(args)
            self.assertFalse(self.output.exists())

    def test_crc_of_even_unselected_zip_members_is_verified(self):
        args = self.fixture()
        self.change_zip(args, 'feedback', {'unused.txt': b'original-extra-bytes'})
        archive = args[3] / 'feedback.zip'
        with zipfile.ZipFile(archive) as zipped:
            info = zipped.getinfo('unused.txt')
        raw = bytearray(archive.read_bytes())
        offset = info.header_offset + 30 + len(info.filename.encode()) + len(info.extra)
        raw[offset] ^= 1
        archive.write_bytes(raw)
        self.update_archive_digest(args, 'feedback')
        with self.assertRaisesRegex(ValueError, 'CRC'):
            self.record(args)
        self.assertFalse(self.output.exists())

    def test_unselected_manifested_pngs_must_match_actual_zip_bytes(self):
        args = self.fixture()
        with zipfile.ZipFile(args[3] / 'feedback.zip') as zipped:
            manifest = json.loads(zipped.read('image-manifest.json'))
        image = fixture_png(640, 360, 99)
        manifest.append({'file': 'images/unreviewed.png', 'bytes': len(image), 'sha256': '0' * 64})
        self.change_zip(args, 'feedback', {'images/unreviewed.png': image,
                                         'image-manifest.json': json.dumps(manifest).encode()})
        with self.assertRaisesRegex(ValueError, 'differs from its archive manifest'):
            self.record(args)
        self.assertFalse(self.output.exists())

    def test_invalid_baseline_duplicate_incomplete_or_corrupt_images_do_not_record(self):
        for mutation in ('baseline', 'duplicate', 'missing-portrait', 'missing-area', 'corrupt'):
            args = self.fixture()
            selection = self.selection(args)
            if mutation == 'baseline': selection[0]['artifact_entry'] = 'baseline/' + selection[0]['artifact_entry']
            if mutation == 'duplicate': selection.append(copy.deepcopy(selection[0]))
            if mutation == 'missing-portrait': selection.pop(1)
            if mutation == 'missing-area': selection.pop()
            if mutation == 'corrupt':
                key, name = 'feedback', selection[-1]['artifact_entry']
                with zipfile.ZipFile(args[3] / (key + '.zip')) as zipped:
                    data = zipped.read(name)[:40]
                    manifest = json.loads(zipped.read('image-manifest.json'))
                item = next(row for row in manifest if row['file'] == name)
                item.update(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
                self.change_zip(args, key, {name: data, 'image-manifest.json': json.dumps(manifest).encode()})
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.record(args, selection=selection)
            self.assertFalse(self.output.exists())

    def test_immutable_png_collision_or_symlink_output_is_rejected_before_writes(self):
        args = self.fixture()
        receipt = self.record(args)
        path = self.output / receipt['images'][0]['path']
        path.write_bytes(b'different bytes at a content-addressed location')
        before = self.snapshot(self.output)
        with self.assertRaisesRegex(ValueError, 'content-addressed PNG'):
            self.record(args)
        self.assertEqual(self.snapshot(self.output), before)
        outside = self.base / 'outside'
        outside.mkdir()
        (outside / 'sentinel').write_bytes(b'untouched')
        for name in ('docs', 'config'):
            target = self.base / ('symlink-' + name)
            target.mkdir()
            (target / name).symlink_to(outside, target_is_directory=True)
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, 'symlink'):
                self.record(args, root=target)
            self.assertEqual(self.snapshot(outside), {'sentinel': b'untouched'})

    def test_receipt_is_replaced_last_and_reordered_reviews_preserve_existing_pngs(self):
        args = self.fixture()
        first = self.record(args)
        originals = {item['path']: (self.output / item['path']).read_bytes() for item in first['images']}
        self.fresh_run_metadata(args)
        replacements = []
        replace = os.replace

        def tracked_replace(source, destination):
            replacements.append(Path(destination).relative_to(self.output).as_posix())
            return replace(source, destination)

        with patch.object(recorder.os, 'replace', side_effect=tracked_replace):
            second = self.record(args, selection=list(reversed(self.selection(args))))
        self.assertEqual(replacements[-1], str(recorder.REVIEW_RECEIPT))
        self.assertGreater(len(replacements), 1)
        self.assertEqual(second['native_workflow_run_id'], 101)
        for path, data in originals.items():
            self.assertEqual((self.output / path).read_bytes(), data)
        review.verify_visual_review(self.output, second, args[2], args[3])
        self.assertFalse(list(self.output.rglob('.graphics-review-*')))

    def test_mid_install_io_failure_restores_previous_receipt_and_all_metadata(self):
        args = self.fixture()
        first = self.record(args)
        original = self.snapshot(self.output)
        self.fresh_run_metadata(args)
        target = self.output.joinpath(*review.PROOF_DIRECTORY, 'metadata/worlds/artifact.json')
        replace, failed = os.replace, False

        def fail_once(source, destination):
            nonlocal failed
            if Path(destination) == target and not failed:
                failed = True
                raise OSError('simulated atomic replacement failure')
            return replace(source, destination)

        with patch.object(recorder.os, 'replace', side_effect=fail_once):
            with self.assertRaisesRegex(OSError, 'simulated atomic replacement failure'):
                self.record(args)
        self.assertTrue(failed)
        self.assertEqual(self.snapshot(self.output), original)
        self.assertEqual(json.loads((self.output / str(recorder.REVIEW_RECEIPT)).read_bytes()), first)
        self.assertFalse(list(self.output.rglob('.graphics-review-*')))


if __name__ == '__main__':
    unittest.main()
