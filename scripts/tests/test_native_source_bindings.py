"""Ensure native source bindings are executable constants, not commented text.

Prevents regression to literal \\n in a source comment silently swallowing
SOURCE_SHA256. The actual runtime CI still compares the full set of expected
digests against every file of the exact pinned Godot commit; this test is
only an early, targeted Python import/contract guard.
"""
import importlib.util
import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / "tools" / "android_qa"
if str(QA) not in sys.path:
    sys.path.insert(0, str(QA))
HEX256 = re.compile(r"^[0-9a-f]{64}$")
EXPECTED = {
    "native_lap_evidence_recovery": (
        "SOURCE_SHA256", "LAP_PROBE_SHA256", "FIXTURE_PROBE_SHA256",
        "FLOW_PROBE_SHA256", "TIME_PROBE_SHA256",
    ),
    "native_handoff_evidence_recovery": (
        "SOURCE_SHA256", "PROBE_SHA256", "HELPER_SHA256",
    ),
}


class NativeSourceBindingsTests(unittest.TestCase):
    def test_reviewed_native_sha_constants_are_real_importable_attributes(self):
        for name, attrs in EXPECTED.items():
            with self.subTest(module=name):
                source_path = QA / (name + ".py")
                source = source_path.read_text(encoding="utf-8")
                self.assertNotIn(r"\\nSOURCE_SHA256", source)
                spec = importlib.util.spec_from_file_location(name, source_path)
                self.assertIsNotNone(spec)
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                for attribute in attrs:
                    with self.subTest(attribute=attribute):
                        self.assertTrue(hasattr(module, attribute), attribute)
                        self.assertRegex(getattr(module, attribute), HEX256)

    def test_both_source_bindings_agree_with_reviewed_godot_pin(self):
        from native_lap_evidence_recovery import SOURCE_SHA256 as lap
        from native_handoff_evidence_recovery import SOURCE_SHA256 as handoff
        config = json.loads((ROOT / "config" / "godot-source.json").read_text(encoding="utf-8"))
        self.assertEqual(config["engine"], "4.6.3")
        self.assertEqual(
            config["revision"],
            "3453a43a8bbdcb0495718e1eced2a40837d6e3ab",
            "Godot pin changed: review real source and renew hashes, never silently accept it",
        )
        self.assertEqual(lap, handoff)
        self.assertEqual(lap, "0fbc839429f52ca4ed07641220b396e1be4ddb5fac250e2faaa2557f9b9d9064")


if __name__ == "__main__":
    unittest.main()
