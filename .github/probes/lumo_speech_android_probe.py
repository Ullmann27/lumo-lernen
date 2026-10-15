#!/usr/bin/env python3
"""Real, digest-pinned Android update/voice-control probe, no acoustic approval.

Uses fictional emulator data and the existing live accessibility reader.
Never injects progress, enables online consent, records microphone input or
uses a real child's device. A silent emulator cannot certify audible timbre.
"""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import time
import traceback

sys.path.insert(0, str(Path(__file__).resolve().parent))
import creative_android_probe as existing

BASE_SHA = "9dfd5f58a8879b3fa95b505ad92bc9cb20ee433298c92797404d3f588c38b1f4"
CERT = existing.CERT


def labels(out, tag):
    return existing.base.accessible_text(existing.live.live_nodes(out, tag))


def read_in_scroll(out, tag, required):
    """Read actual accessible content, scrolling only observed app viewports."""
    seen = ""
    for direction in (-1, 1):
        for attempt in range(12):
            nodes = existing.live.live_nodes(out, f"{tag}-{direction}-{attempt}")
            current = existing.base.accessible_text(nodes)
            seen += "\n" + current
            if all(value in seen for value in required):
                return seen
            scrolls = []
            for node in nodes:
                if node.get("scrollable") != "true" or node.get("package") != existing.PACKAGE:
                    continue
                bounds = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
                if len(bounds) == 4:
                    x0, y0, x1, y1 = bounds
                    if x1 > x0 and y1 > y0:
                        scrolls.append(((x1-x0)*(y1-y0), x0, y0, x1, y1))
            if not scrolls:
                time.sleep(.5)
                continue
            _, x0, y0, x1, y1 = max(scrolls)
            x = (x0+x1)//2
            low, high = int(y0+(y1-y0)*.2), int(y1-(y1-y0)*.2)
            start, end = (high, low) if direction == 1 else (low, high)
            existing.base.adb("shell", "input", "swipe", str(x), str(start),
                              str(x), str(end), "350")
            time.sleep(.7)
    raise RuntimeError(f"Required accessible content not observed: {required}")


def playback_count(text):
    values = re.findall(r"Bestätigte Wiedergabestarts:\s*(\d+)", text)
    if not values:
        raise RuntimeError("No confirmed native playback count observed")
    return int(values[-1])


def _observed_parent_label(nodes, label, *, tap=True):
    """Match an actual Lumo control, including its real multiline caption."""
    normalized = " ".join(label.split())
    for node in nodes:
        if (node.get("package") != existing.PACKAGE
                or node.get("enabled") == "false"
                or node.get("visible-to-user") == "false"):
            continue
        if (node.get("clickable") == "true") != tap:
            continue
        for key in ("text", "content-desc"):
            value = node.get(key, "")
            if label in value.splitlines():
                return label
            if value and " ".join(value.split()) == normalized:
                return value
    return None


def _merged_profile_edit_visible(nodes):
    """Identify the actual Android-merged profile card, not invented bounds."""
    for node in nodes:
        if (node.get("package") != existing.PACKAGE
                or node.get("enabled") == "false"
                or node.get("visible-to-user") == "false"
                or node.get("clickable") != "true"):
            continue
        for key in ("text", "content-desc"):
            lines = [line.strip() for line in node.get(key, "").splitlines()]
            if ("Profil bearbeiten" in lines
                    or any(first == "Profil" and second == "bearbeiten"
                           for first, second in zip(lines, lines[1:]))):
                return node
    return None


def _tap_merged_profile_edit(out, tag):
    """Read the visible button twice; never press its merged card midpoint.

    The existing native Godot reader correctly requires a landscape surface.
    This Flutter profile control is portrait: reuse its full-frame OCR and
    target geometry checks, without changing those native landscape guards.
    """
    deadline = time.monotonic() + 75
    previous = None
    journal = {"scope": "Actual portrait Flutter caption, not adult authentication",
               "status": "WAITING", "frames": []}
    try:
        for attempt in range(6):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            if existing.PACKAGE not in existing.base.foreground():
                raise RuntimeError("Lumo is not foreground for observed profile edit")
            nodes = existing.live.live_nodes(out, f"{tag}-caption-{attempt}")
            card = _merged_profile_edit_visible(nodes)
            if not card:
                raise RuntimeError("Actual merged profile edit caption disappeared")
            card_bounds = list(map(int, re.findall(r"\d+", card.get("bounds", ""))))
            if len(card_bounds) != 4:
                raise RuntimeError("Actual merged profile card has invalid bounds")
            snapshot = existing.capture(out, f"{tag}-pixels-{attempt}", timeout=remaining)
            source = out / snapshot["file"]
            frame = {"source": source.name, "source_sha256": existing.digest(source),
                     "pixels": [snapshot["width"], snapshot["height"]],
                     "reasons": [], "card_bounds": card_bounds}
            lines = existing.image_lines(
                out, f"{tag}-read-{attempt}", existing.normalized("bearbeiten"),
                source_path=source, timeout=max(.1, deadline - time.monotonic()),
                exact=True,
            )
            x0, y0, x1, y1 = card_bounds
            bounds = {tuple(line["bounds"]) for line in lines
                      if existing.normalized(line["text"]) == "bearbeiten"
                      and len(line["bounds"]) == 4
                      and x0 <= line["bounds"][0] < line["bounds"][2] <= x1
                      and y0 <= line["bounds"][1] < line["bounds"][3] <= y1}
            journal["frames"].append(frame)
            if len(bounds) != 1:
                previous = None
                time.sleep(.3)
                continue
            observed = existing.target_observation(frame, list(bounds.pop()), previous)
            frame["target"] = observed
            previous = observed
            if observed["stable_observed_target"]:
                if existing.digest(source) != frame["source_sha256"]:
                    raise RuntimeError("Profile edit screenshot changed before touch")
                left, top, right, bottom = observed["bounds"]
                x, y = str(round((left + right) / 2)), str(round((top + bottom) / 2))
                existing.base.adb("shell", "input", "swipe", x, y, x, y, "120")
                journal.update(status="TOUCH_SENT", touch=[int(x), int(y)])
                time.sleep(1)
                return
            time.sleep(.3)
        raise TimeoutError("Actual profile edit button was not observed twice")
    except Exception as error:
        journal.update(status="FAIL", error=str(error))
        raise
    finally:
        (out / (tag + "-observed-touch.json")).write_text(
            json.dumps(journal, ensure_ascii=False, indent=2) + "\n")


def parents(out):
    visited = set()
    for attempt in range(10):
        nodes = existing.live.live_nodes(out, f"parents-entry-{attempt}")
        # A non-tappable page heading confirms the destination. A button with
        # the same name is only an entry control, not proof of navigation.
        if _observed_parent_label(nodes, "Elternbereich", tap=False):
            return
        if ("Profil bearbeiten" not in visited
                and _merged_profile_edit_visible(nodes)
                and not _observed_parent_label(nodes, "Profil bearbeiten")):
            _tap_merged_profile_edit(out, f"parents-merged-edit-{attempt}")
            visited.add("Profil bearbeiten")
            time.sleep(.4)
            continue
        for label in ("Eltern", "Elternbereich", "Elternbereich öffnen",
                      "Einstellungen", "Profil bearbeiten", "Profil"):
            observed = _observed_parent_label(nodes, label)
            if observed and label not in visited:
                existing.flutter_tap(out, observed, f"parents-entry-{attempt}")
                visited.add(label)
                break
        # The mobile route is Profil -> Profil/bearbeiten -> Elternbereich.
        # Never issue blind Android Back events, which previously closed Lumo
        # at its actual home page and left the probe on the Pixel Launcher.
        time.sleep(.4)
    existing.capture(out, "parents-navigation-missing")
    raise RuntimeError("No observed parent navigation control or parent page")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {"status": "RUNNING", "scope": "Android16 update, voice controls and responsive layouts",
        "not_tested": ["audible Sulafat identity", "dynamic provider synthesis",
            "physical Samsung Galaxy Z Fold", "hinge events", "microphone recognition",
            "complete learning progress migration", "complete Kart race"]}
    try:
        proof = json.loads((args.candidate.parent / "BUILD-PROVENANCE.json").read_text())
        source = os.environ["LUMO_EXPECT_SOURCE"]
        expected_sha = os.environ["LUMO_EXPECT_APK_SHA"]
        if (proof["flutter_source_commit"] != source or
            proof["signingCertificateSha256"] != CERT or proof["versionCode"] != 1927 or
            proof["sha256"] != expected_sha or existing.digest(args.candidate) != expected_sha or
            existing.digest(args.baseline) != BASE_SHA):
            raise RuntimeError("Source, APK digest, version or signature mismatch")
        result["source"] = source
        result["apk_sha256"] = expected_sha
        result["root"] = existing.ensure_rooted_emulator(existing.base.adb, out)
        api = int(existing.base.adb("shell", "getprop", "ro.build.version.sdk"))
        if api != 36:
            raise RuntimeError("Expected actual Android API36 emulator")
        result["android_api"] = api
        existing.base.display(1080, 2400, 480)
        installed = existing.base.adb("install", "-r", "--no-streaming", str(args.baseline), timeout=180)
        if "Success" not in installed:
            raise RuntimeError("Baseline install failed")
        existing.base.launch(out, "baseline")
        result["onboarding"] = existing.onboard(out)
        before_identity = existing.package_identity(out, "baseline")
        before_profile = existing.prefs(out, "baseline").get("flutter.lumo_active_profile")
        before_wallet = existing.wallet(out, "before-update")
        if not before_profile or "LumoTest" not in before_profile:
            raise RuntimeError("No actual persisted baseline profile")
        existing.base.adb("shell", "am", "force-stop", existing.PACKAGE)
        update = existing.base.adb("install", "-r", "--no-streaming", str(args.candidate), timeout=180)
        after_identity = existing.package_identity(out, "candidate")
        if ("Success" not in update or not after_identity["versionCode"].startswith("1927") or
            after_identity["userId"] != before_identity["userId"] or
            after_identity["firstInstallTime"] != before_identity["firstInstallTime"]):
            raise RuntimeError("In-place update changed installation identity")
        existing.base.adb("shell", "svc", "wifi", "disable")
        existing.base.adb("shell", "svc", "data", "disable")
        existing.base.adb("shell", "cmd", "connectivity", "airplane-mode", "enable")
        existing.base.launch(out, "candidate-offline")
        if existing.prefs(out, "candidate").get("flutter.lumo_active_profile") != before_profile:
            raise RuntimeError("Profile changed in update")
        if existing.wallet(out, "after-update") != before_wallet:
            raise RuntimeError("Wallet changed in update")
        parents(out)
        existing.flutter_tap(out, "App und Sprachserver prüfen", "diagnose")
        time.sleep(8)
        text = read_in_scroll(out, "diagnosis-result",
            ["Build 1927", existing.PACKAGE, CERT,
             "Vorhandene Originalaufnahmen bleiben verfügbar",
             "Bestätigte Wiedergabestarts:"])
        starts_before = playback_count(text)
        existing.capture(out, "01_android16_voice_diagnosis")
        existing.flutter_tap(out, "Stimme testen", "original-voice-test")
        time.sleep(1)
        text = read_in_scroll(out, "original-voice-state",
            ["Originalaufnahme c3034465f7dd.m4a", "Bestätigte Wiedergabestarts:"])
        starts_after = playback_count(text)
        if starts_after != starts_before + 1:
            raise RuntimeError("Original preview did not produce exactly one new native start")
        result["original_preview_native_starts"] = [starts_before, starts_after]
        existing.flutter_tap(out, "Stopp", "voice-stop")
        time.sleep(1)
        read_in_scroll(out, "stopped-voice-state", ["Sprachstatus: Ruhe"])
        result["layouts"] = []
        for name, width, height in [("closed", 360, 800), ("opened", 1200, 896), ("closed-return", 360, 800)]:
            existing.base.display(width, height, 160)
            result["layouts"].append(existing.capture(out, f"02_voice_{name}"))
            if existing.PACKAGE not in existing.base.foreground():
                raise RuntimeError("App lost foreground during resizing")
        if existing.wallet(out, "after-voice-controls") != before_wallet:
            raise RuntimeError("Voice controls changed learning rewards")
        result.update(status="PASS", profile_retained=True, wallet_retained=True,
            package=existing.PACKAGE, certificate_sha256=CERT)
        return 0
    except Exception:
        result["status"] = "FAIL"
        result["error"] = traceback.format_exc()
        return 1
    finally:
        (out / "speech-android-result.json").write_text(json.dumps(result, indent=2) + "\n")
        try:
            (out / "logcat.txt").write_text(existing.base.adb("logcat", "-d", "-t", "1500"))
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
