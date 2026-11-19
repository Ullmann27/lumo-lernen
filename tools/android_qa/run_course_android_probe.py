"""Tap each real course card, keep crash logs and inspect the running game on Android."""
import io
import json
import re
import subprocess
import sys
import time
from collections import deque
from pathlib import Path

from PIL import Image

OUT = Path("course-evidence")
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
ACTIVITY = "dev.ullmann.lumo.lumo_lernen.LumoGameActivity"
COURSES = ["dschungelherz", "zauberwald", "sonnenhafen"]


def adb(*args, binary=False):
    return subprocess.check_output(["adb", *args], text=not binary, timeout=35)


def capture(path):
    data = adb("exec-out", "screencap", "-p", binary=True)
    image = Image.open(io.BytesIO(data)).convert("RGB")
    path.write_bytes(data)
    return image


def starts(image):
    # The three primary Los! buttons have solid gold faces. Ignore text, thin
    # borders and scenery by measuring the size and fill of each connected area.
    small = image.resize((image.width // 3, image.height // 3))
    pixels = small.load()
    points = {(x, y) for y in range(small.height) for x in range(small.width)
              if all(abs(a-b) <= 13 for a, b in zip(pixels[x, y], (255, 215, 94)))}
    buttons = []
    while points:
        x, y = points.pop()
        queue = deque([(x, y)])
        left = right = x
        top = bottom = y
        area = 0
        while queue:
            x, y = queue.popleft()
            left, right = min(left, x), max(right, x)
            top, bottom = min(top, y), max(bottom, y)
            area += 1
            for pos in ((x-1,y), (x+1,y), (x,y-1), (x,y+1)):
                if pos in points:
                    points.remove(pos)
                    queue.append(pos)
        width, height = right-left+1, bottom-top+1
        if width >= 24 and height >= 8 and width > 1.45 * height and area >= width * height * .64:
            buttons.append(((left+right)*3//2, (top+bottom)*3//2))
    if len(buttons) != 3:
        return []
    horizontal = max(x for x, y in buttons)-min(x for x, y in buttons) > max(y for x, y in buttons)-min(y for x, y in buttons)
    return sorted(buttons, key=lambda p: p[0] if horizontal else p[1])


def course(index, name, require_movement_log):
    adb("shell", "am", "force-stop", PACKAGE)
    adb("logcat", "-c")
    # The emulator runs adbd as root so the real non-exported activity stays private.
    options = json.dumps({"scene":"run", "game":"run", "grade":1}, separators=(",", ":"))
    result = adb("shell", f"am start -W -n {PACKAGE}/{ACTIVITY} --es lumoLaunchOptions '{options}'")
    if "Status: ok" not in result or "Error" in result:
        raise RuntimeError(result)
    until = time.monotonic() + 100
    while time.monotonic() < until:
        if "[LumoRun] ready" in adb("logcat", "-d", "-s", "godot"):
            buttons = starts(capture(OUT / f"{name}-selection.png"))
            if buttons:
                break
        time.sleep(1)
    else:
        capture(OUT / f"{name}-no-menu.png")
        raise RuntimeError("Three visible course start buttons were not found")
    print(name, "real touch", buttons[index], flush=True)
    adb("shell", "input", "tap", *map(str, buttons[index]))
    until = time.monotonic() + 140
    while time.monotonic() < until:
        logs = adb("logcat", "-d", "-s", "godot")
        if "FATAL" in logs or not adb("shell", "pidof", PACKAGE + ":lumo_game").strip():
            raise RuntimeError("Native game exited")
        if f"[LumoRun] course {name}:" in logs and (not require_movement_log or f"[LumoRun] running {name} " in logs):
            break
        time.sleep(1)
    else:
        raise RuntimeError("Course did not reach play")
    a = capture(OUT / f"{name}-play-1.png").resize((48,32))
    time.sleep(4)
    b = capture(OUT / f"{name}-play-2.png").resize((48,32))
    foreground = adb("shell", "dumpsys", "activity", "activities")
    if not any(ACTIVITY in line and re.search(r"mResumedActivity|topResumedActivity", line) for line in foreground.splitlines()):
        raise RuntimeError("Native activity left the foreground")
    if a.tobytes() == b.tobytes():
        raise RuntimeError("Rendered gameplay stayed frozen")
    print(name, "passed", flush=True)


def main():
    OUT.mkdir(exist_ok=True)
    adb("root")
    adb("wait-for-device")
    if adb("shell", "id", "-u").strip() != "0":
        raise RuntimeError("Rooted Android emulator needed to launch non-exported activity")
    installation = adb("install", "-r", sys.argv[1])
    if "Success" not in installation:
        raise RuntimeError(installation)
    adb("shell", "wm", "size", "840x960")
    adb("shell", "wm", "density", "160")
    failures = []
    for i, name in enumerate(COURSES):
        try:
            course(i, name, "--movement" in sys.argv)
        except (RuntimeError, subprocess.SubprocessError) as err:
            failures.append((name, str(err)))
            print(name, "failed", err, flush=True)
        finally:
            (OUT / f"{name}-logcat.txt").write_text(adb("logcat", "-b", "all", "-d"))
            (OUT / f"{name}-exit-info.txt").write_text(adb("shell", "dumpsys", "activity", "exit-info", PACKAGE))
    if failures:
        sys.exit(str(failures))


if __name__ == "__main__":
    main()
