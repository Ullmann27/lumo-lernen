import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_readiness.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';

/// Adaptive Freischaltung der Lernspiel-Stufen aus dem nachgewiesenen
/// Lernstand (Übungsprotokoll). Wenige Daten schalten nichts frei.
void main() {
  group('Adaptive Freischaltung', () {
    var serial = 0;
    Attempt attempt(String unit,
            {bool correct = true, bool hint = false, String prompt = ''}) =>
        Attempt(
            id: 'a${serial++}',
            studentId: 's',
            subject: 'Mathematik',
            unit: unit,
            competency: unit,
            correct: correct,
            at: DateTime.utc(2026, 11, 1).add(Duration(minutes: serial)),
            hintUsed: hint,
            prompt: prompt);

    test('ohne oder mit wenigen Daten wird nichts freigeschaltet', () {
      expect(GameLevelReadiness.proven(const []), isEmpty);
      final few = [for (var i = 0; i < 7; i++) attempt('Plus bis 100')];
      expect(GameLevelReadiness.proven(few), isEmpty);
      final withHelp = [
        for (var i = 0; i < 12; i++) attempt('Plus bis 100', hint: true)
      ];
      expect(GameLevelReadiness.proven(withHelp), isEmpty,
          reason: 'Antworten mit Hilfe belegen keine Kompetenz');
    });

    test('sicher geübtes Plus bis 100 öffnet Level 39 mit Begründung', () {
      final log = [
        for (var i = 0; i < 9; i++) attempt('Plus bis 100'),
        attempt('Plus bis 100', correct: false),
      ];
      final proven = GameLevelReadiness.proven(log);
      expect(proven.keys, [39]);
      expect(proven[39]!.correct, 9);
      expect(proven[39]!.considered, 10);
      expect(proven[39]!.note, contains('„Plus bis 100“'));
      expect(proven[39]!.note, contains('9 von 10'));
      const repo = GameProgressRepository();
      final runtime = repo.buildRuntime(const {1: 3}, proven: proven);
      final level39 = runtime.firstWhere((r) => r.level.id == 39);
      expect(level39.locked, isFalse);
      expect(level39.evidenceNote, proven[39]!.note);
      expect(runtime.firstWhere((r) => r.level.id == 40).locked, isTrue);
      expect(runtime.firstWhere((r) => r.level.id == 2).isCurrent, isTrue);
    });

    test('zu viele Fehler in den letzten Antworten: keine Freischaltung', () {
      final log = [
        for (var i = 0; i < 20; i++) attempt('Minus bis 100'),
        for (var i = 0; i < 3; i++) attempt('Minus bis 100', correct: false),
      ];
      expect(GameLevelReadiness.proven(log), isEmpty);
    });

    test('Einmaleins zählt nur die passende Reihe', () {
      final threes = [
        for (var i = 1; i <= 10; i++)
          attempt('Kleines 1×1', prompt: '3 × $i = ?')
      ];
      final proven = GameLevelReadiness.proven(threes);
      expect(proven.keys, [42]);
      expect(proven[42]!.note, contains('die 3er-Reihe'));
      final fives = [
        for (var i = 1; i <= 10; i++)
          attempt('Einmaleins', prompt: '$i · 5 = ?')
      ];
      expect(GameLevelReadiness.proven(fives).keys, [41]);
    });

    test('anderes Fach oder Thema zählt nicht, gespielte Level bleiben', () {
      final german = [
        for (var i = 0; i < 12; i++)
          Attempt(
              id: 'd$i',
              studentId: 's',
              subject: 'Deutsch',
              unit: 'Plus bis 100',
              competency: 'x',
              correct: true,
              at: DateTime.utc(2026))
      ];
      expect(GameLevelReadiness.proven(german), isEmpty);
      final log = [for (var i = 0; i < 10; i++) attempt('Schriftliche Addition')];
      expect(GameLevelReadiness.proven(log).keys, [48]);
      expect(GameLevelReadiness.proven(log, stars: const {48: 1}), isEmpty);
      const repo = GameProgressRepository();
      final runtime = repo.buildRuntime(const {48: 2},
          proven: GameLevelReadiness.proven(log));
      final played = runtime.firstWhere((r) => r.level.id == 48);
      expect(played.locked, isFalse);
      expect(played.starsEarned, 2);
      expect(played.evidenceNote, isNull);
    });
  });
}
