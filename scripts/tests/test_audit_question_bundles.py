import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    'audit_question_bundles', Path(__file__).resolve().parents[1] / 'audit_question_bundles.py')
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class QuestionAuditTests(unittest.TestCase):
    def check(self, questions):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'fixture.json'
            path.write_text(json.dumps(questions), encoding='utf-8')
            return audit.audit_bundle(path)

    @staticmethod
    def question(**changes):
        value = {'prompt': 'Wie viel ist 2+3?', 'options': ['4', '5', '6', '7'],
                 'correctIndex': 1, 'hint': 'Zähle zwei und drei zusammen.'}
        return {**value, **changes}

    def codes(self, result):
        return {i['code'] for i in result['issues']}

    def test_wrong_answer_is_detected_independently(self):
        result = self.check([self.question(correctIndex=0)])
        self.assertIn('wrong_arithmetic_answer', self.codes(result))
        self.assertEqual(result['arithmetic_checked'], 1)

    def test_numerically_equivalent_answers_are_ambiguous(self):
        result = self.check([self.question(options=['5', '05', '6', '7'], correctIndex=0)])
        self.assertIn('ambiguous_arithmetic_answer', self.codes(result))

    def test_unicode_case_and_space_duplicates_are_detected(self):
        result = self.check([self.question(prompt='Welches Wort?',
                                          options=['Haus', ' ＨＡＵＳ ', 'Baum', 'Hund'])])
        self.assertIn('duplicate_options', self.codes(result))

    def test_boolean_answer_index_is_rejected(self):
        result = self.check([self.question(correctIndex=True)])
        self.assertIn('invalid_answer_index', self.codes(result))

    def test_duplicate_question_ignores_distractor_order(self):
        result = self.check([self.question(), self.question(options=['7', '6', '5', '4'], correctIndex=2)])
        self.assertIn('duplicate_question', self.codes(result))

    def test_unknown_language_question_is_explicitly_unreviewed(self):
        result = self.check([self.question(prompt='Was reimt sich auf Haus?')])
        self.assertEqual(result['arithmetic_checked'], 0)
        self.assertEqual(result['manual_review'], [1])
        self.assertIn('curriculumSource', result['metadata_not_complete'])

    def test_missing_or_invalid_input_cannot_pass(self):
        with tempfile.TemporaryDirectory() as folder:
            self.assertEqual(audit.audit_directory(Path(folder))['status'], 'issues_found')
            path = Path(folder) / 'bad.json'
            path.write_text('not json', encoding='utf-8')
            self.assertIn('unreadable_bundle', self.codes(audit.audit_bundle(path)))

    def test_arithmetic_operators_and_unrecognised_prompts(self):
        for prompt, expected in [('Was ist 8−3?', 5), ('Wie viel ist 2 mal 3?', 6),
                                 ('Wie viel ist 12÷3?', 4), ('Was ist 3·4?', 12)]:
            with self.subTest(prompt=prompt):
                self.assertEqual(audit.arithmetic_answer(prompt), expected)
        self.assertIsNone(audit.arithmetic_answer('Lisa hat 3 Äpfel und bekommt 4.'))


if __name__ == '__main__':
    unittest.main()
