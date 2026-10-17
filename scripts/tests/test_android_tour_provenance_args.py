"""Protect older Android tours against omitting required provenance arguments."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = [
    ROOT / ".github/workflows/lumo-1954-followup-android.yml",
    ROOT / ".github/workflows/lumo-1955-original-ui-feedback.yml",
]
PROBE = ROOT / ".github/probes/modernization_android_tour.py"
APK = "candidate/dist/x86_64/Lumo-Lernen-Neu.apk"
PROVENANCE = "candidate/release-proof/BUILD-PROVENANCE-x86_64.json"
SUMS = "candidate/release-proof/SHA256SUMS.txt"


class AndroidTourProvenanceArguments(unittest.TestCase):
    def test_probe_requires_apk_provenance_and_sums(self):
        code = PROBE.read_text(encoding="utf-8")
        for argument in ("--apk", "--provenance", "--sums", "--out"):
            with self.subTest(argument=argument):
                self.assertRegex(code, r"parser\.add_argument\(['\"]" +
                                 re.escape(argument) + r"['\"],.*required=True" if argument != "--out"
                                 else r"parser\.add_argument\(['\"]--out['\"]")

    def test_every_android_tour_supplies_the_exact_published_apk_proof(self):
        for path in WORKFLOWS:
            with self.subTest(workflow=path.name):
                text = path.read_text(encoding="utf-8")
                invocation = next(
                    (line.strip() for line in text.splitlines()
                     if line.lstrip().startswith("script: ") and
                     "modernization_android_tour.py" in line),
                    None,
                )
                self.assertIsNotNone(invocation, "Missing real Android tour")
                for token in (f"--apk {APK}", f"--provenance {PROVENANCE}",
                              f"--sums {SUMS}", "--out tour"):
                    self.assertIn(token, invocation)
                self.assertIn("dist/x86_64/Lumo-Lernen-Neu.apk", text)
                self.assertIn("release-proof/BUILD-PROVENANCE-x86_64.json", text)
                self.assertIn("release-proof/SHA256SUMS.txt", text)


if __name__ == "__main__":
    unittest.main()
