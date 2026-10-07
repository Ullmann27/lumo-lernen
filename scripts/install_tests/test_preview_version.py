import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('preview_version', ROOT/'scripts/preview_version.py')
v = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v)


class PreviewVersionTests(unittest.TestCase):
    def setUp(self):
        self.policy = json.loads((ROOT/'config/android-preview-version.json').read_text())
        self.old = {'package': self.policy['package'], 'versionCode': 1321,
                    'signingCertificateSha256': self.policy['signingCertificateSha256']}
        self.new = dict(self.old, versionCode=1335, versionName='0.10.7')

    def test_shared_defaults_advance_previous_delivery(self):
        self.assertEqual(v.resolve(self.policy, {}), (1335, '0.10.7'))

    def test_regression_280_is_rejected_even_if_workflow_sets_it(self):
        with self.assertRaisesRegex(ValueError, 'below reserved minimum'):
            v.resolve(self.policy, {'LUMO_BUILD_NUMBER': '280'})

    def test_known_older_numbers_are_rejected(self):
        for code in (1279, 1321, 1334):
            with self.subTest(code=code), self.assertRaises(ValueError):
                v.resolve(self.policy, {'LUMO_BUILD_NUMBER': str(code)})

    def test_later_version_is_allowed(self):
        self.assertEqual(v.resolve(self.policy, {'LUMO_BUILD_NUMBER': '1336',
                                               'LUMO_VERSION_NAME': '0.10.8'}), (1336, '0.10.8'))

    def test_invalid_numbers_rejected(self):
        for code in (None, True, False, '', '-1', '0', '1.5', '1e4', ' 1335',
                     '1335\n', str(v.MAX_CODE + 1)):
            with self.subTest(code=code), self.assertRaises(ValueError):
                v.resolve(self.policy, {'LUMO_BUILD_NUMBER': code})

    def test_shell_sensitive_names_rejected(self):
        for name in ('', 'new', '0.10.7\n', '0.10.7;echo x', '$(echo x)'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                v.resolve(self.policy, {'LUMO_VERSION_NAME': name})

    def test_policy_cannot_move_backwards(self):
        for key, value in [('minimumVersionCode', 1321), ('versionCode', 280)]:
            policy = copy.deepcopy(self.policy)
            policy[key] = value
            with self.assertRaises(ValueError):
                v.resolve(policy, {})

    def test_valid_compiled_candidate(self):
        v.verify_candidate(self.policy, self.new, {})
        self.assertEqual(v.compare_updates(self.old, self.new)['toVersionCode'], 1335)

    def test_different_signing_or_package_rejected(self):
        for key, value in [('package', 'another.app'), ('signingCertificateSha256', 'different')]:
            new = dict(self.new, **{key: value})
            with self.assertRaises(ValueError):
                v.compare_updates(self.old, new)
            with self.assertRaises(ValueError):
                v.verify_candidate(self.policy, new, {})

    def test_compiled_version_mismatch_rejected(self):
        for key, value in [('versionCode', 280), ('versionName', '0.10.5')]:
            with self.assertRaises(ValueError):
                v.verify_candidate(self.policy, dict(self.new, **{key: value}), {})

    def test_equal_and_downgrade_not_called_updates(self):
        for code in (280, 1321):
            with self.assertRaises(ValueError):
                v.compare_updates(self.old, dict(self.new, versionCode=code))

    def test_legacy_missing_identity_is_rejected(self):
        with self.assertRaises(ValueError):
            v.compare_updates({'versionCode': 1321}, self.new)


if __name__ == '__main__':
    unittest.main()
