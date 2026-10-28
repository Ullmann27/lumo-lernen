import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('release_pin_2001', ROOT / 'scripts/verify_legacy_release_pin.py')
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)

class TutorReleasePolicyTest(unittest.TestCase):
    def test_new_flutter_candidate_retains_native_pin_and_old_release_identity(self):
        config = json.dumps({'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                             'revision': 'adcce3093caa42bf3da47262f70bdf03cdefa347', 'engine': '4.6.3'})
        for version in (2000, 2001):
            self.assertEqual(policy.verify(f'version: 0.12.89+{version}\n', config)[0], version)
        with self.assertRaisesRegex(ValueError, 'no reviewed native pin'):
            policy.verify('version: 0.12.90+2002\n', config)
        broken = json.loads(config)
        broken['revision'] = policy.APPROVED[1999]
        with self.assertRaisesRegex(ValueError, 'revision mismatch'):
            policy.verify('version: 0.12.89+2001\n', json.dumps(broken))

if __name__ == '__main__':
    unittest.main()
