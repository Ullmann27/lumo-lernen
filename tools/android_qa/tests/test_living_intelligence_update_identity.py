"""Synthetic artifact metadata; live install/touch proof remains a CI gate."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools' / 'android_qa'))
from update_artifact_identity import require_update_artifact

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
GODOT = 'adcce3093caa42bf3da47262f70bdf03cdefa347'


class LivingIntelligenceUpdateIdentityTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.apk = Path(self.tmp.name) / 'synthetic-metadata-fixture.apk'
        self.apk.write_bytes(b'METADATA VALIDATOR FIXTURE, NOT AN APK')
        self.source = 'a' * 40
        self.good = {
            'flutter_source_commit': self.source, 'tracked_source_clean': True,
            'versionCode': 2002, 'package': PACKAGE,
            'signingCertificateSha256': CERT,
            'sha256': hashlib.sha256(self.apk.read_bytes()).hexdigest(), 'abis': ['x86_64'],
            'godot': {'revision': GODOT}}

    def validate(self, data):
        (self.apk.parent / 'BUILD-PROVENANCE.json').write_text(json.dumps(data))
        return require_update_artifact(self.apk, source=self.source, version=2002,
            package=PACKAGE, certificate=CERT, native_source=GODOT)

    def test_same_commit_version_signature_and_native_identity_are_required(self):
        self.assertEqual(self.validate(self.good), self.good)
        mutations = [
            {'flutter_source_commit': 'b' * 40}, {'tracked_source_clean': False},
            {'tracked_source_clean': 1},
            {'versionCode': 2001}, {'package': 'different.app'},
            {'signingCertificateSha256': 'untrusted'}, {'sha256': 'changed'},
            {'abis': ['arm64-v8a']}, {'godot': {'revision': 'b' * 40}},
        ]
        for change in mutations:
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                self.validate(dict(copy.deepcopy(self.good), **change))


if __name__ == '__main__':
    unittest.main()
