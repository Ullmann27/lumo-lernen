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
    # 1989 adds Flutter-only subject cards; preserve Build 1988's verified Kart.
    1989: "ffd2955ca9222daf02e6b602b3f213fd9383204a",
    # Flutter-only UI polish; native Godot 4.6.3 remains pinned unchanged.
    1990: "ffd2955ca9222daf02e6b602b3f213fd9383204a",
    # 1991 adds the proven live scene-switch quality regression to the exact
    # same gameplay tree; source delta is one headless test plus its CI hook.
    1991: "63cecf09fa89dd504cc468ebd121b4ec71a0f36c",
    # 1992 redesign is Flutter-only. Retain identical tested native Kart bits.
    1992: "63cecf09fa89dd504cc468ebd121b4ec71a0f36c",
    # 1993 NextGen release: separate native candidate reviewed in Godot PR #113,
    # verified by six independent Godot 4.6.3 CI workflows; never alter 1992.
    1993: "8342a2f10b2ecb8cf9cf1cb9566093fbc4d0b07c",
    # 1994 integrates real selected mode → premium START, new typography,
    # while 1993 stays immutable for installed user test builds.
    1994: "928fed3c7f0b39357e0f06463ce13c8d5677d6e1",
    # 1995: reviewed SOL+ChatGPT completion of responsive 5-page garage,
    # seven green Godot pipelines and immutable Kart SHA; keep 1994 intact.
    1995: "700baf49828eda693ecce15b415847818b1b56d3",
    # 1996 keeps the exact seven-stage-tested Godot gameplay, while only
    # Flutter crystal rendering and Android scroll safety advance.
    1996: "700baf49828eda693ecce15b415847818b1b56d3",
    # 1997: 700baf49 plus one reviewed native fix (Godot branch
    # claude/kart-landing-landscape-fit-20261022): every Kart landing choice
    # stays readable above START in landscape; new headless fit regression.
    # Flutter adds real-progress subject cards and topic lists. 1996 stays intact.
    1997: "3a3142608f6b150ee251373ba81e6face2eed4b3",
    # 1998 changes only Flutter's Spielewelt navigation and two portals.
    # Preserve the source-identical, reviewed Godot 4.6.3 Kart engine.
    1998: "3a3142608f6b150ee251373ba81e6face2eed4b3",
    # 1999: one reviewed ScrollContainer size flag fixes the invisible native
    # games hub; Kart physics, saves, bridge and scenes are byte-identical.
    # Fresh engine/routing/physics/render evidence: Godot audit 2026-10-23,
    # docs/NEXTGEN_AUDIT_20261023.md at Godot commit 494416b.
    1999: "4d0fd40fdf188be6ca86057596c7b51f41701fa3",
    # 2000: combined physically tested Sonnenhafen panoramic jump and cave water/lava
    # plus Flutter local place-value tutor. Prior 1999 APK is immutable.
    # Godot exact combined-source flights and darkride 4.6.3 tests:
    # https://github.com/Ullmann27/lumo-godot/actions/runs/40721498604
    # https://github.com/Ullmann27/lumo-godot/actions/runs/40721498520
    2000: "adcce3093caa42bf3da47262f70bdf03cdefa347",
    # 2001 is Flutter-only tutoring coordination, workshop and profile evidence.
    # Retain the exact independently tested 2000 Godot source and old policies.
    2001: "adcce3093caa42bf3da47262f70bdf03cdefa347",
    # 2002 adds the reviewed deterministic learning-scene core in Flutter.
    # Native source is byte-identical to published 2000 and reserved 2001.
    2002: "adcce3093caa42bf3da47262f70bdf03cdefa347",
    # 2003 retains the exact Godot 4.6.3 source proven by flight, cave,
    # dynamic-neon, Stage-2, and the signed 2002 native emulator tour.
    # Flutter-only change: Opus living original Lumo and animation scene
    # bridged to Sol's proof-scoped, persisted learning engine.
    # https://github.com/Ullmann27/lumo-godot/actions/runs/40721498468
    # https://github.com/Ullmann27/lumo-lernen/pull/418
    2003: "adcce3093caa42bf3da47262f70bdf03cdefa347",
    # 2004: real 360-degree loop, safe failure, 28.2 m stunt jump and
    # native race continuity passed on the exact candidate source in Godot CI
    # run 41088034976 (full race, 104 lap checks, all required gates).
    # The already published 2003 package and pin remain immutable.
    2004: "3689307a6392fd5756bc87ba0e36f3bef9df71e3",
    # Isolated 2005 candidate: combined real Godot Kart/Jump/creative QA; never rewrite 2004.
    2005: "91b8cdba48d539ba48836bfac5f6b62c0d6cfa41",
    # Separate integration candidate after installed 2008 and reserved 2009/2010.
    # Public Godot PR #129, exact head tested by native CI; not the private
    # 2010 graphics bundle. Source identity approval is not release approval.
    2011: "a81ddf12d594cc252caef7503162e89c6b26e1c7",
    # 2012: reviewed combined Godot PR #135 (Kart #134, Design #133,
    # eleven-track handoff #136 and Fold menu fix); source identity only.
    # Android APK and Fold7 acceptance remain separate gates.
    2012: "9947346ecc526512904adecec1815312020beb62",
    # 2013: Flutter 2013 collector with verified Spielewelt hub and the
    # repaired Godot integration collector. Source identity only; APK/device
    # acceptance remains gated by the unified Android workflow.
    2013: "47bef06db45d61d50ecd06d0b0cd0a69b9a25917",
    # 2014: reviewed integration source for physical Kart, rivals and world art.
    # Identity approval only: full native gameplay, APK and in-place Android
    # update acceptance remain mandatory in the unified candidate workflow.
    2014: "207bfbc5377c0f3e8be800854c83ddf2110ac3f6",
    # 2015: reviewed Sonnenhafen, garage and original Lumo integration (Godot PR #152).
    # Source identity only: the exact pinned source must pass all legacy,
    # 2014 and technical-art gates before APK build, then Android/update acceptance.
    2015: "b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1",
    # 2016: isolated Kart effects source, acceptance and update tests are independent.
    2016: "b4ccf593d7833e8c259ff0f963494b00d245d03d",
    # 2017: reviewed native stage, doubled physical pace and bounded roadside action;
    # includes high-density layout and full-card viewport corrections after review.
    # Source identity only; exact-source native, Android and in-place update gates
    # must pass before the immutable ARM64 test APK can be published.
    2017: "1d5c5cb45a323228f627ec529e6ff1ddd86f1c57",
    # 2018: exact Nextgen source after full native and visual review.
    # APK, Android surfaces, preserved 2017 upgrade and review receipt
    # remain independent mandatory gates before immutable publication.
    2018: "ada5ed81ad62339f15289da62670c0a4f9f7f2b9",
    # 2019: integrated Nextgen source after exact native and visual review.
    # This approves source identity only. Fresh native renderer review, APK,
    # Android integration and preserved 2017 upgrade remain mandatory.
    2019: "17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845",
    # 2020: reviewed C4, original-Lumo facial and Treasure source, paired
    # with the installed PCM envelope. Fresh 52-mode native, Android and
    # preserved-update gates remain mandatory; this entry binds source identity.
    2020: "504c8ba70d02702cbccc370d0d96c36a292c5d27",
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
