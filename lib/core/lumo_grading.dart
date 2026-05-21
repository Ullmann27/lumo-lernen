// ════════════════════════════════════════════════════════════════════════
// LUMO GRADING — Oesterreichischer Notenrechner
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: Notenrechner nach oesterreichischen Vorgaben.
//
// Schwellenwerte basierend auf typischer Volksschul-Notenpraxis:
//   1 (Sehr Gut)        91-100%
//   2 (Gut)             81-90%
//   3 (Befriedigend)    64-80%
//   4 (Genuegend)       51-63%
//   5 (Nicht Genuegend)  0-50%
//
// Modi:
//   uebung      = normale Lern-Aufgaben
//   test        = kleiner Test, schwieriger als Uebung
//   schularbeit = grosser Test, deutlich schwieriger
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

enum LumoExerciseMode {
  /// Normale Uebungs-Aufgaben (Lernen)
  uebung,

  /// Kleiner Test - moderater Schwierigkeitsgrad
  test,

  /// Schularbeit - hoechster Schwierigkeitsgrad
  schularbeit,
}

extension LumoExerciseModeMeta on LumoExerciseMode {
  String get label {
    switch (this) {
      case LumoExerciseMode.uebung: return 'Übung';
      case LumoExerciseMode.test: return 'Test';
      case LumoExerciseMode.schularbeit: return 'Schularbeit';
    }
  }

  /// Multiplikator fuer Schwierigkeit (z.B. Zahlenbereich, Komplexitaet).
  /// Heinz: 'Tests muessen schwerer sein als Lern-Uebungen'.
  double get difficultyMultiplier {
    switch (this) {
      case LumoExerciseMode.uebung: return 1.0;
      case LumoExerciseMode.test: return 1.5;
      case LumoExerciseMode.schularbeit: return 2.0;
    }
  }

  /// Anzahl der Aufgaben pro Session.
  int get taskCount {
    switch (this) {
      case LumoExerciseMode.uebung: return 100;     // Heinz: '100 statt 10'
      case LumoExerciseMode.test: return 20;
      case LumoExerciseMode.schularbeit: return 40;
    }
  }

  /// Zeit-Limit in Sekunden (null = kein Limit).
  int? get timeLimitSeconds {
    switch (this) {
      case LumoExerciseMode.uebung: return null;
      case LumoExerciseMode.test: return 600; // 10 Min
      case LumoExerciseMode.schularbeit: return 1800; // 30 Min
    }
  }

  IconData get icon {
    switch (this) {
      case LumoExerciseMode.uebung: return Icons.fitness_center_rounded;
      case LumoExerciseMode.test: return Icons.assignment_rounded;
      case LumoExerciseMode.schularbeit: return Icons.school_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LumoExerciseMode.uebung: return const Color(0xFF10B981);
      case LumoExerciseMode.test: return const Color(0xFFF59E0B);
      case LumoExerciseMode.schularbeit: return const Color(0xFFEF4444);
    }
  }
}

/// Oesterreichische Schul-Note (1-5).
class AustriaGrade {
  const AustriaGrade({
    required this.number,
    required this.text,
    required this.color,
    required this.emoji,
  });

  final int number; // 1-5
  final String text;
  final Color color;
  final String emoji;

  static const sehrGut = AustriaGrade(
      number: 1, text: 'Sehr Gut',
      color: Color(0xFF10B981), emoji: '🌟');
  static const gut = AustriaGrade(
      number: 2, text: 'Gut',
      color: Color(0xFF22D3EE), emoji: '😊');
  static const befriedigend = AustriaGrade(
      number: 3, text: 'Befriedigend',
      color: Color(0xFFFCD34D), emoji: '👍');
  static const genuegend = AustriaGrade(
      number: 4, text: 'Genügend',
      color: Color(0xFFFB923C), emoji: '🤔');
  static const nichtGenuegend = AustriaGrade(
      number: 5, text: 'Nicht Genügend',
      color: Color(0xFFEF4444), emoji: '💪');

  static const _all = [
    sehrGut, gut, befriedigend, genuegend, nichtGenuegend,
  ];

  /// Berechne Note aus Prozent (0-100).
  /// Klassische oesterreichische Volksschul-Schwellenwerte.
  static AustriaGrade fromPercent(double percent) {
    if (percent >= 91) return sehrGut;
    if (percent >= 81) return gut;
    if (percent >= 64) return befriedigend;
    if (percent >= 51) return genuegend;
    return nichtGenuegend;
  }

  /// Berechne Note aus richtig/total.
  static AustriaGrade fromCount(int correct, int total) {
    if (total <= 0) return nichtGenuegend;
    return fromPercent((correct / total) * 100);
  }

  /// Kindgerechte Botschaft je nach Note.
  String childMessage() {
    switch (number) {
      case 1: return 'Du bist ein Lern-Star! Weiter so!';
      case 2: return 'Sehr gut gemacht! Du kannst stolz sein!';
      case 3: return 'Gut gemacht! Mit Üben wird es noch besser!';
      case 4: return 'Noch ein bisschen üben - du schaffst das!';
      default: return 'Keine Sorge! Wir üben das gemeinsam!';
    }
  }
}

/// Ergebnis einer abgeschlossenen Aufgabe-Session.
class LumoSessionResult {
  const LumoSessionResult({
    required this.mode,
    required this.totalTasks,
    required this.correctCount,
    required this.timeSpentSeconds,
    required this.topicId,
  });

  final LumoExerciseMode mode;
  final int totalTasks;
  final int correctCount;
  final int timeSpentSeconds;
  final String topicId;

  int get incorrectCount => totalTasks - correctCount;
  double get percent => totalTasks > 0
      ? (correctCount / totalTasks) * 100
      : 0;
  AustriaGrade get grade => AustriaGrade.fromPercent(percent);

  /// Sterne basierend auf Note (1-5 Sterne).
  int get stars {
    switch (grade.number) {
      case 1: return 5;
      case 2: return 4;
      case 3: return 3;
      case 4: return 2;
      default: return 1;
    }
  }

  /// XP-Belohnung: Tests/Schularbeiten geben mehr.
  int get xpReward {
    final base = correctCount * 5;
    switch (mode) {
      case LumoExerciseMode.uebung: return base;
      case LumoExerciseMode.test: return (base * 1.5).round();
      case LumoExerciseMode.schularbeit: return (base * 2).round();
    }
  }
}
