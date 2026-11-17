import importlib.util
from pathlib import Path
import tempfile
import unittest

from PIL import Image

spec = importlib.util.spec_from_file_location('visual_compare',
    Path(__file__).resolve().parents[1] / 'lumo_visual_compare.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class VisualCompareTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.ref, self.actual = self.root / 'ref.png', self.root / 'actual.png'
        Image.new('RGB', (100, 100), 'navy').save(self.ref)
        Image.new('RGB', (100, 100), 'navy').save(self.actual)

    def compare(self, **kwargs):
        return module.compare(self.ref, self.actual, self.root / 'report', **kwargs)

    def test_identical_capture_passes_and_inputs_are_immutable(self):
        original = self.ref.read_bytes(), self.actual.read_bytes()
        report = self.compare(max_changed_fraction=0)
        self.assertTrue(report['within_threshold'])
        self.assertEqual(report['regions']['full']['changed_fraction'], 0)
        self.assertEqual(original, (self.ref.read_bytes(), self.actual.read_bytes()))

    def test_planted_change_is_localized_and_regression_fails(self):
        image = Image.open(self.actual)
        image.paste('white', (0, 0, 50, 50))
        image.save(self.actual)
        report = self.compare(regions={'changed': [0, 0, .5, .5], 'steady': [.5, .5, 1, 1]},
                              max_changed_fraction=.01)
        self.assertFalse(report['within_threshold'])
        self.assertEqual(report['regions']['changed']['changed_fraction'], 1)
        self.assertEqual(report['regions']['steady']['changed_fraction'], 0)
        self.assertTrue((self.root / 'report' / 'difference.png').exists())

    def test_resize_requires_explicit_diagnostic_alignment(self):
        Image.new('RGB', (120, 80), 'navy').save(self.actual)
        with self.assertRaisesRegex(ValueError, 'sizes differ'):
            self.compare()
        self.assertEqual(self.compare(fit_reference=True)['alignment'], 'diagnostic resize')

    def test_invalid_regions_are_rejected(self):
        for bounds in [[-1, 0, 1, 1], [0, 0, 0, 1], [0, 0, 2, 1]]:
            with self.subTest(bounds=bounds), self.assertRaises(ValueError):
                self.compare(regions={'bad': bounds})
