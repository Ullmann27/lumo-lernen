import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_chart_data.dart';

final _now = DateTime(2026, 11, 25, 12);

Attempt _answer(String id, {
  String student = 'child-a',
  String subject = 'Mathematik',
  String competency = 'Muster',
  bool correct = true,
  DateTime? at,
  int? durationMs,
}) => Attempt(
  id: id,
  studentId: student,
  subject: subject,
  unit: 'Üben',
  competency: competency,
  correct: correct,
  at: at ?? _now.subtract(const Duration(hours: 1)),
  durationMs: durationMs,
);

LearningChartData _data(List<Attempt> attempts, {String student = 'child-a'}) =>
    LearningChartData.fromAttempts(attempts, studentId: student, now: _now);

void main() {
  test('Empty and unknown owners have no invented measurements', () {
    final empty = _data([]);
    expect(empty.total, 0);
    expect(empty.accuracy, isNull);
    expect(empty.competencies, isEmpty);
    expect(empty.weeks, hasLength(4));
    expect(empty.weeks.every((week) => week.subjects.isEmpty), isTrue);
    expect(_data([_answer('a')], student: '').total, 0);
    expect(_data([_answer('a')], student: 'child-b').total, 0);
  });

  test('Owner filtering precedes deduplication; assessments and future are excluded', () {
    final answer = _answer('same');
    final data = _data([
      _answer('same', student: 'child-b', correct: false),
      answer,
      answer,
      _answer('test', subject: 'IQ-Rätsel'),
      _answer('future', at: _now.add(const Duration(minutes: 1))),
      _answer(''),
      _answer('invalid-subject', subject: ''),
    ]);
    expect(data.total, 1);
    expect(data.correct, 1);
    expect(data.competencies.single.hasEnoughEvidence, isFalse);
  });

  test('Same competency in different subjects remains distinct', () {
    final data = _data([
      _answer('a', correct: false),
      _answer('b', subject: 'Deutsch'),
    ]);
    expect(data.competencies, hasLength(2));
    expect(data.competencies.singleWhere((c) => c.subject == 'Deutsch').accuracy, 1);
    expect(data.competencies.singleWhere((c) => c.subject == 'Mathematik').accuracy, 0);
  });

  test('Calendar windows preserve missing weeks and actual zero accuracy', () {
    final start = DateTime(2026, 10, 29);
    final data = _data([
      _answer('outside', at: start.subtract(const Duration(seconds: 1))),
      _answer('first', at: start),
      _answer('third', at: DateTime(2026, 11, 12), correct: false),
      _answer('last', at: _now.toUtc(), correct: false),
    ]);
    expect(data.total, 4);
    expect(data.weeks.map((week) => week.start),
        [start, DateTime(2026, 11, 5), DateTime(2026, 11, 12), DateTime(2026, 11, 19)]);
    expect(data.weeks[0].subjects['Mathematik']!.total, 1);
    expect(data.weeks[0].accuracyFor('Mathematik'), 1);
    expect(data.weeks[1].accuracyFor('Mathematik'), isNull);
    expect(data.weeks[2].accuracyFor('Mathematik'), 0);
    expect(data.weeks[3].accuracyFor('Mathematik'), 0);
  });

  test('Time does not change correctness and small samples stay explicit', () {
    final data = _data([
      for (var i = 0; i < 5; i++)
        _answer('$i', correct: i == 0, durationMs: i == 0 ? 900000 : 10),
    ]);
    expect(data.total, 5);
    expect(data.correct, 1);
    expect(data.accuracy, .2);
    expect(data.competencies.single.hasEnoughEvidence, isTrue);
  });

  test('Trend subjects come from the displayed period, not old lifetime counts', () {
    final data = _data([
      for (var i = 0; i < 8; i++)
        _answer('old-$i', subject: 'Deutsch', at: DateTime(2026, 9, 1)),
      _answer('current', subject: 'Sachunterricht'),
    ]);
    expect(data.total, 9);
    expect(data.subjects, ['Sachunterricht']);
    expect(data.competencies.first.subject, 'Deutsch');
  });

  test('Returned chart collections cannot mutate the source projection', () {
    final data = _data([_answer('a')]);
    expect(() => data.competencies.clear(), throwsUnsupportedError);
    expect(() => data.subjects.clear(), throwsUnsupportedError);
    expect(() => data.weeks.clear(), throwsUnsupportedError);
    expect(() => data.weeks.last.subjects.clear(), throwsUnsupportedError);
  });
}
