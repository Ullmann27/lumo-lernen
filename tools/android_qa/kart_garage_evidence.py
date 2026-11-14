"""Reusable Garage/Continue evidence from PR #456, without historical APK pins.

Inputs are observed screenshots and the game's own saved session. These
validators never create a selection, race, elapsed time or driving progress.
"""
from __future__ import annotations

import csv
import hashlib
import io
import json
import math
from pathlib import Path
import time
import unicodedata

from PIL import Image

from native_ocr_tiles import observed_matches


KARTS = {'comet': 'Comet', 'gecko_velo': 'Gecko Velo'}
# Native3213 kart_fleet.gd -> kart_catalog.gd -> garage _entries(), unsorted.
GARAGE_CARD_ORDER = ('comet', 'geckovelo', 'borurally', 'glider', 'nalacomet', 'noatide')


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


def stage_garage_scroll_observation(frame: dict, lines: list[dict], *,
                                    target_kart: str | None = None,
                                    direction_changes: int = 0) -> dict:
    """Adapt PR #456's observed list drag to the current spatial menu anchors.

    The title is intentionally hidden on short screens. The actual Karts tab,
    current footer and a visible vehicle card bound the left-hand list instead.
    This determines a scroll gesture only; the target still needs a real touch.
    """
    demand(frame.get('acceptable_for_target_sampling') is True,
           'Cannot scroll an incomplete native surface')
    width, height = frame['pixels']
    demand(width > height > 0, 'Expected the actual landscape Garage')
    headers = [row for row in lines if normalize(row['text']) == 'karts']
    footers = [row for row in lines if normalize(row['text']) in
               ('kartmenu', 'menu', 'start', 'rennenstarten')]
    demand(headers and footers, 'Actual Karts tab and menu/start footer required before list scrolling')
    header_bottom = min(row['bounds'][3] for row in headers)
    footer_top = min(row['bounds'][1] for row in footers)
    cards = [row for row in lines if normalize(row['text']) in GARAGE_CARD_ORDER and
             0 < row['bounds'][0] < row['bounds'][2] < width * .50 and
             header_bottom < row['bounds'][1] < row['bounds'][3] < footer_top]
    demand(cards, 'No currently visible vehicle card in the actual left list')
    direction = 'later'
    demand(type(direction_changes) is int and 0 <= direction_changes < 5,
           'Invalid observed garage direction-change count')
    if target_kart is not None:
        demand(target_kart in KARTS, 'Only a requested free kart can guide Garage scrolling')
        wanted = normalize(KARTS[target_kart])
        target_index = GARAGE_CARD_ORDER.index(wanted)
        names = {normalize(row['text']) for row in cards}
        demand(wanted not in names, 'Requested kart is already visible; require target sampling, not scrolling')
        sides = {GARAGE_CARD_ORDER.index(name) < target_index for name in names}
        demand(len(sides) == 1, 'Ambiguous observed cards surround the requested kart')
        direction = 'later' if True in sides else 'earlier'
        for index, first in enumerate(cards):
            x0, y0, x1, y1 = first['bounds']
            for second in cards[index + 1:]:
                a0, b0, a1, b1 = second['bounds']
                overlap = max(0, min(x1, a1) - max(x0, a0)) * max(0, min(y1, b1) - max(y0, b0))
                union = (x1 - x0) * (y1 - y0) + (a1 - a0) * (b1 - b0) - overlap
                if normalize(first['text']) == normalize(second['text']):
                    demand(overlap / union >= .6, 'Ambiguous current garage card regions')
                else:
                    demand(overlap == 0, 'Conflicting complete card names in the same current region')
    card = min(cards, key=lambda row: row['bounds'][1])
    x0, y0, x1, y1 = card['bounds']
    x, start = round((x0 + x1) / 2), round((y0 + y1) / 2)
    if direction == 'earlier' or direction_changes:
        # A fixed workshop control can precede the footer. Keep corrective
        # drags inside the current card caption, never extrapolate into it.
        # Each further reversal reduces the current span, not a saved point.
        available = (y1 - y0) * .8
        span = min(available, max(15, available / (2 ** max(0, direction_changes - 1))))
        middle = (y0 + y1) / 2
        start, end = round(middle - span / 2), round(middle + span / 2)
        if direction == 'later':
            start, end = end, start
        demand(y0 < min(start, end) < max(start, end) < y1,
               'Corrective garage gesture must stay inside the current card caption')
    else:
        end = round(max(header_bottom + 8, start - max(40, (y1 - y0) * 5)))
    demand(0 <= x < width and header_bottom < min(start, end) < max(start, end) < footer_top < height and
           abs(start - end) >= 15, 'Observed vehicle-list span is too small for a controlled drag')
    return {'gesture': [x, start, x, end], 'card': card,
            'header_bottom': header_bottom, 'footer_top': footer_top,
            'direction': direction, 'target_kart': target_kart, 'direction_changes': direction_changes,
            'scope': 'Scroll gesture only; target caption and actual saved selection remain mandatory'}


def stage_garage_card_observations(source: Path, frame: dict, lines: list[dict],
                                   command, *, timeout: float = 15,
                                   clock=time.monotonic) -> dict:
    """Read complete card names from the current tab/footer-bounded raw image.

    Locked cards use blue-gray letters that the general white-text mask removes.
    Retain their original pixels and observed word rectangles. This observation
    can supply a scroll anchor only; it never selects or unlocks a vehicle.
    """
    started = clock()
    demand(math.isfinite(timeout) and timeout > 0, 'A positive garage OCR deadline is required')
    deadline = started + timeout
    demand(frame.get('acceptable_for_target_sampling') is True,
           'Cannot read garage cards on an incomplete native surface')
    raw = source.read_bytes()
    before = hashlib.sha256(raw).hexdigest()
    demand(frame.get('source') == source.name and frame.get('source_sha256') == before,
           'Current garage screenshot does not match its surface observation')
    with Image.open(io.BytesIO(raw)) as original:
        image = original.convert('RGB')
    width, height = image.size
    demand(list(image.size) == frame.get('pixels') and width > height > 0,
           'Garage OCR requires the current observed landscape dimensions')
    headers = [row for row in lines if normalize(row['text']) == 'karts']
    footers = [row for row in lines if normalize(row['text']) in
               ('kartmenu', 'menu', 'start', 'rennenstarten')]
    demand(headers and footers, 'Actual Karts tab and menu/start footer required before garage OCR')
    for row in headers + footers:
        bounds = row.get('bounds')
        demand(isinstance(bounds, (list, tuple)) and len(bounds) == 4 and
               all(isinstance(value, (int, float)) and not isinstance(value, bool) and
                   math.isfinite(value) for value in bounds), 'Invalid observed garage anchor bounds')
        x0, y0, x1, y1 = bounds
        demand(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height,
               'Observed garage anchors exceed the current screenshot')
    box = (0, math.ceil(min(row['bounds'][3] for row in headers)),
           width // 2, math.floor(min(row['bounds'][1] for row in footers)))
    demand(box[0] < box[2] and box[1] < box[3], 'Observed garage anchors do not bound a list')
    prefix = source.with_name(source.stem + '-ocr-garage-card')
    evidence = {'status': 'READING', 'source': source.name, 'source_sha256': before,
                'surface': list(image.size), 'crop': list(box), 'scale': 2,
                'language': 'eng', 'page_segmentation_mode': 11, 'confidence_minimum': 15,
                'image': prefix.with_suffix('.png').name, 'tsv': prefix.with_suffix('.tsv').name,
                'timeout_seconds': timeout, 'cards': [],
                'scope': 'Current complete OCR captions for scroll anchoring only; no vehicle selection'}
    try:
        crop = image.crop(box)
        crop.resize((crop.width * 2, crop.height * 2), Image.Resampling.LANCZOS).save(
            prefix.with_suffix('.png'))
        evidence['image_sha256'] = hashlib.sha256(prefix.with_suffix('.png').read_bytes()).hexdigest()
        remaining = deadline - clock()
        if remaining <= 0:
            raise TimeoutError('Current garage OCR deadline exceeded')
        evidence['output'] = command('tesseract', str(prefix.with_suffix('.png')), str(prefix),
                                     '--psm', '11', '-l', 'eng', 'tsv', timeout=remaining)
        raw_tsv = prefix.with_suffix('.tsv').read_bytes()
        evidence['tsv_sha256'] = hashlib.sha256(raw_tsv).hexdigest()
        rows = list(csv.DictReader(io.StringIO(raw_tsv.decode('utf-8')), delimiter='\t',
                                   quoting=csv.QUOTE_NONE))
        groups = {}
        for word in rows:
            if word.get('level') != '5' or not word.get('text', '').strip():
                continue
            demand(math.isfinite(float(word['conf'])), 'Nonfinite current garage OCR confidence')
            key = tuple(word[field] for field in ('page_num', 'block_num', 'par_num', 'line_num'))
            groups.setdefault(key, []).append(word)
        for words in groups.values():
            words.sort(key=lambda word: int(word['left']))
            # Read the whole line before filtering confidence. A low-confidence
            # extra word must not turn an unknown name into a permitted one;
            # Nala Comet must never also yield its partial caption Comet.
            caption = normalize(' '.join(word['text'] for word in words))
            numbers = [int(word['word_num']) for word in words]
            if (caption not in GARAGE_CARD_ORDER or any(float(word['conf']) < 15 for word in words)
                    or numbers != list(range(numbers[0], numbers[0] + len(words)))):
                continue
            evidence['cards'].extend(observed_matches(
                words, box, 2, image.size, caption, normalize, 'garage-raw-2x'))
        demand(hashlib.sha256(source.read_bytes()).hexdigest() == before,
               'Current garage screenshot changed during OCR')
        if clock() >= deadline:
            raise TimeoutError('Current garage OCR deadline exceeded')
        evidence['status'] = 'READ'
        return evidence
    except Exception as error:
        evidence.update(status='FAIL', error=str(error))
        raise
    finally:
        evidence['elapsed_seconds'] = round(clock() - started, 6)
        prefix.with_suffix('.json').write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + '\n')
