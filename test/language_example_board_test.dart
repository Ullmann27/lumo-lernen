import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/features/learning/widgets/language_practice_material.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_english_vocabulary.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/widgets/interactive_task_workspace.dart';
import 'package:lumo_lernen/features/learning/widgets/language_example_board.dart';

void main() {
  test(
      'Every locally selectable German and English exercise has a language model',
      () {
    for (final activity in PrimaryActivityCatalog.all
        .where((a) => ['Deutsch', 'Englisch'].contains(a.subject))) {
      expect(LanguagePracticeMaterial.supports(activity.id), isTrue,
          reason: activity.id);
    }
    for (final grade in [1, 2, 3, 4]) {
      for (final subject in [
        'Deutsch',
        'Englisch',
        'Lesen',
        'Schreiben',
        'Rechtschreibung'
      ]) {
        final language = subject == 'Englisch'
            ? LearningSubject.englisch
            : LearningSubject.deutsch;
        for (final unit in Curriculum.unitsForGrade(subject, grade)) {
          expect(LanguageExample.forUnit(unit, language), isNotNull,
              reason: '$grade / $subject / $unit');
        }
      }
    }
  });

  test('English animal illustrations are bound to their real current words',
      () {
    final factory = ExerciseFactory(seed: 2065);
    final animals = <String>{};
    for (var i = 0; i < 220; i++) {
      final task =
          factory.nextExact(grade: 2, subject: 'Englisch', unit: 'Tiere');
      final instance = const LegacyLumoTaskAdapter().toTaskInstance(
          task: task, childId: 'animal-check', difficulty: task.difficulty);
      final object = NativeEnglishVocabulary.illustrationFor(instance);
      if (object != null) {
        expect(object['meaning'], task.answer);
        animals.add(object['word']! as String);
      }
    }
    expect(animals, containsAll(['lion', 'cow', 'sheep']));
  });

  testWidgets('Picture cards reveal one word and report a help action',
      (tester) async {
    final task = LumoTask(
        id: 'picture-test',
        grade: 1,
        subject: 'Englisch',
        unit: 'Farben',
        prompt: 'Was bedeutet „red“?',
        answer: 'rot',
        choices: ['rot', 'blau', 'gelb', 'grün'],
        explanation: 'Red bedeutet rot.');
    final instance = const LegacyLumoTaskAdapter()
        .toTaskInstance(task: task, childId: 'test', difficulty: 1);
    final actions = <TaskWorkspaceInteraction>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InteractiveTaskWorkspace(
                task: instance, onInteraction: actions.add))));
    expect(find.byType(CircleAvatar), findsNWidgets(4));
    expect(find.text('rot'), findsNothing);
    await tester.tap(find.byType(CircleAvatar).first);
    await tester.pump();
    expect(actions.last.action, 'inspectLanguageExample');
    expect(actions.last.isHelp, isTrue);
  });

  for (final grade in [1, 2, 3, 4]) {
    testWidgets(
        'Grade $grade sees and explores the example in the real workspace',
        (tester) async {
      final task = ExerciseFactory(seed: 43)
          .nextExact(grade: grade, subject: 'Englisch', unit: 'Begruessung');
      final instance = const LegacyLumoTaskAdapter().toTaskInstance(
          task: task, childId: 'local-test', difficulty: task.difficulty);
      expect(instance.parameters['grade'], grade);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: InteractiveTaskWorkspace(task: instance)))));
      if (grade >= 3) {
        expect(find.text('Hello!'), findsNothing);
        await tester.tap(find.text('Beispiel erkunden'));
        await tester.pump();
      }
      await tester.tap(find.text('Hello!'));
      await tester.pump();
      expect(find.text('Hi, Mia!'), findsOneWidget);
      if (grade == 2) expect(find.text('Beispiel · 2 von 2'), findsOneWidget);
    });
  }
}
