"""Replay the recorded migration shape under an explicit 2017 -> 2019 policy.

These parser regressions reuse recorded 2018 input to check the unchanged
conversion rules. They do not claim an Android 2019 update has been executed.
"""
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_update_preservation as legacy
from update_preservation import (require_learning_preserved,
                                 require_post_update_learning_preserved,
                                 reviewed_migration_versions)


class Build2019IndependentEvidenceMigrationTests(legacy.Build2018IndependentEvidenceMigrationTests):
    def require(self, after=None, before=None, versions=(2017, 2019)):
        return require_learning_preserved(
            self.before if before is None else before,
            self.after if after is None else after,
            migration_versions=versions)

    def test_current_report_names_actual_2019_pair_without_changing_old_report(self):
        current = self.require()
        historical = self.require(versions=(2017, 2018))
        self.assertEqual(current['approved_migration']['to_version'], 2019)
        self.assertEqual(historical['approved_migration']['to_version'], 2018)
        self.assertEqual(current['approved_migration']['records'],
                         historical['approved_migration']['records'])

    def test_each_entry_point_requires_its_own_exact_version_pair(self):
        self.assertIsNone(reviewed_migration_versions(2017, 2019))
        self.assertEqual(reviewed_migration_versions(2017, 2018, allow_2018=True), (2017, 2018))
        self.assertEqual(reviewed_migration_versions(2017, 2019, allow_2019=True), (2017, 2019))
        for baseline, candidate, flags in (
            (2017, 2019, {'allow_2018': True}),
            (2017, 2018, {'allow_2019': True}),
            (2018, 2019, {'allow_2019': True}),
            (2017, 2020, {'allow_2019': True}),
            ('2017', 2019, {'allow_2019': True}),
            (2017, 2019, {'allow_2019': 1}),
            (2017, 2019, {'allow_2018': True, 'allow_2019': True}),
        ):
            with self.subTest(pair=(baseline, candidate), flags=flags), self.assertRaises(RuntimeError):
                reviewed_migration_versions(baseline, candidate, **flags)

    def test_every_post_update_snapshot_is_byte_exact_plus_transitive_history(self):
        report = require_post_update_learning_preserved(
            self.before, self.after, self.after, migration_versions=(2017, 2019))
        self.assertEqual(report['after_update_exact']['correct_answers_preserved'], 1)
        self.assertEqual(report['baseline_history']['approved_migration']['to_version'], 2019)
        reformatted = dict(self.after)
        reformatted[self.key] = json.dumps(json.loads(self.after[self.key]), indent=2)
        self.require(reformatted)
        for later in [reformatted, self.before,
                      self.change_record('correct', 2),
                      self.change_record('independentEvidence', dict(
                          version=1, correct=0, wrong=0, correctStreak=0, wrongStreak=0))]:
            with self.subTest(later=later[self.key]), self.assertRaises(RuntimeError):
                require_post_update_learning_preserved(
                    self.before, self.after, later, migration_versions=(2017, 2019))
        changed_baseline = copy.deepcopy(self.before)
        changed_baseline[self.key] = changed_baseline[self.key].replace('"correct":1', '"correct":2')
        with self.assertRaises(RuntimeError):
            require_post_update_learning_preserved(
                changed_baseline, self.after, self.after, migration_versions=(2017, 2019))


if __name__ == '__main__':
    unittest.main()
