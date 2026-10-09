"""Actual APK 1909 cover-screen OCR regression; never a runtime PASS."""
import hashlib
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_ocr_tiles import observed_matches, read_tiled_word

FIXTURES = [('drift-cover-1909-api35.png', 'ddcb8a10a6a818ce6acf6d24b30c091293f88000749fca9c71de3f169940c2e6'),
            ('drift-cover-1909-api36.png', 'c799ef469f96f6626a808cbba39cced943f37db28f8089154d0834ee5e2bdccf')]

def normalize(value):
    return re.sub('[^a-z0-9]', '', value.lower())

class NativeDimCaptionRegression(unittest.TestCase):
    @unittest.skipUnless(shutil.which('tesseract'), 'Actual screenshot OCR requires Tesseract')
    def test_actual_cover_frames_read_exact_drift_with_real_bounds(self):
        # Actions 37888592898; artifacts 11598996587 and 11599460476.
        # Both fixtures are unedited complete screenshots from the failed runs.
        def command(*args, timeout):
            return subprocess.run(args, timeout=timeout, check=True, capture_output=True,
                                  text=True).stdout
        for filename, digest in FIXTURES:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as directory:
                fixture = Path(__file__).with_name('fixtures') / filename
                self.assertEqual(hashlib.sha256(fixture.read_bytes()).hexdigest(), digest)
                matches = read_tiled_word(fixture, Path(directory), 'cover', 'drift', normalize, command)
                exact = [row for row in matches if row['text'] == 'DRIFT']
                self.assertTrue(exact, matches)
                self.assertTrue(all(row['variant'].startswith('white-latin-dim-') for row in exact))
                for row in exact:
                    x0, y0, x1, y1 = row['bounds']
                    self.assertTrue(1938 <= x0 < x1 <= 2010 and 560 <= y0 < y1 <= 585)
                    self.assertGreaterEqual(row['confidence'], 15)

    def test_partial_rift_is_not_accepted_as_drift(self):
        row = dict(page_num='1', block_num='1', par_num='1', line_num='1',
                   left='12', top='12', width='90', height='30', conf='99', text='RIFT')
        self.assertEqual(observed_matches([row], (0, 0, 120, 90), 3, (120, 90),
                                          'drift', normalize, 'dim'), [])

if __name__ == '__main__':
    unittest.main()
