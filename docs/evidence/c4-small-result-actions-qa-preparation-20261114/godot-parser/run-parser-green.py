import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

STAGE = Path("/home/agent/lumo-c4-small-modal-qa-2708")
SOURCE = STAGE / "parser-source"
ORIGIN = Path("/home/agent/lumo-kart-dream-merge-2708/source")
EVIDENCE = STAGE / "parser-evidence"
ENGINE = "/usr/local/bin/godot"
OVERLAY = "scripts/tests/connect_four_small_result_actions_qa.gd"
INVENTORY = json.loads((EVIDENCE / "source-inventory.json").read_text())

def identity(path):
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
            "git_blob": hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()}

def source_snapshot(root):
    records = []
    for expected in INVENTORY:
        actual = identity(root / expected["path"])
        if actual != {key: expected[key] for key in actual}:
            raise RuntimeError("Production bytes differ: " + expected["path"])
        records.append({"path": expected["path"], **actual})
    raw = (json.dumps(records, sort_keys=True, separators=(",", ":")) + "\n").encode()
    return {"files": len(records), "sha256": hashlib.sha256(raw).hexdigest()}

for name in ("version-after.log", "check-only-after.log", "check-only-after.json"):
    if (EVIDENCE / name).exists():
        raise SystemExit("Refuse to replace original parser evidence")
before = source_snapshot(SOURCE)
origin_before = source_snapshot(ORIGIN)
overlay_before = identity(SOURCE / OVERLAY)
if overlay_before["git_blob"] != "cc9ef04069bb2d73d2953a725e7ee5974e5b496f":
    raise SystemExit("The frozen overlay differs")
env = os.environ.copy()
for key in ("DISPLAY", "LUMO_C4_RUNTIME_DIR", "LUMO_CAPTURE_DIR", "LUMO_KART_MINIMAP_CAPTURE_DIR"):
    env.pop(key, None)
env["XDG_DATA_HOME"] = str(STAGE / "parser-user-data")
env["XDG_CONFIG_HOME"] = str(STAGE / "parser-user-config")
version = subprocess.run([ENGINE, "--version"], env=env, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, timeout=20)
(EVIDENCE / "version-after.log").write_bytes(version.stdout)
command = [ENGINE, "--headless", "--path", str(SOURCE), "--check-only",
           "--script", "res://" + OVERLAY]
started = datetime.datetime.now(datetime.timezone.utc).isoformat()
clock = time.monotonic()
with (EVIDENCE / "check-only-after.log").open("wb") as stream:
    try:
        process = subprocess.run(command, env=env, stdout=stream,
                                 stderr=subprocess.STDOUT, timeout=60)
        code = process.returncode
    except subprocess.TimeoutExpired:
        code = 124
elapsed = round(time.monotonic() - clock, 3)
after = source_snapshot(SOURCE)
origin_after = source_snapshot(ORIGIN)
overlay_after = identity(SOURCE / OVERLAY)
log = (EVIDENCE / "check-only-after.log").read_bytes()
record = {
    "kind": "Godot --headless --check-only; no QA runtime execution",
    "command": command, "started_utc": started, "seconds": elapsed, "exit_code": code,
    "version_exit_code": version.returncode, "engine_version": version.stdout.decode().strip(),
    "version_log_sha256": hashlib.sha256(version.stdout).hexdigest(),
    "native_pin": "e2d15dbc5f3709306decb139eeb70a1cf30c0b73",
    "complete_git_checkout": False,
    "materialization": "All 1454 copied tracked source bytes verified against the exact pinned tree",
    "source_before": before, "source_after": after,
    "origin_before": origin_before, "origin_after": origin_after,
    "overlay_before": overlay_before, "overlay_after": overlay_after,
    "source_unchanged": before == after and origin_before == origin_after,
    "overlay_unchanged": overlay_before == overlay_after,
    "helper": identity(SOURCE / "scripts/tests/connect_four_runtime_regression.gd"),
    "log_bytes": len(log), "log_sha256": hashlib.sha256(log).hexdigest(),
    "engine_import_invoked": False, "renderer_or_probe_invoked": False,
    "frame_rate_measured": False,
    "environment": {"XDG_DATA_HOME": env["XDG_DATA_HOME"], "XDG_CONFIG_HOME": env["XDG_CONFIG_HOME"],
                    "DISPLAY": None, "LUMO_C4_RUNTIME_DIR": None},
}
(EVIDENCE / "check-only-after.json").write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps(record, indent=2))
print(log.decode("utf-8", errors="replace"))
if not record["source_unchanged"] or not record["overlay_unchanged"]:
    raise SystemExit("Source changed during the authorized parser check")
raise SystemExit(code)
