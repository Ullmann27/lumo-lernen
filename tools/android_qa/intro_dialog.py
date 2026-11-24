"""Identify only the actual, optional first-run Lumo introduction."""
from __future__ import annotations

import re

INTRO_TITLES = frozenset((
    'Hallo, ich bin Lumo!', 'Wähle ein Fach', 'Ich helfe dir',
    'Sammle Sterne', 'Und dann: Spielen!',
))


def intro_skip_target(nodes: list[dict], package: str) -> tuple[int, int] | None:
    """Require the intro's title and one enabled, clickable app-owned Skip.

    Never dismiss a system dialog, an ordinary welcome screen, or a race
    preview merely because it contains a similarly named control.
    """
    def captions(node):
        return {line.strip() for key in ('text', 'content-desc')
                for line in (node.get(key) or '').splitlines() if line.strip()}

    app = [node for node in nodes if node.get('package') == package
           and node.get('visible-to-user') != 'false']
    if not any(captions(node) & INTRO_TITLES for node in app):
        return None
    targets = set()
    for node in app:
        if ('Überspringen' not in captions(node)
                or node.get('enabled') != 'true'
                or node.get('clickable') != 'true'):
            continue
        bounds = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',
                              node.get('bounds') or '')
        if bounds is None:
            continue
        x0, y0, x1, y1 = map(int, bounds.groups())
        if x1 - x0 >= 48 and y1 - y0 >= 48:
            targets.add(((x0 + x1) // 2, (y0 + y1) // 2))
    return next(iter(targets)) if len(targets) == 1 else None
