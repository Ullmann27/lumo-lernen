import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/core/writing_target_parser.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';

void main() {
  const guard = TaskQualityGuard();
  const adapter = LegacyLumoTaskAdapter();

  test(
      'all listed non-math/German tasks survive actual validation without relabelling',
      () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final subject in [
        'Rechtschreibung',
        'Schreiben',
        'Lesen',
        'Englisch'
      ]) {
        for (final unit in Curriculum.unitsForGrade(subject, grade)) {
          for (var seed = 0; seed < 20; seed++) {
            final task = ExerciseFactory(seed: seed)
                .next(grade: grade, subject: subject, unit: unit);
            final label = '$grade/$subject/$unit seed=$seed';
            expect(guard.problems(task), isEmpty,
                reason: '$label ${task.prompt} ${task.choices}');
            final checked = adapter.qualityCheckedTask(task);
            expect(checked.subject, subject, reason: label);
            expect(checked.unit, unit, reason: label);
            expect(checked.prompt, task.prompt, reason: label);
            expect(checked.answer, task.answer, reason: label);
            expect(checked.choices, task.choices, reason: label);
            expect(task.choices, contains(task.answer), reason: label);
            if (!task.handwriting) {
              expect(task.choices.length, greaterThanOrEqualTo(3),
                  reason: label);
            }
          }
        }
      }
    }
  });

  test('English is a first-class adaptive subject', () {
    final task = ExerciseFactory(seed: 7)
        .next(grade: 4, subject: 'Englisch', unit: 'Wetter');
    final instance = adapter.toTaskInstance(
      task: task,
      childId: 'english-grade-4',
      difficulty: 3,
    );
    expect(instance.subject, LearningSubject.englisch);
    expect(instance.prompt, isNotEmpty);
    expect(instance.options, isNotEmpty);
  });

  test(
      'Austrian primary subject framework exposes foreign language in grades 3 and 4',
      () {
    expect(
      Curriculum.officialSubjectsForGrade(2),
      contains('Lebende Fremdsprache (verbindliche Übung)'),
    );
    expect(
      Curriculum.officialSubjectsForGrade(4),
      contains('Lebende Fremdsprache'),
    );
    expect(
      Curriculum.officialSubjectsForGrade(4),
      containsAll(<String>[
        'Deutsch',
        'Sachunterricht',
        'Mathematik',
        'Musik',
        'Kunst und Gestaltung',
        'Technik und Design',
        'Bewegung und Sport',
      ]),
    );
  });

  test('first-grade English school supplies stay within school supplies', () {
    const schoolWords = [
      'Buch',
      'Stift',
      'Tasche',
      'Lineal',
      // Fachprüfung 2026-11 (E-M4): pen = Stift, desk = Schultisch.
      'Radiergummi',
      'Schultasche',
      'Schultisch',
      'Sessel',
      'Federpennal',
      'Papier'
    ];
    final observed = <String>{};
    for (var seed = 0; seed < 400; seed++) {
      final task = ExerciseFactory(seed: seed)
          .next(grade: 1, subject: 'Englisch', unit: 'Schulsachen');
      observed.add(task.answer);
      expect(schoolWords, contains(task.answer));
      expect(task.choices.every(schoolWords.contains), isTrue);
    }
    expect(observed.length, greaterThanOrEqualTo(10));
  });

  test('unknown English units honestly report the topic actually generated',
      () {
    final task = ExerciseFactory(seed: 22)
        .next(grade: 1, subject: 'Englisch', unit: 'unbekannt');
    expect(task.unit, isNot('unbekannt'));
    expect(Curriculum.subjects['Englisch'], contains(task.unit));
  });

  test(
      'reading tasks contain their evidence and never ask about an absent picture',
      () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final unit in Curriculum.subjects['Lesen']!) {
        final task = ExerciseFactory(seed: 13)
            .next(grade: grade, subject: 'Lesen', unit: unit);
        expect(task.prompt, isNot(contains('Welcher Artikel')));
        expect(task.prompt, isNot(contains('ist im Bild')));
        if (unit == 'Bild und Wort') {
          expect(task.prompt, startsWith('Schau genau:'));
        }
        if (unit == 'Reihenfolge') {
          expect(task.prompt, contains('Was passiert'));
        }
      }
    }
  });

  test('writing target matches the chosen activity and available number range',
      () {
    final factory = ExerciseFactory(seed: 33);
    for (var grade = 1; grade <= 4; grade++) {
      for (var i = 0; i < 25; i++) {
        final letter = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Buchstaben nachspuren');
        expect(WritingTargetParser.parse(letter.prompt),
            matches(RegExp(r'^[A-Z]$')));
        final number = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Zahlen schreiben');
        expect(int.parse(WritingTargetParser.parse(number.prompt)),
            inInclusiveRange(0, 20));
        final sentence = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Satz abschreiben');
        expect(WritingTargetParser.parse(sentence.prompt).split(' ').length,
            greaterThanOrEqualTo(2));
      }
      // Schwungübungen zeigen jetzt echte Buchstaben statt der alten
      // Wellenlinie ∿ aus dem veralteten Symboltraining.
      for (var n = 0; n < 30; n++) {
        final curve = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Schwunguebung');
        expect(WritingTargetParser.parse(curve.prompt),
            anyOf('S', 'C', 'O', 'U'));
        expect(curve.prompt, isNot(contains('∿')));
      }
    }
  });

  // Fachprüfung 2026-11 (D-M10): Früher war die Lösung immer „Großer
  // Anfang: …“. Jetzt sucht das Kind das Namenwort in einem Satz.
  test(
      'capitalization asks for the noun inside a sentence, without fillers',
      () {
    final factory = ExerciseFactory(seed: 11);
    final positions = <int>{};
    for (var i = 0; i < 200; i++) {
      final task = factory.next(
          grade: 1, subject: 'Rechtschreibung', unit: 'Gross und klein');
      if (!task.prompt.startsWith('Welches Wort muss groß')) continue;
      final sentence = RegExp('„(.+)“').firstMatch(task.prompt)!.group(1)!;
      final words = sentence.replaceAll(RegExp('[.?]'), '').split(' ');
      expect(task.choices, hasLength(3), reason: task.prompt);
      for (final choice in task.choices) {
        expect(words, contains(choice), reason: '$choice / $sentence');
      }
      expect(task.answer, task.answer.toLowerCase());
      expect(task.explanation,
          contains('${task.answer[0].toUpperCase()}${task.answer.substring(1)}'));
      positions.add(words.indexOf(task.answer));
      expect(
          task.choices.any(['ja', 'nein', 'vielleicht', 'anderes'].contains),
          isFalse);
    }
    expect(positions.length, greaterThanOrEqualTo(3),
        reason: 'Das Namenwort soll nicht immer an derselben Stelle stehen.');
  });

  test('Dehnungen and Wortende teach their named spelling pattern', () {
    final factory = ExerciseFactory(seed: 45);
    for (var i = 0; i < 400; i++) {
      final dehnung =
          factory.next(grade: 2, subject: 'Rechtschreibung', unit: 'Dehnungen');
      expect(
          dehnung.answer.contains('h') ||
              dehnung.answer.contains('ie') ||
              dehnung.answer.contains('aa') ||
              dehnung.answer.contains('ee') ||
              dehnung.answer.contains('oo'),
          isTrue);
      final ending =
          factory.next(grade: 2, subject: 'Rechtschreibung', unit: 'Wortende');
      expect(ending.prompt, startsWith('Verlängere das Wort:'));
      expect(ending.answer.length, 1);
    }
  });
}
