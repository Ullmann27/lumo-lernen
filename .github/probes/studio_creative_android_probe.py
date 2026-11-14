#!/usr/bin/env python3
"""Additional real-input Android evidence for the unchanged Studio candidate.

The committed candidate normally supplies its observation helpers. An explicit
unchanged-APK diagnostic may instead bind a separate committed QA checkout;
the APK, native source and original build identity remain independent inputs.
This probe never writes app preferences or game saves. Recorded motion needs
human review; screenrecord timestamps and saves do not measure game FPS/physics.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
import traceback
import zipfile

from PIL import Image

ARTIFACT = 'lumo-studio-2019-candidate'
CANDIDATE_WORKFLOWS = {
    '.github/workflows/lumo-studio-2019.yml': ARTIFACT,
    '.github/workflows/lumo-kart-graphics-2019.yml': 'lumo-kart-graphics-2019-candidate',
}
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
PUZZLE_MOTIF_CAPTIONS = (
    'Bild: Lumos Mondschloss', 'Bild: Candy Cloud Circuit', 'Bild: Volcano Night Run',
    'Bild: Leuchtturm-Bucht', 'Bild: Blütenwiese',
)


def sha(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')


def read_image(path: Path) -> Image.Image:
    with Image.open(path) as source:
        return source.convert('RGB')


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def full_caption_choice(lines: list[dict], captions: tuple[str, ...], normalize) -> dict:
    """Require one complete known caption at one observed physical control."""
    allowed = {normalize(caption) for caption in captions}
    matches = [line for line in lines if isinstance(line.get('text'), str)
               and normalize(line['text']) in allowed]
    require(bool(matches), 'No complete source-confirmed selection caption in the current screenshot')
    for line in matches:
        rect = line.get('bounds')
        require(isinstance(rect, (list, tuple)) and len(rect) == 4
                and all(type(value) in (int, float) and math.isfinite(value) for value in rect)
                and 0 <= rect[0] < rect[2] and 0 <= rect[1] < rect[3],
                'Complete selection caption has invalid observed bounds')
    chosen = matches[0]
    a = chosen['bounds']
    for line in matches[1:]:
        b = line['bounds']
        intersection = max(0, min(a[2], b[2]) - max(a[0], b[0])) * \
                       max(0, min(a[3], b[3]) - max(a[1], b[1]))
        union = (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - intersection
        require(normalize(line['text']) == normalize(chosen['text']) and intersection / union >= .6,
                'Ambiguous complete selection captions or separate physical controls')
    return chosen


def treasure_movement_duration(distance: float, segments: list[dict]) -> int:
    """Use observed approach per real hold, never assume emulator physics rate."""
    require(type(distance) in (int, float) and math.isfinite(distance) and distance >= 3.4,
            'Invalid remaining first-clue distance')
    rates = []
    for segment in segments:
        before, after, milliseconds = (segment.get(key) for key in
                                       ('distance_before', 'distance_after', 'milliseconds'))
        require(all(type(value) in (int, float) and math.isfinite(value) and value >= 0
                    for value in (before, after))
                and type(milliseconds) is int and 100 <= milliseconds <= 1800
                and before - after > .1,
                'A movement estimate requires actual positive bounded approach')
        rates.append((before - after) / (milliseconds / 1000))
    if not rates:
        return 1500
    recent = sorted(rates[-3:])
    observed_rate = recent[len(recent) // 2]
    return round(min(1800, max(220, (distance - 2.8) / observed_rate * 1000)))


def jump_action_choice(lines: list[dict], pixels: list[int], normalize) -> dict:
    """JumpAction is the source-defined lower-right control, below the spacer."""
    require(isinstance(pixels, (list, tuple)) and len(pixels) == 2
            and all(type(value) is int and value > 0 for value in pixels),
            'Jump action requires actual screenshot dimensions')
    width, height = pixels
    choices = []
    for line in lines:
        if not isinstance(line.get('text'), str) or normalize(line['text']) != normalize('SPRINGEN'):
            continue
        rect = line.get('bounds')
        require(isinstance(rect, (list, tuple)) and len(rect) == 4
                and all(type(value) in (int, float) and math.isfinite(value) for value in rect),
                'Jump caption has invalid observed bounds')
        x0, y0, x1, y1 = rect
        if (0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height
                and (x0 + x1) / (2 * width) > .65 and (y0 + y1) / (2 * height) > .65):
            choices.append(line)
    return full_caption_choice(choices, ('SPRINGEN',), normalize)


def build_pause_observation(lines: list[dict], frame: dict, normalize) -> dict | None:
    """Distinguish the real pause panel from the title and walk-mode caption."""
    if not frame['acceptable_for_target_sampling']:
        return None
    width, height = frame['pixels']

    def matches(caption):
        return [line for line in lines if isinstance(line.get('text'), str)
                and normalize(line['text']) == normalize(caption)]

    headings = matches('Deine Welt wartet auf dich')
    resume = matches('Weiterbauen')
    # Weiterbauen also labels the top-right walk-mode switch. That occurrence
    # alone is never evidence of the central pause panel.
    central_resume = [line for line in resume if isinstance(line.get('bounds'), (list, tuple))
                      and len(line['bounds']) == 4
                      and all(type(value) in (int, float) and math.isfinite(value)
                              for value in line['bounds'])
                      and .35 < (line['bounds'][0] + line['bounds'][2]) / (2 * width) < .65]
    if headings or central_resume:
        if not headings or not central_resume:
            return None
        heading = full_caption_choice(headings, ('Deine Welt wartet auf dich',), normalize)
        action = full_caption_choice(central_resume, ('Weiterbauen',), normalize)
        hx0, hy0, hx1, hy1 = heading['bounds']
        ax0, ay0, ax1, ay1 = action['bounds']
        require(.30 < (hx0 + hx1) / (2 * width) < .70
                and .20 * height < hy0 < hy1 < ay0 < ay1 < .85 * height,
                'Build pause heading/action do not form the observed source panel')
        return {'state': 'paused', 'target': action, 'heading': heading}
    titles, modes = matches('LUMO BAUWELT'), matches('Mit Lumo laufen')
    if not titles or not modes:
        return None
    title = full_caption_choice(titles, ('LUMO BAUWELT',), normalize)
    action = full_caption_choice(modes, ('Mit Lumo laufen',), normalize)
    tx0, ty0, tx1, ty1 = title['bounds']
    ax0, ay0, ax1, ay1 = action['bounds']
    require((tx0 + tx1) / (2 * width) < .45 and ty1 < .30 * height
            and (ax0 + ax1) / (2 * width) > .70 and ay1 < .30 * height,
            'Build editor anchors are outside their current header positions')
    return {'state': 'active', 'target': action, 'heading': title}


def verify_candidate_metadata(run: dict, artifacts: dict, jobs: dict, expected: dict) -> dict:
    host, native, run_id = (expected.get(key) for key in ('host_source', 'native_source', 'build_run'))
    workflow = expected.get('workflow_path')
    require(isinstance(workflow, str) and workflow in CANDIDATE_WORKFLOWS,
            'An explicit supported candidate workflow is required')
    require(all(isinstance(value, str) and re.fullmatch(r'[a-f0-9]{40}', value)
                for value in (host, native)), 'Immutable source SHAs are required')
    require(type(run_id) is int and run_id > 0
            and type(expected.get('artifact_id')) is int and expected['artifact_id'] > 0,
            'Current build run and uploaded artifact IDs are required')
    require(isinstance(expected.get('artifact_digest'), str)
            and re.fullmatch(r'sha256:[a-f0-9]{64}', expected['artifact_digest']),
            'Current upload step digest is required')
    require(run.get('id') == run_id and run.get('head_sha') == host,
            'Candidate run is not the immutable requested host source')
    require(run.get('repository', {}).get('full_name') == 'Ullmann27/lumo-lernen',
            'Candidate run belongs to another repository')
    require(run.get('path') == workflow,
            'Candidate was not built by the explicitly requested current workflow')
    rows = [x for x in artifacts.get('artifacts', [])
            if x.get('name') == CANDIDATE_WORKFLOWS[workflow]]
    require(len(rows) == 1, 'Exactly one real candidate artifact is required')
    artifact = rows[0]
    require(artifact.get('id') == expected['artifact_id']
            and artifact.get('digest') == expected['artifact_digest'],
            'Artifact differs from this verify-and-build upload step')
    require(artifact.get('expired') is False and type(artifact.get('size_in_bytes')) is int
            and artifact['size_in_bytes'] > 0,
            'Candidate artifact is expired or empty')
    require(artifact.get('workflow_run', {}).get('id') == run_id
            and artifact.get('workflow_run', {}).get('head_sha') == host,
            'Candidate artifact source does not match the build')
    require(bool(re.fullmatch(r'sha256:[a-f0-9]{64}', artifact.get('digest', ''))),
            'Candidate artifact lacks its actual GitHub digest')
    builders = [x for x in jobs.get('jobs', [])
                if x.get('name') == 'verify-and-build']
    require(len(builders) == 1 and builders[0].get('conclusion') == 'success'
            and builders[0].get('status') == 'completed'
            and builders[0].get('run_id') == run_id and builders[0].get('head_sha') == host,
            'The real verify-and-build job did not succeed')
    return {'artifact': artifact, 'build_job_id': builders[0]['id'],
            'host_source': host, 'native_source': native, 'build_run': run_id,
            'workflow_path': workflow,
            'scope': 'Original build artifact; other main-run tours are independent'}


def candidate_binding(args) -> dict:
    pin = json.loads((args.candidate_source / 'config/godot-source.json').read_text())
    require(pin.get('repository') == 'https://github.com/Ullmann27/lumo-godot.git',
            'Unexpected native repository')
    expected = {'host_source': args.expected_source, 'native_source': pin.get('revision'),
                'build_run': args.build_run, 'artifact_id': args.artifact_id,
                'workflow_path': args.workflow_path,
                'artifact_digest': 'sha256:' + args.artifact_digest.removeprefix('sha256:')}
    return verify_candidate_metadata(*[
        json.loads((args.metadata_dir / name).read_text())
        for name in ('run.json', 'artifacts.json', 'jobs.json')], expected)


def committed_helper(source: Path, module, relative: str) -> None:
    path = source / relative
    require(Path(module.__file__).resolve() == path.resolve(),
            'Imported helper did not come from its bound committed checkout')
    original = subprocess.run(['git', '-C', str(source), 'show', 'HEAD:' + relative],
                              check=True, capture_output=True, timeout=30).stdout
    require(path.read_bytes() == original,
            'Observation helper differs from its immutable committed bytes: ' + relative)


def bounds(value: str) -> list[int] | None:
    result = list(map(int, re.findall(r'-?\d+', value)))
    return result if len(result) == 4 else None


def hub_choice(nodes: list[dict], title: str, size: tuple[int, int],
               minimum: float) -> dict | None:
    """Current318 _GameTile uses one full title/tagline/status Semantics node."""
    choices = []
    for node in nodes:
        if node.get('package') != PACKAGE or node.get('enabled') != 'true':
            continue
        if node.get('clickable') != 'true':
            continue
        for caption in (node.get('content-desc', ''), node.get('text', '')):
            if not (caption.startswith(title + '. ') and caption.endswith(' Spielen')):
                continue
            rect = bounds(node.get('bounds', ''))
            if rect is None:
                continue
            x0, y0, x1, y1 = rect
            if (0 <= x0 < x1 <= size[0] and 0 <= y0 < y1 <= size[1]
                    and min(x1 - x0, y1 - y0) >= minimum):
                record = {'caption': caption, 'bounds': rect}
                if record not in choices:
                    choices.append(record)
    require(len(choices) <= 1, 'Ambiguous live game tile: ' + title)
    return choices[0] if choices else None


def pieces(data: dict, key: str) -> dict:
    result = {x[key]: x for x in data['pieces']}
    require(len(result) == len(data['pieces']), 'Duplicate piece identities in save')
    return result


def one_added_piece(before: dict, after: dict) -> dict:
    left, right = pieces(before, 'uid'), pieces(after, 'uid')
    new = set(right) - set(left)
    require(len(new) == 1 and set(left) <= set(right)
            and all(right[k] == v for k, v in left.items()),
            'Build input did not preserve all old pieces and add exactly one')
    added = right[new.pop()]
    require(added.get('part') == 'sand' and added.get('y') == 0,
            'The actual placement was not the selected ground-level Sandstein')
    return added


def one_quarter_turn(before: dict, after: dict) -> dict:
    left, right = pieces(before, 'id'), pieces(after, 'id')
    require(before.get('rotation_enabled') is True and after.get('rotation_enabled') is True,
            'Rotation was not enabled in actual saved puzzle')
    require(set(left) == set(right), 'Puzzle rotation changed piece identities')
    changed = [key for key in left if left[key] != right[key]]
    require(len(changed) == 1, 'Rotation must change exactly one saved piece')
    key = changed[0]
    expected = {**left[key], 'turn': (int(left[key]['turn']) + 1) % 4}
    require(right[key] == expected and after['moves'] == before['moves'] + 1,
            'Saved change is not exactly one real quarter-turn and one move')
    return {'piece_id': key, 'before': left[key], 'after': right[key]}


def resume_equal(before: dict, after: dict, keys: tuple[str, ...]) -> None:
    require(all(key in before and key in after and before[key] == after[key]
                for key in keys), 'Durable resume changed: ' + ', '.join(keys))


def config_variant_values(raw: str) -> dict[str, str]:
    """Read the actual ConfigFile syntax without interpreting Godot Variants.

    Godot4.6.3 writes nonempty dictionaries across unindented lines and can
    write typed arrays. INI and JSON parsers are not valid readers for that
    format. Retain each complete Variant verbatim; decode only scoped scalar
    fields below. This never executes or writes serialized game state.
    """
    values, stack, chunks = {}, [], []
    section, key, quoted, escaped = None, None, False, False
    pairs = {')': '(', ']': '[', '}': '{'}
    for line in raw.splitlines(keepends=True):
        if key is None:
            stripped = line.strip()
            if not stripped or stripped.startswith((';', '#')):
                continue
            if stripped.startswith('['):
                require(stripped == '[jump]' and section is None,
                        'Unexpected or repeated Jump ConfigFile section')
                section = 'jump'
                continue
            match = re.fullmatch(r'([a-z_]+)=(.*)', line.rstrip('\r\n'))
            require(section == 'jump' and match is not None,
                    'Unrecognized Jump ConfigFile assignment')
            key = match[1]
            require(key not in values, 'Duplicate Jump ConfigFile field: ' + key)
            segment = line.split('=', 1)[1]
        else:
            segment = line
        chunks.append(segment)
        for char in segment:
            if quoted:
                if escaped:
                    escaped = False
                elif char == '\\':
                    escaped = True
                elif char == '"':
                    quoted = False
            elif char == '"':
                quoted = True
            elif char in '([{':
                stack.append(char)
            elif char in ')]}':
                require(bool(stack) and stack.pop() == pairs[char],
                        'Mismatched brackets in actual Jump ConfigFile')
        if not stack and not quoted:
            value = ''.join(chunks).strip()
            require(bool(value), 'Empty Jump ConfigFile value')
            values[key] = value
            key, chunks = None, []
    require(section == 'jump' and key is None and not stack and not quoted,
            'Truncated Jump ConfigFile Variant')
    return values


def parse_jump_save(name: str, raw: str) -> dict:
    match = re.fullmatch(r'jump_([a-f0-9]{24})_([1-4])_([a-f0-9]{12})(?:_course\d+)?\.cfg', name)
    require(match is not None, 'Jump checkpoint lacks actual hashed child scope')
    data = config_variant_values(raw)
    scope = json.loads(data['child_scope'])
    require(bool(re.fullmatch(r'[a-f0-9]{64}', scope)) and scope[:24] == match[1]
            and data.get('version') == '1' and data.get('grade') == match[2],
            'Jump filename and persisted child/grade scope differ')
    return data


def components(image: Image.Image, predicate, roi) -> tuple[list[dict], float]:
    """Connected observed pixels, not generated coordinates or control labels."""
    scale = min(1.0, 720 / image.width)
    small = image.convert('RGB').resize((round(image.width * scale),
                                        round(image.height * scale)))
    w, h = small.size
    pixels = small.load()
    pending = set()
    for y in range(round(roi[1] * h), round(roi[3] * h)):
        for x in range(round(roi[0] * w), round(roi[2] * w)):
            if predicate(*pixels[x, y]):
                pending.add(y * w + x)
    result = []
    while pending:
        first = pending.pop()
        stack = [first]
        points = []
        while stack:
            value = stack.pop()
            x, y = value % w, value // w
            points.append((x, y))
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                adjacent = yy * w + xx
                if 0 <= xx < w and 0 <= yy < h and adjacent in pending:
                    pending.remove(adjacent)
                    stack.append(adjacent)
        if len(points) >= 25:
            xs, ys = zip(*points)
            result.append({'bounds': [min(xs), min(ys), max(xs) + 1, max(ys) + 1],
                           'area': len(points), 'points': points})
    return result, scale


def stick_target(image: Image.Image) -> dict:
    # The source-pinned joystick texture has one cyan circular outer ring.
    # Use the short viewport side so portrait height cannot exclude a real stick.
    groups, scale = components(image,
        lambda r, g, b: r < 60 and b > 150 and g > 65 and b - g > 15 and b > r * 2,
        (0, .40, .43, 1))
    matches = []
    for group in groups:
        x0, y0, x1, y1 = group['bounds']
        w, h = x1 - x0, y1 - y0
        if not (.80 < w / h < 1.22 and w / scale >= max(65, min(image.size) * .13)
                and .12 < group['area'] / (w * h) < .70):
            continue
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        radius = (w + h) / 4
        ring = sum(.55 < math.hypot(x - cx, y - cy) / radius < 1.1
                   for x, y in group['points']) / group['area']
        if ring > .76:
            matches.append({'bounds': [value / scale for value in group['bounds']],
                            'center': [cx / scale, cy / scale],
                            'diameter': (w + h) / (2 * scale), 'ring_fraction': ring,
                            'basis': 'Observed connected cyan ring of original joystick texture'})
    require(len(matches) == 1, 'Current frame has no unique original joystick ring')
    return matches[0]


def solve(matrix: list[list[float]], vector: list[float]) -> list[float]:
    rows = [list(row) + [value] for row, value in zip(matrix, vector)]
    n = len(rows)
    for column in range(n):
        pivot = max(range(column, n), key=lambda row: abs(rows[row][column]))
        require(abs(rows[pivot][column]) > 1e-9, 'Degenerate observed board projection')
        rows[column], rows[pivot] = rows[pivot], rows[column]
        factor = rows[column][column]
        rows[column] = [value / factor for value in rows[column]]
        for row in range(n):
            if row != column:
                factor = rows[row][column]
                rows[row] = [a - factor * b for a, b in zip(rows[row], rows[column])]
    return [row[-1] for row in rows]


def puzzle_board_contour(image: Image.Image) -> dict:
    """Require the observed empty felt trapezoid and its actual gold side rims."""
    # The unshaded #1a2748 felt is tone-mapped in the actual 7b Android frame
    # to roughly (45, 53, 87). Colour only proposes components: straight edges,
    # perspective widening, a filled interior and both gold rims decide below.
    groups, scale = components(image,
        lambda r, g, b: 12 <= r <= 70 and 20 <= g <= 85 and 55 <= b <= 130
        and b - g >= 24 and b - r >= 28 and abs(g - r) <= 25,
        (.15, .27, .85, .88))
    candidates = []
    for group in groups:
        x0, y0, x1, y1 = group['bounds']
        width, height = x1 - x0, y1 - y0
        if not (width > image.width * scale * .22 and height > image.height * scale * .12
                and .38 < (x0 + x1) / (2 * image.width * scale) < .62
                and group['area'] > width * height * .65):
            continue
        rows = {}
        for x, y in group['points']:
            rows.setdefault(y, []).append(x)
        ys = sorted(rows)
        if len(ys) < 28 or ys != list(range(ys[0], ys[-1] + 1)):
            continue
        # Ignore only the antialiased top/bottom edge, not missing interior
        # pieces or a menu/hand occluding an otherwise plausible blue region.
        core = ys[4:-4]
        coverage = sum(len(rows[y]) for y in core) / sum(
            max(rows[y]) - min(rows[y]) + 1 for y in core)
        if coverage < .985:
            continue
        mean_y = sum(core) / len(core)
        denominator = sum((y - mean_y) ** 2 for y in core)
        edges = []
        for choose in (min, max):
            mean_x = sum(choose(rows[y]) for y in core) / len(core)
            slope = sum((y - mean_y) * (choose(rows[y]) - mean_x)
                        for y in core) / denominator
            intercept = mean_x - slope * mean_y
            residual = max(abs(choose(rows[y]) - (slope * y + intercept)) for y in core)
            edges.append((slope, intercept, residual))
        left, right = edges
        top, bottom = ys[1], ys[-2]
        lx0, lx1 = (left[0] * y + left[1] for y in (top, bottom))
        rx0, rx1 = (right[0] * y + right[1] for y in (top, bottom))
        if not (left[0] < 0 < right[0] and max(left[2], right[2]) <= 2
                and 1.04 <= (rx1 - lx1) / (rx0 - lx0) <= 1.5
                and abs((lx0 + rx0) - (lx1 + rx1)) <= max(4, width * .04)):
            continue
        rim_fractions = []
        for edge, sign in ((left, -1), (right, 1)):
            observed = []
            for y in core[::max(1, len(core) // 24)]:
                x = (edge[0] * y + edge[1]) / scale
                gold = False
                for distance in (4, 8, 12, 16):
                    px, py = round(x + sign * distance), round(y / scale)
                    if not (0 <= px < image.width and 0 <= py < image.height):
                        continue
                    red, green, blue = image.getpixel((px, py))[:3]
                    gold |= red >= 70 and red - green >= 10 and green - blue >= 10
                observed.append(gold)
            rim_fractions.append(sum(observed) / len(observed))
        if min(rim_fractions) < .70:
            continue
        candidates.append({'corners': [(lx0 / scale, top / scale), (rx0 / scale, top / scale),
                                        (rx1 / scale, bottom / scale), (lx1 / scale, bottom / scale)],
                           'interior_coverage': coverage, 'gold_side_rim_fractions': rim_fractions,
                           'edge_residual_pixels': [left[2] / scale, right[2] / scale],
                           'perspective_width_ratio': (rx1 - lx1) / (rx0 - lx0)})
    require(len(candidates) == 1, 'Current screenshot has no unique complete empty puzzle-board contour')
    return candidates[0]


def puzzle_piece_target(image: Image.Image, saved: dict) -> dict:
    require(image.width > image.height and saved.get('count') == 6
            and saved.get('motif') == 1, 'This observed-board probe requires six-piece motif1 landscape')
    original_pieces = saved.get('pieces')
    require(isinstance(original_pieces, list) and len(original_pieces) == 6
            and all(isinstance(piece, dict) and piece.get('tray') is True
                    and piece.get('locked') is False for piece in original_pieces)
            and {piece.get('id') for piece in original_pieces} == set(range(6)),
            'The actual save does not describe an empty six-piece puzzle board')
    first = next(piece for piece in original_pieces if piece['id'] == 0)
    require(first.get('x') == -7.0 and first.get('z') == -2.2,
            'The actual first tray piece has moved from the source-confirmed initial slot')
    contour = puzzle_board_contour(image)
    corners = contour['corners']
    # Source796b: unshaded board_base at y=.12; visible width9.7/depth5.5.
    world = [(-4.85, -2.75), (4.85, -2.75), (4.85, 2.75), (-4.85, 2.75)]
    matrix, vector = [], []
    for (x, z), (u, v) in zip(world, corners):
        matrix.extend([[x, z, 1, 0, 0, 0, -u * x, -u * z],
                       [0, 0, 0, x, z, 1, -v * x, -v * z]])
        vector.extend([u, v])
    a, b, c, d, e, f, g, h = solve(matrix, vector)
    x, z = -7.0, -2.2  # Actual first visible tray-piece center in source796b.
    point = [(a * x + b * z + c) / (g * x + h * z + 1),
             (d * x + e * z + f) / (g * x + h * z + 1)]
    require(0 < point[0] < image.width * .45 and image.height * .20 < point[1] < image.height * .85,
            'Observed board projection places tray target outside playable region')
    patch = image.crop((round(point[0] - 8), round(point[1] - 8),
                        round(point[0] + 8), round(point[1] + 8))).convert('L')
    require(patch.entropy() > 2, 'Projected tray center is blank; refusing an unobserved piece touch')
    return {'point': point, 'board_corners': corners, 'board_contour': contour,
            'world_tray_center': [x, .15, z],
            'basis': 'Current screenshot board homography + source796b first tray center; save rotation must confirm hit'}


def build_targets(saved: dict, viewport: list[int], image: Image.Image) -> list[dict]:
    camera = saved['camera']
    orbit, tilt, radius = (float(camera[k]) for k in ('orbit', 'tilt', 'radius'))
    focus = list(map(float, camera['focus']))
    eye = [focus[0] + math.sin(orbit) * math.cos(tilt) * radius,
           focus[1] + math.sin(tilt) * radius,
           focus[2] + math.cos(orbit) * math.cos(tilt) * radius]
    def unit(values):
        length = math.sqrt(sum(x * x for x in values))
        require(length > 1e-8, 'Invalid saved build camera')
        return [x / length for x in values]
    forward = unit([focus[0] - eye[0], focus[1] + 1.2 - eye[1], focus[2] - eye[2]])
    right = unit([-forward[2], 0, forward[0]])
    up = [right[1] * forward[2] - right[2] * forward[1],
          right[2] * forward[0] - right[0] * forward[2],
          right[0] * forward[1] - right[1] * forward[0]]
    x0, y0, x1, y1 = viewport
    focal = (y1 - y0) / (2 * math.tan(math.radians(54) / 2))
    result = []
    # Avoid every saved object by a conservative four-cell margin. The exact
    # post-input one-piece save delta remains the acceptance, never projection.
    for x in range(-20, 21):
        for z in range(-18, 19):
            if 0 <= x <= 3 or any(abs(p['x'] - x) < 4 and abs(p['z'] - z) < 4
                                 for p in saved['pieces']):
                continue
            relative = [x + .5 - eye[0], .01 - eye[1], z + .5 - eye[2]]
            depth = sum(a * b for a, b in zip(relative, forward))
            if depth <= 0:
                continue
            u = (x0 + x1) / 2 + focal * sum(a * b for a, b in zip(relative, right)) / depth
            v = (y0 + y1) / 2 - focal * sum(a * b for a, b in zip(relative, up)) / depth
            if not (.18 * image.width < u < .78 * image.width and
                    .29 * image.height < v < .65 * image.height):
                continue
            patch = image.crop((round(u - 7), round(v - 7), round(u + 7), round(v + 7))).convert('RGB')
            green = sum(g > r * 1.12 and g > b * 1.08 and g > 45
                        for r, g, b in patch.getdata()) / (patch.width * patch.height)
            if green > .8:
                result.append({'point': [u, v], 'cell': [x, 0, z], 'green_fraction': green,
                               'viewport': viewport, 'saved_camera': camera,
                               'basis': 'Actual saved camera + observed Android window frame + fresh visible green land'})
    require(bool(result), 'No source-projected free cell is visible as green land in current frame')
    return sorted(result, key=lambda value: math.dist(value['point'],
                                                     [image.width * .5, image.height * .48]))


class Tour:
    def __init__(self, args):
        self.args, self.out = args, args.out
        self.out.mkdir(parents=True, exist_ok=True)
        self.events, self.context, self.counter = [], {}, 0
        self.helper_source = args.candidate_source
        self.expected_probe_source = args.binding['host_source']
        self.diagnostic_context = None
        if hasattr(args, 'diagnostic_context'):
            relative = 'scripts/run_unchanged_creative_diagnostic.py'
            spec = importlib.util.spec_from_file_location(
                'bound_creative_diagnostic_runner', args.probe_source / relative)
            diagnostic = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(diagnostic)
            committed_helper(args.probe_source, diagnostic, relative)
            self.expected_probe_source = diagnostic.validate_tour_context(
                args, args.diagnostic_context)
            self.helper_source = args.probe_source
            self.diagnostic_context = args.diagnostic_context
        for path in (self.helper_source / '.github/probes',
                     self.helper_source / 'scripts/probes',
                     self.helper_source / 'tools/android_qa'):
            sys.path.insert(0, str(path))
        self.probe = importlib.import_module('creative_android_probe')
        self.original = importlib.import_module('modernization_android_tour')
        self.base, self.live = self.probe.base, self.probe.live
        self.raw_adb = self.base.adb
        self.base.adb = self.audit_adb
        self.started = time.monotonic()

    def tag(self, label):
        self.counter += 1
        return f'{self.counter:04d}-{label}'

    def shot(self, label, *, timeout=None):
        tag = self.tag(label)
        snapshot = self.probe.capture(self.out, tag, **({'timeout': timeout} if timeout is not None else {}))
        return self.out / snapshot['file'], snapshot

    def audit_adb(self, *args, **kwargs):
        event = None
        deadline = getattr(self, 'input_deadline', None)
        if deadline is not None:
            require(time.monotonic() < deadline, 'Treasure movement deadline exceeded before ADB')
        if args[:2] == ('shell', 'input'):
            event = {'arguments': list(args), 'monotonic_seconds': time.monotonic(),
                     'context': dict(self.context)}
            if len(args) >= 3 and args[2] in ('tap', 'swipe'):
                path, shot = self.shot('before-real-input')
                image = read_image(path)
                points = [list(map(float, args[3:5]))]
                if args[2] == 'swipe':
                    points.append(list(map(float, args[5:7])))
                require(all(0 <= x < image.width and 0 <= y < image.height for x, y in points),
                        'Input coordinates outside fresh actual screenshot')
                event.update(capture=shot, points=points)
                if not self.context:
                    # Original onboarding/touch helpers retain actual bounds in
                    # their XML/OCR/readiness journals. Preserve their filenames.
                    evidence = sorted((p for p in self.out.iterdir()
                                       if p.suffix in ('.xml', '.json')),
                                      key=lambda p: p.stat().st_mtime, reverse=True)[:4]
                    event['context'] = {'basis': 'Committed live UI/OCR observation helper',
                                        'helper_source': self.expected_probe_source,
                                        'recent_original_journals': [p.name for p in evidence]}
            self.events.append(event)
            event['dispatch_status'] = 'REQUESTED'
            write(self.out / 'real-input-events.json', self.events)
        try:
            # Snapshot/OCR/journal work can consume the remaining budget. Check
            # again immediately before commands routed through this wrapper.
            # Direct capture subprocesses and OCR keep their own timeouts;
            # no late input or arrival is accepted after they finish.
            if deadline is not None:
                remaining = deadline - time.monotonic()
                hold = (int(args[-1]) / 1000 if args[:3] == ('shell', 'input', 'swipe') else 0)
                require(remaining > hold, 'Treasure movement deadline cannot fit the requested ADB input')
                kwargs['timeout'] = min(kwargs.get('timeout', 60), remaining)
            if event is not None:
                event['dispatch_monotonic'] = time.monotonic()
                event['dispatch_status'] = 'SENT'
            result = self.raw_adb(*args, **kwargs)
            if deadline is not None:
                require(time.monotonic() < deadline, 'Treasure movement deadline exceeded during ADB')
            return result
        except Exception as error:
            if event is not None:
                event.update(dispatch_status='SENT_FAILED' if 'dispatch_monotonic' in event else 'NOT_SENT',
                             error=str(error))
            raise
        finally:
            if event is not None:
                write(self.out / 'real-input-events.json', self.events)

    def touch(self, point, context, milliseconds=120):
        self.context = context
        x, y = map(lambda value: str(round(value)), point)
        try:
            self.base.adb('shell', 'input', 'swipe', x, y, x, y, str(milliseconds),
                          timeout=max(15, milliseconds / 1000 + 5))
        finally:
            self.context = {}

    def native(self, label, tap=False, exact=False):
        self.probe.native_text(self.out, label, self.tag('native-' + self.probe.normalized(label)),
                               tap=tap, exact=exact,
                               orientation=getattr(self, 'surface_orientation', 'landscape'))

    def observe(self, label, exact=False, *, allowed_captions=(), control=''):
        require(control in ('', 'jump-action') and
                (not control or (exact and not allowed_captions
                                 and self.probe.normalized(label) == self.probe.normalized('SPRINGEN'))),
                'Unsupported source-confirmed caption control')
        previous, previous_caption = None, None
        for _ in range(3):
            path, shot = self.shot('observe-' + self.probe.normalized(label))
            lines = self.probe.image_lines(self.out, path.stem,
                self.probe.normalized(label), source_path=path, timeout=60, exact=exact,
                **({'all_caption_regions': True} if control else {}))
            matches = [x for x in lines if
                       (self.probe.normalized(x['text']) == self.probe.normalized(label) if exact
                        else self.probe.normalized(label) in self.probe.normalized(x['text']))]
            require(bool(matches), 'Caption absent from actual screenshot: ' + label)
            frame = self.probe.inspect_surface(
                path, orientation=getattr(self, 'surface_orientation', 'landscape'))
            if control == 'jump-action':
                found = jump_action_choice(matches, frame['pixels'], self.probe.normalized)
            elif allowed_captions:
                found = full_caption_choice(matches, allowed_captions, self.probe.normalized)
            else:
                found = min(matches, key=lambda x: len(x['text']))
            current_caption = self.probe.normalized(found['text'])
            if (allowed_captions or control) and previous_caption != current_caption:
                previous = None
            observed = self.probe.target_observation(frame, found['bounds'], previous,
                anchor='center-panel' if allowed_captions else '')
            if observed['stable_observed_target']:
                return {**found, 'capture': shot, 'stable': observed, 'source_control': control}
            previous, previous_caption = observed, current_caption
            time.sleep(.5)
        raise RuntimeError('Actual text target never stabilized: ' + label)

    def current_stick(self):
        path, shot = self.shot('observe-original-stick')
        target = stick_target(read_image(path))
        target['capture'] = shot
        write(self.out / (path.stem + '-target.json'), target)
        return target

    def move_stick(self, axis, milliseconds):
        target = self.current_stick()
        length = math.hypot(*axis)
        require(length > 0 and 100 <= milliseconds <= 1800, 'Invalid bounded stick gesture')
        point = [target['center'][i] + axis[i] / length * target['diameter'] * .36 for i in range(2)]
        self.touch(point, {**target, 'axis_direction': axis,
                          'input': 'Single real pointer; no simultaneous jump'}, milliseconds)

    def portal(self, title):
        for direction in (-1, 1):
            # Ten gestures need eleven observations, including the state
            # reached by the final permitted movement in either direction.
            for attempt in range(11):
                tag = self.tag('hub-' + self.probe.normalized(title))
                nodes = self.live.live_nodes(self.out, tag)
                path, shot = self.shot('hub-before-choice')
                image = read_image(path)
                target = hub_choice(nodes, title, image.size, 48 * 1.5)
                if target:
                    rect = target['bounds']
                    self.touch([(rect[0] + rect[2]) / 2, (rect[1] + rect[3]) / 2],
                               {**target, 'capture': shot, 'hierarchy': tag,
                                'basis': 'Current candidate live _GameTile complete Semantics, enabled and clickable'})
                    return
                if attempt == 10:
                    break
                scrolls = [bounds(n.get('bounds', '')) for n in nodes
                           if n.get('package') == PACKAGE and n.get('scrollable') == 'true']
                scrolls = [r for r in scrolls if r and 0 <= r[0] < r[2] <= image.width
                           and 0 <= r[1] < r[3] <= image.height]
                require(bool(scrolls), 'No actual hub scroll region and no tile: ' + title)
                rect = max(scrolls, key=lambda r: (r[2] - r[0]) * (r[3] - r[1]))
                x = (rect[0] + rect[2]) // 2
                low, high = rect[1] + .23 * (rect[3] - rect[1]), rect[3] - .23 * (rect[3] - rect[1])
                start, end = (low, high) if direction == -1 else (high, low)
                self.context = {'capture': shot, 'hierarchy': tag, 'bounds': rect,
                                'basis': 'Actual live Flutter scrollable viewport'}
                self.base.adb('shell', 'input', 'swipe', str(x), str(round(start)),
                              str(x), str(round(end)), '450')
                self.context = {}
                time.sleep(.8)
        raise RuntimeError('Current live hub tile not available: ' + title)

    def enter(self, title, header):
        # The original Jump scene retains its actual portrait viewport. The
        # companion scenes enter through creative_runtime's landscape handoff.
        self.surface_orientation = 'responsive' if title == 'Jump & Run' else 'landscape'
        self.portal(title)
        for _ in range(60):
            try:
                if 'LumoGameActivity' in self.base.foreground():
                    break
            except RuntimeError:
                pass
            time.sleep(1)
        else:
            raise RuntimeError('Requested game Activity never appeared: ' + title)
        require(bool(self.base.adb('shell', 'pidof', PACKAGE + ':lumo_game', check=False).strip()),
                'Native process absent')
        self.native(header)
        self.shot('entered-' + self.probe.normalized(title))

    def leave(self, label='Zur Spielewelt', already_pause=False):
        self.probe.leave(self.out, self.tag('leave'), already_menu=already_pause, return_label=label,
                         orientation=getattr(self, 'surface_orientation', 'landscape'))
        # A true foreground + current Flutter accessibility AND visible text
        # avoids accepting the last native buffer as a Flutter return image.
        tag = self.tag('flutter-return')
        nodes = self.live.live_nodes(self.out, tag)
        require(any('Spielen' in (n.get('text', '') + n.get('content-desc', ''))
                    and n.get('package') == PACKAGE for n in nodes),
                'Fresh Flutter accessibility did not return')
        self.probe.flutter_return_capture(self.out, tag)
        require(self.probe.prefs(self.out, self.tag('profile'))['flutter.lumo_active_profile'] == self.profile,
                'Fictional child profile changed across native return')

    def saved(self, kind):
        values = self.probe.saves(self.out, kind, self.tag(kind + '-save'))
        require(len(values) == 1, 'Fresh test profile should have exactly one ' + kind + ' save')
        return next(iter(values.values()))

    def pause_save(self, kind, resume=True):
        caption = {'build': 'Weiterbauen', 'puzzle': 'Weiterpuzzeln', 'treasure': 'Weiter erkunden'}[kind]
        if kind == 'build':
            before = self.observe_build_pause()
            if before['state'] == 'active':
                remaining = before['deadline_monotonic'] - time.monotonic()
                require(remaining > 0, 'Build pause prerequisite expired before Back')
                # One real Back only after two current editor observations.
                # A blank/reflowing entry frame or an already open pause menu
                # must never trigger a speculative toggle or a second Back.
                previous_context = getattr(self, 'context', {})
                self.context = {'basis': 'Two fresh source-confirmed build editor observations',
                                'capture': before['capture'], 'stable': before['stable'],
                                'state': before['state'], 'journal': before['journal']}
                try:
                    self.base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK', timeout=min(15, remaining))
                finally:
                    self.context = previous_context
                self.observe_build_pause(expected='paused')
        else:
            self.base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
            self.native(caption)
        saved = self.saved(kind)
        if resume:
            self.native(caption, tap=True, exact=True)
        return saved

    def observe_build_pause(self, *, expected='', timeout=60):
        require(expected in ('', 'paused'), 'Unknown build pause-state prerequisite')
        started = time.monotonic()
        deadline = started + timeout
        journal = self.out / (self.tag('build-pause-prerequisite') + '.json')
        evidence = {'status': 'WAITING', 'expected': expected, 'timeout_seconds': timeout,
                    'scope': 'Current observed editor/pause prerequisite; no input or gameplay PASS',
                    'frames': []}
        previous, previous_state = None, None
        try:
            while time.monotonic() < deadline:
                path, shot = self.shot('build-current-state', timeout=deadline - time.monotonic())
                frame = self.probe.inspect_surface(path, orientation='landscape')
                row = {'capture': shot, 'surface': frame}
                evidence['frames'].append(row)
                state = None
                if frame['acceptable_for_target_sampling']:
                    remaining = deadline - time.monotonic()
                    require(remaining > 0, 'Build pause observation deadline exceeded')
                    lines = self.probe.image_lines(self.out, path.stem,
                        self.probe.normalized('Mit Lumo laufen'), source_path=path,
                        timeout=remaining, exact=True, all_caption_regions=True)
                    state = build_pause_observation(lines, frame, self.probe.normalized)
                    row['ocr'] = path.stem + '-ocr.json'
                if state is None or (expected and state['state'] != expected):
                    previous, previous_state = None, None
                else:
                    if previous_state != state['state']:
                        previous = None
                    observed = self.probe.target_observation(frame, state['target']['bounds'], previous,
                        anchor='center-panel' if state['state'] == 'paused' else 'right-toolbar')
                    row.update(state=state, target_observation=observed)
                    require(sha(path) == frame['source_sha256'] == shot['sha256'],
                            'Build screenshot changed during state observation')
                    require(time.monotonic() < deadline, 'Build pause observation deadline exceeded')
                    if observed['stable_observed_target']:
                        evidence.update(status='OBSERVED', state=state['state'])
                        return {**state, 'capture': shot, 'stable': observed,
                                'deadline_monotonic': deadline, 'journal': journal.name}
                    previous, previous_state = observed, state['state']
                time.sleep(min(.5, max(0, deadline - time.monotonic())))
            raise RuntimeError('No stable current build editor/pause state before deadline')
        except Exception as error:
            evidence.update(status='FAIL', error=str(error))
            raise
        finally:
            evidence['elapsed_seconds'] = round(time.monotonic() - started, 6)
            write(journal, evidence)

    def toolbar(self, label, anchors):
        for gestures in range(8):
            try:
                observed = self.observe(label, exact=True)
                rect = observed['bounds']
                self.touch([(rect[0] + rect[2]) / 2, (rect[1] + rect[3]) / 2], observed)
                time.sleep(.5)
                return
            except (RuntimeError, TimeoutError) as error:
                last = str(error)
            if gestures == 7:
                break
            visible = None
            for anchor in anchors:
                try:
                    visible = self.observe(anchor)
                    break
                except (RuntimeError, TimeoutError):
                    continue
            require(visible is not None, 'No actual toolbar scroll anchor: ' + last)
            rect = visible['bounds']
            width = visible['capture']['width']
            y = (rect[1] + rect[3]) / 2
            self.context = {**visible, 'basis': 'Observed source-confirmed horizontal toolbar caption row'}
            self.base.adb('shell', 'input', 'swipe', str(round(width * .75)), str(round(y)),
                          str(round(width * .24)), str(round(y)), '500')
            self.context = {}
            time.sleep(.7)
        raise RuntimeError('Native toolbar did not expose ' + label)

    def viewport(self, image):
        raw = self.base.adb('shell', 'dumpsys', 'window', 'windows')
        path = self.out / (self.tag('native-window') + '.txt')
        path.write_text(raw)
        sections = re.split(r'(?=\n\s*Window #)', raw)
        rows = [s for s in sections if 'LumoGameActivity' in s.split('\n', 2)[1 if s.startswith('\n') else 0]]
        matches = []
        for section in rows:
            for match in re.finditer(r'(?:mFrame|\bframe)=\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]', section):
                rect = list(map(int, match.groups()))
                if 0 <= rect[0] < rect[2] <= image.width and 0 <= rect[1] < rect[3] <= image.height:
                    matches.append(rect)
        unique = {tuple(r) for r in matches}
        require(len(unique) == 1, 'No unambiguous actual Godot Android window frame; refusing camera guess')
        return list(unique.pop())

    def build(self):
        wallet_before = self.probe.wallet(self.out, self.tag('build-wallet-before'))
        self.enter('Bauwelt', 'LUMO BAUWELT')
        before = self.pause_save('build')
        path, shot = self.shot('build-free-land')
        image = read_image(path)
        target = build_targets(before, self.viewport(image), image)[0]
        target['capture'] = shot
        self.touch(target['point'], target)
        after = self.pause_save('build')
        added = one_added_piece(before, after)
        require([added[k] for k in ('x', 'y', 'z')] == target['cell'],
                'Real piece was placed outside the source-projected observed cell')
        self.toolbar('Rückgängig', ('Entfernen', 'Drehen', 'Siedlung'))
        undone = self.pause_save('build')
        require(pieces(undone, 'uid') == pieces(before, 'uid'), 'Undo did not restore exact original pieces')
        self.toolbar('Wiederholen', ('Rückgängig', 'Füllen'))
        redone = self.pause_save('build')
        require(pieces(redone, 'uid') == pieces(after, 'uid'), 'Redo did not restore actual placed pieces')
        self.shot('build-redone')
        self.toolbar('Bauziele', ('Füllen', 'Kopieren', 'Spiegel X', 'Speichern', 'Vorlagen'))
        self.native('Ein Zuhause bauen', tap=True)
        self.native('Mein Bauwerk testen', tap=True)
        self.native('Schon geschafft')
        self.leave()
        completed = self.saved('build')
        require('house' in completed.get('completed', []), 'Existing starter-house reward did not persist')
        wallet_after = self.probe.wallet(self.out, self.tag('build-wallet-after'))
        require(wallet_after.get('stars', 0) - wallet_before.get('stars', 0) == 3
                and wallet_after.get('xp', 0) - wallet_before.get('xp', 0) == 24,
                'Existing house goal did not grant exactly its original3stars/24XP')
        self.enter('Bauwelt', 'LUMO BAUWELT')
        resumed = self.pause_save('build')
        resume_equal(completed, resumed, ('pieces', 'completed', 'goal'))
        self.native('Mein Bauwerk testen', tap=True)
        self.leave()
        require(self.probe.wallet(self.out, self.tag('build-replay-wallet')) == wallet_after,
                'Repeated saved house goal duplicated reward')
        return {'status': 'PASS', 'added_piece': added, 'undo_exact_pieces': True,
                'redo_exact_pieces': True, 'durable_resume': True,
                'original_starter_house_reward': {'stars': 3, 'xp': 24, 'replay_deduplicated': True},
                'scope': 'One real new block; existing starter house is separately labelled, not newly built'}

    def select_puzzle_motif(self):
        target = self.probe.normalized('Bild: Candy Cloud Circuit')
        # Five published motifs: observe the initial choice and every state
        # reached by at most four real touches, including the final one.
        for touches in range(5):
            observed = self.observe('Bild:', allowed_captions=PUZZLE_MOTIF_CAPTIONS)
            if self.probe.normalized(observed['text']) == target:
                return {'caption': observed['text'], 'touches': touches,
                        'capture': observed['capture']}
            if touches == 4:
                break
            rect = observed['bounds']
            self.touch([(rect[0] + rect[2]) / 2, (rect[1] + rect[3]) / 2], observed)
            time.sleep(.5)
        raise RuntimeError('Actual puzzle menu did not expose the exact Candy Cloud Circuit motif')


    def puzzle(self):
        self.enter('Puzzle', 'LUMOS PUZZLE')
        for label in ('12 Teile', '24 Teile', '48 Teile', '96 Teile'):
            self.native(label, tap=True)
        self.native('6 Teile')
        motif_selection = self.select_puzzle_motif()
        for label in ('Modus: Bilderpuzzle', 'Modus: Drehpuzzle', 'Modus: Bilderpuzzle'):
            self.native(label, tap=True)
        self.native('Neues Puzzle beginnen', tap=True, exact=True)
        before = self.pause_save('puzzle')
        require(before['count'] == 6 and before['motif'] == 1 and before['rotation_enabled'] is True,
                'Actual menu touches did not persist six-piece motif1 rotation mode')
        path, shot = self.shot('puzzle-observed-board')
        target = puzzle_piece_target(read_image(path), before)
        self.touch(target['point'], {**target, 'capture': shot})
        time.sleep(.5)
        # Opening Pause intentionally clears selection in production. Use its
        # real Save button here, preserving the selected object for rotation.
        self.native('Speichern', tap=True, exact=True)
        selected = self.saved('puzzle')
        # Picking may change tray/x/z on release. Compare rotation to its own
        # actual post-selection save, not to a fabricated untouched baseline.
        self.native('Drehen', tap=True)
        time.sleep(.5)
        self.native('Speichern', tap=True, exact=True)
        rotated = self.saved('puzzle')
        change = one_quarter_turn(selected, rotated)
        self.shot('puzzle-real-quarter-turn')
        self.leave()
        final = self.saved('puzzle')
        self.enter('Puzzle', 'LUMOS PUZZLE')
        self.native('Gespeichertes Puzzle fortsetzen', tap=True, exact=True)
        resumed = self.pause_save('puzzle')
        resume_equal(final, resumed, ('result_id', 'count', 'motif', 'rotation_enabled', 'pieces', 'hints', 'moves'))
        self.leave()
        return {'status': 'PASS', 'menu_count_touches': 4, 'menu_mode_touches': 3,
                'motif_selection': motif_selection,
                'actual_rotation': change, 'durable_resume': True,
                'not_claimed': ['complete puzzle', 'manual snap', 'hints as manual movement']}

    def treasure(self):
        self.enter('Schatzsuche', 'LUMOS STERNENSCHATZ')
        before = self.pause_save('treasure')
        current, positions, segments = before, [before['position']], []
        deadline = time.monotonic() + 1200
        movement = {'status': 'RUNNING', 'target': [-12, 0, -8], 'arrival_radius': 3.4,
                    'maximum_gestures': 18, 'timeout_seconds': 1200,
                    'actual_saved_positions': positions, 'segments': segments,
                    'scope': 'Observed approach only; actual question, answer and durable resume still required'}
        previous_deadline = getattr(self, 'input_deadline', None)
        self.input_deadline = deadline
        try:
            for index in range(19):
                require(time.monotonic() < deadline, 'Treasure movement deadline exceeded before arrival observation')
                position = current.get('position')
                require(isinstance(position, list) and len(position) == 3
                        and all(type(v) in (int, float) and math.isfinite(v) for v in position),
                        'Treasure save has no finite actual player position')
                require(current.get('result_id') == before.get('result_id') and bool(before.get('result_id')),
                        'Treasure movement changed the original result identity')
                x, _, z = position
                direction = [-12 - x, -8 - z]
                distance = math.hypot(*direction)
                if distance < 3.4:
                    movement.update(status='ARRIVAL_OBSERVED', final_distance=distance)
                    break
                require(index < 18 and time.monotonic() < deadline,
                        'First clue remained unreachable within the bounded observed movement budget')
                duration = treasure_movement_duration(distance, segments)
                self.move_stick(direction, duration)
                input_index = len(self.events) - 1
                time.sleep(.3)
                current = self.pause_save('treasure')
                after = current.get('position')
                require(isinstance(after, list) and len(after) == 3
                        and all(type(v) in (int, float) and math.isfinite(v) for v in after)
                        and current.get('result_id') == before.get('result_id'),
                        'Treasure movement produced invalid coordinates or another result identity')
                positions.append(after)
                approached = math.hypot(-12 - after[0], -8 - after[2])
                require(math.dist(position, after) > .2 and distance - approached > .1,
                        'Real joystick segment did not measurably approach the first clue')
                segments.append({'distance_before': distance, 'distance_after': approached,
                                 'milliseconds': duration, 'real_input_event_index': input_index})
                write(self.out / 'treasure-movement.json', movement)
        except Exception as error:
            movement.update(status='FAIL', error=str(error))
            raise
        finally:
            self.input_deadline = previous_deadline
            write(self.out / 'treasure-movement.json', movement)
        require(math.dist(before['position'], current['position']) > 3,
                'Treasure movement not established by actual saved positions')
        self.native('ANSEHEN', tap=True, exact=True)
        self.native('Was hilft einem Baum beim Wachsen?')
        self.shot('treasure-first-question')
        self.native('Ein Tropfen Wasser', tap=True, exact=True)
        found = self.pause_save('treasure')
        require(set(found['solved_clues']) == set(before['solved_clues']) | {'tree'},
                'Actual first-clue answer did not persist tree and preserve prior solved clues')
        require(found['result_id'] == before['result_id'], 'Treasure result identity changed')
        self.native('Rucksack', tap=True, exact=True)
        self.native('Blattschlüssel')
        self.shot('treasure-real-inventory')
        self.native('Weiter erkunden', tap=True, exact=True)
        self.leave()
        final = self.saved('treasure')
        self.enter('Schatzsuche', 'LUMOS STERNENSCHATZ')
        resumed = self.pause_save('treasure')
        resume_equal(final, resumed, ('result_id', 'chapter', 'solved_clues', 'discoveries', 'wrong_attempts'))
        require(math.dist(final['position'], resumed['position']) < .2,
                'Treasure relaunch did not restore actual position')
        self.leave()
        return {'status': 'PASS', 'actual_saved_position_series': positions,
                'observed_movement': movement,
                'first_clue': 'tree', 'visible_inventory': 'Blattschlüssel', 'durable_resume': True,
                'not_claimed': ['full treasure journey', 'original rig in simplified companion scene']}

    def jump_save(self):
        paths = self.base.adb('shell', 'find', f'/data/user/0/{PACKAGE}', '-maxdepth', '8',
                              '-type', 'f', '-name', 'jump_*.cfg').splitlines()
        paths = [p for p in paths if re.fullmatch(r'jump_[a-f0-9]{24}_[1-4]_[a-f0-9]{12}(?:_course\d+)?\.cfg', Path(p).name)]
        require(len(paths) == 1, 'Exactly one actually scoped Jump checkpoint is required')
        raw = self.base.adb('exec-out', 'cat', paths[0])
        (self.out / (self.tag('jump-save') + '.cfg')).write_text(raw)
        return parse_jump_save(Path(paths[0]).name, raw)

    def jump(self):
        self.enter('Jump & Run', 'Halten = höher springen')
        self.native('Pause', tap=True, exact=True)
        initial = self.jump_save()
        self.native('Weiterspielen', tap=True, exact=True)
        jump_target = self.observe('SPRINGEN', exact=True, control='jump-action')
        recording_size = ('540x960' if jump_target['capture']['height'] > jump_target['capture']['width']
                          else '960x540')
        remote = '/sdcard/lumo-studio-creative-jump.mp4'
        log = (self.out / 'jump-screenrecord.log').open('wb')
        started = time.monotonic()
        recorder = subprocess.Popen(['adb', 'shell', 'screenrecord', '--size', recording_size,
                                     '--bit-rate', '4000000', '--time-limit', '90', remote],
                                    stdout=log, stderr=subprocess.STDOUT)
        record = {'source': 'Actual Android screenrecord, unchanged production Jump scene',
                  'requested_size': recording_size,
                  'started_monotonic': started, 'actions': [], 'numeric_physics': 'NOT_MEASURED',
                  'multitouch': 'NOT_TESTED', 'fps_performance': 'NOT_MEASURED'}
        try:
            time.sleep(1)
            for axis, duration in (([1, 0], 350), ([-1, 0], 350)):
                at = time.monotonic() - started
                self.move_stick(axis, duration)
                at = self.events[-1]['dispatch_monotonic'] - started
                record['actions'].append({'type': 'separate-stick', 'start_seconds': at,
                                          'duration_ms': duration, 'axis': axis})
                time.sleep(.8)
            for duration in (80, 650):
                # Re-read the actual caption before each independent press.
                target = self.observe('SPRINGEN', exact=True, control='jump-action')
                rect = target['bounds']
                at = time.monotonic() - started
                self.touch([(rect[0] + rect[2]) / 2, (rect[1] + rect[3]) / 2], target, duration)
                at = self.events[-1]['dispatch_monotonic'] - started
                record['actions'].append({'type': 'short-jump' if duration == 80 else 'held-jump',
                                          'start_seconds': at, 'duration_ms': duration})
                time.sleep(1.6)
                self.shot('jump-after-' + str(duration))
        finally:
            # Signal only the screenrecord PID started for this unique filename.
            listing = self.raw_adb('shell', 'ps', '-A', '-o', 'PID,ARGS', check=False)
            rows = [line.split(None, 1) for line in listing.splitlines() if remote in line and 'screenrecord' in line]
            if len(rows) == 1 and rows[0][0].isdigit():
                self.raw_adb('shell', 'kill', '-2', rows[0][0], check=False)
            try:
                recorder.wait(timeout=95)
            except subprocess.TimeoutExpired:
                recorder.terminate()
                recorder.wait(timeout=10)
                raise RuntimeError('Android screenrecord did not terminate within its own recording limit')
            log.close()
            self.raw_adb('pull', remote, str(self.out / 'jump-actual-android.mp4'), timeout=90)
            write(self.out / 'jump-recording.json', record)
        movie = self.out / 'jump-actual-android.mp4'
        # Keep demuxer timestamps for variable-rate Android screenrecord; full decode stays strict.
        decode = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(movie),
                                 '-enc_time_base', 'demux', '-f', 'null', '-'],
                                capture_output=True, timeout=120)
        (self.out / 'jump-full-decode.log').write_bytes(decode.stdout + decode.stderr)
        require(decode.returncode == 0 and not decode.stderr.strip(), 'Actual Jump MP4 failed full decode')
        media = subprocess.run(['ffprobe', '-v', 'error', '-show_streams', '-show_format',
                                '-of', 'json', str(movie)], check=True, capture_output=True, timeout=30)
        (self.out / 'jump-media.json').write_bytes(media.stdout)
        info = json.loads(media.stdout)
        videos = [stream for stream in info.get('streams', []) if stream.get('codec_type') == 'video']
        require(len(videos) == 1 and [videos[0].get('width'), videos[0].get('height')] ==
                list(map(int, recording_size.split('x'))),
                'Actual Jump recording dimensions differ from the observed scene orientation')
        required_end = max(action['start_seconds'] + action['duration_ms'] / 1000 + 1.2
                           for action in record['actions'])
        require(float(info['format']['duration']) >= max(5, required_end),
                'Jump recording does not contain every dispatched action and its landing wait')
        samples = []
        for action in record['actions']:
            second = action['start_seconds'] + min(.22, action['duration_ms'] / 2000)
            target = self.out / ('jump-frame-' + action['type'] + '-' + str(len(samples)) + '.png')
            subprocess.run(['ffmpeg', '-v', 'error', '-ss', str(second), '-i', str(movie),
                            '-frames:v', '1', str(target)], check=True, capture_output=True, timeout=30)
            samples.append({'file': target.name, 'sha256': sha(target), 'requested_seconds': second})
        self.native('Pause', tap=True, exact=True)
        saved = self.jump_save()
        require(initial['result_id'] == saved['result_id'], 'Jump session identity changed during input recording')
        self.shot('jump-paused-after-real-input')
        self.leave('Zur Spieleauswahl · Abenteuer behalten', already_pause=True)
        # Production restores checkpoints directly into its genuine pause
        # modal and changes the HUD sentence; do not tap a covered Pause.
        self.enter('Jump & Run', 'Kleine Pause')
        resumed = self.jump_save()
        resume_equal(saved, resumed, tuple(saved))
        self.leave('Zur Spieleauswahl · Abenteuer behalten', already_pause=True)
        return {'status': 'INPUTS_RECORDED_SAVE_RESUMED', 'video': movie.name,
                'sha256': sha(movie), 'fully_decoded': True, 'samples': samples,
                'separate_pointer_actions': record['actions'], 'checkpoint_resume': True,
                'visual_motion_review': 'REQUIRED',
                'not_claimed': ['numeric jump height', '60FPS', 'device performance', 'simultaneous multitouch']}

    def run(self):
        binding = self.args.binding
        host, native = binding['host_source'], binding['native_source']
        result = {'status': 'RUNNING', 'host_source': host, 'native_source': native,
                  'probe_source': self.base.command('git', '-C', str(self.args.probe_source), 'rev-parse', 'HEAD').strip(),
                  'probe_sha256': sha(Path(__file__)), 'candidate_binding': binding,
                  'build_run': binding['build_run'], 'games': {},
                  'scope': 'Additional disposable API35 real-input probe of the same unchanged candidate APK',
                  'not_tested': ['Samsung Fold7 hardware', 'Android17', 'thermal/latency/FPS',
                                 'production child data', 'full game completion']}
        try:
            if self.diagnostic_context is not None:
                result['diagnostic_qa'] = self.diagnostic_context['diagnostic_qa']
                result['diagnostic_binding'] = {
                    'file': str(self.args.diagnostic_report),
                    'sha256': sha(self.args.diagnostic_report),
                    'scope': 'Separate QA observations of the unchanged original APK/PCK'}
            for source, expected in ((self.args.candidate_source, host),
                                     (self.args.native_source, native),
                                     (self.args.probe_source, self.expected_probe_source)):
                require(self.base.command('git', '-C', str(source), 'rev-parse', 'HEAD').strip() == expected,
                        'Immutable source checkout mismatch')
                require(not self.base.command('git', '-C', str(source), 'status', '--porcelain', '--untracked-files=no').strip(),
                        'Tracked candidate/native/probe source is dirty')
            committed_helper(self.helper_source, self.probe, '.github/probes/creative_android_probe.py')
            committed_helper(self.helper_source, self.original, '.github/probes/modernization_android_tour.py')
            os.chdir(self.args.candidate_source)
            result['apk_identity'] = self.original.verify_apk_identity(self.args.apk, self.args.provenance, self.args.sums)
            require(result['apk_identity']['flutter_source_commit'] == host
                    and result['apk_identity']['godot_revision'] == native,
                    'Original APK verifier returned another source')
            provenance = json.loads(self.args.provenance.read_text())
            require(result['apk_identity']['apk_sha256'] == provenance.get('sha256')
                    and self.args.apk.stat().st_size == provenance.get('bytes'),
                    'Downloaded APK differs from this build-verifier identity')
            with zipfile.ZipFile(self.args.apk) as archive:
                member = archive.getinfo('assets/lumo_game.pck')
                with archive.open(member) as stream:
                    measured_pck = hashlib.file_digest(stream, 'sha256').hexdigest()
            require(measured_pck == provenance.get('godot', {}).get('pck_sha256')
                    and member.file_size == provenance.get('godot', {}).get('bytes'),
                    'APK embedded PCK differs from this native build identity')
            result['direct_apk_pck_read'] = {'sha256': measured_pck, 'bytes': member.file_size}
            source_files = {
                'candidate': ['.github/probes/creative_android_probe.py',
                              '.github/probes/modernization_android_tour.py',
                              'lib/features/games/spielwelt/spielwelt_hub.dart',
                              'lib/features/games/spielwelt/spielwelt_routes.dart'],
                'native': ['scripts/games/jump_islands.gd', 'scripts/games/jump_touch_button.gd',
                           'scripts/games/kart_joystick.gd', 'scripts/creative/build_world.gd',
                           'scripts/creative/build_state.gd', 'scripts/creative/puzzle_world.gd',
                           'scripts/creative/puzzle_state.gd', 'scripts/creative/treasure_world.gd',
                           'scripts/creative/treasure_state.gd'],
            }
            actual_sources = [
                ('candidate', self.args.candidate_source, source_files['candidate']),
                ('native', self.args.native_source, source_files['native'])]
            if self.diagnostic_context is not None:
                actual_sources.append(('probe', self.helper_source, [
                    entry['path'] for entry in self.diagnostic_context['source_files']['qa']]))
            write(self.out / 'actual-source-files.json', {
                kind: [{'file': name, 'sha256': sha(root / name)} for name in names]
                for kind, root, names in actual_sources})
            result['root'] = self.probe.ensure_rooted_emulator(self.base.adb, self.out)
            result['runtime'] = {key: self.base.adb('shell', 'getprop', prop).strip() for key, prop in
                                 (('sdk', 'ro.build.version.sdk'), ('release', 'ro.build.version.release'),
                                  ('model', 'ro.product.model'), ('fingerprint', 'ro.build.fingerprint'))}
            require(result['runtime']['sdk'] == '35' and result['runtime']['release'] == '15'
                    and bool(result['runtime']['fingerprint']), 'Actual API35/release15 runtime required')
            self.base.adb('logcat', '-c')
            self.base.display(1080, 1920, 240)
            install = self.base.adb('install', '--no-streaming', str(self.args.apk), timeout=300)
            (self.out / 'install.txt').write_text(install)
            require('Success' in install, 'Actual unchanged APK installation failed')
            result['installed'] = self.probe.package_identity(self.out, 'installed')
            require(result['installed']['versionCode'].split()[0] == '2019', 'Installed package version mismatch')
            self.base.launch(self.out, 'fresh-studio')
            result['onboarding'] = self.probe.onboard(self.out)
            self.profile = self.probe.prefs(self.out, 'fictional-profile')['flutter.lumo_active_profile']
            require('LumoTest' in self.profile, 'Actual fictional profile was not persisted')
            for service in ('wifi', 'data'):
                self.base.adb('shell', 'svc', service, 'disable')
            self.base.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
            require(self.base.adb('shell', 'settings', 'get', 'global', 'airplane_mode_on').strip() == '1',
                    'Offline runtime not confirmed')
            result['offline'] = True
            for name in ('jump', 'build', 'puzzle', 'treasure'):
                try:
                    result['games'][name] = getattr(self, name)()
                except Exception as error:
                    result['games'][name] = {'status': 'FAIL', 'error': str(error),
                                             'traceback': traceback.format_exc()}
                    self.shot(name + '-failure')
                    if name != 'treasure':
                        # Preserve this failure, then start only the next
                        # independent game. No same-game retry or state write.
                        self.base.adb('shell', 'am', 'force-stop', PACKAGE)
                        self.base.launch(self.out, self.tag('next-independent-game'))
                        require(self.probe.prefs(self.out, self.tag('recovered-profile'))[
                            'flutter.lumo_active_profile'] == self.profile,
                            'Profile changed during failed-case teardown')
                        self.probe.flutter_tap(self.out, 'Spielen', self.tag('recover-games'))
                finally:
                    write(self.out / 'creative-result.json', result)
            fatal = self.original.logcat_fatal()
            require(not fatal, 'Actual app crash in logcat: ' + repr(fatal))
            result['fatal_crashes'] = len(fatal)
            engine_log = self.raw_adb('logcat', '-d', '-v', 'threadtime', timeout=60)
            engine_errors = [line for line in engine_log.splitlines()
                             if re.search(r'\b(?:godot|Godot)\b.*\b(?:SCRIPT ERROR|ERROR|Parse Error):', line)]
            write(self.out / 'native-engine-errors.json', engine_errors)
            require(not engine_errors, 'Actual native engine error during the real menu/input tour')
            require(all(row.get('status') in ('PASS', 'INPUTS_RECORDED_SAVE_RESUMED')
                        for row in result['games'].values()) and len(result['games']) == 4,
                    'At least one required genuine-input game contract failed; original evidence retained')
            result['status'] = 'RECORDED_REVIEW_REQUIRED'
            result['meaning'] = 'Functional save/input contracts passed; human Jump video review remains mandatory'
            return 0
        except Exception as error:
            result.update(status='FAIL', error=str(error), traceback=traceback.format_exc())
            return 1
        finally:
            result['elapsed_seconds'] = time.monotonic() - self.started
            (self.out / 'logcat.txt').write_text(self.raw_adb('logcat', '-d', '-v', 'threadtime', timeout=60, check=False))
            write(self.out / 'creative-result.json', result)
            write(self.out / 'evidence-manifest.json', [
                {'file': str(p.relative_to(self.out)), 'bytes': p.stat().st_size, 'sha256': sha(p)}
                for p in sorted(self.out.rglob('*')) if p.is_file() and p.name != 'evidence-manifest.json'])
            print('[StudioCreativeAndroid]', result['status'], json.dumps(result.get('games', {})), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate-source', type=Path)
    parser.add_argument('--native-source', type=Path)
    parser.add_argument('--probe-source', type=Path)
    parser.add_argument('--apk', type=Path)
    parser.add_argument('--provenance', type=Path)
    parser.add_argument('--sums', type=Path)
    parser.add_argument('--metadata-dir', type=Path)
    parser.add_argument('--verify-metadata-only', action='store_true')
    parser.add_argument('--expected-source', required=True)
    parser.add_argument('--workflow-path', required=True, choices=tuple(CANDIDATE_WORKFLOWS))
    parser.add_argument('--build-run', type=int, required=True)
    parser.add_argument('--artifact-id', type=int, required=True)
    parser.add_argument('--artifact-digest', required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    for key in ('candidate_source', 'metadata_dir', 'out'):
        value = getattr(args, key)
        if value is None:
            parser.error('--' + key.replace('_', '-') + ' is required')
        setattr(args, key, value.resolve())
    args.binding = candidate_binding(args)
    write(args.out / 'candidate-artifact-binding.json', args.binding)
    if args.verify_metadata_only:
        return 0
    for key in ('candidate_source', 'native_source', 'probe_source', 'apk', 'provenance', 'sums', 'out'):
        value = getattr(args, key)
        if value is None:
            parser.error('--' + key.replace('_', '-') + ' is required for the real tour')
        setattr(args, key, value.resolve())
    return Tour(args).run()


if __name__ == '__main__':
    sys.exit(main())
