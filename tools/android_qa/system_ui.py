"""Read-only recognition of the one observed emulator launcher ANR.

This module never touches a device. Callers must retain the current XML and
screenshot before deciding whether to tap the returned Close app rectangle.
"""
from __future__ import annotations

import re
import xml.etree.ElementTree as ET


PIXEL_LAUNCHER_ANR_TITLE = "Pixel Launcher isn't responding"
_RECTANGLE = re.compile(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]')


def _bounds(node):
    match = _RECTANGLE.fullmatch(node.get('bounds', ''))
    if not match:
        return None
    left, top, right, bottom = map(int, match.groups())
    return (left, top, right, bottom) if right > left and bottom > top else None


def _contains(outer, inner):
    return (outer[0] <= inner[0] < inner[2] <= outer[2]
            and outer[1] <= inner[1] < inner[3] <= outer[3])


def pixel_launcher_anr_close_bounds(root: ET.Element) -> tuple[int, int, int, int] | None:
    """Return a safe Close app target only for the exact Pixel Launcher ANR.

    Require the three observed English captions, unique Android system nodes,
    both enabled clickable actions and a shared visible dialog container.
    Other app failures, ambiguous labels and clipped/invalid targets fail closed.
    No substring matching, coordinate fallback, input or XML mutation occurs.
    """
    visible = [node for node in root.iter('node')
               if node.get('visible-to-user', 'true') == 'true'
               and node.get('displayed', 'true') == 'true']
    selected = []
    for caption, resource_id, clickable in (
        (PIXEL_LAUNCHER_ANR_TITLE, 'android:id/alertTitle', False),
        ('Close app', 'android:id/aerr_close', True),
        ('Wait', 'android:id/aerr_wait', True),
    ):
        matches = [node for node in visible if node.get('text') == caption]
        if len(matches) != 1:
            return None
        node = matches[0]
        if (node.get('package') != 'android'
                or node.get('resource-id') != resource_id
                or node.get('enabled') != 'true'
                or (clickable and node.get('clickable') != 'true')
                or _bounds(node) is None):
            return None
        selected.append(node)

    # A second visible system title makes the current dialog ambiguous, even
    # if one title happens to contain the expected launcher caption.
    if any(node.get('package') == 'android'
           and node.get('resource-id') == 'android:id/alertTitle'
           and node is not selected[0] for node in visible):
        return None

    parents = {child: parent for parent in root.iter() for child in parent}

    def ancestors(node):
        path = [node]
        while node in parents:
            node = parents[node]
            path.append(node)
        return path

    paths = [ancestors(node) for node in selected]
    common = next((node for node in paths[1]
                   if node in paths[0] and node in paths[2]), None)
    if (common is None or common.get('package') != 'android'
            or common.get('enabled') != 'true'
            or common not in visible):
        return None
    boxes = [_bounds(node) for node in selected]
    container = _bounds(common)
    if container is None or any(not _contains(container, box) for box in boxes):
        return None
    close, wait = boxes[1:]
    if (max(close[0], wait[0]) < min(close[2], wait[2])
            and max(close[1], wait[1]) < min(close[3], wait[3])):
        return None
    # Respect clipping and visibility on every enclosing system layout too.
    for node in paths[1][1:]:
        if node.tag != 'node':
            continue
        if node not in visible or node.get('enabled') != 'true':
            return None
        enclosing = _bounds(node)
        if enclosing is None or not _contains(enclosing, close):
            return None
    return close
