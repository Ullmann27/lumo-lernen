import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/scanned_work_analysis.dart';
import 'package:lumo_lernen/features/photo_lesson/photo_lesson_practice.dart';

ScannedWorkAnalysis analyze(String text, {int grade = 1}) =>
    const ScannedWorkAnalysisEngine().analyze(
      rawText: text,
      grade: grade,
      existingSkills: const <String, SkillRecord>{},
    );

void main() {
  test('recognized math preserves the successful template seed schedule', () {
    final analysis = analyze('Hausaufgabe: Rechne 4 + 5.');
    expect(analysis.subject, 'Mathematik');
    final practice = PhotoLessonPractice.generate(analysis: analysis, grade: 1, seed: 1200);
    expect(practice.notice, isEmpty);
    expect(practice.tasks, hasLength(5));
    for (var i = 0; i < 5; i++) {
      final previous = MathTaskTemplates.generate(
        grade: 1, unit: analysis.nextPracticeUnit, seed: 1200 + i * 7919,
      );
      final actual = practice.tasks[i];
      expect(actual.subject, 'Mathematik');
      expect(actual.prompt, previous.prompt);
      expect(actual.answer, previous.answer);
      expect(actual.choices, previous.choices);
      expect(actual.explanation, previous.explanation);
    }
  });

  for (final entry in <String, List<String>>{
    'Deutsch': ['Hausaufgabe: Silben klatschen.', 'Silben'],
    'Englisch': ['English: colour red blue green yellow.', 'Farben'],
    'Sachunterricht': ['Sachunterricht: Tiere Hund Katze Fisch.', 'Tiere'],
  }.entries) {
    test('${entry.key} OCR generates five exercises in the recognized subject/topic', () {
      final analysis = analyze(entry.value[0]);
      expect(analysis.subject, entry.key);
      final practice = PhotoLessonPractice.generate(analysis: analysis, grade: 1, seed: 1200);
      expect(practice.notice, isEmpty);
      expect(practice.tasks, hasLength(5));
      for (final task in practice.tasks) {
        expect(task.subject, entry.key);
        expect(task.unit, entry.value[1]);
        expect(task.prompt, isNotEmpty);
        expect(task.explanation, isNotEmpty);
        expect(task.choices, contains(task.answer));
      }
    });
  }

  test('unsupported science topic truthfully falls back within the same subject', () {
    final analysis = analyze('Hausaufgabe Sachunterricht.');
    expect(analysis.nextPracticeUnit, 'Forschen und Verstehen');
    final practice = PhotoLessonPractice.generate(analysis: analysis, grade: 1, seed: 1200);
    expect(practice.notice, contains('andere Themen aus Sachunterricht'));
    expect(practice.notice, contains(analysis.nextPracticeUnit));
    expect(practice.tasks, hasLength(5));
    for (final task in practice.tasks) {
      expect(task.subject, 'Sachunterricht');
      expect(task.unit, isNot(analysis.nextPracticeUnit));
      expect(task.choices, contains(task.answer));
    }
  });

  test('unsupported English topic cannot become random math', () {
    final analysis = analyze('English homework.');
    final practice = PhotoLessonPractice.generate(analysis: analysis, grade: 1, seed: 12);
    expect(practice.notice, contains('andere Themen aus Englisch'));
    expect(practice.tasks.every((task) => task.subject == 'Englisch'), isTrue);
  });

  test('unclear OCR does not silently select another subject', () {
    final analysis = analyze('qqq xyz abc');
    expect(analysis.subject, 'Unklar');
    final practice = PhotoLessonPractice.generate(analysis: analysis, grade: 1, seed: 12);
    expect(practice.tasks, isEmpty);
    expect(practice.notice, contains('Fach nicht sicher erkennen'));
  });
}
