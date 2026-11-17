"""Evidence must reject stale acknowledgements, card loss and fabricated moves."""
import copy
import hashlib
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from nextgen_evidence import (require_cards_authority_binding, require_cards_draw, require_learning_bridge_moves,
                             require_learning_voice,
                             require_public_saved_match, require_saved_round)


class NextgenEvidenceTests(unittest.TestCase):
    def actual_authority_dump(self):
        path = Path(__file__).with_name('fixtures') / 'android_2018_cards_authority_recorded.txt'
        raw = path.read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),
                         '196b4bd103984b65f63adf10cb1171405163dad2a07df27264ee71e079101aa5')
        return raw.decode()

    def test_actual_service_header_retains_real_process_and_binding_evidence(self):
        # Original workflow43395154888/job131785002542. Its enclosing tour failed;
        # parsing this recorded OS dump is not a new Android runtime acceptance.
        package = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
        report = require_cards_authority_binding(self.actual_authority_dump(), package)
        self.assertEqual(report, {'main_process_pid': 5599, 'native_process_pid': 7348,
                                 'service': 'dev.ullmann.lumo.lumo_lernen.CardsAuthorityService',
                                 'bound': True})

    def test_actual_service_unknown_suffix_foreign_component_or_duplicate_fails(self):
        package = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
        dump = self.actual_authority_dump()
        for bad in (
                dump.replace(' c:' + package + '}', ' c:other.app}'),
                dump.replace(' c:' + package + '}', ' extra:' + package + '}'),
                dump.replace(' c:' + package + '}', ' c:' + package + ' unexpected}'),
                dump.replace(' u0 ' + package + '/', ' u0 other.' + package + '/', 1),
                dump.replace(' u0 ' + package + '/', ' u0 other.app/OtherService\n' + package + '/', 1),
                dump.replace(' c:' + package + '}', '} trailing-unobserved-data'),
                dump + dump):
            with self.subTest(header=bad.splitlines()[2]), self.assertRaises(RuntimeError):
                require_cards_authority_binding(bad, package)

    def test_actual_record_missing_binding_or_wrong_process_still_fails(self):
        package = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
        dump = self.actual_authority_dump()
        for bad in (dump.replace('requested=true', 'requested=false'),
                    dump.replace('received=true', 'received=false'),
                    dump.replace('hasBound=true', 'hasBound=false'),
                    dump.replace('7348:', '5599:'),
                    dump.replace('7348:' + package + ':lumo_game/', '7348:other.app/'),
                    dump.replace('5599:' + package + '/', '5599:' + package + ':lumo_game/'),
                    dump.replace(' u0 CR ', ' u0 ')):
            with self.subTest(dump=bad[-160:]), self.assertRaises(RuntimeError):
                require_cards_authority_binding(bad, package)

    def test_another_service_block_cannot_supply_missing_cards_binding_facts(self):
        package = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
        dump = self.actual_authority_dump()
        foreign = dump.replace('CardsAuthorityService', 'OtherService')
        for missing in ('app=ProcessRecord', '* Client AppBindRecord',
                        'requested=true received=true hasBound=true'):
            incomplete = '\n'.join(line for line in dump.splitlines() if missing not in line) + '\n'
            for combined in (incomplete + foreign, foreign + incomplete):
                with self.subTest(missing=missing), self.assertRaises(RuntimeError):
                    require_cards_authority_binding(combined, package)

    def test_native_speech_requires_local_profile_and_same_process_completion(self):
        start = 'I/LumoLearningSpeech( 1234): started id=4 profile=lumo-free-supertonic-de-v1\n'
        done = 'I/LumoLearningSpeech( 1234): completed id=4\n'
        evidence = require_learning_voice(start + done)
        self.assertEqual(evidence['completed_utterance_ids'], [4])
        self.assertEqual(evidence['native_process_pid'], 1234)
        self.assertFalse(evidence['audible_quality_verified'])
        self.assertFalse(evidence['lip_sync_verified'])
        for value in ('', start, done, done + start,
                      start + done.replace('1234', '1235'),
                      start + done.replace('id=4', 'id=5'),
                      start.replace('lumo-free-supertonic-de-v1', 'different-voice') + done,
                      (start + done).replace('id=4', 'id=0')):
            with self.subTest(log=value), self.assertRaises(RuntimeError):
                require_learning_voice(value)

    def test_spoken_result_must_start_and_finish_after_the_actual_last_move(self):
        event = ('I/LumoLearningSpeech(1234): started id=8 profile=lumo-free-supertonic-de-v1\n'
                 'I/LumoLearningSpeech(1234): completed id=8\n')
        move = 'I/godot(1234): [LearningWorld] move kind=bridge_ten token=4 target=12 placed=5 complete=true\n'
        self.assertEqual(require_learning_voice(move + event, after_final_move=True)
                         ['completed_utterance_ids'], [8])
        for value in (event, event + move, move.replace('complete=true', 'complete=false') + event):
            with self.subTest(log=value), self.assertRaises(RuntimeError):
                require_learning_voice(value, after_final_move=True)

    def test_android_binding_requires_the_distinct_real_main_and_native_processes(self):
        package = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
        component = package + '/dev.ullmann.lumo.lumo_lernen.CardsAuthorityService'
        # Structural fixture follows AOSP ServiceRecord/IntentBindRecord output.
        # It tests evidence parsing; it never represents an actual device run.
        dump = f'''ACTIVITY MANAGER SERVICES (dumpsys activity services)
  * ServiceRecord{{a1 u0 {component}}}
    app=ProcessRecord{{a2 1234:{package}/u0a123}}
    Bindings:
    * IntentBindRecord{{a3 CREATE}}:
      requested=true received=true hasBound=true doRebind=false
      * Client AppBindRecord{{a4 ProcessRecord{{a5 1235:{package}:lumo_game/u0a123}}}}
        Per-process Connections:
          ConnectionRecord{{a6 u0 CR {component}:@a7}}
'''
        report = require_cards_authority_binding(dump, package)
        self.assertEqual((report['main_process_pid'], report['native_process_pid']), (1234, 1235))
        self.assertTrue(report['bound'])
        for bad in ('', dump.replace('received=true', 'received=false'),
                    dump.replace('hasBound=true', 'hasBound=false'),
                    dump.replace('1235:', '1234:'), dump.replace('u0 CR ', 'u0 '),
                    dump.replace('1234:' + package + '/', '1234:' + package + ':lumo_game/'),
                    dump.replace('1235:' + package + ':lumo_game/', '1235:other.app/'),
                    dump.replace('CardsAuthorityService', 'OtherService')):
            with self.subTest(dump=bad[-160:]), self.assertRaises(RuntimeError):
                require_cards_authority_binding(bad, package)

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
