"""Prepare the real host and check Dart-to-Kotlin admission, not Android execution."""
import importlib.util
from pathlib import Path
import re
import shutil
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "studio_prepare_android", ROOT / "scripts/prepare_android.py"
)
PREPARE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PREPARE)


class StudioLearningHostTest(unittest.TestCase):
    def test_generated_host_admits_every_checked_dart_learning_descriptor(self):
        dart = (ROOT / "lib/domain/tutoring/native_learning_activity.dart").read_text()
        descriptor_kinds = set(re.findall(r"NativeLearningActivity\._\(\s*'([^']+)'", dart))
        self.assertIn("equal_sharing", descriptor_kinds)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            main = root / "android/app/src/main"
            main.mkdir(parents=True)
            (main / "AndroidManifest.xml").write_text(
                '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
                '<application><activity android:name=".MainActivity"/></application></manifest>'
            )
            namespace = "example.studio.learning"
            (root / "android/app/build.gradle.kts").write_text(
                f'android {{ namespace = "{namespace}"\n'
                f' defaultConfig {{ applicationId = "{namespace}" }} }}'
            )
            templates = root / "tools/auto_install"
            templates.mkdir(parents=True)
            for name in ("MainActivity.kt", "lumo_file_paths.xml"):
                shutil.copyfile(ROOT / "tools/auto_install" / name, templates / name)
            (root / "tools/lumo-debug.keystore").write_bytes(b"synthetic-test-keystore")
            PREPARE.prepare(root, root / "keystore")
            prepared = (main / "kotlin" / Path(*namespace.split(".")) / "MainActivity.kt").read_text()
            admission = re.search(r'learning\["kind"\] !in setOf\(([^)]+)\)', prepared)
            self.assertIsNotNone(admission)
            accepted_kinds = set(re.findall(r'"([^"]+)"', admission[1]))
            self.assertTrue(descriptor_kinds.issubset(accepted_kinds),
                            f"Android rejects actual Flutter descriptors: {descriptor_kinds - accepted_kinds}")
            self.assertIn('result.error("invalid_learning"', prepared)
            self.assertIn('options.put("learning", JSONObject(learning))', prepared)


if __name__ == "__main__":
    unittest.main()
