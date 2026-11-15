"""Exercise candidate identity and preservation against actual Git snapshots."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "integrated_learning_release", Path(__file__).resolve().parents[1] / "verify_integrated_learning_release.py")
VERIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFY)


class IntegratedLearningManifestTests(unittest.TestCase):
    def setUp(self):
        self.release = {"schemaVersion": 1, "versionName": "0.13.16", "versionCode": 2028,
                        "releaseTag": "lumo-nextgen-learning-0.13.16-2028"}
        self.pubspec = "name: lumo_lernen\nversion: 0.13.16+2028\n"

    def test_consistent_candidate(self):
        VERIFY.validate_manifest(self.release, self.pubspec)

    def test_mismatched_apk_version_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "identical version"):
            VERIFY.validate_manifest(self.release, self.pubspec.replace("2028", "2027"))

    def test_duplicate_pubspec_version_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "exactly one"):
            VERIFY.validate_manifest(self.release, self.pubspec + "version: 0.13.16+2028\n")

    def test_another_release_tag_cannot_relabel_candidate(self):
        self.release["releaseTag"] = "lumo-nextgen-learning-0.13.15-2027"
        with self.assertRaisesRegex(ValueError, "same version"):
            VERIFY.validate_manifest(self.release, self.pubspec)

    def test_boolean_or_text_version_fields_are_rejected(self):
        for key, value in (("schemaVersion", True), ("versionCode", "2028"), ("versionCode", True)):
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                VERIFY.validate_manifest(dict(self.release, **{key: value}), self.pubspec)

    def test_unknown_manifest_fields_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unexpected"):
            VERIFY.validate_manifest(dict(self.release, bypass=True), self.pubspec)

    def test_json_duplicate_keys_are_rejected_before_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            path.write_text('{"versionCode":2027,"versionCode":2028}', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Duplicate JSON key"):
                VERIFY.read_json(path)


class ProtectedWritingSourcesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        subprocess.run(["git", "init", "--quiet", str(cls.root)], check=True)
        for relative in VERIFY.PROTECTED_FILES:
            path = cls.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("original protected module " + relative + "\n", encoding="utf-8")
        cls.mutable = cls.root / "lib/features/learning/learning_content.dart"
        cls.mutable.parent.mkdir(parents=True, exist_ok=True)
        cls.mutable.write_text("original ordinary learning module\n", encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=cls.root, check=True)
        subprocess.run(["git", "-c", "user.name=Lumo QA", "-c", "user.email=qa@example.invalid",
                        "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "fixture baseline"],
                       cwd=cls.root, check=True)
        cls.baseline = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=cls.root, text=True).strip()
        cls.coverage = {"protectedSourceHashes": [{"path": path, "unchangedFromBase": True}
                                                for path in sorted(VERIFY.PROTECTED_FILES)]}

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    def test_hashes_are_computed_from_real_git_baseline(self):
        proof = VERIFY.verify_protected_sources(self.root, self.coverage, self.baseline)
        self.assertEqual(len(proof), 18)
        for entry in proof:
            self.assertEqual(entry["sha256"], hashlib.sha256((self.root / entry["path"]).read_bytes()).hexdigest())

    def test_regular_learning_modernization_remains_allowed(self):
        original = self.mutable.read_bytes()
        try:
            self.mutable.write_text("new scoped learning companion\n", encoding="utf-8")
            VERIFY.verify_protected_sources(self.root, self.coverage, self.baseline)
        finally:
            self.mutable.write_bytes(original)

    def test_writing_and_journal_mutations_are_rejected(self):
        for relative in ("lib/features/writing/writing_engine.dart", "lib/features/journal/journal_repository.dart"):
            path = self.root / relative
            original = path.read_bytes()
            try:
                path.write_text("unexpected replacement\n", encoding="utf-8")
                with self.subTest(path=relative), self.assertRaisesRegex(ValueError, "Protected writing/journal"):
                    VERIFY.verify_protected_sources(self.root, self.coverage, self.baseline)
            finally:
                path.write_bytes(original)

    def test_removed_or_duplicate_protection_cannot_hide_a_file(self):
        for duplicate in (False, True):
            coverage = copy.deepcopy(self.coverage)
            coverage["protectedSourceHashes"].pop()
            if duplicate:
                coverage["protectedSourceHashes"].append(copy.deepcopy(coverage["protectedSourceHashes"][0]))
            with self.subTest(duplicate=duplicate), self.assertRaisesRegex(ValueError, "exactly the reviewed"):
                VERIFY.verify_protected_sources(self.root, coverage, self.baseline)

    def test_unrelated_learning_file_cannot_be_added_to_freeze_modernization(self):
        coverage = copy.deepcopy(self.coverage)
        coverage["protectedSourceHashes"].append({"path": "lib/features/learning/learning_content.dart",
                                                 "unchangedFromBase": True})
        with self.assertRaisesRegex(ValueError, "exactly the reviewed"):
            VERIFY.verify_protected_sources(self.root, coverage, self.baseline)

    def test_false_preservation_declaration_is_rejected(self):
        coverage = copy.deepcopy(self.coverage)
        coverage["protectedSourceHashes"][0]["unchangedFromBase"] = False
        with self.assertRaisesRegex(ValueError, "preservation declaration"):
            VERIFY.verify_protected_sources(self.root, coverage, self.baseline)


if __name__ == "__main__":
    unittest.main()
