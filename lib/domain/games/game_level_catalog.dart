/// 50 Level-Definitionen fuer Lumo Spielewelt.
///
/// Aufbau:
///   1-10  Plus + Mengen bis 10 (Klasse 1)
///   11-20 Minus + Zahlenstrahl + Zehnerübergang (Klasse 1-2)
///   21-30 Lesen + Silben + Wort-Bild (Klasse 1-2)
///   31-40 Sachaufgaben + Logik (Klasse 2-3)
///   41-50 gemischte Herausforderungen (Klasse 3-4)

import 'game_level_model.dart';

abstract class GameLevelCatalog {
  GameLevelCatalog._();

  /// Alle 50 Level in fester Reihenfolge.
  static const List<GameLevel> levels = <GameLevel>[
    // ─────── Block 1: Plus + Mengen bis 10 (Klasse 1) ───────
    GameLevel(id: 1, title: 'Plus bis 5', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Erste Plus-Aufgaben bis 5 sicher loesen'),
    GameLevel(id: 2, title: 'Mengen zaehlen', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Mengen bis 5 schnell erfassen'),
    GameLevel(id: 3, title: 'Plus bis 7', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Plus bis 7 mit Zaehlbild'),
    GameLevel(id: 4, title: 'Punkt-Gruppen', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Punktgruppen ohne Zaehlen erkennen'),
    GameLevel(id: 5, title: 'Plus bis 10', gradeFloor: 1, miniType: GameMiniType.numberHouse, subject: 'Mathe', learningGoal: 'Zahlzerlegung im Rechenhaus'),
    GameLevel(id: 6, title: 'Mengen bis 10', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Mengen bis 10 vergleichen'),
    GameLevel(id: 7, title: 'Zerlege 7', gradeFloor: 1, miniType: GameMiniType.numberHouse, subject: 'Mathe', learningGoal: 'Zahl 7 in zwei Mengen zerlegen'),
    GameLevel(id: 8, title: 'Zerlege 9', gradeFloor: 1, miniType: GameMiniType.numberHouse, subject: 'Mathe', learningGoal: 'Zahl 9 in zwei Mengen zerlegen'),
    GameLevel(id: 9, title: 'Plus-Tricks', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Verdoppeln und Nachbarzahlen'),
    GameLevel(id: 10, title: 'Plus-Meister', gradeFloor: 1, miniType: GameMiniType.mixedQuiz, subject: 'Mathe', learningGoal: 'Block-Test: alle Plus-Themen', maxStars: 3),

    // ─────── Block 2: Minus + Zahlenstrahl (Klasse 1-2) ───────
    GameLevel(id: 11, title: 'Minus bis 5', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Erste Minus-Aufgaben bis 5'),
    GameLevel(id: 12, title: 'Minus bis 10', gradeFloor: 1, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Minus bis 10 mit Zaehlbild'),
    GameLevel(id: 13, title: 'Zahlenweg 1-10', gradeFloor: 1, miniType: GameMiniType.numberPath, subject: 'Mathe', learningGoal: 'Zahlen 1-10 in richtiger Reihenfolge'),
    GameLevel(id: 14, title: 'Welche Zahl fehlt?', gradeFloor: 1, miniType: GameMiniType.numberPath, subject: 'Mathe', learningGoal: 'Luecken im Zahlenstrahl'),
    GameLevel(id: 15, title: 'Zehnerübergang', gradeFloor: 2, miniType: GameMiniType.numberHouse, subject: 'Mathe', learningGoal: 'Plus/Minus ueber die 10er-Grenze'),
    GameLevel(id: 16, title: 'Plus bis 20', gradeFloor: 2, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Plus im Bereich 10-20'),
    GameLevel(id: 17, title: 'Minus bis 20', gradeFloor: 2, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Minus im Bereich 10-20'),
    GameLevel(id: 18, title: 'Zahlen vergleichen', gradeFloor: 2, miniType: GameMiniType.numberPath, subject: 'Mathe', learningGoal: 'Groesser/kleiner/gleich erkennen'),
    GameLevel(id: 19, title: 'Verdoppeln', gradeFloor: 2, miniType: GameMiniType.numberHouse, subject: 'Mathe', learningGoal: 'Verdoppeln bis 20'),
    GameLevel(id: 20, title: 'Minus-Meister', gradeFloor: 2, miniType: GameMiniType.mixedQuiz, subject: 'Mathe', learningGoal: 'Block-Test: Minus + Zahlenstrahl', maxStars: 3),

    // ─────── Block 3: Lesen + Silben + Wort-Bild (Klasse 1-2) ───────
    GameLevel(id: 21, title: 'Anfangslaute', gradeFloor: 1, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Anfangslaute hoeren und zuordnen'),
    GameLevel(id: 22, title: 'Endlaute', gradeFloor: 1, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Endlaute am Wortende hoeren'),
    GameLevel(id: 23, title: 'Silben klatschen', gradeFloor: 1, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Woerter in Silben zerlegen'),
    GameLevel(id: 24, title: 'Reime finden', gradeFloor: 1, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Reim-Wortpaare erkennen'),
    GameLevel(id: 25, title: 'Wort und Bild', gradeFloor: 1, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Geschriebenes Wort zum Bild zuordnen'),
    GameLevel(id: 26, title: 'Kurze Woerter', gradeFloor: 1, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Erste kurze Woerter (3-4 Buchstaben) lesen'),
    GameLevel(id: 27, title: 'Artikel der/die/das', gradeFloor: 2, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Den passenden Artikel waehlen'),
    GameLevel(id: 28, title: 'Einzahl - Mehrzahl', gradeFloor: 2, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Einzahl/Mehrzahl bilden'),
    GameLevel(id: 29, title: 'Wortfamilien', gradeFloor: 2, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Verwandte Woerter finden'),
    GameLevel(id: 30, title: 'Lese-Meister', gradeFloor: 2, miniType: GameMiniType.mixedQuiz, subject: 'Deutsch', learningGoal: 'Block-Test: Lesen + Silben + Reime', maxStars: 3),

    // ─────── Block 4: Sachaufgaben + Logik (Klasse 2-3) ───────
    GameLevel(id: 31, title: 'Einkaufen', gradeFloor: 2, miniType: GameMiniType.mixedQuiz, subject: 'Mathe', learningGoal: 'Sachaufgaben mit Geld'),
    GameLevel(id: 32, title: 'Uhrzeit', gradeFloor: 2, miniType: GameMiniType.mixedQuiz, subject: 'Mathe', learningGoal: 'Volle Stunden und halbe Stunden lesen'),
    GameLevel(id: 33, title: 'Tier-Logik', gradeFloor: 2, miniType: GameMiniType.mixedQuiz, subject: 'Sachunterricht', learningGoal: 'Tiere und Lebensraeume zuordnen'),
    GameLevel(id: 34, title: 'Wetter', gradeFloor: 2, miniType: GameMiniType.mixedQuiz, subject: 'Sachunterricht', learningGoal: 'Wetterzeichen erkennen'),
    GameLevel(id: 35, title: 'Pflanzen', gradeFloor: 2, miniType: GameMiniType.mixedQuiz, subject: 'Sachunterricht', learningGoal: 'Pflanzenteile erkennen'),
    GameLevel(id: 36, title: 'Zaehlen in Sprüngen', gradeFloor: 3, miniType: GameMiniType.numberPath, subject: 'Mathe', learningGoal: 'In 2er- und 5er-Schritten zaehlen'),
    GameLevel(id: 37, title: 'Verdoppeln-Halbieren', gradeFloor: 3, miniType: GameMiniType.numberHouse, subject: 'Mathe', learningGoal: 'Verdoppeln und Halbieren bis 100'),
    GameLevel(id: 38, title: 'Wortarten', gradeFloor: 3, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Nomen, Verb, Adjektiv unterscheiden'),
    GameLevel(id: 39, title: 'Plus bis 100', gradeFloor: 3, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Plus im Hunderterraum'),
    GameLevel(id: 40, title: 'Logik-Meister', gradeFloor: 3, miniType: GameMiniType.mixedQuiz, subject: 'Mix', learningGoal: 'Block-Test: Sachaufgaben + Logik', maxStars: 3),

    // ─────── Block 5: gemischte Challenges (Klasse 3-4) ───────
    GameLevel(id: 41, title: 'Einmaleins Start', gradeFloor: 3, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: '2er- und 5er-Reihe'),
    GameLevel(id: 42, title: 'Einmaleins 3er', gradeFloor: 3, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: '3er-Reihe Einmaleins'),
    GameLevel(id: 43, title: 'Synonyme', gradeFloor: 3, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Woerter mit aehnlicher Bedeutung'),
    GameLevel(id: 44, title: 'Zeitformen', gradeFloor: 3, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Gegenwart und Vergangenheit'),
    GameLevel(id: 45, title: 'Minus bis 100', gradeFloor: 3, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Minus im Hunderterraum'),
    GameLevel(id: 46, title: 'Einmaleins 10er', gradeFloor: 4, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: '10er- und 4er-Reihe'),
    GameLevel(id: 47, title: 'Satzbau', gradeFloor: 4, miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: 'Saetze in richtige Reihenfolge'),
    GameLevel(id: 48, title: 'Schriftliches Plus', gradeFloor: 4, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Schriftliche Addition'),
    GameLevel(id: 49, title: 'Schriftliches Minus', gradeFloor: 4, miniType: GameMiniType.starsPath, subject: 'Mathe', learningGoal: 'Schriftliche Subtraktion'),
    GameLevel(id: 50, title: 'Lumo-Champion', gradeFloor: 4, miniType: GameMiniType.mixedQuiz, subject: 'Mix', learningGoal: 'Finale Mix-Challenge - alle Themen', maxStars: 3),
  ];

  static GameLevel? byId(int id) {
    if (id < 1 || id > levels.length) return null;
    return levels[id - 1];
  }

  /// Schwierigkeitsblock fuer ein Level (1-5).
  static int blockOf(int levelId) {
    if (levelId <= 10) return 1;
    if (levelId <= 20) return 2;
    if (levelId <= 30) return 3;
    if (levelId <= 40) return 4;
    return 5;
  }

  static String blockTitle(int block) {
    switch (block) {
      case 1: return 'Plus & Mengen';
      case 2: return 'Minus & Zahlenstrahl';
      case 3: return 'Lesen & Silben';
      case 4: return 'Sachaufgaben & Logik';
      case 5: return 'Gemischte Challenges';
      default: return 'Lumo-Welt';
    }
  }
}
