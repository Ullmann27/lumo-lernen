"""Keep exact ABI checks strict for universal and single-architecture deliveries."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_unified_apk import validate_abis


class UnifiedApkAbiTest(unittest.TestCase):
    def test_universal_still_requires_both_architectures(self):
        validate_abis({'arm64-v8a', 'x86_64'})
        with self.assertRaises(RuntimeError):
            validate_abis({'arm64-v8a'})

    def test_explicit_single_variant_is_exact(self):
        for abi in ('arm64-v8a', 'x86_64'):
            validate_abis({abi}, {abi})
            with self.assertRaises(RuntimeError):
                validate_abis({'arm64-v8a', 'x86_64'}, {abi})

    def test_empty_or_unknown_expectations_are_rejected(self):
        for expected in (set(), {'armeabi-v7a'}, {'arm64-v8a', 'mips'}):
            with self.assertRaises(RuntimeError):
                validate_abis(expected, expected)

    def test_unexpected_library_architecture_is_rejected(self):
        with self.assertRaises(RuntimeError):
            validate_abis({'arm64-v8a', 'x86_64', 'armeabi-v7a'})


if __name__ == '__main__':
    unittest.main()
