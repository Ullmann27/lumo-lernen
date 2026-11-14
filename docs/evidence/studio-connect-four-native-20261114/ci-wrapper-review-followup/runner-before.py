#!/usr/bin/env python3
"""Run the real C4 renderer against the production Dart controller.

This gate uses a local file transport and test SharedPreferences. It proves the
controller/renderer interaction, not Android Binder, disk persistence, or FPS.
Both process exits, original observations, source hashes and PNGs are required.
"""
from __future__ import annotations

import argparse
from contextlib import ExitStack
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time


HOST_PATHS = (
    "lib", "pubspec.yaml", "pubspec.lock", "config/godot-source.json",
    "test/games/connect_four_runtime_bridge.dart",
    "scripts/run_connect_four_runtime.py",
)
NATIVE_PATHS = ("scripts", "scenes", "assets", "project.godot")
WIN_HISTORY = [0, 6, 1, 6, 2, 5, 3]
WIN_LINE = [[5, 0], [5, 1], [5, 2], [5, 3]]


def read_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return value


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def git(root: Path, *arguments: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(root), *arguments], stderr=subprocess.STDOUT)


def source_snapshot(root: Path, paths: tuple[str, ...]) -> dict:
    """Bind relevant tracked source bytes to HEAD, not generated capture files."""
    head = git(root, "rev-parse", "HEAD").decode().strip()
    entries = git(root, "ls-tree", "-rz", "HEAD", "--", *paths).split(b"\0")
    files = []
    for entry in entries:
        if not entry:
            continue
        metadata, raw_path = entry.split(b"\t", 1)
        mode, kind, expected = metadata.decode().split()
        relative = raw_path.decode("utf-8")
        if kind != "blob" or mode not in ("100644", "100755"):
            raise ValueError(f"Unsupported source entry: {relative}")
        path = root / relative
        if path.is_symlink() or not path.is_file():
            raise ValueError(f"Missing/nonregular source: {relative}")
        data = path.read_bytes()
        blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if blob != expected:
            raise ValueError(f"Working source differs from exact HEAD: {relative}")
        actual_mode = "100755" if path.stat().st_mode & 0o111 else "100644"
        if actual_mode != mode:
            raise ValueError(f"Working source mode differs from HEAD: {relative}")
        files.append({"path": relative, "mode": mode, "git_blob": blob,
                      "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
    if not files:
        raise ValueError("Empty source inventory")
    return {"head": head, "files": files}


def stop_owned_process(process: subprocess.Popen | None) -> None:
    """Terminate only the process group that this runner created."""
    if process is None or process.poll() is not None:
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
        process.wait(timeout=5)


def wait_for_session(path: Path, dart: subprocess.Popen, timeout: float) -> dict:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if dart.poll() is not None:
            raise RuntimeError(f"Dart exited before renderer handshake: {dart.returncode}")
        if path.is_file():
            session = read_json(path)
            if (session.get("token") != "a" * 32
                    or not isinstance(session.get("owner"), str)
                    or len(session["owner"]) != 64
                    or not isinstance(session.get("roundId"), str)
                    or len(session["roundId"]) != 32):
                raise ValueError("Malformed renderer handshake")
            return session
        time.sleep(0.1)
    raise TimeoutError("No production Dart session before the startup deadline")


def wait_for_pair(dart: subprocess.Popen, native: subprocess.Popen, timeout: float) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        codes = (dart.poll(), native.poll())
        if any(code is not None and code != 0 for code in codes):
            raise RuntimeError(f"C4 process failed: Dart={codes[0]}, Godot={codes[1]}")
        if all(code == 0 for code in codes):
            return
        time.sleep(0.1)
    raise TimeoutError("C4 two-process sequence exceeded its bounded deadline")


def validate_results(output: Path) -> dict:
    dart = read_json(output / "dart-result.json")
    native = read_json(output / "native-result.json")
    done = read_json(output / "done.json")
    if dart.get("passed") is not True or native.get("passed") is not True or done.get("finished") is not True:
        raise ValueError("Both original result documents must report success")
    if native.get("errors") != [] or not isinstance(native.get("checks"), int) or native["checks"] < 143:
        raise ValueError("Native assertions are missing or failed")
    round_state = dart.get("round", {})
    final = native.get("final_state", {})
    if (round_state.get("columns") != WIN_HISTORY or final.get("columns") != WIN_HISTORY
            or final.get("winningLine") != WIN_LINE or final.get("phase") != "won"
            or round_state.get("rewarded") is not True or final.get("rewarded") is not True
            or dart.get("reopened_same_round") is not True
            or dart.get("single_player_human_and_bot_observed") is not True
            or dart.get("stars") != 5 or dart.get("xp") != 40
            or round_state.get("id") != final.get("roundId")
            or round_state.get("owner") != final.get("owner")
            or final.get("token") != "a" * 32 or final.get("exit") is not True):
        raise ValueError("Dart/Godot legal history, ownership, reward or exit disagree")
    events = native.get("inputs")
    targets = native.get("targets")
    if not isinstance(events, list) or len(events) < 14 or not isinstance(targets, list) or len(targets) < 7:
        raise ValueError("Original touch/target evidence is missing")
    for target in targets:
        sizes = target.get("size_dp", [])
        if len(sizes) != 2 or any(isinstance(v, bool) or not isinstance(v, (int, float))
                                  or not math.isfinite(v) or v < 47.99 for v in sizes):
            raise ValueError("A touched target is smaller than48dp")
    count = native.get("frames")
    frames = sorted((output / "frames").glob("*.png"))
    if not isinstance(count, int) or count < 100 or len(frames) != count:
        raise ValueError("Recorded frame count does not match the real PNG sequence")
    if [path.name for path in frames] != [f"{i:05d}.png" for i in range(count)]:
        raise ValueError("Non-contiguous renderer frame sequence")
    if native.get("fps_format") != 24 or len(native.get("positions", [])) != count:
        raise ValueError("Original frame/geometry observations are inconsistent")
    positions = native["positions"]
    disc_counts = set()
    moving_frames = 0
    winning_frames = 0
    last_discs = None
    for index, observation in enumerate(positions):
        if observation.get("frame") != index or not isinstance(observation.get("discs"), list):
            raise ValueError("Missing per-frame geometry observation")
        discs = observation["discs"]
        for point in discs:
            if (not isinstance(point, list) or len(point) != 3
                    or any(isinstance(v, bool) or not isinstance(v, (int, float))
                           or not math.isfinite(v) for v in point)):
                raise ValueError("Invalid observed disc geometry")
        disc_counts.add(len(discs))
        if (observation.get("dropping") is True and last_discs is not None
                and len(last_discs) == len(discs) and discs != last_discs):
            moving_frames += 1
        winning_frames += observation.get("win_rings") == 4
        last_discs = discs
    if not set(range(1, 8)).issubset(disc_counts) or moving_frames < 7 or winning_frames < 2:
        raise ValueError("Actual falling geometry or four-disc win frames are missing")
    required_images = {"connect_four_empty.png", "connect_four_win.png", "connect_four_pause.png",
                       "connect_four_phone_playing.png", "connect_four_phone_bot_response.png",
                       "connect_four_phone_portrait.png", "connect_four_fold_landscape.png",
                       "connect_four_small_landscape.png", "connect_four_small_portrait.png"}
    missing = required_images - {p.name for p in output.glob("*.png")}
    if missing:
        raise ValueError(f"Required renderer captures missing: {sorted(missing)}")
    # Pillow decodes every actual PNG. Presence or a file extension is insufficient.
    from PIL import Image
    images = []
    for path in sorted(output.rglob("*.png")):
        with Image.open(path) as picture:
            if picture.format != "PNG":
                raise ValueError(f"Not a PNG: {path}")
            picture.load()
            if min(picture.size) < 100:
                raise ValueError(f"Invalid renderer image size: {path}")
            width, height = picture.size
        data = path.read_bytes()
        images.append({"path": str(path.relative_to(output)), "width": width, "height": height,
                       "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
    return {"native_checks": native["checks"], "frames": count, "images": images,
            "observed_moving_frames": moving_frames, "observed_winning_frames": winning_frames,
            "actual_recording_format_fps": 24, "device_fps_claim": False,
            "backend": "production Dart controller with test SharedPreferences and local file transport",
            "android_binder_or_disk_claim": False}


def run(host: Path, native: Path, output: Path) -> int:
    host, native, output = host.resolve(), native.resolve(), output.resolve()
    if output.exists() and any(output.iterdir()):
        raise ValueError("Refusing to overwrite existing evidence; choose an empty output directory")
    output.mkdir(parents=True, exist_ok=True)
    report = {"started_utc": datetime.now(timezone.utc).isoformat(), "passed": False,
              "scope": "local two-process source-bound runtime gate; not Android/FPS acceptance"}
    dart = renderer = None
    try:
        config = read_json(host / "config/godot-source.json")
        before = {"host": source_snapshot(host, HOST_PATHS), "native": source_snapshot(native, NATIVE_PATHS)}
        if before["native"]["head"] != config.get("revision") or config.get("engine") != "4.6.3":
            raise ValueError("Native checkout does not equal the exact configured4.6.3 source pin")
        for executable in ("flutter", "godot", "xvfb-run"):
            if shutil.which(executable) is None:
                raise ValueError(f"Missing required executable: {executable}")
        version = subprocess.check_output(["godot", "--version"], text=True, timeout=15).strip()
        if not version.startswith("4.6.3."):
            raise ValueError(f"Unexpected Godot version: {version}")
        report["godot_version"] = version
        write_json(output / "source-before.json", before)
        env = os.environ.copy()
        env.update({"LUMO_C4_RUNTIME_DIR": str(output), "LIBGL_ALWAYS_SOFTWARE": "1",
                    "XDG_DATA_HOME": str(output / "user-data"),
                    "XDG_CONFIG_HOME": str(output / "user-config"),
                    "XDG_CACHE_HOME": str(output / "user-cache")})
        dart_command = ["flutter", "test", "--no-pub", "--reporter=expanded",
                        "test/games/connect_four_runtime_bridge.dart"]
        native_command = ["xvfb-run", "-a", "-s", "-screen 0 2560x2560x24 -nolisten tcp",
                          "godot", "--path", str(native), "--fixed-fps", "24",
                          "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
                          "--resolution", "960x540", "--script",
                          "res://scripts/tests/connect_four_runtime_regression.gd", "--", "--capture"]
        report["commands"] = {"dart": dart_command, "godot": native_command}
        with ExitStack() as stack:
            dart_log = stack.enter_context((output / "original-dart.log").open("wb"))
            native_log = stack.enter_context((output / "original-godot.log").open("wb"))
            dart = subprocess.Popen(dart_command, cwd=host, env=env, stdout=dart_log,
                                    stderr=subprocess.STDOUT, start_new_session=True)
            report["session"] = wait_for_session(output / "session.json", dart, 120)
            renderer = subprocess.Popen(native_command, cwd=native, env=env, stdout=native_log,
                                        stderr=subprocess.STDOUT, start_new_session=True)
            wait_for_pair(dart, renderer, 1080)
        report["results"] = validate_results(output)
        after = {"host": source_snapshot(host, HOST_PATHS), "native": source_snapshot(native, NATIVE_PATHS)}
        write_json(output / "source-after.json", after)
        if before != after:
            raise ValueError("Relevant source changed during the runtime gate")
        report["passed"] = True
    except (OSError, ValueError, RuntimeError, TimeoutError, subprocess.SubprocessError) as error:
        report["error"] = f"{type(error).__name__}: {error}"
    finally:
        stop_owned_process(renderer)
        stop_owned_process(dart)
        report["exit_codes"] = {"dart": None if dart is None else dart.poll(),
                                "godot": None if renderer is None else renderer.poll()}
        report["completed_utc"] = datetime.now(timezone.utc).isoformat()
        write_json(output / "runtime-gate.json", report)
    print(json.dumps({"passed": report["passed"], "output": str(output),
                      "error": report.get("error"), "exit_codes": report["exit_codes"]}))
    return 0 if report["passed"] else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", type=Path, required=True)
    parser.add_argument("--native", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    return run(args.host, args.native, args.output)


if __name__ == "__main__":
    raise SystemExit(main())
