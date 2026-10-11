"""Packaging guard fixtures only, NOT synthesized speech or Android playback."""
import hashlib
import io
import json
import sys
import unittest
from pathlib import Path
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_unified_apk import validate_offline_voice


class UnifiedApkVoiceTest(unittest.TestCase):
    def fixture(self):
        model = b"fixture weights, NOT an actual speech model"
        license_text = b"fixture license, NOT the original license"
        audio = b"fixture clip, NOT generated audio"
        config = {
            "profile": "fixture-local-voice", "preset": "F2", "speaker_id": 1,
            "sample_rate": 44100, "onnxruntime_version": "1.23.1",
            "file_sha256": {"model.onnx": hashlib.sha256(model).hexdigest()},
            "model_license_sha256": hashlib.sha256(license_text).hexdigest(),
        }
        catalog = {
            "variant": config["profile"], "preset": "F2", "speaker_id": 1,
            "machine_generated": True, "aliases": {},
            "clips": {
                str(i): {"id": f"free_{i:016x}",
                         "asset_sha256": hashlib.sha256(audio).hexdigest()}
                for i in range(150)
            },
        }
        mp = "assets/lumo_offline_voice/"
        fp = "assets/flutter_assets/assets/audio/voice/lumo_free/"
        files = {
            mp + "model-manifest.json": json.dumps(config).encode(),
            mp + "model.onnx": model,
            fp + "catalog.json": json.dumps(catalog).encode(),
        }
        for prefix in (mp, fp):
            files[prefix + "LICENSE-MODEL.txt"] = license_text
            files[prefix + "LICENSE-CODE.txt"] = b"fixture code notice"
        for clip in catalog["clips"].values():
            files[fp + clip["id"] + ".m4a"] = audio
        for library in ("libonnxruntime.so", "libonnxruntime4j_jni.so"):
            files["lib/arm64-v8a/" + library] = b"fixture native library"
        return files, config, catalog

    def verify(self, files, config, catalog):
        source = io.BytesIO()
        with zipfile.ZipFile(source, "w") as output:
            for name, content in files.items():
                output.writestr(name, content)
        with zipfile.ZipFile(source) as archive:
            return validate_offline_voice(archive, {"arm64-v8a"}, config, catalog)

    def test_complete_digest_pinned_fixture_is_accepted(self):
        files, config, catalog = self.fixture()
        result = self.verify(files, config, catalog)
        self.assertEqual(result["clipCount"], 150)
        self.assertIn("not audible", result["scope"])

    def test_changed_model_or_clip_is_rejected(self):
        for name in (
            "assets/lumo_offline_voice/model.onnx",
            "assets/flutter_assets/assets/audio/voice/lumo_free/free_0000000000000000.m4a",
        ):
            files, config, catalog = self.fixture()
            files[name] = b"modified"
            with self.assertRaisesRegex(RuntimeError, "digest mismatch"):
                self.verify(files, config, catalog)

    def test_missing_native_library_or_license_is_rejected(self):
        for name in (
            "lib/arm64-v8a/libonnxruntime4j_jni.so",
            "assets/lumo_offline_voice/LICENSE-MODEL.txt",
        ):
            files, config, catalog = self.fixture()
            del files[name]
            with self.assertRaisesRegex(RuntimeError, "Missing or duplicated"):
                self.verify(files, config, catalog)

    def test_changed_voice_preset_in_manifest_is_rejected(self):
        files, config, catalog = self.fixture()
        wrong = dict(config, preset="M4")
        files["assets/lumo_offline_voice/model-manifest.json"] = json.dumps(wrong).encode()
        with self.assertRaisesRegex(RuntimeError, "identity or model pin"):
            self.verify(files, config, catalog)


if __name__ == "__main__":
    unittest.main()
