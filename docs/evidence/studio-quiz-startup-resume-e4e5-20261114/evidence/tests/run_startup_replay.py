#!/usr/bin/env python3
"""Run a finite original-state UI replay; explicitly no Dart authority."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("--source", type=Path, required=True)
parser.add_argument("--runtime", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--case", choices=("paused_ack", "active_no_touch", "paused_no_ack"), required=True)
args = parser.parse_args()
package = Path(__file__).resolve().parents[2]
args.output.mkdir(parents=True, exist_ok=False)
target = args.runtime / "scripts/tests/quiz_studio_runtime.gd"
replay = args.runtime / "scripts/tests/quiz_startup_original_state_replay.gd"
shutil.copyfile(args.source, target)
shutil.copyfile(Path(__file__).with_name(replay.name), replay)
bound = [target, replay, args.runtime / "scripts/games/quiz/quiz_studio.gd", args.runtime / "scenes/games/quiz_studio.tscn", args.runtime / "assets/characters/lumo_facial/Lumo-Facial-Mobile.glb"]
hashes = lambda: {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in bound}
before = hashes()
env = dict(os.environ, LUMO_CAPTURE_DIR=str(args.output.resolve()), LUMO_QUIZ_QA_DIR="", LUMO_QUIZ_STARTUP_REPLAY_CASE=args.case, LUMO_QUIZ_STARTUP_REPLAY_STATE=str(package / "evidence/fixtures/original-public-state.json"))
command = ["godot", "--headless", "--path", str(args.runtime), "--script", "res://scripts/tests/quiz_startup_original_state_replay.gd", "--", "--fixture"]
started = datetime.datetime.now(datetime.timezone.utc).isoformat()
clock = time.monotonic()
timed_out = False
with (args.output / "godot.log").open("wb") as log:
    process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    try:
        returncode = process.wait(timeout=45)
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(process.pid, signal.SIGTERM)
        try:
            returncode = process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            returncode = process.wait()
result = {"started_at_utc": started, "completed_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "elapsed_seconds": time.monotonic()-clock, "exit_code": returncode, "timed_out": timed_out, "command": command, "case": args.case, "source_before": before, "source_after": hashes(), "scope": "Actual Godot startup/UI replay with declared synthetic ACK transport; no Dart/Android acceptance"}
(args.output / "execution.json").write_text(json.dumps(result, indent=2)+"\n")
print(json.dumps(result))
raise SystemExit(2 if timed_out else 0)
