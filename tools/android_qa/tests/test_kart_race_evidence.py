"""Reject a result-only claim of a full race; inspect captured HUD text."""
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_android_race import (race_state, second_round_in_progress, require_second_round,
                              wait_for_frame, marker, restart_visible, local_hint_visible,
                              lesson_closed_or_changed)


def frame(*captions):
    return {'lines': [{'text': text} for text in captions], 'text': '\n'.join(captions)}


class KartRaceEvidenceTests(unittest.TestCase):
    def test_real_desktop_ocr_round_one_cannot_prove_round_two(self):
        # Actual read_frame output of docs/screenshots/sonnenhafen-learning.png.
        observed = frame('RUNDE1/2 -', 'PLATZ 6/6', '- Okm/h',
                         'LERN-BOOST - 1. KLASSE - Mathematik')
        self.assertEqual(race_state(observed), {'round': [1, 2], 'place': [6, 6]})
        self.assertFalse(second_round_in_progress(observed))

    def test_combined_hud_round_two_is_read_without_using_speed_or_crystals(self):
        observed = frame('RUNDE 2 / 2 · PLATZ 4 / 6 · 58 km/h · ◆ 9')
        self.assertEqual(race_state(observed), {'round': [2, 2], 'place': [4, 6]})
        self.assertTrue(second_round_in_progress(observed))

    def test_result_hud_round_two_is_insufficient_even_when_button_ocr_fails(self):
        result = frame('RUNDE2/2', 'PLATZ6/6', 'Sonnenhafen-Cup geschafft!')
        self.assertFalse(second_round_in_progress(result))
        with self.assertRaisesRegex(RuntimeError, 'before the result screen'):
            require_second_round(None)
        self.assertFalse(second_round_in_progress(frame('RUNDE2/2', 'PLATZ6/6', 'Noch ein Rennen')))

    def test_unreadable_or_inconsistent_hud_does_not_prove_the_required_round(self):
        for observed in [frame('RUNDE2/2'), frame('RUNDE2/3', 'PLATZ4/6'),
                         frame('RUNDE?/2', 'PLATZ4/6'), frame('PLATZ4/6')]:
            with self.subTest(frame=observed):
                self.assertFalse(second_round_in_progress(observed))

    def test_success_keeps_reference_to_the_actual_prior_capture(self):
        require_second_round(23)


class KartTransitionEvidenceTests(unittest.TestCase):
    def test_stale_hud_frames_are_retained_until_pause_is_actually_visible(self):
        observations = [frame('RUNDE 1/2', '0 km/h', '4'),
                        frame('RUNDE 1/2', '0 km/h', '3'),
                        frame('RUNDE 1/2', 'Kleine Pause im Sonnenhafen', 'Weiterfahren')]
        captured = []
        now = [0.0]
        def capture(label):
            observed = observations[len(captured)]
            captured.append((label, observed))
            now[0] += 1.4  # Realistic slow render/OCR observations, not game time.
            return observed
        result = wait_for_frame(capture, 'android-back-pause',
                                lambda observed: bool(marker(observed, 'Weiterfahren')),
                                'Android Back did not open the Godot pause screen.',
                                clock=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0]+seconds))
        self.assertIs(result, observations[2])
        self.assertEqual([observed for _, observed in captured], observations)
        self.assertGreater(now[0], 2)

    def test_stale_hud_alone_times_out_and_keeps_its_actual_ocr_in_failure(self):
        stale = frame('RUNDE 1/2', '0 km/h', '3')
        now = [0.0]
        captured = []
        def capture(label):
            captured.append(label)
            now[0] += 1
            return stale
        with self.assertRaisesRegex(RuntimeError, 'pause screen.*within 3s.*RUNDE'):
            wait_for_frame(capture, 'android-back-pause',
                           lambda observed: bool(marker(observed, 'Weiterfahren')),
                           'Android Back did not open the Godot pause screen.', timeout=3,
                           clock=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0]+seconds))
        self.assertGreater(len(captured), 1)
        self.assertEqual(now[0], 3)

    def test_one_capture_over_the_deadline_cannot_turn_into_late_success(self):
        now = [0.0]
        def slow_capture(_):
            now[0] = 31
            return frame('Weiterfahren')
        with self.assertRaisesRegex(RuntimeError, 'within 30s'):
            wait_for_frame(slow_capture, 'android-back-pause',
                           lambda observed: bool(marker(observed, 'Weiterfahren')),
                           'Pause did not appear.', clock=lambda: now[0], sleep=lambda _: None)

    def test_restart_requires_round_one_and_cannot_accept_stale_result_or_hud(self):
        self.assertFalse(restart_visible(frame('RUNDE 2/2', 'PLATZ 1/6', 'Noch ein Rennen')))
        self.assertFalse(restart_visible(frame('RUNDE 2/2', 'PLATZ 1/6')))
        self.assertFalse(restart_visible(frame('RUNDE 1/2', 'PLATZ 1/6', 'Weiterfahren')))
        self.assertTrue(restart_visible(frame('RUNDE 1/2', 'PLATZ 1/6', '3')))

    def test_hint_must_replace_the_waiting_caption_while_the_lesson_remains(self):
        original = {'height': 720, 'lines': [{'text': 'LERN-BOOST', 'top': 160},
                    {'text': 'Alle Karts warten. Nimm dir Zeit.', 'top': 290}]}
        explanation = {'height': 720, 'lines': [{'text': 'LERN-BOOST', 'top': 160},
                       {'text': 'Zähle die beiden Gruppen gemeinsam.', 'top': 290}]}
        self.assertFalse(local_hint_visible(original))
        self.assertTrue(local_hint_visible(explanation))
        self.assertFalse(local_hint_visible(frame('RUNDE 1/2')))

    def test_answer_transition_requires_a_real_hud_after_the_lesson_disappears(self):
        self.assertFalse(lesson_closed_or_changed(frame('unreadable frame')))
        self.assertFalse(lesson_closed_or_changed(frame('RUNDE 1/2', 'Weiterfahren')))
        self.assertTrue(lesson_closed_or_changed(frame('RUNDE 1/2', 'PLATZ 1/6')))


if __name__ == '__main__':
    unittest.main()
