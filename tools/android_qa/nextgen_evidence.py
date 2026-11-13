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


def cards_projected_faces(width: int, height: int, density: float, hand_count: int) -> dict:
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
    if (width, height, density) not in supported:
        raise RuntimeError('Cards pixel proof has no verified production geometry for this layout')
    compact = height / density < 520 and width > height
    page_size = 7 if width / density > 850 else 5 if width / density > 550 else 3
    if hand_count < page_size:
        raise RuntimeError('Cards pixel proof requires the verified full first hand page')
    visible = min(page_size, hand_count)
    card_height = 96 * density if compact else min(max(height * .28, 96 * density), 180 * density)
    card_width = card_height * .83 / 1.18
    spacing = min(card_width * 1.08, (width - 32 * density - card_width) / max(1, visible - 1))
    focal = height / (2 * math.tan(math.radians(23)))
    # PlaneMesh is 0.017 units in front of the body; retain its true projection
    # instead of using the nominal screen-space layout rectangle.
    scale = 4 * card_height / focal / 1.18
    magnification = 4 / (4 - .017 * scale)
    center_y = height / 2 + (height / 2 - (76 if compact else 140) * density - card_height / 2) * magnification
    hand = []
    for index in range(visible):
        center_x = width / 2 + (index - (visible - 1) / 2) * spacing * magnification
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


def require_cards_face_pixels(source, public: dict, *, density: float, observations: dict) -> dict:
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
    geometry = cards_projected_faces(image.width, image.height, density, len(hand))

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
    if pause[0] < image.width * .65 or pause[3] > min(image.height * .2, 100 * density):
        raise RuntimeError('Cards Pause caption is not the current top navigation control')
    page = caption('page', geometry['page'])
    hand_bottom = max(point[1] for quad in geometry['hand'] for point in quad)
    if not hand_bottom < page[1] < page[3] < min(image.height, hand_bottom + 100 * density):
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
