#!/usr/bin/env python3
"""Additional UI cases on the already built, immutable 2032 APK.

Historical 2031 runners/gates are not changed. This independent QA installation
reuses their observed case methods, keeps current source identity separate from
QA identity, and has no publisher or full-tour acceptance effect.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import time
import traceback
import urllib.error
import urllib.parse
import urllib.request
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


legacy = module("observed_runtime_cases_2031", HERE / "lumo_nextgen_2031_runtime_cases_android_probe.py")
native = legacy.native_cases_module()
reference, learning = legacy.reference, legacy.learning
require, digest, read_json, write_json = reference.require, reference.digest, reference.read_json, reference.write_json
SOURCE = "9b38360ca5f21919dce4a2b99e605ee39bbbf454"
NATIVE = "9d6ef1d704a0e54098a8f8f0818f36deae0e3789"
SOURCE_RUN, VALIDATION_JOB, BUILD_JOB = 43837592237, 133197989015, 133206155437
VERSION, VERSION_NAME = 2032, "0.13.20"
CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
PCK_SHA = "e7313f1cd28dd00ee324e6798aec6be65e91b28a09bb2b5d2a012a45de5953e7"
ARTIFACT_ID, ARTIFACT_NAME = 14213246542, "lumo-nextgen-x86"
ZIP_BYTES, APK_BYTES = 538205955, 538191855
ZIP_SHA = "d2cd0e5fd84fd963108a33e1ef4d84995c10f2139071984374d30e56ffb3fdb3"
APK_SHA = "388c03118b2677817eba130610d9a8e32e964d91f644f61a9a2bcf5141465ad1"
QA_BRANCH = "qa/lumo-nextgen-2032-runtime-cases-20261116"
CONFIG = HERE / "lumo_nextgen_2032_runtime_cases.json"
CASES = ["numeric_wrong_then_correct", "flutter_switch_during_syllable_playback",
         "native_banana_slower", "native_pattern_then_explicit_core_answer"]
IMMUTABLE_CONFIG = {
    "schemaVersion": 1, "apkSource": SOURCE, "nativeSource": NATIVE,
    "sourceBuildRun": SOURCE_RUN, "sourceValidateJob": VALIDATION_JOB, "sourceBuildJob": BUILD_JOB,
    "package": learning.PACKAGE, "versionName": VERSION_NAME, "versionCode": VERSION,
    "certificate": CERTIFICATE, "pckSha256": PCK_SHA, "cases": CASES,
    "x86Artifact": {"id": ARTIFACT_ID, "name": ARTIFACT_NAME, "zipBytes": ZIP_BYTES,
                    "zipSha256": ZIP_SHA, "apkBytes": APK_BYTES, "apkSha256": APK_SHA},
}
QA_FILES = frozenset((
    ".github/probes/lumo_nextgen_2032_runtime_cases_android_probe.py",
    ".github/probes/lumo_nextgen_2032_runtime_cases.json",
    ".github/workflows/lumo-nextgen-2032-runtime-cases.yml",
    "tools/android_qa/tests/test_nextgen_2032_runtime_cases.py", "STATUS.md", "CONTINUE.md",
))
QA_PREFIXES = ("docs/", "tools/android_qa/tests/fixtures/nextgen_2032_runtime_cases/")
HELPERS = (
    ".github/probes/lumo_nextgen_2031_runtime_cases_android_probe.py",
    ".github/probes/lumo_nextgen_2031_native_runtime_cases.py",
    ".github/probes/lumo_nextgen_2031_replay_reference_android_probe.py",
    ".github/probes/lumo_nextgen_current_reference_android_probe.py",
    ".github/probes/lumo_nextgen_reference_android_probe.py",
    ".github/probes/lumo_nextgen_learning_android_probe.py",
    ".github/probes/lumo_nextgen_native_reader.py",
    ".github/probes/creative_android_probe.py",
)
RATE_HOST_HASHES = {
    "tools/auto_install/LumoLearningConversation.kt": "f3a09318752f819e65be5c8de7486dba1287ae71b5ae5831aed17d5f298904fc",
    "tools/auto_install/LumoLearningSpeech.kt": "6855fcf77abada42a7b59178e013108ef641f523007200be5c916d4e39e096c8",
}
# Reviewed from the exact native Git object; this is source provenance, not a
# runtime rate measurement. APK installation also verifies this revision/PCK.
RATE_NATIVE_SOURCE = {
    "path": "scripts/learning/learning_world.gd",
    "sha256": "1e12a51ee1264c86bdf7e83fc0073e36aae766b777b56923ff80e3a8cf449fca",
    "function": "_speak_syllables",
    "function_sha256": "b7e9819cb5c4478818ba52dab9999bd418cb38d23e9e5df45b848e8753aca6da",
}
ORIGIN_FILES = ("original-run.json", "original-x86-artifact.json",
                "original-validate-job.json", "original-build-job.json")
HEADER = "Wähle die richtige Antwort:"


def helper_hashes():
    return {path: digest(ROOT / path) for path in HELPERS}


def source_rate_contract():
    return {"formula": "max(0.70, baseRate * 0.75)", "apk_source": SOURCE,
        "native_source": NATIVE, "pck_sha256": PCK_SHA,
        "host_source_sha256": dict(RATE_HOST_HASHES), "native_source_review": dict(RATE_NATIVE_SOURCE),
        "binding": "Exact source fingerprints and installed APK/PCK identity; not a rate emitted by MediaPlayer",
        "native_source_read_on_runner": False, "runtime_rate_measured": False}


def load(path):
    return read_json(Path(path).read_text(encoding="utf-8"))


def verify_config(config):
    require(isinstance(config, dict) and set(config) == set(IMMUTABLE_CONFIG) | {"caseAttempt"},
            "Unexpected immutable replay configuration fields")
    for key, expected in IMMUTABLE_CONFIG.items():
        actual = config.get(key)
        require(type(actual) is type(expected) and actual == expected, "Wrong immutable replay field: " + key)
        if isinstance(expected, dict):
            require(all(type(actual.get(k)) is type(v) for k, v in expected.items()),
                    "Wrong immutable artifact field type")
    require(type(config["caseAttempt"]) is int and config["caseAttempt"] > 0,
            "Replay attempt must be a positive integer")
    return config


def verify_qa_identity(qa_commit, qa_workflow_run):
    require(learning.valid_hex(qa_commit, 40) and qa_commit != SOURCE,
            "Replay requires a distinct exact QA commit, not the APK source")
    require(type(qa_workflow_run) is int and qa_workflow_run > 0 and qa_workflow_run != SOURCE_RUN,
            "Replay requires its own workflow run, not the source build run")


def verify_ci_context(qa_commit, qa_workflow_run, environment):
    verify_qa_identity(qa_commit, qa_workflow_run)
    require(environment.get("GITHUB_REPOSITORY") == reference.REPOSITORY and
            environment.get("GITHUB_SHA") == qa_commit and
            environment.get("GITHUB_RUN_ID") == str(qa_workflow_run) and
            environment.get("GITHUB_REF_NAME") == QA_BRANCH,
            "Replay must run in its exact QA repository, branch, commit and workflow")


def allowed_qa_path(name):
    path = PurePosixPath(name)
    return (isinstance(name, str) and bool(name) and "\\" not in name and
            not path.is_absolute() and all(p not in ("", ".", "..") for p in name.split("/")) and
            (name in QA_FILES or name.startswith(QA_PREFIXES)))


def verify_source_binding(qa_commit, qa_workflow_run, output):
    """Compare committed trees; sparse checkout must not hide a product delta."""
    def git(*arguments):
        return subprocess.check_output(["git", *arguments], cwd=ROOT)

    require(git("rev-parse", "HEAD").decode().strip() == qa_commit, "Checkout is not the requested QA commit")
    require(not git("status", "--porcelain", "--untracked-files=no").strip(), "Tracked QA checkout is modified")
    changed = git("diff", "--name-only", "--no-renames", "-z", SOURCE, qa_commit).decode().split("\0")
    changed = [name for name in changed if name]
    require(changed and all(allowed_qa_path(name) for name in changed),
            "QA source differs in a runtime or unapproved path: " + repr([n for n in changed if not allowed_qa_path(n)]))
    for path in HELPERS:
        require(hashlib.sha256(git("show", SOURCE + ":" + path)).hexdigest() == digest(ROOT / path),
                "Inherited observed helper differs from the APK source: " + path)
    for path, expected in RATE_HOST_HASHES.items():
        require(hashlib.sha256(git("show", SOURCE + ":" + path)).hexdigest() == expected,
                "Current rate-controller source differs from reviewed bytes")
    record = {"helper_sha256": helper_hashes(), "source_rate_contract": source_rate_contract(), "mode": "immutable-runtime-cases", "qa_commit": qa_commit, "qa_workflow_run": qa_workflow_run,
              "apk_source": SOURCE, "source_build_run": SOURCE_RUN,
              "apk_source_tree": git("rev-parse", SOURCE + "^{tree}").decode().strip(),
              "qa_tree": git("rev-parse", qa_commit + "^{tree}").decode().strip(),
              "changed_paths": changed, "runtime_source_changed": False, "config_sha256": digest(CONFIG)}
    output.parent.mkdir(parents=True, exist_ok=True)
    require(not output.exists(), "Source binding evidence must be new")
    write_json(output, record)
    return record


def fixed_identity(proof):
    identity = learning.verify_provenance(proof, sha256=APK_SHA, source=SOURCE, native=NATIVE,
                                          version=VERSION, certificate=CERTIFICATE)
    require(identity["versionName"] == VERSION_NAME and identity["godot"]["pck_sha256"] == PCK_SHA,
            "Wrong immutable 2032 versionName/native pack")
    require(identity.get("abis") == ["x86_64"], "Wrong candidate ABI")
    return identity


def verify_candidate(directory):
    apk = directory / "Lumo-Lernen-Neu.apk"
    require(apk.is_file() and apk.stat().st_size == APK_BYTES and digest(apk) == APK_SHA,
            "Candidate is not the exact independently verified 2032 APK bytes")
    return fixed_identity(load(directory / "BUILD-PROVENANCE.json"))


def verify_origin(run, artifact, validation, build):
    require(run.get("id") == SOURCE_RUN and run.get("head_sha") == SOURCE and
            run.get("repository", {}).get("full_name") == reference.REPOSITORY and
            run.get("repository", {}).get("id") == reference.REPOSITORY_ID and
            run.get("path") == ".github/workflows/lumo-nextgen-learning-apk.yml" and
            run.get("status") == "completed" and run.get("conclusion") == "success",
            "Completed source run identity/outcome mismatch")
    for job, number, name in ((validation, VALIDATION_JOB, "validate"), (build, BUILD_JOB, "build")):
        require(job.get("id") == number and job.get("run_id") == SOURCE_RUN and
                job.get("head_sha") == SOURCE and job.get("name") == name and
                job.get("status") == "completed" and job.get("conclusion") == "success",
                "Original source job did not succeed: " + name)
    require(any(step.get("name") == "Independently verify both produced artifacts" and
                step.get("conclusion") == "success" for step in build.get("steps", [])),
            "Original independent APK verification did not succeed")
    for key, expected in {"id": ARTIFACT_ID, "name": ARTIFACT_NAME, "size_in_bytes": ZIP_BYTES,
                          "digest": "sha256:" + ZIP_SHA, "expired": False}.items():
        require(type(artifact.get(key)) is type(expected) and artifact[key] == expected,
                "Wrong immutable 2032 artifact field: " + key)
    origin = artifact.get("workflow_run", {})
    require(origin.get("id") == SOURCE_RUN and origin.get("head_sha") == SOURCE and
            origin.get("repository_id") == reference.REPOSITORY_ID and
            origin.get("head_repository_id") == reference.REPOSITORY_ID,
            "Artifact belongs to a different run/source/repository")


def download(args):
    verify_config(load(CONFIG))
    verify_ci_context(args.qa_commit, args.workflow_run_id, os.environ)
    require(not args.out.exists() or not any(args.out.iterdir()), "Download evidence must be new")
    require(not args.candidate.exists(), "Candidate directory must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    binding = verify_source_binding(args.qa_commit, args.workflow_run_id,
                                    args.out.parent / "source/qa-source-binding.json")
    prefix = "/repos/" + reference.REPOSITORY + "/actions/"
    endpoints = ("runs/" + str(SOURCE_RUN), "artifacts/" + str(ARTIFACT_ID),
                 "jobs/" + str(VALIDATION_JOB), "jobs/" + str(BUILD_JOB))
    records = []
    for name, endpoint in zip(ORIGIN_FILES, endpoints):
        record = reference.api_json(prefix + endpoint)
        write_json(args.out / name, record)
        records.append(record)
    verify_origin(*records)
    # Keep repository credentials on api.github.com; signed storage gets none.
    try:
        response = urllib.request.build_opener(reference.NoRedirect()).open(
            reference.github_request(prefix + "artifacts/" + str(ARTIFACT_ID) + "/zip"), timeout=45)
    except urllib.error.HTTPError as redirect:
        require(redirect.code == 302, "GitHub artifact redirect failed with HTTP " + str(redirect.code))
        url = redirect.headers.get("Location", "")
        target = urllib.parse.urlsplit(url)
        require(target.scheme == "https" and target.hostname and not target.username and not target.password,
                "Unsafe artifact redirect")
        response = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "lumo-2032-replay"}), timeout=90)
    archive = args.candidate.parent / ("artifact-" + str(ARTIFACT_ID) + ".zip")
    archive.parent.mkdir(parents=True, exist_ok=True)
    require(not archive.exists(), "Immutable ZIP may not overwrite an earlier download")
    size = 0
    with response, archive.open("xb") as stream:
        while block := response.read(1024 * 1024):
            size += len(block)
            require(size <= ZIP_BYTES, "Artifact ZIP exceeds immutable size")
            stream.write(block)
    require(size == ZIP_BYTES and digest(archive) == ZIP_SHA, "Immutable ZIP digest/size mismatch")
    reference.extract_zip(archive, args.candidate)
    identity = verify_candidate(args.candidate)
    write_json(args.out / "verified-download.json", {
        "mode": "immutable-runtime-cases", "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id,
        "source_build_run": SOURCE_RUN, "source_run_conclusion": records[0]["conclusion"],
        "artifact_id": ARTIFACT_ID, "artifact_name": ARTIFACT_NAME, "zip_bytes": size,
        "zip_sha256": digest(archive), "apk_bytes": APK_BYTES, "candidate": identity,
        "apk_rebuilt": False, "config_sha256": digest(CONFIG), "source_binding": binding,
        "origin_files": {name: digest(args.out / name) for name in ORIGIN_FILES},
        "zip_members": sorted(str(p.relative_to(args.candidate)) for p in args.candidate.rglob("*") if p.is_file()),
    })


def verify_download_record(directory, candidate, qa_commit, qa_workflow_run):
    verify_config(load(CONFIG))
    identity = verify_candidate(candidate)
    records = [load(directory / name) for name in ORIGIN_FILES]
    verify_origin(*records)
    record = load(directory / "verified-download.json")
    require(record.get("mode") == "immutable-runtime-cases" and record.get("qa_commit") == qa_commit and
            record.get("qa_workflow_run") == qa_workflow_run and record.get("source_build_run") == SOURCE_RUN and
            record.get("source_run_conclusion") == "success" and record.get("artifact_id") == ARTIFACT_ID and
            record.get("artifact_name") == ARTIFACT_NAME and record.get("zip_sha256") == ZIP_SHA and
            record.get("zip_bytes") == ZIP_BYTES and record.get("apk_bytes") == APK_BYTES and
            record.get("candidate") == identity and record.get("apk_rebuilt") is False and
            record.get("config_sha256") == digest(CONFIG) and
            record.get("origin_files") == {name: digest(directory / name) for name in ORIGIN_FILES},
            "Download evidence does not belong to this immutable candidate and QA run")
    binding = load(directory.parent / "source/qa-source-binding.json")
    require(record.get("source_binding") == binding and binding.get("qa_commit") == qa_commit and
            binding.get("qa_workflow_run") == qa_workflow_run and binding.get("apk_source") == SOURCE and
            binding.get("source_build_run") == SOURCE_RUN and binding.get("runtime_source_changed") is False and
            binding.get("config_sha256") == digest(CONFIG) and binding.get("changed_paths") and
            all(allowed_qa_path(path) for path in binding["changed_paths"]),
            "Replay source binding is absent or includes runtime changes")
    return identity


def observed_pattern_answer(nodes, task):
    """Exact line in the current task node; never a substring/foreign header."""
    headers = []
    for node in nodes:
        if (node.get("package") != learning.PACKAGE or node.get("visible-to-user") != "true"
                or node.get("enabled") != "true" or not learning.bounds(node)):
            continue
        lines = {line.strip() for label in learning.node_labels([node]) for line in label.splitlines()}
        if HEADER in lines:
            headers.append(node)
    if not headers:
        return None
    require(len({learning.bounds(node) for node in headers}) == 1,
            "Ambiguous current Core answer headings")
    require(reference.observed_pattern(learning.node_labels(headers)) == task,
            "Current answer heading belongs to a different pattern task")
    viewport = learning.observed_scroll_bounds(nodes)
    controls = {shape: learning.observed_control(nodes, shape) for shape in reference.SHAPES}
    if not viewport or not all(controls.values()) or len(set(controls.values())) != 4:
        return None
    # A card clipped at the ScrollView edge is not a fully observed target.
    if not all(viewport[0] < box[0] < box[2] < viewport[2] and
               viewport[1] < box[1] < box[3] < viewport[3] for box in controls.values()):
        return None
    return {"task": task, "header": HEADER, "header_bounds": learning.bounds(headers[0]),
            "scroll_bounds": viewport, "controls": controls, "target": controls[task["next"]]}


def verify_video(value):
    require(value.get("whole_block_within_recording_limit") is True and
            type(value.get("duration_seconds")) in (int, float) and
            math.isfinite(value["duration_seconds"]) and value["duration_seconds"] > 0 and
            learning.valid_hex(value.get("sha256", ""), 64) and value.get("audio_recorded") is False and
            bool(value.get("file")), "Case lacks its actual positive-duration bounded video")


def verify_source_record(binding, qa_commit, workflow_run_id):
    require(binding.get("mode") == "immutable-runtime-cases" and binding.get("qa_commit") == qa_commit and
            binding.get("qa_workflow_run") == workflow_run_id and binding.get("apk_source") == SOURCE and
            binding.get("source_build_run") == SOURCE_RUN and binding.get("runtime_source_changed") is False and
            binding.get("config_sha256") == digest(CONFIG) and binding.get("helper_sha256") == helper_hashes() and
            binding.get("source_rate_contract") == source_rate_contract() and
            learning.valid_hex(binding.get("apk_source_tree", ""), 40) and
            learning.valid_hex(binding.get("qa_tree", ""), 40) and binding.get("changed_paths") and
            all(allowed_qa_path(path) for path in binding["changed_paths"]),
            "Supplemental source record includes a changed helper/product or different QA identity")


def verify_numeric_case(number):
    require(number.get("status") == "PASS" and number.get("submission_control") == "Antwort prüfen" and
            number.get("input_method") == "real Android text input" and
            number.get("spoken_recognition_exercised") is False and
            number.get("exact_eight_plus_five_numeric_case") is False,
            "Expected actual 9+7 text submission and honest recognition boundary")
    prepared = number["pre_submission_capture"]
    require(prepared.get("capture_after_video_finalization") is True and prepared.get("preservation") ==
            learning.require_preserved(prepared["before"], prepared["after"],
                prepared["checkpoint_before"], prepared["checkpoint_after"]),
            "Numeric capture lost its unchanged unanswered task after recording")
    require(prepared["after"] == number["wrong"]["before"] and
            prepared["checkpoint_after"] == number["wrong"]["checkpoint_before"],
            "First explicit answer is not the freshly rebound unanswered task")
    verify_video(prepared["video"])
    for correct, stage in ((False, "wrong"), (True, "corrected")):
        item = number[stage]
        require(item.get("verification") == legacy.verify_numeric_submission(item["before"], item["after"],
                item["checkpoint_before"], item["checkpoint_after"], correct=correct),
                "Numerical assessment differs from the actual saved attempts")
        verify_video(item["video"])
    require(number["wrong"]["after"] == number["corrected"]["before"] and
            number["wrong"]["checkpoint_after"] == number["corrected"]["checkpoint_before"] and
            number["wrong"]["verification"]["stored_attempt"]["id"] !=
            number["corrected"]["verification"]["stored_attempt"]["id"],
            "Wrong and corrected answers are not two consecutive distinct attempts")


def verify_switch_case(case):
    require(case.get("status") == "PASS" and case.get("explicit_stop_before_switch") is False and
            case.get("old_active_marker_absent") is True and case.get("acoustic_playback_verified") is False and
            case.get("flutter_media_callbacks_in_native_log") is False,
            "Word switch lacks active UI evidence or overstates audio evidence")
    observed = case["observation"]
    require(observed.get("active_label") in ("Silbe 1: Ba, gerade aktiv", "Silbe 2: na, gerade aktiv",
            "Silbe 3: ne, gerade aktiv") and observed.get("next_label") == legacy.NEXT and
            learning.valid_hex(observed.get("xml_sha256", ""), 64), "Missing simultaneous active syllable/Next XML")
    started, finished, touched, elapsed = (observed.get("capture_started_monotonic"),
        observed.get("capture_finished_monotonic"), observed.get("touch_requested_monotonic"),
        case.get("capture_to_touch_seconds"))
    require(all(type(v) in (int, float) and math.isfinite(v) for v in (started, finished, touched, elapsed)) and
            0 <= started <= finished <= touched and 0 <= elapsed <= 1 and
            abs(touched - started - elapsed) <= 1e-6, "Active XML-to-requested-touch exceeds one second")
    require(case.get("verification") == legacy.verify_word_switch(case["before"], case["after"],
            case["checkpoint_before"], case["checkpoint_after"]), "Word-switch preservation mismatch")
    legacy.verify_switch_viewport(case)
    verify_video(case["video"])


def inherited_rate_contract():
    return {"formula": "max(0.70, baseRate * 0.75)", "native_source": native.NATIVE,
        "apk_source": native.SOURCE, "controller": "tools/auto_install/LumoLearningConversation.kt",
        "segments": "scripts/learning/learning_world.gd::_speak_syllables",
        "playback": "tools/auto_install/LumoLearningSpeech.kt::MediaPlayer.playbackParams.setSpeed"}


def bind_current_banana(case):
    require(case.get("source_rate_contract") == inherited_rate_contract(),
            "Inherited slower source description unexpectedly changed")
    value = copy.deepcopy(case)
    value["inherited_metadata_not_current_runtime_evidence"] = value.pop("source_rate_contract")
    value["source_rate_contract"] = source_rate_contract()
    return value


def verify_banana_case(case, profile_id):
    model = {"kind": "syllables", "word": "Banane", "placed": 0, "total": 3, "visible_label": "0 / 3 bewegt"}
    require(case.get("status") == "PASS_WITH_LIMITATIONS" and case.get("action") == "slower" and
            case.get("control") == "Frag Lumo / Langsamer" and case.get("current_task") == reference.BANANA_TITLE and
            case.get("model_before") == model == case.get("model_after") and
            case.get("native_answer_submitted") is False and
            case.get("preservation", {}).get("profile_id") == profile_id and
            case["preservation"].get("same_task_checkpoint") is True,
            "Current slower case lacks its unchanged actual Banane task")
    require(case.get("source_rate_contract") == source_rate_contract() and
            case.get("inherited_metadata_not_current_runtime_evidence") == inherited_rate_contract(),
            "Historical slower metadata cannot stand for current source evidence")
    playback, previous = case.get("playback", {}), case.get("previous_ids", [])
    ids = playback.get("utterance_ids", [])
    require(type(playback.get("pid")) is int and playback["pid"] > 0 and
            playback.get("profile") == native.PROFILE and playback.get("segments") == 4 and
            len(ids) == 4 and all(type(v) is int and v > max(previous, default=0) for v in ids) and
            ids == sorted(set(ids)) and case.get("segment_order_source_contract") == ["Banane", "Ba", "na", "ne"] and
            all(case.get(key) is False for key in ("actual_rate_in_log", "acoustic_speed_verified",
                                                 "segment_words_verified_acoustically")),
            "Slower lacks four new ordered callbacks or overstates acoustic evidence")
    require(all(case.get(key, {}).get("file") for key in
                ("before_screenshot", "after_screenshot", "returned_to_academy")), "Slower screenshots/return missing")
    verify_video(case["video"])


def verify_pattern_case(pattern, evidence):
    task = pattern["task"]
    require(pattern.get("returned_task") == task and pattern.get("native_confirmation_performed") is False and
            pattern.get("native_proposal") == task["next"] and pattern.get("core_answer_submitted") is True and
            pattern.get("observed_group_hint") == "Die kleinste Gruppe hat " + str(task["period"]) + " Zeichen",
            "Pattern lacks the ungraded native group/proposal and same returned task")
    actual = reference.verify_core_submission(evidence["before"], evidence["after"], task)
    require(actual is not None and actual.get("status") == "PASS" and pattern.get("core_submission") == actual,
            "A current explicit Core answer is mandatory; NOT_EXERCISED is not PASS")
    require(evidence.get("selection", {}).get("task") == task and
            evidence["selection"].get("header") == HEADER and evidence.get("explicit_answer_taps") == 1 and
            learning.valid_hex(evidence.get("selection_xml_sha256", ""), 64),
            "Core submission is not bound to its fresh observed task/cards")
    verify_video(evidence["video"])


def verify_runtime_cases(result, *, qa_commit, workflow_run_id):
    verify_qa_identity(qa_commit, workflow_run_id)
    identity = fixed_identity(result.get("candidate", {}))
    require(result.get("schema") == "lumo.nextgen.2032.runtime_cases.android" and
            type(result.get("version")) is int and result["version"] == 1 and
            result.get("status") == "PASS_WITH_LIMITATIONS" and result.get("mode") == "immutable-runtime-cases" and
            result.get("qa_commit") == qa_commit and result.get("qa_workflow_run") == workflow_run_id and
            result.get("apk_source") == SOURCE and result.get("native_source") == NATIVE and
            result.get("source_build_run") == SOURCE_RUN and result.get("cases") == CASES and
            result.get("probe_sha256") == digest(Path(__file__)) and result.get("helper_sha256") == helper_hashes() and
            all(result.get(key) is False for key in ("release_eligible", "original_probe_requirement_satisfied",
                "historical_tour_pass_used", "private_app_data_written_by_probe", "apk_rebuilt_by_probe",
                "fullModernizationComplete")), "Wrong current supplemental identity or acceptance boundary")
    verify_config(result.get("config"))
    require(result.get("config_sha256") == digest(CONFIG), "Runtime config changed")
    verify_source_record(result.get("source_binding", {}), qa_commit, workflow_run_id)
    installed, device = result.get("installed", {}), result.get("device", {})
    require(all(type(installed.get(k)) is type(identity[k]) and installed[k] == identity[k]
            for k in ("package", "versionCode", "versionName", "sha256", "signingCertificateSha256")) and
            installed.get("signature_binding") == "installed base.apk hash equals independently signature-verified input APK" and
            device.get("api") == 35 and device.get("abi") == "x86_64" and device.get("physical_device") is False and
            device.get("package_absent_before_install") is True and result.get("onboarding", {}).get("synthetic") is True,
            "Expected exact real fresh installation and synthetic UI profile")
    profile = result["onboarding"]["profile"]
    require(profile.get("name") == learning.PROFILE_NAME and profile.get("grade") == 1 and
            result.get("final_profile") == profile and result.get("auto_read_restored_before_native") is True and
            result.get("local_voice_settings", {}).get("auto_read") is True, "Profile/auto-read restoration missing")
    changes = result.get("runtime_auto_read_ui_changes", [])
    require(len(changes) == 1 and changes[0].get("control") == "Automatisch vorlesen" and
            changes[0].get("private_preferences_written") is False and
            changes[0].get("before", {}).get("autoReadEnabled") is True and
            changes[0].get("after", {}).get("autoReadEnabled") is False, "Temporary real auto-read preparation missing")
    verify_numeric_case(result["numeric_wrong_then_correct"])
    verify_switch_case(result["flutter_switch_during_syllable_playback"])
    verify_banana_case(result["native_banana_slower"], profile["id"])
    verify_pattern_case(result["pattern"], result["pattern_core_evidence"])
    return {"cases": CASES, "release_eligible": False, "full_replay_replaced": False,
            "current_pattern_core_submission": "PASS"}


class RuntimeCases2032Probe(legacy.RuntimeCasesProbe):
    def candidate_identity(self):
        return verify_candidate(self.args.candidate)

    def verify_previous_result(self, original, identity):
        raise RuntimeError("Independent supplemental cases never reset or borrow a prior tour")

    def submit_pattern_answer(self, task, before):
        require(self.read_pattern("pattern-before-explicit-core-answer") == task, "Core task changed before selection")
        self.see(HEADER, "pattern-core-answer-heading", scroll=True, exact=True)
        selection = None
        for _ in range(8):
            nodes = self.nodes("pattern-observed-core-answer-cards")
            selection = observed_pattern_answer(nodes, task)
            if selection is not None:
                break
            self.scroll(nodes, 1)
        require(selection is not None, "No current exact task/header and four fully visible unique cards")
        with self.recording("pattern-explicit-core-answer-after-ungraded-return"):
            self.capture("pattern-before-explicit-core-answer")
            tag = self.fresh("pattern-final-current-answer-cards")
            nodes = self.live.live_nodes(self.out, tag)
            selection = observed_pattern_answer(nodes, task)
            require(selection is not None, "Core task/cards changed before the single explicit answer")
            evidence = {"before": before, "selection": selection, "selection_xml": tag + ".xml",
                        "selection_xml_sha256": digest(self.out / (tag + ".xml")), "explicit_answer_taps": 1}
            self.result["pattern_core_evidence"] = evidence
            self.save("pattern-core-observed-answer-controls", evidence)
            self.touch(selection["target"], "pattern-explicit-core-answer", HEADER + " / " + task["next"])

            def observe():
                after = learning.learning_snapshot(self.preferences("pattern-after-explicit-core-answer"))
                assessed = reference.verify_core_submission(before, after, task)
                if assessed:
                    evidence["after"] = after
                return assessed

            assessed = self.wait("Actual persisted Core assessment for this question", observe, timeout=45)
            self.capture("pattern-after-explicit-core-assessment")
        evidence["video"] = self.recordings[-1]
        self.result["pattern"]["core_answer_submitted"] = True
        self.result["pattern"]["core_submission"] = assessed

    def run(self):
        self.identify_and_install()
        require(self.result["candidate"] == self.candidate_identity() and self.result["device"]["api"] == 35,
                "Installed supplemental candidate differs from fixed 2032 bytes")
        self.onboard()
        self.configure_local_voice()
        self.set_auto_read_for_cases(False)
        self.academy()
        self.numeric_wrong_then_correct()
        self.word_switch_during_playback()
        self.configure_local_voice()
        self.result["auto_read_restored_before_native"] = self.settings("runtime-auto-read-restored").get("autoReadEnabled") is True
        require(self.result["auto_read_restored_before_native"], "Auto-read was not restored through actual settings")
        self.tap("Lernen", "runtime-native-handoff-academy")
        self.see("LUMO AKADEMIE", "runtime-native-handoff-visible", exact=True)
        self.result["native_banana_slower"] = bind_current_banana(native.banana_slower(self))
        # Call the existing native pattern tour. The only new UI selector is
        # this class's exact multiline-header Core submission above.
        self.pattern()
        self.result["final_profile"] = learning.learning_snapshot(self.preferences("runtime-final-profile"))["profile"]
        self.result["status"] = "PASS_WITH_LIMITATIONS"
        self.result["verification"] = verify_runtime_cases(self.result, qa_commit=self.args.qa_commit,
                                                           workflow_run_id=self.args.workflow_run_id)


def run(args):
    require(not args.out.exists() or not any(args.out.iterdir()), "Supplemental evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    result = {"schema": "lumo.nextgen.2032.runtime_cases.android", "version": 1, "status": "RUNNING",
        "mode": "immutable-runtime-cases", "cases": CASES, "run_id": uuid.uuid4().hex,
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id, "apk_source": SOURCE,
        "native_source": NATIVE, "source_build_run": SOURCE_RUN, "probe_sha256": digest(Path(__file__)),
        "helper_sha256": helper_hashes(), "release_eligible": False, "original_probe_requirement_satisfied": False,
        "historical_tour_pass_used": False, "private_app_data_written_by_probe": False,
        "apk_rebuilt_by_probe": False, "fullModernizationComplete": False,
        "limitations": ["Separate fresh synthetic installation; no full-tour or publication approval.",
            "9+7 uses explicit text submissions 15 then 16; STT/misheard speech is not exercised.",
            "Active syllable switching uses actual UI playback semantics, 1080x2340/320dpi and exact density restore; no acoustic or physical-device proof.",
            "Four current MediaPlayer callback pairs prove Langsamer selection; words/rate are source-bound, not acoustically measured.",
            "Native pattern proposal remains ungraded; only its later explicit Core card records an assisted answer.",
            "Videos have no audio. No mouth/gesture stop, 60FPS, physical Fold7 or complete modernization claim."]}
    probe = None
    try:
        result["config"] = verify_config(load(CONFIG))
        result["config_sha256"] = digest(CONFIG)
        verify_ci_context(args.qa_commit, args.workflow_run_id, os.environ)
        verify_download_record(args.download_evidence, args.candidate, args.qa_commit, args.workflow_run_id)
        result["source_binding"] = verify_source_binding(args.qa_commit, args.workflow_run_id,
                                                          args.out / "qa-source-binding.json")
        args.apk, args.provenance = args.candidate / "Lumo-Lernen-Neu.apk", args.candidate / "BUILD-PROVENANCE.json"
        args.expected_sha256, args.expected_source, args.expected_native = APK_SHA, SOURCE, NATIVE
        args.expected_version, args.expected_version_name, args.expected_certificate = VERSION, VERSION_NAME, CERTIFICATE
        args.conversation_ui, args.submit_core_answer = "ea", True
        require(shutil.which("ffprobe"), "ffprobe required for actual video validation")
        probe = RuntimeCases2032Probe(args, result)
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


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("download", "run", "verify"):
        entry = sub.add_parser(name)
        entry.add_argument("--qa-commit", required=True)
        entry.add_argument("--workflow-run-id", required=True, type=int)
        if name == "verify":
            entry.add_argument("--result", required=True, type=Path)
        else:
            entry.add_argument("--candidate", required=True, type=Path)
            entry.add_argument("--out", required=True, type=Path)
        if name == "run":
            entry.add_argument("--download-evidence", required=True, type=Path)
            entry.add_argument("--serial")
    args = parser.parse_args(argv)
    if args.command == "download":
        download(args)
        return 0
    if args.command == "verify":
        print(json.dumps(verify_runtime_cases(load(args.result), qa_commit=args.qa_commit,
                                             workflow_run_id=args.workflow_run_id)))
        return 0
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main())
