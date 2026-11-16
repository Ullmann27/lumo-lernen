"""Pure source, observation and evidence gates; no Android action or APK download."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import io
import itertools
import json
from pathlib import Path
import stat
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import zipfile


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("reference_probe", ROOT / ".github/probes/lumo_nextgen_reference_android_probe.py")
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


def origins():
    run = {"id": probe.SOURCE_RUN, "head_sha": probe.SOURCE,
           "repository": {"full_name": probe.REPOSITORY, "id": probe.REPOSITORY_ID},
           "path": ".github/workflows/lumo-nextgen-learning-apk.yml"}
    artifact = {"id": probe.ARTIFACT_ID, "name": probe.ARTIFACT_NAME, "size_in_bytes": probe.ZIP_BYTES,
                "digest": "sha256:" + probe.ZIP_SHA256, "expired": False,
                "workflow_run": {"id": probe.SOURCE_RUN, "head_sha": probe.SOURCE,
                                 "repository_id": probe.REPOSITORY_ID, "head_repository_id": probe.REPOSITORY_ID}}
    job = {"id": probe.BUILD_JOB, "run_id": probe.SOURCE_RUN, "head_sha": probe.SOURCE,
           "name": "build", "status": "completed", "conclusion": "success",
           "steps": [{"name": "Independently verify both produced artifacts", "conclusion": "success"}]}
    return run, artifact, job


class OriginTest(unittest.TestCase):
    def test_exact_original_artifact_does_not_require_original_android_success(self):
        run, artifact, job = origins()
        run.update(status="completed", conclusion="failure")
        probe.verify_origin(run, artifact, job)

    def test_wrong_run_source_artifact_signing_build_or_repository_is_rejected(self):
        changes = [(0, "id", 1), (0, "head_sha", "a" * 40), (0, "path", "another.yml"),
                   (0, "repository", {"full_name": "other/repo", "id": probe.REPOSITORY_ID}),
                   (1, "id", probe.ARTIFACT_ID - 1), (1, "name", "lumo-nextgen-arm64"),
                   (1, "size_in_bytes", probe.ZIP_BYTES - 1), (1, "digest", "sha256:" + "f" * 64),
                   (1, "expired", True), (1, "expired", 0),
                   (1, "workflow_run", {**origins()[1]["workflow_run"], "head_sha": "f" * 40}),
                   (1, "workflow_run", {**origins()[1]["workflow_run"], "head_repository_id": 1}),
                   (2, "id", 2), (2, "conclusion", "failure"), (2, "run_id", 2),
                   (2, "head_sha", "f" * 40), (2, "steps", [])]
        for index, key, value in changes:
            with self.subTest(index=index, key=key), self.assertRaises(RuntimeError):
                inputs = list(origins())
                inputs[index][key] = value
                probe.verify_origin(*inputs)

    def test_short_fake_candidate_is_rejected_before_parsing_provenance(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Lumo-Lernen-Neu.apk").write_bytes(b"not the original APK")
            with self.assertRaisesRegex(RuntimeError, "original bytes"):
                probe.verify_candidate(root)


class ArchiveTest(unittest.TestCase):
    def archive(self, names):
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, "w") as writer:
            for name in names:
                writer.writestr(name, b"fixture")
        stream.seek(0)
        return zipfile.ZipFile(stream)

    def test_real_member_paths_extract_without_modifying_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "source.zip"
            with zipfile.ZipFile(archive, "w") as writer:
                writer.writestr("a/report.json", '{"verified":true}')
                writer.writestr("Lumo-Lernen-Neu.apk", b"fixture-only")
            before = probe.digest(archive)
            probe.extract_zip(archive, root / "extracted")
            self.assertEqual((root / "extracted/a/report.json").read_text(), '{"verified":true}')
            self.assertEqual(probe.digest(archive), before)
            with self.assertRaises(RuntimeError):
                probe.extract_zip(archive, root / "extracted")

    def test_traversal_absolute_alias_windows_and_control_paths_are_rejected(self):
        for name in ("../outside", "/outside", "a/../../outside", "a/./b", "a//b", "a\\b", "C:/outside", "a\nb"):
            with self.subTest(name=name), self.archive([name]) as archive, self.assertRaises(RuntimeError):
                probe.safe_zip_members(archive)

    def test_symlinks_and_file_directory_collisions_are_rejected(self):
        link = zipfile.ZipInfo("link")
        link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        for names in ([link], ["a", "a/b"], ["a/b", "a"]):
            with self.subTest(names=names), self.archive(names) as archive, self.assertRaises(RuntimeError):
                probe.safe_zip_members(archive)

    def test_duplicate_member_name_is_rejected(self):
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with self.archive(["report.json", "report.json"]) as archive, self.assertRaises(RuntimeError):
                probe.safe_zip_members(archive)


class VisibleTaskTest(unittest.TestCase):
    def prompt(self, values):
        return "Das Muster wiederholt sich immer gleich: " + " – ".join(values) + " – ? Welche Form folgt?"

    def test_every_actual_two_shape_order_is_read_without_a_fixed_seed(self):
        for left, right in itertools.permutations(probe.SHAPES, 2):
            prompt = self.prompt([left, right, left, right])
            observed = probe.observed_pattern([prompt, prompt])
            self.assertEqual(observed["period"], 2)
            self.assertEqual(observed["next"], left)
            self.assertEqual(observed["prompt"], prompt)

    def test_incomplete_nonperiodic_ambiguous_and_other_grade_questions_fail(self):
        valid = self.prompt(["Stern", "Quadrat", "Stern", "Quadrat"])
        samples = [["Muster"], [valid, self.prompt(["Kreis", "Dreieck", "Kreis", "Dreieck"])],
                   [self.prompt(["Kreis"] * 4)], [self.prompt(["Kreis", "Kreis", "Stern", "Stern"])],
                   [self.prompt(["Kreis", "Stern", "Quadrat"] * 2)],
                   [self.prompt(["Katze", "Hund"] * 2)]]
        for labels in samples:
            with self.subTest(labels=labels), self.assertRaises(RuntimeError):
                probe.observed_pattern(labels)

    def node(self, text, box, **extra):
        return {"text": text, "bounds": box, "package": probe.learning.PACKAGE,
                "enabled": "true", "clickable": "false", **extra}

    def test_repeated_course_button_is_bound_to_title_and_actual_description(self):
        nodes = [self.node("Wörter in Silben hören", "[20,100][300,150]"),
                 self.node("Sprechstücke hören, mitklatschen und ein neues Wort selbst gliedern.", "[20,160][300,240]"),
                 self.node("Mit Lumo anfangen", "[20,260][300,320]", clickable="true"),
                 self.node("Mit Lumo anfangen", "[20,600][300,660]", clickable="true")]
        self.assertEqual(probe.associated_start(nodes, "Wörter in Silben hören"), (20, 260, 300, 320))
        with self.assertRaises(RuntimeError):
            probe.associated_start([nodes[0], *nodes[2:]], "Wörter in Silben hören")

    def test_panel_repeat_cannot_select_same_caption_in_outer_footer(self):
        rows = {"Noch einmal": [{"text": "Noch einmal", "bounds": [30, 220, 120, 245]},
                                {"text": "Noch einmal", "bounds": [30, 700, 120, 725]}],
                "Langsamer": [{"text": "Langsamer", "bounds": [140, 220, 240, 245]}], "Ein Hinweis": []}
        self.assertEqual(probe.panel_repeat_target(rows, (10, 40, 400, 400)), (30, 220, 120, 245))
        rows["Noch einmal"].pop(0)
        self.assertIsNone(probe.panel_repeat_target(rows, (10, 40, 400, 400)))
        rows["Noch einmal"] = [{"text": "Noch einmal", "bounds": [30, 220, 120, 245]},
                               {"text": "Noch einmal", "bounds": [30, 160, 120, 185]}]
        with self.assertRaises(RuntimeError):
            probe.panel_repeat_target(rows, (10, 40, 400, 400))

    def test_missing_panel_siblings_require_more_observation_not_a_guess(self):
        rows = {"Noch einmal": [{"text": "Noch einmal", "bounds": [30, 220, 120, 245]}],
                "Langsamer": [], "Ein Hinweis": []}
        self.assertIsNone(probe.panel_repeat_target(rows, (10, 40, 400, 400)))

    def test_wrapped_status_uses_one_real_frame_variant_in_reading_order(self):
        lines = [{"text": "kommt die Silbe na", "bounds": [20, 140, 250, 170], "variant": "raw"},
                 {"text": "Als Nächstes", "bounds": [20, 100, 200, 130], "variant": "raw"}]
        self.assertEqual(probe.ocr_phrase_variant(lines, "Als Nächstes kommt die Silbe „na“"), "raw")
        lines[1]["variant"] = "different-frame-or-filter"
        self.assertIsNone(probe.ocr_phrase_variant(lines, "Als Nächstes kommt die Silbe „na“"))

    def test_panel_pixel_bounds_are_observed_without_changing_the_screenshot(self):
        from PIL import Image, ImageDraw
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "reader-fixture.png"
            image = Image.new("RGB", (480, 800), "#102030")
            drawing = ImageDraw.Draw(image)
            drawing.rectangle((20, 100, 459, 599), fill="#fff8e8")
            drawing.rectangle((40, 200, 300, 250), fill="#e2eddb")
            image.save(path)
            before = probe.digest(path)
            self.assertEqual(probe.observed_panel_background(path), (20, 100, 460, 600))
            self.assertEqual(before, probe.digest(path))
            Image.new("RGB", (480, 800), "#102030").save(path)
            with self.assertRaises(RuntimeError):
                probe.observed_panel_background(path)

    def test_scattered_pale_pixels_do_not_create_a_panel_touch_region(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "scattered-reader-fixture.png"
            image = Image.new("RGB", (480, 800), "#102030")
            for point in ((20, 100), (450, 590), (250, 300)):
                image.putpixel(point, (255, 248, 232))
            image.save(path)
            with self.assertRaises(RuntimeError):
                probe.observed_panel_background(path)


class PlaybackTest(unittest.TestCase):
    def start(self, turn, pid=55, profile="lumo-free-supertonic-de-v1"):
        return f"I/LumoLearningSpeech({pid}): started id={turn} profile={profile}\n"

    def complete(self, turn, pid=55):
        return f"I/LumoLearningSpeech({pid}): completed id={turn}\n"

    def test_four_actual_sequential_segments_exclude_old_and_other_process_events(self):
        old = self.start(1) + self.complete(1) + self.start(3, 66) + self.complete(3, 66)
        current = "".join(self.start(turn) + self.complete(turn) for turn in (10, 11, 12, 13))
        value = probe.action_playback(old + current, 55, {1}, segments=4)
        self.assertEqual(value["utterance_ids"], [10, 11, 12, 13])
        self.assertFalse(value["spoken_words_in_log"])
        self.assertFalse(value["audible_quality_verified"])

    def test_old_autoplay_cannot_fill_a_missing_repeat_segment(self):
        log = "".join(self.start(turn) + self.complete(turn) for turn in (1, 10, 11, 12))
        self.assertIsNone(probe.action_playback(log, 55, {1}, segments=4))
        self.assertIsNone(probe.action_playback(self.start(10), 55, (), segments=1))

    def test_completion_without_start_wrong_voice_overlap_and_extra_segments_fail(self):
        logs = [self.complete(10), self.start(10, profile="another-voice") + self.complete(10),
                self.start(10) + self.start(11) + self.complete(10),
                self.start(10) + self.complete(10) + self.start(11) + self.complete(11)]
        for log in logs:
            with self.subTest(log=log), self.assertRaises(RuntimeError):
                probe.action_playback(log, 55)


class NativeStartObservationTest(unittest.TestCase):
    foreground = ("topResumedActivity=ActivityRecord{fixture u0 " + probe.learning.PACKAGE +
                  "/dev.ullmann.lumo.lumo_lernen.LumoGameActivity t1}")

    def instance(self, directory, observations):
        instance = probe.ReferenceProbe.__new__(probe.ReferenceProbe)
        instance.out, instance.counter = Path(directory), 0
        pending = iter(observations)
        current = None

        def adb(*args, **kwargs):
            nonlocal current
            if args == ("shell", "dumpsys", "activity", "activities"):
                current = next(pending)
                return current[0]
            if args == ("shell", "pidof", probe.learning.PACKAGE + ":lumo_game"):
                self.assertIs(kwargs.get("check"), False)
                return current[1]
            if args == ("logcat", "-d", "-v", "threadtime"):
                return "unaltered native startup log\n"
            raise AssertionError((args, kwargs))

        instance.base = SimpleNamespace(adb=adb)
        return instance

    def test_resumed_activity_without_pid_waits_for_the_observed_process(self):
        with tempfile.TemporaryDirectory() as directory:
            instance = self.instance(directory, [(self.foreground, ""), (self.foreground, "8241\n")])
            with patch.object(probe.time, "monotonic", side_effect=[0, 0, 1]), \
                 patch.object(probe.time, "sleep"):
                self.assertEqual(instance.wait_native_ready("banana"), 8241)
            rows = [json.loads(path.read_text()) for path in sorted(Path(directory).glob("*.json"))]
            self.assertEqual([row["pidof_output"] for row in rows], ["", "8241\n"])
            self.assertTrue(all(row["activity_dump"] == self.foreground for row in rows))

    def test_pid_without_current_exact_activity_does_not_pass(self):
        for activity in (self.foreground.replace(probe.learning.PACKAGE, "other.package"),
                         self.foreground.replace("topResumedActivity", "lastPausedActivity"),
                         self.foreground.replace("LumoGameActivity", "LumoGameActivityOther")):
            with self.subTest(activity=activity), tempfile.TemporaryDirectory() as directory:
                instance = self.instance(directory, [(activity, "8241")])
                with patch.object(probe.time, "monotonic", side_effect=[0, 0, 61]), \
                     patch.object(probe.time, "sleep"), self.assertRaisesRegex(RuntimeError, "before deadline"):
                    instance.wait_native_ready("banana")
                self.assertEqual(next(Path(directory).glob("*.log")).read_text(), "unaltered native startup log\n")

    def test_missing_process_times_out_and_preserves_raw_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            instance = self.instance(directory, [(self.foreground, "")])
            with patch.object(probe.time, "monotonic", side_effect=[0, 0, 61]), \
                 patch.object(probe.time, "sleep"), self.assertRaisesRegex(RuntimeError, "before deadline"):
                instance.wait_native_ready("banana")
            row = json.loads(next(Path(directory).glob("*.json")).read_text())
            self.assertEqual(row["pidof_output"], "")
            self.assertEqual(row["activity_dump"], self.foreground)
            self.assertEqual(next(Path(directory).glob("*.log")).read_text(), "unaltered native startup log\n")

    def test_ambiguous_and_invalid_process_identifiers_fail_immediately(self):
        for raw_pid in ("8241 8242", "unknown", "0", "-1"):
            with self.subTest(raw_pid=raw_pid), tempfile.TemporaryDirectory() as directory:
                instance = self.instance(directory, [(self.foreground, raw_pid)])
                with patch.object(probe.time, "monotonic", side_effect=[0, 0]), \
                     self.assertRaisesRegex(RuntimeError, "ambiguous or.*invalid"):
                    instance.wait_native_ready("banana")
                self.assertEqual(json.loads(next(Path(directory).glob("*.json")).read_text())["pidof_output"], raw_pid)

    def test_reference_title_and_capture_still_follow_actual_readiness(self):
        instance = probe.ReferenceProbe.__new__(probe.ReferenceProbe)
        calls = Mock()
        instance.base = SimpleNamespace(adb=calls.adb)
        instance.tap, instance.native_see, instance.capture = calls.tap, calls.see, calls.capture
        instance.wait_native_ready = calls.ready
        calls.ready.return_value = 8241
        self.assertEqual(instance.enter_native("banana", "Wörter bauen"), 8241)
        self.assertEqual([entry[0] for entry in calls.mock_calls], ["adb", "tap", "ready", "see", "capture"])
        calls.see.assert_called_once_with("Wörter bauen", "banana-native-title")


class OriginalAndCoreEvidenceTest(unittest.TestCase):
    def snapshot(self):
        return {"profile": {"id": "fictional", "name": probe.learning.PROFILE_NAME, "grade": 1},
                "learning": {"flutter.lumo_attempt_log_v1": "[]"}}

    def test_reference_reset_inherits_the_same_logged_strict_path_reader(self):
        with tempfile.TemporaryDirectory() as temporary:
            instance = probe.ReferenceProbe.__new__(probe.ReferenceProbe)
            instance.out = Path(temporary)
            path = "/data/app/~~opaque==/dev.ullmann.lumo-random==/base.apk"
            raw = "package:" + path + "\n"
            instance.base = SimpleNamespace(adb=lambda *args: raw)
            self.assertEqual(instance.read_installed_base_apk_path("original-before-reset"), path)
            self.assertEqual((instance.out / "original-before-reset-pm-path.txt").read_text(), raw)
            raw = "package:/data/app/app/../base.apk"
            with self.assertRaises(RuntimeError):
                instance.read_installed_base_apk_path("original-before-reset")
            self.assertEqual((instance.out / "original-before-reset-pm-path.txt").read_text(), raw)

    def test_successful_original_and_performance_are_required_before_reset(self):
        identity = {"sha256": probe.APK_SHA256, "versionCode": 2027, "signingCertificateSha256": probe.CERTIFICATE}
        result = {"schema": "lumo.nextgen.learning.android.probe", "status": "PASS_WITH_LIMITATIONS",
                  "candidate": identity, "installed": identity, "historical_tour_pass_used": False,
                  "private_app_data_written_by_probe": False, "final_profile": self.snapshot()["profile"],
                  "native_learning": {"performance": {"capture_status": "MEASURED", "scene_observed_seconds": 12,
                    "window_count": 2, "sample_count": 200, "combined_audio_figure_effect_windows": [3],
                    "current_step_replay_playback": {"utterance_ids": [12]},
                    "video": {"whole_block_within_recording_limit": True}}}}
        probe.verify_original_success(result, identity)
        for key, value in (("status", "FAIL"), ("candidate", {"sha256": "a" * 64}),
                           ("historical_tour_pass_used", True), ("private_app_data_written_by_probe", True),
                           ("native_learning", {}), ("final_profile", {"name": "real-child", "grade": 1})):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_original_success({**result, key: value}, identity)

    def test_explicit_core_answer_requires_one_current_assisted_persisted_result(self):
        task = {"prompt": "current visible pattern", "next": "Quadrat"}
        before, after = self.snapshot(), self.snapshot()
        self.assertIsNone(probe.verify_core_submission(before, after, task))
        entry = {"id": "new-attempt", "sub": "Logik", "unit": "Muster", "q": task["prompt"],
                 "a": "Quadrat", "e": "Quadrat", "ok": True, "hint": True}
        after["learning"]["flutter.lumo_attempt_log_v1"] = json.dumps([entry])
        self.assertEqual(probe.verify_core_submission(before, after, task)["status"], "PASS")
        for key, value in (("q", "old question"), ("a", "Kreis"), ("ok", False), ("hint", False)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(after)
                changed["learning"]["flutter.lumo_attempt_log_v1"] = json.dumps([{**entry, key: value}])
                probe.verify_core_submission(before, changed, task)

    def test_old_attempts_cannot_be_lost_rewritten_or_duplicated(self):
        task = {"prompt": "current", "next": "Stern"}
        before = self.snapshot()
        before["learning"]["flutter.lumo_attempt_log_v1"] = json.dumps([{"id": "old", "ok": False}])
        for entries in ([], [{"id": "old", "ok": True}], [{"id": "old"}, {"id": "old"}]):
            with self.subTest(entries=entries), self.assertRaises(RuntimeError):
                after = self.snapshot()
                after["learning"]["flutter.lumo_attempt_log_v1"] = json.dumps(entries)
                probe.verify_core_submission(before, after, task)


PANEL_FIXTURE = Path(__file__).parent / "fixtures/nextgen_panel_43816667737"
PANEL_BEFORE = "0343-runtime-banana-slower-panel.png"
PANEL_AFTER = "0344-runtime-failure-current-screen.png"


class PanelFixtureSequence:
    """Real unchanged PNGs; explicitly simulated captures, clock and OCR rows.

    The original run never reached panel OCR. These constructed rows test the
    caller's gates, not Android OCR success or a newly recorded second frame.
    """
    def __init__(self, frames):
        self.frames, self.current = frames, None
        self.now, self.captures, self.ocr_reads = 0.0, 0, 0
        self.inputs, self.saved = [], {}
        self.rows = [
            {"text": "Frag Lumo", "bounds": [80, 690, 440, 750]},
            {"text": "Zurück", "bounds": [780, 700, 940, 750]},
            {"text": "Noch einmal", "bounds": [110, 1700, 400, 1740]},
            {"text": "Langsamer", "bounds": [480, 1700, 740, 1740]},
            {"text": "Ein Hinweis", "bounds": [780, 1700, 990, 1740]},
        ]
        spec = importlib.util.spec_from_file_location(
            "panel_fixture_surface", ROOT / "tools/android_qa/native_surface_readiness.py")
        self.surface = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.surface)
        self.instance = object.__new__(probe.ReferenceProbe)
        self.instance.out, self.instance.counter = PANEL_FIXTURE, 0
        self.instance.native_tap = lambda *args: self.inputs.append(("question", args))
        self.instance.save = lambda name, value: self.saved.__setitem__(name, copy.deepcopy(value))
        self.instance.base = SimpleNamespace(adb=lambda *args, **kwargs: self.inputs.append(("scroll", args)))
        self.instance.reader = SimpleNamespace(capture=self.capture, inspect_surface=self.inspect,
            image_lines=self.ocr, target_observation=self.surface.target_observation)

    def sleep(self, seconds):
        self.now += seconds

    def capture(self, *args, **kwargs):
        self.current = self.frames[min(self.captures, len(self.frames) - 1)]
        self.captures += 1
        self.now += self.current.get("seconds", 1)
        source = PANEL_FIXTURE / self.current["file"]
        return {"file": source.name, "sha256": probe.digest(source), "width": 1080, "height": 2340}

    def inspect(self, source, **kwargs):
        frame = self.surface.inspect_surface(source, **kwargs)
        if self.current.get("partial"):
            frame["acceptable_for_target_sampling"] = False
        return frame

    def ocr(self, *args, **kwargs):
        self.ocr_reads += 1
        self.now += self.current.get("ocr_seconds", 0)
        return self.current.get("rows", self.rows)


class QuestionPanelReadinessTest(unittest.TestCase):
    def execute(self, sequence):
        with patch.object(probe.time, "monotonic", lambda: sequence.now), \
                patch.object(probe.time, "sleep", sequence.sleep):
            return sequence.instance.question_repeat_target()

    def test_original_no_panel_then_open_panel_is_observed_after_only_one_question_tap(self):
        sequence = PanelFixtureSequence([
            {"file": PANEL_BEFORE}, {"file": PANEL_AFTER}, {"file": PANEL_AFTER}])
        target = self.execute(sequence)
        self.assertEqual(target, (110, 1700, 400, 1740))
        self.assertEqual(sequence.captures, 3)
        self.assertEqual(sequence.inputs, [("question", ("Lumo fragen", "banana-open-question"))])
        self.assertEqual(next(iter(sequence.saved.values()))["state"], "PANEL_NOT_YET_OBSERVED")

    def test_original_fixture_hashes_pixels_and_observed_single_tap_are_bound(self):
        manifest = json.loads((PANEL_FIXTURE / "manifest.json").read_text())
        for name, record in manifest["files"].items():
            raw = (PANEL_FIXTURE / name).read_bytes()
            self.assertEqual(len(raw), record["bytes"])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), record["sha256"])
        with self.assertRaises(probe.QuestionPanelNotObserved):
            probe.observed_panel_background(PANEL_FIXTURE / PANEL_BEFORE)
        self.assertEqual(probe.observed_panel_background(PANEL_FIXTURE / PANEL_AFTER), (40, 606, 1040, 1803))
        journal = json.loads((PANEL_FIXTURE / "0342-runtime-banana-open-question-surface-readiness.json").read_text())
        self.assertEqual(journal["status"], "TOUCH_SENT")
        self.assertEqual(journal["label"], "Lumo fragen")
        self.assertEqual(len(journal["frames"]), 2)
        self.assertTrue(journal["frames"][-1]["target"]["stable_observed_target"])
        self.assertEqual(journal["touch"], [691, 1974])

    def test_missing_panel_never_passes_and_uses_only_the_original_twelve_attempts(self):
        sequence = PanelFixtureSequence([{"file": PANEL_BEFORE}])
        with self.assertRaisesRegex(RuntimeError, "did not settle"):
            self.execute(sequence)
        self.assertEqual(sequence.captures, 12)
        self.assertEqual(len(sequence.inputs), 1)
        self.assertEqual(sequence.ocr_reads, 0)
        self.assertEqual(len(sequence.saved), 12)

    def test_panel_first_seen_on_final_attempt_cannot_supply_two_stable_frames(self):
        sequence = PanelFixtureSequence([{"file": PANEL_BEFORE}] * 11 + [{"file": PANEL_AFTER}])
        with self.assertRaisesRegex(RuntimeError, "did not settle"):
            self.execute(sequence)
        self.assertEqual(sequence.captures, 12)
        self.assertEqual(len(sequence.inputs), 1)

    def test_scattered_pixels_and_changed_geometry_are_not_readiness_waits(self):
        for answers, message, captures in (
            ([RuntimeError("Ambiguous scattered question-panel pixels")], "Ambiguous scattered", 1),
            ([(40, 606, 1040, 1803), (60, 606, 1060, 1803)], "geometry changed", 2),
        ):
            with self.subTest(message=message):
                sequence = PanelFixtureSequence([{"file": PANEL_AFTER}])
                with patch.object(probe, "observed_panel_background", side_effect=answers), \
                        self.assertRaisesRegex(RuntimeError, message):
                    self.execute(sequence)
                self.assertEqual(sequence.captures, captures)
                self.assertEqual(len(sequence.inputs), 1)

    def test_panel_disappearance_after_observation_does_not_reuse_its_heading_or_target(self):
        sequence = PanelFixtureSequence([{"file": PANEL_AFTER}, {"file": PANEL_BEFORE}, {"file": PANEL_AFTER}])
        with self.assertRaisesRegex(RuntimeError, "panel disappeared"):
            self.execute(sequence)
        self.assertEqual(sequence.captures, 2)
        self.assertEqual(len(sequence.inputs), 1)

    def test_partial_transition_requires_fresh_heading_and_two_fresh_targets(self):
        sequence = PanelFixtureSequence([
            {"file": PANEL_AFTER}, {"file": PANEL_AFTER, "partial": True},
            {"file": PANEL_AFTER}, {"file": PANEL_AFTER}])
        self.assertEqual(self.execute(sequence), (110, 1700, 400, 1740))
        self.assertEqual(sequence.captures, 4)
        sequence = PanelFixtureSequence([
            {"file": PANEL_AFTER}, {"file": PANEL_AFTER, "partial": True}, {"file": PANEL_AFTER}])
        sequence.frames[-1]["rows"] = sequence.rows[2:]
        with self.assertRaisesRegex(RuntimeError, "heading missing"):
            self.execute(sequence)
        self.assertEqual(sequence.captures, 3)
        self.assertEqual(len(sequence.inputs), 1)

    def test_missing_heading_or_shortcut_sibling_does_not_authorize_a_target(self):
        sequence = PanelFixtureSequence([{"file": PANEL_AFTER}])
        sequence.frames[0]["rows"] = sequence.rows[2:]
        with self.assertRaisesRegex(RuntimeError, "heading missing"):
            self.execute(sequence)
        self.assertEqual(len(sequence.inputs), 1)
        sequence = PanelFixtureSequence([{"file": PANEL_AFTER}])
        sequence.frames[0]["rows"] = sequence.rows[:3]
        with self.assertRaisesRegex(RuntimeError, "did not settle"):
            self.execute(sequence)
        self.assertEqual(sequence.captures, 12)
        self.assertEqual(sum(kind == "question" for kind, _ in sequence.inputs), 1)
        self.assertEqual(sum(kind == "scroll" for kind, _ in sequence.inputs), 12)


if __name__ == "__main__":
    unittest.main()
