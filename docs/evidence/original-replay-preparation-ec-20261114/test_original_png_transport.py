from __future__ import annotations

import contextlib
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image
import original_replay as reader
import original_png_transport as exporter


class OriginalPngTransportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.extracted = self.root / "originals"
        self.output = self.root / "new-receipts"
        self.output.mkdir()
        self.names = {
            "android": "lumo-connect-four-2020-android-c4",
            "update": "lumo-connect-four-2020-in-place-update-proof",
            "desktop": "lumo-connect-four-2020-desktop-runtime",
        }
        self.artifacts = {}
        for index, (label, name) in enumerate(self.names.items(), 1):
            self.artifacts[name] = {
                "metadata": {"id": index, "name": name, "size_in_bytes": 1,
                             "digest": "sha256:" + str(index) * 64},
                "destination": label, "files": [],
            }
            (self.extracted / label).mkdir(parents=True)
        png = io.BytesIO()
        Image.new("RGB", (2, 2), (17, 29, 43)).save(png, format="PNG")
        self.png = png.getvalue()
        self.write_json("android", "c4/c4-result.json",
                        {"transitions": [{"action": "drop", "after": "accepted-007"}]})
        self.write_json("android", "c4/observations/accepted-007.json",
                        {"frame": "accepted-007.png"})
        self.write_json("android", "village/village-result.json",
                        {"native": {"frame": {"file": "accepted-village.png"}}})
        self.write_json("android", "main/tour-result.json",
                        {"steps": [{"step": "race-drive", "ok": True, "gas_pulses": 3}]})
        self.write_json("update", "update-result.json",
                        {"native_tour": {"drive": {"gas_pulses": 2}}})
        for label, path in (
            ("android", "c4/accepted-007.png"),
            ("android", "village/accepted-village.png"),
            ("android", "village/returned-flutter-frame.png"),
            ("android", "main/21_race_driving_late_2.png"),
            ("update", "21_race_driving_late_1.png"),
            ("update", "updated-profile-offline.png"),
            ("desktop", "runtime/connect_four_win.png"),
            ("update", "fold-cover.png"),
        ):
            self.write_bytes(label, path, self.png)
        self.receipt = {
            "status": "PASS_EXACT_ORIGINALS_REPLAYED",
            "host_source": reader.HOST, "native_source": reader.NATIVE,
            "acceptance_run": reader.RUN, "acceptance_attempt": reader.ATTEMPT,
            "reader_run": 123, "reader_attempt": 1,
            "original_archives": {name: row["metadata"] for name, row in self.artifacts.items()},
            "candidate": {"apks": {"x86_64": {"sha256": "a" * 64},
                                   "arm64-v8a": {"sha256": "b" * 64}}},
        }
        self.save_inputs()

    def tearDown(self):
        self.temporary.cleanup()

    def write_bytes(self, label, relative, payload):
        path = self.extracted / label / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(payload)
        rows = self.artifacts[self.names[label]]["files"]
        rows[:] = [row for row in rows if row["path"] != relative]
        rows.append({"path": relative, "bytes": len(payload),
                     "sha256": hashlib.sha256(payload).hexdigest()})

    def write_json(self, label, relative, value):
        self.write_bytes(label, relative, (json.dumps(value) + "\n").encode())

    def save_inputs(self):
        (self.output / "original-archives.json").write_text(json.dumps({"artifacts": self.artifacts}))
        (self.output / "ORIGINAL-REPLAY-RECEIPT.json").write_text(json.dumps(self.receipt))

    def execute(self, stream):
        with patch.object(reader, "EXTRACTED", self.extracted), \
                patch.object(reader, "OUTPUT", self.output), \
                patch.object(reader, "identity", return_value=None), \
                contextlib.redirect_stdout(stream):
            exporter.main()

    def test_selects_accepted_dynamic_ids_and_real_last_drive_frames_without_changes(self):
        before = reader.file_inventory(self.extracted)
        stream = io.StringIO()
        self.execute(stream)
        self.assertEqual(before, reader.file_inventory(self.extracted))
        metadata = reader.read(self.output / "visual-originals.json")
        self.assertEqual(metadata["count"], 8)
        self.assertEqual(metadata["total_original_png_bytes"], len(self.png) * 8)
        images = {row["id"]: row for row in metadata["images"]}
        self.assertEqual(images["android-c4-after-actual-drop-and-bot"]["path"], "c4/accepted-007.png")
        self.assertEqual(images["android-main-actual-drive"]["path"], "main/21_race_driving_late_2.png")
        self.assertEqual(images["android-update-actual-drive"]["path"], "21_race_driving_late_1.png")
        self.assertIn("not an Android victory", images["desktop-c4-actual-victory"]["scope"])
        rows = stream.getvalue().splitlines()
        starts = [json.loads(line.split(" ", 1)[1]) for line in rows if line.startswith("LUMO_PNG_BEGIN ")]
        parts = [json.loads(line.split(" ", 1)[1]) for line in rows if line.startswith("LUMO_PNG_PART ")]
        ends = [json.loads(line.split(" ", 1)[1]) for line in rows if line.startswith("LUMO_PNG_END ")]
        self.assertEqual((len(starts), len(parts), len(ends)), (8, 8, 8))
        import base64
        for item in starts:
            encoded = "".join(row["data"] for row in parts if row["id"] == item["id"])
            self.assertEqual(base64.b64decode(encoded, validate=True), self.png)
            self.assertEqual(item["bytes"], len(self.png))
            self.assertEqual((item["width"], item["height"]), (2, 2))
        self.assertFalse(metadata["human_visual_review_in_this_job"])

    def test_modified_original_png_is_rejected_before_any_image_is_emitted(self):
        (self.extracted / "android/c4/accepted-007.png").write_bytes(b"changed after acceptance")
        stream = io.StringIO()
        with self.assertRaises(ValueError):
            self.execute(stream)
        self.assertEqual(stream.getvalue(), "")
        self.assertFalse((self.output / "visual-originals.json").exists())

    def test_authenticated_report_cannot_select_an_outside_file(self):
        self.write_json("android", "c4/observations/accepted-007.json", {"frame": "../outside.png"})
        self.write_bytes("android", "outside.png", self.png)
        self.save_inputs()
        stream = io.StringIO()
        with self.assertRaises(ValueError):
            self.execute(stream)
        self.assertEqual(stream.getvalue(), "")
        self.assertFalse((self.output / "visual-originals.json").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
