"""Original PR481 portrait frames and negative observer counterexamples.

These checks locate an observed control. They do not establish a new Android
gesture, motion, save, or frame-rate result.
"""
import hashlib
import importlib.util
from pathlib import Path
import unittest

from PIL import Image, ImageDraw


SOURCE = Path(__file__).resolve().parents[2] / '.github/probes/studio_creative_android_probe.py'
SPEC = importlib.util.spec_from_file_location('studio_portrait_observer', SOURCE)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)
FIXTURES = Path(__file__).parent / 'fixtures/studio_joystick_portrait_pr481'
ORIGINALS = (
    ('0019-observe-original-stick.png',
     '2afbab541db859df123d1c800282d8379b4d20a2e9da85c3d4a759601ddc8b34'),
    ('0020-jump-failure.png',
     '37073ec19b112d4213c9e9da05e1d3c59da4766dc3f917f92ca1c0340e47a381'),
)


class PortraitJoystickContracts(unittest.TestCase):
    def original(self, index=0):
        filename, expected = ORIGINALS[index]
        path = FIXTURES / filename
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), expected)
        return probe.read_image(path)

    @staticmethod
    def synthetic(size=(1080, 1920)):
        return Image.new('RGB', size, (100, 180, 220))

    @staticmethod
    def ring(image, bounds, inset=14):
        draw = ImageDraw.Draw(image)
        draw.ellipse(bounds, fill=(0, 160, 240))
        x0, y0, x1, y1 = bounds
        draw.ellipse((x0 + inset, y0 + inset, x1 - inset, y1 - inset),
                     fill=(12, 30, 70))

    def test_both_unmodified_device_frames_select_only_the_original_outer_ring(self):
        for index, (filename, _) in enumerate(ORIGINALS):
            with self.subTest(original=filename):
                image = self.original(index)
                self.assertEqual(image.size, (1080, 1920))
                target = probe.stick_target(image)
                self.assertAlmostEqual(target['center'][0], 138, delta=2)
                self.assertAlmostEqual(target['center'][1], 1726.5, delta=2)
                self.assertAlmostEqual(target['diameter'], 186, delta=2)
                self.assertGreater(target['ring_fraction'], .95)

    def test_synthetic_resampling_of_the_original_preserves_observed_coordinates(self):
        original = self.original()
        for size in ((540, 960), (720, 1280)):
            with self.subTest(synthetic_size=size):
                image = original.resize(size, Image.Resampling.LANCZOS)
                factor = size[0] / original.width
                target = probe.stick_target(image)
                self.assertAlmostEqual(target['center'][0], 138 * factor, delta=2)
                self.assertAlmostEqual(target['center'][1], 1726.5 * factor, delta=2)
                self.assertAlmostEqual(target['diameter'], 186 * factor, delta=2)

    def test_landscape_original_contract_still_selects_the_same_ring(self):
        image = self.synthetic((960, 540))
        self.ring(image, (30, 340, 155, 465), inset=12)
        target = probe.stick_target(image)
        self.assertAlmostEqual(target['center'][0], 92.5, delta=2)
        self.assertAlmostEqual(target['center'][1], 402.5, delta=2)

    def test_blank_and_filled_circles_are_not_joystick_rings(self):
        blank = self.synthetic()
        filled = self.synthetic()
        ImageDraw.Draw(filled).ellipse((45, 1633, 231, 1819), fill=(0, 160, 240))
        for label, image in (('blank', blank), ('filled circle', filled)):
            with self.subTest(counterexample=label), self.assertRaisesRegex(
                    RuntimeError, 'no unique original joystick ring'):
                probe.stick_target(image)

    def test_absolute_and_proportional_minima_still_reject_small_rings(self):
        cases = (
            ((540, 960), (40, 820, 98, 878), 6),
            ((1080, 1920), (40, 1640, 150, 1750), 12),
        )
        for size, bounds, inset in cases:
            with self.subTest(size=size):
                image = self.synthetic(size)
                self.ring(image, bounds, inset)
                with self.assertRaisesRegex(RuntimeError, 'no unique original joystick ring'):
                    probe.stick_target(image)

    def test_two_valid_portrait_rings_remain_ambiguous(self):
        image = self.original()
        self.ring(image, (257, 1633, 443, 1819))
        with self.assertRaisesRegex(RuntimeError, 'no unique original joystick ring'):
            probe.stick_target(image)

    def test_elongated_or_outside_control_region_rings_are_rejected(self):
        for label, bounds in (
                ('elongated', (40, 1640, 240, 1740)),
                ('right side', (820, 1640, 1006, 1826)),
                ('above lower region', (45, 100, 231, 286))):
            with self.subTest(counterexample=label):
                image = self.synthetic()
                self.ring(image, bounds)
                with self.assertRaisesRegex(RuntimeError, 'no unique original joystick ring'):
                    probe.stick_target(image)


if __name__ == '__main__':
    unittest.main()
