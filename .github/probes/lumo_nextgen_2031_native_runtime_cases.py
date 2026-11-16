#!/usr/bin/env python3
"""Two additional visible native cases on an already verified 2031 installation.

No install, reset, private state injection or publication occurs here. The caller
owns the existing ReferenceProbe-compatible instance and the full result file.
MediaPlayer logs prove callbacks, not spoken words, speed or an acoustic stop.
"""
from __future__ import annotations

import hashlib
import importlib.util
import math
from pathlib import Path
import re
import time

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("native_runtime_reference", HERE / "lumo_nextgen_reference_android_probe.py")
reference = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reference)
learning = reference.learning
require, digest = reference.require, reference.digest

SOURCE = "e05a96a52aaf57e466e79831f15aaffd144284ee"
NATIVE = "678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef"
APK_SHA = "8e96a05c51fc12504a19831cee14b64c6a8e9a35a8a36863db455bed0e2cec1a"
PCK_SHA = "94b0a84b8715537fff9ff84e451c889ca1fe1b8440a4448ded93989b3feb0aef"
PROFILE = "lumo-free-supertonic-de-v1"
SLOWER, STOP, IDLE = "Langsamer", "Stimme stoppen", "Schritt anhören"


def remaining(deadline):
    value = deadline - time.monotonic()
    require(value > 0, "Native runtime observation deadline expired")
    return value


def current_events(log, pid, previous_ids):
    require(type(pid) is int and pid > 0, "A real unique native PID is required")
    previous = set(previous_ids)
    for raw_pid, payload in re.findall(r"(?m)^I/LumoLearningSpeech\s*\(\s*(\d+)\):\s*failed (\{.*\})\s*$", log):
        if int(raw_pid) == pid:
            failure = learning.read_json(payload)
            require(type(failure.get("id")) is int and failure["id"] in previous,
                    "Current native playback reported an explicit failure")
    events = [(state, int(turn), profile) for raw_pid, state, turn, profile in learning.speech_events(log)
              if int(raw_pid) == pid and int(turn) not in previous]
    for state, turn, profile in events:
        require(turn > max(previous, default=0), "Unseen older playback ID cannot prove this action")
        require(profile == PROFILE if state == "started" else profile in ("", PROFILE),
                "Unexpected current native voice profile")
    return events


def active_playback(log, pid, previous_ids):
    """No fresh events means wait; an already completed/mixed turn fails closed."""
    events = current_events(log, pid, previous_ids)
    if not events:
        return None
    require(len(events) == 1 and events[0][0] == "started",
            "Playback completed or changed before the direct stop")
    return {"pid": pid, "utterance_id": events[0][1], "profile": PROFILE,
            "started_observed": True, "completed_observed": False}


def verify_stopped_window(log, pid, previous_ids, utterance_id):
    require(current_events(log, pid, previous_ids) == [("started", utterance_id, PROFILE)],
            "Stopped turn completed, disappeared, or produced an unexpected later segment")


def slower_target(rows, panel):
    """Select the exact shortcut only within the currently observed panel."""
    def inside(row):
        box = row.get("bounds", ())
        return len(box) == 4 and panel[0] <= box[0] < box[2] <= panel[2] and panel[1] <= box[1] < box[3] <= panel[3]

    anchor = any(inside(row) and reference.normalized(row.get("text", "")) in
                 (reference.normalized("Noch einmal"), reference.normalized("Ein Hinweis")) for row in rows)
    matches = {tuple(row["bounds"]) for row in rows if inside(row) and
               reference.normalized(row.get("text", "")) == reference.normalized(SLOWER)}
    if not anchor or not matches:
        return None
    target = min(matches)
    require(all(abs(a - b) <= 12 for other in matches for a, b in zip(target, other)),
            "Ambiguous Langsamer controls inside the observed panel")
    return target


def question_slower_target(probe):
    probe.native_tap("Lumo fragen", "runtime-banana-open-question")
    deadline = time.monotonic() + 90
    previous, panel_before, heading_seen = None, None, False
    while remaining(deadline):
        tag = probe.fresh("runtime-banana-slower-panel")
        shot = probe.reader.capture(probe.out, tag, timeout=remaining(deadline))
        source = probe.out / shot["file"]
        frame = probe.reader.inspect_surface(source, orientation="responsive")
        if not frame["acceptable_for_target_sampling"]:
            previous = None
            heading_seen = False
            continue
        try:
            panel = reference.observed_panel_background(source)
        except reference.QuestionPanelNotObserved:
            require(panel_before is None, "Previously observed question panel disappeared")
            previous, heading_seen = None, False
            probe.save(tag + "-pending", {"capture": shot, "state": "PANEL_NOT_YET_OBSERVED"})
            continue
        if panel_before is not None:
            require(all(abs(a - b) <= 12 for a, b in zip(panel, panel_before)), "Question panel moved during shortcut selection")
        panel_before = panel
        rows = probe.reader.image_lines(probe.out, tag, reference.normalized(SLOWER), source_path=source,
            exact=True, all_caption_regions=True, timeout=min(30, remaining(deadline)))
        if not heading_seen:
            heading_seen = all(any(reference.normalized(row["text"]) == reference.normalized(label) and
                panel[0] <= row["bounds"][0] < row["bounds"][2] <= panel[2] and
                panel[1] <= row["bounds"][1] < row["bounds"][3] <= panel[3] for row in rows)
                for label in ("Frag Lumo", "Zurück"))
            require(heading_seen, "Current Frag Lumo panel and its Zurück header were not observed")
        target = slower_target(rows, panel)
        record = {"capture": shot, "panel_bounds": panel, "heading_observed": heading_seen, "captions": rows}
        if target is None:
            probe.save(tag + "-scroll", record)
            x = (panel[0] + panel[2]) // 2
            low, high = panel[3] - (panel[3] - panel[1]) // 5, panel[1] + (panel[3] - panel[1]) // 5
            probe.base.adb("shell", "input", "swipe", str(x), str(low), str(x), str(high), "400", timeout=min(5, remaining(deadline)))
            previous = None
            continue
        observed = probe.reader.target_observation(frame, target, previous)
        record["target"] = observed
        probe.save(tag + "-target", record)
        previous = observed
        if observed["stable_observed_target"]:
            remaining(deadline)
            require(digest(source) == frame["source_sha256"], "Question screenshot changed during observation")
            return target


def observed_voice_target(probe, label, deadline, guard=lambda: None):
    """Two fresh full-frame observations; guard can reject completion during OCR."""
    previous = None
    while remaining(deadline):
        guard()
        tag = probe.fresh("runtime-voice-" + ("stop" if label == STOP else "idle"))
        shot = probe.reader.capture(probe.out, tag, timeout=remaining(deadline))
        source = probe.out / shot["file"]
        frame = probe.reader.inspect_surface(source, orientation="responsive")
        if not frame["acceptable_for_target_sampling"]:
            previous = None
            continue
        # All lines of a real full-frame OCR variant are retained. There is no
        # assumed footer crop or remembered stop-button coordinate.
        rows = probe.reader.image_lines(probe.out, tag, reference.normalized(label), source_path=source,
                                        exact=True, timeout=min(12, remaining(deadline)))
        selected, selection = probe.reader.standalone_caption_target(rows, label, pixels=frame["pixels"])
        guard()
        observed = probe.reader.target_observation(frame, selected["bounds"], previous) if selected else None
        probe.save(tag + "-target", {"label": label, "capture": shot, "selection": selection, "target": observed})
        previous = observed
        if observed and observed["stable_observed_target"]:
            remaining(deadline)
            require(digest(source) == frame["source_sha256"], "Voice-control screenshot changed during observation")
            return {"label": label, "bounds": observed["bounds"], "capture": shot,
                    "source_sha256": frame["source_sha256"], "stable_observed_target": True}


def stop_active_playback(probe, pid, previous_ids, *, timeout=45, quiet_seconds=5):
    """One direct observed stop, never a retry or a question-panel action."""
    require(0 < timeout <= 45 and 5 <= quiet_seconds <= 10, "Unexpected active-stop observation budget")
    deadline, began = time.monotonic() + timeout, time.monotonic()
    record = {"status": "RUNNING", "pid": pid, "previous_ids": sorted(previous_ids), "observations": [],
              "question_menu_opened_during_active_window": False, "stop_event_available_in_host_log": False,
              "acoustic_stop_verified": False, "mouth_gesture_stop_verified": False, "millisecond_stop_verified": False}
    journal = probe.fresh("runtime-active-stop")

    def read(phase, end):
        raw_pid = probe.base.adb("shell", "pidof", learning.PACKAGE + ":lumo_game", check=False, timeout=min(3, remaining(end)))
        record["observations"].append({"phase": phase, "raw_pid": raw_pid, "elapsed_seconds": time.monotonic() - began})
        probe.save(journal, record)
        require(raw_pid.split() == [str(pid)], "The current native playback process changed")
        log = probe.speech_log(timeout=min(5, remaining(end)))
        record["observations"][-1]["speech_log_sha256"] = hashlib.sha256(log.encode()).hexdigest()
        remaining(end)
        return log

    try:
        active = None
        while active is None:
            active = active_playback(read("waiting-for-start", deadline), pid, previous_ids)
            if active is None:
                time.sleep(min(.25, remaining(deadline)))
        record["active_before_stop"] = active

        def still_active():
            require(active_playback(read("fresh-active-check", deadline), pid, previous_ids) == active,
                    "Current playing turn was lost before stop")

        target = observed_voice_target(probe, STOP, deadline, still_active)
        still_active()  # No navigation, OCR or wait between this check and input.
        x = round((target["bounds"][0] + target["bounds"][2]) / 2)
        y = round((target["bounds"][1] + target["bounds"][3]) / 2)
        record["stop_touch"] = {**target, "point": [x, y], "elapsed_before_input": time.monotonic() - began}
        probe.save(journal, record)
        probe.base.adb("shell", "input", "swipe", str(x), str(y), str(x), str(y), "120", timeout=min(5, remaining(deadline)))
        remaining(deadline)
        stopped_at = time.monotonic()
        quiet_deadline = stopped_at + quiet_seconds + 10
        while True:
            verify_stopped_window(read("after-direct-stop", quiet_deadline), pid, previous_ids, active["utterance_id"])
            if time.monotonic() - stopped_at >= quiet_seconds:
                break
            time.sleep(min(.25, remaining(quiet_deadline)))
        idle = observed_voice_target(probe, IDLE, time.monotonic() + 25)
        verify_stopped_window(read("after-visible-idle", time.monotonic() + 8), pid, previous_ids, active["utterance_id"])
        record.update(status="PASS_WITH_LIMITATIONS", returned_voice_control=idle,
            observation_seconds=time.monotonic() - stopped_at, minimum_observation_seconds=quiet_seconds,
            no_late_new_segments=True, active_id_completed_after_stop=False)
        return record
    except Exception as error:
        record.update(status="FAIL", error=str(error))
        raise
    finally:
        probe.save(journal, record)


def retained_video(probe):
    value = probe.recordings[-1]
    require(value["whole_block_within_recording_limit"] and value["duration_seconds"] > 0,
            "The actual case video did not cover the bounded block")
    return value


def back_to_academy(probe, tag):
    probe.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
    probe.see("Lumo erklärt es mir", tag + "-guided-hub", exact=True)
    probe.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
    probe.see("LUMO AKADEMIE", tag + "-academy", exact=True)
    return probe.capture(tag + "-academy")


def banana_slower(probe):
    probe.academy()
    probe.tap("Lumo erklärt es mir", "runtime-banana-guided-hub")
    for _ in range(30):
        nodes = probe.nodes("runtime-banana-course")
        target = reference.associated_start(nodes, "Wörter in Silben hören")
        if target:
            probe.touch(target, "runtime-banana-course-start", "Wörter in Silben hören / Mit Lumo anfangen")
            break
        probe.scroll(nodes, 1)
    else:
        raise RuntimeError("Current syllable course start was not observed")
    for title in ("Wir hören genau hin", "Sprechen statt Buchstaben zählen"):
        probe.see(title, "runtime-banana-guided-step", scroll=True, exact=True)
        probe.tap("Weiter", "runtime-banana-next")
    probe.see(reference.BANANA_TITLE, "runtime-banana-task", scroll=True, exact=True)
    before = learning.learning_snapshot(probe.preferences("runtime-banana-before-native"))
    pid = probe.enter_native("runtime-banana", "Wörter bauen")
    probe.native_see("Banane", "runtime-banana-word")
    probe.native_see("Als Nächstes kommt die Silbe „Ba“", "runtime-banana-first-syllable")
    initial = probe.playback(pid, ())
    probe.native_see(IDLE, "runtime-banana-initial-complete", exact=True)
    model = {"kind": "syllables", "word": "Banane", "placed": 0, "total": 3, "visible_label": "0 / 3 bewegt"}
    probe.native_see(model["visible_label"], "runtime-banana-model-before")
    start_image = probe.capture("runtime-banana-before-slower", native=True)
    target = question_slower_target(probe)
    previous = probe.ids(pid)
    with probe.recording("runtime-banana-four-slower-segments"):
        probe.touch(target, "runtime-banana-slower", "Frag Lumo / " + SLOWER)
        playback = probe.playback(pid, previous, segments=4)
        probe.native_see(IDLE, "runtime-banana-slower-completed", exact=True)
        probe.native_see(model["visible_label"], "runtime-banana-model-after")
        end_image = probe.capture("runtime-banana-after-slower", native=True)
        rows = probe.reader.image_lines(probe.out, probe.fresh("runtime-banana-panel-closed"), reference.normalized("Frag Lumo"),
            source_path=probe.out / end_image["file"], exact=True, all_caption_regions=True, timeout=30)
        require(not any(reference.normalized(row["text"]) == reference.normalized("Frag Lumo") for row in rows),
                "Slower shortcut did not close the actual question panel")
    video = retained_video(probe)
    probe.return_native("runtime-banana", reference.BANANA_TITLE)
    probe.see(reference.BANANA_TITLE, "runtime-banana-same-guided-step", scroll=True, exact=True)
    after = learning.learning_snapshot(probe.preferences("runtime-banana-after-native"))
    result = {"status": "PASS_WITH_LIMITATIONS", "action": "slower", "control": "Frag Lumo / " + SLOWER,
        "current_task": reference.BANANA_TITLE, "model_before": model, "model_after": dict(model),
        "initial_playback": initial, "previous_ids": sorted(previous), "playback": playback,
        "segment_order_source_contract": ["Banane", "Ba", "na", "ne"], "actual_rate_in_log": False,
        "segment_words_verified_acoustically": False, "acoustic_speed_verified": False,
        "source_rate_contract": {"formula": "max(0.70, baseRate * 0.75)", "native_source": NATIVE,
            "apk_source": SOURCE, "controller": "tools/auto_install/LumoLearningConversation.kt",
            "segments": "scripts/learning/learning_world.gd::_speak_syllables",
            "playback": "tools/auto_install/LumoLearningSpeech.kt::MediaPlayer.playbackParams.setSpeed"},
        "preservation": learning.require_preserved(before, after, model, dict(model)),
        "native_answer_submitted": False, "before_screenshot": start_image, "after_screenshot": end_image, "video": video}
    result["returned_to_academy"] = back_to_academy(probe, "runtime-banana-return")
    return result


def bridge_active_stop(probe):
    probe.academy()
    probe.guided_course()
    before = learning.learning_snapshot(probe.preferences("runtime-bridge-before-native"))
    pid = probe.enter_native("runtime-bridge", "Zahlen zum Anfassen")
    initial = probe.playback(pid, ())
    # The existing real why-two flow prepares a longer checked explanation and
    # finishes it first. Its menu is never opened in the subsequent stop window.
    why = probe.native_bridge_question(pid)
    probe.native_see(IDLE, "runtime-bridge-explanation-complete", exact=True)
    model = {"kind": "bridge_ten", "a": 8, "b": 5, "placed": 2, "visible_label": "2 / 5 bewegt"}
    probe.native_see(model["visible_label"], "runtime-bridge-model-before-stop")
    start_image = probe.capture("runtime-bridge-before-replay-stop", native=True)
    previous = probe.ids(pid)
    with probe.recording("runtime-bridge-current-playback-direct-stop"):
        probe.native_tap(IDLE, "runtime-bridge-start-current-explanation")
        stopped = stop_active_playback(probe, pid, previous)
        probe.native_see(model["visible_label"], "runtime-bridge-model-after-stop")
        end_image = probe.capture("runtime-bridge-after-stop", native=True)
        verify_stopped_window(probe.speech_log(), pid, previous, stopped["active_before_stop"]["utterance_id"])
    video = retained_video(probe)
    probe.return_native("runtime-bridge", "Acht und fünf")
    probe.see("Acht und fünf", "runtime-bridge-same-guided-step", scroll=True, exact=True)
    after = learning.learning_snapshot(probe.preferences("runtime-bridge-after-native"))
    result = {**stopped, "current_task": "Acht und fünf", "stop_control": STOP,
        "model_before": model, "model_after": dict(model), "initial_playback": initial,
        "prepared_explanation": why, "native_answer_submitted": False,
        "preservation": learning.require_preserved(before, after, model, dict(model)),
        "before_screenshot": start_image, "after_screenshot": end_image, "video": video}
    result["returned_to_academy"] = back_to_academy(probe, "runtime-bridge-return")
    return result


def verify_native_cases(result, *, candidate):
    """Same pure result gate for the case runner and its separate QA entry."""
    require(result.get("schema") == "lumo.nextgen.native.runtime.cases" and
        type(result.get("version")) is int and result["version"] == 1 and
        result.get("status") == "PASS_WITH_LIMITATIONS" and result.get("candidate") == candidate and
        candidate.get("sha256") == APK_SHA and candidate.get("flutter_source_commit") == SOURCE and
        candidate.get("versionCode") == 2031 and candidate.get("versionName") == "0.13.19" and
        candidate.get("package") == learning.PACKAGE and candidate.get("signingCertificateSha256") == reference.CERTIFICATE and
        candidate.get("godot", {}).get("revision") == NATIVE and candidate["godot"].get("pck_sha256") == PCK_SHA and
        result.get("module_sha256") == digest(Path(__file__)) and
        result.get("installation_or_reset_performed") is False and result.get("final_screen") == "LUMO AKADEMIE",
        "Native case result is not this unchanged 2031 installation and helper")
    banana, bridge = result.get("banana_slower", {}), result.get("bridge_active_stop", {})
    for case, title, model in ((banana, reference.BANANA_TITLE,
            {"kind": "syllables", "word": "Banane", "placed": 0, "total": 3, "visible_label": "0 / 3 bewegt"}),
            (bridge, "Acht und fünf", {"kind": "bridge_ten", "a": 8, "b": 5, "placed": 2, "visible_label": "2 / 5 bewegt"})):
        require(case.get("status") == "PASS_WITH_LIMITATIONS" and case.get("current_task") == title and
            case.get("model_before") == model == case.get("model_after") and case.get("native_answer_submitted") is False and
            case.get("preservation", {}).get("same_task_checkpoint") is True and
            bool(case.get("preservation", {}).get("profile_id")), "Native case changed its visible task/model or lacks preservation evidence")
        video = case.get("video", {})
        require(video.get("whole_block_within_recording_limit") is True and
            type(video.get("duration_seconds")) in (int, float) and math.isfinite(video["duration_seconds"]) and video["duration_seconds"] > 0 and
            learning.valid_hex(video.get("sha256", ""), 64) and bool(video.get("file")) and
            bool(case.get("before_screenshot", {}).get("file")) and bool(case.get("after_screenshot", {}).get("file")) and
            bool(case.get("returned_to_academy", {}).get("file")), "Actual native case video/screenshots/return are missing")
    playback = banana.get("playback", {})
    ids = playback.get("utterance_ids", [])
    require(banana.get("action") == "slower" and banana.get("control") == "Frag Lumo / " + SLOWER and
        banana.get("segment_order_source_contract") == ["Banane", "Ba", "na", "ne"] and
        type(playback.get("pid")) is int and playback["pid"] > 0 and playback.get("profile") == PROFILE and
        playback.get("segments") == 4 and len(ids) == 4 and all(type(value) is int and value > 0 for value in ids) and
        ids == sorted(set(ids)) and not set(ids).intersection(banana.get("previous_ids", [])) and
        banana.get("actual_rate_in_log") is False and banana.get("acoustic_speed_verified") is False and
        banana.get("segment_words_verified_acoustically") is False,
        "Banana slower action lacks four current ordered playback segments or overstates acoustic evidence")
    active, touch, idle = (bridge.get(name, {}) for name in ("active_before_stop", "stop_touch", "returned_voice_control"))
    require(type(active.get("pid")) is int and active["pid"] > 0 and active.get("profile") == PROFILE and
        type(active.get("utterance_id")) is int and active["utterance_id"] > max(bridge.get("previous_ids", []), default=0) and
        active.get("started_observed") is True and active.get("completed_observed") is False and
        bridge.get("stop_control") == touch.get("label") == STOP and idle.get("label") == IDLE and
        touch.get("stable_observed_target") is True and idle.get("stable_observed_target") is True and
        bool(touch.get("capture", {}).get("file")) and bool(idle.get("capture", {}).get("file")) and
        type(bridge.get("observation_seconds")) in (int, float) and 5 <= bridge["observation_seconds"] <= 60 and
        bridge.get("minimum_observation_seconds") == 5 and bridge.get("no_late_new_segments") is True and
        bridge.get("active_id_completed_after_stop") is False and
        all(bridge.get(key) is False for key in ("question_menu_opened_during_active_window", "stop_event_available_in_host_log",
            "acoustic_stop_verified", "mouth_gesture_stop_verified", "millisecond_stop_verified")),
        "Direct stop lacks fresh active playback, visible controls, bounded later observation or accurate limitations")
    return result


def run_native_cases(probe):
    require("native_runtime_cases" not in probe.result, "Native cases may run only once per result")
    candidate, installed = probe.result.get("candidate", {}), probe.result.get("installed", {})
    require(candidate.get("flutter_source_commit") == SOURCE and candidate.get("sha256") == APK_SHA and
        candidate.get("versionCode") == 2031 and candidate.get("versionName") == "0.13.19" and
        candidate.get("package") == learning.PACKAGE and candidate.get("signingCertificateSha256") == reference.CERTIFICATE and
        candidate.get("godot", {}).get("revision") == NATIVE and candidate["godot"].get("pck_sha256") == PCK_SHA and
        all(installed.get(key) == candidate.get(key) for key in ("sha256", "versionCode", "signingCertificateSha256")),
        "Native runtime cases require the already verified unchanged 2031 installation")
    result = {"schema": "lumo.nextgen.native.runtime.cases", "version": 1, "status": "RUNNING",
              "candidate": candidate, "module_sha256": digest(Path(__file__)), "installation_or_reset_performed": False}
    probe.result["native_runtime_cases"] = result
    try:
        probe.see("LUMO AKADEMIE", "runtime-native-cases-start", exact=True)
        profile = learning.learning_snapshot(probe.preferences("runtime-native-cases-profile"))["profile"]
        require(profile.get("name") == learning.PROFILE_NAME and profile.get("grade") == 1,
                "Expected the existing synthetic grade-1 UI profile")
        result["banana_slower"] = banana_slower(probe)
        result["bridge_active_stop"] = bridge_active_stop(probe)
        result["final_profile"] = learning.learning_snapshot(probe.preferences("runtime-native-cases-final-profile"))["profile"]
        require(result["final_profile"] == profile, "Native runtime cases changed the synthetic profile")
        result.update(status="PASS_WITH_LIMITATIONS", final_screen="LUMO AKADEMIE", limitations=[
            "Four current callbacks plus visible Langsamer prove the selected action; rate and words are source-bound, not acoustically measured.",
            "Stop is bounded by fresh started-without-completed evidence, visible idle and absence of later segments in the recorded window; the host logs no explicit stop callback.",
            "No acoustic, millisecond, mouth, gesture or physical-device stop result is inferred; videos contain no audio track."])
        verify_native_cases(result, candidate=candidate)
        return result
    except Exception as error:
        result.update(status="FAIL", error=str(error))
        raise
    finally:
        probe.save("native-runtime-cases", result)
