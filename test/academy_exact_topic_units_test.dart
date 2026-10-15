import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/curriculum/academy_topic_units.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/cross_grade_writing_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  test('every 3rd/4th grade academy quiz tile has its OWN real unit', () {
    var exercised = 0;
    for (final grade in LumoCurriculum.grades.where((g) => g.grade >= 3)) {
      for (final subject in grade.subjects) {
        for (final topic in subject.topics) {
          if (topic.id == 'd3_geschichten' ||
              topic.id == 'd4_aufsatz') {
            // Dedicated story library / authored writing, not quiz tasks.
            continue;
          }
          final resolved = AcademyTopicUnits.exerciseUnit(
            topicId: topic.id,
            title: topic.title,
            subject: subject.name,
            grade: grade.grade,
          );
          final scope =
              '${grade.grade}. Klasse/${subject.name}/${topic.id}';
          expect(resolved, isNotNull, reason: scope);
          expect(
            Curriculum.unitsForGrade(subject.name, grade.grade),
            contains(resolved), reason: scope,
          );
          for (final seed in [13, 31, 73]) {
            final task = ExerciseFactory(seed: seed).next(
              grade: grade.grade,
              subject: subject.name,
              unit: resolved!,
            );
            expect(task.grade, grade.grade, reason: scope);
            expect(task.subject, subject.name, reason: scope);
            expect(task.unit, resolved, reason: scope);
            expect(task.prompt.trim(), isNotEmpty, reason: scope);
            expect(task.answer.trim(), isNotEmpty, reason: scope);
            expect(task.choices, contains(task.answer), reason: scope);
          }
          exercised++;
        }
      }
    }
    expect(exercised, greaterThanOrEqualTo(50));
  });

  test('resolver fails closed rather than silently showing another topic', () {
    expect(
      AcademyTopicUnits.exerciseUnit(
        topicId: 'future-unit-without-generator',
        title: 'Etwas komplett anderes',
        subject: 'Mathematik',
        grade: 4,
      ),
      isNull,
    );
    expect(
      AcademyTopicUnits.exerciseUnit(
        topicId: 'd4_aufsatz',
        title: 'Aufsätze',
        subject: 'Deutsch',
        grade: 4,
      ),
      isNull,
    );
  });

  testWidgets('creative writing saves and restores grade-4 draft independently',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    Future<void> open() => tester.pumpWidget(
          const MaterialApp(
            home: CrossGradeWritingScreen(
              profileName: 'LumoTester',
              enrolledGrade: 2,
            ),
          ),
        );

    await open();
    await tester.pump();
    expect(find.text('4. Klasse · Aufsätze'), findsOneWidget);
    expect(find.byKey(const ValueKey('cross-grade-writing-input')),
        findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('cross-grade-writing-input')),
        'Lumo findet eine Karte. Auf der Karte steht ein Ziel.');
    await tester.ensureVisible(
        find.byKey(const ValueKey('cross-grade-writing-save')));
    await tester.tap(find.byKey(const ValueKey('cross-grade-writing-save')));
    await tester.pump();
    expect(find.byKey(const ValueKey('cross-grade-writing-saved')),
        findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getString(
            'cross_grade_writing_v1:lumotester:4:aufsatz:draft:0'),
        contains('Lumo findet eine Karte.'));
    // Recreate screen: draft survives, no mutation to the enrolled grade.
    await tester.pumpWidget(const SizedBox.shrink());
    await open();
    await tester.pump();
    final textField = tester.widget<TextField>(
        find.byKey(const ValueKey('cross-grade-writing-input')));
    expect(textField.controller?.text, contains('Lumo findet eine Karte.'));
    expect(find.textContaining('2. Klasse'), findsWidgets);
  });
}
