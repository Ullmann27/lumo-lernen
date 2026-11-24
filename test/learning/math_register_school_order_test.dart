import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/curriculum/academy_topic_units.dart';
import 'package:lumo_lernen/core/curriculum/math_unit_order.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_hint_service.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

/// Mathematik-Register für die Vorführung am 24.11.2026: gleiche Ordnung in
/// jeder Klasse, exakte Plus-/Minus-Routen und Erklärungen, die zur Aufgabe
/// passen.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every grade lists Mathematik in school order and keeps every unit', () {
    for (var grade = 1; grade <= 4; grade++) {
      final units =
          Curriculum.unitsForGrade('Mathematik', grade, currentGradeOnly: true);
      final groups = units.map(MathUnitOrder.groupOf).toList();
      final ranks = groups.map(MathUnitOrder.groups.indexOf).toList();
      for (var i = 1; i < ranks.length; i++) {
        expect(ranks[i], greaterThanOrEqualTo(ranks[i - 1]),
            reason: '$grade. Klasse: $units');
      }
      final grouped = MathUnitOrder.grouped(units);
      expect(grouped.expand((entry) => entry.$2).toList(), units);
    }
    final first =
        Curriculum.unitsForGrade('Mathematik', 1, currentGradeOnly: true);
    expect(
        first.indexOf('Plus bis 10'), lessThan(first.indexOf('Textaufgaben')));
    expect(
        first.indexOf('Plus bis 10'), lessThan(first.indexOf('Minus bis 10')));
    expect(
        first.indexOf('Minus bis 10'), lessThan(first.indexOf('Plus bis 20')));
  });

  test('grade 1 and 2 academy plus/minus tiles start their exact unit', () {
    const expected = {
      1: {'m1_plus20': 'Plus bis 20', 'm1_minus20': 'Minus bis 20'},
      2: {'m2_plus100': 'Plus bis 100', 'm2_minus100': 'Minus bis 100'},
      3: {
        'm3_zahlen1000': 'Plus bis 1000',
        'm3_minus1000': 'Minus bis 1000',
        'm3_geometrie': 'Umfang',
      },
    };
    for (final MapEntry(key: grade, value: tiles) in expected.entries) {
      final math = LumoCurriculum.grades
          .singleWhere((g) => g.grade == grade)
          .subjects
          .singleWhere((s) => s.name == 'Mathematik');
      for (final MapEntry(key: id, value: unit) in tiles.entries) {
        final topic = math.topics.singleWhere((t) => t.id == id);
        // The tile title names exactly what is practised.
        expect(topic.title, unit);
        expect(
          AcademyTopicUnits.exerciseUnit(
              topicId: topic.id,
              title: topic.title,
              subject: 'Mathematik',
              grade: grade),
          unit,
        );
      }
    }
  });

  test('Plus bis 100 stays addition and names the fitting strategy', () {
    final factory = ExerciseFactory(seed: 2411);
    final addition = RegExp(r'^(\d+) \+ (\d+) = \?$');
    for (var i = 0; i < 200; i++) {
      final task = factory.nextExact(
          grade: 2, subject: 'Mathematik', unit: 'Plus bis 100');
      final match = addition.firstMatch(task.prompt);
      expect(match, isNotNull, reason: task.prompt);
      final a = int.parse(match!.group(1)!), b = int.parse(match.group(2)!);
      expect(a + b, lessThanOrEqualTo(100));
      expect(task.answer, '${a + b}');
      final crossesTen = a % 10 + b % 10 >= 10;
      if (task.explanation.startsWith('Zehnerübergang')) {
        expect(crossesTen, isTrue, reason: task.explanation);
      }
      if (b % 10 == 0) {
        expect(task.explanation, contains('nur ganze Zehner'));
      }
    }
  });

  test('level-2 hint in Zahlenraum 100 splits tens and ones without the result',
      () {
    const hints = TaskHintService();
    LumoTask task(String prompt, String unit) => LumoTask(
          id: 'mathe-register-hint',
          grade: 2,
          subject: 'Mathematik',
          unit: unit,
          prompt: prompt,
          answer: 'nicht verwenden',
          choices: const [],
          explanation: 'nicht verwenden',
        );
    final plus = hints.explain(task('37 + 25 = ?', 'Plus bis 100'), level: 2);
    expect(plus, contains('Zerlege 25 in 20 und 5'));
    expect(plus, contains('37 + 20'));
    expect(plus, isNot(contains('62')));
    final minus = hints.explain(task('64 - 28 = ?', 'Minus bis 100'), level: 2);
    expect(minus, contains('Zerlege 28 in 20 und 8'));
    expect(minus, contains('64 − 20'));
    expect(minus, isNot(contains('36')));
  });

  testWidgets('register shows group headings, examples and opens the unit',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? started;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LumoLearningHub(
          grade: 2,
          onStartUnit: (_, unit) => started = unit,
          onReading: () {},
          onPracticalSubject: (_) {},
          onAdvanced: () {},
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('learning-subject-Mathematik')));
    await tester.pump();
    expect(find.byKey(const ValueKey('learning-unit-group-Plus und Minus')),
        findsOneWidget);
    expect(
        find.byKey(
            const ValueKey('learning-unit-example-Mathematik-Plus bis 100')),
        findsOneWidget);
    final plus =
        find.byKey(const ValueKey('learning-unit-Mathematik-Plus bis 100'));
    await tester.ensureVisible(plus);
    await tester.pump();
    expect(tester.getSize(plus).height, greaterThanOrEqualTo(48));
    await tester.tap(plus);
    expect(started, 'Plus bis 100');
  });
}
