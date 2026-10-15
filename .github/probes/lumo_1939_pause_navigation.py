"""1939 visual acceptance: reuse the complete-race observed modal navigation.

Copied from kart_complete_android_probe.tap_native without changing its caption,
full-surface, stable-frame, footer, scroll or final touch gates. Application state
is never written; only the real visible pause menu receives ordinary gestures.
"""
import json
from pathlib import Path
import time
import creative_android_probe as creative
from kart_complete_android_probe import scroll_observation, stable_scroll_observation

base = creative.base


def tap_pause_setting(out: Path, label: str, tag: str, *, scroll: str | None = None, context: str = 'pause') -> None:
    def write_json(name, value):
        (out / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')

    wanted = creative.normalized(label)
    initial_gas_search = (
        label == 'Gas: GAS-Taste halten' and scroll == 'down' and context == 'pause'
    )
    initial_gas_direction = 'down'
    deadline, previous_scroll = time.monotonic() + 180, None
    for attempt in range(10):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError('Observed native action preparation exceeded 180 seconds')
        capture = creative.capture(out, f'{tag}-{attempt}', timeout=remaining)
        source = out / capture['file']
        frame = creative.inspect_surface(source)
        if not frame['acceptable_for_target_sampling']:
            previous_scroll = None
            write_json(f'{tag}-{attempt}-observed-scroll.json', {'status': 'SURFACE_REJECTED', 'frame': frame})
            continue
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError('Observed native action preparation exceeded 180 seconds')
        lines = creative.image_lines(out, f'{tag}-{attempt}', wanted, exact=True,
                                     source_path=source, timeout=remaining)
        matches = [row for row in lines if creative.normalized(row['text']) == wanted]
        if matches:
            # The final action also needs the shared current-full-surface
            # and two-frame target gate, with this exact caption retained.
            from caption_scroll_recovery import make_gas_caption_recovery
            recovery = make_gas_caption_recovery(
                label, scroll=scroll, context=context,
                scroll_observation=scroll_observation,
                stable_scroll_observation=stable_scroll_observation,
                digest=creative.digest, swipe=base.adb, clock=time.monotonic)
            if recovery is None:
                creative.native_text(out, label, tag + '-stable-action', tap=True, exact=True)
            else:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError('Observed native action preparation exceeded 180 seconds')
                creative.native_tap(out, label, tag + '-stable-action',
                                    timeout=min(120, remaining), exact=True,
                                    missing_caption=recovery)
            return
        if scroll and attempt >= 1:
            direction = initial_gas_direction if initial_gas_search else scroll
            observation = scroll_observation(lines, direction, context)
            swipe_duration = 450
            if initial_gas_search:
                # Use only captions that passed the existing current-modal
                # footer and bounds checks. Keep the recovery direction
                # after the list end leaves the following viewport.
                captions = {row['caption'] for row in observation['selected_captions']}
                if {'neuefahrtauswahlen', 'rennenabbrechen'} <= captions:
                    initial_gas_direction = 'up'
                    observation = scroll_observation(lines, initial_gas_direction, context)
                # A slow half-span drag keeps consecutive settings views
                # overlapping instead of flinging past the middle rows.
                full_gesture = list(observation['gesture'])
                x0, y0, x1, y1 = full_gesture
                distance = max(1, abs(y1 - y0) // 2)
                bounded_y1 = y0 + (distance if y1 > y0 else -distance)
                observation = {
                    **observation,
                    'gesture': [x0, y0, x1, bounded_y1],
                    'unbounded_gesture': full_gesture,
                    'drag_duration_ms': 900,
                }
                swipe_duration = 900
            current = stable_scroll_observation(frame, observation, previous_scroll)
            evidence = {
                'target': label, 'direction': observation['direction'], 'observed_captions': lines,
                'gesture': observation['gesture'], 'current': current,
                'previous': previous_scroll, 'status': 'WAITING_FOR_STABLE_MODAL',
                'scope': 'two complete current frames; gesture inside observed modal captions',
            }
            previous_scroll = current
            if not current['stable']:
                write_json(f'{tag}-{attempt}-observed-scroll.json', evidence)
                continue
            if creative.digest(source) != frame['source_sha256']:
                raise RuntimeError('The observed scroll screenshot changed before input')
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('Observed native action preparation exceeded 180 seconds')
            base.adb('shell', 'input', 'swipe', *map(str, observation['gesture']), str(swipe_duration),
                     timeout=min(10, remaining))
            evidence['status'] = 'SWIPE_SENT'
            write_json(f'{tag}-{attempt}-observed-scroll.json', evidence)
            previous_scroll = None
            time.sleep(1.5)
            continue
        time.sleep(1)
    raise RuntimeError('Exact current native action caption is missing: ' + label)
