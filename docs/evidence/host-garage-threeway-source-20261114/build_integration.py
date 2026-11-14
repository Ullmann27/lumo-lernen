"""Assemble the narrow source proposal without importing or testing it."""
from pathlib import Path
import ast
import shutil

ROOT = Path(__file__).resolve().parent
BASE = ROOT / 'original-source/current-0b7'
PRODUCER = ROOT / 'original-source/producer-51ec'
FINAL = ROOT / 'final-source'


def node_text(source, name, owner=None):
    tree = ast.parse(source)
    nodes = tree.body if owner is None else next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == owner).body
    node = next(n for n in nodes if isinstance(n, (ast.FunctionDef, ast.ClassDef)) and n.name == name)
    return ''.join(source.splitlines(True)[node.lineno - 1:node.end_lineno])


def replace_node(source, name, replacement, owner=None):
    old = node_text(source, name, owner)
    assert source.count(old) == 1
    return source.replace(old, replacement)


def write(rel, text):
    path = FINAL / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


rel = 'tools/android_qa/kart_garage_evidence.py'
base, producer = (BASE / rel).read_text(), (PRODUCER / rel).read_text()
result = base.replace('import unicodedata\n', 'import unicodedata\n\nfrom PIL import Image\n')
constant_start = producer.index('SPATIAL_KART_CAPTIONS =')
constant_end = producer.index('\n\n', constant_start)
constant = producer[constant_start:constant_end]
anchor = "KARTS = {'comet': 'Comet', 'gecko_velo': 'Gecko Velo'}"
result = result.replace(anchor, anchor + '\n' + constant)
helpers = '\n\n'.join(node_text(producer, name).rstrip('\n') for name in
                      ('_observed_caption', '_workshop_outline', '_observed_scrollbar',
                       'stage_kart_target_observation')) + '\n\n\n'
new = node_text(producer, 'stage_garage_scroll_observation')
new = new.replace("kart: str = 'gecko_velo') -> dict:",
                  "kart: str = 'gecko_velo',\n                                    caption_words: list[dict] | None = None) -> dict:")
old_cards = """    cards = [row for row in lines if normalize(row['text']) in order and
             left < row['bounds'][0] < row['bounds'][2] < right and
             top + 2 < row['bounds'][1] < row['bounds'][3] < bottom - 2]
"""
new_cards = """    candidates = lines if caption_words is None else caption_words
    # Retain the stricter current-frame word-evidence contract. Words may
    # guide scrolling inside the observed clip; they never authorize a tap.
    for row in candidates:
        if caption_words is None and normalize(row['text']) not in order:
            continue
        bounds = row.get('bounds')
        demand(isinstance(bounds, (list, tuple)) and len(bounds) == 4 and
               all(isinstance(value, (int, float)) and not isinstance(value, bool) and
                   math.isfinite(value) for value in bounds),
               'Invalid observed vehicle/menu bounds')
        x0, y0, x1, y1 = bounds
        demand(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height,
               'Observed vehicle/menu bounds exceed the current screenshot')
    cards = [row for row in candidates if normalize(row['text']) in order and
             left < row['bounds'][0] < row['bounds'][2] < right and
             top + 2 < row['bounds'][1] < row['bounds'][3] < bottom - 2]
    if caption_words is not None:
        demand(cards, 'No currently visible vehicle card in the actual left list')
        for index, first in enumerate(cards):
            x0, y0, x1, y1 = first['bounds']
            for second in cards[index + 1:]:
                a0, b0, a1, b1 = second['bounds']
                overlap = max(0, min(x1, a1) - max(x0, a0)) * max(0, min(y1, b1) - max(y0, b0))
                union = (x1 - x0) * (y1 - y0) + (a1 - a0) * (b1 - b0) - overlap
                if normalize(first['text']) == normalize(second['text']):
                    demand(overlap / union >= .6, 'Ambiguous repeated vehicle caption regions')
                else:
                    demand(overlap == 0, 'Conflicting vehicle captions in one observed region')
"""
assert old_cards in new
new = new.replace(old_cards, new_cards)
new = new.replace("'scroll_fraction': fraction, 'visible_cards': cards,",
                  "'scroll_fraction': fraction, 'visible_cards': cards,\n            'card': min(cards, key=lambda row: row['bounds'][1]) if cards else None,")
result = replace_node(result, 'stage_garage_scroll_observation', helpers + new)
assert node_text(result, 'stage_garage_word_observations') == node_text(base, 'stage_garage_word_observations')
write(rel, result)

rel = '.github/probes/modernization_android_tour.py'
base, producer = (BASE / rel).read_text(), (PRODUCER / rel).read_text()
recovery = node_text(producer, '_stage_kart_scroll_recovery')
initial = "        current = garage_evidence.stage_garage_scroll_observation(frame, lines, source=source, kart=kart)\n"
with_words = initial + """        if not current['visible_cards']:
            # Preserve the original whole-word Boru recovery. Component OCR
            # has a different coordinate/source contract and is never passed
            # off as one of these original full-frame TSV variants.
            full_frame = [row for row in lines if row.get('variant') in
                          ('contrast', 'raw', 'white-text', 'white-latin',
                           'navy-latin', 'navy-latin-1x', 'teal-text-1x')]
            words = garage_evidence.stage_garage_word_observations(source.parent, source.stem, full_frame)
            if words['captions']:
                current = garage_evidence.stage_garage_scroll_observation(
                    frame, lines, source=source, kart=kart, caption_words=words['captions'])
            current.update(caption_source='original_tsv_word_sequences' if words['captions']
                           else 'original_tsv_no_complete_card', ocr_sources=words['sources'])
        words_stable = True
        if previous is not None and ('caption_source' in current or 'caption_source' in previous):
            words_stable = current.get('caption_source') == previous.get('caption_source')
            if current.get('caption_source') == 'original_tsv_word_sequences':
                old_card, new_card = previous.get('card'), current.get('card')
                words_stable = (words_stable and old_card is not None and new_card is not None and
                                garage_evidence.normalize(old_card['text']) == garage_evidence.normalize(new_card['text']) and
                                max(abs(a - b) for a, b in zip(old_card['bounds'], new_card['bounds'])) <= 3)
"""
assert recovery.count(initial) == 1
recovery = recovery.replace(initial, with_words)
recovery = recovery.replace("stable = (previous is not None and previous_missing_frame is not None and",
                            "stable = (previous is not None and previous_missing_frame is not None and words_stable and")
result = replace_node(base, '_stage_kart_scroll_recovery', recovery)
result = replace_node(result, '_select_stage_kart', node_text(producer, '_select_stage_kart'))
assert node_text(result, '_continue_actual_race') == node_text(base, '_continue_actual_race')
write(rel, result)

rel = 'tools/android_qa/tests/test_kart_garage_evidence.py'
base, producer = (BASE / rel).read_text(), (PRODUCER / rel).read_text()
result = base
for owner, before, after in [
    ('GarageObservedScrollTests', 'test_current_hidden_title_layout_uses_only_the_tab_footer_and_left_card',
     'test_current_hidden_title_layout_uses_the_observed_clip_not_only_tab_and_footer'),
    ('GarageObservedScrollTests', 'test_missing_anchors_incomplete_frames_and_right_preview_are_rejected',
     'test_missing_current_context_and_incomplete_frames_are_rejected'),
    ('GarageObservedScrollTests', 'test_actual_scroll_needs_two_stable_frames_and_unchanged_screenshot',
     'test_actual_scroll_needs_two_stable_frames_and_unchanged_screenshot'),
    ('CurrentGarageProbeWiringTests', 'test_selection_needs_a_successful_observed_native_touch_receipt',
     'test_selection_reports_success_only_after_the_observed_input_succeeds')]:
    result = replace_node(result, before, node_text(producer, after, owner), owner)
assert node_text(result, 'test_continue_requires_touch_then_physical_drive_and_retains_original_evidence',
                 'CurrentGarageProbeWiringTests') == node_text(base, 'test_continue_requires_touch_then_physical_drive_and_retains_original_evidence',
                                                             'CurrentGarageProbeWiringTests')
write(rel, result)

rel = 'tools/android_qa/tests/test_kart_garage_scroll_recovery.py'
result = (PRODUCER / rel).read_text()
empty_words = '''def empty_word_observation(out, tag, lines):
    """Explicit synthetic empty TSVs for the pixel-only replay branch.

    The PNGs and line JSON remain original. These header-only word streams
    deliberately contain no inferred words; the separate 3d91 suite replays
    actual Boru TSV bytes through the unchanged word parser.
    """
    fields = ['level', 'page_num', 'block_num', 'par_num', 'line_num', 'word_num',
              'left', 'top', 'width', 'height', 'conf', 'text']
    for variant in dict.fromkeys(row['variant'] for row in lines):
        (out / f'{tag}-ocr-{variant}.tsv').write_text('\\t'.join(fields) + '\\n')


'''
result = result.replace('class OriginalGarageViewportTests', empty_words + 'class OriginalGarageViewportTests', 1)
result = result.replace("        frame['source'] = source.name\n        return frame, lines, source\n",
                        "        frame['source'] = source.name\n        empty_word_observation(self.out, source.stem, lines)\n        return frame, lines, source\n")
result = result.replace("            current_frame = dict(frame, source=current.name)\n",
                        "            current_frame = dict(frame, source=current.name)\n            empty_word_observation(Path(folder), previous.stem, lines)\n            empty_word_observation(Path(folder), current.stem, lines)\n")
result = result.replace("        observed = copy.deepcopy(self.lines)\n",
                        "        observed = copy.deepcopy(self.lines)\n        empty_word_observation(self.out, source_path.stem, observed)\n")
write(rel, result)

rel = 'tools/android_qa/tests/test_kart_scroll_word_evidence.py'
result = (BASE / rel).read_text()
result = result.replace("'base': SimpleNamespace(adb=self.adb), 'time': self.clock}",
                        "'base': SimpleNamespace(adb=self.adb), 'time': self.clock, 'Path': Path}")
result = result.replace("            self.frame, self.lines, caption_words=self.recovered()['captions'])",
                        "            self.frame, self.lines, source=self.source,\n            caption_words=self.recovered()['captions'])")
anchor = '    def tsv_rows(self):\n'
fresh = '''    def fresh_observation(self, number):
        # Distinct replay paths model two captures of the unchanged original.
        # They are controlled observations, never a second claimed Android PNG.
        tag = f'current-word-observation-{number}'
        for source in list(self.out.glob(TAG + '*')):
            destination = self.out / (tag + source.name[len(TAG):])
            shutil.copyfile(source, destination)
        source = self.out / (tag + '.png')
        return dict(self.frame, source=source.name), source

'''
assert anchor in result
result = result.replace(anchor, fresh + anchor)
result = replace_node(result, 'test_original_boru_frame_recovers_only_scroll_after_two_bound_frames', '''    def test_original_boru_frame_recovers_only_scroll_after_two_bound_frames(self):
        callback = self.controller()
        first_frame, first_source = self.fresh_observation(1)
        second_frame, second_source = self.fresh_observation(2)
        first = callback(first_frame, self.lines, first_source, deadline=10,
                         previous_missing_frame=None)
        self.assertEqual(first['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
        self.adb.assert_not_called()
        second = callback(second_frame, self.lines, second_source, deadline=10,
                          previous_missing_frame=first_frame)
        self.assertEqual(second['status'], 'SWIPE_SENT')
        self.assertEqual(second['card']['text'], 'Boru Rally')
        self.assertEqual(second['card']['bounds'], [314.5, 593.0, 511.0, 629.0])
        self.assertEqual(second['direction'], 'backward')
        x0, y0, x1, y1 = second['gesture']
        self.assertEqual(x0, x1)
        self.assertLess(y0, y1)
        self.assertGreaterEqual(y1 - y0, 15)
        self.assertLess(y1 - y0, 40)
        # The unchanged original has its clipped list between y416 and665.
        self.assertTrue(42 < x0 < 750 and 416 < y0 < y1 < 665)
        self.assertEqual(second['caption_source'], 'original_tsv_word_sequences')
        self.assertEqual(len(second['ocr_sources']), 7)
        for source in second['ocr_sources']:
            self.assertEqual(source['sha256'], digest(self.out / source['file']))
        self.adb.assert_called_once_with('shell', 'input', 'swipe',
                                         *map(str, second['gesture']), '650', timeout=10)
''', 'GarageOriginalWordSequenceTests')
result = replace_node(result, 'test_original_line_failure_and_existing_exact_comet_path_are_preserved', '''    def test_original_line_gap_and_exact_comet_path_use_the_current_clip(self):
        current = evidence.stage_garage_scroll_observation(
            self.frame, self.lines, source=self.source)
        self.assertEqual(current['visible_cards'], [])
        self.assertIsNone(current['card'])
        self.assertIsNone(evidence.stage_kart_target_observation(
            self.frame, self.lines, 'gecko_velo', current['viewport_bounds']))
        # Exact Comet lines remain useful for direction, but the old long
        # gesture is no longer accepted as the geometry of this actual list.
        lines = json.loads((FIXTURES / '21_stage_select_gecko_velo-0-ocr.json').read_text())
        readiness = json.loads((FIXTURES / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
        current = evidence.stage_garage_scroll_observation(
            readiness['frames'][0], lines, source=FIXTURES / '21_stage_select_gecko_velo-0.png')
        self.assertEqual(current['card']['text'], 'Comet')
        self.assertEqual(current['direction'], 'forward')
        self.assertNotEqual(current['gesture'], [374, 486, 374, 351])
        self.assertLess(351, current['viewport_bounds'][1])
''', 'GarageOriginalWordSequenceTests')
result = result.replace("dict(row, block_num='999', top=str(int(row['top']) + 200))",
                        "dict(row, block_num='999', top=str(int(row['top']) - 160))")
result = result.replace("            self.frame, self.lines, caption_words=captions + [second])",
                        "            self.frame, self.lines, source=self.source, caption_words=captions + [second])")
result = result.replace("            self.frame, self.lines, caption_words=captions + [comet])",
                        "            self.frame, self.lines, source=self.source, caption_words=captions + [comet])")
result = replace_node(result, 'test_unstable_words_need_a_new_pair_and_changed_png_or_deadline_never_swipe', '''    def test_unstable_words_need_a_new_pair_and_changed_png_or_deadline_never_swipe(self):
        callback = self.controller()
        first_frame, first_source = self.fresh_observation(1)
        callback(first_frame, self.lines, first_source, deadline=10, previous_missing_frame=None)
        rows = self.tsv_rows()
        for row in rows:
            if row['level'] == '5' and row['text'] in ('Boru', 'Rally'):
                row['left'] = str(int(row['left']) + 40)
        self.write_rows(rows)
        second_frame, second_source = self.fresh_observation(2)
        observed = callback(second_frame, self.lines, second_source, deadline=10,
                            previous_missing_frame=first_frame)
        self.assertEqual(observed['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
        self.adb.assert_not_called()
        third_frame, third_source = self.fresh_observation(3)
        third_source.write_bytes(b'changed after observation')
        with self.assertRaisesRegex(RuntimeError, 'screenshot.*changed'):
            callback(third_frame, self.lines, third_source, deadline=10,
                     previous_missing_frame=second_frame)
        self.adb.assert_not_called()
        fourth_frame, fourth_source = self.fresh_observation(4)
        self.clock.monotonic = lambda: 10.0
        with self.assertRaisesRegex(RuntimeError, 'bounded deadline'):
            callback(fourth_frame, self.lines, fourth_source, deadline=10,
                     previous_missing_frame=second_frame)
        self.adb.assert_not_called()
''', 'GarageOriginalWordSequenceTests')
result = replace_node(result, 'test_five_gesture_limit_remains_hard_after_word_recovery', '''    def test_five_gesture_limit_remains_hard_after_word_recovery(self):
        callback = self.controller()
        for number in range(1, 6):
            first_frame, first_source = self.fresh_observation(number * 2)
            second_frame, second_source = self.fresh_observation(number * 2 + 1)
            callback(first_frame, self.lines, first_source, deadline=10,
                     previous_missing_frame=None)
            result = callback(second_frame, self.lines, second_source, deadline=10,
                              previous_missing_frame=first_frame)
            self.assertEqual(result['swipe_number'], number)
        first_frame, first_source = self.fresh_observation(12)
        second_frame, second_source = self.fresh_observation(13)
        callback(first_frame, self.lines, first_source, deadline=10, previous_missing_frame=None)
        with self.assertRaisesRegex(RuntimeError, 'after five observed list gestures'):
            callback(second_frame, self.lines, second_source, deadline=10,
                     previous_missing_frame=first_frame)
        self.assertEqual(self.adb.call_count, 5)
''', 'GarageOriginalWordSequenceTests')
write(rel, result)

fixtures = PRODUCER / 'tools/android_qa/tests/fixtures/kart-scroll-6f42'
for path in fixtures.rglob('*'):
    if path.is_file():
        target = FINAL / path.relative_to(PRODUCER)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)

print('Prepared two production helpers, two directly dependent test modules and nine original fixture files; no tests imported or run.')
