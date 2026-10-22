"""Keep the original 1989-to-1990 game screenshot proof limited to its own release branches.

New Lumo builds (1991 onward) must use their version-appropriate visual
evidence rather than silently rewriting this immutable historical contract.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "lumo-games-before-after.yml"
OLD_BRANCH = "chatgpt/lumo-1990-ui-unified-polish-2026-10-19"
INTEGRATION_BRANCH = "chatgpt/lumo-1990-integration-hardening-2026-10-19"


class HistoricalGamesVisualWorkflowScopeTest(unittest.TestCase):
    def test_only_original_1990_branches_are_allowed(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        job = source.split("\njobs:\n", 1)[1].split("\n  capture-games:\n", 1)[1]
        gate = job.split("\n    runs-on:", 1)[0]
        self.assertIn("if: >-", gate)
        self.assertIn("github.event.pull_request.head.ref", gate)
        self.assertIn("github.ref_name", gate)
        self.assertIn(OLD_BRANCH, gate)
        self.assertIn(INTEGRATION_BRANCH, gate)
        self.assertNotIn("claude/lumo-android-integration-m0-aloove", gate)
        self.assertNotIn("github.event_name == 'push'", gate)

    def test_old_build_evidence_remains_unchanged(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("ref: lumo-v0.12.77-1989-test", source)
        self.assertIn("'version: 0.12.77+1989'", source)
        self.assertIn("'version: 0.12.78+1990'", source)
        self.assertIn("git -C before rev-parse HEAD", source)
        self.assertIn("git -C after rev-parse HEAD", source)
        self.assertIn("visual/MANIFEST.json", source)
        self.assertIn("if-no-files-found: error", source)


if __name__ == "__main__":
    unittest.main()
