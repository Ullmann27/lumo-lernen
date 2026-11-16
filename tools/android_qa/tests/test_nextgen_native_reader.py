"""Replay real current-frame OCR; no Android input, capture or acceptance run."""
from __future__ import annotations

from contextlib import contextmanager
import hashlib
import importlib.util
import json
import copy
from pathlib import Path
import shutil
import sys
import tempfile
from types import ModuleType
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
PROBES = ROOT / ".github/probes"
sys.path[:0] = [str(PROBES), str(ROOT / "scripts/probes"), str(ROOT / "tools/android_qa")]
# The recorded-frame tests never connect to Android. Keep the real historical
# reader import, with an empty transport sentinel that cannot issue a UI call.
with patch.dict(sys.modules, {"uiautomator2": ModuleType("no_android_in_fixture_tests")}):
    import creative_android_probe as historical

SPEC = importlib.util.spec_from_file_location("current_pattern_fixture", PROBES / "lumo_nextgen_current_reference_android_probe.py")
current = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(current)
FIXTURE = Path(__file__).parent / "fixtures/nextgen_pattern_wrapped_43790709991"
FRAME = FIXTURE / "0114-pattern-native-question-9.png"
OCR = FIXTURE / "0114-pattern-native-question-9-ocr.json"
QUESTION = "Was kommt als Nächstes"


@contextmanager
def original_frame_transport():
    """Replace only ADB/Tesseract I/O with the unchanged recorded frame/rows."""
    captures, reads = [], []

    def capture(out, tag, timeout=None):
        target = out / (tag + ".png")
        shutil.copyfile(FRAME, target)
        captures.append(target)
        return {"file": target.name, "width": 1080, "height": 2340,
                "sha256": hashlib.sha256(target.read_bytes()).hexdigest()}

    def image_lines(out, tag, wanted="", source_path=None, timeout=225, exact=False, **kwargs):
        if source_path is None:
            source_path = out / capture(out, tag)["file"]
        if source_path.read_bytes() != FRAME.read_bytes():
            raise AssertionError("Fixture OCR must describe this actual captured image")
        reads.append({"source": source_path, "timeout": timeout, "wanted": wanted})
        rows = json.loads(OCR.read_text(encoding="utf-8"))
        (out / (tag + "-ocr.json")).write_bytes(OCR.read_bytes())
        return rows

    with patch.object(historical, "capture", side_effect=capture), \
         patch.object(historical, "image_lines", side_effect=image_lines), \
         patch.object(historical.time, "sleep"):
        yield captures, reads


class OriginalFrameTests(unittest.TestCase):
    def test_fixture_is_byte_identical_to_the_original_failed_diagnostic(self):
        manifest = json.loads((FIXTURE / "manifest.json").read_text())
        self.assertEqual(manifest["workflowRun"], 43790709991)
        self.assertEqual(manifest["originalDiagnosticOutcome"], "FAILED")
        self.assertFalse(manifest["synthetic"])
        for record in manifest["files"]:
            data = (FIXTURE / record["file"]).read_bytes()
            self.assertEqual(len(data), record["bytes"])
            self.assertEqual(hashlib.sha256(data).hexdigest(), record["sha256"])

    def test_current_candidate_reads_complete_question_from_actual_wrapped_frame(self):
        with tempfile.TemporaryDirectory() as directory, original_frame_transport() as (captures, reads):
            probe = object.__new__(current.CurrentCandidateProbe)
            probe.out, probe.counter, probe.reader = Path(directory), 0, historical
            # This exact runtime dispatch fails on c4e330 despite the text in
            # the real frame. Do not concatenate or prefilter fixture rows.
            probe.native_see(QUESTION, "pattern-native-question")
            self.assertEqual(len(captures), 1)
            self.assertEqual(len(reads), 1)
            self.assertGreater(reads[0]["timeout"], 0)
            self.assertLessEqual(reads[0]["timeout"], 225)
            evidence = json.loads(next(probe.out.glob("*-wrapped-read.json")).read_text())
            self.assertEqual(evidence["status"], "READ")
            self.assertEqual(evidence["label"], QUESTION)
            self.assertFalse(evidence["input_issued"])
            frame = evidence["frames"][0]
            self.assertEqual(frame["source_sha256"], hashlib.sha256(FRAME.read_bytes()).hexdigest())
            self.assertEqual(len(frame["match"]["rows"]), 2)
            original_rows = json.loads(OCR.read_text())
            for row in frame["match"]["rows"]:
                self.assertIn(row, original_rows)
                self.assertEqual(row["variant"], frame["match"]["variant"])

    def test_historical_reader_still_rejects_this_original_frame(self):
        with tempfile.TemporaryDirectory() as directory, original_frame_transport() as (captures, _):
            with self.assertRaisesRegex(RuntimeError, "Current native screenshot lacks Was kommt als Nächstes"):
                historical.native_text(Path(directory), QUESTION, "historical-unchanged")
            self.assertEqual(len(captures), 10)


class AdjacentPhraseTests(unittest.TestCase):
    def setUp(self):
        self.reader = current.native_reader
        self.rows = [row for row in json.loads(OCR.read_text())
                     if row["variant"] == "raw" and row["bounds"][1] < 400]
        self.assertEqual(len(self.rows), 2)

    def test_missing_words_wrong_order_and_cross_variant_are_rejected(self):
        cases = []
        rows = copy.deepcopy(self.rows)
        rows[1]["text"] = "kommt als?"
        cases.append(rows)
        rows = copy.deepcopy(self.rows)
        rows[1]["text"] = "als kommt Nächstes?"
        cases.append(rows)
        rows = copy.deepcopy(self.rows)
        rows[1]["variant"] = "another-mask"
        cases.append(rows)
        for rows in cases:
            with self.subTest(rows=rows):
                self.assertIsNone(self.reader.adjacent_phrase(rows, QUESTION, (1080, 2340)))

    def test_far_columns_intervening_rows_and_invalid_bounds_are_rejected(self):
        cases = []
        rows = copy.deepcopy(self.rows)
        rows[1]["bounds"][1:4:2] = [1000, 1052]
        cases.append(rows)
        rows = copy.deepcopy(self.rows)
        rows[1]["bounds"][0:3:2] = [920, 1070]
        cases.append(rows)
        rows = copy.deepcopy(self.rows)
        rows.insert(1, {"text": "anderer Absatz", "variant": "raw", "bounds": [78, 295, 600, 320]})
        cases.append(rows)
        for bad in ([-1, 338, 800, 390], [77, 338, 1081, 390], [77, 390, 800, 338], [77, float("nan"), 800, 390]):
            rows = copy.deepcopy(self.rows)
            rows[1]["bounds"] = bad
            cases.append(rows)
        for rows in cases:
            with self.subTest(rows=rows):
                self.assertIsNone(self.reader.adjacent_phrase(rows, QUESTION, (1080, 2340)))

    def test_distinct_phrase_regions_are_ambiguous(self):
        other = copy.deepcopy(self.rows)
        for row in other:
            row["bounds"][1] += 800
            row["bounds"][3] += 800
        with self.assertRaisesRegex(RuntimeError, "Ambiguous distinct native phrase regions"):
            self.reader.adjacent_phrase(self.rows + other, QUESTION, (1080, 2340))

    def test_actual_reading_order_and_single_line_remain_supported(self):
        # Input array order is not screen order. All coordinates remain real.
        match = self.reader.adjacent_phrase(list(reversed(self.rows)), QUESTION, (1080, 2340))
        self.assertEqual(match["rows"], self.rows)
        # Explicitly synthetic one-line layout: complete words remain required.
        line = {"text": "Muster entdecken · Was kommt als Nächstes?", "variant": "fixture",
                "bounds": [20, 30, 1000, 90]}
        self.assertEqual(self.reader.adjacent_phrase([line], QUESTION, (1080, 2340))["rows"], [line])

    def test_separate_observations_never_supply_each_others_missing_line(self):
        with tempfile.TemporaryDirectory() as directory, original_frame_transport() as (captures, reads):
            original_read = historical.image_lines.side_effect
            count = 0

            def alternating(*args, **kwargs):
                nonlocal count
                original_read(*args, **kwargs)
                row = copy.deepcopy(self.rows[count % 2])
                count += 1
                return [row]

            with patch.object(historical, "image_lines", side_effect=alternating):
                with self.assertRaisesRegex(RuntimeError, "lacks complete adjacent phrase"):
                    self.reader.see_wrapped_text(historical, Path(directory), QUESTION, "separate-frames")
            self.assertEqual(len(captures), 10)
            self.assertEqual(len(reads), 10)
            self.assertTrue(all(0 < item["timeout"] <= 225 for item in reads))
            self.assertEqual([call.args for call in historical.time.sleep.call_args_list], [(2,)] * 10)

    def test_changed_screenshot_is_rejected_even_when_ocr_words_match(self):
        with tempfile.TemporaryDirectory() as directory, original_frame_transport():
            original_read = historical.image_lines.side_effect

            def changed(*args, **kwargs):
                rows = original_read(*args, **kwargs)
                source = kwargs["source_path"]
                source.write_bytes(source.read_bytes() + b"synthetic-change")
                return rows

            with patch.object(historical, "image_lines", side_effect=changed):
                with self.assertRaisesRegex(RuntimeError, "screenshot changed during OCR"):
                    self.reader.see_wrapped_text(historical, Path(directory), QUESTION, "changed-frame")

    def test_capture_does_not_extend_the_existing_frame_budget(self):
        with tempfile.TemporaryDirectory() as directory, original_frame_transport() as (_, reads):
            with patch.object(self.reader.time, "monotonic", side_effect=[0, 226]):
                with self.assertRaisesRegex(TimeoutError, "frame deadline exceeded"):
                    self.reader.see_wrapped_text(historical, Path(directory), QUESTION, "expired-frame")
            self.assertEqual(reads, [])

    def test_override_is_limited_to_the_complete_nonexact_pattern_question(self):
        probe = object.__new__(current.CurrentCandidateProbe)
        with patch.object(current.reference.ReferenceProbe, "native_see") as previous:
            probe.native_see("Was kommt", "shorter")
            probe.native_see("Banane", "other")
            probe.native_see(QUESTION, "exact", exact=True)
            self.assertEqual([call.args for call in previous.call_args_list],
                             [("Was kommt", "shorter"), ("Banane", "other"), (QUESTION, "exact")])
            self.assertEqual(previous.call_args_list[-1].kwargs, {"exact": True})


if __name__ == "__main__":
    unittest.main()
