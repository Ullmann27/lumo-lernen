import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/writing/expanded_writing_template_repository.dart';
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

  // Fachprüfung 2026-11 (D-M18): Schreiben steigt jetzt mit der Klasse.
  // Der alte Test verlangte in allen Klassen Großbuchstaben A–Z und Zahlen
  // 0–20; jetzt gilt: einzelne Zeichen nur mit echter Spurvorlage, ab
  // Klasse 2 Kleinbuchstaben/Zahlwörter, ab Klasse 3 Wörter und Sätze.
  test('writing target matches the chosen activity and grows with the grade',
      () {
    const repository = ExpandedWritingTemplateRepository();
    final factory = ExerciseFactory(seed: 33);
    for (var grade = 1; grade <= 4; grade++) {
      final letterTargets = <String>{};
      for (var i = 0; i < 40; i++) {
        final letter = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Buchstaben nachspuren');
        final target = WritingTargetParser.parse(letter.prompt);
        letterTargets.add(target);
        if (grade <= 2) {
          expect(target, hasLength(1), reason: letter.prompt);
          expect(repository.findOrFallback(target).strokes, isNotEmpty,
              reason: letter.prompt);
        } else {
          expect(target.length, greaterThan(1), reason: letter.prompt);
        }
        final number = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Zahlen schreiben');
        final numberTarget = WritingTargetParser.parse(number.prompt);
        if (grade == 1) {
          expect(int.parse(numberTarget), inInclusiveRange(0, 20));
        } else {
          expect(numberTarget, matches(RegExp(r'^[a-zäöüß]+$')),
              reason: number.prompt);
        }
        final sentence = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Satz abschreiben');
        final sentenceTarget = WritingTargetParser.parse(sentence.prompt);
        expect(sentenceTarget.split(' ').length, greaterThanOrEqualTo(2));
        if (grade == 3) expect(sentenceTarget.length, lessThanOrEqualTo(40));
      }
      if (grade == 1) {
        expect(letterTargets.any((t) => RegExp(r'^[A-Z]$').hasMatch(t)),
            isTrue);
        expect(letterTargets.any((t) => RegExp(r'^[a-z]$').hasMatch(t)),
            isTrue);
      }
      // Schwungübungen zeigen echte Buchstaben statt der alten Wellenlinie ∿
      // aus dem veralteten Symboltraining.
      for (var n = 0; n < 30; n++) {
        final curve = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Schwunguebung');
        final target = WritingTargetParser.parse(curve.prompt);
        expect(curve.prompt, isNot(contains('∿')));
        if (grade <= 2) {
          expect(repository.findOrFallback(target).strokes, isNotEmpty,
              reason: curve.prompt);
        } else {
          expect(target.length, greaterThan(1));
        }
      }
    }
    final grade4Sentences = <String>{
      for (var i = 0; i < 80; i++)
        WritingTargetParser.parse(factory
            .next(grade: 4, subject: 'Schreiben', unit: 'Satz abschreiben')
            .prompt),
    };
    expect(grade4Sentences.any((s) => s.contains('„')), isTrue);
    expect(grade4Sentences.any((s) => s.contains(',')), isTrue);
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
