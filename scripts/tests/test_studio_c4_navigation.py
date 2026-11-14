"""Replay original failed Android navigation observations without Android I/O."""

from copy import deepcopy
import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'c4_navigation_under_test', ROOT / '.github/probes/lumo_connect_four_android_probe.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
FIXTURES = Path(__file__).parent / 'fixtures/studio_c4_navigation'


def nodes(name):
    return [dict(n.attrib) for n in ET.parse(FIXTURES / name).iter('node')]


class CurrentFlutterNavigation(unittest.TestCase):
    def target(self, values, density=2.625, size=(1080, 2400)):
        return MODULE.flutter_hub_navigation_target(values, size, density)

    def test_both_original_paused_cards_pages_require_their_visible_exit(self):
        for api in (35, 37):
            with self.subTest(api=api):
                value = self.target(nodes(f'api{api}-paused.xml'))
                self.assertEqual(value['action'], 'leave_paused_game')
                self.assertEqual(value['caption'], 'Zur Spieleauswahl')

    def test_both_actual_failure_pages_require_showcase_back_instead_of_hidden_tabs(self):
        for api in (35, 37):
            with self.subTest(api=api):
                value = self.target(nodes(f'api{api}-showcase.xml'))
                self.assertEqual(value['action'], 'leave_cards_showcase')
                self.assertEqual(value['caption'], 'Zur Spielwelt zurück')
                self.assertEqual(value['bounds'], [32, 157, 158, 283])

    def test_original_home_and_hub_are_distinct_current_routes(self):
        self.assertEqual(self.target(nodes('api35-home.xml'))['action'], 'open_games_tab')
        self.assertEqual(self.target(nodes('api35-hub.xml')), {'action': 'hub_ready'})

    def test_hidden_disabled_foreign_and_undersized_back_controls_cannot_pass(self):
        source = nodes('api35-showcase.xml')
        for change in ({'clickable': 'false'}, {'enabled': 'false'},
                       {'package': 'foreign.app'}, {'bounds': '[32,157][157,283]'}):
            with self.subTest(change=change):
                values = deepcopy(source)
                for node in values:
                    if node.get('content-desc') == 'Zur Spielwelt zurück':
                        node.update(change)
                self.assertIsNone(self.target(values))
        self.assertIsNone(self.target(source, density=3))
        self.assertIsNone(self.target(source, size=(120, 2400)))

    def test_ambiguous_target_and_unknown_page_are_rejected(self):
        values = nodes('api35-showcase.xml')
        other = deepcopy(next(n for n in values if n.get('content-desc') == 'Zur Spielwelt zurück'))
        other['bounds'] = '[200,157][326,283]'
        values.append(other)
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous'):
            self.target(values)
        self.assertIsNone(self.target([]))


if __name__ == '__main__':
    unittest.main()
