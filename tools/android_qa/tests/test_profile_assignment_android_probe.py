"""Pure readers only; synthetic fixtures cannot produce an Android PASS."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET


PATH = Path(__file__).resolve().parents[3] / '.github/probes/profile_assignment_android_probe.py'
SPEC = importlib.util.spec_from_file_location('profile_assignment_android_probe_test', PATH)
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)
DAY = '2026-10-10'
A = 'stud-100001-0'
B = 'stud-100002-1'
REMOTE = '/data/app/~~synthetic/package-random/base.apk'


def legacy_values(correct=2):
    skill = {'skillId': PROBE.SKILL, 'subject': 'Mathematik', 'unit': 'Plus bis 10',
             'correct': correct, 'wrong': 0, 'hintCount': 0,
             'lastSeen': DAY + 'T12:00:00.000'}
    return {
        'lumo_progress_skills': json.dumps({PROBE.SKILL: skill}),
        'lumo_progress_daily': json.dumps({DAY: correct}),
        'lumo_progress_last': json.dumps({'Mathematik': 'Plus bis 10'}),
        'lumo_cosmos_items_v1': json.dumps([
            {'t': 1, 'x': .3 + index * .1, 'y': .4, 's': 1.0, 'r': 0.0}
            for index in range(correct)
        ]),
        'lumo_cosmos_meta_v1': json.dumps({'c': correct, 's': 1, 'd': DAY}),
    }


def assigned():
    originals = legacy_values()
    prefs = {'flutter.' + key: value for key, value in originals.items()}
    prefs[PROBE.CLAIM] = json.dumps({'version': 1, 'owner': A, 'state': 'committed'})
    prefs[PROBE.SNAPSHOT] = json.dumps({'owner': A, 'data': originals})
    return prefs


def node(text='', bounds='[0,0][0,0]', clickable=False, **extra):
    return ET.Element('node', {
        'package': PROBE.PACKAGE, 'text': text, 'bounds': bounds,
        'clickable': str(clickable).lower(), 'enabled': 'true', **extra,
    })


def question():
    root = node(bounds='[0,0][1080,2400]')
    root.append(node('5', '[900,20][980,90]', clickable=True))  # Actual-style wallet position.
    root.append(node('Aufgabe 1 / 30', '[60,110][340,150]'))
    root.append(node('2 + 3 = ?', '[100,180][600,250]'))
    for index, answer in enumerate((2, 5, 6, 8)):
        x = 60 + index * 230
        button = node(bounds=f'[{x},400][{x+200},520]', clickable=True)
        button.append(node(str(answer), f'[{x+60},430][{x+140},490]'))
        root.append(button)
    return root


class DurableLearningReaderTests(unittest.TestCase):
    def test_exact_android_school_schema_uses_cls_and_real_ids(self):
        school = {
            'classes': [{'id': 'class-1-0', 'name': '1a', 'grade': 1, 'teachers': ['teacher-local']}],
            'students': [{'id': A, 'name': 'Alina', 'cls': 'class-1-0', 'groups': []},
                         {'id': B, 'name': 'Boris', 'cls': 'class-1-0', 'groups': []}],
            'groups': [], 'assignments': [],
        }
        self.assertEqual(PROBE.school_children({PROBE.SCHOOL: json.dumps(school)}),
                         {'Alina': A, 'Boris': B})
        school['students'][1]['id'] = A
        with self.assertRaisesRegex(RuntimeError, 'same stored ID'):
            PROBE.school_children({PROBE.SCHOOL: json.dumps(school)})

    def test_global_and_assigned_snapshot_never_leak_into_b(self):
        prefs = assigned()
        PROBE.require_claim(prefs, A, legacy_values())
        PROBE.require_progress(prefs, A, 2, DAY)
        PROBE.require_progress(prefs, B, 0, DAY)
        with self.assertRaisesRegex(RuntimeError, 'daily'):
            PROBE.require_progress(prefs, B, 2, DAY)

    def test_scoped_b_write_does_not_modify_a_or_originals(self):
        prefs = assigned()
        a_before = PROBE.learning_state(prefs, A)
        for key, value in legacy_values(1).items():
            prefs[PROBE.namespace_key(key, B)] = value
        PROBE.require_progress(prefs, B, 1, DAY, require_scoped=True)
        PROBE.require_claim(prefs, A, legacy_values())
        self.assertEqual(PROBE.learning_state(prefs, A), a_before)

    def test_snapshot_alone_is_not_a_durable_materialized_namespace(self):
        with self.assertRaisesRegex(RuntimeError, 'actual Android namespace'):
            PROBE.require_progress(assigned(), A, 2, DAY, require_scoped=True)

    def test_wrong_owner_prepared_claim_and_changed_originals_fail(self):
        for change in ('owner', 'prepared', 'original'):
            prefs = assigned()
            if change == 'owner':
                prefs[PROBE.CLAIM] = json.dumps({'version': 1, 'owner': B, 'state': 'committed'})
            elif change == 'prepared':
                prefs[PROBE.CLAIM] = json.dumps({'version': 1, 'owner': A, 'state': 'prepared'})
            else:
                prefs['flutter.lumo_progress_daily'] = '{"2026-10-10":3}'
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                PROBE.require_claim(prefs, A, legacy_values())

    def test_boolean_counter_cannot_masquerade_as_one_answer(self):
        prefs = {'flutter.' + key: value for key, value in legacy_values(1).items()}
        prefs['flutter.lumo_progress_daily'] = json.dumps({DAY: True})
        with self.assertRaisesRegex(RuntimeError, 'daily'):
            PROBE.require_progress(prefs, None, 1, DAY)

    def test_wrong_hint_or_answer_count_fails(self):
        for field, value in (('correct', 3), ('wrong', 1), ('hintCount', 1)):
            values = legacy_values()
            skills = json.loads(values['lumo_progress_skills'])
            skills[PROBE.SKILL][field] = value
            prefs = {'flutter.' + key: val for key, val in values.items()}
            prefs['flutter.lumo_progress_skills'] = json.dumps(skills)
            with self.subTest(field=field), self.assertRaisesRegex(RuntimeError, 'durable Plus'):
                PROBE.require_progress(prefs, None, 2, DAY)

    def test_one_b_answer_cannot_accept_two_a_trees_or_an_invalid_world_object(self):
        tree = {'t': 1, 'x': .3, 'y': .4, 's': 1.0, 'r': 0.0}
        for objects in ([tree, dict(tree, x=.8)], [], [dict(tree, t=0)],
                        [dict(tree, x=True)], [dict(tree, s=-1)]):
            prefs = {'flutter.' + key: value for key, value in legacy_values(1).items()}
            prefs['flutter.lumo_cosmos_items_v1'] = json.dumps(objects)
            with self.subTest(objects=objects), self.assertRaises(RuntimeError):
                PROBE.require_progress(prefs, None, 1, DAY)

    def test_visit_metadata_may_change_but_learning_and_world_objects_may_not(self):
        first = PROBE.learning_state(assigned(), A)
        visit = copy.deepcopy(first)
        visit['cosmos']['meta'].update(s=2, d='2026-10-11')
        self.assertEqual(PROBE.learning_signature(first), PROBE.learning_signature(visit))
        visit['cosmos']['items'].append({'t': 1})
        self.assertNotEqual(PROBE.learning_signature(first), PROBE.learning_signature(visit))

    def test_duplicate_or_nonfinite_json_and_preferences_fail(self):
        for raw in ('{"owner":"A","owner":"B"}', '{"correct":NaN}'):
            with self.subTest(raw=raw), self.assertRaises(RuntimeError):
                PROBE.strict_json(raw)
        with self.assertRaisesRegex(RuntimeError, 'duplicate'):
            PROBE.parse_preferences('<map><string name="x">A</string><string name="x">B</string></map>')
        with self.assertRaisesRegex(RuntimeError, 'Android map'):
            PROBE.parse_preferences('<fake/>')


class InstalledBytesReaderTests(unittest.TestCase):
    def test_hash_size_and_exact_remote_path_are_bound_together(self):
        proof = PROBE.installed_bytes('package:' + REMOTE, 'a' * 64 + '  ' + REMOTE,
                                      '12345', 'a' * 64, 12345)
        self.assertEqual(proof['bytes'], 12345)
        self.assertTrue(proof['matches_input'])
        self.assertIn('not exported', proof['scope'])

    def test_bad_hash_size_duplicate_paths_and_unrelated_filename_fail(self):
        for paths, hashed, size in (
            ('package:' + REMOTE, 'b' * 64 + '  ' + REMOTE, '12345'),
            ('package:' + REMOTE, 'a' * 64 + '  /other/base.apk', '12345'),
            ('package:' + REMOTE, 'a' * 64 + '  ' + REMOTE, '12344'),
            ('package:' + REMOTE, 'a' * 64 + '  ' + REMOTE, '12345\n12345'),
            ('package:' + REMOTE + '\npackage:' + REMOTE, 'a' * 64 + '  ' + REMOTE, '12345'),
        ):
            with self.subTest(paths=paths, hashed=hashed, size=size), self.assertRaises(RuntimeError):
                PROBE.installed_bytes(paths, hashed, size, 'a' * 64, 12345)


class VisibleAnswerReaderTests(unittest.TestCase):
    def test_question_uses_real_clickable_ancestor_and_excludes_wallet_number(self):
        state = PROBE.plus_question(list(question().iter('node')), 1080, 2400)
        self.assertEqual(state['prompt'], '2 + 3 = ?')
        self.assertEqual(state['answer'], 5)
        self.assertEqual(state['task_index'], 1)
        self.assertEqual(state['target_bounds'], [290, 400, 490, 520])
        self.assertEqual(set(state['options']), {'2', '5', '6', '8'})

    def test_disabled_missing_and_offscreen_answer_cannot_authorize_touch(self):
        for change in ('disabled', 'offscreen', 'missing-click', 'missing-enabled'):
            root = question()
            button = root[4]  # Correct answer's actual parent.
            if change == 'disabled':
                button.set('enabled', 'false')
            elif change == 'offscreen':
                button.set('bounds', '[290,2380][490,2500]')
            elif change == 'missing-enabled':
                del button.attrib['enabled']
            else:
                button.set('clickable', 'false')
            with self.subTest(change=change):
                self.assertIsNone(PROBE.plus_question(list(root.iter('node')), 1080, 2400))

    def test_clickable_panel_with_multiple_numbers_is_not_an_answer(self):
        root = question()
        root.set('clickable', 'true')
        root[4].set('clickable', 'false')
        self.assertIsNone(PROBE.plus_question(list(root.iter('node')), 1080, 2400))

    def test_ambiguous_task_and_non_addition_range_are_rejected(self):
        root = question()
        root.append(node('1 + 2 = ?', '[100,270][600,340]'))
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous live Plus'):
            PROBE.plus_question(list(root.iter('node')), 1080, 2400)
        root = question()
        root[2].set('text', '8 + 9 = ?')
        with self.assertRaisesRegex(RuntimeError, 'outside Plus'):
            PROBE.plus_question(list(root.iter('node')), 1080, 2400)

    def test_missing_task_index_or_three_options_is_not_sufficient(self):
        for index in (1, 6):
            root = question()
            root.remove(root[index])
            self.assertIsNone(PROBE.plus_question(list(root.iter('node')), 1080, 2400))

    def test_confirmation_capture_has_no_test_scroll_and_rejects_clipping(self):
        for bottom, should_pass in ((1100, True), (2300, False)):
            probe = PROBE.AndroidProbe.__new__(PROBE.AndroidProbe)
            probe.width, probe.height = 1080, 2400
            probe.result = {}
            root = node(bounds='[0,150][1080,2300]', scrollable='true')
            root.append(node('Lernstand zugeordnet', '[80,700][1000,780]'))
            root.append(node(PROBE.SUCCESS_TEXT, f'[80,800][1000,{bottom}]'))
            reads = []
            probe.see = lambda *args, **kwargs: reads.append(kwargs)
            probe.nodes = lambda *_: (list(root.iter('node')), {'file': 'synthetic.xml'})
            probe.checkpoint = lambda *args, **kwargs: {}
            probe.preserved = lambda *_: None
            probe.scroll = lambda *_: self.fail('Success checkpoint must not scroll')
            if should_pass:
                probe.success_without_scroll()
                self.assertTrue(probe.result['assignment_success_visibility']
                                ['no_test_scroll_after_confirmation'])
            else:
                with self.assertRaisesRegex(RuntimeError, 'inside the live scroll viewport'):
                    probe.success_without_scroll()
            self.assertTrue(all(row == {'scroll': False} for row in reads))


class ProfileEditFocusReaderTests(unittest.TestCase):
    def card(self, **changes):
        # Exact merged label/bounds from baseline-school-edit-ui-0045.xml.
        attributes = {
            'content-desc': 'Level 1\n2\nEntdecker:in\nKlasse 1\n10 / 400 XP\n'
                            'Profil\nbearbeiten\nLernprofi: 2 von 10\nSpieler:in: 0 von 1\n'
                            'Tüftler:in: 0 von 5\nSternensammler: 2 von 10\nHeld:in: 1 von 3',
            'focusable': 'true', 'focused': 'false',
        }
        attributes.update(changes)
        return node(bounds='[0,831][1080,1678]', clickable=True, **attributes)

    def test_actual_merged_card_is_ready_without_authorizing_activation(self):
        card = self.card()
        ready = PROBE.profile_edit_target([card], 1080, 2400)
        self.assertEqual(ready['bounds'], [0, 831, 1080, 1678])
        self.assertEqual(ready['label'], 'Profil\nbearbeiten')
        self.assertFalse(ready['focused'])
        self.assertIsNone(PROBE.profile_edit_target([card], 1080, 2400, require_focused=True))
        self.assertEqual(PROBE.matching([card], 'Profil\nbearbeiten', 1080, 2400), [])

    def test_only_explicit_input_focus_authorizes_enter(self):
        card = self.card(selected='true')
        for focused in (None, 'false', 'true'):
            if focused is None:
                card.attrib.pop('focused', None)
            else:
                card.set('focused', focused)
            target = PROBE.profile_edit_target([card], 1080, 2400, require_focused=True)
            with self.subTest(focused=focused):
                self.assertEqual(target is not None, focused == 'true')

    def test_disabled_missing_foreign_clipped_and_nonclickable_cards_are_rejected(self):
        for attribute, value in (('enabled', 'false'), ('enabled', None),
                                 ('clickable', 'false'), ('clickable', None),
                                 ('package', 'other.app'), ('bounds', '[0,-10][1080,800]'),
                                 ('bounds', '[0,2200][1080,2500]'),
                                 ('visible-to-user', 'false')):
            card = self.card(focused='true')
            if value is None:
                del card.attrib[attribute]
            else:
                card.set(attribute, value)
            with self.subTest(attribute=attribute, value=value):
                self.assertIsNone(PROBE.profile_edit_target([card], 1080, 2400))
                self.assertIsNone(PROBE.profile_edit_target(
                    [card], 1080, 2400, require_focused=True))

    def test_label_requires_exact_adjacent_lines_in_one_attribute(self):
        for text in ('Profil bearbeiten', 'Profil\nanderes\nbearbeiten',
                     'bearbeiten\nProfil', 'Profilbild\nbearbeiten', 'Profil\nBearbeiten'):
            card = self.card(**{'content-desc': text})
            with self.subTest(text=text):
                self.assertIsNone(PROBE.profile_edit_target([card], 1080, 2400))
        card = self.card(**{'content-desc': 'bearbeiten'})
        card.set('text', 'Profil')
        self.assertIsNone(PROBE.profile_edit_target([card], 1080, 2400))

    def test_multiple_edit_targets_are_ambiguous_even_when_only_one_is_focused(self):
        cards = [self.card(focused='true'), self.card()]
        for focused in (False, True):
            with self.subTest(require_focused=focused), self.assertRaisesRegex(
                    RuntimeError, 'Ambiguous profile edit focus target'):
                PROBE.profile_edit_target(cards, 1080, 2400, require_focused=focused)

    def test_focus_on_navigation_or_foreign_edit_does_not_authorize_the_card(self):
        card = self.card()
        navigation = node('Profil', '[857,2148][1068,2316]', clickable=True, focused='true')
        foreign = self.card(focused='true')
        foreign.set('package', 'other.app')
        self.assertIsNone(PROBE.profile_edit_target(
            [card, navigation, foreign], 1080, 2400, require_focused=True))


class FailClosedEntryTests(unittest.TestCase):
    def test_existing_evidence_is_not_overwritten_by_a_failed_second_invocation(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(
                PROBE, 'AndroidProbe', side_effect=AssertionError('Android must not be initialized')):
            path = Path(directory) / 'result.json'
            original = '{"synthetic_existing_evidence":"preserve exactly"}\n'
            path.write_text(original)
            code = PROBE.main(['--baseline', '/missing/baseline.apk',
                               '--candidate', '/missing/candidate.apk', '--out', directory])
            self.assertEqual(code, 1)
            self.assertEqual(path.read_text(), original)

    def test_missing_candidate_binding_fails_before_importing_android_or_claiming_pass(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(
                os.environ, {'LUMO_CANDIDATE_SHA256': 'PENDING'}), patch.object(
                PROBE, 'AndroidProbe', side_effect=AssertionError('Android must not be initialized')):
            code = PROBE.main(['--baseline', '/missing/baseline.apk',
                               '--candidate', '/missing/candidate.apk', '--out', directory])
            report = json.loads((Path(directory) / 'result.json').read_text())
            self.assertEqual(code, 1)
            self.assertEqual(report['status'], 'FAIL')
            self.assertEqual(report['answers'], [])
            self.assertIsNone(report['qa_commit'])
            self.assertIn('LUMO_CANDIDATE_SHA256', report['error'])


if __name__ == '__main__':
    unittest.main()
