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


    def test_each_android_tour_installs_real_ocr_runtime_and_language_packs(self):
        # The 1954 Android tour previously reported FileNotFoundError:
        # [Errno 2] No such file or directory: 'tesseract' at race start.
        # Only packages from the Android tour job count: installation in the
        # preceding 'verify' job lives on a different GitHub Actions runner.
        for path in WORKFLOWS:
            with self.subTest(workflow=path.name):
                text = path.read_text(encoding="utf-8")
                self.assertIn("  android-tour:", text)
                tour = text.split("  android-tour:", 1)[1]
                self.assertIn("tesseract-ocr", tour)
                self.assertIn("tesseract-ocr-deu", tour)
                self.assertIn("tesseract-ocr-eng", tour)
                self.assertIn("modernization_android_tour.py", tour)

    def test_1954_checks_available_ocr_languages_before_booting_emulator(self):
        path = WORKFLOWS[0]
        text = path.read_text(encoding="utf-8")
        tour = text.split("  android-tour:", 1)[1]
        commands = (
            "command -v tesseract",
            "tesseract --list-langs 2>&1 | tee tour/tesseract-installed-languages.txt",
            "grep -Fxq 'deu' tour/tesseract-installed-languages.txt",
            "grep -Fxq 'eng' tour/tesseract-installed-languages.txt",
        )
        for command in commands:
            with self.subTest(command=command):
                self.assertIn(command, tour)
        self.assertLess(tour.index("command -v tesseract"),
                        tour.index("modernization_android_tour.py"))


if __name__ == "__main__":
    unittest.main()
