"""Gates that keep the next family APK installable over the published app."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import release_pipeline_gates as gates

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "lumo-family-draft-release.yml"


def verification(**overrides):
    info = {
        "package": gates.PACKAGE_ID,
        "versionCode": 2012,
        "versionName": "0.13.0",
        "abis": ["arm64-v8a", "x86_64"],
        "sha256": "a" * 64,
        "signingCertificateSha256": gates.EXPECTED_CERT_SHA256,
    }
    info.update(overrides)
    return info


class ReleasePipelineGateTests(unittest.TestCase):
    def test_pubspec_must_be_newer_than_last_published_family_build(self):
        report = gates.evaluate_source(
            pubspec_text="version: 0.13.0+2012\n", last_published=2004
        )
        self.assertEqual(report["versionCode"], 2012)
        self.assertEqual(report["tag"], "coachpreview-build-2012")
        self.assertEqual(report["lastPublishedFamilyBuild"], 2004)
        self.assertEqual(
            report["downloadUrl"],
            "https://github.com/Ullmann27/lumo-lernen/releases/download/"
            "coachpreview-build-2012/Lumo-Lernen-Neu.apk",
        )
        with self.assertRaises(ValueError):
            gates.evaluate_source(
                pubspec_text="version: 0.12.92+2004\n", last_published=2004
            )
        with self.assertRaises(ValueError):
            gates.evaluate_source(
                pubspec_text="version: 0.12.91+2003\n", last_published=2004
            )

    def test_known_2004_floor_cannot_be_lowered(self):
        self.assertEqual(gates.effective_last_published(1999), 2004)
        self.assertEqual(gates.effective_last_published(2004), 2004)
        self.assertEqual(gates.effective_last_published(2012), 2012)

    def test_verification_rejects_wrong_package_cert_or_missing_arm64(self):
        ok = gates.evaluate_verification(
            verification(), version_name="0.13.0", version_code=2012
        )
        self.assertEqual(ok["package"], gates.PACKAGE_ID)
        self.assertIn("arm64-v8a", ok["abis"])
        with self.assertRaises(ValueError):
            gates.evaluate_verification(
                verification(package="dev.ullmann.lumo.lumo_lernen"),
                version_name="0.13.0",
                version_code=2012,
            )
        with self.assertRaises(ValueError):
            gates.evaluate_verification(
                verification(signingCertificateSha256="0" * 64),
                version_name="0.13.0",
                version_code=2012,
            )
        with self.assertRaises(ValueError):
            gates.evaluate_verification(
                verification(abis=["x86_64"]),
                version_name="0.13.0",
                version_code=2012,
            )
        with self.assertRaises(ValueError):
            gates.evaluate_verification(
                verification(versionCode=2011),
                version_name="0.13.0",
                version_code=2012,
            )

    def test_published_family_catalog_ignores_drafts_and_wrong_assets(self):
        catalog = [
            {
                "tag_name": "coachpreview-build-2004",
                "draft": False,
                "prerelease": True,
                "assets": [{"name": "Lumo-Lernen-Neu.apk"}],
            },
            {
                "tag_name": "coachpreview-build-2012",
                "draft": True,
                "prerelease": True,
                "assets": [{"name": "Lumo-Lernen-Neu.apk"}],
            },
            {
                "tag_name": "coachpreview-build-2005",
                "draft": False,
                "prerelease": False,
                "assets": [{"name": "Lumo-Lernen-Neu.apk"}],
            },
            {
                "tag_name": "lumo-0.12.92-2004",
                "draft": False,
                "prerelease": True,
                "assets": [{"name": "Lumo-Lernen-Neu.apk"}],
            },
            {
                "tag_name": "coachpreview-build-1999",
                "draft": False,
                "prerelease": True,
                "assets": [{"name": "Lumo-Lernen-latest.apk"}],
            },
        ]
        self.assertEqual(gates.published_family_builds(catalog), [2004])
        self.assertEqual(gates.newest_published_family_build(catalog), 2004)

    def test_sha256_sidecar_uses_the_apk_bytes(self):
        with tempfile.TemporaryDirectory() as folder:
            apk = Path(folder) / "Lumo-Lernen-Neu.apk"
            apk.write_bytes(b"family-apk-fixture")
            sidecar = gates.write_sha256_sidecar(apk)
            digest = gates.sha256_file(apk)
            self.assertEqual(
                sidecar.read_text(encoding="utf-8"), f"{digest}  {apk.name}\n"
            )

    def test_draft_notes_warn_that_the_in_app_button_ignores_drafts(self):
        notes = gates.draft_release_notes("0.13.0", 2012, "abc123")
        self.assertIn("DRAFT", notes)
        self.assertIn("ignores drafts", notes)
        self.assertIn("prerelease", notes)
        self.assertIn("coachpreview-build-2012", notes)
        self.assertIn(gates.PACKAGE_ID, notes)
        self.assertIn(gates.EXPECTED_CERT_SHA256, notes)
        self.assertIn("Do not uninstall", notes)

    def test_current_repo_pubspec_is_already_newer_than_2004(self):
        name, code = gates.parse_pubspec_version(
            (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
        )
        self.assertGreater(code, gates.KNOWN_LAST_PUBLISHED)
        self.assertRegex(name, r"^[0-9]")

    def test_workflow_can_build_without_publishing_and_drafts_only_on_request(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("name: Lumo family draft release pipeline", source)
        self.assertIn("workflow_dispatch:", source)
        self.assertIn("verify-only", source)
        self.assertIn("build-only", source)
        self.assertIn("draft-release", source)
        self.assertIn("github.event.inputs.mode != 'verify-only'", source)
        self.assertIn("github.event.inputs.mode == 'draft-release'", source)
        self.assertIn("scripts/release_pipeline_gates.py", source)
        self.assertIn("scripts/verify_unified_apk.py", source)
        self.assertIn("Lumo-Lernen-Neu.apk.sha256", source)
        self.assertNotIn("gh release create", source)
        self.assertNotIn("--latest", source)
        create = source.split("upload-family-draft:", 1)[1]
        self.assertIn("contents: write", create)
        self.assertIn("prepare_family_draft_release.sh", create)
        self.assertIn("--create-draft", create)
        self.assertIn("github.event.inputs.mode == 'draft-release'", create)


class FamilyDraftScriptTests(unittest.TestCase):
    def test_script_defaults_to_dry_run_and_requires_explicit_draft_flag(self):
        script = (ROOT / "scripts" / "prepare_family_draft_release.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("set -euo pipefail", script)
        self.assertIn("--create-draft", script)
        self.assertIn("gh release create", script)
        self.assertIn("--draft", script)
        self.assertIn("--prerelease", script)
        self.assertIn("release_pipeline_gates.py", script)
        self.assertIn("CREATE_DRAFT=0", script)
        self.assertIn("Refusing to overwrite an existing tag", script)
        self.assertNotIn("gh release edit", script)
        self.assertIn("Dry run only", script)


if __name__ == "__main__":
    unittest.main()
