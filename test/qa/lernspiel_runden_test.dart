import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/mini_game_learning_task.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';

/// Lernspiele: Jede Runde passt zum Fach der Spielstufe, wiederholt keine
/// Aufgabe und unterscheidet sich zwischen Runden. Früher war jede Runde
/// einer Rechenstufe gleich, und „Plus bis 5“ zeigte in allen fünf Feldern
/// abwechselnd 3 + 2 und 4 + 1; „Zehnerübergang“ dreimal dieselbe Lücke.
void main() {
  const subjects = <String, LearningSubject>{
    'Mathe': LearningSubject.mathematik,
    'Deutsch': LearningSubject.deutsch,
    'Sachunterricht': LearningSubject.sachkunde,
    'Mix': LearningSubject.logik,
  };
  String key(MiniGameLearningTask task) =>
      '${task.prompt}|${task.cue}|${task.count}|${task.answer}|'
      '${task.word}|${task.initialBoxes}';

  for (final level in GameLevelCatalog.levels.where((l) => l.id != 50)) {
    test('Stufe ${level.id} „${level.title}“: Fach, keine Wiederholung', () {
      final decks = <String>{};
      for (var seed = 0; seed < 60; seed++) {
        final deck = MiniGameLearningDeck.build(level, seed);
        expect(deck, hasLength(MiniGameLearningDeck.taskCount(level)));
        for (final task in deck) {
          expect(task.isValid, isTrue, reason: task.prompt);
          expect(task.subject, subjects[level.subject],
              reason: '${level.subject}: ${task.prompt}');
        }
        if (level.miniType == GameMiniType.starsPath ||
            level.miniType == GameMiniType.numberHouse) {
          final keys = deck.map(key).toList();
          expect(keys.toSet(), hasLength(keys.length),
              reason: 'Seed $seed wiederholt eine Aufgabe: $keys');
        }
        decks.add(deck.map(key).join(' / '));
      }
      if (level.miniType == GameMiniType.starsPath ||
          level.miniType == GameMiniType.numberHouse) {
        expect(decks.length, greaterThan(1),
            reason: 'Jede Runde ist gleich');
      }
    });
  }
}
