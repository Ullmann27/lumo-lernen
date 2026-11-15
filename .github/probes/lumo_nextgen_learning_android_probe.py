#!/usr/bin/env python3
"""Current learning acceptance on one fresh, independently identified Android APK.

Run on a disposable rooted x86_64 emulator. Required runtime dependencies are
adb, Android build-tools (aapt/apksigner), ffprobe, Tesseract, Pillow and the
repository's pinned uiautomator2. Only shared reader/capture/OCR helpers are
imported; no historical tour or its main/PASS is executed. All application
actions use visible accessibility or freshly observed native OCR targets.

Example (all identities must come from the current CI candidate):
  python3 .github/probes/lumo_nextgen_learning_android_probe.py \
    --apk candidate.apk --provenance BUILD-PROVENANCE.json \
    --expected-sha256 "$APK_SHA256" --expected-source "$FLUTTER_SHA" \
    --expected-native "$GODOT_SHA" --expected-version 2027 \
    --expected-certificate "$CERT_SHA256" --out evidence/learning

The probe installs the APK itself and rejects an already installed package.
It never writes app preferences, databases, native IPC or progress. Synthetic
answers/profile creation and local voice permission use the real user flow.
PASS_WITH_LIMITATIONS means the specified automated gates passed; neither an
emulator without a spoken input nor a screenrecord without audio certifies real
speech recognition, audible quality, phoneme timing or a physical Fold device.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import hashlib
import importlib
import json
import math
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time
import traceback
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
PROFILE_NAME = "LumoNextTest"
CHECKPOINT_PREFIX = "flutter.lumo_learning_lab_session_v1"
LEARNING_PREFIXES = (
    "flutter.lumo_progress", "flutter.lumo_writing_progress", "flutter.lumo_journal",
    "flutter.lumo_story_library", "flutter.lumo_reading_sessions", "flutter.lumo_attempt_log",
    "flutter.lumo_reward_wallet", "flutter.lumo_school", "flutter.lumo_learning",
    "flutter.lumo_legacy",
)
PROFILE_FIELDS = ("id", "name", "age", "grade", "createdAt")
BRIDGE_PROMPT = "8 + 5 = ? Rechne zuerst bis zur Zehn."
WORD_PROMPT = "Schreibe das Namenwort: Ba – na – ne."
PATTERN_PROMPT = "Kreis – Dreieck – Kreis – Dreieck – Kreis. Welche Form kommt als Nächstes?"
MODEL_ASSENT = ("Als erwachsene Person akzeptiere ich für die lokale Sprachfunktion die "
                "obenstehenden Modellbedingungen einschließlich der Nutzungsbeschränkungen.")
FOLD7_SPECIFICATION = "https://news.samsung.com/global/samsung-galaxy-z-fold7-raising-the-bar-for-smartphones"
DISPLAY_LAYOUTS = (
    ("compact", 720, 1600, 320), ("expanded", 1768, 2208, 360),
    ("fold7-cover-emulated", 1080, 2520, 420),
    ("fold7-inner-emulated", 1968, 2184, 420),
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "Ambiguous duplicate JSON key: " + key)
        result[key] = value
    return result


def read_json(text: str) -> dict:
    value = json.loads(text, object_pairs_hook=unique_object)
    require(isinstance(value, dict), "Expected a JSON object")
    return value


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def valid_hex(value: str, length: int) -> bool:
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{" + str(length) + "}", value) is not None


def verify_provenance(proof: dict, *, sha256: str, source: str, native: str,
                      version: int, certificate: str) -> dict:
    """Reject stale/ambiguous identity before touching the emulator."""
    require(valid_hex(sha256, 64) and valid_hex(certificate, 64), "Full lowercase SHA-256 values required")
    require(valid_hex(source, 40) and valid_hex(native, 40), "Full immutable source commits required")
    require(type(version) is int and version >= 2027, "This probe requires the new learning build, versionCode >= 2027")
    expected = {"sha256": sha256, "flutter_source_commit": source,
                "versionCode": version, "package": PACKAGE,
                "signingCertificateSha256": certificate}
    for key, value in expected.items():
        require(type(proof.get(key)) is type(value) and proof[key] == value,
                "Candidate provenance mismatch: " + key)
    require(proof.get("tracked_source_clean") is True, "Candidate source was not clean")
    require(proof.get("abis") == ["x86_64"], "Expected the standalone x86_64 emulator APK")
    require(isinstance(proof.get("versionName"), str) and bool(proof["versionName"]), "versionName missing")
    godot = proof.get("godot")
    require(isinstance(godot, dict) and godot.get("revision") == native, "Wrong native source provenance")
    require(valid_hex(godot.get("pck_sha256"), 64), "Native pack digest missing")
    return {**expected, "versionName": proof["versionName"], "godot": godot,
            "abis": ["x86_64"], "tracked_source_clean": True}


def verify_manifest_and_signer(badging: str, signer: str, identity: dict) -> None:
    package = re.findall(r"(?m)^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging)
    require(len(package) == 1, "APK manifest identity missing or ambiguous")
    require(package[0] == (PACKAGE, str(identity["versionCode"]), identity["versionName"]),
            "Actual APK manifest differs from expected provenance")
    # SDK output from run 43759362796 uses "V2 Signer:" for the same
    # independently verified certificate. Accept that observed label and the
    # existing numbered format; still require exactly one complete fingerprint.
    certificates = re.findall(
        r"(?m)^(?:Signer #\d+|V2 Signer:) certificate SHA-256 digest: ([0-9a-fA-F]{64})[ \t]*$",
        signer,
    )
    fingerprint_lines = [line for line in signer.splitlines() if "certificate SHA-256 digest:" in line]
    require(len(fingerprint_lines) == 1 and len(certificates) == 1 and
            certificates[0].lower() == identity["signingCertificateSha256"],
            "Actual APK signing certificate differs from expected certificate")


def verify_installed_metadata(package_dump: str, installed_hash: str, identity: dict) -> dict:
    codes = set(re.findall(r"\bversionCode=(\d+)\b", package_dump))
    names = set(re.findall(r"(?m)^\s*versionName=(\S+)\s*$", package_dump))
    require(codes == {str(identity["versionCode"])} and names == {identity["versionName"]},
            "Installed PackageManager version differs from candidate")
    require(installed_hash == identity["sha256"], "Installed APK bytes differ from verified candidate")
    require(re.search(r"Package \[" + re.escape(PACKAGE) + r"\]", package_dump) is not None,
            "Installed package dump does not identify the expected package")
    return {"package": PACKAGE, "versionCode": identity["versionCode"],
            "versionName": identity["versionName"], "sha256": installed_hash,
            "signingCertificateSha256": identity["signingCertificateSha256"],
            "signature_binding": "installed base.apk hash equals independently signature-verified input APK"}


def installed_base_apk_path(raw: str) -> str:
    """Accept one monolithic Android APK path, including opaque ~~ directories.

    The allowed filename alphabet follows the existing fold_device_capture
    reader. Segments must be nonempty and may not be '.' or '..'; package,
    version, signature and exact installed bytes are independently checked.
    """
    require(isinstance(raw, str), "Installed APK path response must be text")
    lines = raw.splitlines()
    require(len(lines) == 1, "Expected exactly one installed base APK")
    match = re.fullmatch(r"package:(/data/app/(?:[A-Za-z0-9_~+=@.-]+/)+base\.apk)", lines[0])
    require(match is not None, "Unsafe or unrecognized installed base APK path")
    path = match[1]
    require(not any(part in (".", "..") for part in path.split("/")), "Installed APK path contains traversal segments")
    return path


def node_labels(nodes) -> list[str]:
    labels = []
    for node in nodes:
        labels.extend(value for key in ("text", "content-desc")
                      if (value := node.get(key, "").strip()))
        # API 35 exposes the empty EA question field's visible placeholder as
        # hint, not text/content-desc (recorded run 43768151118). A hint is not
        # entered text or an actionable control, and disappears once filled.
        if (node.get("package") == PACKAGE and node.get("class") == "android.widget.EditText"
                and node.get("enabled") == "true" and node.get("visible-to-user") == "true"
                and node.get("text", "") == "" and bounds(node, min_height=30)):
            if hint := node.get("hint", "").strip():
                labels.append(hint)
    return labels


def bounds(node, *, min_height: int = 1) -> tuple[int, int, int, int] | None:
    match = re.fullmatch(r"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]", node.get("bounds", ""))
    if not match:
        return None
    x0, y0, x1, y1 = map(int, match.groups())
    if x0 < 0 or y0 < 0 or x1 <= x0 or y1 - y0 < min_height:
        return None
    return x0, y0, x1, y1


def observed_control(nodes, label: str, *, package: str = PACKAGE,
                     equivalent_navigation: bool = False) -> tuple | None:
    matches = set()
    for node in nodes:
        if node.get("package") != package or node.get("enabled") != "true" or node.get("clickable") != "true":
            continue
        if any(label in node.get(key, "").splitlines() for key in ("text", "content-desc")):
            box = bounds(node, min_height=32)
            if box:
                matches.add(box)
    if equivalent_navigation and matches:
        # The actual home card and navigation tab both call setSection(games).
        # This exception is used only for that reviewed, equivalent route.
        require(label == "Spielen", "Only the reviewed home game navigation is equivalent")
        return min(matches, key=lambda b: ((b[2] - b[0]) * (b[3] - b[1]), b))
    require(len(matches) <= 1, "Ambiguous enabled visible control: " + label)
    return next(iter(matches), None)


def observed_scroll_bounds(nodes) -> tuple | None:
    boxes = {box for node in nodes if node.get("package") == PACKAGE and
             node.get("enabled") == "true" and node.get("scrollable") == "true" and
             (box := bounds(node, min_height=100))}
    return max(boxes, key=lambda b: ((b[2] - b[0]) * (b[3] - b[1]), b)) if boxes else None


def visible_scroll_signature(nodes) -> str:
    """Track actual visible content/geometry, excluding fixed chrome outside it."""
    viewport = observed_scroll_bounds(nodes)
    rows = []
    if viewport:
        for node in nodes:
            box = bounds(node)
            if (node.get("package") == PACKAGE and box and
                    box[0] < viewport[2] and box[2] > viewport[0] and
                    box[1] < viewport[3] and box[3] > viewport[1] and node_labels([node])):
                rows.append((node.get("text", ""), node.get("content-desc", ""), box,
                             node.get("clickable", ""), node.get("enabled", ""), node.get("checked", "")))
    return hashlib.sha256(json.dumps([viewport, sorted(rows)], ensure_ascii=False).encode()).hexdigest()


def verify_voice_settings(before: dict, after: dict) -> dict:
    expected = {"localVoiceLicenseAccepted": True, "voiceEnabled": True,
                "autoReadEnabled": True, "microphoneEnabled": True, "calmMode": False}
    for key, wanted in expected.items():
        require(type(after.get(key)) is bool and after[key] is wanted, "Final saved voice setting mismatch: " + key)
    for key in ("scannerEnabled", "aiProxyEnabled", "cloudVoiceEnabled"):
        require(after.get(key, False) == before.get(key, False), "Unexpected unrelated permission change: " + key)
    return {"license": after["localVoiceLicenseAccepted"], "voice": after["voiceEnabled"],
            "auto_read": after["autoReadEnabled"], "microphone": after["microphoneEnabled"],
            "calm_mode": after["calmMode"], "online_services_changed": False}


def learning_snapshot(preferences: dict) -> dict:
    active = read_json(preferences.get("flutter.lumo_active_profile", "{}"))
    require(active.get("id") and active.get("name") == PROFILE_NAME, "Fictional active profile missing or changed")
    records = {key: value for key, value in preferences.items()
               if key.startswith(LEARNING_PREFIXES) and not key.startswith(CHECKPOINT_PREFIX)}
    # Resume checkpoints are compared independently; they are not mastery.
    return {"profile": {key: active.get(key) for key in PROFILE_FIELDS}, "learning": records}


def checkpoint(preferences: dict, topic: str) -> dict | None:
    matches = []
    for key, raw in preferences.items():
        if not key.startswith(CHECKPOINT_PREFIX):
            continue
        data = read_json(raw)
        require(data.get("version") == 1 and isinstance(data.get("sessions"), dict), "Unknown resume schema")
        matches.extend(value for value in data["sessions"].values()
                       if isinstance(value, dict) and value.get("topicId") == topic)
    require(len(matches) <= 1, "Ambiguous task checkpoint for " + topic)
    return matches[0] if matches else None


def require_preserved(before: dict, after: dict, before_task: dict | None = None,
                      after_task: dict | None = None) -> dict:
    require(before == after, "Profile/learning/reward data changed during explanation or lifecycle roundtrip")
    if before_task is not None:
        require(before_task == after_task, "Displayed task/model checkpoint changed during lifecycle roundtrip")
    return {"profile_id": before["profile"]["id"], "learning_keys_compared": len(before["learning"]),
            "same_task_checkpoint": before_task is not None}


def speech_events(log: str):
    return re.findall(r"(?m)^I/LumoLearningSpeech\s*\(\s*(\d+)\):\s*"
                      r"(started|completed) id=(\d+)(?: profile=([\w-]+))?\s*$", log)


def speech_completion(log: str, pid: int, *, previous_ids=()) -> dict:
    """Correlate actual MediaPlayer events to this native process and this turn."""
    starts, complete = set(), set()
    for observed_pid, state, raw_id, profile in speech_events(log):
        turn = int(raw_id)
        if int(observed_pid) != pid or turn <= 0 or turn in previous_ids:
            continue
        if state == "started" and profile == "lumo-free-supertonic-de-v1":
            starts.add(turn)
        if state == "completed" and turn in starts:
            complete.add(turn)
    require(bool(complete), "No new actual local MediaPlayer start/completion in the current native process")
    return {"pid": pid, "utterance_ids": sorted(complete), "profile": "lumo-free-supertonic-de-v1",
            "evidence": "Android MediaPlayer callbacks", "audible_quality_verified": False}


def why_response(labels: list[str]) -> str | None:
    """A current explanation must mention the original quantities and ten."""
    for label in labels:
        lowered = label.lower()
        if "warum zuerst zwei?" in lowered or label == BRIDGE_PROMPT:
            continue
        if (re.search(r"\b(8|acht)\b", lowered) and re.search(r"\b(2|zwei)\b", lowered)
                and re.search(r"\b(10|zehn|zehnerfeld)\b", lowered)
                and any(word in lowered for word in ("weil", "fehlen", "brauch", "bis zur", "bis zehn", "frei", "ergänze"))):
            return label
    return None


def microphone_outcome(labels: list[str]) -> str | None:
    """Recognize actual current UI states, without declaring spoken STT proof."""
    joined = "\n".join(labels).lower()
    if "sprich jetzt" in joined or re.search(r"\bhört (?:dir )?zu\b", joined):
        return "listening_ui_observed"
    if any(text in joined for text in (
        "start nicht bestätigt", "spracherkennung ist auf diesem gerät noch nicht bestätigt",
        "spracheingabe ist nicht bereit",
        "spracherkennung ist auf diesem gerät nicht bereit", "spracherkennung ist nicht verfügbar",
        "sprache ist lokal noch nicht bereit", "mikrofon ist nicht freigegeben",
        "nicht starten", "nicht gestartet",
    )):
        return "explicit_device_limitation"
    return None


PERFORMANCE_COUNTERS = (
    "fox_usable_samples", "speech_playing_samples", "speech_playing_audible_samples",
    "effects_active_samples", "speech_fox_effects_samples",
)


def learning_performance_windows(log: str, pid: int) -> list[dict]:
    """Validate the native producer's actual intervals for this one process."""
    windows = []
    expected = {"schema", "version", "kind", "platform", "renderer", "display_driver", "adapter",
                "reduced_motion", "window_index", "window_ms", "sample_count",
                "frame_ms", "process_ms", "render", *PERFORMANCE_COUNTERS}
    metrics = {
        "frame_ms": {"mean", "p50", "p95", "p99", "max", "over_16_7_count", "over_16_7_fraction"},
        "process_ms": {"mean", "p95", "max"},
        "render": {"draw_calls_mean", "primitives_mean", "render_objects_mean", "objects_mean", "nodes_mean"},
    }

    def number(value, label):
        require(type(value) in (int, float) and math.isfinite(value) and value >= 0,
                "Invalid native performance number: " + label)

    for line in log.splitlines():
        match = re.fullmatch(r"I/(?:godot|Godot)\s*\(\s*(\d+)\s*\):\s*LUMO_LEARNING_PERF (\{.*\})\s*", line)
        if not match or int(match[1]) != pid:
            continue
        require(len(match[2]) <= 8000, "Oversized native performance record")
        report = read_json(match[2])
        require(set(report) == expected, "Unexpected native performance schema fields")
        require(report["schema"] == "lumo.learning.perf" and type(report["version"]) is int and
                report["version"] == 1, "Unknown native performance schema/version")
        require(report["kind"] == "bridge_ten" and report["platform"] == "Android",
                "Performance does not describe the actual Android 8+5 scene")
        for key in ("renderer", "display_driver", "adapter"):
            require(isinstance(report[key], str) and 0 < len(report[key]) <= 120,
                    "Missing native rendering identity: " + key)
        require(type(report["reduced_motion"]) is bool, "Invalid native reduced-motion observation")
        index, count = report["window_index"], report["sample_count"]
        require(type(index) is int and index >= 0 and
                (not windows or index > windows[-1]["window_index"]),
                "Repeated or stale native performance window")
        require(type(count) is int and count > 0, "Native performance has no actual frame samples")
        number(report["window_ms"], "window_ms")
        require(5000 <= report["window_ms"] <= 60000,
                "Native performance requires complete five-second measurement windows")
        for group, keys in metrics.items():
            require(isinstance(report[group], dict) and set(report[group]) == keys,
                    "Missing native performance metrics: " + group)
            for key in keys:
                number(report[group][key], group + "." + key)
        frame, process = report["frame_ms"], report["process_ms"]
        require(0 < frame["mean"] <= frame["max"] + .000001 and
                frame["p50"] <= frame["p95"] <= frame["p99"] <= frame["max"],
                "Inconsistent measured native frame times")
        require(abs(frame["mean"] * count - report["window_ms"]) <= 1,
                "Measured native frame intervals do not match elapsed window time")
        require(process["mean"] <= process["max"] + .000001 and process["p95"] <= process["max"],
                "Inconsistent measured native process times")
        over = frame["over_16_7_count"]
        require(type(over) is int and 0 <= over <= count and
                0 <= frame["over_16_7_fraction"] <= 1 and
                abs(frame["over_16_7_fraction"] - over / count) <= .001,
                "Inconsistent observed frame-budget count/fraction")
        for key in PERFORMANCE_COUNTERS:
            require(type(report[key]) is int and 0 <= report[key] <= count,
                    "Invalid measured native co-occurrence counter: " + key)
        require(report["speech_playing_audible_samples"] <= report["speech_playing_samples"] and
                report["speech_fox_effects_samples"] <= min(
                    report["speech_playing_audible_samples"], report["fox_usable_samples"],
                    report["effects_active_samples"]), "Inconsistent audio/figure/effect observations")
        require(not report["reduced_motion"] or report["effects_active_samples"] == 0,
                "Reduced-motion scene claims moving effects")
        windows.append(report)
    return windows


def learning_performance_summary(windows: list[dict], pid: int, seconds: float) -> dict:
    require(10 <= seconds <= 60, "Native performance observation must last 10 to 60 seconds")
    require(len(windows) >= 2, "Two actual native performance windows are required")
    combined = [w["window_index"] for w in windows if w["speech_fox_effects_samples"] > 0]
    require(combined, "No measured window contains audible speech, usable figure and moving effects together")
    count = sum(w["sample_count"] for w in windows)
    covered_ms = sum(w["window_ms"] for w in windows)
    require(10000 <= covered_ms <= seconds * 1000 + 100,
            "Native measurement windows exceed the current observation period")
    mean = sum(w["frame_ms"]["mean"] * w["sample_count"] for w in windows) / count
    over = sum(w["frame_ms"]["over_16_7_count"] for w in windows)
    return {
        "capture_status": "MEASURED", "native_pid": pid, "scene_observed_seconds": seconds,
        "window_count": len(windows), "sample_count": count, "windows": windows,
        "measured_window_seconds": covered_ms / 1000,
        "combined_audio_figure_effect_windows": combined,
        "mean_process_frame_interval_ms": mean, "mean_process_frame_rate_hz": 1000 / mean,
        "process_frames_over_16_7_ms": over, "process_frames_over_16_7_fraction": over / count,
        "worst_window_p95_ms": max(w["frame_ms"]["p95"] for w in windows),
        "worst_window_p99_ms": max(w["frame_ms"]["p99"] for w in windows),
        "minimum_samples_per_window": min(w["sample_count"] for w in windows),
        "windows_with_fewer_than_100_samples": [w["window_index"] for w in windows if w["sample_count"] < 100],
        "percentile_boundary": "Nearest-rank percentiles describe these samples only. With fewer than 100 samples, P99 selects the maximum; small windows do not establish a stable tail-latency estimate.",
        "physical_device_60fps_verified": False,
        "measurement_boundary": "Actual Godot _process intervals in the Android emulator; per-window percentiles are not global percentiles or display presentation timestamps.",
        "audio_boundary": "Accepted native playing/audible status; no human listening or acoustic waveform capture.",
    }


class LearningProbe:
    def __init__(self, args, result: dict):
        self.args, self.out, self.result = args, args.out, result
        for path in (ROOT / "scripts", ROOT / "scripts/probes", ROOT / "tools/android_qa", Path(__file__).parent):
            sys.path.insert(0, str(path))
        if args.serial:
            os.environ["ANDROID_SERIAL"] = args.serial
        self.reader = importlib.import_module("creative_android_probe")
        self.base, self.live = self.reader.base, self.reader.live
        self.verifier = importlib.import_module("verify_android_apk")
        self.counter = 0
        self.recordings = []

    def save(self, name, value):
        (self.out / (name + ".json")).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")

    def fresh(self, tag):
        self.counter += 1
        return f"{self.counter:04d}-{tag}"

    def nodes(self, tag):
        return self.live.live_nodes(self.out, self.fresh(tag))

    def wait(self, description, observe, accept=bool, timeout=45):
        deadline, last = time.monotonic() + timeout, None
        while time.monotonic() < deadline:
            last = observe()
            if accept(last):
                return last
            time.sleep(.6)
        raise RuntimeError(description + " not observed before deadline; last=" + repr(last)[:1200])

    def touch(self, box, tag, label):
        self.save(self.fresh(tag + "-touch"), {"label": label, "observed_bounds": box})
        x, y = str((box[0] + box[2]) // 2), str((box[1] + box[3]) // 2)
        self.base.adb("shell", "input", "swipe", x, y, x, y, "120")
        time.sleep(.6)

    def scroll(self, nodes, direction):
        box = observed_scroll_bounds(nodes)
        if box is None:
            return False
        x, low, high = (box[0] + box[2]) // 2, box[1] + (box[3] - box[1]) // 5, box[3] - (box[3] - box[1]) // 5
        start, end = (low, high) if direction < 0 else (high, low)
        self.base.adb("shell", "input", "swipe", str(x), str(start), str(x), str(end), "400")
        time.sleep(.7)
        return True

    def seek_scrolled(self, select, tag, *, max_scrolls=64, timeout=120, readiness_timeout=15):
        """Search forward first and observe after every gesture, including last.

        The former 17-up/17-down sequence could merely return to the starting
        position on the long parent page. Reverse only after two unchanged
        observed views; retain a bounded deadline and exact target validation.
        """
        deadline = time.monotonic() + timeout
        journal = {"status": "NOT_FOUND", "strategy": "forward_then_observed_boundary_reverse",
                   "non_scroll_observations": 0, "gestures": []}
        try:
            nodes = self.nodes(tag)
            found = select(nodes)
            if found is not None:
                journal["status"] = "FOUND"
                return found
            for direction in (1, -1):
                unchanged = 0
                for _ in range(max_scrolls):
                    if time.monotonic() >= deadline:
                        journal["reason"] = "bounded search deadline"
                        return None
                    viewport = observed_scroll_bounds(nodes)
                    # A newly entered Flutter page or ordinary dialog may have
                    # no scrollable semantics yet. Keep observing for a bounded
                    # time; never invent a gesture area while it is absent.
                    readiness_deadline = min(deadline, time.monotonic() + readiness_timeout)
                    while viewport is None:
                        if time.monotonic() >= readiness_deadline:
                            journal["reason"] = "bounded wait without target or scrollable viewport"
                            return None
                        time.sleep(.6)
                        nodes = self.nodes(tag)
                        journal["non_scroll_observations"] += 1
                        found = select(nodes)
                        if found is not None:
                            journal["status"] = "FOUND"
                            return found
                        viewport = observed_scroll_bounds(nodes)
                    before = visible_scroll_signature(nodes)
                    if not self.scroll(nodes, direction):
                        journal["reason"] = "no current enabled scrollable viewport"
                        return None
                    nodes = self.nodes(tag)
                    after = visible_scroll_signature(nodes)
                    journal["gestures"].append({"direction": direction, "observed_bounds": viewport,
                                                  "before": before, "after": after, "content_changed": before != after})
                    # Never perform a final gesture without observing its result.
                    found = select(nodes)
                    if found is not None:
                        journal["status"] = "FOUND"
                        return found
                    unchanged = unchanged + 1 if before == after else 0
                    if unchanged >= 2:
                        break
                else:
                    journal["reason"] = "bounded gesture limit before an observed boundary"
                    return None
            journal["reason"] = "target absent after both observed boundaries"
            return None
        finally:
            self.save(self.fresh(tag + "-scroll-search"), journal)

    def see(self, text, tag, *, scroll=False, exact=False):
        def select(nodes):
            labels = node_labels(nodes)
            return labels if any(text in label.splitlines() if exact else text in label for label in labels) else None
        if scroll:
            found = self.seek_scrolled(select, tag)
            if found is not None:
                return found
        else:
            for _ in range(30):
                found = select(self.nodes(tag))
                if found is not None:
                    return found
                time.sleep(.6)
        raise RuntimeError("Current visible Flutter text missing: " + text)

    def tap(self, text, tag, *, scroll=True, equivalent_navigation=False):
        # Unlike a historical tap helper, only enabled, unique actionable nodes
        # are accepted. Every scrolling gesture also uses current live bounds.
        def select(nodes):
            return observed_control(nodes, text, equivalent_navigation=equivalent_navigation)
        if scroll:
            box = self.seek_scrolled(select, tag)
            if box is not None:
                self.touch(box, tag, text)
                return
        else:
            for _ in range(25):
                box = select(self.nodes(tag))
                if box is not None:
                    self.touch(box, tag, text)
                    return
                time.sleep(.6)
        raise RuntimeError("No unique enabled live Flutter control: " + text)

    def capture(self, tag, *, native=False):
        name = self.fresh(tag)
        result = (self.reader.capture(self.out, name) if native else
                  self.reader.capture_flutter_ready(self.out, name, timeout=45))
        self.result.setdefault("screenshots", []).append(result)
        return result

    def preferences(self, tag):
        return self.reader.prefs(self.out, self.fresh(tag))

    def read_installed_base_apk_path(self, tag):
        raw = self.base.adb("shell", "pm", "path", PACKAGE)
        # Preserve the original reader response even if path validation fails.
        (self.out / (tag + "-pm-path.txt")).write_text(raw)
        return installed_base_apk_path(raw)

    def checkpoint(self, topic, **expected):
        def observe():
            return checkpoint(self.preferences(topic + "-checkpoint"), topic)
        return self.wait("Current persisted " + topic + " task/model", observe,
                         lambda item: item is not None and all(item.get(k) == v for k, v in expected.items()))

    def type_text(self, text, tag):
        require(re.fullmatch(r"[A-Za-z0-9 ?,.'-]+", text) is not None, "Only explicit ASCII test input is supported")
        nodes = self.nodes(tag)
        fields = [n for n in nodes if n.get("package") == PACKAGE and n.get("class") == "android.widget.EditText"
                  and n.get("enabled") == "true" and bounds(n, min_height=30)]
        require(len(fields) == 1, "Exactly one observed editable test field required")
        self.touch(bounds(fields[0]), tag, "observed EditText")
        if fields[0].get("text"):
            current = fields[0].get("text", "")
            require(len(current) <= 200, "Unexpected long pre-existing text in test input")
            self.base.adb("shell", "input", "keyevent", "KEYCODE_MOVE_END")
            self.base.adb("shell", "input", "keyevent", *(["KEYCODE_DEL"] * len(current)))
        # adb invokes a remote shell. Quote the controlled ASCII payload again
        # for that shell; do not pass punctuation/globs unquoted to input text.
        payload = text.replace(" ", "%s").replace("'", "'\"'\"'")
        self.base.adb("shell", "input", "text", "'" + payload + "'")
        self.wait("Real text input " + text, lambda: self.nodes(tag + "-written"),
                  lambda ns: any(n.get("class") == "android.widget.EditText" and n.get("text") == text for n in ns))
        ime = self.base.adb("shell", "settings", "get", "secure", "default_input_method").split("/", 1)[0]
        if any(n.get("package") == ime for n in self.nodes(tag + "-ime")):
            self.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
            time.sleep(.5)

    @contextmanager
    def recording(self, tag):
        """Retain real short video segments; screenrecord's 180 s limit is explicit."""
        name = self.fresh(tag)
        remote = "/sdcard/lumo-learning-" + self.result["run_id"] + "-" + name + ".mp4"
        before = set(self.base.adb("shell", "pidof", "screenrecord", check=False).split())
        require(not before, "Another screenrecord is active; refusing to stop or reuse it")
        log = (self.out / (name + "-screenrecord.txt")).open("w")
        process = subprocess.Popen(["adb", "shell", "screenrecord", "--time-limit", "180",
                                    "--bit-rate", "4000000", remote], stdout=log, stderr=subprocess.STDOUT)
        began = time.monotonic()
        owned = None
        try:
            pids = self.wait("Own Android screenrecord", lambda: self.base.adb("shell", "pidof", "screenrecord", check=False).split())
            require(len(pids) == 1 and pids[0].isdigit(), "Recorder identity is ambiguous")
            owned = pids[0]
            yield
        finally:
            capture_block_seconds = time.monotonic() - began
            if owned and owned in self.base.adb("shell", "pidof", "screenrecord", check=False).split():
                self.base.adb("shell", "kill", "-2", owned)
            try:
                process.wait(timeout=20)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=5)
            log.close()
            if owned:
                local = self.out / (name + ".mp4")
                self.base.adb("pull", remote, str(local), timeout=90)
                metadata = read_json(self.base.command("ffprobe", "-v", "error", "-show_streams", "-show_format",
                                                      "-of", "json", str(local)))
                videos = [s for s in metadata.get("streams", []) if s.get("codec_type") == "video"]
                require(len(videos) == 1 and float(metadata.get("format", {}).get("duration", 0)) > 0,
                        "No decodable actual video was recorded")
                entry = {"file": local.name, "sha256": digest(local), "bytes": local.stat().st_size,
                         "duration_seconds": float(metadata["format"]["duration"]),
                         "width": videos[0]["width"], "height": videos[0]["height"],
                         "audio_recorded": False, "maximum_seconds": 180,
                         "block_elapsed_seconds": round(capture_block_seconds, 2),
                         "whole_block_within_recording_limit": capture_block_seconds < 180}
                self.recordings.append(entry)
                self.save(name + "-video", entry)
                self.result["videos"] = self.recordings

    def identify_and_install(self):
        args = self.args
        proof_raw = args.provenance.read_text()
        identity = verify_provenance(read_json(proof_raw), sha256=args.expected_sha256,
                                     source=args.expected_source, native=args.expected_native,
                                     version=args.expected_version, certificate=args.expected_certificate)
        require(digest(args.apk) == identity["sha256"], "Candidate APK SHA-256 mismatch")
        (self.out / "candidate-BUILD-PROVENANCE.json").write_text(proof_raw)
        tools = Path(self.verifier.find_apksigner()).parent
        signer = self.base.command(str(tools / "apksigner"), "verify", "--print-certs", str(args.apk), timeout=120)
        badging = self.base.command(str(tools / "aapt"), "dump", "badging", str(args.apk), timeout=120)
        (self.out / "candidate-signature.txt").write_text(signer)
        (self.out / "candidate-manifest.txt").write_text(badging)
        verify_manifest_and_signer(badging, signer, identity)
        with zipfile.ZipFile(args.apk) as archive:
            embedded = read_json(archive.read("assets/lumo_game_source.json").decode())
            with archive.open("assets/lumo_game.pck") as stream:
                pck_hash = hashlib.file_digest(stream, "sha256").hexdigest()
            require(embedded.get("revision") == args.expected_native and
                    embedded.get("pck_sha256") == pck_hash == identity["godot"]["pck_sha256"],
                    "Embedded native source/pack differs from current provenance")
        self.result["candidate"] = identity
        root = self.reader.ensure_rooted_emulator(self.base.adb, self.out)
        require(root.get("serial") == self.base.adb("get-serialno"), "Rooted emulator identity changed")
        api = int(self.base.adb("shell", "getprop", "ro.build.version.sdk"))
        abi = self.base.adb("shell", "getprop", "ro.product.cpu.abi")
        require(api >= 35 and abi == "x86_64", "Expected API 35+ x86_64 disposable emulator")
        existing = self.base.adb("shell", "pm", "list", "packages", PACKAGE).splitlines()
        require("package:" + PACKAGE not in existing, "Package already installed; a genuinely fresh installation is required")
        self.result["device"] = {"serial": root["serial"], "api": api, "abi": abi,
                                  "package_absent_before_install": True, "physical_device": False}
        output = self.base.adb("install", str(args.apk.resolve()), timeout=180)
        (self.out / "fresh-install.txt").write_text(output)
        require("Success" in output.splitlines(), "Fresh APK installation did not succeed")
        installed_path = self.read_installed_base_apk_path("installed")
        hashed = self.base.adb("shell", "sha256sum", installed_path)
        (self.out / "installed-apk-sha256.txt").write_text(hashed)
        require(re.fullmatch(r"[0-9a-f]{64}\s+" + re.escape(installed_path), hashed) is not None,
                "Installed APK hash could not be read")
        dump = self.base.adb("shell", "dumpsys", "package", PACKAGE)
        (self.out / "installed-package.txt").write_text(dump)
        self.result["installed"] = verify_installed_metadata(dump, hashed.split()[0], identity)
        self.base.adb("logcat", "-c")
        self.base.launch(self.out, "fresh-first-launch")

    def onboard(self):
        with self.recording("onboarding"):
            self.tap("Los geht's!", "welcome")
            self.see("Wie heißt du?", "profile-name")
            self.type_text(PROFILE_NAME, "fictional-name")
            self.tap("Weiter", "name-next")
            self.see("Wie alt bist du?", "profile-age")
            self.tap("Weiter", "age-next")
            self.see("In welche Klasse gehst du?", "profile-grade")
            self.tap("Profil speichern", "profile-save")
            self.see(PROFILE_NAME, "synthetic-home")
            stored = self.preferences("synthetic-profile")
            active = learning_snapshot(stored)["profile"]
            require(active["grade"] == 1, "The grade-1 reference profile was not created by onboarding")
            self.result["onboarding"] = {"profile": active, "input": "real Android text input", "synthetic": True}
            self.capture("home-after-onboarding")

    def settings(self, tag):
        return read_json(self.preferences(tag).get("flutter.lumo_app_settings_v1", "{}"))

    def configure_local_voice(self):
        # Settings are exposed on the actual game hub; no game is launched.
        self.tap("Spielen", "home-game-hub", equivalent_navigation=True)
        self.tap("Einstellungen", "parent-settings")
        self.see("Elternbereich", "parent-settings-open")
        before = self.settings("voice-before")
        if before.get("localVoiceLicenseAccepted") is not True:
            self.tap("Neue Sätze offline vorlesen", "local-license")
            self.see("Neue Sätze kostenlos vorlesen", "license-dialog")
            self.tap(MODEL_ASSENT, "license-checkbox")
            self.capture("local-model-conditions")
            self.tap("Lokale Stimme freigeben", "license-confirm")
            self.wait("Local model assent persisted", lambda: self.settings("license-saved"),
                      lambda s: s.get("localVoiceLicenseAccepted") is True)
        for label, key, wanted in (("Lumo-Stimme", "voiceEnabled", True),
                                    ("Automatisch vorlesen", "autoReadEnabled", True),
                                    ("Mikrofon erlauben", "microphoneEnabled", True),
                                    ("Ruhiger Modus", "calmMode", False)):
            current = self.settings("read-" + key)
            require(type(current.get(key)) is bool, "Missing actual setting: " + key)
            if current[key] != wanted:
                self.tap(label, "set-" + key)
                self.wait("Saved setting " + key, lambda: self.settings("saved-" + key),
                          lambda s: s.get(key) is wanted)
        after = self.settings("voice-after")
        self.result["local_voice_settings"] = verify_voice_settings(before, after)
        self.capture("local-voice-ready")

    def academy(self):
        self.tap("Lernen", "academy-tab")
        self.see("LUMO AKADEMIE", "academy-open")
        self.tap("Lernwerkzeuge & Geschichten", "academy-tools")
        self.see("Dein Lernatelier", "academy-tools-open", scroll=True)

    def open_lab(self):
        self.tap("Lumos interaktives Lernatelier", "lab-entry")
        self.see("Lumos Lernatelier", "lab-hub")

    def close_task(self):
        self.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        self.see("Lumos Lernatelier", "return-lab-hub")

    def stop_task(self, prompt, tag):
        self.tap("Stopp", tag + "-stop")
        self.see("Die Erklärung ist angehalten. Deine Aufgabe bleibt liegen.", tag + "-stopped", scroll=True)
        self.see(prompt, tag + "-same-prompt", scroll=True, exact=True)
        self.capture(tag + "-stopped-same-task")

    def task_roundtrips(self, topic, title, prompt, **model):
        before_task = self.checkpoint(topic, phase="example", **model)
        before = learning_snapshot(self.preferences(topic + "-before-roundtrips"))
        with self.recording(topic + "-pause-return"):
            self.capture(topic + "-before-pause")
            self.base.adb("shell", "input", "keyevent", "KEYCODE_HOME")
            foreground = self.base.adb("shell", "dumpsys", "activity", "activities")
            resumed = "\n".join(line for line in foreground.splitlines() if "ResumedActivity" in line or "topResumedActivity" in line)
            require(PACKAGE not in resumed, "App did not actually leave the foreground")
            (self.out / self.fresh(topic + "-paused-activity.txt")).write_text(resumed)
            time.sleep(2)
            self.base.launch(self.out, self.fresh(topic + "-resume"))
            self.see(prompt, topic + "-resumed-task", scroll=True, exact=True)
            self.capture(topic + "-after-pause")
        after_task = self.checkpoint(topic, **model)
        after = learning_snapshot(self.preferences(topic + "-after-pause"))
        pause = require_preserved(before, after, before_task, after_task)
        self.close_task()
        self.tap(title, topic + "-reenter")
        self.see(prompt, topic + "-reopened-prompt", scroll=True, exact=True)
        reopen_task = self.checkpoint(topic, **model)
        reopened = learning_snapshot(self.preferences(topic + "-after-return"))
        returned = require_preserved(before, reopened, before_task, reopen_task)
        self.capture(topic + "-same-model-after-return")
        return {"checkpoint": before_task, "pause_resume": pause, "route_return": returned}

    def resize_bridge(self):
        before_task = self.checkpoint("bridge", moved=1)
        before = learning_snapshot(self.preferences("bridge-before-resize"))
        original_size = self.base.adb("shell", "wm", "size")
        original_density = self.base.adb("shell", "wm", "density")
        self.save("display-original", {"size": original_size, "density": original_density})
        states = []
        try:
            for name, width, height, density in DISPLAY_LAYOUTS:
                self.base.display(width, height, density)
                actual_size = self.base.adb("shell", "wm", "size")
                actual_density = self.base.adb("shell", "wm", "density")
                sizes = re.findall(r"(?m)^(?:Physical|Override) size:\s*(\d+)x(\d+)\s*$", actual_size)
                densities = re.findall(r"(?m)^(?:Physical|Override) density:\s*(\d+)\s*$", actual_density)
                require(sizes and tuple(map(int, sizes[-1])) == (width, height) and
                        densities and int(densities[-1]) == density,
                        "Actual Android display configuration differs from requested test layout")
                display = {"layout": name, "width": width, "height": height,
                           "android_test_density_dpi": density, "wm_size": actual_size,
                           "wm_density": actual_density, "physical_ppi_claimed": False}
                self.save(self.fresh(name + "-display"), display)
                with self.recording("bridge-resize-" + name):
                    self.see(BRIDGE_PROMPT, "bridge-" + name + "-prompt", scroll=True, exact=True)
                    self.see("Verschobener Stein 1, zurück in den Vorrat", "bridge-" + name + "-model", scroll=True)
                    capture = self.capture("bridge-" + name)
                    require((capture["width"], capture["height"]) == (width, height), "Resize did not produce requested pixels")
                    states.append({**display, "screenshot": capture,
                                   "preservation": require_preserved(
                                       before, learning_snapshot(self.preferences(name + "-prefs")),
                                       before_task, self.checkpoint("bridge", moved=1))})
        finally:
            for command, original in (("size", original_size), ("density", original_density)):
                override = re.search(r"Override (?:size|density):\s*(\S+)", original)
                self.base.adb("shell", "wm", command, override[1] if override else "reset")
            time.sleep(2)
        self.see(BRIDGE_PROMPT, "bridge-restored-display-prompt", scroll=True, exact=True)
        restored = require_preserved(before, learning_snapshot(self.preferences("bridge-restored-display-prefs")),
                                     before_task, self.checkpoint("bridge", moved=1))
        return {"layouts": [f"{w}x{h}@{d}dpi" for _, w, h, d in DISPLAY_LAYOUTS],
                "observations": states, "restored_display_preservation": restored,
                "fold7_pixel_specification_source": FOLD7_SPECIFICATION,
                "fold7_scope": "Emulated Galaxy Z Fold7 portrait resolutions with a chosen Android 420-dpi test density. This logical density is not the physical pixel density (PPI).",
                "physical_fold_verified": False, "hinge_verified": False}

    def conversation(self):
        chat4 = self.args.conversation_ui == "chat4"
        input_label = "Frag Lumo oder tippe deine Antwort" if chat4 else "Frag Lumo"
        stop_label = "Gestoppt." if chat4 else "Ich habe aufgehört. Du kannst in Ruhe weitermachen."
        mic_label = "Gespräch starten" if chat4 else "Sprechen"
        self.tap("Frage an Lumo", "task-conversation")
        self.see(input_label, "current-conversation-input", scroll=True, exact=True)
        self.type_text("Warum zuerst zwei?", "why-first-two")
        self.tap("Senden", "why-send")
        self.see("Geprüfte Aufgabenhilfe auf diesem Gerät." if chat4 else "Deine Aufgabe",
                 "grounded-task-dialogue", scroll=True)
        self.see(BRIDGE_PROMPT, "conversation-current-task", scroll=True, exact=True)
        response = None
        for direction in (-1, 1):
            for _ in range(17):
                nodes = self.nodes("typed-why-answer")
                response = why_response(node_labels(nodes))
                if response:
                    break
                self.scroll(nodes, direction)
            if response:
                break
        require(response is not None, "No current grounded explanation of eight, two and ten was visible")
        self.capture("typed-why-response")
        # The transcript is evidence, not an answer/score API. No confirmation
        # button is pressed and this dialogue must not award any progress.
        self.tap("Stopp", "conversation-stop")
        self.see(stop_label, "conversation-stopped", scroll=True)
        self.see("Mikrofon aus" if chat4 else "Sprechen", "conversation-mic-off", scroll=True)
        self.capture("conversation-stopped")
        services = self.base.adb("shell", "cmd", "package", "query-services", "--brief", "-a",
                                 "android.speech.RecognitionService", check=False)
        (self.out / "recognition-services.txt").write_text(services)
        self.tap(mic_label, "real-microphone-request")
        # Grant only a currently displayed Android microphone permission. The
        # English and German captions are Android system UI, not app fallbacks.
        deadline = time.monotonic() + 35
        observed = []
        while time.monotonic() < deadline:
            nodes = self.nodes("microphone-outcome")
            labels = node_labels(nodes)
            observed = labels
            system = [n for n in nodes if n.get("package") in ("com.android.permissioncontroller", "com.google.android.permissioncontroller")]
            if system:
                allowed = []
                for caption in ("While using the app", "WHILE USING THE APP", "Bei Nutzung der App", "BEI NUTZUNG DER APP"):
                    for package in ("com.android.permissioncontroller", "com.google.android.permissioncontroller"):
                        box = observed_control(system, caption, package=package)
                        if box:
                            allowed.append((caption, box))
                require(len(allowed) == 1, "Observed microphone permission has no unambiguous allow control")
                self.touch(allowed[0][1], "microphone-permission", allowed[0][0])
                continue
            observed_state = microphone_outcome(labels)
            if observed_state is not None:
                break
            time.sleep(.6)
        else:
            raise RuntimeError("Microphone request produced neither listening state nor explicit device limitation")
        self.save("microphone-observation", {"labels": observed, "services": services,
                                             "observed_state": observed_state})
        self.capture("actual-microphone-outcome")
        self.tap("Stopp", "microphone-stop")
        self.see(stop_label, "microphone-stopped", scroll=True)
        self.see("Mikrofon aus" if chat4 else "Sprechen", "microphone-off", scroll=True)
        self.tap("Zurück zur Aufgabe", "conversation-return")
        self.see(BRIDGE_PROMPT, "conversation-returned-task", scroll=True, exact=True)
        return {"ui_contract": self.args.conversation_ui, "typed_question": "Warum zuerst zwei?",
                "visible_explanation": response, "task_grounding_label_observed": True,
                "stop_visible": True, "microphone_request_observed": True,
                "microphone_ui_outcome": observed_state,
                "recognition": "NOT_VERIFIED", "recognition_observations": observed,
                "limitation": "No real spoken utterance was supplied; emulator recognizer availability is recorded separately."}

    def labs(self):
        self.open_lab()
        self.tap("Die Zehnerbrücke", "bridge-entry")
        self.see(BRIDGE_PROMPT, "current-eight-plus-five", scroll=True, exact=True)
        with self.recording("eight-plus-five-explanation"):
            self.tap("Hilf mir", "bridge-hint")
            self.stop_task(BRIDGE_PROMPT, "bridge")
            before = learning_snapshot(self.preferences("conversation-learning-before"))
            self.result["conversation"] = self.conversation()
            require_preserved(before, learning_snapshot(self.preferences("conversation-learning-after")))
            self.tap("Vorratsstein 1, ins Feld verschieben", "bridge-move-one")
            self.checkpoint("bridge", problemId="bridge-8-5", moved=1, phase="example")
        self.result["bridge"] = self.task_roundtrips("bridge", "Die Zehnerbrücke", BRIDGE_PROMPT, moved=1)
        self.result["bridge"]["resize"] = self.resize_bridge()
        self.close_task()

        self.tap("Die Wortwerkstatt", "word-entry")
        self.see(WORD_PROMPT, "current-banane", scroll=True, exact=True)
        with self.recording("banane-syllables"):
            for caption in ("Ba, Baustein 3, anlegen", "na, Baustein 4, anlegen", "ne, Baustein 1, anlegen"):
                self.tap(caption, "word-build")
            self.checkpoint("words", problemId="word-banane", tokens=[2, 3, 0], phase="example")
            self.tap("Silben anhören", "banane-listen")
            self.tap("Stopp", "banane-listen-stop")
            self.tap("Noch einmal", "banane-repeat")
            self.tap("Stopp", "banane-repeat-stop")
            self.tap("Langsamer", "banane-slower")
            self.stop_task(WORD_PROMPT, "banane-slower")
        self.result["word"] = self.task_roundtrips("words", "Die Wortwerkstatt", WORD_PROMPT, tokens=[2, 3, 0])
        self.close_task()

        self.tap("Lumos Formenwerkstatt", "pattern-entry")
        self.see(PATTERN_PROMPT, "current-pattern", scroll=True, exact=True)
        with self.recording("pattern-hint-and-correction"):
            self.tap("Kreis, auswählen", "pattern-wrong-candidate")
            self.checkpoint("patterns", patternChoice=0)
            before = learning_snapshot(self.preferences("pattern-candidate-before"))
            self.tap("Hilf mir", "pattern-hint")
            self.tap("Dreieck, auswählen", "pattern-correct-candidate")
            self.checkpoint("patterns", patternChoice=1)
            self.stop_task(PATTERN_PROMPT, "pattern")
            require_preserved(before, learning_snapshot(self.preferences("pattern-candidate-after")))
        self.result["pattern"] = self.task_roundtrips("patterns", "Lumos Formenwerkstatt", PATTERN_PROMPT, patternChoice=1)
        self.close_task()
        self.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        self.see("LUMO AKADEMIE", "labs-to-academy")

    def guided_course(self):
        self.tap("Lumo erklärt es mir", "guided-entry")
        # Bind a repeated start label to the visible course title and its next
        # button, before another course title. Never assume a fixed card row.
        for _ in range(30):
            nodes = self.nodes("guided-course")
            titles = [bounds(n) for n in nodes if "Über den Zehner" in node_labels([n]) and bounds(n)]
            buttons = [bounds(n, min_height=32) for n in nodes if "Mit Lumo anfangen" in node_labels([n]) and
                       n.get("clickable") == "true" and n.get("enabled") == "true" and bounds(n, min_height=32)]
            if len(titles) == 1:
                title = titles[0]
                below = [b for b in buttons if b[1] >= title[3] and b[0] < title[2] and b[2] > title[0]]
                if below:
                    chosen = min(below, key=lambda b: b[1])
                    self.touch(chosen, "guided-bridge-start", "Über den Zehner / Mit Lumo anfangen")
                    break
            self.scroll(nodes, 1)
        else:
            raise RuntimeError("Observed start button for Über den Zehner was not available")
        self.see("Heute lernen wir einen Rechentrick", "guided-greeting", scroll=True)
        self.tap("Weiter", "guided-foundation")
        self.see("Zähle die Äpfel", "guided-foundation-prompt", scroll=True)
        self.tap("6", "guided-answer-six")
        self.tap("Weiter", "guided-example")
        self.see("Acht und fünf", "guided-eight-plus-five", scroll=True, exact=True)

    def speech_log(self, timeout=15):
        log = self.base.adb("logcat", "-d", "-v", "brief", "-s", "LumoLearningSpeech:I", "godot:I", "Godot:I", "*:S",
                            timeout=timeout)
        (self.out / self.fresh("native-speech.txt")).write_text(log)
        return log

    def native_playback(self, pid, previous=(), timeout=180):
        def observe():
            try:
                return speech_completion(self.speech_log(), pid, previous_ids=previous)
            except RuntimeError as error:
                if str(error).startswith("No new actual local MediaPlayer"):
                    return None
                raise
        return self.wait("Current native MediaPlayer playback completion", observe, timeout=timeout)

    def native_render_diagnostics(self, pid, deadline):
        """Supplement the interval probe with bounded, read-only system dumps."""
        files = []

        def capture(tag, *arguments):
            filename = self.fresh(tag + ".txt")
            path = self.out / filename
            remaining = deadline - time.monotonic() - 2
            if remaining < .5:
                path.write_text("Not collected: remaining scene observation budget is exhausted.\n")
                files.append({"file": filename, "status": "budget_exhausted"})
                return ""
            try:
                text = self.base.adb("shell", "dumpsys", *arguments, check=False,
                                     timeout=min(5, remaining - .25))
                path.write_text(text)
                files.append({"file": filename, "status": "raw_response_recorded"})
                return text
            except Exception as error:
                path.write_text(str(error) + "\n")
                files.append({"file": filename, "status": "unavailable"})
                return ""

        capture("gfxinfo-native", "gfxinfo", PACKAGE + ":lumo_game", "framestats")
        capture("gfxinfo-package", "gfxinfo", PACKAGE, "framestats")
        layers = capture("surfaceflinger-observed-layers", "SurfaceFlinger", "--list")
        observed = sorted({line.strip() for line in layers.splitlines()
                           if PACKAGE in line and "LumoGameActivity" in line},
                          key=lambda label: ("SurfaceView" not in label, label))[:2]
        for index, label in enumerate(observed):
            # adb's remote shell needs the exact observed layer name quoted.
            capture(f"surfaceflinger-native-{index}", "SurfaceFlinger", "--latency", shlex.quote(label))
        result = {"native_pid": pid, "files": files, "observed_native_layers": observed,
                  "interpretation": "Supplementary raw Android reports. HWUI gfxinfo can omit Godot SurfaceView rendering; SurfaceFlinger latency can be unsupported. Neither substitutes for the measured native frame windows."}
        self.save("native-system-rendering-observation", result)
        return result

    def native_performance(self, pid, previous_playback_ids):
        # The independently bounded measurement begins after native startup and
        # the two spoken learning steps. Ignore the next producer window: it may
        # contain intervals from before this measurement started.
        initial = learning_performance_windows(self.speech_log(), pid)
        previous_index = initial[-1]["window_index"] if initial else 0
        scene_began = time.monotonic()
        deadline = scene_began + 60
        replayed, playback = False, None
        while time.monotonic() < deadline - 2:
            log = self.speech_log(timeout=min(5, deadline - time.monotonic() - 1))
            observed = learning_performance_windows(log, pid)
            windows = [w for w in observed if w["window_index"] > previous_index + 1]
            elapsed = time.monotonic() - scene_began
            combined = any(w["speech_fox_effects_samples"] > 0 for w in windows)
            if replayed:
                try:
                    playback = speech_completion(log, pid, previous_ids=previous_playback_ids)
                except RuntimeError as error:
                    if not str(error).startswith("No new actual local MediaPlayer"):
                        raise
            if elapsed >= 10 and len(windows) >= 2 and combined and playback:
                system = self.native_render_diagnostics(pid, deadline)
                remaining = deadline - time.monotonic()
                require(remaining > 0, "Native performance screenshot exceeded the observation budget")
                screenshot = self.reader.capture(self.out, self.fresh("native-performance-observed-scene"),
                                                 timeout=min(5, remaining))
                self.result.setdefault("screenshots", []).append(screenshot)
                report = learning_performance_summary(windows, pid, time.monotonic() - scene_began)
                report["system_rendering_evidence"] = system
                report["current_step_replay_requested"] = replayed
                report["current_step_replay_playback"] = playback
                report["premeasurement_windows"] = initial
                report["premeasurement_windows_used_in_summary"] = False
                report["discarded_partial_window_after_index"] = previous_index
                report["capture_scope"] = "Visible 8+5 scene after initial startup; no task, model or progress reset."
                self.save("native-learning-performance", report)
                return report
            crossed_boundary = any(w["window_index"] > previous_index for w in observed)
            if crossed_boundary and not replayed and deadline - time.monotonic() >= 15:
                # "Noch einmal" restarts the model. This existing button only
                # replays the current checked step and preserves the two stones.
                previous_playback_ids = set(previous_playback_ids) | {
                    int(turn) for observed_pid, _, turn, _ in speech_events(log)
                    if int(observed_pid) == pid
                }
                self.reader.native_tap(self.out, "Schritt anhören", self.fresh("performance-current-step-audio"),
                                       timeout=min(20, deadline - time.monotonic() - 10),
                                       exact=True, orientation="responsive")
                replayed = True
            time.sleep(.6)
        raise RuntimeError("No complete measured audio/figure/effects performance window within the 60-second current-scene budget")

    def wait_native_ready(self, tag, *, timeout=60):
        # Android may publish the resumed ActivityRecord before the isolated
        # process is discoverable. Neither record alone proves scene readiness;
        # retain both observations and keep the later OCR/audio gates unchanged.
        component = re.compile(re.escape(PACKAGE) + r"/(?:[\w$.]*\.)?LumoGameActivity(?=[\s}])")

        def observe():
            activity = self.base.adb("shell", "dumpsys", "activity", "activities", timeout=15)
            raw_pid = self.base.adb("shell", "pidof", PACKAGE + ":lumo_game", timeout=15, check=False)
            self.save(self.fresh(tag + "-native-start-observation"), {
                "expected_process": PACKAGE + ":lumo_game",
                "activity_dump": activity, "pidof_output": raw_pid,
            })
            pids = raw_pid.split()
            require(len(pids) <= 1 and (not pids or re.fullmatch(r"[1-9][0-9]*", pids[0])),
                    "Actual native process is ambiguous or has an invalid PID")
            foreground = any("ResumedActivity" in line and component.search(line)
                             for line in activity.splitlines())
            return int(pids[0]) if foreground and pids else None

        try:
            return self.wait("Current native Activity and isolated process", observe, timeout=timeout)
        except Exception:
            try:
                raw_log = self.base.adb("logcat", "-d", "-v", "threadtime", timeout=15, check=False)
                (self.out / (self.fresh(tag + "-native-start-failure") + ".log")).write_text(raw_log)
            except Exception as log_error:
                self.save(self.fresh(tag + "-native-start-log-error"), {"error": str(log_error)})
            raise

    def native_roundtrip(self):
        self.guided_course()
        self.capture("native-entry-same-guided-task")
        before = learning_snapshot(self.preferences("native-learning-before"))
        self.base.adb("logcat", "-c")
        with self.recording("native-three-dimensional-learning"):
            self.tap("Mit Lumo in 3D ausprobieren", "native-existing-entry")
            pid = self.wait_native_ready("original-guided")
            self.reader.native_text(self.out, "Zahlen zum Anfassen", self.fresh("native-title"), orientation="responsive")
            self.capture("native-current-eight-plus-five", native=True)
            playback = self.native_playback(pid)
            self.reader.native_text(self.out, "Ein Objekt zeigen", self.fresh("native-move-one"),
                                    tap=True, exact=True, orientation="responsive")
            self.reader.native_text(self.out, "Ein Objekt zeigen", self.fresh("native-move-two"),
                                    tap=True, exact=True, orientation="responsive")
            self.reader.native_text(self.out, "Zehn sind voll", self.fresh("native-ten-full"), orientation="responsive")
            self.capture("native-ten-and-three", native=True)
            second_playback = self.native_playback(pid, playback["utterance_ids"])
        # A separate real recording ensures the bounded measurement is covered
        # even if the first local TTS model startup consumed the entry segment.
        with self.recording("native-three-dimensional-performance"):
            performance = self.native_performance(pid, playback["utterance_ids"] + second_playback["utterance_ids"])
        performance["video"] = self.recordings[-1]
        require(performance["video"]["whole_block_within_recording_limit"] and
                performance["video"]["duration_seconds"] >= performance["scene_observed_seconds"] - 2,
                "Actual native performance video does not cover the observed measurement interval")
        self.save("native-learning-performance", performance)
        self.reader.native_text(self.out, "Zur Aufgabe", self.fresh("native-return"),
                                tap=True, exact=True, orientation="responsive")
        self.wait("Native process exited after explicit return", lambda: self.base.adb("shell", "pidof", PACKAGE + ":lumo_game", check=False),
                  lambda value: not value, timeout=45)
        self.see("Acht und fünf", "same-guided-task-returned", scroll=True, exact=True)
        self.capture("native-return-current-task")
        after = learning_snapshot(self.preferences("native-learning-after"))
        self.result["native_learning"] = {"first_playback": playback, "second_playback": second_playback,
                                          "performance": performance,
                                          "preservation": require_preserved(before, after),
                                          "entry": "existing guided lesson button", "current_task": "Acht und fünf"}

    def run(self):
        self.identify_and_install()
        self.onboard()
        self.configure_local_voice()
        self.academy()
        self.labs()
        self.native_roundtrip()
        self.result["final_profile"] = learning_snapshot(self.preferences("final-profile-and-progress"))["profile"]
        self.result["status"] = "PASS_WITH_LIMITATIONS"
        self.result["limitations"] = [
            "Real spoken recognition was not exercised; actual request, system availability and Stop were observed.",
            "Native MediaPlayer start/completion proves playback callbacks, not audible quality or phoneme lip sync.",
            "Actual emulator frame intervals and render counters were collected with audio/figure/effect overlap; this is not a verified 60-FPS result on a physical device.",
            "Real emulator screenshots/video and resized displays do not replace physical Fold/phone acceptance.",
        ]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    for flag in ("apk", "provenance", "out"):
        parser.add_argument("--" + flag, required=True, type=Path)
    for flag in ("expected-sha256", "expected-source", "expected-native", "expected-certificate"):
        parser.add_argument("--" + flag, required=True)
    parser.add_argument("--expected-version", type=int, required=True)
    parser.add_argument("--serial")
    parser.add_argument("--conversation-ui", choices=("ea", "chat4"), default="ea",
                        help="Explicit reviewed UI contract; canonical EA API is the default")
    args = parser.parse_args(argv)
    if args.out.exists() and any(args.out.iterdir()):
        parser.error("--out must be absent or empty: previous-run evidence may not be reused")
    args.out.mkdir(parents=True, exist_ok=True)
    result = {"schema": "lumo.nextgen.learning.android.probe", "version": 1, "status": "RUNNING",
              "run_id": uuid.uuid4().hex, "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "probe_sha256": digest(Path(__file__)), "historical_tour_pass_used": False,
              "private_app_data_written_by_probe": False, "synthetic_profile": PROFILE_NAME}
    probe = None
    try:
        require(shutil.which("ffprobe") is not None, "ffprobe is required to validate real videos")
        probe = LearningProbe(args, result)
        probe.run()
        return 0
    except Exception as error:
        result.update(status="FAIL", error=str(error), traceback=traceback.format_exc())
        if probe:
            try:
                probe.capture("failure-current-screen", native=True)
            except Exception as capture_error:
                result["failure_capture_error"] = str(capture_error)
        print(traceback.format_exc(), file=sys.stderr, flush=True)
        return 1
    finally:
        result["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        (args.out / "learning-android-result.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps({key: result[key] for key in ("status", "run_id", "started_utc", "finished_utc")}), flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
