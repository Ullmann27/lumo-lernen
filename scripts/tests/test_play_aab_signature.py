"""Regression for strict self-signed Google Play upload certificate verification."""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]


class PlayUploadSignatureTests(unittest.TestCase):
    def test_verifier_uses_private_keystore_without_password_in_process_args(self):
        script = (ROOT / "scripts/build_play_aab.sh").read_text(encoding="utf-8")
        self.assertIn('jarsigner -verify -strict -verbose', script)
        self.assertIn('-keystore "$LUMO_PLAY_UPLOAD_KEYSTORE"', script)
        self.assertIn('-storepass:env LUMO_PLAY_UPLOAD_STORE_PASSWORD', script)
        self.assertNotIn('-storepass "$LUMO_PLAY_UPLOAD_STORE_PASSWORD"', script)

    @unittest.skipUnless(shutil.which("jarsigner") and shutil.which("keytool"),
                         "Java signing toolchain unavailable")
    def test_self_signed_upload_is_accepted_but_unsigned_content_is_rejected(self):
        with tempfile.TemporaryDirectory() as location:
            root = Path(location)
            store = root / "upload.p12"
            bundle = root / "sample.aab"
            env = dict(
                os.environ,
                LUMO_PLAY_UPLOAD_STORE_PASSWORD="lumo-ci-test-123456",
                LUMO_PLAY_UPLOAD_KEY_PASSWORD="lumo-ci-test-123456",
            )
            keytool = [
                "keytool", "-genkeypair", "-alias", "upload", "-keyalg", "RSA",
                "-keysize", "2048", "-validity", "3",
                "-dname", "CN=Lumo Test Upload, C=AT",
                "-keystore", str(store), "-storetype", "PKCS12",
                "-storepass:env", "LUMO_PLAY_UPLOAD_STORE_PASSWORD",
                "-keypass:env", "LUMO_PLAY_UPLOAD_KEY_PASSWORD", "-noprompt",
            ]
            self.assertEqual(subprocess.run(keytool, env=env, capture_output=True).returncode, 0)
            with zipfile.ZipFile(bundle, "w") as data:
                data.writestr("base/manifest/AndroidManifest.xml", b"test-only")
            sign = [
                "jarsigner", "-keystore", str(store),
                "-storepass:env", "LUMO_PLAY_UPLOAD_STORE_PASSWORD",
                "-keypass:env", "LUMO_PLAY_UPLOAD_KEY_PASSWORD",
                str(bundle), "upload",
            ]
            self.assertEqual(subprocess.run(sign, env=env, capture_output=True).returncode, 0)
            verify = [
                "jarsigner", "-verify", "-strict", "-verbose",
                "-keystore", str(store),
                "-storepass:env", "LUMO_PLAY_UPLOAD_STORE_PASSWORD", str(bundle),
            ]
            self.assertEqual(subprocess.run(verify, env=env, capture_output=True).returncode, 0)
            with zipfile.ZipFile(bundle, "a") as data:
                data.writestr("base/dex/unsigned.dex", b"tampered")
            self.assertNotEqual(subprocess.run(verify, env=env, capture_output=True).returncode, 0)


if __name__ == "__main__":
    unittest.main()
