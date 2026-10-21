"""Judge the Flutter -> Lumo Kart -> race -> pause -> Flutter tour from real data.

Every check reads actual emulator evidence: adb screenshots, the race session
the game itself persisted, and Flutter's SharedPreferences. Nothing is
injected into the app. A colourful garage, a log line or a resumed activity
alone never counts as a started race, a driving kart or a working return.
"""
from __future__ import annotations

import io
import json
import math

from PIL import Image, ImageChops, ImageStat

# Learning data that a paused Kart session must leave untouched. Keys are
# stored per child as "<base>::<studentId>"; Flutter adds the "flutter." prefix.
LEARNING_PREFIXES = (
    'flutter.lumo_progress', 'flutter.lumo_writing_progress', 'flutter.lumo_journal',
    'flutter.lumo_story_library', 'flutter.lumo_reading_sessions', 'flutter.lumo_attempt_log',
    'flutter.lumo_reward_wallet', 'flutter.lumo_school', 'flutter.lumo_learning',
    'flutter.lumo_legacy',
)
PROFILE_KEY = 'flutter.lumo_active_profile'
# lastActiveAt is refreshed whenever the profile is saved; it is not learning data.
PROFILE_FIELDS = ('id', 'name', 'age', 'grade', 'createdAt')


def _rgb(png: bytes) -> Image.Image:
    return Image.open(io.BytesIO(png)).convert('RGB')


def rendered_race_frame(png: bytes) -> dict:
    """Reject black, clipped or flat frames; same limits as lumo-godot check_android_frame."""
    image = _rgb(png)
    width, height = image.size
    if width <= height or width < 320 or height < 160:
        raise RuntimeError(f'Expected a landscape race frame; got {width}x{height}')
    pixels = image.load()
    fractions, detail = [], []
    # Exclude Android's status/navigation bars and inspect each third of the image.
    for third in range(3):
        count = visible = bright = 0
        colours = set()
        for y in range(height // 8, height * 7 // 8, 3):
            for x in range(width * third // 3 + 3, width * (third + 1) // 3 - 3, 3):
                rgb = pixels[x, y]
                visible += max(rgb) > 24
                bright += max(rgb) >= 80
                colours.add(tuple(value // 16 for value in rgb))
                count += 1
        fraction = visible / max(1, count)
        fractions.append(round(fraction, 3))
        if fraction < 0.65:
            raise RuntimeError(f'Black/clipped race region in third {third + 1}: {fraction:.1%} visible')
        bright_fraction = bright / max(1, count)
        if len(colours) < 8 or bright_fraction < 0.2:
            raise RuntimeError(f'Blank race region in third {third + 1}: '
                               f'{len(colours)} colour bins, {bright_fraction:.1%} bright')
        detail.append({'colour_bins': len(colours), 'bright_fraction': round(bright_fraction, 3)})
    return {'size': [width, height], 'visible_fractions': fractions, 'detail': detail}


def _central_difference(first: bytes, second: bytes, box) -> dict:
    a, b = _rgb(first), _rgb(second)
    if a.size != b.size:
        raise RuntimeError(f'Compared screenshots differ in size: {a.size} / {b.size}')
    region = box(a.width, a.height)
    one, two = a.crop(region), b.crop(region)
    one.thumbnail((400, 200))
    two = two.resize(one.size)
    diff = ImageChops.difference(one, two)
    flattened = getattr(diff, 'get_flattened_data', diff.getdata)  # getdata leaves in Pillow 14
    data = list(flattened())
    changed = sum(1 for pixel in data if sum(pixel) >= 96) / max(1, len(data))
    mean = sum(ImageStat.Stat(diff).mean) / 3
    return {'changed_fraction': round(changed, 3), 'mean_channel_delta': round(mean, 2)}


def garage_replaced(garage: bytes, race: bytes) -> dict:
    """The race view must differ substantially from the last garage step."""
    report = _central_difference(garage, race, lambda w, h: (w // 12, h // 8, w * 11 // 12, h * 7 // 8))
    if report['changed_fraction'] < .22 or report['mean_channel_delta'] < 18:
        raise RuntimeError(f'Android still shows the garage, not the race: {report}')
    return report


def world_moved(before: bytes, after: bytes) -> dict:
    """While GAS is held the chase camera must carry the 3D world past the kart.

    The HUD bar, minimap and touch controls stay put, so only the central
    world view is compared. Thresholds are deliberately modest: the native
    session distance is the primary proof that the kart drove.
    """
    report = _central_difference(before, after, lambda w, h: (w // 6, h // 5, w * 5 // 6, h * 4 // 5))
    if report['changed_fraction'] < .08 or report['mean_channel_delta'] < 6:
        raise RuntimeError(f'The rendered world did not move while GAS was held: {report}')
    return report


def require_race_session(state: dict, *, track: str = 'sonnenhafen', mode: str = 'race') -> None:
    if state.get('track_id') != track or state.get('mode') != mode:
        raise RuntimeError(f'Saved race belongs to {state.get("mode")}/{state.get("track_id")}, '
                           f'not {mode}/{track}')
    if state.get('finished') or state.get('completed_race'):
        raise RuntimeError('Saved race is already finished')
    for key in ('distance', 'elapsed'):
        value = state.get(key)
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
            raise RuntimeError(f'Saved race field {key} is not a finite number')


def race_running(state: dict, *, track: str = 'sonnenhafen', mode: str = 'race') -> bool:
    """True once the countdown is over and the race clock has run for a second."""
    require_race_session(state, track=track, mode=mode)
    return state['countdown'] <= 0 and state['elapsed'] >= 1.0


def driving_progress(start: dict, later: dict, *, min_distance: float = 8.0,
                     min_elapsed: float = 2.5, track: str = 'sonnenhafen',
                     mode: str = 'race') -> dict:
    """The same live race advanced: the kart covered distance and the clock ran."""
    require_race_session(start, track=track, mode=mode)
    require_race_session(later, track=track, mode=mode)
    if start['result_id'] != later['result_id']:
        raise RuntimeError('Driving evidence spans two different races')
    distance = later['distance'] - start['distance']
    elapsed = later['elapsed'] - start['elapsed']
    report = {'result_id': later['result_id'], 'distance_gain': round(distance, 2),
              'elapsed_gain': round(elapsed, 2), 'checkpoint_index': later['checkpoint_index']}
    if distance < min_distance or elapsed < min_elapsed:
        raise RuntimeError(f'The kart did not actually drive: {report}')
    return report


def paused_unchanged(first: dict, second: dict, *, track: str = 'sonnenhafen',
                     mode: str = 'race') -> dict:
    """While the pause menu is open the saved race must not advance."""
    require_race_session(first, track=track, mode=mode)
    require_race_session(second, track=track, mode=mode)
    keys = ('result_id', 'distance', 'elapsed', 'checkpoint_index', 'finished')
    changed = {key: [first.get(key), second.get(key)] for key in keys if first.get(key) != second.get(key)}
    if changed:
        raise RuntimeError(f'The race advanced while paused: {changed}')
    return {key: first[key] for key in keys}


def _profile(prefs: dict) -> dict:
    raw = prefs.get(PROFILE_KEY)
    if not raw:
        raise RuntimeError('No active child profile is stored')
    data = json.loads(raw)
    return {field: data.get(field) for field in PROFILE_FIELDS}


def learning_snapshot(prefs: dict) -> dict:
    return {key: value for key, value in prefs.items() if key.startswith(LEARNING_PREFIXES)}


def learning_preserved(before: dict, after: dict) -> dict:
    """Profile and learning data survive Kart, pause and return exactly."""
    profile_before, profile_after = _profile(before), _profile(after)
    if profile_before != profile_after:
        raise RuntimeError(f'Active child profile changed: {profile_before} -> {profile_after}')
    old, new = learning_snapshot(before), learning_snapshot(after)
    if not old:
        raise RuntimeError('No learning data was stored before the Kart session')
    missing = sorted(set(old) - set(new))
    changed = sorted(key for key in old if key in new and new[key] != old[key])
    if missing or changed:
        raise RuntimeError(f'Learning data lost or changed by the Kart session: '
                           f'missing={missing} changed={changed}')
    return {'profile': profile_after, 'learning_keys_compared': len(old),
            'learning_keys_added': sorted(set(new) - set(old))}


def labels_still_present(before: list[str], after: list[str], *, minimum: float = .6) -> dict:
    """The same Flutter page offers (mostly) the same controls after the return."""
    old = {label for label in before if label.strip()}
    new = {label for label in after if label.strip()}
    if not old:
        raise RuntimeError('No accessible labels were recorded before the Kart session')
    kept = len(old & new) / len(old)
    report = {'labels_before': len(old), 'labels_after': len(new), 'kept_fraction': round(kept, 3)}
    if kept < minimum:
        raise RuntimeError(f'The learning page lost its controls after the return: {report}, '
                           f'missing={sorted(old - new)[:20]}')
    return report
