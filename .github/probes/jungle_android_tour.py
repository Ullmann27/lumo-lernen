#!/usr/bin/env python3
"""Run the existing exact-APK tour through Dschungelherz's real menu entry.

The existing installation, source/signature, onboarding, learning, race movement,
pause/continue, Flutter return, profile and Fold-layout checks remain unchanged.
Only the native menu journey selects the newly added course. Selection uses
observed OCR captions and bounded scroll gestures; saved game state is read-only.
"""
from __future__ import annotations

import json
import re
import time
from pathlib import Path

import modernization_android_tour as tour

COURSE = "jungle_emerald_3600"
probe = tour.probe
base = tour.base


def start_jungle_race(out: Path) -> dict:
    if not tour.godot_alive():
        raise RuntimeError("The embedded Godot process is not running")
    previous_id = tour._previous_kart_race_id(out)
    probe.native_text(out, "Einzelrennen", "jungle-single-race", tap=True, exact=True)
    probe.native_text(out, "Strecken", "jungle-open-tracks", tap=True, exact=True)
    gestures: list[dict] = []

    def scroll_tracks(frame: dict, _lines: list, source: Path, *,
                      deadline: float, previous_missing_frame=None) -> dict:
        if len(gestures) >= 12:
            raise RuntimeError("Dschungelherz remained invisible after 12 observed list gestures")
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("The bounded course-selection deadline expired")
        lines = probe.image_lines(out, "jungle-drawer-%02d" % len(gestures),
                                  source_path=source, timeout=min(40.0, remaining))
        observed = " ".join(probe.normalized(line["text"]) for line in lines)
        if "rennwelten" not in observed and "streckenpass" not in observed:
            raise RuntimeError("The live screenshot does not establish the track-selection drawer")
        if probe.digest(source) != frame["source_sha256"]:
            raise RuntimeError("The observed drawer screenshot changed before its gesture")
        width, height = frame["pixels"]
        # The production spatial menu places its only selection ScrollContainer
        # in the left panel. Its observed title and surface are required above.
        # Stay below its header and above its fixed footer, at this frame's size.
        x = round(width * 0.23)
        bottom, top = round(height * 0.78), round(height * 0.34)
        gesture = {"status": "SWIPE_SENT", "source": source.name,
                   "sha256": frame["source_sha256"], "pixels": [width, height],
                   "start": [x, bottom], "end": [x, top],
                   "observed_drawer_caption": observed[:1000]}
        base.adb("shell", "input", "swipe", str(x), str(bottom), str(x), str(top), "450")
        gestures.append(gesture)
        (out / "jungle-track-scrolls.json").write_text(
            json.dumps(gestures, ensure_ascii=False, indent=2) + "\n")
        return gesture

    probe.native_tap(out, "Dschungelherz", "jungle-select-course", timeout=240,
                     exact=True, missing_caption=scroll_tracks)
    selected = probe.capture(out, "jungle-selected-menu")
    menu_pixels = (out / selected["file"]).read_bytes()
    actions: list[dict] = []
    previous = None
    start_deadline = time.monotonic() + 45
    while time.monotonic() < start_deadline:
        screen = tour._screencap()
        (out / "jungle-start-button.png").write_bytes(screen)
        found = None
        for label in ("Rennen starten", "START"):
            point = tour._read_garage_footer(screen, label)
            if point is not None:
                found = (label, point)
                break
        if found is not None and previous is not None and found[0] == previous[0]:
            dx, dy = found[1][0] - previous[1][0], found[1][1] - previous[1][1]
            if dx * dx + dy * dy < 100:
                base.adb("shell", "input", "tap", str(found[1][0]), str(found[1][1]))
                actions.append({"caption": found[0], "tap": list(found[1]),
                                "evidence": "jungle-start-button.png"})
                break
        previous = found
        time.sleep(1.0)
    else:
        raise RuntimeError("No stable, actually rendered race-start caption was found")

    session = tour.RaceSession(out, expected_mode="race", expected_track=COURSE)
    state = tour.wait_race_running(session, previous_id=previous_id)
    expected_marker = r"\[Kart\] race_world_ready: " + re.escape(COURSE) + r" mode=race(?:\s|$)"
    log = base.adb("logcat", "-d", "-v", "brief", timeout=60, check=False)
    if re.search(expected_marker, log) is None:
        raise RuntimeError("The production runtime did not confirm the selected jungle course")
    screen = tour._screencap()
    (out / "21_lumo_kart_real_race.png").write_bytes(screen)
    confirmed = {key: state[key] for key in (
        "result_id", "selected_kart", "selected_driver", "mode", "track_id",
        "countdown", "elapsed", "distance")}
    report = {
        "expected_mode": "race", "expected_track": COURSE,
        "touches": actions, "track_scrolls": len(gestures),
        "garage_replaced": tour.evidence.garage_replaced(menu_pixels, screen),
        "rendered_frame": tour.evidence.rendered_race_frame(screen),
        "confirmed_selection": confirmed, "previous_result_id": previous_id,
        "scope": "Actual APK OCR touches and read-only game-produced session; no state injection",
    }
    (out / "jungle-android-entry.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    return report


if __name__ == "__main__":
    tour._start_actual_embedded_race = start_jungle_race
    raise SystemExit(tour.main())
