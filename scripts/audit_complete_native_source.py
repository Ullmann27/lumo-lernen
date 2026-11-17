#!/usr/bin/env python3
"""Fail-closed inspection of the original LUMO Kart/learning native source.

This checks the checked-out Godot source, not an external archive and not a
rendered concept. File presence is only source readiness, never phone QA.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ARCHIVED_NATIVE_SHA = "2af3170645dd9595cebcb234cd12f4343d621b3b"
R02_PREFIX = "assets/karts/r02"
REQUIRED_CODE = (
    "scripts/games/kart_island.gd",
    "scripts/games/kart_neon_hub.gd",
    "scripts/games/kart_jungle_environment.gd",
    "scripts/learning/learning_world.gd",
    "assets/kart/jungle_emerald_3600/detail_v2/dressing/jungle_dressing_v2.gd",
)
R02_GLB_PATHS = tuple(
    f"{R02_PREFIX}/r02_{index:02d}{level}.glb"
    for index in range(1, 11)
    for level in ("", "_lod1", "_lod2")
)


def sha_at(root: Path) -> str | None:
    result = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "HEAD"],
        text=True, capture_output=True, check=False,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def check_glb(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size < 20:
        return False
    with path.open("rb") as stream:
        header = stream.read(12)
    return (
        header[:4] == b"glTF"
        and int.from_bytes(header[4:8], "little") == 2
        and int.from_bytes(header[8:12], "little") == path.stat().st_size
    )


def audit(root: Path) -> dict:
    root = root.resolve()
    commit = sha_at(root)
    required = {p: (root / p).is_file() for p in REQUIRED_CODE}
    glbs = {p: check_glb(root / p) for p in R02_GLB_PATHS}
    manifest_path = root / R02_PREFIX / "manifest.json"
    manifest_ok = False
    if manifest_path.is_file():
        try:
            manifest_ok = isinstance(json.loads(
                manifest_path.read_text(encoding="utf-8")), dict)
        except (ValueError, UnicodeError, OSError):
            pass

    kart_source = (
        (root / "scripts/games/kart_island.gd").read_text(encoding="utf-8")
        if required["scripts/games/kart_island.gd"] else ""
    )
    environment_source = (
        (root / "scripts/games/kart_jungle_environment.gd").read_text(encoding="utf-8")
        if required["scripts/games/kart_jungle_environment.gd"] else ""
    )
    route_signals = {
        "kart_scene_loads_neon_hub":
            "kart_neon_hub.gd" in kart_source,
        "jungle_uses_v2_dressing":
            "detail_v2/dressing/jungle_dressing_v2.gd" in environment_source,
    }

    missing_code = sorted(p for p, ok in required.items() if not ok)
    missing_glbs = sorted(p for p, ok in glbs.items() if not ok)
    source_ready = (
        commit == ARCHIVED_NATIVE_SHA
        and not missing_code
        and not missing_glbs
        and manifest_ok
        and all(route_signals.values())
    )
    return {
        "schema": "lumo-full-native-source-gate-v1",
        "native_root": str(root),
        "native_commit_observed": commit,
        "required_original_native_commit": ARCHIVED_NATIVE_SHA,
        "native_source_identity_matched": commit == ARCHIVED_NATIVE_SHA,
        "optimized_r02_models_verified": sum(glbs.values()),
        "optimized_r02_models_required": len(R02_GLB_PATHS),
        "r02_manifest_json_valid": manifest_ok,
        "missing_required_code": missing_code,
        "missing_or_invalid_r02_glbs": missing_glbs,
        "runtime_route_source_signals": route_signals,
        "source_ready_for_runtime_tests": source_ready,
        "apk_created": False,
        "physical_fold7_tested": False,
        "message": (
            "Quellbestand erfasst; echte Godot-Runtime, Android-APK und Fold7-Abnahme bleiben separate Gates."
            if source_ready else
            "NICHT vollständig: Kein Full-Content-APK-Release aus diesem Quellstand freigeben."
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot-root", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--require-ready", action="store_true")
    args = parser.parse_args()
    result = audit(args.godot_root)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(result["message"])
    print(f"R02-GLBs: {result['optimized_r02_models_verified']}/30")
    print(f"Godot: {result['native_commit_observed'] or 'nicht vorhanden'}")
    print(f"Prüfbericht: {args.report}")
    return 2 if args.require_ready and not result["source_ready_for_runtime_tests"] else 0


if __name__ == "__main__":
    sys.exit(main())
