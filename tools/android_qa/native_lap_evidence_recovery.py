"""Source-bound QA for the newly reconstructed lap/result probes.

This verifies observations, not a screenshot quality rating or Android performance.
The ordered contract was reviewed against a984/b915/efeb probe sources; the
old workflow's 21 checks remain separate and unchanged.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
import struct
import zlib
from functools import wraps
from pathlib import Path

SOURCE_SHA256 = "00e4c7223465f4fcab165b2a603b17bc7bc9eb1727c4a9f5291fffc9d671fee2"
LAP_PROBE_SHA256 = "8129eea26ded1a9ddba71d7cb3dd11f38a12a89d09d89218d726354ec318c245"
FIXTURE_PROBE_SHA256 = "b9155b5ddb7332875d96a7785f0ea3fb7749a7670fac18562815f88bc88a2ff9"
FLOW_PROBE_SHA256 = "efeb21871cf8be91e5bf74226d1e70e51f52729a8a3ed45a242984b0fb7990f5"
TIME_PROBE_SHA256 = "15f8b808ec1e5b598f24c9cf224246a129e821625bd02a38ccf5794349e28b1e"
ACTIONS = {key: True for key in ("gas", "brake", "drift", "boost", "item")}
PROVENANCE = "NEW_TEST_IMPLEMENTATION_AFTER_WORKSPACE_LOSS"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def evidence_guard(function):
    @wraps(function)
    def guarded(*args, **kwargs):
        try:
            return function(*args, **kwargs)
        except (KeyError, IndexError, TypeError, AttributeError, OverflowError) as error:
            raise ValueError("Malformed native evidence: " + str(error)) from error
    return guarded


def finite(value, message: str) -> float:
    require(type(value) in (int, float) and math.isfinite(value), message)
    return value


def equal(actual, expected, message: str, *, tolerant=False, host_numbers=False) -> None:
    """Typed equality; only explicitly selected timing or host-JSON fields relax it."""
    if isinstance(expected, dict):
        require(type(actual) is dict and set(actual) == set(expected), message)
        for key in expected:
            equal(actual[key], expected[key], message + "." + key,
                  tolerant=tolerant, host_numbers=host_numbers)
    elif isinstance(expected, list):
        require(type(actual) is list and len(actual) == len(expected), message)
        for index, value in enumerate(expected):
            equal(actual[index], value, message + f"[{index}]",
                  tolerant=tolerant, host_numbers=host_numbers)
    elif type(expected) in (int, float):
        finite(actual, message)
        require(type(actual) is type(expected) or host_numbers, message + " type")
        require(abs(actual - expected) <= 1e-9 if tolerant else actual == expected, message)
    else:
        require(type(actual) is type(expected) and actual == expected, message)


def subset(actual, expected: dict, message: str, *, tolerant=False) -> None:
    require(type(actual) is dict and set(expected) <= set(actual), message)
    for key, value in expected.items():
        equal(actual[key], value, message + "." + key, tolerant=tolerant)


def rounded_seconds(seconds) -> float:
    finite(seconds, "finite duration")
    require(seconds >= 0, "nonnegative duration")
    return math.floor(seconds * 1000 + 0.5) / 1000.0


def time_text(seconds) -> str:
    milliseconds = math.floor(finite(seconds, "time text duration") * 1000 + 0.5)
    require(milliseconds >= 0, "time text duration")
    return f"{milliseconds // 60000:02d}:{milliseconds // 1000 % 60:02d}.{milliseconds % 1000:03d}"


def hud_speed(text: str, expected: str) -> None:
    require(type(text) is str and text.count("km/h") == 1 and
            re.findall(r"(?<!\S)(\d+) km/h(?=\s|$)", text) == [expected],
            "actual HUD requires exactly one canonical speed token")


def place_title(place: int) -> str:
    require(type(place) is int and 1 <= place <= 6, "source-derived place title int")
    return {1: "1. PLATZ!", 2: "2. Platz!", 3: "3. Platz!"}.get(place, f"Platz {place}")


def finished_ui(state: dict, title: str, *, after_tick=True) -> None:
    require(type(state) is dict, "result UI object")
    fields = {"action_disabled", "controls_visible", "displayed_speed_kmh", "expected_message_text",
              "hud_text", "message_text", "raw_speed"}
    require(set(state) == fields | ({"after_tick"} if after_tick else set()), "actual UI fields")
    equal(state.get("controls_visible"), False, "finished controls hidden")
    equal(state.get("displayed_speed_kmh"), 0, "finished displayed speed int zero")
    equal(state.get("action_disabled"), ACTIONS, "all five finished actions disabled")
    equal(state.get("expected_message_text"), title, "source-derived result title")
    equal(state.get("message_text"), title, "actual result title")
    hud = state.get("hud_text")
    hud_speed(hud, "0")
    finite(state.get("raw_speed"), "unchanged physical speed observation")
    require(type(state["raw_speed"]) is float and state["raw_speed"] >= 0,
            "actual nonnegative float physical speed observation")
    if after_tick:
        later = state.get("after_tick")
        finished_ui(later, title, after_tick=False)
        equal(later["raw_speed"], state["raw_speed"], "finished display never mutates physical speed")


def gates_context(gates: list) -> tuple[list, float, float]:
    require(type(gates) is list and len(gates) == 16, "sixteen ordered driven gates")
    previous_seconds = previous_distance = 0.0
    for index, gate in enumerate(gates):
        require(type(gate) is dict and set(gate) == {"gate", "seconds", "distance"}, "gate fields")
        equal(gate["gate"], index + 1, "ordered gate int")
        seconds = finite(gate["seconds"], "gate elapsed")
        distance = finite(gate["distance"], "gate distance")
        require(type(seconds) is float and type(distance) is float, "actual float gate observations")
        require(seconds > previous_seconds and distance > previous_distance, "monotonic gates")
        previous_seconds, previous_distance = seconds, distance
    laps = [gates[7]["seconds"], gates[15]["seconds"] - gates[7]["seconds"]]
    return laps, rounded_seconds(min(laps)), rounded_seconds(gates[15]["seconds"])


def result_payload(payload: dict, result_id: str, best: float, total: float) -> None:
    require(type(payload) is dict and type(result_id) is str and result_id, "result identity")
    require(set(payload) == {"bestLapSeconds", "checkpoints", "driver", "elapsedSeconds", "game", "kart",
                             "mode", "place", "resets", "resultId", "sessionId", "solved", "starTokens",
                             "stars", "status", "track"}, "actual public payload fields")
    subset(payload, {"game": "kart", "mode": "race", "status": "completed",
                     "driver": "fox", "kart": "comet", "track": "sonnenhafen",
                     "resultId": result_id, "solved": 0, "stars": 3, "resets": 0,
                     "checkpoints": 16, "bestLapSeconds": best, "elapsedSeconds": total},
           "legitimate public result")
    require(type(payload.get("place")) is int and 1 <= payload["place"] <= 6, "result place int")
    require(type(payload.get("starTokens")) is int and payload["starTokens"] >= 0, "collected stars int")
    require(type(payload.get("sessionId")) is str, "public session id string")


def result_text(text: str, payload: dict) -> None:
    equal(text, "\n".join(("Gesamtzeit   " + time_text(payload["elapsedSeconds"]),
                          "Beste Runde   " + time_text(payload["bestLapSeconds"]),
                          f"Sterne gesammelt   {payload['starTokens']}",
                          f"Belohnung   +{payload['stars']} Sterne")), "actual full result stats")


def common(data: dict, count: int, probe_sha: str) -> list:
    require(type(data) is dict, "evidence object")
    equal(data.get("status"), "PASS", "evidence status")
    equal(data.get("check_count"), count, "actual check count")
    equal(data.get("failed_checks"), 0, "no reported failed checks")
    equal(data.get("provenance"), PROVENANCE, "new evidence provenance")
    equal(data.get("engine"), "4.6.3-stable (official)", "actual matching engine")
    equal(data.get("display_server"), "X11", "real X11 renderer")
    equal(data.get("rendering_method"), "gl_compatibility", "actual rendering method")
    equal(data.get("renderer_setting"), "forward_plus", "unchanged project renderer setting")
    equal(data.get("physical_device_performance"), "NOT EXECUTED", "physical scope")
    equal(data.get("source_sha256"), SOURCE_SHA256, "reviewed production source")
    equal(data.get("probe_sha256"), probe_sha, "reviewed probe source")
    checks = data.get("checks")
    require(type(checks) is list and len(checks) == count, "actual ordered check inventory")
    for check in checks:
        require(type(check) is dict and set(check) == {"name", "passed", "expected", "actual"},
                "check fields")
        equal(check["passed"], True, "individual check passed boolean")
    return checks


@evidence_guard
def validate_time_format(data: dict) -> None:
    require(type(data) is dict, "formatter evidence object")
    equal(data.get("status"), "PASS", "formatter status")
    equal(data.get("passed"), 29, "all 29 formatter cases passed")
    equal(data.get("failed"), 0, "no failed formatter case")
    equal(data.get("display"), "headless", "formatter-only headless scope")
    equal(data.get("scope"), "formatter only; no race/physics/result/reward state is assigned", "formatter scope")
    engine = data.get("engine")
    subset(engine, {"major": 4, "minor": 6, "patch": 3, "status": "stable",
                    "build": "official", "string": "4.6.3-stable (official)",
                    "hash": "7d41c59c457bd5a245092b4e7eb2d833e3b3f8c3", "hex": 263683},
           "formatter actual matching official engine")
    cases = data.get("checks")
    require(type(cases) is list and len(cases) == len(TIME_CASES), "ordered 29 formatter cases")
    for index, (seconds, expected) in enumerate(TIME_CASES):
        source = "actual1905 lap" if index == 15 else "actual1905 payload" if index == 16 else "boundary or normal time"
        equal(cases[index], {"seconds": seconds, "expected": expected, "observed": expected,
                             "pass": True, "source": source}, f"formatter case {index}")


@evidence_guard
def validate_lap_session(data: dict) -> None:
    checks = common(data, 104, LAP_PROBE_SHA256)
    equal(data.get("fixture_probe_sha256"), FIXTURE_PROBE_SHA256, "reviewed fixture helper")
    equal(data.get("result_reopen_png"), "result_reopen.png", "lap result screenshot role")
    require(type(data.get("result_reopen_png_sha256")) is str and
            re.fullmatch(r"[0-9a-f]{64}", data["result_reopen_png_sha256"]) is not None,
            "actual lap screenshot digest shape")
    require(tuple(row["name"] for row in checks) == LAP_NAMES, "ordered 104 source-derived labels")
    laps, best, total = gates_context(data.get("ordered_gates"))
    gates = data["ordered_gates"]
    before, restored, payload = data.get("lap2_before"), data.get("lap2_restored"), data.get("finished_payload")
    require(type(before) is dict and type(restored) is dict and type(payload) is dict, "race state objects")
    result_id = payload.get("resultId")
    result_payload(payload, result_id, best, total)
    equal(data.get("expected_laps"), laps, "measured lap intervals", tolerant=True)
    equal(data.get("finished_elapsed_seconds"), gates[-1]["seconds"], "raw finish elapsed")
    equal(data.get("reopened_result_elapsed_seconds"), data["finished_elapsed_seconds"], "reopen frozen elapsed")
    equal(data.get("reopened_result_payload"), payload, "reopen exact public payload")
    equal(data.get("reopened_result_stats_visible"), True, "actual reopened result visible")
    result_text(data.get("reopened_result_stats_text"), payload)
    equal(data.get("reward_calls"), 1, "one actual host reward")
    require(type(data.get("driven_frames")) is int and 0 < data["driven_frames"] <= 12000, "bounded physical driving")
    require(abs(gates[-1]["seconds"] - data["driven_frames"] / 60.0) <= 1e-9,
            "raw duration equals actual fixed physics step count")
    equal(before, {"lap_times": [laps[0]], "lap_started_at": laps[0],
                   "checkpoint_index": 10, "distance": gates[9]["distance"],
                   "elapsed": gates[9]["seconds"], "result_id": result_id}, "before saved race")
    equal(restored, before, "new-instance restored race", tolerant=True)
    finished_ui(data.get("reopened_result_ui"), place_title(payload["place"]))
    finished_ui(data.get("direct_result_ui"), "Ziel!")
    equal(data.get("fixture_scope"),
          "20 ConfigFile pair fixtures and legacy/UI state fixtures are assigned; ordered_gates alone records actual driven progress",
          "assigned fixture scope remains explicit")

    def row(index, expected, actual=None, *, tolerant=False, projection=None, host_numbers=False):
        check = checks[index]
        equal(check["expected"], expected, check["name"] + " expected", tolerant=tolerant)
        observed = check["actual"] if projection is None else projection(check["actual"])
        equal(observed, expected if actual is None else actual, check["name"] + " actual",
              tolerant=tolerant, host_numbers=host_numbers)

    row(0, {"lap_times": [], "lap_started_at": 0.0}, projection=lambda a: {k: a[k] for k in ("lap_times", "lap_started_at")})
    subset(checks[0]["actual"], {"checkpoint_index": 0, "elapsed": 0.0, "distance": 0.0, "result_id": result_id}, "actual initial race")
    row(1, True, gates[:10])
    row(2, {"checkpoint_index": 10, "finished": False})
    row(3, [laps[0]])
    row(4, laps[0])
    row(5, before)
    row(6, before, tolerant=True)
    row(7, result_id)
    row(8, 0)
    pair = {key: before[key] for key in ("lap_times", "lap_started_at")}
    row(9, before, pair, tolerant=True)
    row(10, {"checkpoint_index": 10, "result_id": result_id})
    row(11, True)
    row(12, before, restored, tolerant=True)
    row(13, before, restored, tolerant=True)
    row(14, 0)
    row(15, restored["elapsed"])
    row(16, 16)
    row(17, True, gates)
    row(18, laps, tolerant=True)
    row(19, best)
    row(20, {"elapsedSeconds": total, "line": "Gesamtzeit   " + time_text(total)},
        {"elapsedSeconds": total, "text": data["reopened_result_stats_text"]})
    row(21, {"resets": 0, "resultId": result_id, "solved": 0, "stars": 3}, payload)
    row(22, 1)
    final_state = {"checkpoint_index": 16, "distance": gates[-1]["distance"],
                   "elapsed": gates[-1]["seconds"], "lap_started_at": gates[-1]["seconds"],
                   "lap_times": laps, "result_id": result_id}
    row(23, final_state, {"lap_times": laps, "lap_started_at": gates[-1]["seconds"]}, tolerant=True)
    row(24, payload)
    row(25, {"best": time_text(best), "total": time_text(total), "visible": True},
        {"text": data["reopened_result_stats_text"], "visible": True})
    local_stars = checks[26]["expected"].get("local_stars")
    require(type(local_stars) is int and local_stars >= 3, "observed local progress after lap reward")
    row(26, {"host_rewards": 1, "local_stars": local_stars})
    row(27, [False, False])
    row(28, [place_title(payload["place"])] * 2)
    ranked_ui = data["reopened_result_ui"]
    row(29, {"action_disabled": ACTIONS, "displayed_speed_kmh": 0},
        {"immediate": {k: v for k, v in ranked_ui.items() if k != "after_tick"}, "after_tick": ranked_ui["after_tick"]})
    ack = checks[30]["actual"]
    require(type(ack) is dict and set(ack) == {"returns", "save_exists"} and
            type(ack["returns"]) is list and len(ack["returns"]) == 1, "one completed ACK return")
    row(30, {"resultId": result_id, "save_exists": False, "status": "completed"},
        projection=lambda a: {"save_exists": a["save_exists"], "resultId": a["returns"][0]["resultId"], "status": a["returns"][0]["status"]})
    host_payload = dict(payload)
    if host_payload["sessionId"] == "":
        host_payload["sessionId"] = "recovered-lap-continuity"
    equal(ack["returns"][0], host_payload, "exact normalized host ACK payload", host_numbers=True)
    for index in range(31, 104):
        expected = STATIC_EXPECTED[index]
        if 88 <= index <= 96:
            row(index, expected, projection=lambda a: {"has_best": "Beste Runde   " in a["text"],
                "line": a["text"].split("Beste Runde   ")[1].split("\n")[0] if "Beste Runde   " in a["text"] else ""})
            equal(checks[index]["actual"]["lap_times"], [], "legacy result has no invented lap history")
            legacy_lines = ["Gesamtzeit   00:58.000"]
            if expected["has_best"]:
                legacy_lines.append("Beste Runde   " + expected["line"])
            legacy_lines.extend(("Sterne gesammelt   0", "Belohnung   +3 Sterne"))
            equal(checks[index]["actual"]["text"], "\n".join(legacy_lines), "complete actual legacy result text")
        elif index == 100:
            row(index, expected, projection=lambda a: {key: a[key]["displayed_speed_kmh"] for key in ("driving", "paused", "finished", "after_tick")} | {"raw_speed": a["driving"]["raw_speed"]})
            state = checks[index]["actual"]
            for key in ("driving", "paused", "finished", "after_tick"):
                equal(state[key]["raw_speed"], 12.0, "time-trial raw speed never changed")
                wanted = "43" if key in ("driving", "paused") else "0"
                hud_speed(state[key]["hud_text"], wanted)
            finished_ui(state["finished"], "Ziel!", after_tick=False)
            finished_ui(state["after_tick"], "Ziel!", after_tick=False)
        elif index == 103:
            ui = data["direct_result_ui"]
            row(index, expected, {"immediate": {k: v for k, v in ui.items() if k != "after_tick"}, "after_tick": ui["after_tick"]})
        else:
            row(index, expected)


FLOW_NAMES = (
    "gate-twelve touch pause saves a paused race",
    "second-lap touch reopen retains completed lap timing",
    "second-lap touch reopen keeps paused progress and identity",
    "full touch race retains two independently measured lap intervals",
    "public best and total equal measured gate milliseconds",
    "finished touch reopen keeps the original public payload",
    "finished touch reopen visibly retains original result lines",
    "finished touch reopen hides controls and immediately displays stopped HUD",
    "finished touch reopen cannot award twice",
)
FLOW_PNGS = (
    "01-start-grid.png", "02-paused-mid-race.png", "03-restored-race.png",
    "04-result.png", "05-reopened-garage.png", "06-reopened-result.png",
)


@evidence_guard
def validate_complete_flow(data: dict) -> None:
    checks = common(data, 9, FLOW_PROBE_SHA256)
    require(tuple(row["name"] for row in checks) == FLOW_NAMES, "ordered nine new flow labels")
    equal(data.get("actual_menu_touch_steps"), 5, "five actual garage steps")
    equal(data.get("save_reopen_resume"), True, "original touch continuation")
    equal(data.get("lap2_save_reopen_resume"), True, "second-lap touch continuation")
    equal(data.get("input"), "screen touch/drag; physics stepped at 1/60; no teleport or forced finish", "actual input scope")
    laps, best, total = gates_context(data.get("ordered_gates"))
    gates, payload = data["ordered_gates"], data.get("result")
    require(type(payload) is dict, "flow result payload")
    result_id = payload.get("resultId")
    result_payload(payload, result_id, best, total)
    equal(data.get("expected_laps"), laps, "flow gate-derived lap intervals", tolerant=True)
    equal(data.get("lap_times"), laps, "actual two flow laps", tolerant=True)
    equal(data.get("best_lap_seconds_unrounded"), min(laps), "raw actual best lap", tolerant=True)
    equal(data.get("finished_elapsed_seconds"), gates[-1]["seconds"], "flow raw finish elapsed")
    equal(data.get("reopened_result_elapsed_seconds"), data["finished_elapsed_seconds"], "flow reopen elapsed unchanged")
    equal(data.get("reopened_result_payload"), payload, "flow exact reopened payload")
    equal(data.get("result_stats_visible"), True, "original actual result label visible")
    equal(data.get("reopened_result_stats_visible"), True, "reopened actual result label visible")
    result_text(data.get("actual_result_stats_text"), payload)
    equal(data.get("reopened_result_stats_text"), data["actual_result_stats_text"], "full result text unchanged")
    equal(data.get("reward_calls"), 1, "flow one host reward")
    before, restored = data.get("lap2_before"), data.get("lap2_restored")
    equal(before, {"lap_times": [laps[0]], "lap_started_at": laps[0],
                   "checkpoint_index": 12, "distance": gates[11]["distance"],
                   "elapsed": gates[11]["seconds"], "result_id": result_id}, "flow saved lap two")
    equal(restored, before, "flow restored progress and lap timing", tolerant=True)
    ui = data.get("reopened_result_ui")
    finished_ui(ui, place_title(payload["place"]))

    def row(index, expected, actual=None, *, tolerant=False):
        check = checks[index]
        equal(check["expected"], expected, check["name"] + " expected", tolerant=tolerant)
        equal(check["actual"], expected if actual is None else actual,
              check["name"] + " actual", tolerant=tolerant)

    row(0, True, {"game": "kart", "status": "paused", "resultId": result_id,
                  "sessionId": "complete-touch-race", "solved": 0.0, "stars": 0.0})
    row(1, before, restored, tolerant=True)
    row(2, before, restored, tolerant=True)
    row(3, laps, tolerant=True)
    row(4, {"bestLapSeconds": best, "elapsedSeconds": total}, payload)
    row(5, payload)
    row(6, {"text": data["actual_result_stats_text"], "visible": True})
    row(7, {"all_actions_disabled": True, "controls_visible": False, "displayed_speed_kmh": 0},
        {"immediate": {k: v for k, v in ui.items() if k != "after_tick"}, "after_tick": ui["after_tick"]})
    local_stars = checks[8]["expected"].get("local_stars")
    require(type(local_stars) is int and local_stars >= 3, "observed local progress after reward")
    row(8, {"host_rewards": 1, "local_stars": local_stars})
    screenshots = data.get("screenshot_sha256")
    require(type(screenshots) is dict and set(screenshots) == set(FLOW_PNGS), "exact six screenshot roles")
    for name, digest in screenshots.items():
        require(type(digest) is str and re.fullmatch(r"[0-9a-f]{64}", digest) is not None, "screenshot digest " + name)
    equal(data.get("reopened_result_screenshot"), "06-reopened-result.png", "finished reopen screenshot role")
    equal(data.get("reopened_result_screenshot_sha256"), screenshots["06-reopened-result.png"], "finished screenshot matching digest")


def regular_bytes(path: Path) -> bytes:
    require(not path.is_symlink() and path.is_file(), "regular evidence file: " + str(path))
    value = path.read_bytes()
    require(bool(value), "nonempty evidence file: " + str(path))
    return value


def sha256(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def load_evidence(path: Path) -> tuple[dict, str]:
    def unique_pairs(pairs):
        value = {}
        for key, entry in pairs:
            require(key not in value, "duplicate JSON evidence key: " + key)
            value[key] = entry
        return value
    raw = regular_bytes(path)
    try:
        data = json.loads(raw, object_pairs_hook=unique_pairs,
                          parse_constant=lambda value: require(False, "nonfinite JSON: " + value))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("Invalid JSON evidence: " + str(path)) from error
    return data, sha256(raw)


def bound_file(path: Path, expected_sha: str) -> None:
    require(sha256(regular_bytes(path)) == expected_sha, "actual file SHA256 mismatch: " + str(path))


def bound_png(path: Path, expected_sha: str) -> None:
    raw = regular_bytes(path)
    require(sha256(raw) == expected_sha, "actual screenshot SHA256 mismatch: " + str(path))
    require(len(raw) > 33 and raw[:8] == b"\x89PNG\r\n\x1a\n" and raw[12:16] == b"IHDR",
            "actual PNG header: " + str(path))
    require(struct.unpack(">II", raw[16:24]) == (1280, 720), "actual probe viewport dimensions: " + str(path))
    cursor, header_count, compressed, ended = 8, 0, bytearray(), False
    while cursor < len(raw):
        require(cursor + 12 <= len(raw), "complete PNG chunk header")
        length = struct.unpack(">I", raw[cursor:cursor + 4])[0]
        end = cursor + length + 12
        require(end <= len(raw), "complete PNG chunk data")
        kind, chunk = raw[cursor + 4:cursor + 8], raw[cursor + 8:cursor + 8 + length]
        crc = struct.unpack(">I", raw[cursor + 8 + length:end])[0]
        require(zlib.crc32(kind + chunk) & 0xFFFFFFFF == crc, "actual PNG chunk CRC")
        if kind == b"IHDR":
            header_count += 1
            require(cursor == 8 and length == 13 and header_count == 1, "single first PNG IHDR")
            require(chunk[8] == 8 and chunk[9] in (2, 6) and chunk[10:] == b"\x00\x00\x00",
                    "actual noninterlaced RGB/RGBA viewport PNG")
            channels = 3 if chunk[9] == 2 else 4
        elif kind == b"IDAT":
            require(header_count == 1 and not ended, "PNG data follows header")
            compressed.extend(chunk)
        elif kind == b"IEND":
            require(length == 0 and end == len(raw), "complete PNG IEND without trailing data")
            ended = True
        cursor = end
    require(header_count == 1 and ended and bool(compressed), "complete PNG image chunks")
    decoded_size = (1280 * channels + 1) * 720
    try:
        decoder = zlib.decompressobj()
        pixels = decoder.decompress(bytes(compressed), decoded_size + 1)
    except zlib.error as error:
        raise ValueError("Corrupt PNG compressed image") from error
    require(len(pixels) == decoded_size and decoder.eof and not decoder.unused_data and
            not decoder.unconsumed_tail, "complete bounded PNG image data")
    stride = 1280 * channels + 1
    require(all(pixels[row * stride] in range(5) for row in range(720)), "valid PNG scanline filters")


@evidence_guard
def summarize_native_lap_evidence(godot_root: Path, *, lap_directory=None,
                                  flow_directory=None, time_directory=None) -> dict:
    godot_root = Path(godot_root)
    for relative, expected in (
        ("scripts/games/kart_island.gd", SOURCE_SHA256),
        ("scripts/tests/kart_race_continuity_regression.gd", LAP_PROBE_SHA256),
        ("scripts/tests/kart_lap_session_fixtures.gd", FIXTURE_PROBE_SHA256),
        ("scripts/tests/kart_complete_flow_regression.gd", FLOW_PROBE_SHA256),
        ("scripts/tests/kart_time_format_regression.gd", TIME_PROBE_SHA256),
    ):
        bound_file(godot_root / relative, expected)
    lap_directory = Path(lap_directory) if lap_directory else godot_root / "exports/race-continuity"
    flow_directory = Path(flow_directory) if flow_directory else godot_root / "exports/complete-flow"
    time_directory = Path(time_directory) if time_directory else godot_root / "exports/time-format"
    lap, lap_sha = load_evidence(lap_directory / "lap-session-evidence.json")
    flow, _ = load_evidence(flow_directory / "evidence.json")
    timing, timing_sha = load_evidence(time_directory / "evidence.json")
    validate_lap_session(lap)
    validate_complete_flow(flow)
    validate_time_format(timing)
    require({p.name for p in lap_directory.glob("*.png")} == {"result_reopen.png"}, "exact lap screenshot role")
    bound_png(lap_directory / "result_reopen.png", lap["result_reopen_png_sha256"])
    require({p.name for p in flow_directory.glob("*.png")} == set(FLOW_PNGS), "exact six flow PNG files")
    for name in FLOW_PNGS:
        bound_png(flow_directory / name, flow["screenshot_sha256"][name])
    return {
        "complete_flow_reopened_result_stats_text": flow["reopened_result_stats_text"],
        "complete_flow_reopened_result_png_sha256": flow["reopened_result_screenshot_sha256"],
        "complete_flow_lap2_save_reopen_resume": True,
        "complete_flow_finished_save_reopen": True,
        "complete_flow_reopened_result_ui": flow["reopened_result_ui"],
        "lap_session_checks": lap["check_count"],
        "lap_session_legacy_fixture_count": 20,
        "lap_session_evidence_sha256": lap_sha,
        "lap_session_source_sha256": lap["source_sha256"],
        "lap_session_probe_sha256": lap["probe_sha256"],
        "lap_session_reopened_result_stats_text": lap["reopened_result_stats_text"],
        "lap_session_reopened_result_png_sha256": lap["result_reopen_png_sha256"],
        "lap_session_direct_result_ui": lap["direct_result_ui"],
        "lap_session_reopened_result_ui": lap["reopened_result_ui"],
        "lap_session_fixture_probe_sha256": lap["fixture_probe_sha256"],
        "time_format_checks": 29,
        "time_format_evidence_sha256": timing_sha,
    }

LAP_NAMES = ('new race starts with empty known lap timing',
 'physical driving reaches the first lap boundary',
 'physical driving reaches lap two before saving',
 'the first completed lap is measured from gate eight',
 'the current lap starts exactly at gate eight',
 'pause freezes both lap timing and race state',
 'quality rebuild preserves lap timing',
 'quality rebuild preserves race result ID',
 'lap-two atomic ConfigFile exists',
 'ConfigFile stores completed laps and current start',
 'lap-two save retains legitimate gate progress and identity',
 'a new instance offers the saved lap-two race',
 'new-instance resume restores frozen progress and identity',
 'new-instance resume restores both lap timing fields',
 'a paused resume never awards a result',
 'resume itself does not advance elapsed time',
 'resumed physical driving completes sixteen gates',
 'all physically crossed gates are ordered and monotonic',
 'two completed laps equal independently measured gate intervals',
 'published best lap agrees with the two measured laps',
 'published milliseconds and the visible total agree with gate sixteen',
 'the legitimate race keeps ID, integer solved zero, three stars and zero resets',
 'the driven race awards exactly one host reward',
 'finished ConfigFile retains both completed laps',
 'finished reopen retains the original public payload',
 'finished reopen visibly retains both best and total result lines',
 'finished reopen never awards another local or host reward',
 'saved finished result hides driving controls immediately and after tick',
 'saved finished result shows the result heading immediately and after tick',
 'saved finished result disables every driving action and displays stopped speed immediately',
 'completed ACK removes the durable save without a duplicate award',
 'optional timing data still restores: valid measured pair',
 'validated timing pair: valid measured pair',
 'optional timing data still restores: both timing keys absent',
 'validated timing pair: both timing keys absent',
 'optional timing data still restores: history key absent',
 'validated timing pair: history key absent',
 'optional timing data still restores: start key absent',
 'validated timing pair: start key absent',
 'optional timing data still restores: history is a string',
 'validated timing pair: history is a string',
 'optional timing data still restores: start is a string',
 'validated timing pair: start is a string',
 'optional timing data still restores: start is a boolean',
 'validated timing pair: start is a boolean',
 'optional timing data still restores: interval is a boolean',
 'validated timing pair: interval is a boolean',
 'optional timing data still restores: interval is a string',
 'validated timing pair: interval is a string',
 'optional timing data still restores: zero interval',
 'validated timing pair: zero interval',
 'optional timing data still restores: negative interval',
 'validated timing pair: negative interval',
 'optional timing data still restores: NaN interval',
 'validated timing pair: NaN interval',
 'optional timing data still restores: infinite interval',
 'validated timing pair: infinite interval',
 'optional timing data still restores: NaN start',
 'validated timing pair: NaN start',
 'optional timing data still restores: infinite start',
 'validated timing pair: infinite start',
 'optional timing data still restores: invalid negative start',
 'validated timing pair: invalid negative start',
 'optional timing data still restores: future start',
 'validated timing pair: future start',
 'optional timing data still restores: history exceeds start',
 'validated timing pair: history exceeds start',
 'optional timing data still restores: more history than completed gates',
 'validated timing pair: more history than completed gates',
 'optional timing data still restores: later lap cannot begin at race start zero',
 'validated timing pair: later lap cannot begin at race start zero',
 'legacy lap-two duration stays explicitly unknown',
 'resave stores the unknown sentinel',
 'new-instance resave round-trip keeps the unknown sentinel',
 'the unknown partial lap is skipped at its legitimate boundary',
 'a new known boundary can be saved without invented history',
 'known start with shorter legacy history restores',
 'only the subsequent full legacy lap is recorded',
 'the subsequently measured legacy lap survives another restore',
 'finishing an unknown partial legacy lap never invents a best time',
 'legacy gate correction precedes timing: v1',
 'legacy later lap remains unmeasured: v1',
 'legacy gate correction precedes timing: v2',
 'legacy later lap remains unmeasured: v2',
 'legacy gate correction precedes timing: v3',
 'legacy later lap remains unmeasured: v3',
 'legacy gate correction precedes timing: v4',
 'legacy later lap remains unmeasured: v4',
 'legacy result displays only a valid known payload best: 28.0',
 'legacy result displays only a valid known payload best: 0.0',
 'legacy result displays only a valid known payload best: -1.0',
 'legacy result displays only a valid known payload best: 28',
 'legacy result displays only a valid known payload best: true',
 'legacy result displays only a valid known payload best: inf',
 'legacy result displays only a valid known payload best: nan',
 'legacy result displays only a valid known payload best: 1000.0',
 'legacy result displays only a valid known payload best: '
 '100000000000000001097906362944045541740492309677311846336810682903157585404911491537163328978494688899061249669721172515611590283743140088328307009198146046031271664502933027185697489699588559043338384466165001178426897626212945177628091195786707458122783970171784415105291802893207873272974885715430223118336.0',
 'first-lap legacy retains the known original start',
 'known later start accepts shorter history after legacy gaps',
 'finished training retains its deliberately completed partial lap',
 'time-trial HUD only changes finished display without mutating speed',
 'direct noncinematic result hides driving controls immediately and after tick',
 'direct noncinematic result shows the result heading immediately and after tick',
 'direct noncinematic result disables every driving action and displays stopped speed immediately')

STATIC_EXPECTED = {31: True,
 32: [[30.0], 30.0],
 33: True,
 34: [[], -1.0],
 35: True,
 36: [[], -1.0],
 37: True,
 38: [[], -1.0],
 39: True,
 40: [[], -1.0],
 41: True,
 42: [[], -1.0],
 43: True,
 44: [[], -1.0],
 45: True,
 46: [[], -1.0],
 47: True,
 48: [[], -1.0],
 49: True,
 50: [[], -1.0],
 51: True,
 52: [[], -1.0],
 53: True,
 54: [[], -1.0],
 55: True,
 56: [[], -1.0],
 57: True,
 58: [[], -1.0],
 59: True,
 60: [[], -1.0],
 61: True,
 62: [[], -1.0],
 63: True,
 64: [[], -1.0],
 65: True,
 66: [[], -1.0],
 67: True,
 68: [[], -1.0],
 69: True,
 70: [[], -1.0],
 71: [[], -1.0],
 72: -1.0,
 73: [[], -1.0],
 74: [[], 60.0],
 75: [[], 60.0],
 76: [[], 60.0],
 77: [[30.0], 90.0],
 78: [[30.0], 90.0],
 79: {'bestLapSeconds': 0.0, 'lap_times': []},
 80: {'gate': 10, 'restored': True},
 81: [[], -1.0],
 82: {'gate': 10, 'restored': True},
 83: [[], -1.0],
 84: {'gate': 10, 'restored': True},
 85: [[], -1.0],
 86: {'gate': 10, 'restored': True},
 87: [[], -1.0],
 88: {'has_best': True, 'line': '00:28.000'},
 89: {'has_best': False, 'line': ''},
 90: {'has_best': False, 'line': ''},
 91: {'has_best': False, 'line': ''},
 92: {'has_best': False, 'line': ''},
 93: {'has_best': False, 'line': ''},
 94: {'has_best': False, 'line': ''},
 95: {'has_best': False, 'line': ''},
 96: {'has_best': False, 'line': ''},
 97: [[], 0.0],
 98: [[30.0], 60.0],
 99: [[30.0, 20.0], 30.0],
 100: {'after_tick': 0, 'driving': 43, 'finished': 0, 'paused': 43, 'raw_speed': 12.0},
 101: [False, False],
 102: ['Ziel!', 'Ziel!'],
 103: {'action_disabled': {'boost': True, 'brake': True, 'drift': True, 'gas': True, 'item': True},
       'displayed_speed_kmh': 0}}

TIME_CASES = ((0.0, '00:00.000'),
 (0.0004, '00:00.000'),
 (0.0005, '00:00.001'),
 (0.0006, '00:00.001'),
 (0.001, '00:00.001'),
 (0.125, '00:00.125'),
 (0.9994, '00:00.999'),
 (0.9995, '00:01.000'),
 (0.9996, '00:01.000'),
 (1.0, '00:01.000'),
 (1.0004, '00:01.000'),
 (1.001, '00:01.001'),
 (12.345, '00:12.345'),
 (12.3454, '00:12.345'),
 (12.3456, '00:12.346'),
 (40.9999999999977, '00:41.000'),
 (41.0, '00:41.000'),
 (59.9994, '00:59.999'),
 (59.9995, '01:00.000'),
 (59.9996, '01:00.000'),
 (60.0, '01:00.000'),
 (60.9999999999977, '01:01.000'),
 (61.125, '01:01.125'),
 (119.9996, '02:00.000'),
 (120.0, '02:00.000'),
 (3599.9996, '60:00.000'),
 (3600.125, '60:00.125'),
 (90.0, '01:30.000'),
 (489.123, '08:09.123'))
