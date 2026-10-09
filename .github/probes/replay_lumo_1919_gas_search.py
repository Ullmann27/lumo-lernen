#!/usr/bin/env python3
"""Replay the recorded API36 initial Gas-caption search without Android.

This is a harness regression test, never an application/gameplay PASS.

Inputs:
  --source    Exact kart_complete_android_probe.py being tested.
  --fixtures  Unmodified files extracted from pinned artifact 11641916981.
  --manifest  JSON {"files": {"relative/path": "sha256", ...}}.
  --out       Optional JSON report file.

The calling workflow owns the original ZIP artifact-ID/digest gate.
This script verifies every consumed fixture against the supplied manifest,
checks the original failure's app/Godot/APK identity, and executes the real
AST-extracted reader functions.

No target caption, touch, saved state, reward, or race completion is invented.
"""
from __future__ import annotations

import argparse
import ast
import copy
import hashlib
import json
import math
from pathlib import Path, PurePosixPath
import re
import sys
import tempfile
from types import SimpleNamespace
import unicodedata

from PIL import Image


APP_SOURCE = "d07b2b48593b939a2a0446fcb83a25a2b2a59db6"
GODOT_SOURCE = "d140e5b05cb5afacfe675559b78da4254cb1daed"
APK_SHA256 = "8e2ea31fed333fd8e89becd073b100c53ce9449017badb43ab4bc28022cc51aa"
APK_BYTES = 205316096
ARTIFACT_ID = 11641916981

GAS = "Gas: GAS-Taste halten"
PREFIX = "enable-public-auto-gas"
ORIGINAL_ERROR = "Screenshot tile OCR deadline exceeded"
EXPECTED_RED = "Recorded list end received another downward search"
PASS_MARKER = (
    "[GasScrollReplay] PASS: recorded API36 Gas search and unchanged other scopes"
)

# Original job-log capture offsets, relative to enable-public-auto-gas-0.
# Reused as a deterministic reader clock, not as a performance measurement.
CAPTURE_OFFSETS = (
    0.0,
    18.1824873,
    34.7551051,
    53.3274616,
    68.8654236,
    87.3569585,
    107.4221952,
    131.6341802,
    151.0795200,
)


class FixtureError(RuntimeError):
    """Bad/missing fixture or dependency; never an acceptable baseline RED."""


class EndOfRecordedFrames(Exception):
    """Deliberately end a reader-only replay without claiming target success."""


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class Fixtures:
    def __init__(self, root: Path, manifest_path: Path):
        self.root = root.resolve()
        self.manifest_path = manifest_path.resolve()
        raw_bytes = self.manifest_path.read_bytes()
        raw = json.loads(raw_bytes)
        files = raw.get("files") if isinstance(raw, dict) else None
        if not isinstance(files, dict) or not files:
            raise FixtureError("Manifest must contain a nonempty files dictionary")

        self.entries = {}
        self.used = {}
        self.cache = {}
        self.manifest_sha256 = sha256(raw_bytes)
        self.metadata = {key: value for key, value in raw.items() if key != "files"}

        for name, digest in files.items():
            if not isinstance(name, str) or not isinstance(digest, str):
                raise FixtureError("Manifest file names and digests must be strings")
            parts = name.split("/")
            if (
                "\\" in name
                or PurePosixPath(name).is_absolute()
                or any(part in ("", ".", "..") for part in parts)
                or not re.fullmatch(r"[0-9a-f]{64}", digest)
            ):
                raise FixtureError("Invalid manifest entry: " + repr(name))
            path = self.root.joinpath(*parts).resolve()
            if not path.is_relative_to(self.root):
                raise FixtureError("Manifest path escapes fixture directory")
            self.entries[name] = (path, digest)

    def locate(self, filename: str, *, prefer_full_race=False) -> str:
        candidates = [
            name for name in self.entries
            if name == filename or name.endswith("/" + filename)
        ]
        if prefer_full_race:
            preferred = [
                name for name in candidates
                if name == "full-race/" + filename
                or name.endswith("/full-race/" + filename)
            ]
            if preferred:
                candidates = preferred
        if len(candidates) != 1:
            raise FixtureError(
                f"Expected one manifest entry for {filename}; got {candidates}"
            )
        return candidates[0]

    def read(self, filename: str, *, prefer_full_race=False) -> bytes:
        name = self.locate(filename, prefer_full_race=prefer_full_race)
        if name not in self.cache:
            path, expected = self.entries[name]
            data = path.read_bytes()
            actual = sha256(data)
            if actual != expected:
                raise FixtureError("Fixture SHA256 mismatch: " + name)
            self.cache[name] = data
            self.used[name] = {"sha256": actual, "bytes": len(data)}
        return self.cache[name]

    def read_json(self, filename: str, *, prefer_full_race=False):
        return json.loads(self.read(
            filename, prefer_full_race=prefer_full_race
        ))

    def path(self, filename: str) -> Path:
        name = self.locate(filename)
        self.read(filename)
        return self.entries[name][0]

    def archive_receipt(self):
        for parent in (self.manifest_path.parent, self.root):
            path = parent / "archive.sha256"
            if path.is_file():
                value = path.read_text().strip()
                first = value.split()[0] if value else ""
                if not re.fullmatch(r"[0-9a-f]{64}", first):
                    raise FixtureError("Invalid archive.sha256 receipt")
                return {
                    "sha256": first,
                    "receipt": str(path),
                    "verification_owner": "calling workflow",
                }
        return {
            "metadata": self.metadata,
            "verification_owner": "calling workflow",
            "note": "Original ZIP is not re-downloaded or rehashed by this replay.",
        }


def select_functions(tree, names):
    found = {}
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name in names:
                if node.name in found:
                    raise FixtureError("Duplicate function: " + node.name)
                found[node.name] = copy.deepcopy(node)
    missing = set(names) - set(found)
    if missing:
        raise FixtureError("Required real functions missing: " + repr(sorted(missing)))
    return [found[name] for name in names]


def load_real_nodes(source: Path, repo_root: Path):
    creative_path = repo_root / ".github/probes/creative_android_probe.py"
    surface_path = repo_root / "tools/android_qa/native_surface_readiness.py"

    paths = {
        "tested_probe": source,
        "creative_reader": creative_path,
        "surface_reader": surface_path,
    }
    contents = {name: path.read_bytes() for name, path in paths.items()}
    trees = {
        name: ast.parse(data.decode("utf-8"), filename=str(paths[name]))
        for name, data in contents.items()
    }

    top_level = trees["tested_probe"]
    mains = [
        node for node in top_level.body
        if isinstance(node, ast.FunctionDef) and node.name == "main"
    ]
    if len(mains) != 1:
        raise FixtureError("Expected the real probe main()")
    nested = ast.Module(body=mains[0].body, type_ignores=[])

    nodes = []
    nodes += select_functions(
        trees["surface_reader"], ["inspect_surface", "target_observation"]
    )
    nodes += select_functions(
        trees["creative_reader"],
        ["digest", "normalized", "native_tap", "native_text"],
    )
    nodes += select_functions(
        top_level, ["scroll_observation", "stable_scroll_observation"]
    )
    nodes += select_functions(nested, ["write_json", "tap_native"])

    code = compile(
        ast.fix_missing_locations(ast.Module(body=nodes, type_ignores=[])),
        "<real-lumo-gas-replay-functions>",
        "exec",
    )
    provenance = {
        name: {"path": str(paths[name]), "sha256": sha256(data)}
        for name, data in contents.items()
    }
    return code, provenance


def base_namespace():
    return {
        "__name__": "lumo_recorded_gas_replay",
        "hashlib": hashlib,
        "json": json,
        "math": math,
        "Path": Path,
        "re": re,
        "unicodedata": unicodedata,
        "Image": Image,
    }


def validate_original_failure(fixtures: Fixtures, code):
    result = fixtures.read_json("result.json", prefer_full_race=True)
    expected = {
        "status": "FAIL",
        "source": APP_SOURCE,
        "godot": GODOT_SOURCE,
        "harness": APP_SOURCE,
        "apk_sha256": APK_SHA256,
        "android_sdk": 36,
        "error": ORIGINAL_ERROR,
    }
    for key, value in expected.items():
        if result.get(key) != value:
            raise FixtureError(f"Wrong original result identity: {key}")

    installed = result.get("installed_apk", {})
    if (
        installed.get("sha256") != APK_SHA256
        or installed.get("bytes") != APK_BYTES
        or installed.get("matches_candidate") is not True
    ):
        raise FixtureError("Wrong installed-APK identity in original result")

    trace = result.get("traceback", "")
    if "native_ocr_tiles.py" not in trace or "line 127" not in trace:
        raise FixtureError("Original result does not contain the recorded OCR failure")

    ns = base_namespace()
    exec(code, ns)
    records = []
    for index in range(6):
        png_name = f"{PREFIX}-{index}.png"
        png = fixtures.read(png_name)
        rows = fixtures.read_json(f"{PREFIX}-{index}-ocr.json")
        if not isinstance(rows, list):
            raise FixtureError("Original OCR result must be a list")
        if any(
            ns["normalized"](row["text"]) == ns["normalized"](GAS)
            for row in rows
        ):
            raise FixtureError("Failure fixture unexpectedly contains exact Gas target")

        surface = ns["inspect_surface"](fixtures.path(png_name))
        if surface["source_sha256"] != sha256(png):
            raise FixtureError("Real inspect_surface disagrees with original PNG hash")
        if surface["acceptable_for_target_sampling"] is not True:
            raise FixtureError("Recorded Gas frame is not a complete native surface")
        records.append({"png": png, "rows": rows, "surface": surface})

    observations = {}
    for index in range(1, 6):
        data = fixtures.read_json(f"{PREFIX}-{index}-observed-scroll.json")
        if data.get("observed_captions") != records[index]["rows"]:
            raise FixtureError("OCR and original scroll observation disagree")
        if data["current"]["frame"] != records[index]["surface"]:
            raise FixtureError("Original surface observation disagrees with real inspector")
        observed = ns["scroll_observation"](records[index]["rows"], "down", "pause")
        for key in ("gesture", "content_bounds", "footer_bounds", "selected_captions"):
            if observed[key] != data["current"]["observation"][key]:
                raise FixtureError("Original scroll geometry disagrees: " + key)
        observations[index] = data

    if observations[2]["status"] != "SWIPE_SENT":
        raise FixtureError("Missing original first downward swipe")
    if observations[5]["status"] != "SWIPE_SENT":
        raise FixtureError("Missing original repeated bottom swipe")

    return records, observations, {
        **expected,
        "installed_apk": installed,
        "artifact_id": ARTIFACT_ID,
        "archive_gate": fixtures.archive_receipt(),
    }


def run_case(code, records, sequence, *, label=GAS, direction="down", context="pause"):
    """Replay real PNG/OCR bytes. Only capture/OCR/ADB/time are adapted."""
    state = SimpleNamespace(ordinal=-1, clock=0.0)
    swipes = []
    capture_budgets = []
    stopped = None

    with tempfile.TemporaryDirectory(prefix="lumo-gas-reader-replay-") as temporary:
        out = Path(temporary)

        def monotonic():
            return state.clock

        def sleep(seconds):
            state.clock += seconds

        def capture(destination, tag, timeout):
            check(destination == out, "Capture output directory changed")
            check(0 < timeout <= 180, "Existing 180-second action deadline changed")
            state.ordinal += 1
            if state.ordinal >= len(sequence):
                raise EndOfRecordedFrames
            check(
                tag == f"{PREFIX}-{state.ordinal}",
                "Replay entered an unrecorded final-target action",
            )
            capture_budgets.append(timeout)
            state.clock = max(
                state.clock, CAPTURE_OFFSETS[state.ordinal]
            )
            record = records[sequence[state.ordinal]]
            filename = tag + ".png"
            # Verbatim byte copy of an authenticated original PNG.
            (out / filename).write_bytes(record["png"])
            return {"file": filename}

        def image_lines(destination, tag, wanted="", source_path=None,
                        timeout=225, exact=False):
            check(destination == out, "OCR output directory changed")
            check(exact is True, "Exact-caption search was weakened")
            check(
                tag == f"{PREFIX}-{state.ordinal}",
                "Replay requested an unrecorded OCR frame",
            )
            check(
                source_path == out / (tag + ".png"),
                "OCR is not bound to the current replay capture",
            )
            check(timeout > 0, "OCR was invoked after its deadline")
            return copy.deepcopy(records[sequence[state.ordinal]]["rows"])

        def adb(*arguments, **kwargs):
            check(
                len(arguments) == 8
                and arguments[:3] == ("shell", "input", "swipe"),
                "Replay attempted an operation other than a recorded-search swipe",
            )
            gesture = list(map(int, arguments[3:7]))
            check(
                gesture[0] == gesture[2] and gesture[1] != gesture[3],
                "Replay attempted a target tap or a nonvertical gesture",
            )
            check(
                0 < kwargs.get("timeout", 0) <= 10,
                "Existing ADB gesture deadline changed",
            )
            swipes.append({
                "frame": state.ordinal,
                "fixture_frame": sequence[state.ordinal],
                "gesture": gesture,
                "duration_ms": int(arguments[7]),
            })
            return ""

        ns = base_namespace()
        ns.update({
            "out": out,
            "time": SimpleNamespace(monotonic=monotonic, sleep=sleep),
            "base": SimpleNamespace(adb=adb),
            "capture": capture,
            "image_lines": image_lines,
        })
        exec(code, ns)
        ns["creative"] = SimpleNamespace(**{
            name: ns[name] for name in (
                "normalized", "digest", "inspect_surface",
                "native_tap", "native_text", "capture", "image_lines",
            )
        })

        for original_index in sequence:
            check(
                not any(
                    ns["normalized"](row["text"]) == ns["normalized"](label)
                    for row in records[original_index]["rows"]
                ),
                "Scope replay would require an actual target action",
            )

        try:
            ns["tap_native"](
                label, PREFIX, scroll=direction, context=context
            )
        except EndOfRecordedFrames:
            stopped = "END_OF_RECORDED_FRAMES"
        except RuntimeError as error:
            stopped = str(error)
        else:
            raise AssertionError("Replay claimed success without an observed target")

        journal = {}
        for path in sorted(out.glob(PREFIX + "-*-observed-scroll.json")):
            index = int(path.name[len(PREFIX) + 1:].split("-", 1)[0])
            journal[index] = json.loads(path.read_text())

        check(capture_budgets, "Probe did not request a real replay frame")
        check(capture_budgets[0] == 180, "Initial action deadline is no longer 180 seconds")

        for swipe in swipes:
            index = swipe["frame"]
            entry = journal[index]
            current = entry["current"]
            previous = entry["previous"]
            check(entry["status"] == "SWIPE_SENT", "Missing actual swipe evidence")
            check(current["stable"] is True, "Swipe bypassed two-frame stability")
            check(previous is not None, "Swipe lacks its preceding modal frame")
            check(
                current["frame"]["source"] == f"{PREFIX}-{index}.png"
                and previous["frame"]["source"] == f"{PREFIX}-{index - 1}.png",
                "Swipe did not use two consecutive replay captures",
            )
            check(
                current["frame"]["source_sha256"]
                == sha256(records[sequence[index]]["png"])
                and previous["frame"]["source_sha256"]
                == sha256(records[sequence[index - 1]]["png"]),
                "Swipe evidence is not bound to the original PNG bytes",
            )
            x0, y0, x1, y1 = current["observation"]["content_bounds"]
            a, b, c, d = swipe["gesture"]
            check(
                x0 <= a <= x1 and x0 <= c <= x1
                and y0 <= b <= y1 and y0 <= d <= y1,
                "Swipe left the currently observed modal geometry",
            )
            check(
                entry["direction"] == ("up" if d > b else "down"),
                "Evidence does not report the actual swipe direction",
            )

        return {
            "label": label,
            "requested_direction": direction,
            "context": context,
            "fixture_sequence": sequence,
            "stop": stopped,
            "swipes": swipes,
            "reader_clock_seconds": state.clock,
            "application_or_target_success": False,
        }


def span(gesture):
    return abs(gesture[3] - gesture[1])


def run_checks(code, records, original, report):
    # Original chronological failure prefix: no image or OCR value is invented.
    primary = run_case(code, records, list(range(6)))
    primary["scope"] = "Original recorded frames 0–5 in their original order"
    report["cases"].append(primary)
    check(primary["stop"] == "END_OF_RECORDED_FRAMES", "Primary replay ended unexpectedly")
    check([item["frame"] for item in primary["swipes"]] == [2, 5],
          "Recorded modal frames no longer produce the expected two gated swipes")
    first, recovery = primary["swipes"]

    # Keep this the first behavioral assertion: original d07 gives the expected RED.
    check(recovery["gesture"][3] > recovery["gesture"][1], EXPECTED_RED)
    check(span(first["gesture"]) <= span(original[2]["gesture"]) // 2,
          "Initial Gas drag does not retain the required geometric overlap")
    check(span(recovery["gesture"]) <= span(original[5]["gesture"]) // 2,
          "Recovery Gas drag does not retain the required geometric overlap")
    check(first["duration_ms"] == recovery["duration_ms"] == 900,
          "Gas overlap drags are not using the bounded slower 900ms gesture")

    # Policy scenario composed ONLY from real original images/OCR.
    # Original top views 0/1 follow the bottom recovery. This is deliberately
    # not described as the original Android timeline or a recovered target.
    latched = run_case(code, records, [0, 1, 2, 3, 4, 5, 0, 1])
    latched["scope"] = (
        "Composed real-frame policy replay: after bottom recovery, "
        "two real views without the end captions; no runtime recovery claim"
    )
    report["cases"].append(latched)
    check(latched["stop"] == "END_OF_RECORDED_FRAMES", "Latch replay ended unexpectedly")
    check([item["frame"] for item in latched["swipes"]] == [2, 5, 7],
          "Latch replay lost the consecutive-frame gesture gate")
    check(
        latched["swipes"][-1]["gesture"][3] > latched["swipes"][-1]["gesture"][1],
        "Latched Gas recovery reverted downward when the end captions disappeared",
    )

    # A different, absent caption must preserve the legacy search behavior.
    other_caption = run_case(
        code, records, list(range(6)), label="Gas: automatisch"
    )
    other_caption["scope"] = "Different caption retains original pause/down gestures"
    report["cases"].append(other_caption)
    check(other_caption["stop"] == "END_OF_RECORDED_FRAMES",
          "Other-caption replay ended unexpectedly")
    check([item["gesture"] for item in other_caption["swipes"]]
          == [original[2]["gesture"], original[5]["gesture"]],
          "The initial Gas fix changed another caption's gestures")
    check(all(item["duration_ms"] == 450 for item in other_caption["swipes"]),
          "The initial Gas fix changed another caption's duration")

    # Same caption but an originally upward request stays outside the special case.
    other_direction = run_case(
        code, records, [0, 1, 2], direction="up"
    )
    other_direction["scope"] = "Original up request retains legacy gesture and duration"
    report["cases"].append(other_direction)
    check(other_direction["stop"] == "END_OF_RECORDED_FRAMES",
          "Other-direction replay ended unexpectedly")
    check(len(other_direction["swipes"]) == 1,
          "Original up request changed its modal-frame gate")
    original_up = [
        original[2]["gesture"][0], original[2]["gesture"][3],
        original[2]["gesture"][2], original[2]["gesture"][1],
    ]
    check(other_direction["swipes"][0]["gesture"] == original_up
          and other_direction["swipes"][0]["duration_ms"] == 450,
          "Initial Gas fix changed an originally upward request")

    # Real pause screenshots cannot establish a scrolling finished-result menu.
    other_context = run_case(
        code, records, [0, 1], context="finished"
    )
    other_context["scope"] = "Wrong menu context keeps the original geometry rejection"
    report["cases"].append(other_context)
    check(
        other_context["stop"]
        == "Observed modal captions provide too little room to scroll",
        "Finished context no longer preserves the original geometry rejection",
    )
    check(not other_context["swipes"],
          "Wrong-context fixture unexpectedly authorized a swipe")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--fixtures", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()

    report = {
        "status": "RUNNING",
        "scope": "Deterministic reader/harness regression; no Android execution",
        "application_or_gameplay_pass": False,
        "target_caption_injected": False,
        "cases": [],
    }
    fixtures = None
    exit_code = 2
    message = ""

    try:
        if sys.version_info < (3, 11):
            raise FixtureError("Python 3.11 or newer is required by the real digest function")
        repo_root = Path(__file__).resolve().parents[2]
        code, provenance = load_real_nodes(args.source.resolve(), repo_root)
        report["source_files"] = provenance
        fixtures = Fixtures(args.fixtures, args.manifest)
        report["manifest_sha256"] = fixtures.manifest_sha256
        records, original, identity = validate_original_failure(fixtures, code)
        report["original_failure_identity"] = identity
        run_checks(code, records, original, report)
        report["status"] = "PASS"
        exit_code = 0
        message = PASS_MARKER
    except AssertionError as error:
        report.update(status="FAIL", error=str(error))
        exit_code = 1
        message = "[GasScrollReplay] FAIL: " + str(error)
    except Exception as error:
        report.update(
            status="ERROR",
            error=f"{type(error).__name__}: {error}",
        )
        exit_code = 2
        message = "[GasScrollReplay] ERROR: " + report["error"]

    if fixtures is not None:
        report["verified_fixture_files"] = fixtures.used

    if args.out is not None:
        try:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_text(
                json.dumps(report, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
        except Exception as error:
            print(
                f"[GasScrollReplay] ERROR: Could not write report: {error}",
                flush=True,
            )
            return 2

    print(message, flush=True)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
