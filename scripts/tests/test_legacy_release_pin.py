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

    def test_1985_separately_pins_kart_without_rewriting_1984(self):
        previous = module.APPROVED[1984]
        candidate = module.APPROVED[1985]
        self.assertEqual(previous, "20652880eda687c67cfa72301dad5a173b1fe6c5")
        self.assertEqual(candidate, "ffd2955ca9222daf02e6b602b3f213fd9383204a")
        self.assertEqual(module.verify(pubspec(1985), config(candidate)), (1985, candidate))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1985), config(previous))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1984), config(candidate))

    def test_1986_includes_flutter_scene_upgrades_without_unreviewed_kart_changes(self):
        selected = module.APPROVED[1986]
        self.assertEqual(selected, module.APPROVED[1985])
        self.assertEqual(module.verify(pubspec(1986), config(selected)), (1986, selected))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1986), config(module.APPROVED[1984]))

    def test_1987_education_ui_preserves_pinned_native_engine(self):
        current = module.APPROVED[1987]
        self.assertEqual(current, module.APPROVED[1986])
        self.assertEqual(module.verify(pubspec(1987), config(current)), (1987, current))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(current))

    def test_1988_cards_build_preserves_exact_verified_kart_pin(self):
        selected = module.APPROVED[1988]
        self.assertEqual(selected, module.APPROVED[1987])
        self.assertEqual(module.verify(pubspec(1988), config(selected)), (1988, selected))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(selected))

    def test_1989_subject_cards_preserve_1988_native_source_and_reject_mismatch(self):
        current = module.APPROVED[1989]
        self.assertEqual(current, module.APPROVED[1988])
        self.assertEqual(current, "ffd2955ca9222daf02e6b602b3f213fd9383204a")
        self.assertEqual(module.verify(pubspec(1989), config(current)), (1989, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1989), config(module.APPROVED[1984]))
        with self.assertRaisesRegex(ValueError, "origin"):
            module.verify(pubspec(1989), config(current, origin="https://example.org"))
        with self.assertRaisesRegex(ValueError, "engine"):
            module.verify(pubspec(1989), config(current, engine="4.7"))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(current))

    def test_1990_design_release_preserves_exact_reviewed_godot_source(self):
        approved = module.APPROVED[1990]
        self.assertEqual(approved, module.APPROVED[1989])
        self.assertEqual(approved, "ffd2955ca9222daf02e6b602b3f213fd9383204a")
        self.assertEqual(module.verify(pubspec(1990), config(approved)), (1990, approved))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(approved))


    def test_1991_latest_native_scene_transition_test_preserves_1990_identity(self):
        older = module.APPROVED[1990]
        newest = module.APPROVED[1991]
        self.assertEqual(older, "ffd2955ca9222daf02e6b602b3f213fd9383204a")
        self.assertEqual(newest, "63cecf09fa89dd504cc468ebd121b4ec71a0f36c")
        self.assertNotEqual(older, newest)
        self.assertEqual(module.verify(pubspec(1991), config(newest)), (1991, newest))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1991), config(older))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1990), config(newest))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(newest))

    def test_1992_ux_refresh_does_not_change_1991_native_gameplay(self):
        previous = module.APPROVED[1991]
        current = module.APPROVED[1992]
        self.assertEqual(current, previous)
        self.assertEqual(module.verify(pubspec(1992), config(current)),
                         (1992, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1992), config(module.APPROVED[1990]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(current))

    def test_1993_nextgen_uses_pinned_reviewed_cinematic_kart_without_mutating_1992(self):
        old = module.APPROVED[1992]
        newest = module.APPROVED[1993]
        self.assertEqual(old, "63cecf09fa89dd504cc468ebd121b4ec71a0f36c")
        self.assertEqual(newest, "8342a2f10b2ecb8cf9cf1cb9566093fbc4d0b07c")
        self.assertNotEqual(old, newest)
        self.assertEqual(module.verify(pubspec(1993), config(newest)), (1993, newest))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1993), config(old))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1992), config(newest))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(newest))

    def test_1994_premium_mode_and_math_release_preserves_1993_source(self):
        old = module.APPROVED[1993]
        candidate = module.APPROVED[1994]
        self.assertEqual(old, "8342a2f10b2ecb8cf9cf1cb9566093fbc4d0b07c")
        self.assertEqual(candidate, "928fed3c7f0b39357e0f06463ce13c8d5677d6e1")
        self.assertNotEqual(old, candidate)
        self.assertEqual(module.verify(pubspec(1993), config(old)), (1993, old))
        self.assertEqual(module.verify(pubspec(1994), config(candidate)), (1994, candidate))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1993), config(candidate))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1994), config(old))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(candidate))

    def test_1995_sol_math_and_verified_responsive_kart_is_immutable(self):
        original = module.APPROVED[1994]
        candidate = module.APPROVED[1995]
        self.assertEqual(original, "928fed3c7f0b39357e0f06463ce13c8d5677d6e1")
        self.assertEqual(candidate, "700baf49828eda693ecce15b415847818b1b56d3")
        self.assertNotEqual(original, candidate)
        self.assertEqual(module.verify(pubspec(1995), config(candidate)), (1995, candidate))
        self.assertEqual(module.verify(pubspec(1994), config(original)), (1994, original))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1995), config(original))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1994), config(candidate))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(candidate))

    def test_1996_crystal_geometry_release_is_distinct_and_pin_locked(self):
        old = module.APPROVED[1995]
        new = module.APPROVED[1996]
        self.assertEqual(old, "700baf49828eda693ecce15b415847818b1b56d3")
        self.assertEqual(new, old)
        self.assertEqual(module.verify(pubspec(1995), config(old)), (1995, old))
        self.assertEqual(module.verify(pubspec(1996), config(new)), (1996, new))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(new))

    def test_1997_landing_fit_release_has_its_own_reviewed_pin(self):
        old = module.APPROVED[1996]
        new = module.APPROVED[1997]
        self.assertEqual(old, "700baf49828eda693ecce15b415847818b1b56d3")
        self.assertEqual(new, "3a3142608f6b150ee251373ba81e6face2eed4b3")
        self.assertNotEqual(old, new)
        self.assertEqual(module.verify(pubspec(1996), config(old)), (1996, old))
        self.assertEqual(module.verify(pubspec(1997), config(new)), (1997, new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1997), config(old))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1996), config(new))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(new))

    def test_1998_spielwelt_ui_preserves_1997_native_kart(self):
        previous = module.APPROVED[1997]
        current = module.APPROVED[1998]
        self.assertEqual(previous, "3a3142608f6b150ee251373ba81e6face2eed4b3")
        self.assertEqual(current, previous)
        self.assertEqual(module.verify(pubspec(1997), config(previous)), (1997, previous))
        self.assertEqual(module.verify(pubspec(1998), config(current)), (1998, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1998), config(module.APPROVED[1996]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9998), config(current))

    def test_1999_preserves_the_reviewed_visible_hub_fix(self):
        candidate = "4d0fd40fdf188be6ca86057596c7b51f41701fa3"
        self.assertEqual(module.verify(pubspec(1999), config(candidate)), (1999, candidate))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1999), config(module.APPROVED[1998]))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1998), config(candidate))

    def test_2000_bumps_existing_app_and_pins_combined_sonnenhafen_with_tutor(self):
        previous = module.APPROVED[1999]
        candidate = module.APPROVED[2000]
        self.assertEqual(previous, "4d0fd40fdf188be6ca86057596c7b51f41701fa3")
        self.assertEqual(candidate, "adcce3093caa42bf3da47262f70bdf03cdefa347")
        self.assertNotEqual(previous, candidate)
        self.assertEqual(module.verify(pubspec(2000), config(candidate)), (2000, candidate))
        self.assertEqual(module.verify(pubspec(1999), config(previous)), (1999, previous))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(2000), config(previous))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1999), config(candidate))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(2001), config(candidate))

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
            module.verify(pubspec(9999), config(current))

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
            module.verify(pubspec(9999), config(latest))

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
            module.verify(pubspec(9999), config(new))

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
            module.verify(pubspec(9999), config(selected))

    def test_1981_reading_adventure_preserves_native_source(self):
        old = module.APPROVED[1980]
        new = module.APPROVED[1981]
        self.assertEqual(new, old)
        self.assertEqual(module.verify(pubspec(1981), config(new)), (1981, new))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1981), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(new))

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
            module.verify(pubspec(9999), config(selected))

    def test_1983_tv_studio_preserves_exact_1982_native_revision(self):
        current = module.APPROVED[1983]
        self.assertEqual(current, module.APPROVED[1982])
        self.assertEqual(module.verify(pubspec(1983), config(current)), (1983, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1983), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(current))

    def test_1984_scene_and_voice_release_keeps_1983_verified_kart_pin(self):
        current = module.APPROVED[1984]
        previous = module.APPROVED[1983]
        self.assertEqual(current, previous)
        self.assertEqual(module.verify(pubspec(1984), config(current)), (1984, current))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            module.verify(pubspec(1984), config(module.APPROVED[1978]))
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(current))

    def test_unknown_release_source_and_engine_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
            module.verify(pubspec(9999), config(module.APPROVED[1968]))
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
