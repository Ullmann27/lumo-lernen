// Prüfmatrix aller Lernkacheln (Team A1, Auftrag Abschnitt 4).
//
// Dieser Test erzeugt die Matrix docs/qa/lernmodul_pruefmatrix.csv aus der
// echten Oberfläche: Er öffnet die LUMO AKADEMIE für jede Klasse, tippt jede
// sichtbare Fach- und Themenkachel an und hält fest, was wirklich geöffnet
// wird (eigenes Lernmodul, Aufgabengenerator, Aktivitätenkatalog …). Für jede
// Generator-Kachel werden je 120 Aufgaben über ExerciseFactory.nextExact
// erzeugt und auf Fach, Klasse, Rubrik und Qualitätsprüfung geprüft. Dazu
// kommen Tests-Bildschirm (Kategorie × Stufe), Schularbeit-Karten,
// Lernatelier-Werkzeuge, Lernspiel-Stufen und der Akademie-Themenkatalog.
//
// Neue oder entfernte Kacheln fallen auf: Die erzeugte Matrix muss mit der
// eingecheckten Datei übereinstimmen. Nach einer gewollten Änderung:
//   LUMO_UPDATE_PRUEFMATRIX=1 flutter test test/qa/lernmodul_pruefmatrix_test.dart
// und die Änderung der CSV im Commit prüfen.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/adventure/lumo_adventure_tasks.dart';
import 'package:lumo_lernen/core/curriculum/academy_topic_units.dart';
import 'package:lumo_lernen/core/curriculum/learning_level.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/sections/section_content.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/tests/lumo_tests_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _csvPath = 'docs/qa/lernmodul_pruefmatrix.csv';
const _mdPath = 'docs/qa/lernmodul_pruefmatrix.md';
const _samples = 120;

const _header = <String>[
  'Bereich',
  'Klasse',
  'Fach',
  'Rubrik',
  'Kachel',
  'Oeffnet',
  'Datenquelle',
  'Aufgabenfach',
  'Varianten',
  'Schwierigkeit',
  'Befund',
  'Ebene',
];

final _rows = <List<String>>[];
final _defects = <String>[];
final _layout = <String>[];

class _PushRecorder extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

String _routeTarget(Route<dynamic> route, BuildContext context) {
  if (route is MaterialPageRoute) {
    return route.builder(context).runtimeType.toString();
  }
  return route.runtimeType.toString();
}

String _strip(String id) =>
    id.replaceFirst(RegExp(r'-\d{6,}-\d+-\d+$'), '');

/// Welche Datenquelle der Generator für diese Rubrik nutzt.
String _sourceFor(int grade, String subject, String unit) {
  if (LumoAdventureTasks.handles(subject, unit)) {
    return 'LumoAdventureTasks';
  }
  switch (subject) {
    case 'Mathematik':
      final ids = [
        for (final t in MathTaskTemplates.templates)
          if (t.unit == unit && t.grade <= grade) t.id,
      ];
      return 'MathTaskTemplates ${ids.join('+')}';
    case 'Deutsch':
      if (unit == 'St oder Sp') return 'ExerciseFactory St/Sp';
      final ids = [
        for (final t in GermanTaskTemplates.templates)
          if (t.unit == unit && t.grade <= grade) t.id,
      ];
      return 'GermanTaskTemplates ${ids.join('+')}';
    case 'Sachunterricht':
      return 'Sachunterricht-Fragenbank';
    case 'Englisch':
      return 'Englisch-Wortschatz';
    default:
      return 'ExerciseFactory $subject';
  }
}

/// Erzeugt [_samples] Aufgaben und prüft Fach, Klasse, Rubrik, Qualität.
(String, String, String, String) _sample(
    int grade, String subject, String unit) {
  const guard = TaskQualityGuard();
  final prompts = <String>{};
  final patterns = <String>{};
  var minDifficulty = 99;
  var maxDifficulty = 0;
  final problems = <String>[];
  for (var seed = 0; seed < _samples; seed++) {
    final LumoTask task;
    try {
      task = ExerciseFactory(seed: seed * 7919 + grade)
          .nextExact(grade: grade, subject: subject, unit: unit);
    } catch (error) {
      problems.add('Fehler: $error');
      break;
    }
    prompts.add('${task.prompt}|${task.answer}');
    patterns.add(_strip(task.id));
    if (task.difficulty < minDifficulty) minDifficulty = task.difficulty;
    if (task.difficulty > maxDifficulty) maxDifficulty = task.difficulty;
    if (task.subject != subject || task.unit != unit || task.grade != grade) {
      problems.add('falsches Ziel ${task.subject}/${task.unit}/${task.grade}');
    }
    final issues = guard.problems(task);
    if (issues.isNotEmpty) problems.add('${issues.join(',')}: ${task.prompt}');
  }
  final verdict = problems.isEmpty ? 'ok' : problems.first;
  if (problems.isNotEmpty) {
    _defects.add('$grade/$subject/$unit: $verdict');
  }
  final source = _sourceFor(grade, subject, unit);
  final shown = source.startsWith('MathTaskTemplates') ||
          source.startsWith('GermanTaskTemplates')
      ? source
      : '$source (${(patterns.toList()..sort()).join('+')})';
  return (
    shown,
    verdict == 'ok' ? subject : 'FEHLER',
    '${prompts.length}',
    minDifficulty == maxDifficulty
        ? '$minDifficulty'
        : '$minDifficulty-$maxDifficulty',
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (var grade = 1; grade <= 4; grade++) {
    testWidgets('Lernhub Klasse $grade: jede Kachel öffnet ihr Ziel',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      app.update(app.state.copyWith(grade: grade, childName: 'Mia'));
      final recorder = _PushRecorder();
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [recorder],
        home: LumoAkademieScreen(appState: app),
      ));
      await _settle(tester);
      await tester.tap(find.byKey(ValueKey('grade-pill-$grade')));
      await _settle(tester);
      final context = tester.element(find.byType(LumoAkademieScreen));

      // Layout-Überläufe in geöffneten Modulen sind ein eigener Befund
      // (Gestaltung, nicht Navigation). Sie werden in der Matrix vermerkt
      // und im Prüfbericht gemeldet, statt den Navigationstest abzubrechen.
      var overflow = false;
      Future<String> observe(Future<void> Function() action) async {
        final before = recorder.pushed.length;
        app.update(app.state.copyWith(
            section: LumoSection.learn, subject: 'Alle', unit: 'Alle'));
        final original = FlutterError.onError;
        overflow = false;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('RenderFlex overflowed')) {
            overflow = true;
            return;
          }
          original?.call(details);
        };
        try {
          await action();
          await _settle(tester);
          if (recorder.pushed.length > before) {
            final route = recorder.pushed.last;
            final target = _routeTarget(route, context);
            route.navigator!.pop();
            await _settle(tester);
            await tester.pump(const Duration(seconds: 1));
            return target;
          }
        } finally {
          FlutterError.onError = original;
        }
        final st = app.state;
        if (st.section == LumoSection.exercises) {
          return 'Übung ${st.subject}/${st.unit}';
        }
        if (st.section == LumoSection.reading) return 'Lesebereich';
        return 'NICHTS';
      }

      List<String> subjectKeys(String prefix) => [
            for (final element in find
                .byWidgetPredicate((w) =>
                    (w is InkWell || w is ListTile) &&
                    w.key is ValueKey<String> &&
                    (w.key as ValueKey<String>).value.startsWith(prefix))
                .evaluate())
              (element.widget.key as ValueKey<String>)
                  .value
                  .substring(prefix.length),
          ];

      Future<void> reveal(Finder target) async {
        if (target.evaluate().isEmpty) {
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pump();
          await tester.scrollUntilVisible(target, 250,
              scrollable: find.byType(Scrollable).first, maxScrolls: 120);
        } else {
          await tester.ensureVisible(target);
        }
        await tester.pump();
      }

      const expansion = PageStorageKey<String>('learning-other-subjects');
      Future<void> showExtra(Key key) async {
        await reveal(find.byKey(expansion));
        if (find.byKey(key).evaluate().isEmpty) {
          await tester.tap(find.byKey(expansion));
          await _settle(tester);
        }
      }

      final main = subjectKeys('learning-subject-');
      await showExtra(const ValueKey('learning-extra-Lesen'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await _settle(tester);
      final extra = subjectKeys('learning-extra-');
      expect(main, isNotEmpty);
      expect(extra, isNotEmpty);

      for (final subject in [...main, ...extra]) {
        final isMain = main.contains(subject);
        final key = isMain
            ? ValueKey('learning-subject-$subject')
            : ValueKey('learning-extra-$subject');
        if (!isMain) await showExtra(key);
        final opened = await observe(() async {
          await reveal(find.byKey(key));
          await tester.tap(find.byKey(key));
        });
        if (opened != 'NICHTS') {
          // Praktisches Fach: eigener Aktivitätenkatalog statt Quiz.
          final activities =
              PrimaryActivityCatalog.forGrade(grade, subject: subject);
          _rows.add([
            'Lernhub',
            '$grade',
            subject,
            '(Fach)',
            key.value,
            opened,
            'PrimaryActivityCatalog (${activities.length} Aktivitäten)',
            '–',
            '${activities.length}',
            '$grade',
            activities.isEmpty ? 'FEHLER: leer' : 'ok',
            '–',
          ]);
          if (activities.isEmpty) _defects.add('$grade/$subject leer');
          continue;
        }
        // Fach ist geöffnet: jede Themenkachel antippen.
        if (subject == 'Lesen') {
          final reading = await observe(() async {
            await tester.ensureVisible(
                find.byKey(const ValueKey('learning-active-reading')));
            await tester.pump();
            await tester.tap(find.byKey(const ValueKey('learning-active-reading')));
          });
          _rows.add([
            'Lernhub', '$grade', subject, 'Mit Lumo laut lesen',
            'learning-active-reading', reading, 'Lesebereich (Geschichten)',
            '–', '–', '$grade', reading == 'Lesebereich' ? 'ok' : 'FEHLER',
            '–',
          ]);
        }
        final units = Curriculum.unitsForGrade(subject, grade,
            currentGradeOnly: true);
        expect(units, isNotEmpty, reason: '$grade/$subject ohne Themen');
        for (final unit in units) {
          final tile = find.byKey(ValueKey('learning-unit-$subject-$unit'));
          await reveal(tile);
          expect(tile.hitTestable(), findsOneWidget,
              reason: '$grade/$subject/$unit');
          final opened = await observe(() async {
            await tester.tap(tile);
          });
          var source = 'eigenes Lernmodul';
          var taskSubject = '–';
          var variants = '–';
          var difficulty = '$grade';
          var verdict = 'ok';
          if (opened.startsWith('Übung ')) {
            final target = opened.substring('Übung '.length);
            if (target != '$subject/$unit') {
              verdict = 'FEHLER: öffnet $target';
              _defects.add('$grade/$subject/$unit öffnet $target');
            }
            final sample = _sample(grade, subject, unit);
            source = sample.$1;
            taskSubject = sample.$2;
            variants = sample.$3;
            difficulty = sample.$4;
            if (taskSubject == 'FEHLER') verdict = 'FEHLER: Generator';
          } else if (opened == 'NICHTS') {
            verdict = 'FEHLER: keine Reaktion';
            _defects.add('$grade/$subject/$unit ohne Reaktion');
          }
          if (overflow) {
            _layout.add('$grade/$subject/$unit → $opened');
            if (verdict == 'ok') verdict = 'Layout-Überlauf 412dp';
          }
          _rows.add([
            'Lernhub', '$grade', subject, unit,
            'learning-unit-$subject-$unit', opened, source, taskSubject,
            variants, difficulty, verdict,
            LearningLevels.levelOf(subject, unit, grade).title,
          ]);
        }
        app.update(app.state.copyWith(section: LumoSection.learn));
        await reveal(find.byKey(const ValueKey('learning-back-to-subjects')));
        await tester.tap(find.byKey(const ValueKey('learning-back-to-subjects')));
        await _settle(tester);
      }

      // Lernatelier-Werkzeuge (Erweitert) dieser Klasse.
      await reveal(find.byKey(const ValueKey('learning-advanced-entry')));
      await tester.tap(find.byKey(const ValueKey('learning-advanced-entry')));
      await _settle(tester);
      // Die Werkzeugkarte ist eine Spalte: ist ihr letzter Eintrag gebaut,
      // sind es alle.
      await reveal(find.byKey(const ValueKey('akademie-voluntary-discovery')));
      final tools = [
        for (final element in find
            .byWidgetPredicate((w) =>
                w is ListTile &&
                w.key is ValueKey<String> &&
                ((w.key as ValueKey<String>).value.startsWith('academy-') ||
                    (w.key as ValueKey<String>).value.startsWith('akademie-')))
            .evaluate())
          (element.widget.key as ValueKey<String>).value,
      ];
      expect(tools, isNotEmpty);
      for (final tool in tools) {
        final opened = await observe(() async {
          await reveal(find.byKey(ValueKey(tool)));
          await tester.tap(find.byKey(ValueKey(tool)));
        });
        _rows.add([
          'Lernatelier', '$grade', '–', tool, tool, opened,
          opened.startsWith('Übung') ? 'ExerciseFactory' : 'eigenes Modul',
          '–', '–', '$grade',
          opened == 'NICHTS'
              ? 'FEHLER'
              : overflow
                  ? 'Layout-Überlauf 412dp'
                  : 'ok',
          '–',
        ]);
        if (overflow) _layout.add('$grade/$tool → $opened');
        if (opened == 'NICHTS') _defects.add('$grade/Werkzeug $tool');
      }
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(minutes: 8)));
  }

  testWidgets('Tests-Bildschirm: jede Kategorie und Stufe', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (var grade = 1; grade <= 4; grade++) {
      final app = LumoAppState();
      app.update(app.state.copyWith(grade: grade, childName: 'Mia'));
      LumoSection? section;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LumoTestsScreen(
                appState: app,
                drawBackground: false,
                onSection: (s) => section = s)),
      ));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('tests-show-all')));
      await _settle(tester);
      final categories = [
        for (final element in find
            .byWidgetPredicate((w) =>
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith('test-category-'))
            .evaluate())
          (element.widget.key as ValueKey<String>)
              .value
              .substring('test-category-'.length),
      ];
      expect(categories, contains('Alle'));
      for (final category in categories) {
        for (final level in const [-1, 0, 1]) {
          await tester.tap(find.byKey(ValueKey('test-category-$category')));
          await _settle(tester);
          await tester.ensureVisible(find.byKey(ValueKey('test-level-$level')));
          await tester.tap(find.byKey(ValueKey('test-level-$level')));
          await _settle(tester);
          section = null;
          await tester.ensureVisible(find.byKey(const ValueKey('tests-start')));
          await tester.tap(find.byKey(const ValueKey('tests-start')));
          await _settle(tester);
          final st = app.state;
          final taskGrade = (grade + st.testLevel).clamp(1, 4).toInt();
          final subjects = <String>{};
          final units = <String>{};
          var maxDifficulty = 0;
          var handwriting = 0;
          // Lumo Expertenwelt nie ohne ausdrückliche Auswahl im Test.
          final levels = <LumoLearningLevel>{};
          for (var seed = 0; seed < 30; seed++) {
            final factory = ExerciseFactory(seed: seed * 101 + grade);
            for (var i = 0; i < 10; i++) {
              final task = factory.next(
                  grade: taskGrade,
                  subject: st.subject,
                  unit: st.unit,
                  gradedOnly: true);
              subjects.add(task.subject);
              units.add('${task.subject}/${task.unit}');
              if (task.difficulty > maxDifficulty) {
                maxDifficulty = task.difficulty;
              }
              if (task.handwriting) handwriting++;
              levels.add(
                  LearningLevels.levelOf(task.subject, task.unit, taskGrade));
            }
          }
          // Ein Fachtest bleibt im Fach; Deutsch umfasst laut Lehrplan auch
          // Lesen und Rechtschreibung.
          final pure = st.subject == 'Alle' ||
              subjects.every(ExerciseFactory.gradedSubjectsFor(st.subject).contains);
          final ok = section == LumoSection.exercises &&
              st.sessionKind == LumoSessionKind.test &&
              st.testLevel == level &&
              st.subject == category &&
              pure &&
              handwriting == 0 &&
              !levels.contains(LumoLearningLevel.expertenwelt) &&
              maxDifficulty <= taskGrade;
          if (!ok) _defects.add('Test $grade/$category/$level');
          _rows.add([
            'Tests', '$grade', category, 'Stufe $level (Kl. $taskGrade)',
            'test-category-$category+test-level-$level+tests-start',
            'Übung ${st.subject}/${st.unit} (${st.sessionKind.name}, 10 Fragen)',
            'ExerciseFactory.next gradedOnly',
            (subjects.toList()..sort()).join('+'),
            '${units.length} Rubriken',
            '1-$maxDifficulty',
            ok ? 'ok' : 'FEHLER',
            [
              for (final level in LumoLearningLevel.values)
                if (levels.contains(level)) level.title,
            ].join('+'),
          ]);
        }
      }
      for (final key in const ['iq-test-start', 'cognitive-profile-start']) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    }
    _rows.add([
      'Tests', '1-4', 'Knobeln', 'Lumo Knobel-Test', 'iq-test-start',
      'IqTestScreen', 'IqPuzzleGenerator', 'Logik', '–', '–', 'ok', '–',
    ]);
    _rows.add([
      'Tests', '1-4', 'Denken', 'Denkprofil', 'cognitive-profile-start',
      'CognitiveProfileScreen', 'CognitiveProfileGenerator', 'Logik', '–',
      '–', 'ok', '–',
    ]);
  });

  testWidgets('Schularbeit-Karten starten das versprochene Fach',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 882));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(grade: 3, childName: 'Mia'));
    LumoSection? section;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SectionContent(
              appState: app,
              section: LumoSection.schoolwork,
              onSection: (s) => section = s)),
    ));
    await _settle(tester);
    const cards = <String>[
      'Gemischter Lerncheck',
      'Mathe-Schularbeit',
      'Deutsch-Schularbeit',
      'Sachunterricht-Lerncheck',
      'Englisch-Lerncheck',
      'Schnelle Wiederholung',
    ];
    for (final card in cards) {
      section = null;
      final action = find.byKey(ValueKey('schoolwork-$card'));
      await tester.ensureVisible(action);
      await tester.pump();
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      await tester.tap(action);
      await _settle(tester);
      final st = app.state;
      final total = switch (st.sessionKind) {
        LumoSessionKind.schoolwork => 30,
        LumoSessionKind.test => 10,
        LumoSessionKind.exerciseSet => 20,
        _ => 0,
      };
      final graded = st.sessionKind != LumoSessionKind.exerciseSet;
      final subjects = <String>{};
      final levels = <LumoLearningLevel>{};
      for (var seed = 0; seed < 20; seed++) {
        final factory = ExerciseFactory(seed: seed * 53 + 3);
        for (var i = 0; i < total; i++) {
          final task = factory.next(
              grade: 3,
              subject: st.subject,
              unit: st.unit,
              gradedOnly: graded);
          subjects.add(task.subject);
          levels.add(LearningLevels.levelOf(task.subject, task.unit, 3));
        }
      }
      final ok = section == LumoSection.exercises &&
          !(graded && levels.contains(LumoLearningLevel.expertenwelt));
      if (!ok) _defects.add('Schularbeit $card');
      _rows.add([
        'Schularbeit', '1-4', st.subject, card, 'Text: $card',
        'Übung ${st.subject}/${st.unit} (${st.sessionKind.name}, $total Fragen)',
        'ExerciseFactory.next${graded ? ' gradedOnly' : ''}',
        (subjects.toList()..sort()).join('+'), '–', '–',
        ok ? 'ok' : 'FEHLER',
        [
          for (final level in LumoLearningLevel.values)
            if (levels.contains(level)) level.title,
        ].join('+'),
      ]);
    }
  });

  test('Akademie-Themenkatalog und Lernspiel-Stufen', () {
    for (final level in LumoCurriculum.grades) {
      for (final subject in level.subjects) {
        for (final topic in subject.topics) {
          final module = LearningModuleRegistry.hasModule(topic.id);
          final unit = AcademyTopicUnits.exerciseUnit(
            topicId: topic.id,
            title: topic.title,
            subject: subject.name,
            grade: level.grade,
          );
          final target = module
              ? 'eigenes Lernmodul'
              : unit != null
                  ? 'Übung ${subject.name}/$unit'
                  : topic.isWriting
                      ? 'Schreibmodul'
                      : 'Sonderweg (Geschichten/Schreiben/Chat)';
          _rows.add([
            'Akademie-Thema', '${level.grade}', subject.name, topic.title,
            topic.id, target,
            unit != null ? _sourceFor(level.grade, subject.name, unit) : '–',
            '–', '–', '${level.grade}', 'ok',
            unit != null
                ? LearningLevels.levelOf(subject.name, unit, level.grade).title
                : '–',
          ]);
        }
      }
    }
    for (final game in GameLevelCatalog.levels) {
      _rows.add([
        'Lernspiel', '${game.gradeFloor}', game.subject, game.title,
        'level-${game.id}', game.miniType.name, 'MiniGameLearningDeck',
        '–', '–', '${game.gradeFloor}', 'ok', '–',
      ]);
    }
  });

  test('Prüfmatrix stimmt mit docs/qa überein', () {
    expect(_defects, isEmpty, reason: _defects.join('\n'));
    if (_layout.isNotEmpty) {
      // ignore: avoid_print
      print('Layout-Überläufe (Befund für Gestaltung):\n${_layout.join('\n')}');
    }
    String cell(String value) {
      final clean = value.replaceAll('\n', ' ');
      return clean.contains(';') || clean.contains('"')
          ? '"${clean.replaceAll('"', '""')}"'
          : clean;
    }

    final csv = StringBuffer()..writeln(_header.join(';'));
    for (final row in _rows) {
      csv.writeln(row.map(cell).join(';'));
    }
    final md = StringBuffer()
      ..writeln('# Prüfmatrix Lernmodule (maschinell erzeugt)')
      ..writeln()
      ..writeln('Erzeugt von `test/qa/lernmodul_pruefmatrix_test.dart` aus der '
          'echten Oberfläche (Akademie, Tests, Schularbeit) und den Katalogen. '
          'Nicht von Hand bearbeiten; neu erzeugen mit '
          '`LUMO_UPDATE_PRUEFMATRIX=1 flutter test test/qa/lernmodul_pruefmatrix_test.dart`. '
          'Bewertung und Lehrplanbezug: `docs/qa/LERNMODUL_PRUEFBERICHT_2026-11-26.md`.')
      ..writeln()
      ..writeln('Generator-Kacheln: je $_samples Aufgaben über '
          '`ExerciseFactory.nextExact`, geprüft auf Fach, Klasse, Rubrik und '
          '`TaskQualityGuard`. „Varianten“ = verschiedene Aufgaben (Text + '
          'Lösung) unter $_samples.')
      ..writeln()
      ..writeln('„Ebene“: Schulwissen, Vertiefung oder Lumo Expertenwelt '
          '(`lib/core/curriculum/learning_level.dart`). Tests und '
          'Schularbeiten ziehen nie aus der Expertenwelt; bei Tests und '
          'Schularbeit-Karten stehen die tatsächlich gezogenen Ebenen.')
      ..writeln();
    final counts = <String, int>{};
    for (final row in _rows) {
      counts[row[0]] = (counts[row[0]] ?? 0) + 1;
    }
    md.writeln('| Bereich | Zeilen |');
    md.writeln('|---|---|');
    for (final entry in counts.entries) {
      md.writeln('| ${entry.key} | ${entry.value} |');
    }
    md.writeln();
    md.writeln('| ${_header.join(' | ')} |');
    md.writeln('|${List.filled(_header.length, '---').join('|')}|');
    for (final row in _rows) {
      md.writeln('| ${row.map((c) => c.replaceAll('|', '/')).join(' | ')} |');
    }
    if (Platform.environment['LUMO_UPDATE_PRUEFMATRIX'] == '1') {
      File(_csvPath).writeAsStringSync(csv.toString());
      File(_mdPath).writeAsStringSync(md.toString());
    }
    final committed = File(_csvPath);
    expect(committed.existsSync(), isTrue,
        reason: '$_csvPath fehlt: mit LUMO_UPDATE_PRUEFMATRIX=1 erzeugen');
    // Verglichen werden Kachel, Ziel, Datenquelle und Befund. Die gezählten
    // Varianten und Schwierigkeiten hängen von Zufallsfolgen ab und ändern
    // sich mit jeder Inhaltsverbesserung; sie stehen nur zur Information in
    // der Datei.
    String key(String line) {
      final cells = line.split(';');
      return [
        for (var i = 0; i < cells.length; i++)
          if (i != 8 && i != 9) cells[i],
      ].join(';');
    }

    final expected = committed.readAsLinesSync().map(key).toList();
    final actual = csv.toString().trimRight().split('\n').map(key).toList();
    final missing = actual.where((l) => !expected.contains(l)).toList();
    final gone = expected.where((l) => !actual.contains(l)).toList();
    expect([...missing.map((l) => '+ $l'), ...gone.map((l) => '- $l')],
        isEmpty,
        reason: 'Kacheln oder Ziele haben sich geändert. Prüfen und die '
            'Matrix neu erzeugen (LUMO_UPDATE_PRUEFMATRIX=1).');
  });
}
