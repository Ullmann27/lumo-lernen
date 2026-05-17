import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/weekly_challenge.dart';

void main() {
  group('WeeklyChallengeCatalog', () {
    test('liefert 4 verschiedene Sets', () {
      expect(WeeklyChallengeCatalog.sets.length, 4);
      final ids = WeeklyChallengeCatalog.sets.map((s) => s.id).toSet();
      expect(ids.length, 4, reason: 'IDs muessen eindeutig sein');
    });

    test('jedes Set hat 5+ Levels', () {
      for (final set in WeeklyChallengeCatalog.sets) {
        expect(set.levels.length, greaterThanOrEqualTo(5));
      }
    });

    test('alle referenzierten Level-IDs existieren im GameLevelCatalog', () {
      for (final set in WeeklyChallengeCatalog.sets) {
        for (final ref in set.levels) {
          final level = GameLevelCatalog.byId(ref.catalogLevelId);
          expect(level, isNotNull,
              reason: 'Set ${set.id} referenziert nichtexistierendes Level ${ref.catalogLevelId}');
        }
      }
    });

    test('weekModulo deckt 0..n-1 ab (rotiert sauber)', () {
      final modulos = WeeklyChallengeCatalog.sets.map((s) => s.weekModulo).toSet();
      for (var i = 0; i < WeeklyChallengeCatalog.sets.length; i++) {
        expect(modulos.contains(i), true, reason: 'Modulo $i fehlt');
      }
    });

    test('isoWeekOfYear liefert sinnvolle Werte', () {
      final jan1 = DateTime(2026, 1, 1);
      final dec31 = DateTime(2026, 12, 31);
      expect(WeeklyChallengeCatalog.isoWeekOfYear(jan1), inInclusiveRange(1, 2));
      expect(WeeklyChallengeCatalog.isoWeekOfYear(dec31), inInclusiveRange(52, 54));
    });

    test('activeFor liefert immer ein gueltiges Set', () {
      for (var month = 1; month <= 12; month++) {
        final d = DateTime(2026, month, 15);
        final set = WeeklyChallengeCatalog.activeFor(d);
        expect(WeeklyChallengeCatalog.sets.contains(set), true);
      }
    });

    test('Plus-Woche hat keine Multiplikation', () {
      final plusWeek = WeeklyChallengeCatalog.sets.firstWhere((s) => s.id == 'week_addition_focus');
      for (final ref in plusWeek.levels) {
        final level = GameLevelCatalog.byId(ref.catalogLevelId)!;
        expect(level.title.toLowerCase().contains('einmaleins'), false);
      }
    });
  });
}
