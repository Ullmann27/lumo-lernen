#!/usr/bin/env python3
"""Keep pre-boot ANR evidence authoritative through an isolated Android tour.

begin marks the interval before installation. finish records read-only endpoint
dumps, then stops the existing monitor and verifies its complete original output.
verify only reads retained files. No mode installs an APK, clears logs, dismisses
a dialog, restarts a monitor, or changes a previous readiness result.
"""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import importlib.util
import json
from pathlib import Path, PurePosixPath
import re
import sys
import time


_SPEC = importlib.util.spec_from_file_location(
    "runtime_anr_framework", Path(__file__).with_name("android_framework_ready.py")
)
FRAMEWORK = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(FRAMEWORK)
FINAL_COMMANDS = {
    "properties": ["getprop"],
    "system-server-pid": ["pidof", "system_server"],
    "input-state": ["dumpsys", "input"],
    "window-state": ["dumpsys", "window", "-a"],
    "events-anr": ["logcat", "-b", "events", "-d", "-v", "threadtime", "-s", "am_anr"],
}
# Exact successful ADB startup bytes in artifact14093659058. Other stderr is not
# normalized or ignored, and the corresponding wait command must still exit0.
ADB_DAEMON_STARTED = (
    b"* daemon not running; starting now at tcp:5037\n"
    b"* daemon started successfully\n"
)
THREADTIME = re.compile(
    r"^(?:\d{4}-)?\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+\s+"
    r"\d+\s+\d+\s+[VDIWEFAS]\s+(?P<tag>[^:\r\n]+):\s?(?P<message>.*)$"
)
SCOPE = (
    "Bounded recorded Android ANR and observation-completeness check. "
    "No APK functionality, visual quality, FPS, physical-device performance, "
    "future stability or retroactive framework-readiness approval."
)


def file_identity(path: Path) -> dict:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            size += len(chunk)
            digest.update(chunk)
    return {"bytes": size, "sha256": digest.hexdigest()}


def original(root: Path, relative: str) -> Path:
    path = PurePosixPath(relative)
    if (not isinstance(relative, str) or not relative or "\\" in relative
            or path.is_absolute() or any(part in ("", ".", "..") for part in relative.split("/"))):
        raise ValueError("Unsafe original path")
    target = root / relative
    if target.is_symlink() or not target.resolve(strict=True).is_relative_to(root.resolve()):
        raise ValueError("Original path escapes its evidence directory")
    if not target.is_file():
        raise ValueError("Missing original file: " + relative)
    return target


def read_json(path: Path) -> dict:
    def unique(pairs):
        value = {}
        for key, item in pairs:
            if key in value:
                raise ValueError("Duplicate JSON field: " + key)
            value[key] = item
        return value

    value = json.loads(path.read_bytes(), object_pairs_hook=unique)
    if not isinstance(value, dict):
        raise ValueError("Expected JSON object: " + path.name)
    return value


def write_new(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def timestamp(value: str) -> datetime:
    result = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if result.tzinfo is None or result.utcoffset() is None:
        raise ValueError("Observation timestamps need a timezone")
    return result


def begin(framework_out: Path, out: Path, serial: str) -> dict:
    if (out / "runtime-start.json").exists() or (out / "runtime-end.json").exists():
        raise ValueError("Refusing to replace an existing runtime interval")
    identity = read_json(framework_out / "monitor-process.json")
    ready = read_json(framework_out / "framework-readiness.json")
    if (identity.get("serial") != serial or identity.get("adb") != FRAMEWORK.adb_path()
            or not FRAMEWORK.monitor_alive(framework_out)
            or any((framework_out / name).exists() for name in ("monitor-finished.json", "monitor-stop.json"))):
        raise ValueError("The original matching startup monitor must still be running")
    if (ready.get("status") != "PASS" or ready.get("monitor_alive_at_finish") is not True
            or ready.get("serial") != serial or ready.get("adb") != identity["adb"]):
        raise ValueError("A recorded positive guard is required before installation")
    value = {"schema": 1, "began_at": FRAMEWORK.utc(), "serial": serial,
             "monitor_identity": identity,
             "monitor_process": file_identity(framework_out / "monitor-process.json"),
             "framework_readiness": file_identity(framework_out / "framework-readiness.json"),
             "scope": "Workflow boundary before the first APK installation and tour commands."}
    write_new(out / "runtime-start.json", value)
    return value


def capture_end(framework_out: Path, out: Path, serial: str, tour_exit_code: int) -> dict:
    if (out / "runtime-end.json").exists() or (out / "commands").exists():
        raise ValueError("Refusing to replace endpoint observations")
    if type(tour_exit_code) is not int or not 0 <= tour_exit_code <= 255:
        raise ValueError("Expected the unchanged shell tour exit code, 0..255")
    value = {"schema": 1, "started_at": FRAMEWORK.utc(), "serial": serial,
             "tour_exit_code": tour_exit_code, "commands": {}, "files": {}, "errors": []}
    try:
        value["monitor_alive_before"] = FRAMEWORK.monitor_alive(framework_out)
        adb = FRAMEWORK.adb_path()
        identity = read_json(framework_out / "monitor-process.json")
        if identity.get("serial") != serial or identity.get("adb") != adb:
            raise ValueError("Endpoint and monitor have different adb/device identities")
        recorder = FRAMEWORK.Recorder(out, adb, serial)
        deadline = time.monotonic() + 30
        for name, arguments in FINAL_COMMANDS.items():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError("Endpoint observation budget exhausted")
            result = recorder.run(name, arguments, min(5, remaining))
            record = {key: item for key, item in result.items() if key not in ("stdout", "stderr")}
            value["commands"][name] = record
            for relative in (record["stdout_file"], record["stderr_file"],
                             record["stdout_file"].removesuffix(".stdout") + ".json"):
                value["files"][relative] = file_identity(original(out, relative))
        value["monitor_alive_after"] = FRAMEWORK.monitor_alive(framework_out)
    except (OSError, ValueError, KeyError, RuntimeError, TimeoutError) as error:
        value["errors"].append(f"{type(error).__name__}: {error}")
    value["finished_at"] = FRAMEWORK.utc()
    if (out / "runtime-start.json").exists():
        value["runtime_start"] = file_identity(out / "runtime-start.json")
    write_new(out / "runtime-end.json", value)
    return value


def scan_anrs(path: Path) -> dict:
    findings, count, parsed, last = [], 0, 0, b""
    with path.open("rb") as stream:
        for number, line in enumerate(stream, 1):
            last = line
            text = line.decode("utf-8", errors="replace").rstrip("\r\n")
            match = THREADTIME.match(text)
            if not match:
                if re.search(r"\bam_anr\s*:|\bActivityManager\s*:\s*ANR\s+in\b", text):
                    count += 1
                    if len(findings) < 100:
                        findings.append({"line": number, "tag": "unparsed_anr_marker", "original_line": text})
                continue
            parsed += 1
            tag, message = match["tag"].strip(), match["message"]
            if tag == "am_anr" or (tag == "ActivityManager" and re.match(r"ANR\s+in\b", message)):
                count += 1
                if len(findings) < 100:
                    findings.append({"line": number, "tag": tag, "original_line": text})
    return {"anr_record_count": count, "findings": findings,
            "findings_truncated": count > len(findings), "threadtime_records": parsed,
            "ends_with_newline": bool(last and last.endswith(b"\n")),
            "original": file_identity(path)}


def verify(framework_out: Path, out: Path, serial: str) -> dict:
    errors, inputs = [], {}

    def require(condition: bool, reason: str) -> None:
        if not condition:
            errors.append(reason)

    def load(root: Path, name: str):
        try:
            path = original(root, name)
            inputs[("framework/" if root == framework_out else "runtime/") + name] = file_identity(path)
            return read_json(path)
        except (OSError, ValueError, TypeError) as error:
            errors.append(f"unavailable:{name}:{type(error).__name__}")
            return None

    scan = None
    try:
        scan = scan_anrs(original(framework_out, "logcat-all.stdout"))
        inputs["framework/logcat-all.stdout"] = scan["original"]
        require(scan["anr_record_count"] == 0, "recorded_android_anr")
        require(scan["threadtime_records"] > 0 and scan["ends_with_newline"], "empty_or_truncated_logcat")
    except (OSError, ValueError, TypeError) as error:
        errors.append("unavailable:logcat-all.stdout:" + type(error).__name__)

    names = ("monitor-process.json", "monitor-finished.json", "monitor-commands.json",
             "monitor-stop.json", "framework-readiness.json")
    monitor, finished, commands, stopped, ready = [load(framework_out, name) for name in names]
    start, end = [load(out, name) for name in ("runtime-start.json", "runtime-end.json")]
    endpoint, adb_start = None, None
    if all(value is not None for value in (monitor, finished, commands, stopped, ready, start, end)):
        try:
            require(all(type(value.get("schema")) is int and value["schema"] == 1
                        for value in (ready, start, end)), "unknown_observation_schema")
            require(all(value.get("serial") == serial for value in (monitor, ready, start, end)), "device_identity_mismatch")
            require(start["monitor_identity"] == stopped["monitor_identity"] == monitor, "monitor_identity_changed")
            require(start["monitor_process"] == inputs["framework/monitor-process.json"], "monitor_provenance_changed")
            require(start["framework_readiness"] == inputs["framework/framework-readiness.json"], "readiness_original_changed")
            require(end["runtime_start"] == inputs["runtime/runtime-start.json"], "runtime_start_changed")
            require(ready.get("status") == "PASS" and ready.get("monitor_alive_at_finish") is True,
                    "original_framework_guard_not_positive")
            require(end.get("monitor_alive_before") is True and end.get("monitor_alive_after") is True,
                    "monitor_not_alive_through_endpoint")
            require(not end.get("errors"), "endpoint_capture_failed")
            require(type(end.get("tour_exit_code")) is int and end["tour_exit_code"] == 0, "tour_command_failed_or_missing")
            require(type(monitor.get("budget_seconds")) is int and 1 <= monitor["budget_seconds"] <= FRAMEWORK.MAX_MONITOR_SECONDS,
                    "unknown_monitor_budget")
            require(finished.get("stop_requested") is True and finished.get("budget_exhausted") is False,
                    "monitor_ended_without_requested_stop_or_budget_exhausted")
            records = finished["commands"]
            require(records == commands["commands"] and len(records) == 2, "missing_or_restarted_logcat_session")
            wait, log = records
            adb = monitor["adb"]
            require(ready.get("adb") == adb, "guard_adb_mismatch")
            require(wait["command"] == [adb, "-s", serial, "wait-for-device"] and type(wait["returncode"]) is int
                    and wait["returncode"] == 0 and wait["stop_requested"] is False, "wait_for_device_incomplete")
            require(log["command"] == [adb, "-s", serial, "logcat", "-b", "all", "-v", "threadtime"],
                    "logcat_command_filtered_or_changed")
            require(log["stdout"] == "logcat-all.stdout" and log["stderr"] == "logcat-all.stderr",
                    "logcat_output_identity_changed")
            require(log["stop_requested"] is True and type(log["returncode"]) is int
                    and log["returncode"] in (0, -15), "logcat_terminated_early_or_abnormally")
            times = [monitor["started_at"], wait["started_at"], wait["finished_at"], log["started_at"],
                     ready["finished_at"], start["began_at"], end["started_at"], end["finished_at"],
                     log["finished_at"], finished["finished_at"], stopped["stopped_at"]]
            parsed = [timestamp(value) for value in times]
            require(all(left <= right for left, right in zip(parsed, parsed[1:])), "recording_does_not_cover_full_interval")
            require(not (out / "stop-error.json").exists(), "monitor_stop_failed")
            for name in (*names[:3], "framework-readiness.json", "wait-for-device.stdout", "wait-for-device.stderr",
                         "logcat-all.stdout", "logcat-all.stderr", "monitor.stdout", "monitor.stderr"):
                actual = file_identity(original(framework_out, name))
                inputs["framework/" + name] = actual
                require(stopped["files"].get(name) == actual, "stopped_original_changed:" + name)
            for name in ("monitor.stderr", "logcat-all.stderr"):
                require(original(framework_out, name).stat().st_size == 0, "recording_stderr_not_empty:" + name)
            wait_stderr = original(framework_out, "wait-for-device.stderr").read_bytes()
            adb_start = {"original": inputs["framework/wait-for-device.stderr"],
                         "classification": ("empty" if wait_stderr == b"" else
                                            "exact_observed_successful_daemon_start" if wait_stderr == ADB_DAEMON_STARTED
                                            else "unexpected_stderr")}
            require(wait_stderr in (b"", ADB_DAEMON_STARTED), "wait_for_device_stderr_unrecognized")

            require(set(end["commands"]) == set(FINAL_COMMANDS), "incomplete_endpoint_commands")
            outputs, expected_files = {}, set()
            for name, arguments in FINAL_COMMANDS.items():
                record = end["commands"][name]
                require(record["command"] == [adb, "-s", serial, "shell", *arguments], "endpoint_command_changed:" + name)
                require(type(record["returncode"]) is int and record["returncode"] == 0
                        and record["timed_out"] is False, "endpoint_command_failed:" + name)
                require(timestamp(end["started_at"]) <= timestamp(record["started_at"])
                        <= timestamp(record["finished_at"]) <= timestamp(end["finished_at"]), "endpoint_time_invalid:" + name)
                record_path = record["stdout_file"].removesuffix(".stdout") + ".json"
                require(read_json(original(out, record_path)) == record, "endpoint_record_changed:" + name)
                for relative in (record["stdout_file"], record["stderr_file"], record_path):
                    expected_files.add(relative)
                    actual = file_identity(original(out, relative))
                    require(end["files"].get(relative) == actual, "endpoint_original_changed:" + relative)
                outputs[name] = original(out, record["stdout_file"]).read_text(encoding="utf-8")
                require(original(out, record["stderr_file"]).stat().st_size == 0, "endpoint_stderr_not_empty:" + name)
            require(set(end["files"]) == expected_files, "endpoint_file_inventory_mismatch")
            endpoint = FRAMEWORK.interactive_surface(outputs["window-state"], outputs["events-anr"], outputs["input-state"])
            require(endpoint["anr_observed"] is False, "endpoint_android_anr_or_error_history")
            require(endpoint["window_last_anr_clear"] is True, "endpoint_window_anr_history_unknown")
            require(endpoint["input_dispatch"]["ready"] is True, "endpoint_dispatch_state_unknown_frozen_or_anr")
            require("unrecognized_anr_event_output" not in endpoint["errors"], "endpoint_anr_events_unrecognized")
            last_sample = ready["samples"][-1]
            require(outputs["system-server-pid"].strip() == last_sample["pid"], "system_server_identity_changed")
            expected_properties = {"sys.boot_completed": "1", "sys.system_server.start_count": last_sample["start_count"],
                                   "ro.build.version.sdk": "37", "ro.build.version.release": "17",
                                   "ro.build.fingerprint": last_sample["android_runtime"]["fingerprint"]}
            for key, expected in expected_properties.items():
                values = re.findall(r"^\[" + re.escape(key) + r"\]: \[(.*)\]$", outputs["properties"], re.MULTILINE)
                require(bool(expected) and values == [expected], "endpoint_runtime_changed_or_unknown:" + key)
        except (OSError, ValueError, TypeError, KeyError, IndexError, UnicodeError) as error:
            errors.append("invalid_or_missing_observation:" + type(error).__name__ + ":" + str(error))
    return {"schema": 1, "status": "FAIL" if errors else "PASS",
            "result": "ANDROID_RUNTIME_ANR_REJECTED" if errors else "ANDROID_RUNTIME_ANR_OBSERVATION_COMPLETE",
            "serial": serial, "errors": errors, "logcat": scan, "endpoint": endpoint, "adb_start": adb_start,
            "inputs": inputs, "observer_sources": {name: file_identity(Path(__file__).with_name(name))
                                                    for name in ("verify_android_runtime_anr.py", "android_framework_ready.py")},
            "scope": SCOPE, "verified_at": FRAMEWORK.utc()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("begin", "finish", "verify"))
    parser.add_argument("--framework-out", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--tour-exit-code", type=int)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-[0-9]+", args.serial):
        parser.error("Expected an exact emulator serial")
    if (args.mode == "finish") != (args.tour_exit_code is not None):
        parser.error("Only finish requires --tour-exit-code")
    framework_out, out = args.framework_out.resolve(), args.out.resolve()
    if framework_out == out:
        parser.error("Keep endpoint observations separate from the original monitor directory")
    try:
        if args.mode == "begin":
            begin(framework_out, out, args.serial)
            print(json.dumps({"result": "ANDROID_RUNTIME_INTERVAL_BEGUN", "serial": args.serial}))
            return 0
        report = args.report or out / "runtime-anr-verification.json"
        if report.exists():
            raise ValueError("Refusing to replace an existing verification report")
        if args.mode == "finish":
            capture_end(framework_out, out, args.serial, args.tour_exit_code)
            try:
                FRAMEWORK.stop_monitor(framework_out)
            except (OSError, ValueError, KeyError, RuntimeError) as error:
                write_new(out / "stop-error.json", {"error": f"{type(error).__name__}: {error}", "observed_at": FRAMEWORK.utc()})
        result = verify(framework_out, out, args.serial)
        write_new(report, result)
        print(json.dumps({key: result[key] for key in ("status", "result", "errors")}))
        return 0 if result["status"] == "PASS" else 1
    except (OSError, ValueError, TypeError, KeyError, RuntimeError) as error:
        print(json.dumps({"status": "FAIL", "result": "ANDROID_RUNTIME_ANR_REJECTED",
                          "errors": [f"{type(error).__name__}: {error}"], "scope": SCOPE}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
