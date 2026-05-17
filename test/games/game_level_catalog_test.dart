import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';

void main() {
  group('GameLevelCatalog', () {
    test('liefert genau 50 Level', () {
      expect(GameLevelCatalog.levels.length, 50);
    });

    test('Level-IDs sind aufsteigend von 1 bis 50', () {
      for (var i = 0; i < 50; i++) {
        expect(GameLevelCatalog.levels[i].id, i + 1);
      }
    });

    test('Block 1 (Level 1-10) ist Klasse 1 ohne Multiplikation', () {
      for (var i = 0; i < 10; i++) {
        final level = GameLevelCatalog.levels[i];
        expect(level.gradeFloor, 1, reason: 'Level ${level.id} sollte Klasse 1 sein');
        expect(level.title.toLowerCase().contains('einmaleins'), false,
            reason: 'Level ${level.id} darf keine Multiplikation in Klasse 1 sein');
      }
    });

    test('Schwierigkeit steigt: gradeFloor von Level 50 >= Level 1', () {
      expect(
        GameLevelCatalog.levels.last.gradeFloor,
        greaterThanOrEqualTo(GameLevelCatalog.levels.first.gradeFloor),
      );
    });

    test('byId liefert korrektes Level oder null', () {
      expect(GameLevelCatalog.byId(1)?.id, 1);
      expect(GameLevelCatalog.byId(50)?.id, 50);
      expect(GameLevelCatalog.byId(0), isNull);
      expect(GameLevelCatalog.byId(51), isNull);
    });

    test('blockOf gruppiert Level in 5 Bloecke a 10', () {
      expect(GameLevelCatalog.blockOf(1), 1);
      expect(GameLevelCatalog.blockOf(10), 1);
      expect(GameLevelCatalog.blockOf(11), 2);
      expect(GameLevelCatalog.blockOf(20), 2);
      expect(GameLevelCatalog.blockOf(30), 3);
      expect(GameLevelCatalog.blockOf(40), 4);
      expect(GameLevelCatalog.blockOf(50), 5);
    });

    test('Alle Level haben gueltige Lernziele', () {
      for (final level in GameLevelCatalog.levels) {
        expect(level.learningGoal.isNotEmpty, true);
        expect(level.title.isNotEmpty, true);
        expect(level.maxStars, inInclusiveRange(1, 3));
      }
    });

    test('Block-Endpunkte (Level 10, 20, 30, 40, 50) sind Mix-Quiz mit 3 Sternen', () {
      for (final endId in <int>[10, 20, 30, 40, 50]) {
        final l = GameLevelCatalog.byId(endId)!;
        expect(l.miniType, GameMiniType.mixedQuiz, reason: 'Level $endId sollte Mix-Quiz sein');
        expect(l.maxStars, 3, reason: 'Level $endId Block-Test sollte 3 Sterne haben');
      }
    });
  });
}
