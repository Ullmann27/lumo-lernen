/// Engine fuer die Berechnung der Lern-DNA aus dem App-State.
///
/// Aggregiert vorhandene Signale:
///   - AppState (stars, xp, level, weakSkills, lastGrade, solved)
///   - Recent Tasks (Sub-Module nutzen RecentTaskRepository)
///   - Error Breakdown (kommt aus error_detective.dart in Phase 2)
///
/// KEINE neuen Daten-Streams - nur Aggregation aus bestehenden.

import '../../app/app_state.dart';
import '../../core/school_exercise_generator.dart';
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

  // ─── Staerken nur aus tatsaechlich geloesten Aufgaben ───
  List<DnaSkillEntry> _buildStrengthsFromState(
    LumoSessionState state,
    List<DnaSkillEntry> knownWeaknesses,
  ) {
    final weakLabels =
        knownWeaknesses.map((entry) => entry.skillLabel).toSet();
    final candidates = <({String subject, String unit, int count})>[];

    for (final subject in Curriculum.subjects.keys) {
      final currentUnits = Curriculum.unitsForGrade(
        subject,
        state.grade,
        currentGradeOnly: true,
      ).toSet();
      for (final entry in state.solved.entries) {
        if (entry.value <= 0 ||
            !currentUnits.contains(entry.key) ||
            weakLabels.contains(entry.key)) {
          continue;
        }
        candidates.add(
          (subject: subject, unit: entry.key, count: entry.value),
        );
      }
    }

    candidates.sort((a, b) => b.count.compareTo(a.count));
    return candidates.take(3).map((entry) {
      final score =
          (0.55 + entry.count * 0.06).clamp(0.55, 0.95).toDouble();
      final confidence =
          (0.35 + entry.count * 0.08).clamp(0.35, 0.95).toDouble();
      return DnaSkillEntry(
        subject: entry.subject,
        skillLabel: Curriculum.prettifyUnit(entry.unit),
        score: score,
        confidence: confidence,
      );
    }).toList(growable: false);
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
      final subject = Curriculum.subjects.containsKey(state.subject)
          ? state.subject
          : 'Mathematik';
      final units = Curriculum.unitsForGrade(
        subject,
        state.grade,
        currentGradeOnly: true,
      );
      final nextUnit = units.isEmpty ? null : units.first;
      return DnaRecommendation(
        title: nextUnit == null
            ? 'Neues Thema entdecken'
            : '${Curriculum.prettifyUnit(nextUnit)} entdecken',
        subject: subject,
        reason:
            'Keine aktuelle Schwäche erkannt. Als Nächstes passt Stoff der ${state.grade}. Klasse.',
        priority: 'mittel',
        suggestedUnit: nextUnit,
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
    final subject = Curriculum.subjects.containsKey(state.subject)
        ? state.subject
        : 'Mathematik';
    final units = Curriculum.unitsForGrade(
      subject,
      state.grade,
      currentGradeOnly: true,
    );
    if (units.isEmpty) return '';
    final unsolved = units.firstWhere(
      (unit) => (state.solved[unit] ?? 0) < 3,
      orElse: () => units.first,
    );
    return Curriculum.prettifyUnit(unsolved);
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
