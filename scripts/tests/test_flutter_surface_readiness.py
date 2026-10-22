import json
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / '.github' / 'probes'))
from flutter_surface_readiness import capture_when_ready, inspect_flutter_frame


def frame(file: Path, *, painted: bool) -> None:
    image = Image.new('RGB', (360, 800), (5, 28, 61))
    if painted:
        draw = ImageDraw.Draw(image)
        for y in range(50, 740, 25):
            for x in range(15, 345, 25):
                value = (x * 7 + y * 11) % 240
                draw.rectangle((x, y, x + 24, y + 24),
                               fill=(value, (value * 3) % 240, (value * 7) % 240))
    image.save(file)


class FlutterSurfaceReadinessTest(unittest.TestCase):
    def test_rejects_realistic_flat_loading_screen_accepts_rendered_content(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)
            frame(out / 'blank.png', painted=False)
            frame(out / 'ready.png', painted=True)
            blank = inspect_flutter_frame(out / 'blank.png')
            ready = inspect_flutter_frame(out / 'ready.png')
            self.assertFalse(blank['visually_ready'])
            self.assertTrue(ready['visually_ready'])
            self.assertLess(blank['content_entropy_bits'], ready['content_entropy_bits'])

    def test_retries_without_claiming_early_dark_frame_as_real_screenshot(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)
            moment = [0.0]
            captured = []

            def snapshot(directory, name):
                captured.append(name)
                file = directory / (name + '.png')
                frame(file, painted=len(captured) >= 3)
                return {'file': file.name, 'sha256': f'fixture-{len(captured)}'}

            def wait(seconds):
                moment[0] += seconds

            result = capture_when_ready(out, '07_home_after_onboarding',
                                        snapshot, clock=lambda: moment[0],
                                        wait=wait)
            self.assertEqual(len(captured), 3)
            self.assertTrue((out / result['file']).is_file())
            self.assertEqual(result['file'], '07_home_after_onboarding.png')
            self.assertFalse((out / (captured[-1] + '.png')).exists())
            self.assertTrue((out / (captured[0] + '.png')).exists())
            journal = json.loads((out / '07_home_after_onboarding-render-readiness.json').read_text())
            self.assertEqual(journal['status'], 'PASS')
            self.assertEqual(len(journal['attempts']), 3)
            self.assertFalse(journal['attempts'][0]['visually_ready'])
            self.assertTrue(journal['attempts'][2]['visually_ready'])

    def test_never_passes_permanently_unrendered_page(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)
            calls = [0]

            def blank(directory, name):
                calls[0] += 1
                file = directory / (name + '.png')
                frame(file, painted=False)
                return {'file': file.name, 'sha256': 'fixture'}

            with self.assertRaisesRegex(RuntimeError, 'visually unrendered'):
                capture_when_ready(out, '10_lernen', blank, max_attempts=2,
                                   wait=lambda seconds: None)
            self.assertEqual(calls[0], 2)
            journal = json.loads((out / '10_lernen-render-readiness.json').read_text())
            self.assertEqual(journal['status'], 'FAIL')
            self.assertEqual(len(journal['attempts']), 2)
            self.assertFalse((out / '10_lernen.png').exists())

    def test_blocks_path_traversal_and_untrusted_capture_file(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)
            with self.assertRaises(ValueError):
                capture_when_ready(out, '../wrong', lambda *_: None)

            with self.assertRaisesRegex(ValueError, 'unsafe file name'):
                capture_when_ready(out, 'safe', lambda *_: {'file': '../unsafe.png'})
            journal = json.loads((out / 'safe-render-readiness.json').read_text())
            self.assertEqual(journal['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
