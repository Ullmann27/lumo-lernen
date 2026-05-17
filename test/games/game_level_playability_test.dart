import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/game_level_playability.dart';

void main() {
  group('GameLevelPlayability', () {
    test('liefert fuer jedes Level eine stabile Route', () {
      for (final level in GameLevelCatalog.levels) {
        final route = GameLevelPlayability.routeFor(level);
        expect(route, isNotNull, reason: 'Level ${level.id} hat keine Route');
      }
    });

    test('numberHouse-Level bleiben bei numberHouse', () {
      final numberHouseLevels = GameLevelCatalog.levels
          .where((level) => level.miniType == GameMiniType.numberHouse);
      for (final level in numberHouseLevels) {
        expect(
          GameLevelPlayability.routeFor(level),
          GamePlayRoute.numberHouse,
          reason: 'Level ${level.id} muss NumberHouse bleiben',
        );
      }
    });

    test('alle anderen Mini-Typen sind spielbar ueber starsPath', () {
      final routedToStarsPath = GameLevelCatalog.levels
          .where((level) => level.miniType != GameMiniType.numberHouse);
      for (final level in routedToStarsPath) {
        expect(
          GameLevelPlayability.routeFor(level),
          GamePlayRoute.starsPath,
          reason: 'Level ${level.id} (${level.miniType}) sollte spielbar sein',
        );
      }
    });
  });
}
