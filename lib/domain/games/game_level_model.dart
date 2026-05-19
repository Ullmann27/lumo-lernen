/// Lumo Spielewelt - Datenmodell fuer ein Level.
///
/// 50 Level in 5 Bloecken:
///   1-10  Plus/Mengen bis 10
///   11-20 Minus + Zahlenstrahl
///   21-30 Lesen + Silben
///   31-40 Sachaufgaben + Logik
///   41-50 gemischte Challenges

import 'package:flutter/foundation.dart';

enum GameMiniType {
  starsPath,       // Lumo sammelt Sterne auf Pfad - Aufgaben loesen
  numberHouse,     // Rechenhaus mit fehlenden Zahlen
  numberPath,      // Zahlenweg-Sprung
  wordForest,      // Silben/Woerter
  mixedQuiz,       // Mix-Quiz mit 5 Aufgaben
  colorBoxes,      // Anmalen-Mengen: 10 Kaestchen, X anmalen
  letterFill,      // Buchstaben-Luecke: M_US, BR_T, _PFEL etc.
}

extension GameMiniTypeMeta on GameMiniType {
  String get germanLabel {
    switch (this) {
      case GameMiniType.starsPath: return 'Sterne sammeln';
      case GameMiniType.numberHouse: return 'Rechenhaus bauen';
      case GameMiniType.numberPath: return 'Zahlenweg';
      case GameMiniType.wordForest: return 'Woerterwald';
      case GameMiniType.mixedQuiz: return 'Lumos Mix';
      case GameMiniType.colorBoxes: return 'Mengen anmalen';
      case GameMiniType.letterFill: return 'Buchstaben-Luecke';
    }
  }

  String get emoji {
    switch (this) {
      case GameMiniType.starsPath: return '⭐';
      case GameMiniType.numberHouse: return '🏠';
      case GameMiniType.numberPath: return '🦘';
      case GameMiniType.wordForest: return '🌲';
      case GameMiniType.mixedQuiz: return '🎯';
      case GameMiniType.colorBoxes: return '🎨';
      case GameMiniType.letterFill: return '🔤';
    }
  }
}

@immutable
class GameLevel {
  const GameLevel({
    required this.id,
    required this.title,
    required this.gradeFloor,
    required this.miniType,
    required this.subject,
    required this.learningGoal,
    this.maxStars = 3,
  });

  /// 1 bis 50.
  final int id;

  /// Kurzer Level-Titel, z.B. "Plus bis 5".
  final String title;

  /// Mindest-Klasse fuer dieses Level (1-4). Kinder unter dieser Klasse
  /// koennen das Level zwar sehen aber nicht sinnvoll spielen.
  final int gradeFloor;

  final GameMiniType miniType;

  /// 'Mathe' / 'Deutsch' / 'Sachunterricht' / 'Mix'.
  final String subject;

  /// Eltern-taugliche Beschreibung des Lernziels.
  final String learningGoal;

  /// Maximale Sterne in diesem Level (1, 2 oder 3).
  final int maxStars;
}

/// Live-Zustand eines Levels (verschmolzen mit Fortschritt).
@immutable
class GameLevelRuntime {
  const GameLevelRuntime({
    required this.level,
    required this.locked,
    required this.starsEarned,
    this.isCurrent = false,
  });

  final GameLevel level;
  final bool locked;
  /// 0, 1, 2 oder 3.
  final int starsEarned;
  /// Markiert das aktive (naechste freie) Level fuer den Lumo-Avatar.
  final bool isCurrent;

  bool get isCompleted => starsEarned > 0;
  bool get isPerfect => starsEarned >= level.maxStars;
}
