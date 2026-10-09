"""Synthetic ADB transport cases; no live game or visibility PASS is fabricated."""
from io import BytesIO
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from PIL import Image
from test_gas_caption_scroll_recovery import load_creative

class ScreencapResizeRetry(unittest.TestCase):
    def setUp(self):
        self.probe = load_creative()
        self.base = self.probe.base
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        stream = BytesIO()
        Image.new('RGB', (12, 8), (10, 20, 30)).save(stream, format='PNG')
        self.png = stream.getvalue()

    def failure(self, code=255):
        return subprocess.CalledProcessError(code, ['adb', 'exec-out', 'screencap', '-p'],
                                             stderr=b'capture failed during resize')

    def readers(self):
        return [lambda: self.base.capture(self.out, 'frame'),
                lambda: self.probe.capture(self.out, 'frame', timeout=5)]

    def test_transient_resize_failure_requires_fresh_complete_png(self):
        for read in self.readers():
            with self.subTest(reader=read), patch.object(self.base.subprocess, 'run',
                    side_effect=[self.failure(), SimpleNamespace(stdout=self.png)]) as command, \
                    patch.object(self.base.time, 'sleep'):
                result = read()
            self.assertEqual(command.call_count, 2)
            self.assertEqual((self.out / result['file']).read_bytes(), self.png)
            self.assertEqual(result['sha256'], hashlib.sha256(self.png).hexdigest())
            self.assertEqual((result['width'], result['height']), (12, 8))
            self.assertEqual(json.loads((self.out / 'frame-screencap-recovery.json').read_text())[0]['return_code'], 255)

    def test_other_command_errors_are_not_retried(self):
        for read in self.readers():
            with patch.object(self.base.subprocess, 'run', side_effect=self.failure(1)) as command, \
                    patch.object(self.base.time, 'sleep'), self.assertRaises(subprocess.CalledProcessError):
                read()
            self.assertEqual(command.call_count, 1)

    def test_persistent_failure_preserves_error_after_four_attempts_without_png(self):
        for read in self.readers():
            with patch.object(self.base.subprocess, 'run', side_effect=self.failure()) as command, \
                    patch.object(self.base.time, 'sleep'), self.assertRaises(subprocess.CalledProcessError):
                read()
            self.assertEqual(command.call_count, 4)
            self.assertFalse((self.out / 'frame.png').exists())

    def test_timeout_capture_keeps_original_overall_deadline(self):
        now = [0.0]
        def fail(*args, **kwargs):
            now[0] = 2.0
            raise self.failure()
        with patch.object(self.base.subprocess, 'run', side_effect=fail) as command, \
                patch.object(self.probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(self.probe.time, 'sleep'), self.assertRaises(TimeoutError):
            self.probe.capture(self.out, 'bounded', timeout=1)
        self.assertEqual(command.call_count, 1)
        self.assertFalse((self.out / 'bounded.png').exists())

if __name__ == '__main__':
    unittest.main()
