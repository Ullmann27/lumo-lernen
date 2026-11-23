import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/logic/logic_games.dart';
import 'package:lumo_lernen/domain/logic/logic_learning_profile.dart';

LogicPuzzleResult _result(
  int level, {
  int grade = 2,
  String version = 'test-v1',
  String? sessionId,
  int? day,
  int hints = 0,
  int errors = 0,
  bool replay = false,
  bool revealed = false,
}) => LogicPuzzleResult(
  attemptId: 'attempt-$level',
  puzzleId: 'sudoku-$grade-$level-$version',
  contentVersion: version,
  kind: LogicGameKind.sudoku,
  grade: grade,
  level: level,
  sessionId: sessionId ?? 'visit-${level % 3}',
  startedAt: DateTime(2026, 11, day ?? 20 + level % 2, 10),
  completedAt: DateTime(2026, 11, day ?? 20 + level % 2, 10, 5),
  hints: hints,
  errors: errors,
  solutionRevealed: revealed,
  isReplay: replay,
);

LogicProgress _progress(Iterable<LogicPuzzleResult> results) => LogicProgress(
  profileId: 'child-a',
  selectedGrade: 2,
  results: {for (final result in results) result.puzzleId: result},
);

LogicSkillReport _report(LogicProgress progress) =>
    LogicLearningProfile.fromProgress(
      progress,
      grade: 2,
      contentVersion: 'test-v1',
    ).reports.firstWhere((report) => report.kind == LogicGameKind.sudoku);

void main() {
  test('unplayed areas are unobserved, never a low ability score', () {
    final profile = LogicLearningProfile.fromProgress(
      _progress([]),
      grade: 2,
      contentVersion: 'test-v1',
    );
    expect(profile.reports, hasLength(3));
    for (final report in profile.reports) {
      expect(report.stage, LogicEvidenceStage.exploring);
      expect(report.summary, contains('entdecken'));
    }
  });

  test('a single visit or single day cannot create a repeated observation', () {
    final sameVisit = _progress([
      for (var i = 1; i <= 8; i++) _result(i, sessionId: 'one-visit'),
    ]);
    final sameDay = _progress([
      for (var i = 1; i <= 8; i++) _result(i, day: 20),
    ]);
    expect(_report(sameVisit).stage, LogicEvidenceStage.exploring);
    expect(_report(sameDay).stage, LogicEvidenceStage.exploring);
  });

  test('different new puzzles across visits permit task-specific feedback', () {
    final report = _report(
      _progress([for (var i = 1; i <= 6; i++) _result(i)]),
    );
    expect(report.stage, LogicEvidenceStage.independent);
    expect(report.summary, contains('ohne Lumo-Hilfe'));
    expect(report.summary, isNot(contains('Intelligenz')));
    expect(report.distinctPuzzles, 6);
  });

  test(
    'help is not relabelled independent and mistakes are not personality',
    () {
      final helped = _report(
        _progress([for (var i = 1; i <= 6; i++) _result(i, hints: 1)]),
      );
      final corrected = _report(
        _progress([for (var i = 1; i <= 6; i++) _result(i, errors: 4)]),
      );
      expect(helped.stage, LogicEvidenceStage.practicing);
      expect(helped.summary, contains('geschafft'));
      expect(corrected.stage, LogicEvidenceStage.independent);
      expect(corrected.summary, isNot(contains('fehlerfrei')));
    },
  );

  test('replays and other grades or content versions are not pooled', () {
    final report = _report(
      _progress([
        _result(1),
        _result(2),
        _result(3, replay: true),
        _result(4, replay: true),
        _result(5, grade: 3),
        _result(6, grade: 3),
        _result(7, version: 'other-v2'),
        _result(8, version: 'other-v2'),
      ]),
    );
    expect(report.distinctPuzzles, 2);
    expect(report.stage, LogicEvidenceStage.exploring);
  });

  test(
    'highest-stage feedback requires independent completion of both stages',
    () {
      final strong = _progress([
        for (final i in [1, 2, 3, 4, 11, 12]) _result(i),
      ]);
      final assisted = _progress([
        for (final i in [1, 2, 3, 4, 11]) _result(i),
        _result(12, revealed: true),
      ]);
      expect(_report(strong).stage, LogicEvidenceStage.challenge);
      expect(_report(assisted).stage, LogicEvidenceStage.independent);
    },
  );

  test('guided success unlocks the next level, only in its own track', () {
    final progress = _progress([_result(1, hints: 3, revealed: true)]);
    expect(progress.isUnlocked(LogicGameKind.sudoku, 2, 2), isTrue);
    expect(progress.isUnlocked(LogicGameKind.words, 2, 2), isFalse);
    expect(progress.isUnlocked(LogicGameKind.sudoku, 1, 2), isFalse);
    expect(progress.isUnlocked(LogicGameKind.sudoku, 2, 3), isFalse);
    expect(progress.isUnlocked(LogicGameKind.sudoku, 2, 13), isFalse);
  });

  test('session evidence cannot be erased by a later draft snapshot', () {
    final session = LogicPuzzleSession(
      attemptId: 'a',
      puzzleId: 'p',
      contentVersion: 'v1',
      kind: LogicGameKind.sudoku,
      grade: 1,
      level: 1,
      sessionId: 's',
      startedAt: DateTime(2026, 11, 20),
      answers: {0: '1'},
      hints: 2,
      errors: 3,
      solutionRevealed: true,
    );
    final edited = session
        .copyWith(
          answers: {0: '2'},
          hints: 0,
          errors: 0,
          solutionRevealed: false,
        )
        .preservingEvidenceFrom(session);
    expect(edited.answers[0], '2');
    expect(edited.hints, 2);
    expect(edited.errors, 3);
    expect(edited.solutionRevealed, isTrue);
    expect(edited.revision, 1);
    final restored = LogicPuzzleSession.fromJson(edited.toJson());
    expect(restored.hints, 2);
    expect(restored.answers, {0: '2'});
  });

  test(
    'malformed progress is rejected instead of silently erasing evidence',
    () {
      final json = _progress([_result(1)]).toJson();
      json['selectedGrade'] = 9;
      expect(() => LogicProgress.fromJson(json), throwsFormatException);
      final identityMismatch = _progress([_result(1)]).toJson();
      identityMismatch['results'] = {'other-puzzle': _result(1).toJson()};
      expect(
        () => LogicProgress.fromJson(identityMismatch),
        throwsFormatException,
      );
    },
  );
}
