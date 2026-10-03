import hashlib
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cache_built_apk
import download_apk
import upload_tested_apk

REPO = 'Ullmann27/lumo-lernen'
TAG = 'unified-build-275'


class CandidateCacheTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.evidence = self.root/'evidence'; self.evidence.mkdir()
        self.apk = self.evidence/'tested.apk'
        with zipfile.ZipFile(self.apk, 'w') as archive:
            for name in ['AndroidManifest.xml', 'resources.arsc', 'assets/lumo_game.pck',
                         'lib/x86_64/libgodot_android.so', 'lib/x86_64/libflutter.so']:
                archive.writestr(name, b'fixture')
        self.binary = self.apk.read_bytes()
        self.sha = hashlib.sha256(self.binary).hexdigest()
        self.build = {'repository': REPO, 'draft_release': TAG, 'tracked_source_clean': True,
                      'release_published': False, 'mode': 'runner-build', 'flutter_source_commit': 'a'*40,
                      'apk': {'sha256': self.sha, 'bytes': len(self.binary), 'signingCertificateSha256': 'b'*64}}
        (self.evidence/'runner-build-proof.json').write_text(json.dumps(self.build))
        self.release = {'id': 42, 'tag_name': TAG, 'draft': True, 'assets': []}
        self.bytes = {}; self.calls = []

    def upload(self, command, **kwargs):
        self.calls.append(command)
        self.assertEqual(command[:4], ['gh', 'release', 'upload', TAG])
        self.assertNotIn('--clobber', command)
        for filename in command[4:command.index('--repo')]:
            path = Path(filename); identifier = len(self.bytes)+1
            self.bytes[identifier] = path.read_bytes()
            self.release['assets'].append({'id': identifier, 'name': path.name})

    def read(self, repository, asset, path):
        self.assertEqual(repository, REPO)
        path.write_bytes(self.bytes[asset['id']])

    def transport(self):
        return (
            patch('cache_built_apk.resolve_draft', return_value=self.release),
            patch('download_apk.resolve_draft', return_value=self.release),
            patch('upload_tested_apk.resolve_draft', return_value=self.release),
            patch('download_apk.read_asset', side_effect=self.read),
            patch('subprocess.run', side_effect=self.upload),
        )

    def cache(self):
        cache_built_apk.cache(SimpleNamespace(repository=REPO, release_tag=TAG, evidence=self.evidence))

    def test_cache_download_then_passed_promotion_preserves_bytes_and_original_source(self):
        a,b,c,d,e = self.transport()
        with a,b,c,d,e, patch.dict('os.environ', {'GITHUB_SHA': 'c'*40}, clear=True):
            self.cache()
            self.assertEqual([a['name'] for a in self.release['assets']],
                             [download_apk.CANDIDATE_NAME, download_apk.PROVENANCE_NAME])
            resumed = self.root/'new-harness'
            download_apk.download(REPO, TAG, self.sha, resumed)
            self.assertEqual((resumed/'tested.apk').read_bytes(), self.binary)
            build = json.loads((resumed/'runner-build-proof.json').read_text())
            self.assertEqual(build['flutter_source_commit'], 'a'*40)
            proof = json.loads((resumed/'download-proof.json').read_text())
            self.assertEqual(proof['qa_harness_commit'], 'c'*40)
            (resumed/'result.json').write_text(json.dumps({'passed': True, 'sha256': self.sha}))
            upload_tested_apk.upload(SimpleNamespace(repository=REPO, release_tag=TAG, evidence=resumed))
            final = self.release['assets'][-1]
            self.assertEqual(final['name'], 'Lumo-Lernen-Neu.apk')
            self.assertEqual(self.bytes[final['id']], self.binary)
            # A successful rerun checks the existing APK, never replaces it.
            count = len(self.calls)
            upload_tested_apk.upload(SimpleNamespace(repository=REPO, release_tag=TAG, evidence=resumed))
            self.assertEqual(len(self.calls), count)

    def test_build_preflight_rejects_apk_or_either_cached_asset(self):
        for name in ['Existing.apk', download_apk.CANDIDATE_NAME, download_apk.PROVENANCE_NAME]:
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, 'refuses to replace'):
                download_apk.require_empty_build_draft({'assets': [{'name': name}]})

    def test_failed_ui_or_changed_bytes_never_upload_final_apk(self):
        args = SimpleNamespace(repository=REPO, release_tag=TAG, evidence=self.evidence)
        with patch('upload_tested_apk.subprocess.run') as remote:
            (self.evidence/'result.json').write_text(json.dumps({'passed': False, 'sha256': self.sha}))
            with self.assertRaisesRegex(ValueError, 'No passing'):
                upload_tested_apk.upload(args)
            (self.evidence/'result.json').write_text(json.dumps({'passed': True, 'sha256': self.sha}))
            self.apk.write_bytes(b'changed')
            with self.assertRaisesRegex(ValueError, 'hashes must be identical'):
                upload_tested_apk.upload(args)
            remote.assert_not_called()

    def test_candidate_requires_explicit_matching_sha_and_unique_provenance(self):
        a,b,c,d,e = self.transport()
        with a,b,c,d,e:
            self.cache()
            with self.assertRaisesRegex(ValueError, 'provenance does not match'):
                download_apk.download(REPO, TAG, '0'*64, self.root/'wrong-sha')
            with self.assertRaisesRegex(ValueError, 'refuses to replace'):
                self.cache()
            self.release['assets'].append({'id': 99, 'name': 'another.bin'})
            with self.assertRaisesRegex(ValueError, 'unique cached candidate'):
                download_apk.download(REPO, TAG, self.sha, self.root/'ambiguous')

    def test_corrupt_cached_bytes_or_provenance_fail_closed(self):
        a,b,c,d,e = self.transport()
        with a,b,c,d,e:
            self.cache()
            candidate, origin = self.release['assets']
            self.bytes[candidate['id']] = b'corrupt'
            with self.assertRaisesRegex(ValueError, 'SHA-256 mismatch'):
                download_apk.download(REPO, TAG, self.sha, self.root/'corrupt')
            self.bytes[candidate['id']] = self.binary
            metadata = json.loads(self.bytes[origin['id']]); metadata['cached_release_id'] = 99
            self.bytes[origin['id']] = json.dumps(metadata).encode()
            with self.assertRaisesRegex(ValueError, 'provenance does not match'):
                download_apk.download(REPO, TAG, self.sha, self.root/'wrong-draft')


if __name__ == '__main__':
    unittest.main()
