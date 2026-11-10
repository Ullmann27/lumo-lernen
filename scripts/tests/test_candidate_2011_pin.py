"""Regression for the candidate/version mismatch found in PR #437.

This checks source identity only. It does not approve an APK, a device update,
private 2010 source integration, visual quality, or Android runtime behaviour.
"""
import hashlib
import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "candidate_pin_policy", ROOT / "scripts" / "verify_legacy_release_pin.py"
)
POLICY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(POLICY)
ORIGIN = "https://github.com/Ullmann27/lumo-godot.git"
CANDIDATE_REVISION = "a81ddf12d594cc252caef7503162e89c6b26e1c7"
PREVIOUS_REVISION = "91b8cdba48d539ba48836bfac5f6b62c0d6cfa41"
HISTORICAL_POLICY_SHA256 = "be2e5714396b81f4797051394fb8ebbbc484f65a5deb1b71cc234f17ba3ae1de"


def config(revision=CANDIDATE_REVISION, *, origin=ORIGIN, engine="4.6.3"):
    return json.dumps({"repository": origin, "revision": revision, "engine": engine})


def version(build):
    return f"name: lumo_lernen\nversion: 0.12.99+{build}\n"


class Candidate2011PinTests(unittest.TestCase):
    def test_current_candidate_identity_exceeds_existing_2008_and_reserved_2010(self):
        pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
        source = (ROOT / "config" / "godot-source.json").read_text(encoding="utf-8")
        # This is the actual failing build contract, not an invented mock.
        build, revision = POLICY.verify(pubspec, source)
        self.assertEqual((build, revision), (2013, "47bef06db45d61d50ecd06d0b0cd0a69b9a25917"))
        self.assertGreater(build, 2011)

    def test_new_candidate_has_exact_reviewed_native_identity(self):
        self.assertEqual(
            POLICY.verify(version(2011), config()), (2011, CANDIDATE_REVISION)
        )

    def test_2012_and_2013_keep_distinct_reviewed_native_identities(self):
        self.assertEqual(
            POLICY.verify(
                version(2012),
                config("9947346ecc526512904adecec1815312020beb62"),
            ),
            (2012, "9947346ecc526512904adecec1815312020beb62"),
        )
        self.assertEqual(
            POLICY.verify(
                version(2013),
                config("47bef06db45d61d50ecd06d0b0cd0a69b9a25917"),
            ),
            (2013, "47bef06db45d61d50ecd06d0b0cd0a69b9a25917"),
        )

    def test_all_existing_native_identities_are_unchanged(self):
        old = {k: v for k, v in POLICY.APPROVED.items() if k not in (2011, 2012, 2013)}
        digest = hashlib.sha256(
            json.dumps(old, sort_keys=True, separators=(",", ":")).encode()
        ).hexdigest()
        self.assertEqual(digest, HISTORICAL_POLICY_SHA256)
        for build, revision in old.items():
            with self.subTest(build=build):
                self.assertEqual(POLICY.verify(version(build), config(revision)),
                                 (build, revision))

    def test_2005_keeps_its_original_revision(self):
        self.assertEqual(POLICY.verify(version(2005), config(PREVIOUS_REVISION)),
                         (2005, PREVIOUS_REVISION))
        with self.assertRaisesRegex(ValueError, "revision mismatch"):
            POLICY.verify(version(2005), config())

    def test_2011_rejects_old_or_invented_native_sources(self):
        for revision in (PREVIOUS_REVISION, "0" * 40, "", "a81ddf12"):
            with self.subTest(revision=revision):
                with self.assertRaisesRegex(ValueError, "revision mismatch"):
                    POLICY.verify(version(2011), config(revision))

    def test_foreign_source_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "origin"):
            POLICY.verify(version(2011), config(origin="https://example.invalid/game.git"))

    def test_unreviewed_engine_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "engine"):
            POLICY.verify(version(2011), config(engine="4.7"))

    def test_extra_configuration_fields_are_rejected(self):
        data = json.loads(config())
        data["skip_verification"] = True
        with self.assertRaisesRegex(ValueError, "config keys"):
            POLICY.verify(version(2011), json.dumps(data))

    def test_unreserved_and_private_checkpoint_versions_stay_closed(self):
        for build in (2006, 2007, 2008, 2009, 2010, 9999):
            with self.subTest(build=build):
                with self.assertRaisesRegex(ValueError, "no reviewed native pin"):
                    POLICY.verify(version(build), config())

    def test_missing_or_duplicate_version_remains_rejected(self):
        for spec in ("name: lumo_lernen\n", version(2011) + version(2011)):
            with self.subTest(pubspec=spec):
                with self.assertRaisesRegex(ValueError, "Exactly one"):
                    POLICY.verify(spec, config())


if __name__ == "__main__":
    unittest.main()
