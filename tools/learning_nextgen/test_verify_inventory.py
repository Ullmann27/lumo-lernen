"""Negative and positive source-inventory contracts; no Android claims."""
import copy
import json
import unittest

from verify_inventory import LEDGER, check_repository, source_catalog, validate_ledger


class SourceCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = source_catalog()

    def setUp(self):
        self.ledger = json.loads(LEDGER.read_text(encoding="utf-8"))

    def test_exact_source_coverage(self):
        result = check_repository()
        self.assertEqual(result["status"], "STATIC_SOURCE_MATCH_ONLY")
        self.assertEqual(result["counts"]["academyTopicIds"], 36)
        self.assertEqual(result["counts"]["dedicatedModuleIds"], 20)
        self.assertEqual(result["counts"]["labTopics"], 6)
        self.assertEqual(result["counts"]["generatorSubjectFamilies"], 8)
        self.assertFalse(result["allLearningModernized"])
        self.assertFalse(result["androidRuntimeVerified"])

    def test_missing_topic_fails(self):
        self.ledger["academyTopics"].pop()
        with self.assertRaisesRegex(ValueError, "academy topics"):
            validate_ledger(self.ledger, self.source)

    def test_missing_registered_module_fails(self):
        self.ledger["dedicatedModules"].pop()
        with self.assertRaisesRegex(ValueError, "registered modules"):
            validate_ledger(self.ledger, self.source)

    def test_duplicates_fail(self):
        self.ledger["labTopics"].append(copy.deepcopy(self.ledger["labTopics"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate ID"):
            validate_ledger(self.ledger, self.source)

    def test_task_without_entry_fails(self):
        self.ledger["academyTopics"][0]["entry"] = ""
        with self.assertRaisesRegex(ValueError, "lacks reachable source entry"):
            validate_ledger(self.ledger, self.source)

    def test_unsubstantiated_modernization_fails(self):
        self.ledger["academyTopics"][0]["modernized"] = True
        with self.assertRaisesRegex(ValueError, "modernization"):
            validate_ledger(self.ledger, self.source)

    def test_incomplete_android_and_audio_evidence_fails(self):
        self.ledger["academyTopics"][0]["modernized"] = True
        self.ledger["academyTopics"][0]["evidence"] = {
            "hostCommit": "real-sha", "nativeCommit": "real-sha",
            "integrationRun": "test-run-id", "taskCoverage": "test-id",
        }
        with self.assertRaisesRegex(ValueError, "androidRun"):
            validate_ledger(self.ledger, self.source)

    def test_wrong_subject_or_grade_fails(self):
        self.ledger["academyTopics"][0]["grade"] = 4
        with self.assertRaisesRegex(ValueError, "academy topics"):
            validate_ledger(self.ledger, self.source)

    def test_staged_sources_remain_unverified(self):
        result = validate_ledger(self.ledger, self.source)
        self.assertFalse(result["generatorUnitsEnumerated"])
        self.assertEqual(result["status"], "STATIC_SOURCE_MATCH_ONLY")


if __name__ == "__main__":
    unittest.main()
