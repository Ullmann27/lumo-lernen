"""Preserved evidence must not admit stale source or mask a failed runtime."""
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from preserved_source_proof import (
    APP_SOURCE, GODOT_SOURCE, BUILD_REJECTION, DIRTY_CAPTURE,
    NATIVE_MARKERS, NATIVE_PNG_COUNTS, verify_preserved_source,
)


class PreservedSourceProofTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        self.app, self.native, self.failed = [root / name for name in ('app', 'native', 'failed')]
        for folder in (self.app, self.native, self.failed):
            folder.mkdir()
        self.write(self.app, 'source-sha.txt', APP_SOURCE + '\n')
        self.write(self.native, 'fold-controls/source-sha.txt', GODOT_SOURCE + '\n')
        self.write(self.failed, 'source-sha.txt', APP_SOURCE + '\n')
        self.write(self.failed, 'build.log', BUILD_REJECTION + '\nM\t' + DIRTY_CAPTURE + '\n')
        self.write(self.app, 'TEST-RESULTS.txt', '\n'.join((
            'Flutter source: ' + APP_SOURCE, 'PASS Flutter source analysis (no errors)',
            'PASS full Flutter regression suite', 'PASS native preparation Python tests')))
        self.write(self.app, 'analysis.log', '151 issues found. (ran in 13.0s)\n')
        self.write(self.app, 'dependencies.log', 'Got dependencies!\n')
        for name, passed, skipped in (('flutter-tests', 750, 4), ('launcher-candidate-green', 15, 0),
                                      ('photo-lesson-candidate-green', 12, 0)):
            self.write(self.app, name + '.log', f'00:01 +{passed}' + (f' ~{skipped}' if skipped else '') + ': All tests passed!\n')
        for name, count, skipped in (('native-preparation', 9, 0), ('android-harness-tests', 204, 8)):
            self.write(self.app, name + '.log', f'Ran {count} tests in 0.5s\n\nOK' + (f' (skipped={skipped})' if skipped else '') + '\n')
        self.write(self.app, 'launcher-base-red.log', 'A profile changed while lifetime-wallet storage was pending.\nExpected: false\n Actual: <true>\nSome tests failed.\n')
        self.write(self.app, 'photo-lesson-base-red.log', '\n'.join(
            f'Photo lesson must keep recognized subject {subject} and topic.' for subject in ('Deutsch', 'Englisch', 'Sachunterricht')) + '\nSome tests failed.\n')
        self.write(self.app, 'backend.log', '# tests 22\n# pass 22\n# fail 0\n')
        self.write(self.app, 'content.log', 'Checked 40960 generated tasks\nPASS: exact answers\n')
        self.write(self.app, 'repair-guard.log', 'Zero-Defect Repair Guard finished.\n')
        engine = 'Godot Engine v4.6.3.stable.official.7d41c59c4\n'
        for name, markers in NATIVE_MARKERS.items():
            self.write(self.native, 'fold-controls/' + name, engine + '\n'.join(markers) + '\n')
        self.write(self.native, 'fold-controls/import.log', engine + '[ DONE ] reimport\n')
        self.write(self.native, 'complete-flow/evidence.json', json.dumps({
            'save_reopen_resume': True, 'ordered_gates': [{'gate': i} for i in range(1, 17)],
            'result': {'status': 'completed', 'checkpoints': 16}}))
        png_header = b'\x89PNG\r\n\x1a\n' + struct.pack('>I4sII', 13, b'IHDR', 1280, 720)
        for i in range(26):
            self.write(self.app, f'app-renders/{i}.png', png_header)
        for folder, count in NATIVE_PNG_COUNTS.items():
            for i in range(count):
                self.write(self.native, f'{folder}/{i}.png', png_header)
        for i in range(9):
            self.write(self.native, f'fleet-models/{i}.glb', b'glTF')

    def write(self, folder, name, content):
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content) if isinstance(content, bytes) else path.write_text(content)

    def verify(self):
        return verify_preserved_source(self.app, self.native, self.failed)

    def test_exact_evidence_pass_retains_original_failure_and_all_file_hashes(self):
        result = self.verify()
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(result['known_failed_build']['status'], 'FAIL')
        self.assertEqual(result['strict_native_probes'], 19)
        self.assertEqual(result['test_counts']['flutter'], {'passed': 750, 'skipped': 4})
        self.assertEqual(result['native_png_count'], 113)
        self.assertTrue(all(len(row['sha256']) == 64 for rows in result['files'].values() for row in rows))

    def test_stale_source_rejected_for_each_artifact(self):
        for folder, name in ((self.app, 'source-sha.txt'), (self.native, 'fold-controls/source-sha.txt'),
                             (self.failed, 'source-sha.txt')):
            path = folder / name
            original = path.read_text()
            with self.subTest(artifact=folder.name):
                path.write_text('0' * 40)
                with self.assertRaisesRegex(ValueError, 'Stale'):
                    self.verify()
                path.write_text(original)

    def test_error_after_final_pass_is_never_ignored(self):
        path = self.native / 'fold-controls/kart_race_continuity_regression.log'
        original = path.read_text()
        for error in ('ERROR: Texture leaked', 'SCRIPT ERROR: Parse Error', 'Assertion failed'):
            with self.subTest(error=error):
                path.write_text(original + error + '\n')
                with self.assertRaisesRegex(ValueError, 'Strict engine failure'):
                    self.verify()

    def test_missing_final_marker_rejects_an_earlier_split_pass(self):
        self.write(self.native, 'fold-controls/kart_physics_regression.log',
                   'Godot Engine v4.6.3.stable.official.7d41c59c4\n[KartSplit] PASS: raised road\n')
        with self.assertRaisesRegex(ValueError, 'Missing final runtime marker'):
            self.verify()

    def test_both_video_grade_markers_required(self):
        self.write(self.native, 'fold-controls/kart_video_visual_regression.log',
                   'Godot Engine v4.6.3.stable.official.7d41c59c4\n[ Kart ] PASS\n' +
                   NATIVE_MARKERS['kart_video_visual_regression.log'][0] + '\n')
        with self.assertRaisesRegex(ValueError, 'Missing final runtime marker'):
            self.verify()

    def test_extra_dirty_path_and_other_build_errors_rejected(self):
        expected = (self.failed / 'build.log').read_text()
        for suffix in ('M\tlib/product.dart\n', 'ERROR: native export failed\n'):
            with self.subTest(suffix=suffix):
                self.write(self.failed, 'build.log', expected + suffix)
                with self.assertRaisesRegex(ValueError, 'additional dirty path'):
                    self.verify()

    def test_missing_expected_base_red_is_not_success(self):
        self.write(self.app, 'launcher-base-red.log', 'Some tests failed.\nUnrelated exception\n')
        with self.assertRaisesRegex(ValueError, 'Missing expected launcher base RED'):
            self.verify()

    def test_wrong_test_count_and_green_failure_rejected(self):
        for text in ('00:01 +749 ~4: All tests passed!\n',
                     'Some tests failed.\n00:01 +750 ~4: All tests passed!\n'):
            with self.subTest(text=text):
                self.write(self.app, 'flutter-tests.log', text)
                with self.assertRaises(ValueError):
                    self.verify()

    def test_native_import_error_and_wrong_engine_rejected(self):
        for text in ('Godot Engine v4.6.3.stable.official.7d41c59c4\nERROR: Failed to load\n',
                     'Godot Engine v4.5.stable.official.abc\n'):
            with self.subTest(text=text):
                self.write(self.native, 'fold-controls/import.log', text)
                with self.assertRaises(ValueError):
                    self.verify()

    def test_missing_runtime_image_is_rejected(self):
        (self.native / 'complete-flow/0.png').unlink()
        with self.assertRaisesRegex(ValueError, 'Incomplete native screenshot set'):
            self.verify()

    def test_unordered_race_gate_is_rejected(self):
        path = self.native / 'complete-flow/evidence.json'
        content = json.loads(path.read_text())
        content['ordered_gates'][2]['gate'] = 1
        path.write_text(json.dumps(content))
        with self.assertRaisesRegex(ValueError, 'Incomplete ordered race gates'):
            self.verify()

    def test_symlink_cannot_substitute_evidence(self):
        path = self.app / 'source-sha.txt'
        path.unlink()
        path.symlink_to(self.failed / 'source-sha.txt')
        with self.assertRaisesRegex(ValueError, 'Missing regular evidence'):
            self.verify()


if __name__ == '__main__':
    unittest.main()
