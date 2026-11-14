#!/usr/bin/env python3
"""Keep one private emulator init-console connection open through adb root.

This transport does not use adb, reconnect, change cgroups or change SELinux.
The caller supplies the fixed logger program; original input and every received
byte are retained. A dead channel is a failed observation, never a new session.
"""
from __future__ import annotations

import argparse
import base64
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import select
import socket
import stat
import struct
import subprocess
import sys
import time


PROTOCOL = "init-console-device-session-v2"
MAX_TRANSCRIPT_BYTES = 64 * 1024 * 1024
MAX_SECONDS = 7200


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def identity(data: bytes) -> dict:
    return {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def write_new(path: Path, value: dict) -> None:
    temporary = path.with_name(path.name + ".partial")
    with temporary.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, indent=2)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.link(temporary, path)
    temporary.unlink()


def read_json(path: Path) -> dict:
    if path.is_symlink() or not path.is_file():
        raise ValueError("Missing regular console receipt: " + path.name)
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("Duplicate console receipt field")
            result[key] = value
        return result
    value = json.loads(path.read_bytes(), object_pairs_hook=unique)
    if not isinstance(value, dict):
        raise ValueError("Console receipt must be an object")
    return value


def process_identity(pid: int) -> dict:
    if type(pid) is not int or pid <= 1:
        raise ValueError("Invalid console process PID")
    fields = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
    if len(fields) < 20 or fields[0] in ("Z", "X", "x"):
        raise ValueError("Console process is absent or dead")
    argv = Path(f"/proc/{pid}/cmdline").read_bytes().decode().rstrip("\0").split("\0")
    return {"pid": pid, "start_ticks": fields[19], "argv": argv,
            "executable": str(Path(f"/proc/{pid}/exe").resolve(strict=True))}


def socket_state(path: Path) -> dict:
    parent = path.parent
    if path != path.absolute() or parent.is_symlink() or parent.resolve(strict=True) != parent:
        raise ValueError("Console channel must have its exact private absolute path")
    p = parent.stat()
    if not stat.S_ISDIR(p.st_mode) or stat.S_IMODE(p.st_mode) != 0o700 or p.st_uid != os.getuid():
        raise ValueError("Console channel directory is not private to this runner")
    s = path.lstat()
    if not stat.S_ISSOCK(s.st_mode) or s.st_uid != os.getuid():
        raise ValueError("Console channel is not this runner's Unix socket")
    return {"path": str(path), "device": s.st_dev, "inode": s.st_ino,
            "mode": s.st_mode, "uid": s.st_uid, "parent_device": p.st_dev,
            "parent_inode": p.st_ino, "parent_mode": p.st_mode}


def prepare(path: Path) -> dict:
    run, attempt = os.environ.get("GITHUB_RUN_ID", ""), os.environ.get("GITHUB_RUN_ATTEMPT", "")
    if not re.fullmatch(r"[1-9][0-9]*", run) or not re.fullmatch(r"[1-9][0-9]*", attempt):
        raise ValueError("Actual Actions run and attempt are required for console preparation")
    temp = Path(os.environ["RUNNER_TEMP"]).resolve(strict=True)
    expected = temp / f"lumo-serial-{run}-{attempt}" / "console.sock"
    if path != expected or len(os.fsencode(path)) > 100:
        raise ValueError("Unexpected or overlong private console socket path")
    path.parent.mkdir(mode=0o700)
    if stat.S_IMODE(path.parent.stat().st_mode) != 0o700:
        raise ValueError("Console directory permissions changed")
    result = {"schema": 1, "prepared_at": utc(), "run_id": run, "run_attempt": attempt,
              "socket": str(path), "emulator_option": "unix:" + str(path) + ",server,nowait",
              "uid": os.getuid(), "source": identity(Path(__file__).read_bytes())}
    write_new(path.parent / "prepare.json", result)
    return result


def check(path: Path) -> dict:
    preparation = read_json(path.parent / "prepare.json")
    if (preparation.get("socket") != str(path) or preparation.get("run_id") != os.environ.get("GITHUB_RUN_ID")
            or preparation.get("run_attempt") != os.environ.get("GITHUB_RUN_ATTEMPT")
            or preparation.get("source") != identity(Path(__file__).read_bytes())):
        raise ValueError("Console preparation is not bound to this actual run/source")
    return {"preparation": preparation, "socket": socket_state(path)}


def command_bytes(program: bytes, token: str) -> bytes:
    if not re.fullmatch(r"[0-9a-f]{32}", token) or not program or b"\0" in program:
        raise ValueError("Invalid literal console program or nonce")
    payload = base64.b64encode(program).decode()
    # One physical line: echoed input cannot be an exact nonce-delimited output
    # line. The shell PID expands in the interactive init console, not adb.
    command = (f"printf '\\nLUMO_CONSOLE_BEGIN_{token}\\n'; "
               f"printf '%s' '{payload}' | /system/bin/toybox base64 -d | "
               "/system/bin/sh -s -- \"$$\"; lumo_console_rc=$?; "
               f"printf '\\nLUMO_CONSOLE_END_{token}:%s\\n' \"$lumo_console_rc\"\n")
    if len(command.encode()) > 4095:
        raise ValueError("Console command exceeds the conservative canonical line limit")
    return command.encode()


def launch_frame(raw: bytes, token: str) -> dict | None:
    begin = ("LUMO_CONSOLE_BEGIN_" + token).encode()
    end = re.compile(("LUMO_CONSOLE_END_" + token + r":([0-9]+)").encode())
    starts, ends, offset = [], [], 0
    # Interactive mksh redraws echoed input with bare CR/backspace bytes.
    # Only LF terminates an acknowledgement line; keep the original bytes and
    # offsets intact, and leave an incomplete final line unacknowledged.
    for part in raw.split(b"\n")[:-1]:
        line = part + b"\n"
        text = line.rstrip(b"\r\n")
        if text == begin:
            starts.append((offset, offset + len(line)))
        match = end.fullmatch(text)
        if match:
            ends.append((offset, offset + len(line), int(match[1])))
        offset += len(line)
    if len(starts) > 1 or len(ends) > 1:
        raise ValueError("Ambiguous console launch acknowledgement")
    if not starts or not ends:
        return None
    if ends[0][0] < starts[0][1] or ends[0][2] != 0:
        raise ValueError("Console logger launch failed")
    payload = raw[starts[0][1]:ends[0][0]]
    # QEMU may multiplex kernel/logcat onto this terminal. Preserve these bytes
    # as part of the exact frame; the fixed program's own launch.stdout/stderr
    # are separately retrieved and required empty by the device verifier.
    return {"begin_offset": starts[0][0], "end_offset": ends[0][1], "returncode": 0,
            "interleaved_output": identity(payload), "acknowledged_prefix": identity(raw[:ends[0][1]])}


def validate_peer(peer: dict, path: Path, uid: int) -> None:
    option = "unix:" + str(path) + ",server,nowait"
    if (type(peer.get("pid")) is not int or peer["pid"] <= 1 or peer.get("uid") != uid
            or not re.fullmatch(r"[0-9]+", peer.get("start_ticks", ""))
            or not re.fullmatch(r"qemu-system-[A-Za-z0-9_-]+", Path(peer.get("executable", "")).name)
            or peer.get("argv", []).count(option) != 1):
        raise ValueError("Unix socket peer is not the actual emulator with the exact console option")


def peer_identity(channel: socket.socket, path: Path) -> dict:
    pid, uid, gid = struct.unpack("3i", channel.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
    process = process_identity(pid)
    validate_peer({**process, "uid": uid}, path, os.getuid())
    return {**process, "uid": uid, "gid": gid}


def collect(out: Path) -> int:
    config = read_json(out / "config.json")
    path = Path(config["socket"])
    program = (out / "program.sh").read_bytes()
    command = command_bytes(program, config["token"])
    if config["program"] != identity(program) or (out / "command.stdin").read_bytes() != command:
        raise ValueError("Console input program changed before execution")
    deadline = time.monotonic() + MAX_SECONDS
    launch_deadline = time.monotonic() + 20
    result = {"schema": 1, "status": "FAIL", "started_at": utc(), "token": config["token"],
              "connections": 0, "stop_requested": False, "errors": []}
    channel = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        state = socket_state(path)
        channel.settimeout(5)
        channel.connect(str(path))
        result["connections"] = 1
        if socket_state(path) != state:
            raise ValueError("Console socket changed during connection")
        peer = peer_identity(channel, path)
        result.update(socket=state, peer=peer)
        channel.sendall(command)
        result["sent_at"] = utc()
        channel.setblocking(False)
        raw = bytearray()
        acknowledged = False
        with (out / "transcript.stdout").open("xb") as stream:
            while True:
                if time.monotonic() >= deadline:
                    raise TimeoutError("Persistent console observation budget exhausted")
                readable, _, _ = select.select([channel], [], [], .1)
                if readable:
                    data = channel.recv(65536)
                    if not data:
                        raise RuntimeError("Original console channel ended before its requested close")
                    stream.write(data)
                    stream.flush()
                    raw.extend(data)
                    if len(raw) > MAX_TRANSCRIPT_BYTES:
                        raise ValueError("Console transcript exceeds its explicit preservation bound")
                if not acknowledged:
                    frame = launch_frame(bytes(raw), config["token"])
                    if frame is not None:
                        write_new(out / "launch.json", {"schema": 1, "status": "PASS",
                                  "observed_at": utc(), "sent_at": result["sent_at"],
                                  "socket": state, "peer": peer, "frame": frame})
                        acknowledged = True
                    elif time.monotonic() >= launch_deadline:
                        raise TimeoutError("Actual console launch acknowledgement was not received")
                request = out / "stop-request.json"
                if request.exists():
                    stop = read_json(request)
                    if not acknowledged or stop.get("token") != config["token"] or stop.get("logger_exit") != 143:
                        raise ValueError("Unbound or premature console close request")
                    if process_identity(peer["pid"]) != {key: peer[key] for key in ("pid", "start_ticks", "argv", "executable")}:
                        raise ValueError("Emulator process identity changed")
                    if socket_state(path) != state:
                        raise ValueError("Console socket identity changed before close")
                    result.update(status="PASS", stop_requested=True, stop_request=stop)
                    break
    except (OSError, ValueError, RuntimeError, TimeoutError) as error:
        result["errors"].append(type(error).__name__ + ": " + str(error))
    finally:
        channel.close()
        result["finished_at"] = utc()
        result["source"] = identity(Path(__file__).read_bytes())
        write_new(out / "finished.json", result)
    return 0 if result["status"] == "PASS" else 1


def start(out: Path, program: bytes, token: str, serial: str) -> dict:
    path = Path(os.environ["LUMO_ANDROID_CONSOLE_SOCKET"])
    check(path)
    out.mkdir(mode=0o700, parents=False)
    (out / "prepare.json").write_bytes((path.parent / "prepare.json").read_bytes())
    (out / "program.sh").write_bytes(program)
    (out / "command.stdin").write_bytes(command_bytes(program, token))
    write_new(out / "config.json", {"schema": 1, "socket": str(path), "serial": serial,
              "token": token, "program": identity(program), "preparation": identity((out / "prepare.json").read_bytes())})
    command = [sys.executable, str(Path(__file__).resolve()), "_hold", "--out", str(out.resolve())]
    with (out / "holder.stdout").open("xb") as stdout, (out / "holder.stderr").open("xb") as stderr:
        started = utc()
        process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr, start_new_session=True)
    actual = process_identity(process.pid)
    if actual["argv"] != command:
        raise ValueError("Console holder did not execute the exact local helper command")
    write_new(out / "process.json", {**actual, "command": command, "started_at": started})
    deadline = time.monotonic() + 22
    while time.monotonic() < deadline:
        if (out / "finished.json").exists() or process.poll() is not None:
            raise RuntimeError("Persistent init-console transport failed before launch completion")
        if (out / "launch.json").exists():
            return observe(out, "launched")
        time.sleep(.05)
    raise TimeoutError("Persistent init-console launcher did not acknowledge the fixed program")


def observe(out: Path, label: str) -> dict:
    if not re.fullmatch(r"[a-z][a-z-]*", label):
        raise ValueError("Invalid console observation label")
    process, launch = read_json(out / "process.json"), read_json(out / "launch.json")
    actual = process_identity(process["pid"])
    if actual != {key: process[key] for key in actual} or launch.get("status") != "PASS" or (out / "finished.json").exists():
        raise ValueError("Original persistent console connection is no longer live")
    peer = process_identity(launch["peer"]["pid"])
    if peer != {key: launch["peer"][key] for key in peer} or socket_state(Path(launch["socket"]["path"])) != launch["socket"]:
        raise ValueError("Original emulator console endpoint changed")
    with (out / "transcript.stdout").open("rb") as stream:
        before = os.fstat(stream.fileno())
        raw = stream.read(before.st_size)
        after = os.fstat(stream.fileno())
    if len(raw) != before.st_size or (before.st_dev, before.st_ino) != (after.st_dev, after.st_ino) or after.st_size < before.st_size:
        raise ValueError("Console transcript changed identity or was truncated")
    result = {"observed_at": utc(), "label": label, "holder": actual, "peer": peer,
              "socket": launch["socket"], "transcript_prefix": identity(raw)}
    directory = out / "observations"
    directory.mkdir(exist_ok=True)
    write_new(directory / (label + ".json"), result)
    return result


def finish(out: Path, token: str, logger_exit: int) -> dict:
    observe(out, "before-close")
    write_new(out / "stop-request.json", {"requested_at": utc(), "token": token, "logger_exit": logger_exit})
    deadline = time.monotonic() + 5
    while not (out / "finished.json").exists() and time.monotonic() < deadline:
        time.sleep(.05)
    result = read_json(out / "finished.json")
    if result.get("status") != "PASS" or result.get("stop_requested") is not True or result.get("errors"):
        raise ValueError("Console channel did not remain uninterrupted until its requested close")
    return result


def verify(out: Path, program: bytes, token: str, serial: str, labels: tuple[str, ...]) -> dict:
    config, preparation, process, launch, finished, stop = [read_json(out / name) for name in
        ("config.json", "prepare.json", "process.json", "launch.json", "finished.json", "stop-request.json")]
    raw = (out / "transcript.stdout").read_bytes()
    source = identity(Path(__file__).read_bytes())
    if (config.get("program") != identity(program) or (out / "program.sh").read_bytes() != program
            or (out / "command.stdin").read_bytes() != command_bytes(program, token)
            or config.get("token") != token or config.get("serial") != serial
            or config.get("preparation") != identity((out / "prepare.json").read_bytes())
            or preparation.get("source") != source or finished.get("source") != source
            or preparation.get("socket") != config.get("socket")
            or preparation.get("emulator_option") != "unix:" + config["socket"] + ",server,nowait"):
        raise ValueError("Console source, exact input, run preparation or device binding differs")
    validate_peer(launch["peer"], Path(config["socket"]), preparation["uid"])
    state = launch["socket"]
    if (state.get("path") != config["socket"] or state.get("uid") != preparation["uid"]
            or not stat.S_ISSOCK(state["mode"]) or not stat.S_ISDIR(state["parent_mode"])
            or stat.S_IMODE(state["parent_mode"]) != 0o700
            or process.get("command") != process.get("argv")
            or len(process["argv"]) != 5 or Path(process["argv"][1]).name != Path(__file__).name
            or process["argv"][2:4] != ["_hold", "--out"]):
        raise ValueError("Console private socket or fixed holder process binding changed")
    if (launch.get("status") != "PASS" or launch.get("frame") != launch_frame(raw, token)
            or finished.get("status") != "PASS" or finished.get("errors")
            or type(finished.get("connections")) is not int or finished["connections"] != 1 or finished.get("stop_requested") is not True
            or stop.get("token") != token or stop.get("logger_exit") != 143
            or finished.get("stop_request") != stop or finished.get("peer") != launch.get("peer")
            or finished.get("socket") != launch.get("socket")):
        raise ValueError("Console session is incomplete, ambiguous or was reconnected")
    if any((out / name).read_bytes() for name in ("holder.stdout", "holder.stderr")):
        raise ValueError("Console holder emitted unexpected output or errors")
    directory = out / "observations"
    if {p.name for p in directory.iterdir()} != {label + ".json" for label in labels}:
        raise ValueError("Console observations are incomplete or duplicated")
    times = [process["started_at"], finished["started_at"], launch["sent_at"], launch["observed_at"]]
    observations = []
    previous_size = launch["frame"]["end_offset"]
    for label in labels:
        observed = read_json(directory / (label + ".json"))
        size = observed["transcript_prefix"]["bytes"]
        if type(size) is not int or not previous_size <= size <= len(raw):
            raise ValueError("Console prefix length is absent, shrinking or beyond the complete original")
        previous_size = size
        if (observed.get("label") != label or observed.get("holder") != {key: process[key] for key in ("pid", "start_ticks", "argv", "executable")}
                or observed.get("peer") != {key: launch["peer"][key] for key in ("pid", "start_ticks", "argv", "executable")}
                or observed.get("socket") != launch["socket"]
                or identity(raw[:observed["transcript_prefix"]["bytes"]]) != observed["transcript_prefix"]):
            raise ValueError("Console identity or original transcript prefix changed")
        times.append(observed["observed_at"])
        observations.append(observed)
    times += [stop["requested_at"], finished["finished_at"]]
    stamps = [datetime.fromisoformat(value) for value in times]
    if any(value.tzinfo is None for value in stamps) or any(a > b for a, b in zip(stamps, stamps[1:])):
        raise ValueError("Console observation chronology is invalid")
    files = {}
    for path in sorted(out.rglob("*")):
        if path.is_symlink():
            raise ValueError("Console evidence must not contain symlinks")
        if path.is_file():
            files[str(path.relative_to(out))] = identity(path.read_bytes())
    return {"status": "PASS", "protocol": PROTOCOL, "launch": launch, "finished": finished,
            "observations": observations, "files": files, "scope": "One observed init-console transport; guest process and all-buffer continuity are verified separately."}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("prepare", "check", "_hold"))
    parser.add_argument("--socket", type=Path)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    if args.mode in ("prepare", "check"):
        if args.socket is None or args.out is not None:
            parser.error("prepare/check requires only --socket")
        print(json.dumps(prepare(args.socket) if args.mode == "prepare" else check(args.socket)))
        return 0
    if args.out is None or args.socket is not None:
        parser.error("_hold requires only --out")
    return collect(args.out)


if __name__ == "__main__":
    raise SystemExit(main())
