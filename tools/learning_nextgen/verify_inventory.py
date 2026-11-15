#!/usr/bin/env python3
"""Verify that the source-derived NextGen coverage ledger is complete.

This is a STATIC/source gate. It must never be described as a Flutter runtime,
Godot import, Android UI, device FPS, voice or content-quality verification.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / "docs/integration/lumo-nextgen-20261115/COVERAGE_BASELINE.json"
PROTOCOL = ROOT / "docs/integration/lumo-nextgen-20261115/PROTOCOL_V1.md"


def _text(path: str, root: Path = ROOT) -> str:
    return (root / path).read_text(encoding="utf-8")


def source_catalog(root: Path = ROOT) -> dict[str, Any]:
    topics = _text("lib/features/teacher_mode/topic_curriculum.dart", root)
    registry = _text("lib/features/learning_modules/learning_module_registry.dart", root)
    labs = _text("lib/features/learning/lab/learning_lab_catalog.dart", root)
    generator = _text("lib/core/school_exercise_generator.dart", root)
    topic_re = r"'([^']+)':\s*TopicContext\(\s*grade:\s*(\d+),\s*subject:\s*'([^']+)',\s*title:\s*'([^']+)'"
    module_re = r"case\s+'([^']+)':\s*return\s+(\w+)\("
    lab_re = r"LabTopic\(\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)'"
    topic_items = [
        {"id": tid, "grade": int(grade), "subject": subj, "title": title}
        for tid, grade, subj, title in re.findall(topic_re, topics, re.S)
    ]
    module_items = [
        {"id": tid, "screen": screen}
        for tid, screen in re.findall(module_re, registry, re.S)
    ]
    lab_items = [
        {"id": tid, "title": title, "subject": subj, "unit": unit}
        for tid, title, subj, unit in re.findall(lab_re, labs, re.S)
    ]
    start = generator.split("static List<String> exerciseSubjectsForGrade", 1)
    if len(start) != 2:
        raise ValueError("missing authoritative generator subject entry")
    subject_part = start[1].split("];", 1)[0]
    family_subjects = re.findall(r"'([^']+)'", subject_part)
    if len(start[1].split("];", 1)) != 2:
        raise ValueError("cannot parse generator subject list")
    return {
        "academyTopics": topic_items,
        "dedicatedModules": module_items,
        "labTopics": lab_items,
        "generatorSubjects": family_subjects,
    }


def _unique(values: list[str], group: str) -> None:
    if len(values) != len(set(values)):
        raise ValueError(f"{group}: duplicate ID")


def _strict_equal(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise ValueError(f"{label}: unexpected source/ledger mismatch")


def validate_ledger(data: dict[str, Any], source: dict[str, Any]) -> dict[str, Any]:
    if data.get("schema") != "lumo.nextgen.coverage.v1":
        raise ValueError("invalid coverage schema")
    if data.get("status") != "SOURCE_INVENTORY_NOT_RUNTIME_CERTIFIED":
        raise ValueError("coverage may not claim a runtime certificate")
    for key in ("academyTopics", "dedicatedModules", "labTopics",
                "generatorFamilies", "specialFlows"):
        if not isinstance(data.get(key), list):
            raise ValueError(f"invalid {key} ledger section")

    topics = data["academyTopics"]
    modules = data["dedicatedModules"]
    labs = data["labTopics"]
    families = data["generatorFamilies"]
    specials = data["specialFlows"]
    for group, rows in (
        ("academyTopics", topics), ("dedicatedModules", modules),
        ("labTopics", labs), ("generatorFamilies", families),
        ("specialFlows", specials),
    ):
        _unique([r["id"] for r in rows], group)
        for row in rows:
            if not isinstance(row.get("entry"), str) or not row["entry"].strip():
                raise ValueError(f"{group}: task lacks reachable source entry")
            if row.get("modernized") is not False:
                evidence = row.get("evidence")
                if row.get("modernized") is not True or not isinstance(evidence, dict):
                    raise ValueError(f"{group}: modernization cannot be asserted without evidence")
                for mandatory in ("hostCommit", "nativeCommit", "integrationRun",
                                  "androidRun", "taskCoverage"):
                    if not evidence.get(mandatory):
                        raise ValueError(f"{group}: missing {mandatory} evidence")
    _strict_equal(
        [{"id": r["id"], "grade": r["grade"], "subject": r["subject"],
          "title": r["title"]} for r in topics],
        source["academyTopics"], "36 grade-scoped academy topics",
    )
    _strict_equal(
        [{"id": r["id"], "screen": r["screen"]} for r in modules],
        source["dedicatedModules"], "directly registered modules",
    )
    topic_ids = {r["id"] for r in topics}
    if any(row["id"] not in topic_ids for row in modules):
        raise ValueError("registered module not backed by academy topic")
    _strict_equal(
        [{"id": r["id"], "title": r["title"], "subject": r["subject"],
          "unit": r["unit"]} for r in labs],
        source["labTopics"], "real learning atelier topics",
    )
    _strict_equal(
        [r["subject"] for r in families],
        source["generatorSubjects"], "generator-backed subject families",
    )
    expected_counts = {
        "academyTopicIds": len(topics),
        "dedicatedModuleIds": len(modules),
        "labTopics": len(labs),
        "generatorSubjectFamilies": len(families),
        "specialFlows": len(specials),
    }
    _strict_equal(data.get("counts"), expected_counts, "ledger counts")

    if {r["grade"] for r in topics} != {1, 2, 3, 4}:
        raise ValueError("grade 1–4 coverage missing")
    if any(r["grade"] not in (1, 2, 3, 4) for r in topics):
        raise ValueError("invalid academy grade")
    return {
        "status": "STATIC_SOURCE_MATCH_ONLY",
        "counts": expected_counts,
        "academyMissingModules": sorted(topic_ids - {r["id"] for r in modules}),
        "generatorUnitsEnumerated": False,
        "allLearningModernized": False,
        "androidRuntimeVerified": False,
    }


def check_repository(root: Path = ROOT) -> dict[str, Any]:
    ledger = json.loads(
        (root / "docs/integration/lumo-nextgen-20261115/COVERAGE_BASELINE.json")
        .read_text(encoding="utf-8")
    )
    protocol = (root / "docs/integration/lumo-nextgen-20261115/PROTOCOL_V1.md").read_text(
        encoding="utf-8"
    )
    # Verify the actual shipped Dart v1 identity, not the independent
    # Python/JSON transport experiment in contract_reference.py.
    for field in (
        "LumoLearningIdentity", "sessionId", "taskId", "revision",
        "cancelEpoch", "stepId", "turnId", "LumoLearningActionRequest",
        "LumoLearningPresentation", "LumoLearningAudioFrame",
        "LumoCompanionRequests",
    ):
        if field not in protocol:
            raise ValueError(f"v1 protocol lacks {field}")
    native = json.loads((root / "config/godot-source.json").read_text(encoding="utf-8"))
    if native.get("revision") != ledger["source"]["godotRevision"]:
        raise ValueError("app pinned native source differs from inventory")
    # Contract and coverage are additive; preserve the combined-host version.
    if "version: 0.13.11+2023" not in _text("pubspec.yaml", root):
        raise ValueError("combined-host version was changed without APK policy")
    return validate_ledger(ledger, source_catalog(root))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, help="write a source-only JSON receipt")
    args = parser.parse_args()
    report = check_repository()
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n",
                               encoding="utf-8")
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
