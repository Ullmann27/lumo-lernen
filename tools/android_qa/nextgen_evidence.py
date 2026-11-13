"""Fail-closed checks of real Cards IPC, persisted rounds and learning moves.

These functions inspect observations. They never create Android app state.
"""
from __future__ import annotations

import re


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
    matching = [block for block in blocks if re.match(
        r'^[ \t]*\* ServiceRecord\{[^\n}]*\b' + component + r'\}', block)]
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
