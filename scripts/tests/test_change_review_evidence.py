"""Protect the existing CI evidence upload, without running PR-supplied code."""

from pathlib import Path
import re
import unittest


WORKFLOW = (
    Path(__file__).resolve().parents[2]
    / ".github/workflows/lumo-change-review.yml"
)


class ChangeReviewEvidenceTests(unittest.TestCase):
    def evidence_step(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        return text.split(
            "- name: Preserve evidence even when checks fail", 1
        )[1].split("\n  report:", 1)[0]

    def test_hidden_generated_evidence_is_explicitly_included(self):
        self.assertRegex(
            self.evidence_step(), r"include-hidden-files:\s+true\b"
        )

    def test_upload_is_scoped_to_the_generated_directory(self):
        self.assertEqual(
            re.findall(r"^\s+path:\s*(.+)$", self.evidence_step(), re.MULTILINE),
            [".ci-results/"],
        )
        self.assertRegex(self.evidence_step(), r"if:\s+always\(\)")

    def test_empty_upload_cannot_appear_as_saved_proof(self):
        self.assertRegex(
            self.evidence_step(), r"if-no-files-found:\s+error\b"
        )


if __name__ == "__main__":
    unittest.main()
