#!/usr/bin/env python3
"""Observe and exercise the real English lesson on an already verified APK.

Only current visible controls receive input. The app-private layout is read;
answers, saves, launch descriptors and IPC requests are never injected. Pure
validators can explicitly accept desktop fixtures; the Android CLI cannot.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback
import unicodedata
import zipfile

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
LAYOUT = '/data/user/0/' + PACKAGE + '/files/learning_layout_v1.json'
SELF = '.github/probes/lumo_english_objects_android_probe.py'
MEANINGS = {
    'book': ('Buch',), 'pen': ('Kugelschreiber', 'Stift'),
    'ruler': ('Lineal',), 'ball': ('Ball',), 'car': ('Auto',),
    'sun': ('Sonne',), 'apple': ('Apfel',),
    'bag': ('Tasche',), 'rubber': ('Radiergummi',),
    'school bag': ('Schultasche',), 'desk': ('Schreibtisch',),
    'chair': ('Sessel',), 'pencil case': ('Federpennal',),
    'paper': ('Papier',),
}
HINTS = {
    'book': 'Dieser Gegenstand hat viele Seiten. Du kannst darin lesen.',
    'pen': 'Damit kannst du schreiben und zeichnen. Achte auf die schmale Spitze.',
    'ruler': 'Damit misst du gerade Strecken. Die kleinen Striche zeigen die Länge.',
    'ball': 'Dieser runde Gegenstand kann rollen und springen.',
    'car': 'Dieses Fahrzeug fährt auf vier Rädern.',
    'sun': 'Dieses helle Himmelsobjekt gibt uns Licht und Wärme.',
    'apple': 'Diese Frucht wächst am Baum. Sie hat einen Stiel und ein Blatt.',
    'bag': 'In dieser Tasche kannst du Dinge tragen. Schau auf die beiden Henkel.',
    'rubber': 'Damit entfernst du Bleistiftstriche. Das weiche Stück steckt in einer Papierhülle.',
    'school bag': 'Darin trägst du deine Schulsachen. Suche die Schulterriemen und die kleine Vordertasche.',
    'desk': 'An dieser großen Platte kannst du schreiben. Vier Beine tragen sie.',
    'chair': 'Darauf kannst du sitzen. Suche die Sitzfläche und die hohe Rückenlehne.',
    'pencil case': 'Darin bewahrst du deine Stifte auf. Der Reißverschluss öffnet das kleine längliche Etui.',
    'paper': 'Auf diesem dünnen weißen Blatt kannst du schreiben oder zeichnen. Die Linien helfen dir dabei.',
}
HOST_FILES = (
    SELF, '.github/probes/modernization_android_tour.py',
    '.github/probes/creative_android_probe.py',
    '.github/probes/lumo_nextgen_surfaces_android_probe.py',
    '.github/probes/lumo_education_android_probe.py',
    '.github/probes/lumo_learning_journey_probe.py',
    '.github/probes/lumo_free_voice_android_probe.py',
    'scripts/probes/pr207_android_smoke.py', 'scripts/probes/pr207_android_ui_probe.py',
    'tools/android_qa/kart_tour_evidence.py', 'tools/android_qa/nextgen_evidence.py',
    '.github/probes/flutter_surface_readiness.py',
    'tools/android_qa/native_surface_readiness.py', 'tools/android_qa/native_ocr_tiles.py',
    'lib/domain/tutoring/native_learning_activity.dart',
    'lib/domain/tutoring/native_english_vocabulary.dart',
    'lib/features/learning/learning_content.dart',
    'lib/features/lumo3d/lumo3d_launcher.dart', 'lib/core/native_profile_key_repository.dart',
    'lib/app/app_state.dart', 'lib/core/legacy_learning_data.dart',
    'tools/auto_install/MainActivity.kt', 'tools/auto_install/LumoGameActivity.kt',
)
NATIVE_FILES = (
    'scripts/learning/learning_world.gd', 'scripts/learning/english_object_gallery.gd',
    'scripts/learning/learning_activity.gd', 'scripts/learning/english_vocabulary.gd',
    'scenes/learning/learning_world.tscn', 'scripts/app/mobile_runtime.gd',
    'scripts/app/android_safe_area.gd', 'scripts/app/scene_router.gd',
    'scripts/systems/host_bridge.gd',
)
PROTECTED_PREFIXES = (
    'flutter.lumo_progress', 'flutter.lumo_writing_progress', 'flutter.lumo_journal',
    'flutter.lumo_story_library', 'flutter.lumo_reading_sessions', 'flutter.lumo_attempt_log',
    'flutter.lumo_reward_wallet', 'flutter.lumo_school', 'flutter.lumo_learning',
    'flutter.lumo_legacy', 'flutter.lumo_3d_', 'flutter.lumo_app_settings',
    'flutter.lumo.cards.', 'flutter.lumo.connect_four.', 'flutter.lumo.memory.',
    'flutter.lumo.quiz.',
)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def parse_json(raw):
    def unique(pairs):
        value = {}
        for key, item in pairs:
            require(key not in value, 'Duplicate JSON key: ' + key)
            value[key] = item
        return value
    def invalid(value):
        raise RuntimeError('Non-finite JSON number: ' + value)
    return json.loads(raw, object_pairs_hook=unique, parse_constant=invalid)


def number(value, name):
    require(type(value) in (int, float) and math.isfinite(value), 'Invalid number: ' + name)
    return float(value)


def integer(value, name, minimum=0, maximum=2**63 - 1):
    require(type(value) is int and minimum <= value <= maximum, 'Invalid integer: ' + name)
    return value


def vector(value, count, name):
    require(type(value) is list and len(value) == count, 'Invalid vector: ' + name)
    return [number(item, name) for item in value]


def rect(value, name, empty=False):
    result = vector(value, 4, name)
    require(result[2] >= 0 and result[3] >= 0, 'Negative rectangle: ' + name)
    require(empty or min(result[2:]) > 0, 'Empty rectangle: ' + name)
    return result


def inside(inner, outer, epsilon=1e-4):
    return (inner[0] >= outer[0] - epsilon and inner[1] >= outer[1] - epsilon
            and inner[0] + inner[2] <= outer[0] + outer[2] + epsilon
            and inner[1] + inner[3] <= outer[1] + outer[3] + epsilon)


def overlap(a, b):
    return (min(a[0]+a[2], b[0]+b[2]) > max(a[0], b[0]) + 1e-4
            and min(a[1]+a[3], b[1]+b[3]) > max(a[1], b[1]) + 1e-4)


def near(a, b, epsilon=1e-3):
    return len(a) == len(b) and all(abs(x-y) <= epsilon for x, y in zip(a, b))


def bounds(points):
    xs, ys = [p[0] for p in points], [p[1] for p in points]
    return [min(xs), min(ys), max(xs)-min(xs), max(ys)-min(ys)]


def convex_hull(points):
    points = sorted(set(tuple(p) for p in points))
    def cross(o, a, b):
        return (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])
    parts = []
    for ordered in (points, list(reversed(points))):
        part = []
        for point in ordered:
            while len(part) >= 2 and cross(part[-2], part[-1], point) <= 0:
                part.pop()
            part.append(point)
        parts.append(part[:-1])
    return parts[0]+parts[1]


def point_inside_hull(point, hull):
    return len(hull) >= 3 and all(
        (b[0]-a[0])*(point[1]-a[1]) - (b[1]-a[1])*(point[0]-a[0]) >= -1e-3
        for a, b in zip(hull, hull[1:]+hull[:1]))


def normalized(text):
    text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', text.lower())


def check_task(prompt, options, counter):
    require(type(prompt) is str and type(options) is list, 'Missing actual task text')
    match = re.fullmatch(r'Was bedeutet „([^“]+)“\?', prompt)
    if not match:
        match = re.fullmatch(r'Was heißt (.+) auf Deutsch\?', prompt)
    require(match is not None, 'Not one of the real local English question forms')
    word = match.group(1)
    require(word in MEANINGS, 'UNSUPPORTED_CURRENT_TASK: ' + word)
    require(2 <= len(options) <= 6 and len(set(options)) == len(options)
            and all(type(x) is str and x for x in options), 'Actual answer choices are incomplete')
    meanings = [item for item in options if item in MEANINGS[word]]
    require(len(meanings) == 1, 'Actual English task has no unique supported meaning')
    require(re.fullmatch(r'Aufgabe [1-9]\d* / [1-9]\d*', counter) is not None,
            'Actual lesson position is absent')
    return {'prompt': prompt, 'word': word, 'meaning': meanings[0],
            'options': sorted(options), 'counter': counter}


def check_prior_tour(prior, apk_sha256, expected_api, expected_steps):
    require(type(prior) is dict and prior.get('status') == 'PASS'
            and prior.get('apk_sha256') == apk_sha256
            and prior.get('android_sdk') == str(expected_api)
            and prior.get('fatal_crashes') == 0,
            'The normal tour has not passed this exact installed APK/runtime')
    steps = prior.get('steps')
    require(type(steps) is list and len(steps) == len(expected_steps) == 21
            and all(type(row) is dict and row.get('ok') is True for row in steps),
            'The normal21-step tour is incomplete or has a failed observation')
    names = [row.get('step') for row in steps]
    require(all(type(name) is str for name in names)
            and len(set(names)) == 21 and set(names) == set(expected_steps),
            'The normal tour has duplicate, missing or foreign step identities')


def profile_binding(prefs):
    student = prefs.get('flutter.lumo_learning_local_student_id_v1')
    require(type(student) is str and re.fullmatch(r'local-[a-f0-9]{32}', student),
            'Existing local fictional test child required')
    require(not prefs.get('flutter.lumo_school_active_student_v1'),
            'This probe does not switch or test school-child owners')
    profile = parse_json(prefs.get('flutter.lumo_active_profile', '{}'))
    require(profile.get('name') == 'LumoTest' and profile.get('grade') == 1,
            'Existing setup-created LumoTest grade-one fixture required')
    registry = parse_json(prefs.get('flutter.lumo_3d_profile_keys_v1', '{}'))
    require(registry.get('version') == 1 and type(registry.get('owners')) is dict,
            'Existing native owner registry missing')
    key = registry['owners'].get(student)
    require(type(key) is str and re.fullmatch(r'p_[a-f0-9]{32}', key),
            'Current learning child has no actual native key')
    require(list(registry['owners'].values()).count(key) == 1, 'Native owner identity ambiguous')
    return {'child_key': key, 'grade': 1,
            'student_id_sha256': hashlib.sha256(student.encode()).hexdigest()}


def preservation(before, after):
    require(profile_binding(before) == profile_binding(after), 'Learning child changed')
    first = parse_json(before['flutter.lumo_active_profile'])
    last = parse_json(after['flutter.lumo_active_profile'])
    fields = ('id', 'name', 'age', 'grade', 'createdAt')
    require(all(first.get(k) == last.get(k) for k in fields), 'Active profile changed')
    a = {k: v for k, v in before.items() if k.startswith(PROTECTED_PREFIXES)}
    b = {k: v for k, v in after.items() if k.startswith(PROTECTED_PREFIXES)}
    require(a and a == b, 'Protected preferences changed during native help/return')
    return {'protected_keys': len(a), 'keys': sorted(a), 'unchanged': True,
            'scope': 'Only the actually present keys; no absent save/multi-child migration claim'}


def project(layout, world):
    world = vector(world, 3, 'world corner')
    camera = layout['camera']
    basis = camera['view_basis_columns']
    require(type(basis) is list and len(basis) == 3, 'View basis missing')
    basis = [vector(c, 3, 'view basis') for c in basis]
    origin = vector(camera['view_origin'], 3, 'view origin')
    view = [origin[row] + sum(basis[col][row]*world[col] for col in range(3))
            for row in range(3)] + [1.0]
    columns = camera['projection_columns']
    require(type(columns) is list and len(columns) == 4, 'Projection matrix missing')
    columns = [vector(c, 4, 'projection column') for c in columns]
    clip = [sum(columns[col][row]*view[col] for col in range(4)) for row in range(4)]
    require(clip[3] > 1e-8, 'Geometry lies behind the actual camera')
    width, height = vector(layout['window_px'], 2, 'window')
    return [(clip[0]/clip[3]+1)*width/2, (1-clip[1]/clip[3])*height/2]


def to_decor(layout, point):
    render = layout['android_observation']['render_rect']
    width, height = layout['window_px']
    return [render[0] + point[0]*render[2]/width,
            render[1] + point[1]*render[3]/height]


def decor_rect(layout, rectangle):
    first = to_decor(layout, rectangle[:2])
    last = to_decor(layout, [rectangle[0]+rectangle[2], rectangle[1]+rectangle[3]])
    return first + [last[0]-first[0], last[1]-first[1]]


def check_layout(layout, task, owner, image_size, density, pid, *, allow_fixture=False):
    require(type(layout) is dict and layout.get('schema') == 1, 'Missing layout schema')
    integer(layout.get('layout_sequence'), 'layout sequence', 1)
    integer(layout.get('ticks_msec'), 'ticks')
    require(integer(layout.get('pid'), 'PID', 1) == pid, 'Layout belongs to another process')
    require(layout.get('settled') is True and layout.get('ui_visible') is True,
            'Layout is not settled/visible')
    permitted = {'android_window_insets'} | ({'platform_fixture'} if allow_fixture else set())
    require(layout.get('observation_source') in permitted, 'No actual Android View/Insets observation')
    require(type(layout.get('suspended')) is bool, 'Missing actual lifecycle flag')
    launch = layout.get('launch')
    require(type(launch) is dict and launch.get('scene') == 'learning'
            and launch.get('subject') == 'Englisch', 'Wrong actual public launch route')
    require(launch.get('grade') == owner['grade'] and launch.get('childKey') == owner['child_key'],
            'Public launch does not belong to the existing learning child')
    require(type(launch.get('sessionId')) is str and re.fullmatch(
        r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', launch['sessionId']),
        'Actual Activity session UUID missing')
    expected_launch_keys = {'scene', 'subject', 'grade', 'childKey', 'sessionId', 'learning',
                           'learningVoiceEnabled', 'localVoiceLicenseAccepted', 'learningAutoRead'}
    require(set(launch) == expected_launch_keys, 'Unexpected private/free-text launch fields')
    for name in ('learningVoiceEnabled', 'localVoiceLicenseAccepted', 'learningAutoRead'):
        require(type(launch[name]) is bool, 'Voice policy field is not boolean')
    require(not launch['learningVoiceEnabled'] or launch['localVoiceLicenseAccepted'],
            'Native speech enabled without existing license assent')
    descriptor = launch['learning']
    require(type(descriptor) is dict and set(descriptor) == {'kind', 'word', 'meaning', 'objects'},
            'Unexpected learning descriptor')
    require(descriptor['kind'] == 'english_objects' and descriptor['word'] == task['word']
            and descriptor['meaning'] == task['meaning'], 'Native task differs from actual Flutter question')
    words = descriptor['objects']
    require(type(words) is list and len(words) == 3 and len(set(words)) == 3
            and all(word in MEANINGS for word in words) and task['word'] in words,
            'Invalid closed object set')
    selection = integer(layout.get('selection'), 'selection', -1, 2)
    attempts = integer(layout.get('attempts'), 'attempts', 0, 1000)
    hint = integer(layout.get('hint_level'), 'hint', 0, 2)
    complete = layout.get('complete')
    require(type(complete) is bool and (selection == -1) == (attempts == 0), 'Invalid local selection state')
    require(complete == (selection >= 0 and words[selection] == task['word']),
            'Completion does not match the selected real object')
    require(layout.get('title') == 'Englisch · ' + task['word'], 'Visible title not bound to task')
    explanation = ('Richtig: „%s“. Wähle jetzt „Zur Aufgabe“.' % task['meaning'] if complete else
                   'Tippe selbst auf den hell umrandeten Gegenstand.' if hint == 2 else
                   HINTS[task['word']] if hint == 1 else
                   'Das passt noch nicht. Ein Hinweis kann dir helfen.' if attempts else
                   'Tippe auf den Gegenstand zum englischen Wort.')
    require(layout.get('explanation') == explanation, 'Wrong current guidance/completion text')
    window = vector(layout.get('window_px'), 2, 'window')
    require(min(window) >= 240 and near(window, vector(layout.get('viewport_px'), 2, 'viewport')),
            'Learning window/viewport coordinate contract differs')
    require(abs(number(layout.get('density'), 'density')-density) < .001 and density > 0,
            'Layout density differs from actual Android density')
    measured = layout.get('android_observation')
    require(type(measured) is dict and set(measured) == {'view_size', 'decor_size', 'render_rect', 'system_insets', 'insets'},
            'Incomplete original Android View observation')
    decor = vector(measured['decor_size'], 2, 'decor')
    view = vector(measured['view_size'], 2, 'view')
    render = rect(measured['render_rect'], 'render View')
    system = vector(measured['system_insets'], 4, 'system insets')
    effective = vector(measured['insets'], 4, 'effective insets')
    require(near(decor, image_size) and near(view, render[2:]) and min(view) > 0,
            'Screenshot does not match actual decor/render View')
    require(inside(render, [0, 0, *decor]) and min(system+effective) >= 0,
            'Invalid View or system Insets')
    actual = [max(0, system[0]-render[0]), max(0, system[1]-render[1]),
              max(0, render[0]+render[2]-(decor[0]-system[2])),
              max(0, render[1]+render[3]-(decor[1]-system[3]))]
    require(near(effective, actual), 'Effective Insets are not actual View overlap')
    scaled = [effective[0]*window[0]/view[0], effective[1]*window[1]/view[1],
              effective[2]*window[0]/view[0], effective[3]*window[1]/view[1]]
    safe = rect(layout.get('safe_rect_px'), 'safe rectangle')
    require(near(safe, [scaled[0], scaled[1], window[0]-scaled[0]-scaled[2], window[1]-scaled[1]-scaled[3]]),
            'Safe rectangle does not follow measured Insets')
    stage = rect(layout.get('stage_rect_px'), 'stage')
    header = rect(layout.get('header_rect_px'), 'header')
    footer = rect(layout.get('footer_rect_px'), 'footer')
    require(all(inside(r, safe) for r in (stage, header, footer))
            and not overlap(stage, header) and not overlap(stage, footer), 'HUD intrudes into object stage')
    controls = layout.get('controls')
    require(type(controls) is list and all(type(c) is dict for c in controls), 'Controls missing')
    names = [c.get('id') for c in controls]
    expected = {'choice_0', 'choice_1', 'choice_2', 'hint', 'restart', 'return'}
    require(type(layout.get('voice_available')) is bool, 'Voice availability missing')
    if layout['voice_available']:
        expected.add('voice')
        require(launch['learningVoiceEnabled'] and launch['localVoiceLicenseAccepted'], 'Unlicensed voice control exposed')
    require(set(names) == expected and len(names) == len(expected), 'Missing/duplicate actual controls')
    for control in controls:
        r = rect(control.get('rect_px'), 'control')
        hit = rect(control.get('hit_rect_px'), 'exposed hit surface')
        require(control.get('visible') is True and type(control.get('enabled')) is bool,
                'Invisible or malformed control')
        require(inside(hit, r) and inside(r, footer) and inside(hit, safe), 'Clipped unsafe control')
        physical = decor_rect(layout, hit)
        require(min(physical[2:]) + 1e-6 >= 48*density, 'Exposed target smaller than48dp')
        enabled = not layout['suspended']
        if control['id'].startswith('choice_'):
            enabled = enabled and not complete
            require(control.get('text') == str(int(control['id'][-1])+1), 'Wrong numbered object label')
        elif control['id'] == 'hint':
            enabled = enabled and not complete and hint < 2
            require(control.get('text') == 'Hinweis', 'Wrong hint label')
        elif control['id'] == 'return':
            require(control.get('text') == 'Zur Aufgabe', 'Wrong return label')
        require(control['enabled'] is enabled, 'Control enablement contradicts actual state')
    objects = layout.get('objects')
    require(type(objects) is list and len(objects) == 3, 'Exactly three observed objects required')
    geometries = []
    for index, item in enumerate(objects):
        require(type(item) is dict and item.get('index') == index and item.get('word') == words[index],
                'Real object order differs from public descriptor')
        require(item.get('hint_visible') is ((hint == 2 or complete) and words[index] == task['word']),
                'Hint ring highlights the wrong object')
        meshes = item.get('meshes')
        require(type(meshes) is list and 2 <= len(meshes) <= 100, 'Actual object mesh observations absent')
        all_points, recognizable = [], []
        paths = set()
        for mesh in meshes:
            path = mesh.get('path')
            require(type(path) is str and path and path not in paths and '..' not in path,
                    'Ambiguous real mesh path')
            paths.add(path)
            world, projected = mesh.get('world_corners'), mesh.get('projected_corners_px')
            require(type(world) is list and len(world) == 8 and type(projected) is list and len(projected) == 8,
                    'Incomplete actual mesh bounds')
            independent = [project(layout, p) for p in world]
            for calculated, supplied in zip(independent, projected):
                require(near(calculated, vector(supplied, 2, 'projected corner'), 1.0),
                        'Independent projection disagrees with actual Godot corner')
            require(inside(bounds(independent), stage), 'Real object geometry intersects HUD/system bars')
            all_points.extend(independent)
            if path.startswith('RecognizableObject/'):
                recognizable.extend(independent)
        require(recognizable, 'Numbered plinth cannot replace the recognizable object')
        whole = bounds(all_points)
        require(min(decor_rect(layout, whole)[2:]) + 1e-6 >= 48*density, 'Actual object became a thumbnail')
        pick = rect(item.get('pick_rect_px'), 'spatial target', empty=True)
        collision = item.get('collision_world_corners')
        supplied_collision = item.get('collision_projected_corners_px')
        require(type(collision) is list and len(collision) == 8
                and type(supplied_collision) is list and len(supplied_collision) == 8,
                'Actual collision volume missing')
        projected_collision = [project(layout, corner) for corner in collision]
        require(all(near(a, vector(b, 2, 'collision projection'), 1.0)
                    for a, b in zip(projected_collision, supplied_collision)),
                'Independent collision projection differs')
        if min(pick[2:]) > 0:
            hull = convex_hull(projected_collision)
            corners = [[pick[0]+dx*pick[2], pick[1]+dy*pick[3]] for dx, dy in ((0, 0), (1, 0), (1, 1), (0, 1))]
            require(inside(pick, stage) and all(point_inside_hull(p, hull) for p in corners)
                    and min(decor_rect(layout, pick)[2:]) + 1e-6 >= 48*density,
                    'Claimed spatial target is unsafe or smaller than48dp')
        for old in geometries:
            require(not overlap(old['window_rect'], whole), 'Real objects overlap')
        geometries.append({'word': item['word'], 'window_rect': whole,
                           'object_decor_rect': decor_rect(layout, bounds(recognizable)),
                           'meshes': len(meshes)})
    return geometries


def check_pixels(image, geometries):
    from PIL import ImageStat
    result = []
    for item in geometries:
        x, y, width, height = item['object_decor_rect']
        box = (math.floor(x), math.floor(y), math.ceil(x+width), math.ceil(y+height))
        require(0 <= box[0] < box[2] <= image.width and 0 <= box[1] < box[3] <= image.height,
                'Projected object crop outside actual screenshot')
        crop = image.crop(box).convert('RGB')
        stats = ImageStat.Stat(crop)
        bins = {tuple(v//16 for v in rgb) for rgb in crop.getdata()}
        extrema = crop.getextrema()
        require(max(stats.stddev) >= 8 and len(bins) >= 12
                and max(hi-lo for lo, hi in extrema) >= 40, 'Blank/flat real object region')
        result.append({'word': item['word'], 'box': list(box), 'stddev': stats.stddev,
                       'colour_bins': len(bins), 'scope': 'Visible pixel detail, not semantic image recognition'})
    return result


def check_caption(lines, caption, image_size, region=None):
    wanted = normalized(caption)
    accepted = []
    for row in lines:
        if type(row) is not dict or normalized(str(row.get('text', ''))) != wanted:
            continue
        raw = vector(row.get('bounds'), 4, 'OCR bounds')
        r = [raw[0], raw[1], raw[2]-raw[0], raw[3]-raw[1]]
        if min(r[2:]) > 0 and inside(r, [0, 0, *image_size]) and (region is None or inside(r, region, 2)):
            accepted.append(row)
    require(accepted, 'Actual screenshot lacks exact bounded caption: ' + caption)
    return accepted


def check_transition(before, after, action, index=None):
    require(before['launch'] == after['launch'] and before['pid'] == after['pid'],
            'Action changed actual task/session/process')
    require(after['layout_sequence'] > before['layout_sequence'], 'Action reused an old observation')
    expected = {k: before[k] for k in ('selection', 'attempts', 'hint_level', 'complete')}
    if action == 'choice':
        require(type(index) is int and 0 <= index <= 2 and not before['complete'], 'Invalid choice transition')
        expected.update(selection=index, attempts=before['attempts']+1,
                        complete=before['launch']['learning']['objects'][index] == before['launch']['learning']['word'])
    elif action == 'hint':
        require(before['hint_level'] < 2 and not before['complete'], 'Invalid hint transition')
        expected['hint_level'] += 1
    elif action != 'home':
        raise RuntimeError('Unknown transition')
    require(all(after.get(k) == value for k, value in expected.items()), 'Actual state transition differs')
    require(after.get('suspended') is False, 'Activity did not resume actual input')
    return {'action': action, 'before_sequence': before['layout_sequence'],
            'after_sequence': after['layout_sequence'], 'actual_state': expected}


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def check_deadline(deadline, label):
    require(time.monotonic() < deadline, label + ' completed after its bounded deadline')


class AndroidProbe:
    def __init__(self, args):
        self.args, self.out = args, args.out
        self.out.mkdir(parents=True, exist_ok=True)
        require(not (self.out/'result.json').exists(), 'Refusing to overwrite an original probe result')
        self.count, self.events = 0, []
        os.environ['ANDROID_SERIAL'] = args.serial
        for relative in ('.github/probes', 'scripts/probes', 'tools/android_qa'):
            sys.path.insert(0, str(args.candidate_source/relative))
        self.tour = importlib.import_module('modernization_android_tour')
        self.probe, self.base, self.live = self.tour.probe, self.tour.base, self.tour.live
        self.surfaces = importlib.import_module('lumo_nextgen_surfaces_android_probe')
        self.education = importlib.import_module('lumo_education_android_probe')
        self.journey = importlib.import_module('lumo_learning_journey_probe')
        self.original_adb = self.base.adb
        self.base.adb = self.adb

    def tag(self, name):
        self.count += 1
        return '%04d-%s' % (self.count, name)

    def adb(self, *args, timeout=30, check=True):
        return self.base.command('adb', '-s', self.args.serial, *args, timeout=timeout, check=check)

    def foreground(self, native=True):
        value = self.surfaces.resumed_activity()
        target = 'LumoGameActivity' if native else 'MainActivity'
        require(target in value, 'Expected real foreground Activity missing: ' + target)
        return value

    def pid(self):
        value = self.adb('shell', 'pidof', PACKAGE+':lumo_game', check=False).strip()
        require(re.fullmatch(r'[1-9]\d*', value), 'Isolated learning process missing/ambiguous')
        return int(value)

    def read_layout(self):
        tag = self.tag('layout-read')
        started = time.time()
        result = subprocess.run(['adb', '-s', self.args.serial, 'exec-out', 'cat', LAYOUT],
                                capture_output=True, timeout=10)
        (self.out/(tag+'.raw')).write_bytes(result.stdout)
        (self.out/(tag+'.stderr')).write_bytes(result.stderr)
        digest = hashlib.sha256(result.stdout).hexdigest()
        write(self.out/(tag+'.json'), {'path': LAYOUT, 'started_unix_seconds': started,
              'finished_unix_seconds': time.time(), 'returncode': result.returncode,
              'bytes': len(result.stdout), 'sha256': digest})
        require(result.returncode == 0 and 0 < len(result.stdout) <= 262144,
                'No bounded actual Learning observation')
        return parse_json(result.stdout), digest

    def wait(self, name, observe, accept, timeout=45):
        deadline, errors = time.monotonic()+timeout, []
        while time.monotonic() < deadline:
            try:
                value = observe()
                if accept(value):
                    check_deadline(deadline, name)
                    return value
            except (RuntimeError, ValueError, KeyError, TypeError) as error:
                errors.append(str(error))
            time.sleep(min(.4, max(0, deadline-time.monotonic())))
        write(self.out/(self.tag(name)+'-failure.json'), {'errors': errors[-12:], 'budget_seconds': timeout})
        raise RuntimeError('Actual state not observed within budget: ' + name)

    def snapshot(self, name):
        from PIL import Image
        deadline = time.monotonic()+45
        for _ in range(12):
            check_deadline(deadline, name)
            try:
                self.foreground()
                pid = self.pid()
                layout, before_hash = self.read_layout()
                tag = self.tag(name)
                shot = self.probe.capture(self.out, tag, timeout=max(.01, deadline-time.monotonic()))
                path = self.out/shot['file']
                with Image.open(path) as source:
                    image = source.convert('RGB')
                geometry = check_layout(layout, self.task, self.owner, image.size, self.density, pid)
                pixels = check_pixels(image, geometry)
                caption = 'Englisch · '+self.task['word']
                lines = self.probe.image_lines(self.out, tag+'-title', normalized(caption), path,
                                               timeout=max(.01, min(12, deadline-time.monotonic())), exact=True)
                ocr = check_caption(lines, caption, image.size, decor_rect(layout, layout['header_rect_px']))
                after, after_hash = self.read_layout()
                require(before_hash == after_hash and layout == after, 'Layout changed during screenshot/OCR')
                self.foreground()
                require(pid == self.pid(), 'Native process changed during screenshot')
                check_deadline(deadline, name)
                report = {'capture': shot, 'layout': layout, 'layout_sha256': before_hash,
                          'independent_geometry': geometry, 'object_pixels': pixels, 'title_ocr': ocr}
                write(self.out/(tag+'-observation.json'), report)
                return report
            except (RuntimeError, ValueError, KeyError, TypeError, TimeoutError) as error:
                write(self.out/(self.tag(name)+'-rejected.json'), {'error': str(error)})
                time.sleep(min(.3, max(0, deadline-time.monotonic())))
        raise RuntimeError('No stable current English frame: ' + name)

    def touch(self, observation, identifier, *, spatial=None):
        layout = observation['layout']
        self.foreground()
        latest, digest = self.read_layout()
        require(digest == observation['layout_sha256'] and latest == layout and not layout['suspended'],
                'Touch target is no longer the actually captured layout')
        if spatial is None:
            matches = [c for c in layout['controls'] if c['id'] == identifier]
            require(len(matches) == 1 and matches[0]['enabled'] and matches[0]['visible'],
                    'Actual control unavailable')
            target = matches[0]['hit_rect_px']
        else:
            require(type(spatial) is int and 0 <= spatial < 3 and not layout['complete'], 'Invalid spatial input')
            target = layout['objects'][spatial]['pick_rect_px']
        physical = decor_rect(layout, target)
        require(min(physical[2:])+1e-6 >= 48*self.density, 'Actual target is smaller than48dp')
        point = [round(physical[0]+physical[2]/2), round(physical[1]+physical[3]/2)]
        self.events.append({'type': 'actual_adb_touch', 'identifier': identifier, 'spatial_index': spatial,
                            'point': point, 'hit_rect_decor': physical, 'layout_sha256': digest,
                            'layout_sequence': layout['layout_sequence'], 'capture': observation['capture']})
        write(self.out/'input-events.json', self.events)
        self.adb('shell', 'input', 'tap', *map(str, point))

    def nodes(self, name):
        return self.live.live_nodes(self.out, self.tag(name))

    def flutter_tap(self, caption, name, scrolls=12):
        deadline = time.monotonic()+60
        for attempt in range(scrolls+1):
            nodes = self.nodes(name)
            target = self.education._enabled_control_bounds(nodes, caption)
            if target and min(target[2]-target[0], target[3]-target[1]) >= 48*self.density:
                shot = self.probe.capture(self.out, self.tag(name+'-actual-target'),
                                          timeout=max(.01, deadline-time.monotonic()))
                # Accessibility is reread after capture; the real tap never uses old bounds.
                current = self.education._enabled_control_bounds(self.nodes(name+'-current'), caption)
                if current != target:
                    continue
                check_deadline(deadline, name)
                point = [round((target[0]+target[2])/2), round((target[1]+target[3])/2)]
                self.events.append({'type': 'actual_flutter_touch', 'caption': caption,
                                    'bounds': target, 'point': point, 'capture': shot})
                write(self.out/'input-events.json', self.events)
                self.adb('shell', 'input', 'tap', *map(str, point))
                return
            if attempt == scrolls:
                break
            box = self.education._scroll_bounds(nodes)
            require(box is not None, 'No actual scroll viewport for ' + caption)
            x = round((box[0]+box[2])/2)
            a, b = round(box[1]+.75*(box[3]-box[1])), round(box[1]+.25*(box[3]-box[1]))
            if attempt >= scrolls//2:
                a, b = b, a
            self.adb('shell', 'input', 'swipe', str(x), str(a), str(x), str(b), '400')
            check_deadline(deadline, name)
            time.sleep(.4)
        raise RuntimeError('No real exposed48dp Flutter control: ' + caption)

    def navigate(self):
        for _ in range(4):
            nodes = self.nodes('actual-starting-route')
            labels = self.tour.labels(nodes)
            if self.education._enabled_control_bounds(nodes, self.journey.LEARN_TILE):
                self.flutter_tap(self.journey.LEARN_TILE, 'learning-tab', scrolls=0)
                break
            if any('Spiel pausiert' in label for label in labels):
                self.flutter_tap('Zur Spieleauswahl', 'leave-native-game-pause')
            elif self.education._enabled_control_bounds(nodes, 'Zur Spielwelt zurück'):
                self.flutter_tap('Zur Spielwelt zurück', 'leave-game-showcase', scrolls=0)
            else:
                raise RuntimeError('No observed safe route from current Flutter page to learning')
        else:
            raise RuntimeError('Actual learning hub not reached through bounded public controls')
        self.wait('learning-hub', lambda: self.tour.labels(self.nodes('learning-hub')),
                  lambda labels: any('Was möchtest du lernen?' in x for x in labels))
        self.flutter_tap('Englisch', 'english-subject')
        self.wait('english-topics', lambda: self.tour.labels(self.nodes('english-topics')),
                  lambda labels: any('Wähle ein Thema.' in x for x in labels))
        self.flutter_tap('Schulsachen', 'school-objects-topic')
        self.wait('actual-english-task', lambda: self.tour.labels(self.nodes('english-task')),
                  lambda labels: any('Was bedeutet ' in x or 'Was heißt ' in x for x in labels))

    def task_observation(self, name):
        texts, captions = set(), set()
        deadline = time.monotonic()+60
        for attempt in range(17):
            nodes = self.nodes(name)
            for node in nodes:
                if node.get('package') != PACKAGE or node.get('visible-to-user') == 'false':
                    continue
                for value in (node.get('text', ''), node.get('content-desc', '')):
                    texts.update(value.splitlines())
                    if node.get('clickable') == 'true' and node.get('enabled') == 'true':
                        captions.update(value.splitlines())
            prompts = {s.strip() for s in texts if re.fullmatch(r'Was bedeutet „[^“]+“\?|Was heißt .+ auf Deutsch\?', s.strip())}
            counters = {s.strip() for s in texts if re.fullmatch(r'Aufgabe [1-9]\d* / [1-9]\d*', s.strip())}
            if len(prompts) == 1 and len(counters) == 1 and 'Mit Lumo in 3D ausprobieren' in captions:
                # Real choice nodes use the renderer's own option text; no answer is sent.
                options = sorted(s for s in captions if s in {m for group in MEANINGS.values() for m in group}
                                 or s in {'Tasche', 'Radiergummi', 'Schultasche', 'Schreibtisch', 'Sessel', 'Federpennal', 'Papier', 'Stift'})
                require(len(options) <= 4, 'More than four actual Schulsachen choices or task changed while scrolling')
                if len(options) == 4:
                    task = check_task(next(iter(prompts)), options, next(iter(counters)))
                    check_deadline(deadline, name)
                    write(self.out/(name+'-task.json'), task)
                    return task
            if len(prompts) == 1:
                prompt = next(iter(prompts))
                word = re.fullmatch(r'Was bedeutet „([^“]+)“\?|Was heißt (.+) auf Deutsch\?', prompt)
                observed_word = word.group(1) or word.group(2)
                if observed_word not in MEANINGS:
                    write(self.out/(name+'-unsupported.json'), {'prompt': prompt, 'scope': 'Observed current task outside current native catalogue; no answer/reward injected'})
                    raise RuntimeError('UNSUPPORTED_CURRENT_TASK: '+observed_word)
            box = self.education._scroll_bounds(nodes)
            require(box is not None and attempt < 16, 'Actual task/options/3D help not jointly observed')
            x = round((box[0]+box[2])/2)
            high, low = round(box[1]+.75*(box[3]-box[1])), round(box[1]+.25*(box[3]-box[1]))
            a, b = (high, low) if attempt < 8 else (low, high)
            self.adb('shell', 'input', 'swipe', str(x), str(a), str(x), str(b), '400')
            check_deadline(deadline, name)
            time.sleep(.4)
        raise RuntimeError('Actual unchanged English task not fully observed')

    def binding(self):
        a = self.args
        hashes = {}
        for root, expected, paths, prefix in (
                (a.candidate_source, a.expected_source, HOST_FILES, 'host/'),
                (a.native_source, a.expected_native, NATIVE_FILES, 'native/')):
            require(re.fullmatch('[a-f0-9]{40}', expected), 'Full source commit required')
            require(subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip() == expected,
                    'Actual checkout source differs')
            require(not subprocess.check_output(['git', '-C', str(root), 'status', '--porcelain', '--untracked-files=no'], text=True).strip(),
                    'Tracked candidate source is dirty')
            for relative in paths:
                actual = (root/relative).read_bytes()
                expected_bytes = subprocess.check_output(['git', '-C', str(root), 'show', 'HEAD:'+relative])
                require(actual == expected_bytes, 'Executed working source differs: '+relative)
                hashes[prefix+relative] = hashlib.sha256(actual).hexdigest()
        require(Path.cwd().resolve() == a.candidate_source and Path(__file__).resolve() == a.candidate_source/SELF,
                'Run actual candidate probe in its clean candidate CWD')
        identity = self.tour.verify_apk_identity(a.apk, a.provenance, a.sums)
        require(identity['flutter_source_commit'] == a.expected_source and identity['godot_revision'] == a.expected_native,
                'APK provenance source differs')
        with zipfile.ZipFile(a.apk) as archive:
            require(archive.namelist().count('assets/lumo_game.pck') == 1, 'Actual embedded PCK absent/ambiguous')
            with archive.open('assets/lumo_game.pck') as stream:
                pck = hashlib.file_digest(stream, 'sha256').hexdigest()
        require(pck == identity['godot_pck_sha256'], 'Actual embedded PCK differs')
        installed = self.adb('shell', 'pm', 'path', PACKAGE).strip().splitlines()
        require(len(installed) == 1 and re.fullmatch(r'package:/data/app/[A-Za-z0-9_./=+~-]+/base\.apk', installed[0]),
                'Installed candidate APK path absent/ambiguous')
        digest = self.adb('shell', 'sha256sum', installed[0][8:]).split()[0]
        require(digest == identity['apk_sha256'], 'Installed APK is not the verified candidate')
        return {'host': a.expected_source, 'native': a.expected_native, 'apk': identity,
                'installed_apk_sha256': digest, 'embedded_pck_sha256': pck, 'source_hashes': hashes}

    def returned(self):
        self.wait('native-return', lambda: (not self.tour.godot_alive()
                  and 'MainActivity' in self.surfaces.resumed_activity()), bool)
        require(self.tour.alive(), 'Flutter host died during native return')
        after_task = self.task_observation('returned-task')
        require(after_task == self.task, 'Returned to a different question/options/lesson position')
        # Bring the exact original prompt into the real viewport, without submitting it.
        self.education.wait_text(self.out, self.task['prompt'], self.tag('return-prompt-visible'), timeout=45, scroll=True)
        accepted, deadline = [], time.monotonic()+30
        from PIL import Image
        for _ in range(12):
            check_deadline(deadline, 'actual Flutter return pixels')
            try:
                self.foreground(native=False)
                require(not self.tour.godot_alive(), 'Private process returned while checking Flutter pixels')
                tag = self.tag('returned-flutter')
                shot = self.probe.capture(self.out, tag, timeout=max(.01, deadline-time.monotonic()))
                path = self.out/shot['file']
                with Image.open(path) as image:
                    size = image.size
                lines = self.probe.image_lines(self.out, tag, normalized(self.task['prompt']), path,
                    timeout=max(.01, deadline-time.monotonic()), exact=True,
                    reject_captions=('Die Spielwelt wird geöffnet',))
                captions = check_caption(lines, self.task['prompt'], size)
                self.foreground(native=False)
                require(not self.tour.godot_alive(), 'Native process revived during return capture')
                check_deadline(deadline, 'actual Flutter return pixels')
                accepted.append({'capture': shot, 'captions': captions})
                if len(accepted) == 2:
                    break
            except (RuntimeError, TimeoutError) as error:
                write(self.out/(self.tag('return-rejected')+'.json'), {'error': str(error)})
        require(len(accepted) == 2, 'Two actual positive returned Flutter frames not observed')
        result = subprocess.run(['adb', '-s', self.args.serial, 'shell', 'test', '-e', LAYOUT],
                                capture_output=True, timeout=10)
        write(self.out/'closed-observation.json', {'path': LAYOUT, 'returncode': result.returncode,
              'stdout': result.stdout.decode(errors='replace'), 'stderr': result.stderr.decode(errors='replace')})
        require(result.returncode == 1 and not result.stderr, 'Closed learning observation still exists/read failed')
        write(self.out/'return-pixels.json', {'status': 'PASS', 'frames': accepted, 'task': after_task,
                                            'budget_seconds': 30, 'maximum_observations': 12})
        return after_task

    def run(self):
        a = self.args
        require(re.fullmatch(r'emulator-\d+', a.serial), 'Existing disposable emulator required')
        require(self.adb('get-serialno').strip() == a.serial, 'Wrong actual emulator')
        require(self.adb('shell', 'getprop', 'ro.kernel.qemu').strip() == '1'
                and self.adb('shell', 'id', '-u').strip() == '0',
                'Requires already rooted disposable CI emulator; this probe never requests root')
        runtime = {'sdk': int(self.adb('shell', 'getprop', 'ro.build.version.sdk').strip()),
                   'release': self.adb('shell', 'getprop', 'ro.build.version.release').strip(),
                   'fingerprint': self.adb('shell', 'getprop', 'ro.build.fingerprint').strip()}
        require(runtime['sdk'] == a.expected_api and runtime['release'] == {35: '15', 37: '17'}[a.expected_api]
                and runtime['fingerprint'], 'Actual Android runtime differs')
        before = self.binding()
        prior = parse_json(a.tour_result.read_bytes())
        check_prior_tour(prior, before['apk']['apk_sha256'], a.expected_api,
                         (*self.tour.HARD_STEPS, 'display-fold_offen',
                          'display-fold_aussen', 'display-quer'))
        density = self.adb('shell', 'wm', 'density')
        (self.out/'actual-density.txt').write_text(density)
        values = re.findall(r'(?:Physical|Override) density:\s*(\d+)', density)
        require(values, 'Actual density absent')
        self.density = int(values[-1])/160
        write(self.out/'binding-before.json', before)
        self.navigate()
        self.task = self.task_observation('before-native')
        before_prefs = self.probe.prefs(self.out, 'before-native')
        self.owner = profile_binding(before_prefs)
        self.flutter_tap('Mit Lumo in 3D ausprobieren', 'open-real-learning')
        self.wait('native-learning', lambda: 'LumoGameActivity' in self.surfaces.resumed_activity(), bool, 60)
        current = self.snapshot('initial')
        state = current['layout']
        require(state['selection'] == -1 and state['attempts'] == 0 and state['hint_level'] == 0
                and not state['complete'] and not state['suspended'], 'Actual new illustration not fresh')
        settings = parse_json(before_prefs.get('flutter.lumo_app_settings_v1', '{}'))
        require(state['launch']['localVoiceLicenseAccepted'] is (settings.get('localVoiceLicenseAccepted') is True),
                'Native voice assent differs from actual parent settings')
        require(not state['launch']['learningVoiceEnabled'] or settings.get('voiceEnabled') is True,
                'Native voice ignores actual mute setting')
        transitions = []
        target = state['launch']['learning']['objects'].index(self.task['word'])
        wrong = (target+1) % 3
        self.touch(current, 'choice_'+str(wrong))
        self.wait('wrong-choice', lambda: self.read_layout()[0], lambda x: x.get('attempts') == 1)
        after = self.snapshot('wrong-choice')
        transitions.append(check_transition(current['layout'], after['layout'], 'choice', wrong))
        current = after
        for level in (1, 2):
            self.touch(current, 'hint')
            self.wait('hint-'+str(level), lambda: self.read_layout()[0], lambda x: x.get('hint_level') == level)
            after = self.snapshot('hint-'+str(level))
            transitions.append(check_transition(current['layout'], after['layout'], 'hint'))
            current = after
        home_before = current['layout']
        self.adb('shell', 'input', 'keyevent', '3')
        self.wait('actual-home', lambda: self.adb('shell', 'dumpsys', 'activity', 'activities'),
                  lambda raw: not re.search(r'mResumedActivity.*'+re.escape(PACKAGE), raw), 20)
        time.sleep(2.6)
        require(self.pid() == home_before['pid'], 'Home destroyed actual lesson process')
        # The app may have stopped before it could publish a paused snapshot.
        # Absence is valid here; an old settled active snapshot is not.
        observed = subprocess.run(['adb', '-s', a.serial, 'exec-out', 'cat', LAYOUT],
                                  capture_output=True, timeout=10)
        (self.out/'home-layout.raw').write_bytes(observed.stdout)
        (self.out/'home-layout.stderr').write_bytes(observed.stderr)
        if observed.returncode == 0:
            paused = parse_json(observed.stdout)
            require(paused.get('suspended') is True and paused.get('launch') == home_before['launch'],
                    'Home retained a stale active or foreign lesson observation')
        else:
            exists = subprocess.run(['adb', '-s', a.serial, 'shell', 'test', '-e', LAYOUT],
                                    capture_output=True, timeout=10)
            write(self.out/'home-observation-existence.json', {'returncode': exists.returncode,
                  'stdout': exists.stdout.decode(errors='replace'), 'stderr': exists.stderr.decode(errors='replace')})
            require(exists.returncode == 1 and not exists.stderr and b'No such file or directory' in observed.stderr,
                    'Home observation read failed for a reason other than actual invalidation')
        write(self.out/'home-observation.json', {'returncode': observed.returncode,
              'bytes': len(observed.stdout), 'sha256': hashlib.sha256(observed.stdout).hexdigest(),
              'scope': 'Read-only lifecycle observation; absent file is not a paused-state sample'})
        self.base.launch(self.out, self.tag('resume-from-home'))
        self.wait('same-native-resumed', lambda: 'LumoGameActivity' in self.surfaces.resumed_activity(), bool)
        after = self.snapshot('after-home')
        transitions.append(check_transition(home_before, after['layout'], 'home'))
        current = after
        spatial = current['layout']['objects'][target]['pick_rect_px']
        spatial_used = min(spatial[2:]) > 0
        self.touch(current, 'object_'+str(target) if spatial_used else 'choice_'+str(target),
                   spatial=target if spatial_used else None)
        self.wait('correct-object', lambda: self.read_layout()[0], lambda x: x.get('complete') is True)
        after = self.snapshot('complete')
        transitions.append(check_transition(current['layout'], after['layout'], 'choice', target))
        self.touch(after, 'return')
        self.returned()
        retained = preservation(before_prefs, self.probe.prefs(self.out, 'after-native'))
        after_binding = self.binding()
        require(before == after_binding, 'Actual sources/APK/PCK changed during English probe')
        crashes = self.tour.logcat_fatal()
        require(not crashes, 'Actual application crash recorded')
        write(self.out/'binding-after.json', after_binding)
        return {'status': 'PASS', 'source_binding': before, 'android_runtime': runtime,
                'task': self.task, 'transitions': transitions, 'spatial_object_touch': spatial_used,
                'profile_preservation': retained, 'same_actual_task_returned': True,
                'no_answer_or_mastery_submitted': True, 'fatal_crashes': len(crashes),
                'scope': 'Actual existing child English task; visible objects, wrong choice, two bounded hints, Home/resume, correct illustration, two real Flutter return frames; no injected state',
                'not_tested': ['English pronunciation or actual audio playback', 'Applied facial/jaw motion',
                              'Physical Fold7/FPS/thermal/touch latency', 'Two-child switching',
                              'Absent historical saves/journal/writing data', 'Unrepresented English words/abstract phrases']}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('candidate-source', 'native-source', 'apk', 'provenance', 'sums', 'tour-result', 'out'):
        parser.add_argument('--'+name, required=True, type=Path)
    for name in ('expected-source', 'expected-native', 'serial'):
        parser.add_argument('--'+name, required=True)
    parser.add_argument('--expected-api', type=int, choices=(35, 37), required=True)
    args = parser.parse_args(argv)
    for name in ('candidate_source', 'native_source', 'apk', 'provenance', 'sums', 'tour_result', 'out'):
        setattr(args, name, getattr(args, name).resolve())
    if (args.out/'result.json').exists():
        print('Refusing to overwrite previous probe result', file=sys.stderr)
        return 2
    probe = None
    try:
        probe = AndroidProbe(args)
        write(args.out/'result.json', probe.run())
        return 0
    except Exception as error:
        args.out.mkdir(parents=True, exist_ok=True)
        write(args.out/'result.json', {'status': 'FAIL', 'error': type(error).__name__+': '+str(error),
              'expected_host': args.expected_source, 'expected_native': args.expected_native,
              'unsupported_current_task': 'UNSUPPORTED_CURRENT_TASK:' in str(error), 'android_pass_claimed': False})
        (args.out/'failure-traceback.txt').write_text(traceback.format_exc())
        if probe is not None:
            try:
                probe.probe.capture(args.out, 'failure-actual-screen')
            except Exception as capture_error:
                (args.out/'failure-capture-error.txt').write_text(str(capture_error))
        return 1
    finally:
        if probe is not None:
            probe.base.adb = probe.original_adb


if __name__ == '__main__':
    raise SystemExit(main())
