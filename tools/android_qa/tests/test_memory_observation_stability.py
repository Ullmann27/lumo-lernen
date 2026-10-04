"""Actual XML parser regressions; mocked touches are not Android round proof."""
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from android_ui import Android
from memory_android_round import Round, cards, scoreboard_scores, settled_child_board


FIXTURES = Path(__file__).parent/'fixtures/memory-37132721782'


def captured(name):
    return ET.parse(FIXTURES/name).getroot()


class StopAfterReobserve(Exception):
    pass


class MemoryObservationTests(unittest.TestCase):
    def check(self, dumps=()):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.events, self.touches, self.swipes = [], [], []
        frames = iter(dumps)
        device = types.SimpleNamespace(bounds=Android.bounds,
            dump=lambda: next(frames), tap=lambda x, y: self.touches.append((x, y)),
            swipe=lambda *args: self.swipes.append(args))
        check = Round(device, Path(directory.name), timeout=60)
        check.record = lambda event, **data: self.events.append((event, data))
        check.screenshot = lambda name: self.events.append(('screenshot', {'name': name}))
        return check

    def test_actual_mixed_child_footer_does_not_make_temporary_button_faces_matched(self):
        mixed = captured('016-board.xml')
        self.assertEqual(scoreboard_scores(mixed), (0, 2))
        self.assertEqual(cards(mixed)[9].symbol, '🦊')
        self.assertFalse(cards(mixed)[9].is_matched)
        self.assertIsNone(settled_child_board(mixed))
        settled = captured('017-first-card-revealed.xml')
        self.assertEqual(scoreboard_scores(settled), (0, 6))
        self.assertTrue(cards(settled)[10].is_matched)
        self.assertIsNotNone(settled_child_board(settled))
        pending = captured('018-board.xml')
        self.assertFalse(cards(pending)[13].is_matched)
        self.assertIsNone(settled_child_board(pending))

    def test_ready_requires_two_identical_settled_snapshots_after_actual_turn_changes(self):
        frames = [captured(name) for name in ('016-board.xml', '017-first-card-revealed.xml',
                  '018-board.xml', '020-first-card-revealed.xml', '021-first-card-revealed.xml')]
        check = self.check(frames)
        with patch('memory_android_round.time.sleep'):
            result = check.ready()
        self.assertIs(result, frames[-1])
        self.assertEqual(check.sequence, 5)
        self.assertEqual(scoreboard_scores(result), (0, 9))
        self.assertEqual(self.touches, [])

    def test_observation_only_remembers_matched_role_and_preserves_actual_xml(self):
        frames = [captured(name) for name in ('016-board.xml', '018-board.xml',
                                             '020-first-card-revealed.xml')]
        originals = [ET.tostring(root) for root in frames]
        check = self.check(frames)
        check.frame()
        self.assertNotIn(9, check.matched)
        check.frame()
        self.assertNotIn(13, check.matched)
        check.frame()
        self.assertIn(9, check.matched)
        self.assertIn(13, check.matched)
        self.assertEqual([ET.tostring(root) for root in frames], originals)

    def test_transient_empty_semantics_is_saved_and_reobserved_without_input(self):
        blank = ET.fromstring('<hierarchy><node bounds="[0,0][480,800]"/></hierarchy>')
        actual = captured('001-initial-memory.xml')
        check = self.check([blank, actual])
        with patch('memory_android_round.time.sleep'):
            root = check.frame('after-transition')
        self.assertIs(root, actual)
        self.assertEqual(check.sequence, 2)
        self.assertTrue((check.out/'001-after-transition.xml').is_file())
        self.assertTrue((check.out/'002-after-transition.xml').is_file())
        self.assertIn('await_visible_android_content', [event for event, _ in self.events])
        self.assertEqual(self.touches, [])
        self.assertEqual(self.swipes, [])

    def test_opponent_matched_face_cannot_confirm_own_first_tap_or_trigger_second(self):
        initial = captured('001-initial-memory.xml')
        changed = captured('017-first-card-revealed.xml')
        check = self.check([initial, changed])
        check.verify_grid_extremes = lambda root: root
        calls = 0
        def ready():
            nonlocal calls
            calls += 1
            if calls == 1:
                return initial
            raise StopAfterReobserve()
        check.ready = ready
        with patch('memory_android_round.time.sleep'), self.assertRaises(StopAfterReobserve):
            check.play()
        self.assertEqual(self.touches, [(64, 258)])
        self.assertIn('first_touch_unconfirmed_board_changed', [event for event, _ in self.events])
        self.assertFalse(any('second card' in data.get('reason', '') for _, data in self.events))

    def test_unchanged_unresponsive_first_tap_still_fails_without_silent_retry(self):
        initial = captured('001-initial-memory.xml')
        check = self.check([initial]*5)
        check.verify_grid_extremes = lambda root: root
        check.ready = lambda: initial
        with patch('memory_android_round.time.sleep'), self.assertRaisesRegex(
                RuntimeError, 'First real card tap was not observed'):
            check.play()
        self.assertEqual(len(self.touches), 1)

    def test_fresh_grid_reachability_uses_real_swipe_directions_before_any_touch(self):
        initial = captured('001-initial-memory.xml')
        # Constructed bottom viewport only tests gesture/control selection;
        # actual bottom-row reachability is still required on Android.
        bottom = ET.fromstring('''<hierarchy><node bounds="[0,0][480,800]">
            <node scrollable="true" enabled="true" bounds="[10,204][470,716]">
                <node content-desc="Memory Karte 21, verdeckt&#10;?" class="android.widget.Button"
                    clickable="true" bounds="[10,577][119,686]"/>
                <node content-desc="Memory Karte 24, verdeckt&#10;?" class="android.widget.Button"
                    clickable="true" bounds="[361,577][470,686]"/>
            </node></node></hierarchy>''')
        check = self.check([bottom, initial])
        with patch('memory_android_round.time.sleep'):
            root = check.verify_grid_extremes(initial)
        self.assertIs(root, initial)
        self.assertEqual(len(self.swipes), 2)
        self.assertGreater(self.swipes[0][1], self.swipes[0][3])
        self.assertLess(self.swipes[1][1], self.swipes[1][3])
        extremes = [data['card'] for event, data in self.events
                    if event == 'fresh_memory_grid_extreme_reachable']
        self.assertEqual(extremes, [24, 1])
        self.assertEqual(self.touches, [])

    def test_extreme_card_outside_viewport_clipped_or_exposed_never_passes_fresh_check(self):
        for condition in ('outside', 'clipped', 'exposed'):
            with self.subTest(condition=condition):
                root = captured('001-initial-memory.xml')
                node = cards(root)[1].node
                node.set('content-desc', 'Memory Karte 24, 🦊' if condition == 'exposed'
                         else 'Memory Karte 24, verdeckt')
                if condition == 'outside':
                    node.set('bounds', '[10,710][119,819]')
                elif condition == 'clipped':
                    # Actual clipped-row geometry from the initial capture,
                    # reassigned to an extreme-card selector regression.
                    node.set('bounds', '[10,672][119,716]')
                check = self.check()
                with self.assertRaises(RuntimeError):
                    check.verify_grid_extremes(root)
                self.assertEqual(self.swipes, [])
                self.assertEqual(self.touches, [])

    def test_visible_pair_score_must_be_complete_unique_and_possible(self):
        for xml in ('<hierarchy><node content-desc="Du"/><node content-desc="0"/></hierarchy>',
                    '<hierarchy><node content-desc="Du"/><node content-desc="8"/>'
                    '<node content-desc="Lumo 🦊"/><node content-desc="5"/></hierarchy>',
                    '<hierarchy><node content-desc="Du"/><node content-desc="0"/>'
                    '<node content-desc="Du"/><node content-desc="1"/>'
                    '<node content-desc="Lumo 🦊"/><node content-desc="2"/></hierarchy>'):
            with self.subTest(xml=xml), self.assertRaises(RuntimeError):
                scoreboard_scores(ET.fromstring(xml))


if __name__ == '__main__':
    unittest.main()
