"""The new early negative-frame exit retains source and deadline integrity."""
from pathlib import Path
import shutil
import sys
from types import SimpleNamespace
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_flutter_loading_frame_rejection import FIXTURES, OriginalFixtureCase, invoke, reader


class EarlyNegativeExit(OriginalFixtureCase):
    def test_changed_pixels_cannot_be_recorded_as_the_observed_loading_caption(self):
        source = self.out / 'captured.png'
        shutil.copyfile(FIXTURES / 'android37-loading.png', source)

        def command(*args, timeout):
            shutil.copyfile(FIXTURES / 'android37-loading-contrast.tsv',
                            Path(args[2]).with_suffix('.tsv'))
            Image.new('RGB', (1080, 2400), 'black').save(source)
            return 'Exact original TSV with an explicitly adverse source replacement'

        with self.assertRaisesRegex(RuntimeError, 'changed during OCR'):
            invoke(reader(command), self.out, source)
        self.assertFalse((self.out / 'frame-ocr-rejected.json').exists())

    def test_caption_finishing_after_budget_cannot_be_relabelled_as_fresh_negative_evidence(self):
        now = [0.0]
        clock = SimpleNamespace(monotonic=lambda: now[0])

        def command(*args, timeout):
            self.assertEqual(timeout, 30)
            shutil.copyfile(FIXTURES / 'android37-loading-contrast.tsv',
                            Path(args[2]).with_suffix('.tsv'))
            now[0] = 30.01
            return 'Exact original TSV with a deliberately expired local clock'

        with self.assertRaises(TimeoutError):
            invoke(reader(command, clock=clock), self.out, FIXTURES / 'android37-loading.png')
        self.assertFalse((self.out / 'frame-ocr-rejected.json').exists())


if __name__ == '__main__':
    unittest.main()
