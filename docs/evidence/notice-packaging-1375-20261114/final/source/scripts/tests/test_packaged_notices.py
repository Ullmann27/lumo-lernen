"""Real file/ZIP counterexamples using explicit synthetic notice inputs."""
import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
import warnings
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from package_notices import (ASSET_PREFIX, MANIFEST_PATH, POLICY_PATH,
                             bundle_notices, policy_entries, validate_packaged_notices)
from verify_play_bundle import BaseModuleArchive
from notice_fixtures import fixture


class PackagedNoticeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'host'
        self.native = Path(self.temp.name) / 'native'
        self.source = {'repository': 'https://example.invalid/native.git',
                       'revision': '1' * 40, 'engine': '4.6.3'}
        self.policy, self.members, self.originals = fixture(self.source)
        (self.root / 'config').mkdir(parents=True)
        (self.root / POLICY_PATH).write_bytes(self.policy)
        (self.root / 'config/godot-source.json').write_text(json.dumps(self.source))
        for (source, path), data in self.originals.items():
            target = (self.root if source == 'host' else self.native) / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)

    def verify_members(self, members, *, aab=False, duplicate=None,
                       policy=None, source=None):
        buffer = io.BytesIO()
        prefix = 'base/' if aab else ''
        with zipfile.ZipFile(buffer, 'w') as archive:
            for name, data in members.items():
                archive.writestr(prefix + name, data)
            if duplicate:
                with warnings.catch_warnings():
                    warnings.simplefilter('ignore', UserWarning)
                    archive.writestr(prefix + duplicate, members[duplicate])
        with zipfile.ZipFile(buffer) as archive:
            view = BaseModuleArchive(archive) if aab else archive
            return validate_packaged_notices(
                view, self.policy if policy is None else policy,
                self.source if source is None else source)

    def test_preparation_copies_all_bytes_and_is_idempotent(self):
        first = bundle_notices(self.root, self.native)
        second = bundle_notices(self.root, self.native)
        self.assertEqual(first, second)
        base = self.root / 'android/app/src/main'
        actual = {path.relative_to(base).as_posix(): path.read_bytes()
                  for path in (base / 'assets/lumo_notices').rglob('*') if path.is_file()}
        self.assertEqual(actual, self.members)
        for aab in (False, True):
            with self.subTest(aab=aab):
                self.assertEqual(self.verify_members(actual, aab=aab)['status'], 'verified')
        for (source, path), original in self.originals.items():
            self.assertEqual(((self.root if source == 'host' else self.native) / path).read_bytes(), original)

    def test_each_missing_changed_or_duplicate_zip_member_is_rejected(self):
        for aab in (False, True):
            for name in self.members:
                for mutation in ('missing', 'changed', 'duplicate'):
                    with self.subTest(aab=aab, member=name, mutation=mutation):
                        members = dict(self.members)
                        if mutation == 'missing':
                            del members[name]
                        elif mutation == 'changed':
                            members[name] += b'changed'
                        with self.assertRaises((RuntimeError, ValueError)):
                            self.verify_members(members, aab=aab,
                                                duplicate=name if mutation == 'duplicate' else None)

    def test_unexpected_stale_notice_asset_is_rejected_in_both_archives(self):
        for aab in (False, True):
            with self.subTest(aab=aab), self.assertRaisesRegex(RuntimeError, 'inventory'):
                self.verify_members({**self.members, ASSET_PREFIX + 'stale.txt': b'stale'}, aab=aab)

    def test_stale_policy_and_changed_native_identity_cannot_reuse_receipt(self):
        for aab in (False, True):
            with self.subTest(aab=aab, mutation='policy'), self.assertRaisesRegex(RuntimeError, 'manifest'):
                self.verify_members(self.members, aab=aab, policy=self.policy + b' ')
            for field, value in [('revision', '2' * 40), ('repository', 'https://example.invalid/other.git')]:
                with self.subTest(aab=aab, field=field), self.assertRaisesRegex(RuntimeError, 'manifest'):
                    self.verify_members(self.members, aab=aab, source={**self.source, field: value})

    def test_policy_cannot_omit_duplicate_or_relocate_an_original(self):
        policy = json.loads(self.policy)
        for mutation in ('missing', 'duplicate', 'traversal', 'hash', 'boolean_schema'):
            candidate = copy.deepcopy(policy)
            if mutation == 'missing':
                candidate['notices'].pop()
            elif mutation == 'duplicate':
                candidate['notices'][-1] = candidate['notices'][0]
            elif mutation == 'traversal':
                candidate['notices'][0]['path'] = '../outside.txt'
            elif mutation == 'hash':
                candidate['notices'][0]['sha256'] = 'not-a-sha256'
            else:
                candidate['schema'] = True
            with self.subTest(mutation=mutation), self.assertRaises(RuntimeError):
                policy_entries(json.dumps(candidate).encode())

    def test_changed_source_and_symlink_fail_before_writing_package(self):
        original = self.root / 'assets/fonts/OFL.txt'
        data = original.read_bytes()
        original.write_bytes(data + b'changed')
        with self.assertRaisesRegex(RuntimeError, 'Original notice bytes'):
            bundle_notices(self.root, self.native)
        self.assertFalse((self.root / 'android').exists())
        original.unlink()
        outside = self.root / 'original.txt'
        outside.write_bytes(data)
        original.symlink_to(outside)
        with self.assertRaisesRegex(RuntimeError, 'unsafe'):
            bundle_notices(self.root, self.native)
        self.assertFalse((self.root / 'android').exists())

    def test_unexpected_existing_output_is_preserved_and_rejected(self):
        target = self.root / 'android/app/src/main/assets/lumo_notices'
        target.mkdir(parents=True)
        other = target / 'unrelated-work.txt'
        other.write_bytes(b'preserve this work')
        with self.assertRaisesRegex(RuntimeError, 'Unexpected existing'):
            bundle_notices(self.root, self.native)
        self.assertEqual(other.read_bytes(), b'preserve this work')


if __name__ == '__main__':
    unittest.main()
