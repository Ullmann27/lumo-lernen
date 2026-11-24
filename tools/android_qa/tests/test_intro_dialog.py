import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from intro_dialog import INTRO_TITLES, intro_skip_target

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'


def node(text='', **overrides):
    return {'package': PACKAGE, 'text': text, 'content-desc': '',
            'enabled': 'true', 'clickable': 'true',
            'bounds': '[500,100][800,220]', **overrides}


class IntroDialogTests(unittest.TestCase):
    def test_all_five_actual_intro_titles(self):
        for title in INTRO_TITLES:
            with self.subTest(title=title):
                self.assertEqual(intro_skip_target([
                    node(title, clickable='false'), node('Überspringen')
                ], PACKAGE), (650, 160))

    def test_combined_semantics_caption(self):
        self.assertEqual(intro_skip_target([
            node(content_desc='unused', **{'content-desc': 'Schritt 1 von 5\nHallo, ich bin Lumo!'}),
            node(**{'content-desc': 'Überspringen'})
        ], PACKAGE), (650, 160))

    def test_no_intro_or_wrong_skip_caption(self):
        for title in ['Hallo! Ich bin Lumo.', 'Dein Lumo-Tag', 'Rennen starten']:
            self.assertIsNone(intro_skip_target([node(title), node('Überspringen')], PACKAGE))
        self.assertIsNone(intro_skip_target([
            node('Hallo, ich bin Lumo!'), node('Tippen zum Überspringen')
        ], PACKAGE))

    def test_system_disabled_clipped_and_invalid_targets(self):
        for skip in [node('Überspringen', package='android'),
                     node('Überspringen', enabled='false'),
                     node('Überspringen', clickable='false'),
                     node('Überspringen', bounds='[1,2][2,3]'),
                     node('Überspringen', bounds='invalid'),
                     node('Überspringen', **{'visible-to-user': 'false'})]:
            self.assertIsNone(intro_skip_target([node('Hallo, ich bin Lumo!'), skip], PACKAGE))

    def test_multiple_distinct_targets_fail_closed(self):
        self.assertIsNone(intro_skip_target([
            node('Hallo, ich bin Lumo!'), node('Überspringen'),
            node('Überspringen', bounds='[100,100][200,200]')
        ], PACKAGE))
        self.assertEqual(intro_skip_target([
            node('Hallo, ich bin Lumo!'), node('Überspringen'), node('Überspringen')
        ], PACKAGE), (650, 160))


if __name__ == '__main__':
    unittest.main()
