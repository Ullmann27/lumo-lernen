"""Guardrails: cleanup only reviewed old draft tags and aged disposable APK artifacts."""
from datetime import datetime, timedelta, timezone
import importlib.util
from pathlib import Path
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "cleanup_obsolete_github_assets.py"
spec = importlib.util.spec_from_file_location("lumo_artifact_cleaner", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
NOW = datetime(2026, 10, 19, 6, tzinfo=timezone.utc)

def ts(days):
    return (NOW - timedelta(days=days)).isoformat()

class CleanupSafetyTests(unittest.TestCase):
    def test_only_reviewed_old_drafts_are_candidates(self):
        item = {"id": 123, "tag_name": "unified-build-275", "draft": True,
                "created_at": ts(16)}
        self.assertTrue(module.deletable_draft(item, NOW))
        for tag in ("lumo-v0.12.73-1985-spatial-reading",
                    "lumo-v0.12.72-1984-atelier-scenes",
                    "unified-build-281", "lumo-meister-test-2026-10-12"):
            self.assertFalse(module.deletable_draft(dict(item, tag_name=tag), NOW))
        self.assertFalse(module.deletable_draft(dict(item, draft=False), NOW))
        self.assertFalse(module.deletable_draft(dict(item, created_at=ts(6)), NOW))

    def test_actions_artifacts_must_be_named_disposable_and_older_than_21_days(self):
        sample = {"id": 4, "name": "lumo-1974-arm64-verified",
                  "created_at": ts(30), "expired": False}
        self.assertTrue(module.deletable_artifact(sample, NOW))
        for name in ("lumo-1986-arm64-verified", "lumo-1984-android-tour",
                     "story-storage-runtime-screenshots", "source-provenance",
                     "lumo-1985-capture", "APK-VERIFICATION.json"):
            self.assertFalse(module.deletable_artifact(dict(sample, name=name), NOW)
                             if name == "lumo-1986-arm64-verified"
                             else module.deletable_artifact(dict(sample, name=name,
                                                                created_at=ts(1)), NOW))
        self.assertFalse(module.deletable_artifact(dict(sample, expired=True), NOW))
        self.assertFalse(module.deletable_artifact(dict(sample, name="lumo-1986-arm64-verified",
                                                          created_at=ts(1)), NOW))

if __name__ == "__main__":
    unittest.main()
