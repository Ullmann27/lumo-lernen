"""Constructed selector regressions; these are not Android usage evidence."""
from pathlib import Path
import sys
import tempfile
import types
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from android_ui import Android
from cards_android_round import CardsRound


class LearningPromptTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.touches, self.records = [], []
        self.check = CardsRound(types.SimpleNamespace(bounds=Android.bounds,
            tap=lambda x, y: self.touches.append((x, y))),
            Path(self.tmp.name), timeout=1, allow_unverified=True)
        self.check.record = lambda event, **data: self.records.append((event, data))

    def fixture(self, prompt='Finde den Buchstaben A.', answers=('A', 'B', 'C', 'D')):
        root = ET.Element('hierarchy')
        panel = ET.SubElement(root, 'node', {'bounds': '[0,0][480,800]'})
        def label(text, bounds, clickable='false'):
            return ET.SubElement(panel, 'node', {'content-desc': text,
                'bounds': bounds, 'clickable': clickable, 'enabled': 'true'})
        label('Denkpause', '[50,240][300,270]')
        label('+1', '[380,240][420,260]')
        label(prompt, '[50,292][430,350]')
        for answer, box in zip(answers, ('[50,370][230,420]', '[250,370][430,420]',
                                        '[50,430][230,480]', '[250,430][430,480]')):
            label(answer, box, 'true')
        label('Lumo Karte, Rot, Zahl 7, nicht spielbar', '[20,610][116,744]', 'true')
        label('Ziehen', '[340,520][430,570]', 'true')
        label('Blau', '[250,550][300,580]')
        self.check.latest_root = root
        return root

    def test_all_twenty_real_letter_instructions_remain_explicitly_unverified(self):
        for letter in 'ABCDEFGHIJKLMNOPQRST':
            with self.subTest(letter=letter):
                root = self.fixture(f'Finde den Buchstaben {letter}.')
                original = ET.tostring(root)
                self.check.learning_answer(root)
                self.assertEqual(ET.tostring(root), original)
                self.assertEqual(self.records[-2][0], 'visible_unverified_answer')
                self.assertFalse(self.records[-2][1]['verified'])
                self.assertEqual(self.touches[-1], (140, 395))
        self.assertEqual(self.check.verified_answers, 0)
        self.assertEqual(self.check.unverified_answers, 20)

    def test_visible_arithmetic_still_taps_only_the_computed_answer(self):
        root = self.fixture('Was ist 3 + 4?', ('6', '7', '8', '9'))
        self.check.learning_answer(root)
        self.assertEqual(self.check.verified_answers, 1)
        self.assertEqual(self.check.unverified_answers, 0)
        self.assertEqual(self.touches, [(340, 395)])
        self.assertEqual(self.records[-2][1]['expected'], '7')

    def test_unsupported_instruction_without_opt_in_never_taps(self):
        self.check.allow_unverified = False
        with self.assertRaisesRegex(RuntimeError, 'Unsupported visible question'):
            self.check.learning_answer(self.fixture())
        self.assertEqual(self.touches, [])

    def test_ambiguous_or_absent_heading_never_taps(self):
        for duplicate in (False, True):
            with self.subTest(duplicate=duplicate):
                root = self.fixture()
                if duplicate:
                    ET.SubElement(root[0], 'node', {'content-desc': 'Denkpause',
                                                  'bounds': '[50,200][300,230]'})
                else:
                    root[0].remove(root[0][0])
                with self.assertRaisesRegex(RuntimeError, 'learning heading'):
                    self.check.learning_answer(root)
        self.assertEqual(self.touches, [])

    def test_ambiguous_prompt_strip_never_guesses(self):
        root = self.fixture()
        ET.SubElement(root[0], 'node', {'content-desc': 'Noch ein sichtbarer Satz.',
                                      'bounds': '[50,352][430,365]'})
        with self.assertRaisesRegex(RuntimeError, 'uniquely identify'):
            self.check.learning_answer(root)
        self.assertEqual(self.touches, [])

    def test_disabled_or_hidden_prompt_ancestor_never_counts_as_visible(self):
        for attribute in ('enabled', 'visible-to-user'):
            with self.subTest(attribute=attribute):
                root = self.fixture()
                panel, prompt = root[0], root[0][2]
                panel.remove(prompt)
                wrapper = ET.SubElement(panel, 'node', {attribute: 'false',
                                                       'bounds': '[50,290][430,355]'})
                wrapper.append(prompt)
                with self.assertRaisesRegex(RuntimeError, 'uniquely identify'):
                    self.check.learning_answer(root)
        self.assertEqual(self.touches, [])


if __name__ == '__main__':
    unittest.main()
