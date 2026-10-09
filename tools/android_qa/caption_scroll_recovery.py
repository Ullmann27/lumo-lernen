"""Bounded recovery for an actually lost Fullrace Gas settings caption.

This reader performs no capture/OCR loop and changes no application state. Its
caller supplies actual current complete frames, OCR and the native deadline.
Only observed modal geometry can authorize at most two upward scroll gestures;
the final button still needs the existing native two-target-frame touch gate.
"""
from __future__ import annotations

import copy
import math
from pathlib import Path
import time

GAS_CAPTION = 'Gas: GAS-Taste halten'


def make_gas_caption_recovery(label: str, *, scroll: str | None, context: str,
                              scroll_observation, stable_scroll_observation,
                              digest, swipe, clock=time.monotonic):
    """Keep every other caption, menu, scroll direction and default path intact."""
    if (label, scroll, context) != (GAS_CAPTION, 'down', 'pause'):
        return None
    return GasCaptionScrollRecovery(scroll_observation, stable_scroll_observation,
                                    digest, swipe, clock)


class GasCaptionScrollRecovery:
    def __init__(self, scroll_observation, stable_scroll_observation, digest, swipe, clock):
        self.observe = scroll_observation
        self.stabilize = stable_scroll_observation
        self.digest = digest
        self.swipe = swipe
        self.clock = clock
        self.previous = None
        self.previous_source = None
        self.swipes_sent = 0

    @staticmethod
    def identity(frame):
        return tuple(frame.get(key) for key in
                     ('source', 'source_sha256', 'captured_after_seconds'))

    def __call__(self, frame: dict, lines: list[dict], source: Path, *, deadline: float,
                 previous_missing_frame: dict | None = None) -> dict:
        evidence = {'target': GAS_CAPTION, 'direction': 'up', 'context': 'pause',
                    'swipes_sent': self.swipes_sent, 'maximum_recovery_swipes': 2,
                    'scope': 'current observed modal scrolling only; final target gate remains required'}
        if type(deadline) not in (int, float) or not math.isfinite(deadline):
            raise ValueError('Gas recovery requires the existing finite native deadline')
        if deadline - self.clock() <= 0:
            raise TimeoutError('Gas caption recovery exhausted the existing native deadline')
        if frame.get('acceptable_for_target_sampling') is not True:
            self.previous = self.previous_source = None
            return {**evidence, 'status': 'SURFACE_REJECTED'}
        captured = frame.get('captured_after_seconds')
        if (frame.get('source') != source.name or type(captured) not in (int, float)
                or not math.isfinite(captured) or captured < 0):
            raise RuntimeError('Gas recovery frame lacks a current bound capture identity')
        if self.swipes_sent >= 2:
            return {**evidence, 'status': 'RECOVERY_SWIPE_LIMIT_REACHED'}
        # An intervening rejected surface or observed target resets the native
        # missing-frame chain. Do not stabilize against a preceding older frame.
        if (previous_missing_frame is None or self.previous is None or
                self.identity(previous_missing_frame) != self.identity(self.previous['frame'])):
            self.previous = self.previous_source = None
        previous = self.previous
        previous_source = self.previous_source
        if previous and (frame['source'] == previous['frame']['source'] or
                         captured <= previous['frame']['captured_after_seconds']):
            self.previous = self.previous_source = None
            return {**evidence, 'status': 'STALE_FRAME_REJECTED'}
        observation = self.observe(lines, 'up', 'pause')
        current = self.stabilize(copy.deepcopy(frame), observation, previous)
        self.previous, self.previous_source = current, source
        evidence.update(current=current, previous=previous,
                        observed_captions=copy.deepcopy(lines), gesture=observation['gesture'])
        if not current['stable']:
            return {**evidence, 'status': 'WAITING_FOR_SECOND_FRESH_MODAL_FRAME'}
        if previous_source is None or self.digest(previous_source) != previous['frame']['source_sha256']:
            raise RuntimeError('Previous Gas recovery screenshot changed before input')
        if self.digest(source) != frame['source_sha256']:
            raise RuntimeError('Current Gas recovery screenshot changed before input')
        remaining = deadline - self.clock()
        if remaining <= 0:
            raise TimeoutError('Gas caption recovery exhausted the existing native deadline')
        self.swipe('shell', 'input', 'swipe', *map(str, observation['gesture']), '450',
                   timeout=min(10, remaining))
        self.swipes_sent += 1
        self.previous = self.previous_source = None
        return {**evidence, 'status': 'SWIPE_SENT', 'swipes_sent': self.swipes_sent}
