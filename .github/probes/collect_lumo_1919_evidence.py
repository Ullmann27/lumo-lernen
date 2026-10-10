#!/usr/bin/env python3
"""Aggregate exact APK1919 evidence while retaining original failed attempts."""
from __future__ import annotations
import ast
import base64
import hashlib
import io
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from PIL import Image

REPO = "Ullmann27/lumo-lernen"
RUN = 37975946198
APP = "d07b2b48593b939a2a0446fcb83a25a2b2a59db6"
GODOT = "d140e5b05cb5afacfe675559b78da4254cb1daed"
APK_SHA = "8e2ea31fed333fd8e89becd073b100c53ce9449017badb43ab4bc28022cc51aa"
APK_BYTES = 205316096
PCK_SHA = "71920fb7f5c9ec798032fe2317ca22bf4eecd91b08699daa22ed360e0b45a7f8"
API = "https://api.github.com"
OUT = Path("verified-package")
TOKEN = os.environ["LUMO_READ_TOKEN"]
HEADERS = {"Authorization": "Bearer " + TOKEN, "Accept": "application/vnd.github+json",
           "X-GitHub-Api-Version": "2022-11-28"}
EXPECTED_JOBS = {
    "verify-and-build": 113974160562, "android (build, 35)": 113988997747,
    "android (puzzle, 35)": 113988997645, "android (rhythm, 35)": 113988997663,
    "android (treasure, 35)": 113988998247, "android (kart, 35)": 113988997714,
    "android (kart, 36)": 113988997647,
}
ARTIFACTS = []
FILES = []
IMAGES = []
ANDROID = {}

def require(value, message):
    if not value:
        raise RuntimeError(message)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def api_json(path):
    req = urllib.request.Request(API + "/repos/" + REPO + path, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=45) as response:
        return json.load(response)

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def archive(artifact, run_id, source):
    require(not artifact["expired"], "Expired artifact")
    require(artifact["workflow_run"]["id"] == run_id and
            artifact["workflow_run"]["head_sha"] == source, "Artifact source mismatch")
    require(0 < artifact["size_in_bytes"] < 1500000000, "Artifact size budget")
    expected = artifact["digest"]
    require(re.fullmatch(r"sha256:[0-9a-f]{64}", expected or ""), "Missing archive digest")
    req = urllib.request.Request(
        API + f"/repos/{REPO}/actions/artifacts/{artifact['id']}/zip", headers=HEADERS)
    try:
        urllib.request.build_opener(NoRedirect).open(req, timeout=45)
    except urllib.error.HTTPError as response:
        require(response.code in (302, 303, 307), "Artifact API did not redirect")
        location = response.headers.get("Location", "")
    else:
        raise RuntimeError("Expected artifact redirect")
    require(urllib.parse.urlsplit(location).scheme == "https", "Non-HTTPS artifact transfer")
    # The signed cross-host request deliberately contains no GitHub Authorization header.
    path = Path(tempfile.gettempdir()) / ("lumo-audit-" + str(artifact["id"]) + ".zip")
    digest = hashlib.sha256()
    count = 0
    with urllib.request.urlopen(location, timeout=120) as response, path.open("wb") as dest:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            count += len(chunk)
            require(count <= artifact["size_in_bytes"], "Archive exceeds declared size")
            digest.update(chunk)
            dest.write(chunk)
    require(count == artifact["size_in_bytes"] and "sha256:" + digest.hexdigest() == expected,
            "Archive bytes or hash differ")
    z = zipfile.ZipFile(path)
    require(len(z.infolist()) <= 5000, "Archive entry budget")
    require(sum(i.file_size for i in z.infolist()) <= 4000000000, "Expanded archive budget")
    require(len(z.namelist()) == len(set(z.namelist())), "Duplicate archive names")
    for item in z.infolist():
        p = PurePosixPath(item.filename)
        require(not p.is_absolute() and ".." not in p.parts and "\\" not in item.filename,
                "Unsafe archive path")
        require(not item.flag_bits & 1, "Encrypted archive")
        require((item.external_attr >> 16) & 0o170000 != 0o120000, "Symlink archive entry")
    ARTIFACTS.append({"id": artifact["id"], "name": artifact["name"], "bytes": count,
                      "sha256": digest.hexdigest(), "entries": len(z.infolist()),
                      "run_id": run_id, "head_sha": source})
    return z

def member(z, suffix):
    safe_name(suffix)
    # Producer roots are canonical; nested copied replay fixtures are a different scope.
    if suffix in z.namelist():
        return suffix
    matches = [n for n in z.namelist() if n.endswith("/" + suffix)]
    require(matches, "Missing archive member: " + suffix)
    depth = min(n.count("/") for n in matches)
    matches = [n for n in matches if n.count("/") == depth]
    require(len(matches) == 1, "Expected one shallow archive member: " + suffix)
    return matches[0]

def read_json(z, suffix):
    return json.loads(z.read(member(z, suffix)))

def write_file(relative, raw, artifact_id, original):
    safe_name(relative)
    target = OUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    require(not target.exists(), "Duplicate output path")
    target.write_bytes(raw)
    FILES.append({"file": relative, "bytes": len(raw), "sha256": sha(raw),
                  "artifact_id": artifact_id, "archive_member": original})

def png(z, suffix, relative, artifact_id, display=False):
    name = member(z, suffix)
    raw = z.read(name)
    with Image.open(io.BytesIO(raw)) as im:
        require(im.format == "PNG", "PNG format")
        im.load()
        width, height = im.size
        extrema = im.convert("RGB").getextrema()
    require(width >= 320 and height >= 300, "Unexpected image size")
    require(any(high - low > 30 for low, high in extrema), "Image lacks visible variation")
    write_file(relative, raw, artifact_id, name)
    meta = {"file": relative, "width": width, "height": height, "bytes": len(raw),
            "sha256": sha(raw), "artifact_id": artifact_id, "archive_member": name}
    IMAGES.append(meta)
    if display:
        emit_png(meta, raw)
    return meta

def emit_png(meta, raw):
    require(len(raw) < 4000000, "Visual transfer budget")
    encoded = base64.b64encode(raw).decode("ascii")
    key = "frame" + str(len(IMAGES))
    count = (len(encoded) + 49999) // 50000
    print("LUMO_PNG_BEGIN " + json.dumps(dict(meta, key=key, chunks=count)), flush=True)
    for number in range(count):
        print(f"LUMO_PNG_CHUNK {key} {number} " + encoded[number*50000:(number+1)*50000],
              flush=True)
    print("LUMO_PNG_END " + key, flush=True)


def copy_small_reports(z, prefix, artifact_id):
    for entry in z.infolist():
        if (entry.is_dir() or PurePosixPath(entry.filename).suffix.lower()
                not in (".json", ".jsonl", ".log", ".txt", ".md")
                or entry.file_size > 5000000):
            continue
        write_file(prefix + "/" + entry.filename, z.read(entry.filename),
                   artifact_id, entry.filename)

def validate_identity(result, game, sdk, harness):
    require(result["status"] == "PASS" and "error" not in result, "Android result not PASS")
    require(result["source"] == APP and result["godot"] == GODOT and
            result["apk_sha256"] == APK_SHA and result["android_sdk"] == sdk,
            "Android result identity mismatch")
    require(result["harness"] == harness and result["tested_games"] == [game],
            "Android harness or scope mismatch")
    require(result["update"]["status"] == "PASS" and result["update"]["profile_retained"] is True
            and result["update"]["offline"] is True, "Android update evidence incomplete")


CERT = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
APK_NAME = "LUMO-Lernen-0.12.12-1919.apk"
RECOVERY_PATH = ".github/workflows/lumo-1919-gas-recovery.yml"
REPLAY_NAME = "Original failure replay and harness regression"
ANDROID_NAME = "Existing APK 1919 full Android race on API36"
RECORDER_STEP = "Require recorder regression on identical constructed schedules"
RECORDER_FAILED_RUN = 37987900281
RECORDER_ORIGINAL_HEAD = "d40519d011500246bb4c7ad5a39ad684aa9477bd"
RECORDER_PROBE = ".github/probes/kart_complete_android_probe.py"
RECORDER_TEST = "tools/android_qa/tests/test_kart_video_recorder.py"
RECORDER_ORIGINAL_SHA = "4e19fed0117bbb878b1b79c0fa3e3e2c0e72da53380d5402b31d8370d9bb3b7f"
RECORDER_CANDIDATE_SHA = "6b7c38220488072c317b2d73523f3e40fe5002fd64523a7c16884998c716af89"
RECORDER_TEST_SHA = "4ace9bdf3c7745b7faf0405db00648c61678e70a358e8835d360a5c8103d50b4"
RECORDER_FAILURE = "Actual Android footage collection failed: Cannot safely identify the owned screenrecord process"
RECORDER_FIXTURE_KIND = "constructed deterministic subprocess schedules; actual failure PID response was not saved"
RECORDER_RED_CASES = {
    "test_actual_command_observations_are_retained_on_transport_failure",
    "test_clean_remote_exit_with_delayed_host_observation_collects_without_signal",
    "test_cmdline_read_error_cannot_authorize_sigint",
    "test_invalid_or_group_pid_cannot_receive_a_signal (value=b'0')",
    "test_invalid_or_group_pid_cannot_receive_a_signal (value=b'00')",
    "test_later_segment_launch_failure_cannot_pass_using_earlier_footage",
    "test_live_single_matching_target_receives_only_its_own_sigint",
    "test_non_utf8_process_response_retains_the_exact_observed_bytes",
    "test_own_client_nonzero_exit_is_never_usable_footage",
    "test_pid_observation_and_client_wait_share_one_20_second_budget",
    "test_pidof_nonzero_status_with_a_numeric_stdout_is_not_success",
    "test_single_pid_for_another_remote_recording_is_never_signalled",
    "test_truncated_cmdline_cannot_authorize_sigint",
}
LOCK_PATH = Path(".github/probes/lumo_1919_aggregation_lock.json")
ORIGINAL_ARTIFACTS = {
    "apk": (11639898022, "lumo-visual-apk-37975946198", 215903589, "17dccd7ba9836396fb491d4dd35b18b3452698b80c3fcc7eb31f54b04afcad13"),
    "build": (11640997839, "lumo-kart-stage2-android-build-api35-37975946198", 43898880, "fbe2f50e4de8ffe93179bd3e6fbed661abb5a53c980b8c48e57a5041af0c496d"),
    "puzzle": (11640833003, "lumo-kart-stage2-android-puzzle-api35-37975946198", 18847369, "e9a87d527e10e835237f9403ccc47434e7938d0c72541b3a518968f0808b197d"),
    "rhythm": (11640224132, "lumo-kart-stage2-android-rhythm-api35-37975946198", 15538367, "3749410c9d7796e48fa246c322066e61120df1812abbfa056c829f8276413c9f"),
    "treasure": (11641082753, "lumo-kart-stage2-android-treasure-api35-37975946198", 30619062, "b3bb7218b40f089b017d35fd4d059804273bbe1e68ab0e4ad2bc4619ef4d00f6"),
    "kart": (11641449935, "lumo-kart-stage2-android-kart-api35-37975946198", 266654314, "e02a93fb191c9cb2173b3566c272599cb8fd50976f69adf3f8f27d363d32ca31"),
    "failed-api36": (11641916981, "lumo-kart-stage2-android-kart-api36-37975946198", 136961576, "a1543a51c0d5782f011b6ca6fb944d22c9efc33000299c3f21470f8602e4df2e"),
}
SOURCE_CACHE = {}
FRAME_SIZES = {
    "lumo-driver-4views.png": (1280, 1280),
    "lumo-face-1280x720.png": (1280, 720),
    "lumo-face-800x480.png": (800, 480),
    "lumo-face-412x915.png": (412, 915),
    "lumo_front.png": (900, 900), "lumo_side.png": (900, 900),
    "lumo_rear.png": (900, 900), "lumo_three_quarter.png": (900, 900),
    "menu-0.png": (1280, 720), "sonnenhafen-025.png": (1280, 720),
    "start-1280x720.png": (1280, 720), "start-800x480.png": (800, 480),
    "start-412x915.png": (412, 915), "start-saved-320x568.png": (320, 568),
    "01-low-entry.png": (1280, 720), "02-low-middle.png": (1280, 720),
    "03-low-exit.png": (1280, 720), "04-high-entry.png": (1280, 720),
    "05-high-middle.png": (1280, 720), "06-high-exit.png": (1280, 720),
}
NATIVE_FILES = (
    "scripts/games/kart_vehicle.gd", "scripts/games/kart_garage_menu.gd",
    "scripts/games/kart_stage.gd", "scripts/games/kart_character_finish.gd",
    "scripts/games/kart_island.gd", "scenes/games/kart_island.tscn",
    "scripts/games/kart_harbor_aquarium.gd", "assets/shaders/kart_aquarium.gdshader",
    "scripts/tests/kart_aquarium_clearance_regression.gd",
    "scripts/tests/kart_aquarium_capture.gd",
    "scripts/tests/kart_character_pose_regression.gd",
    "scripts/tests/kart_face_depth_regression.gd",
    "scripts/tests/kart_start_hero_regression.gd",
    "scripts/tests/kart_fox_eye_proportions_regression.gd",
    "scripts/tests/kart_stage_visual_regression.gd",
    "scripts/tests/kart_garage_face_capture.gd",
    "scripts/tests/kart_driver_portrait.gd",
    "scripts/tests/kart_reference_capture.gd",
    "scripts/tests/kart_visual_quality_capture.gd",
)
REGRESSIONS = (
    "test/progress_repository_storage_test.dart",
    "test/learning_modules/learning_module_progress_test.dart",
    "test/domain/school_model_test.dart", "test/domain/school_analysis_test.dart",
    "test/domain/learning_analysis_extended_test.dart",
    "test/reward_wallet_transaction_test.dart",
)

def safe_name(value):
    require(type(value) is str and value and "\\" not in value,
            "Invalid relative path")
    parts = value.split("/")
    require(not PurePosixPath(value).is_absolute() and
            all(part not in ("", ".", "..") for part in parts), "Unsafe relative path")
    return value

def positive(value, label):
    require(type(value) is int and value > 0, "Missing positive lock value: " + label)
    return value

def hex_value(value, size, label):
    require(type(value) is str and re.fullmatch(r"[0-9a-f]{" + str(size) + r"}", value)
            and set(value) != {"0"}, "Missing exact hash: " + label)
    return value

def source_bytes(repo, revision, name):
    require(repo in (REPO, "Ullmann27/lumo-godot"), "Unexpected source repository")
    hex_value(revision, 40, "source revision")
    safe_name(name)
    key = (repo, revision, name)
    if key not in SOURCE_CACHE:
        url = API + "/repos/" + repo + "/contents/" + urllib.parse.quote(name, safe="/") + "?ref=" + revision
        with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=45) as response:
            item = json.load(response)
        require(item["type"] == "file" and item["encoding"] == "base64", "Source response is not a file")
        raw = base64.b64decode("".join(item["content"].split()), validate=True)
        require(len(raw) == item["size"] and len(raw) <= 2000000, "Source byte size")
        require(hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
                == item["sha"], "Source Git blob differs")
        SOURCE_CACHE[key] = raw
    return SOURCE_CACHE[key]

def validated_lock():
    require(LOCK_PATH.is_file() and not LOCK_PATH.is_symlink(), "Missing aggregation lock")
    lock = json.loads(LOCK_PATH.read_text())
    require(set(lock) == {"schema", "app_commit", "godot_commit", "apk_sha256",
                         "recovery_run_id", "recovery_run_attempt", "recovery_head_sha",
                         "replay_job_id", "android_job_id", "artifacts"},
            "Incomplete or unexpected aggregation lock fields")
    require(lock["schema"] == "lumo.1919-aggregation-lock.v1" and
            lock["app_commit"] == APP and lock["godot_commit"] == GODOT and
            lock["apk_sha256"] == APK_SHA, "Lock fixed source mismatch")
    for key in ("recovery_run_id", "recovery_run_attempt", "replay_job_id", "android_job_id"):
        positive(lock[key], key)
    hex_value(lock["recovery_head_sha"], 40, "recovery harness")
    require(lock["recovery_run_id"] not in (RUN, 37987154620, RECORDER_FAILED_RUN),
            "A known failed run cannot be recovery")
    require(lock["replay_job_id"] != lock["android_job_id"], "Recovery jobs must be distinct")
    require(set(lock["artifacts"]) == {"replay", "android"}, "Two exact recovery artifacts required")
    for role, item in lock["artifacts"].items():
        require(set(item) == {"id", "name", "bytes", "sha256"}, "Incomplete artifact lock")
        positive(item["id"], role + " artifact id")
        positive(item["bytes"], role + " artifact bytes")
        hex_value(item["sha256"], 64, role + " artifact sha256")
        prefix = "lumo-1919-gas-replay-" if role == "replay" else "lumo-1919-api36-gas-recovery-"
        require(item["name"] == prefix + str(lock["recovery_run_id"]), "Recovery artifact name")
    return lock

def checked_run(run_id, attempt, head, conclusion, workflow):
    run = api_json(f"/actions/runs/{run_id}")
    require(run["id"] == run_id and run["run_attempt"] == attempt and
            run["head_sha"] == head and run["path"] == workflow and
            run["repository"]["full_name"] == REPO and
            run["status"] == "completed" and run["conclusion"] == conclusion,
            "Workflow run identity or completion differs: " + str(run_id))
    return run

def jobs_for(run_id):
    rows, page = [], 1
    while True:
        response = api_json(f"/actions/runs/{run_id}/jobs?filter=all&per_page=100&page={page}")
        batch = response["jobs"]
        rows.extend(batch)
        if len(rows) >= response["total_count"]:
            break
        require(batch and page < 20, "Incomplete job inventory")
        page += 1
    require(len(rows) == len({row["id"] for row in rows}), "Duplicate job identities")
    return {row["id"]: row for row in rows}

def checked_job(jobs, job_id, name, run_id, attempt, head, conclusion):
    require(job_id in jobs, "Required job missing: " + str(job_id))
    job = jobs[job_id]
    require(job["name"] == name and job["run_id"] == run_id and
            job["run_attempt"] == attempt and job["head_sha"] == head and
            job["status"] == "completed" and job["conclusion"] == conclusion,
            "Required job identity/result differs: " + str(job_id))
    return job

def step(job, name, conclusion):
    matches = [row for row in job["steps"] if row["name"] == name]
    require(len(matches) == 1 and matches[0]["status"] == "completed" and
            matches[0]["conclusion"] == conclusion, "Required step differs: " + name)

def job_meta(job):
    return {key: job[key] for key in
            ("id", "name", "run_id", "run_attempt", "head_sha", "status", "conclusion", "html_url")}

def run_meta(run):
    return {key: run[key] for key in
            ("id", "run_attempt", "head_sha", "status", "conclusion", "path", "html_url")}

def artifact_list(run_id):
    response = api_json(f"/actions/runs/{run_id}/artifacts?per_page=100")
    require(response["total_count"] == len(response["artifacts"]), "Unprocessed artifact page")
    return {row["id"]: row for row in response["artifacts"]}

def checked_artifact(items, run_id, head, contract):
    artifact_id, name, size, digest = contract
    require(artifact_id in items, "Required artifact missing: " + str(artifact_id))
    item = items[artifact_id]
    require(item["name"] == name and item["size_in_bytes"] == size and
            item["digest"] == "sha256:" + digest and item["expired"] is False and
            item["workflow_run"]["id"] == run_id and
            item["workflow_run"]["head_sha"] == head, "Artifact lock differs: " + str(artifact_id))
    return item

def lock_contract(item):
    return item["id"], item["name"], item["bytes"], item["sha256"]

def primary_result(z):
    matches = [n for n in z.namelist() if PurePosixPath(n).name == "result.json" and
               "full-race" not in PurePosixPath(n).parts and "replay" not in PurePosixPath(n).parts]
    require(matches, "Missing primary Android result")
    depth = min(name.count("/") for name in matches)
    matches = [name for name in matches if name.count("/") == depth]
    require(len(matches) == 1, "Ambiguous primary Android result")
    return json.loads(z.read(matches[0]))

def verify_profile(profile):
    old = "26045518fded02d6b588dcbd03898312b6a2103d173873a67413102a8583d0ab"
    new = "49a5f51bb39da8bd1319271290a03c495facba38a76b1db84650e98b0a214eb5"
    test_sha = "7a82a25d0932e2db45717472c4016dbae8453190c7a4283db66901780ad19d6a"
    cases = ("answer keeps its student when assignment changes during progress load",
             "answer keeps its student when assignment changes during progress save",
             "unassigned answers retain the existing local log attribution")
    require(profile["status"] == "PASS" and profile["flutter_source_commit"] == APP and
            profile["original_commit"] == "ab21b2295ca5307bae5e07c0c8a01c3017ee91a3" and
            profile["original_app_state_sha256"] == old and
            profile["candidate_app_state_sha256"] == new and
            profile["unchanged_test_sha256"] == test_sha, "Profile source contract")
    require(sha(source_bytes(REPO, APP, "lib/app/app_state.dart")) == new and
            sha(source_bytes(REPO, APP, "test/app_state_student_identity_test.dart")) == test_sha,
            "Profile source bytes differ")
    require(sha(source_bytes(REPO, profile["original_commit"], "lib/app/app_state.dart")) == old,
            "Original app_state bytes differ")
    for phase, status, code, count, state in (
            ("red", "EXPECTED_RED", 1, 3, old), ("green", "PASS", 0, 3, new),
            ("existing_regressions", "PASS", 0, 58, new)):
        report = profile[phase]
        require(report["status"] == status and report["source_commit"] == APP and
                report["exit_code"] == code and report["visible_tests"] == count and
                report["skipped"] == 0 and report["test_sha256"] == test_sha and
                report["app_state_sha256"] == state, "Profile phase differs: " + phase)
        hex_value(report["json_reporter_sha256"], 64, phase + " reporter")
    for phase, expected in (
            ("red", dict(zip(cases, ("failure", "failure", "success")))),
            ("green", dict.fromkeys(cases, "success"))):
        rows = profile[phase]["cases"]
        require(len(rows) == 3 and {r["name"]: r["result"] for r in rows} == expected,
                "Exact profile cases differ: " + phase)
    errors = profile["red"]["errors"]
    require(len(errors) == 2 and {e["test"] for e in errors} == set(cases[:2]),
            "Expected only two attribution errors")
    for error in errors:
        require(error["is_failure"] is True and
                re.search(r"(?m)^Expected:\s*'student-a'\s*$", error["error"]) and
                re.search(r"(?m)^\s*Actual:\s*'student-b'\s*$", error["error"]),
                "Compiler/bootstrap error cannot count as attribution RED")
    hashes = profile["regression_source_sha256"]
    require(set(hashes) == set(REGRESSIONS), "Required regression source inventory")
    for name, digest in hashes.items():
        require(sha(source_bytes(REPO, APP, name)) == digest, "Regression source differs")
    return {"status": "PASS", "red_failed": 2, "red_passed": 1,
            "green_passed": 3, "existing_regressions_passed": 58, "skipped": 0,
            "test_sha256": test_sha, "original_app_state_sha256": old,
            "candidate_app_state_sha256": new}

def verify_character(character, z, artifact_id):
    require(character["status"] == "PASS" and character["flutter_source_commit"] == APP and
            character["godot_source_commit"] == GODOT and character["measured_checks"] ==
            {"character-pose": 2325, "face-depth": 23, "start-hero": 69},
            "Character source or measured checks differ")
    require(set(character["source_sha256"]) == set(NATIVE_FILES), "Character source inventory")
    for name, digest in character["source_sha256"].items():
        require(sha(source_bytes("Ullmann27/lumo-godot", GODOT, name)) == digest,
                "Pinned native source bytes differ: " + name)
    aquarium = character["aquarium"]
    expected_quality = {"LOW": {"batched_props": 292, "fish": 12},
                        "HIGH": {"batched_props": 324, "fish": 40}}
    require(aquarium["runs"] == {"headless": expected_quality, "rendered": expected_quality}
            and aquarium["gpu_instance_clearance_verified"] is True,
            "Aquarium measured evidence differs")
    driven = aquarium["capture_driven_metres"]
    require(set(driven) == {name[:-4] for name in FRAME_SIZES if re.match(r"0[1-6]-", name)}
            and all(type(v) in (int, float) and 6 <= v < 1000 for v in driven.values()),
            "Aquarium driven captures differ")
    frames = character["captures"]
    require(len(frames) == 20 and {f["file"] for f in frames} == set(FRAME_SIZES),
            "Twenty unique expected character captures required")
    for frame in frames:
        name = frame["file"]
        require(PurePosixPath(name).name == name, "Frame must be a basename")
        raw = z.read(member(z, "character-review/" + name))
        require(sha(raw) == frame["sha256"] and len(raw) == frame["bytes"], "Frame bytes differ")
        require((frame["width"], frame["height"]) == FRAME_SIZES[name], "Frame metadata dimensions")
        meta = png(z, "character-review/" + name, "character-review/" + name, artifact_id)
        require((meta["width"], meta["height"]) == FRAME_SIZES[name], "Actual PNG dimensions differ")
    return {"status": "PASS", "captures": 20, "measured_checks": character["measured_checks"],
            "aquarium": aquarium, "godot_source_commit": GODOT}

def verify_recorder_processes(video, z):
    """Validate the actual producer's recorded observations without issuing commands."""
    raw = z.read(member(z, "full-race/android-screenrecord-processes.jsonl"))
    require(0 < len(raw) <= 5000000, "Recorder process observation budget")
    rows = [json.loads(line) for line in raw.decode("utf-8").splitlines() if line.strip()]
    require(rows, "Missing actual recorder process observations")
    segments = video["segments"]
    indices = [int(segment["file"].removeprefix("android-race-").removesuffix(".mp4"))
               for segment in segments]
    require(indices == list(range(len(segments))) and
            all(type(segment["exit_code"]) is int and segment["exit_code"] == 0 for segment in segments),
            "Recovered video must have distinct contiguous segments and successful client exits")
    grouped = {index: [] for index in indices}
    previous = -1
    for row in rows:
        require(type(row) is dict and type(row.get("segment")) is int and
                row["segment"] in grouped and type(row.get("monotonic_seconds")) in (int, float) and
                math.isfinite(row["monotonic_seconds"]) and row["monotonic_seconds"] >= previous,
                "Recorder observation identity or ordering differs")
        previous = row["monotonic_seconds"]
        require(row.get("phase") in {"finish-start", "pidof", "remote-absent", "cmdline",
                                     "owner-confirmed", "sigint", "client-finished"} and
                "error" not in row and "timeout" not in row,
                "Failed/unknown recorder observations cannot prove complete footage")
        grouped[row["segment"]].append(row)
    remote_ids = set()
    for index, entries in grouped.items():
        phases = [row["phase"] for row in entries]
        require(phases and phases[0] == "finish-start" and phases[-1] == "client-finished" and
                len(phases) == len(set(phases)), "Recorder segment lifecycle is incomplete")
        start, finish = entries[0], entries[-1]
        require(type(finish["client_returncode"]) is int and finish["client_returncode"] == 0 and
                start["client_returncode"] in (None, 0) and
                0 <= finish["monotonic_seconds"] - start["monotonic_seconds"] <= 20,
                "Recorder client did not finish successfully within its existing budget")
        args = start["expected_argv"]
        require(type(args) is list and len(args) == 8 and args[:7] ==
                ["/system/bin/screenrecord", "--size", "960x540", "--bit-rate",
                 "2000000", "--time-limit", "180"] and type(args[7]) is str,
                "Recorder segment command differs")
        target = re.fullmatch(r"/sdcard/lumo-full-race-([0-9a-f]{32})-([0-9]{3})\.mp4", args[7])
        require(target and int(target[2]) == index, "Recorder unique target differs from segment")
        remote_ids.add(target[1])
        observed_pid = None
        owner = None
        for row in entries[1:-1]:
            phase = row["phase"]
            if phase in ("pidof", "cmdline", "sigint"):
                require(type(row.get("returncode")) is int and
                        all(type(row.get(field)) is str for field in
                            ("stdout", "stderr", "stdout_hex", "stderr_hex")),
                        "Recorder ADB status or exact response bytes missing")
                outputs = {}
                for field in ("stdout", "stderr"):
                    encoded = row[field + "_hex"]
                    require(re.fullmatch(r"(?:[0-9a-f]{2})*", encoded) is not None,
                            "Recorder response is not canonical byte hex")
                    outputs[field] = bytes.fromhex(encoded)
                    require(outputs[field].decode("utf-8", errors="replace") == row[field],
                            "Recorder decoded response differs from retained original bytes")
                if phase == "pidof":
                    require(row["arguments"] == ["shell", "pidof", "screenrecord"],
                            "Recorder PID observation command differs")
                    if row["returncode"] == 1 and outputs == {"stdout": b"", "stderr": b""}:
                        observed_pid = None
                        require("remote-absent" in phases and "owner-confirmed" not in phases and
                                "sigint" not in phases, "Absent PID authorized a signal")
                    else:
                        require(row["returncode"] == 0 and outputs["stderr"] == b"" and
                                re.fullmatch(rb"[1-9][0-9]*", outputs["stdout"].strip()),
                                "Ambiguous/failed PID observation counted as owned")
                        observed_pid = outputs["stdout"].strip().decode("ascii")
                elif phase == "cmdline":
                    require(observed_pid and row["arguments"] ==
                            ["exec-out", "cat", "/proc/" + observed_pid + "/cmdline"] and
                            row["returncode"] == 0 and outputs["stderr"] == b"" and
                            outputs["stdout"] == b"\0".join(arg.encode() for arg in args) + b"\0",
                            "Recorder observed command does not own the exact unique target")
                else:
                    require(owner and owner["client_returncode"] is None and
                            row["arguments"] == ["shell", "kill", "-2", observed_pid] and
                            row["returncode"] == 0 and outputs == {"stdout": b"", "stderr": b""},
                            "Recorder SIGINT lacks its preceding exact ownership observation")
            elif phase == "owner-confirmed":
                require(observed_pid and "cmdline" in phases[:phases.index(phase)] and
                        row["pid"] == observed_pid and row["client_returncode"] in (None, 0),
                        "Recorder ownership event differs")
                owner = row
            else:
                require(phase == "remote-absent" and "pidof" in phases[:phases.index(phase)] and
                        observed_pid is None and row["client_returncode"] in (None, 0),
                        "Recorder absent-process event differs")
        if start["client_returncode"] is None:
            require("pidof" in phases and ("remote-absent" in phases or owner is not None),
                    "A still-running client needs its genuine remote-process observation")
            expected_phases = ["finish-start", "pidof"]
            if owner is None:
                expected_phases.append("remote-absent")
            else:
                expected_phases.extend(["cmdline", "owner-confirmed"])
                if owner["client_returncode"] is None:
                    expected_phases.append("sigint")
            expected_phases.append("client-finished")
            require(phases == expected_phases,
                    "Recorder lifecycle phases do not match the exact producer branch")
        else:
            require(phases == ["finish-start", "client-finished"],
                    "Finished recorder unexpectedly authorized more input")
    require(len(remote_ids) == 1, "Recorder segments do not share the same producer identity")
    return {"status": "PASS", "source": "actual Android producer subprocess observations",
            "file": "full-race/android-screenrecord-processes.jsonl",
            "bytes": len(raw), "sha256": sha(raw), "observations": len(rows),
            "segments": len(segments), "constructed_schedule": False}


def verify_full(full, z, sdk, harness):
    require(full["status"] == "PASS" and "error" not in full and
            full["source"] == APP and full["godot"] == GODOT and
            full["apk_sha256"] == APK_SHA and full["harness"] == harness and
            type(full["android_sdk"]) is int and full["android_sdk"] == sdk, "Full race identity")
    require(full["installed_apk"] == {"sha256": APK_SHA, "bytes": APK_BYTES, "matches_candidate": True},
            "Installed APK bytes differ")
    for name in ("pause_resume", "offline_result_recovery", "replay_deduplication",
                 "visible_flutter_return", "menu_resize", "pause_resize", "result_resize"):
        require(full[name]["status"] == "PASS", "Full race guard missing: " + name)
    require(full["fresh_race_readiness"]["status"] == "READY", "Fresh race was not ready")
    require(full["pause_resume"]["saved_pause_progress_stable"] is True and
            full["pause_resume"]["unfinished_reward_unchanged"] is True and
            0 < full["pause_resume"]["checkpoint"] < 8, "First-lap pause evidence")
    require(full["offline_result_recovery"]["reward_stars"] == 3 and
            full["offline_result_recovery"]["reward_xp"] == 0 and
            full["offline_result_recovery"]["host_acknowledged"] is True, "Actual reward/ACK")
    for field in ("same_completed_result_reopened", "host_return", "wallet_unchanged",
                  "host_acknowledged", "final_offline_restart"):
        require(full["replay_deduplication"][field] is True, "Deduplication guard: " + field)
    for phase in ("menu_resize", "pause_resize", "result_resize"):
        require(len(full[phase]["captures"]) == 4, "Four actual resize captures required")
        if phase != "menu_resize":
            require(full[phase]["saved_progress_stable"] is True, "Resize changed progress")
        for capture in full[phase]["captures"]:
            c = capture["capture"]
            safe_name(c["file"])
            require(sha(z.read(member(z, "full-race/" + c["file"]))) == c["sha256"],
                    "Actual resize PNG differs")
    trace = read_json(z, "full-race/race-trace.json")
    require(len(trace) >= 3 and any(0 < r["checkpoint_index"] < 8 and not r["finished"] for r in trace)
            and any(8 <= r["checkpoint_index"] < 16 and not r["finished"] for r in trace),
            "Both advancing laps must be observed")
    last, result_id = trace[-1], full["result_id"]
    require(all(r["result_id"] == result_id for r in trace) and last["finished"] is True and
            last["completed_race"] is True and last["checkpoint_index"] == 16 and
            last["elapsed"] > 10 and last["distance"] > trace[0]["distance"], "Actual completed race trace")
    payload = full["native_result"]
    require(last["result_payload"] == payload, "Final native result differs from trace")
    for key, value in {"resultId": result_id, "status": "completed", "game": "kart",
                       "mode": "race", "track": "sonnenhafen", "driver": "fox",
                       "kart": "comet", "checkpoints": 16, "solved": 0, "stars": 3}.items():
        require(payload.get(key) == value, "Native result field differs: " + key)
    require(type(payload["place"]) is int and 1 <= payload["place"] <= 6, "Actual race place")
    identity = {key: full[key] for key in ("source", "godot", "apk_sha256", "android_sdk", "serial")}
    require(set(full["resource_snapshots"]) == {"first-driving", "completed-before-fold"},
            "Resource snapshot phases")
    for phase, snap in full["resource_snapshots"].items():
        require(snap["status"] == "PASS" and "error" not in snap and snap["phase"] == phase and
                snap["identity"] == identity and len(snap["reads"]) == 3 and
                [r["name"] for r in snap["reads"]] == ["pid", "proc_stat", "meminfo"],
                "Read-only native resource identity")
        require(all("error" not in r and type(r["raw"]) is str and r["raw"].strip()
                    for r in snap["reads"]), "Raw resource evidence incomplete")
    video = full["video"]
    require(video["status"] == "PASS" and video["errors"] == [] and video["segments"],
            "Actual Android video incomplete")
    for segment in video["segments"]:
        require(re.fullmatch(r"android-race-\d{3}\.mp4", segment["file"]), "Video filename")
        raw = z.read(member(z, "full-race/" + segment["file"]))
        require(len(raw) == segment["bytes"] and len(raw) >= 1024 and sha(raw) == segment["sha256"],
                "Actual video bytes differ")
    summary = {"status": "PASS", "native_result": payload,
            "installed_apk": full["installed_apk"], "checkpoints": 16,
            "video_segments_verified": len(video["segments"]),
            "resource_phases": sorted(full["resource_snapshots"]),
            "not_tested": full["not_tested"]}
    if sdk == 36:
        summary["recorder_process_evidence"] = verify_recorder_processes(video, z)
    return summary


def verify_replay(z, harness):
    binding = read_json(z, "gas-replay-evidence/HARNESS-BINDING.json")
    require(binding["source"] == APP and binding["godot"] == GODOT and
            binding["harness"] == harness, "Replay source/harness identity")
    for revision, field in ((APP, "source_tree"), (harness, "harness_tree")):
        require(api_json("/git/commits/" + revision)["tree"]["sha"] == binding[field],
                "Replay Git tree identity")
    compare = api_json("/compare/" + APP + "..." + harness)
    allowed = {
        ".github/probes/kart_complete_android_probe.py",
        ".github/probes/prepare_lumo_1919_gas_replay.py",
        ".github/probes/replay_lumo_1919_gas_search.py",
        ".github/probes/fixtures/lumo-1919-baseline-apksigner.txt",
        "tools/android_qa/tests/test_gas_caption_scroll_recovery.py",
        RECORDER_TEST,
        ".github/workflows/lumo-1919-gas-recovery.yml",
        "docs/LUMO_1919_ANDROID_GAS_RECOVERY.md",
    }
    changes = compare["files"]
    require(compare["merge_base_commit"]["sha"] == APP and 0 < len(changes) <= len(allowed)
            and {f["filename"] for f in changes} <= allowed and
            all(f["status"] in ("added", "modified") for f in changes),
            "Recovery changed an unapproved product or harness path")
    require(set(binding["changed_paths"]) == {f["filename"] for f in changes},
            "Reported changed paths differ")
    required_hashes = allowed - {"docs/LUMO_1919_ANDROID_GAS_RECOVERY.md",
                                ".github/probes/fixtures/lumo-1919-baseline-apksigner.txt"}
    require(required_hashes <= set(binding["sha256"]), "Required harness hashes missing")
    for name in required_hashes:
        require(sha(source_bytes(REPO, harness, name)) == binding["sha256"][name],
                "Harness source bytes differ: " + name)
    manifest_raw = z.read(member(z, "gas-replay-fixture/MANIFEST.json"))
    manifest = json.loads(manifest_raw)
    require(type(manifest["files"]) is dict and manifest["files"], "Replay fixture manifest")
    for name, digest in manifest["files"].items():
        safe_name(name)
        hex_value(digest, 64, "fixture")
        require(sha(z.read(member(z, "gas-replay-fixture/" + name))) == digest,
                "Replay fixture bytes differ")
    roles = {"tested_probe": ".github/probes/kart_complete_android_probe.py",
             "creative_reader": ".github/probes/creative_android_probe.py",
             "surface_reader": "tools/android_qa/native_surface_readiness.py"}
    for phase, status, source in (("original", "FAIL", APP), ("candidate", "PASS", harness)):
        report = read_json(z, "gas-replay-evidence/" + phase + ".json")
        require(report["status"] == status and report["application_or_gameplay_pass"] is False and
                report["target_caption_injected"] is False and
                report["manifest_sha256"] == sha(manifest_raw), "Replay outcome/scope differs")
        if phase == "original":
            require(report["error"] == "Recorded list end received another downward search",
                    "Fixture/bootstrap failure cannot count as expected replay RED")
        else:
            require("error" not in report and report["cases"], "Replay candidate incomplete")
        require(set(report["source_files"]) == set(roles), "Replay source roles differ")
        for role, name in roles.items():
            revision = source if role == "tested_probe" else harness
            require(report["source_files"][role]["sha256"] ==
                    sha(source_bytes(REPO, revision, name)), "Actual replay functions differ")
        identity = report["original_failure_identity"]
        require(identity["source"] == APP and identity["godot"] == GODOT and
                identity["apk_sha256"] == APK_SHA and identity["android_sdk"] == 36 and
                identity["artifact_id"] == 11641916981, "Replay original failure identity")
        require(report["verified_fixture_files"], "No fixture bytes verified")
        for name, record in report["verified_fixture_files"].items():
            require(name in manifest["files"], "Unlisted replay fixture")
            raw = z.read(member(z, "gas-replay-fixture/" + safe_name(name)))
            require(record["sha256"] == sha(raw) and record["bytes"] == len(raw),
                    "Consumed replay fixture differs")
    unit_log = z.read(member(z, "gas-replay-evidence/unit-tests.log")).decode()
    unit_counts = [int(n) for n in re.findall(r"(?m)^Ran ([1-9][0-9]*) tests? in ", unit_log)]
    require("FAILED" not in unit_log and unit_counts == [33, 59, 16] and
            len(re.findall(r"(?m)^OK\s*$", unit_log)) == 3, "Replay unit suites incomplete/skipped")
    return {"status": "PASS", "harness": harness, "original_status": "FAIL",
            "original_error": "Recorded list end received another downward search",
            "candidate_status": "PASS", "application_or_gameplay_pass": False,
            "target_caption_injected": False, "manifest_sha256": sha(manifest_raw),
            "unit_test_counts": unit_counts,
            "changed_paths": sorted(binding["changed_paths"])}

def verify_recorder_regression(z, harness):
    """Check constructed OS schedules separately from authentic Android evidence."""
    old = source_bytes(REPO, RECORDER_ORIGINAL_HEAD, RECORDER_PROBE)
    new = source_bytes(REPO, harness, RECORDER_PROBE)
    test = source_bytes(REPO, harness, RECORDER_TEST)
    require(len(old) == 54526 and sha(old) == RECORDER_ORIGINAL_SHA and
            sha(new) == RECORDER_CANDIDATE_SHA and sha(test) == RECORDER_TEST_SHA,
            "Recorder approved source or unchanged test bytes differ")
    require(z.read(member(z, "gas-replay-evidence/original-recorder-probe.py")) == old,
            "Recorder original is not the exact d405 probe")

    def outside_recorder(raw):
        require(raw.count(b"class VideoRecorder:") == 1, "Recorder class boundary differs")
        prefix, body = raw.split(b"class VideoRecorder:", 1)
        require(body.count(b"\n\ndef main() -> int:") == 1, "Recorder main boundary differs")
        _, suffix = body.split(b"\n\ndef main() -> int:", 1)
        return prefix, suffix

    require(outside_recorder(old) == outside_recorder(new),
            "Recorder correction changed another probe section since d405")
    classes = [node for node in ast.parse(test).body
               if isinstance(node, ast.ClassDef) and node.name == "VideoRecorderProcessTests"]
    require(len(classes) == 1, "Recorder test class differs")
    methods = {node.name for node in classes[0].body
               if isinstance(node, ast.FunctionDef) and node.name.startswith("test_")}
    require(len(methods) == 19, "Recorder test source must define nineteen methods")
    files = {}
    for phase, status, source_sha in (("original", "FAIL", RECORDER_ORIGINAL_SHA),
                                      ("candidate", "PASS", RECORDER_CANDIDATE_SHA)):
        name = "gas-replay-evidence/" + phase + "-recorder-tests"
        raw, log_raw = z.read(member(z, name + ".json")), z.read(member(z, name + ".log"))
        report, log = json.loads(raw), log_raw.decode("utf-8")
        require(set(report) == {"schema", "status", "application_or_gameplay_pass", "fixture_kind",
                               "source", "test", "tests_run", "failures", "errors", "skipped"},
                "Recorder report fields differ")
        require(report["schema"] == "lumo.screenrecord-constructed-schedules.v1" and
                report["status"] == status and report["application_or_gameplay_pass"] is False and
                report["fixture_kind"] == RECORDER_FIXTURE_KIND and
                type(report["tests_run"]) is int and report["tests_run"] == 19 and
                report["errors"] == [] and report["skipped"] == [],
                "Recorder outcome/count/scope differs: " + phase)
        for field, digest in (("source", source_sha), ("test", RECORDER_TEST_SHA)):
            require(set(report[field]) == {"path", "sha256"} and
                    type(report[field]["path"]) is str and report[field]["path"] and
                    report[field]["sha256"] == digest, "Recorder report source differs")
        require(re.findall(r"(?m)^Ran ([1-9][0-9]*) tests? in ", log) == ["19"] and
                not re.search(r"(?m)^ERROR:|^OK \(skipped=", log), "Recorder log suite differs")
        if phase == "original":
            failures = report["failures"]
            prefix = "__main__.VideoRecorderProcessTests."
            require(type(failures) is list and len(failures) == 13 and
                    all(set(item) == {"test", "traceback"} and
                        type(item["test"]) is str and item["test"].startswith(prefix) and
                        type(item["traceback"]) is str and "\nAssertionError:" in item["traceback"]
                        for item in failures), "Recorder RED must contain only thirteen assertions")
            require({item["test"][len(prefix):] for item in failures} == RECORDER_RED_CASES and
                    re.findall(r"(?m)^FAILED \(failures=([0-9]+)\)\s*$", log) == ["13"] and
                    len(re.findall(r"(?m)^FAIL: ", log)) == 13,
                    "Unexpected recorder RED cannot replace the expected regression")
        else:
            require(report["failures"] == [] and not re.search(r"(?m)^FAIL:|^FAILED", log) and
                    len(re.findall(r"(?m)^OK\s*$", log)) == 1, "Recorder GREEN is incomplete")
            completed = re.findall(
                r"(?m)^(test_[A-Za-z0-9_]+) \(__main__\.VideoRecorderProcessTests\.\1\) \.\.\. ok$", log)
            require(len(completed) == 19 and set(completed) == methods,
                    "Recorder GREEN must execute every unchanged test method")
        files[phase] = {"report_sha256": sha(raw), "log_sha256": sha(log_raw),
                        "status": status, "tests_run": 19,
                        "assertion_failures": 13 if phase == "original" else 0}
    return {"status": "PASS", "schema": "lumo.screenrecord-constructed-schedules.v1",
            "fixture_kind": RECORDER_FIXTURE_KIND, "application_or_gameplay_pass": False,
            "authentic_pid_replay": False, "original_harness": RECORDER_ORIGINAL_HEAD,
            "candidate_harness": harness, "original_probe_sha256": RECORDER_ORIGINAL_SHA,
            "candidate_probe_sha256": RECORDER_CANDIDATE_SHA, "test_sha256": RECORDER_TEST_SHA,
            "phases": files}


def recorder_failure_history():
    """Keep the third failed attempt separate from any subsequent recovery."""
    run = checked_run(RECORDER_FAILED_RUN, 1, RECORDER_ORIGINAL_HEAD, "failure", RECOVERY_PATH)
    jobs = jobs_for(RECORDER_FAILED_RUN)
    replay = checked_job(jobs, 114014374961, REPLAY_NAME, RECORDER_FAILED_RUN,
                         1, RECORDER_ORIGINAL_HEAD, "success")
    android = checked_job(jobs, 114014576709, ANDROID_NAME, RECORDER_FAILED_RUN,
                          1, RECORDER_ORIGINAL_HEAD, "failure")
    step(android, "Verify the exact APK, provenance, baseline and signatures", "success")
    step(android, "Update exact APK and exercise the complete offline Kart flow", "failure")
    step(android, "Require both actual results and the installed APK readback", "skipped")
    items = artifact_list(RECORDER_FAILED_RUN)
    replay_artifact = checked_artifact(
        items, RECORDER_FAILED_RUN, RECORDER_ORIGINAL_HEAD,
        (11644206473, "lumo-1919-gas-replay-37987900281", 8910979,
         "7ef4f7ce4cd97e7b7fcc81115324c22574932e0690f4e94980fcd08a91788269"))
    with archive(replay_artifact, RECORDER_FAILED_RUN, RECORDER_ORIGINAL_HEAD) as z:
        binding = read_json(z, "gas-replay-evidence/HARNESS-BINDING.json")
        require(binding["source"] == APP and binding["godot"] == GODOT and
                binding["harness"] == RECORDER_ORIGINAL_HEAD and
                binding["sha256"][RECORDER_PROBE] == RECORDER_ORIGINAL_SHA,
                "Historical recorder-run replay identity differs")
        old = read_json(z, "gas-replay-evidence/original.json")
        new = read_json(z, "gas-replay-evidence/candidate.json")
        require(old["status"] == "FAIL" and
                old["error"] == "Recorded list end received another downward search" and
                new["status"] == "PASS" and "error" not in new and
                all(row["application_or_gameplay_pass"] is False and
                    row["target_caption_injected"] is False for row in (old, new)),
                "Historical Gas replay must not imply recorder or Android success")
        copy_small_reports(z, "history/recorder-failure-replay", replay_artifact["id"])
    artifact = checked_artifact(
        items, RECORDER_FAILED_RUN, RECORDER_ORIGINAL_HEAD,
        (11645193524, "lumo-1919-api36-gas-recovery-37987900281", 261443909,
         "1560e0abaa807a6be31c52165c983ddf788c25b6fbb2a208ab82f6233a78b865"))
    with archive(artifact, RECORDER_FAILED_RUN, RECORDER_ORIGINAL_HEAD) as z:
        validate_identity(primary_result(z), "kart", 36, RECORDER_ORIGINAL_HEAD)
        failed = read_json(z, "full-race/result.json")
        require(failed["status"] == "FAIL" and failed["error"] == RECORDER_FAILURE and
                failed["source"] == APP and failed["godot"] == GODOT and
                failed["harness"] == RECORDER_ORIGINAL_HEAD and failed["apk_sha256"] == APK_SHA and
                failed["android_sdk"] == 36 and failed["installed_apk"] ==
                {"sha256": APK_SHA, "bytes": APK_BYTES, "matches_candidate": True},
                "Historical recorder failure/source identity differs")
        video = failed["video"]
        require(video["status"] == "NOT_EXECUTED_OR_FAILED" and
                video["errors"] == ["Cannot safely identify the owned screenrecord process"] and
                len(video["segments"]) == 5, "Historical incomplete footage differs")
        for segment in video["segments"]:
            require(re.fullmatch(r"android-race-\d{3}\.mp4", segment["file"]),
                    "Historical video segment name")
            raw = z.read(member(z, "full-race/" + segment["file"]))
            require(len(raw) == segment["bytes"] and len(raw) >= 1024 and sha(raw) == segment["sha256"],
                    "Historical partial footage bytes differ")
        guards = {name: failed[name]["status"] for name in
                  ("pause_resume", "offline_result_recovery", "replay_deduplication",
                   "visible_flutter_return", "menu_resize", "pause_resize", "result_resize")}
        require(set(guards.values()) == {"PASS"} and
                failed["offline_result_recovery"] ==
                {"status": "PASS", "reward_stars": 3, "reward_xp": 0, "host_acknowledged": True},
                "Historical race/reward sub-results differ")
        for key in ("same_completed_result_reopened", "host_return", "wallet_unchanged",
                    "host_acknowledged", "final_offline_restart"):
            require(failed["replay_deduplication"][key] is True,
                    "Historical completed-result recovery differs")
        trace = read_json(z, "full-race/race-trace.json")
        payload = failed["native_result"]
        require(trace and trace[-1]["result_payload"] == payload and
                trace[-1]["finished"] is True and trace[-1]["completed_race"] is True and
                trace[-1]["checkpoint_index"] == 16 and
                payload["resultId"] == failed["result_id"] and payload["status"] == "completed" and
                payload["game"] == "kart" and payload["mode"] == "race" and
                payload["checkpoints"] == 16 and payload["solved"] == 0 and payload["stars"] == 3,
                "Historical completed native result differs")
        require(not any(name.endswith("/android-screenrecord-processes.jsonl") or
                        name == "android-screenrecord-processes.jsonl" for name in z.namelist()),
                "Historical raw PID observation unexpectedly differs")
        copy_small_reports(z, "history/recorder-collection", artifact["id"])
        png(z, "full-race/failure.png", "history/recorder-collection/failure.png", artifact["id"])
    return {"classification": "runtime-probe recorder collection failure after race/reward/reopen",
            "run": run_meta(run), "job": job_meta(android), "replay_job": job_meta(replay),
            "artifact_id": artifact["id"], "replay_artifact_id": replay_artifact["id"],
            "error": RECORDER_FAILURE, "creative_probe": "PASS", "full_race_probe": "FAIL",
            "recorded_sub_results": guards, "native_result_id": payload["resultId"],
            "reward_stars": 3, "reward_xp": 0, "verified_segments_before_failure": 5,
            "video_status": "NOT_EXECUTED_OR_FAILED",
            "raw_pid_response": "NOT RECORDED BY THIS HARNESS",
            "replaced_only_for_required_coverage": True}


def main():
    lock = validated_lock()
    require(json.loads(source_bytes(REPO, APP, "config/godot-source.json"))["revision"] == GODOT,
            "Original App/Godot source pin differs")
    require(re.search(r"(?m)^version:\s*0\.12\.12\+1919\s*$",
                      source_bytes(REPO, APP, "pubspec.yaml").decode()), "Original source version differs")
    original = checked_run(RUN, 1, APP, "failure", ".github/workflows/lumo-runtime-apk.yml")
    jobs = jobs_for(RUN)
    checked = [checked_job(jobs, job_id, name, RUN, 1, APP, "success")
               for name, job_id in EXPECTED_JOBS.items() if name != "android (kart, 36)"]
    require(len(checked) == 6, "Exactly six original successful jobs required")
    original_failure = checked_job(jobs, 113988997647, "android (kart, 36)", RUN, 1, APP, "failure")
    original_package = checked_job(jobs, 114005456901, "Package verified Android test APK",
                                   RUN, 1, APP, "skipped")
    step(original_failure, "Update exact APK and exercise actual offline native game", "failure")
    recovery_id, attempt, harness = (lock["recovery_run_id"], lock["recovery_run_attempt"],
                                     lock["recovery_head_sha"])
    recovery = checked_run(recovery_id, attempt, harness, "success", RECOVERY_PATH)
    recovery_jobs = jobs_for(recovery_id)
    replay_job = checked_job(recovery_jobs, lock["replay_job_id"], REPLAY_NAME,
                             recovery_id, attempt, harness, "success")
    android_job = checked_job(recovery_jobs, lock["android_job_id"], ANDROID_NAME,
                              recovery_id, attempt, harness, "success")
    for name in ("Require unchanged product sources and bind the harness",
                 "Run targeted regressions before any emulator",
                 RECORDER_STEP,
                 "Retrieve the pinned original API36 failure fixtures",
                 "Require the original regression and candidate recovery"):
        step(replay_job, name, "success")
    for name in ("Verify the exact APK, provenance, baseline and signatures",
                 "Update exact APK and exercise the complete offline Kart flow",
                 "Require both actual results and the installed APK readback"):
        step(android_job, name, "success")
    old_artifacts, new_artifacts = artifact_list(RUN), artifact_list(recovery_id)
    require(not OUT.exists(), "Refusing to mix an existing output directory")
    OUT.mkdir()
    write_file("AGGREGATION-LOCK.json", LOCK_PATH.read_bytes(), None,
               "git:" + os.environ["GITHUB_SHA"] + ":" + str(LOCK_PATH))
    candidate = checked_artifact(old_artifacts, RUN, APP, ORIGINAL_ARTIFACTS["apk"])
    with archive(candidate, RUN, APP) as z:
        provenance = read_json(z, "BUILD-PROVENANCE.json")
        verification = read_json(z, "APK-VERIFICATION.json")
        raw = z.read(member(z, "Lumo-Lernen-Neu.apk"))
        require(len(raw) == APK_BYTES and sha(raw) == APK_SHA, "Actual original APK bytes differ")
        for report in (provenance, verification):
            require(report["sha256"] == APK_SHA and report["bytes"] == APK_BYTES and
                    report["versionName"] == "0.12.12" and report["versionCode"] == 1919 and
                    report["godot"]["revision"] == GODOT and report["godot"]["pck_sha256"] == PCK_SHA and
                    report["signingCertificateSha256"] == CERT, "APK provenance/report differs")
        require(provenance["flutter_source_commit"] == APP and
                provenance["tracked_source_clean"] is True, "Original product source was not clean")
        require(verification["minSdk"] == 24 and verification["targetSdk"] == 36 and
                verification["abis"] == ["arm64-v8a", "x86_64"] and
                verification["elf16KiBAligned"] is True and
                verification["resourcesArscAligned"] is True and
                verification["package"] == "dev.ullmann.lumo.lumo_lernen.coachpreview",
                "Original APK platform contract differs")
        with zipfile.ZipFile(io.BytesIO(raw)) as apk:
            require(len(apk.namelist()) == len(set(apk.namelist())) and apk.testzip() is None,
                    "Actual APK ZIP integrity differs")
            embedded = read_json(apk, "lumo_game_source.json")
            require(embedded["revision"] == GODOT and embedded["pck_sha256"] == PCK_SHA,
                    "Embedded APK source differs")
            packs = [n for n in apk.namelist() if n.endswith(".pck")]
            require(len(packs) == 1 and sha(apk.read(packs[0])) == PCK_SHA, "Actual PCK bytes differ")
        write_file(APK_NAME, raw, candidate["id"], member(z, "Lumo-Lernen-Neu.apk"))
        del raw
        profile = read_json(z, "PROFILE-IDENTITY-EVIDENCE.json")
        character = read_json(z, "character-review/CHARACTER-EVIDENCE.json")
        profile_summary = verify_profile(profile)
        character_summary = verify_character(character, z, candidate["id"])
        for name in ("BUILD-PROVENANCE.json", "APK-VERIFICATION.json",
                     "PROFILE-IDENTITY-EVIDENCE.json", "character-review/CHARACTER-EVIDENCE.json"):
            entry = member(z, name)
            write_file(name, z.read(entry), candidate["id"], entry)
        copy_small_reports(z, "original-candidate", candidate["id"])

    for game in ("build", "puzzle", "rhythm", "treasure", "kart"):
        artifact = checked_artifact(old_artifacts, RUN, APP, ORIGINAL_ARTIFACTS[game])
        with archive(artifact, RUN, APP) as z:
            result = primary_result(z)
            validate_identity(result, game, 35, APP)
            require(result[game]["status"] == "PASS" and "error" not in result,
                    "Original native game sub-check differs")
            key = game + "-api35"
            copy_small_reports(z, "android/" + key, artifact["id"])
            png(z, "01_updated_profile.png", "android/" + key + "/updated-profile.png", artifact["id"])
            ANDROID[key] = {"status": "PASS", "source": APP, "harness": APP, "android_sdk": 35,
                            "artifact_id": artifact["id"], "tested_games": [game]}
            if game == "kart":
                full = read_json(z, "full-race/result.json")
                ANDROID[key]["full_race"] = verify_full(full, z, 35, APP)
                for suffix, title in (
                        ("04-driving-000.png", "race"),
                        ("06-completed-result-phone.png", "result"),
                        ("12-same-completed-result-reopened.png", "reopened-result"),
                        ("13-completed-race-returned-to-app.png", "returned-to-app")):
                    png(z, "full-race/" + suffix, "android/" + key + "/" + title + ".png", artifact["id"])

    artifact = checked_artifact(old_artifacts, RUN, APP, ORIGINAL_ARTIFACTS["failed-api36"])
    with archive(artifact, RUN, APP) as z:
        prior_creative = primary_result(z)
        validate_identity(prior_creative, "kart", 36, APP)
        failed = read_json(z, "full-race/result.json")
        require(failed["status"] == "FAIL" and
                failed["error"] == "Screenshot tile OCR deadline exceeded" and
                failed["source"] == APP and failed["godot"] == GODOT and
                failed["harness"] == APP and failed["apk_sha256"] == APK_SHA and
                failed["android_sdk"] == 36, "Historical API36 failure differs")
        copy_small_reports(z, "history/original-api36", artifact["id"])
        png(z, "full-race/failure.png", "history/original-api36/failure.png", artifact["id"])
        history = [{"classification": "runtime-probe input-search failure",
                    "run": run_meta(original), "job": job_meta(original_failure),
                    "artifact_id": artifact["id"], "error": failed["error"],
                    "creative_probe": "PASS", "full_race_probe": "FAIL",
                    "replaced_only_for_required_coverage": True}]

    setup_id, setup_head = 37987154620, "5b40528b19023ec83e0696d836766f71e7f5cea4"
    setup_run = checked_run(setup_id, 1, setup_head, "failure", RECOVERY_PATH)
    setup_jobs = jobs_for(setup_id)
    setup_replay = checked_job(setup_jobs, 114011886647, REPLAY_NAME, setup_id, 1, setup_head, "success")
    setup_job = checked_job(setup_jobs, 114012071636, ANDROID_NAME, setup_id, 1, setup_head, "failure")
    step(setup_job, "Verify the exact APK, provenance, baseline and signatures", "failure")
    step(setup_job, "Update exact APK and exercise the complete offline Kart flow", "skipped")
    setup_artifact = checked_artifact(
        artifact_list(setup_id), setup_id, setup_head,
        (11643567447, "lumo-1919-api36-gas-recovery-37987154620", 8912041,
         "8747cb54a5f370ee34c4b4abdf76c8cc386fb884284d72562c733cc536d259bd"))
    with archive(setup_artifact, setup_id, setup_head) as z:
        copy_small_reports(z, "history/signer-reader-setup", setup_artifact["id"])
    history.append({"classification": "signer-output reader assertion before emulator",
                    "run": run_meta(setup_run), "job": job_meta(setup_job),
                    "replay_job": job_meta(setup_replay), "artifact_id": setup_artifact["id"],
                    "android_runtime_executed": False, "android_runtime_result": "NOT EXECUTED"})
    history.append(recorder_failure_history())

    replay_artifact = checked_artifact(new_artifacts, recovery_id, harness,
                                       lock_contract(lock["artifacts"]["replay"]))
    with archive(replay_artifact, recovery_id, harness) as z:
        replay_summary = verify_replay(z, harness)
        recorder_summary = verify_recorder_regression(z, harness)
        copy_small_reports(z, "recovery-replay", replay_artifact["id"])
    artifact = checked_artifact(new_artifacts, recovery_id, harness,
                                 lock_contract(lock["artifacts"]["android"]))
    with archive(artifact, recovery_id, harness) as z:
        binding = read_json(z, "APK-RETEST-BINDING.json")
        require(binding["source"] == APP and binding["godot"] == GODOT and
                binding["harness"] == harness and binding["candidate_artifact_id"] == 11639898022 and
                binding["candidate_run_id"] == RUN and binding["apk_sha256"] == APK_SHA and
                binding["apk_bytes"] == APK_BYTES and binding["versionName"] == "0.12.12" and
                binding["versionCode"] == 1919 and binding["signingCertificateSha256"] == CERT and
                binding["binary_signatures_verified"] is True and binding["baseline_run_id"] == 37674457852 and
                binding["baseline_sha256"] == "82865962c7c00413c75bfc2e427a201bb957ab564d8c8eb944f2b798dfbf1511",
                "Retest APK/source/baseline binding differs")
        result = primary_result(z)
        validate_identity(result, "kart", 36, harness)
        require(result["kart"]["status"] == "PASS" and "error" not in result, "Recovered native Kart check")
        full = read_json(z, "full-race/result.json")
        full_summary = verify_full(full, z, 36, harness)
        copy_small_reports(z, "android/kart-api36", artifact["id"])
        png(z, "01_updated_profile.png", "android/kart-api36/updated-profile.png", artifact["id"])
        for suffix, title in (
                ("04-driving-000.png", "race"), ("06-completed-result-phone.png", "result"),
                ("12-same-completed-result-reopened.png", "reopened-result"),
                ("13-completed-race-returned-to-app.png", "returned-to-app")):
            png(z, "full-race/" + suffix, "android/kart-api36/" + title + ".png", artifact["id"])
        ANDROID["kart-api36"] = {"status": "PASS", "source": APP, "harness": harness,
                                "android_sdk": 36, "artifact_id": artifact["id"],
                                "tested_games": ["kart"], "full_race": full_summary}
    require(set(ANDROID) == {"build-api35", "puzzle-api35", "rhythm-api35", "treasure-api35",
                             "kart-api35", "kart-api36"}, "Final required Android coverage differs")
    require(sha((OUT / APK_NAME).read_bytes()) == APK_SHA, "Output APK changed")
    summary = {
        "schema": "lumo.existing-apk-aggregation.v1",
        "status": "VERIFIED_BY_AGGREGATION", "required_checks_covered": True,
        "all_source_runs_successful": False,
        "scope": "Unchanged APK1919: six original successful checks and targeted API36 follow-up",
        "apk_file": APK_NAME, "apk_sha256": APK_SHA, "apk_bytes": APK_BYTES,
        "versionName": "0.12.12", "versionCode": 1919,
        "flutter_source_commit": APP, "godot_source_commit": GODOT, "pck_sha256": PCK_SHA,
        "signingCertificateSha256": CERT, "original_apk_artifact_id": candidate["id"],
        "aggregation_commit": os.environ["GITHUB_SHA"], "aggregation_run_id": int(os.environ["GITHUB_RUN_ID"]),
        "aggregation_lock_sha256": sha(LOCK_PATH.read_bytes()),
        "original_run": run_meta(original), "original_packaging": job_meta(original_package),
        "original_successful_jobs": [job_meta(j) for j in checked],
        "recovery_run": run_meta(recovery), "recovery_harness_commit": harness,
        "recovery_replay_job": job_meta(replay_job), "recovery_android_job": job_meta(android_job),
        "recorded_prior_failures": history, "profile_identity": profile_summary,
        "character_evidence": character_summary, "harness_replay": replay_summary,
        "recorder_regression": recorder_summary,
        "android": ANDROID, "archives": ARTIFACTS, "files": FILES, "images": IMAGES,
        "profile_identity_evidence_sha256": sha((OUT / "PROFILE-IDENTITY-EVIDENCE.json").read_bytes()),
        "character_evidence_sha256": sha((OUT / "character-review/CHARACTER-EVIDENCE.json").read_bytes()),
        "physical_device_performance": "NOT EXECUTED",
        "not_executed_by_aggregator": ["new build", "new game run", "physical device", "audio evaluation",
                                     "manual visual approval"],
        "selection": "Exact APK; all twenty character PNGs; original reports up to 5 MB; selected unchanged Android PNGs. Videos are byte-verified in producer archives and not copied.",
    }
    (OUT / "QA-RESULTS.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n")
    (OUT / "README.md").write_text(
        "# Lumo 0.12.12+1919 test APK\n\nThe APK bytes are unchanged: " + APK_SHA +
        ". Six successful original checks and the separately identified API36 follow-up cover the required gates.\n\n"
        "Original run 37975946198 remains FAILURE; its API36 input-search failure and skipped packaging job are retained. "
        "Run 37987154620 also remains FAILURE: its signer-output reader assertion occurred before emulator execution. "
        "Run 37987900281 remains FAILURE: its race/reward/reopen sub-results passed, but recorder collection failed.\n\n"
        "The separate nineteen recorder unit cases use constructed subprocess schedules, not recorded failure PID responses. "
        "Their expected original RED and candidate GREEN are not Android gameplay results; the final API36 producer must pass "
        "independently with complete byte-verified videos and genuine recorder process observations.\n\n"
        "QA-RESULTS.json binds exact runs, attempts, jobs, sources, report hashes and byte-verified ZIPs. "
        "character-review contains real desktop Godot captures; android contains real emulator captures. "
        "No physical-device/FPS/audio or manual visual approval is claimed. "
        "Original reports may refer to uncopied videos, XML and galleries; their original artifact IDs and verified hashes remain recorded.\n")
    files = sorted(p for p in OUT.rglob("*") if p.is_file())
    (OUT / "SHA256SUMS.txt").write_text("".join(
        sha(path.read_bytes()) + "  " + path.relative_to(OUT).as_posix() + "\n" for path in files))
    compact = {key: summary[key] for key in (
        "status", "required_checks_covered", "all_source_runs_successful", "apk_file", "apk_sha256",
        "apk_bytes", "flutter_source_commit", "godot_source_commit", "original_run",
        "recovery_run", "recovery_harness_commit", "profile_identity", "character_evidence")}
    compact["verified_original_job_ids"] = [j["id"] for j in checked]
    compact["verified_recovery_job_ids"] = [replay_job["id"], android_job["id"]]
    compact["recorded_failures"] = [{"run_id": row["run"]["id"], "classification": row["classification"]}
                                    for row in history]
    compact["android_statuses"] = {name: row["status"] for name, row in ANDROID.items()}
    compact["included_files"] = len(files) + 1
    compact["qa_results_sha256"] = sha((OUT / "QA-RESULTS.json").read_bytes())
    print("LUMO_AGGREGATION_JSON " + json.dumps(compact, ensure_ascii=False), flush=True)
    if os.environ.get("LUMO_EMIT_FOUR_VIEWS") == "1":
        name = "character-review/lumo-driver-4views.png"
        meta = next(row for row in IMAGES if row["file"] == name)
        raw = (OUT / name).read_bytes()
        require(sha(raw) == meta["sha256"], "Final displayed four-view PNG changed")
        emit_png(meta, raw)
    print("[Lumo1919Aggregation] VERIFIED_BY_AGGREGATION: exact APK; six original successful checks plus targeted API36; original failures retained", flush=True)

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        detail = str(error) if isinstance(error, RuntimeError) else type(error).__name__
        print("[Lumo1919Aggregation] FAILED: " + detail, flush=True)
        raise SystemExit(1)
