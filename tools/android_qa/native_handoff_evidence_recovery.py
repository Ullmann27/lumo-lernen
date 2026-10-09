"""Strict source contract for the ten assigned-state handoff lifecycle cases.

The current source binding is a preparation checkpoint. A passing synthetic
unit fixture is not a rendered probe, an Android run, or permission to pin it.
"""
from __future__ import annotations

from pathlib import Path
import re

from native_lap_evidence_recovery import (
    bound_file, equal, evidence_guard, load_evidence, regular_bytes, require, subset,
)

SOURCE_SHA256 = "7247dd551b900194936d60d31e4436d0e2a9dc74fb4c91e2306d94f6d8689c8c"
PROBE_SHA256 = "f82c717207786cf666f66ff33dbbda5992e11b17623f5481ab58750dc263441f"
HELPER_SHA256 = "fb78dcba3a212ef8b540a2b125fe7baabe123d1f85975451ebaddde9a3d96cef"
PROBE_PATH = "res://scripts/tests/kart_race_continuity_regression.gd"
FIXTURE_SCOPE = (
    "Assigned elapsed/checkpoint/distance state; real _finish, return, "
    "natural queue_free and fresh garage; no driven-lap claim"
)
PASS_MARKER = "[KartHandoffLifecycle] PASS: 10 checks, 0 failures"
NAMES = (
    "accepted completed return initially removes the session",
    "accepted return retains one reward and original result ID",
    "natural scene teardown cannot recreate an accepted completed session",
    "fresh garage cannot offer an already handed-off result",
    "failed host return retains a durable completed session after teardown",
    "accepted unfinished paused return retains resumable progress",
    "accepted cup result retains continuation state",
    "new race after handoff can persist its fresh identity",
    "standalone return performs the real SceneRouter transition",
    "standalone accepted route teardown cannot recreate its completed session",
)
STATIC_EXPECTED = (
    False, None, False, False, True, True, True, True,
    "res://scenes/games/game_hub.tscn", False,
)
ENGINE = {
    "major": 4, "minor": 6, "patch": 3, "status": "stable", "build": "official",
    "string": "4.6.3-stable (official)",
    "hash": "7d41c59c457bd5a245092b4e7eb2d833e3b3f8c3", "hex": 263683,
}


@evidence_guard
def validate_handoff_lifecycle(data: dict) -> None:
    require(type(data) is dict and set(data) == {
        "status", "checks", "fixture_scope", "source_sha256", "probe_sha256",
        "probe_path", "helper_sha256", "engine", "display_server",
    }, "actual lifecycle evidence fields")
    equal(data["status"], "PASS", "lifecycle status")
    equal(data["fixture_scope"], FIXTURE_SCOPE, "assigned lifecycle scope")
    equal(data["source_sha256"], SOURCE_SHA256, "lifecycle production source")
    equal(data["probe_sha256"], PROBE_SHA256, "active Continuity probe source")
    equal(data["probe_path"], PROBE_PATH, "active Continuity producer path")
    equal(data["helper_sha256"], HELPER_SHA256, "lifecycle fixture helper source")
    subset(data["engine"], ENGINE, "actual matching official lifecycle engine")
    equal(data["display_server"], "X11", "rendered lifecycle display server")
    checks = data["checks"]
    require(type(checks) is list and len(checks) == 10, "ten ordered lifecycle cases")
    for index, (name, expected) in enumerate(zip(NAMES, STATIC_EXPECTED)):
        check = checks[index]
        require(type(check) is dict and set(check) == {
            "name", "passed", "expected", "actual",
        }, "lifecycle case fields")
        equal(check["name"], name, "ordered lifecycle label")
        equal(check["passed"], True, "lifecycle passed boolean")
        if index == 1:
            value = check["expected"]
            require(type(value) is dict and set(value) == {
                "reward_calls", "returns", "resultId",
            }, "one handoff identity observation")
            equal(value["reward_calls"], 1, "one integer host reward")
            equal(value["returns"], 1, "one integer host return")
            require(type(value["resultId"]) is str and re.fullmatch(
                r"natural-ack-state-fixture-\d+-\d+", value["resultId"]
            ) is not None, "source-generated original result identity")
            equal(check["actual"], value, "actual single handoff preserves original identity")
        else:
            equal(check["expected"], expected, name + " source expectation")
            equal(check["actual"], expected, name + " observation")


@evidence_guard
def summarize_handoff_lifecycle(godot_root: Path, *, lifecycle_directory=None,
                                continuity_log=None) -> dict:
    godot_root = Path(godot_root)
    for relative, expected in (
        ("scripts/games/kart_island.gd", SOURCE_SHA256),
        ("scripts/tests/kart_race_continuity_regression.gd", PROBE_SHA256),
        ("scripts/tests/kart_handoff_lifecycle_fixtures.gd", HELPER_SHA256),
    ):
        bound_file(godot_root / relative, expected)
    directory = (Path(lifecycle_directory) if lifecycle_directory else
                 godot_root / "exports/race-bridge")
    data, digest = load_evidence(directory / "handoff-lifecycle-evidence.json")
    validate_handoff_lifecycle(data)
    log_path = (Path(continuity_log) if continuity_log else godot_root /
                "exports/fold-controls/kart_race_continuity_regression.log")
    try:
        log = regular_bytes(log_path).decode("utf-8")
    except UnicodeDecodeError as error:
        raise ValueError("Invalid lifecycle Continuity log") from error
    require(log.splitlines().count(PASS_MARKER) == 1,
            "exactly one ten-case lifecycle PASS in the active Continuity log")
    require("[KartContinuity] PASS:" in log, "original Continuity PASS retained")
    result_id = data["checks"][1]["actual"]["resultId"]
    require(log.splitlines().count("[LumoHost] reward reported: " + result_id) == 1,
            "exactly one logged reward for the original lifecycle result identity")
    require(not re.search(
        r"SCRIPT ERROR|Parse Error|ERROR:|Assertion failed|\[ProbeRunner\] FAIL|"
        r"\[ProbeRunner\] timeout|\[KartHandoffLifecycle\] FAIL:|"
        r"ObjectDB instances leaked at exit|resources still in use at exit", log),
        "no lifecycle, probe, or exit-resource error")
    return {
        "handoff_lifecycle_checks": len(data["checks"]),
        "handoff_lifecycle_evidence_sha256": digest,
        "handoff_lifecycle_source_sha256": data["source_sha256"],
        "handoff_lifecycle_probe_sha256": data["probe_sha256"],
        "handoff_lifecycle_helper_sha256": data["helper_sha256"],
    }
