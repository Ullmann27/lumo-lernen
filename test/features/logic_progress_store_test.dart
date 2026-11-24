import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/domain/logic/logic_games.dart';
import 'package:lumo_lernen/domain/logic/logic_learning_profile.dart';
import 'package:lumo_lernen/features/games/logic/logic_progress_store.dart';

Map<int, String> _solution(LogicPuzzle puzzle) => {
      for (final cell in puzzle.cells)
        if (cell.editable) cell.index: cell.answer,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = LogicProgressStore();
  late LogicPuzzle puzzle;
  final start = DateTime(2026, 11, 23, 10);

  Future<LogicPuzzleSession> begin(String profileId) => store.begin(
        profileId: profileId,
        puzzle: puzzle,
        sessionId: 'visit-one',
        now: start,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    puzzle = LogicCatalog.puzzle(LogicGameKind.sudoku, 1, 1);
  });

  test(
    'drafts and selected school grade stay with the captured child',
    () async {
      var session = await begin('child-a');
      final index = puzzle.cells.firstWhere((c) => c.editable).index;
      session = session.copyWith(answers: {index: puzzle.cells[index].answer});
      await store.saveSession('child-a', session);
      await store.setGrade('child-a', 3);
      final a = await store.load('child-a');
      final b = await store.load('child-b');
      expect(a.selectedGrade, 3);
      expect(a.drafts[puzzle.id]?.answers, session.answers);
      expect(b.drafts, isEmpty);
      expect(b.results, isEmpty);
      expect(b.selectedGrade, 1);
    },
  );

  test(
    'resume keeps answers, help and original visit through a new store',
    () async {
      final session = (await begin('child-a')).copyWith(
        answers: _solution(puzzle),
        hints: 2,
        errors: 1,
        solutionRevealed: true,
      );
      await store.saveSession('child-a', session);
      const restoredStore = LogicProgressStore();
      final resumed = await restoredStore.begin(
        profileId: 'child-a',
        puzzle: puzzle,
        sessionId: 'a-new-visit',
        now: start.add(const Duration(days: 1)),
      );
      expect(resumed.attemptId, session.attemptId);
      expect(resumed.sessionId, 'visit-one');
      expect(resumed.hints, 2);
      expect(resumed.errors, 1);
      expect(resumed.solutionRevealed, isTrue);
      expect(resumed.answers, session.answers);
    },
  );

  test(
    'old async saves cannot erase hints or overwrite a newer grid',
    () async {
      final original = await begin('child-a');
      final older = original.copyWith(hints: 1);
      final newer = older.copyWith(answers: _solution(puzzle), hints: 2);
      await store.saveSession('child-a', newer);
      await store.saveSession('child-a', older);
      final restored = (await store.load('child-a')).drafts[puzzle.id]!;
      expect(restored.hints, 2);
      expect(restored.answers, _solution(puzzle));
    },
  );

  test('incomplete puzzles cannot be marked completed', () async {
    final session = await begin('child-a');
    await expectLater(
      store.complete('child-a', session, puzzle: puzzle, now: start),
      throwsStateError,
    );
    expect((await store.load('child-a')).results, isEmpty);
  });

  test(
    'first completion is idempotent and delayed saving cannot reopen it',
    () async {
      final session = (await begin(
        'child-a',
      ))
          .copyWith(answers: _solution(puzzle));
      final first = await store.complete(
        'child-a',
        session,
        puzzle: puzzle,
        now: start.add(const Duration(minutes: 4)),
      );
      final second = await store.complete(
        'child-a',
        session,
        puzzle: puzzle,
        now: start.add(const Duration(minutes: 5)),
      );
      await store.saveSession('child-a', session);
      expect(first.results, hasLength(1));
      expect(second.results, hasLength(1));
      expect(
        second.results[puzzle.id]!.completedAt,
        first.results[puzzle.id]!.completedAt,
      );
      expect((await store.load('child-a')).drafts, isEmpty);
    },
  );

  test(
    'a replay never turns an assisted first completion into independent evidence',
    () async {
      final assisted = (await begin(
        'child-a',
      ))
          .copyWith(answers: _solution(puzzle), hints: 2);
      await store.complete(
        'child-a',
        assisted,
        puzzle: puzzle,
        now: start.add(const Duration(minutes: 4)),
      );
      final replay = (await begin(
        'child-a',
      ))
          .copyWith(answers: _solution(puzzle));
      expect(replay.isReplay, isTrue);
      final progress = await store.complete(
        'child-a',
        replay,
        puzzle: puzzle,
        now: start.add(const Duration(minutes: 6)),
      );
      expect(progress.results, hasLength(1));
      expect(progress.results[puzzle.id]!.hints, 2);
      expect(progress.results[puzzle.id]!.independent, isFalse);
      expect(progress.isUnlocked(LogicGameKind.sudoku, 1, 2), isTrue);
      await store.complete(
        'child-a',
        replay,
        puzzle: puzzle,
        now: start.add(const Duration(minutes: 7)),
      );
      await store.saveSession('child-a', replay);
      expect((await store.load('child-a')).drafts, isEmpty);
    },
  );

  test(
    'restarting an unfinished puzzle preserves help and marks repetition',
    () async {
      final helped = (await begin('child-a')).copyWith(hints: 1);
      await store.saveSession('child-a', helped);
      final restarted = await store.begin(
        profileId: 'child-a',
        puzzle: puzzle,
        sessionId: 'visit-two',
        now: start.add(const Duration(hours: 1)),
        restart: true,
      );
      expect(restarted.attemptId, isNot(helped.attemptId));
      expect(restarted.hints, 1);
      expect(restarted.isReplay, isTrue);
      await expectLater(store.saveSession('child-a', helped), throwsStateError);
    },
  );

  test(
    'queued writes from separate store objects retain both changes',
    () async {
      final session = (await begin('child-a')).copyWith(hints: 1);
      const other = LogicProgressStore();
      await Future.wait([
        store.saveSession('child-a', session),
        other.setGrade('child-a', 4),
      ]);
      final progress = await store.load('child-a');
      expect(progress.selectedGrade, 4);
      expect(progress.drafts[puzzle.id]!.hints, 1);
    },
  );

  test(
    'corrupt bytes are retained for recovery instead of overwritten',
    () async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'lumo.logic_progress.v1.child-a';
      await prefs.setString(key, '{broken');
      await expectLater(store.load('child-a'), throwsFormatException);
      await expectLater(store.setGrade('child-a', 2), throwsFormatException);
      expect(prefs.getString(key), '{broken');
    },
  );
}
