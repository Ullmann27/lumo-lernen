import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/cognitive_profile_generator.dart';
import 'package:lumo_lernen/core/cognitive_profile_repository.dart';
import 'package:lumo_lernen/core/cognitive_profile_scorer.dart';
import 'package:lumo_lernen/core/iq/iq_puzzle_generator.dart';
import 'package:lumo_lernen/core/iq/iq_puzzle_quality.dart';
import 'package:lumo_lernen/core/iq/iq_test_repository.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';
import 'package:shared_preferences/shared_preferences.dart';

CognitiveProfileResult _cognitive(String id, {String child = 'child-a'}) {
  final questions = CognitiveProfileGenerator.forGrade(2);
  return CognitiveProfileScorer.score(
      id: id,
      studentId: child,
      grade: 2,
      questions: questions,
      answers: {for (final q in questions) q.id: q.correctAnswer},
      finishedAt: DateTime(2026, 11, 15),
      durationMs: 1000);
}

IqTestResult _iq(String id, {String child = 'child-a'}) {
  final session = IqTestSession(grade: 2, seed: 27, itemsPerArea: 6);
  while (!session.finished) {
    final p = session.current;
    session.answer(
        switch (p) {
          IqChoicePuzzle p => [p.answer],
          IqMemoryPuzzle p => p.sequence,
        },
        durationMs: 1000);
  }
  return session.result(
      id: id,
      studentId: child,
      finishedAt: DateTime(2026, 11, 15),
      durationMs: 36000);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every cognitive answer is checked against the visible givens', () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final q in CognitiveProfileGenerator.forGrade(grade)) {
        expect(CognitiveProfileGenerator.problems(q), isEmpty, reason: q.id);
        final changed = CognitiveQuestion(
            id: q.id,
            grade: q.grade,
            domain: q.domain,
            prompt: q.prompt,
            choices: q.choices,
            correctAnswer:
                q.choices.firstWhere((choice) => choice != q.correctAnswer),
            explanation: q.explanation,
            difficulty: q.difficulty,
            stimulus: q.stimulus,
            stimulusVisibleMs: q.stimulusVisibleMs);
        expect(CognitiveProfileGenerator.problems(changed),
            contains('answer_not_supported_by_givens'),
            reason: q.id);
      }
    }
  });

  test('IQ rules reject a different stored answer at every level', () {
    final generator = IqPuzzleGenerator(Random(515));
    for (final area in IqArea.values) {
      for (var level = 1; level <= 8; level++) {
        final puzzle = generator.generate(area, level, '${area.name}-$level');
        expect(IqPuzzleQuality.problems(puzzle), isEmpty);
        final changed = switch (puzzle) {
          IqMatrixPuzzle p => IqMatrixPuzzle(
              id: p.id,
              level: p.level,
              question: p.question,
              explanation: p.explanation,
              answer: (p.answer + 1) % p.optionCount,
              columns: p.columns,
              cells: p.cells,
              options: p.options),
          IqSeriesPuzzle p => IqSeriesPuzzle(
              id: p.id,
              level: p.level,
              question: p.question,
              explanation: p.explanation,
              answer: (p.answer + 1) % p.optionCount,
              shown: p.shown,
              options: p.options),
          IqOddOnePuzzle p => IqOddOnePuzzle(
              id: p.id,
              level: p.level,
              question: p.question,
              explanation: p.explanation,
              answer: (p.answer + 1) % p.optionCount,
              figures: p.figures),
          IqRotationPuzzle p => IqRotationPuzzle(
              id: p.id,
              level: p.level,
              question: p.question,
              explanation: p.explanation,
              answer: (p.answer + 1) % p.optionCount,
              target: p.target,
              options: p.options,
              tint: p.tint),
          IqNumberPuzzle p => IqNumberPuzzle(
              id: p.id,
              level: p.level,
              question: p.question,
              explanation: p.explanation,
              answer: (p.answer + 1) % p.optionCount,
              numbers: p.numbers,
              options: p.options),
          IqMemoryPuzzle p => IqMemoryPuzzle(
              id: p.id,
              level: p.level,
              question: p.question,
              explanation: p.explanation,
              gridSize: p.gridSize,
              sequence: [...p.sequence, p.gridSize * p.gridSize],
              showMs: p.showMs,
              gapMs: p.gapMs),
        };
        expect(IqPuzzleQuality.problems(changed), isNotEmpty,
            reason: '${area.name}/$level');
      }
    }
  });

  test('unconfirmed input and stale submissions never change IQ performance',
      () {
    final session = IqTestSession(grade: 2, seed: 20);
    final first = session.current as IqChoicePuzzle;
    expect(() => session.answer([], durationMs: 0), throwsArgumentError);
    expect(() => session.answer([first.optionCount], durationMs: 0),
        throwsArgumentError);
    expect(session.index, 0);
    expect(session.records, isEmpty);
    session.answer([first.answer],
        durationMs: 40, expectedPuzzleId: first.id, expectedIndex: 0);
    expect(
        () => session.answer([first.answer],
            durationMs: 40, expectedPuzzleId: first.id, expectedIndex: 0),
        throwsStateError);
    expect(session.index, 1);
    expect(session.records, hasLength(1));
    expect(session.current.level, first.level + 1);
  });

  test('a cognitive profile requires confirmed valid choices', () {
    final questions = CognitiveProfileGenerator.forGrade(1);
    expect(
        () => CognitiveProfileScorer.score(
            id: 'incomplete',
            studentId: 'child',
            grade: 1,
            questions: questions,
            answers: const {},
            finishedAt: DateTime(2026),
            durationMs: 10),
        throwsArgumentError);
  });

  test('concurrent cognitive saves, retries and clear keep separate histories',
      () async {
    await Future.wait([
      for (var i = 0; i < 8; i++)
        const CognitiveProfileRepository().save(_cognitive('c-$i'))
    ]);
    await const CognitiveProfileRepository().save(_cognitive('c-0'));
    await const CognitiveProfileRepository()
        .save(_cognitive('other', child: 'child-b'));
    expect(await const CognitiveProfileRepository().loadAll('child-a'),
        hasLength(8));
    expect(await const CognitiveProfileRepository().loadAll('child-b'),
        hasLength(1));
    final saving =
        const CognitiveProfileRepository().save(_cognitive('before-clear'));
    final clearing = const CognitiveProfileRepository().clear('child-a');
    await Future.wait([saving, clearing]);
    expect(
        await const CognitiveProfileRepository().loadAll('child-a'), isEmpty);
    expect(await const CognitiveProfileRepository().loadAll('child-b'),
        hasLength(1));
  });

  test('concurrent IQ saves are idempotent and do not overwrite another child',
      () async {
    await Future.wait([
      for (var i = 0; i < 8; i++) const IqTestRepository().save(_iq('q-$i'))
    ]);
    await const IqTestRepository().save(_iq('q-0'));
    await const IqTestRepository().save(_iq('other', child: 'child-b'));
    final history = await const IqTestRepository().loadAll('child-a');
    expect(history, hasLength(8));
    expect(history.every((r) => r.total == 36 && r.solved == 36), isTrue);
    expect(await const IqTestRepository().loadAll('child-b'), hasLength(1));
  });

  test('unreadable histories are retained instead of overwritten by a save',
      () async {
    SharedPreferences.setMockInitialValues({
      'lumo.cognitive_profile.v1.child-a': 'corrupt existing history',
      'lumo.iq_test.v1.child-a': 'corrupt existing history',
    });
    await expectLater(
        const CognitiveProfileRepository().save(_cognitive('new')),
        throwsFormatException);
    await expectLater(
        const IqTestRepository().save(_iq('new')), throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo.cognitive_profile.v1.child-a'),
        'corrupt existing history');
    expect(
        prefs.getString('lumo.iq_test.v1.child-a'), 'corrupt existing history');
  });
}
