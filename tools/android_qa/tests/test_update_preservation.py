"""An update gate must reject empty progress and a replaced installation."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_preservation import (require_in_place_update, require_learning_preserved,
                                 require_post_update_learning_preserved)

_FIXTURE = Path(__file__).parent / 'fixtures/update_2017_2018_independent_evidence.json'
_FIXTURE_SHA256 = '8815f517552ebdde7908ff98b1bb389147a4857ccb4a75cabd65e2142eb3338a'


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


class Build2018IndependentEvidenceMigrationTests(unittest.TestCase):
    def setUp(self):
        fixture = json.loads(_FIXTURE.read_text(encoding='utf-8'))
        self.metadata = fixture['metadata']
        self.before = fixture['before']
        self.after = fixture['after']
        self.key = self.metadata['skill_preference_key']
        self.skill = 'mathematik::plus bis 10'

    def require(self, after=None, before=None, versions=(2017, 2018)):
        return require_learning_preserved(
            self.before if before is None else before,
            self.after if after is None else after,
            migration_versions=versions)

    def change_record(self, field, value, *, remove=False):
        after = copy.deepcopy(self.after)
        records = json.loads(after[self.key])
        if remove:
            records[self.skill].pop(field)
        else:
            records[self.skill][field] = value
        after[self.key] = json.dumps(records)
        return after

    def test_actual_fixture_is_hash_bound_to_original_failed_android_artifact(self):
        self.assertEqual(hashlib.sha256(_FIXTURE.read_bytes()).hexdigest(), _FIXTURE_SHA256)
        self.assertEqual(self.metadata['artifact_id'], 14022392802)
        self.assertEqual(self.metadata['workflow_run_id'], 43395154888)
        self.assertEqual(self.metadata['artifact_sha256'],
                         '63e14a7e65ea4d96a1f818c938f4b61ff96c1429654e6984b3c28ee492b0c6fa')
        self.assertEqual(self.metadata['xml_sha256'], {
            'before': '54755eb54ad0456c77ff6fcf213372c5ffee0263f197b4d83ce228d5ef19f5b0',
            'after': '7dd2cb0d80addf99ada4f0cfbb30f78825dd5865c436bfde40822aa2527337ea',
        })
        for label, snapshot in [('before', self.before), ('after', self.after)]:
            self.assertEqual(hashlib.sha256(snapshot[self.key].encode()).hexdigest(),
                             self.metadata['skill_raw_sha256'][label])
        self.assertEqual(set(self.before), set(self.after))
        self.assertEqual(len(self.before), 15)

    def test_default_remains_strict_and_exact_approved_upgrade_is_recorded(self):
        with self.assertRaises(RuntimeError):
            require_learning_preserved(self.before, self.after)
        report = self.require()
        self.assertEqual(report['correct_answers_preserved'], 1)
        self.assertEqual((report['earned_stars'], report['earned_xp']), (1, 5))
        self.assertEqual(report['approved_migration']['records'], [{
            'preference_key': self.key, 'skill_id': self.skill,
            'added_independent_evidence': {
                'version': 1, 'correct': 1, 'wrong': 0,
                'correctStreak': 1, 'wrongStreak': 0,
            },
        }])
        self.assertNotIn('independentEvidence', json.loads(self.before[self.key])[self.skill])

    def test_unapproved_version_pairs_types_and_missing_opt_in_fail(self):
        for versions in [(2016, 2018), (2017, 2021), (2018, 2018),
                         ('2017', 2018), [2017, 2018], (True, 2018), ()]:
            with self.subTest(versions=versions), self.assertRaises(RuntimeError):
                self.require(versions=versions)

    def test_all_original_fields_require_identical_value_and_type(self):
        original = json.loads(self.before[self.key])[self.skill]
        self.assertEqual(len(original), 10)
        for field, value in original.items():
            changed = value + 1 if type(value) is int else value + '-changed'
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.require(self.change_record(field, changed))
            with self.subTest(deleted=field), self.assertRaises(RuntimeError):
                self.require(self.change_record(field, None, remove=True))
            if type(value) is int:
                for other_type in [float(value), bool(value), str(value)]:
                    with self.subTest(field=field, value=other_type), self.assertRaises(RuntimeError):
                        self.require(self.change_record(field, other_type))

    def test_all_evidence_fields_require_exact_version_values_and_types(self):
        expected = json.loads(self.after[self.key])[self.skill]['independentEvidence']
        invalid = [None, [], {}, {**expected, 'extra': 0}]
        for field, value in expected.items():
            invalid.extend([
                {**expected, field: value + 1}, {**expected, field: -1},
                {**expected, field: float(value)}, {**expected, field: bool(value)},
                {**expected, field: str(value)},
                {key: item for key, item in expected.items() if key != field},
            ])
        for evidence in invalid:
            with self.subTest(evidence=evidence), self.assertRaises(RuntimeError):
                self.require(self.change_record('independentEvidence', evidence))

    def test_helped_history_is_retained_without_invented_independent_success(self):
        before, after = copy.deepcopy(self.before), copy.deepcopy(self.after)
        old_records, new_records = json.loads(before[self.key]), json.loads(after[self.key])
        old_records[self.skill]['hintCount'] = 1
        new_records[self.skill]['hintCount'] = 1
        before[self.key], after[self.key] = json.dumps(old_records), json.dumps(new_records)
        with self.assertRaises(RuntimeError):
            self.require(after, before)
        new_records[self.skill]['independentEvidence'] = dict(
            version=1, correct=0, wrong=0, correctStreak=0, wrongStreak=0)
        after[self.key] = json.dumps(new_records)
        report = self.require(after, before)
        self.assertEqual(report['correct_answers_preserved'], 1)
        self.assertEqual(report['approved_migration']['records'][0]
                         ['added_independent_evidence']['correct'], 0)

    def test_legacy_streak_bounds_follow_reviewed_attribution_without_changing_history(self):
        for correct, wrong, streak, misses, expected_correct, expected_wrong in [
            (3, 2, 9, 0, 3, 0), (3, 2, 0, 9, 0, 2), (3, 2, 2, 1, 0, 0),
        ]:
            before, after = copy.deepcopy(self.before), copy.deepcopy(self.after)
            old_records, new_records = json.loads(before[self.key]), json.loads(after[self.key])
            for records in [old_records, new_records]:
                records[self.skill].update(correct=correct, wrong=wrong,
                                           currentStreak=streak, currentMisses=misses)
            new_records[self.skill]['independentEvidence'].update(
                correct=correct, wrong=wrong, correctStreak=expected_correct,
                wrongStreak=expected_wrong)
            before[self.key], after[self.key] = json.dumps(old_records), json.dumps(new_records)
            self.require(after, before)

    def test_map_identity_membership_unknown_fields_and_invalid_json_are_rejected(self):
        records = json.loads(self.after[self.key])
        invalid = [
            {}, [], None,
            {'another-skill': records[self.skill]},
            {**records, 'another-skill': records[self.skill]},
            {self.skill: {**records[self.skill], 'futureField': 2}},
        ]
        raw_invalid = [json.dumps(item) for item in invalid]
        raw_invalid.extend([
            '{broken',
            '{"same":{},"same":{}}',
            self.after[self.key].replace('"version":1', '"version":1,"version":1'),
            self.after[self.key].replace('"correct":1', '"correct":NaN'),
        ])
        for raw in raw_invalid:
            with self.subTest(raw=raw), self.assertRaises(RuntimeError):
                self.require({**self.after, self.key: raw})

    def test_existing_future_or_malformed_evidence_cannot_be_replaced_as_a_migration(self):
        before = copy.deepcopy(self.before)
        records = json.loads(before[self.key])
        records[self.skill]['independentEvidence'] = dict(
            version=2, correct=1, wrong=0, correctStreak=1, wrongStreak=0)
        before[self.key] = json.dumps(records)
        with self.assertRaises(RuntimeError):
            self.require(before=before)
        for field, value in [('hintCount', True), ('correct', 10001),
                             ('wrong', -1), ('difficulty', 0), ('currentStreak', 1001)]:
            malformed = copy.deepcopy(self.before)
            records = json.loads(malformed[self.key])
            records[self.skill][field] = value
            malformed[self.key] = json.dumps(records)
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.require(before=malformed)

    def test_primary_namespace_is_bound_to_unchanged_persisted_local_identity(self):
        owner_key = 'flutter.lumo_learning_local_student_id_v1'
        for wrong in [None, '', 'local-other', 'local-' + '0' * 32,
                      json.loads(self.before['flutter.lumo_active_profile'])['id']]:
            with self.subTest(owner=wrong), self.assertRaises(RuntimeError):
                self.require({**self.after, owner_key: wrong})
        missing = copy.deepcopy(self.after)
        del missing[owner_key]
        with self.assertRaises(RuntimeError):
            self.require(missing)

    def test_foreign_child_keys_remain_exact_and_cannot_be_added_or_reassigned(self):
        foreign = 'flutter.lumo_progress_skills::another-child'
        before = {**self.before, foreign: self.before[self.key]}
        after = {**self.after, foreign: self.before[self.key]}
        self.require(after, before)
        after[foreign] = self.after[self.key]
        with self.assertRaises(RuntimeError):
            self.require(after, before)
        with self.assertRaises(RuntimeError):
            self.require({**self.after, foreign: self.after[self.key]})
        removed = dict(self.after)
        del removed[self.key]
        removed[foreign] = self.after[self.key]
        with self.assertRaises(RuntimeError):
            self.require(removed)

    def test_unrelated_protected_fields_profile_and_rewards_remain_exact(self):
        for key in self.before:
            if not key.startswith(('flutter.lumo_progress', 'flutter.lumo_learning',
                                   'flutter.lumo_attempt_log', 'flutter.lumo_reward_wallet')):
                continue
            for replacement in [None, '{}']:
                after = copy.deepcopy(self.after)
                if replacement is None:
                    del after[key]
                else:
                    after[key] = replacement
                with self.subTest(key=key, replacement=replacement), self.assertRaises(RuntimeError):
                    self.require(after)
        for identity in ['id', 'name', 'age', 'grade', 'createdAt']:
            after = copy.deepcopy(self.after)
            profile = json.loads(after['flutter.lumo_active_profile'])
            profile[identity] = str(profile[identity]) + '-changed'
            after['flutter.lumo_active_profile'] = json.dumps(profile)
            with self.subTest(identity=identity), self.assertRaises(RuntimeError):
                self.require(after)

    def test_every_post_update_snapshot_is_byte_exact_plus_transitive_history(self):
        report = require_post_update_learning_preserved(
            self.before, self.after, self.after, migration_versions=(2017, 2018))
        self.assertEqual(report['after_update_exact']['correct_answers_preserved'], 1)
        self.assertEqual(report['baseline_history']['correct_answers_preserved'], 1)
        self.assertIn('approved_migration', report['baseline_history'])
        reformatted = dict(self.after)
        reformatted[self.key] = json.dumps(json.loads(self.after[self.key]), indent=2)
        self.require(reformatted)  # Initial migration permits JSON formatting only after full validation.
        for later in [reformatted, self.before,
                      self.change_record('correct', 2),
                      self.change_record('independentEvidence', dict(
                          version=1, correct=0, wrong=0, correctStreak=0, wrongStreak=0))]:
            with self.subTest(later=later[self.key]), self.assertRaises(RuntimeError):
                require_post_update_learning_preserved(
                    self.before, self.after, later, migration_versions=(2017, 2018))
        changed_baseline = copy.deepcopy(self.before)
        changed_baseline[self.key] = changed_baseline[self.key].replace('"correct":1', '"correct":2')
        with self.assertRaises(RuntimeError):
            require_post_update_learning_preserved(
                changed_baseline, self.after, self.after, migration_versions=(2017, 2018))

    def test_default_post_update_report_shape_and_byte_gate_are_unchanged(self):
        expected = require_learning_preserved(self.before, self.before)
        self.assertEqual(require_post_update_learning_preserved(
            self.before, self.before, self.before), expected)
        with self.assertRaises(RuntimeError):
            require_post_update_learning_preserved(self.before, self.after, self.after)


if __name__ == '__main__':
    unittest.main()
