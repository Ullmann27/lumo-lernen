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

    def test_1931_requires_new_version_and_actual_subtraction_acceptance(self):
        with self.assertRaises(ValueError):
            PACKAGE.validate(self.provenance, self.android, self.outcomes, self.run,
                             self.log, version_code=1931, version_name="0.12.24")
        self.provenance.update(versionCode=1931, versionName="0.12.24")
        with self.assertRaises(ValueError):
            PACKAGE.validate(self.provenance, self.android, self.outcomes, self.run,
                             self.log, version_code=1931, version_name="0.12.24")
        self.android["subtraction_course"] = {"status": "PASS"}
        self.assertEqual(PACKAGE.validate(
            self.provenance, self.android, self.outcomes, self.run, self.log,
            version_code=1931, version_name="0.12.24")["source"], self.source)

    def test_1932_requires_accepted_help_after_two_real_wrong_answers(self):
        self.provenance.update(versionCode=1932, versionName="0.12.25")
        self.android["subtraction_course"] = {"status": "PASS"}
        def verify():
            return PACKAGE.validate(self.provenance, self.android, self.outcomes,
                                    self.run, self.log, version_code=1932,
                                    version_name="0.12.25")
        with self.assertRaises(ValueError):
            verify()
        self.android["subtraction_course"]["active_help"] = {
            "status": "PASS", "real_wrong_taps": 2,
            "no_hint_before_acceptance": True,
            "actual_accept_button_tapped": True,
        }
        self.assertEqual(verify()["source"], self.source)
        self.android["subtraction_course"]["active_help"]["actual_accept_button_tapped"] = False
        with self.assertRaises(ValueError):
            verify()


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

    def test_1931_pins_existing_1930_update_and_its_own_package_version(self):
        workflow = (ROOT / ".github/workflows/lumo-education-1931.yml").read_text()
        self.assertIn("LUMO_BASE_VERSION: '1930'", workflow)
        self.assertIn("LUMO_EXPECT_VERSION: '1931'", workflow)
        self.assertIn("--version-code 1931 --version-name 0.12.24", workflow)
        self.assertIn("run-id: 38147910017", workflow)
        self.assertIn("lumo-education-1930-emulator-38147910017", workflow)
        self.assertIn("needs: [verify-build, android-learning]", workflow)
        self.assertNotIn("contents: write", workflow)
        self.assertNotIn("gh release create", workflow)


if __name__ == "__main__":
    unittest.main()
