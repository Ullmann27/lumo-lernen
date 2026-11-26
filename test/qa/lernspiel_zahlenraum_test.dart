import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/mini_game_learning_task.dart';

/// Lernspiel „Sterne sammeln“: Auch die falschen Karten bleiben im
/// Zahlenraum der Stufe. Früher zeigte „Minus bis 10“ (Stufe 12) Karten
/// bis 18 (z. B. 15 bei 8 − 7), „Plus bis 20“ bis 30 und „Plus bis 100“
/// bis 200 (Befund Team A1, Punkt 10).
void main() {
  // Zahlenraum laut Stufentitel. Schriftliches Rechnen (48, 49) nutzt die
  // gemeinsame Übungsvorlage und ist hier nicht erfasst.
  const ranges = <int, int>{
    1: 5, 3: 7, 4: 10, 6: 10, 9: 10, 11: 5, 12: 10, //
    16: 20, 17: 20, 39: 100, 41: 100, 42: 100, 45: 100, 46: 100,
  };

  test('jede Rechenpfad-Stufe ist erfasst', () {
    final ids = GameLevelCatalog.levels
        .where((l) => l.miniType == GameMiniType.starsPath)
        .map((l) => l.id)
        .where((id) => id != 48 && id != 49)
        .toSet();
    expect(ids, ranges.keys.toSet());
  });

  for (final entry in ranges.entries) {
    final level = GameLevelCatalog.levels.firstWhere((l) => l.id == entry.key);
    test('Stufe ${level.id} „${level.title}“: Karten 0 bis ${entry.value}', () {
      var shown = 0;
      for (var seed = 0; seed < 200; seed++) {
        for (final task in MiniGameLearningDeck.build(level, seed)) {
          expect(task.isValid, isTrue, reason: task.prompt);
          expect(task.choices, contains(task.answer));
          for (final card in task.choices) {
            final value = int.parse(card);
            expect(value, inInclusiveRange(0, entry.value),
                reason: '${task.prompt} zeigt die Karte $card');
            shown++;
          }
        }
      }
      expect(shown, greaterThan(200 * 4));
    });
  }

  test('„Minus bis 10“: 8 − 7 zeigt keine 15 mehr', () {
    final level = GameLevelCatalog.levels.firstWhere((l) => l.id == 12);
    expect(level.title, 'Minus bis 10');
    var seen = 0;
    for (var seed = 0; seed < 400; seed++) {
      for (final task in MiniGameLearningDeck.build(level, seed)) {
        if (!task.prompt.startsWith('8 − 7')) continue;
        seen++;
        expect(task.choices, isNot(contains('15')));
        expect(task.answer, '1');
      }
    }
    expect(seen, greaterThan(0), reason: '8 − 7 kam in 400 Runden nie vor');
  });
}
