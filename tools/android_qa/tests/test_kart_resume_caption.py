"""Replay the untouched APK 1948 failure frame through the real OCR/touch guard.

This is a reader regression, not Android gameplay acceptance. The caption comes
from the actual completed-race flow so stale action text fails on the real image.
"""
import ast
import hashlib
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from test_gas_caption_scroll_recovery import KART_PATH, load_creative


FIXTURE = Path(__file__).with_name('fixtures') / 'kart-resume-1948/api35.png'


class KartResumeCaptionTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('tesseract'), 'Real screenshot OCR needs Tesseract')
    def test_completed_race_action_touches_visible_resume_button(self):
        self.assertEqual(hashlib.sha256(FIXTURE.read_bytes()).hexdigest(),
                         '2b8bbd2e8d3146735e86e3e571719c625e9c4fdda49f1d995142f649cbb5a7f0')
        calls = [node for node in ast.walk(ast.parse(KART_PATH.read_text()))
                 if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                 and node.func.id == 'tap_native' and len(node.args) >= 2
                 and isinstance(node.args[1], ast.Constant)
                 and node.args[1].value == 'actual-completed-race-resume']
        self.assertEqual(len(calls), 1)
        label = ast.literal_eval(calls[0].args[0])
        creative = load_creative()
        with tempfile.TemporaryDirectory() as temporary:
            out = Path(temporary)
            lines = creative.image_lines(out, 'real-1948', source_path=FIXTURE)
            observed = [row for row in lines
                        if creative.normalized(row['text']) == creative.normalized(label)]
            self.assertTrue(observed, 'Completed-race flow requests an absent caption: ' + label)
            for row in observed:
                x0, y0, x1, y1 = row['bounds']
                self.assertTrue(325 <= x0 < x1 <= 601 and 874 <= y0 < y1 <= 964)

            def capture(directory, tag, **kwargs):
                target = directory / (tag + '.png')
                shutil.copyfile(FIXTURE, target)
                return {'file': target.name}

            # Only the transport/capture source is replaced: the real OCR,
            # complete-surface check and stable two-frame target guard execute.
            with patch.object(creative, 'capture', capture), \
                    patch.object(creative.base, 'adb') as adb:
                creative.native_text(out, label, 'resume', tap=True, exact=True)
            adb.assert_called_once()
            arguments = adb.call_args.args
            self.assertEqual(arguments[:3], ('shell', 'input', 'swipe'))
            self.assertEqual(arguments[3:5], arguments[5:7])
            self.assertTrue(325 <= int(arguments[3]) <= 601)
            self.assertTrue(874 <= int(arguments[4]) <= 964)


if __name__ == '__main__':
    unittest.main()
