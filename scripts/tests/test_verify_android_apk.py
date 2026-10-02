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
