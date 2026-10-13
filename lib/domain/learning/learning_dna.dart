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
library;

import 'package:flutter/foundation.dart';

/// Eine konkrete Staerke oder Schwaeche im Lernprofil.
@immutable
class DnaSkillEntry {
  const DnaSkillEntry({
    required this.subject,
    required this.skillLabel,
    required this.score,
    this.confidence = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
  });

  /// 'Mathe', 'Deutsch', 'Sachunterricht'.
  final String subject;

  /// z.B. 'Plus bis 10', 'Reime', 'Artikel der/die/das'.
  final String skillLabel;

  /// Observed correct-answer ratio, not a competency or diagnosis score.
  final double score;

  /// Legacy compatibility field; no diagnostic confidence is inferred or shown.
  final double confidence;
  final int correctAnswers;
  final int wrongAnswers;
  int get answerCount => correctAnswers + wrongAnswers;

  /// Conservative display grouping only; not a validated diagnostic threshold.
  bool get hasEnoughAnswersForGrouping => answerCount >= 10;
  bool get isSmallSample => answerCount > 0 && !hasEnoughAnswersForGrouping;
  String get answerSummary => answerCount == 0
      ? 'Noch keine Antworten'
      : '${(score * 100).round()}% · $correctAnswers von $answerCount Antworten richtig';
  String get sampleNote => answerCount == 0
      ? 'Keine Datengrundlage'
      : isSmallSample
          ? 'Kleine Stichprobe – noch keine Einordnung'
          : 'Übungsbeobachtung, keine Kompetenzdiagnose';

  bool get isStrength => hasEnoughAnswersForGrouping && score >= 0.70;
  bool get isWeakness => hasEnoughAnswersForGrouping && score <= 0.45;
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
      case DnaPreferredTaskType.multipleChoice:
        return 'Antworten auswaehlen';
      case DnaPreferredTaskType.directInput:
        return 'Selber eintippen';
      case DnaPreferredTaskType.writing:
        return 'Schreiben mit Finger';
      case DnaPreferredTaskType.visual:
        return 'Mit Bildern lernen';
      case DnaPreferredTaskType.auditory:
        return 'Zuhoeren';
      case DnaPreferredTaskType.gamified:
        return 'Lernspiele';
      case DnaPreferredTaskType.unknown:
        return 'Wir finden es heraus';
    }
  }

  String get emoji {
    switch (this) {
      case DnaPreferredTaskType.multipleChoice:
        return '☑️';
      case DnaPreferredTaskType.directInput:
        return '⌨️';
      case DnaPreferredTaskType.writing:
        return '✏️';
      case DnaPreferredTaskType.visual:
        return '🖼️';
      case DnaPreferredTaskType.auditory:
        return '🔊';
      case DnaPreferredTaskType.gamified:
        return '🎯';
      case DnaPreferredTaskType.unknown:
        return '🔍';
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
    this.skillObservations = const <DnaSkillEntry>[],
    this.errorBreakdown = const <String, int>{},
    this.preferredTaskType = DnaPreferredTaskType.unknown,
    this.nextRecommendation,
    this.recentProgress = '',
    this.frustrationSignals = const <DnaFrustrationSignal>[],
    this.nextRubric = '',
    this.totalSessions,
    this.totalCorrect = 0,
    this.totalIncorrect = 0,
  });

  final String childName;
  final DateTime? lastUpdated;

  /// Top-3 Staerken (sortiert).
  final List<DnaSkillEntry> strengths;

  /// Top-3 Schwaechen (sortiert).
  final List<DnaSkillEntry> weaknesses;
  final List<DnaSkillEntry> skillObservations;

  /// Wie viele Fehler pro Fehlertyp gezaehlt wurden.
  /// Keys aus ErrorDetective: 'countingError', 'plusMinusSwap', etc.
  final Map<String, int> errorBreakdown;

  final DnaPreferredTaskType preferredTaskType;

  /// Die naechste empfohlene Aktion.
  final DnaRecommendation? nextRecommendation;

  /// Stored answer totals. No time window or improvement is inferred.
  final String recentProgress;

  /// Aktuelle Frustrations-Signale (ggf. leer).
  final List<DnaFrustrationSignal> frustrationSignals;

  /// Konkrete naechste Rubrik die das Kind ueben sollte.
  /// z.B. "Plus bis 10 mit Zaehlbild".
  final String nextRubric;

  /// Unknown unless recorded explicitly; never fabricated from answer totals.
  final int? totalSessions;
  final int totalCorrect;
  final int totalIncorrect;

  double get correctRate {
    final total = totalCorrect + totalIncorrect;
    if (total == 0) return 0.0;
    return totalCorrect / total;
  }

  bool get hasFrustrationSignals => frustrationSignals.isNotEmpty;

  String parentAnalysisPrompt({required int grade}) {
    final out = StringBuffer()
      ..writeln('Lernanalyse für das aktuelle Profil (Klasse $grade).')
      ..writeln(
          'Datengrundlage: gespeicherte Antwort-Einträge, Gesamtwerte ohne abgegrenzten Zeitraum.')
      ..writeln(
          'Gesamt: ${totalCorrect + totalIncorrect} Antworten, $totalCorrect richtig, $totalIncorrect falsch.')
      ..writeln(
          'Keine Aussagen über heute, diese Woche, Verbesserung, Sitzungsanzahl oder Diagnosesicherheit ableiten.');
    if (skillObservations.isEmpty || totalCorrect + totalIncorrect == 0) {
      out.writeln(
          'Noch keine Antwortdaten. Keine Stärken oder Schwierigkeiten erfinden.');
    }
    const footer =
        'Gib 3–5 praktische Sätze für Eltern und eine sinnvolle nächste Übung. '
        'Kleine Stichproben ausdrücklich vorsichtig einordnen; keine Kompetenzdiagnose.\n';
    var omitted = 0;
    // The existing transport rejects messages over 1200 characters. Keep whole
    // observations and all data-quality instructions; never truncate a claim.
    for (final entry in skillObservations) {
      final line = '${entry.subject} / ${entry.skillLabel}: '
          '${entry.answerSummary}. '
          '${entry.isSmallSample || entry.answerCount == 0 ? entry.sampleNote : "Übungsbeobachtung"}.\n';
      final omissionReserve =
          '\nWeitere ${skillObservations.length} Themen nicht einzeln aufgeführt.\n'
              .length;
      if (out.length + line.length + footer.length + omissionReserve <= 1200) {
        out.write(line);
      } else {
        omitted++;
      }
    }
    if (omitted > 0) {
      out.writeln('Weitere $omitted Themen nicht einzeln aufgeführt.');
    }
    out.write(footer);
    return out.toString();
  }

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
