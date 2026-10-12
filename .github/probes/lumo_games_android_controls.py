"""Select live navigation controls, not the unrelated larger content scroll."""
import re


def bounds(node):
    value = list(map(int, re.findall(r'-?\d+', node.get('bounds', ''))))
    return value if len(value) == 4 and value[2] > value[0] and value[3] > value[1] else None


def navigation_scroll_bounds(nodes, package):
    navigation = []
    for node in nodes:
        if node.get('package') != package or node.get('clickable') != 'true':
            continue
        if (node.get('text', '') or node.get('content-desc', '')) in ('Start', 'Lernen', 'Spielen', 'Eltern'):
            box = bounds(node)
            if box:
                navigation.append(box)
    candidates = []
    for node in nodes:
        if node.get('package') != package or node.get('scrollable') != 'true':
            continue
        box = bounds(node)
        if box and any(box[0] <= (n[0]+n[2])/2 <= box[2] and
                       box[1] <= (n[1]+n[3])/2 <= box[3] for n in navigation):
            candidates.append(box)
    return min(candidates, key=lambda b: b[0], default=None)


def enabled_button_bounds(nodes, package, caption):
    for node in nodes:
        if (node.get('package') == package and node.get('clickable') == 'true'
                and node.get('enabled') == 'true' and node.get('visible-to-user') != 'false'
                and caption in (node.get('text', ''), node.get('content-desc', ''))):
            box = bounds(node)
            # A clipped 6px navigation sliver is not an acceptable real tap.
            if box and box[2]-box[0] >= 40 and box[3]-box[1] >= 40:
                return box
    return None
