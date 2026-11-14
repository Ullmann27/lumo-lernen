"""Original PNG/OCR replays; no new Tesseract, Android, resume or gameplay claim."""
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = Path(os.environ.get('LUMO_PAUSE_SOURCE_ROOT', str(ROOT)))
FIXTURES = Path(__file__).with_name('fixtures') / 'kart-continue-08e'


def load_probes():
    for directory in (ROOT / 'tools/android_qa', ROOT / 'scripts/probes', ROOT / '.github/probes'):
        sys.path.insert(0, str(directory))

    def load(name, relative):
        spec = importlib.util.spec_from_file_location(name, SOURCE_ROOT / relative)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    adapter = SimpleNamespace(live_nodes=lambda *_: [], live_tap_label=lambda *_: None)
    with patch.dict(sys.modules, {'pr207_android_ui_probe': adapter}):
        probe = load('continue_caption_probe', '.github/probes/creative_android_probe.py')
        with patch.dict(sys.modules, {'creative_android_probe': probe}):
            tour = load('continue_caption_tour', '.github/probes/modernization_android_tour.py')
    return probe, tour


class StopAfterObservedTouch(Exception):
    """The replay stops at the existing mandatory HUD check, before any game claim."""


class KartContinueCaptionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        provenance = json.loads((FIXTURES / 'provenance.json').read_bytes())
        if (provenance['run_id'] != 43574161418 or provenance['job_id'] != 132384862551
                or provenance['artifact_id'] != 14106471875
                or provenance['archive_sha256'] != 'e044ba0959d2099a5b2b498f1ca31d9f6ac7f9fbad4fabffb2d0d00c92dfc3f3'):
            raise AssertionError('Original pause fixture lost its current source binding')
        for row in provenance['files']:
            data = (FIXTURES / row['file']).read_bytes()
            if len(data) != row['bytes'] or hashlib.sha256(data).hexdigest() != row['sha256']:
                raise AssertionError('Original pause bytes changed')

    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)
        self.probe, self.tour = load_probes()
        self.frames = [(FIXTURES / f'21_continue_touch-{index}.png').read_bytes() for index in range(2)]
        self.ocr = [json.loads((FIXTURES / f'21_continue_touch-{index}-ocr.json').read_bytes()) for index in range(2)]
        self.adb = Mock()
        self.hud = Mock(side_effect=StopAfterObservedTouch())

    def continue_replay(self, transform=None, *, alter_second_png=False, late_second_ocr=False):
        now, count = [0.0], [0]
        paused = {'result_id': 'synthetic-caller-boundary'}
        scoped = SimpleNamespace(expected_kart='gecko_velo', expected_mode='cup', expected_track='sonnenhafen')
        session = SimpleNamespace(in_folder=lambda _out: scoped)

        def capture(out, tag, timeout=None):
            count[0] += 1
            now[0] += 1
            target = out / (tag + '.png')
            target.write_bytes(self.frames[(count[0] - 1) % 2])
            return {'file': target.name}

        def image_lines(out, tag, wanted, *, source_path, timeout, exact, **kwargs):
            rows = copy.deepcopy(self.ocr[(count[0] - 1) % 2])
            if transform is not None:
                rows = transform(rows)
            now[0] += 1
            if count[0] == 2 and alter_second_png:
                source_path.write_bytes(b'changed-after-original-observation')
            if count[0] == 2 and late_second_ocr:
                now[0] += 120
            return rows

        with patch.object(self.tour, 'probe', self.probe), \
                patch.object(self.tour.garage_evidence, 'require_selected_race') as identity, \
                patch.object(self.tour, 'wait_race_hud', self.hud), \
                patch.object(self.probe, 'capture', capture), \
                patch.object(self.probe, 'image_lines', side_effect=image_lines) as reader, \
                patch.object(self.probe.base, 'adb', self.adb), \
                patch.object(self.probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(self.probe.time, 'sleep', side_effect=lambda seconds: now.__setitem__(0, now[0] + seconds)):
            try:
                self.tour._continue_actual_race(self.out, session, paused)
            except StopAfterObservedTouch:
                pass
        return reader, identity

    def test_actual_two_frame_continue_targets_the_independent_caption(self):
        reader, identity = self.continue_replay()
        self.adb.assert_called_once()
        self.assertEqual(self.adb.call_args.args[3:7], ('1262', '408', '1262', '408'))
        self.hud.assert_called_once_with(self.out)
        identity.assert_called_once()
        report = json.loads((self.out / '21_continue_touch-surface-readiness.json').read_bytes())
        self.assertEqual(report['final_observed_bounds'], [1093.0, 388.0, 1430.0, 427.0])
        self.assertEqual(len(report['frames']), 2)
        self.assertTrue(report['exact_caption_required'])
        self.assertTrue(all(call.kwargs.get('all_caption_regions') is True for call in reader.call_args_list))

    def test_instruction_word_without_a_standalone_caption_never_taps(self):
        def only_instruction(rows):
            return [row for row in rows if row['bounds'] != [1093.0, 388.0, 1430.0, 427.0]]
        with self.assertRaises(TimeoutError):
            self.continue_replay(only_instruction)
        self.adb.assert_not_called()
        self.hud.assert_not_called()

    def test_two_distinct_independent_controls_remain_ambiguous(self):
        def duplicate_control(rows):
            rows.append({'text': 'Weiterfahren', 'bounds': [300.0, 388.0, 637.0, 427.0], 'variant': 'contrast'})
            return rows
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous distinct standalone'):
            self.continue_replay(duplicate_control)
        self.adb.assert_not_called()

    def test_duplicate_same_control_and_ocr_order_do_not_change_the_target(self):
        self.continue_replay(lambda rows: list(reversed(rows)))
        self.adb.assert_called_once()
        self.assertEqual(self.adb.call_args.args[3:7], ('1262', '408', '1262', '408'))

    def test_invalid_or_offscreen_matching_region_cannot_be_discarded_silently(self):
        def outside(rows):
            rows.append({'text': 'Weiterfahren', 'bounds': [-3.0, 388.0, 334.0, 427.0], 'variant': 'contrast'})
            return rows
        with self.assertRaisesRegex(RuntimeError, 'Invalid observed standalone-caption bounds'):
            self.continue_replay(outside)
        self.adb.assert_not_called()

    def test_original_png_change_after_ocr_still_prevents_dispatch(self):
        with self.assertRaisesRegex(RuntimeError, 'screenshot changed'):
            self.continue_replay(alter_second_png=True)
        self.adb.assert_not_called()

    def test_late_ocr_does_not_outlive_the_existing_touch_deadline(self):
        with self.assertRaises(TimeoutError):
            self.continue_replay(late_second_ocr=True)
        self.adb.assert_not_called()

    def test_substrings_are_not_promoted_to_the_exact_continue_caption(self):
        def no_exact(rows):
            for row in rows:
                if row['text'].lower() == 'weiterfahren':
                    row['text'] = 'Weiterfahren spaeter'
            return rows
        with self.assertRaises(TimeoutError):
            self.continue_replay(no_exact)
        self.adb.assert_not_called()

    def test_existing_native_callers_keep_their_original_forwarded_contract(self):
        with patch.object(self.probe, 'native_tap') as touch:
            self.probe.native_text(self.out, 'Weiter', 'ordinary', tap=True, exact=True)
        touch.assert_called_once_with(self.out, 'Weiter', 'ordinary', exact=True, orientation='landscape')


if __name__ == '__main__':
    unittest.main()
