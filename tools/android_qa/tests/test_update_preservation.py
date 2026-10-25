"""An update gate must reject empty progress and a replaced installation."""
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_preservation import require_in_place_update, require_learning_preserved


class UpdatePreservationTests(unittest.TestCase):
    def setUp(self):
        self.old = {'userId': '10209', 'firstInstallTime': '2026-10-22 12:00:00',
                    'versionCode': '1997 minSdk=24 targetSdk=36'}
        self.new = dict(self.old, versionCode='1999 minSdk=24 targetSdk=36')
        self.prefs = {
            'flutter.lumo_active_profile': json.dumps(
                {'id': 'child-a', 'name': 'LumoTest', 'grade': 1, 'age': 7,
                 'createdAt': '2026-10-22', 'lastActiveAt': 'old'}),
            'flutter.lumo_progress_skills::child-a': json.dumps({
                'math-add-10': {'correct': 1, 'wrong': 0, 'subject': 'Mathematik'}}),
            'flutter.lumo_reward_wallet_v1': json.dumps({'stars': 1, 'xp': 10}),
            'flutter.lumo_journal::child-b': '[{"text":"Keep my story"}]',
        }

    def test_same_installation_with_higher_expected_version_is_accepted(self):
        report = require_in_place_update(self.old, self.new, 1999)
        self.assertEqual(report['before_version'], 1997)
        self.assertEqual(report['after_version'], 1999)

    def test_reinstall_version_reuse_and_wrong_version_are_rejected(self):
        for changes in ({'userId': '10210'}, {'firstInstallTime': 'new'},
                        {'versionCode': '1997'}, {'versionCode': '2000'},
                        {'versionCode': ''}):
            with self.subTest(changes=changes), self.assertRaises(RuntimeError):
                require_in_place_update(self.old, dict(self.new, **changes), 1999)

    def test_nonempty_learning_and_other_child_data_are_preserved(self):
        after = copy.deepcopy(self.prefs)
        profile = json.loads(after['flutter.lumo_active_profile'])
        profile['lastActiveAt'] = 'new'
        after['flutter.lumo_active_profile'] = json.dumps(profile)
        report = require_learning_preserved(self.prefs, after)
        self.assertEqual(report['learning_keys_compared'], 3)

    def test_deleted_changed_and_unearned_reward_data_are_rejected(self):
        for key in self.prefs:
            after = dict(self.prefs)
            after.pop(key)
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                require_learning_preserved(self.prefs, after)
        after = dict(self.prefs)
        after['flutter.lumo_reward_wallet_v1'] = '{"stars":2,"xp":20}'
        with self.assertRaises(RuntimeError):
            require_learning_preserved(self.prefs, after)

    def test_empty_or_zero_progress_is_never_update_evidence(self):
        for progress in ('{}', '{"math":{"correct":0,"wrong":0}}', 'null', '[]'):
            empty = dict(self.prefs)
            empty['flutter.lumo_progress_skills::child-a'] = progress
            with self.subTest(progress=progress), self.assertRaises(RuntimeError):
                require_learning_preserved(empty, empty)
        no_reward = dict(self.prefs)
        no_reward['flutter.lumo_reward_wallet_v1'] = '{"stars":0,"xp":0}'
        with self.assertRaises(RuntimeError):
            require_learning_preserved(no_reward, no_reward)


if __name__ == '__main__':
    unittest.main()
