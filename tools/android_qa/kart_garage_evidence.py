"""Reusable Garage/Continue evidence from PR #456, without historical APK pins.

Inputs are observed screenshots and the game's own saved session. These
validators never create a selection, race, elapsed time or driving progress.
"""
from __future__ import annotations

import csv
import hashlib
import io
import math
from pathlib import Path
import unicodedata

from PIL import Image


KARTS = {'comet': 'Comet', 'gecko_velo': 'Gecko Velo'}


def demand(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def require_selected_race(state: dict, kart: str, *, previous_id: str | None = None,
                          mode: str = 'cup', track: str = 'sonnenhafen') -> None:
    demand(kart in KARTS and state.get('selected_kart') == kart,
           f'Actual race selected {state.get("selected_kart")!r}, expected {kart}')
    demand(state.get('track_id') == track and state.get('mode') == mode,
           'Confirmed Garage did not start the selected race mode and track')
    demand(state.get('selected_driver') == 'fox', 'Original Lumo driver was not preserved')
    demand(not state.get('finished') and not state.get('completed_race'),
           'Expected a newly running unfinished race')
    result_id = state.get('result_id')
    demand(isinstance(result_id, str) and bool(result_id) and result_id != previous_id,
           'Race start reused the previous saved race instead of the confirmed selection')
    for key in ('distance', 'elapsed', 'countdown'):
        value = state.get(key)
        demand(isinstance(value, (int, float)) and not isinstance(value, bool) and
               math.isfinite(value), f'Nonfinite or missing native race field: {key}')


def selected_race_readiness(state: dict, kart: str, previous_id: str | None,
                            observed_new_id: str | None, *, mode: str = 'cup',
                            track: str = 'sonnenhafen') -> tuple[str | None, bool]:
    """Only the old save before the first new snapshot is a loading observation."""
    identity = state.get('result_id')
    if previous_id is not None and identity == previous_id:
        demand(observed_new_id is None, 'Native session reverted to the previous race after a new identity')
        return None, False
    require_selected_race(state, kart, previous_id=previous_id, mode=mode, track=track)
    demand(observed_new_id is None or identity == observed_new_id,
           'Confirmed race identity changed while awaiting its countdown')
    return identity, state['countdown'] <= 0 and state['elapsed'] >= 1.0


def require_resumed_progress(paused: dict, resumed: dict, kart: str, *,
                             mode: str = 'cup', track: str = 'sonnenhafen') -> dict:
    require_selected_race(paused, kart, mode=mode, track=track)
    require_selected_race(resumed, kart, mode=mode, track=track)
    demand(resumed['result_id'] == paused['result_id'], 'Continue opened a different race')
    distance = resumed['distance'] - paused['distance']
    elapsed = resumed['elapsed'] - paused['elapsed']
    demand(distance >= 8.0 and elapsed >= 2.5,
           f'Continue has not produced new driving progress: {distance} m / {elapsed} s')
    demand(resumed['countdown'] <= 0, 'Continue restarted the countdown')
    return {'result_id': resumed['result_id'], 'kart': kart,
            'distance_gain_after_continue': distance, 'elapsed_gain_after_continue': elapsed}


def normalize(text: str) -> str:
    text = unicodedata.normalize('NFKD', text.lower())
    return ''.join(char for char in text if char.isalnum())


def stage_cup_target_observation(frame: dict, lines: list[dict]) -> dict:
    """Read the actual cup label: Grand Prix, or Pokal on the narrow landing."""
    demand(frame.get('acceptable_for_target_sampling') is True,
           'Cannot read a cup choice on an incomplete native surface')
    width, height = frame['pixels']
    demand(width > height > 0, 'Cup observation requires the actual landscape landing')
    aliases = {'grandprix': 'Grand Prix', 'pokal': 'Pokal'}
    navigation_words = {'fahrer', 'garage', 'strecken', 'tempo', 'mehr', 'modi'}
    navigation, candidates, seen_navigation = [], [], set()
    for row in lines:
        words = {normalize(word) for word in row['text'].split()} - {''}
        if words <= navigation_words and words & {'fahrer', 'garage'}:
            navigation.append(row)
            seen_navigation.update(words)
        # Match the complete caption. Removing symbols turns OCR composites
        # such as '= Grand Prix' into aliases with decoration-sized bounds.
        caption = ''.join(unicodedata.normalize('NFKC', row['text']).casefold().split())
        if caption in aliases:
            candidates.append(row)
    demand({'fahrer', 'garage'} <= seen_navigation,
           'Actual landing Fahrer/Garage navigation required before the cup choice')
    for row in navigation + candidates:
        bounds = row.get('bounds')
        demand(isinstance(bounds, (list, tuple)) and len(bounds) == 4 and
               all(isinstance(value, (int, float)) and not isinstance(value, bool) and
                   math.isfinite(value) for value in bounds), 'Invalid observed cup/navigation bounds')
        x0, y0, x1, y1 = bounds
        demand(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height,
               'Observed cup/navigation bounds exceed the current screenshot')
    navigation_top = min(row['bounds'][1] for row in navigation)
    candidates = [row for row in candidates if row['bounds'][3] < navigation_top]
    demand(candidates, 'No actual Grand Prix or Pokal caption above the landing navigation')
    demand(len({normalize(row['text']) for row in candidates}) == 1,
           'Conflicting current cup captions on the same landing')
    selected = candidates[0]
    x0, y0, x1, y1 = selected['bounds']
    for row in candidates[1:]:
        a0, b0, a1, b1 = row['bounds']
        overlap = max(0, min(x1, a1) - max(x0, a0)) * max(0, min(y1, b1) - max(y0, b0))
        union = (x1 - x0) * (y1 - y0) + (a1 - a0) * (b1 - b0) - overlap
        demand(overlap / union >= .6, 'Ambiguous cup-caption regions on the current landing')
    return {'target': selected, 'caption': aliases[normalize(selected['text'])],
            'navigation_top': navigation_top, 'matching_observations': len(candidates),
            'scope': 'Observed cup button; the new native race must still confirm mode cup'}


def stage_driver_word_observations(out: Path, tag: str, lines: list[dict]) -> dict:
    """Read exact words from this frame's existing full-frame OCR outputs.

    The fox icon can share an OCR line with its caption. Use the real word
    rectangle, never the icon-plus-caption line rectangle or estimated bounds.
    Scales match creative_android_probe.image_lines; its confidence floor and
    all seven original variants remain unchanged.
    """
    scales = {'contrast': 2, 'raw': 2, 'white-text': 2, 'white-latin': 2,
              'navy-latin': 2, 'navy-latin-1x': 1, 'teal-text-1x': 1}
    demand(Path(tag).name == tag, 'Invalid current driver OCR tag')
    variants = list(dict.fromkeys(row.get('variant') for row in lines))
    demand(variants and all(variant in scales for variant in variants),
           'Original driver OCR variants are required for word observations')
    words, sources = [], []
    for variant in variants:
        source = out / f'{tag}-ocr-{variant}.tsv'
        demand(source.is_file(), 'Original current-frame driver TSV is missing')
        raw = source.read_bytes()
        sources.append({'file': source.name, 'sha256': hashlib.sha256(raw).hexdigest(),
                        'bytes': len(raw), 'scale': scales[variant]})
        reader = csv.DictReader(io.StringIO(raw.decode('utf-8')), delimiter='\t',
                                quoting=csv.QUOTE_NONE)
        demand({'level', 'text', 'conf', 'left', 'top', 'width', 'height'} <=
               set(reader.fieldnames or ()), 'Invalid original driver TSV columns')
        for word in reader:
            caption = unicodedata.normalize('NFKC', word['text']).strip().casefold()
            if word['level'] != '5' or caption != 'lumo':
                continue
            confidence = float(word['conf'])
            demand(math.isfinite(confidence), 'Nonfinite original driver OCR confidence')
            if confidence < 15:
                continue
            scale = scales[variant]
            left, top, width, height = (int(word[key]) for key in
                                       ('left', 'top', 'width', 'height'))
            words.append({'text': word['text'], 'variant': variant,
                          'bounds': [left / scale, top / scale,
                                     (left + width) / scale, (top + height) / scale],
                          'source_tsv': source.name})
    return {'words': words, 'sources': sources}


def stage_driver_target_observation(frame: dict, lines: list[dict], *,
                                    caption_words: list[dict] | None = None) -> dict:
    """Locate the real Lumo card below the tabs, never the identical brand.

    The current landscape driver list is left-aligned, below Fahrer/Karts and
    above the menu/start footer. All target coordinates still come from OCR.
    Multiple OCR variants may describe one glyph; distinct targets are fatal.
    """
    demand(frame.get('acceptable_for_target_sampling') is True,
           'Cannot select a driver on an incomplete native surface')
    width, height = frame['pixels']
    demand(width > height > 0, 'Driver observation requires the actual landscape menu')
    tabs = {'rennen', 'fahrer', 'karts', 'strecken', 'tempo'}
    headers, footers, captions = [], [], []
    observed_tabs = set()
    for row in lines:
        words = {normalize(word) for word in row['text'].split()} - {''}
        if words <= tabs and words & {'fahrer', 'karts'}:
            headers.append(row)
            observed_tabs.update(words)
        elif normalize(row['text']) in ('kartmenu', 'menu', 'start', 'rennenstarten'):
            footers.append(row)
        elif normalize(row['text']) == 'lumo':
            captions.append(row)
    if caption_words is not None:
        captions = [row for row in caption_words if
                    unicodedata.normalize('NFKC', row['text']).strip().casefold() == 'lumo']
    demand({'fahrer', 'karts'} <= observed_tabs and footers,
           'Actual Fahrer/Karts tabs and menu/start footer required before driver selection')
    for row in headers + footers + captions:
        bounds = row.get('bounds')
        demand(isinstance(bounds, (list, tuple)) and len(bounds) == 4 and
               all(isinstance(value, (int, float)) and not isinstance(value, bool) and
                   math.isfinite(value) for value in bounds), 'Invalid observed driver/menu bounds')
        x0, y0, x1, y1 = bounds
        demand(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height,
               'Observed driver/menu bounds exceed the current screenshot')
    header_bottom = max(row['bounds'][3] for row in headers)
    footer_top = min(row['bounds'][1] for row in footers)
    demand(header_bottom < footer_top, 'Observed driver tabs and footer do not bound a list')
    targets = [row for row in captions if row['bounds'][2] < width * .5 and
               header_bottom < row['bounds'][1] < row['bounds'][3] < footer_top]
    demand(targets, 'No exact Lumo driver caption in the observed left-hand list')
    selected = targets[0]
    x0, y0, x1, y1 = selected['bounds']
    for row in targets[1:]:
        a0, b0, a1, b1 = row['bounds']
        overlap = max(0, min(x1, a1) - max(x0, a0)) * max(0, min(y1, b1) - max(y0, b0))
        union = (x1 - x0) * (y1 - y0) + (a1 - a0) * (b1 - b0) - overlap
        demand(overlap / union >= .6, 'Ambiguous Lumo driver captions in the observed list')
    return {'target': selected, 'matching_observations': len(targets),
            'header_bottom': header_bottom, 'footer_top': footer_top,
            'scope': 'Observed landscape driver card; saved fox selection remains mandatory'}


def stage_garage_word_observations(out: Path, tag: str, lines: list[dict]) -> dict:
    """Recover complete known card captions from this frame's original words.

    Decorative artwork may share the OCR line. Matching still requires whole,
    consecutive words in one original TSV line, with observed word rectangles.
    The evidence authorizes a list gesture only, never a vehicle selection.
    """
    captions = ('Comet', 'Gecko Velo', 'Boru Rally', 'Glider', 'Nala Comet', 'Noa Tide')
    scales = {'contrast': 2, 'raw': 2, 'white-text': 2, 'white-latin': 2,
              'navy-latin': 2, 'navy-latin-1x': 1, 'teal-text-1x': 1}
    demand(Path(tag).name == tag, 'Invalid current vehicle OCR tag')
    variants = list(dict.fromkeys(row.get('variant') for row in lines))
    demand(variants and all(variant in scales for variant in variants),
           'Original full-frame vehicle OCR variants are required')
    observed, sources = [], []
    for variant in variants:
        source = out / f'{tag}-ocr-{variant}.tsv'
        demand(source.is_file(), 'Original current-frame vehicle TSV is missing')
        raw = source.read_bytes()
        scale = scales[variant]
        sources.append({'file': source.name, 'sha256': hashlib.sha256(raw).hexdigest(),
                        'bytes': len(raw), 'scale': scale})
        reader = csv.DictReader(io.StringIO(raw.decode('utf-8')), delimiter='\t',
                                quoting=csv.QUOTE_NONE)
        required = {'level', 'page_num', 'block_num', 'par_num', 'line_num',
                    'word_num', 'text', 'conf', 'left', 'top', 'width', 'height'}
        demand(required <= set(reader.fieldnames or ()), 'Invalid original vehicle TSV columns')
        groups = {}
        for word in reader:
            if word['level'] == '5':
                key = tuple(word[field] for field in ('page_num', 'block_num', 'par_num', 'line_num'))
                groups.setdefault(key, []).append(word)
        for key, words in groups.items():
            matches = []
            for caption in captions:
                wanted = caption.casefold().split()
                for start in range(len(words) - len(wanted) + 1):
                    span = words[start:start + len(wanted)]
                    actual = [unicodedata.normalize('NFKC', word['text']).strip().casefold()
                              for word in span]
                    if actual != wanted:
                        continue
                    numbers = [int(word['word_num']) for word in span]
                    if numbers[0] < 1 or numbers != list(range(numbers[0], numbers[0] + len(span))):
                        continue
                    confidence = [float(word['conf']) for word in span]
                    demand(all(math.isfinite(value) for value in confidence),
                           'Nonfinite original vehicle OCR confidence')
                    if any(value < 15 for value in confidence):
                        continue
                    boxes = []
                    for word in span:
                        left, top, width, height = (int(word[field]) for field in
                                                   ('left', 'top', 'width', 'height'))
                        demand(left >= 0 and top >= 0 and width > 0 and height > 0,
                               'Invalid original vehicle word rectangle')
                        boxes.append((left, top, left + width, top + height))
                    # One TSV line alone must not join distant columns or
                    # vertically disjoint words into a fictitious card title.
                    if any(not (0 <= right[0] - left[2] <= max(left[3] - left[1],
                                                              right[3] - right[1]) and
                                max(left[1], right[1]) < min(left[3], right[3]))
                           for left, right in zip(boxes, boxes[1:])):
                        continue
                    bounds = [min(box[0] for box in boxes) / scale,
                              min(box[1] for box in boxes) / scale,
                              max(box[2] for box in boxes) / scale,
                              max(box[3] for box in boxes) / scale]
                    matches.append({'start': start, 'end': start + len(span),
                                    'text': caption, 'bounds': bounds, 'variant': variant,
                                    'source_tsv': source.name, 'line_identity': list(key),
                                    'word_numbers': numbers})
            for match in matches:
                # Comet inside the complete known Nala Comet caption is not
                # a second card. Retain only the maximal known word sequence.
                if any(other['start'] <= match['start'] and match['end'] <= other['end'] and
                       (other['start'], other['end']) != (match['start'], match['end'])
                       for other in matches):
                    continue
                observed.append({key: value for key, value in match.items()
                                 if key not in ('start', 'end')})
    return {'captions': observed, 'sources': sources}


def _garage_stat_bars(frame: dict, source: Path, header_bottom: float,
                      workshop_top: float) -> dict:
    """Observe the five cyan stat bars in this frame, never a vehicle identity.

    KartStatBars draws #5fe3ff and a 22-percent white highlight. Its scale
    ticks can interrupt a row by a few pixels. A whole, unique five-row block
    is required; a partial card, arbitrary cyan artwork or right-hand preview
    is not a scroll target. The unchanged PNG remains the replay source.
    """
    raw = source.read_bytes()
    source_hash = hashlib.sha256(raw).hexdigest()
    demand(source_hash == frame.get('source_sha256') and
           len(raw) == frame.get('source_bytes'),
           'Current Garage screenshot does not match its surface observation')
    width, height = frame['pixels']
    with Image.open(io.BytesIO(raw)) as original:
        demand(list(original.size) == frame['pixels'],
               'Current Garage PNG dimensions differ from its surface observation')
        image = original.convert('RGB')
    pixels = image.load()

    def cyan(x: int, y: int) -> bool:
        red, green, blue = pixels[x, y]
        return (abs(blue - 255) <= 2 and
                ((abs(red - 95) <= 2 and abs(green - 227) <= 2) or
                 (abs(red - 130) <= 2 and abs(green - 233) <= 2)))

    bands: list[dict] = []
    for y in range(math.floor(header_bottom) + 1, math.ceil(workshop_top)):
        start = last = None
        matched = 0
        runs = []
        for x in range(1, math.floor(width * .5)):
            if cyan(x, y):
                if start is None:
                    start, matched = x, 0
                last = x
                matched += 1
            elif start is not None and x - last > 3:
                if last - start + 1 >= 32 and matched / (last - start + 1) >= .95:
                    runs.append((start, last + 1))
                start = last = None
                matched = 0
        if start is not None and last - start + 1 >= 32 and matched / (last - start + 1) >= .95:
            runs.append((start, last + 1))
        for left, right in runs:
            previous = [band for band in bands if band['bounds'][3] == y and
                        abs(band['bounds'][0] - left) <= 1 and
                        abs(band['bounds'][2] - right) <= 1]
            if previous:
                bounds = previous[0]['bounds']
                bounds[0], bounds[2], bounds[3] = min(bounds[0], left), max(bounds[2], right), y + 1
            else:
                bands.append({'bounds': [left, y, right, y + 1]})

    bands = [band for band in bands
             if 3 <= band['bounds'][3] - band['bounds'][1] <= 40 and
             band['bounds'][2] - band['bounds'][0] >=
             6 * (band['bounds'][3] - band['bounds'][1])]
    bands.sort(key=lambda band: (band['bounds'][1], band['bounds'][0]))
    candidates = []
    for first in range(max(0, len(bands) - 4)):
        block = bands[first:first + 5]
        rectangles = [band['bounds'] for band in block]
        lefts = [box[0] for box in rectangles]
        heights = [box[3] - box[1] for box in rectangles]
        pitches = [b[1] - a[1] for a, b in zip(rectangles, rectangles[1:])]
        if (max(lefts) - min(lefts) > 1 or max(heights) - min(heights) > 1 or
                min(pitches) < max(heights) * 2 or max(pitches) - min(pitches) > 1 or
                max(pitches) > max(heights) * 5):
            continue
        left, right = max(lefts) + 1, min(box[2] for box in rectangles) - 1
        if right - left < 30:
            continue
        middles = [(box[1] + box[3] - 1) // 2 for box in rectangles]
        columns = [x for x in range(left, right) if all(cyan(x, y) for y in middles)]
        if not columns:
            continue
        x = min(columns, key=lambda value: abs(value - (left + right) / 2))
        gesture = [x, middles[-1], x, middles[0]]
        if gesture[1] - gesture[3] < 15:
            continue
        candidates.append({'gesture': gesture, 'bars': rectangles,
                           'anchor_bounds': [left, rectangles[0][1], right, rectangles[-1][3]]})
    demand(candidates, 'No complete current five-bar block in the actual left Garage list')
    demand(len(candidates) == 1, 'Ambiguous current five-bar blocks in the left Garage list')
    return {**candidates[0], 'anchor_kind': 'current-stat-bars',
            'pixel_source': {'file': source.name, 'sha256': source_hash, 'bytes': len(raw),
                             'pixels': [width, height], 'base_rgb': [95, 227, 255],
                             'highlight_rgb': [130, 233, 255], 'channel_tolerance': 2,
                             'max_tick_gap_pixels': 3, 'minimum_row_coverage': .95},
            'scope': 'Current pixel geometry for scrolling only; no vehicle name or selection inferred'}


def stage_garage_scroll_observation(frame: dict, lines: list[dict], *,
                                    caption_words: list[dict] | None = None,
                                    source: Path | None = None) -> dict:
    """Keep each drag inside a current caption or a proved current stat block.

    Karts and the local workshop caption identify the current left-hand list.
    Their text bounds are context, not a claimed viewport edge. A vehicle name
    can be clipped between cards; only a complete current pixel block may then
    provide scroll geometry. Exact target touch and the new saved race remain
    separate mandatory checks.
    """
    demand(frame.get('acceptable_for_target_sampling') is True,
           'Cannot scroll an incomplete native surface')
    width, height = frame['pixels']
    demand(width > height > 0, 'Expected the actual landscape Garage')
    headers = [row for row in lines if normalize(row['text']) == 'karts']
    footers = [row for row in lines if normalize(row['text']) in
               ('kartmenu', 'menu', 'start', 'rennenstarten')]
    workshop = [row for row in lines if normalize(row['text']) == 'lackteileeffekte']
    candidates = lines if caption_words is None else caption_words
    named_cards = [row for row in candidates if normalize(row['text']) in
                   ('comet', 'geckovelo', 'borurally', 'glider', 'nalacomet', 'noatide')]
    demand(headers and footers and workshop,
           'Actual Karts tab, local workshop and menu/start footer required before list scrolling')
    for row in headers + footers + workshop + (named_cards if caption_words is None else candidates):
        bounds = row.get('bounds')
        demand(isinstance(bounds, (list, tuple)) and len(bounds) == 4 and
               all(isinstance(value, (int, float)) and not isinstance(value, bool) and
                   math.isfinite(value) for value in bounds), 'Invalid observed Garage bounds')
        x0, y0, x1, y1 = bounds
        demand(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height,
               'Observed Garage bounds exceed the current screenshot')
    demand(all(row['bounds'][2] < width * .5 for row in workshop),
           'Current workshop caption is not in the left Garage list')
    header_bottom = min(row['bounds'][3] for row in headers)
    footer_top = min(row['bounds'][1] for row in footers)
    workshop_top = min(row['bounds'][1] for row in workshop)
    demand(header_bottom < workshop_top < footer_top,
           'Current Garage context does not bound the left-hand list')
    context = {'header_bottom': header_bottom, 'workshop_top': workshop_top,
               'footer_top': footer_top,
               'context_bounds': {'karts': [row['bounds'] for row in headers],
                                  'workshop': [row['bounds'] for row in workshop]}}
    section_cards = [row for row in named_cards if
                     0 < row['bounds'][0] < row['bounds'][2] < width * .50 and
                     header_bottom < row['bounds'][1] < row['bounds'][3] < footer_top]
    if caption_words is not None:
        # Retain the producer's ambiguity gate across its whole observed
        # section, before narrowing a gesture to the local workshop boundary.
        for index, left in enumerate(section_cards):
            x0, y0, x1, y1 = left['bounds']
            for right in section_cards[index + 1:]:
                a0, b0, a1, b1 = right['bounds']
                overlap = max(0, min(x1, a1) - max(x0, a0)) * max(0, min(y1, b1) - max(y0, b0))
                union = (x1 - x0) * (y1 - y0) + (a1 - a0) * (b1 - b0) - overlap
                if normalize(left['text']) == normalize(right['text']):
                    demand(overlap / union >= .6, 'Ambiguous repeated vehicle caption regions')
                else:
                    demand(overlap == 0, 'Conflicting vehicle captions in one observed region')
    cards = [row for row in section_cards if row['bounds'][3] < workshop_top]
    if not cards:
        demand(source is not None, 'No currently visible vehicle card in the actual left list')
        return {**_garage_stat_bars(frame, source, header_bottom, workshop_top), **context}
    card = min(cards, key=lambda row: row['bounds'][1])
    same_caption = [row for row in cards if normalize(row['text']) == normalize(card['text'])]
    x0, y0 = (max(row['bounds'][axis] for row in same_caption) for axis in (0, 1))
    x1, y1 = (min(row['bounds'][axis] for row in same_caption) for axis in (2, 3))
    x, start, end = round((x0 + x1) / 2), math.ceil(y1) - 1, math.floor(y0) + 1
    demand(x0 < x < x1 and y0 < end < start < y1 and start - end >= 15,
           'Observed vehicle caption is too small or ambiguous for an interior drag')
    return {'gesture': [x, start, x, end], 'card': card,
            'anchor_kind': 'current-caption', 'anchor_caption': normalize(card['text']),
            'anchor_bounds': [x0, y0, x1, y1], **context,
            'scope': 'Scroll inside current caption only; exact target and saved selection remain mandatory'}
