#!/usr/bin/env python3
"""Additional visible Banane/pattern acceptance of the immutable 2027 x86 APK.

`download` runs on the CI runner, never rebuilds an APK, and verifies the exact
original Actions run/artifact, ZIP digest and independently supplied APK digest.
`run` reuses only the existing readers/install/onboarding helpers, not their tour.
Every app action uses current accessibility or screenshot/OCR observations. App
preferences are read only; a fresh fictional grade-1 profile is created by UI.
The QA commit is deliberately distinct from the unchanged APK source commit.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import sys
import time
import traceback
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import uuid
import zipfile

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("reference_learning_helpers", HERE / "lumo_nextgen_learning_android_probe.py")
learning = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(learning)
require, digest, read_json = learning.require, learning.digest, learning.read_json

REPOSITORY = "Ullmann27/lumo-lernen"
REPOSITORY_ID = 1222433959
SOURCE_RUN = 43759362796
BUILD_JOB = 132956370454
SOURCE = "72a7914059d10152604b877cfeaf8bd1d2155810"
NATIVE = "ec702dad29def7ea3db6f62f2ead7b8ca6bca2bb"
PCK_SHA256 = "aeec3bee15604e814dfe02b643e55977497f18fa08283b1de1be0d3dda4aa65a"
ARTIFACT_ID = 14180917030
ARTIFACT_NAME = "lumo-nextgen-x86"
ZIP_BYTES = 538191859
ZIP_SHA256 = "93f5e7c5836018ec195e377a98a8bd58b995e2ca0b132c3ab158f772f98dc0a8"
APK_BYTES = 538177759
APK_SHA256 = "9f3166a4e071f3f0e4217b1aa7e2e100bbf9ee2cfeb41bdbc47d33827e768fc9"
CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
VERSION_CODE, VERSION_NAME = 2027, "0.13.15"
QA_BRANCH = "qa/lumo-nextgen-reference-android-20261115"
SHAPES = frozenset(("Kreis", "Dreieck", "Stern", "Quadrat"))
BANANA_TITLE = "Ba – na – ne"
NATIVE_ENTRY = "Mit Lumo in 3D ausprobieren"


def write_json(path: Path, value) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def verify_origin(run: dict, artifact: dict, job: dict) -> None:
    require(run.get("id") == SOURCE_RUN and run.get("head_sha") == SOURCE, "Wrong original run/source")
    require(run.get("repository", {}).get("full_name") == REPOSITORY and
            run.get("repository", {}).get("id") == REPOSITORY_ID, "Wrong original repository")
    require(run.get("path") == ".github/workflows/lumo-nextgen-learning-apk.yml", "Wrong source workflow")
    expected = {"id": ARTIFACT_ID, "name": ARTIFACT_NAME, "size_in_bytes": ZIP_BYTES,
                "digest": "sha256:" + ZIP_SHA256, "expired": False}
    for key, value in expected.items():
        require(type(artifact.get(key)) is type(value) and artifact[key] == value, "Wrong immutable artifact " + key)
    origin = artifact.get("workflow_run", {})
    require(origin.get("id") == SOURCE_RUN and origin.get("head_sha") == SOURCE and
            origin.get("repository_id") == REPOSITORY_ID and
            origin.get("head_repository_id") == REPOSITORY_ID, "Artifact belongs to a different run/source")
    require(job.get("id") == BUILD_JOB and job.get("run_id") == SOURCE_RUN and
            job.get("head_sha") == SOURCE and job.get("name") == "build" and
            job.get("status") == "completed" and job.get("conclusion") == "success", "Original build did not succeed")
    require(any(s.get("name") == "Independently verify both produced artifacts" and
                s.get("conclusion") == "success" for s in job.get("steps", [])), "Original APK verification did not pass")


def verify_candidate(directory: Path) -> dict:
    apk = directory / "Lumo-Lernen-Neu.apk"
    require(apk.is_file() and apk.stat().st_size == APK_BYTES and digest(apk) == APK_SHA256,
            "Downloaded APK differs from independently verified original bytes")
    proof = read_json((directory / "BUILD-PROVENANCE.json").read_text())
    identity = learning.verify_provenance(proof, sha256=APK_SHA256, source=SOURCE,
                                          native=NATIVE, version=VERSION_CODE, certificate=CERTIFICATE)
    require(identity["versionName"] == VERSION_NAME and identity["godot"]["pck_sha256"] == PCK_SHA256,
            "Wrong original versionName/native pack")
    return identity


def safe_zip_members(archive: zipfile.ZipFile) -> list[zipfile.ZipInfo]:
    """Reject traversal, platform path tricks, links and duplicate aliases first."""
    members, names, total = [], set(), 0
    for item in archive.infolist():
        name = item.filename
        path = PurePosixPath(name)
        require(name and "\\" not in name and ":" not in name and not name.startswith("/") and
                all(part not in ("", ".", "..") for part in name.rstrip("/").split("/")) and
                not any(ord(char) < 32 for char in name), "Unsafe ZIP path: " + repr(name))
        require(path.as_posix() not in names, "Duplicate ZIP path: " + name)
        names.add(path.as_posix())
        kind = stat.S_IFMT(item.external_attr >> 16)
        require(kind in (0, stat.S_IFREG, stat.S_IFDIR) and not item.flag_bits & 1, "Unsupported ZIP member: " + name)
        require(not (item.is_dir() and kind == stat.S_IFREG) and
                not (not item.is_dir() and kind == stat.S_IFDIR), "Inconsistent ZIP member: " + name)
        total += item.file_size
        require(total <= 1500 * 1024 * 1024, "Unreasonable artifact expansion")
        members.append(item)
    require(members, "Empty source artifact")
    file_names = {PurePosixPath(i.filename).as_posix() for i in members if not i.is_dir()}
    require(all(str(parent) not in file_names for name in names for parent in PurePosixPath(name).parents
                if str(parent) != "."), "ZIP file/directory collision")
    return members


def extract_zip(archive_path: Path, directory: Path) -> None:
    require(not directory.exists(), "Candidate directory must be new")
    with zipfile.ZipFile(archive_path) as archive:
        members = safe_zip_members(archive)
        directory.mkdir(parents=True)
        for item in members:
            destination = directory / item.filename
            if item.is_dir():
                destination.mkdir(parents=True, exist_ok=True)
            else:
                destination.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(item) as source, destination.open("xb") as target:
                    shutil.copyfileobj(source, target, length=1024 * 1024)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, newurl):
        return None


def github_request(path: str) -> urllib.request.Request:
    token = os.environ.get("GH_TOKEN", "")
    require(bool(token), "Read-only GH_TOKEN required on the CI runner")
    require(path.startswith("/") and not path.startswith("//"), "Unexpected GitHub resource")
    return urllib.request.Request("https://api.github.com" + path, headers={
        "Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "lumo-reference-qa"})


def api_json(path: str) -> dict:
    with urllib.request.build_opener(NoRedirect()).open(github_request(path), timeout=45) as response:
        return read_json(response.read(5 * 1024 * 1024).decode())


def download(args) -> None:
    require(not args.out.exists() or not any(args.out.iterdir()), "Download evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    prefix = "/repos/" + REPOSITORY + "/actions/"
    run = api_json(prefix + "runs/" + str(SOURCE_RUN))
    artifact = api_json(prefix + "artifacts/" + str(ARTIFACT_ID))
    job = api_json(prefix + "jobs/" + str(BUILD_JOB))
    for name, value in (("original-run", run), ("original-artifact", artifact), ("original-build-job", job)):
        write_json(args.out / (name + ".json"), value)
    verify_origin(run, artifact, job)
    # Never forward repository credentials to the redirect/storage host.
    try:
        response = urllib.request.build_opener(NoRedirect()).open(
            github_request(prefix + "artifacts/" + str(ARTIFACT_ID) + "/zip"), timeout=45)
    except urllib.error.HTTPError as redirect:
        require(redirect.code == 302, "GitHub artifact redirect failed with HTTP " + str(redirect.code))
        url = redirect.headers.get("Location", "")
        parts = urllib.parse.urlsplit(url)
        require(parts.scheme == "https" and parts.hostname and not parts.username and not parts.password,
                "Unsafe artifact redirect")
        response = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "lumo-reference-qa"}), timeout=90)
    archive_path = args.candidate.parent / ("artifact-" + str(ARTIFACT_ID) + ".zip")
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    require(not archive_path.exists(), "Original ZIP may not overwrite a previous download")
    size = 0
    with response, archive_path.open("xb") as stream:
        while block := response.read(1024 * 1024):
            size += len(block)
            require(size <= ZIP_BYTES, "Artifact ZIP exceeds immutable size")
            stream.write(block)
    require(size == ZIP_BYTES and digest(archive_path) == ZIP_SHA256, "Artifact ZIP digest/size mismatch")
    extract_zip(archive_path, args.candidate)
    identity = verify_candidate(args.candidate)
    write_json(args.out / "verified-download.json", {
        "source_run": SOURCE_RUN, "artifact_id": ARTIFACT_ID, "artifact_name": ARTIFACT_NAME,
        "zip_sha256": ZIP_SHA256, "zip_bytes": ZIP_BYTES, "apk_bytes": APK_BYTES,
        "candidate": identity, "qa_commit": args.qa_commit, "apk_rebuilt": False,
        "zip_members": [i.as_posix() for i in args.candidate.rglob("*") if i.is_file()],
    })


def observed_pattern(labels: list[str]) -> dict:
    grammar = r"Das Muster wiederholt sich immer gleich:\s*(.+?)\s*[–—-]\s*\?\s*Welche Form folgt\?"
    prompts = {match.group(0) for label in labels for match in re.finditer(grammar, label, re.DOTALL)}
    require(len(prompts) == 1, "Expected one current complete pattern question")
    prompt = next(iter(prompts))
    match = re.fullmatch(grammar, prompt, re.DOTALL)
    sequence = re.split(r"\s*[–—-]\s*", match.group(1).strip())
    require(len(sequence) == 4 and set(sequence) <= SHAPES and len(set(sequence)) == 2,
            "Expected the displayed grade-1 two-shape sequence")
    periods = [p for p in range(1, len(sequence) // 2 + 1)
               if all(value == sequence[index % p] for index, value in enumerate(sequence))]
    require(periods and min(periods) == 2, "Visible grade-1 sequence does not prove a repeated group of two")
    period = min(periods)
    return {"prompt": prompt, "sequence": sequence, "period": period, "next": sequence[len(sequence) % period]}


def associated_start(nodes, title: str):
    """A repeated start caption must follow this observed title before another start."""
    titles = {learning.bounds(n) for n in nodes if title in learning.node_labels([n]) and learning.bounds(n)}
    require(len(titles) <= 1, "Ambiguous guided lesson title")
    if not titles:
        return None
    heading = next(iter(titles))
    buttons = {learning.bounds(n, min_height=32) for n in nodes
               if n.get("package") == learning.PACKAGE and n.get("enabled") == "true" and
               n.get("clickable") == "true" and "Mit Lumo anfangen" in learning.node_labels([n]) and
               learning.bounds(n, min_height=32)}
    below = [b for b in buttons if b[1] >= heading[3] and b[0] < heading[2] and b[2] > heading[0]]
    if not below:
        return None
    selected = min(below, key=lambda b: b[1])
    # The next card's subject/grade heading may be visible between unrelated
    # targets. Require the source lesson description in the same observed gap.
    expected_description = "Sprechstücke hören, mitklatschen und ein neues Wort selbst gliedern."
    descriptions = [learning.bounds(n) for n in nodes if expected_description in learning.node_labels([n]) and learning.bounds(n)]
    require(any(d[1] >= heading[3] and d[3] <= selected[1] for d in descriptions),
            "Start button is not bound to the visible syllable course description")
    return selected


def normalized(text: str) -> str:
    return re.sub("[^a-z0-9]", "", unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower())


def ocr_phrase_variant(lines: list[dict], label: str) -> str | None:
    for variant in {line.get("variant", "") for line in lines}:
        rows = sorted((line for line in lines if line.get("variant", "") == variant),
                      key=lambda row: (row["bounds"][1], row["bounds"][0]))
        if normalized(label) in normalized(" ".join(row["text"] for row in rows)):
            return variant
    return None


def panel_repeat_target(observations: dict[str, list[dict]], panel: tuple) -> tuple | None:
    """Select the repeat inside a currently observed question-panel envelope.

    The outer footer has another identical caption. The panel's actual pale
    background pixels and its previously observed heading establish its bounds;
    fresh Langsamer/Ein Hinweis captions bind the currently scrolled shortcuts.
    """
    def inside(box):
        return panel[0] <= box[0] < box[2] <= panel[2] and panel[1] <= box[1] < box[3] <= panel[3]
    anchors = [tuple(row["bounds"]) for label in ("Langsamer", "Ein Hinweis")
               for row in observations.get(label, []) if normalized(row["text"]) == normalized(label) and inside(row["bounds"])]
    if not anchors:
        return None
    candidates = {tuple(row["bounds"]) for row in observations["Noch einmal"]
                  if normalized(row["text"]) == normalized("Noch einmal") and inside(row["bounds"]) and
                  row["bounds"][3] <= max(box[3] for box in anchors) + 12}
    if not candidates:
        return None
    target = min(candidates)
    require(all(abs(a - b) <= 12 for box in candidates for a, b in zip(box, target)),
            "Ambiguous repeat controls inside observed question panel")
    return target


def observed_panel_background(source: Path) -> tuple:
    """Locate the real dialog background, preserving the original screenshot.

    The source-defined panel is #fff8e8; the modal shade darkens every surface
    behind it. This reads current pixels, not a viewport-size/layout formula.
    The caller also requires the real Frag Lumo heading before any scroll.
    """
    from PIL import Image, ImageChops
    with Image.open(source) as original:
        red, green, blue = original.convert("RGB").split()
    channels = [channel.point(lambda value, expected=expected: 255 if abs(value - expected) <= 3 else 0)
                for channel, expected in ((red, 255), (green, 248), (blue, 232))]
    mask = ImageChops.multiply(ImageChops.multiply(channels[0], channels[1]), channels[2])
    box = mask.getbbox()
    require(box and box[2] - box[0] >= 160 and box[3] - box[1] >= 100,
            "Current question-panel background not observed")
    area = (box[2] - box[0]) * (box[3] - box[1])
    require(mask.histogram()[255] / area >= .25, "Ambiguous scattered question-panel pixels")
    return box


def action_playback(log: str, pid: int, previous_ids=(), *, segments: int = 1) -> dict | None:
    """Require ordered current-action starts and completions in this native PID."""
    events = [(state, int(turn), profile) for raw_pid, state, turn, profile in learning.speech_events(log)
              if int(raw_pid) == pid and int(turn) not in previous_ids and int(turn) > 0]
    started, complete, active = [], [], None
    for state, turn, profile in events:
        if state == "started":
            require(profile == "lumo-free-supertonic-de-v1", "Unexpected native voice profile")
            require(active is None and turn not in started, "Overlapping or duplicate current-action playback")
            started.append(turn)
            active = turn
        elif turn == active:
            complete.append(turn)
            active = None
        else:
            raise RuntimeError("Completion without its current-action native start")
    require(len(started) <= segments, "Unexpected extra playback in this action window")
    if len(complete) != segments:
        return None
    return {"pid": pid, "utterance_ids": complete, "segments": segments,
            "profile": "lumo-free-supertonic-de-v1", "evidence": "ordered MediaPlayer started/completed callbacks",
            "spoken_words_in_log": False, "audible_quality_verified": False}


def verify_original_success(result: dict, identity: dict) -> None:
    require(result.get("schema") == "lumo.nextgen.learning.android.probe" and
            result.get("status") in ("PASS", "PASS_WITH_LIMITATIONS") and
            result.get("candidate") == identity, "Original probe has not passed on these exact APK bytes")
    require(result.get("historical_tour_pass_used") is False and
            result.get("private_app_data_written_by_probe") is False, "Original probe evidence contract changed")
    installed = result.get("installed", {})
    require(installed.get("sha256") == APK_SHA256 and installed.get("versionCode") == VERSION_CODE and
            installed.get("signingCertificateSha256") == CERTIFICATE, "Original installation identity differs")
    performance = result.get("native_learning", {}).get("performance", {})
    require(performance.get("capture_status") == "MEASURED" and
            10 <= performance.get("scene_observed_seconds", 0) <= 60 and
            performance.get("window_count", 0) >= 2 and performance.get("sample_count", 0) > 0 and
            performance.get("combined_audio_figure_effect_windows") and
            performance.get("current_step_replay_playback", {}).get("utterance_ids") and
            performance.get("video", {}).get("whole_block_within_recording_limit") is True,
            "Original native performance gates did not pass")
    require(result.get("final_profile", {}).get("name") == learning.PROFILE_NAME and
            result.get("final_profile", {}).get("grade") == 1, "Original profile is not the fictional grade-1 fixture")


def attempts(snapshot: dict) -> list[dict]:
    values = json.loads(snapshot["learning"].get("flutter.lumo_attempt_log_v1", "[]"), object_pairs_hook=learning.unique_object)
    require(isinstance(values, list) and all(isinstance(item, dict) and item.get("id") for item in values),
            "Unexpected stored attempt log")
    require(len({item["id"] for item in values}) == len(values), "Duplicate attempt IDs")
    return values


def verify_core_submission(before: dict, after: dict, task: dict) -> dict | None:
    require(before["profile"] == after["profile"], "Core answer changed the active fictional profile")
    old, new = attempts(before), attempts(after)
    old_by_id, new_by_id = {item["id"]: item for item in old}, {item["id"]: item for item in new}
    require(all(new_by_id.get(key) == value for key, value in old_by_id.items()), "Core answer lost or rewrote earlier attempts")
    added = [value for key, value in new_by_id.items() if key not in old_by_id]
    if not added:
        return None
    require(len(added) == 1, "One explicit Core answer produced multiple attempts")
    entry = added[0]
    expected = {"sub": "Logik", "unit": "Muster", "q": task["prompt"], "a": task["next"],
                "e": task["next"], "ok": True, "hint": True}
    require(all(type(entry.get(key)) is type(value) and entry[key] == value for key, value in expected.items()),
            "Stored Core assessment is not this explicit assisted pattern answer")
    return {"status": "PASS", "submission_control": "observed Core answer card", "stored_attempt": entry,
            "changed_learning_keys": sorted(key for key in before["learning"] | after["learning"]
                                            if before["learning"].get(key) != after["learning"].get(key)),
            "native_was_ungraded_before_submission": True}


class ReferenceProbe(learning.LearningProbe):
    def reset_successful_original(self):
        original_path = self.args.previous_probe_out / "learning-android-result.json"
        original = read_json(original_path.read_text())
        identity = verify_candidate(self.args.candidate)
        verify_original_success(original, identity)
        require(original.get("device", {}).get("serial") == self.base.adb("get-serialno") and
                original["device"].get("physical_device") is False and original["device"].get("api") == 35,
                "Original probe did not use this disposable API35 emulator")
        current = learning.learning_snapshot(self.preferences("completed-original-before-reset"))
        require(current["profile"] == original["final_profile"], "Original synthetic profile changed before reset")
        paths = self.base.adb("shell", "pm", "path", learning.PACKAGE).splitlines()
        require(len(paths) == 1 and re.fullmatch(r"package:/data/app/[A-Za-z0-9_+/=.-]+/base\.apk", paths[0]),
                "Original package path missing or ambiguous")
        path = paths[0].removeprefix("package:")
        hashed = self.base.adb("shell", "sha256sum", path).split()
        require(len(hashed) == 2 and hashed[1] == path, "Original installed APK hash unavailable")
        installed = learning.verify_installed_metadata(self.base.adb("shell", "dumpsys", "package", learning.PACKAGE),
                                                        hashed[0], identity)
        record = {"original_result_sha256": digest(original_path), "original_result": str(original_path),
                  "original_status": original["status"], "original_run_id": original["run_id"],
                  "installed_before_reset": installed, "synthetic_profile_before_reset": current["profile"],
                  "package": learning.PACKAGE, "reason": "Fresh UI-created fixture for additional scenes after complete original PASS"}
        self.save("original-probe-verified-before-reset", record)
        output = self.base.adb("uninstall", learning.PACKAGE, timeout=120)
        require("Success" in output.splitlines(), "Removal of the verified synthetic test installation failed")
        record["uninstall_output"] = output
        self.save("verified-synthetic-installation-reset", record)
        self.result["previous_complete_probe"] = record

    def native_see(self, label, tag, *, exact=False):
        if exact or len(label) <= 24:
            self.reader.native_text(self.out, label, self.fresh(tag), exact=exact, orientation="responsive")
            return
        # A real status sentence can wrap. Join actual OCR lines from one
        # captured frame/variant in reading order, never across screenshots.
        for _ in range(8):
            name = self.fresh(tag)
            shot = self.reader.capture(self.out, name)
            lines = self.reader.image_lines(self.out, name, normalized(label),
                                           source_path=self.out / shot["file"], timeout=40)
            variant = ocr_phrase_variant(lines, label)
            if variant is not None:
                self.save(name + "-phrase", {"label": label, "capture": shot, "variant": variant,
                                              "evidence": "current OCR lines in reading order"})
                return
            time.sleep(.6)
        raise RuntimeError("Current native screenshot lacks wrapped status: " + label)

    def native_tap(self, label, tag):
        self.reader.native_tap(self.out, label, self.fresh(tag), exact=True,
                               orientation="responsive", standalone_caption=True)

    def ids(self, pid):
        return {int(turn) for raw_pid, _, turn, _ in learning.speech_events(self.speech_log()) if int(raw_pid) == pid}

    def playback(self, pid, previous, segments=1, timeout=150):
        return self.wait("New complete native action playback", lambda: action_playback(
            self.speech_log(), pid, previous, segments=segments), timeout=timeout)

    def enter_native(self, tag, title):
        self.base.adb("logcat", "-c")
        self.tap(NATIVE_ENTRY, tag + "-visible-3d-entry")
        self.wait("Native learning activity foreground", lambda: self.base.adb("shell", "dumpsys", "activity", "activities"),
                  lambda text: any("LumoGameActivity" in line for line in text.splitlines() if "ResumedActivity" in line), timeout=60)
        pids = self.base.adb("shell", "pidof", learning.PACKAGE + ":lumo_game").split()
        require(len(pids) == 1 and pids[0].isdigit(), "Actual native process missing or ambiguous")
        self.native_see(title, tag + "-native-title")
        self.capture(tag + "-native-entry", native=True)
        return int(pids[0])

    def return_native(self, tag, title):
        self.native_tap("Zur Aufgabe", tag + "-return")
        self.wait("Native process exited after visible return", lambda: self.base.adb(
            "shell", "pidof", learning.PACKAGE + ":lumo_game", check=False), lambda value: not value, timeout=45)
        self.see(title, tag + "-returned-task", scroll=True)
        self.capture(tag + "-flutter-return")

    def question_repeat_target(self):
        self.native_tap("Lumo fragen", "banana-open-question")
        previous, previous_panel, heading_seen = None, None, False
        for attempt in range(12):
            tag = self.fresh("banana-observed-question-panel-" + str(attempt))
            shot = self.reader.capture(self.out, tag)
            source = self.out / shot["file"]
            frame = self.reader.inspect_surface(source, orientation="responsive")
            if not frame["acceptable_for_target_sampling"]:
                previous = None
                continue
            panel = observed_panel_background(source)
            if previous_panel is not None:
                require(all(abs(a - b) <= 12 for a, b in zip(panel, previous_panel)),
                        "Observed question-panel geometry changed unexpectedly")
            previous_panel = panel
            captions = {}
            labels = ("Langsamer", "Ein Hinweis", "Noch einmal") if heading_seen else ("Frag Lumo", "Zurück", "Langsamer", "Ein Hinweis", "Noch einmal")
            for label in labels:
                captions[label] = self.reader.image_lines(self.out, self.fresh("question-caption"), normalized(label),
                                                         source_path=source, exact=True, all_caption_regions=True, timeout=35)
            if not heading_seen:
                for label in ("Frag Lumo", "Zurück"):
                    require(any(normalized(row["text"]) == normalized(label) and
                                panel[0] <= row["bounds"][0] < row["bounds"][2] <= panel[2] and
                                panel[1] <= row["bounds"][1] < row["bounds"][3] <= panel[3]
                                for row in captions[label]), "Real question-panel heading missing: " + label)
                heading_seen = True
            target = panel_repeat_target(captions, panel)
            if target is None:
                self.save(tag + "-scroll", {"capture": shot, "observed_panel_bounds": panel,
                                             "captions": captions, "reason": "Panel shortcuts are not yet visible"})
                x = (panel[0] + panel[2]) // 2
                lower = panel[3] - (panel[3] - panel[1]) // 5
                upper = panel[1] + (panel[3] - panel[1]) // 5
                self.base.adb("shell", "input", "swipe", str(x), str(lower), str(x), str(upper), "400")
                previous = None
                time.sleep(.6)
                continue
            observed = self.reader.target_observation(frame, target, previous)
            self.save(tag + "-target", {"capture": shot, "captions": captions, "target": observed})
            previous = observed
            if observed["stable_observed_target"]:
                require(digest(source) == frame["source_sha256"], "Question-panel screenshot changed")
                return target
        raise RuntimeError("Question-panel repeat did not settle on two actual frames")

    def banana(self):
        self.academy()
        self.tap("Lumo erklärt es mir", "banana-guided-hub")
        with self.recording("banana-guided-navigation"):
            for _ in range(30):
                nodes = self.nodes("banana-guided-course")
                target = associated_start(nodes, "Wörter in Silben hören")
                if target:
                    self.touch(target, "banana-course-start", "Wörter in Silben hören / Mit Lumo anfangen")
                    break
                self.scroll(nodes, 1)
            else:
                raise RuntimeError("Visible syllable course start not found")
            for title in ("Wir hören genau hin", "Sprechen statt Buchstaben zählen"):
                self.see(title, "banana-guided-step", scroll=True, exact=True)
                self.capture("banana-guided-step")
                self.tap("Weiter", "banana-guided-next")
            self.see(BANANA_TITLE, "banana-guided-example", scroll=True, exact=True)
            self.capture("banana-guided-before-native")
        before = learning.learning_snapshot(self.preferences("banana-before-native"))
        with self.recording("banana-native-entry-and-first-playback"):
            pid = self.enter_native("banana", "Wörter bauen")
            self.native_see("Banane", "banana-native-word")
            self.native_see("Als Nächstes kommt die Silbe „Ba“", "banana-first-syllable")
            initial = self.playback(pid, ())
        steps = []
        for index, expected in enumerate(("Als Nächstes kommt die Silbe „na“", "Als Nächstes kommt die Silbe „ne“", "Das Wort hat 3 Silben"), 1):
            with self.recording("banana-visible-syllable-step-" + str(index)):
                previous = self.ids(pid)
                self.native_tap("Nächste Silbe zeigen", "banana-syllable-" + str(index))
                self.native_see(expected, "banana-syllable-status-" + str(index))
                if index == 3:
                    self.native_see("Banane: Ba – na – ne", "banana-complete-visible-word")
                playback = self.playback(pid, previous)
                steps.append({"step": index, "observed_status": expected, "playback": playback,
                              "screenshot": self.capture("banana-syllable-" + str(index), native=True)})
        self.native_see("Schritt anhören", "banana-idle-before-repeat", exact=True)
        target = self.question_repeat_target()
        previous = self.ids(pid)
        with self.recording("banana-four-segment-repeat"):
            self.touch(target, "banana-panel-repeat", "Frag Lumo / Noch einmal")
            repeated = self.playback(pid, previous, segments=4)
            self.native_see("Schritt anhören", "banana-repeat-completed", exact=True)
            capture = self.capture("banana-repeat-completed", native=True)
            lines = self.reader.image_lines(self.out, self.fresh("banana-question-closed"), normalized("Frag Lumo"),
                                           source_path=self.out / capture["file"], exact=True, all_caption_regions=True, timeout=40)
            require(not any(normalized(row["text"]) == normalized("Frag Lumo") for row in lines),
                    "Question panel did not close automatically after repeat")
        repeat_video = self.recordings[-1]
        require(repeat_video["whole_block_within_recording_limit"], "Repeat recording exceeded its actual capture limit")
        with self.recording("banana-return-to-same-guided-step"):
            self.return_native("banana", BANANA_TITLE)
        after = learning.learning_snapshot(self.preferences("banana-after-native"))
        self.result["banana"] = {"current_task": BANANA_TITLE, "word": "Banane", "syllables": ["Ba", "na", "ne"],
                                 "initial_playback": initial, "steps": steps, "repeat_playback": repeated,
                                 "repeat_video": repeat_video, "segment_order_source_contract": ["Banane", "Ba", "na", "ne"],
                                 "segment_words_verified_acoustically": False,
                                 "preservation": learning.require_preserved(before, after), "native_answer_submitted": False}
        self.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        self.see("Lumo erklärt es mir", "banana-back-to-guided-hub")
        self.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        self.see("LUMO AKADEMIE", "banana-back-to-academy")

    def read_pattern(self, tag):
        self.see("Das Muster wiederholt sich immer gleich:", tag, scroll=True)
        return observed_pattern(learning.node_labels(self.nodes(tag + "-current-prompt")))

    def pattern(self):
        with self.recording("pattern-visible-academy-navigation"):
            nodes = self.nodes("pattern-academy")
            if learning.observed_control(nodes, "Alle Fächer"):
                self.tap("Alle Fächer", "pattern-all-subjects")
            self.see("Weitere Lernbereiche", "pattern-more-subjects", scroll=True)
            if not learning.observed_control(self.nodes("pattern-expanded-subjects"), "Logik"):
                self.tap("Weitere Lernbereiche", "pattern-expand-more-subjects")
            self.tap("Logik", "pattern-logic")
            self.tap("Muster", "pattern-unit")
            task = self.read_pattern("pattern-current-question")
            self.capture("pattern-unanswered-before-native")
        before = learning.learning_snapshot(self.preferences("pattern-before-native"))
        with self.recording("pattern-native-entry-and-playback"):
            pid = self.enter_native("pattern", "Muster entdecken")
            self.native_see("Was kommt als Nächstes", "pattern-native-question")
            initial = self.playback(pid, ())
        with self.recording("pattern-observed-group-and-unconfirmed-proposal"):
            previous = self.ids(pid)
            self.native_tap("Gruppe entdecken", "pattern-one-group-hint")
            hint = "Die kleinste Gruppe hat " + str(task["period"]) + " Zeichen"
            self.native_see(hint, "pattern-actual-smallest-period")
            hint_playback = self.playback(pid, previous)
            self.capture("pattern-two-sign-group", native=True)
            # Select a real displayed form; do not use the model-only confirm API.
            self.native_tap(task["next"], "pattern-native-form-proposal")
            self.native_see("Dein Vorschlag ist „" + task["next"] + "“", "pattern-proposal-only")
            self.native_see("Bestätige deine Antwort anschließend", "pattern-visible-return-obligation")
            self.capture("pattern-unconfirmed-native-proposal", native=True)
        with self.recording("pattern-return-to-same-unanswered-question"):
            self.return_native("pattern", "Das Muster wiederholt sich immer gleich:")
            returned = self.read_pattern("pattern-returned-question")
            require(returned == task, "Native return replaced the displayed pattern question")
            # This enabled control is only built while !_answered. Its actual
            # reappearance proves that native demonstration did not score it.
            self.see(NATIVE_ENTRY, "pattern-return-unanswered", scroll=True, exact=True)
            require(learning.observed_control(self.nodes("pattern-unanswered-control"), NATIVE_ENTRY),
                    "Returned task is not an enabled unanswered Core question")
            self.capture("pattern-current-unanswered-return")
        after = learning.learning_snapshot(self.preferences("pattern-after-native"))
        self.result["pattern"] = {"task": task, "returned_task": returned, "initial_playback": initial,
                                  "hint_playback": hint_playback, "observed_group_hint": hint,
                                  "native_proposal": task["next"], "native_confirmation_performed": False,
                                  "core_answer_submitted": False,
                                  "core_submission_boundary": "A Core answer-card tap submits directly; no separate confirmation exists for a native-only proposal.",
                                  "preservation": learning.require_preserved(before, after)}
        # Preserve a separate completed, ungraded roundtrip before any optional
        # normal Core answer. The native proposal itself never gets scored.
        self.save("pattern-ungraded-roundtrip", self.result["pattern"])
        if self.args.submit_core_answer:
            self.submit_pattern_answer(task, after)

    def submit_pattern_answer(self, task, before):
        require(self.read_pattern("pattern-before-explicit-core-answer") == task, "Core task changed before answer selection")
        self.see("Wähle die richtige Antwort:", "pattern-core-answer-heading", scroll=True, exact=True)
        target = None
        for _ in range(8):
            nodes = self.nodes("pattern-observed-core-answer-cards")
            controls = {shape: learning.observed_control(nodes, shape) for shape in SHAPES}
            heading = "Wähle die richtige Antwort:" in learning.node_labels(nodes)
            if heading and all(controls.values()) and len(set(controls.values())) == 4:
                target = controls[task["next"]]
                self.save("pattern-core-observed-answer-controls", {"task": task, "controls": controls})
                break
            self.scroll(nodes, 1)
        if target is None:
            self.result["pattern"]["core_submission"] = {"status": "NOT_EXERCISED",
                "reason": "No simultaneous unique observed Core answer heading and four enabled shape cards; ungraded roundtrip remains separately evidenced."}
            return
        with self.recording("pattern-explicit-core-answer-after-ungraded-return"):
            self.capture("pattern-before-explicit-core-answer")
            self.touch(target, "pattern-explicit-core-answer", "Wähle die richtige Antwort / " + task["next"])
            def observe():
                current = learning.learning_snapshot(self.preferences("pattern-after-explicit-core-answer"))
                return verify_core_submission(before, current, task)
            assessed = self.wait("Actual persisted Core assessment for this question", observe, timeout=45)
            self.capture("pattern-after-explicit-core-assessment")
        self.result["pattern"]["core_answer_submitted"] = True
        self.result["pattern"]["core_submission"] = assessed

    def run(self):
        self.reset_successful_original()
        self.identify_and_install()
        require(self.result["device"]["api"] == 35, "Reference run requires API 35 exactly")
        self.onboard()
        self.configure_local_voice()
        self.banana()
        self.pattern()
        self.result["final_profile"] = learning.learning_snapshot(self.preferences("final-profile-and-progress"))["profile"]
        self.result["status"] = "PASS_WITH_LIMITATIONS"
        self.result["limitations"] = [
            "Same immutable APK in a new disposable installation with a newly UI-created fictional grade-1 profile.",
            "MediaPlayer callbacks prove current native playback, not audible pronunciation or acoustic segment identity; videos have no audio track.",
            "Native pattern selection is ungraded; a later Core assessment is reported only if its current answer card and actual stored result were observed.",
            "No STT, physical Android device, frame-rate, lip-sync, or English-only layout telemetry claim is made by this additional probe.",
        ]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="mode", required=True)
    for mode in ("download", "run"):
        child = commands.add_parser(mode)
        child.add_argument("--candidate", type=Path, required=True)
        child.add_argument("--out", type=Path, required=True)
        child.add_argument("--qa-commit", required=True)
        if mode == "run":
            child.add_argument("--download-evidence", type=Path, required=True)
            child.add_argument("--previous-probe-out", type=Path, required=True)
            child.add_argument("--submit-core-answer", action="store_true")
            child.add_argument("--serial")
    args = parser.parse_args(argv)
    require(learning.valid_hex(args.qa_commit, 40) and args.qa_commit != SOURCE, "A separate immutable QA commit is required")
    if args.mode == "download":
        download(args)
        return 0
    require(not args.out.exists() or not any(args.out.iterdir()), "Runtime evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    result = {"schema": "lumo.nextgen.reference.android.probe", "version": 1, "status": "RUNNING",
              "run_id": uuid.uuid4().hex, "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "qa_commit": args.qa_commit, "apk_source": SOURCE, "native_source": NATIVE,
              "source_workflow_run": SOURCE_RUN, "source_artifact_id": ARTIFACT_ID,
              "probe_sha256": digest(Path(__file__)), "historical_tour_pass_used": False,
              "private_app_data_written_by_probe": False, "apk_rebuilt": False}
    probe = None
    try:
        download_proof = read_json((args.download_evidence / "verified-download.json").read_text())
        verify_origin(*(read_json((args.download_evidence / (name + ".json")).read_text())
                        for name in ("original-run", "original-artifact", "original-build-job")))
        require(download_proof.get("zip_sha256") == ZIP_SHA256 and download_proof.get("artifact_id") == ARTIFACT_ID and
                download_proof.get("qa_commit") == args.qa_commit, "Download evidence is not bound to this QA run")
        identity = verify_candidate(args.candidate)
        require(download_proof.get("candidate") == identity, "Downloaded provenance changed before installation")
        args.apk, args.provenance = args.candidate / "Lumo-Lernen-Neu.apk", args.candidate / "BUILD-PROVENANCE.json"
        args.expected_sha256, args.expected_source, args.expected_native = APK_SHA256, SOURCE, NATIVE
        args.expected_version, args.expected_certificate, args.conversation_ui = VERSION_CODE, CERTIFICATE, "ea"
        require(shutil.which("ffprobe"), "ffprobe is required for actual video validation")
        probe = ReferenceProbe(args, result)
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
        write_json(args.out / "reference-android-result.json", result)
        print(json.dumps({key: result[key] for key in ("status", "run_id", "qa_commit", "apk_source")}), flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
