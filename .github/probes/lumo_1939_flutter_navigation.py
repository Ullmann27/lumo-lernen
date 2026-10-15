"""Actual accessibility coordinates with a settled target before every 1939 tap."""
import json
from pathlib import Path
import re
import time
import lumo_education_android_probe as edu
existing = edu.existing
_enabled_control_bounds = edu._enabled_control_bounds


def tap_stable_control(out: Path, caption: str, tag: str) -> None:
    # Scrolling/bouncing sheets must settle before a coordinate-based touch.
    settling = 0
    previous = None
    stable_since = None
    for direction in (1, -1):
        for attempt in range(32):
            nodes = existing.live.live_nodes(out, f"{tag}-{direction}-{attempt}")
            if existing.recover_launcher_dialog(out, nodes, tag):
                continue
            bounds = _enabled_control_bounds(nodes, caption)
            if bounds is not None:
                now = time.monotonic()
                if previous is None or max(abs(a-b) for a,b in zip(previous,bounds)) > 2:
                    previous, stable_since = bounds, now
                    time.sleep(.4)
                    continue
                if now - stable_since < .8:
                    time.sleep(.4)
                    continue
                (out / (tag + '-stable-touch.json')).write_text(json.dumps({
                    'caption': caption, 'bounds': bounds, 'previous_bounds': previous,
                    'stable_seconds': now - stable_since,
                    'scope': 'current enabled caption remains within 2 pixels for at least 0.8 seconds',
                }, indent=2) + '\n')
                x, y = str((bounds[0]+bounds[2])//2), str((bounds[1]+bounds[3])//2)
                existing.base.adb("shell", "input", "swipe", x, y, x, y, "120")
                time.sleep(2)
                return
            previous = stable_since = None
            visible_label = any(
                node.get("package") == existing.PACKAGE
                and any(caption == value or caption in value.splitlines()
                        for value in (node.get("text", ""), node.get("content-desc", "")))
                for node in nodes
            )
            if visible_label and settling < 10:
                settling += 1
                time.sleep(.6)
                continue
            scrolls = []
            for node in nodes:
                if (node.get("package") != existing.PACKAGE
                        or node.get("scrollable") != "true"):
                    continue
                box = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
                if len(box) == 4 and box[2] > box[0] and box[3] > box[1]:
                    scrolls.append(box)
            if not scrolls:
                time.sleep(.5)
                continue
            box = max(scrolls, key=lambda b: (b[2]-b[0])*(b[3]-b[1]))
            x = str((box[0]+box[2])//2)
            low, high = round(box[1]+.2*(box[3]-box[1])), round(box[1]+.8*(box[3]-box[1]))
            start, end = (high, low) if direction == 1 else (low, high)
            existing.base.adb("shell", "input", "swipe", x, str(start), x, str(end), "400")
            time.sleep(.4)
    existing.capture(out, tag + "-missing")
    raise RuntimeError("No enabled live Flutter course control: " + caption)
