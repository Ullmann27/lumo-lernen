import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('gamescontrols',ROOT/'.github/probes/lumo_games_android_controls.py')
controls=importlib.util.module_from_spec(spec)
spec.loader.exec_module(controls)
PACKAGE='dev.ullmann.lumo.lumo_lernen.coachpreview'


class ActualNavigationTest(unittest.TestCase):
    def setUp(self):
        path=ROOT/'scripts/tests/fixtures/android_1934_short_landscape_navigation.xml'
        self.nodes=[n.attrib for n in ET.parse(path).iter('node')]

    def test_actual_short_landscape_uses_sidebar_not_larger_right_column(self):
        self.assertEqual(controls.navigation_scroll_bounds(self.nodes,PACKAGE),[11,136,169,230])

    def test_clipped_six_pixel_navigation_is_not_tappable(self):
        self.assertIsNone(controls.enabled_button_bounds(self.nodes,PACKAGE,'Lernen'))
        self.assertEqual(controls.enabled_button_bounds(self.nodes,PACKAGE,'Start'),[47,139,133,218])

    def test_logo_caption_and_other_package_do_not_create_navigation_control(self):
        self.assertIsNone(controls.enabled_button_bounds(self.nodes,PACKAGE,'Spielen'))
        self.assertIsNone(controls.navigation_scroll_bounds(self.nodes,'another.package'))
