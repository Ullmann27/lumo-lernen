import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/games/mini_games/game_task_factory.dart';

void main() {
  group('GameTaskFactory', () {
    test('maps representative level titles to fitting units', () {
      expect(
        GameTaskFactory.resolveMathUnit(GameLevelCatalog.byId(13)!, grade: 1),
        'Zahlenstrahl',
      );
      expect(
        GameTaskFactory.resolveMathUnit(GameLevelCatalog.byId(48)!, grade: 4),
        'Schriftliche Addition',
      );
      expect(
        GameTaskFactory.resolveGermanUnit(GameLevelCatalog.byId(22)!),
        'Endlaute',
      );
      expect(
        GameTaskFactory.resolveGermanUnit(GameLevelCatalog.byId(25)!),
        'Wort-Bild schreiben',
      );
    });

    test('can generate stable playable tasks for every catalog level', () {
      for (final level in GameLevelCatalog.levels) {
        final task = GameTaskFactory.generate(
          level: level,
          appGrade: level.gradeFloor,
          seed: level.id * 97,
        );
        expect(task.prompt.trim(), isNotEmpty, reason: 'Level ${level.id}');
        expect(task.answer.trim(), isNotEmpty, reason: 'Level ${level.id}');
        expect(task.choices, contains(task.answer), reason: 'Level ${level.id}');
        expect(task.choices.toSet().length, task.choices.length, reason: 'Level ${level.id}');
      }
    });
  });
}
