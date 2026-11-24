"""Fail-closed targeted Android HUD OCR, based on actual 1978 failure."""
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_android_race import (  # noqa: E402
    focused_race_hud_text, focused_race_hud_visible,
)


class FocusedKartHudOCRTests(unittest.TestCase):
    def test_exactly_three_independent_visual_race_hud_markers(self):
        # Verbatim focused Tesseract result from the real 1978 Android PNG.
        self.assertTrue(focused_race_hud_visible(
            'RUNDE 1/2 PLATZ6/6 Okm/h x0'))
        self.assertTrue(focused_race_hud_visible(
            'RUNDE 2 / 2  PLATZ 3 / 6  78 km/h'))
        for false_text in (
            '', 'RUNDE 1/2', 'PLATZ 6/6 0 km/h',
            'RUNDE 1/2 PLATZ 6/6', 'RUNDE 1/2 0 km/h',
            'RUNDE 3/2 PLATZ 6/6 0 km/h',
            'RUNDE 1/2 PLATZ 7/6 0 km/h',
            'RUNDE 1/2 PLATZ 6/6 und Los!',
        ):
            with self.subTest(false_text=false_text):
                self.assertFalse(focused_race_hud_visible(false_text))

    def test_genuine_screen_pixels_recover_lap_rank_and_speed(self):
        # Not a hardcoded string adapter: draw a real contrast HUD onto
        # a landscape device-sized RGB image, run actual Tesseract pixels.
        with tempfile.TemporaryDirectory() as work:
            file = Path(work) / 'race.png'
            image = Image.new('RGB', (2400, 1080), '#F2C9A0')
            draw = ImageDraw.Draw(image)
            draw.rounded_rectangle((485, 44, 1990, 145), radius=28,
                                   fill='#26303B')
            font_file = Path('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
            font = ImageFont.truetype(str(font_file), 43) if font_file.is_file() else ImageFont.load_default()
            draw.text((670, 74), 'RUNDE 1/2  PLATZ 6/6  0 km/h',
                      fill='white', font=font)
            image.save(file)
            actual = focused_race_hud_text(file)
            self.assertTrue(focused_race_hud_visible(actual),
                            f'The actual cropped bitmap must be legible: {actual!r}')

    def test_only_real_landscape_frame_is_accepted(self):
        with tempfile.TemporaryDirectory() as work:
            file = Path(work) / 'portrait.png'
            Image.new('RGB', (360, 800), '#101824').save(file)
            with self.assertRaisesRegex(RuntimeError, 'landscape'):
                focused_race_hud_text(file)


if __name__ == '__main__':
    unittest.main()
