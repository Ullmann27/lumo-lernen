#!/usr/bin/env python3
"""Prepare the original verified APK only after a successful complete QA replay."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import tarfile
import zipfile

REPOSITORY = "Ullmann27/lumo-lernen"
SOURCE = "72a7914059d10152604b877cfeaf8bd1d2155810"
NATIVE = "ec702dad29def7ea3db6f62f2ead7b8ca6bca2bb"
SOURCE_RUN = 43759362796
BUILD_JOB = 132956370454
VALIDATION_JOB = 132950549079
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
ARM64_SHA = "20722fad9ca114c0182b928d132fdc674aa7a9b76f92eea20f3135a605e63be5"
X86_SHA = "9f3166a4e071f3f0e4217b1aa7e2e100bbf9ee2cfeb41bdbc47d33827e768fc9"
ARM64_ARTIFACT = {"id": 14180184789, "name": "lumo-nextgen-arm64", "size_in_bytes": 535028936,
                  "digest": "sha256:49cecb2860a0929014b2712da94b667bd59b59685b8cb29896c894eb3f3dd230"}
REPLAY_WORKFLOW = ".github/workflows/lumo-nextgen-reference-android.yml"
REPLAY_BRANCH = "qa/lumo-nextgen-reference-android-20261115"
TAG = "lumo-nextgen-learning-0.13.15-2027"
APK_NAME = "Lumo-Lernen-Neu-0.13.15-2027.apk"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def read_json(path):
    def unique(items):
        result = {}
        for key, value in items:
            require(key not in result, "Duplicate JSON key: " + key)
            result[key] = value
        return result
    return json.loads(Path(path).read_text(), object_pairs_hook=unique)


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def digest(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def api(path):
    return json.loads(subprocess.check_output(["gh", "api", "repos/" + REPOSITORY + "/" + path]))


def verify_artifact_metadata(actual, expected, run_id, source):
    for key in ("id", "name", "size_in_bytes", "digest"):
        require(actual.get(key) == expected[key], "Artifact metadata mismatch: " + key)
    require(actual.get("expired") is False, "Artifact has expired")
    origin = actual.get("workflow_run", {})
    require(origin.get("id") == run_id and origin.get("head_sha") == source,
            "Artifact belongs to a different run or source")


def download_artifact(expected, run_id, source, destination, proof):
    metadata = api("actions/artifacts/" + str(expected["id"]))
    verify_artifact_metadata(metadata, expected, run_id, source)
    write_json(proof / (str(expected["id"]) + "-metadata.json"), metadata)
    archive = proof / (str(expected["id"]) + ".zip")
    with archive.open("wb") as stream:
        subprocess.run(["gh", "api", "repos/" + REPOSITORY + "/actions/artifacts/" +
                        str(expected["id"]) + "/zip"], stdout=stream, check=True)
    require(archive.stat().st_size == expected["size_in_bytes"] and
            "sha256:" + digest(archive) == expected["digest"], "Downloaded artifact bytes differ")
    require(not destination.exists(), "Extraction directory already exists")
    destination.mkdir(parents=True)
    with zipfile.ZipFile(archive) as zipped:
        names = zipped.namelist()
        require(len(names) == len(set(names)), "Duplicate artifact member")
        for member in zipped.infolist():
            path = PurePosixPath(member.filename)
            require(not path.is_absolute() and ".." not in path.parts and "\\" not in member.filename and
                    not stat.S_ISLNK(member.external_attr >> 16), "Unsafe artifact member")
            require(destination.joinpath(*path.parts).resolve().is_relative_to(destination.resolve()),
                    "Artifact member escapes destination")
        require(zipped.testzip() is None, "Artifact CRC failed")
        zipped.extractall(destination)
    return metadata


def verify_replay_results(original, reference, replay, qa_commit):
    accepted = ("PASS", "PASS_WITH_LIMITATIONS")
    require(all(result.get("status") in accepted for result in (original, reference, replay)),
            "Both actual Android tours and replay summary must pass")
    require(reference.get("qa_commit") == qa_commit == replay.get("qa_commit"), "QA commit mismatch")
    require(replay.get("apk_source") == SOURCE and replay.get("apk_sha256") == X86_SHA and
            replay.get("original_source_run") == SOURCE_RUN and replay.get("apk_rebuilt") is False,
            "Replay did not use the original immutable APK")
    candidate = original.get("candidate", {})
    require(reference.get("candidate") == candidate and candidate.get("sha256") == X86_SHA and
            candidate.get("flutter_source_commit") == SOURCE and candidate.get("package") == PACKAGE and
            candidate.get("signingCertificateSha256") == CERTIFICATE and candidate.get("versionCode") == 2027 and
            candidate.get("godot", {}).get("revision") == NATIVE, "Android candidate identity mismatch")
    require(reference.get("previous_complete_probe", {}).get("original_run_id") == original.get("run_id") and
            bool(original.get("run_id")), "Additional tour is not bound to the full original tour")
    require(reference.get("banana", {}).get("repeat_playback", {}).get("segments") == 4 and
            len(reference.get("banana", {}).get("steps", [])) == 3 and
            reference.get("pattern", {}).get("native_confirmation_performed") is False,
            "Native reference-scene evidence missing")
    performance = original.get("native_learning", {}).get("performance", {})
    require(performance.get("capture_status") == "MEASURED" and
            10 <= performance.get("scene_observed_seconds", 0) <= 60 and
            performance.get("window_count", 0) >= 2 and performance.get("sample_count", 0) > 0 and
            bool(performance.get("combined_audio_figure_effect_windows")) and
            bool(performance.get("current_step_replay_playback", {}).get("utterance_ids")) and
            performance.get("video", {}).get("whole_block_within_recording_limit") is True,
            "Original joint audio/figure/effects performance gate not satisfied")
    return performance


def main():
    require(os.environ.get("GITHUB_REPOSITORY") == REPOSITORY, "Wrong release repository")
    config = read_json("config/nextgen-replay-publish.json")
    require(config.get("schemaVersion") == 1 and config.get("apkSourceCommit") == SOURCE,
            "Wrong replay publication configuration")
    qa_commit, qa_run = config["qaCommit"], config["qaRun"]
    require(re.fullmatch(r"[0-9a-f]{40}", qa_commit) is not None and type(qa_run) is int,
            "Immutable QA source and run required")
    proof = Path("publication-proof")
    require(not proof.exists(), "Publication proof must be new")
    proof.mkdir()
    source_run = api("actions/runs/" + str(SOURCE_RUN))
    require(source_run.get("head_sha") == SOURCE and
            source_run.get("path") == ".github/workflows/lumo-nextgen-learning-apk.yml",
            "Original build run has wrong source/workflow")
    write_json(proof / "source-run.json", source_run)
    for job_id, name in ((VALIDATION_JOB, "validate"), (BUILD_JOB, "build")):
        job = api("actions/jobs/" + str(job_id))
        require(job.get("run_id") == SOURCE_RUN and job.get("name") == name and
                job.get("status") == "completed" and job.get("conclusion") == "success",
                "Original source validation/build did not succeed")
        write_json(proof / (name + "-job.json"), job)
    run = api("actions/runs/" + str(qa_run))
    require(run.get("head_sha") == qa_commit and run.get("head_branch") == REPLAY_BRANCH and
            run.get("path") == REPLAY_WORKFLOW and run.get("status") == "completed" and
            run.get("conclusion") == "success", "Exact Android replay is not successful")
    write_json(proof / "replay-run.json", run)
    expected_replay = config["qaArtifact"]
    require(expected_replay.get("name") == "lumo-nextgen-immutable-android-replay", "Wrong replay artifact")
    download_artifact(expected_replay, qa_run, qa_commit, Path("android-evidence"), proof)
    original = read_json("android-evidence/original-android/learning-android-result.json")
    reference = read_json("android-evidence/reference-android/reference-android-result.json")
    replay = read_json("android-evidence/replay-result.json")
    performance = verify_replay_results(original, reference, replay, qa_commit)
    download_artifact(ARM64_ARTIFACT, SOURCE_RUN, SOURCE, Path("release"), proof)
    release = Path("release")
    provenance = read_json(release / "BUILD-PROVENANCE.json")
    apk = release / "Lumo-Lernen-Neu.apk"
    require(apk.stat().st_size == 535014830 and digest(apk) == ARM64_SHA == provenance.get("sha256") and
            provenance.get("flutter_source_commit") == SOURCE and provenance.get("tracked_source_clean") is True and
            provenance.get("godot", {}).get("revision") == NATIVE and provenance.get("package") == PACKAGE and
            provenance.get("signingCertificateSha256") == CERTIFICATE and provenance.get("abis") == ["arm64-v8a"] and
            provenance.get("versionName") == "0.13.15" and provenance.get("versionCode") == 2027,
            "Original ARM64 artifact provenance or bytes mismatch")
    apk.rename(release / APK_NAME)
    delivery = {"schemaVersion": 1, "apkSourceCommit": SOURCE, "godotCommit": NATIVE,
                "qaCommit": qa_commit, "qaRun": qa_run, "originalBuildRun": SOURCE_RUN,
                "originalAndroidOutcome": "FAIL before installation: signer output parser; original retained",
                "replayOutcome": replay["status"], "apkRebuilt": False,
                "arm64Sha256": ARM64_SHA, "arm64Bytes": 535014830,
                "x86Sha256": X86_SHA, "publicationCommit": os.environ["GITHUB_SHA"],
                "fullModernizationComplete": False, "performance": performance,
                "limitations": replay["limitations"]}
    write_json(release / "DELIVERY.json", delivery)
    (release / "COVERAGE.json").write_bytes(subprocess.check_output(
        ["git", "show", SOURCE + ":docs/nextgen/COVERAGE.json"]))
    with tarfile.open(release / "Android-Lernpruefung.tar.gz", "w:gz") as archive:
        archive.add("android-evidence", arcname=".")
    Path("release-notes.md").write_text(
        "# LUMO Lernwelt 0.13.15 (2027)\n\n"
        "Neue einzelne ARM64-Test-APK mit bestehender Paketkennung und Testsignatur.\n\n"
        f"Appquelle: `{SOURCE}`\n\nGodot: `{NATIVE}`\n\n"
        f"APK SHA-256: `{ARM64_SHA}`\n\nSignatur: `{CERTIFICATE}`\n\n"
        f"Android-Prüfquelle: `{qa_commit}`, [Prüflauf](https://github.com/{REPOSITORY}/actions/runs/{qa_run}).\n\n"
        "Quellvalidierung und Build bestanden im ursprünglichen Lauf. Seine erste Androidtour hielt vor Installation "
        "an einem ungeeigneten Signatur-Ausgabeparser an. Der eng korrigierte Leser und die vollständige ursprüngliche "
        "Tour sowie zusätzliche native Banane-/Musterszenen wurden anschließend an genau derselben x86-APK geprüft. "
        "Die ARM64-Datei wurde dabei nicht neu gebaut. Originalfehler und neue Ergebnisse bleiben getrennt erhalten.\n\n"
        "Die Aufnahmen und Messungen stammen von einem Android-35-x86_64-Emulator mit Software-Grafik. "
        "Sie belegen keine physische ARM64-/Fold7-Abnahme, echte gesprochene Erkennung oder menschlich geprüfte Klangqualität. "
        "60 FPS sind nur dann erreicht, wenn die veröffentlichten Messwerte dies zeigen. "
        "Die vollständige Modernisierung aller Aufgabenvarianten bleibt ausdrücklich offen.\n")
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"tag={TAG}\nsource={SOURCE}\napk={APK_NAME}\n")
    print(json.dumps({"prepared": True, "tag": TAG, "apkSource": SOURCE, "qaCommit": qa_commit,
                      "apkSha256": ARM64_SHA, "fullModernizationComplete": False}))


if __name__ == "__main__":
    main()
