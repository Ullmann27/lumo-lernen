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

# The pinned native KartFleet order guides scrolling only. A choice still
# requires its complete current caption and the game's own new race save.
SPATIAL_KART_CAPTIONS = (
    'Comet', 'Gecko Velo', 'Boru Rally', 'Glider', 'Nala Comet', 'Noa Tide',
    'Iva Aurora', 'Aurora GT', 'Zuri Volt', 'Blitz', 'Terra', 'Koloss',
    'Phantom', 'Stella',
)


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


def _observed_caption(lines: list[dict], caption: str, width: int, height: int) -> dict:
    matches = [row for row in lines if normalize(row['text']) == normalize(caption)]
    demand(matches, f'Current {caption} caption is required for the vehicle list')
    for row in matches:
        bounds = row.get('bounds')
        demand(isinstance(bounds, (tuple, list)) and len(bounds) == 4 and
               all(isinstance(value, (int, float)) and not isinstance(value, bool) and
                   math.isfinite(value) for value in bounds), 'Invalid current list anchor bounds')
        x0, y0, x1, y1 = bounds
        demand(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height,
               'Current list anchor exceeds the screenshot')
    chosen = matches[0]
    x0, y0, x1, y1 = chosen['bounds']
    for row in matches[1:]:
        a0, b0, a1, b1 = row['bounds']
        intersection = max(0, min(x1, a1) - max(x0, a0)) * max(0, min(y1, b1) - max(y0, b0))
        union = (x1 - x0) * (y1 - y0) + (a1 - a0) * (b1 - b0) - intersection
        demand(intersection / union >= .6, f'Ambiguous current {caption} regions')
    return chosen


def _workshop_outline(image: Image.Image, caption: dict, top: int, bottom: int) -> list[int]:
    """Read the connected cyan outline enclosing the current workshop caption."""
    pixels, points = image.load(), set()
    for y in range(top, bottom):
        for x in range(image.width // 2):
            red, green, blue = pixels[x, y]
            if green >= 100 and blue >= 100 and green - red >= 35 and blue - red >= 35 and abs(green - blue) <= 55:
                points.add((x, y))
    cx0, cy0, cx1, cy1 = caption['bounds']
    candidates = []
    while points:
        first = points.pop()
        pending, x0, y0, x1, y1, count = [first], first[0], first[1], first[0], first[1], 0
        while pending:
            x, y = pending.pop()
            x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x), max(y1, y)
            count += 1
            for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if point in points:
                    points.remove(point)
                    pending.append(point)
        x1, y1 = x1 + 1, y1 + 1
        if (x0 < cx0 < cx1 < x1 and y0 < cy0 < cy1 < y1 and
                1.8 * (cy1 - cy0) <= y1 - y0 <= 6 * (cy1 - cy0) and
                x1 - x0 >= 1.2 * (cx1 - cx0) and x1 - x0 >= 2 * (y1 - y0) and
                count >= x1 - x0 + y1 - y0):
            candidates.append([x0, y0, x1, y1])
    demand(len(candidates) == 1, 'A unique current workshop outline is required for the vehicle list')
    return candidates[0]


def _observed_scrollbar(image: Image.Image, workshop: list[int], header_bottom: int) -> dict:
    """Locate the current narrow track and its contiguous grey thumb in pixels."""
    left, top, right, bottom = workshop
    pixels, columns = image.load(), []
    for x in range(round(right - (right - left) * .22), min(image.width // 2, round(right + image.width * .01))):
        start, thumb_rows = None, []
        for y in range(header_bottom + 1, top + 1):
            red, green, blue = pixels[x, y]
            track = 8 <= red <= 42 and 0 <= green - red <= 8 and 2 <= blue - green <= 12
            # Include the thumb's antialiased boundary, which lies between
            # its grey fill and the dark track in these original PNGs.
            thumb = 43 <= red <= 180 and abs(green - red) <= 10 and 0 <= blue - green <= 12
            if y < top and (track or thumb):
                if start is None:
                    start, thumb_rows = y, []
                if thumb:
                    thumb_rows.append(y)
            elif start is not None:
                length = y - start
                if (length >= max(40, (top - header_bottom) * .35) and
                        max(6, length * .03) <= len(thumb_rows) <= length * .4 and
                        max(thumb_rows) - min(thumb_rows) + 1 == len(thumb_rows) and
                        top - y <= max(10, (bottom - top) * .35)):
                    columns.append([x, start, y, min(thumb_rows), max(thumb_rows) + 1])
                start = None
    demand(columns, 'No current vehicle-list scrollbar track and thumb observed')
    longest = max(row[2] - row[1] for row in columns)
    columns = [row for row in columns if row[2] - row[1] >= longest * .98]
    groups = []
    for row in columns:
        if (not groups or row[0] - groups[-1][-1][0] > 3 or
                any(abs(row[index] - groups[-1][-1][index]) > 3 for index in (1, 2, 3, 4))):
            groups.append([])
        groups[-1].append(row)
    groups = [group for group in groups if len(group) >= 3 and
              group[-1][0] - group[0][0] + 1 <= max(6, longest * .08)]
    demand(len(groups) == 1, 'Ambiguous or incomplete current vehicle-list scrollbar')
    group = groups[0]
    track_bounds = [group[0][0], max(row[1] for row in group), group[-1][0] + 1, min(row[2] for row in group)]
    thumb_bounds = [track_bounds[0], max(row[3] for row in group), track_bounds[2], min(row[4] for row in group)]
    demand(track_bounds[1] <= thumb_bounds[1] < thumb_bounds[3] <= track_bounds[3],
           'Current scrollbar thumb is outside its track')
    return {'track_bounds': track_bounds, 'thumb_bounds': thumb_bounds,
            'sampled_columns': len(group)}


def stage_kart_target_observation(frame: dict, lines: list[dict], kart: str,
                                  viewport_bounds: list[int]) -> dict | None:
    """Only a complete, unambiguous current name inside the clip permits a tap."""
    demand(kart in KARTS and frame.get('acceptable_for_target_sampling') is True,
           'A complete current vehicle surface and known kart are required')
    left, top, right, bottom = viewport_bounds
    width, height = frame['pixels']
    demand(0 <= left < right <= width and 0 <= top < bottom <= height,
           'Current vehicle viewport is outside the screenshot')
    matches = [row for row in lines if normalize(row['text']) == normalize(KARTS[kart])]
    inside = []
    for row in matches:
        bounds = row.get('bounds')
        demand(isinstance(bounds, (list, tuple)) and len(bounds) == 4 and
               all(isinstance(value, (int, float)) and not isinstance(value, bool) and
                   math.isfinite(value) for value in bounds), 'Invalid current kart caption bounds')
        x0, y0, x1, y1 = bounds
        # A clipped glyph's OCR rectangle can touch the clip edge while still
        # spelling the requested name. Keep a real interior margin there.
        margin = max(2, (y1 - y0) * .15)
        if left + margin < x0 < x1 < right - margin and top + margin < y0 < y1 < bottom - margin:
            inside.append(row)
    if not inside:
        return None
    selected = _observed_caption(inside, KARTS[kart], width, height)
    return {'target': selected, 'matching_observations': len(inside),
            'viewport_bounds': viewport_bounds,
            'scope': 'Complete current caption inside the observed card clip; race save still mandatory'}


def stage_garage_scroll_observation(frame: dict, lines: list[dict], *, source: Path,
                                    kart: str = 'gecko_velo') -> dict:
    """Observe the real short list even when no complete card name is visible.

    The scrollbar's current pixels bound the vertical clip; the separately
    observed aligned workshop outline bounds its horizontal interior. Neither
    the tab/footer gap nor a remembered caption is a scrolling rectangle.
    """
    demand(frame.get('acceptable_for_target_sampling') is True,
           'Cannot scroll an incomplete native surface')
    width, height = frame['pixels']
    demand(width > height > 0, 'Expected the actual landscape Garage')
    demand(kart in KARTS, 'Unknown requested spatial kart')
    source = Path(source)
    raw = source.read_bytes()
    demand(source.name == frame.get('source') and len(raw) == frame.get('source_bytes') and
           hashlib.sha256(raw).hexdigest() == frame.get('source_sha256'),
           'Current vehicle-list screenshot identity changed')
    with Image.open(io.BytesIO(raw)) as opened:
        demand(opened.format == 'PNG' and opened.size == (width, height),
               'Current vehicle-list screenshot dimensions or format differ')
        image = opened.convert('RGB')
    header = _observed_caption(lines, 'Karts', width, height)
    workshop_caption = _observed_caption(lines, 'Lack, Teile & Effekte', width, height)
    footer = _observed_caption(lines, 'Rennen starten', width, height)
    header_bottom, footer_top = math.ceil(header['bounds'][3]), math.floor(footer['bounds'][1])
    demand(header_bottom < workshop_caption['bounds'][1] < workshop_caption['bounds'][3] < footer_top and
           workshop_caption['bounds'][2] < width * .5,
           'Current workshop does not separate the left list from the race footer')
    workshop = _workshop_outline(image, workshop_caption, header_bottom + 1, footer_top)
    scrollbar = _observed_scrollbar(image, workshop, header_bottom)
    rail, thumb = scrollbar['track_bounds'], scrollbar['thumb_bounds']
    margin = max(3, math.ceil((workshop[2] - workshop[0]) * .02))
    viewport = [workshop[0] + margin, rail[1], rail[0] - margin, rail[3]]
    left, top, right, bottom = viewport
    demand(0 <= left < right < width * .5 and header_bottom < top < bottom < workshop[1] < footer_top and
           right - left >= 4 * margin and bottom - top >= 60,
           'Current card viewport is too small or conflicts with the workshop')
    order = {normalize(caption): index for index, caption in enumerate(SPATIAL_KART_CAPTIONS)}
    cards = [row for row in lines if normalize(row['text']) in order and
             left < row['bounds'][0] < row['bounds'][2] < right and
             top + 2 < row['bounds'][1] < row['bounds'][3] < bottom - 2]
    target_index = order[normalize(KARTS[kart])]
    visible_indices = {order[normalize(row['text'])] for row in cards}
    travel = (rail[3] - rail[1]) - (thumb[3] - thumb[1])
    demand(travel > 0, 'Current scrollbar has no observed travel')
    fraction = (thumb[1] - rail[1]) / travel
    if visible_indices and max(visible_indices) < target_index:
        direction, basis = 'forward', 'complete current cards precede the requested kart'
    elif visible_indices and min(visible_indices) > target_index:
        direction, basis = 'backward', 'complete current cards follow the requested kart'
    else:
        # The fixed, checked native order guides direction through a clipped
        # gap only. No inferred card position can authorize a selection tap.
        direction = 'backward' if fraction >= target_index / (len(order) - 1) else 'forward'
        basis = 'current scrollbar position and pinned native order; direction only'
    distance = max(15, round((bottom - top) * .1))
    center = (top + bottom) / 2
    start, end = round(center + distance / 2), round(center - distance / 2)
    if direction == 'backward':
        start, end = end, start
    x = round((left + right) / 2)
    demand(left < x < right and top + margin < min(start, end) < max(start, end) < bottom - margin,
           'Current vehicle-list gesture exceeds the observed interior')
    return {'gesture': [x, start, x, end], 'direction': direction, 'direction_basis': basis,
            'viewport_bounds': viewport, 'workshop_bounds': workshop, 'scrollbar': scrollbar,
            'scroll_fraction': fraction, 'visible_cards': cards,
            'header_bottom': header_bottom, 'footer_top': footer_top,
            'source_sha256': frame['source_sha256'],
            'scope': 'Observed conservative card interior for scrolling only; exact target and actual race remain mandatory'}
