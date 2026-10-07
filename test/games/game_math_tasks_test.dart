import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/game_math_tasks.dart';

void main() {
  test('All 50 actual routes appear and unlock in curriculum order', () {
    final repo = GameProgressRepository();
    final initial = repo.buildRuntime({});
    expect(initial.length, 50);
    expect(initial.every((r) => r.level.miniType.isPlayable), isTrue);
    expect(initial.first.locked, isFalse);
    final after9 = repo.buildRuntime({9: 2});
    expect(after9.firstWhere((r) => r.level.id == 10).locked, isFalse);
    expect(after9.firstWhere((r) => r.level.id == 11).locked, isTrue);
    final after25 = repo.buildRuntime({25: 3});
    expect(after25.firstWhere((r) => r.level.id == 26).locked, isFalse);
    expect(after25.firstWhere((r) => r.level.id == 27).locked, isTrue);
  });

  test(
      'Every StarsPath level has correct answers matching its advertised operation',
      () {
    for (final level in GameLevelCatalog.playableLevels
        .where((l) => l.miniType == GameMiniType.starsPath)) {
      for (var i = 0; i < 40; i++) {
        final task = GameMathTasks.starsPath(level, i);
        expect(task.choices.toSet().length, task.choices.length);
        expect(task.choices.where((v) => v == task.answer).length, 1);
        expect(task.explanation, isNotEmpty);
        if ([4, 6].contains(level.id)) continue;
        final values = RegExp(r'\d+')
            .allMatches(task.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        expect(values.length, 2);
        final a = values[0], b = values[1];
        final subtract = [11, 12, 17, 45, 49].contains(level.id);
        final multiply = [41, 42, 46].contains(level.id);
        expect(
            int.parse(task.answer),
            subtract
                ? a - b
                : multiply
                    ? a * b
                    : a + b,
            reason: 'Level ${level.id}: ${task.prompt}');
        if (level.id == 1 || level.id == 11)
          expect(a + (subtract ? 0 : b), lessThanOrEqualTo(5));
        if (level.id == 3) expect(a + b, lessThanOrEqualTo(7));
        if ([16, 17].contains(level.id))
          expect(a + (subtract ? 0 : b), lessThanOrEqualTo(20));
        if ([39, 45].contains(level.id))
          expect(a + (subtract ? 0 : b), lessThanOrEqualTo(100));
        if (level.id == 41) expect(a, isIn([2, 5]));
        if (level.id == 42) expect(a, 3);
        if (level.id == 46) expect(a, isIn([10, 4]));
      }
    }
  });

  test(
      'Rechenhaus keeps fixed decomposition, crossing ten, doubling and cap100',
      () {
    for (final level in GameLevelCatalog.playableLevels
        .where((l) => l.miniType == GameMiniType.numberHouse)) {
      for (var i = 0; i < 60; i++) {
        final task = GameMathTasks.numberHouse(level, i);
        expect(task.answer + task.visibleRoom, task.roof);
        expect(task.choices.where((n) => n == task.answer).length, 1);
        if (level.id == 7) expect(task.roof, 7);
        if (level.id == 8) expect(task.roof, 9);
        if (level.id == 15) {
          expect(task.roof, greaterThan(10));
          expect(task.answer, lessThan(10));
          expect(task.visibleRoom, lessThan(10));
        }
        if ([19, 37].contains(level.id)) expect(task.answer, task.visibleRoom);
        if (level.id == 37) expect(task.roof, inInclusiveRange(20, 100));
      }
    }
  });

  test('Completion stars persist and never downgrade on a replay', () async {
    SharedPreferences.setMockInitialValues({});
    const repo = GameProgressRepository();
    await repo.recordResult(childId: 'test', levelId: 25, starsEarned: 3);
    await repo.recordResult(childId: 'test', levelId: 25, starsEarned: 1);
    expect((await repo.loadStars('test'))[25], 3);
    expect(
        repo
            .buildRuntime(await repo.loadStars('test'))
            .firstWhere((r) => r.level.id == 37)
            .locked,
        isFalse);
  });

  test('StarsPath written-arithmetic levels do not always put the answer first',
      () {
    for (final id in [48, 49]) {
      final level = GameLevelCatalog.playableLevels.firstWhere((l) => l.id == id);
      final positions = <int>{
        for (var i = 0; i < 20; i++)
          GameMathTasks.starsPath(level, i)
              .choices
              .indexOf(GameMathTasks.starsPath(level, i).answer),
      };
      expect(positions.contains(-1), isFalse, reason: 'level $id answer missing');
      expect(positions.length, greaterThan(1),
          reason: 'level $id always shows the answer at the same position');
    }
  });
}
