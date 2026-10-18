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

    def test_1973_sonnenhafen_b3_keeps_1972_road_candidate_frozen(self):
        old = module.APPROVED[1972]
        upgraded = module.APPROVED[1973]
        self.assertEqual(old, "b8f464d946f73d9b88458bf223f1b83db3975a1a")
        self.assertEqual(upgraded, "7bdb7ca91691396399abf3b16f09a54259538df7")
        self.assertNotEqual(old, upgraded)
        self.assertEqual(module.verify(pubspec(1972), config(old)), (1972, old))
        self.assertEqual(module.verify(pubspec(1973), config(upgraded)), (1973, upgraded))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1972), config(upgraded))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1973), config(old))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1974), config(upgraded))

    def test_1974_sonnenhafen_clearance_never_mutates_1973_baseline(self):
        prior = module.APPROVED[1973]
        current = module.APPROVED[1974]
        self.assertEqual(prior, "7bdb7ca91691396399abf3b16f09a54259538df7")
        self.assertEqual(current, "42b011dc23abffc24a5df2e13171fa5ada22d6eb")
        self.assertNotEqual(prior, current)
        self.assertEqual(module.verify(pubspec(1973), config(prior)), (1973, prior))
        self.assertEqual(module.verify(pubspec(1974), config(current)), (1974, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1973), config(current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1974), config(prior))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1975), config(current))

    def test_1975_grounded_gate_pins_verified_godot_without_rewriting_1974(self):
        prior = module.APPROVED[1974]
        current = module.APPROVED[1975]
        self.assertEqual(prior, "42b011dc23abffc24a5df2e13171fa5ada22d6eb")
        self.assertEqual(current, "a17b06c4719cc94c94bdf97afb3b6862cd049323")
        self.assertNotEqual(prior, current)
        self.assertEqual(module.verify(pubspec(1974), config(prior)), (1974, prior))
        self.assertEqual(module.verify(pubspec(1975), config(current)), (1975, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1974), config(current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1975), config(prior))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(current))

    def test_1976_darkride_neon_and_motion_fix_use_exact_reviewed_source(self):
        old = module.APPROVED[1975]
        new = module.APPROVED[1976]
        self.assertEqual(old, "a17b06c4719cc94c94bdf97afb3b6862cd049323")
        self.assertEqual(new, "6518a13fb8eb30c81c8a2115d14791cbe7ddd24a")
        self.assertNotEqual(old, new)
        self.assertEqual(module.verify(pubspec(1975), config(old)), (1975, old))
        self.assertEqual(module.verify(pubspec(1976), config(new)), (1976, new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1975), config(new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1976), config(old))

    def test_1977_cavern_preserves_1976_fallback_and_rejects_cross_pinning(self):
        old = module.APPROVED[1976]
        new = "efa1f69b4128a047e6196ee85762447e412db266"
        self.assertEqual(module.verify(pubspec(1977), config(new)), (1977, new))
        self.assertEqual(module.verify(pubspec(1976), config(old)), (1976, old))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1977), config(old))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1976), config(new))

    def test_1978_visual_and_fold_release_retains_exact_1977_godot_binary(self):
        latest = module.APPROVED[1978]
        self.assertEqual(latest, module.APPROVED[1977])
        self.assertEqual(latest, "efa1f69b4128a047e6196ee85762447e412db266")
        for build in (1976, 1977, 1978):
            self.assertEqual(
                module.verify(pubspec(build), config(module.APPROVED[build])),
                (build, module.APPROVED[build]),
            )
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1978), config(module.APPROVED[1976]))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1977), config(module.APPROVED[1976]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(latest))

    def test_1979_cinema_lab_uses_exact_godot_source_and_preserves_fallbacks(self):
        new = module.APPROVED[1979]
        old = module.APPROVED[1978]
        self.assertEqual(new, '20652880eda687c67cfa72301dad5a173b1fe6c5')
        self.assertNotEqual(new, old)
        for build in (1976, 1977, 1978, 1979):
            self.assertEqual(
                module.verify(pubspec(build), config(module.APPROVED[build])),
                (build, module.APPROVED[build]),
            )
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1978), config(new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1979), config(old))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(new))

    def test_1980_integrated_atelier_and_kart_preserves_verified_cinema(self):
        previous = module.APPROVED[1979]
        selected = module.APPROVED[1980]
        self.assertEqual(selected, "20652880eda687c67cfa72301dad5a173b1fe6c5")
        self.assertEqual(previous, selected)
        for build in (1978, 1979, 1980):
            self.assertEqual(
                module.verify(pubspec(build), config(module.APPROVED[build])),
                (build, module.APPROVED[build]),
            )
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1980), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(selected))

    def test_1981_reading_adventure_preserves_native_source(self):
        old = module.APPROVED[1980]
        new = module.APPROVED[1981]
        self.assertEqual(new, old)
        self.assertEqual(module.verify(pubspec(1981), config(new)), (1981, new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1981), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(new))

    def test_1982_quizshow_ui_only_preserves_1981_native_pin(self):
        previous = module.APPROVED[1981]
        selected = module.APPROVED[1982]
        self.assertEqual(selected, previous)
        self.assertEqual(selected, "20652880eda687c67cfa72301dad5a173b1fe6c5")
        self.assertEqual(
            module.verify(pubspec(1982), config(selected)), (1982, selected),
        )
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1982), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(selected))

    def test_1983_tv_studio_preserves_exact_1982_native_revision(self):
        current = module.APPROVED[1983]
        self.assertEqual(current, module.APPROVED[1982])
        self.assertEqual(module.verify(pubspec(1983), config(current)), (1983, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1983), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(current))

    def test_1984_scene_and_voice_release_keeps_1983_verified_kart_pin(self):
        current = module.APPROVED[1984]
        previous = module.APPROVED[1983]
        self.assertEqual(current, previous)
        self.assertEqual(module.verify(pubspec(1984), config(current)), (1984, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1984), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(current))

    def test_unknown_release_source_and_engine_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(1985), config(module.APPROVED[1968]))
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
