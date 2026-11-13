"""Evidence must reject stale acknowledgements, card loss and fabricated moves."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from nextgen_evidence import (require_cards_draw, require_learning_bridge_moves,
                             require_public_saved_match, require_saved_round)


class NextgenEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.round = 'cards-' + 'a' * 32
        self.saved = {'id': self.round, 'owner': 'b' * 64, 'version': 1, 'deckVersion': 1,
                      'current': 0, 'phase': 'playing',
                      'players': [{'hand': [f'c{i}' for i in range(8)], 'stars': 0},
                                  {'hand': [f'c{i}' for i in range(8, 15)], 'stars': 0}],
                      'discard': ['c15'], 'draw': [f'c{i}' for i in range(16, 112)]}
        self.after = {'protocol': 1, 'token': 'c' * 32, 'roundId': self.round,
                      'revision': 4, 'ack': 1, 'viewer': 0, 'current': 0,
                      'paused': False, 'phase': 'playing', 'canDraw': True,
                      'hand': [{'id': x} for x in self.saved['players'][0]['hand']],
                      'players': [{'count': 8, 'stars': 0}, {'count': 7, 'stars': 0}],
                      'top': {'id': 'c15'}, 'drawCount': 96}
        self.before = copy.deepcopy(self.after)
        self.before.update(revision=2, ack=0, drawCount=97)
        self.before['hand'].pop()
        self.before['players'][0]['count'] = 7
        self.request = {'action': 'draw', 'token': 'c' * 32, 'sequence': 1, 'revision': 2}

    def test_real_ack_requires_same_round_and_actual_persisted_hand_growth(self):
        report = require_cards_draw(self.before, self.request, self.after, self.saved, owner='b' * 64)
        self.assertEqual(report['cards_conserved'], 112)
        self.assertEqual(report['child_cards_added'], 1)

    def test_replaced_round_replayed_action_and_unacknowledged_draw_fail(self):
        for field, value in (('roundId', 'cards-' + 'd' * 32), ('token', 'd' * 32),
                             ('ack', 0), ('revision', 2), ('drawCount', 97)):
            after = copy.deepcopy(self.after)
            after[field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                require_cards_draw(self.before, self.request, after, self.saved, owner='b' * 64)
        for field, value in (('action', 'pause'), ('revision', 1), ('sequence', 0),
                             ('sequence', True), ('token', 'd' * 32)):
            request = dict(self.request, **{field: value})
            with self.subTest(request=field), self.assertRaises(RuntimeError):
                require_cards_draw(self.before, request, self.after, self.saved, owner='b' * 64)
        with self.assertRaisesRegex(RuntimeError, 'child owner'):
            require_cards_draw(self.before, self.request, self.after, self.saved, owner='d' * 64)

    def test_missing_duplicate_and_cross_child_cards_fail(self):
        for mutation in ('missing', 'duplicate', 'owner', 'round'):
            saved = copy.deepcopy(self.saved)
            if mutation == 'missing': saved['draw'].pop()
            if mutation == 'duplicate': saved['draw'][0] = 'c0'
            if mutation == 'owner': saved['owner'] = 'child-name'
            if mutation == 'round': saved['id'] = 'cards-' + 'd' * 32
            with self.subTest(mutation=mutation), self.assertRaises(RuntimeError):
                require_saved_round(saved, self.round)

    def test_ack_with_unchanged_hand_or_private_answer_is_not_evidence(self):
        before = copy.deepcopy(self.before)
        before['hand'] = copy.deepcopy(self.after['hand'])
        with self.assertRaises(RuntimeError):
            require_cards_draw(before, self.request, self.after, self.saved, owner='b' * 64)
        for private in ({'drawPile': ['hidden']}, {'question': {'correct': 1}}):
            with self.subTest(private=private), self.assertRaises(RuntimeError):
                require_public_saved_match(dict(self.after, **private), self.saved)

    def test_eight_plus_five_requires_five_unique_successful_actual_moves(self):
        log = '\n'.join(
            f'I godot: [LearningWorld] move kind=bridge_ten token={i} target={i + 8} '
            f'placed={i + 1} complete={str(i == 4).lower()}' for i in range(5))
        self.assertEqual(require_learning_bridge_moves(log)['remainder'], 3)
        for bad in ('', log.replace('target=9', 'target=10'),
                    log.replace('token=1', 'token=0'), log + '\n' + log,
                    log.replace('complete=true', 'complete=false')):
            with self.subTest(bad=bad[:60]), self.assertRaises(RuntimeError):
                require_learning_bridge_moves(bad)


if __name__ == '__main__':
    unittest.main()
