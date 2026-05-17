/// Lumo Lern-DNA - das sichtbare Lernprofil pro Kind.
///
/// Aggregiert alle bisherigen Lern-Signale zu einer Eltern-tauglichen
/// und einer kindgerechten Kurz-Darstellung.
///
/// Quellen:
///   - AppState (stars, xp, level, weakSkills, lastGrade)
///   - LearningProfileEngine (Skill-State pro Subject)
///   - RecentTaskRepository (letzte Aufgaben)
///   - ErrorDetective (Fehlertypen, kommt in Phase 2)

import 'package:flutter/foundation.dart';

/// Eine konkrete Staerke oder Schwaeche im Lernprofil.
@immutable
class DnaSkillEntry {
  const DnaSkillEntry({
    required this.subject,
    required this.skillLabel,
    required this.score,
    this.confidence = 0.5,
  });

  /// 'Mathe', 'Deutsch', 'Sachunterricht'.
  final String subject;

  /// z.B. 'Plus bis 10', 'Reime', 'Artikel der/die/das'.
  final String skillLabel;

  /// 0.0 (sehr schwach) bis 1.0 (sehr stark).
  final double score;

  /// Wie sicher der Wert ist (0.0-1.0). Niedrig bei wenig Daten.
  final double confidence;

  bool get isStrength => score >= 0.70;
  bool get isWeakness => score <= 0.45;
}

/// Bevorzugte Aufgabenart fuer ein Kind.
enum DnaPreferredTaskType {
  /// Multiple-Choice: tippen aus 3-4 Optionen.
  multipleChoice,

  /// Direkte Eingabe (Zahl, Wort tippen).
  directInput,

  /// Schreibaufgabe (mit Stift/Finger).
  writing,

  /// Visuell unterstuetzt (Bilder, Zaehlmengen).
  visual,

  /// Auditive Aufgaben (vorgelesen, Hoeren).
  auditory,

  /// Spielerisch (Quiz, Drag-Drop).
  gamified,

  /// Noch nicht bestimmt.
  unknown,
}

extension DnaPreferredTaskTypeLabel on DnaPreferredTaskType {
  String get germanLabel {
    switch (this) {
      case DnaPreferredTaskType.multipleChoice: return 'Antworten auswaehlen';
      case DnaPreferredTaskType.directInput: return 'Selber eintippen';
      case DnaPreferredTaskType.writing: return 'Schreiben mit Finger';
      case DnaPreferredTaskType.visual: return 'Mit Bildern lernen';
      case DnaPreferredTaskType.auditory: return 'Zuhoeren';
      case DnaPreferredTaskType.gamified: return 'Lernspiele';
      case DnaPreferredTaskType.unknown: return 'Wir finden es heraus';
    }
  }

  String get emoji {
    switch (this) {
      case DnaPreferredTaskType.multipleChoice: return '☑️';
      case DnaPreferredTaskType.directInput: return '⌨️';
      case DnaPreferredTaskType.writing: return '✏️';
      case DnaPreferredTaskType.visual: return '🖼️';
      case DnaPreferredTaskType.auditory: return '🔊';
      case DnaPreferredTaskType.gamified: return '🎯';
      case DnaPreferredTaskType.unknown: return '🔍';
    }
  }
}

/// Frustrations-Signale aus der Lernhistorie.
@immutable
class DnaFrustrationSignal {
  const DnaFrustrationSignal({
    required this.type,
    required this.severity,
    required this.message,
    this.lastSeen,
  });

  final DnaFrustrationType type;
  /// 0.0 (mild) bis 1.0 (hoch).
  final double severity;
  /// Kindgerechte Beschreibung fuer Eltern.
  final String message;
  final DateTime? lastSeen;
}

enum DnaFrustrationType {
  /// Mehrere Aufgaben in Folge falsch.
  consecutiveErrors,

  /// Sehr lange Pausen vor Antworten.
  longHesitation,

  /// Aufgaben abgebrochen (nicht beendet).
  taskAbandonment,

  /// Hilfen wiederholt benoetigt.
  repeatedHelpRequests,

  /// App haeufig verlassen mitten in Session.
  appExits,
}

/// Eine konkrete Lern-Empfehlung.
@immutable
class DnaRecommendation {
  const DnaRecommendation({
    required this.title,
    required this.subject,
    required this.reason,
    required this.priority,
    this.suggestedUnit,
  });

  final String title;
  final String subject;
  /// Warum diese Empfehlung gegeben wird (eltern-tauglich).
  final String reason;
  /// 'hoch' / 'mittel' / 'niedrig'.
  final String priority;
  /// Konkretes Unit innerhalb des Subjects (z.B. 'Plus bis 10').
  final String? suggestedUnit;
}

/// Komplette Lern-DNA eines Kindes.
@immutable
class LearningDna {
  const LearningDna({
    this.childName = '',
    this.lastUpdated,
    this.strengths = const <DnaSkillEntry>[],
    this.weaknesses = const <DnaSkillEntry>[],
    this.errorBreakdown = const <String, int>{},
    this.preferredTaskType = DnaPreferredTaskType.unknown,
    this.nextRecommendation,
    this.recentProgress = '',
    this.frustrationSignals = const <DnaFrustrationSignal>[],
    this.nextRubric = '',
    this.totalSessions = 0,
    this.totalCorrect = 0,
    this.totalIncorrect = 0,
  });

  final String childName;
  final DateTime? lastUpdated;

  /// Top-3 Staerken (sortiert).
  final List<DnaSkillEntry> strengths;

  /// Top-3 Schwaechen (sortiert).
  final List<DnaSkillEntry> weaknesses;

  /// Wie viele Fehler pro Fehlertyp gezaehlt wurden.
  /// Keys aus ErrorDetective: 'countingError', 'plusMinusSwap', etc.
  final Map<String, int> errorBreakdown;

  final DnaPreferredTaskType preferredTaskType;

  /// Die naechste empfohlene Aktion.
  final DnaRecommendation? nextRecommendation;

  /// Kurze Eltern-taugliche Zusammenfassung der letzten Tage.
  /// z.B. "Heute 12 Aufgaben, davon 9 richtig. Streak: 7 Tage."
  final String recentProgress;

  /// Aktuelle Frustrations-Signale (ggf. leer).
  final List<DnaFrustrationSignal> frustrationSignals;

  /// Konkrete naechste Rubrik die das Kind ueben sollte.
  /// z.B. "Plus bis 10 mit Zaehlbild".
  final String nextRubric;

  final int totalSessions;
  final int totalCorrect;
  final int totalIncorrect;

  double get correctRate {
    final total = totalCorrect + totalIncorrect;
    if (total == 0) return 0.0;
    return totalCorrect / total;
  }

  bool get hasFrustrationSignals => frustrationSignals.isNotEmpty;

  /// Liefert eine drei-Wort-Zusammenfassung fuer das Kind.
  /// z.B. "Stark in Plus".
  String get childHeadline {
    if (strengths.isEmpty && weaknesses.isEmpty) {
      return 'Wir finden es zusammen heraus!';
    }
    if (strengths.isNotEmpty) {
      return 'Stark in ${strengths.first.skillLabel}';
    }
    return 'Wir uebungen ${weaknesses.first.skillLabel}';
  }
}
