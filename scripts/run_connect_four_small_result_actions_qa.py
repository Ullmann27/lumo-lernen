#!/usr/bin/env python3
"""Separate source-bound QA for two scrolled 640x360 winning-dialog actions.

This runs only the explicit Godot/Dart overlay after approval. It uses the
unchanged production controller, real rendered input, a local file transport
and test preferences. It does not build an APK or run the native 52-mode suite.
"""
from __future__ import annotations

import argparse
from contextlib import ExitStack
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


HOST = "aab09275ec6b5808de9be539ca4e1a7e70921249"
HOST_TREE = "baaa84b40b09e61d144f158e5b35a1c4dc5d2ef0"
NATIVE = "e2d15dbc5f3709306decb139eeb70a1cf30c0b73"
NATIVE_TREE = "ea0f73ae6aad8792a963cadaa483c290a2f2a62e"
BASE_RUNNER = "scripts/run_connect_four_runtime.py"
BASE_RUNNER_BLOB = "36d93ed0908705e339346bf5ef451cf047b641b5"
BASE_PROBE = "scripts/tests/connect_four_runtime_regression.gd"
BASE_PROBE_BLOB = "94c32597c0170c5c3199e39ca6fbfcc1caf25f99"
DART_OVERLAY = "test/games/connect_four_small_result_actions_qa.dart"
GD_OVERLAY = "tools/qa/connect_four_small_result_actions_qa.gd"
GD_DESTINATION = "scripts/tests/connect_four_small_result_actions_qa.gd"
QA_PATHS = (
    ".github/workflows/lumo-c4-small-result-actions-qa.yml",
    "scripts/run_connect_four_small_result_actions_qa.py",
    DART_OVERLAY, GD_OVERLAY,
)
UID_ALPHABET = "abcdefghijklmnopqrstuvwxy012345678"


def require(value: bool, message: str) -> None:
    if not value:
        raise ValueError(message)


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(root), *args], text=True, stderr=subprocess.STDOUT
    ).strip()


def identity(path: Path) -> dict:
    require(path.is_file() and not path.is_symlink(), f"Nonregular evidence/source: {path}")
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
            "git_blob": hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()}


def require_clean(root: Path, revision: str, tree: str) -> None:
    require(git(root, "rev-parse", "HEAD") == revision, f"Wrong exact HEAD: {root}")
    require(git(root, "rev-parse", "HEAD^{tree}") == tree, f"Wrong exact tree: {root}")
    for args in (("diff", "--quiet", "HEAD", "--"),
                 ("diff", "--cached", "--quiet", "HEAD", "--")):
        subprocess.run(["git", "-C", str(root), *args], check=True)


def load_helper(host: Path):
    require_clean(host, HOST, HOST_TREE)
    require(identity(host / BASE_RUNNER)["git_blob"] == BASE_RUNNER_BLOB,
            "The reused production runner differs from its reviewed blob")
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("lumo_frozen_c4_runtime", host / BASE_RUNNER)
    require(spec is not None and spec.loader is not None, "Cannot load exact runner helpers")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def native_untracked_metadata(native: Path, paths: tuple[str, ...], allowed: set[str]) -> list[dict]:
    """Bind generated Godot 4.6.3 UID sidecars to exact tracked source blobs.

    ResourceUID::id_to_text uses this 34-character alphabet and at most 63 bits:
    godotengine/godot@4.6.3-stable core/io/resource_uid.cpp, blob 4a03a4b8.
    UID files are data, not permission to introduce untracked executable input.
    """
    extra = set(filter(None, git(native, "ls-files", "--others", "--exclude-standard",
                                 "-z", "--", *paths).split("\0")))
    metadata = []
    for relative in sorted(extra - allowed):
        require(relative.endswith((".gd.uid", ".gdshader.uid")),
                "Unexpected untracked executable/input source: " + relative)
        source = relative[:-4]
        tree_entry = git(native, "ls-tree", "-z", "HEAD", "--", source).split("\0")
        require(len(tree_entry) == 2 and tree_entry[1] == "",
                "Generated UID lacks one exact tracked source: " + relative)
        entry, entry_path = tree_entry[0].split("\t", 1)
        mode, kind, expected_blob = entry.split()
        require(entry_path == source and kind == "blob" and mode in ("100644", "100755"),
                "Generated UID counterpart is not a tracked regular source: " + relative)
        source_identity = identity(native / source)
        require(source_identity["git_blob"] == expected_blob,
                "Generated UID counterpart differs from its committed blob: " + source)
        uid_identity = identity(native / relative)
        raw = (native / relative).read_bytes()
        require(re.fullmatch(rb"uid://[a-y0-8]{1,13}\n", raw) is not None,
                "Malformed Godot-generated UID sidecar: " + relative)
        digits = raw[6:-1].decode("ascii")
        value = 0
        for digit in digits:
            value = value * len(UID_ALPHABET) + UID_ALPHABET.index(digit)
        require(value <= 0x7FFFFFFFFFFFFFFF and (len(digits) == 1 or digits[0] != "a"),
                "Noncanonical/out-of-range Godot UID: " + relative)
        metadata.append({"path": relative, "source": source,
                         "source_git_blob": expected_blob, "uid": raw[:-1].decode("ascii"),
                         **uid_identity})
    return metadata


def require_unchanged_sources(before: dict, after: dict) -> None:
    require(before == after, "Source/QA-overlay/UID metadata identity changed during execution")


def audit_sources(qa: Path, host: Path, native: Path, helper, overlays: bool) -> dict:
    require_clean(host, HOST, HOST_TREE)
    require_clean(native, NATIVE, NATIVE_TREE)
    qa_head = git(qa, "rev-parse", "HEAD")
    qa_tree = git(qa, "rev-parse", "HEAD^{tree}")
    require_clean(qa, qa_head, qa_tree)
    require(git(qa, "show", "-s", "--format=%P", "HEAD") == HOST,
            "QA must be one dedicated child commit of the immutable host")
    changed = git(qa, "diff", "--no-renames", "--name-status", HOST, "HEAD").splitlines()
    require(sorted(changed) == sorted("A\t" + path for path in QA_PATHS),
            "QA commit must add exactly the four reviewed QA files")
    config = helper.read_json(host / "config/godot-source.json")
    require(config == {"repository": "https://github.com/Ullmann27/lumo-godot.git",
                       "revision": NATIVE, "engine": "4.6.3"}, "Frozen native pin changed")
    require(identity(native / BASE_PROBE)["git_blob"] == BASE_PROBE_BLOB,
            "The inherited actual input helper differs from its reviewed blob")
    native_metadata = native_untracked_metadata(
        native, helper.NATIVE_PATHS, {GD_DESTINATION} if overlays else set())
    for root, paths, allowed in (
        (host, helper.HOST_PATHS + (DART_OVERLAY,), {DART_OVERLAY} if overlays else set()),
        (qa, QA_PATHS, set()),
    ):
        extra = set(filter(None, git(root, "ls-files", "--others", "--exclude-standard", "--", *paths).splitlines()))
        require(extra <= allowed, f"Unexpected untracked executable/input source: {sorted(extra - allowed)}")
    result = {"host": helper.source_snapshot(host, helper.HOST_PATHS),
              "native": helper.source_snapshot(native, helper.NATIVE_PATHS),
              "qa": helper.source_snapshot(qa, QA_PATHS),
              "trees": {"host": HOST_TREE, "native": NATIVE_TREE, "qa": qa_tree},
              "generated_native_uid_metadata": native_metadata}
    if overlays:
        result["overlays"] = []
        for source, target in ((qa / DART_OVERLAY, host / DART_OVERLAY),
                               (qa / GD_OVERLAY, native / GD_DESTINATION)):
            require(identity(source) == identity(target), f"Overlay bytes changed: {target}")
            result["overlays"].append({"source": str(source.relative_to(qa)),
                                       "destination": str(target.relative_to(host if source.name.endswith('.dart') else native)),
                                       **identity(target)})
    return result


def install_overlay(source: Path, destination: Path) -> None:
    require(not destination.exists() and not destination.is_symlink(),
            f"Refusing to overwrite an existing overlay: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("xb") as stream:
        stream.write(source.read_bytes())


def box(value: object) -> list[float]:
    require(isinstance(value, list) and len(value) == 4, "Malformed observed rectangle")
    require(all(isinstance(v, (int, float)) and not isinstance(v, bool)
                and math.isfinite(v) for v in value), "Nonfinite observed rectangle")
    require(value[2] > 0 and value[3] > 0, "Empty observed rectangle")
    return value


def enclosed(inner: list[float], outer: list[float]) -> bool:
    return (inner[0] >= outer[0] - 0.1 and inner[1] >= outer[1] - 0.1
            and inner[0] + inner[2] <= outer[0] + outer[2] + 0.1
            and inner[1] + inner[3] <= outer[1] + outer[3] + 0.1)


def validate_results(output: Path, helper, session: dict) -> dict:
    dart = helper.read_json(output / "dart-result.json")
    native = helper.read_json(output / "native-result.json")
    done = helper.read_json(output / "done.json")
    require(all(report.get("passed") is True for report in (dart, native, done))
            and done.get("finished") is True, "Original Dart/native/completion results disagree")
    require(dart.get("verified_actions") == ["restart", "mode"] and dart.get("stars") == 10
            and dart.get("xp") == 80 and dart.get("reopened_same_round") is True,
            "Production-controller action/reward assertions are missing")
    require(native.get("errors") == [] and type(native.get("checks")) is int
            and native["checks"] > 0 and native.get("viewport_px") == [640, 360]
            and native.get("density") == 1.0 and native.get("return_acknowledged") is True,
            "Original small-viewport observations failed")
    require(native.get("helper_source") == {"path": BASE_PROBE, "blob": BASE_PROBE_BLOB},
            "Input helper provenance is missing")
    require(native.get("submitted_requests") == dart.get("received_requests"),
            "Native submissions and actual Dart requests disagree")
    final = native.get("final_state", {})
    require(final.get("token") == session["token"] and final.get("owner") == session["owner"]
            and final.get("exit") is True and final.get("columns") == []
            and final.get("twoPlayers") is False, "Final acknowledged solo/exit state disagrees")
    actions = native.get("actions", [])
    require([entry.get("action") for entry in actions] == ["restart", "mode"],
            "Exactly the two intended result-dialog actions are required")
    inputs = native.get("inputs")
    require(isinstance(inputs, list) and inputs, "Original input evidence is missing")
    required_pngs = set()
    layouts = []
    for entry in actions:
        action = entry["action"]
        prefix = "small_result_" + action
        for moment in ("before", "after"):
            image_name = prefix + "_" + moment + ".png"
            layout_name = prefix + "_" + moment + ".layout.json"
            require(entry.get(moment + "_capture") == image_name
                    and entry.get(moment + "_layout") == layout_name, "Unexpected capture path")
            required_pngs.add(image_name)
            layout = helper.read_json(output / layout_name)
            state = entry[moment + "_state"]
            require(layout.get("settled") is True and layout.get("pending") == 0
                    and layout.get("window_px") == [640, 360]
                    and layout.get("viewport_px") == [640, 360]
                    and layout.get("safe_rect") == [0, 24, 640, 312]
                    and layout.get("density") == 1.0, "Capture geometry is not the intended settled viewport")
            for key in ("token", "owner", "roundId", "revision", "ack", "phase", "paused",
                        "twoPlayers", "rewarded", "columns"):
                require(layout.get(key) == state.get(key), f"Capture/state mismatch: {layout_name}:{key}")
            layouts.append({"path": layout_name, **identity(output / layout_name)})
            if moment == "before":
                targets = [target for target in layout.get("buttons", []) if target.get("id") == action]
                require(len(targets) == 1, "Captured result action is absent or ambiguous")
                target = targets[0]
                require(target.get("visible") is True and target.get("enabled") is True
                        and target.get("clipped") is False, "Touched action is not fully exposed")
                rect = box(target.get("rect_px"))
                hit = box(target.get("hit_rect_px"))
                require(all(abs(a - b) < 0.1 for a, b in zip(rect, hit))
                        and rect[2] >= 48 and rect[3] >= 48
                        and enclosed(rect, box(layout["safe_rect"])), "Incomplete or undersized target")
                expected = {**target, "size_dp": [rect[2], rect[3]]}
                require(entry.get("target") == expected, "Action target differs from its original layout")
                require(target.get("text") == ("Neue Runde" if action == "restart" else "Gegen Lumo spielen"),
                        "Wrong result action label")
        scroll = entry.get("scroll_evidence", {})
        start, end = scroll.get("input_start_inclusive"), scroll.get("input_end_exclusive")
        require(type(start) is int and type(end) is int and 0 <= start < end <= len(inputs),
                "Missing bounded original scroll input range")
        drags = [event for event in inputs[start:end] if event.get("drag") is True]
        require(drags and len(drags) == scroll.get("drag_events")
                and scroll.get("scroll_before") != scroll.get("scroll_after")
                and all(event.get("snapshot_revision") == entry["before_state"]["revision"] for event in drags),
                "Target was not revealed by acknowledged-state-preserving drag input")
        taps = [event for event in inputs if event.get("label") == action + " exposed result action"]
        require([tap.get("pressed") for tap in taps] == [True, False], "Actual target press/release missing")
        rect = entry["target"]["rect_px"]
        for tap in taps:
            point = tap.get("screen_px")
            require(isinstance(point, list) and len(point) == 2
                    and all(isinstance(v, (int, float)) and not isinstance(v, bool)
                            and math.isfinite(v) for v in point)
                    and abs(point[0] - (rect[0] + rect[2] / 2)) < 0.1
                    and abs(point[1] - (rect[1] + rect[3] / 2)) < 0.1,
                    "Input point differs from the captured target center")
    require({p.name for p in output.glob("*.png")} == required_pngs, "Expected exactly four original captures")
    from PIL import Image
    images = []
    for name in sorted(required_pngs):
        path = output / name
        with Image.open(path) as picture:
            require(picture.format == "PNG" and picture.size == (640, 360), "Unexpected original PNG dimensions")
            picture.load()
        images.append({"path": name, "width": 640, "height": 360, **identity(path)})
    return {"verified_actions": ["restart", "mode"], "native_checks": native["checks"],
            "images": images, "layouts": layouts, "input_events": len(inputs),
            "android_or_measured_fps_claim": False}


def run(qa: Path, host: Path, native: Path, output: Path, preflight: bool) -> int:
    qa, host, native, output = (path.resolve() for path in (qa, host, native, output))
    roots = (qa, host, native)
    require(all(a != b and a not in b.parents and b not in a.parents
                for index, a in enumerate(roots) for b in roots[index + 1:]),
            "Use three separate, nonnested fresh source checkouts")
    require(all(output != root and root not in output.parents and output not in root.parents for root in roots),
            "Evidence must be outside all source checkouts")
    output.mkdir(parents=True, exist_ok=False)
    report = {"schema": 1, "passed": False, "preflight_only": preflight,
              "started_utc": datetime.now(timezone.utc).isoformat(),
              "scope": "two real scrolled desktop result actions; local file transport and test preferences; no Android/FPS claim"}
    helper = dart = renderer = before = None
    try:
        helper = load_helper(host)
        pristine = audit_sources(qa, host, native, helper, False)
        helper.write_json(output / "source-pristine.json", pristine)
        if preflight:
            report["passed"] = True
        else:
            for executable in ("flutter", "godot", "xvfb-run"):
                require(shutil.which(executable) is not None, "Missing executable: " + executable)
            version = subprocess.check_output(["godot", "--version"], text=True, timeout=15).strip()
            require(version.startswith("4.6.3."), "Unexpected actual Godot version")
            report["godot_version"] = version
            install_overlay(qa / DART_OVERLAY, host / DART_OVERLAY)
            install_overlay(qa / GD_OVERLAY, native / GD_DESTINATION)
            before = audit_sources(qa, host, native, helper, True)
            helper.write_json(output / "source-before.json", before)
            env = os.environ.copy()
            env.update({"LUMO_C4_RUNTIME_DIR": str(output), "LIBGL_ALWAYS_SOFTWARE": "1",
                        "XDG_DATA_HOME": str(output / "user-data"),
                        "XDG_CONFIG_HOME": str(output / "user-config"),
                        "XDG_CACHE_HOME": str(output / "user-cache")})
            dart_command = ["flutter", "test", "--no-pub", "--reporter=expanded", DART_OVERLAY]
            native_command = ["xvfb-run", "-a", "-s", "-screen 0 960x540x24 -nolisten tcp",
                              "godot", "--path", str(native), "--fixed-fps", "24",
                              "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
                              "--resolution", "640x360", "--script", "res://" + GD_DESTINATION,
                              "--", "--capture"]
            report["commands"] = {"dart": dart_command, "godot": native_command}
            report["fixed_fps_argument_is_not_a_measurement"] = True
            with ExitStack() as stack:
                dart_log = stack.enter_context((output / "original-dart.log").open("xb"))
                native_log = stack.enter_context((output / "original-godot.log").open("xb"))
                dart = subprocess.Popen(dart_command, cwd=host, env=env, stdout=dart_log,
                                        stderr=subprocess.STDOUT, start_new_session=True)
                report["session"] = helper.wait_for_session(output / "session.json", dart, 120)
                renderer = subprocess.Popen(native_command, cwd=native, env=env, stdout=native_log,
                                            stderr=subprocess.STDOUT, start_new_session=True)
                helper.wait_for_pair(dart, renderer, 600)
            report["original_godot_log"] = helper.validate_native_log(output / "original-godot.log")
            report["results"] = validate_results(output, helper, report["session"])
            report["passed"] = True
    except Exception as error:
        report["error"] = f"{type(error).__name__}: {error}"
    finally:
        if helper is not None:
            helper.stop_owned_process(renderer)
            helper.stop_owned_process(dart)
            if before is not None:
                try:
                    after = audit_sources(qa, host, native, helper, True)
                    helper.write_json(output / "source-after.json", after)
                    require_unchanged_sources(before, after)
                except Exception as error:
                    report["passed"] = False
                    report["source_after_error"] = f"{type(error).__name__}: {error}"
        report["exit_codes"] = {"dart": None if dart is None else dart.poll(),
                                "godot": None if renderer is None else renderer.poll()}
        report["completed_utc"] = datetime.now(timezone.utc).isoformat()
        (output / "small-result-actions-gate.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": report["passed"], "preflight_only": preflight,
                      "output": str(output), "error": report.get("error"),
                      "source_after_error": report.get("source_after_error")}))
    return 0 if report["passed"] else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qa", type=Path, required=True)
    parser.add_argument("--host", type=Path, required=True)
    parser.add_argument("--native", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--preflight", action="store_true")
    args = parser.parse_args()
    return run(args.qa, args.host, args.native, args.output, args.preflight)


if __name__ == "__main__":
    raise SystemExit(main())
