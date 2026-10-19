#!/usr/bin/env python3
"""Fail-closed identity gate for preserved 1950–1952 and current 1968 APK jobs.

Old candidate workflows intentionally pin their original Godot source. A
modern stabilization PR must retain an equally explicit verified pin rather
than fail an obsolete 1950-only assertion or accept any SHA from config.
Unknown release numbers REQUIRE an explicit reviewed policy update.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPROVED = {
    1950: "268c9b327a8f81ba08c55e1b4bccd3664ce12f88",
    1951: "268c9b327a8f81ba08c55e1b4bccd3664ce12f88",
    1952: "268c9b327a8f81ba08c55e1b4bccd3664ce12f88",
    1968: "61f51b942b2521b506e6b203b89a1b3ec2bd284f",
    1969: "6b3945583a361c4ea974e4b6846ae0d616b1727a",
    1970: "3453a43a8bbdcb0495718e1eced2a40837d6e3ab",
    1971: "3453a43a8bbdcb0495718e1eced2a40837d6e3ab",
    1972: "b8f464d946f73d9b88458bf223f1b83db3975a1a",
    1973: "7bdb7ca91691396399abf3b16f09a54259538df7",
    1974: "42b011dc23abffc24a5df2e13171fa5ada22d6eb",
    1975: "a17b06c4719cc94c94bdf97afb3b6862cd049323",
    1976: "6518a13fb8eb30c81c8a2115d14791cbe7ddd24a",
    1977: "efa1f69b4128a047e6196ee85762447e412db266",
    1978: "efa1f69b4128a047e6196ee85762447e412db266",
    1979: "20652880eda687c67cfa72301dad5a173b1fe6c5",
    1980: "20652880eda687c67cfa72301dad5a173b1fe6c5",
    1981: "20652880eda687c67cfa72301dad5a173b1fe6c5",
    # Quizshow 1982 changes Flutter presentation only; retain the 1981
    # native SHA already verified by the Android integration workflow.
    1982: "20652880eda687c67cfa72301dad5a173b1fe6c5",
    # Visual-only quiz studio remains pinned to the same inspected native tree.
    1983: "20652880eda687c67cfa72301dad5a173b1fe6c5",
    # 1984 only changes Flutter scenes and narration; preserve the validated Kart pin.
    1984: "20652880eda687c67cfa72301dad5a173b1fe6c5",
    # Separate 1985 candidate: PR #106 persistence and tested start-light polish.
    1985: "ffd2955ca9222daf02e6b602b3f213fd9383204a",
    # 1986 builds the integrated Flutter improvements without changing native Kart source.
    1986: "ffd2955ca9222daf02e6b602b3f213fd9383204a",
    # 1987 only updates Flutter education UI; native Kart remains validated.
    1987: "ffd2955ca9222daf02e6b602b3f213fd9383204a",
    # 1988 integrates the fair Cards bot and Bauwelt preview without native Kart changes.
    1988: "ffd2955ca9222daf02e6b602b3f213fd9383204a",
}

def verify(pubspec_text: str, source_text: str) -> tuple[int, str]:
    versions = re.findall(r"^version:\s*[0-9]+(?:\.[0-9]+)*\+([0-9]+)\s*$", pubspec_text, re.MULTILINE)
    if len(versions) != 1:
        raise ValueError("Exactly one explicit release build number is required")
    version = int(versions[0])
    required = APPROVED.get(version)
    if required is None:
        raise ValueError(f"Version {version} has no reviewed native pin; update policy after source review")
    cfg = json.loads(source_text)
    if type(cfg) is not dict or set(cfg) != {"repository", "revision", "engine"}:
        raise ValueError("Unexpected native source config keys")
    if cfg["repository"] != "https://github.com/Ullmann27/lumo-godot.git":
        raise ValueError("Native source origin is not approved")
    if cfg["engine"] != "4.6.3":
        raise ValueError("Unreviewed Godot engine version")
    if cfg["revision"] != required:
        raise ValueError(f"Native revision mismatch for build {version}: expected {required}, got {cfg['revision']}")
    return version, required

if __name__ == "__main__":
    version, sha = verify(
        (ROOT / "pubspec.yaml").read_text(encoding="utf-8"),
        (ROOT / "config" / "godot-source.json").read_text(encoding="utf-8"),
    )
    print(f"PASS reviewed Lumo build {version}; exact Godot 4.6.3 source {sha}")
