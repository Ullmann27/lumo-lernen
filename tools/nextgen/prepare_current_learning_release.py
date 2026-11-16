#!/usr/bin/env python3
"""Prepare this source's ARM64 test release after both actual Android tours."""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = ROOT / ".github/probes"
SPEC = importlib.util.spec_from_file_location("current_release_probe", PROBES / "lumo_nextgen_current_reference_android_probe.py")
current = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(current)
reference, learning = current.reference, current.learning
require, digest, read_json = current.require, current.digest, current.read_json


def verify_tours(original, extra, *, source, native, version, version_name,
                 certificate, x86_sha256, workflow_run, original_result_sha256):
    identity = learning.verify_provenance(original.get("candidate", {}), sha256=x86_sha256,
                                          source=source, native=native, version=version, certificate=certificate)
    require(identity["versionName"] == version_name, "Android versionName differs from current build")
    current.verify_current_original(original, identity, digest(PROBES / "lumo_nextgen_learning_android_probe.py"))
    require(extra.get("schema") == "lumo.nextgen.reference.android.probe" and
            extra.get("status") in ("PASS", "PASS_WITH_LIMITATIONS") and
            extra.get("mode") == "current-build", "Additional current-build tour has not passed")
    require(extra.get("candidate") == identity and extra.get("qa_commit") == source and
            extra.get("apk_source") == source and extra.get("native_source") == native and
            type(extra.get("source_workflow_run")) is int and extra["source_workflow_run"] == workflow_run,
            "Reference tour belongs to a different candidate or workflow run")
    require(extra.get("probe_sha256") == digest(PROBES / "lumo_nextgen_current_reference_android_probe.py") and
            extra.get("reference_probe_sha256") == digest(PROBES / "lumo_nextgen_reference_android_probe.py"),
            "Reference tour was produced by different probe sources")
    return verify_observed_execution(original, extra, identity=identity,
                                     original_result_sha256=original_result_sha256)


def verify_observed_execution(original, extra, *, identity, original_result_sha256):
    """Shared runtime gates after a caller validates its exact source/run mode.

    The current-build caller above still requires QA == APK source. A separate
    immutable replay caller must validate its distinct QA commit and source run;
    neither caller may rewrite records to satisfy another mode's identity gate.
    """
    for flag in ("historical_tour_pass_used", "private_app_data_written_by_probe", "apk_rebuilt_by_probe",
                 "fullModernizationComplete"):
        require(extra.get(flag) is False, "Reference evidence contract changed: " + flag)
    installed = extra.get("installed", {})
    require(all(installed.get(key) == identity[key] for key in
                ("package", "versionCode", "versionName", "sha256", "signingCertificateSha256")),
            "Additional tour installed identity differs")
    previous = extra.get("previous_complete_probe", {})
    require(bool(original.get("run_id")) and previous.get("original_run_id") == original["run_id"] and
            previous.get("original_status") == original["status"] and
            previous.get("original_result_sha256") == original_result_sha256 and
            learning.valid_hex(original_result_sha256, 64), "Reference reset is not bound to the complete original result")
    require(previous.get("installed_before_reset", {}).get("sha256") == identity["sha256"] and
            previous.get("synthetic_profile_before_reset") == original["final_profile"],
            "Original candidate/profile was not reverified before reference reset")
    device, extra_device = original.get("device", {}), extra.get("device", {})
    require(bool(device.get("serial")) and device.get("serial") == extra_device.get("serial") and
            all(d.get("physical_device") is False and d.get("api") == 35 and d.get("abi") == "x86_64" and
                d.get("package_absent_before_install") is True for d in (device, extra_device)),
            "Both tours must use fresh installations on the same disposable API35 x86 emulator")
    banana, pattern = extra.get("banana", {}), extra.get("pattern", {})
    require(banana.get("word") == "Banane" and banana.get("syllables") == ["Ba", "na", "ne"] and
            len(banana.get("steps", [])) == 3 and banana.get("repeat_playback", {}).get("segments") == 4 and
            len(banana.get("repeat_playback", {}).get("utterance_ids", [])) == 4 and
            banana.get("repeat_video", {}).get("whole_block_within_recording_limit") is True and
            banana.get("native_answer_submitted") is False and banana.get("preservation", {}).get("profile_id"),
            "Actual native Banane steps, repeat or preserved return are missing")
    require(pattern.get("task") and pattern.get("returned_task") == pattern["task"] and
            pattern.get("native_confirmation_performed") is False and
            pattern.get("hint_playback", {}).get("utterance_ids") and
            pattern.get("observed_group_hint") and pattern.get("preservation", {}).get("profile_id"),
            "Actual native pattern hint and ungraded preserved return are missing")
    if pattern.get("core_answer_submitted") is True:
        require(pattern.get("core_submission", {}).get("status") == "PASS", "Claimed Core submission lacks stored assessment")
    return original["native_learning"]["performance"]


def main():
    require(os.environ.get("GITHUB_REPOSITORY") == reference.REPOSITORY, "Wrong release repository")
    source, native = os.environ["GITHUB_SHA"], os.environ["LUMO_EXPECTED_NATIVE"]
    version, version_name = int(os.environ["VERSION_CODE"]), os.environ["VERSION_NAME"]
    workflow_run = int(os.environ["GITHUB_RUN_ID"])
    certificate = os.environ["LUMO_CERTIFICATE"]
    root, evidence = Path("release"), Path("android-evidence")
    original_path = evidence / "original-android/learning-android-result.json"
    reference_path = evidence / "reference-android/reference-android-result.json"
    original, extra = read_json(original_path.read_text()), read_json(reference_path.read_text())
    performance = verify_tours(original, extra, source=source, native=native, version=version,
                               version_name=version_name, certificate=certificate,
                               x86_sha256=os.environ["X86_SHA"], workflow_run=workflow_run,
                               original_result_sha256=digest(original_path))
    proof = read_json((root / "BUILD-PROVENANCE.json").read_text())
    apk = root / "Lumo-Lernen-Neu.apk"
    require(digest(apk) == os.environ["ARM64_SHA"] == proof.get("sha256") and
            proof.get("flutter_source_commit") == source and proof.get("tracked_source_clean") is True and
            proof.get("godot", {}).get("revision") == native and proof.get("package") == learning.PACKAGE and
            proof.get("signingCertificateSha256") == certificate and proof.get("abis") == ["arm64-v8a"] and
            proof.get("versionName") == version_name and type(proof.get("versionCode")) is int and
            proof["versionCode"] == version and version > 2027,
            "Current ARM64 artifact provenance or bytes mismatch")
    require(proof["godot"]["pck_sha256"] == original["candidate"]["godot"]["pck_sha256"],
            "ARM64 and x86 candidates contain different native learning packs")
    coverage = read_json((ROOT / "docs/nextgen/COVERAGE.json").read_text())
    require(coverage.get("scope", {}).get("fullModernizationComplete") is False, "Full modernization was not accepted")
    apk_name = f"Lumo-Lernen-Neu-{version_name}-{version}.apk"
    destination = root / apk_name
    require(not destination.exists(), "Release APK may not overwrite an existing file")
    limitations = list(dict.fromkeys(original.get("limitations", []) + extra.get("limitations", []) + [
        "All task inventory entries are not individually modernized 3D learning simulations; many routes use the shared task card.",
        "The native learning figure runs in the existing separate Godot Activity, not inline on every Flutter task screen.",
        "The ARM64 download is independently artifact-verified; runtime recordings are from the x86 APK of the same source.",
        "Physical Fold7 hinge behavior, preserved upgrade/process-death recovery, sustained hardware FPS and acoustic speech quality remain unverified.",
    ]))
    delivery = {"schemaVersion": 1, "apkSourceCommit": source, "godotCommit": native,
                "versionName": version_name, "versionCode": version, "package": learning.PACKAGE,
                "signingCertificateSha256": certificate, "workflowRun": workflow_run,
                "arm64Sha256": proof["sha256"], "arm64Bytes": apk.stat().st_size,
                "x86Sha256": original["candidate"]["sha256"], "fullModernizationComplete": False,
                "originalAndroidStatus": original["status"], "referenceAndroidStatus": extra["status"],
                "originalResultSha256": digest(original_path), "referenceResultSha256": digest(reference_path),
                "performance": performance, "limitations": limitations}
    reference.write_json(root / "DELIVERY.json", delivery)
    apk.rename(destination)
    Path("release-notes.md").write_text(
        f"# LUMO Lernwelt {version_name} ({version})\n\n"
        "Neue einzelne ARM64-Test-APK mit bestehender Paketkennung und bestehender Testsignatur.\n\n"
        f"Flutter: `{source}`\n\nGodot: `{native}`\n\n"
        f"APK SHA-256: `{proof['sha256']}`\n\nSignatur: `{certificate}`\n\n"
        f"[Vollständiger Quell-, Build- und Android-Prüflauf](https://github.com/{reference.REPOSITORY}/actions/runs/{workflow_run}).\n\n"
        "Die tatsächliche Androidtour und die zusätzlichen nativen Banane-/Musterszenen wurden an der x86-APK "
        "desselben Quellstands ausgeführt. Beide Läufe, die installierten Bytes, die Originalbilder/-videos "
        "und die gemessenen Audio-/Figur-/Effektfenster sind miteinander verbunden.\n\n"
        "Die ursprüngliche Version 2027 wurde nach dem beobachteten Verlust des Aufgabenkontexts beim Öffnen "
        "des Lab-Gesprächs nicht veröffentlicht. Diese neue APK enthält die Produktkorrektur.\n\n"
        "Die Aufnahmen stammen von Android 35 x86_64 mit Software-Grafik. Das ist kein physischer ARM64-/Fold7-, "
        "Spracherkennungs- oder 60-FPS-Nachweis. Die vollständige Modernisierung aller Aufgabenvarianten bleibt "
        "ausdrücklich offen. DELIVERY.json enthält Messwerte und Grenzen; die Abdeckungsliste bleibt maßgeblich.\n",
        encoding="utf-8")
    print(json.dumps({"prepared": True, "apk": apk_name, "source": source,
                      "sha256": proof["sha256"], "fullModernizationComplete": False}))


if __name__ == "__main__":
    main()
