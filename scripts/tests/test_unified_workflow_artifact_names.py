"""Guard artifact identity against misleading historical Build 1988 names.

Build-specific identity belongs in APP-VERSION and BUILD-PROVENANCE.
The historical 1988 prerelease branch gate itself must remain unchanged.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "lumo-unified-integration-2026.yml"


class UnifiedArtifactNamingTests(unittest.TestCase):
    def test_generic_name_is_identical_for_arm64_upload_and_release_download(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertEqual(source.count("name: lumo-unified-arm64-verified"), 2)
        self.assertEqual(source.count("name: lumo-unified-android-tour"), 1)
        self.assertNotIn("lumo-1988-arm64-verified", source)
        self.assertNotIn("lumo-1988-android-tour", source)
        self.assertIn("dist/APP-VERSION.txt", source)
        self.assertIn("dist/BUILD-PROVENANCE.json", source)

    def test_1989_test_release_is_gated_by_real_android_tour(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("publish-1989-android-test-prerelease:", source)
        self.assertIn("head.repo.full_name == github.repository", source)
        self.assertIn("head.ref == 'chatgpt/lumo-1989-premium-learning-cards-2026-10-19'", source)
        self.assertIn("needs: [verify-and-build, android-tour]", source)
        self.assertIn("assert evidence['versionCode'] == 1989", source)
        self.assertIn("assert evidence['versionName'] == '0.12.77'", source)
        self.assertIn("TAG=lumo-v0.12.77-1989-test", source)
        self.assertIn("--prerelease", source)

    def test_original_1988_release_requires_old_branch_and_original_version(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("github.event.pull_request.head.ref == 'chatgpt/lumo-fair-cards-buildworld-release-gates-2026-10-19'", source)
        self.assertIn("assert provenance['versionCode'] == 1988", source)
        self.assertIn("assert provenance['versionName'] == '0.12.76'", source)
        self.assertIn("TAG=lumo-v0.12.76-1988-fair-cards", source)


if __name__ == "__main__":
    unittest.main()
