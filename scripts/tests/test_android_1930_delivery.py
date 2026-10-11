"""Delivery gate regressions. These fixtures are not Android run evidence."""
import copy
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "package_android_test_delivery", ROOT / "tools/package_android_test_delivery.py")
PACKAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGE)


class DeliveryGateTest(unittest.TestCase):
    def setUp(self):
        self.source = "a" * 40
        self.provenance = {
            "flutter_source_commit": self.source, "versionCode": 1930,
            "versionName": "0.12.23", "package": "dev.ullmann.lumo.lumo_lernen.coachpreview",
            "abis": ["arm64-v8a"], "tracked_source_clean": True,
            "signingCertificateSha256": PACKAGE.CERTIFICATE,
            "godot": {"revision": PACKAGE.GODOT},
            "elf16KiBAligned": True, "resourcesArscAligned": True,
        }
        self.android = {
            "status": "PASS", "candidate_source": self.source,
            "voice_update_kart": {"status": "PASS"}, "school_course": {"status": "PASS"},
            "discovery_course": {"status": "PASS"}, "restart_school_discovery_wallet": "PASS",
        }
        self.outcomes = {"SOURCE_SHA": self.source, "DEPENDENCIES": "success",
                         "ANALYSIS": "success", "TESTS": "success"}
        self.run = {"head_sha": self.source, "status": "completed", "conclusion": "success",
                    "html_url": "https://github.com/test/unit-fixture/actions/runs/1"}
        self.log = "00:45 +1200 ~115: All tests passed!"

    def validate(self):
        return PACKAGE.validate(self.provenance, self.android, self.outcomes, self.run, self.log)

    def test_complete_matching_evidence_is_required(self):
        self.assertEqual(self.validate()["passed"], 1200)

    def test_old_wrong_package_architecture_source_or_signature_is_rejected(self):
        original = copy.deepcopy(self.provenance)
        for field, value in (("versionCode", 1929), ("abis", ["x86_64"]),
                             ("package", "dev.normal.app"),
                             ("signingCertificateSha256", "b" * 64),
                             ("tracked_source_clean", False)):
            self.provenance = {**original, field: value}
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.validate()

    def test_failed_or_partial_android_acceptance_is_rejected(self):
        self.android["discovery_course"]["status"] = "FAIL"
        with self.assertRaises(ValueError):
            self.validate()

    def test_old_ci_cannot_be_used_for_new_source(self):
        self.outcomes["SOURCE_SHA"] = "b" * 40
        with self.assertRaises(ValueError):
            self.validate()

    def test_success_without_real_test_summary_is_rejected(self):
        self.log = "Compilation successful"
        with self.assertRaises(ValueError):
            self.validate()


class DeliveryWorkflowTest(unittest.TestCase):
    def setUp(self):
        self.workflow = (ROOT / ".github/workflows/lumo-education-1930.yml").read_text()
        self.builder = self.workflow.split("\n  package-download:")[0]

    def test_both_native_artifacts_are_uploaded_by_the_builder(self):
        self.assertIn("name: lumo-education-1930-arm64-", self.builder)
        self.assertIn("name: lumo-education-1930-emulator-", self.builder)
        self.assertIn("name: lumo-education-1930-build-evidence-", self.builder)
        self.assertNotIn("path: dist/\n", self.builder)

    def test_final_zip_depends_on_actual_android_acceptance(self):
        self.assertIn("needs: [verify-build, android-learning]", self.workflow)
        self.assertIn("complete-ci/evidence", self.workflow)
        self.assertIn('run[\'head_sha\'] == os.environ[\'GITHUB_SHA\']', self.workflow)

    def test_no_publication_payment_or_second_flutter_suite(self):
        self.assertNotIn("contents: write", self.workflow)
        self.assertNotIn("gh release create", self.workflow)
        self.assertNotIn("flutter test --", self.workflow)


if __name__ == "__main__":
    unittest.main()
