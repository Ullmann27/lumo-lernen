import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lumo Spielwelt: Spiele, Freischaltung und Spielergebnisse.
///
/// Keine Oberfläche entscheidet selbst, ob ein Spiel offen ist. Sie fragt
/// [GameUnlockService]. Freigeschaltet wird nur über verdienten Fortschritt
/// ([EarnedProgress]), nie über ausgebbare Sterne: Wer Sterne im Shop
/// ausgibt, verliert kein Spiel. Einmal offen heißt dauerhaft offen.

enum GameId { memory, cards, puzzle, jumpRun, rhythm, treasure, build, kart }

/// Ob es das Spiel schon gibt. Ehrlich anzeigen, nichts vortäuschen.
enum GameAvailability { playable, comingSoon }

/// Verdienter Fortschritt. Sinkt nie, auch nicht beim Ausgeben von Sternen.
class EarnedProgress {
  const EarnedProgress({required this.totalEarnedStars});

  /// Alle jemals verdienten Sterne (Wallet `totalEarnedStars`), nicht der
  /// aktuelle Kontostand.
  final int totalEarnedStars;
}

/// Regel für ein Spiel. [requires]: dieses Spiel muss vorher offen sein
/// (Reihenfolge Lernen → Memory → Cards → weitere Spiele → Kart).
/// [minEarnedStars]: verdiente Sterne. `null` heißt: Heinz hat noch keine
/// Schwelle festgelegt, die Stufe hängt dann nur an der Reihenfolge.
class GameUnlockRule {
  const GameUnlockRule({this.requires, this.minEarnedStars});

  final GameId? requires;
  final int? minEarnedStars;
}

class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.tagline,
    required this.availability,
    required this.rule,
  });

  final GameId id;
  final String title;
  final String tagline;
  final GameAvailability availability;
  final GameUnlockRule rule;
}

enum GameLockReason { none, needsPreviousGame, needsEarnedStars }

class GameUnlockState {
  const GameUnlockState({
    required this.unlocked,
    this.reason = GameLockReason.none,
    this.missingStars = 0,
    this.previous,
  });

  final bool unlocked;
  final GameLockReason reason;
  final int missingStars;
  final GameId? previous;
}

/// Eine laufende Runde. Spiele melden am Ende ein [GameResult].
abstract interface class GameSession {
  GameId get game;
  DateTime get startedAt;
}

class GameReward {
  const GameReward({this.stars = 0, this.xp = 0});
  final int stars;
  final int xp;
}

class GameResult {
  const GameResult({
    required this.game,
    required this.finishedAt,
    required this.completed,
    this.reward = const GameReward(),
  });

  final GameId game;
  final DateTime finishedAt;
  final bool completed;
  final GameReward reward;
}

/// Gespeicherter Spielstand (z. B. Bauwelt), als JSON pro Spiel.
class GameSaveState {
  const GameSaveState({required this.game, required this.data});
  final GameId game;
  final Map<String, Object?> data;
}

/// Die Spiele der Spielwelt in Freischalt-Reihenfolge.
class GameCatalog {
  static const List<GameDefinition> games = [
    GameDefinition(
      id: GameId.memory,
      title: 'Memory',
      tagline: 'Finde die Paare!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(),
    ),
    GameDefinition(
      id: GameId.cards,
      title: 'Cards',
      tagline: 'Sammeln. Spielen. Staunen!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.memory),
    ),
    GameDefinition(
      id: GameId.puzzle,
      title: 'Puzzle',
      tagline: 'Stück für Stück die Welt entdecken!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.cards),
    ),
    GameDefinition(
      id: GameId.jumpRun,
      title: 'Jump & Run',
      tagline: 'Spring. Laufe. Sei mutig!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.cards),
    ),
    GameDefinition(
      id: GameId.rhythm,
      title: 'Rhythm Party',
      tagline: 'Fühl den Beat!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.cards),
    ),
    GameDefinition(
      id: GameId.treasure,
      title: 'Schatzsuche',
      tagline: 'Rätsel. Hinweise. Schätze!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.cards),
    ),
    GameDefinition(
      id: GameId.build,
      title: 'Bauwelt',
      tagline: 'Bauen. Gestalten. Deiner Fantasie sind keine Grenzen gesetzt!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.cards),
    ),
    GameDefinition(
      id: GameId.kart,
      title: 'Lumo Kart',
      tagline: 'Fahre mit Lumo um die Wette!',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.jumpRun),
    ),
  ];

  static GameDefinition byId(GameId id) =>
      games.firstWhere((game) => game.id == id);
}

/// Reine Regelprüfung ohne Speicher. [permanent]: bereits dauerhaft offene
/// Spiele; sie bleiben offen, egal was die Regel heute sagt.
class GameUnlockPolicy {
  const GameUnlockPolicy({this.games = GameCatalog.games});

  final List<GameDefinition> games;

  Map<GameId, GameUnlockState> evaluate(
    EarnedProgress progress, {
    Set<GameId> permanent = const {},
  }) {
    final result = <GameId, GameUnlockState>{};
    GameUnlockState stateOf(GameDefinition game) {
      final known = result[game.id];
      if (known != null) return known;
      final GameUnlockState state;
      final previous = game.rule.requires;
      final minStars = game.rule.minEarnedStars;
      if (permanent.contains(game.id)) {
        state = const GameUnlockState(unlocked: true);
      } else if (previous != null &&
          !stateOf(games.firstWhere((g) => g.id == previous)).unlocked) {
        state = GameUnlockState(
          unlocked: false,
          reason: GameLockReason.needsPreviousGame,
          previous: previous,
        );
      } else if (minStars != null && progress.totalEarnedStars < minStars) {
        state = GameUnlockState(
          unlocked: false,
          reason: GameLockReason.needsEarnedStars,
          missingStars: minStars - progress.totalEarnedStars,
        );
      } else {
        state = const GameUnlockState(unlocked: true);
      }
      return result[game.id] = state;
    }

    for (final game in games) {
      stateOf(game);
    }
    return result;
  }
}

/// Prüft die Regeln und merkt sich jede Freischaltung dauerhaft.
class GameUnlockService {
  const GameUnlockService({this.policy = const GameUnlockPolicy()});

  static const storageKey = 'lumo_game_unlocks_v1';

  final GameUnlockPolicy policy;

  Future<Map<GameId, GameUnlockState>> load(EarnedProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final permanent = <GameId>{};
    try {
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        for (final name in (jsonDecode(raw) as List).cast<String>()) {
          for (final id in GameId.values) {
            if (id.name == name) permanent.add(id);
          }
        }
      }
    } catch (_) {}
    final states = policy.evaluate(progress, permanent: permanent);
    final open = {
      for (final entry in states.entries)
        if (entry.value.unlocked) entry.key,
    };
    if (open.difference(permanent).isNotEmpty) {
      await prefs.setString(
        storageKey,
        jsonEncode([for (final id in open) id.name]..sort()),
      );
    }
    return states;
  }
}
