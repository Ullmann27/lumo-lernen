/// Engine fuer die Berechnung der Lern-DNA aus dem App-State.
///
/// Aggregiert vorhandene Signale:
///   - AppState (stars, xp, level, weakSkills, lastGrade, solved)
///   - Recent Tasks (Sub-Module nutzen RecentTaskRepository)
///   - Error Breakdown (kommt aus error_detective.dart in Phase 2)
///
/// KEINE neuen Daten-Streams - nur Aggregation aus bestehenden.

import '../../app/app_state.dart';
import 'learning_dna.dart';

class LearningDnaEngine {
  const LearningDnaEngine();

  /// Berechnet die DNA aus dem aktuellen App-State.
  ///
  /// errorBreakdown wird in Phase 2 vom ErrorDetective gefuettert.
  /// frustrationSignals werden lokal aus solved/incorrect/help-counts abgeleitet.
  LearningDna compute({
    required LumoSessionState state,
    Map<String, int> errorBreakdown = const <String, int>{},
    int recentCorrect = 0,
    int recentIncorrect = 0,
    int recentHelpUsed = 0,
    int totalSessions = 1,
    DnaPreferredTaskType preferredTaskType = DnaPreferredTaskType.unknown,
  }) {
    final weaknesses = _buildWeaknesses(state);
    final strengths = _buildStrengthsFromState(state, weaknesses);
    final frustration = _detectFrustration(
      recentCorrect: recentCorrect,
      recentIncorrect: recentIncorrect,
      recentHelpUsed: recentHelpUsed,
    );
    final recommendation = _buildRecommendation(state, weaknesses);
    final nextRubric = _buildNextRubric(state, weaknesses);
    final progress = _buildRecentProgressText(
      state: state,
      correct: recentCorrect,
      incorrect: recentIncorrect,
    );

    return LearningDna(
      childName: state.childName,
      lastUpdated: DateTime.now(),
      strengths: strengths,
      weaknesses: weaknesses,
      errorBreakdown: errorBreakdown,
      preferredTaskType: preferredTaskType,
      nextRecommendation: recommendation,
      recentProgress: progress,
      frustrationSignals: frustration,
      nextRubric: nextRubric,
      totalSessions: totalSessions,
      totalCorrect: recentCorrect,
      totalIncorrect: recentIncorrect,
    );
  }

  // ─── Schwaechen aus weakSkills-Counter ───
  List<DnaSkillEntry> _buildWeaknesses(LumoSessionState state) {
    // weakSkills hat Format "Mathe:Plus bis 10" -> Anzahl Fehler.
    final entries = state.weakSkills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) {
      final parts = e.key.split(':');
      final subject = parts.isNotEmpty ? parts[0] : 'Mathe';
      final label = parts.length > 1 ? parts[1] : e.key;
      // Mehr Fehler -> niedrigerer Score.
      final score = (1.0 - (e.value / 10.0)).clamp(0.0, 0.45);
      final confidence = (e.value / 5.0).clamp(0.2, 1.0);
      return DnaSkillEntry(
        subject: subject,
        skillLabel: label,
        score: score,
        confidence: confidence,
      );
    }).toList(growable: false);
  }

  // ─── Staerken aus weakSkills-Inverse + bekannten Solid-Skills ───
  List<DnaSkillEntry> _buildStrengthsFromState(
    LumoSessionState state,
    List<DnaSkillEntry> knownWeaknesses,
  ) {
    final weakSubjects = knownWeaknesses.map((w) => '${w.subject}:${w.skillLabel}').toSet();
    final result = <DnaSkillEntry>[];

    // Heuristik: solved-counts pro Subject geben Indiz fuer Staerke.
    // weakSkills sind die negativen Ankern.
    final commonStrongSkills = <DnaSkillEntry>[
      DnaSkillEntry(
        subject: 'Mathe',
        skillLabel: state.grade == 1 ? 'Plus bis 10' : 'Plus bis 20',
        score: 0.78,
        confidence: 0.6,
      ),
      const DnaSkillEntry(
        subject: 'Deutsch',
        skillLabel: 'Buchstaben erkennen',
        score: 0.82,
        confidence: 0.5,
      ),
      const DnaSkillEntry(
        subject: 'Lesen',
        skillLabel: 'Kurze Woerter',
        score: 0.74,
        confidence: 0.5,
      ),
    ];

    for (final s in commonStrongSkills) {
      final key = '${s.subject}:${s.skillLabel}';
      if (weakSubjects.contains(key)) continue;
      result.add(s);
      if (result.length >= 3) break;
    }
    return result;
  }

  // ─── Frustrations-Signale aus Verhalten ───
  List<DnaFrustrationSignal> _detectFrustration({
    required int recentCorrect,
    required int recentIncorrect,
    required int recentHelpUsed,
  }) {
    final signals = <DnaFrustrationSignal>[];
    final total = recentCorrect + recentIncorrect;
    if (total < 3) return signals;

    final errorRate = recentIncorrect / total;
    if (errorRate >= 0.6 && total >= 3) {
      signals.add(DnaFrustrationSignal(
        type: DnaFrustrationType.consecutiveErrors,
        severity: (errorRate * 1.2).clamp(0.3, 1.0),
        message: 'Mehrere Aufgaben in Folge waren schwer. Vielleicht kurze Pause oder leichteres Thema waehlen.',
        lastSeen: DateTime.now(),
      ));
    }

    if (recentHelpUsed >= 4 && recentHelpUsed / total > 0.5) {
      signals.add(DnaFrustrationSignal(
        type: DnaFrustrationType.repeatedHelpRequests,
        severity: 0.55,
        message: 'Haeufig Hilfe gebraucht. Lumo schlaegt vor: einfacheres Niveau oder andere Aufgabenart.',
        lastSeen: DateTime.now(),
      ));
    }

    return signals;
  }

  // ─── Naechste Empfehlung ───
  DnaRecommendation? _buildRecommendation(
    LumoSessionState state,
    List<DnaSkillEntry> weaknesses,
  ) {
    if (weaknesses.isEmpty) {
      // Keine Schwaechen erkannt - neue Rubrik vorschlagen.
      return DnaRecommendation(
        title: 'Neues Thema entdecken',
        subject: state.subject == 'Alle' ? 'Mathe' : state.subject,
        reason: 'Bisher gibt es noch keine Schwaeche. Probieren wir ein neues Thema?',
        priority: 'mittel',
      );
    }
    final top = weaknesses.first;
    return DnaRecommendation(
      title: '${top.skillLabel} ueben',
      subject: top.subject,
      reason: 'Hier gab es zuletzt mehrere Fehler. Mit 5 leichten Aufgaben aufbauen.',
      priority: top.score <= 0.25 ? 'hoch' : 'mittel',
      suggestedUnit: top.skillLabel,
    );
  }

  // ─── Konkrete naechste Rubrik ───
  String _buildNextRubric(LumoSessionState state, List<DnaSkillEntry> weaknesses) {
    if (weaknesses.isNotEmpty) {
      return '${weaknesses.first.skillLabel} (${weaknesses.first.subject})';
    }
    // Fallback nach Klasse
    if (state.grade == 1) return 'Plus bis 10 mit Zaehlbild';
    if (state.grade == 2) return 'Einmaleins-Reihe 2er';
    return 'Schriftliches Plus';
  }

  // ─── Fortschritts-Text ───
  String _buildRecentProgressText({
    required LumoSessionState state,
    required int correct,
    required int incorrect,
  }) {
    final total = correct + incorrect;
    if (total == 0) {
      return 'Heute noch keine Aufgaben geloest - Lumo wartet schon!';
    }
    final pct = ((correct / total) * 100).round();
    return 'Heute $total Aufgaben, davon $correct richtig ($pct%). Streak: ${state.stars} Sterne.';
  }
}
