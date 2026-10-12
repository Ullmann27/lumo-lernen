import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/science_task_data.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';

void main() {
  for (var grade = 1; grade <= 4; grade++) {
    test(
        'grade $grade: comprehension has 24 grounded questions and no immediate repeat',
        () {
      for (final unit in ['Sätze lesen', 'Lesesinn']) {
        final f = ExerciseFactory(seed: 1937);
        final problems = <String>{};
        String? previous;
        for (var n = 0; n < 200; n++) {
          final t = f.next(grade: grade, subject: 'Lesen', unit: unit);
          final key = '${t.prompt}|${t.answer}';
          expect(key, isNot(previous), reason: '$unit at $n');
          expect(t.choices.toSet().length, t.choices.length);
          expect(t.choices.where((v) => v == t.answer), hasLength(1));
          expect(t.explanation, isNotEmpty);
          problems.add(key);
          previous = key;
        }
        expect(problems.length, greaterThanOrEqualTo(24), reason: unit);
      }
    });
  }
  test(
      'new science entries retain exact questions and answers through the real adapter',
      () {
    final guard = TaskQualityGuard();
    const adapter = LegacyLumoTaskAdapter();
    final signatures = <String>{};
    for (final q in scienceExtensionQuestions) {
      final task = LumoTask(
          id: 'synthetic-science',
          grade: q.grade,
          subject: 'Sachunterricht',
          unit: q.unit,
          prompt: q.prompt,
          answer: q.answer,
          choices: [q.answer, ...q.choices.where((v) => v != q.answer)],
          explanation: q.explanation,
          difficulty: q.grade,
          visual: 'science');
      expect(guard.problems(task), isEmpty, reason: q.prompt);
      final actual = adapter.toTaskInstance(
          task: task, childId: 'synthetic', difficulty: q.grade);
      expect(actual.prompt, q.prompt);
      final correctOptions = actual.options.where((o) => o.payload == actual.correctAnswer);
      expect(correctOptions, hasLength(1));
      expect(correctOptions.single.label, q.answer);
      expect(signatures.add('${q.grade}|${q.prompt}'), isTrue);
    }
    expect(scienceExtensionQuestions.length, greaterThanOrEqualTo(80));
  });
  test('single-topic sessions avoid repeats even when a finite bank cycles',
      () {
    for (final subject in ['Mathematik', 'Lesen', 'Sachunterricht']) {
      final unit = {
        'Mathematik': 'Zeit',
        'Lesen': 'Reihenfolge',
        'Sachunterricht': 'Verkehr'
      }[subject]!;
      final f = ExerciseFactory(seed: 77);
      String? previous;
      final distinct = <String>{};
      for (var i = 0; i < 200; i++) {
        final t = f.next(grade: 1, subject: subject, unit: unit);
        final key = '${t.prompt}|${t.answer}';
        expect(key, isNot(previous), reason: '$subject $i');
        distinct.add(key);
        previous = key;
      }
      expect(
          distinct.length, greaterThanOrEqualTo(subject == 'Lesen' ? 24 : 8));
    }
  });
}
