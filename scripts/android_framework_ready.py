#!/usr/bin/env python3
"""Observe a real API37 framework before the upstream action sends its keyevent.

This program never installs an APK, sets a property, supplies adb responses, or
suppresses an upstream failure. The separate monitor records unfiltered logcat
from the first available adb connection, including the crash buffer.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time


SERVICES = ("input", "settings", "activity", "package", "window")
STOP_REQUESTED = False


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def adb_path() -> str:
    root = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not root:
        raise ValueError("ANDROID_HOME or ANDROID_SDK_ROOT is required")
    path = (Path(root) / "platform-tools/adb").resolve(strict=True)
    if not os.access(path, os.X_OK):
        raise ValueError("The actual SDK adb is not executable")
    return str(path)


def process_identity(pid: int) -> tuple[str, str] | None:
    try:
        fields = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
        return fields[0], fields[19]
    except (OSError, IndexError):
        return None


def monitor_alive(out: Path) -> bool:
    info = json.loads((out / "monitor-process.json").read_text())
    identity = process_identity(info["pid"])
    return bool(identity and identity[0] != "Z" and identity[1] == info["start_ticks"])


def start_monitor(out: Path, serial: str) -> None:
    out.mkdir(parents=True, exist_ok=True)
    if (out / "monitor-process.json").exists():
        raise ValueError("Refusing to replace existing framework start evidence")
    command = [sys.executable, str(Path(__file__).resolve()), "_monitor", "--out", str(out), "--serial", serial]
    with (out / "monitor.stdout").open("xb") as stdout, (out / "monitor.stderr").open("xb") as stderr:
        process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr, start_new_session=True)
    identity = process_identity(process.pid)
    if identity is None:
        raise RuntimeError("Framework log monitor did not start")
    write_json(out / "monitor-process.json", {"pid": process.pid, "start_ticks": identity[1], "command": command, "started_at": utc(), "serial": serial, "adb": adb_path(), "budget_seconds": 450})


def collect_monitor(out: Path, serial: str) -> int:
    global STOP_REQUESTED

    def stop(_signum: int, _frame: object) -> None:
        global STOP_REQUESTED
        STOP_REQUESTED = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    deadline = time.monotonic() + 450
    commands = (("wait-for-device", [adb_path(), "-s", serial, "wait-for-device"]), ("logcat-all", [adb_path(), "-s", serial, "logcat", "-b", "all", "-v", "threadtime"]))
    records = []
    for name, command in commands:
        if STOP_REQUESTED:
            break
        started = utc()
        with (out / f"{name}.stdout").open("xb") as stdout, (out / f"{name}.stderr").open("xb") as stderr:
            process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
            while process.poll() is None and not STOP_REQUESTED and time.monotonic() < deadline:
                time.sleep(0.1)
            ended_by_observer = process.poll() is None
            if ended_by_observer:
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=2)
        records.append({"command": command, "started_at": started, "finished_at": utc(), "returncode": process.returncode, "ended_by_observer": ended_by_observer, "stop_requested": STOP_REQUESTED, "stdout": f"{name}.stdout", "stderr": f"{name}.stderr"})
        write_json(out / "monitor-commands.json", {"commands": records})
        if process.returncode != 0 or STOP_REQUESTED:
            break
    write_json(out / "monitor-finished.json", {"finished_at": utc(), "stop_requested": STOP_REQUESTED, "budget_exhausted": time.monotonic() >= deadline, "commands": records})
    return 0 if STOP_REQUESTED else 1


def stop_monitor(out: Path, allow_not_started: bool = False) -> None:
    if (out / "monitor-stop.json").exists():
        return
    path = out / "monitor-process.json"
    if not path.exists():
        if allow_not_started:
            print("Framework monitor was not started; no readiness claim.")
            return
        raise ValueError("Missing framework monitor provenance")
    info = json.loads(path.read_text())
    identity = process_identity(info["pid"])
    if identity and identity[0] != "Z":
        if identity[1] != info["start_ticks"]:
            raise ValueError("Monitor PID was reused; refusing to signal another process")
        os.killpg(info["pid"], signal.SIGTERM)
        deadline = time.monotonic() + 4
        while monitor_alive(out) and time.monotonic() < deadline:
            time.sleep(0.1)
        if monitor_alive(out):
            os.killpg(info["pid"], signal.SIGKILL)
            raise RuntimeError("Framework monitor needed forced termination")
    files = {}
    for file in sorted(out.rglob("*")):
        if file.is_file() and file.name != "monitor-stop.json":
            data = file.read_bytes()
            files[str(file.relative_to(out))] = {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
    write_json(out / "monitor-stop.json", {"stopped_at": utc(), "monitor_identity": info, "files": files, "scope": "Raw available adb startup observations; no app or device-performance result."})


class Recorder:
    def __init__(self, out: Path, adb: str, serial: str):
        self.out, self.adb, self.serial = out, adb, serial
        self.counter = 0
        (out / "commands").mkdir(parents=True, exist_ok=True)

    def run(self, name: str, arguments: list[str], timeout: float) -> dict:
        self.counter += 1
        base = f"commands/{self.counter:04d}-{name}"
        command = [self.adb, "-s", self.serial, "shell", *arguments]
        started = utc()
        timed_out = False
        process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
        try:
            stdout, stderr = process.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            os.killpg(process.pid, signal.SIGKILL)
            stdout, stderr = process.communicate()
        (self.out / (base + ".stdout")).write_bytes(stdout)
        (self.out / (base + ".stderr")).write_bytes(stderr)
        record = {"command": command, "started_at": started, "finished_at": utc(), "returncode": process.returncode, "timed_out": timed_out, "stdout_file": base + ".stdout", "stderr_file": base + ".stderr"}
        write_json(self.out / (base + ".json"), record)
        return {**record, "stdout": stdout.decode("utf-8", errors="replace"), "stderr": stderr.decode("utf-8", errors="replace")}


def observe(recorder: Recorder, deadline: float, clock=time.monotonic) -> dict:
    commands = [("properties", ["getprop"]), ("pid-before", ["pidof", "system_server"])]
    commands += [(f"service-{name}", ["service", "check", name]) for name in SERVICES]
    commands += [("settings-read", ["settings", "get", "global", "boot_count"]), ("package-read", ["cmd", "package", "path", "android"]), ("window-read", ["wm", "size"]), ("pid-after", ["pidof", "system_server"]), ("count-after", ["getprop", "sys.system_server.start_count"])]
    results = {}
    for name, arguments in commands:
        remaining = deadline - clock()
        if remaining <= 0:
            break
        results[name] = recorder.run(name, arguments, min(5.0, remaining))
    errors = []
    for name, _ in commands:
        result = results.get(name)
        if not result or result["returncode"] != 0 or result["timed_out"]:
            errors.append(f"command_unavailable:{name}")
    output = lambda name: results.get(name, {}).get("stdout", "").strip()
    properties = dict(re.findall(r"^\[([^\]]+)\]: \[(.*)\]$", output("properties"), re.MULTILINE))
    pid = output("pid-before")
    count = properties.get("sys.system_server.start_count", "")
    if properties.get("sys.boot_completed") != "1":
        errors.append("boot_property_not_one")
    if not re.fullmatch(r"[1-9][0-9]*", pid) or output("pid-after") != pid:
        errors.append("system_server_pid_not_consistent")
    if not re.fullmatch(r"[1-9][0-9]*", count) or output("count-after") != count:
        errors.append("system_server_start_count_not_consistent")
    for name in SERVICES:
        if output(f"service-{name}") != f"Service {name}: found":
            errors.append(f"service_not_registered:{name}")
    if not re.fullmatch(r"[0-9]+", output("settings-read")):
        errors.append("settings_provider_not_readable")
    if not re.search(r"^package:/[^\n]+\.apk$", output("package-read"), re.MULTILINE):
        errors.append("android_package_not_readable")
    if not re.search(r"Physical size: [1-9][0-9]*x[1-9][0-9]*", output("window-read")):
        errors.append("window_manager_not_readable")
    runtime = {"sdk": properties.get("ro.build.version.sdk", ""), "release": properties.get("ro.build.version.release", ""), "fingerprint": properties.get("ro.build.fingerprint", "")}
    if runtime["sdk"] != "37" or runtime["release"] != "17" or not runtime["fingerprint"]:
        errors.append("expected_android37_release17_not_observed")
    return {"observed_at": utc(), "ready": not errors, "errors": errors, "pid": pid, "start_count": count, "android_runtime": runtime, "services": {name: output(f"service-{name}") for name in SERVICES}, "settings_boot_count": output("settings-read"), "package_android": output("package-read"), "window_size": output("window-read"), "command_records": {name: {key: value for key, value in item.items() if key not in ("stdout", "stderr")} for name, item in results.items()}}


def poll_framework(recorder: Recorder, timeout: float, stable_seconds: float, minimum_samples: int, poll_seconds: float = 2, clock=time.monotonic, sleeper=time.sleep) -> dict:
    start = clock()
    deadline = start + timeout
    stable_since = None
    consecutive = 0
    identity = None
    samples = []
    reason = "framework_readiness_deadline_exceeded"
    status = "FAIL"
    while clock() < deadline:
        sample = observe(recorder, deadline, clock)
        samples.append(sample)
        current_identity = (sample["pid"], sample["start_count"])
        coherent = all(re.fullmatch(r"[1-9][0-9]*", value) for value in current_identity) and "system_server_pid_not_consistent" not in sample["errors"] and "system_server_start_count_not_consistent" not in sample["errors"]
        if coherent and identity is not None and identity != current_identity:
            reason = "observed_system_server_identity_changed"
            break
        if coherent:
            identity = current_identity
        runtime = sample["android_runtime"]
        if (runtime["sdk"] and runtime["sdk"] != "37") or (runtime["release"] and runtime["release"] != "17"):
            reason = "wrong_android_runtime"
            break
        if sample["ready"]:
            stable_since = clock() if stable_since is None else stable_since
            consecutive += 1
            if consecutive >= minimum_samples and clock() - stable_since >= stable_seconds and clock() < deadline:
                reason = "required_framework_services_observed_stable"
                status = "PASS"
                break
        else:
            stable_since, consecutive = None, 0
        remaining = deadline - clock()
        if remaining > 0:
            sleeper(min(poll_seconds, remaining))
    return {"schema": 1, "status": status, "reason": reason, "elapsed_seconds": clock() - start, "budget_seconds": timeout, "required_stable_seconds": stable_seconds, "required_minimum_samples": minimum_samples, "consecutive_ready_samples": consecutive, "stable_observed_seconds": 0 if stable_since is None else clock() - stable_since, "samples": samples, "observed_start_count_greater_than_one": any(s["start_count"].isdigit() and int(s["start_count"]) > 1 for s in samples), "scope": "Sampled pre-app framework readiness only; raw startup logs must distinguish any early race from a system-server failure. This is not an app test or physical-device performance measurement."}


def wait_for_framework(out: Path, serial: str, timeout: float, stable_seconds: float, minimum_samples: int) -> int:
    if not monitor_alive(out):
        raise RuntimeError("Startup log monitor is unavailable; refusing unobserved readiness")
    record = json.loads((out / "monitor-process.json").read_text())
    if record["serial"] != serial or record["adb"] != adb_path():
        raise RuntimeError("Readiness and startup monitor target different SDK adb/device identities")
    result = poll_framework(Recorder(out, adb_path(), serial), timeout, stable_seconds, minimum_samples)
    result.update({"serial": serial, "adb": adb_path(), "finished_at": utc(), "monitor_alive_at_finish": monitor_alive(out)})
    if not result["monitor_alive_at_finish"]:
        result.update(status="FAIL", reason="startup_monitor_exited_before_readiness_finished")
    write_json(out / "framework-readiness.json", result)
    print(json.dumps({key: result[key] for key in ("status", "reason", "serial", "elapsed_seconds", "consecutive_ready_samples")}))
    return 0 if result["status"] == "PASS" else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("start", "wait", "stop", "_monitor"))
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--stable-seconds", type=float, default=10)
    parser.add_argument("--minimum-samples", type=int, default=3)
    parser.add_argument("--allow-not-started", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-[0-9]+", args.serial):
        parser.error("Expected the exact emulator serial")
    if not 0 < args.stable_seconds < args.timeout <= 120 or args.minimum_samples < 3:
        parser.error("Readiness needs a positive bounded window and at least three observations")
    out = args.out.resolve()
    if args.mode == "start":
        start_monitor(out, args.serial)
    elif args.mode == "_monitor":
        return collect_monitor(out, args.serial)
    elif args.mode == "wait":
        return wait_for_framework(out, args.serial, args.timeout, args.stable_seconds, args.minimum_samples)
    else:
        stop_monitor(out, args.allow_not_started)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Framework readiness failed: {error}", file=sys.stderr)
        sys.exit(1)
