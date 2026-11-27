"""Auswertelogik der Probe „Lumo Insight“. Die XML-Eingaben sind SYNTHETISCH.

Sie stammen aus test/parents/lumo_insight_semantics_test.dart (Flutter-Semantik in
pixel_5-Maßen, mit A6_HIERARCHY exportiert) und sind KEIN Android-Nachweis. Die Probe im
Emulator ist damit nicht getestet; geprüft wird nur, dass sie richtig liest und vergleicht.
"""
import importlib.util
import json
from pathlib import Path
import re
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools' / 'android_qa'))
import parent_insight_reader as reader  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / 'fixtures' / 'parent_insight_synthetic'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'


def hierarchy(name):
    return list(ET.parse(FIXTURES / f'{name}.xml').getroot().iter('node'))


def node(desc, *, rid='', enabled='true', package=PACKAGE):
    return ET.Element('node', {'text': '', 'content-desc': desc, 'resource-id': rid,
                               'package': package, 'enabled': enabled,
                               'bounds': '[0,0][100,100]'})


def screen(answers='Antworten: 36, 33 ohne Hilfe', streak='Lerntage in Folge: 1, zuletzt heute',
           strengths='Stärken: 1, ab 85 % ohne Hilfe', needs='Förderbedarf: 3, unter 85 % ohne Hilfe',
           basis='Grundlage wie „Auf einen Blick“: 36 Antworten im Aufgabenprotokoll dieses '
                 'Profils, davon 33 ohne Hilfe.',
           guidance='Grundlage: 36 Antworten auf diesem Gerät, davon 33 ohne Hilfe.'):
    rows = [node(answers, rid='insight-stat-answers'), node(streak, rid='insight-stat-streak'),
            node(strengths, rid='insight-stat-strengths'), node(needs, rid='insight-stat-needs')]
    if basis:
        rows.append(node(basis, rid='insight-stats-basis'))
    if guidance:
        rows.append(node('Auf einen Blick\n' + guidance))
    return rows


def snap(rows):
    return reader.snapshot(reader.read_tiles(rows, PACKAGE), reader.read_stats_basis(rows, PACKAGE),
                           reader.read_guidance_basis(rows, PACKAGE))


class SyntheticHierarchyTest(unittest.TestCase):
    def test_36_answers_match_auf_einen_blick(self):
        rows = hierarchy('insight_36_antworten')
        tiles = reader.read_tiles(rows, PACKAGE)
        self.assertTrue(reader.is_settled(tiles))
        self.assertEqual({k: v['source'] for k, v in tiles.items()},
                         {k: 'resource-id' for k in reader.TILES})
        values = snap(rows)
        self.assertEqual(values['answers'], 36)
        self.assertEqual(values['answers_hint'], {'kind': 'independent', 'independent': 33})
        self.assertEqual((values['streak'], values['streak_hint']), (0, 'zuletzt gestern'))
        self.assertEqual((values['strengths'], values['needs']), ('1', '3'))
        self.assertEqual(values['guidance']['total'], 36)
        self.assertEqual(values['guidance']['independent'], 33)
        self.assertEqual(values['stats_basis']['state'], 'logged')
        self.assertEqual(reader.consistency_failures(values), [])

    def test_empty_profile_is_a_true_zero(self):
        values = snap(hierarchy('insight_leer'))
        self.assertEqual(values['answers'], 0)
        self.assertEqual(values['answers_hint'], {'kind': 'none'})
        self.assertEqual(values['strengths'], '–')
        self.assertEqual(values['guidance']['state'], 'empty')
        self.assertEqual(values['stats_basis']['state'], 'empty')
        self.assertEqual(reader.consistency_failures(values), [])

    def test_loading_is_never_read_as_zero(self):
        rows = hierarchy('insight_laedt')
        tiles = reader.read_tiles(rows, PACKAGE)
        self.assertFalse(reader.is_settled(tiles))
        self.assertEqual({v['value'] for v in tiles.values()}, {'…'})
        values = snap(rows)
        self.assertIsNone(values['answers'])
        self.assertEqual(values['stats_basis']['state'], 'loading')
        failures = reader.consistency_failures(values)
        self.assertTrue(any('laden noch' in f for f in failures), failures)

    def test_fixture_is_marked_synthetic(self):
        for path in FIXTURES.glob('*.xml'):
            self.assertIn('SYNTHETISCH', path.read_text(encoding='utf-8')[:400], path.name)


class ConsistencyTest(unittest.TestCase):
    def test_heinz_finding_zero_tiles_with_36_answers_fails(self):
        failures = reader.consistency_failures(snap(screen(
            answers='Antworten: 0, noch keine', streak='Lerntage in Folge: 0, noch keine',
            strengths='Stärken: –, noch offen', needs='Förderbedarf: –, noch offen')))
        self.assertTrue(any('zeigt 0' in f for f in failures), failures)

    def test_independent_hint_must_match(self):
        failures = reader.consistency_failures(snap(screen(answers='Antworten: 36, 30 ohne Hilfe')))
        self.assertTrue(any('30 ohne Hilfe' in f for f in failures), failures)

    def test_older_counters_are_added_once(self):
        rows = screen(answers='Antworten: 15, inkl. 5 ältere',
                      basis='Grundlage wie „Auf einen Blick“: 10 Antworten im Aufgabenprotokoll '
                            'dieses Profils, davon 8 ohne Hilfe. Dazu 5 ältere Antworten ohne '
                            'Datum aus der Zeit vor dem Protokoll: zählen bei „Antworten“ mit, '
                            'nicht bei Stärken und Förderbedarf.',
                      guidance='Grundlage: 10 Antworten auf diesem Gerät, davon 8 ohne Hilfe.')
        self.assertEqual(reader.consistency_failures(snap(rows)), [])
        wrong = screen(answers='Antworten: 20, inkl. 5 ältere',
                       guidance='Grundlage: 10 Antworten auf diesem Gerät, davon 8 ohne Hilfe.')
        self.assertTrue(reader.consistency_failures(snap(wrong)))

    def test_only_older_counters(self):
        rows = screen(answers='Antworten: 5, ältere, ohne Datum',
                      strengths='Stärken: –, noch offen', needs='Förderbedarf: –, noch offen',
                      basis='Noch keine Antworten im Aufgabenprotokoll dieses Profils. 5 ältere '
                            'Antworten ohne Datum aus der Zeit vor dem Protokoll: zählen bei '
                            '„Antworten“ mit, nicht bei Stärken und Förderbedarf.',
                      guidance='Noch keine protokollierten Antworten. Sobald geübt wurde, steht '
                               'hier, was gerade geübt wird und wobei Unterstützung hilft.')
        values = snap(rows)
        self.assertEqual(values['answers_hint'], {'kind': 'all-older'})
        self.assertEqual(reader.consistency_failures(values), [])

    def test_read_error_and_missing_tiles_fail(self):
        failures = reader.consistency_failures(snap(screen(
            answers='Antworten: –, nicht geladen',
            basis='Die Kennzahlen konnten nicht sicher geladen werden.')))
        self.assertTrue(any('nicht auswertbar' in f for f in failures), failures)
        missing = reader.consistency_failures(snap(screen()[1:]))
        self.assertTrue(any('fehlen' in f for f in missing), missing)

    def test_ambiguous_tile_raises(self):
        rows = screen() + [node('Antworten: 12, 10 ohne Hilfe')]
        with self.assertRaises(ValueError):
            reader.read_tiles(rows, PACKAGE)

    def test_content_desc_without_identifier_and_foreign_package(self):
        rows = [node('Antworten: 6, 4 ohne Hilfe'),
                node('Antworten: 99, 1 ohne Hilfe', package='com.android.systemui')]
        tiles = reader.read_tiles(rows, PACKAGE)
        self.assertEqual(tiles['answers']['value'], '6')
        self.assertEqual(tiles['answers']['source'], 'content-desc')

    def test_ocr_replacement_only_with_one_clear_line(self):
        text = 'Auf einen Blick\nGrundlage: 36 Antworten auf diesem\nGerat, davon 33 ohne Hilfe.'
        self.assertEqual(reader.read_guidance_basis_ocr(text)['total'], 36)
        self.assertEqual(reader.read_guidance_basis_ocr(text)['source'], 'ocr')
        self.assertIsNone(reader.read_guidance_basis_ocr('Grundlage: 3 Antworten'))


def log(*rows):
    return json.dumps([{'id': i, 'sid': 'self', 'sub': 'Mathematik', 'unit': 'Plus bis 10',
                        'ok': ok, **({'hint': True} if hint else {})} for i, ok, hint in rows])


SUBMISSIONS = [
    {'correct': True, 'assisted': False}, {'correct': False, 'assisted': False},
    {'correct': True, 'assisted': True}, {'correct': True, 'assisted': True},
    {'correct': True, 'assisted': False}, {'correct': True, 'assisted': False}]


class AfterAnswersTest(unittest.TestCase):
    def setUp(self):
        self.before = snap(screen(answers='Antworten: 0, noch keine',
                                  streak='Lerntage in Folge: 0, noch keine',
                                  strengths='Stärken: –, noch offen',
                                  needs='Förderbedarf: –, noch offen',
                                  basis='Noch keine Antworten in diesem Profil.',
                                  guidance='Noch keine protokollierten Antworten.'))
        self.after = snap(screen(answers='Antworten: 6, 4 ohne Hilfe',
                                 strengths='Stärken: –, noch offen',
                                 needs='Förderbedarf: –, noch offen',
                                 basis='Grundlage wie „Auf einen Blick“: 6 Antworten im '
                                       'Aufgabenprotokoll dieses Profils, davon 4 ohne Hilfe.',
                                 guidance='Grundlage: 6 Antworten auf diesem Gerät, davon 4 ohne Hilfe.'))
        self.delta = reader.attempt_log_delta(
            log(('old', True, False)),
            log(('old', True, False), ('a', True, False), ('b', False, False), ('c', True, True),
                ('d', True, True), ('e', True, False), ('f', True, False)))

    def test_attempt_log_delta(self):
        self.assertEqual(self.delta['count'], 6)
        self.assertEqual((self.delta['wrong'], self.delta['assisted'], self.delta['independent']),
                         (1, 2, 4))
        self.assertEqual(self.delta['units'], ['Mathematik · Plus bis 10'])
        self.assertEqual(reader.expected_from_submissions(SUBMISSIONS),
                         {'count': 6, 'correct': 5, 'wrong': 1, 'assisted': 2, 'independent': 4})

    def test_six_answers_pass(self):
        self.assertEqual(reader.consistency_failures(self.after), [])
        self.assertEqual(reader.answer_failures(self.before, self.after, SUBMISSIONS, self.delta), [])

    def test_wrong_growth_and_streak_fail(self):
        stale = snap(screen(answers='Antworten: 5, 4 ohne Hilfe',
                            streak='Lerntage in Folge: 0, zuletzt gestern',
                            guidance='Grundlage: 5 Antworten auf diesem Gerät, davon 4 ohne Hilfe.'))
        failures = reader.answer_failures(self.before, stale, SUBMISSIONS, self.delta)
        self.assertTrue(any('stieg um 5' in f for f in failures), failures)
        self.assertTrue(any('Lerntage' in f for f in failures), failures)

    def test_restart_must_keep_every_value(self):
        same = snap(screen(answers='Antworten: 6, 4 ohne Hilfe',
                           strengths='Stärken: –, noch offen',
                           needs='Förderbedarf: –, noch offen',
                           basis='Grundlage wie „Auf einen Blick“: 6 Antworten im '
                                 'Aufgabenprotokoll dieses Profils, davon 4 ohne Hilfe.',
                           guidance='Grundlage: 6 Antworten auf diesem Gerät, davon 4 ohne Hilfe.'))
        self.assertEqual(reader.restart_failures(self.after, same), [])
        lost = snap(screen(answers='Antworten: 0, noch keine'))
        self.assertTrue(reader.restart_failures(self.after, lost))


class TaskReaderTest(unittest.TestCase):
    def test_task_prompt_and_answer_cards(self):
        rows = [node('Runde 1 von 3\nAufgabe 4 / 30\n2 beim ersten Versuch'),
                node('3 + 4 = ?', rid='plus10-task'),
                node('Antwort 6'), node('Antwort 7'), node('Antwort 8', enabled='false'),
                node('Tipp')]
        task = reader.read_task(rows, PACKAGE)
        self.assertEqual((task['index'], task['total'], task['correct']), (4, 30, 7))
        self.assertEqual(task['answers'], {6: True, 7: True, 8: False})
        self.assertEqual(reader.choose_distractor(task), 6)
        self.assertIsNone(task['round_continue'])

    def test_round_break_and_missing_distractor(self):
        rows = [node('Runde 1 von 3 geschafft!'), node('Weiter mit Runde 2'),
                node('Für heute aufhören')]
        self.assertEqual(reader.read_task(rows, PACKAGE)['round_continue'], 'Weiter mit Runde 2')
        with self.assertRaises(ValueError):
            reader.choose_distractor({'correct': 7, 'answers': {7: True, 6: False}})


class SourceSelectorsTest(unittest.TestCase):
    """Jeder Selektor der Probe steht so im App-Code (lib/)."""

    def source(self, path):
        return (ROOT / path).read_text(encoding='utf-8')

    def test_dashboard_semantics(self):
        dashboard = self.source('lib/features/parents/lumo_insight_dashboard.dart')
        self.assertIn("identifier: 'insight-stat-$key'", dashboard)
        self.assertIn("label: '$label: $value, $hint'", dashboard)
        self.assertIn("identifier: 'insight-stats-basis'", dashboard)
        for label in reader.TILES.values():
            self.assertIn(f"label: '{label}'", dashboard)
        for text in ("'wird geladen'", "'nicht geladen'", "'noch keine'", "'ältere, ohne Datum'",
                     "'inkl. ${m.olderAnswers} ältere'", "'${m.loggedIndependent} ohne Hilfe'",
                     "'zuletzt heute'", "'Kennzahlen werden geladen …'",
                     "'Noch keine Antworten in diesem Profil.'",
                     "'Grundlage wie „Auf einen Blick“: ${m.loggedAnswers} '"):
            self.assertIn(text, dashboard)
        guidance = self.source('lib/features/report/learning_guidance_panel.dart')
        self.assertIn("'Grundlage: ${g.total} Antworten auf diesem Gerät, '", guidance)
        self.assertIn("'davon ${g.independentTotal} ohne Hilfe.'", guidance)
        self.assertIn("'Noch keine protokollierten Antworten. Sobald geübt wurde, steht '", guidance)
        report = self.source('lib/features/settings/parent_report_card.dart')
        self.assertIn("'Lumo Insight'", report)

    def test_learning_route_selectors(self):
        hub = self.source('lib/features/sections/lumo_learning_hub.dart')
        self.assertIn("Text('Themen · ${subject.name}',", hub)
        self.assertIn("'Themen · Mathematik' in app_text", self.source('.github/probes/lumo_parent_insight_android_probe.py'))
        # Schulwissen-Kacheln (badge == null, z. B. „Plus bis 10“) beginnen mit
        # dem Titel; die Probe tippt per Textanfang. Vertiefung/Expertenwelt
        # tragen ihr Abzeichen zwischen Titel und Status (Team A4).
        self.assertIn(
            "label: badge == null ? '$title\\n$status' : '$title\\n$badge\\n$status'", hub)
        self.assertIn('LumoLearningLevel.schulwissen => null,', hub)
        registry = self.source('lib/features/learning_modules/learning_module_registry.dart')
        self.assertIn("case 'm1_plus10':\n        return PlusBis10Screen", registry)
        screen_ = self.source('lib/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart')
        for text in ("semanticLabel: 'Antwort $ans'", "'Aufgabe ${_taskIdx + 1} / $_totalTasks'",
                     "'$_a + $_b = ?'", "label: _showHint ? 'Anderer Tipp' : 'Tipp'",
                     "unit: 'Plus bis 10'",
                     "_pendingHintUsed = _showHint || _helpLevel > 0 || _wrongAttempts > 0;"):
            self.assertIn(text, screen_)
        rounds = self.source('lib/features/learning_modules/learning_module_rounds.dart')
        self.assertIn("'Weiter mit Runde ${round + 1}'", rounds)


PROBE_PATH = ROOT / '.github/probes/lumo_parent_insight_android_probe.py'


class ProbeModuleTest(unittest.TestCase):
    def test_probe_loads_and_requires_all_steps(self):
        stub = SimpleNamespace(base=SimpleNamespace(adb=Mock(), launch=Mock()),
                               live=SimpleNamespace(live_nodes=Mock()), PACKAGE=PACKAGE,
                               capture=Mock(), prefs=Mock(), flutter_tap=Mock())
        spec = importlib.util.spec_from_file_location('parent_insight_probe_contract', PROBE_PATH)
        module = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {
                'creative_android_probe': stub,
                'modernization_android_tour': SimpleNamespace(verify_apk_identity=Mock()),
                'lumo_local_backup_android_probe': SimpleNamespace()}):
            spec.loader.exec_module(module)
        self.assertEqual(module.REQUIRED, ('apk-identity', 'fictional-profile', 'insight-before',
                                           'answer-tasks', 'insight-after', 'insight-restart'))
        self.assertEqual(module.RESULT, 'parent-insight-result.json')
        # Sechs Antworten: jede Aufgabe eine, die falsch beantwortete zwei.
        self.assertEqual(len(module.PLAN) + module.PLAN.count('wrong-then-correct'), 6)
        self.assertIn('hint-then-correct', module.PLAN)
        self.assertTrue(re.search(r"for name in \('apk', 'provenance', 'sums', 'out'\)",
                                  PROBE_PATH.read_text(encoding='utf-8')))


if __name__ == '__main__':
    unittest.main()
