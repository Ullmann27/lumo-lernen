"""Fresh Flutter pixels after real process return; Android/OCR transport is isolated.

Both PNG fixtures are unchanged original318 Android screenshots. OCR replies in
the scheduler tests are controlled adapter replies, not a new OCR/device PASS.
The source fixture manifest distinguishes the stale API37 image from API35.
"""
import ast
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import tempfile
from types import SimpleNamespace
import unicodedata
import unittest

ROOT = Path(__file__).resolve().parents[3]
PROBE = ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py'
FIXTURES = Path(__file__).with_name('fixtures') / 'studio_flutter_return_318'
SPEC = importlib.util.spec_from_file_location('flutter_surface_readiness',
    ROOT / '.github/probes/flutter_surface_readiness.py')
READINESS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(READINESS)


def normalized(value):
    text = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', text.lower())


class StudioFlutterReturnTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        manifest = json.loads((FIXTURES / 'manifest.json').read_text())
        self.images = {}
        for item in manifest['files']:
            raw = (FIXTURES / item['file']).read_bytes()
            self.assertEqual(hashlib.sha256(raw).hexdigest(), item['sha256'])
            self.images[item['file']] = raw
        self.native = self.images['android37_stale_native.png']
        self.flutter = self.images['android35_current_flutter.png']

    def replay(self, frames, *, native_alive=False, wrong_marker=False, leave_during_ocr=False):
        clock = [0.0]
        captures = []
        ocr_calls = []
        foreground = ['MainActivity']
        expected = [
            {'text': 'Erklärung lesen', 'bounds': [168, 1736, 445, 1771]},
            {'text': 'Schritt 6 von 6', 'bounds': [97, 1109, 394, 1140]},
        ]

        def wait(_label, observe, accept, **_kwargs):
            value = observe()
            if not accept(value):
                raise RuntimeError('Actual native process has not returned')
            return value

        def capture(out, tag, **_kwargs):
            index = min(len(captures), len(frames) - 1)
            raw = frames[index]
            path = out / (tag + '.png')
            path.write_bytes(raw)
            captures.append(path)
            clock[0] += .2
            return {'file': path.name, 'sha256': hashlib.sha256(raw).hexdigest(),
                    'width': 1080, 'height': 2400}

        def lines(out, tag, wanted='', source_path=None, **_kwargs):
            self.assertIsNotNone(source_path)
            raw = Path(source_path).read_bytes()
            ocr_calls.append(hashlib.sha256(raw).hexdigest())
            clock[0] += .2
            if leave_during_ocr:
                foreground[0] = 'LumoGameActivity'
            if raw == self.flutter and not wrong_marker:
                return copy.deepcopy(expected)
            return [{'text': 'Zahlen zum Anfassen', 'bounds': [70, 79, 979, 174]}]

        scope = {
            'Path': Path, 'json': json, 're': re,
            'inspect_flutter_frame': READINESS.inspect_flutter_frame,
            'time': SimpleNamespace(monotonic=lambda: clock[0],
                sleep=lambda seconds: clock.__setitem__(0, clock[0] + seconds)),
            'wait_for': wait,
            'tour': SimpleNamespace(godot_alive=lambda: native_alive, alive=lambda: True),
            'resumed_activity': lambda: foreground[0],
            'education': SimpleNamespace(wait_text=lambda *_args, **_kwargs: None),
            'must_see': lambda *_args, **_kwargs: None,
            'probe': SimpleNamespace(capture_flutter_ready=capture, capture=capture,
                image_lines=lines, normalized=normalized,
                digest=lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()),
        }
        tree = ast.parse(PROBE.read_text())
        names = {'returned_to_flutter', 'capture_returned_flutter'}
        functions = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in names]
        exec(compile(ast.Module(body=functions, type_ignores=[]), str(PROBE), 'exec'), scope)
        lesson = next(node for node in tree.body
                      if isinstance(node, ast.FunctionDef) and node.name == 'learning_roundtrip')
        call = next(node for node in ast.walk(lesson) if isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Name) and node.func.id == 'returned_to_flutter')
        options = {item.arg: ast.literal_eval(item.value) for item in call.keywords}
        return scope, options, captures, ocr_calls

    def run_return(self, scope, options):
        return scope['returned_to_flutter'](
            self.out, 'Acht und fünf', 'same-lesson', **options)

    def test_original_api37_native_frame_is_rejected_before_two_fresh_flutter_frames(self):
        scope, options, captures, ocr_calls = self.replay([self.native, self.flutter, self.flutter])
        self.run_return(scope, options)
        self.assertEqual((self.out / 'same-lesson.png').read_bytes(), self.flutter)
        self.assertEqual(len(captures), 3)
        self.assertGreaterEqual(len(ocr_calls), 3)
        report = json.loads((self.out / 'same-lesson-return-pixels.json').read_text())
        self.assertEqual(report['status'], 'PASS')
        self.assertEqual(report['consecutive_confirmed_frames'], 2)
        self.assertEqual(report['frames'][0]['status'], 'REJECTED')
        self.assertEqual(report['source_sha256'], hashlib.sha256(self.flutter).hexdigest())

    def test_semantics_ready_does_not_accept_persistently_native_pixels(self):
        scope, options, captures, _ = self.replay([self.native])
        with self.assertRaisesRegex(RuntimeError, 'Flutter.*pixel|Flutter.*caption'):
            self.run_return(scope, options)
        self.assertGreater(len(captures), 1)
        self.assertFalse((self.out / 'same-lesson.png').exists())

    def test_wrong_visible_caption_cannot_be_replaced_by_semantics(self):
        scope, options, _, _ = self.replay([self.flutter], wrong_marker=True)
        with self.assertRaisesRegex(RuntimeError, 'Flutter.*pixel|Flutter.*caption'):
            self.run_return(scope, options)

    def test_native_process_must_exit_before_any_capture(self):
        scope, options, captures, _ = self.replay([self.flutter], native_alive=True)
        with self.assertRaisesRegex(RuntimeError, 'process has not returned'):
            self.run_return(scope, options)
        self.assertEqual(captures, [])

    def test_caption_sequence_must_restart_after_an_intervening_stale_frame(self):
        scope, options, captures, _ = self.replay([self.flutter, self.native, self.flutter, self.flutter])
        self.run_return(scope, options)
        self.assertEqual(len(captures), 4)
        self.assertEqual((self.out / 'same-lesson.png').read_bytes(), self.flutter)

    def test_activity_change_during_ocr_cannot_authorize_a_flutter_capture(self):
        scope, options, _, _ = self.replay([self.flutter], leave_during_ocr=True)
        with self.assertRaisesRegex(RuntimeError, 'Flutter.*pixel|Flutter.*activity'):
            self.run_return(scope, options)


if __name__ == '__main__':
    unittest.main()
