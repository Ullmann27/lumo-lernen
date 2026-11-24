import hashlib
import json
from pathlib import Path
import shutil
import stat

STAGE = Path("/home/agent/lumo-c4-small-modal-qa-2708")
ORIGIN = Path("/home/agent/lumo-kart-dream-merge-2708/source")
DESTINATION = STAGE / "parser-source"
EVIDENCE = STAGE / "parser-evidence"
EXPECTED = json.loads((STAGE / "worker/parser-expected-files.json").read_text())
OVERLAY = STAGE / "worker/connect_four_small_result_actions_qa.gd"
OVERLAY_PATH = "scripts/tests/connect_four_small_result_actions_qa.gd"
EXPECTED_OVERLAY = "92368c1e776c3b32ed2147127ea0c5d52f66df70"
EXPECTED_HELPER = "94c32597c0170c5c3199e39ca6fbfcc1caf25f99"

def identify(path):
    data = path.read_bytes()
    return {
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "git_blob": hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest(),
    }

if DESTINATION.exists():
    raise SystemExit("Refuse to overwrite an existing parser source directory")
if EVIDENCE.exists():
    raise SystemExit("Refuse to overwrite existing parser evidence")
if identify(OVERLAY)["git_blob"] != EXPECTED_OVERLAY:
    raise SystemExit("Frozen overlay bytes differ")
tracked = []
missing = []
total = 0
for entry in EXPECTED["entries"]:
    path = ORIGIN / entry["path"]
    if not path.exists():
        missing.append(entry["path"])
        continue
    if entry["type"] != "blob" or path.is_symlink() or not path.is_file():
        raise SystemExit("Unsupported source file type: " + entry["path"])
    identity = identify(path)
    if identity["git_blob"] != entry["sha"]:
        raise SystemExit("Materialized source differs from exact e2 tree: " + entry["path"])
    tracked.append({"path": entry["path"], **identity})
    total += identity["bytes"]
materialized = {item["path"]: item for item in tracked}
helper = materialized.get("scripts/tests/connect_four_runtime_regression.gd")
if helper is None or helper["git_blob"] != EXPECTED_HELPER:
    raise SystemExit("Exact inherited helper is absent")
cache = ORIGIN / ".godot"
if not cache.is_dir():
    raise SystemExit("Existing import cache is absent; no import is authorized")
for path in cache.rglob("*"):
    if path.is_symlink():
        raise SystemExit("Refuse a cache symlink")
    if path.is_file():
        total += path.stat().st_size
if total > shutil.disk_usage(STAGE).free - 1_000_000_000:
    raise SystemExit("Insufficient shared memory budget for the bounded physical copy")
DESTINATION.mkdir()
EVIDENCE.mkdir()
for entry in tracked:
    target = DESTINATION / entry["path"]
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ORIGIN / entry["path"], target)
shutil.copytree(cache, DESTINATION / ".godot", symlinks=False)
sidecars = []
for entry in tracked:
    path = ORIGIN / entry["path"]
    for suffix in (".import", ".uid"):
        sidecar = Path(str(path) + suffix)
        relative = entry["path"] + suffix
        if relative in materialized or not sidecar.is_file():
            continue
        if sidecar.is_symlink():
            raise SystemExit("Refuse a sidecar symlink: " + relative)
        destination = DESTINATION / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(sidecar, destination)
        sidecars.append({"path": relative, **identify(sidecar)})
target = DESTINATION / OVERLAY_PATH
if target.exists():
    raise SystemExit("The QA overlay would overwrite production")
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(OVERLAY, target)
inventory = sorted(tracked, key=lambda item: item["path"])
raw = (json.dumps(inventory, sort_keys=True, separators=(",", ":")) + "\n").encode()
(EVIDENCE / "source-inventory.json").write_bytes(raw)
record = {
    "purpose": "Materialized source copy for authorized check-only parsing",
    "native_pin": EXPECTED["native"], "native_tree": EXPECTED["tree"],
    "origin": str(ORIGIN), "destination": str(DESTINATION),
    "complete_git_checkout": False, "git_directory_copied": False,
    "source_fetch_performed": False, "engine_import_performed": False,
    "materialized_tracked_files": len(inventory), "missing_selected_paths": missing,
    "source_inventory_sha256": hashlib.sha256(raw).hexdigest(),
    "source_inventory_bytes": len(raw),
    "helper": helper,
    "overlay": {"path": OVERLAY_PATH, **identify(target)},
    "cache_copy": "Physical private copy of the existing owned Godot cache; no links",
    "sidecars_copied": len(sidecars),
    "sidecar_inventory_sha256": hashlib.sha256(json.dumps(sidecars, sort_keys=True).encode()).hexdigest(),
    "physical_copy_bytes_before_sidecars": total,
    "home_free_after": shutil.disk_usage(STAGE).free,
}
(EVIDENCE / "prepare.json").write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps(record, indent=2))
