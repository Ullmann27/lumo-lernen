"""Strict visible picker targeting; fixtures are not Android round proof."""
from pathlib import Path
import sys
import tempfile
import types
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from android_ui import Android
from cards_android_round import CardsRound, picker_color_button


class ColorPickerTests(unittest.TestCase):
    def fixture(self):
        return ET.parse(Path(__file__).parent/'fixtures/cards-color-picker-visible.xml').getroot()

    def test_duplicate_table_caption_uses_actual_clickable_picker_ancestor_bounds(self):
        root = self.fixture()
        original = ET.tostring(root)
        target = picker_color_button(root, 'Rot')
        self.assertEqual(target.get('bounds'), '[51,368][135,452]')
        touches = []
        with tempfile.TemporaryDirectory() as directory:
            check = CardsRound(types.SimpleNamespace(bounds=Android.bounds,
                               tap=lambda x, y: touches.append((x, y))),
                               Path(directory), timeout=1, allow_unverified=False)
            check.latest_root = root
            check.record = lambda *args, **kwargs: None
            check.tap_node(target, 'actual clickable picker Rot button')
        self.assertEqual(touches, [(93, 410)])
        self.assertEqual(ET.tostring(root), original)

    def test_direct_actionable_caption_is_supported_without_ancestor_guessing(self):
        root = self.fixture()
        self.assertEqual(picker_color_button(root, 'Blau').get('bounds'), '[247,368][331,452]')

    def test_multiple_actionable_color_buttons_are_rejected(self):
        root = self.fixture()
        ET.SubElement(root[0], 'node', {'content-desc': 'Rot', 'enabled': 'true',
                                      'clickable': 'true', 'bounds': '[140,470][224,554]'})
        with self.assertRaisesRegex(RuntimeError, 'found 2'):
            picker_color_button(root, 'Rot')

    def test_disabled_or_invisible_label_or_action_ancestor_is_rejected(self):
        for on_label in (True, False):
            for attribute in ('enabled', 'visible-to-user'):
                with self.subTest(on_label=on_label, attribute=attribute):
                    root = self.fixture()
                    target = root[0][3]
                    (target[0] if on_label else target).set(attribute, 'false')
                    with self.assertRaisesRegex(RuntimeError, 'found 0'):
                        picker_color_button(root, 'Rot')

    def test_missing_or_ambiguous_picker_heading_never_taps_a_color_caption(self):
        for duplicate in (False, True):
            with self.subTest(duplicate=duplicate):
                root = self.fixture()
                if duplicate:
                    ET.SubElement(root[0], 'node', {'content-desc': 'Waehle eine Farbe',
                                                  'bounds': '[48,300][432,320]'})
                else:
                    root[0].remove(root[0][2])
                with self.assertRaisesRegex(RuntimeError, 'picker heading'):
                    picker_color_button(root, 'Rot')

    def test_action_above_heading_or_shared_across_colors_is_rejected(self):
        for shared in (False, True):
            with self.subTest(shared=shared):
                root = self.fixture()
                target = root[0][3]
                if shared:
                    ET.SubElement(target, 'node', {'content-desc': 'Gelb',
                                                  'bounds': '[112,395][132,419]'})
                else:
                    target.set('bounds', '[51,260][135,310]')
                    target[0].set('bounds', '[70,275][110,299]')
                with self.assertRaisesRegex(RuntimeError, 'found 0'):
                    picker_color_button(root, 'Rot')


if __name__ == '__main__':
    unittest.main()
