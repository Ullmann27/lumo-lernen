#!/usr/bin/env python3
"""Additional observed cases on immutable APK 2031; never release acceptance.

The unchanged 2031 downloader supplies candidate/source evidence. This entry
requires its own disposable, initially uninstalled emulator and creates a
fictional profile through onboarding. It neither consumes nor replaces the
complete original/reference tour and never writes private application data.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import time
import traceback
import uuid

HERE = Path(__file__).resolve().parent


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


immutable = module("runtime_cases_2031_identity", HERE / "lumo_nextgen_2031_replay_reference_android_probe.py")
reference, learning = immutable.reference, immutable.learning
require, digest, read_json, write_json = immutable.require, immutable.digest, immutable.read_json, immutable.write_json
CONFIG = HERE / "lumo_nextgen_2031_runtime_cases.json"
CASES = ["numeric_wrong_then_correct", "flutter_switch_during_syllable_playback",
         "native_banana_slower", "native_stop_during_playback"]
RECALL_PROMPT = "9 + 7 = ? Rechne zuerst bis zur Zehn."
WRONG_FEEDBACK = "Deine Zahl liegt um eins daneben. Prüfe: Der erste Schritt beginnt nach der Startzahl."
WORD_BUILD_PROMPT = "Baue „Banane“ aus seinen Sprechstücken. Ein Baustein bleibt übrig."
WORD_RECALL_PROMPT = "Schreibe das Namenwort: Ra – ke – te."
NEXT = "Jetzt selbstständig antworten"
ACTIVE_SYLLABLE = re.compile(r"^Silbe ([123]): (Ba|na|ne), gerade aktiv$")
SYLLABLE = re.compile(r"^Silbe ([123]): (Ba|na|ne)(?:, gerade aktiv)?$")


def native_cases_module():
    return module("runtime_cases_2031_native", HERE / "lumo_nextgen_2031_native_runtime_cases.py")


def verify_runtime_config(config):
    fixed = {"schemaVersion": 1, "apkSource": immutable.SOURCE, "nativeSource": immutable.NATIVE,
             "sourceBuildRun": immutable.SOURCE_RUN, "versionName": immutable.VERSION_NAME,
             "versionCode": immutable.VERSION, "cases": CASES}
    require(isinstance(config, dict) and set(config) == set(fixed) | {"caseAttempt"},
            "Unexpected immutable runtime-cases configuration fields")
    for key, expected in fixed.items():
        require(type(config.get(key)) is type(expected) and config[key] == expected,
                "Wrong immutable runtime-cases configuration: " + key)
    require(type(config["caseAttempt"]) is int and config["caseAttempt"] > 0,
            "caseAttempt must be a positive integer")
    return config


def journey(snapshot, subject, unit):
    matches = []
    for key, raw in snapshot["learning"].items():
        if not key.startswith("flutter.lumo_progress_journey_v1"):
            continue
        value = read_json(raw)
        require(value.get("version") == 1 and isinstance(value.get("records"), dict),
                "Unexpected persisted journey schema")
        for record in value["records"].values():
            if record.get("subject") == subject and record.get("unit") == unit:
                matches.append((key, record))
    require(len(matches) == 1, "Exactly one current subject/unit journey required")
    return matches[0]


def verify_numeric_submission(before, after, checkpoint_before, checkpoint_after, *, correct):
    """An actual new attempt plus the separately persisted lab/journey identity."""
    require(before["profile"] == after["profile"], "Numeric submission changed the fictional profile")
    old, new = reference.attempts(before), reference.attempts(after)
    prior = {item["id"]: item for item in old}
    current = {item["id"]: item for item in new}
    require(all(current.get(key) == value for key, value in prior.items()),
            "Numeric submission lost or rewrote a previous attempt")
    added = [item for item in new if item["id"] not in prior]
    require(len(added) == 1, "One explicit numeric check must save exactly one new attempt")
    attempt = added[0]
    wanted = {"sid": "self", "sub": "Mathematik", "unit": "Plus bis 20",
              "q": RECALL_PROMPT, "a": "16" if correct else "15", "e": "16", "ok": correct}
    require(all(type(attempt.get(key)) is type(value) and attempt[key] == value for key, value in wanted.items()),
            "Stored numerical assessment does not match this explicit 9+7 submission")
    require(type(attempt.get("hint", False)) is bool and attempt.get("hint", False) is correct,
            "Correction must retain assistance; first wrong attempt must not invent help")
    for checkpoint in (checkpoint_before, checkpoint_after):
        require(checkpoint.get("topicId") == "bridge" and checkpoint.get("problemId") == "bridge-9-7" and
                checkpoint.get("phase") == "recall" and checkpoint.get("seed") == 0 and
                type(checkpoint.get("attempt")) is int and checkpoint["attempt"] >= 1 and
                checkpoint.get("pendingAttemptId") is None and checkpoint.get("support") == 0 and
                checkpoint.get("hint") == 0, "Wrong numeric task/phase or unfinished checkpoint")
    require(checkpoint_before.get("sessionId") == checkpoint_after.get("sessionId") and
            isinstance(checkpoint_after.get("sessionId"), str) and checkpoint_after["sessionId"] and
            checkpoint_after["attempt"] == checkpoint_before["attempt"] + 1 and
            checkpoint_before.get("done") is False and
            checkpoint_before.get("wrongBefore") is correct and
            checkpoint_after.get("wrongBefore") is True and checkpoint_after.get("done") is correct and
            checkpoint_after.get("answer") == wanted["a"], "Numeric checkpoint did not record this single check")
    saved_id = checkpoint_after.get("lastSavedAttemptId")
    require(saved_id == f"{checkpoint_after['sessionId']}-{checkpoint_after['attempt']}" and
            saved_id != checkpoint_before.get("lastSavedAttemptId"), "Lab saved-attempt identity did not advance")
    old_key, old_journey = journey(before, "Mathematik", "Plus bis 20")
    new_key, new_journey = journey(after, "Mathematik", "Plus bis 20")
    require(old_key == new_key, "Numeric journey changed its owner namespace")
    for key, delta in (("attempts", 1), ("assistedCorrect", int(correct)),
                       ("independentCorrect", 0), ("transferCorrect", 0)):
        require(type(old_journey.get(key)) is int and type(new_journey.get(key)) is int and
                new_journey[key] == old_journey[key] + delta, "Incorrect persisted journey delta: " + key)
    require(new_journey.get("recentTaskIds") == old_journey.get("recentTaskIds", []) + [saved_id] and
            new_journey.get("independentProblemIds") == old_journey.get("independentProblemIds"),
            "Missing/doubled lab attempt or correction counted as independent transfer")
    old_errors = old_journey.get("errorCounts", {})
    expected_errors = dict(old_errors)
    if not correct:
        expected_errors["one_off"] = expected_errors.get("one_off", 0) + 1
    require(new_journey.get("errorCounts") == expected_errors, "Wrong numerical error observation")
    return {"status": "PASS", "stored_attempt": attempt, "lab_attempt_id": saved_id,
            "journey_key": new_key, "journey_attempts": new_journey["attempts"],
            "support": {"checkpoint_support": checkpoint_after["support"],
                        "prior_wrong_answer": checkpoint_before["wrongBefore"],
                        "stored_hint_used": attempt.get("hint", False),
                        "assisted_correct_delta": int(correct)},
            "attempt_log_id_is_separate_from_lab_evidence_id": True}


def observed_active_next(nodes):
    """Only one fresh UI hierarchy can establish both playback cue and Next."""
    labels = []
    for node in nodes:
        if (node.get("package") != learning.PACKAGE or node.get("visible-to-user") != "true" or
                not learning.bounds(node, min_height=20)):
            continue
        labels.extend(learning.node_labels([node]))
    active = set()
    for label in labels:
        matched = ACTIVE_SYLLABLE.fullmatch(label)
        if matched:
            index, word = int(matched[1]), matched[2]
            require((index, word) in ((1, "Ba"), (2, "na"), (3, "ne")), "Contradictory current syllable label")
            active.add(label)
    require(len(active) <= 1, "Ambiguous simultaneous active syllables")
    target = learning.observed_control([node for node in nodes if node.get("visible-to-user") == "true"], NEXT)
    if not active or target is None:
        return None
    require("Die Wortwerkstatt" in labels, "Active syllable/Next are not in the current word lab")
    return {"active_label": next(iter(active)), "next_bounds": target, "next_label": NEXT,
            "evidence": "same fresh Android accessibility hierarchy"}


def switch_display(wm_size, wm_density):
    """Parse observed WM state, retaining the original override for restoration."""
    def values(raw, kind, pattern):
        lines = [line.strip() for line in raw.splitlines() if line.strip()]
        found = [re.fullmatch(r"(Physical|Override) " + kind + r":\s*(" + pattern + r")", line)
                 for line in lines]
        require(found and all(found) and found[0][1] == "Physical" and
                len({item[1] for item in found}) == len(found), "Ambiguous viewport WM " + kind)
        return {item[1]: item[2] for item in found}
    size, density = values(wm_size, "size", r"[1-9][0-9]*x[1-9][0-9]*"), values(wm_density, "density", r"[1-9][0-9]*")
    return {"wm_size": wm_size, "wm_density": wm_density,
            "size": list(map(int, size.get("Override", size["Physical"]).split("x"))),
            "density_dpi": int(density.get("Override", density["Physical"])),
            "physical_density_dpi": int(density["Physical"]),
            "density_override": int(density["Override"]) if "Override" in density else None}


def observed_switch_ready(nodes):
    """Require the syllable strip, Next and Replay in this same actual viewport."""
    visible = [node for node in nodes if node.get("package") == learning.PACKAGE and
               node.get("visible-to-user") == "true" and learning.bounds(node, min_height=32)]
    # Flutter merges this column's static text into one multiline description.
    # Match an entire recorded line, not an arbitrary substring or old caption.
    labels = {line.strip() for label in learning.node_labels(visible) for line in label.splitlines()}
    if not {"Die Wortwerkstatt", WORD_BUILD_PROMPT} <= labels:
        return None
    viewport = learning.observed_scroll_bounds(visible)
    next_box = learning.observed_control(visible, NEXT)
    replay_box = learning.observed_control(visible, "Noch einmal")
    syllables = {}
    for node in visible:
        for label in learning.node_labels([node]):
            match = SYLLABLE.fullmatch(label)
            if match:
                index, word = int(match[1]), match[2]
                require((index, word) in ((1, "Ba"), (2, "na"), (3, "ne")), "Contradictory viewport syllable")
                item = {"label": label, "bounds": learning.bounds(node, min_height=32)}
                require(index not in syllables or syllables[index] == item, "Ambiguous viewport syllable")
                syllables[index] = item
    if viewport is None or next_box is None or replay_box is None or set(syllables) != {1, 2, 3}:
        return None
    boxes = [next_box, replay_box] + [item["bounds"] for item in syllables.values()]
    if not all(viewport[0] <= box[0] < box[2] <= viewport[2] and
               viewport[1] <= box[1] < box[3] <= viewport[3] for box in boxes):
        return None
    return {"heading": "Die Wortwerkstatt", "prompt": WORD_BUILD_PROMPT,
            "syllables": [syllables[i] for i in (1, 2, 3)], "scroll_bounds": viewport,
            "next_bounds": next_box, "next_label": NEXT,
            "replay_bounds": replay_box, "replay_label": "Noch einmal"}


def verify_switch_viewport(case):
    viewport = case.get("viewport", {})
    require(viewport.get("mode") == "larger_logical_emulator_view" and
            viewport.get("standard_density_case") is False and viewport.get("physical_device_evidence") is False,
            "Missing explicit larger logical emulator viewport boundary")
    displays = []
    for name in ("original", "prepared", "restored"):
        record = viewport.get(name, {})
        display = record.get("display", {})
        require(display == switch_display(display.get("wm_size", ""), display.get("wm_density", "")),
                "Viewport display differs from its raw WM observation")
        shot = record.get("screenshot", {})
        require(display["size"] == [1080, 2340] and (shot.get("width"), shot.get("height")) == (1080, 2340) and
                learning.valid_hex(shot.get("sha256", ""), 64), "Viewport requires unchanged real pixel dimensions")
        displays.append(display)
    require(displays[0]["density_dpi"] > 320 and displays[1]["density_dpi"] == 320 and
            displays[1]["wm_size"] == displays[0]["wm_size"] and
            displays[1]["physical_density_dpi"] == displays[0]["physical_density_dpi"] and
            displays[2] == displays[0] and viewport["restored"].get("status") == "RESTORED",
            "Viewport density was not observed at 320 and restored exactly")
    for name, snapshot_key, checkpoint_key in (("prepared", "before", "checkpoint_before"),
                                              ("restored", "after", "checkpoint_after")):
        record = viewport[name]
        expected = learning.require_preserved(case[snapshot_key], record["snapshot"],
                                             case[checkpoint_key], record["checkpoint"])
        require(record.get("preservation") == expected, "Viewport changed the current task or learning state")
    ready = case.get("replay_preparation", {})
    require(ready.get("heading") == "Die Wortwerkstatt" and ready.get("prompt") == WORD_BUILD_PROMPT and
            ready.get("next_label") == NEXT and ready.get("replay_label") == "Noch einmal" and
            learning.valid_hex(ready.get("xml_sha256", ""), 64) and
            type(ready.get("replay_taps")) is int and ready["replay_taps"] == 1,
            "Replay lacks one freshly observed joint viewport")
    syllables = ready.get("syllables", [])
    require(len(syllables) == 3 and all(SYLLABLE.fullmatch(item.get("label", "")) and
            SYLLABLE.fullmatch(item["label"]).groups() == (str(i), word)
            for item, (i, word) in zip(syllables, ((1, "Ba"), (2, "na"), (3, "ne")))),
            "Replay viewport lacks all three actual syllable labels")
    box = ready.get("scroll_bounds", [])
    targets = [ready.get("next_bounds", []), ready.get("replay_bounds", [])] + [s.get("bounds", []) for s in syllables]
    require(len(box) == 4 and all(type(v) is int for v in box) and
            all(len(b) == 4 and all(type(v) is int for v in b) and
                box[0] <= b[0] < b[2] <= box[2] and box[1] <= b[1] < b[3] <= box[3] for b in targets),
            "Replay controls were not observed together inside the viewport")
    start, finish, requested = (ready.get(key) for key in
        ("capture_started_monotonic", "capture_finished_monotonic", "replay_requested_monotonic"))
    require(all(type(v) in (int, float) and math.isfinite(v) for v in (start, finish, requested)) and
            0 <= start <= finish <= requested and requested - start <= 1 and
            case["observation"]["capture_started_monotonic"] >= requested,
            "Replay viewport observation became stale before its single requested tap")


def verify_word_switch(before, after, checkpoint_before, checkpoint_after):
    preserved = learning.require_preserved(before, after)
    require(checkpoint_before.get("topicId") == "words" and checkpoint_before.get("problemId") == "word-banane" and
            checkpoint_before.get("phase") == "build" and checkpoint_before.get("tokens") == [2, 3, 0] and
            checkpoint_before.get("done") is True and checkpoint_before.get("lastSavedAttemptId") and
            checkpoint_before.get("pendingAttemptId") is None and type(checkpoint_before.get("attempt")) is int and
            checkpoint_before.get("lastSavedAttemptId") ==
                f"{checkpoint_before.get('sessionId')}-{checkpoint_before['attempt']}",
            "No completed real Banane construction before playback")
    _, built = journey(before, "Deutsch", "Silben")
    require(checkpoint_before["lastSavedAttemptId"] in built.get("recentTaskIds", []) and
            type(built.get("assistedCorrect")) is int and built["assistedCorrect"] >= 1,
            "Banane construction is not present in its persisted accompanied evidence")
    require(checkpoint_after.get("topicId") == "words" and checkpoint_after.get("problemId") == "word-rakete" and
            checkpoint_after.get("phase") == "recall" and checkpoint_after.get("tokens") == [] and
            checkpoint_after.get("done") is False and checkpoint_after.get("answer") == "" and
            checkpoint_after.get("lastSavedAttemptId") is None and checkpoint_after.get("pendingAttemptId") is None and
            checkpoint_after.get("sessionId") == checkpoint_before.get("sessionId") and
            checkpoint_after.get("attempt") == checkpoint_before.get("attempt") and
            checkpoint_after.get("seed") == checkpoint_before.get("seed") == 0,
            "Playback switch did not reach the new unanswered task without an extra attempt")
    return {"status": "PASS", "preservation": preserved, "from_problem": "word-banane",
            "to_problem": "word-rakete", "same_session": True, "no_new_attempt_or_reward": True}


def verify_runtime_cases(result, *, qa_commit, workflow_run_id):
    """Pure final check for this additional evidence, never a publisher gate."""
    immutable.verify_qa_identity(qa_commit, workflow_run_id)
    require(result.get("schema") == "lumo.nextgen.runtime_cases.android" and
            type(result.get("version")) is int and result["version"] == 1 and
            result.get("status") == "PASS_WITH_LIMITATIONS" and result.get("mode") == "immutable-runtime-cases" and
            result.get("release_eligible") is False and result.get("original_probe_requirement_satisfied") is False and
            result.get("qa_commit") == qa_commit and result.get("qa_workflow_run") == workflow_run_id and
            result.get("apk_source") == immutable.SOURCE and result.get("native_source") == immutable.NATIVE and
            result.get("source_build_run") == immutable.SOURCE_RUN and
            result.get("historical_tour_pass_used") is False and result.get("private_app_data_written_by_probe") is False and
            result.get("apk_rebuilt_by_probe") is False and result.get("fullModernizationComplete") is False,
            "Runtime cases must keep their separate immutable, non-release identity")
    identity = immutable.fixed_identity(result.get("candidate", {}))
    verify_runtime_config(result.get("config"))
    installed = result.get("installed", {})
    require(all(type(installed.get(key)) is type(identity[key]) and installed[key] == identity[key]
                for key in ("package", "versionCode", "versionName", "sha256", "signingCertificateSha256")) and
            installed.get("signature_binding") == "installed base.apk hash equals independently signature-verified input APK" and
            type(result.get("device", {}).get("api")) is int and result["device"]["api"] == 35 and
            result["device"].get("abi") == "x86_64" and result["device"].get("physical_device") is False and
            result["device"].get("package_absent_before_install") is True and result.get("onboarding", {}).get("synthetic") is True,
            "Runtime cases require their own real fresh installation and UI profile")
    require(result.get("auto_read_restored_before_native") is True and
            result.get("final_profile") == result["onboarding"].get("profile"),
            "Runtime cases did not restore auto-read or preserve their own profile")
    changes = result.get("runtime_auto_read_ui_changes", [])
    require(len(changes) == 1 and changes[0].get("control") == "Automatisch vorlesen" and
            changes[0].get("private_preferences_written") is False and
            changes[0].get("before", {}).get("autoReadEnabled") is True and
            changes[0].get("after", {}).get("autoReadEnabled") is False and
            result.get("local_voice_settings", {}).get("auto_read") is True,
            "Temporary auto-read preparation and restored voice settings were not recorded")
    number = result.get("numeric_wrong_then_correct", {})
    require(number.get("status") == "PASS" and number.get("submission_control") == "Antwort prüfen" and
            number.get("input_method") == "real Android text input" and number.get("spoken_recognition_exercised") is False,
            "The numerical case is not an explicit UI-submitted correction")
    for correct, stage in ((False, "wrong"), (True, "corrected")):
        item = number.get(stage, {})
        actual = verify_numeric_submission(item["before"], item["after"], item["checkpoint_before"],
                                           item["checkpoint_after"], correct=correct)
        require(item.get("verification") == actual, "Numerical verification differs from its persisted evidence")
    require(number["wrong"]["after"] == number["corrected"]["before"] and
            number["wrong"]["checkpoint_after"] == number["corrected"]["checkpoint_before"] and
            number["wrong"]["verification"]["stored_attempt"]["id"] != number["corrected"]["verification"]["stored_attempt"]["id"],
            "Wrong and corrected answers must be two sequential distinct attempts")
    videos = [number[stage].get("video", {}) for stage in ("wrong", "corrected")]
    switch = result.get("flutter_switch_during_syllable_playback", {})
    require(switch.get("status") == "PASS" and switch.get("explicit_stop_before_switch") is False and
            switch.get("old_active_marker_absent") is True and
            switch.get("observation", {}).get("active_label") in
                ("Silbe 1: Ba, gerade aktiv", "Silbe 2: na, gerade aktiv", "Silbe 3: ne, gerade aktiv") and
            switch["observation"].get("next_label") == NEXT and
            learning.valid_hex(switch["observation"].get("xml_sha256", ""), 64),
            "Task switch lacks fresh simultaneous playback/Next evidence")
    timing = switch["observation"]
    started, finished, touched, elapsed = (timing.get("capture_started_monotonic"),
        timing.get("capture_finished_monotonic"), timing.get("touch_requested_monotonic"),
        switch.get("capture_to_touch_seconds"))
    require(all(type(value) in (int, float) and math.isfinite(value)
                for value in (started, finished, touched, elapsed)) and
            0 <= started <= finished <= touched and 0 <= elapsed <= 1 and
            abs((touched - started) - elapsed) <= 1e-6,
            "Active playback capture through requested touch exceeded its freshness budget")
    require(switch.get("verification") == verify_word_switch(switch["before"], switch["after"],
                switch["checkpoint_before"], switch["checkpoint_after"]), "Word-switch preservation mismatch")
    verify_switch_viewport(switch)
    videos.append(switch.get("video", {}))
    require(all(video.get("whole_block_within_recording_limit") is True and
                type(video.get("duration_seconds")) in (int, float) and video["duration_seconds"] > 0 and
                learning.valid_hex(video.get("sha256", ""), 64) and video.get("audio_recorded") is False
                for video in videos), "A runtime-case action is not covered by its actual complete video")
    native = result.get("native_runtime_cases", {})
    require(native.get("schema") == "lumo.nextgen.native.runtime.cases" and native.get("version") == 1 and
            native.get("status") == "PASS_WITH_LIMITATIONS" and native.get("candidate") == identity and
            all(native.get(key, {}).get("status") in ("PASS", "PASS_WITH_LIMITATIONS")
                for key in ("banana_slower", "bridge_active_stop")), "Both additional native cases must complete")
    native_cases_module().verify_native_cases(native, candidate=identity)
    return {"cases": CASES, "release_eligible": False, "full_replay_replaced": False}


class RuntimeCasesProbe(immutable.ReplayProbe):
    def switch_display_observation(self, tag):
        raw = {"wm_size": self.base.adb("shell", "wm", "size"),
               "wm_density": self.base.adb("shell", "wm", "density")}
        self.save(self.fresh(tag), raw)
        return switch_display(**raw)

    @contextmanager
    def word_switch_viewport(self, report):
        original = self.switch_display_observation("switch-original-display")
        require(original["size"] == [1080, 2340] and original["density_dpi"] > 320,
                "Unexpected original switch viewport size/density")
        viewport = {"mode": "larger_logical_emulator_view", "standard_density_case": False,
                    "physical_device_evidence": False, "original": {"display": original,
                    "screenshot": self.capture("switch-original-density")}}
        report["viewport"] = viewport
        require((viewport["original"]["screenshot"]["width"], viewport["original"]["screenshot"]["height"]) == (1080, 2340),
                "Original viewport PNG pixel dimensions differ")
        primary = None
        try:
            self.base.adb("shell", "wm", "density", "320")
            display = self.wait("Observed switch density 320", lambda: self.switch_display_observation("switch-density-320"),
                lambda item: item["density_dpi"] == 320 and item["wm_size"] == original["wm_size"] and
                item["physical_density_dpi"] == original["physical_density_dpi"], timeout=15)
            checkpoint = self.checkpoint("words", **report["checkpoint_before"])
            snapshot = learning.learning_snapshot(self.preferences("switch-density-320-learning"))
            viewport["prepared"] = {"display": display, "snapshot": snapshot, "checkpoint": checkpoint,
                "preservation": learning.require_preserved(report["before"], snapshot,
                    report["checkpoint_before"], checkpoint), "screenshot": self.capture("switch-density-320")}
            require((viewport["prepared"]["screenshot"]["width"], viewport["prepared"]["screenshot"]["height"]) == (1080, 2340),
                    "Prepared viewport PNG pixel dimensions differ")
            yield
        except BaseException as error:
            primary = error
            raise
        finally:
            try:
                restored_to = str(original["density_override"]) if original["density_override"] is not None else "reset"
                viewport["restore_command"] = ["wm", "density", restored_to]
                self.base.adb("shell", "wm", "density", restored_to)
                display = self.wait("Original switch density restored", lambda: self.switch_display_observation("switch-density-restored"),
                                    lambda item: item == original, timeout=15)
                viewport["restored_display_observation"] = display
                expected_checkpoint = report.get("checkpoint_after", report["checkpoint_before"])
                expected_snapshot = report.get("after", report["before"])
                checkpoint = self.checkpoint("words", **expected_checkpoint)
                snapshot = learning.learning_snapshot(self.preferences("switch-restored-learning"))
                viewport["restored"] = {"status": "RESTORED", "display": display, "snapshot": snapshot,
                    "checkpoint": checkpoint, "preservation": learning.require_preserved(expected_snapshot, snapshot,
                    expected_checkpoint, checkpoint), "screenshot": self.capture("switch-original-density-restored")}
                require((viewport["restored"]["screenshot"]["width"], viewport["restored"]["screenshot"]["height"]) == (1080, 2340),
                        "Restored viewport PNG pixel dimensions differ")
            except BaseException as error:
                viewport["restoration_error"] = {"type": type(error).__name__, "message": str(error)}
                if primary is None:
                    raise

    def start_visible_syllable_replay(self):
        # A replay from the footer at the original density leaves every syllable
        # offscreen. Position all three targets before this single new playback.
        deadline, gestures = time.monotonic() + 45, []
        while time.monotonic() < deadline:
            nodes = self.nodes("switch-joint-viewport")
            labels = learning.node_labels([n for n in nodes if n.get("package") == learning.PACKAGE and
                                          n.get("visible-to-user") == "true" and learning.bounds(n, min_height=32)])
            require(time.monotonic() < deadline, "Joint switch viewport arrived after its preparation deadline")
            require({"Die Wortwerkstatt", WORD_BUILD_PROMPT} <=
                    {line.strip() for label in labels for line in label.splitlines()},
                    "Word viewport owner/task is no longer visible")
            if observed_switch_ready(nodes) is not None:
                break
            viewport = learning.observed_scroll_bounds(nodes)
            require(viewport is not None and len(gestures) < 30, "No observed joint switch viewport before replay")
            has_syllable = any(SYLLABLE.fullmatch(label) for label in labels)
            lower_visible = learning.observed_control(nodes, NEXT) is not None or learning.observed_control(nodes, "Noch einmal") is not None
            direction = -1 if lower_visible and not has_syllable else 1
            x, y = (viewport[0] + viewport[2]) // 2, (viewport[1] + viewport[3]) // 2
            end = y - direction * max(1, (viewport[3] - viewport[1]) // 20)
            gesture = {"observed_scroll_bounds": viewport, "start": [x, y], "end": [x, end],
                       "direction": direction, "before_replay": True}
            self.save(self.fresh("switch-joint-viewport-scroll"), gesture)
            gestures.append(gesture)
            self.base.adb("shell", "input", "swipe", str(x), str(y), str(x), str(end), "400")
            time.sleep(.2)
        else:
            raise RuntimeError("No observed joint switch viewport before replay; no playback was requested")
        screenshot = self.capture("switch-joint-viewport-before-replay")
        name = self.fresh("switch-final-joint-viewport")
        started = time.monotonic()
        nodes = self.live.live_nodes(self.out, name)
        finished = time.monotonic()
        ready = observed_switch_ready(nodes)
        require(ready is not None, "Joint switch viewport changed before replay")
        ready.update(xml=name + ".xml", xml_sha256=digest(self.out / (name + ".xml")),
                     screenshot=screenshot, gestures=gestures, capture_started_monotonic=started,
                     capture_finished_monotonic=finished)
        requested = time.monotonic()
        require(requested < deadline and requested - started <= 1,
                "Replay viewport observation became stale before its requested tap")
        ready.update(replay_requested_monotonic=requested, replay_taps=1)
        self.touch(ready["replay_bounds"], "switch-start-observed-syllable-replay", "Noch einmal")
        return ready

    def switch_on_active_syllable(self, *, timeout=45):
        require(0 < timeout <= 45, "Unexpected active Flutter observation budget")
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            name = self.fresh("switch-live-active-and-next")
            capture_started = time.monotonic()
            nodes = self.live.live_nodes(self.out, name)
            capture_finished = time.monotonic()
            target = observed_active_next(nodes)
            if target is not None:
                require(capture_finished < deadline, "Active syllable arrived after its observation budget")
                xml = self.out / (name + ".xml")
                target.update(xml=xml.name, xml_sha256=digest(xml))
                touch_requested = time.monotonic()
                elapsed = touch_requested - capture_started
                require(touch_requested < deadline and elapsed <= 1,
                        "Active playback capture became stale before the requested touch")
                target.update(capture_started_monotonic=capture_started,
                              capture_finished_monotonic=capture_finished,
                              touch_requested_monotonic=touch_requested)
                self.touch(target["next_bounds"], "switch-first-active-next", NEXT)
                return {"observation": target, "capture_to_touch_seconds": elapsed}
            if learning.observed_control(nodes, NEXT) is None:
                self.scroll(nodes, 1)
            else:
                time.sleep(.1)
        raise RuntimeError("No fresh simultaneous active syllable and enabled Next; missed playback is not PASS")

    def set_auto_read_for_cases(self, enabled):
        # Called only while the real settings page is open. No preference write.
        before = self.settings("runtime-auto-read-before")
        if before.get("autoReadEnabled") is not enabled:
            self.tap("Automatisch vorlesen", "runtime-auto-read-visible-toggle")
        after = self.wait("Runtime auto-read setting saved", lambda: self.settings("runtime-auto-read-after"),
                          lambda value: value.get("autoReadEnabled") is enabled)
        require({k: v for k, v in before.items() if k != "autoReadEnabled"} ==
                {k: v for k, v in after.items() if k != "autoReadEnabled"}, "Unrelated setting changed")
        self.result.setdefault("runtime_auto_read_ui_changes", []).append({"before": before, "after": after,
                        "control": "Automatisch vorlesen", "private_preferences_written": False})
        self.capture("runtime-auto-read-" + ("on" if enabled else "off"))

    def numeric_wrong_then_correct(self):
        self.open_lab()
        self.tap("Die Zehnerbrücke", "numeric-bridge-entry")
        self.see(learning.BRIDGE_PROMPT, "numeric-example", scroll=True, exact=True)
        with self.recording("numeric-build-before-graded-recall"):
            self.tap("Jetzt gemeinsam bauen", "numeric-build-phase")
            for index in (1, 2):
                self.tap(f"Vorratsstein {index}, ins Feld verschieben", "numeric-build-stone")
            self.checkpoint("bridge", problemId="bridge-8-5", phase="build", moved=2)
            self.tap("Mein Modell prüfen", "numeric-model-check")
            self.checkpoint("bridge", problemId="bridge-8-5", phase="build", done=True, pendingAttemptId=None)
            self.tap(NEXT, "numeric-recall-phase")
            self.see(RECALL_PROMPT, "numeric-nine-plus-seven", scroll=True, exact=True)
            self.capture("numeric-before-wrong-answer")
        before_checkpoint = self.checkpoint("bridge", problemId="bridge-9-7", phase="recall", done=False, wrongBefore=False)
        before = learning.learning_snapshot(self.preferences("numeric-before-first-check"))
        report = {"status": "RUNNING", "prompt": RECALL_PROMPT, "problem_id": "bridge-9-7",
                  "submission_control": "Antwort prüfen", "input_method": "real Android text input",
                  "spoken_recognition_exercised": False, "exact_eight_plus_five_numeric_case": False}
        self.result["numeric_wrong_then_correct"] = report
        for given, correct, name in (("15", False, "wrong"), ("16", True, "corrected")):
            with self.recording("numeric-" + name + "-submission"):
                self.type_text(given, "numeric-" + name + "-input")
                self.capture("numeric-" + name + "-before-explicit-check")
                self.tap("Antwort prüfen", "numeric-" + name + "-explicit-check")
                checkpoint = self.checkpoint("bridge", problemId="bridge-9-7", phase="recall", answer=given,
                    done=correct, wrongBefore=True, pendingAttemptId=None, attempt=before_checkpoint["attempt"] + 1)
                self.see("Richtig! Diese Antwort war mit Hilfe." if correct else WRONG_FEEDBACK,
                         "numeric-" + name + "-feedback", scroll=True, exact=True)
                after = learning.learning_snapshot(self.preferences("numeric-" + name + "-stored"))
                verification = verify_numeric_submission(before, after, before_checkpoint, checkpoint, correct=correct)
                screenshot = self.capture("numeric-" + name + "-after-assessment")
            report[name] = {"before": before, "after": after, "checkpoint_before": before_checkpoint,
                            "checkpoint_after": checkpoint, "verification": verification,
                            "screenshot": screenshot, "video": self.recordings[-1]}
            before, before_checkpoint = after, checkpoint
        report["status"] = "PASS"
        self.close_task()

    def word_switch_during_playback(self):
        self.tap("Die Wortwerkstatt", "switch-word-entry")
        self.see(learning.WORD_PROMPT, "switch-current-banane", scroll=True, exact=True)
        with self.recording("switch-build-banane-and-retain-syllable-replay"):
            self.tap("Jetzt gemeinsam bauen", "switch-build-phase")
            for caption in ("Ba, Baustein 3, anlegen", "na, Baustein 4, anlegen", "ne, Baustein 1, anlegen"):
                self.tap(caption, "switch-build-word")
            self.checkpoint("words", problemId="word-banane", phase="build", tokens=[2, 3, 0])
            # Explicit syllables select the real replay path. Auto-read is off
            # so later model feedback does not replace it with a prose sentence.
            self.tap("Silben vorsprechen: Banane", "switch-select-syllable-audio")
            self.tap("Mein Modell prüfen", "switch-check-built-word")
            self.checkpoint("words", problemId="word-banane", phase="build", done=True, pendingAttemptId=None)
            self.see(NEXT, "switch-next-is-offered", scroll=True, exact=True)
        before_checkpoint = self.checkpoint("words", problemId="word-banane", phase="build", done=True)
        before = learning.learning_snapshot(self.preferences("switch-learning-before"))
        report = {"status": "RUNNING", "before": before, "checkpoint_before": before_checkpoint,
                  "explicit_stop_before_switch": False, "flutter_media_callbacks_in_native_log": False,
                  "acoustic_playback_verified": False}
        self.result["flutter_switch_during_syllable_playback"] = report
        with self.word_switch_viewport(report):
            with self.recording("switch-during-actual-active-syllable"):
                report["replay_preparation"] = self.start_visible_syllable_replay()
                report.update(self.switch_on_active_syllable())
                checkpoint = self.checkpoint("words", problemId="word-rakete", phase="recall", done=False, answer="")
                self.see(WORD_RECALL_PROMPT, "switch-new-rakete-prompt", scroll=True, exact=True)
                after_nodes = self.nodes("switch-no-old-active-syllable")
                require(not any("gerade aktiv" in label for label in learning.node_labels(after_nodes)),
                        "Old active syllable survived task replacement")
                after = learning.learning_snapshot(self.preferences("switch-learning-after"))
                verification = verify_word_switch(before, after, before_checkpoint, checkpoint)
                screenshot = self.capture("switch-new-unanswered-rakete")
                report.update(after=after, checkpoint_after=checkpoint, verification=verification,
                              old_active_marker_absent=True, screenshot=screenshot)
            report["video"] = self.recordings[-1]
        report["status"] = "PASS"
        self.close_task()
        self.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        self.see("LUMO AKADEMIE", "switch-back-to-academy")

    def run(self):
        # Deliberately do not call ReferenceProbe.run/reset_successful_original:
        # this is an independent additional installation, not a full replay.
        native = native_cases_module()
        self.result["native_runtime_module_sha256"] = digest(Path(native.__file__))
        self.identify_and_install()
        require(self.result["device"]["api"] == 35, "Runtime cases require API 35 exactly")
        self.onboard()
        self.configure_local_voice()
        self.set_auto_read_for_cases(False)
        self.academy()
        self.numeric_wrong_then_correct()
        self.word_switch_during_playback()
        self.configure_local_voice()
        self.result["auto_read_restored_before_native"] = self.settings("runtime-auto-read-restored").get("autoReadEnabled") is True
        require(self.result["auto_read_restored_before_native"], "Auto-read was not restored through settings")
        self.tap("Lernen", "runtime-native-handoff-academy")
        self.see("LUMO AKADEMIE", "runtime-native-handoff-visible")
        native.run_native_cases(self)
        self.result["final_profile"] = learning.learning_snapshot(self.preferences("runtime-final-profile"))["profile"]
        self.result["status"] = "PASS_WITH_LIMITATIONS"
        self.result["verification"] = verify_runtime_cases(self.result, qa_commit=self.args.qa_commit,
                                                           workflow_run_id=self.args.workflow_run_id)
        self.result["limitations"] = [
            "Additional runtime cases only; original/reference tours and release acceptance are separate and unchanged.",
            "The graded numeric task is 9+7, not the ungraded 8+5 demonstration; no spoken or misheard number was supplied.",
            "The Flutter switch observes the player's active syllable semantics, not native speech-log events or acoustic audio.",
            "The full XML-capture-to-requested-touch interval must stay within one second; a slower capture fails closed.",
            "The Flutter playback switch uses a larger logical emulator view at 1080x2340 pixels / 320dpi, restored before native cases; it does not establish this case at the original density or on physical Fold hardware.",
            "Auto-read is temporarily disabled through real settings to retain explicit syllable replay, then restored before native cases.",
            "Emulator videos contain no audio; no physical-device, pronunciation, acoustic speed, millisecond-stop or lip-sync claim.",
        ]


def run(args):
    require(not args.out.exists() or not any(args.out.iterdir()), "Runtime-case evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    result = {"schema": "lumo.nextgen.runtime_cases.android", "version": 1, "status": "RUNNING",
              "mode": "immutable-runtime-cases", "release_eligible": False, "original_probe_requirement_satisfied": False,
              "run_id": uuid.uuid4().hex, "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id, "apk_source": immutable.SOURCE,
              "native_source": immutable.NATIVE, "source_build_run": immutable.SOURCE_RUN,
              "probe_sha256": digest(Path(__file__)), "reference_probe_sha256": digest(Path(reference.__file__)),
              "historical_tour_pass_used": False, "private_app_data_written_by_probe": False,
              "apk_rebuilt_by_probe": False, "fullModernizationComplete": False}
    probe = None
    try:
        result["config"] = verify_runtime_config(immutable.load(CONFIG))
        result["config_sha256"] = digest(CONFIG)
        immutable.verify_ci_context(args.qa_commit, args.workflow_run_id, os.environ)
        immutable.verify_download_record(args.download_evidence, args.candidate, args.qa_commit, args.workflow_run_id)
        result["source_binding"] = immutable.verify_source_binding(args.qa_commit, args.workflow_run_id,
                                                    args.out / "qa-source-binding.json")
        args.apk, args.provenance = args.candidate / "Lumo-Lernen-Neu.apk", args.candidate / "BUILD-PROVENANCE.json"
        args.expected_sha256, args.expected_source, args.expected_native = immutable.APK_SHA, immutable.SOURCE, immutable.NATIVE
        args.expected_version, args.expected_certificate, args.conversation_ui = immutable.VERSION, immutable.CERTIFICATE, "ea"
        require(shutil.which("ffprobe"), "ffprobe is required for actual video validation")
        probe = RuntimeCasesProbe(args, result)
        probe.run()
        return 0
    except Exception as error:
        result.update(status="FAIL", error=str(error), traceback=traceback.format_exc())
        if probe:
            try:
                probe.capture("runtime-failure-current-screen", native=True)
            except Exception as failure:
                result["failure_capture_error"] = str(failure)
        print(traceback.format_exc(), file=sys.stderr, flush=True)
        return 1
    finally:
        result["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        write_json(args.out / "runtime-cases-result.json", result)
        print(json.dumps({key: result[key] for key in ("status", "run_id", "qa_commit", "apk_source", "release_eligible")}), flush=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ("candidate", "download-evidence", "out"):
        parser.add_argument("--" + flag, type=Path, required=True)
    parser.add_argument("--qa-commit", required=True)
    parser.add_argument("--workflow-run-id", required=True, type=int)
    parser.add_argument("--serial")
    return run(parser.parse_args(argv))


if __name__ == "__main__":
    raise SystemExit(main())
