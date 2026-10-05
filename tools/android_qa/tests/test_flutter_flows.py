"""Read-only parser/target regressions; these are never Android usage proof."""
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from android_ui import Android, content_scroll_gesture
from cards_android_round import CardsRound, arithmetic, described_cards, is_result
from flutter_flows import (FlutterChecks, LEARNING_SELECTION_CAPTION, addition_prompt_from_labels,
                           apple_help_from_labels, profile_from_labels, visible_text_lines,
                           wallet_from_labels)
from memory_android_round import Round, cards, has_caption, labels, result_scores


class VisibleUiTests(unittest.TestCase):
    def test_actual_akademie_plus_module_path_requires_help_answer_and_daily_reward(self):
        source = Path(__file__).resolve().parents[3]/'lib'
        shell = (source/'app/app_shell.dart').read_text()
        akademie = (source/'features/teacher_mode/lumo_akademie_screen.dart').read_text()
        registry = (source/'features/learning_modules/learning_module_registry.dart').read_text()
        module = (source/'features/learning_modules/plus_bis_10/plus_bis_10_screen.dart').read_text()
        self.assertRegex(shell, r'return LumoAkademieScreen\(\s*appState: _appState')
        self.assertIn(LEARNING_SELECTION_CAPTION, akademie)
        self.assertIn("id: 'm1_plus10'", akademie)
        self.assertIn('return PlusBis10Screen(appState: appState)', registry)
        self.assertIn("'Zähle alle Äpfel zusammen:", module)
        root = ET.fromstring('''<hierarchy><node bounds="[0,0][480,800]">
            <node content-desc="Aufgabe 1 / 30&#10;Plus bis 10" bounds="[60,30][410,80]"/>
            <node content-desc="2 + 5 = ?" bounds="[30,100][450,230]"/>
            <node content-desc="Ein Tipp!&#10;Zähle alle Äpfel zusammen: 🍎🍎 und 🍏🍏🍏🍏🍏"
                bounds="[30,260][450,360]"/>
            <node content-desc="7" clickable="true" bounds="[30,450][225,560]"/>
            <node content-desc="6" clickable="true" bounds="[240,450][450,560]"/>
            <node content-desc="8" clickable="true" bounds="[30,575][225,685]"/>
            <node content-desc="5" clickable="true" bounds="[240,575][450,685]"/>
            </node></hierarchy>''')
        device = types.SimpleNamespace(key=lambda *args: keys.append(args), capture=lambda name: None)
        calls, keys = [], []
        check = FlutterChecks(device, Path('.'), 'example')
        check.top = lambda: None
        check.click = lambda caption, **kwargs: calls.append((caption, kwargs))
        check.wait = lambda caption, **kwargs: root
        check.frame = lambda name: root
        check.targets = lambda screen, caption, **kwargs: [(1, 1, 3, 3)] if caption in {'5', '6', '7', '8'} else []
        check.record = lambda *args, **kwargs: None
        before = {'stars': 9, 'xp': 18, 'daily_completed': 0}
        after = {'stars': 10, 'xp': 23, 'daily_completed': 1}
        values = iter([before, after])
        check.wallet = lambda name: next(values)
        with patch('flutter_flows.time.sleep'):
            check.learning()
        self.assertEqual([caption for caption, _ in calls],
                         ['Lernen', '1. Klasse', 'Mathe', 'Plus bis 10', '5', '5', '7'])
        self.assertTrue(calls[1][1]['contains'])
        self.assertTrue(calls[2][1]['contains'])
        self.assertTrue(calls[3][1]['contains'])
        self.assertEqual(keys, [('4', 'KEY_BACK')])
        self.assertEqual(check.proof['learning']['wrong_answers'], ['5', '5'])
        self.assertEqual(check.proof['learning']['wallet_after']['daily_completed'], 1)
        values = iter([before, dict(after, daily_completed=0)])
        check.wallet = lambda name: next(values)
        with patch('flutter_flows.time.sleep'), self.assertRaises(RuntimeError):
            check.learning()

    def test_local_apple_help_must_match_unique_visible_plus_task(self):
        self.assertEqual(addition_prompt_from_labels(['Plus bis 10\n2 + 5 = ?']), '2 + 5 = ?')
        hint = 'Zähle alle Äpfel zusammen: 🍎🍎 und 🍏🍏🍏🍏🍏'
        self.assertEqual(apple_help_from_labels(['Ein Tipp!\n'+hint], '2 + 5 = ?'), hint)
        for values in (['2 + 5 = ?', '3 + 4 = ?'], ['9 + 8 = ?'], ['Keine Frage']):
            with self.subTest(values=values), self.assertRaises(ValueError):
                addition_prompt_from_labels(values)
        for values in (['Lumo erklärt'], [hint+' Text'], ['Zähle alle Äpfel zusammen: 🍎 und 🍏']):
            with self.subTest(values=values), self.assertRaises(ValueError):
                apple_help_from_labels(values, '2 + 5 = ?')

    def test_real_home_scroll_stays_inside_content_above_companion(self):
        root = ET.parse(Path(__file__).parent/'fixtures/home-api35-37111452558.xml').getroot()
        gesture = content_scroll_gesture(root)
        self.assertEqual(gesture['bounds'], [0, 246, 720, 874])
        self.assertTrue(246 < gesture['high'] < gesture['low'] < 874)
        self.assertTrue(0 < gesture['x'] < 720)

    def test_scroll_targets_actual_fold_viewport_and_refuses_non_scrollable_controls(self):
        root = ET.fromstring('''<hierarchy><node bounds="[0,0][1812,2176]">
            <node scrollable="true" enabled="false" bounds="[0,0][1812,2176]"/>
            <node scrollable="true" bounds="[20,500][1792,1700]"/>
            <node clickable="true" bounds="[0,1750][1812,2176]"/>
            </node></hierarchy>''')
        gesture = content_scroll_gesture(root)
        self.assertEqual(gesture['bounds'], [20, 500, 1792, 1700])
        self.assertTrue(500 < gesture['high'] < gesture['low'] < 1700)
        self.assertIsNone(content_scroll_gesture(ET.fromstring(
            '<hierarchy><node clickable="true" bounds="[0,0][720,1280]"/></hierarchy>')))

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

    def test_actual_compact_android_wallet_progress_prefix_preserves_xml_and_bounds(self):
        fixture = Path(__file__).parent/'fixtures/home-api35-37121358107.xml'
        root = ET.parse(fixture).getroot()
        original = ET.tostring(root)
        raw = labels(root)
        self.assertIn('0, 0 Sterne\nLevel 1\n0 Lerntage in Folge\n'
                      'Heute: 0 von 3 Aufgaben\n0 / 400 XP bis Level 2', raw)
        self.assertEqual(wallet_from_labels(raw), {'stars': 0, 'xp': 0, 'level': 1,
                                                   'daily_completed': 0, 'daily_goal': 3})
        checker = FlutterChecks(types.SimpleNamespace(bounds=Android.bounds), Path('.'), 'example')
        self.assertEqual(checker.targets(root, 'Spielen', contains=True), [(16, 328, 464, 416)])
        self.assertEqual(content_scroll_gesture(root)['bounds'], [0, 132, 480, 577])
        self.assertEqual(ET.tostring(root), original)

    def test_numeric_merged_progress_value_matches_actual_daily_completion(self):
        for progress, completed, goal in [(33, 1, 3), (67, 2, 3), (100, 5, 3), (13, 1, 8)]:
            with self.subTest(progress=progress):
                value = wallet_from_labels([f'{progress}, 27 Sterne', '7 / 400 XP bis Level 3',
                                            f'Heute: {completed} von {goal} Aufgaben'])
                self.assertEqual(value['stars'], 27)
                self.assertEqual(value['daily_completed'], completed)

    def test_merged_progress_prefix_never_bypasses_missing_or_ambiguous_wallet_checks(self):
        for values in (['0, 27 Sterne', '0 / 400 XP bis Level 2'],
                       ['0, 27 Sterne', 'Heute: 0 von 3 Aufgaben'],
                       ['0, 27 Sterne', '28 Sterne', '0 / 400 XP bis Level 2', 'Heute: 0 von 3 Aufgaben'],
                       ['33, 27 Sterne', '0 / 400 XP bis Level 2', 'Heute: 0 von 3 Aufgaben'],
                       ['101, 27 Sterne', '0 / 400 XP bis Level 2', 'Heute: 3 von 3 Aufgaben'],
                       ['Text 0, 27 Sterne', '0 / 400 XP bis Level 2', 'Heute: 0 von 3 Aufgaben'],
                       ['0, 27 Sterne extra', '0 / 400 XP bis Level 2', 'Heute: 0 von 3 Aufgaben'],
                       ['0, 27 Sterne', '0 / 400 XP bis Level 2', 'Heute: 0 von 0 Aufgaben']):
            with self.subTest(values=values), self.assertRaises(ValueError):
                wallet_from_labels(values)

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
