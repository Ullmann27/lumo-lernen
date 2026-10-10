#!/usr/bin/env python3
"""Five constructed parser cases; no ADB, APK, real PID, video or gameplay execution."""
from __future__ import annotations
import argparse
import ast
import hashlib
import io
import json
import math
from pathlib import Path, PurePosixPath
import re
import zipfile

ERROR = "Recorder lifecycle phases do not match the exact producer branch"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    options = parser.parse_args()
    raw = options.source.read_bytes()
    wanted = {"require", "sha", "safe_name", "member", "verify_recorder_processes"}
    definitions = [node for node in ast.parse(raw).body
                   if isinstance(node, ast.FunctionDef) and node.name in wanted]
    if len(definitions) != len(wanted):
        raise RuntimeError("Parser dependencies were not found exactly once")
    namespace = {"json": json, "re": re, "math": math, "hashlib": hashlib,
                 "PurePosixPath": PurePosixPath}
    exec(compile(ast.Module(body=definitions, type_ignores=[]),
                 "selected-parser-functions-only", "exec"), namespace)
    args = ["/system/bin/screenrecord", "--size", "960x540", "--bit-rate",
            "2000000", "--time-limit", "180",
            "/sdcard/lumo-full-race-" + "a" * 32 + "-000.mp4"]

    def observation(phase, second, **values):
        return dict(segment=0, phase=phase, monotonic_seconds=second, **values)

    def command(phase, second, arguments, stdout=b"", stderr=b"", code=0):
        return observation(
            phase, second, arguments=arguments, returncode=code,
            stdout=stdout.decode("utf-8", errors="replace"),
            stderr=stderr.decode("utf-8", errors="replace"),
            stdout_hex=stdout.hex(), stderr_hex=stderr.hex())

    live = [
        observation("finish-start", 100, client_returncode=None, expected_argv=args),
        command("pidof", 101, ["shell", "pidof", "screenrecord"], b"31415\n"),
        command("cmdline", 102, ["exec-out", "cat", "/proc/31415/cmdline"],
                b"\0".join(arg.encode() for arg in args) + b"\0"),
        observation("owner-confirmed", 103, pid="31415", client_returncode=None),
        command("sigint", 104, ["shell", "kill", "-2", "31415"]),
        observation("client-finished", 105, client_returncode=0),
    ]
    already_finished = [
        observation("finish-start", 100, client_returncode=0, expected_argv=args),
        observation("client-finished", 101, client_returncode=0),
    ]
    absent = [
        observation("finish-start", 100, client_returncode=None, expected_argv=args),
        command("pidof", 101, ["shell", "pidof", "screenrecord"], code=1),
        observation("remote-absent", 102, client_returncode=None),
        observation("client-finished", 103, client_returncode=0),
    ]
    owner_finished = [
        dict(row, client_returncode=0) if row["phase"] == "owner-confirmed" else row
        for row in live if row["phase"] != "sigint"
    ]
    cases = [
        {"name": "complete_live_owner_requires_signal", "expected_accepted": True, "rows": live},
        {"name": "missing_required_sigint", "expected_accepted": False,
         "rows": [row for row in live if row["phase"] != "sigint"]},
        {"name": "client_already_finished", "expected_accepted": True, "rows": already_finished},
        {"name": "clean_remote_absence", "expected_accepted": True, "rows": absent},
        {"name": "owner_finished_before_signal", "expected_accepted": True, "rows": owner_finished},
    ]
    results = []
    for case in cases:
        memory = io.BytesIO()
        with zipfile.ZipFile(memory, "w") as archive:
            archive.writestr("full-race/android-screenrecord-processes.jsonl",
                             "\n".join(json.dumps(row) for row in case["rows"]) + "\n")
        memory.seek(0)
        actual, error, error_type = False, None, None
        try:
            with zipfile.ZipFile(memory) as archive:
                outcome = namespace["verify_recorder_processes"](
                    {"segments": [{"file": "android-race-000.mp4", "exit_code": 0}]},
                    archive)
            actual = outcome["status"] == "PASS"
        except Exception as problem:
            error, error_type = str(problem), type(problem).__name__
        matched = actual == case["expected_accepted"]
        if not case["expected_accepted"]:
            matched = matched and error_type == "RuntimeError" and ERROR in (error or "")
        results.append({"name": case["name"], "expected_accepted": case["expected_accepted"],
                        "actual_accepted": actual, "matches_expected": matched,
                        "error": error, "error_type": error_type})
    failures = [row["name"] for row in results if not row["matches_expected"]]
    report = {
        "schema": "lumo.recorder-process-parser-regression.v1",
        "status": "PASS" if not failures else "FAIL",
        "scope": "constructed in-memory JSONL parser regression; no Android, video or gameplay execution",
        "application_or_gameplay_pass": False,
        "authentic_pid_replay": False,
        "source": {"path": str(options.source.resolve()), "sha256": hashlib.sha256(raw).hexdigest()},
        "test": {"path": str(Path(__file__).resolve()),
                 "sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},
        "fixture_sha256": hashlib.sha256(
            json.dumps(cases, sort_keys=True, separators=(",", ":")).encode()).hexdigest(),
        "cases_run": len(results), "failures": failures, "results": results,
        "constructed_cases": cases,
    }
    options.out.parent.mkdir(parents=True, exist_ok=True)
    options.out.write_text(json.dumps(report, indent=2) + "\n")
    if failures:
        print("[RecorderProtocolRegression] FAIL: " + ", ".join(failures))
        return 1
    print("[RecorderProtocolRegression] PASS: four valid producer branches; missing required SIGINT rejected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

