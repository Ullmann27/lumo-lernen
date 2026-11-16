"""Bind the existing observed active-stop flow to this new build's identity.

The 2031 runner and its immutable result verifier remain unchanged. Only its
version-neutral bridge_active_stop action is reused, including every live
PID/playback, two-frame target, 45-second and later quiet-window guard.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("current_stop_observed_action",
    HERE / "lumo_nextgen_2031_native_runtime_cases.py")
observed = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(observed)
learning, reference = observed.learning, observed.reference
require, digest = observed.require, observed.digest
SCHEMA = "lumo.nextgen.current.native.active_stop"


def banana_digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                     ensure_ascii=False).encode()).hexdigest()


def current_identity(candidate, qa_commit):
    require(isinstance(candidate, dict) and type(candidate.get("versionCode")) is int and
            candidate["versionCode"] >= 2032, "Current native stop requires a new candidate from 2032")
    return learning.verify_provenance(candidate, sha256=candidate.get("sha256"), source=qa_commit,
        native=candidate.get("godot", {}).get("revision"), version=candidate["versionCode"],
        certificate=reference.CERTIFICATE)


def require_complete_banana(banana, profile_id):
    require(banana.get("word") == "Banane" and banana.get("syllables") == ["Ba", "na", "ne"] and
        len(banana.get("steps", [])) == 3 and banana.get("repeat_playback", {}).get("segments") == 4 and
        len(banana.get("repeat_playback", {}).get("utterance_ids", [])) == 4 and
        banana.get("repeat_video", {}).get("whole_block_within_recording_limit") is True and
        banana.get("native_answer_submitted") is False and bool(profile_id) and
        banana.get("preservation", {}).get("profile_id") == profile_id,
        "Current native stop must follow the complete Banane flow for this profile")


def verify_current_native_stop(result, *, candidate, qa_commit, workflow_run_id, profile_id, banana):
    """Validate only the new current-build stop result, never a historic replay."""
    identity = current_identity(candidate, qa_commit)
    require(isinstance(result, dict) and result.get("schema") == SCHEMA and
        type(result.get("version")) is int and result["version"] == 1 and
        result.get("status") == "PASS_WITH_LIMITATIONS" and result.get("mode") == "current-build" and
        result.get("candidate") == identity and result.get("qa_commit") == qa_commit and
        result.get("apk_source") == qa_commit and result.get("native_source") == identity["godot"]["revision"] and
        type(workflow_run_id) is int and workflow_run_id > 0 and
        type(result.get("workflow_run_id")) is int and result["workflow_run_id"] == workflow_run_id and
        result.get("helper_sha256") == digest(Path(__file__)) and
        result.get("observed_helper_sha256") == digest(Path(observed.__file__)) and
        result.get("installation_or_reset_performed") is False and
        result.get("flow_phase") == "after_complete_banana_before_pattern" and
        result.get("completed_banana_sha256") == banana_digest(banana),
        "Current native stop is missing or has a different source/helper/tour identity")
    require_complete_banana(banana, profile_id)
    installed = result.get("installed", {})
    path = installed.get("apk_path", "")
    require(learning.installed_base_apk_path("package:" + path) == path,
            "Current native stop lacks its observed installed APK path")
    hashed = re.fullmatch(r"([0-9a-f]{64})\s+" + re.escape(path), installed.get("sha256_output", "").strip())
    require(hashed is not None, "Current native stop installed APK hash response is ambiguous")
    metadata = learning.verify_installed_metadata(installed.get("package_dump", ""), hashed[1], identity)
    require(metadata == installed.get("metadata"), "Current native stop installed metadata changed")
    before, after = result.get("before", {}), result.get("after", {})
    preserved = learning.require_preserved(before, after)
    require(before.get("profile", {}).get("id") == profile_id and result.get("preservation") == preserved,
            "Current native stop changed the profile or learning/reward data")
    case = result.get("bridge_active_stop", {})
    model = {"kind": "bridge_ten", "a": 8, "b": 5, "placed": 2, "visible_label": "2 / 5 bewegt"}
    require(case.get("status") == "PASS_WITH_LIMITATIONS" and case.get("current_task") == "Acht und fünf" and
        case.get("model_before") == model == case.get("model_after") and case.get("native_answer_submitted") is False and
        case.get("preservation", {}).get("profile_id") == profile_id and
        case["preservation"].get("same_task_checkpoint") is True,
        "Current native stop lacks the preserved actual bridge task")
    video = case.get("video", {})
    require(video.get("whole_block_within_recording_limit") is True and
        type(video.get("duration_seconds")) in (int, float) and math.isfinite(video["duration_seconds"]) and
        video["duration_seconds"] > 0 and learning.valid_hex(video.get("sha256", ""), 64) and
        bool(video.get("file")) and video.get("audio_recorded") is False and
        all(bool(case.get(key, {}).get("file")) for key in
            ("before_screenshot", "after_screenshot", "returned_to_academy")),
        "Current native stop video or observed return is missing")
    active, touch, idle = (case.get(name, {}) for name in
                          ("active_before_stop", "stop_touch", "returned_voice_control"))
    previous = case.get("previous_ids", [])
    require(isinstance(previous, list) and all(type(value) is int and value > 0 for value in previous) and
        type(active.get("pid")) is int and active["pid"] > 0 and active.get("profile") == observed.PROFILE and
        type(active.get("utterance_id")) is int and active["utterance_id"] > max(previous, default=0) and
        active.get("started_observed") is True and active.get("completed_observed") is False and
        case.get("stop_control") == touch.get("label") == observed.STOP and idle.get("label") == observed.IDLE and
        touch.get("stable_observed_target") is True and idle.get("stable_observed_target") is True and
        bool(touch.get("capture", {}).get("file")) and bool(idle.get("capture", {}).get("file")) and
        type(touch.get("elapsed_before_input")) in (int, float) and 0 <= touch["elapsed_before_input"] <= 45 and
        type(case.get("observation_seconds")) in (int, float) and 5 <= case["observation_seconds"] <= 60 and
        case.get("minimum_observation_seconds") == 5 and case.get("no_late_new_segments") is True and
        case.get("active_id_completed_after_stop") is False and
        all(case.get(key) is False for key in ("question_menu_opened_during_active_window",
            "stop_event_available_in_host_log", "acoustic_stop_verified", "mouth_gesture_stop_verified",
            "millisecond_stop_verified")),
        "Current native stop lacks live playback/target/quiet guards or overstates acoustic evidence")
    return result


def run_current_native_stop(probe):
    """No installation/reset: use this tour's current, freshly rechecked APK."""
    args = probe.args
    identity = current_identity(probe.candidate_identity(), args.qa_commit)
    record = {"schema": SCHEMA, "version": 1, "status": "RUNNING", "mode": "current-build",
        "candidate": identity, "qa_commit": args.qa_commit, "apk_source": identity["flutter_source_commit"],
        "native_source": identity["godot"]["revision"], "workflow_run_id": args.workflow_run_id,
        "helper_sha256": digest(Path(__file__)), "observed_helper_sha256": digest(Path(observed.__file__)),
        "installation_or_reset_performed": False, "flow_phase": "after_complete_banana_before_pattern",
        "completed_banana_sha256": banana_digest(probe.result.get("banana", {}))}
    probe.result["current_native_active_stop"] = record
    try:
        require(probe.result.get("mode") == "current-build" and probe.result.get("candidate") == identity and
            probe.result.get("qa_commit") == args.qa_commit == args.expected_source and
            probe.result.get("source_workflow_run") == args.workflow_run_id,
            "Current native stop does not belong to this installed source tour")
        path = probe.read_installed_base_apk_path(probe.fresh("current-stop-installed"))
        package_dump = probe.base.adb("shell", "dumpsys", "package", learning.PACKAGE, timeout=30)
        hashed = probe.base.adb("shell", "sha256sum", path, timeout=30)
        match = re.fullmatch(r"([0-9a-f]{64})\s+" + re.escape(path), hashed.strip())
        record["installed"] = {"apk_path": path, "package_dump": package_dump, "sha256_output": hashed}
        require(match is not None, "Current native stop installed APK hash response is ambiguous")
        metadata = learning.verify_installed_metadata(package_dump, match[1], identity)
        record["installed"]["metadata"] = metadata
        require(metadata == probe.result.get("installed"), "Current native stop installation changed since onboarding")
        before = learning.learning_snapshot(probe.preferences("current-stop-learning-before"))
        record["before"] = before
        require_complete_banana(probe.result.get("banana", {}), before["profile"]["id"])
        record["bridge_active_stop"] = observed.bridge_active_stop(probe)
        after = learning.learning_snapshot(probe.preferences("current-stop-learning-after"))
        record.update(after=after, preservation=learning.require_preserved(before, after), status="PASS_WITH_LIMITATIONS")
        verify_current_native_stop(record, candidate=identity, qa_commit=args.qa_commit,
            workflow_run_id=args.workflow_run_id, profile_id=before["profile"]["id"], banana=probe.result["banana"])
        return record
    except Exception as error:
        record.update(status="FAIL", error=str(error))
        raise
