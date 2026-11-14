#!/usr/bin/env python3
"""Observe the real API37 framework and unlocked foreground before app setup.

The framework guard never installs an APK, supplies adb responses, or suppresses
an upstream failure. One observed nonsecure keyguard may receive a
bounded dismissal request; only subsequent stable window observations can pass.
The separate monitor records unfiltered startup logcat, including the crash buffer.
The explicitly requested runtime handoff also starts a detached device logger
before the observed root transition; it neither clears nor rotates either log.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import secrets
import selectors
import shlex
import signal
import subprocess
import sys
import time


SERVICES = ("input", "settings", "activity", "package", "window")
STOP_REQUESTED = False
DEFAULT_MONITOR_SECONDS = 450
MAX_MONITOR_SECONDS = 7200

_CONSOLE_SPEC = importlib.util.spec_from_file_location(
    "lumo_init_console_transport", Path(__file__).with_name("android_console_transport.py")
)
CONSOLE = importlib.util.module_from_spec(_CONSOLE_SPEC)
_CONSOLE_SPEC.loader.exec_module(CONSOLE)


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


def monitor_budget(seconds: int) -> int:
    if type(seconds) is not int or not 1 <= seconds <= MAX_MONITOR_SECONDS:
        raise ValueError(f"Monitor duration must be an integer from 1 to {MAX_MONITOR_SECONDS} seconds")
    return seconds


def start_monitor(out: Path, serial: str, monitor_seconds: int = DEFAULT_MONITOR_SECONDS) -> None:
    monitor_seconds = monitor_budget(monitor_seconds)
    out.mkdir(parents=True, exist_ok=True)
    if (out / "monitor-process.json").exists():
        raise ValueError("Refusing to replace existing framework start evidence")
    command = [sys.executable, str(Path(__file__).resolve()), "_monitor", "--out", str(out), "--serial", serial,
               "--monitor-seconds", str(monitor_seconds)]
    with (out / "monitor.stdout").open("xb") as stdout, (out / "monitor.stderr").open("xb") as stderr:
        started_at = utc()
        process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr, start_new_session=True)
    identity = process_identity(process.pid)
    if identity is None:
        raise RuntimeError("Framework log monitor did not start")
    write_json(out / "monitor-process.json", {"pid": process.pid, "start_ticks": identity[1], "command": command, "started_at": started_at, "serial": serial, "adb": adb_path(), "budget_seconds": monitor_seconds})


def collect_monitor(out: Path, serial: str, monitor_seconds: int = DEFAULT_MONITOR_SECONDS) -> int:
    global STOP_REQUESTED

    def stop(_signum: int, _frame: object) -> None:
        global STOP_REQUESTED
        STOP_REQUESTED = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    deadline = time.monotonic() + monitor_budget(monitor_seconds)
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
        return self.run_adb(name, ["shell", *arguments], timeout)

    def run_adb(self, name: str, arguments: list[str], timeout: float) -> dict:
        self.counter += 1
        base = f"commands/{self.counter:04d}-{name}"
        command = [self.adb, "-s", self.serial, *arguments]
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


DEVICE_LOG_TAG = "LumoRuntimeRecorder"
DEVICE_LOG_PATH = re.compile(r"/data/local/tmp/lumo-runtime-[0-9a-f]{32}")
DEVICE_LOG_FILES = ("logcat.stdout", "logcat.stderr", "session.stdout", "session.stderr", "wait.stderr", "run.sh", "console.pid", "launch.stdout", "launch.stderr")
ROOT_RESTART_CLOSED = "adb: unable to connect for root: closed"


def expected_root_disconnect(result: dict) -> bool:
    return (result["returncode"] == 1 and not result["timed_out"] and
            ((not result["stdout"] and result["stderr"].strip() == ROOT_RESTART_CLOSED) or
             (not result["stderr"] and result["stdout"].strip() == ROOT_RESTART_CLOSED)))


def device_logger_script(remote: str) -> str:
    if not DEVICE_LOG_PATH.fullmatch(remote):
        raise ValueError("Invalid private device logger directory")
    # nohup and setsid are checked on the real emulator. The shell waits for
    # its actual logcat child and preserves that child's exit status.
    return ("#!/system/bin/sh\nset -u\numask 077\nunset ANDROID_LOG_TAGS\ncd " + remote + " || exit 91\n"
            "printf '%s\\n' \"$$\" > session.pid\n: > wait.stderr\n"
            "/system/bin/logcat -b all -v threadtime > logcat.stdout 2> logcat.stderr &\n"
            "logger=$!\nprintf '%s\\n' \"$logger\" > logger.pid\n"
            "attempt=0\nwhile [ ! -s logcat.stdout ] && [ \"$attempt\" -lt 50 ]; do\n"
            "  sleep 0.1\n  attempt=$((attempt + 1))\ndone\n"
            "if [ -s logcat.stdout ]; then printf 'ready\\n' > ready; fi\n"
            "wait \"$logger\" 2> wait.stderr\n"
            "result=$?\nprintf '%s\\n' \"$result\" > logger.exit\nexit \"$result\"\n")


def device_logger_launch(remote: str) -> str:
    script = device_logger_script(remote)
    return ("set -eu\numask 077\n"
            "test \"$#\" -eq 1\ncase \"$1\" in ''|*[!0-9]*) exit 92;; esac\n"
            "test \"$(getprop init.svc.console)\" = running\n"
            "test -x /system/bin/toybox && test -x /system/bin/logcat\n"
            "mkdir " + remote + "\nexec > " + remote + "/launch.stdout 2> " + remote + "/launch.stderr\n"
            "printf '%s\\n' \"$1\" > " + remote + "/console.pid\n"
            "printf '%s' " + shlex.quote(script) + " > " + remote + "/run.sh\n"
            "/system/bin/toybox nohup /system/bin/toybox setsid /system/bin/sh " + remote +
            "/run.sh > " + remote + "/session.stdout 2> " + remote + "/session.stderr < /dev/null &\n"
            "attempt=0\nwhile [ ! -s " + remote + "/ready ] && [ \"$attempt\" -lt 100 ]; do\n"
            "  sleep 0.1\n  attempt=$((attempt + 1))\ndone\ntest -s " + remote + "/ready\n")


def device_snapshot_script(remote: str, *, live: bool = True) -> str:
    device_logger_script(remote)  # Validate before any shell interpolation.
    script = "set -eu\ntest ! -L " + remote + "\ncd " + remote + "\n"
    if live:
        script += "printf '__console_service__\\n'\ngetprop init.svc.console\n"
        for role in ("console", "session", "logger", "adbd"):
            source = "pidof adbd" if role == "adbd" else "cat " + role + ".pid"
            if role != "adbd":
                script += "test -f " + role + ".pid && test ! -L " + role + ".pid\n"
            script += ("pid=$(" + source + ")\ncase \"$pid\" in ''|*[!0-9]*) exit 92;; esac\n"
                       "printf '__" + role + "_stat__\\n'\ncat /proc/$pid/stat\n"
                       "printf '__" + role + "_argv__\\n'\nod -An -v -tx1 /proc/$pid/cmdline\n"
                       "printf '__" + role + "_uid__\\n'\nawk '/^Uid:/{print $2, $3, $4, $5}' /proc/$pid/status\n"
                       "printf '__" + role + "_cgroup__\\n'\ncat /proc/$pid/cgroup\n")
    for name in DEVICE_LOG_FILES:
        script += ("test -f " + name + " && test ! -L " + name + "\n"
                   "printf '__file_" + name + "__\\n'\nstat -c '%d:%i:%s:%f' " + name + "\n")
    script += "printf '__script_hash__\\n'\nsha256sum run.sh\n"
    return script


def parse_device_snapshot(raw: str, remote: str, *, live: bool = True) -> dict:
    expected = {"file_" + name for name in DEVICE_LOG_FILES} | {"script_hash"}
    if live:
        expected |= {"console_service"}
        expected |= {role + suffix for role in ("console", "session", "logger", "adbd")
                     for suffix in ("_stat", "_argv", "_uid", "_cgroup")}
    sections, current = {}, None
    for line in raw.splitlines():
        match = re.fullmatch(r"__([a-z_.]+)__", line)
        if match:
            current = match[1]
            if current in sections or current not in expected:
                raise ValueError("Unknown or duplicate device snapshot section")
            sections[current] = []
        elif current is None:
            raise ValueError("Unframed device snapshot output")
        else:
            sections[current].append(line)
    if set(sections) != expected:
        raise ValueError("Incomplete device snapshot")
    result = {"files": {}}
    for name in DEVICE_LOG_FILES:
        match = re.fullmatch(r"([0-9]+):([0-9]+):([0-9]+):([0-9a-fA-F]+)", "".join(sections["file_" + name]))
        if not match or int(match[4], 16) & 0xF000 != 0x8000:
            raise ValueError("Device evidence must be a regular file")
        result["files"][name] = {"device": int(match[1]), "inode": int(match[2]),
                                  "bytes": int(match[3]), "mode": int(match[4], 16)}
    expected_hash = hashlib.sha256(device_logger_script(remote).encode()).hexdigest()
    if sections["script_hash"] != [expected_hash + "  run.sh"]:
        raise ValueError("Device logger script differs from the literal source")
    result["script_sha256"] = expected_hash
    if live:
        if sections["console_service"] != ["running"]:
            raise ValueError("The actual init console service is not running")
        for role in ("console", "session", "logger", "adbd"):
            stat = " ".join(sections[role + "_stat"])
            match = re.fullmatch(r"([0-9]+) \(.*\) (.*)", stat)
            fields = match[2].split() if match else []
            if len(fields) < 20 or fields[0] in ("Z", "X", "x"):
                raise ValueError("Device logger process is absent or dead")
            argv = bytes.fromhex("".join(sections[role + "_argv"]).replace(" ", "")).decode().rstrip("\0").split("\0")
            wanted = {"console": ["/system/bin/sh"], "session": ["/system/bin/sh", remote + "/run.sh"],
                      "logger": ["/system/bin/logcat", "-b", "all", "-v", "threadtime"]}
            if (role != "adbd" and argv != wanted[role]) or (role == "adbd" and
                    (not argv or argv[0] not in ("/system/bin/adbd", "/apex/com.android.adbd/bin/adbd"))):
                raise ValueError("Device logger process command changed")
            uid = " ".join(sections[role + "_uid"])
            if not re.fullmatch(r"(?:0 0 0 0|2000 2000 2000 2000)", uid):
                raise ValueError("Unexpected actual console/logger/adbd UID")
            cgroups = {}
            for line in sections[role + "_cgroup"]:
                group = re.fullmatch(r"([0-9]+):([a-z0-9_,=]*):(/[^\s]*)", line)
                if (not group or group[1] in cgroups or any(part in (".", "..") for part in group[3].split("/"))):
                    raise ValueError("Invalid or duplicate actual process cgroup")
                cgroups[group[1]] = {"controllers": group[2], "path": group[3]}
            if "0" not in cgroups or cgroups["0"]["controllers"]:
                raise ValueError("Actual unified process cgroup observation is required")
            result[role] = {"pid": int(match[1]), "ppid": int(fields[1]), "pgrp": int(fields[2]),
                            "session": int(fields[3]), "start_ticks": fields[19], "argv": argv,
                            "uid": int(uid.split()[0]), "cgroups": cgroups}
        console, adbd = result["console"], result["adbd"]
        adbd_group = adbd["cgroups"]["0"]["path"]
        if (console["ppid"] != 1 or console["pid"] <= 1 or
                not re.fullmatch(r".*/uid_[0-9]+/pid_" + str(adbd["pid"]), adbd_group)):
            raise ValueError("Actual init-console and adbd service groups are not established")
        for role in ("console", "session", "logger"):
            group = result[role]["cgroups"]["0"]["path"]
            if (group == adbd_group or group.startswith(adbd_group + "/")
                    or result[role]["cgroups"] != console["cgroups"] or result[role]["uid"] != console["uid"]):
                raise ValueError("Logger is not in the distinct actual init-console cgroup")
        session, logger = result["session"], result["logger"]
        if (session["pid"] != session["session"] or session["pgrp"] != session["session"]
                or logger["session"] != session["session"] or logger["pgrp"] != session["session"]
                or logger["ppid"] != session["pid"]):
            raise ValueError("Device logger does not belong to its independent session")
    return result


def same_device_session(before: dict, after: dict) -> None:
    # The detached shell may be reparented to init after the launch shell exits;
    # its PID, birth time, session and literal command must remain identical.
    for role in ("console", "session", "logger"):
        for key in ("pid", "pgrp", "session", "start_ticks", "argv", "uid", "cgroups"):
            if before[role][key] != after[role][key]:
                raise ValueError("Device logger process identity changed: " + role + ":" + key)
    for name in DEVICE_LOG_FILES:
        for key in ("device", "inode", "mode"):
            if before["files"][name][key] != after["files"][name][key]:
                raise ValueError("Device logger file identity changed: " + name)
        if after["files"][name]["bytes"] < before["files"][name]["bytes"]:
            raise ValueError("Device logger file was truncated: " + name)
    if before["script_sha256"] != after["script_sha256"]:
        raise ValueError("Device logger source changed")


def device_marker_line(raw: bytes, marker: str) -> bytes | None:
    pattern = re.compile(rb"^(?:[0-9]{4}-)?[0-9]{2}-[0-9]{2} [0-9:.]+\s+[0-9]+\s+[0-9]+\s+I\s+"
                         + DEVICE_LOG_TAG.encode() + rb"\s*:\s?" + re.escape(marker.encode()) + rb"$")
    matches = [line for line in raw.splitlines() if pattern.fullmatch(line)]
    if len(matches) > 1:
        raise ValueError("Device continuity marker is not unique")
    return matches[0] if matches else None


class DeviceLogSession:
    """A real detached logcat, with raw command receipts and no reconnect path."""

    def __init__(self, out: Path, adb: str, serial: str, remote: str, timeout: float = 30):
        if not DEVICE_LOG_PATH.fullmatch(remote) or not re.fullmatch(r"emulator-[0-9]+", serial):
            raise ValueError("Expected one private logger on an exact emulator")
        if out.exists():
            raise ValueError("Refusing to overwrite a device logger observation phase")
        self.out, self.remote = out, remote
        self.recorder = Recorder(out, adb, serial)
        self.deadline = time.monotonic() + timeout
        self.records = []

    def run(self, name: str, arguments: list[str], *, direct: bool = False,
            accept: tuple[int, ...] = (0,)) -> dict:
        remaining = self.deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("Device logger observation deadline expired")
        method = self.recorder.run_adb if direct else self.recorder.run
        result = method(name, arguments, min(15, remaining))
        self.records.append({key: value for key, value in result.items() if key not in ("stdout", "stderr")})
        closed = (name == "root-request" and direct and arguments == ["root"] and expected_root_disconnect(result))
        if result["timed_out"] or result["returncode"] not in accept or (result["stderr"] and not closed):
            raise RuntimeError("Device logger command failed: " + name)
        return result

    def shell(self, name: str, script: str) -> dict:
        return self.run(name, ["sh", "-c", shlex.quote(script)])

    def snapshot(self, name: str, *, live: bool = True) -> tuple[dict, dict]:
        record = self.shell(name, device_snapshot_script(self.remote, live=live))
        return parse_device_snapshot(record["stdout"], self.remote, live=live), record

    def marker(self, name: str, marker: str, host_log: Path | None = None) -> dict:
        if not re.fullmatch(r"lumo-[0-9a-f]{32}-(start|end)", marker):
            raise ValueError("Invalid continuity marker")
        sent = self.run(name + "-write", ["log", "-p", "i", "-t", DEVICE_LOG_TAG, marker])
        while time.monotonic() < self.deadline:
            result = self.run(name + "-read", ["grep", "-F", marker, self.remote + "/logcat.stdout"], accept=(0, 1))
            device = device_marker_line((self.out / result["stdout_file"]).read_bytes(), marker)
            host = device_marker_line(host_log.read_bytes(), marker) if host_log is not None else device
            if device is not None and device == host:
                return {"value": marker, "line_hex": device.hex(), "sent": sent["started_at"],
                        "observed_at": result["finished_at"], "record": result["stdout_file"],
                        "host_overlap_observed": host_log is not None}
            time.sleep(min(.1, max(0, self.deadline - time.monotonic())))
        raise TimeoutError("Actual device and host continuity marker was not observed")

    def originals(self) -> dict:
        return {str(file.relative_to(self.out)): {"bytes": file.stat().st_size,
                "sha256": hashlib.sha256(file.read_bytes()).hexdigest()}
                for file in sorted((self.out / "commands").glob("*")) if file.is_file()}


LAUNCH_FAILURE_SECONDS = 8.0
LAUNCH_FAILURE_COMMAND_SECONDS = 2.0
LAUNCH_FAILURE_COMMAND_BYTES = 64 * 1024
LAUNCH_FAILURE_TOTAL_BYTES = 256 * 1024


def _launch_failure_read(out: Path, name: str, command: list[str],
                         deadline: float, maximum: int) -> dict:
    """Keep bounded original process output; never turn it into a launch result."""
    if not re.fullmatch(r"[a-z][a-z0-9-]*", name) or not 0 < maximum <= LAUNCH_FAILURE_COMMAND_BYTES:
        raise ValueError("Invalid bounded launch diagnostic request")
    if any((out / (name + suffix)).exists() or (out / (name + suffix)).is_symlink()
           for suffix in (".stdout", ".stderr", ".json")):
        raise ValueError("Refusing to replace a launch diagnostic original")
    record = {"command": command, "started_at": utc(), "returncode": None,
              "timed_out": False, "byte_limit_exceeded": False, "errors": [],
              "stdout_file": name + ".stdout", "stderr_file": name + ".stderr"}
    buffers = {"stdout": bytearray(), "stderr": bytearray()}
    process = None
    stop_at = min(deadline - .2, time.monotonic() + LAUNCH_FAILURE_COMMAND_SECONDS)
    cleanup_at = min(deadline, stop_at + .2)
    with selectors.DefaultSelector() as selector:
        try:
            if maximum <= 0 or time.monotonic() >= stop_at:
                raise TimeoutError("Launch diagnostic budget exhausted before command")
            process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, start_new_session=True, bufsize=0)
            for stream in ("stdout", "stderr"):
                pipe = getattr(process, stream)
                os.set_blocking(pipe.fileno(), False)
                selector.register(pipe, selectors.EVENT_READ, stream)
            while selector.get_map() or process.poll() is None:
                if time.monotonic() >= stop_at:
                    record["timed_out"] = True
                    break
                for key, _event in selector.select(min(.05, max(0, stop_at - time.monotonic()))):
                    remaining = maximum - sum(len(data) for data in buffers.values())
                    try:
                        data = os.read(key.fd, min(65536, remaining + 1))
                    except BlockingIOError:
                        continue
                    if not data:
                        selector.unregister(key.fileobj)
                    else:
                        buffers[key.data].extend(data[:remaining])
                        if len(data) > remaining:
                            record["byte_limit_exceeded"] = True
                            break
                if record["byte_limit_exceeded"]:
                    break
        except Exception as error:
            record["errors"].append(type(error).__name__ + ": " + str(error)[:1024])
            record["timed_out"] |= isinstance(error, TimeoutError)
        finally:
            if process is not None:
                try:
                    if process.poll() is None:
                        try:
                            os.killpg(process.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                    # Drain already available bytes after termination, within
                    # the same deadline/cap. A limited read is only a prefix.
                    while selector.get_map() and not record["byte_limit_exceeded"] and time.monotonic() < cleanup_at:
                        for key, _event in selector.select(min(.01, max(0, cleanup_at - time.monotonic()))):
                            remaining = maximum - sum(len(data) for data in buffers.values())
                            try:
                                data = os.read(key.fd, min(65536, remaining + 1))
                            except BlockingIOError:
                                continue
                            if not data:
                                selector.unregister(key.fileobj)
                            else:
                                buffers[key.data].extend(data[:remaining])
                                if len(data) > remaining:
                                    record["byte_limit_exceeded"] = True
                                    break
                    process.wait(timeout=max(0, cleanup_at - time.monotonic()))
                except Exception as error:
                    record["errors"].append(type(error).__name__ + ": " + str(error)[:1024])
                finally:
                    record["returncode"] = process.poll()
                    record["output_complete"] = not (selector.get_map() or record["timed_out"] or
                                                       record["byte_limit_exceeded"] or record["errors"])
                    for stream in ("stdout", "stderr"):
                        getattr(process, stream).close()
            else:
                record["output_complete"] = False
    record["files"] = {}
    for stream, data in buffers.items():
        with (out / record[stream + "_file"]).open("xb") as handle:
            handle.write(data)
        record["files"][stream] = {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
    record["finished_at"] = utc()
    with (out / (name + ".json")).open("x") as handle:
        json.dump(record, handle, indent=2)
        handle.write("\n")
    return record


def collect_launch_failure(session: DeviceLogSession) -> dict:
    """Read only this failed session's originals; success remains impossible."""
    remote = session.remote
    if not DEVICE_LOG_PATH.fullmatch(remote) or not re.fullmatch(r"emulator-[0-9]+", session.recorder.serial):
        raise ValueError("Invalid failed launch diagnostic identity")
    out = session.out / "launch-failure"
    out.mkdir(exist_ok=False)
    started = time.monotonic()
    deadline = started + LAUNCH_FAILURE_SECONDS
    report = {"schema": 1, "status": "DIAGNOSTIC_ONLY", "started_at": utc(),
              "remote": remote, "serial": session.recorder.serial, "commands": [], "errors": [],
              "budget_seconds": LAUNCH_FAILURE_SECONDS, "raw_byte_budget": LAUNCH_FAILURE_TOTAL_BYTES,
              "scope": "Failure-only read of original launch evidence. No launch, readiness or continuity acceptance."}
    commands = []
    for name in ("launch.stdout", "launch.stderr", "session.stdout", "session.stderr", "logcat.stderr"):
        path = remote + "/" + name
        script = "test ! -L " + remote + " && test -d " + remote + " && test ! -L " + path + " && test -f " + path + " && exec cat " + path
        commands.append((name.replace(".", "-"), script))
    state = ("printf '__reader_uid__\\n'; id; printf '__init_console__\\n'; getprop init.svc.console\n"
             "printf '__toybox_executable__\\n'; test -x /system/bin/toybox; printf '%s\\n' \"$?\"\n"
             "printf '__logcat_executable__\\n'; test -x /system/bin/logcat; printf '%s\\n' \"$?\"\n"
             "test ! -L " + remote + " && test -d " + remote + " || exit 95\n")
    for name in ("console.pid", "session.pid", "logger.pid", "ready", "logger.exit"):
        path = remote + "/" + name
        state += ("printf '__" + name + "__\\n'; test ! -L " + path + " && test -f " + path +
                  " && /system/bin/toybox head -c 128 " + path + "; printf '\\n'\n")
    commands.append(("state", state))
    used = 0
    try:
        for name, script in commands:
            if time.monotonic() >= deadline - .2 or used >= LAUNCH_FAILURE_TOTAL_BYTES:
                report["errors"].append("Diagnostic time or byte budget exhausted; remaining commands not attempted")
                break
            command = [session.recorder.adb, "-s", session.recorder.serial, "shell", "sh", "-c", shlex.quote(script)]
            record = _launch_failure_read(out, name, command, deadline,
                                          min(LAUNCH_FAILURE_COMMAND_BYTES, LAUNCH_FAILURE_TOTAL_BYTES - used))
            report["commands"].append(record)
            used += sum(file["bytes"] for file in record["files"].values())
    except Exception as error:
        report["errors"].append(type(error).__name__ + ": " + str(error)[:1024])
    report.update(finished_at=utc(), elapsed_seconds=time.monotonic() - started, raw_bytes=used,
                  all_commands_attempted=len(report["commands"]) == len(commands),
                  path=str(out.relative_to(session.out.parent)))
    with (out / "report.json").open("x") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")
    return report


def start_device_log(out: Path, framework_out: Path, serial: str) -> dict:
    if out.exists():
        raise ValueError("Refusing to replace device logger evidence")
    token = secrets.token_hex(16)
    remote = "/data/local/tmp/lumo-runtime-" + token
    session = DeviceLogSession(out / "start", adb_path(), serial, remote, timeout=45)
    value = {"schema": 1, "started_at": utc(), "remote": remote, "serial": serial,
             "adb": adb_path(), "token": token, "status": "FAIL", "errors": []}
    try:
        value["console_launch"] = CONSOLE.start(out / "console", device_logger_launch(remote).encode(), token, serial)
        launch_outputs = [session.run("launch-" + name, ["cat", remote + "/launch." + name])
                          for name in ("stdout", "stderr")]
        if any(record["stdout"] for record in launch_outputs):
            raise ValueError("Actual console launch program emitted output or errors")
        first, _ = session.snapshot("initial")
        value["initial"] = first
        value["marker"] = session.marker("start-marker", "lumo-" + token + "-start",
                                          framework_out / "logcat-all.stdout")
        prefix = session.run("prefix", ["cat", remote + "/logcat.stdout"])
        value["prefix"] = prefix["stdout_file"]
        second, _ = session.snapshot("before-root")
        same_device_session(first, second)
        value["before_root"] = second
        value["console_before_root"] = CONSOLE.observe(out / "console", "before-root")
        root = {"started_at": utc(), "requested": False}
        value["root"] = root
        uid = session.run("root-before-uid", ["id", "-u"])["stdout"].strip()
        if uid not in ("0", "2000"):
            raise ValueError("Unrecognized real emulator shell UID")
        root["uid_before"] = uid
        if uid != "0":
            root["requested"] = True
            command = session.run("root-request", ["root"], direct=True, accept=(0, 1))
            if (command["returncode"] == 1 and not expected_root_disconnect(command)) or "cannot run as root" in command["stdout"]:
                raise RuntimeError("The emulator did not accept the explicit root request")
            root["command"] = {key: item for key, item in command.items() if key not in ("stdout", "stderr")}
        session.run("root-wait", ["wait-for-device"], direct=True)
        root["uid_after"] = session.run("root-after-uid", ["id", "-u"])["stdout"].strip()
        root["boot_completed"] = session.run("root-boot", ["getprop", "sys.boot_completed"])["stdout"].strip()
        if root["uid_after"] != "0" or root["boot_completed"] != "1":
            raise ValueError("Root preparation lacks an actual UID0 and boot1")
        after, _ = session.snapshot("after-root")
        same_device_session(first, after)
        value["after_root"] = after
        value["console_after_root"] = CONSOLE.observe(out / "console", "after-root")
        root["finished_at"] = utc()
        value["status"] = "PASS"
    except (OSError, ValueError, RuntimeError, TimeoutError) as error:
        value["errors"].append(type(error).__name__ + ": " + str(error))
        if "console_launch" not in value:
            try:
                value["launch_failure_diagnostics"] = collect_launch_failure(session)
            except Exception as diagnostic_error:
                value["launch_failure_diagnostics"] = {"status": "INCOMPLETE", "error":
                    type(diagnostic_error).__name__ + ": " + str(diagnostic_error)[:1024]}
        raise
    finally:
        value.update(finished_at=utc(), records=session.records, files=session.originals())
        write_json(out / "start.json", value)
    return value


def observe_device_log(out: Path, label: str) -> dict:
    start = json.loads((out / "start.json").read_text())
    session = DeviceLogSession(out / label, start["adb"], start["serial"], start["remote"], timeout=10)
    value = {"started_at": utc(), "status": "FAIL"}
    try:
        snapshot, _ = session.snapshot("identity")
        same_device_session(start["initial"], snapshot)
        connection = CONSOLE.observe(out / "console", label)
        value.update(status="PASS", snapshot=snapshot, console_connection=connection)
        return value
    finally:
        value.update(finished_at=utc(), records=session.records, files=session.originals())
        write_json(out / (label + ".json"), value)


def finish_device_log(out: Path) -> dict:
    start = json.loads((out / "start.json").read_text())
    session = DeviceLogSession(out / "finish", start["adb"], start["serial"], start["remote"], timeout=45)
    value = {"schema": 1, "status": "FAIL", "started_at": utc(), "errors": []}
    try:
        before, _ = session.snapshot("before-stop")
        same_device_session(start["initial"], before)
        value["before_stop"] = before
        value["marker"] = session.marker("end-marker", "lumo-" + start["token"] + "-end")
        current, _ = session.snapshot("checked-stop-target")
        same_device_session(before, current)
        value["stop_target"] = current
        value["stop_requested_at"] = utc()
        session.run("stop", ["kill", "-TERM", str(current["logger"]["pid"])])
        while time.monotonic() < session.deadline:
            result = session.shell("exit", "if [ -s " + start["remote"] + "/logger.exit ]; then cat " + start["remote"] + "/logger.exit; fi")
            if result["stdout"].strip():
                if result["stdout"].strip() != "143":
                    raise ValueError("The original device logger did not stop by the requested TERM")
                value["exit_code"] = 143
                break
            time.sleep(min(.1, max(0, session.deadline - time.monotonic())))
        if "exit_code" not in value:
            raise TimeoutError("Device logger exit was not observed")
        stopped, _ = session.snapshot("stopped-files", live=False)
        value["stopped"] = stopped
        for name in DEVICE_LOG_FILES:
            if any(stopped["files"][name][key] != current["files"][name][key] for key in ("device", "inode", "mode")):
                raise ValueError("Stopped device log file changed identity")
            if stopped["files"][name]["bytes"] > 512 * 1024 * 1024:
                raise ValueError("Original device log exceeds the explicit 512MiB read bound; not truncated")
            result = session.run("original-" + name.replace(".", "-"), ["cat", start["remote"] + "/" + name])
            path = session.out / result["stdout_file"]
            if path.stat().st_size != stopped["files"][name]["bytes"]:
                raise ValueError("The complete original device file was not retrieved")
            value[name] = result["stdout_file"]
        final, _ = session.snapshot("files-after-read", live=False)
        if final != stopped:
            raise ValueError("Device originals changed during complete retrieval")
        value["console_finish"] = CONSOLE.finish(out / "console", start["token"], value["exit_code"])
        value["status"] = "PASS"
    except (OSError, ValueError, RuntimeError, TimeoutError) as error:
        value["errors"].append(type(error).__name__ + ": " + str(error))
        raise
    finally:
        value.update(finished_at=utc(), records=session.records, files=session.originals())
        write_json(out / "finish.json", value)
    return value


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
    parser.add_argument("--monitor-seconds", type=int, default=DEFAULT_MONITOR_SECONDS)
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-[0-9]+", args.serial):
        parser.error("Expected the exact emulator serial")
    if not 0 < args.stable_seconds < args.timeout <= 120 or args.minimum_samples < 3:
        parser.error("Readiness needs a positive bounded window and at least three observations")
    try:
        monitor_budget(args.monitor_seconds)
    except ValueError as error:
        parser.error(str(error))
    out = args.out.resolve()
    if args.mode == "start":
        start_monitor(out, args.serial, args.monitor_seconds)
    elif args.mode == "_monitor":
        return collect_monitor(out, args.serial, args.monitor_seconds)
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
