import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

PATH = Path(__file__).resolve().parents[1] / "prepare_offline_voice.py"
SPEC = importlib.util.spec_from_file_location("prepare_offline_voice", PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class OfflineSpeechTokenizerTest(unittest.TestCase):
    """Actual Java normalization/tokenization; synthetic ONNX, no model inference."""

    @classmethod
    def setUpClass(cls):
        root = PATH.parents[1]
        cls.fixtures = Path(__file__).parent / 'fixtures/offline_voice_tokenizer'
        cls.expected_indexer = json.loads(
            (root / 'config/lumo-offline-voice.json').read_text()
        )['file_sha256']['unicode_indexer.bin']
        cls.java = cls.tool('java')
        javac = cls.tool('javac')
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-offline-tokenizer-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.classes = Path(cls.temp.name) / 'classes'
        cls.classes.mkdir()
        sources = [root / 'tools/auto_install/LumoOfflineSpeechEngine.java',
                   root / 'scripts/voice/LumoOfflineSpeechEngineProbe.java',
                   cls.fixtures / 'OfflineVoiceTokenizerContract.java',
                   *sorted((cls.fixtures / 'onnx').rglob('*.java'))]
        cls.run_checked([javac, '-encoding', 'UTF-8', '-d', str(cls.classes),
                         *map(str, sources)])

    @staticmethod
    def tool(name):
        configured = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin' / name
        selected = str(configured) if configured.is_file() else shutil.which(name)
        if not selected:
            raise RuntimeError('Use the existing JDK; no compiler download')
        return selected

    @staticmethod
    def run_checked(command):
        result = subprocess.run(command, capture_output=True, text=True, timeout=60)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return result

    def test_original_banana_sentence_with_exact_pinned_tokenizer(self):
        with tempfile.TemporaryDirectory(prefix='lumo-tokenizer-model-boundary-') as models:
            result = self.run_checked([
                self.java, '-cp', str(self.classes), 'OfflineVoiceTokenizerContract',
                str(self.fixtures / 'unicode_indexer.bin'), self.expected_indexer, models,
            ])
        self.assertIn('LUMO_OFFLINE_TOKENIZER_PASS checks=11 ', result.stdout)
        print(result.stdout, end='')

    def test_existing_java_voice_guards(self):
        result = self.run_checked([
            self.java, '-cp', str(self.classes), 'LumoOfflineSpeechEngineProbe', '--unit-only',
        ])
        self.assertIn('PASS local voice Java guards: 11', result.stdout)
        print(result.stdout, end='')


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
