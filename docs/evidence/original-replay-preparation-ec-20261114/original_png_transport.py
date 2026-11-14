#!/usr/bin/env python3
"""Transport a small set of unchanged accepted original PNGs for direct review."""
from __future__ import annotations

import base64
import hashlib
import io
import json
from pathlib import PurePosixPath

from PIL import Image
import original_replay as reader

MAX_TOTAL_PNG_BYTES = 24 * 1024**2
MAX_ONE_PNG_BYTES = 8 * 1024**2
CHUNK_CHARACTERS = 8192


def main():
    reader.identity()
    receipt = reader.read(reader.OUTPUT / "ORIGINAL-REPLAY-RECEIPT.json")
    reader.require(receipt["status"] == "PASS_EXACT_ORIGINALS_REPLAYED"
                   and receipt["host_source"] == reader.HOST
                   and receipt["native_source"] == reader.NATIVE
                   and receipt["acceptance_run"] == reader.RUN
                   and receipt["acceptance_attempt"] == reader.ATTEMPT,
                   "Successful exact current original replay is required")
    original = reader.read(reader.OUTPUT / "original-archives.json")["artifacts"]
    for name, row in original.items():
        reader.require(row["metadata"] == receipt["original_archives"][name],
                       "Image source archive differs from the verified receipt")
    android = "lumo-connect-four-2020-android-c4"
    update = "lumo-connect-four-2020-in-place-update-proof"
    desktop = "lumo-connect-four-2020-desktop-runtime"
    files = {name: {entry["path"]: entry for entry in row["files"]}
             for name, row in original.items()}

    def bound_file(name, relative):
        reader.require(type(relative) is str, "Original image/report path must be a string")
        path = PurePosixPath(relative)
        reader.require(bool(path.parts) and not path.is_absolute()
                       and str(path) == relative and "\\" not in relative
                       and all(part not in (".", "..") for part in path.parts),
                       "Original image/report path is not canonical")
        reader.require(relative in files[name], "Original image/report was not in the checked archive")
        root = reader.EXTRACTED / original[name]["destination"]
        actual = root / relative
        reader.require(actual.resolve().is_relative_to(root.resolve()),
                       "Original image/report escaped its checked archive")
        identity = reader.record(actual)
        expected = files[name][relative]
        reader.require(identity == {key: expected[key] for key in ("bytes", "sha256")},
                       "Original image/report bytes changed after replay")
        return actual

    def original_json(name, relative):
        return reader.read(bound_file(name, relative))

    c4 = original_json(android, "c4/c4-result.json")
    drops = [item for item in c4["transitions"] if item.get("action") == "drop"]
    reader.require(bool(drops) and type(drops[-1]["after"]) is str, "Accepted actual C4 move missing")
    observation_id = drops[-1]["after"]
    reader.require("/" not in observation_id and "\\" not in observation_id
                   and observation_id not in ("", ".", ".."), "Invalid accepted observation identifier")
    observation = original_json(android, "c4/observations/" + observation_id + ".json")
    village = original_json(android, "village/village-result.json")
    tour = original_json(android, "main/tour-result.json")
    drive = [item for item in tour["steps"] if item.get("step") == "race-drive"]
    reader.require(len(drive) == 1 and type(drive[0]["gas_pulses"]) is int
                   and 1 <= drive[0]["gas_pulses"] <= 3, "Accepted main drive pulse count differs")
    update_result = original_json(update, "update-result.json")
    update_pulses = update_result["native_tour"]["drive"]["gas_pulses"]
    reader.require(type(update_pulses) is int and 1 <= update_pulses <= 3,
                   "Accepted in-place update drive pulse count differs")
    selected = [
        ("android-c4-after-actual-drop-and-bot", android, "c4/" + observation["frame"],
         "Android API35 x86_64; accepted child move and bot response, not a completed victory."),
        ("android-village-native", android, "village/" + village["native"]["frame"]["file"],
         "Android API35 x86_64; accepted native Village arrival."),
        ("android-village-returned-flutter", android, "village/returned-flutter-frame.png",
         "Android API35 x86_64; actual Flutter return after Village."),
        ("android-main-actual-drive", android,
         "main/21_race_driving_late_" + str(drive[0]["gas_pulses"] - 1) + ".png",
         "Android API35 x86_64; last accepted gas pulse of main race driving."),
        ("android-update-actual-drive", update,
         "21_race_driving_late_" + str(update_pulses - 1) + ".png",
         "Android API35 x86_64; actual driving after the in-place 2017-to-2020 update."),
        ("android-update-profile", update, "updated-profile-offline.png",
         "Android API35 x86_64; actual profile after in-place update."),
        ("desktop-c4-actual-victory", desktop, "runtime/connect_four_win.png",
         "Desktop Godot C4 victory; not an Android victory."),
        ("android-update-fold-cover", update, "fold-cover.png",
         "Android API35 x86_64; original Fold cover after in-place update."),
    ]
    byte_total = 0
    for label, name, relative, scope in selected:
        path = bound_file(name, relative)
        size = path.stat().st_size
        reader.require(0 < size <= MAX_ONE_PNG_BYTES, "Original PNG exceeds transport size bound")
        byte_total += size
    reader.require(byte_total <= MAX_TOTAL_PNG_BYTES, "Original PNG transport total exceeds bound")
    metadata_rows = []
    for label, name, relative, scope in selected:
        path = bound_file(name, relative)
        payload = path.read_bytes()
        expected = files[name][relative]
        reader.require(len(payload) == expected["bytes"]
                       and hashlib.sha256(payload).hexdigest() == expected["sha256"],
                       "Original PNG changed before transport")
        with Image.open(io.BytesIO(payload)) as picture:
            reader.require(picture.format == "PNG", "Only original PNG files are transported")
            dimensions = picture.size
            picture.verify()
        with Image.open(io.BytesIO(payload)) as picture:
            picture.load()
        encoded = base64.b64encode(payload).decode("ascii")
        chunks = [encoded[start:start + CHUNK_CHARACTERS]
                  for start in range(0, len(encoded), CHUNK_CHARACTERS)]
        metadata = {
            "id": label, "kind": "unchanged_current_acceptance_original",
            "source": reader.HOST, "native_source": reader.NATIVE,
            "acceptance_run": reader.RUN, "acceptance_attempt": reader.ATTEMPT,
            "reader_run": receipt["reader_run"], "reader_attempt": receipt["reader_attempt"],
            "artifact": original[name]["metadata"], "path": relative, "scope": scope,
            "git_blob": hashlib.sha1(b"blob " + str(len(payload)).encode() + b"\0" + payload).hexdigest(),
            "sha256": expected["sha256"], "bytes": len(payload), "mime_type": "image/png",
            "width": dimensions[0], "height": dimensions[1],
            "encoded_characters": len(encoded), "parts": len(chunks),
            "android_test_apk_sha256": receipt["candidate"]["apks"]["x86_64"]["sha256"],
            "arm64_delivery_apk_sha256": receipt["candidate"]["apks"]["arm64-v8a"]["sha256"],
        }
        metadata_rows.append(metadata)
        print("LUMO_PNG_BEGIN " + json.dumps(metadata, sort_keys=True), flush=True)
        for index, chunk in enumerate(chunks):
            print("LUMO_PNG_PART " + json.dumps({
                "id": label, "index": index, "data": chunk,
            }, sort_keys=True), flush=True)
        print("LUMO_PNG_END " + json.dumps({
            "id": label, "parts": len(chunks), "sha256": metadata["sha256"],
        }, sort_keys=True), flush=True)
    reader.write_new(reader.OUTPUT / "visual-originals.json", {
        "schema": 1, "source": reader.HOST, "native_source": reader.NATIVE,
        "acceptance_run": reader.RUN, "acceptance_attempt": reader.ATTEMPT,
        "count": len(metadata_rows), "total_original_png_bytes": byte_total,
        "images": metadata_rows, "bytes_unchanged": True,
        "human_visual_review_in_this_job": False,
        "scope": "Original PNG byte transport only; subsequent viewer observations must be recorded separately.",
    })
    print("LUMO_ORIGINAL_PNG_TRANSPORT_COMPLETE " + json.dumps({
        "images": len(metadata_rows), "bytes": byte_total,
        "metadata": reader.record(reader.OUTPUT / "visual-originals.json"),
    }, sort_keys=True), flush=True)


if __name__ == "__main__":
    main()
