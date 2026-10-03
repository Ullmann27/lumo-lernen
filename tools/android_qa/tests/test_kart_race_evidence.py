"""Reject a result-only claim of a full race; inspect captured HUD text."""
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_android_race import race_state, second_round_in_progress, require_second_round


def frame(*captions):
    return {'lines': [{'text': text} for text in captions]}


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


if __name__ == '__main__':
    unittest.main()
