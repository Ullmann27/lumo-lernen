"""Read-only parser/target regressions; these are never Android usage proof."""
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from android_ui import Android
from cards_android_round import CardsRound, arithmetic, described_cards, is_result
from flutter_flows import FlutterChecks, profile_from_labels, visible_text_lines, wallet_from_labels
from memory_android_round import Round, cards, has_caption, labels, result_scores


class VisibleUiTests(unittest.TestCase):
    def test_shared_pause_caption_is_an_exact_visible_line_not_a_substring(self):
        # Captured from the current LumoGamePauseScope widget semantics tree:
        # the Card merges its two Text children; buttons keep separate labels.
        root = ET.fromstring('''<hierarchy><node
            content-desc="Spiel pausiert&#10;Dein aktueller Zug wartet auf dich.">
            <node content-desc="Fortsetzen" clickable="true" bounds="[80,400][640,490]"/>
            <node content-desc="Zur Spieleauswahl" clickable="true" bounds="[80,590][640,690]"/>
            </node></hierarchy>''')
        original = ET.tostring(root)
        self.assertNotIn('Spiel pausiert', labels(root))
        self.assertTrue(has_caption(root, 'Spiel pausiert'))
        self.assertTrue(has_caption(root, 'Fortsetzen'))
        self.assertFalse(has_caption(root, 'pausiert'))
        self.assertFalse(has_caption(ET.fromstring(
            '<hierarchy><node content-desc="Nicht Spiel pausiert"/></hierarchy>'), 'Spiel pausiert'))
        self.assertEqual(ET.tostring(root), original)

    def test_memory_back_background_resume_accepts_actual_merged_pause_caption(self):
        self._merged_pause_flow(cards_game=False)

    def test_cards_back_resume_accepts_actual_merged_pause_caption(self):
        self._merged_pause_flow(cards_game=True)

    def _merged_pause_flow(self, cards_game):
        def screen(children):
            return ET.fromstring('<hierarchy><node bounds="[0,0][720,1280]">'
                                 + children + '</node></hierarchy>')
        pause = screen('''<node content-desc="Spiel pausiert&#10;Dein aktueller Zug wartet auf dich."
            bounds="[40,300][680,800]">
            <node content-desc="Fortsetzen" clickable="true" bounds="[80,400][640,490]"/>
            <node content-desc="Zur Spieleauswahl" clickable="true" bounds="[80,590][640,690]"/>
            </node>''')
        board = screen('''<node content-desc="Lumo Karte, Rot, Zahl 7, spielbar" bounds="[40,700][200,900]"/>
                           <node content-desc="Ziehen" clickable="true" bounds="[80,1000][320,1100]"/>'''
                       if cards_game else '''<node content-desc="Memory Karte 1, verdeckt&#10;?"
                           bounds="[40,200][200,360]"/><node content-desc="Du bist dran! Tipp 2 Karten."/>''')
        result = screen('<node content-desc="' + ('Nochmal' if cards_game else 'Nochmal!')
                        + '" clickable="true" bounds="[80,400][640,490]"/>')
        games = screen('<node content-desc="Lumo Spielewelt"/>')
        events, touches, keys = [], [], []
        device = types.SimpleNamespace(bounds=Android.bounds,
                                       tap=lambda x, y: touches.append((x, y)),
                                       key=lambda *args: keys.append(args),
                                       foreground=lambda package: keys.append(('foreground', package)))
        with tempfile.TemporaryDirectory() as directory, patch('memory_android_round.time.sleep'):
            check = (CardsRound(device, Path(directory), timeout=1, allow_unverified=True)
                     if cards_game else Round(device, Path(directory), timeout=1))
            frames = iter([board, pause, board, pause, games] if cards_game
                          else [board, pause, board, pause, board, pause, games])
            def frame(name):
                check.latest_root = next(frames)
                return check.latest_root
            check.frame = frame
            check.screenshot = lambda name: None
            check.record = lambda event, **values: events.append(event)
            if cards_game:
                check.after_result(result)
            else:
                check.after_result(result, 'example', background=True)
        self.assertIn('cards_back_resume_verified' if cards_game else 'android_back_resume_verified', events)
        self.assertIn('cards_return_verified' if cards_game else 'return_to_games_verified', events)
        self.assertEqual(touches.count((360, 445)), 2 if cards_game else 3)
        self.assertEqual(touches[-1], (360, 640))
        if not cards_game:
            self.assertIn('background_resume_verified', events)
            self.assertIn(('foreground', 'example'), keys)

    def test_actual_api35_merged_profile_preserves_original_xml_and_touch_bounds(self):
        fixture = Path(__file__).parent/'fixtures/home-api35-37111452558.xml'
        root = ET.parse(fixture).getroot()
        original = ET.tostring(root)
        raw = labels(root)
        self.assertIn('Hallo, Kind!\nDein Lumo-Tag · 1. Klasse', raw)
        self.assertEqual(profile_from_labels(raw),
                         {'Hallo, Kind!', 'Dein Lumo-Tag · 1. Klasse'})
        checker = FlutterChecks(types.SimpleNamespace(bounds=Android.bounds), Path('.'), 'example')
        self.assertEqual(checker.targets(root, 'Spielen', contains=True), [(32, 638, 688, 814)])
        self.assertEqual(ET.tostring(root), original)
        self.assertIn('Hallo, Kind!\nDein Lumo-Tag · 1. Klasse', labels(root))

    def test_all_home_wallet_fields_can_share_one_visible_semantics_caption(self):
        # Field text/units come from _ProgressCard in home_content.dart. This
        # case exercises merging; it is not an Android wallet screenshot claim.
        value = wallet_from_labels(['27 Sterne\nLevel 2\n1 Lerntag in Folge\n'
                                    'Heute: 2 von 5 Aufgaben\n7 / 400 XP bis Level 3'])
        self.assertEqual(value, {'stars': 27, 'xp': 407, 'level': 2,
                                 'daily_completed': 2, 'daily_goal': 5})

    def test_missing_or_conflicting_merged_profile_and_wallet_still_fail(self):
        for values in (['Hallo, Kind!'], ['Hallo, Kind!\nDein Lumo-Tag · 1. Klasse\nDein Lumo-Tag · 2. Klasse'],
                       ['Hallo, Kind!\nHallo, Mia!\nDein Lumo-Tag · 1. Klasse']):
            with self.subTest(values=values), self.assertRaises(ValueError):
                profile_from_labels(values)
        with self.assertRaises(ValueError):
            wallet_from_labels(['27 Sterne\n28 Sterne\nHeute: 2 von 5 Aufgaben\n7 / 400 XP bis Level 3'])

    def test_task_prompt_line_remains_visible_when_merged_with_its_subject(self):
        self.assertEqual(visible_text_lines(['Mathematik\n2 + 5 = ?']), ['Mathematik', '2 + 5 = ?'])

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

    def test_help_caption_can_be_merged_with_its_visible_decorative_emoji(self):
        root = ET.fromstring('''<hierarchy><node bounds="[0,0][720,1280]">
            <node clickable="true" content-desc="✨&#10;Lumo, hilf mir" bounds="[100,300][600,410]"/>
            </node></hierarchy>''')
        checker = FlutterChecks(types.SimpleNamespace(bounds=Android.bounds), Path('.'), 'example')
        self.assertEqual(checker.targets(root, 'Lumo, hilf mir'), [])
        self.assertEqual(checker.targets(root, 'Lumo, hilf mir', contains=True), [(100, 300, 600, 410)])

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
