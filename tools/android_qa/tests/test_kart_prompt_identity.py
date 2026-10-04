"""Regression cases from run 37171778921; no new OCR or Android input."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_android_race import answer_for, lesson_closed_or_changed, prompt_for


def observed(raw, cropped=None, options=('2', '8', '5')):
    prompt = {'text': raw, 'left': 135, 'top': 154, 'width': 57, 'height': 12}
    frame = {'height': 480, 'lines': [
        {'text': 'LERN-BOOST - 1. KLASSE - Mathematik', 'top': 120, 'height': 12}, prompt],
        'prompt_box': {'left': 133, 'top': 141, 'width': 488, 'height': 32},
        'words': [], 'option_words': [
            {'text': value, 'left': 210+i*164, 'top': 190, 'width': 6, 'height': 9}
            for i, value in enumerate(options)]}
    if cropped is not None:
        frame['lesson_prompt'] = dict(prompt, text=cropped)
        frame['lines'].append(frame['lesson_prompt'])
    return frame


class PromptIdentityTests(unittest.TestCase):
    def test_real_seven_minus_two_not_spurious_twenty_two(self):
        frame = observed('7-2=?', '7-22?')
        self.assertEqual(prompt_for(frame), '7−2')
        self.assertEqual(answer_for(frame)['expected'], 5)

    def test_real_three_minus_three_not_spurious_thirty_five(self):
        frame = observed('3-3=?', '3-35?', ('2', '0'))
        self.assertEqual(prompt_for(frame), '3−3')
        self.assertEqual(answer_for(frame)['expected'], 0)

    def test_changed_prompt_does_not_require_an_answer_button(self):
        frame = observed('3-3=?', options=())
        self.assertIsNone(answer_for(frame))
        self.assertTrue(lesson_closed_or_changed(frame, '7−2'))

    def test_skipped_original_can_be_identified_without_answer_buttons(self):
        self.assertEqual(prompt_for(observed('7-2=?', options=())), '7−2')

    def test_same_task_with_different_spacing_is_not_a_transition(self):
        self.assertFalse(lesson_closed_or_changed(observed('7 - 2 = ?'), '7−2=?'))

    def test_equal_result_does_not_make_different_tasks_identical(self):
        self.assertTrue(lesson_closed_or_changed(observed('3+2=?'), '7−2=?'))

    def test_two_conflicting_explicit_readings_are_rejected(self):
        frame = observed('7-2=?', '7-3=?')
        self.assertIsNone(prompt_for(frame))
        self.assertIsNone(answer_for(frame))

    def test_no_prior_prompt_cannot_prove_change_behind_a_visible_lesson(self):
        self.assertFalse(lesson_closed_or_changed(observed('3-3=?'), None))

    def test_malformed_task_does_not_prove_change(self):
        self.assertFalse(lesson_closed_or_changed(observed('Zähle weiter 7 und 2'), '3−3'))

    def test_unreadable_options_still_block_a_correct_answer_action(self):
        self.assertIsNone(answer_for(observed('7-2=?', '7-22?', ('2', '8'))))

    def test_optional_equals_fallback_remains_supported(self):
        self.assertEqual(answer_for(observed('7+1', options=('8',)))['expected'], 8)

    def test_prompt_outside_actual_question_box_is_ignored(self):
        frame = observed('7-2=?')
        frame['lines'].append({'text': '3+3=?', 'top': 250, 'height': 12})
        self.assertEqual(prompt_for(frame), '7−2')


if __name__ == '__main__':
    unittest.main()
