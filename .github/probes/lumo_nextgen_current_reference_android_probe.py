#!/usr/bin/env python3
"""Run native Banane/pattern acceptance after this build's complete Android tour.

The historical 2027 downloader/replay remains pinned to its original bytes.
This entry point accepts identity only from the current build job's outputs,
checks the real candidate hash/provenance again and retains every previous-tour,
same-device, synthetic-profile and installed-hash gate before the existing reset.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import sys
import time
import traceback
import uuid

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("current_reference_helpers", HERE / "lumo_nextgen_reference_android_probe.py")
reference = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reference)
learning = reference.learning
require, digest, read_json = reference.require, reference.digest, reference.read_json


def current_candidate(args) -> dict:
    require(args.expected_version > reference.VERSION_CODE, "Current candidate must be newer than the rejected 2027 build")
    proof = read_json((args.candidate / "BUILD-PROVENANCE.json").read_text())
    identity = learning.verify_provenance(proof, sha256=args.expected_sha256, source=args.expected_source,
                                          native=args.expected_native, version=args.expected_version,
                                          certificate=args.expected_certificate)
    require(identity["versionName"] == args.expected_version_name, "Current candidate versionName mismatch")
    require(args.qa_commit == args.expected_source, "Current QA and APK must use the same source commit")
    require(digest(args.candidate / "Lumo-Lernen-Neu.apk") == identity["sha256"], "Current candidate APK hash mismatch")
    return identity


def verify_current_original(original, identity, original_probe_sha256):
    reference.verify_complete_original(original, identity)
    require(learning.valid_hex(original_probe_sha256, 64) and
            original.get("probe_sha256") == original_probe_sha256,
            "Original result was not produced by this checkout's complete probe")


def verify_ci_context(args, environment):
    require(type(args.workflow_run_id) is int and args.workflow_run_id > 0, "Current workflow run ID required")
    require(environment.get("GITHUB_REPOSITORY") == reference.REPOSITORY and
            environment.get("GITHUB_SHA") == args.qa_commit == args.expected_source and
            environment.get("GITHUB_RUN_ID") == str(args.workflow_run_id),
            "Current candidate must be checked within its own source workflow run")


class CurrentCandidateProbe(reference.ReferenceProbe):
    def candidate_identity(self):
        return current_candidate(self.args)

    def verify_previous_result(self, original, identity):
        verify_current_original(original, identity, digest(HERE / "lumo_nextgen_learning_android_probe.py"))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ("candidate", "previous-probe-out", "out"):
        parser.add_argument("--" + flag, type=Path, required=True)
    for flag in ("qa-commit", "expected-sha256", "expected-source", "expected-native",
                 "expected-certificate", "expected-version-name"):
        parser.add_argument("--" + flag, required=True)
    parser.add_argument("--expected-version", type=int, required=True)
    parser.add_argument("--workflow-run-id", type=int, required=True)
    parser.add_argument("--submit-core-answer", action="store_true")
    parser.add_argument("--serial")
    args = parser.parse_args(argv)
    require(not args.out.exists() or not any(args.out.iterdir()), "Current runtime evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    result = {"schema": "lumo.nextgen.reference.android.probe", "version": 1, "status": "RUNNING",
              "mode": "current-build", "run_id": uuid.uuid4().hex,
              "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "qa_commit": args.qa_commit, "apk_source": args.expected_source,
              "native_source": args.expected_native, "source_workflow_run": args.workflow_run_id,
              "probe_sha256": digest(Path(__file__)),
              "reference_probe_sha256": digest(HERE / "lumo_nextgen_reference_android_probe.py"),
              "historical_tour_pass_used": False, "private_app_data_written_by_probe": False,
              "apk_rebuilt_by_probe": False, "fullModernizationComplete": False}
    probe = None
    try:
        verify_ci_context(args, os.environ)
        current_candidate(args)
        args.apk = args.candidate / "Lumo-Lernen-Neu.apk"
        args.provenance = args.candidate / "BUILD-PROVENANCE.json"
        args.conversation_ui = "ea"
        require(shutil.which("ffprobe"), "ffprobe is required for actual video validation")
        probe = CurrentCandidateProbe(args, result)
        probe.run()
        return 0
    except Exception as error:
        result.update(status="FAIL", error=str(error), traceback=traceback.format_exc())
        if probe:
            try:
                probe.capture("failure-current-screen", native=True)
            except Exception as failure:
                result["failure_capture_error"] = str(failure)
        print(traceback.format_exc(), file=sys.stderr, flush=True)
        return 1
    finally:
        result["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        reference.write_json(args.out / "reference-android-result.json", result)
        print(json.dumps({key: result[key] for key in ("status", "run_id", "qa_commit", "apk_source")}), flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
