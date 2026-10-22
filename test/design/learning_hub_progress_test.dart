import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';

// The subject cards show the child's saved answers, never sample numbers.
void main() {
  Widget hub(int grade, Map<String, SkillRecord> skills) => MaterialApp(
        home: Scaffold(
          body: LumoLearningHub(
            grade: grade,
            skills: skills,
            onStartUnit: (_, __) {},
            onReading: () {},
            onPracticalSubject: (_) {},
            onAdvanced: () {},
          ),
        ),
      );

  SkillRecord skill(String subject, String unit, {int correct = 0, int wrong = 0}) =>
      SkillRecord(
        skillId: SkillRecord.makeId(subject, unit),
        subject: subject,
        unit: unit,
        correct: correct,
        wrong: wrong,
      );

  String status(WidgetTester tester, String subject) => tester
      .widget<Text>(find.byKey(ValueKey('learning-subject-progress-$subject')))
      .data!;

  testWidgets('a new child sees every subject as not yet started', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(hub(2, const {}));
    for (final subject in ['Mathematik', 'Deutsch', 'Englisch', 'Sachunterricht']) {
      expect(status(tester, subject), 'Noch nicht begonnen');
    }
    expect(find.text('0%'), findsNWidgets(4));
    expect(find.byKey(const ValueKey('learning-hub-lumo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only correctly answered topics of the enrolled grade count',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final math2 = Curriculum.unitsForGrade('Mathematik', 2, currentGradeOnly: true);
    final german2 = Curriculum.unitsForGrade('Deutsch', 2, currentGradeOnly: true);
    final math4 = Curriculum.unitsForGrade('Mathematik', 4, currentGradeOnly: true)
        .where((unit) => !math2.contains(unit))
        .toList();
    expect(math2.length, greaterThanOrEqualTo(2));
    expect(german2, isNotEmpty);
    expect(math4, isNotEmpty);
    final records = [
      skill('Mathematik', math2[0], correct: 3, wrong: 1),
      skill('Mathematik', math2[1], correct: 1),
      skill('Mathematik', math4.first, correct: 5), // other grade: ignored
      skill('Deutsch', german2.first, wrong: 2), // no correct answer yet
    ];
    await tester.pumpWidget(hub(2, {for (final r in records) r.skillId: r}));
    expect(status(tester, 'Mathematik'), '2 von ${math2.length} Themen geübt');
    expect(find.text('${(200 / math2.length).round()}%'), findsOneWidget);
    expect(status(tester, 'Deutsch'), 'Noch nicht begonnen');
    expect(status(tester, 'Englisch'), 'Noch nicht begonnen');
    final semantics = tester.getSemantics(
        find.byKey(const ValueKey('learning-subject-Mathematik')));
    expect(semantics.label,
        'Mathematik\nRechnen & Knobeln\n2 von ${math2.length} Themen geübt');
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  });
}
