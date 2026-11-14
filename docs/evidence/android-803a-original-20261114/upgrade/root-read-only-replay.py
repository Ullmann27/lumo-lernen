"""Replay original 803a upgrade preservation without running an app/device."""
from __future__ import annotations

import datetime
import hashlib
import importlib
import json
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

from PIL import Image


ROOT = Path(__file__).resolve().parent
ORIGINAL = ROOT / "original"
CHECKOUT = Path("/home/agent/lumo-merge-2b586-2708")
HOST = "803a4e960ffb804a46b6d09417731c031f00f680"
SOURCE_BLOBS = {
    "update_preservation.py": "3ddcc5e17b21e48408e6cd854f7e40eeadbddce2",
    "kart_tour_evidence.py": "c7bd2af82f3912c468bc21212ae017b06f70d116",
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def original_inventory() -> list[dict]:
    expected = json.loads((ROOT / "root-download-integrity.json").read_text())["inventory"]
    for entry in expected:
        data = (ORIGINAL / entry["name"]).read_bytes()
        assert len(data) == entry["bytes"], entry["name"]
        assert digest(data) == entry["sha256"], entry["name"]
    return expected


def preferences(name: str) -> dict:
    tree = ET.fromstring((ORIGINAL / name).read_bytes())
    assert tree.tag == "map"
    names = [node.get("name") for node in tree]
    assert all(names) and len(names) == len(set(names))
    assert all(node.tag in {"string", "boolean", "int", "long", "float"} for node in tree)
    return {
        node.get("name"): node.text if node.tag == "string" else node.get("value")
        for node in tree
    }


def package(prefix: str) -> dict:
    raw = (ORIGINAL / (prefix + "-package.txt")).read_text()
    uid = (ORIGINAL / (prefix + "-package-uid.txt")).read_text()
    result = {}
    for name, expression, text in (
        ("versionCode", r"^\s*versionCode=(\d+)\b", raw),
        ("firstInstallTime", r"^\s*firstInstallTime=(.+)$", raw),
        ("userId", r"\buid:(\d+)\b", uid),
    ):
        matches = re.findall(expression, text, flags=re.MULTILINE)
        assert len(matches) == 1, (name, matches)
        result[name] = matches[0]
    return result


def main() -> None:
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    before_inventory = original_inventory()
    source_dir = ROOT / "replay-source-803a"
    source_dir.mkdir(exist_ok=True)
    source_records = []
    for name, expected_blob in SOURCE_BLOBS.items():
        path = "tools/android_qa/" + name
        data = subprocess.run(
            ["git", "show", HOST + ":" + path], cwd=CHECKOUT,
            check=True, capture_output=True,
        ).stdout
        blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        assert blob == expected_blob, (path, blob)
        (source_dir / name).write_bytes(data)
        source_records.append({"path": path, "git_blob": blob, "sha256": digest(data)})
    sys.path.insert(0, str(source_dir))
    preservation = importlib.import_module("update_preservation")
    report = json.loads((ORIGINAL / "update-result.json").read_text())
    assert report["status"] == "PASS" and report["candidate_source"] == HOST
    assert report["candidate"]["flutter_source_commit"] == HOST
    assert report["candidate"]["sha256"] == "fc66e87274173c6c8440bc0dcdcb6e4b7f838dfa168a07e392ec305c15ee566a"
    assert report["candidate"]["godot"]["revision"] == "0e26153f0e58cc05739e72923b4c563a4cf380b8"
    install = preservation.require_in_place_update(package("baseline"), package("updated"), 2020)
    assert install == report["installation"]
    before = preferences("before-update-preferences.xml")
    after_update = preferences("after-update-preferences.xml")
    versions = preservation.reviewed_migration_versions(2017, 2020, allow_2020=True)
    replay = {
        "after_update": preservation.require_learning_preserved(
            before, after_update, migration_versions=versions,
        )
    }
    assert replay["after_update"] == report["after_update"]
    for label, name, recorded in (
        ("after_kart", "after-kart-preferences.xml", report["after_kart"]),
        ("after_restart", "after-restart-preferences.xml", report["after_restart"]),
        ("fold_cover", "fold-cover-preferences.xml", report["fold"]["cover"]),
        ("fold_open", "fold-open-preferences.xml", report["fold"]["open"]),
        ("fold_landscape", "fold-landscape-preferences.xml", report["fold"]["landscape"]),
    ):
        result = preservation.require_post_update_learning_preserved(
            before, after_update, preferences(name), migration_versions=versions,
        )
        assert result == recorded, label
        replay[label] = result
    viewed = [
        "updated-profile-offline.png", "fold-open.png", "fold-cover.png",
        "fold-landscape.png", "23_zurueck_in_flutter.png",
        "21_lumo_kart_real_race.png", "21_race_driving_late_2.png",
    ]
    images = []
    for name in viewed:
        data = (ORIGINAL / name).read_bytes()
        with Image.open(ORIGINAL / name) as image:
            size = list(image.size)
        images.append({"path": name, "bytes": len(data), "sha256": digest(data), "pixels": size})
    assert original_inventory() == before_inventory
    record = {
        "started_at_utc": started,
        "completed_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "status": "PASS", "host": HOST, "artifact_id": 14110561328,
        "source_blobs": source_records, "installation": install,
        "preservation_states_replayed": len(replay),
        "results": replay,
        "all_original_files_unchanged": len(before_inventory),
        "original_pngs_visually_opened_by_root": images,
        "visual_observations": [
            "Updated Home and three emulated Fold dimensions retain the original fox, grade 1, one star and 5/400 XP; text in these selected states is visible. Portrait content and the short landscape layout require scrolling to see lower sections.",
            "The actual return capture visibly shows the Flutter games page, labeled game cards, selected Spielen navigation and one star.",
            "The later race frame visibly shows the original fox in the kart, a rendered track, lap/position/speed and labeled controls. Its minimap extends past the right image edge and overlaps part of the SPEED control. This concrete layout observation has been sent for source triage; no input failure is inferred from the still image.",
            "The landscape Home frame displays Mathe 82% after the one recorded learning answer. The meaning of that score has been sent for source review; the still image alone does not establish an incorrect calculation.",
        ],
        "limits": [
            "Read-only replay of original artifact data using the exact 803a preservation functions; no new app, Android, engine or benchmark run.",
            "The actual CI run used Android API 35/x86_64 with emulated dimensions, not a physical ARM64 or folding device.",
            "The genuine preserved journey is one grade-1 profile and one answered 3+2 task, earning one star and five XP. Seven existing learning keys and the explicit additive independentEvidence-v1 migration are checked; this is not every learning subject, profile or history.",
            "Seven of 225 original PNGs were visually opened by Root. No manual review of every image, audible output, complete two-lap reward, 60 FPS or Nintendo-level quality is claimed.",
            "The separate C4 Android probe failed its branch-origin guard before any C4 observations; successful upgrade evidence does not override that failure.",
        ],
    }
    (ROOT / "root-read-only-replay.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({k: record[k] for k in ["status", "host", "artifact_id", "preservation_states_replayed", "all_original_files_unchanged"]}))


if __name__ == "__main__":
    main()
