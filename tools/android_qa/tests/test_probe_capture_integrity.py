import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts' / 'probes'))
import pr207_android_smoke as smoke  # noqa: E402


class CaptureIntegrityTest(unittest.TestCase):
    """A busy emulator can cut a screencap transfer; such a file must not be used."""

    HEADER = b'\x89PNG\r\n\x1a\n'

    def test_complete_png_has_iend_chunk(self):
        self.assertTrue(smoke.png_complete(self.HEADER + b'data' + smoke.PNG_END))

    def test_truncated_transfer_is_rejected(self):
        self.assertFalse(smoke.png_complete(self.HEADER + b'data'))
        self.assertFalse(smoke.png_complete(b''))
        self.assertFalse(smoke.png_complete(b'junk' + smoke.PNG_END))


if __name__ == '__main__':
    unittest.main()
