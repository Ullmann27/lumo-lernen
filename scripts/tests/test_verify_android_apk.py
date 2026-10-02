import hashlib
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
import subprocess


spec = importlib.util.spec_from_file_location('verify_android_apk', Path(__file__).resolve().parents[1] / 'verify_android_apk.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ApkSignatureTest(unittest.TestCase):
    certificate = b'public certificate fixture'
    digest = hashlib.sha256(certificate).hexdigest()

    def test_matches_certificate_bytes_and_ignores_other_fingerprints(self):
        output = (
            'Verifies\n'
            'Signer #1 certificate DN: CN=Android Debug\n'
            f'Signer #1 certificate SHA-256 digest: {self.digest.upper()}\n'
            'Signer #1 certificate SHA-1 digest: abcdef\n'
            f'Signer #1 public key SHA-256 digest: {"0" * 64}\n'
        )
        self.assertEqual(module.verify_certificate_digest(output, self.certificate), self.digest)

    def test_v31_sdk_ranges_repeating_one_certificate_and_dev_release(self):
        # Matches the labels in AOSP ApkSignerTool.verify / printCertificate.
        # https://android.googlesource.com/platform/tools/apksig/+/refs/heads/main/src/apksigner/java/com/android/apksigner/ApkSignerTool.java
        for dev_release in ('', ' (dev release=true)'):
            with self.subTest(dev_release=dev_release):
                output = (
                    'Verified using v3.1 scheme (APK Signature Scheme v3.1): true\r\n'
                    'Number of signers: 1\r\n'
                    f'Signer (minSdkVersion=33{dev_release}, maxSdkVersion=2147483647) certificate DN: CN=Android Debug\r\n'
                    f'Signer (minSdkVersion=33{dev_release}, maxSdkVersion=2147483647) certificate SHA-256 digest: {self.digest.upper()}\r\n'
                    f'Signer (minSdkVersion=24, maxSdkVersion=32) certificate SHA-256 digest: {self.digest}\r\n'
                    f'Signer (minSdkVersion=24, maxSdkVersion=32) public key SHA-256 digest: {"0" * 64}\r\n'
                    f'Source Stamp Signer certificate SHA-256 digest: {"1" * 64}\r\n'
                )
                self.assertEqual(module.verify_certificate_digest(output, self.certificate), self.digest)

    def test_rejects_untrusted_or_unreadable_additional_sdk_signer(self):
        valid = f'Signer (minSdkVersion=24, maxSdkVersion=32) certificate SHA-256 digest: {self.digest}\n'
        for label, digest in (
            ('Signer (minSdkVersion=33, maxSdkVersion=2147483647)', '0' * 64),
            ('Signer (minSdkVersion=33, maxSdkVersion=2147483647)', 'malformed'),
            ('Signer (unknown-format=true)', self.digest),
        ):
            with self.subTest(label=label, digest=digest):
                with self.assertRaises(module.VerificationError):
                    module.verify_certificate_digest(valid + f'{label} certificate SHA-256 digest: {digest}\n', self.certificate)

    def test_failure_diagnostic_is_limited_to_public_digest_labels(self):
        output = (
            'Signer #1 certificate DN: CN=DO-NOT-PRINT\n'
            'unrelated private host details\n'
            f'Signer #1 certificate SHA-256 digest: {"0" * 64}\n'
        )
        with self.assertRaises(module.VerificationError) as caught:
            module.verify_certificate_digest(output, self.certificate)
        message = str(caught.exception)
        self.assertIn('Signer #1: ' + '0' * 64, message)
        self.assertNotIn('DO-NOT-PRINT', message)
        self.assertNotIn('private host details', message)

    def test_rejects_missing_malformed_multiple_and_wrong_certificates(self):
        valid = f'Signer #1 certificate SHA-256 digest: {self.digest}\n'
        cases = (
            ('', self.certificate),
            ('Signer #1 certificate SHA-256 digest: abcdef\n', self.certificate),
            (valid + valid.replace('#1', '#2'), self.certificate),
            (valid, b'another certificate'),
            (valid, b''),
        )
        for output, certificate in cases:
            with self.subTest(output=output, certificate=certificate):
                with self.assertRaises(module.VerificationError):
                    module.verify_certificate_digest(output, certificate)

    def test_tool_failure_cannot_pass_even_if_output_contains_a_digest(self):
        output = f'Signer #1 certificate SHA-256 digest: {self.digest}\n'.encode()
        failed = subprocess.CompletedProcess(['apksigner'], 1, stdout=output, stderr=b'failure')
        with patch.object(module.subprocess, 'run', return_value=failed):
            with self.assertRaises(module.VerificationError):
                module.run_tool(['apksigner', 'verify', '--print-certs', 'example.apk'])
