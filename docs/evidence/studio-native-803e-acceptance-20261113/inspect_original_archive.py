"""Read-only inventory of the exact 803e native artifact; no visual approval."""
from __future__ import annotations

import hashlib
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import stat
import sys
import zipfile

from PIL import Image


SOURCE = "803e7a626ea6ef0aeeda9c37010e844033d3a8e3"
TREE = "dc24bfa8b3fac8812c88cfc8f8eab3af1479979c"
RUN_ID = 43524051371
COUNTS = {
    "learning_sharing_capture": 6,
    "lumo_studio_motion_capture": 8,
    "puzzle_rotation_regression": 7,
    "puzzle_menu_lifecycle_regression": 6,
    "treasure_exploration_regression": 3,
    "cards_safe_area_regression": 3,
    "mobile_safe_area_regression": 4,
}
SOURCES = (
    "nextgen-evidence/nextgen", "studio-evidence", "touch-evidence/workshop",
    "touch-evidence/treasure", "touch-evidence/build",
)


def main() -> None:
    archive, artifact_path, destination = map(Path, sys.argv[1:4])
    mode = sys.argv[4] if len(sys.argv) > 4 else "bundle"
    assert mode in ("bundle", "studio")
    artifact = json.loads(artifact_path.read_text())
    with archive.open("rb") as archive_stream:
        actual_digest = hashlib.file_digest(archive_stream, "sha256").hexdigest()
    assert artifact["name"] == ("lumo-studio-2019-native-evidence" if mode == "bundle" else "lumo-studio-2019-new-evidence")
    assert artifact["workflow_run"]["id"] == RUN_ID
    assert artifact["workflow_run"]["head_sha"] == SOURCE
    assert artifact["expired"] is False
    assert artifact["digest"] == "sha256:" + actual_digest
    assert artifact["size_in_bytes"] == archive.stat().st_size
    destination.mkdir(parents=True, exist_ok=True)
    report = {"source": SOURCE, "tree": TREE, "run_id": RUN_ID, "archive_scope": mode,
              "artifact_id": artifact["id"], "zip_bytes": archive.stat().st_size,
              "zip_sha256": actual_digest, "images_opened_visually": [],
              "limitation": "Archive/source/file integrity only; not Android or visual acceptance."}
    with zipfile.ZipFile(archive) as zipped:
        assert zipped.testzip() is None, "CRC failure"
        infos = zipped.infolist()
        names = [("studio-evidence/" if mode == "studio" else "") + entry.filename for entry in infos]
        assert len(set(names)) == len(names), "Duplicate ZIP members"
        lookup = dict(zip(names, infos))

        def read(name: str) -> bytes:
            path = PurePosixPath(name)
            assert not path.is_absolute() and ".." not in path.parts
            entry = lookup[name]
            assert not entry.is_dir() and not stat.S_ISLNK(entry.external_attr >> 16)
            return zipped.read(entry)

        def record_file(name: str, data: bytes) -> dict:
            target = destination / "selected-originals" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                assert target.read_bytes() == data, "Different existing original: " + name
            else:
                target.write_bytes(data)
            return {"path": name, "artifact_entry": lookup[name].filename,
                    "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}

        stamps = {}
        for prefix in (SOURCES if mode == "bundle" else ("studio-evidence",)):
            source = read(prefix + "/source-sha.txt").decode().strip()
            dirty = read(prefix + "/source-dirty.txt").decode().strip()
            tree_name = prefix + "/source-tree.txt"
            tree = read(tree_name).decode().strip() if tree_name in lookup else None
            assert source == SOURCE and not dirty, prefix
            if prefix != "nextgen-evidence/nextgen":
                assert tree == TREE, prefix
            elif tree is not None:
                assert tree == TREE, prefix
            stamps[prefix] = {"source": source, "dirty": dirty, "tree": tree}
            for suffix in ("source-sha.txt", "source-dirty.txt", "engine.txt", "results.tsv"):
                name = prefix + "/" + suffix
                record_file(name, read(name))
            if tree is not None:
                record_file(tree_name, read(tree_name))
        report["source_stamps"] = stamps
        roster_name = "studio-evidence/renderer-images.json"
        roster = json.loads(read(roster_name))["images"]
        assert len(roster) == 37
        record_file(roster_name, read(roster_name))
        listed = {"studio-evidence/" + row["path"]: row for row in roster}
        actual_pngs = {name for name in names if name.startswith("studio-evidence/captures/") and name.endswith(".png")}
        assert set(listed) == actual_pngs
        images, sidecars = [], []
        for probe, count in COUNTS.items():
            prefix = "studio-evidence/captures/" + probe + "/"
            selected = sorted(name for name in actual_pngs if name.startswith(prefix))
            assert len(selected) == count, (probe, len(selected), count)
            for name in selected:
                data = read(name)
                row = record_file(name, data)
                with Image.open(BytesIO(data)) as image:
                    dimensions = list(image.size)
                    image.verify()
                original = listed[name]
                assert row["sha256"] == original["sha256"] and row["bytes"] == original["bytes"]
                assert dimensions == [original["width"], original["height"]]
                images.append({**row, "dimensions": dimensions, "probe": probe})
                if probe == "cards_safe_area_regression":
                    layout_name = "studio-evidence/" + original["native_layout"]["path"]
                    layout_data = read(layout_name)
                    layout_row = record_file(layout_name, layout_data)
                    assert layout_row["sha256"] == original["native_layout"]["sha256"]
                    assert layout_row["bytes"] == original["native_layout"]["bytes"]
                    layout = json.loads(layout_data)
                    assert type(layout["schema"]) is int and layout["schema"] == 1
                    assert layout["observation_source"] == "fixture"
                    assert layout["window_px"] == dimensions
                    assert layout["settled"] and layout["ui_visible"] and layout["pending"] == 0
                    sidecars.append(layout_row)
        shared_name = "studio-evidence/captures/mobile_safe_area_regression/mobile-safe-area.json"
        shared_data = read(shared_name)
        shared = json.loads(shared_data)
        assert shared["failures"] == [] and len(shared["targets"]) == 15
        assert all(row["fully_inside_true_safe_area"] and min(row["exposed_dp"]) >= 47.95 for row in shared["targets"])
        expected_names = {module + "-landscape-cutout.png" for module in ("jump", "build", "puzzle", "treasure")}
        assert {row["path"] for row in shared["images"]} == expected_names
        by_name = {PurePosixPath(row["path"]).name: row for row in images if row["probe"] == "mobile_safe_area_regression"}
        assert set(by_name) == expected_names
        for row in shared["images"]:
            assert row["sha256"] == by_name[row["path"]]["sha256"]
            assert by_name[row["path"]]["dimensions"] == [2400, 1080]
        sidecars.append(record_file(shared_name, shared_data))
        rows = read("studio-evidence/results.tsv").decode().strip().splitlines()
        assert rows[0] == "probe\tmode\tresult" and len(rows[1:]) == 16
        assert all(row.split("\t")[-1] == "PASS" for row in rows[1:])
        for name in names:
            if name.startswith("studio-evidence/") and name.endswith(".log") and "/" not in name[len("studio-evidence/"):]:
                record_file(name, read(name))
        report.update(crc="PASS", studio_gate_rows=rows[1:], images=images,
                      studio_png_count=len(images), sidecars=sidecars,
                      archive_member_count=len(infos))
        if mode == "bundle":
            plan = json.loads((destination / "review-plan.json").read_text())
            assert plan["native_source"] == SOURCE and plan["required_workflow_run"] == RUN_ID
            plan_names = [row["artifact_entry"] for row in plan["entries"]]
            assert len(plan_names) == len(set(plan_names)) == 32
            selected = []
            for planned in plan["entries"]:
                name = planned["artifact_entry"]
                assert name.endswith(".png")
                data = read(name)
                row = record_file(name, data)
                with Image.open(BytesIO(data)) as image:
                    dimensions = list(image.size)
                    image.verify()
                assert min(dimensions) >= 320
                selected.append({**planned, **row, "dimensions": dimensions})
            early_path = destination / "studio-partial-inventory.json"
            early = json.loads(early_path.read_text())
            assert early["source"] == SOURCE and early["run_id"] == RUN_ID
            current = {row["path"]: row for row in images + sidecars}
            compared = []
            for earlier in early["images"] + early["sidecars"]:
                now = current[earlier["path"]]
                assert now["sha256"] == earlier["sha256"] and now["bytes"] == earlier["bytes"]
                compared.append(earlier["path"])
            assert len(compared) == 41
            report["early_studio_binding"] = {
                "artifact_id": early["artifact_id"], "zip_sha256": early["zip_sha256"],
                "all_original_bytes_match_final_bundle": True, "compared_paths": compared,
            }
            report["planned_review_images"] = selected
            (destination / "review-plan-extraction.json").write_text(json.dumps({
                "status": "EXTRACTED_AND_BOUND_NOT_VISUALLY_APPROVED_BY_THIS_AGENT",
                "source": SOURCE, "run_id": RUN_ID, "artifact_id": artifact["id"],
                "zip_sha256": actual_digest, "entries": selected,
                "early_studio_binding": report["early_studio_binding"],
            }, indent=2) + "\n")
    output = destination / ("original-archive-inventory.json" if mode == "bundle" else "studio-partial-inventory.json")
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"report": str(output), "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
                      "artifact_id": artifact["id"], "zip_bytes": archive.stat().st_size,
                      "zip_sha256": actual_digest, "studio_png_count": len(report["images"]),
                      "sidecars": len(report["sidecars"]), "crc": report["crc"]}))


if __name__ == "__main__":
    main()
