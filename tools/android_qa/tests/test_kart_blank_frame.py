"""A Godot frame without any drawn UI is reported as such, not as a missing button.

Replays the situation of run 44473804677 with synthetic frames: the Kart
landing screenshot was the project clear colour (20,15,31) on the whole app
area while logcat showed CanvasShaderGLES3 link failures. The tour used to fall
through to the legacy wizard and fail with "Missing Android kart footer at step
1: Weiter", which hid the real cause.
"""
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw

sys.dont_write_bytecode = True
Image.preinit()
sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_modernization_tour_identity import TOUR_MODULE as tour  # noqa: E402

CLEAR = (20, 15, 31)
LOG = '\n'.join([
    'E/godot   ( 4808): ERROR: CanvasShaderGLES3: Program linking failed:',
    'E/godot   ( 4808): Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)',
    'E/godot   ( 4808): ERROR: SceneShaderGLES3: Program linking failed:',
    'E/godot   ( 4808): Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)',
    'I/godot   ( 4808): OpenGL API OpenGL ES 3.0 (OpenGL ES 3.0 SwiftShader 4.0.0.1) - Compatibility',
])


def png(draw_ui=False, size=(2400, 1080)):
    image = Image.new('RGB', size, CLEAR)
    canvas = ImageDraw.Draw(image)
    canvas.rectangle((0, 0, size[0], 40), fill=(0, 0, 0))          # status bar text area
    canvas.text((60, 10), '7:05', fill=(255, 255, 255))
    canvas.rectangle((1050, size[1] - 20, 1350, size[1] - 14), fill=(255, 255, 255))  # nav handle
    if draw_ui:
        canvas.rounded_rectangle((1900, 860, 2300, 980), 30, fill=(255, 215, 94))
        canvas.rectangle((200, 200, 900, 700), fill=(40, 90, 200))
    buffer = io.BytesIO()
    image.save(buffer, format='PNG')
    return buffer.getvalue()


class BlankFrameTests(unittest.TestCase):
    def test_clear_colour_frame_is_blank(self):
        blank = tour.blank_native_frame(png())
        self.assertEqual(blank['rgb'], list(CLEAR))
        self.assertGreaterEqual(blank['share'], .995)

    def test_frame_with_drawn_ui_is_not_blank(self):
        self.assertIsNone(tour.blank_native_frame(png(draw_ui=True)))

    def test_gl_link_failures_are_counted_per_shader(self):
        gl = tour.gl_link_failures(LOG)
        self.assertEqual(gl['link_failures'], {'Canvas': 1, 'Scene': 1})
        self.assertEqual(gl['uniform_limit_lines'], 2)
        self.assertIn('SwiftShader', gl['renderer'])

    def test_kart_start_reports_blank_frame_instead_of_missing_weiter(self):
        frame = png()
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(tour, 'godot_alive', lambda: True), \
                patch.object(tour, '_screencap', lambda: frame), \
                patch.object(tour, '_read_garage_footer', lambda *a, **k: None), \
                patch.object(tour.base, 'adb', lambda *a, **k: LOG), \
                patch.object(tour.time, 'sleep', lambda s: None), \
                patch.dict('os.environ', {'LUMO_NATIVE_STAGE_MENU': '0'}):
            with self.assertRaises(RuntimeError) as caught:
                tour._start_actual_embedded_race(Path(folder))
            report = json.loads((Path(folder) / '21_kart_blank_frame.json').read_text())
        message = str(caught.exception)
        self.assertIn('shows no UI', message)
        self.assertNotIn('Weiter', message)
        self.assertEqual(report['classification'], 'rendering on this emulator GL')
        self.assertEqual(report['gl']['link_failures']['Canvas'], 1)

    def test_drawn_landing_still_reaches_the_wizard_search(self):
        frame = png(draw_ui=True)
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(tour, 'godot_alive', lambda: True), \
                patch.object(tour, '_screencap', lambda: frame), \
                patch.object(tour, '_read_garage_footer', lambda *a, **k: None), \
                patch.object(tour.base, 'adb', lambda *a, **k: ''), \
                patch.object(tour.time, 'sleep', lambda s: None), \
                patch.dict('os.environ', {'LUMO_NATIVE_STAGE_MENU': '0'}):
            with self.assertRaisesRegex(RuntimeError, 'Missing Android kart footer at step 1: Weiter'):
                tour._start_actual_embedded_race(Path(folder))


if __name__ == '__main__':
    unittest.main()
