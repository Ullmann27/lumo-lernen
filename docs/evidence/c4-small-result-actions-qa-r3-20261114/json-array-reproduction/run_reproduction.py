#!/usr/bin/env python3
"""Run only the isolated Godot JSON/type predicate reproduction."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parent
ENGINE = "/usr/local/bin/godot"
SOURCES = (
    "project.godot", "old/int_expectations.gd", "new/float_expectations.gd",
    "original-layout-matches.gd.txt", "candidate-layout-matches.gd.txt",
    "run_reproduction.py",
)

def identity(path):
    data = path.read_bytes()
    return {"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest(),
            "git_blob":hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()}

def snapshot():
    return {name:identity(ROOT/name) for name in SOURCES}

before = snapshot()
environment = os.environ.copy()
environment.pop("DISPLAY", None)
environment.pop("LUMO_C4_RUNTIME_DIR", None)
for name, directory in (
    ("XDG_DATA_HOME","isolated-data"),
    ("XDG_CONFIG_HOME","isolated-config"),
    ("XDG_CACHE_HOME","isolated-cache"),
):
    target = ROOT/directory
    target.mkdir(exist_ok=True)
    environment[name] = str(target)
records = []
for label, script in (("red", "old/int_expectations.gd"), ("green", "new/float_expectations.gd")):
    command = [ENGINE, "--headless", "--path", str(ROOT), "--script", "res://"+script]
    started = datetime.now(timezone.utc).isoformat()
    tick = time.monotonic()
    process = subprocess.run(command, cwd=ROOT, env=environment, capture_output=True, timeout=30)
    (ROOT/(label+".stdout.log")).write_bytes(process.stdout)
    (ROOT/(label+".stderr.log")).write_bytes(process.stderr)
    outputs = [line[len("JSON_ARRAY_MATCH_REPRO "):] for line in process.stdout.decode().splitlines()
               if line.startswith("JSON_ARRAY_MATCH_REPRO ")]
    result = json.loads(outputs[0]) if len(outputs) == 1 else None
    record = {"label":label,"command":command,"started_utc":started,
              "elapsed_seconds":round(time.monotonic()-tick,6),"exit_code":process.returncode,
              "stdout":identity(ROOT/(label+".stdout.log")),
              "stderr":identity(ROOT/(label+".stderr.log")),"result":result}
    (ROOT/(label+".run.json")).write_text(json.dumps(record,indent=2)+"\n")
    records.append(record)
    if result is None:
        break
after = snapshot()
verified = len(records) == 2 and before == after
if verified:
    red, green = records
    red_failures = [row["name"] for row in red["result"]["cases"] if not row["passed"]]
    verified = (
        red["exit_code"] == 1 and red_failures == ["exact_geometry"]
        and red["result"]["checks"] == 15 and red["result"]["failures"] == 1
        and green["exit_code"] == 0 and green["result"]["checks"] == 15
        and green["result"]["failures"] == 0
        and all(row["passed"] for row in green["result"]["cases"])
        and [(row["name"],row["expected"],row["input_json"]) for row in red["result"]["cases"]]
            == [(row["name"],row["expected"],row["input_json"]) for row in green["result"]["cases"]]
        and all(result["input_number_type_ids"] == [result["float_type_id"]]*3
                for result in [red["result"],green["result"]])
    )
summary = {"scope":"Only an isolated exact QA predicate with synthetic JSON; no application/renderer/input run",
           "verified_red_green":verified,"before":before,"after":after,"runs":records,
           "source_before_after_identical":before == after}
(ROOT/"reproduction.json").write_text(json.dumps(summary,indent=2)+"\n")
print(json.dumps({"verified_red_green":verified,"source_before_after_identical":before == after,
                  "runs":[{"label":r["label"],"exit_code":r["exit_code"],"result":r["result"]} for r in records]}))
raise SystemExit(0 if verified else 1)
