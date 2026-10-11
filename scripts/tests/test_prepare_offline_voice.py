import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest

PATH = Path(__file__).resolve().parents[1] / "prepare_offline_voice.py"
SPEC = importlib.util.spec_from_file_location("prepare_offline_voice", PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class OfflineModelPackagingTest(unittest.TestCase):
    def fixture(self, root):
        main = root / "android/app/src/main"
        main.mkdir(parents=True)
        (main / "AndroidManifest.xml").write_text("<manifest/>")
        (root / "android/app/build.gradle.kts").write_text("android { }\n")
        (root / "config").mkdir()
        voice = root / "assets/audio/voice/lumo_free"
        voice.mkdir(parents=True)
        (voice / "LICENSE-MODEL.txt").write_text("TEST LICENSE, not the real model")
        (voice / "LICENSE-CODE.txt").write_text("TEST code license")
        archive = root / "fixture.tar.bz2"
        payload = b"deterministic packaging fixture, not a speech model"
        with tarfile.open(archive, "w:bz2") as output:
            member = tarfile.TarInfo("fixture/model.int8.onnx")
            member.size = len(payload)
            output.addfile(member, io.BytesIO(payload))
        config = {
            "bundle_url": "https://example.invalid/never-used",
            "bundle_sha256": MODULE.digest(archive),
            "bundle_directory": "fixture",
            "file_sha256": {"model.int8.onnx": hashlib.sha256(payload).hexdigest()},
            "model_license_sha256": MODULE.digest(voice / "LICENSE-MODEL.txt"),
            "onnxruntime_version": "1.23.1",
            "profile": "test-fixture", "preset": "F2",
        }
        (root / "config/lumo-offline-voice.json").write_text(json.dumps(config))
        return archive, config

    def test_pinned_bytes_license_dependency_and_idempotence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive, config = self.fixture(root)
            for _ in range(2):
                result = MODULE.bundle(root, archive)
                self.assertEqual(result["runtime_cloud_calls"], 0)
                self.assertFalse(result["system_tts"])
            gradle = (root / "android/app/build.gradle.kts").read_text()
            self.assertEqual(gradle.count(MODULE.GRADLE_START), 1)
            self.assertEqual(gradle.count("onnxruntime-android:1.23.1"), 1)
            target = root / "android/app/src/main/assets/lumo_offline_voice"
            self.assertEqual(MODULE.digest(target / "model.int8.onnx"),
                             config["file_sha256"]["model.int8.onnx"])
            self.assertEqual((target / "LICENSE-MODEL.txt").read_bytes(),
                             (root / "assets/audio/voice/lumo_free/LICENSE-MODEL.txt").read_bytes())

    def test_wrong_archive_is_refused_before_payload_use(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive, _ = self.fixture(root)
            archive.write_bytes(b"not the approved archive")
            with self.assertRaisesRegex(ValueError, "digest mismatch"):
                MODULE.bundle(root, archive)

    def test_missing_or_modified_model_license_is_not_silently_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive, _ = self.fixture(root)
            (root / "assets/audio/voice/lumo_free/LICENSE-MODEL.txt").write_text("wrong license")
            with self.assertRaisesRegex(ValueError, "Open RAIL-M"):
                MODULE.bundle(root, archive)

    def test_existing_marker_cannot_hide_a_changed_runtime(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive, _ = self.fixture(root)
            MODULE.bundle(root, archive)
            gradle = root / "android/app/build.gradle.kts"
            gradle.write_text(gradle.read_text().replace(":1.23.1", ":0.0.0"))
            with self.assertRaisesRegex(ValueError, "pinned runtime"):
                MODULE.bundle(root, archive)

    def test_unbalanced_dependency_marker_is_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive, _ = self.fixture(root)
            gradle = root / "android/app/build.gradle.kts"
            gradle.write_text("android { }\n" + MODULE.GRADLE_END)
            with self.assertRaisesRegex(ValueError, "dependency markers"):
                MODULE.bundle(root, archive)
