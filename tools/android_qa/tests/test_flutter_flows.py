"""Read-only parser/target regressions; these are never Android usage proof."""
from pathlib import Path
import sys
import tempfile
import types
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from android_ui import Android
from cards_android_round import CardsRound, arithmetic, described_cards, is_result
from flutter_flows import FlutterChecks, wallet_from_labels
from memory_android_round import cards, result_scores


class VisibleUiTests(unittest.TestCase):
    def test_wallet_reconstructs_xp_and_daily_progress_across_level_boundary(self):
        value = wallet_from_labels(['27 Sterne', '7 / 400 XP bis Level 3',
                                    'Heute: 2 von 5 Aufgaben', '27'])
        self.assertEqual(value, {'stars': 27, 'xp': 407, 'level': 2,
                                 'daily_completed': 2, 'daily_goal': 5})

    def test_wallet_rejects_missing_ambiguous_or_invalid_actual_captions(self):
        for values in (['27'], ['27 Sterne', '29 Sterne', '0 / 400 XP bis Level 2',
                                'Heute: 0 von 5 Aufgaben'],
                       ['27 Sterne', '401 / 400 XP bis Level 2', 'Heute: 0 von 5 Aufgaben'],
                       ['27 Sterne', '0 / 400 XP bis Level 1', 'Heute: 0 von 5 Aufgaben'],
                       ['+27 Sterne', '0 / 400 XP bis Level 2', 'Heute: 0 von 5 Aufgaben']):
            with self.subTest(values=values), self.assertRaises(ValueError):
                wallet_from_labels(values)

    def test_target_requires_actionable_ancestor_and_clips_current_display(self):
        root = ET.fromstring('''<hierarchy><node bounds="[0,0][904,2316]">
            <node clickable="false" content-desc="7" bounds="[10,10][50,50]"/>
            <node clickable="true" bounds="[-20,1300][240,1410]">
                <node content-desc="Lernen" bounds="[0,1320][200,1380]"/>
            </node></node></hierarchy>''')
        checker = FlutterChecks(types.SimpleNamespace(bounds=Android.bounds), Path('.'), 'example')
        self.assertEqual(checker.targets(root, '7'), [])
        self.assertEqual(checker.targets(root, 'Lernen'), [(0, 1300, 240, 1410)])

    def test_only_observed_memory_faces_are_available_to_solver(self):
        root = ET.fromstring('''<hierarchy>
            <node content-desc="Memory Karte 1, verdeckt&#10;?"/>
            <node content-desc="Memory Karte 2, 🦊&#10;🦊"/>
            <node content-desc="Du: 8 Paare    Lumo: 4 Paare"/>
            </hierarchy>''')
        self.assertIsNone(cards(root)[1].symbol)
        self.assertEqual(cards(root)[2].symbol, '🦊')
        self.assertEqual(result_scores(root), (8, 4))

    def test_cards_uses_visible_face_labels_and_complete_result_controls(self):
        root = ET.fromstring('''<hierarchy>
            <node content-desc="Verdeckt"/>
            <node content-desc="Lumo Karte, Rot, Zahl 7, spielbar"/>
            <node content-desc="Lumo gewinnt diesmal!"/>
            <node content-desc="Nochmal"/><node content-desc="Zurueck"/>
            </hierarchy>''')
        self.assertEqual(len(described_cards(root)), 1)
        self.assertTrue(is_result(root))
        self.assertFalse(is_result(ET.fromstring('<hierarchy><node content-desc="Nochmal"/></hierarchy>')))

    def test_arithmetic_is_computed_from_supported_visible_question_only(self):
        for prompt, expected in [('2 + 5 = ?', '7'), ('9 − 4 = ?', '5'),
                                 ('3 × 4 = ?', '12'), ('24 : 6 = ?', '4'),
                                 ('24 : 0 = ?', None), ('24 : 5 = ?', None),
                                 ('Was ist die Mehrzahl von Hund?', None)]:
            with self.subTest(prompt=prompt):
                self.assertEqual(arithmetic(prompt), expected)

    def test_visible_non_arithmetic_answer_never_counts_as_verified_math(self):
        root = ET.fromstring('''<hierarchy>
            <node content-desc="Denkpause" bounds="[100,100][400,150]"/>
            <node content-desc="Was ist die Mehrzahl von Hund?" bounds="[100,170][600,230]"/>
            <node content-desc="Hunde" clickable="true" bounds="[100,250][330,320]"/>
            <node text="Hund" clickable="true" bounds="[350,250][580,320]"/>
            </hierarchy>''')
        events, touches = [], []
        with tempfile.TemporaryDirectory() as directory:
            check = CardsRound(types.SimpleNamespace(bounds=Android.bounds),
                               Path(directory), timeout=1, allow_unverified=True)
            check.record = lambda event, **values: events.append((event, values))
            check.tap_node = lambda node, reason: touches.append(node)
            check.learning_answer(root)
        self.assertEqual(check.verified_answers, 0)
        self.assertEqual(check.unverified_answers, 1)
        self.assertEqual([event for event, _ in events], ['visible_unverified_answer'])
        self.assertFalse(events[0][1]['verified'])
        self.assertEqual(len(touches), 1)
        self.assertEqual(touches[0].attrib['content-desc'], 'Hunde')


if __name__ == '__main__':
    unittest.main()
