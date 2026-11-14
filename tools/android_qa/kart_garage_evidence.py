"""Reusable Garage/Continue evidence from PR #456, without historical APK pins.

Inputs are observed screenshots and the game's own saved session. These
validators never create a selection, race, elapsed time or driving progress.
"""
from __future__ import annotations

import math
import unicodedata


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


def stage_driver_target_observation(frame: dict, lines: list[dict]) -> dict:
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


def stage_garage_scroll_observation(frame: dict, lines: list[dict]) -> dict:
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
    cards = [row for row in lines if normalize(row['text']) in
             ('comet', 'geckovelo', 'borurally', 'glider', 'nalacomet', 'noatide') and
             0 < row['bounds'][0] < row['bounds'][2] < width * .50 and
             header_bottom < row['bounds'][1] < row['bounds'][3] < footer_top]
    demand(cards, 'No currently visible vehicle card in the actual left list')
    card = min(cards, key=lambda row: row['bounds'][1])
    x0, y0, x1, y1 = card['bounds']
    x, start = round((x0 + x1) / 2), round((y0 + y1) / 2)
    end = round(max(header_bottom + 8, start - max(40, (y1 - y0) * 5)))
    demand(0 <= x < width and header_bottom < end < start < footer_top < height and
           start - end >= 15, 'Observed vehicle-list span is too small for a controlled drag')
    return {'gesture': [x, start, x, end], 'card': card,
            'header_bottom': header_bottom, 'footer_top': footer_top,
            'scope': 'Scroll gesture only; target caption and actual saved selection remain mandatory'}
