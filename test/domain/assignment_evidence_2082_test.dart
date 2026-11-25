import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';

void main() {
  final created = DateTime(2026, 11, 25, 9);
  final now = DateTime(2026, 11, 25, 12);
  Assignment assignment({int count = 3, String? child}) => Assignment(
    id: 'homework',
    classId: 'class',
    targetKind: child == null
        ? AssignmentTargetKind.wholeClass
        : AssignmentTargetKind.student,
    targetId: child,
    subject: 'Mathematik',
    unit: 'Plus bis 20',
    title: 'Plus üben',
    taskCount: count,
    createdAt: created,
  );
  Attempt answer(String id, {
    String child = 'a',
    String subject = 'Mathematik',
    String unit = 'Plus bis 20',
    bool correct = true,
    bool hint = false,
    int minutes = 1,
    int? durationMs,
  }) => Attempt(
    id: id, studentId: child, subject: subject, unit: unit,
    competency: 'Addition', correct: correct, hintUsed: hint,
    at: created.add(Duration(minutes: minutes)), durationMs: durationMs,
    prompt: '8 + 5', given: correct ? '13' : '12', expected: '13',
  );

  test('Nur eindeutige eigene Antworten im Zeitraum und Thema zählen', () {
    final first = answer('first');
    final result = AssignmentProgress.of(assignment(), [
      first, first,
      answer('second', correct: false, minutes: 2),
      answer('other-child', child: 'b'),
      answer('other-subject', subject: 'Deutsch'),
      answer('other-unit', unit: 'Minus bis 20'),
      answer('before', minutes: -1),
      answer('future', minutes: 181),
      answer(''),
    ], studentId: 'a', now: now);
    expect((result.done, result.correct), (2, 1));
    expect(result.answers.map((a) => a.id), ['first', 'second']);
    expect(result.completed, isFalse);
  });

  test('Ergebnis bleibt an die ersten Zielaufgaben gebunden', () {
    final result = AssignmentProgress.of(assignment(count: 2), [
      answer('late', minutes: 3),
      answer('first', correct: false),
      answer('second', minutes: 2),
    ], studentId: 'a', now: now);
    expect((result.done, result.correct), (2, 1));
    expect(result.completed, isTrue);
    expect(result.fraction, 1);
    expect(result.answers.map((a) => a.id), ['first', 'second']);
    expect(() => result.answers.add(answer('extra')), throwsUnsupportedError);
  });

  test('Hilfen zählen als Arbeit, aber nicht als selbstständige Leistung', () {
    final result = AssignmentProgress.of(assignment(), [
      answer('one', hint: true),
      answer('two', correct: false, minutes: 2),
      answer('three', minutes: 3),
    ], studentId: 'a', now: now);
    expect((result.done, result.correct), (3, 2));
    expect((result.guided, result.independent, result.independentCorrect),
        (1, 2, 1));
    expect(result.completed, isTrue);
  });

  test('Bearbeitungsdauer ändert keine Antwortbewertung', () {
    final fast = AssignmentProgress.of(assignment(), [
      answer('one', durationMs: 100),
    ], studentId: 'a', now: now);
    final slow = AssignmentProgress.of(assignment(), [
      answer('one', durationMs: 3600000),
    ], studentId: 'a', now: now);
    expect((fast.done, fast.correct, fast.independentCorrect),
        (slow.done, slow.correct, slow.independentCorrect));
  });

  test('Gemischte ungebundene Profile werden niemals aufsummiert', () {
    expect(AssignmentProgress.of(assignment(), [
      answer('one'), answer('two', child: 'b'),
    ], now: now).done, 0);
    expect(AssignmentProgress.of(assignment(child: 'a'), [
      answer('one'), answer('two', child: 'b'),
    ], studentId: 'b', now: now).done, 0);
    expect(AssignmentProgress.of(assignment(child: 'a'), [
      answer('one'), answer('two', child: 'b'),
    ], now: now).done, 1);
  });

  test('Leere Daten und ungültige Aufgabenanzahl behaupten keinen Abschluss', () {
    for (final count in [0, -1, 3]) {
      final result = AssignmentProgress.of(assignment(count: count), [],
          studentId: 'a', now: now);
      expect(result.completed, isFalse);
      expect(result.fraction, 0);
    }
  });
}
