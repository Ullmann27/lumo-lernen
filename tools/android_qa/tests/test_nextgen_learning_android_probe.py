"""Pure evidence gates for the current learning probe; no Android mutation."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    "nextgen_learning_android_probe",
    ROOT / ".github/probes/lumo_nextgen_learning_android_probe.py",
)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


class ArtifactIdentityTest(unittest.TestCase):
    def setUp(self):
        self.expected = {"sha256": "a" * 64, "source": "b" * 40, "native": "c" * 40,
                         "version": 2027, "certificate": "d" * 64}
        self.proof = {"sha256": "a" * 64, "flutter_source_commit": "b" * 40,
                      "versionCode": 2027, "versionName": "2.0.27", "package": probe.PACKAGE,
                      "signingCertificateSha256": "d" * 64, "tracked_source_clean": True,
                      "abis": ["x86_64"], "godot": {"revision": "c" * 40, "pck_sha256": "e" * 64}}

    def test_exact_current_identity_is_accepted(self):
        result = probe.verify_provenance(self.proof, **self.expected)
        self.assertEqual(result["flutter_source_commit"], "b" * 40)
        self.assertEqual(result["versionCode"], 2027)

    def test_each_mismatched_source_or_binary_fact_is_rejected(self):
        for key, value in (("sha256", "f" * 64), ("flutter_source_commit", "f" * 40),
                           ("versionCode", 2018), ("versionCode", "2027"),
                           ("package", "another.package"), ("signingCertificateSha256", "f" * 64),
                           ("tracked_source_clean", False), ("tracked_source_clean", 1),
                           ("abis", ["arm64-v8a"]), ("abis", ["x86_64", "arm64-v8a"]),
                           ("versionName", ""), ("godot", {"revision": "f" * 40, "pck_sha256": "e" * 64}),
                           ("godot", {"revision": "c" * 40, "pck_sha256": "short"})):
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                probe.verify_provenance({**self.proof, key: value}, **self.expected)

    def test_short_mutable_and_historical_pins_are_rejected(self):
        for key, value in (("source", "main"), ("native", "c" * 7), ("sha256", "a" * 63),
                           ("certificate", "D" * 64), ("version", 2018), ("version", True)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_provenance(self.proof, **{**self.expected, key: value})

    def test_duplicate_json_keys_cannot_hide_an_identity(self):
        for value in ('{"sha256":"a","sha256":"b"}',
                      '{"godot":{"revision":"a","revision":"b"}}', '[]'):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                probe.read_json(value)

    def test_actual_manifest_and_signer_must_match(self):
        identity = probe.verify_provenance(self.proof, **self.expected)
        badging = f"package: name='{probe.PACKAGE}' versionCode='2027' versionName='2.0.27' platformBuildVersionName='16'\n"
        signer = "Signer #1 certificate SHA-256 digest: " + "d" * 64 + "\n"
        probe.verify_manifest_and_signer(badging, signer, identity)
        for actual_manifest, actual_signer in ((badging.replace("2027", "2018"), signer),
                                               (badging.replace("2.0.27", "2.0.18"), signer),
                                               (badging, signer.replace("d" * 64, "e" * 64)),
                                               (badging, signer + signer.replace("#1", "#2")),
                                               (badging + badging, signer), (badging, "")):
            with self.subTest(manifest=actual_manifest, signer=actual_signer), self.assertRaises(RuntimeError):
                probe.verify_manifest_and_signer(actual_manifest, actual_signer, identity)

    def test_installed_bytes_and_packagemanager_must_match(self):
        identity = probe.verify_provenance(self.proof, **self.expected)
        dump = f"Package [{probe.PACKAGE}] (abc):\n    versionCode=2027 minSdk=24 targetSdk=36\n    versionName=2.0.27\n"
        result = probe.verify_installed_metadata(dump, "a" * 64, identity)
        self.assertEqual(result["signingCertificateSha256"], "d" * 64)
        for actual, actual_hash in ((dump.replace("2027", "2018"), "a" * 64),
                                    (dump.replace(probe.PACKAGE, "other.package"), "a" * 64),
                                    (dump + "versionCode=2018\n", "a" * 64),
                                    (dump, "f" * 64)):
            with self.subTest(actual=actual, actual_hash=actual_hash), self.assertRaises(RuntimeError):
                probe.verify_installed_metadata(actual, actual_hash, identity)

    def test_observed_sdk_v2_signer_format_is_accepted(self):
        # Original Android job 132959417938 / artifact 14180492732, preserved
        # under docs/nextgen/evidence/android_signature_reader_20261115/.
        signer = (
            "V2 Signer: certificate DN: CN=Android Debug, O=Lumo Lernen, C=AT\n"
            "V2 Signer: certificate SHA-256 digest: "
            "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702\n"
            "V2 Signer: certificate SHA-1 digest: 90c562e2465d2d9a3fec1de5fc185097bc2161d1\n"
            "V2 Signer: certificate MD5 digest: 7dd2c8ddd337a881ac3d2662a98bf638\n"
        )
        identity = {**probe.verify_provenance(self.proof, **self.expected),
                    "versionName": "0.13.15",
                    "signingCertificateSha256":
                    "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"}
        badging = f"package: name='{probe.PACKAGE}' versionCode='2027' versionName='0.13.15'\n"
        probe.verify_manifest_and_signer(badging, signer, identity)

    def test_v2_signer_rejects_wrong_partial_or_ambiguous_certificates(self):
        identity = probe.verify_provenance(self.proof, **self.expected)
        badging = f"package: name='{probe.PACKAGE}' versionCode='2027' versionName='2.0.27'\n"
        valid = "V2 Signer: certificate SHA-256 digest: " + "d" * 64 + "\n"
        numbered = "Signer #1 certificate SHA-256 digest: " + "d" * 64 + "\n"
        for signer in (valid.replace("d" * 64, "e" * 64),
                       valid.replace("d" * 64, "d" * 63),
                       valid.replace("d" * 64, "d" * 65),
                       valid + valid, valid + numbered,
                       valid + valid.replace("V2 Signer:", "Unknown signer:"),
                       "untrusted prefix " + valid,
                       valid.replace("V2 Signer:", "Unknown signer:")):
            with self.subTest(signer=signer), self.assertRaises(RuntimeError):
                probe.verify_manifest_and_signer(badging, signer, identity)


class InstalledBaseApkPathTest(unittest.TestCase):
    def test_real_recorded_android_opaque_path_is_accepted(self):
        # An unchanged historical Android observation, not this failed run's
        # missing pm-path output and not new runtime acceptance.
        fixture = ROOT / "tools/android_qa/tests/fixtures/android_2018_cards_authority_recorded.txt"
        lines = [line.strip().removeprefix("baseDir=") for line in fixture.read_text().splitlines()
                 if line.strip().startswith("baseDir=")]
        self.assertEqual(len(lines), 1)
        self.assertIn("/data/app/~~", lines[0])
        self.assertEqual(probe.installed_base_apk_path("package:" + lines[0] + "\n"), lines[0])

    def test_supported_flat_and_nested_monolithic_paths(self):
        for path in ("/data/app/dev.ullmann.lumo-1/base.apk",
                     "/data/app/~~opaque_+=-/dev.ullmann.lumo-random==/base.apk"):
            for ending in ("", "\n", "\r\n"):
                with self.subTest(path=path, ending=ending):
                    self.assertEqual(probe.installed_base_apk_path("package:" + path + ending), path)

    def test_missing_multiple_split_and_unsafe_paths_fail(self):
        valid = "package:/data/app/~~opaque==/dev.ullmann.lumo-random==/base.apk"
        for raw in ("", valid + "\n" + valid, valid + "\n\n", valid + "\npackage:/data/app/app/split_config.en.apk",
                    "package:/data/app/app/split_config.en.apk", "/data/app/app/base.apk",
                    "package:/data/local/tmp/app/base.apk", "package:/data/application/app/base.apk",
                    "package:/data/app/base.apk", "package:/data/app//app/base.apk",
                    "package:/data/app/./app/base.apk", "package:/data/app/app/../base.apk",
                    "package:/data/app/app/base.apk;id", "package:/data/app/$(id)/base.apk",
                    "package:/data/app/app/base.apk ", " " + valid,
                    "package:/data/app/a\\b/base.apk", "package:/data/app/a%2fb/base.apk",
                    "package:/data/app/ä/base.apk", "package:/data/app/a\x00b/base.apk"):
            with self.subTest(raw=raw), self.assertRaises(RuntimeError):
                probe.installed_base_apk_path(raw)

    def test_raw_pm_path_response_is_saved_before_validation_failure(self):
        with tempfile.TemporaryDirectory() as temporary:
            instance = probe.LearningProbe.__new__(probe.LearningProbe)
            instance.out = Path(temporary)
            raw = "package:/data/app/~~opaque==/app/base.apk\npackage:/data/app/app/split.apk\n"
            calls = []
            def adb(*args):
                calls.append(args)
                return raw
            instance.base = SimpleNamespace(adb=adb)
            with self.assertRaises(RuntimeError):
                instance.read_installed_base_apk_path("installed")
            self.assertEqual((instance.out / "installed-pm-path.txt").read_text(), raw)
            self.assertEqual(calls, [("shell", "pm", "path", probe.PACKAGE)])


class ObservationTest(unittest.TestCase):
    def node(self, **changes):
        return {"text": "Stopp", "bounds": "[10,20][210,120]", "enabled": "true",
                "clickable": "true", "package": probe.PACKAGE, **changes}

    def test_only_live_enabled_actionable_bounds_are_accepted(self):
        self.assertEqual(probe.observed_control([self.node()], "Stopp"), (10, 20, 210, 120))
        for changes in ({"enabled": "false"}, {"clickable": "false"}, {"package": "other.package"},
                        {"bounds": "[-1,20][210,120]"}, {"bounds": "[10,20][210,21]"},
                        {"bounds": "[10,20][9,120]"}, {"bounds": "guessed"}, {"text": "Stopp später"}):
            with self.subTest(changes=changes):
                self.assertIsNone(probe.observed_control([self.node(**changes)], "Stopp"))

    def test_ambiguous_controls_are_rejected(self):
        with self.assertRaises(RuntimeError):
            probe.observed_control([self.node(), self.node(bounds="[10,200][210,300]")], "Stopp")

    def test_duplicate_semantics_on_same_observed_rectangle_are_one_target(self):
        self.assertEqual(probe.observed_control([self.node(), self.node()], "Stopp"), (10, 20, 210, 120))

    def test_equivalent_navigation_exception_is_restricted_to_reviewed_route(self):
        nodes = [self.node(text="Spielen"), self.node(text="Spielen", bounds="[10,200][410,400]")]
        self.assertEqual(probe.observed_control(nodes, "Spielen", equivalent_navigation=True), (10, 20, 210, 120))
        with self.assertRaises(RuntimeError):
            probe.observed_control([self.node()], "Stopp", equivalent_navigation=True)

    def test_question_prompt_or_generic_reply_is_not_why_evidence(self):
        for labels in ([probe.BRIDGE_PROMPT], ["Warum zuerst zwei?"], ["Du schaffst das!"],
                       ["Bis 10 fehlen 2."], ["8 und 2 und 10."]):
            with self.subTest(labels=labels):
                self.assertIsNone(probe.why_response(labels))
        response = "Weil von acht bis zehn zwei freie Plätze fehlen."
        self.assertEqual(probe.why_response([response]), response)
        visible = "Im Zehnerfeld liegen 8 Plättchen. Es sind noch 2 Plätze frei. Darum brauchen wir zuerst 2 aus dem Vorrat."
        self.assertEqual(probe.why_response([visible]), visible)

    def test_microphone_requires_actual_ready_ui_or_explicit_device_limitation(self):
        for text in ("Sprich jetzt. Lumo sendet die Frage automatisch.", "Lumo hört dir zu."):
            with self.subTest(text=text):
                self.assertEqual(probe.microphone_outcome([text]), "listening_ui_observed")
        for text in (
            "Eine deutsche Spracherkennung ist auf diesem Gerät noch nicht bestätigt.",
            "Das Mikrofon hat den Start nicht bestätigt. Du kannst tippen.",
            "Lokale Spracherkennung ist auf diesem Gerät nicht bereit.",
            "Die Spracheingabe ist nicht bereit. Prüfe die Mikrofonfreigabe.",
        ):
            with self.subTest(text=text):
                self.assertEqual(probe.microphone_outcome([text]), "explicit_device_limitation")
        for labels in (["Sprechen", "Stopp"], ["Zuhören …"], ["Spracherkennung"],
                       ["Deine Antwort ist noch nicht bestätigt."]):
            with self.subTest(labels=labels):
                self.assertIsNone(probe.microphone_outcome(labels))


class MicrophonePermissionFlowTest(unittest.TestCase):
    """Runtime Element nodes: original XML and labelled synthetic frames; no device run."""
    fixtures = ROOT / "tools/android_qa/tests/fixtures/nextgen_permission_43774460935"

    @classmethod
    def setUpClass(cls):
        manifest = json.loads((cls.fixtures / "manifest.json").read_text())
        member = manifest["files"][0]
        data = (cls.fixtures / member["file"]).read_bytes()
        assert len(data) == member["bytes"]
        assert hashlib.sha256(data).hexdigest() == member["sha256"]
        cls.original = list(ET.fromstring(data).iter("node"))

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)

    def node(self, text, **changes):
        return ET.Element("node", {"text": text, "content-desc": "", "enabled": "true", "clickable": "false",
                "visible-to-user": "true", "package": probe.PACKAGE,
                "bounds": "[30,40][1030,180]", **changes})

    def permission(self, prompt="Allow Lumo Lernen Neu to record audio?", **button_changes):
        # Synthetic transport fixtures. Their geometry/text is not a recorded
        # post-0138 hierarchy, and cannot serve as Android runtime evidence.
        package = "com.google.android.permissioncontroller"
        return [self.node(prompt, package=package,
                          **{"resource-id": package + ":id/permission_message"}),
                self.node("While using the app",
                          **{"package": package, "clickable": "true",
                             "resource-id": package + ":id/permission_allow_foreground_only_button",
                             "bounds": "[130,1120][950,1280]", **button_changes})]

    def listening(self):
        return [self.node("Lumo hört dir zu.")]

    def scenario(self, frames, *, read_seconds=1):
        instance = probe.LearningProbe.__new__(probe.LearningProbe)
        instance.args = SimpleNamespace(conversation_ui="freevoice")
        instance.out = self.out
        instance.base = SimpleNamespace(adb=lambda *args, **kwargs: "synthetic.recognizer/Service")
        instance.tap = instance.see = instance.type_text = instance.capture = lambda *args, **kwargs: None
        clock, touches, observations, saved = SimpleNamespace(now=0), [], [], {}
        instance.save = lambda name, value: saved.update({name: value})
        def nodes(tag):
            if tag == "typed-why-answer":
                return [self.node("Weil von acht bis zehn zwei freie Plätze fehlen.")]
            self.assertEqual(tag, "microphone-outcome")
            frame = frames[min(len(observations), len(frames) - 1)]
            observations.append(frame)
            clock.now += read_seconds
            return frame
        def touch(box, tag, label):
            touches.append((box, tag, label, clock.now))
            clock.now += .6
        def sleep(seconds):
            self.assertGreaterEqual(seconds, 0)
            clock.now += seconds
        instance.nodes, instance.touch = nodes, touch
        def run():
            with patch.object(probe.time, "monotonic", lambda: clock.now), patch.object(probe.time, "sleep", sleep):
                return instance.conversation()
        return SimpleNamespace(run=run, clock=clock, touches=touches, observations=observations, saved=saved)

    def test_original_zero_height_dialog_is_polled_until_a_fresh_visible_audio_target(self):
        system = [n for n in self.original if "permissioncontroller" in n.get("package", "")]
        self.assertEqual(len(system), 1)
        self.assertEqual(system[0].get("visible-to-user"), "false")
        self.assertEqual(system[0].get("bounds"), "[27,1205][1053,1205]")
        ready = self.permission()
        run = self.scenario([self.original, ready, ready, self.listening()])
        result = run.run()
        self.assertEqual(result["microphone_ui_outcome"], "listening_ui_observed")
        self.assertEqual(len(run.observations), 4)
        self.assertEqual(len(run.touches), 1)
        self.assertEqual(run.touches[0][:2], ((130, 1120, 950, 1280), "microphone-permission"))

    def test_case_aliases_and_duplicate_semantics_are_one_real_allow_target(self):
        ready = self.permission(**{"content-desc": "WHILE USING THE APP"})
        ready.append(copy.deepcopy(ready[1]))
        run = self.scenario([ready, self.listening()])
        self.assertEqual(run.run()["microphone_ui_outcome"], "listening_ui_observed")
        self.assertEqual(len(run.touches), 1)

    def test_system_packages_and_caption_case_variants_keep_one_target(self):
        for package in ("com.android.permissioncontroller", "com.google.android.permissioncontroller"):
            for prompt, caption in (("Allow Lumo Lernen Neu to record audio?", "While using the app"),
                                    ("Allow Lumo Lernen Neu to record audio?", "WHILE USING THE APP"),
                                    ("Lumo Lernen Neu erlauben, Audio aufzunehmen?", "Bei Nutzung der App"),
                                    ("Lumo Lernen Neu erlauben, Audio aufzunehmen?", "BEI NUTZUNG DER APP")):
                with self.subTest(package=package, caption=caption):
                    ready = self.permission(prompt)
                    for node in ready:
                        node.set("package", package)
                    ready[1].set("text", caption)
                    run = self.scenario([ready, self.listening()])
                    self.assertEqual(run.run()["microphone_ui_outcome"], "listening_ui_observed")
                    self.assertEqual(len(run.touches), 1)

    def test_two_different_allow_buttons_remain_ambiguous(self):
        ready = self.permission()
        other = copy.deepcopy(ready[1])
        other.set("bounds", "[130,1400][950,1560]")
        ready.append(other)
        run = self.scenario([ready, self.listening()])
        with self.assertRaisesRegex(RuntimeError, "[Aa]mbiguous"):
            run.run()
        self.assertEqual(run.touches, [])

    def test_unrelated_permission_and_other_app_are_refused_before_touch(self):
        for prompt in ("Allow Lumo Lernen Neu to take pictures and record video?",
                       "Allow Lumo Lernen Neu to access this device's location?",
                       "Allow Another App to record audio?", "Allow Lumo Lernen Neu to record audio and access location?"):
            with self.subTest(prompt=prompt):
                run = self.scenario([self.permission(prompt), self.listening()])
                with self.assertRaisesRegex(RuntimeError, "audio permission"):
                    run.run()
                self.assertEqual(run.touches, [])

    def test_audio_prompt_must_itself_be_visible_in_the_same_system_package(self):
        for changes in ({"visible-to-user": "false"}, {"bounds": "[30,40][1030,40]"},
                        {"package": probe.PACKAGE}):
            with self.subTest(changes=changes):
                ready = self.permission()
                ready[0].attrib.update(changes)
                run = self.scenario([ready])
                with self.assertRaisesRegex(RuntimeError, "Microphone request produced neither"):
                    run.run()
                self.assertEqual(run.touches, [])
                self.assertGreaterEqual(run.clock.now, 35)

    def test_visible_button_waits_for_fresh_audio_prompt_before_grant(self):
        ready = self.permission()
        partial = copy.deepcopy(ready)
        partial[0].set("visible-to-user", "false")
        run = self.scenario([partial, ready, self.listening()])
        self.assertEqual(run.run()["microphone_ui_outcome"], "listening_ui_observed")
        self.assertEqual(len(run.observations), 3)
        self.assertEqual(len(run.touches), 1)
        self.assertGreater(run.touches[0][3], 2)

    def test_invisible_disabled_or_zero_height_allow_cannot_be_tapped(self):
        for changes in ({"visible-to-user": "false"}, {"enabled": "false"},
                        {"clickable": "false"}, {"bounds": "[130,1120][950,1120]"}):
            with self.subTest(changes=changes):
                run = self.scenario([self.permission(**changes)])
                with self.assertRaisesRegex(RuntimeError, "Microphone request produced neither"):
                    run.run()
                self.assertEqual(run.touches, [])
                self.assertGreaterEqual(run.clock.now, 35)
                self.assertLessEqual(run.clock.now, 36)

    def test_visible_permission_after_tap_waits_for_transition_without_retapping(self):
        ready = self.permission()
        run = self.scenario([ready, ready, ready, self.listening()])
        self.assertEqual(run.run()["microphone_ui_outcome"], "listening_ui_observed")
        self.assertEqual(len(run.touches), 1)
        self.assertEqual(len(run.observations), 4)

    def test_permission_transition_timeout_fails_after_only_one_touch(self):
        run = self.scenario([self.permission()])
        with self.assertRaisesRegex(RuntimeError, "Microphone permission did not transition"):
            run.run()
        self.assertEqual(len(run.touches), 1)
        self.assertGreaterEqual(run.clock.now, 35)
        self.assertLessEqual(run.clock.now, 36)
        self.assertNotIn("microphone-observation", run.saved)

    def test_permission_disappearance_alone_is_not_a_microphone_outcome(self):
        run = self.scenario([self.permission(), [self.node("Sprechen")]])
        with self.assertRaisesRegex(RuntimeError, "Microphone permission did not transition"):
            run.run()
        self.assertEqual(len(run.touches), 1)

    def test_underlying_app_outcome_does_not_pass_while_dialog_is_present(self):
        ready = self.permission() + self.listening()
        run = self.scenario([ready, ready, self.listening()])
        self.assertEqual(run.run()["microphone_ui_outcome"], "listening_ui_observed")
        self.assertEqual(len(run.observations), 3)
        self.assertEqual(len(run.touches), 1)

    def test_late_ready_hierarchy_cannot_extend_original_deadline_or_trigger_touch(self):
        run = self.scenario([self.permission()], read_seconds=36)
        with self.assertRaisesRegex(RuntimeError, "Microphone request produced neither"):
            run.run()
        self.assertEqual(run.touches, [])
        self.assertEqual(len(run.observations), 1)

    def test_already_authorized_listening_ui_or_explicit_limitation_needs_no_grant(self):
        for label, outcome in (("Lumo hört dir zu.", "listening_ui_observed"),
                               ("Lokale Spracherkennung ist auf diesem Gerät nicht bereit.", "explicit_device_limitation")):
            with self.subTest(label=label):
                run = self.scenario([[self.node(label)]])
                self.assertEqual(run.run()["microphone_ui_outcome"], outcome)
                self.assertEqual(run.touches, [])

    def test_recorded_ready_dialog_uses_actual_runtime_xml_parser_and_element_nodes(self):
        fixture = ROOT / "tools/android_qa/tests/fixtures/nextgen_permission_43781148281"
        manifest = json.loads((fixture / "manifest.json").read_text())
        member = manifest["files"][0]
        data = (fixture / member["file"]).read_bytes()
        self.assertEqual(len(data), member["bytes"])
        self.assertEqual(hashlib.sha256(data).hexdigest(), member["sha256"])
        scripts = ROOT / "scripts/probes"
        base_spec = importlib.util.spec_from_file_location("permission_runtime_smoke", scripts / "pr207_android_smoke.py")
        base = importlib.util.module_from_spec(base_spec)
        base_spec.loader.exec_module(base)
        spec = importlib.util.spec_from_file_location("permission_runtime_ui", scripts / "pr207_android_ui_probe.py")
        live = importlib.util.module_from_spec(spec)
        # Only the Android transport is substituted. The actual live_nodes
        # function parses the unchanged recorded XML and returns its Elements.
        with patch.dict(sys.modules, {"uiautomator2": SimpleNamespace(), "pr207_android_smoke": base}):
            spec.loader.exec_module(live)
        def dump_hierarchy(**kwargs):
            self.assertEqual(kwargs, {"compressed": False, "pretty": False})
            return data.decode("utf-8")
        live._device = SimpleNamespace(dump_hierarchy=dump_hierarchy)
        instance = probe.LearningProbe.__new__(probe.LearningProbe)
        instance.out, instance.counter, instance.live = self.out, 0, live
        nodes = instance.nodes("recorded-ready-permission")
        self.assertTrue(nodes and all(isinstance(node, ET.Element) for node in nodes))
        self.assertEqual(probe.observed_microphone_allow(nodes),
                         ("While using the app", (137, 1127, 943, 1281)))
        run = self.scenario([self.original, nodes, nodes, self.listening()])
        self.assertEqual(run.run()["microphone_ui_outcome"], "listening_ui_observed")
        self.assertEqual(len(run.touches), 1)
        self.assertEqual(run.touches[0][0], (137, 1127, 943, 1281))


class RecordedConversationHintTest(unittest.TestCase):
    """Replay the actual empty EA field; this is not a new Android run."""
    fixtures = ROOT / "tools/android_qa/tests/fixtures/nextgen_conversation_43768151118"

    @classmethod
    def setUpClass(cls):
        manifest = json.loads((cls.fixtures / "manifest.json").read_text())
        member = manifest["files"][0]
        data = (cls.fixtures / member["file"]).read_bytes()
        assert len(data) == member["bytes"]
        assert hashlib.sha256(data).hexdigest() == member["sha256"]
        cls.nodes = [node.attrib for node in ET.fromstring(data).iter("node")]
        fields = [node for node in cls.nodes if node.get("class") == "android.widget.EditText"]
        assert len(fields) == 1
        cls.field = fields[0]

    def instance(self, nodes=None):
        instance = probe.LearningProbe.__new__(probe.LearningProbe)
        instance.counter = 0
        instance.nodes = lambda tag: self.nodes if nodes is None else nodes
        instance.save = lambda name, value: None
        return instance

    def test_recorded_visible_hint_satisfies_exact_input_observation_without_scroll(self):
        self.assertEqual(self.field["hint"], "Frag Lumo")
        self.assertEqual(self.field["text"], "")
        self.assertEqual(self.field["content-desc"], "")
        self.assertEqual(probe.bounds(self.field), (86, 2187, 994, 2340))
        instance = self.instance()
        instance.scroll = lambda *args: self.fail("Already visible input must not scroll")
        labels = instance.see("Frag Lumo", "recorded-input", scroll=True, exact=True)
        self.assertIn("Frag Lumo", labels)
        self.assertIsNone(probe.why_response(probe.node_labels([self.field])))

    def test_hidden_disabled_foreign_filled_or_invalid_field_hint_is_not_visible_text(self):
        for changes in ({"visible-to-user": "false"}, {"visible-to-user": ""},
                        {"enabled": "false"}, {"package": "other.package"},
                        {"class": "android.view.View"}, {"bounds": ""},
                        {"bounds": "[-1,2187][994,2340]"}, {"bounds": "[86,2187][86,2340]"},
                        {"bounds": "[86,2187][994,2216]"}, {"text": "Already entered"},
                        {"text": " "}):
            with self.subTest(changes=changes):
                self.assertNotIn("Frag Lumo", probe.node_labels([{**self.field, **changes}]))

    def test_hint_does_not_replace_actual_text_input_or_create_a_labelled_button(self):
        self.assertIsNone(probe.observed_control(self.nodes, "Frag Lumo"))
        text = "Warum zuerst zwei?"
        instance, calls, touches = self.instance(), [], []
        instance.touch = lambda box, tag, label: touches.append(box)
        instance.base = SimpleNamespace(adb=lambda *args: calls.append(args) or "test.ime/Keyboard")
        def wait(description, observe, accept):
            self.assertFalse(accept(observe()), "An empty field/hint cannot prove typed input")
            self.assertTrue(accept([{**self.field, "text": text}]))
        instance.wait = wait
        instance.type_text(text, "recorded-input")
        self.assertEqual(touches, [(86, 2187, 994, 2340)])
        self.assertIn(("shell", "input", "text", "'Warum%szuerst%szwei?'"), calls)

    def test_multiple_editable_fields_remain_rejected_before_any_input(self):
        instance = self.instance([*self.nodes, {**self.field, "bounds": "[86,1900][994,2053]"}])
        instance.touch = lambda *args: self.fail("Ambiguous input must not be touched")
        with self.assertRaisesRegex(RuntimeError, "Exactly one observed editable test field required"):
            instance.type_text("Warum zuerst zwei?", "ambiguous-input")


class SettingsNavigationTest(unittest.TestCase):
    """Original failed UI frames; only the reader transport is replayed here."""
    fixtures = ROOT / "tools/android_qa/tests/fixtures/nextgen_settings_43766331070"

    @classmethod
    def setUpClass(cls):
        manifest = json.loads((cls.fixtures / "manifest.json").read_text())
        for member in manifest["files"]:
            data = (cls.fixtures / member["file"]).read_bytes()
            assert len(data) == member["bytes"]
            assert hashlib.sha256(data).hexdigest() == member["sha256"]

    def nodes(self, name):
        return [node.attrib for node in ET.parse(self.fixtures / name).getroot().iter("node")]

    def replay(self, frames):
        instance = probe.LearningProbe.__new__(probe.LearningProbe)
        instance.counter = 0
        position, directions, journals = [0], [], []
        instance.nodes = lambda tag: frames[position[0]]
        def scroll(nodes, direction):
            self.assertEqual(nodes, frames[position[0]])
            directions.append(direction)
            position[0] = min(position[0] + 1, len(frames) - 1)
            return True
        instance.scroll = scroll
        instance.save = lambda name, value: journals.append(value)
        return instance, directions, journals

    def test_real_clipped_switch_is_not_tappable_until_next_observation(self):
        clipped = self.nodes("0077-local-license.xml")
        visible = self.nodes("0078-local-license.xml")
        label = "Neue Sätze offline vorlesen"
        self.assertIsNone(probe.observed_control(clipped, label))
        self.assertEqual(probe.observed_control(visible, label), (91, 886, 989, 1359))
        instance, directions, journals = self.replay([clipped, visible])
        result = instance.seek_scrolled(lambda nodes: probe.observed_control(nodes, label), "last-gesture", max_scrolls=1)
        self.assertEqual(result, (91, 886, 989, 1359))
        self.assertEqual(directions, [1])
        self.assertEqual(journals[-1]["status"], "FOUND")

    def test_observed_viewport_drives_gesture_inside_settings_not_fixed_chrome(self):
        nodes = self.nodes("0124-set-microphoneEnabled.xml")
        viewport = probe.observed_scroll_bounds(nodes)
        self.assertEqual(viewport, (0, 286, 1080, 1774))
        calls = []
        instance = probe.LearningProbe.__new__(probe.LearningProbe)
        instance.base = SimpleNamespace(adb=lambda *args: calls.append(args))
        with patch.object(probe.time, "sleep"):
            self.assertTrue(instance.scroll(nodes, 1))
        command = calls[0]
        self.assertEqual(command[:3], ("shell", "input", "swipe"))
        x0, y0, x1, y1 = map(int, command[3:7])
        self.assertEqual(x0, x1)
        self.assertTrue(viewport[0] < x0 < viewport[2])
        self.assertTrue(viewport[1] < y1 < y0 < viewport[3])

    def test_reverse_requires_two_observed_stationary_views(self):
        lower = self.nodes("0078-local-license.xml")
        upper = self.nodes("0077-local-license.xml")
        instance, directions, journals = self.replay([lower, lower, lower, upper])
        def title(nodes):
            labels = probe.node_labels(nodes)
            return labels if "Ton und Stimme" in labels else None
        self.assertIsNotNone(instance.seek_scrolled(title, "observed-boundary", max_scrolls=3))
        self.assertEqual(directions, [1, 1, -1])
        self.assertEqual([event["content_changed"] for event in journals[-1]["gestures"]], [False, False, True])

    def test_current_visible_target_does_not_scroll(self):
        nodes = self.nodes("0078-local-license.xml")
        instance, directions, _ = self.replay([nodes])
        self.assertIsNotNone(instance.seek_scrolled(lambda ns: probe.observed_control(ns, "Neue Sätze offline vorlesen"), "already-visible"))
        self.assertEqual(directions, [])

    def test_missing_microphone_remains_a_failure_after_bounded_search(self):
        for name in ("0091-set-microphoneEnabled.xml", "0124-set-microphoneEnabled.xml"):
            with self.subTest(name=name):
                nodes = self.nodes(name)
                self.assertIsNone(probe.observed_control(nodes, "Mikrofon erlauben"))
                instance, directions, journals = self.replay([nodes])
                result = instance.seek_scrolled(lambda ns: probe.observed_control(ns, "Mikrofon erlauben"), "absent-microphone")
                self.assertIsNone(result)
                self.assertEqual(directions, [1, 1, -1, -1])
                self.assertEqual(journals[-1]["status"], "NOT_FOUND")

    def test_transient_missing_viewport_waits_for_observed_dialog_target_without_gesture(self):
        # The real checkbox/control attributes are retained. Removing its
        # enclosing scroll node simulates a non-scrolling transport surface,
        # not a claimed new Android observation.
        frame = [n for n in self.nodes("0078-local-license.xml") if n.get("scrollable") != "true"]
        instance, directions, journals = self.replay([frame])
        observations = iter([[], frame])
        instance.nodes = lambda tag: next(observations)
        with patch.object(probe.time, "sleep"):
            result = instance.seek_scrolled(lambda ns: probe.observed_control(ns, "Neue Sätze offline vorlesen"), "loading-dialog")
        self.assertEqual(result, (91, 886, 989, 1359))
        self.assertEqual(directions, [])
        self.assertEqual(journals[-1]["non_scroll_observations"], 1)

    def test_missing_viewport_cannot_create_a_fallback_gesture(self):
        instance, directions, journals = self.replay([[]])
        self.assertIsNone(instance.seek_scrolled(lambda ns: None, "missing-viewport", readiness_timeout=0))
        self.assertEqual(directions, [])
        self.assertIn("bounded wait", journals[-1]["reason"])

    def test_final_settings_gate_rejects_actual_ungranted_microphone_and_privacy_changes(self):
        values = {node.get("name"): node.text for node in ET.parse(
            self.fixtures / "0090-read-microphoneEnabled-preferences.xml").getroot()}
        observed = json.loads(values["flutter.lumo_app_settings_v1"])
        self.assertFalse(observed["microphoneEnabled"])
        with self.assertRaisesRegex(RuntimeError, "microphoneEnabled"):
            probe.verify_voice_settings(observed, observed)
        expected = {**observed, "microphoneEnabled": True}
        self.assertTrue(probe.verify_voice_settings(observed, expected)["microphone"])
        for key, value in (("microphoneEnabled", "true"), ("localVoiceLicenseAccepted", False),
                           ("voiceEnabled", False), ("autoReadEnabled", False), ("calmMode", True),
                           ("scannerEnabled", True), ("aiProxyEnabled", True), ("cloudVoiceEnabled", True)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_voice_settings(observed, {**expected, key: value})


class PreservationTest(unittest.TestCase):
    def setUp(self):
        self.profile = {"id": "fictional-unique-child", "name": probe.PROFILE_NAME,
                        "age": 7, "grade": 1, "createdAt": "2026-11-15", "lastActiveAt": "first"}
        self.task = {"topicId": "bridge", "problemId": "bridge-8-5", "sessionId": "session-one",
                     "phase": "example", "moved": 1, "seed": 0}
        self.prefs = {"flutter.lumo_active_profile": json.dumps(self.profile),
                      "flutter.lumo_progress::fictional-unique-child": '{"level":1}',
                      "flutter.lumo_reward_wallet_v1": '{"stars":0}',
                      probe.CHECKPOINT_PREFIX + "::fictional-unique-child": json.dumps(
                          {"version": 1, "sessions": {"bridge:0": self.task}})}

    def test_learning_snapshot_excludes_only_independently_compared_checkpoint(self):
        snapshot = probe.learning_snapshot(self.prefs)
        self.assertEqual(len(snapshot["learning"]), 2)
        self.assertEqual(probe.checkpoint(self.prefs, "bridge"), self.task)
        self.assertIsNone(probe.checkpoint(self.prefs, "words"))
        result = probe.require_preserved(snapshot, copy.deepcopy(snapshot), self.task, copy.deepcopy(self.task))
        self.assertTrue(result["same_task_checkpoint"])

    def test_lost_progress_reward_or_profile_fails(self):
        snapshot = probe.learning_snapshot(self.prefs)
        changed = copy.deepcopy(snapshot)
        changed["learning"]["flutter.lumo_reward_wallet_v1"] = '{"stars":1}'
        missing = copy.deepcopy(snapshot)
        missing["learning"].pop("flutter.lumo_progress::fictional-unique-child")
        other_profile = copy.deepcopy(snapshot)
        other_profile["profile"]["id"] = "other-child"
        for after in (changed, missing, other_profile):
            with self.subTest(after=after), self.assertRaises(RuntimeError):
                probe.require_preserved(snapshot, after)

    def test_task_switch_reset_or_lost_checkpoint_fails(self):
        snapshot = probe.learning_snapshot(self.prefs)
        for after in (None, {**self.task, "moved": 0}, {**self.task, "problemId": "bridge-9-4"},
                      {**self.task, "phase": "build"}, {**self.task, "sessionId": "recreated"}):
            with self.subTest(after=after), self.assertRaises(RuntimeError):
                probe.require_preserved(snapshot, snapshot, self.task, after)

    def test_profile_activity_timestamp_does_not_change_learning_identity(self):
        later = {**self.prefs, "flutter.lumo_active_profile": json.dumps({**self.profile, "lastActiveAt": "later"})}
        self.assertEqual(probe.learning_snapshot(self.prefs), probe.learning_snapshot(later))

    def test_unknown_or_duplicate_checkpoint_fails_closed(self):
        key = probe.CHECKPOINT_PREFIX + "::fictional-unique-child"
        for value in ({"version": 2, "sessions": {}}, {"version": 1, "sessions": []},
                      {"version": 1, "sessions": {"bridge:0": self.task, "bridge:1": self.task}}):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                probe.checkpoint({**self.prefs, key: json.dumps(value)}, "bridge")

    def test_real_or_missing_profile_is_rejected(self):
        for value in ({}, {**self.profile, "name": "Someone else"}, {**self.profile, "id": None}):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                probe.learning_snapshot({**self.prefs, "flutter.lumo_active_profile": json.dumps(value)})


class NativePlaybackTest(unittest.TestCase):
    def events(self, pid=1234, turn=4):
        return (f"I/LumoLearningSpeech( {pid}): started id={turn} profile=lumo-free-supertonic-de-v1\n"
                f"I/LumoLearningSpeech( {pid}): completed id={turn}\n")

    def test_current_process_and_turn_playback(self):
        result = probe.speech_completion(self.events(), 1234)
        self.assertEqual(result["utterance_ids"], [4])
        self.assertFalse(result["audible_quality_verified"])

    def test_old_process_old_turn_and_missing_native_completion_are_rejected(self):
        for log, pid, previous in ((self.events(), 5678, ()), (self.events(), 1234, (4,)),
                                   (self.events().splitlines()[0], 1234, ()),
                                   (self.events().splitlines()[1], 1234, ()),
                                   (self.events(turn=0), 1234, ()),
                                   (self.events().replace("lumo-free-supertonic-de-v1", "unverified-voice"), 1234, ())):
            with self.subTest(log=log, pid=pid, previous=previous), self.assertRaises(RuntimeError):
                probe.speech_completion(log, pid, previous_ids=previous)

    def test_completion_before_start_is_not_playback_evidence(self):
        lines = self.events().splitlines()
        with self.assertRaises(RuntimeError):
            probe.speech_completion("\n".join(reversed(lines)), 1234)

    def test_second_playback_is_new_in_same_native_process(self):
        log = self.events() + self.events(turn=8)
        self.assertEqual(probe.speech_completion(log, 1234, previous_ids=(4,))["utterance_ids"], [8])


class NativePerformanceTest(unittest.TestCase):
    """Synthetic parser fixtures are not substituted for real APK measurements."""

    def packet(self, index=1):
        return {
            "schema": "lumo.learning.perf", "version": 1, "kind": "bridge_ten",
            "platform": "Android", "renderer": "gl_compatibility", "display_driver": "Android",
            "adapter": "parser-test-fixture", "reduced_motion": False,
            "window_index": index, "window_ms": 5000, "sample_count": 250,
            "frame_ms": {"mean": 20, "p50": 18, "p95": 30, "p99": 40, "max": 50,
                         "over_16_7_count": 200, "over_16_7_fraction": .8},
            "process_ms": {"mean": 4, "p95": 7, "max": 12},
            "render": {"draw_calls_mean": 100, "primitives_mean": 18000,
                       "render_objects_mean": 45, "objects_mean": 1000, "nodes_mean": 200},
            "fox_usable_samples": 250, "speech_playing_samples": 100,
            "speech_playing_audible_samples": 90, "effects_active_samples": 240,
            "speech_fox_effects_samples": 80,
        }

    def line(self, packet=None, pid=1234):
        return f"I/godot   ( {pid}): LUMO_LEARNING_PERF {json.dumps(packet or self.packet())}\n"

    def parse(self, *packets):
        return probe.learning_performance_windows("".join(self.line(p) for p in packets), 1234)

    def test_only_current_native_pid_and_exact_marker_supply_observations(self):
        valid = self.packet()
        unrelated = self.line(pid=99) + "I/godot( 1234): 60 FPS configured\n"
        unrelated += self.line().replace("LUMO_LEARNING_PERF", "LUMO_OLD_PERF")
        self.assertEqual(probe.learning_performance_windows(unrelated, 1234), [])
        self.assertEqual(probe.learning_performance_windows(unrelated + self.line(valid), 1234), [valid])
        self.assertEqual(probe.learning_performance_windows(self.line(valid).replace("/godot", "/Godot"), 1234), [valid])

    def test_schema_task_platform_and_adapter_are_bound_to_actual_android_scene(self):
        for key, value in (("schema", "another.perf"), ("version", 2), ("version", True),
                           ("kind", "syllables"), ("platform", "Linux"),
                           ("renderer", ""), ("adapter", None), ("display_driver", "x" * 121),
                           ("reduced_motion", 0), ("declared_fps", 60)):
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                self.parse({**self.packet(), key: value})
        for key in ("adapter", "sample_count", "render", "speech_fox_effects_samples"):
            packet = self.packet()
            del packet[key]
            with self.subTest(missing=key), self.assertRaises(RuntimeError):
                self.parse(packet)

    def test_duplicate_json_and_non_monotone_windows_cannot_reuse_evidence(self):
        duplicate = self.line().replace('"version": 1', '"version": 1, "version": 1')
        with self.assertRaises(RuntimeError):
            probe.learning_performance_windows(duplicate, 1234)
        for second in (1, 0, -1, True, 1.5):
            with self.subTest(second=second), self.assertRaises(RuntimeError):
                self.parse(self.packet(), self.packet(second))
        # Pause/resume may discard a partial window; monotone gaps remain valid.
        self.assertEqual(len(self.parse(self.packet(), self.packet(4))), 2)

    def test_empty_partial_nonfinite_and_inconsistent_sample_time_is_rejected(self):
        for key, value in (("sample_count", 0), ("sample_count", True), ("sample_count", 250.0),
                           ("window_ms", 4999), ("window_ms", 60001),
                           ("window_ms", float("nan")), ("window_ms", 10000)):
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                self.parse({**self.packet(), key: value})
        for group, key, value in (("frame_ms", "mean", float("inf")),
                                  ("frame_ms", "mean", 0), ("frame_ms", "mean", 10),
                                  ("frame_ms", "p50", 45), ("frame_ms", "p99", 51),
                                  ("process_ms", "mean", 15), ("process_ms", "p95", 13),
                                  ("render", "primitives_mean", -1), ("render", "nodes_mean", True)):
            packet = self.packet()
            packet[group][key] = value
            with self.subTest(group=group, key=key, value=value), self.assertRaises(RuntimeError):
                self.parse(packet)

    def test_frame_budget_and_simultaneous_audio_figure_effect_counts_are_consistent(self):
        for key, value in (("over_16_7_count", 251), ("over_16_7_count", True),
                           ("over_16_7_fraction", .2), ("over_16_7_fraction", 1.1)):
            packet = self.packet()
            packet["frame_ms"][key] = value
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                self.parse(packet)
        for key, value in (("fox_usable_samples", 251), ("speech_playing_samples", 50),
                           ("speech_playing_audible_samples", 101), ("effects_active_samples", 70),
                           ("speech_fox_effects_samples", True), ("speech_fox_effects_samples", 91),
                           ("reduced_motion", True)):
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                self.parse({**self.packet(), key: value})

    def test_aggregate_uses_actual_sample_weights_and_does_not_average_percentiles(self):
        second = self.packet(2)
        second.update(sample_count=100, fox_usable_samples=100, effects_active_samples=100,
                      speech_fox_effects_samples=0)
        second["frame_ms"] = {"mean": 50, "p50": 40, "p95": 80, "p99": 100, "max": 120,
                              "over_16_7_count": 100, "over_16_7_fraction": 1}
        summary = probe.learning_performance_summary(self.parse(self.packet(), second), 1234, 15)
        self.assertEqual(summary["capture_status"], "MEASURED")
        self.assertEqual(summary["sample_count"], 350)
        self.assertEqual(summary["measured_window_seconds"], 10)
        self.assertAlmostEqual(summary["mean_process_frame_interval_ms"], 10000 / 350)
        self.assertAlmostEqual(summary["mean_process_frame_rate_hz"], 35)
        self.assertAlmostEqual(summary["process_frames_over_16_7_fraction"], 300 / 350)
        self.assertEqual(summary["worst_window_p95_ms"], 80)
        self.assertEqual(summary["worst_window_p99_ms"], 100)
        self.assertEqual(summary["combined_audio_figure_effect_windows"], [1])
        self.assertFalse(summary["physical_device_60fps_verified"])
        self.assertNotIn("PASS", json.dumps(summary))

    def test_two_full_windows_and_ten_to_sixty_actual_seconds_are_mandatory(self):
        windows = self.parse(self.packet(), self.packet(2))
        for seconds in (0, 9.99, 60.01, float("nan"), float("inf")):
            with self.subTest(seconds=seconds), self.assertRaises(RuntimeError):
                probe.learning_performance_summary(windows, 1234, seconds)
        for incomplete in ([], windows[:1]):
            with self.subTest(incomplete=incomplete), self.assertRaises(RuntimeError):
                probe.learning_performance_summary(incomplete, 1234, 10)
        with self.assertRaises(RuntimeError):
            probe.learning_performance_summary(windows + self.parse(self.packet(3)), 1234, 10)
        self.assertEqual(probe.learning_performance_summary(windows, 1234, 60)["window_count"], 2)

    def test_real_cold_start_can_have_one_slow_sample_and_zero_process_monitors(self):
        cold = self.packet()
        cold.update(window_ms=5311.041, sample_count=1)
        cold["frame_ms"] = {"mean": 5311.041, "p50": 5311.041, "p95": 5311.041,
                            "p99": 5311.041, "max": 5311.041,
                            "over_16_7_count": 1, "over_16_7_fraction": 1}
        cold["process_ms"] = {"mean": 0, "p95": 0, "max": 0}
        cold.update({key: 1 for key in probe.PERFORMANCE_COUNTERS})
        summary = probe.learning_performance_summary(self.parse(cold, self.packet(2)), 1234, 12)
        self.assertEqual(summary["minimum_samples_per_window"], 1)
        self.assertEqual(summary["windows_with_fewer_than_100_samples"], [1])
        self.assertEqual(summary["worst_window_p99_ms"], 5311.041)
        self.assertFalse(summary["physical_device_60fps_verified"])

    def test_separate_nonzero_components_do_not_claim_simultaneous_observation(self):
        packets = [self.packet(1), self.packet(2)]
        for packet in packets:
            packet["speech_fox_effects_samples"] = 0
        with self.assertRaisesRegex(RuntimeError, "together"):
            probe.learning_performance_summary(self.parse(*packets), 1234, 12)
        for packet in packets:
            packet.update(reduced_motion=True, effects_active_samples=0)
        with self.assertRaisesRegex(RuntimeError, "together"):
            probe.learning_performance_summary(self.parse(*packets), 1234, 12)


if __name__ == "__main__":
    unittest.main()
