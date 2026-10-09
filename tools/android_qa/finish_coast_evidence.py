#!/usr/bin/env python3
"""Validate the source-bound, assigned-state FinishCoast16 probe evidence.

This reader does not start Godot and does not certify a driven race, GL, Android,
or an APK. The workflow runs the producer once before invoking this reader.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import sys


SOURCES = {
    "scripts/games/kart_island.gd": "00e4c7223465f4fcab165b2a603b17bc7bc9eb1727c4a9f5291fffc9d671fee2",
    "scripts/games/kart_vehicle.gd": "0b67b43385934109f77ea62ae4f5f517e49344fd9cc1824a11fd56b65d8bc671",
    "scripts/games/kart_world.gd": "f14f5e953fa878f10f090d8ce284afcb75ad692cfaac6a1f124cf29de6ea030a",
    "project.godot": "eac3b969cc475e9b9047d420eb6012a1b98b127c1a8706a9eb88e0e83f33b280",
    "scripts/tests/kart_finish_coast_regression.gd": "39d201352e1ece35de7fbc01de007d04a08845ba33e4300c0ac1b7cdaf62c32d",
    "scripts/tests/kart_finish_coast_fixtures.gd": "bdb788e89150f5db211f148b6e3cbc130e2b83e97ff00c5085bb2ed5f93b0e07",
}
ENGINE_SHA256 = "f64d4ed19fc9df9440321653fcc80df8c6e365ba7b6de0a29e2cfa9fa71bfeb3"
ENGINE = {
    "build": "official", "hash": "7d41c59c457bd5a245092b4e7eb2d833e3b3f8c3",
    "hex": 263683, "major": 4, "minor": 6, "patch": 3, "status": "stable",
    "string": "4.6.3-stable (official)", "timestamp": 0,
}
CRITERIA = {
    "absolute_lateral_max_m": 5.0001,
    "ground_error_max_m": 0.002,
    "normal_dot_min": 0.999,
    "camera_distance_min_m": 2.2,
    "reduced_camera_roll_max_rad_exclusive": 0.0001,
    "reduced_camera_orbit_max_rad_exclusive": 0.15,
    "edge_contact_feedback_per_step_max": 1,
}
NAMES = (
    "normal55degrees", "reduced55degrees", "zero_velocity", "near_zero_velocity",
    "reverse_velocity_and_wheels", "left_edge_outward_contact", "right_edge_outward_contact",
    "curved_segment_contact", "sloped_surface_ground", "ramp_surface_ground",
    "airborne_gravity", "pause_freezes_coast", "skip_does_not_move",
    "progress_payload_remain_frozen", "actual_box_camera_clearance",
    "reduced_motion_camera_no_orbit_roll",
)
INPUT_SPEEDS = (17.015, 17.015, 0.0, 0.03, 5.0, 17.0, 17.0, 20.0, 10.0, 1.0)
SCOPE = "Sixteen finish motion/camera unit fixtures on actual geometry; not a driven race"
MARKER = "[PhysicalFinishCoast] PASS: 16 numerical controls, 0 failures"
ENGINE_HEADER = "Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org"
FAIL_LOG = re.compile(
    r"SCRIPT ERROR|Parse Error|ERROR:|Assertion failed|Failed to load|"
    r"\[ProbeRunner\] (?:FAIL|timeout)|\[PhysicalFinishCoast\] FAIL|"
    r"ObjectDB instances leaked at exit|resources still in use at exit|"
    r"RID allocations? .*leaked|RIDs?\b[^\n]*leaked|leaked (?:RID|texture)|"
    r"TextureStorage.*leak|leaked at exit",
    re.IGNORECASE,
)
VECTOR = re.compile(r"\(([^,]+), ([^,]+), ([^,]+)\)")
CASE_BOOLS = {"entry_kept", "frozen", "damping", "sign_kept", "stopped", "clear_camera"}
CASE_INTS = {"confetti_calls", "steps", "wall_contacts", "max_contacts_per_step"}
CASE_NUMBERS = {
    "max_lane", "max_ground_error", "minimum_normal_dot", "minimum_camera_distance",
    "displacement", "end_speed", "max_velocity", "max_camera_roll", "max_camera_orbit",
}
CASE_KEYS = CASE_BOOLS | CASE_INTS | CASE_NUMBERS
POSE_KEYS = {"case", "frame", "position", "velocity", "speed", "lane", "ground_error", "camera_distance"}


class EvidenceError(ValueError):
    pass


def need(condition, message):
    if not condition:
        raise EvidenceError(message)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def object_pairs(pairs):
    result = {}
    for key, value in pairs:
        need(key not in result, f"duplicate JSON key: {key}")
        result[key] = value
    return result


def decode(raw, name):
    def invalid_constant(value):
        raise EvidenceError(f"{name}: nonfinite JSON constant {value}")
    return json.loads(raw.decode("utf-8"), object_pairs_hook=object_pairs,
                      parse_constant=invalid_constant)


def number(value, label):
    need(type(value) in (int, float) and math.isfinite(value), f"{label}: finite number required")
    return value


def vector(value, label):
    need(type(value) is str, f"{label}: serialized vector required")
    match = VECTOR.fullmatch(value)
    need(match is not None, f"{label}: malformed vector")
    try:
        result = tuple(float(item) for item in match.groups())
    except ValueError as error:
        raise EvidenceError(f"{label}: malformed vector components") from error
    need(all(math.isfinite(item) for item in result), f"{label}: nonfinite vector")
    return result


def exact_object(value, keys, label):
    need(type(value) is dict and set(value) == set(keys), f"{label}: exact fields required")


def true(value, label):
    need(value is True, f"{label}: true boolean required")


def close(actual, expected, label, tolerance=1e-12):
    need(math.isclose(number(actual, label), number(expected, label), rel_tol=1e-12,
                      abs_tol=tolerance), f"{label}: does not match emitted measurements")


def validate(project, evidence, motion, log, engine, source_revision_file=None,
             expected_source_revision=None):
    raw_sources = {}
    for path, expected in SOURCES.items():
        raw = (project / path).read_bytes()
        need(digest(raw) == expected, f"source file drift: {path}")
        raw_sources[path] = digest(raw)
    engine_raw = engine.read_bytes()
    need(digest(engine_raw) == ENGINE_SHA256, "engine executable bytes do not match official 4.6.3 Linux binary")
    evidence_raw, motion_raw, log_raw = evidence.read_bytes(), motion.read_bytes(), log.read_bytes()
    data, poses = decode(evidence_raw, "evidence"), decode(motion_raw, "motion")
    exact_object(data, {"status", "source_sha256", "source_hashes", "engine_executable_sha256",
                        "checks", "failed", "assigned_state_scope", "fixed_criteria", "engine"}, "evidence")
    need(data["status"] == "PASS", "evidence status must be PASS")
    need(type(data["failed"]) is int and data["failed"] == 0, "failed count must be integer zero")
    need(data["source_sha256"] == SOURCES["scripts/games/kart_island.gd"], "core binding differs")
    exact_object(data["source_hashes"], SOURCES, "source_hashes")
    need(data["source_hashes"] == raw_sources, "evidence source hashes differ from exact disk files")
    need(data["engine_executable_sha256"] == ENGINE_SHA256, "evidence engine executable binding differs")
    exact_object(data["engine"], ENGINE, "engine")
    for key, expected in ENGINE.items():
        need(type(data["engine"][key]) is type(expected) and data["engine"][key] == expected,
             f"engine metadata differs: {key}")
    need(data["assigned_state_scope"] == SCOPE, "assigned-state scope differs")
    exact_object(data["fixed_criteria"], CRITERIA, "fixed_criteria")
    for key, expected in CRITERIA.items():
        need(number(data["fixed_criteria"][key], key) == expected, f"fixed criterion differs: {key}")
        if type(expected) is int:
            need(type(data["fixed_criteria"][key]) is int, f"{key}: integer required")

    checks = data["checks"]
    need(type(checks) is list and len(checks) == 16, "exactly sixteen ordered rows required")
    for index, (row, name) in enumerate(zip(checks, NAMES)):
        exact_object(row, {"name", "passed", "actual"}, f"row {index}")
        need(type(row["name"]) is str and row["name"] == name, f"row {index}: label or order differs")
        true(row["passed"], name)
        need(type(row["actual"]) is dict, f"{name}: actual object required")
    actual = [row["actual"] for row in checks]

    for index, value in enumerate(actual[:10]):
        name = NAMES[index]
        exact_object(value, CASE_KEYS, name)
        for key in CASE_BOOLS:
            need(type(value[key]) is bool, f"{name}.{key}: boolean required")
        for key in CASE_BOOLS - {"clear_camera"}:
            true(value[key], f"{name}.{key}")
        for key in CASE_INTS:
            need(type(value[key]) is int and value[key] >= 0, f"{name}.{key}: nonnegative integer required")
        for key in CASE_NUMBERS:
            number(value[key], f"{name}.{key}")
            if key != "end_speed":
                need(value[key] >= 0, f"{name}.{key}: nonnegative measurement required")
        need(value["max_lane"] <= 5.0001, f"{name}: lateral limit exceeded")
        need(value["max_ground_error"] <= 0.002, f"{name}: ground limit exceeded")
        need(value["minimum_normal_dot"] >= 0.999, f"{name}: surface-normal limit missed")
        steps = (21, 22) if index == 1 else (192, 193)
        need(value["steps"] in steps, f"{name}: observed step count differs from fixed duration")
        close(value["max_velocity"], INPUT_SPEEDS[index], f"{name}.fixed input speed", 1e-4)
        if index == 4:
            need(value["end_speed"] <= 0.00001, f"{name}: reverse sign lost")
        else:
            need(value["end_speed"] >= -0.00001, f"{name}: forward sign lost")
    need(actual[2]["displacement"] < 0.002 and actual[2]["max_velocity"] == 0.0,
         "zero velocity moved or gained velocity")
    need(actual[3]["displacement"] < 0.002 and actual[3]["end_speed"] == 0.0,
         "near-zero velocity moved or did not stop")
    for index in (5, 6):
        need(actual[index]["wall_contacts"] > 0 and actual[index]["max_contacts_per_step"] <= 1,
             f"{NAMES[index]}: edge contact/feedback predicate failed")

    exact_object(actual[10], {"position", "vertical_speed", "airborne"}, NAMES[10])
    air_position = vector(actual[10]["position"], "airborne position")
    true(actual[10]["airborne"], "airborne gravity")
    need(number(actual[10]["vertical_speed"], "airborne vertical_speed") < 4.0,
         "airborne gravity did not reduce initial vertical speed")
    exact_object(actual[11], {"position", "timer"}, NAMES[11])
    pause_position = vector(actual[11]["position"], "pause position")
    need(number(actual[11]["timer"], "pause timer") == 3.2, "pause did not retain initial finish timer")
    # Both source-bound fixtures use the same Bergwelt pose. The airborne fixture
    # adds 3m before the one step; raw road height and prior velocity are absent.
    need(air_position[1] > pause_position[1] + 3.0, "airborne fixture did not rise above its assigned start")
    exact_object(actual[12], {"position", "timer", "result_seen"}, NAMES[12])
    need(vector(actual[12]["position"], "skip position") == pause_position, "skip changed position")
    need(number(actual[12]["timer"], "skip timer") == 0.0, "skip did not clear timer")
    true(actual[12]["result_seen"], "skip result_seen")

    linked = {"normal": 0, "reduced": 1, "left": 5, "right": 6, "ramp": 9}
    exact_object(actual[13], linked, NAMES[13])
    for key, index in linked.items():
        true(actual[13][key], f"progress frozen {key}")
        need(actual[13][key] is actual[index]["frozen"], f"progress summary differs: {key}")
    exact_object(actual[14], {"normal", "left", "right", "normal_clear", "left_clear", "right_clear"}, NAMES[14])
    for key, index in {"normal": 0, "left": 5, "right": 6}.items():
        close(actual[14][key], actual[index]["minimum_camera_distance"], f"camera summary {key}")
        need(actual[14][key] >= 2.2, f"camera clearance too short: {key}")
        true(actual[14][key + "_clear"], f"camera summary clear {key}")
        true(actual[index]["clear_camera"], f"camera measured clear {key}")
    true(actual[1]["clear_camera"], "reduced measured camera clear")
    exact_object(actual[15], {"confetti_calls", "max_camera_roll", "max_camera_orbit", "mechanism"}, NAMES[15])
    need(type(actual[15]["confetti_calls"]) is int and actual[15]["confetti_calls"] == 0,
         "reduced motion confetti must be integer zero")
    need(actual[15]["confetti_calls"] == actual[1]["confetti_calls"], "reduced confetti summary differs")
    for key, limit in (("max_camera_roll", 0.0001), ("max_camera_orbit", 0.15)):
        close(actual[15][key], actual[1][key], f"reduced summary {key}")
        need(0 <= actual[15][key] < limit, f"reduced motion {key} limit missed")
    need(actual[15]["mechanism"] == "reduced branch uses ordinary chase instead of orbit",
         "reduced motion mechanism differs")

    need(type(poses) is list and len(poses) == sum(value["steps"] for value in actual[:10]),
         "motion count differs from observed steps")
    cursor = 0
    for index, value in enumerate(actual[:10]):
        name, count = NAMES[index], value["steps"]
        group = poses[cursor:cursor + count]
        cursor += count
        prior_velocity = value["max_velocity"]
        for frame, pose in enumerate(group):
            exact_object(pose, POSE_KEYS, f"{name} pose {frame}")
            need(pose["case"] == name, f"motion case/order differs: {name}")
            need(type(pose["frame"]) is int and pose["frame"] == frame, f"motion frame/order differs: {name}")
            vector(pose["position"], f"{name} position {frame}")
            velocity = vector(pose["velocity"], f"{name} velocity {frame}")
            magnitude = math.sqrt(sum(component * component for component in velocity))
            # The producer serializes vectors with limited decimal precision.
            # Preserve its 0.0001 damping criterion with 0.00002 serialization allowance.
            need(magnitude <= prior_velocity + 0.00012, f"{name}: motion velocity increased")
            need(magnitude <= value["max_velocity"] + 0.00002, f"{name}: motion velocity exceeds input")
            prior_velocity = magnitude
            for key in ("speed", "lane", "ground_error", "camera_distance"):
                number(pose[key], f"{name} motion {key} {frame}")
            need(abs(pose["lane"]) <= 5.0001 and abs(pose["ground_error"]) <= 0.002,
                 f"{name}: raw motion leaves road/surface")
            need(pose["camera_distance"] >= 0, f"{name}: negative camera distance")
            need(abs(pose["speed"]) <= value["max_velocity"] + 0.00002, f"{name}: motion speed exceeds input")
            need(pose["speed"] <= 0.00001 if index == 4 else pose["speed"] >= -0.00001,
                 f"{name}: raw motion speed sign changed")
        close(max(abs(pose["lane"]) for pose in group), value["max_lane"], f"{name}.max_lane")
        close(max(abs(pose["ground_error"]) for pose in group), value["max_ground_error"], f"{name}.max_ground_error")
        close(min(pose["camera_distance"] for pose in group), value["minimum_camera_distance"], f"{name}.minimum_camera_distance")
        close(group[-1]["speed"], value["end_speed"], f"{name}.end_speed")

    log_text = log_raw.decode("utf-8")
    need(log_text.splitlines().count(MARKER) == 1 and log_text.count(MARKER) == 1,
         "exactly one complete FinishCoast success marker required")
    need(log_text.splitlines().count(ENGINE_HEADER) == 1, "official engine header missing or duplicated")
    need(FAIL_LOG.search(log_text) is None, "engine error, failure, timeout or leaked resources in producer log")
    source_revision = None
    need((source_revision_file is None) == (expected_source_revision is None), "both source revision inputs are required together")
    if source_revision_file is not None:
        source_revision = source_revision_file.read_text(encoding="utf-8").strip()
        need(re.fullmatch(r"[0-9a-f]{40}", source_revision) is not None and
             source_revision == expected_source_revision, "source revision does not equal exact APK pin")
    return {
        "status": "PASS", "checks": 16, "motion_pose_count": len(poses),
        "source_revision": source_revision, "source_sha256": raw_sources,
        "engine_executable_sha256": ENGINE_SHA256,
        "evidence_sha256": digest(evidence_raw), "motion_sha256": digest(motion_raw),
        "log_sha256": digest(log_raw), "scope": SCOPE,
        "raw_recomputed": ["ordered motion groups/frames", "lateral maximum", "ground error maximum",
                           "camera distance minimum", "end speed", "motion speed sign",
                           "finite vectors", "damped velocity within vector serialization precision"],
        "additional_reader_guard": "Summary input speed matches fixed fixture; raw speed/velocity cannot exceed that input",
        "source_bound_limits": ["pre-step entry pose/velocity", "basis/normal dot", "progress payload snapshots",
                                "wheel motion speed", "timer/result state", "wall-contact increments",
                                "actual OBB intersections", "camera orbit/roll", "airborne road height",
                                "pause prior velocity"],
        "execution": "Reader of producer evidence; no engine, GL, Android or APK execution by this reader",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--motion", type=Path, required=True)
    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--summary", type=Path, required=True)
    parser.add_argument("--source-revision-file", type=Path)
    parser.add_argument("--expected-source-revision")
    args = parser.parse_args()
    try:
        report = validate(args.project, args.evidence, args.motion, args.log, args.engine,
                          args.source_revision_file, args.expected_source_revision)
        args.summary.parent.mkdir(parents=True, exist_ok=True)
        args.summary.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    except (EvidenceError, OSError, UnicodeError, ValueError, TypeError) as error:
        print(f"[PhysicalFinishCoastReader] FAIL: {error}", file=sys.stderr)
        return 1
    print("[PhysicalFinishCoastReader] PASS: 16 source-bound numerical controls and raw motion")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
