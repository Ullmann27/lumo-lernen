#!/usr/bin/env python3
"""Run one native probe and reject runtime faults even if Godot exits zero."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

FAULT = re.compile(r"SCRIPT ERROR:|Parse Error:|Compile Error:|ERROR:.*p_size")


def stop(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def run(command: list[str], path: Path, timeout: float) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    process = None
    offset = 0
    tail = ""
    failure = None
    deadline = time.monotonic() + timeout
    with path.open("wb") as output:
        try:
            process = subprocess.Popen(
                command, stdout=output, stderr=subprocess.STDOUT,
                start_new_session=True,
            )
            while True:
                with path.open("rb") as source:
                    source.seek(offset)
                    new = source.read()
                offset += len(new)
                text = new.decode("utf-8", errors="replace")
                if text:
                    sys.stdout.write(text)
                    sys.stdout.flush()
                scanned = tail + text
                if FAULT.search(scanned):
                    failure = "Godot reported a runtime, parser, compiler or invalid font error"
                tail = scanned[-2048:]
                if failure:
                    stop(process)
                    break
                if process.poll() is not None:
                    break
                if time.monotonic() >= deadline:
                    failure = f"Probe exceeded its {timeout:g} second limit"
                    stop(process)
                    break
                time.sleep(0.15)
            code = process.wait()
        finally:
            if process is not None:
                stop(process)
    # The child may have written its final line between the last read and exit.
    with path.open("rb") as source:
        source.seek(offset)
        remaining = source.read().decode("utf-8", errors="replace")
    if remaining:
        sys.stdout.write(remaining)
        sys.stdout.flush()
    if FAULT.search(tail + remaining):
        failure = "Godot reported a runtime, parser, compiler or invalid font error"
    if failure:
        print(f"::error::{failure}; complete log: {path}", file=sys.stderr)
        return 1
    return code if code >= 0 else 128 - code


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=float, required=True)
    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("a probe command is required after --")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    return run(command, args.log, args.timeout)


if __name__ == "__main__":
    raise SystemExit(main())
