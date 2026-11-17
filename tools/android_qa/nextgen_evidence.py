"""Fail-closed checks of real Cards IPC, persisted rounds and learning moves.

These functions inspect observations. They never create Android app state.
"""
from __future__ import annotations

import re


def require_learning_voice(log: str, *, after_final_move: bool = False) -> dict:
    """Require real Android MediaPlayer start/completion; never infer sound quality."""
    if after_final_move:
        movements = list(re.finditer(
            r'\[LearningWorld\] move kind=bridge_ten token=\d+ target=12 placed=5 complete=true', log))
        if not movements:
            raise RuntimeError('No actual final bridge move before the spoken result')
        log = log[movements[-1].end():]
    events = re.findall(
        r'(?m)^I/LumoLearningSpeech\s*\(\s*(\d+)\):\s*'
        r'(started|completed) id=(\d+)(?: profile=([\w-]+))?\s*$', log)
    starts, completed, pids = {}, [], set()
    for pid, state, raw_id, profile in events:
        utterance = int(raw_id)
        if utterance <= 0:
            raise RuntimeError('Invalid native speech utterance identity')
        if state == 'started':
            if profile != 'lumo-free-supertonic-de-v1':
                raise RuntimeError('Speech did not use the original local Lumo profile')
            starts[(int(pid), utterance)] = True
        elif (int(pid), utterance) in starts:
            completed.append(utterance)
            pids.add(int(pid))
    if not completed or len(pids) != 1:
        raise RuntimeError('No completed actual local playback in one native process')
    return {'native_process_pid': pids.pop(), 'completed_utterance_ids': sorted(set(completed)),
            'profile': 'lumo-free-supertonic-de-v1', 'preset': 'F2',
            'audible_quality_verified': False, 'lip_sync_verified': False}


def require_cards_authority_binding(services: str, package: str) -> dict:
    """Read Android's real ServiceRecord/IntentBindRecord dump, not app claims.

    AOSP's IntentBindRecord.dumpInService emits requested/received/hasBound and
    a Client AppBindRecord containing its ProcessRecord. Unknown dump formats
    fail closed so saved output can be inspected before adapting the parser.
    """
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+', package):
        raise RuntimeError('Invalid Android package for Cards binding evidence')
    # Android's applicationId adds .coachpreview, while the compiled Kotlin
    # namespace remains dev.ullmann.lumo.lumo_lernen. Do not confuse the two.
    service_class = 'dev.ullmann.lumo.lumo_lernen.CardsAuthorityService'
    class_names = [re.escape(service_class)]
    if service_class.startswith(package + '.'):
        class_names.append(re.escape(service_class[len(package):]))
    component = re.escape(package) + r'/(?:' + '|'.join(class_names) + r')'
    blocks = re.split(r'(?m)(?=^[ \t]*\* ServiceRecord\{)', services)
    # The recorded Android dump adds its defining package as `c:<package>`.
    # Accept only that observed suffix and the legacy header. Match the whole
    # header so a foreign component or a later line cannot supply its identity.
    header = (r'^[ \t]*\* ServiceRecord\{[^\s{}]+ u\d+ ' + component +
              r'(?: c:' + re.escape(package) + r')?\}[ \t]*(?:\r?\n|$)')
    matching = [block for block in blocks if re.match(
        header, block)]
    if len(matching) != 1:
        raise RuntimeError('Expected one actual Android CardsAuthorityService record')
    block = matching[0]
    main = re.search(r'\bapp=ProcessRecord\{[^\n}]* (\d+):' + re.escape(package) + r'/[^\n}]+\}', block)
    client = re.search(r'\* Client AppBindRecord\{[^\n}]*ProcessRecord\{[^\n}]* (\d+):' +
                       re.escape(package) + r':lumo_game/[^\n}]+\}', block)
    if not main or not client or main[1] == client[1]:
        raise RuntimeError('Cards service must bind the visible native process to the distinct Dart host')
    if not re.search(r'\brequested=true received=true hasBound=true\b', block):
        raise RuntimeError('Android has not delivered a live Cards authority binding')
    if not re.search(r'ConnectionRecord\{[^\n}]*\bCR\b[^\n}]*' + component, block):
        raise RuntimeError('Cards authority has no actual auto-create connection')
    return {'main_process_pid': int(main[1]), 'native_process_pid': int(client[1]),
            'service': service_class, 'bound': True}


def require_saved_round(saved: dict, round_id: str) -> dict:
    if not re.fullmatch(r'cards-[a-f0-9]{32}', round_id):
        raise RuntimeError('Cards round identity is not an opaque generated ID')
    if saved.get('id') != round_id or saved.get('version') != 1 or saved.get('deckVersion') != 1:
        raise RuntimeError('Persisted Cards round identity/version changed')
    if not re.fullmatch(r'[a-f0-9]{64}', saved.get('owner', '')):
        raise RuntimeError('Cards save does not have a per-child owner')
    players = saved.get('players')
    if not isinstance(players, list) or len(players) != 2:
        raise RuntimeError('Cards save must retain both players')
    groups = [saved.get('draw'), saved.get('discard')]
    groups.extend(player.get('hand') for player in players)
    if not all(isinstance(group, list) for group in groups) or not groups[1]:
        raise RuntimeError('Cards save has incomplete deck groups')
    cards = [card for group in groups for card in group]
    if len(cards) != 112 or any(not isinstance(card, str) or not card for card in cards):
        raise RuntimeError('Cards save did not conserve the complete 112-card deck')
    if len(set(cards)) != 112:
        raise RuntimeError('Cards save contains duplicated cards')
    return {'round_id': round_id, 'owner': saved['owner'], 'cards_conserved': len(cards)}


def require_public_saved_match(public: dict, saved: dict) -> dict:
    report = require_saved_round(saved, public.get('roundId', ''))
    if public.get('protocol') != 1 or not re.fullmatch(r'[a-f0-9]{32}', public.get('token', '')):
        raise RuntimeError('Cards public state has an invalid protocol/session')
    viewer = public.get('viewer')
    if type(viewer) is not int or viewer not in (0, 1):
        raise RuntimeError('Cards public viewer is invalid')
    expected_hand = saved['players'][viewer]['hand']
    if [card.get('id') for card in public.get('hand', [])] != expected_hand:
        raise RuntimeError('Rendered Cards hand differs from persisted authoritative hand')
    if (public.get('drawCount') != len(saved['draw']) or
            public.get('top', {}).get('id') != saved['discard'][-1] or
            public.get('current') != saved.get('current') or
            public.get('phase') != saved.get('phase')):
        raise RuntimeError('Rendered Cards state is not the persisted authoritative round')
    public_players = public.get('players', [])
    if len(public_players) != 2 or any(
            player.get('count') != len(saved['players'][i]['hand']) or
            player.get('stars') != saved['players'][i].get('stars')
            for i, player in enumerate(public_players)):
        raise RuntimeError('Rendered opponent counts/stars differ from the saved round')
    for player in public_players:
        if 'hand' in player or 'cards' in player:
            raise RuntimeError('Private opponent cards leaked into the public IPC state')
    if any(key in public for key in ('draw', 'drawPile', 'correctIndex', 'correct')):
        raise RuntimeError('Private deck or learning answers leaked into the renderer')
    question = public.get('question', {})
    if isinstance(question, dict) and any(key in question for key in ('correct', 'correctIndex')):
        raise RuntimeError('Learning answer leaked into public question')
    return report


def require_cards_draw(before: dict, request: dict, after: dict, saved: dict, *, owner: str) -> dict:
    report = require_public_saved_match(after, saved)
    if not re.fullmatch(r'[a-f0-9]{64}', owner) or saved['owner'] != owner:
        raise RuntimeError('Cards draw changed the persisted child owner')
    if not before.get('canDraw') or before.get('paused') or before.get('viewer') != 0:
        raise RuntimeError('Draw did not start on the active child turn')
    for key in ('token', 'roundId', 'viewer'):
        if before.get(key) != after.get(key):
            raise RuntimeError('Cards draw changed session, round or child identity')
    sequence = request.get('sequence')
    if (request.get('action') != 'draw' or request.get('token') != before.get('token') or
            request.get('revision') != before.get('revision') or
            type(sequence) is not int or sequence <= before.get('ack', -1) or
            type(after.get('ack')) is not int or after['ack'] < sequence or
            after.get('revision', -1) <= before.get('revision', -1)):
        raise RuntimeError('The real native draw was not acknowledged by the same Dart round')
    old_hand = {card['id'] for card in before['hand']}
    new_hand = {card['id'] for card in after['hand']}
    # The child only drew. A subsequent bot draw-two can add more cards, but
    # cannot remove a card from the child's hand or replace its round.
    if not old_hand < new_hand or after['drawCount'] >= before['drawCount']:
        raise RuntimeError('Acknowledgement did not produce an actual persisted card draw')
    report.update(sequence=sequence, revision_before=before['revision'],
                  revision_after=after['revision'], child_cards_added=len(new_hand - old_hand),
                  draw_count_before=before['drawCount'], draw_count_after=after['drawCount'])
    return report


def cards_projected_faces(width: int, height: int, density: float, hand_count: int,
                          *, ui_rect=None) -> dict:
    """Project the actual Cards plane meshes; these are never input coordinates.

    This layout contract follows cards_table.gd's billboard/projection and is
    checked against independent Godot unproject_position readbacks in five
    viewports. Unknown inputs fail rather than sampling a guessed screen area.
    """
    import math

    if (type(width) is not int or type(height) is not int or
            not 64 <= width <= 8192 or not 64 <= height <= 8192 or
            type(hand_count) is not int or not 1 <= hand_count <= 112 or
            isinstance(density, bool) or not isinstance(density, (int, float)) or
            not math.isfinite(density) or not .75 <= density <= 4):
        raise RuntimeError('Cards pixel proof requires valid viewport/density/hand geometry')
    supported = {(1080, 2400, 2.625), (1280, 720, 1), (412, 915, 1),
                 (690, 829, 1), (2400, 1080, 2.625)}
    if ui_rect is None and (width, height, density) not in supported:
        raise RuntimeError('Cards pixel proof has no verified production geometry for this layout')
    if ui_rect is None:
        ui_rect = [0, 0, width, height]
    if (not isinstance(ui_rect, (list, tuple)) or len(ui_rect) != 4 or
            any(isinstance(value, bool) or not isinstance(value, (int, float)) or
                not math.isfinite(value) for value in ui_rect)):
        raise RuntimeError('Cards projection requires a finite measured UI rectangle')
    ui_x, ui_y, ui_width, ui_height = ui_rect
    if not (0 <= ui_x < width and 0 <= ui_y < height and
            0 < ui_width <= width - ui_x and 0 < ui_height <= height - ui_y):
        raise RuntimeError('Cards measured UI rectangle exceeds its native viewport')
    compact = ui_height / density < 520 and ui_width > ui_height
    page_size = 7 if ui_width / density > 850 else 5 if ui_width / density > 550 else 3
    if hand_count < page_size:
        raise RuntimeError('Cards pixel proof requires the verified full first hand page')
    visible = min(page_size, hand_count)
    card_height = 96 * density if compact else min(max(ui_height * .28, 96 * density), 180 * density)
    card_width = card_height * .83 / 1.18
    spacing = min(card_width * 1.08, (ui_width - 32 * density - card_width) / max(1, visible - 1))
    focal = height / (2 * math.tan(math.radians(23)))
    # PlaneMesh is 0.017 units in front of the body; retain its true projection
    # instead of using the nominal screen-space layout rectangle.
    scale = 4 * card_height / focal / 1.18
    magnification = 4 / (4 - .017 * scale)
    anchor_y = ui_y + ui_height - (76 if compact else 140) * density - card_height / 2
    center_y = height / 2 + (anchor_y - height / 2) * magnification
    hand = []
    for index in range(visible):
        anchor_x = ui_x + ui_width / 2 + (index - (visible - 1) / 2) * spacing
        center_x = width / 2 + (anchor_x - width / 2) * magnification
        x0, x1 = center_x - card_width * magnification / 2, center_x + card_width * magnification / 2
        y0, y1 = center_y - card_height * magnification / 2, center_y + card_height * magnification / 2
        hand.append([[x0, y0], [x1, y0], [x1, y1], [x0, y1]])

    distance = max(1, .72 / (width / height))
    eye = (0, 5.3 * distance, 7 * distance)
    backward = (0, eye[1] - 1.05, eye[2] + .25)
    length = math.sqrt(sum(value * value for value in backward))
    backward = tuple(value / length for value in backward)
    up = (0, backward[2], -backward[1])
    discard = []
    for x, z in ((-.415, -.59), (.415, -.59), (.415, .59), (-.415, .59)):
        relative = (.62 + x, 1.17 + .017 - eye[1], -.23 + z - eye[2])
        depth = -sum(value * axis for value, axis in zip(relative, backward))
        vertical = sum(value * axis for value, axis in zip(relative, up))
        discard.append([width / 2 + focal * relative[0] / depth, height / 2 - focal * vertical / depth])
    return {'hand': hand, 'discard': discard, 'page_size': page_size,
            'page': f'1/{math.ceil(hand_count / page_size)}', 'compact': compact}


def require_cards_layout(layout: dict, public: dict, *, width: int, height: int,
                         density: float, allow_fixture: bool = False) -> dict:
    """Bind measured Android edges and actual mesh readbacks to one Cards state.

    Pixel polygons are calculated independently. Supplied Godot polygons are
    cross-checks only and never become the pixel sampling coordinates.
    """
    import hashlib
    import json
    import math

    def vector(value, count, label):
        if (not isinstance(value, (list, tuple)) or len(value) != count or
                any(isinstance(number, bool) or not isinstance(number, (int, float)) or
                    not math.isfinite(number) for number in value)):
            raise RuntimeError('Invalid Cards layout measurement: ' + label)
        return list(value)

    def close(actual, expected, label, tolerance=.01):
        actual = vector(actual, len(expected), label)
        if any(abs(a-b) > tolerance for a, b in zip(actual, expected)):
            raise RuntimeError('Cards layout measurement disagrees with ' + label)

    if not isinstance(layout, dict) or type(layout.get('schema')) is not int or layout['schema'] != 1:
        raise RuntimeError('Cards requires the current native layout observation schema')
    origin = layout.get('observation_source')
    if origin != 'android_window_insets' and not (allow_fixture and origin == 'fixture'):
        raise RuntimeError('Cards requires actual Android window-inset observations')
    if (layout.get('settled') is not True or layout.get('ui_visible') is not True or
            layout.get('selected_card_id') != '' or type(layout.get('pending')) is not int or
            layout['pending'] != 0 or type(layout.get('page')) is not int or layout['page'] != 0):
        raise RuntimeError('Cards layout is unsettled, pending, hidden, selected or on another page')
    for field, minimum in (('layout_sequence', 1), ('ticks_msec', 0), ('page_size', 1),
                           ('revision', 0), ('ack', 0), ('viewer', 0)):
        if type(layout.get(field)) is not int or layout[field] < minimum:
            raise RuntimeError('Invalid Cards layout sequence/state field: ' + field)
    for field in ('token', 'roundId'):
        if not isinstance(layout.get(field), str) or not layout[field] or layout[field] != public.get(field):
            raise RuntimeError('Cards layout belongs to another public ' + field)
    for field in ('revision', 'ack', 'viewer', 'paused', 'phase'):
        if layout.get(field) != public.get(field):
            raise RuntimeError('Cards layout has stale or changed public state: ' + field)
    if (layout.get('paused') is not False or layout.get('phase') != 'playing' or
            public.get('canDraw') is not True or public.get('viewer') != 0 or public.get('current') != 0):
        raise RuntimeError('Cards layout requires the active unpaused child turn')
    close([layout.get('density')], [density], 'actual display density', .00001)
    observation = layout.get('android_observation')
    if not isinstance(observation, dict):
        raise RuntimeError('Missing Cards Android View observations')
    decor = vector(observation.get('decor_size'), 2, 'decor_size')
    close(decor, [width, height], 'current screenshot size')
    window = vector(layout.get('window_px'), 2, 'window_px')
    if any(not 64 <= value <= 8192 or int(value) != value for value in window):
        raise RuntimeError('Cards native window has invalid pixel dimensions')
    close(layout.get('viewport_px'), window, 'unscaled native Cards viewport')
    view = vector(observation.get('view_size'), 2, 'view_size')
    render = vector(observation.get('render_rect'), 4, 'render_rect')
    x, y, render_width, render_height = render
    if not (0 <= x < width and 0 <= y < height and 0 < render_width <= width-x and
            0 < render_height <= height-y):
        raise RuntimeError('Cards RenderView extends beyond the current screenshot')
    close(view, [render_width, render_height], 'RenderView bounds')
    system = vector(observation.get('system_insets'), 4, 'system_insets')
    if (any(value < 0 for value in system) or system[0]+system[2] >= width or
            system[1]+system[3] >= height):
        raise RuntimeError('Cards system insets leave no usable content')
    overlap = [max(0, system[0]-x), max(0, system[1]-y),
               max(0, x+render_width-(width-system[2])),
               max(0, y+render_height-(height-system[3]))]
    if overlap[0]+overlap[2] >= render_width or overlap[1]+overlap[3] >= render_height:
        raise RuntimeError('Cards system insets cover its complete RenderView')
    close(observation.get('insets'), overlap, 'measured RenderView/system-bar intersection')
    scale_x, scale_y = window[0]/view[0], window[1]/view[1]
    inset = [overlap[0]*scale_x, overlap[1]*scale_y,
             overlap[2]*scale_x, overlap[3]*scale_y]
    ui = [inset[0], inset[1], window[0]-inset[0]-inset[2], window[1]-inset[1]-inset[3]]
    close(layout.get('ui_rect'), ui, 'derived safe UI rectangle')
    hand = public.get('hand')
    top = public.get('top')
    if (not isinstance(hand, list) or not hand or not isinstance(top, dict) or
            not isinstance(top.get('id'), str) or any(not isinstance(card, dict) or
            not isinstance(card.get('id'), str) for card in hand)):
        raise RuntimeError('Cards layout lacks actual public card identities')
    native = cards_projected_faces(int(window[0]), int(window[1]), density, len(hand), ui_rect=ui)
    if layout['page_size'] != native['page_size']:
        raise RuntimeError('Cards measured page size differs from its independent projection')
    observed_hand = layout.get('hand')
    observed_top = layout.get('discard')
    if (not isinstance(observed_hand, list) or len(observed_hand) != len(native['hand']) or
            not isinstance(observed_top, dict) or observed_top.get('id') != top['id']):
        raise RuntimeError('Cards mesh readbacks do not cover the current complete first page/discard')
    pairs = [(observed_top, top['id'], native['discard'])]
    pairs += [(observed, card['id'], calculated) for observed, card, calculated in
              zip(observed_hand, hand, native['hand'])]
    for observed, card_id, calculated in pairs:
        if not isinstance(observed, dict) or observed.get('id') != card_id:
            raise RuntimeError('Cards mesh identity differs from the current public hand')
        quad = observed.get('quad')
        if not isinstance(quad, list) or len(quad) != 4:
            raise RuntimeError('Cards requires four real projected corners per mesh')
        for actual, expected in zip(quad, calculated):
            close(actual, expected, 'independent projected mesh ' + card_id, .05)

    def to_screen(quad):
        return [[x+point[0]/scale_x, y+point[1]/scale_y] for point in quad]

    geometry = dict(native, hand=[to_screen(quad) for quad in native['hand']],
                    discard=to_screen(native['discard']))
    canonical = json.dumps(layout, sort_keys=True, separators=(',', ':'), ensure_ascii=False)
    return {'geometry': geometry, 'layout_sha256': hashlib.sha256(canonical.encode()).hexdigest(),
            'layout_sequence': layout['layout_sequence'], 'observation_source': origin,
            'safe_ui_rect': [x+ui[0]/scale_x, y+ui[1]/scale_y, ui[2]/scale_x, ui[3]/scale_y],
            'mesh_readback_tolerance_px': .05, 'scope': 'Independent projection agrees with actual native mesh readbacks'}


def require_cards_face_pixels(source, public: dict, *, density: float, observations: dict,
                             layout: dict | None = None, allow_fixture_layout: bool = False) -> dict:
    """Require visible artwork in actual projected front faces, not the whole image.

    This rejects blank/flat fronts. It does not identify card art, assess exact
    number legibility, or replace state/interaction evidence and human review.
    """
    import hashlib
    import io
    import math
    from pathlib import Path
    from PIL import Image, ImageChops, ImageDraw, ImageOps
    from native_surface_readiness import inspect_surface

    source = Path(source)
    raw = source.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    if observations.get('source_sha256') != digest:
        raise RuntimeError('Cards UI observations do not belong to this original screenshot')
    surface = inspect_surface(source, orientation='responsive')
    if not surface['acceptable_for_target_sampling']:
        raise RuntimeError('Cards pixel proof requires a complete current viewport')
    if (public.get('paused') is not False or public.get('canDraw') is not True or
            public.get('phase') != 'playing' or public.get('viewer') != 0 or public.get('current') != 0):
        raise RuntimeError('Cards pixel proof requires the active unpaused child turn')
    image = Image.open(io.BytesIO(raw)).convert('RGB')
    hand = public.get('hand')
    top = public.get('top')
    if (not isinstance(hand, list) or not hand or not isinstance(top, dict) or
            not isinstance(top.get('id'), str) or
            any(not isinstance(card, dict) or not isinstance(card.get('id'), str) for card in hand)):
        raise RuntimeError('Cards pixel proof requires public hand and discard identities')
    layout_binding = (require_cards_layout(layout, public, width=image.width, height=image.height,
                                           density=density, allow_fixture=allow_fixture_layout)
                      if layout is not None else None)
    geometry = (layout_binding['geometry'] if layout_binding is not None else
                cards_projected_faces(image.width, image.height, density, len(hand)))

    def caption(name, expected):
        item = observations.get(name, {})
        bounds = item.get('bounds')
        if (''.join(str(item.get('text', '')).split()) != expected or
                not isinstance(bounds, (list, tuple)) or len(bounds) != 4 or
                any(isinstance(value, bool) or not isinstance(value, (int, float)) or
                    not math.isfinite(value) for value in bounds)):
            raise RuntimeError('Cards pixel proof lacks current exact OCR caption: ' + name)
        x0, y0, x1, y1 = bounds
        if not 0 <= x0 < x1 <= image.width or not 0 <= y0 < y1 <= image.height:
            raise RuntimeError('Cards OCR caption lies outside its screenshot: ' + name)
        return bounds

    report = {'source': source.name, 'source_sha256': digest, 'pixels': list(image.size),
              'density': density, 'roundId': public.get('roundId'), 'revision': public.get('revision'),
              'page': geometry['page'], 'faces': [],
              'scope': 'Projected current front faces contain nonuniform colored artwork; no card identity or legibility claim'}
    if layout_binding is not None:
        report['layout_binding'] = {key: value for key, value in layout_binding.items() if key != 'geometry'}
    faces = [(card['id'], quad) for card, quad in zip(hand, geometry['hand'])]
    faces.append((top['id'], geometry['discard']))
    red, green, blue = image.split()
    high = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    low = ImageChops.darker(ImageChops.darker(red, green), blue)
    color = ImageChops.subtract(high, low).point(lambda value: 255 if value >= 24 else 0)
    grayscale = ImageOps.grayscale(image)
    for card_id, quad in faces:
        if any(not 0 <= x < image.width or not 0 <= y < image.height for x, y in quad):
            raise RuntimeError('Projected Cards front face leaves the current viewport')
        center = [sum(point[axis] for point in quad) / 4 for axis in (0, 1)]
        # Exclude bevels, gold legal-move outlines and edge antialiasing. This is
        # an inset of each actual mesh, not a fixed or globally sampled region.
        interior = [(center[0] + (x - center[0]) * .72, center[1] + (y - center[1]) * .72)
                    for x, y in quad]
        mask = Image.new('L', image.size)
        ImageDraw.Draw(mask).polygon(interior, fill=255)
        pixels = mask.histogram()[255]
        if pixels < 128:
            raise RuntimeError('Cards front face is too small for reliable pixel evidence')
        colored = ImageChops.multiply(color, mask).histogram()[255] / pixels
        histogram = grayscale.histogram(mask)

        def quantile(fraction):
            count = 0
            for value, amount in enumerate(histogram):
                count += amount
                if count >= pixels * fraction:
                    return value
            return 255

        spread = quantile(.95) - quantile(.05)
        face = {'card_id': card_id, 'quad': quad, 'interior_pixels': pixels,
                'colored_fraction': colored, 'luminance_p95_minus_p05': spread}
        report['faces'].append(face)
        if colored < .12 or spread < 24:
            raise RuntimeError('Cards front face is blank or lacks visible artwork: ' + str(face))
    pause = caption('pause', 'Pause')
    ui_x, ui_y, ui_width, ui_height = (layout_binding['safe_ui_rect'] if layout_binding is not None
                                     else [0, 0, image.width, image.height])
    if pause[0] < ui_x + ui_width * .65 or pause[3] > ui_y + min(ui_height * .2, 100 * density):
        raise RuntimeError('Cards Pause caption is not the current top navigation control')
    page = caption('page', geometry['page'])
    hand_bottom = max(point[1] for quad in geometry['hand'] for point in quad)
    if not hand_bottom < page[1] < page[3] < min(ui_y + ui_height, hand_bottom + 100 * density):
        raise RuntimeError('Cards page caption does not confirm the projected visible hand layout')

    return report


def require_learning_bridge_moves(log: str) -> dict:
    moves = re.findall(
        r'\[LearningWorld\] move kind=bridge_ten token=(\d+) target=(\d+) '
        r'placed=(\d+) complete=(true|false)', log)
    observed = [(int(token), int(target), int(placed), done == 'true')
                for token, target, placed, done in moves]
    if len(observed) != 5:
        raise RuntimeError(f'Expected five actual successful 8 + 5 moves, observed {len(observed)}')
    if ([value[2] for value in observed] != [1, 2, 3, 4, 5] or
            [value[1] for value in observed] != [8, 9, 10, 11, 12] or
            len({value[0] for value in observed}) != 5 or
            [value[3] for value in observed] != [False, False, False, False, True]):
        raise RuntimeError('Live learning objects did not fill ten and then the remaining three')
    return {'moved_objects': 5, 'ten_filled_after': 2, 'remainder': 3,
            'target_indices': [value[1] for value in observed], 'complete': True}
