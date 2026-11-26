import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/mini_game_round.dart';

/// Einstufung der Lernspiel-Stufen laut Lehrplan (Entscheidung Heinz,
/// 26.11.2026) und Erhalt alter Spielstände aus Build 2082: Sterne,
/// Freigaben und angefangene Runden mit ihren damaligen Antwortkarten.
void main() {
  group('Einstufung', () {
    test('Plus/Minus bis 100 und Einmaleins: 2. Klasse, schriftlich: 3.', () {
      const expected = <int, int>{39: 2, 45: 2, 41: 2, 42: 2, 46: 2, 48: 3, 49: 3};
      for (final entry in expected.entries) {
        final level = GameLevelCatalog.byId(entry.key)!;
        expect(level.gradeFloor, entry.value,
            reason: '${level.id} „${level.title}“');
      }
    });

    test('IDs, Titel, Spielart und Reihenfolge bleiben', () {
      const titles = <int, String>{
        39: 'Plus bis 100', 41: 'Einmaleins Start', 42: 'Einmaleins 3er',
        45: 'Minus bis 100', 46: 'Einmaleins 10er',
        48: 'Schriftliches Plus', 49: 'Schriftliches Minus',
      };
      expect(GameLevelCatalog.levels, hasLength(50));
      for (var i = 0; i < 50; i++) {
        expect(GameLevelCatalog.levels[i].id, i + 1);
      }
      for (final entry in titles.entries) {
        final level = GameLevelCatalog.byId(entry.key)!;
        expect(level.title, entry.value);
        expect(level.miniType.name, 'starsPath');
      }
    });
  });

  group('Spielstand aus Build 2082', () {
    final fixture = jsonDecode(
            File('test/fixtures/lernspiel_2082/spielstand.json')
                .readAsStringSync())
        as Map<String, dynamic>;
    final prefs = (fixture['prefs'] as Map).cast<String, Object>();
    final childId = fixture['childId'] as String;
    final owner = fixture['owner'] as String;

    test('Sterne und Freigaben bleiben unverändert', () async {
      SharedPreferences.setMockInitialValues(Map.of(prefs));
      const repo = GameProgressRepository();
      final stars = await repo.loadStars(childId);
      final old = (jsonDecode(prefs['lumo.games.stars.$childId'] as String)
              as Map)
          .map((k, v) => MapEntry(int.parse('$k'), v as int));
      expect(stars, old);
      final preserved = await repo.loadUnlocked(childId);
      expect(preserved, {1, 2, 3, 4, 5, 6, 7, 8, 9});
      final runtime = repo.buildRuntime(stars, preservedUnlocked: preserved);
      for (final level in runtime) {
        expect(level.locked, level.level.id > 41,
            reason: 'Level ${level.level.id}');
        expect(level.starsEarned, old[level.level.id] ?? 0);
        expect(level.evidenceNote, isNull);
      }
      // Nichts wurde umgeschrieben.
      final after = await SharedPreferences.getInstance();
      expect(after.getString('lumo.games.stars.$childId'),
          prefs['lumo.games.stars.$childId']);
      expect(after.getString('lumo.games.curriculum50.$childId'),
          prefs['lumo.games.curriculum50.$childId']);
    });

    final rounds = (fixture['rounds'] as Map).cast<String, dynamic>();
    for (final entry in rounds.entries) {
      test('angefangene Runde in Level ${entry.key} lädt mit ihren Karten', () {
        final level = GameLevelCatalog.byId(int.parse(entry.key))!;
        final data = entry.value as Map<String, dynamic>;
        final round = MiniGameRound.read(data['snapshot'] as String,
            owner: owner, level: level);
        expect(round.legacyCards, isTrue);
        expect(round.tasks.first.prompt, data['prompt']);
        expect(round.tasks.first.choices, data['shownChoices']);
        expect(round.responses.first.attempts, [data['wrong']]);
        // Weiterspielen speichert die alte Kartenfassung mit.
        final again = MiniGameRound.read(
            jsonEncode(round.copy().toJson()),
            owner: owner,
            level: level);
        expect(again.tasks.first.choices, data['shownChoices']);
        expect(jsonDecode(jsonEncode(round.toJson())).containsKey('cards'),
            isFalse);
      });
    }

    test('neue Runden tragen die Kartenfassung und bleiben im Zahlenraum',
        () {
      final level = GameLevelCatalog.byId(12)!;
      final round = MiniGameRound.fresh(
          owner: owner, level: level, seed: 7, id: 'f' * 32);
      final text = jsonEncode(round.toJson());
      expect(jsonDecode(text)['cards'], MiniGameRound.cardsVersion);
      final read = MiniGameRound.read(text, owner: owner, level: level);
      expect(read.legacyCards, isFalse);
      for (final task in read.tasks) {
        expect(task.choices.every((c) => int.parse(c) <= 10), isTrue,
            reason: task.prompt);
      }
      final broken = (jsonDecode(text) as Map)..['cards'] = 9;
      expect(
          () => MiniGameRound.read(jsonEncode(broken),
              owner: owner, level: level),
          throwsFormatException);
    });
  });
}
