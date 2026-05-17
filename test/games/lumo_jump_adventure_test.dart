import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/mini_games/lumo_jump_adventure_game.dart';

void main() {
  group('LumoJumpAdventure', () {
    test('daily seed is deterministic per UTC day', () {
      final morning = DateTime.utc(2026, 5, 17, 8, 0);
      final evening = DateTime.utc(2026, 5, 17, 22, 0);
      final nextDay = DateTime.utc(2026, 5, 18, 8, 0);

      expect(lumoJumpDailySeed(morning), lumoJumpDailySeed(evening));
      expect(lumoJumpDailySeed(nextDay), isNot(lumoJumpDailySeed(morning)));
    });

    test('generator creates child-safe solvable chunks with chest and question blocks', () {
      final level = generateLumoJumpAdventureLevel(seed: 2026137);

      expect(level.questionBlocks, hasLength(3));
      expect(level.chestRect.left, greaterThan(level.questionBlocks.last.rect.right));
      expect(level.obstacles, isNotEmpty);
      expect(
        level.obstacles.every((entry) =>
            entry.type == LumoJumpObstacleType.puddle ||
            entry.type == LumoJumpObstacleType.lowBranch ||
            entry.type == LumoJumpObstacleType.rollingLog),
        isTrue,
      );
      expect(level.chunks, isNotEmpty);
      expect(level.chunks.every((chunk) => chunk.isSolvable), isTrue);
    });

    test('wallet rewards increase current and total earned stars', () {
      final appState = LumoAppState();
      final initialStars = appState.state.stars;
      final initialTotal = appState.state.totalEarnedStars;

      appState.awardEarnedStars(55, message: 'Lumo gewinnt Sterne');

      expect(appState.state.stars, initialStars + 55);
      expect(appState.state.totalEarnedStars, initialTotal + 55);
    });
  });
}
