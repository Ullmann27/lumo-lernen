import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_evidence.dart';

void main() {
  const lesson = GuidedLessonCatalog.bridgeTen;
  final independent = lesson.steps[5];
  final check = lesson.steps[6];
  test(
    'different observed answer patterns choose specific, non-diagnostic hints',
    () {
      final hints = ['4', '2', '10']
          .map(
            (answer) => GuidedLessonEvidence.hintForAnswer(
              lesson: lesson,
              step: independent,
              answer: answer,
            ),
          )
          .toList();
      expect(hints.toSet().length, 3);
      expect(
        hints.every((h) => h != null && !h.contains(independent.expected)),
        isTrue,
      );
      expect(hints[0], contains('vollen Zehner auch'));
      expect(hints[1], contains('freien Plätze'));
      expect(hints[2], contains('Äpfel daneben'));
      expect(
        GuidedLessonEvidence.hintForAnswer(
          lesson: lesson,
          step: independent,
          answer: '9',
        ),
        isNull,
      );
    },
  );
  LearningEvidence answer(
    GuidedLessonStep step, {
    String? value,
    int attempts = 1,
    int help = 0,
    String id = 'attempt-1',
  }) => GuidedLessonEvidence.observation(
    lesson: lesson,
    step: step,
    attemptId: id,
    answer: value ?? step.expected,
    attempts: attempts,
    helpLevel: help,
  );

  test('a retry after feedback never becomes independent transfer', () {
    for (final help in [0, 1, 2, 3]) {
      final retried = answer(check, attempts: 2, help: help);
      expect(retried.correct, isTrue);
      expect(retried.helpLevel, greaterThan(0));
      expect(retried.transferCheck, isFalse);
    }
    final hinted = answer(check, help: 1);
    expect(hinted.transferCheck, isFalse);
    expect(hinted.helpLevel, 1);
  });

  test('only a genuine independent check creates transfer evidence', () {
    expect(answer(independent).transferCheck, isFalse);
    expect(answer(check).transferCheck, isTrue);
    expect(answer(check, value: '10').transferCheck, isFalse);
  });

  test('stores observed answer patterns without raw answer or diagnosis', () {
    expect(answer(independent, value: '4').errorTag, 'answer_equals_remainder');
    expect(
      answer(independent, value: '2').errorTag,
      'answer_equals_gap_to_ten',
    );
    expect(answer(independent, value: '10').errorTag, 'answer_stops_at_ten');
    expect(answer(independent, value: '9').errorTag, 'bridge_ten_other_answer');
    expect(answer(independent).errorTag, isNull);
  });

  test('verified transfer joins existing local review and survives reload', () {
    final day = DateTime.utc(2026, 11, 10);
    var journey = LearningJourney();
    void record(LearningEvidence evidence, DateTime time) {
      journey = journey.recordEvidence(
        subject: lesson.subject,
        unit: lesson.schoolUnit,
        evidence: evidence,
        now: time,
      );
    }

    record(answer(independent, id: 'first'), day);
    record(answer(check, id: 'check'), day);
    final saved = LearningJourney.fromJson(
      journey.toJson(),
    ).records.values.single;
    expect(saved.status, JourneyStatus.independentlyChecked);
    expect(saved.independentCorrect, 2);
    expect(saved.transferCorrect, 1);
    expect(saved.dueAt, day.add(const Duration(days: 1)));
    record(answer(check, id: 'later-check'), day.add(const Duration(days: 1)));
    expect(journey.records.values.single.status, JourneyStatus.retained);
    expect(
      journey.records.values.single.dueAt,
      day.add(const Duration(days: 4)),
    );
  });

  test(
    'assisted success remains practice, independent check cannot erase history',
    () {
      var journey = LearningJourney();
      for (final evidence in [
        answer(independent, value: '4', id: 'wrong'),
        answer(independent, attempts: 2, id: 'retry'),
        answer(check, id: 'check'),
      ]) {
        journey = journey.recordEvidence(
          subject: lesson.subject,
          unit: lesson.schoolUnit,
          evidence: evidence,
          now: DateTime.utc(2026, 11, 10),
        );
      }
      final record = journey.records.values.single;
      expect(record.status, JourneyStatus.practicing);
      expect(record.assistedCorrect, 1);
      expect(record.independentCorrect, 1);
      expect(record.errorCounts, {'answer_equals_remainder': 1});
    },
  );

  test('accompanied examples cannot be submitted as school evidence', () {
    expect(() => answer(lesson.steps[3]), throwsArgumentError);
    expect(() => answer(check, attempts: 0), throwsArgumentError);
  });
}
