#!/usr/bin/env python3
"""Run the reviewed Android probe test roster; empty or skipped suites fail."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
import time
import traceback
import unittest

ROOT = Path(__file__).resolve().parents[1]
ROSTER = ROOT / "scripts/android_probe_acceptance_roster.json"


def test_ids(suite: unittest.TestSuite) -> list[str]:
    found: list[str] = []
    for test in suite:
        if isinstance(test, unittest.TestSuite):
            found.extend(test_ids(test))
        else:
            found.append(test.id())
    return found


class RecordingResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.started_ids: list[str] = []
        self.success_ids: list[str] = []

    def startTest(self, test):
        self.started_ids.append(test.id())
        super().startTest(test)

    def addSuccess(self, test):
        self.success_ids.append(test.id())
        super().addSuccess(test)


def run_group(
    group: str, config: dict, repo_root: Path, output: Path
) -> int:
    output.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    report = {
        "schema": 1,
        "group": group,
        "status": "FAIL",
        "scope": "Offline Python/OCR source contracts; no Android gameplay claim.",
        "python": sys.version,
        "resolved_tesseract": shutil.which("tesseract"),
        "expected_ids": config["expected_ids"],
    }
    try:
        expected = config["expected_ids"]
        if not expected or len(expected) != len(set(expected)):
            raise ValueError("Expected test roster must be nonempty and unique")
        source = repo_root / config["directory"] / config["pattern"]
        source_bytes = source.read_bytes()
        report["test_source"] = {
            "path": str(source.relative_to(repo_root)),
            "bytes": len(source_bytes),
            "sha256": hashlib.sha256(source_bytes).hexdigest(),
        }
        loader = unittest.TestLoader()
        suite = loader.discover(
            str(repo_root / config["directory"]), pattern=config["pattern"]
        )
        discovered = test_ids(suite)
        report["discovered_ids"] = discovered
        report["discovered_count"] = suite.countTestCases()
        if loader.errors:
            raise RuntimeError("Test discovery errors: " + "\n".join(loader.errors))
        if sorted(discovered) != sorted(expected):
            raise RuntimeError("Discovered test IDs differ from the reviewed roster")
        if suite.countTestCases() != len(expected):
            raise RuntimeError("Discovered test count differs from the reviewed roster")
        result = unittest.TextTestRunner(
            stream=sys.stderr,
            verbosity=2,
            resultclass=RecordingResult,
        ).run(suite)
        report.update(
            tests_run=result.testsRun,
            started_ids=result.started_ids,
            success_ids=result.success_ids,
            failures=[{"id": t.id(), "traceback": value} for t, value in result.failures],
            errors=[{"id": t.id(), "traceback": value} for t, value in result.errors],
            skipped=[{"id": t.id(), "reason": value} for t, value in result.skipped],
            expected_failures=[
                {"id": t.id(), "traceback": value}
                for t, value in result.expectedFailures
            ],
            unexpected_successes=[t.id() for t in result.unexpectedSuccesses],
        )
        accepted = (
            result.wasSuccessful()
            and result.testsRun == len(expected)
            and sorted(result.started_ids) == sorted(expected)
            and sorted(result.success_ids) == sorted(expected)
            and not result.skipped
            and not result.expectedFailures
            and not result.unexpectedSuccesses
        )
        if not accepted:
            raise RuntimeError("Every reviewed test must execute and pass without skips")
        report["status"] = "PASS"
    except (Exception, SystemExit) as error:
        report["failure"] = {"type": type(error).__name__, "message": str(error)}
        traceback.print_exc()
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 6)
        (output / (group + ".json")).write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    print(
        json.dumps(
            {
                "group": group,
                "status": report["status"],
                "expected": len(report["expected_ids"]),
                "tests_run": report.get("tests_run", 0),
                "successes": len(report.get("success_ids", [])),
            },
            sort_keys=True,
        )
    )
    return 0 if report["status"] == "PASS" else 1


def main() -> int:
    document = json.loads(ROSTER.read_text(encoding="utf-8"))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--group", choices=sorted(document["groups"]), required=True)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    return run_group(
        arguments.group,
        document["groups"][arguments.group],
        ROOT,
        arguments.output,
    )


if __name__ == "__main__":
    raise SystemExit(main())
