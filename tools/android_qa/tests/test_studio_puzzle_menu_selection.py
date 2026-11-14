"""Exercise the actual Puzzle method with bounded synthetic live-UI observations.

This tests selection control flow, not Android or OCR quality. The method body
and its original saved-state condition are compiled unchanged from the probe.
No app state is written; the fake device is confined to these unit cases.
"""
from __future__ import annotations

import ast
import copy
import json
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / ".github/probes/studio_creative_android_probe.py"
CAPTIONS = (
    "Bild: Lumos Mondschloss", "Bild: Candy Cloud Circuit", "Bild: Volcano Night Run",
    "Bild: Leuchtturm-Bucht", "Bild: Blütenwiese",
)


def actual_method():
    tree = ast.parse(SOURCE.read_text())
    helpers = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in {"write", "require"}]
    cls = next(node for node in tree.body if isinstance(node, ast.ClassDef) and node.name == "Tour")
    method = next(node for node in cls.body if isinstance(node, ast.FunctionDef) and node.name == "puzzle")
    isolated_class = copy.deepcopy(cls)
    isolated_class.body = [method]
    isolated = ast.Module(body=helpers + [isolated_class], type_ignores=[])
    namespace = {"Path": Path, "json": json}
    exec(compile(ast.fix_missing_locations(isolated), str(SOURCE), "exec"), namespace)
    return namespace["Tour"].puzzle


class SavedConditionReached(Exception):
    """Stop only after the actual method has accepted its unchanged saved-state condition."""


class ObservedProbe:
    def __init__(self, device):
        self.device = device

    @staticmethod
    def normalized(value):
        return "".join(letter for letter in value.casefold() if letter.isalnum())

    def image_lines(self, out, tag, wanted="", *, source_path=None, timeout=0, exact=False):
        if source_path is None:
            raise AssertionError("Fresh concrete screenshot must be read")
        self.device.observed.append(self.device.motif)
        captions = self.device.caption_override
        if captions is None:
            captions = [CAPTIONS[self.device.motif]]
        # Partial prefix and unrelated toolbar text must not be interpreted as a selected motif.
        return [{"text": text, "bounds": [10, 20, 200, 40]} for text in
                ["Bild:", "Bild ansehen", *captions]]


class FakeDevice:
    def __init__(self, out: Path, motif=3):
        self.out = out
        self.motif, self.count, self.rotation = motif, 12, False
        self.probe = ObservedProbe(self)
        self.observed, self.image_taps, self.confirmations, self.calls = [], [], [], []
        self.caption_override = None
        self.advance = True
        self.saved_override = {}
        self.started = False
        self.counter = 0

    def tag(self, label):
        self.counter += 1
        return f"{self.counter:04d}-{label}"

    def enter(self, game, title):
        self.calls.append(("enter", game, title))

    def shot(self, label):
        if label == "puzzle-observed-board":
            raise SavedConditionReached()
        path = self.out / (self.tag(label) + ".png")
        return path, {"file": path.name, "sha256": "synthetic-not-a-real-frame"}

    def observe(self, label, exact=False):
        if not exact or label != CAPTIONS[self.motif]:
            raise AssertionError("Final confirmation must be the currently visible exact caption")
        self.confirmations.append(label)
        return {"text": label, "capture": {"scope": "synthetic"}, "stable": {"stable_observed_target": True}}

    def native(self, label, tap=False, exact=False):
        self.calls.append(("native", label, tap, exact))
        if label.endswith(" Teile"):
            if int(label.split()[0]) != self.count:
                raise AssertionError("Unexpected count-state assumption")
            if tap:
                counts = (6, 12, 24, 48, 96)
                self.count = counts[(counts.index(self.count) + 1) % len(counts)]
        elif label.startswith("Bild:") and tap:
            # The original broken method is deliberately executable here: its one
            # broad selector touch really advances default3 to4 before its condition fails.
            if label != "Bild:" and (not exact or label != CAPTIONS[self.motif]):
                raise AssertionError("A real image tap must target the exact observed caption")
            self.image_taps.append({"label": label, "before": self.motif,
                                    "observed_before": bool(self.observed and self.observed[-1] == self.motif)})
            if self.advance:
                self.motif = (self.motif + 1) % len(CAPTIONS)
        elif label.startswith("Modus:"):
            current = "Modus: Drehpuzzle" if self.rotation else "Modus: Bilderpuzzle"
            if label != current or not tap:
                raise AssertionError("Mode-state check changed")
            self.rotation = not self.rotation
        elif label == "Neues Puzzle beginnen":
            if not (tap and exact):
                raise AssertionError("Original start guard changed")
            self.started = True

    def pause_save(self, game):
        if game != "puzzle" or not self.started:
            raise AssertionError("Save was read before actual menu start")
        return {"count": self.count, "motif": self.motif, "rotation_enabled": self.rotation,
                **self.saved_override}


class PuzzleSelectionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.method = staticmethod(actual_method())

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-puzzle-observation-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_actual_default_three_reaches_motif_one_through_observed_titles(self):
        device = FakeDevice(self.root, 3)
        with self.assertRaises(SavedConditionReached):
            self.method(device)
        self.assertEqual([x["label"] for x in device.image_taps], [CAPTIONS[3], CAPTIONS[4], CAPTIONS[0]])
        self.assertTrue(all(x["observed_before"] for x in device.image_taps))
        self.assertEqual(device.confirmations, [CAPTIONS[1]])
        self.assertEqual((device.count, device.motif, device.rotation), (6, 1, True))

    def test_every_actual_start_caption_is_observed_without_fixed_tap_count(self):
        for start, count in [(0, 1), (1, 0), (2, 4), (3, 3), (4, 2)]:
            with self.subTest(start=start):
                device = FakeDevice(self.root / str(start), start)
                with self.assertRaises(SavedConditionReached):
                    self.method(device)
                self.assertEqual(len(device.image_taps), count)
                self.assertTrue(all(x["observed_before"] for x in device.image_taps))
                self.assertEqual(device.confirmations, [CAPTIONS[1]])

    def test_missing_unknown_and_ambiguous_caption_never_send_a_selector_touch(self):
        for captions in ([], ["Bild: Unbekannt"], [CAPTIONS[3], CAPTIONS[4]]):
            with self.subTest(captions=captions):
                device = FakeDevice(self.root)
                device.caption_override = captions
                with self.assertRaises(RuntimeError):
                    self.method(device)
                self.assertFalse(device.image_taps)
                self.assertFalse(device.started)

    def test_unchanged_caption_after_a_touch_stops_without_blind_extra_taps(self):
        device = FakeDevice(self.root)
        device.advance = False
        with self.assertRaises(RuntimeError):
            self.method(device)
        self.assertEqual(len(device.image_taps), 1)
        self.assertFalse(device.started)

    def test_saved_count_motif_and_rotation_conditions_are_still_mandatory(self):
        for override in ({"count": 12}, {"motif": 4}, {"rotation_enabled": False}):
            with self.subTest(override=override):
                device = FakeDevice(self.root)
                device.saved_override = override
                with self.assertRaisesRegex(RuntimeError, "did not persist six-piece motif1 rotation mode"):
                    self.method(device)

    def test_final_target_confirmation_must_precede_start(self):
        device = FakeDevice(self.root, 1)
        def refuse_confirmation(label, exact=False):
            raise RuntimeError("Actual target disappeared before start")
        device.observe = refuse_confirmation
        with self.assertRaisesRegex(RuntimeError, "target disappeared"):
            self.method(device)
        self.assertFalse(device.started)


if __name__ == "__main__":
    unittest.main()
