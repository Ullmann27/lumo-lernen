#!/usr/bin/env python3
"""Observe the real API37 framework and unlocked foreground before app setup.

This program never installs an APK, sets a property, supplies adb responses, or
suppresses an upstream failure. One observed nonsecure keyguard may receive a
bounded dismissal request; only subsequent stable window observations can pass.
The separate monitor records unfiltered startup logcat, including the crash buffer.
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


def input_dispatch_state(input_dump: str) -> dict:
    """Read only the current AOSP InputDispatcher section, never its ANR history."""
    lines = input_dump.splitlines()
    starts = [index for index, line in enumerate(lines)
              if line.strip() == "Input Dispatcher State:"]
    anr_state = any(line.strip() == "Input Dispatcher State at time of last ANR:"
                    for line in lines)
    values = {"DispatchEnabled": [], "DispatchFrozen": []}
    if len(starts) == 1:
        start = starts[0]
        indent = len(lines[start]) - len(lines[start].lstrip())
        for line in lines[start + 1:]:
            if not line.strip():
                continue
            depth = len(line) - len(line.lstrip())
            if depth <= indent:
                break
            for field in values:
                match = re.fullmatch(r"\s*" + field + r":\s*(.*?)\s*", line)
                if match:
                    values[field].append(match[1])
    enabled = values["DispatchEnabled"]
    frozen = values["DispatchFrozen"]
    return {"ready": len(starts) == 1 and enabled == ["true"] and frozen == ["false"]
                     and not anr_state,
            "enabled": enabled[0] if len(enabled) == 1 else None,
            "frozen": frozen[0] if len(frozen) == 1 else None,
            "current_section_count": len(starts), "anr_state_present": anr_state}


def interactive_surface(window_dump: str, anr_events: str, input_dump: str = "") -> dict:
    """Read actual window and dispatcher fields; unknown/conflicting states fail.

    The named fields come from WindowManagerService, DisplayContent, WindowState
    KeyguardServiceDelegate and InputDispatcher. These observations do not prove
    future emulator stability or app input delivery. No coordinate or application
    name is assumed. Missing credential security never authorizes an unlock.
    """
    errors = []
    input_dispatch = input_dispatch_state(input_dump)
    event_lines = [line for line in anr_events.splitlines() if line.strip()
                   and not line.startswith("--------- beginning of ")]
    observed_anrs = [line for line in event_lines if re.search(r"\bam_anr\s*:", line)]
    if any(line not in observed_anrs for line in event_lines):
        errors.append("unrecognized_anr_event_output")
    last_anr = re.search(
        r"(?ms)^WINDOW MANAGER LAST ANR \(dumpsys window lastanr\)\s*\n(.*?)(?=^WINDOW MANAGER |\Z)",
        window_dump,
    )
    # The -a dump inserts a separator before the next service section. Ignore
    # only that structural line, never arbitrary ANR text or an empty response.
    last_anr_lines = ([line.strip() for line in last_anr[1].splitlines()
                       if line.strip() and not re.fullmatch(r"-{8,}", line.strip())]
                      if last_anr else [])
    no_window_anr = last_anr_lines == ["<no ANR has occurred since boot>"]
    window_anr = bool(last_anr_lines and not no_window_anr)
    error_window = bool(re.search(r"Application (?:Not Responding|Error)|AppNotRespondingDialog|AppErrorDialog", window_dump))
    anr_observed = bool(observed_anrs or window_anr or error_window
                        or input_dispatch["anr_state_present"])
    if anr_observed:
        errors.append("android_anr_or_error_window_observed")
    elif not no_window_anr:
        errors.append("window_anr_state_not_observed")

    lines = window_dump.splitlines()
    starts = [i for i, line in enumerate(lines) if line.strip() == "KeyguardServiceDelegate"]
    keyguard = {}
    if len(starts) == 1:
        start = starts[0]
        indent = len(lines[start]) - len(lines[start].lstrip())
        for line in lines[start + 1:]:
            if not line.strip():
                continue
            depth = len(line) - len(line.lstrip())
            if depth <= indent:
                break
            if depth == indent + 2 and "=" in line:
                key, value = line.strip().split("=", 1)
                if key in keyguard:
                    errors.append("ambiguous_keyguard_field:" + key)
                keyguard[key] = value
    fields = ("showing", "inputRestricted", "occluded", "dreaming",
              "deviceHasKeyguard", "enabled", "bootCompleted")
    # Android 17's actual dump uses systemReady; older dumps use systemIsReady.
    # Both may agree, but missing, malformed or conflicting values are unknown.
    system_values = [keyguard[name] for name in ("systemReady", "systemIsReady")
                     if name in keyguard]
    system_ready = (system_values[0] if system_values
                    and all(value == system_values[0] for value in system_values) else None)
    keyguard_known = (all(keyguard.get(key) in ("true", "false") for key in fields)
                      and system_ready in ("true", "false"))
    if not keyguard_known:
        errors.append("keyguard_state_not_observed")
    credential_secure = {"true": True, "false": False}.get(keyguard.get("secure"))
    if "secure" in keyguard and credential_secure is None:
        errors.append("keyguard_credential_security_malformed")
    awake = (keyguard.get("screenState") == "SCREEN_STATE_ON"
             and keyguard.get("interactiveState") == "INTERACTIVE_STATE_AWAKE"
             and keyguard.get("dreaming") == "false")
    if not awake:
        errors.append("interactive_display_not_awake")
    if system_ready != "true" or keyguard.get("bootCompleted") != "true":
        errors.append("keyguard_framework_not_ready")

    focuses = re.findall(r"(?m)^\s*mCurrentFocus=(.+)$", window_dump)
    applications = re.findall(r"(?m)^\s*mFocusedApp=(.+)$", window_dump)
    focus = focuses[0].strip() if len(focuses) == 1 else ""
    application = applications[0].strip() if len(applications) == 1 else ""
    focused_window = bool(re.fullmatch(r"Window\{[^\n{}]+\}", focus))
    if not focused_window:
        errors.append("focused_window_missing_or_ambiguous")
    blocks = list(re.finditer(r"(?m)^\s*Window #\d+ (Window\{[^\n{}]+\}):\s*$", window_dump))
    surfaces = []
    for index, block in enumerate(blocks):
        if block[1] == focus:
            end = blocks[index + 1].start() if index + 1 < len(blocks) else len(window_dump)
            surfaces += re.findall(r"\bmHasSurface=(true|false)\s+isReadyForDisplay\(\)=(true|false)", window_dump[block.end():end])
    surface_ready = surfaces == [("true", "true")]
    if not surface_ready:
        errors.append("focused_window_surface_not_ready")
    boot_display = re.findall(r"\bmSystemBooted=(true|false)\s+mDisplayEnabled=(true|false)", window_dump)
    frozen = re.findall(r"\bmDisplayFrozen=([^\s]*)", window_dump)
    # Android 17 no longer emits mDisplayFrozen here. An explicit positive
    # InputDispatcher sample replaces that observation; absence alone cannot.
    # A legacy window freeze or freeze reason still vetoes readiness.
    if (boot_display != [("true", "true")] or frozen not in ([], ["false"])
            or "mInputFreezeReason=" in window_dump or not input_dispatch["ready"]):
        errors.append("display_dispatch_not_observed_unfrozen")

    # Only an explicitly visible, awake, nonsecure keyguard is eligible for one
    # request. A zero request exit is never treated as an unlocked acknowledgment.
    unlock_eligible = (not errors and keyguard_known and focused_window and surface_ready
                       and keyguard.get("showing") == "true"
                       and keyguard.get("inputRestricted") == "true"
                       and credential_secure is False
                       and keyguard.get("occluded") == "false"
                       and keyguard.get("enabled") == "true"
                       and keyguard.get("deviceHasKeyguard") == "true")
    if keyguard.get("showing") != "false" or keyguard.get("inputRestricted") != "false":
        errors.append("keyguard_not_observed_unlocked")

    def component(value: str) -> str | None:
        matches = re.findall(r"\b([A-Za-z_][\w.]*)/(\.?[A-Za-z_$][\w.$]*)\b", value)
        if len(matches) != 1:
            return None
        package, activity = matches[0]
        return package + "/" + (package + activity if activity.startswith(".") else activity)

    focus_component = component(focus)
    app_component = component(application)
    if not application.startswith("ActivityRecord{") or not focus_component or focus_component != app_component:
        errors.append("focused_activity_not_consistent")
    return {"ready": not errors, "errors": errors, "keyguard": keyguard,
            "credential_secure": credential_secure, "input_dispatch": input_dispatch,
            "focused_window": focus, "focused_application": application,
            "surface_ready": surface_ready, "anr_observed": anr_observed,
            "anr_events": observed_anrs, "window_last_anr_clear": no_window_anr,
            "unlock_eligible": unlock_eligible}


def observe(recorder: Recorder, deadline: float, clock=time.monotonic) -> dict:
    commands = [("properties", ["getprop"]), ("pid-before", ["pidof", "system_server"])]
    commands += [(f"service-{name}", ["service", "check", name]) for name in SERVICES]
    commands += [("settings-read", ["settings", "get", "global", "boot_count"]),
                 ("package-read", ["cmd", "package", "path", "android"]),
                 ("window-read", ["wm", "size"]),
                 ("window-state", ["dumpsys", "window", "-a"]),
                 ("input-state", ["dumpsys", "input"]),
                 ("events-anr", ["logcat", "-b", "events", "-d", "-v", "threadtime", "-s", "am_anr"]),
                 ("pid-after", ["pidof", "system_server"]),
                 ("count-after", ["getprop", "sys.system_server.start_count"])]
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
    interactive = interactive_surface(output("window-state"), output("events-anr"),
                                      output("input-state"))
    unlock_eligible = not errors and interactive["unlock_eligible"]
    errors += interactive["errors"]
    return {"observed_at": utc(), "ready": not errors, "errors": errors, "pid": pid,
            "start_count": count, "android_runtime": runtime, "interactive": interactive,
            "unlock_eligible": unlock_eligible,
            "services": {name: output(f"service-{name}") for name in SERVICES},
            "settings_boot_count": output("settings-read"), "package_android": output("package-read"),
            "window_size": output("window-read"),
            "command_records": {name: {key: value for key, value in item.items() if key not in ("stdout", "stderr")} for name, item in results.items()}}


def observe_resources(recorder: Recorder, deadline: float, clock=time.monotonic) -> dict:
    """One read-only storage/memory sample; never a substitute readiness gate."""
    results = {}
    for name, arguments in (("data-filesystem", ["df", "-k", "/data"]),
                            ("memory-info", ["cat", "/proc/meminfo"]),
                            ("mounted-filesystems", ["cat", "/proc/mounts"])):
        remaining = deadline - clock()
        if remaining <= 0:
            break
        result = recorder.run(name, arguments, min(2.0, remaining))
        results[name] = {key: value for key, value in result.items() if key not in ("stdout", "stderr")}
    return {"scope": "Single actual read-only /data, memory and mount observation, including unsuccessful command records; no partition changes", "command_records": results}


def poll_framework(recorder: Recorder, timeout: float, stable_seconds: float, minimum_samples: int, poll_seconds: float = 2, clock=time.monotonic, sleeper=time.sleep) -> dict:
    start = clock()
    deadline = start + timeout
    stable_since = None
    consecutive = 0
    identity = None
    stable_surface = None
    unlock_action = {"attempted": False, "scope": "At most one observed nonsecure keyguard request; no MENU82 or dialog clicks."}
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
        if sample["interactive"]["anr_observed"]:
            reason = "observed_android_anr"
            break
        if sample["unlock_eligible"] and not unlock_action["attempted"]:
            remaining = deadline - clock()
            if remaining <= 0:
                break
            command = recorder.run("unlock-keyguard", ["wm", "dismiss-keyguard"], min(5, remaining))
            unlock_action.update(attempted=True, observed_sample=len(samples) - 1,
                                 command_record={key: value for key, value in command.items()
                                                 if key not in ("stdout", "stderr")})
            if command["returncode"] != 0 or command["timed_out"]:
                reason = "keyguard_unlock_command_failed"
                break
        if sample["ready"]:
            surface = (sample["interactive"]["focused_window"], sample["interactive"]["focused_application"])
            if surface != stable_surface:
                stable_since, consecutive = None, 0
                stable_surface = surface
            stable_since = clock() if stable_since is None else stable_since
            consecutive += 1
            if consecutive >= minimum_samples and clock() - stable_since >= stable_seconds and clock() < deadline:
                reason = "required_framework_and_interactive_surface_observed_stable"
                status = "PASS"
                break
        else:
            stable_since, consecutive, stable_surface = None, 0, None
        remaining = deadline - clock()
        if remaining > 0:
            sleeper(min(poll_seconds, remaining))
    return {"schema": 1, "status": status, "reason": reason, "elapsed_seconds": clock() - start, "budget_seconds": timeout, "required_stable_seconds": stable_seconds, "required_minimum_samples": minimum_samples, "consecutive_ready_samples": consecutive, "stable_observed_seconds": 0 if stable_since is None else clock() - stable_since, "samples": samples, "unlock_action": unlock_action, "redundant_menu_keyevent_82": "NOT_SENT", "observed_start_count_greater_than_one": any(s["start_count"].isdigit() and int(s["start_count"]) > 1 for s in samples), "scope": "Sampled pre-app framework, keyguard, visible focus and ANR observations. The same stable positive window is required after any unlock request. No app input delivery, later system stability or physical-device performance is certified."}


def wait_for_framework(out: Path, serial: str, timeout: float, stable_seconds: float, minimum_samples: int, cli22_proof: Path | None = None) -> int:
    if not monitor_alive(out):
        raise RuntimeError("Startup log monitor is unavailable; refusing unobserved readiness")
    record = json.loads((out / "monitor-process.json").read_text())
    if record["serial"] != serial or record["adb"] != adb_path():
        raise RuntimeError("Readiness and startup monitor target different SDK adb/device identities")
    started = time.monotonic()
    deadline = started + timeout
    recorder = Recorder(out, adb_path(), serial)
    resources = observe_resources(recorder, deadline)
    result = {"schema": 1, "status": "FAIL", "reason": "actual_cli22_avd_binding_not_verified", "samples": [], "consecutive_ready_samples": 0}
    try:
        if cli22_proof is None:
            raise ValueError("The actual CLI22 and generated AVD proof is mandatory before keyevent or app tests")
        command = [sys.executable, str(Path(__file__).with_name("prepare_android37_cli22.py")),
                   "verify", "--out", str(cli22_proof), "--phase", "guard"]
        with (out / "cli22-avd-verify.stdout").open("xb") as stdout, (out / "cli22-avd-verify.stderr").open("xb") as stderr:
            verified = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                                      timeout=max(.001, min(20, deadline - time.monotonic())), check=False)
        write_json(out / "cli22-avd-verify.json", {"command": command, "returncode": verified.returncode})
        if verified.returncode:
            raise RuntimeError("Actual CLI22/AVD verification failed; original stderr is preserved")
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("Original readiness budget exhausted before framework polling")
        result = poll_framework(recorder, remaining, stable_seconds, minimum_samples)
        result["framework_poll_budget_seconds"] = remaining
    except Exception as error:
        result["binding_error"] = f"{type(error).__name__}: {error}"
    result.update({"resource_observation": resources, "cli22_proof": str(cli22_proof) if cli22_proof else None,
                   "budget_seconds": timeout, "elapsed_seconds": time.monotonic() - started})
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
    parser.add_argument("--cli22-proof", type=Path)
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
        return wait_for_framework(out, args.serial, args.timeout, args.stable_seconds, args.minimum_samples, args.cli22_proof)
    else:
        stop_monitor(out, args.allow_not_started)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Framework readiness failed: {error}", file=sys.stderr)
        sys.exit(1)
