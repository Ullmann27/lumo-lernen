"""Storage-reader regressions; fictional fixtures are never Android evidence."""
import ast
import copy
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '.github/probes/lumo_education_android_probe.py'


class PilotStorageTest(unittest.TestCase):
    def setUp(self):
        helpers = [n for n in ast.parse(SOURCE.read_text()).body
                   if isinstance(n, ast.FunctionDef) and n.name == '_verify_pilot_storage']
        scope = {'json': json}
        exec(compile(ast.Module(body=helpers, type_ignores=[]), str(SOURCE), 'exec'), scope)
        self.verify = scope['_verify_pilot_storage']
        self.profile = 'fictional-a'
        self.skills = 'flutter.lumo_progress_skills::' + self.profile
        self.daily = 'flutter.lumo_progress_daily::' + self.profile
        self.last = 'flutter.lumo_progress_last::' + self.profile
        self.log = 'flutter.lumo_attempt_log_v1'
        self.before = {
            'flutter.lumo_learning_local_student_id_v1': self.profile,
            self.skills: json.dumps({'mathematik::plus bis 20': {'correct': 2}}),
            self.daily: json.dumps({'2026-10-12': 4}),
            self.last: json.dumps({'Mathematik': 'Plus bis 20'}),
            self.log: '[]', 'flutter.lumo_reward_wallet_v1': '{"stars": 3}',
            'flutter.lumo_active_profile': '{"name": "Fictional A"}',
            'flutter.lumo_progress_discovery_v1::fictional-a': '{"parentAllowed": false}',
            'flutter.lumo_progress_skills::fictional-b': '{"deutsch::silben": {"correct": 7}}',
        }
        self.record = {'skillId': 'deutsch::silben', 'subject': 'Deutsch', 'unit': 'Silben',
                       'correct': 2, 'wrong': 1, 'hintCount': 1}
        self.after = copy.deepcopy(self.before)
        self.after[self.skills] = json.dumps({
            'mathematik::plus bis 20': {'correct': 2}, 'deutsch::silben': self.record})
        self.after[self.daily] = json.dumps({'2026-10-12': 6})
        self.after[self.last] = json.dumps({'Mathematik': 'Plus bis 20', 'Deutsch': 'Silben'})
        self.after[self.log] = json.dumps([
            {'id': '1', 'sub': 'Deutsch', 'unit': 'Silben', 'ok': False, 'a': '1', 'e': '2'},
            {'id': '2', 'sub': 'Deutsch', 'unit': 'Silben', 'ok': True, 'a': '2', 'e': '2'},
            {'id': '3', 'sub': 'Deutsch', 'unit': 'Silben', 'ok': True, 'a': '3', 'e': '3'},
        ])

    def test_exact_new_subject_record_and_two_daily_answers_pass(self):
        self.assertEqual(self.verify(self.before, self.after, 'Deutsch', 'Silben'), self.record)

    def test_duplicate_counts_wrong_subject_or_hint_cannot_pass(self):
        for key, value in [('correct', 3), ('wrong', 0), ('hintCount', 2),
                           ('subject', 'Mathematik'), ('unit', 'Pflanzen')]:
            altered = copy.deepcopy(self.after)
            records = json.loads(altered[self.skills])
            records['deutsch::silben'][key] = value
            altered[self.skills] = json.dumps(records)
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.verify(self.before, altered, 'Deutsch', 'Silben')

    def test_other_profile_wallet_discovery_or_prior_math_change_fails(self):
        for key in ['flutter.lumo_progress_skills::fictional-b',
                    'flutter.lumo_reward_wallet_v1', 'flutter.lumo_active_profile',
                    'flutter.lumo_progress_discovery_v1::fictional-a']:
            altered = {**self.after, key: '{}'}
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.verify(self.before, altered, 'Deutsch', 'Silben')
        altered = copy.deepcopy(self.after)
        records = json.loads(altered[self.skills])
        records['mathematik::plus bis 20']['correct'] = 0
        altered[self.skills] = json.dumps(records)
        with self.assertRaises(RuntimeError):
            self.verify(self.before, altered, 'Deutsch', 'Silben')

    def test_missing_daily_duplicate_attempt_or_changed_old_subject_fails(self):
        for key, raw in [(self.daily, self.before[self.daily]),
                         (self.log, self.after[self.log].replace('"3"', '"2"')),
                         (self.last, '{"Deutsch": "Silben"}')]:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.verify(self.before, {**self.after, key: raw}, 'Deutsch', 'Silben')


if __name__ == '__main__':
    unittest.main()
