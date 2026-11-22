"""Tap each real course card, keep crash logs and inspect the running game on Android."""
import io
import hashlib
import json
import re
import subprocess
import sys
import time
import traceback
from collections import deque
from pathlib import Path

from PIL import Image

from rooted_emulator import ensure_rooted_emulator
from emulator_diagnostics import FATAL

OUT = Path("course-evidence")
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
ACTIVITY = "dev.ullmann.lumo.lumo_lernen.LumoGameActivity"
COURSES = ["dschungelherz", "zauberwald", "sonnenhafen"]


def captured_adb(*args, binary=False, timeout=35, run=None):
    """Keep both original streams, including partial output on an ADB failure."""
    command = ["adb", *args]
    result = (run or subprocess.run)(command, capture_output=True,
                                    text=not binary, timeout=timeout)
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, command,
                                            output=result.stdout, stderr=result.stderr)
    return result


def adb(*args, binary=False, timeout=35):
    return captured_adb(*args, binary=binary, timeout=timeout).stdout


def error_details(error):
    detail = {"type": type(error).__name__, "message": str(error),
              "traceback": "".join(traceback.format_exception(type(error), error, error.__traceback__))}
    if isinstance(error, (subprocess.CalledProcessError, subprocess.TimeoutExpired)):
        command = error.cmd
        detail["command"] = list(command) if not isinstance(command, str) else command
        detail["return_code"] = getattr(error, "returncode", None)
        if isinstance(error, subprocess.TimeoutExpired):
            detail["timeout_seconds"] = error.timeout
    return detail


def save_stream(path, output):
    data = output if isinstance(output, bytes) else (output or "").encode("utf-8")
    path.write_bytes(data)
    return {"file": path.name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
            "available": output is not None}


def retryable_diagnostic_error(error):
    # Run 45067933161 recorded rc255 but retained neither output stream. It
    # does not establish whether the transport or the log buffer caused it.
    # Retrying these read-only queries never restarts adbd or clears logcat.
    if isinstance(error, subprocess.TimeoutExpired):
        return True
    if not isinstance(error, subprocess.CalledProcessError):
        return False
    if error.returncode == 255:
        return True
    output = "\n".join(value.decode("utf-8", errors="replace")
                       if isinstance(value, bytes) else value or ""
                       for value in (error.stdout, error.stderr))
    return error.returncode == 1 and re.search(
        r"device offline|device ['\"]?[^\n]+['\"]? not found|no devices/emulators found|"
        r"connection reset|broken pipe|protocol fault|transport[^\n]*closed|error: closed",
        output, re.IGNORECASE) is not None


def collect_adb_evidence(name, kind, arguments, *, timeout=65, attempts=3,
                         clock=None, sleep=None):
    """Bound retries and retain every stdout/stderr before accepting final bytes."""
    if not 1 <= attempts <= 3 or not 1 <= timeout <= 90:
        raise ValueError("Diagnostic evidence requires 1–3 attempts and a 1–90 second budget")
    clock, sleep = clock or time.monotonic, sleep or time.sleep
    began = clock()
    deadline = began + timeout
    report = {"status": "FAIL", "command": ["adb", *arguments], "attempts": [],
              "scope": "Read-only evidence collection; rc255 cause remains unclassified."}
    target = OUT / f"{name}-{kind}.txt"
    target.unlink(missing_ok=True)
    last_error = None
    for attempt in range(1, attempts + 1):
        remaining = deadline - clock()
        if remaining <= 0:
            last_error = TimeoutError("Diagnostic evidence deadline expired")
            break
        output = stderr = None
        error = None
        try:
            completed = captured_adb(*arguments, timeout=min(20, remaining))
            output, stderr = completed.stdout, completed.stderr
            if clock() > deadline:
                raise TimeoutError("Diagnostic evidence command exceeded its deadline")
            if not output or not output.strip():
                raise RuntimeError("Required diagnostic output is empty")
        except Exception as caught:
            error = caught
            if isinstance(caught, (subprocess.CalledProcessError, subprocess.TimeoutExpired)):
                output, stderr = caught.stdout, caught.stderr
        record = {"attempt": attempt, "status": "FAIL" if error else "PASS",
                  "elapsed_seconds": round(clock() - began, 3),
                  "stdout": save_stream(OUT / f"{name}-{kind}-attempt-{attempt}-stdout.txt", output),
                  "stderr": save_stream(OUT / f"{name}-{kind}-attempt-{attempt}-stderr.txt", stderr)}
        if error is not None:
            record["error"] = error_details(error)
        else:
            record["return_code"] = 0
        report["attempts"].append(record)
        (OUT / f"{name}-{kind}-attempts.json").write_text(json.dumps(report, indent=2) + "\n")
        if error is None:
            save_stream(target, output)
            report["status"] = "PASS"
            report["file"] = target.name
            (OUT / f"{name}-{kind}-attempts.json").write_text(json.dumps(report, indent=2) + "\n")
            return report
        last_error = error
        if not retryable_diagnostic_error(error) or attempt == attempts:
            break
        print(name, kind, "diagnostic retry", attempt, str(error), flush=True)
        remaining = deadline - clock()
        if remaining <= 0:
            break
        sleep(min(float(attempt), remaining))
    report["error"] = error_details(last_error)
    (OUT / f"{name}-{kind}-attempts.json").write_text(json.dumps(report, indent=2) + "\n")
    raise RuntimeError(f"Required {kind} evidence was not collected: {last_error}") from last_error


def validate_course_logs(name, require_movement_log, evidence):
    logs = (OUT / evidence["file"]).read_text(errors="replace")
    markers = ["[LumoRun] ready", f"[LumoRun] course {name}:"]
    if require_movement_log:
        markers.append(f"[LumoRun] running {name} ")
    if any(marker not in logs for marker in markers):
        raise RuntimeError("Required course/movement markers are absent from the saved logcat")
    # A later successful read must not erase a native error from a failed,
    # partially returned logcat. Both complete and partial streams remain evidence.
    fatal = []
    for attempt in evidence["attempts"]:
        text = (OUT / attempt["stdout"]["file"]).read_text(errors="replace")
        fatal.extend(line for line in text.splitlines() if re.search(FATAL, line))
    if fatal:
        (OUT / f"{name}-native-errors.txt").write_text("\n".join(fatal) + "\n")
        raise RuntimeError("Native/engine errors appeared in retained course logcat")


def strict_adb(*args, timeout=35, run=subprocess.run):
    """ADB call in the error format the shared root-readiness helper recognises.

    `adb root` restarts adbd; right after boot the caller often loses its
    transport and adb prints "unable to connect for root: closed" (rc 1)
    although the restart is accepted (run 44476731175). The helper treats
    exactly that response as recoverable and then proves UID 0 and boot 1.
    """
    command = ("adb", *args)
    result = run(list(command), capture_output=True, text=True, timeout=timeout)
    output = (result.stdout or "") + (result.stderr or "")
    if result.returncode != 0:
        raise RuntimeError(f"Command failed ({result.returncode}): {command!r}\n{output.strip()}")
    return output


def capture(path):
    data = adb("exec-out", "screencap", "-p", binary=True)
    image = Image.open(io.BytesIO(data)).convert("RGB")
    path.write_bytes(data)
    return image


def starts(image):
    # The three primary Los! buttons have solid gold faces. Ignore text, thin
    # borders and scenery by measuring the size and fill of each connected area.
    small = image.resize((image.width // 3, image.height // 3))
    pixels = small.load()
    points = {(x, y) for y in range(small.height) for x in range(small.width)
              if all(abs(a-b) <= 13 for a, b in zip(pixels[x, y], (255, 215, 94)))}
    buttons = []
    while points:
        x, y = points.pop()
        queue = deque([(x, y)])
        left = right = x
        top = bottom = y
        area = 0
        while queue:
            x, y = queue.popleft()
            left, right = min(left, x), max(right, x)
            top, bottom = min(top, y), max(bottom, y)
            area += 1
            for pos in ((x-1,y), (x+1,y), (x,y-1), (x,y+1)):
                if pos in points:
                    points.remove(pos)
                    queue.append(pos)
        width, height = right-left+1, bottom-top+1
        if width >= 24 and height >= 8 and width > 1.45 * height and area >= width * height * .64:
            buttons.append(((left+right)*3//2, (top+bottom)*3//2))
    if len(buttons) != 3:
        return []
    horizontal = max(x for x, y in buttons)-min(x for x, y in buttons) > max(y for x, y in buttons)-min(y for x, y in buttons)
    return sorted(buttons, key=lambda p: p[0] if horizontal else p[1])


def course(index, name, require_movement_log):
    adb("shell", "am", "force-stop", PACKAGE)
    adb("logcat", "-c")
    # The emulator runs adbd as root so the real non-exported activity stays private.
    options = json.dumps({"scene":"run", "game":"run", "grade":1}, separators=(",", ":"))
    result = adb("shell", f"am start -W -n {PACKAGE}/{ACTIVITY} --es lumoLaunchOptions '{options}'")
    if "Status: ok" not in result or "Error" in result:
        raise RuntimeError(result)
    until = time.monotonic() + 100
    while time.monotonic() < until:
        if "[LumoRun] ready" in adb("logcat", "-d", "-s", "godot"):
            buttons = starts(capture(OUT / f"{name}-selection.png"))
            if buttons:
                break
        time.sleep(1)
    else:
        capture(OUT / f"{name}-no-menu.png")
        raise RuntimeError("Three visible course start buttons were not found")
    print(name, "real touch", buttons[index], flush=True)
    adb("shell", "input", "tap", *map(str, buttons[index]))
    until = time.monotonic() + 140
    while time.monotonic() < until:
        logs = adb("logcat", "-d", "-s", "godot")
        if "FATAL" in logs or not adb("shell", "pidof", PACKAGE + ":lumo_game").strip():
            raise RuntimeError("Native game exited")
        if f"[LumoRun] course {name}:" in logs and (not require_movement_log or f"[LumoRun] running {name} " in logs):
            break
        time.sleep(1)
    else:
        raise RuntimeError("Course did not reach play")
    a = capture(OUT / f"{name}-play-1.png").resize((48,32))
    time.sleep(4)
    b = capture(OUT / f"{name}-play-2.png").resize((48,32))
    foreground = adb("shell", "dumpsys", "activity", "activities")
    if not any(ACTIVITY in line and re.search(r"mResumedActivity|topResumedActivity", line) for line in foreground.splitlines()):
        raise RuntimeError("Native activity left the foreground")
    if a.tobytes() == b.tobytes():
        raise RuntimeError("Rendered gameplay stayed frozen")
    print(name, "gameplay checks complete; collecting required logs", flush=True)


def run_courses(require_movement_log):
    """Observe all three courses; diagnostics cannot replace the primary failure."""
    results = []
    for i, name in enumerate(COURSES):
        record = {"course": name, "status": "FAIL", "gameplay_status": "FAIL",
                  "primary_failure": None, "evidence": {}, "evidence_failures": []}
        try:
            course(i, name, require_movement_log)
            record["gameplay_status"] = "PASS"
        except Exception as error:
            record["primary_failure"] = error_details(error)
            print(name, "gameplay failed", str(error), flush=True)
            if isinstance(error, (subprocess.CalledProcessError, subprocess.TimeoutExpired)):
                try:
                    record["primary_failure"]["stdout"] = save_stream(
                        OUT / f"{name}-primary-stdout.txt", error.stdout)
                    record["primary_failure"]["stderr"] = save_stream(
                        OUT / f"{name}-primary-stderr.txt", error.stderr)
                except OSError as storage_error:
                    record["evidence_failures"].append(
                        {"kind": "primary-stream-storage", **error_details(storage_error)})
        # Each collector is independent. In particular, failed logcat must not
        # prevent exit-info collection or the observation of the next course.
        for kind, arguments in (
                ("logcat", ("logcat", "-b", "all", "-d")),
                ("exit-info", ("shell", "dumpsys", "activity", "exit-info", PACKAGE))):
            try:
                evidence = collect_adb_evidence(name, kind, arguments)
                record["evidence"][kind] = evidence
                if kind == "logcat" and record["gameplay_status"] == "PASS":
                    validate_course_logs(name, require_movement_log, evidence)
            except Exception as error:
                record["evidence_failures"].append({"kind": kind, **error_details(error)})
                print(name, kind, "evidence failed", str(error), flush=True)
        if record["gameplay_status"] == "PASS" and not record["evidence_failures"]:
            record["status"] = "PASS"
        try:
            (OUT / f"{name}-probe.json").write_text(json.dumps(record, indent=2) + "\n")
        except OSError as storage_error:
            record["status"] = "FAIL"
            record["evidence_failures"].append({"kind": "result-storage", **error_details(storage_error)})
        results.append(record)
        print(name, "passed" if record["status"] == "PASS" else "failed", flush=True)
    result = {"status": "PASS" if all(row["status"] == "PASS" for row in results) else "FAIL",
              "movement_log_required": require_movement_log, "courses": results}
    try:
        (OUT / "COURSE-PROBE.json").write_text(json.dumps(result, indent=2) + "\n")
    except OSError as storage_error:
        result["status"] = "FAIL"
        result["report_failure"] = error_details(storage_error)
        print("Course report storage failed", str(storage_error), flush=True)
    return result


def main():
    OUT.mkdir(exist_ok=True)
    # Root is needed to start the real non-exported LumoGameActivity. The
    # helper retries only the documented adbd-restart disconnect and fails
    # unless the shell really runs as UID 0 on a booted emulator.
    ensure_rooted_emulator(strict_adb, OUT)
    installation = adb("install", "-r", "--no-streaming", sys.argv[1], timeout=300)
    if "Success" not in installation:
        raise RuntimeError(installation)
    adb("shell", "wm", "size", "840x960")
    adb("shell", "wm", "density", "160")
    result = run_courses("--movement" in sys.argv)
    if result["status"] != "PASS":
        failures = [{key: row[key] for key in ("course", "primary_failure", "evidence_failures")}
                    for row in result["courses"] if row["status"] != "PASS"]
        sys.exit(json.dumps({"courses": failures, "report_failure": result.get("report_failure")}))


if __name__ == "__main__":
    main()
