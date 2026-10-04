"""Incomplete OCR may defer a hint check, never remove its final requirement."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_android_race import require_learning_evidence, wrong_option_for


class LearningEvidenceTests(unittest.TestCase):
    def test_correct_only_option_cannot_be_guessed_into_a_wrong_answer(self):
        answer = {'expected': 9, 'options': [{'text': '9', 'left': 373, 'top': 214}]}
        self.assertIsNone(wrong_option_for(answer))

    def test_only_an_actually_read_different_option_is_selected(self):
        correct = {'text': '9', 'left': 373, 'top': 214}
        wrong = {'text': '8', 'left': 210, 'top': 214}
        self.assertIs(wrong_option_for({'expected': 9, 'options': [correct, wrong]}), wrong)

    def test_finished_race_and_correct_answers_do_not_replace_missing_hint(self):
        with self.assertRaisesRegex(RuntimeError, 'wrong-answer/local-hint'):
            require_learning_evidence(5, False, require_correct=True, check_wrong_hint=True)

    def test_hint_alone_does_not_replace_a_correct_answer(self):
        with self.assertRaisesRegex(RuntimeError, 'actual maths answer'):
            require_learning_evidence(0, True, require_correct=True, check_wrong_hint=True)

    def test_both_independent_interactions_satisfy_the_existing_full_gate(self):
        require_learning_evidence(2, True, require_correct=True, check_wrong_hint=True)

    def test_explicit_non_hint_mode_does_not_change_correct_answer_gate(self):
        require_learning_evidence(1, False, require_correct=True, check_wrong_hint=False)
        with self.assertRaises(RuntimeError):
            require_learning_evidence(0, False, require_correct=True, check_wrong_hint=False)


if __name__ == '__main__':
    unittest.main()
