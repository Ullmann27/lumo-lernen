"""Reject mismatched or unknown Godot source for version-bound APK releases."""
import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "verify_legacy_release_pin", ROOT / "scripts" / "verify_legacy_release_pin.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
ORIGIN = "https://github.com/Ullmann27/lumo-godot.git"


def config(sha: str, *, engine: str = "4.6.3", origin: str = ORIGIN) -> str:
    return json.dumps({"repository": origin, "revision": sha, "engine": engine})


def pubspec(build: int) -> str:
    return f"name: lumo_lernen\nversion: 0.12.56+{build}\n"


class VersionBoundGodotSourceTests(unittest.TestCase):
    def test_preserved_release_1950_to_1952_requires_original_source(self):
        for number in (1950, 1951, 1952):
            with self.subTest(number=number):
                self.assertEqual(
                    module.verify(pubspec(number), config(module.APPROVED[number])),
                    (number, module.APPROVED[number]),
                )
                with self.assertRaisesRegex(ValueError, "revision mismatch"):
                    module.verify(pubspec(number), config(module.APPROVED[1968]))

    def test_stabilized_1968_rejects_original_1950_source(self):
        number, expected = module.verify(
            pubspec(1968), config(module.APPROVED[1968]),
        )
        self.assertEqual(number, 1968)
        self.assertEqual(expected, module.APPROVED[1968])
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1968), config(module.APPROVED[1950]))

    def test_new_1969_uses_animating_godot_without_rewriting_1968_history(self):
        old = module.APPROVED[1968]
        new = module.APPROVED[1969]
        self.assertEqual(old, "61f51b942b2521b506e6b203b89a1b3ec2bd284f")
        self.assertEqual(new, "6b3945583a361c4ea974e4b6846ae0d616b1727a")
        self.assertNotEqual(old, new)
        self.assertEqual(module.verify(pubspec(1968), config(old)), (1968, old))
        self.assertEqual(module.verify(pubspec(1969), config(new)), (1969, new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1969), config(old))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1968), config(new))

    def test_new_1970_grounding_uses_separate_immutable_reviewer_pin(self):
        previous = module.APPROVED[1969]
        grounding = module.APPROVED[1970]
        self.assertEqual(previous, "6b3945583a361c4ea974e4b6846ae0d616b1727a")
        self.assertEqual(grounding, "3453a43a8bbdcb0495718e1eced2a40837d6e3ab")
        self.assertNotEqual(previous, grounding)
        self.assertEqual(module.verify(pubspec(1969), config(previous)), (1969, previous))
        self.assertEqual(module.verify(pubspec(1970), config(grounding)), (1970, grounding))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1970), config(previous))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1969), config(grounding))

    def test_1971_profile_safety_release_retains_verified_godot_pin(self):
        old = module.APPROVED[1970]
        new = module.APPROVED[1971]
        self.assertEqual(old, "3453a43a8bbdcb0495718e1eced2a40837d6e3ab")
        self.assertEqual(new, old)
        self.assertEqual(module.verify(pubspec(1971), config(new)), (1971, new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1971), config(module.APPROVED[1969]))

    def test_1972_multilevel_road_keeps_1971_profile_candidate_frozen(self):
        prior = module.APPROVED[1971]
        new = module.APPROVED[1972]
        self.assertEqual(prior, "3453a43a8bbdcb0495718e1eced2a40837d6e3ab")
        self.assertEqual(new, "b8f464d946f73d9b88458bf223f1b83db3975a1a")
        self.assertNotEqual(new, prior)
        self.assertEqual(module.verify(pubspec(1971), config(prior)), (1971, prior))
        self.assertEqual(module.verify(pubspec(1972), config(new)), (1972, new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1972), config(prior))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1971), config(new))

    def test_unknown_release_source_and_engine_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1973), config(module.APPROVED[1968]))
        with self.assertRaisesRegex(ValueError, "origin"):
            module.verify(pubspec(1968), config(module.APPROVED[1968], origin="https://example.org"))
        with self.assertRaisesRegex(ValueError, "engine"):
            module.verify(pubspec(1968), config(module.APPROVED[1968], engine="4.7"))
        with self.assertRaisesRegex(ValueError, "source config keys"):
            module.verify(pubspec(1968), json.dumps({"revision": module.APPROVED[1968]}))

    def test_malformed_version_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Exactly one"):
            module.verify("name: lumo_lernen\n", config(module.APPROVED[1968]))


if __name__ == "__main__":
    unittest.main()
