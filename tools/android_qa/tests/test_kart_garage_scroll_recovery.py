"""Real failed Android frames must permit a safe scroll, never a guessed tap.

The PNGs and OCR JSON are unchanged observations from run43594006354, attempt1.
Main and Update have different horizontal insets. Main's post-scroll frame
clips both nearby captions; Update visibly shows Boru Rally but its original
OCR read only Boru. Neither observation authorizes a vehicle-selection tap.
These regressions exercise probe decisions, not Android/device acceptance.
"""
from __future__ import annotations

import copy
from contextlib import ExitStack, contextmanager
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kart_garage_evidence as evidence
from native_surface_readiness import inspect_surface
from test_modernization_tour_identity import TOUR_MODULE as tour


FIXTURES = Path(__file__).parent / 'fixtures/kart-scroll-6f42'
# Independently annotated from the original full-resolution PNGs: content
# begins below the top clip and ends above the fixed workshop button. These
# are assertions about these four archived frames, never production inputs.
VISIBLE_LIST = {'main': (42, 416, 750, 665),
                'update': (178, 416, 845, 665)}
# Frame1 in each original readiness journal records SWIPE_SENT at these
# coordinates. Frame0 records the first (slightly different in Main) proposal.
ORIGINAL_SENT_DRAG = {'main': (374, 486, 374, 351),
                      'update': (510, 486, 510, 351)}
VEHICLE_NAMES = {'comet', 'geckovelo', 'borurally', 'glider', 'nalacomet', 'noatide'}


def original_observation(layout: str, index: int):
    manifest = json.loads((FIXTURES / 'source.json').read_text())
    case = next(item for item in manifest['cases'] if item['name'] == layout)
    snapshot = next(item for item in case['snapshots'] if item['frame_index'] == index)
    for item in snapshot['files']:
        raw = (FIXTURES / item['path']).read_bytes()
        if len(raw) != item['bytes'] or hashlib.sha256(raw).hexdigest() != item['sha256']:
            raise AssertionError('Original regression evidence changed: ' + item['path'])
    frame = copy.deepcopy(snapshot['original_frame'])
    source = FIXTURES / layout / frame['source']
    lines = json.loads((source.with_name(source.stem + '-ocr.json')).read_text())
    return frame, lines, source


def gesture_is_inside(gesture, rectangle):
    left, top, right, bottom = rectangle
    x0, y0, x1, y1 = gesture
    return left < x0 < right and left < x1 < right and top < y0 < bottom and top < y1 < bottom


def empty_word_observation(out, tag, lines):
    """Explicit synthetic empty TSVs for the pixel-only replay branch.

    The PNGs and line JSON remain original. These header-only word streams
    deliberately contain no inferred words; the separate 3d91 suite replays
    actual Boru TSV bytes through the unchanged word parser.
    """
    fields = ['level', 'page_num', 'block_num', 'par_num', 'line_num', 'word_num',
              'left', 'top', 'width', 'height', 'conf', 'text']
    for variant in dict.fromkeys(row['variant'] for row in lines):
        (out / f'{tag}-ocr-{variant}.tsv').write_text('\t'.join(fields) + '\n')


class OriginalGarageViewportTests(unittest.TestCase):
    def assert_safe_scroll(self, proof, layout):
        gesture = proof['gesture']
        self.assertTrue(gesture_is_inside(gesture, VISIBLE_LIST[layout]),
                        f'{layout}: {gesture} leaves the actual clipped list')
        self.assertTrue(gesture_is_inside(gesture, proof['viewport_bounds']))
        self.assertEqual(gesture[0], gesture[2])
        self.assertNotEqual(gesture[1], gesture[3])
        self.assertLess(abs(gesture[1] - gesture[3]),
                        (VISIBLE_LIST[layout][3] - VISIBLE_LIST[layout][1]) / 2)

    def test_both_original_layouts_keep_every_scroll_point_inside_the_real_clip(self):
        for layout in VISIBLE_LIST:
            for index in (0, 2):
                with self.subTest(layout=layout, original_frame=index):
                    frame, lines, source = original_observation(layout, index)
                    proof = evidence.stage_garage_scroll_observation(frame, lines, source=source)
                    self.assert_safe_scroll(proof, layout)

    def test_actual_old_drag_crosses_the_clip_even_though_tabs_and_footer_enclose_it(self):
        manifest = json.loads((FIXTURES / 'source.json').read_text())
        for case in manifest['cases']:
            frame = case['snapshots'][0]['original_frame']
            old = frame['missing_caption_recovery']
            with self.subTest(layout=case['name']):
                sent = ORIGINAL_SENT_DRAG[case['name']]
                self.assertLess(old['header_bottom'], sent[3])
                self.assertLess(sent[1], old['footer_top'])
                self.assertFalse(gesture_is_inside(sent, VISIBLE_LIST[case['name']]))
                current, lines, source = original_observation(case['name'], 0)
                proof = evidence.stage_garage_scroll_observation(current, lines, source=source)
                self.assert_safe_scroll(proof, case['name'])

    def test_both_actual_anchorless_frames_produce_scroll_evidence_without_a_card_tap(self):
        for layout in VISIBLE_LIST:
            frame, lines, source = original_observation(layout, 2)
            with self.subTest(layout=layout), patch.object(tour.base, 'adb') as adb:
                self.assertFalse([line for line in lines
                                  if evidence.normalize(line['text']) in VEHICLE_NAMES])
                proof = evidence.stage_garage_scroll_observation(frame, lines, source=source)
                self.assert_safe_scroll(proof, layout)
                adb.assert_not_called()
                self.assertNotEqual(proof.get('status'), 'TOUCH_SENT')

    def test_missing_or_foreign_surface_binding_cannot_authorize_scroll(self):
        frame, lines, source = original_observation('main', 0)
        _, _, foreign = original_observation('update', 0)
        cases = [
            (dict(frame, acceptable_for_target_sampling=False), source),
            (dict(frame, pixels=[1080, 2400]), source),
            (dict(frame, pixels=[2399, 1080]), source),
            (dict(frame, source_sha256='0' * 64), source),
            (dict(frame, source_bytes=frame['source_bytes'] + 1), source),
            (frame, foreign),
        ]
        for current, path in cases:
            with self.subTest(frame=current, source=path), self.assertRaises((RuntimeError, ValueError)):
                evidence.stage_garage_scroll_observation(current, lines, source=path)

    def test_actual_current_menu_context_is_required_even_when_scroll_pixels_exist(self):
        frame, lines, source = original_observation('main', 2)
        required = ({'karts'}, {'lackteileeffekte'}, {'kartmenu', 'menu', 'start', 'rennenstarten'})
        for missing in required:
            filtered = [line for line in lines if evidence.normalize(line['text']) not in missing]
            with self.subTest(missing=missing), self.assertRaises((RuntimeError, ValueError)):
                evidence.stage_garage_scroll_observation(frame, filtered, source=source)

    def test_missing_or_two_current_scrollbar_tracks_do_not_authorize_a_drag(self):
        _, lines, original = original_observation('main', 0)
        with tempfile.TemporaryDirectory() as folder:
            for change in ('erase', 'duplicate'):
                with self.subTest(pixel_change=change), Image.open(original) as image:
                    changed = image.convert('RGB')
                    # This is the visible rail strip in the original image,
                    # not a call to the detector being tested. The original
                    # fixture remains untouched; these are negative inputs.
                    strip = (749, 407, 766, 668)
                    if change == 'erase':
                        changed.paste((0, 0, 0), strip)
                    else:
                        changed.paste(changed.crop(strip), (709, 407))
                    source = Path(folder) / (change + '.png')
                    changed.save(source)
                    frame = inspect_surface(source)
                    self.assertTrue(frame['acceptable_for_target_sampling'])
                    with self.assertRaises(RuntimeError):
                        evidence.stage_garage_scroll_observation(frame, lines, source=source)

    def test_correct_dimensions_and_file_hash_do_not_make_a_jpeg_a_capture_png(self):
        _, lines, original = original_observation('main', 0)
        with tempfile.TemporaryDirectory() as folder, Image.open(original) as image:
            source = Path(folder) / 'non-png-capture.png'
            image.convert('RGB').save(source, format='JPEG')
            frame = inspect_surface(source)
            with self.assertRaises(RuntimeError):
                evidence.stage_garage_scroll_observation(frame, lines, source=source)


def scroll_recovery_from_validated_observations():
    """Retain the real current-frame analysis before the private decision step."""
    decide = tour._stage_kart_scroll_recovery()

    def observe_then_decide(frame, lines, source, *, deadline, previous_missing_frame):
        current = tour.garage_evidence.stage_garage_scroll_observation(
            frame, lines, source=source)
        return decide(frame, lines, source, deadline=deadline,
                      previous_missing_frame=previous_missing_frame, current=current)

    return observe_then_decide


class ObservedGarageScrollBoundaryTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)

    def observation(self, layout, index, name):
        frame, lines, original = original_observation(layout, index)
        source = self.out / (name + '.png')
        shutil.copyfile(original, source)
        frame['source'] = source.name
        empty_word_observation(self.out, source.stem, lines)
        return frame, lines, source

    def test_a_new_horizontal_layout_requires_its_own_second_current_observation(self):
        main, main_lines, main_source = self.observation('main', 2, 'old-layout')
        updated, updated_lines, updated_source = self.observation('update', 2, 'new-layout-first')
        current, current_lines, current_source = self.observation('update', 2, 'new-layout-second')
        callback = scroll_recovery_from_validated_observations()
        with patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'monotonic', return_value=0):
            first = callback(main, main_lines, main_source, deadline=10,
                             previous_missing_frame=None)
            self.assertEqual(first['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
            changed = callback(updated, updated_lines, updated_source, deadline=10,
                               previous_missing_frame=main)
            self.assertEqual(changed['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
            adb.assert_not_called()
            current = callback(current, current_lines, current_source, deadline=10,
                               previous_missing_frame=updated)
        self.assertEqual(current['status'], 'SWIPE_SENT')
        adb.assert_called_once()
        gesture = list(map(int, adb.call_args.args[3:7]))
        self.assertTrue(gesture_is_inside(gesture, VISIBLE_LIST['update']))

    def test_a_missing_intervening_frame_cannot_reuse_the_prior_scroll_observation(self):
        frame, lines, source = self.observation('main', 2, 'before-gap')
        after, after_lines, after_source = self.observation('main', 2, 'after-gap')
        last, last_lines, last_source = self.observation('main', 2, 'current-pair')
        callback = scroll_recovery_from_validated_observations()
        with patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'monotonic', return_value=0):
            callback(frame, lines, source, deadline=10, previous_missing_frame=None)
            after_gap = callback(after, after_lines, after_source, deadline=10, previous_missing_frame=None)
            self.assertEqual(after_gap['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
            adb.assert_not_called()
            ready = callback(last, last_lines, last_source, deadline=10, previous_missing_frame=after)
        self.assertEqual(ready['status'], 'SWIPE_SENT')
        adb.assert_called_once()

    def test_replaced_previous_png_invalidates_the_pair_even_when_current_png_is_unchanged(self):
        frame, lines, original = original_observation('main', 2)
        with tempfile.TemporaryDirectory() as folder:
            previous = Path(folder) / original.name
            current = Path(folder) / 'current.png'
            previous.write_bytes(original.read_bytes())
            current.write_bytes(original.read_bytes())
            current_frame = dict(frame, source=current.name)
            empty_word_observation(Path(folder), previous.stem, lines)
            empty_word_observation(Path(folder), current.stem, lines)
            callback = scroll_recovery_from_validated_observations()
            with patch.object(tour.base, 'adb') as adb, \
                    patch.object(tour.time, 'monotonic', return_value=0):
                callback(frame, lines, previous, deadline=10, previous_missing_frame=None)
                previous.write_bytes(b'replaced previous observation')
                with self.assertRaises(RuntimeError):
                    callback(current_frame, lines, current, deadline=10, previous_missing_frame=frame)
            adb.assert_not_called()

    def test_expired_deadline_refuses_an_otherwise_stable_real_scroll(self):
        frame, lines, source = self.observation('main', 2, 'first')
        current, current_lines, current_source = self.observation('main', 2, 'second')
        callback = scroll_recovery_from_validated_observations()
        with patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'monotonic', return_value=0):
            callback(frame, lines, source, deadline=10, previous_missing_frame=None)
            with self.assertRaises((RuntimeError, TimeoutError)):
                callback(current, current_lines, current_source, deadline=0, previous_missing_frame=frame)
        adb.assert_not_called()

    def test_deadline_expiring_during_real_pixel_analysis_prevents_input(self):
        frame, lines, source = self.observation('main', 2, 'first')
        current, current_lines, current_source = self.observation('main', 2, 'second')
        callback = scroll_recovery_from_validated_observations()
        clock = [0.0]
        original = tour.garage_evidence.stage_garage_scroll_observation

        def analyze_then_expire(*args, **kwargs):
            result = original(*args, **kwargs)
            clock[0] = 11.0
            return result

        with patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'monotonic', side_effect=lambda: clock[0]):
            callback(frame, lines, source, deadline=10, previous_missing_frame=None)
            with patch.object(tour.garage_evidence, 'stage_garage_scroll_observation', side_effect=analyze_then_expire), \
                    self.assertRaises((RuntimeError, TimeoutError)):
                callback(current, current_lines, current_source, deadline=10, previous_missing_frame=frame)
        adb.assert_not_called()


    def test_a_validated_list_from_another_current_png_cannot_authorize_recovery(self):
        main, lines, source = self.observation('main', 2, 'first-layout')
        changed, _, changed_source = self.observation('update', 2, 'different-layout')
        proof = tour.garage_evidence.stage_garage_scroll_observation(
            main, lines, source=source)
        decide = tour._stage_kart_scroll_recovery()
        with patch.object(tour.base, 'adb') as adb, \
                self.assertRaisesRegex(RuntimeError, 'different current screenshot'):
            decide(changed, lines, changed_source, deadline=10,
                   previous_missing_frame=None, current=proof)
        adb.assert_not_called()


    def test_cached_current_frame_keeps_the_original_boru_words_and_pair(self):
        # Two uniquely named copies are controlled replay observations, not
        # a newly observed Android return, card selection or race.
        originals = Path(__file__).parent / 'fixtures/kart-scroll-3d91'
        original_tag = '21_stage_select_gecko_velo-2'
        original_frame = json.loads((originals /
            '21_stage_select_gecko_velo-surface-readiness.json').read_text())['frames'][2]
        lines = json.loads((originals / (original_tag + '-ocr.json')).read_text())
        decide = tour._stage_kart_scroll_recovery()
        analyze = tour.garage_evidence.stage_garage_scroll_observation
        previous = None
        with patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'monotonic', return_value=0), \
                patch.object(tour.garage_evidence, 'stage_garage_scroll_observation',
                             wraps=analyze) as analyses:
            for number in (1, 2):
                tag = f'cached-boru-original-{number}'
                for original in originals.glob(original_tag + '*'):
                    shutil.copyfile(original, self.out / (tag + original.name[len(original_tag):]))
                source = self.out / (tag + '.png')
                frame = dict(original_frame, source=source.name)
                current = tour.garage_evidence.stage_garage_scroll_observation(
                    frame, lines, source=source)
                self.assertEqual(current['visible_cards'], [])
                result = decide(frame, lines, source, deadline=10,
                                previous_missing_frame=previous, current=current)
                self.assertNotIn('caption_source', current)
                self.assertEqual(result['caption_source'], 'original_tsv_word_sequences')
                self.assertEqual(result['card']['text'], 'Boru Rally')
                self.assertEqual(result['card']['bounds'], [314.5, 593.0, 511.0, 629.0])
                self.assertEqual(len(result['ocr_sources']), 7)
                self.assertEqual(result['status'],
                    'WAITING_FOR_SECOND_LIST_FRAME' if number == 1 else 'SWIPE_SENT')
                if number == 1:
                    adb.assert_not_called()
                previous = frame
            # Each frame has one complete line analysis and the retained,
            # distinct word-enriched analysis; no duplicate initial analysis.
            self.assertEqual(analyses.call_count, 4)
            adb.assert_called_once_with('shell', 'input', 'swipe',
                *map(str, result['gesture']), '650', timeout=10)
        self.assertEqual(result['direction'], 'backward')


class GarageExactTargetTests(unittest.TestCase):
    def current(self, layout='main', index=0):
        _, lines, source = original_observation(layout, index)
        frame = inspect_surface(source)
        region = evidence.stage_garage_scroll_observation(frame, lines, source=source, kart='comet')
        return frame, lines, region['viewport_bounds']

    def test_multiple_original_ocr_variants_of_one_complete_card_are_one_target(self):
        for layout in VISIBLE_LIST:
            with self.subTest(layout=layout):
                frame, lines, viewport = self.current(layout)
                target = evidence.stage_kart_target_observation(frame, lines, 'comet', viewport)
                self.assertIsNotNone(target)
                self.assertEqual(evidence.normalize(target['target']['text']), 'comet')
                left, top, right, bottom = target['target']['bounds']
                self.assertTrue(gesture_is_inside((left, top, right, bottom), VISIBLE_LIST[layout]))

    def test_actual_anchorless_and_partial_ocr_never_name_the_selected_vehicle(self):
        for layout in VISIBLE_LIST:
            with self.subTest(layout=layout):
                frame, lines, viewport = self.current(layout, 2)
                for kart in ('comet', 'gecko_velo'):
                    self.assertIsNone(evidence.stage_kart_target_observation(frame, lines, kart, viewport))

    def test_a_caption_outside_or_straddling_the_actual_clip_is_not_a_target(self):
        frame, lines, viewport = self.current()
        for bounds in ([314, 400, 434, 428], [314, 650, 434, 678],
                       [1400, 472, 1520, 499], [20, 472, 50, 499]):
            observed = copy.deepcopy(lines)
            for row in observed:
                if evidence.normalize(row['text']) == 'comet':
                    row['bounds'] = bounds
            with self.subTest(bounds=bounds):
                self.assertIsNone(evidence.stage_kart_target_observation(frame, observed, 'comet', viewport))

    def test_two_distinct_exact_card_regions_are_not_reduced_to_the_first_match(self):
        frame, lines, viewport = self.current()
        second = {'text': 'Comet', 'bounds': [314, 572, 434, 599], 'variant': 'raw'}
        with self.assertRaises(RuntimeError):
            evidence.stage_kart_target_observation(frame, lines + [second], 'comet', viewport)

    def test_prefix_suffix_and_partial_captions_do_not_authorize_a_selection(self):
        frame, lines, viewport = self.current()
        for text in ('Come', 'Comet Plus', 'Gecko', 'Gecko Velo Extra'):
            observed = copy.deepcopy(lines)
            for row in observed:
                if evidence.normalize(row['text']) == 'comet':
                    row['text'] = text
            with self.subTest(text=text):
                self.assertIsNone(evidence.stage_kart_target_observation(frame, observed, 'comet', viewport))
                self.assertIsNone(evidence.stage_kart_target_observation(frame, observed, 'gecko_velo', viewport))


class GarageObservationReplay:
    """Feed original observations through the real caller and record its inputs.

    The supplied sequence tests how fresh observations authorize an input. It
    does not predict Android inertia or claim a newly captured successful race.
    Only capture, OCR, ADB and elapsed wall time are replaced; pixel analysis,
    viewport guards, target stability and the real selection caller run.
    """
    def __init__(self, out, observations, *, capture_seconds=.25, ocr_seconds=.5):
        self.out = out
        self.observations = observations
        self.capture_seconds = capture_seconds
        self.ocr_seconds = ocr_seconds
        self.now = 0.0
        self.capture_count = 0
        self.ocr_count = 0
        self.inputs = []
        self.lines = []
        self.after_ocr = None
        self.ocr_calls = []

    def capture(self, _out, name, **_kwargs):
        position = min(self.capture_count, len(self.observations) - 1)
        layout, index = self.observations[position]
        _, self.lines, source = original_observation(layout, index)
        path = self.out / (name + '.png')
        shutil.copyfile(source, path)
        self.capture_count += 1
        self.now += self.capture_seconds
        if self.capture_count > 20:
            raise AssertionError('Probe failed to respect its bounded observation loop')
        return {'file': path.name}

    def ocr(self, *_args, source_path, **_kwargs):
        self.ocr_count += 1
        self.now += self.ocr_seconds
        self.ocr_calls.append({'args': _args, 'kwargs': dict(_kwargs)})
        if self.after_ocr is not None:
            self.after_ocr(source_path)
        observed = copy.deepcopy(self.lines)
        empty_word_observation(self.out, source_path.stem, observed)
        wanted = _args[2] if len(_args) > 2 else ''
        if wanted and not _kwargs.get('all_caption_regions'):
            # Model the real reader's early exit with the original rows:
            # Comet appears in contrast, while the workshop is read later.
            seen = []
            for variant in dict.fromkeys(row['variant'] for row in observed):
                seen.extend(row for row in observed if row['variant'] == variant)
                if any(tour.probe.normalized(row['text']) == wanted for row in seen):
                    return seen
        return observed

    def adb(self, *args, **kwargs):
        self.inputs.append({'args': args, 'kwargs': kwargs, 'after_capture': self.capture_count})
        return ''

    def sleep(self, seconds):
        self.now += seconds

    @contextmanager
    def installed(self):
        with ExitStack() as stack:
            stack.enter_context(patch.object(tour.probe, 'capture', side_effect=self.capture))
            stack.enter_context(patch.object(tour.probe, 'image_lines', side_effect=self.ocr))
            stack.enter_context(patch.object(tour.base, 'adb', side_effect=self.adb))
            stack.enter_context(patch.object(tour.time, 'monotonic', side_effect=lambda: self.now))
            stack.enter_context(patch.object(tour.time, 'sleep', side_effect=self.sleep))
            yield


class GarageSelectionObservationTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)

    def test_comet_selection_reads_later_original_variants_that_contain_the_workshop(self):
        for layout in VISIBLE_LIST:
            with self.subTest(layout=layout):
                _, lines, _ = original_observation(layout, 0)
                contrast = [row for row in lines if row['variant'] == 'contrast']
                self.assertTrue(any(evidence.normalize(row['text']) == 'comet' for row in contrast))
                self.assertFalse(any(evidence.normalize(row['text']) == 'lackteileeffekte'
                                     for row in contrast))
                self.assertTrue(any(evidence.normalize(row['text']) == 'lackteileeffekte'
                                    for row in lines))
                replay = GarageObservationReplay(self.out, [(layout, 0), (layout, 0)])
                with replay.installed():
                    tour._select_stage_kart(self.out, 'comet')
                self.assertEqual(replay.capture_count, 2)
                self.assertEqual(len(replay.inputs), 1)
                self.assertTrue(all(call['kwargs'].get('all_caption_regions') is True
                                    and call['kwargs'].get('exact') is True
                                    for call in replay.ocr_calls))

    def test_anchorless_view_can_scroll_but_only_two_new_complete_frames_allow_the_tap(self):
        for layout in VISIBLE_LIST:
            with self.subTest(layout=layout):
                replay = GarageObservationReplay(self.out, [(layout, 2), (layout, 2),
                                                            (layout, 0), (layout, 0)])
                with replay.installed():
                    result = tour._select_stage_kart(self.out, 'comet')
                self.assertEqual(replay.capture_count, 4)
                self.assertEqual(len(replay.inputs), 2)
                scroll, tap = replay.inputs
                self.assertEqual([scroll['after_capture'], tap['after_capture']], [2, 4])
                self.assertTrue(gesture_is_inside(list(map(int, scroll['args'][3:7])),
                                                 VISIBLE_LIST[layout]))
                self.assertEqual(tap['args'][:3], ('shell', 'input', 'swipe'))
                self.assertEqual(tap['args'][3:5], tap['args'][5:7])
                self.assertEqual(tap['args'][7], '120')
                journal = json.loads((self.out / result['readiness']).read_text())
                self.assertEqual(journal['status'], 'TOUCH_SENT')
                self.assertEqual([frame['target']['stable_observed_target']
                                  for frame in journal['frames'] if 'target' in frame], [False, True])

    def test_only_real_inputs_settle_and_each_fresh_frame_has_one_full_list_analysis(self):
        # Controlled producer/clock replay, not measured Android throughput.
        # Both the normal budget and a deliberately tight budget must still
        # require four fresh frames: two list observations, then two targets.
        for timeout, final_pause in ((150, 1.5), (5, .5)):
            with self.subTest(timeout=timeout):
                replay = GarageObservationReplay(self.out, [('main', 2), ('main', 2),
                                                            ('main', 0), ('main', 0)])
                pauses = []

                def settle(seconds):
                    pauses.append((replay.capture_count, len(replay.inputs), seconds))
                    replay.sleep(seconds)

                analyze = tour.garage_evidence.stage_garage_scroll_observation
                with replay.installed(), \
                        patch.object(tour.garage_evidence, 'stage_garage_scroll_observation',
                                     wraps=analyze) as analyses, \
                        patch.object(tour.time, 'sleep', side_effect=settle):
                    result = tour._select_stage_kart(self.out, 'comet', timeout=timeout)
                self.assertEqual(replay.capture_count, 4)
                self.assertEqual(replay.ocr_count, 4)
                self.assertEqual(analyses.call_count, 4)
                sources = [call.kwargs['source'].name for call in analyses.call_args_list]
                self.assertEqual(len(set(sources)), 4)
                self.assertEqual([event['after_capture'] for event in replay.inputs], [2, 4])
                self.assertEqual([event['args'][7] for event in replay.inputs], ['650', '120'])
                self.assertEqual(pauses, [(2, 1, 1.5), (4, 2, final_pause)])
                self.assertTrue(all(call['kwargs'].get('all_caption_regions') is True
                                    and call['kwargs'].get('exact') is True
                                    for call in replay.ocr_calls))
                journal = json.loads((self.out / result['readiness']).read_text())
                self.assertEqual(journal['status'], 'TOUCH_SENT')
                self.assertEqual(journal['frames'][0]['missing_caption_recovery']['status'],
                                 'WAITING_FOR_SECOND_LIST_FRAME')
                self.assertEqual(journal['frames'][1]['missing_caption_recovery']['status'],
                                 'SWIPE_SENT')
                self.assertEqual([frame['target']['stable_observed_target']
                                  for frame in journal['frames'] if 'target' in frame], [False, True])

    def test_incomplete_surfaces_keep_the_bounded_pause_without_ocr_or_input(self):
        for pixels, color in (((2400, 1080), (0, 0, 0)),
                              ((1080, 2400), (30, 50, 70))):
            with self.subTest(pixels=pixels):
                replay = GarageObservationReplay(self.out, [('main', 0)] * 3)
                capture = replay.capture
                pauses = []

                def incomplete_first(*args, **kwargs):
                    snapshot = capture(*args, **kwargs)
                    if replay.capture_count == 1:
                        # Deliberate negative input in the temporary replay,
                        # never a replacement for an archived original PNG.
                        with Image.new('RGB', pixels, color) as incomplete:
                            incomplete.save(self.out / snapshot['file'])
                    return snapshot

                def settle(seconds):
                    pauses.append((replay.capture_count, len(replay.inputs), seconds))
                    replay.sleep(seconds)

                replay.capture = incomplete_first
                with replay.installed(), patch.object(tour.time, 'sleep', side_effect=settle):
                    result = tour._select_stage_kart(self.out, 'comet')
                self.assertEqual(replay.capture_count, 3)
                self.assertEqual(replay.ocr_count, 2)
                self.assertEqual([event['after_capture'] for event in replay.inputs], [3])
                self.assertEqual(pauses, [(1, 0, 1.5), (3, 1, 1.5)])
                journal = json.loads((self.out / result['readiness']).read_text())
                self.assertFalse(journal['frames'][0]['acceptable_for_target_sampling'])
                self.assertNotIn('kart_list', journal['frames'][0])
                self.assertEqual([frame['target']['stable_observed_target']
                                  for frame in journal['frames'] if 'target' in frame], [False, True])

    def test_png_change_after_list_analysis_still_prevents_the_real_scroll(self):
        replay = GarageObservationReplay(self.out, [('main', 2), ('main', 2)])
        _, _, replacement = original_observation('update', 2)
        analyze = tour.garage_evidence.stage_garage_scroll_observation

        def analyze_then_replace(*args, **kwargs):
            result = analyze(*args, **kwargs)
            if replay.capture_count == 2:
                shutil.copyfile(replacement, kwargs['source'])
            return result

        with replay.installed(), \
                patch.object(tour.garage_evidence, 'stage_garage_scroll_observation',
                             side_effect=analyze_then_replace), \
                self.assertRaisesRegex(RuntimeError, 'changed before gesture'):
            tour._select_stage_kart(self.out, 'gecko_velo')
        self.assertFalse(replay.inputs)
        journal = json.loads((self.out / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
        self.assertEqual(journal['status'], 'FAIL')

    def test_faster_observation_does_not_allow_a_sixth_list_gesture_or_a_guessed_tap(self):
        replay = GarageObservationReplay(self.out, [('main', 2)])
        with replay.installed(), \
                self.assertRaisesRegex(RuntimeError, 'after five observed list gestures'):
            tour._select_stage_kart(self.out, 'gecko_velo')
        self.assertEqual(replay.capture_count, 12)
        self.assertEqual(len(replay.inputs), 5)
        self.assertTrue(all(event['args'][7] == '650' for event in replay.inputs))
        self.assertTrue(all(event['args'][3:5] != event['args'][5:7]
                            for event in replay.inputs))
        journal = json.loads((self.out / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
        self.assertEqual(journal['status'], 'FAIL')
        self.assertNotIn('touch', journal)

    def test_one_old_complete_frame_and_one_new_frame_do_not_form_a_stable_target_pair(self):
        replay = GarageObservationReplay(self.out, [('main', 0), ('main', 2),
                                                    ('main', 0), ('main', 0)])
        with replay.installed():
            tour._select_stage_kart(self.out, 'comet')
        self.assertEqual(replay.capture_count, 4)
        self.assertEqual(len(replay.inputs), 1)
        self.assertEqual(replay.inputs[0]['after_capture'], 4)

    def test_actual_missing_and_partial_captions_never_become_a_vehicle_tap(self):
        for layout in VISIBLE_LIST:
            with self.subTest(layout=layout):
                replay = GarageObservationReplay(self.out, [(layout, 2)],
                                                 capture_seconds=20, ocr_seconds=10)
                with replay.installed(), self.assertRaises((RuntimeError, TimeoutError)):
                    tour._select_stage_kart(self.out, 'gecko_velo')
                for event in replay.inputs:
                    self.assertNotEqual(event['args'][3:5], event['args'][5:7],
                                        'A partial/missing actual caption authorized a tap')
                journal = json.loads((self.out / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
                self.assertEqual(journal['status'], 'FAIL')
                self.assertNotIn('touch', journal)

    def test_current_png_replacement_after_ocr_cannot_authorize_scroll_or_tap(self):
        _, _, replacement = original_observation('update', 0)
        for index, label in ((2, 'gecko_velo'), (0, 'comet')):
            with self.subTest(original_frame=index):
                replay = GarageObservationReplay(self.out, [('main', index)])

                def replace(path):
                    if replay.capture_count == 2:
                        shutil.copyfile(replacement, path)

                replay.after_ocr = replace
                with replay.installed(), self.assertRaises((RuntimeError, ValueError)):
                    tour._select_stage_kart(self.out, label)
                self.assertFalse(replay.inputs)

    def test_capture_or_ocr_crossing_the_selection_deadline_cannot_send_a_tap(self):
        for capture_seconds, ocr_seconds in ((80, .5), (.25, 80)):
            with self.subTest(capture_seconds=capture_seconds, ocr_seconds=ocr_seconds):
                replay = GarageObservationReplay(self.out, [('main', 0)],
                                                 capture_seconds=capture_seconds,
                                                 ocr_seconds=ocr_seconds)
                with replay.installed(), self.assertRaises((RuntimeError, TimeoutError)):
                    tour._select_stage_kart(self.out, 'comet')
                self.assertFalse(replay.inputs)

    def test_ambiguous_complete_targets_fail_in_the_real_selection_caller(self):
        replay = GarageObservationReplay(self.out, [('main', 0)])

        def duplicate_target(_path):
            replay.lines.append({'text': 'Comet', 'bounds': [314, 572, 434, 599], 'variant': 'raw'})

        replay.after_ocr = duplicate_target
        with replay.installed(), self.assertRaises(RuntimeError):
            tour._select_stage_kart(self.out, 'comet')
        self.assertFalse(replay.inputs)
        journal = json.loads((self.out / '21_stage_select_comet-surface-readiness.json').read_text())
        self.assertEqual(journal['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
