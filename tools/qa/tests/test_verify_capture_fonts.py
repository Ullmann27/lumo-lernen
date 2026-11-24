"""Prevent shipping unreadable Ahem-block screenshots as proof of app design."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from PIL import Image, ImageDraw

MODULE = Path(__file__).resolve().parents[1] / "verify_capture_fonts.py"
SPEC = importlib.util.spec_from_file_location("verify_capture_fonts", MODULE)
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class ScreenshotTypographyQualityTests(unittest.TestCase):
    def test_ahem_like_solid_text_bars_are_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "ahem.png"
            image = Image.new("RGB", (585, 1266), (8, 31, 66))
            draw = ImageDraw.Draw(image)
            for x, y, w in ((30, 85, 255), (30, 146, 140), (30, 210, 215)):
                draw.rectangle((x, y, x + w, y + 24), fill=(250, 250, 250))
            image.save(path)
            with self.assertRaisesRegex(ValueError, "Ahem"):
                CHECK.assert_real_text_rendering(path)

    def test_actual_hollow_glyph_like_strokes_are_accepted(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "text.png"
            image = Image.new("RGB", (585, 1266), (8, 31, 66))
            draw = ImageDraw.Draw(image)
            # An O-like glyph with counterspace cannot be an Ahem rectangle.
            for x in (36, 102, 175, 252):
                draw.ellipse((x, 80, x + 56, 150), outline=(245, 245, 245), width=8)
            image.save(path)
            report = CHECK.assert_real_text_rendering(path)
            self.assertEqual(report["status"], "PASS")
            self.assertEqual(report["continuous_solid_bar_rows"], 0)

    def test_invalid_image_size_fails_closed(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "tiny.png"
            Image.new("RGB", (80, 50), (0, 0, 0)).save(path)
            with self.assertRaisesRegex(ValueError, "Unexpected screenshot size"):
                CHECK.assert_real_text_rendering(path)


if __name__ == "__main__":
    unittest.main()
