import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('verify_android_apk', Path(__file__).resolve().parents[1] / 'verify_android_apk.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class ApkSignatureTest(unittest.TestCase):
    def test_tool_failure_cannot_pass_even_with_success_text(self):
        failed = subprocess.CompletedProcess(['java'], 1,
            stdout=b'Verified stable APK signing certificate', stderr=b'failure')
        with patch.object(module.subprocess, 'run', return_value=failed):
            with self.assertRaises(module.VerificationError):
                module.run_tool(['java', 'verifier'])

    def test_java_home_selects_the_configured_jdk_instead_of_a_jre_on_path(self):
        with tempfile.TemporaryDirectory() as folder:
            binary = Path(folder) / 'bin' / 'java'
            binary.parent.mkdir(); binary.touch()
            with patch.dict(module.os.environ, {'JAVA_HOME': folder}):
                self.assertEqual(module.find_java_tool('java'), str(binary))
