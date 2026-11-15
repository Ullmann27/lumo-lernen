#!/usr/bin/env python3
"""DIAGNOSTIC_ONLY: observe two native reference routes on the immutable APK.

This separate starter does not call or replace the original acceptance replay,
ReferenceProbe.run, or reset_successful_original. Its result cannot satisfy the
original-probe requirement and must never be used for release acceptance.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import sys
import time
import traceback
import uuid

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "diagnostic_reference_helpers", HERE / "lumo_nextgen_reference_android_probe.py")
reference = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reference)
learning = reference.learning
require = reference.require


def diagnostic_result(qa_commit: str) -> dict:
    return {
        "schema": "lumo.nextgen.native.reference.diagnostic",
        "version": 1,
        "status": "DIAGNOSTIC_ONLY",
        "diagnostic_outcome": "RUNNING",
        "original_probe_requirement_satisfied": False,
        "release_eligible": False,
        "run_id": uuid.uuid4().hex,
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "qa_commit": qa_commit,
        "qa_base": "c600e1e02745931cc1dd0a17e528a60f8ed4abf3",
        "apk_source": reference.SOURCE,
        "native_source": reference.NATIVE,
        "source_workflow_run": reference.SOURCE_RUN,
        "source_artifact_id": reference.ARTIFACT_ID,
        "probe_sha256": reference.digest(Path(__file__)),
        "reference_helper_sha256": reference.digest(HERE / "lumo_nextgen_reference_android_probe.py"),
        "learning_helper_sha256": reference.digest(HERE / "lumo_nextgen_learning_android_probe.py"),
        "historical_tour_pass_used": False,
        "private_app_data_written_by_probe": False,
        "apk_rebuilt": False,
        "limitations": [
            "DIAGNOSTIC_ONLY: the complete original Android replay is not executed or claimed.",
            "No previous_original_success is supplied; no installation is reset or uninstalled.",
            "Same immutable APK, initially absent package, fresh emulator and UI-created synthetic profile.",
            "Native selections are ungraded; the optional existing Core answer tap is reported separately.",
            "MediaPlayer callbacks are not acoustic pronunciation, microphone or lip-sync proof.",
            "This diagnostic does not establish the original combined performance gate or physical-device acceptance.",
        ],
    }


def prepare_candidate(args) -> None:
    """Keep the same immutable download/provenance gates as the reference probe."""
    origin = args.download_evidence
    proof = reference.read_json((origin / "verified-download.json").read_text())
    reference.verify_origin(*(reference.read_json((origin / (name + ".json")).read_text())
                              for name in ("original-run", "original-artifact", "original-build-job")))
    require(proof.get("zip_sha256") == reference.ZIP_SHA256 and
            proof.get("artifact_id") == reference.ARTIFACT_ID and
            proof.get("qa_commit") == args.qa_commit,
            "Download evidence is not bound to this diagnostic QA commit")
    identity = reference.verify_candidate(args.candidate)
    require(proof.get("candidate") == identity, "Downloaded provenance changed before installation")
    args.apk = args.candidate / "Lumo-Lernen-Neu.apk"
    args.provenance = args.candidate / "BUILD-PROVENANCE.json"
    args.expected_sha256 = reference.APK_SHA256
    args.expected_source = reference.SOURCE
    args.expected_native = reference.NATIVE
    args.expected_version = reference.VERSION_CODE
    args.expected_certificate = reference.CERTIFICATE
    args.conversation_ui = "ea"


def observe_routes(probe) -> None:
    # These are existing observed-UI helpers, not a replacement acceptance run.
    # identify_and_install refuses a previously present package and verifies
    # the actual installed bytes, version and signer before any app navigation.
    probe.identify_and_install()
    require(probe.result["device"]["api"] == 35, "Diagnostic requires Android API 35 exactly")
    require(probe.result["device"].get("package_absent_before_install") is True,
            "Diagnostic requires a fresh disposable installation")
    probe.onboard()
    probe.configure_local_voice()
    probe.banana()
    probe.pattern()
    probe.result["final_profile"] = learning.learning_snapshot(
        probe.preferences("diagnostic-final-profile-and-progress"))["profile"]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ("candidate", "download-evidence", "out"):
        parser.add_argument("--" + flag, type=Path, required=True)
    parser.add_argument("--qa-commit", required=True)
    parser.add_argument("--serial")
    parser.add_argument("--submit-core-answer", action="store_true")
    args = parser.parse_args(argv)
    require(learning.valid_hex(args.qa_commit, 40) and args.qa_commit != reference.SOURCE,
            "A separate immutable diagnostic QA commit is required")
    require(not args.out.exists() or not any(args.out.iterdir()), "Diagnostic evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    result = diagnostic_result(args.qa_commit)
    probe = None
    try:
        prepare_candidate(args)
        require(shutil.which("ffprobe") is not None, "ffprobe is required for actual video validation")
        probe = reference.ReferenceProbe(args, result)
        observe_routes(probe)
        result["diagnostic_outcome"] = "COMPLETED"
        return 0
    except Exception as error:
        result.update(diagnostic_outcome="FAILED", error=str(error), traceback=traceback.format_exc())
        if probe:
            try:
                probe.capture("diagnostic-failure-current-screen", native=True)
            except Exception as failure:
                result["failure_capture_error"] = str(failure)
        print(traceback.format_exc(), file=sys.stderr, flush=True)
        return 1
    finally:
        # No helper result or failure can promote this run to acceptance.
        result.update(status="DIAGNOSTIC_ONLY", original_probe_requirement_satisfied=False,
                      release_eligible=False,
                      finished_utc=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))
        reference.write_json(args.out / "diagnostic-android-result.json", result)
        print(json.dumps({key: result[key] for key in
                          ("status", "diagnostic_outcome", "original_probe_requirement_satisfied",
                           "release_eligible", "run_id", "qa_commit", "apk_source")}), flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
