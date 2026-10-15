/// Lern-DNA from a snapshot of the active profile's stored SkillRecords.
/// No synthetic competencies, inferred sessions or unsupported time windows.
library;

import '../../app/app_state.dart';
import '../../core/progress_repository.dart';
import 'learning_dna.dart';

class LearningDnaEngine {
  const LearningDnaEngine();

  LearningDna compute({
    required LumoSessionState state,
    Map<String, SkillRecord> skills = const <String, SkillRecord>{},
    Map<String, int> errorBreakdown = const <String, int>{},
    DnaPreferredTaskType preferredTaskType = DnaPreferredTaskType.unknown,
  }) {
    final observations = skills.values.map((source) {
      final record = source.normalized();
      return DnaSkillEntry(
        subject: record.subject,
        skillLabel: record.unit,
        score: record.accuracy,
        correctAnswers: record.correct,
        wrongAnswers: record.wrong,
      );
    }).toList()
      ..sort((a, b) {
        final subject = a.subject.compareTo(b.subject);
        return subject != 0 ? subject : a.skillLabel.compareTo(b.skillLabel);
      });
    final strengths = observations.where((e) => e.isStrength).toList()
      ..sort((a, b) {
        final ratio = b.score.compareTo(a.score);
        return ratio != 0 ? ratio : b.answerCount.compareTo(a.answerCount);
      });
    final weaknesses = observations.where((e) => e.isWeakness).toList()
      ..sort((a, b) {
        final ratio = a.score.compareTo(b.score);
        return ratio != 0 ? ratio : b.answerCount.compareTo(a.answerCount);
      });
    final correct = observations.fold<int>(0, (n, e) => n + e.correctAnswers);
    final incorrect = observations.fold<int>(0, (n, e) => n + e.wrongAnswers);
    final total = correct + incorrect;
    final progress = total == 0
        ? 'Noch keine Antwortdaten: Eine Einordnung ist noch nicht möglich.'
        : 'Gesamt: $total Antworten, davon $correct richtig '
            '(${((correct / total) * 100).round()}%). '
            '${total < 10 ? 'Kleine Stichprobe. ' : ''}'
            'Gespeicherte Übungsbeobachtungen, keine Kompetenzdiagnose.';
    return LearningDna(
      childName: state.childName,
      lastUpdated: DateTime.now(), // Analysis generation, not an answer date.
      strengths: List.unmodifiable(strengths.take(3)),
      weaknesses: List.unmodifiable(weaknesses.take(3)),
      skillObservations: List.unmodifiable(observations),
      errorBreakdown: Map.unmodifiable(errorBreakdown),
      preferredTaskType: preferredTaskType,
      nextRecommendation: _recommendation(state, weaknesses),
      recentProgress: progress,
      nextRubric: _nextRubric(state, weaknesses),
      totalCorrect: correct,
      totalIncorrect: incorrect,
      // Help/session/emotion/time claims require separately recorded evidence.
    );
  }

  DnaRecommendation _recommendation(
      LumoSessionState state, List<DnaSkillEntry> weaknesses) {
    if (weaknesses.isEmpty) {
      return DnaRecommendation(
        title: 'Neues Thema entdecken',
        subject: state.subject == 'Alle' ? 'Mathematik' : state.subject,
        reason:
            'Wir sammeln weitere Antworten. Probieren wir eine passende Übung?',
        priority: 'mittel',
      );
    }
    final top = weaknesses.first;
    return DnaRecommendation(
      title: '${top.skillLabel} üben',
      subject: top.subject,
      reason: '${top.answerSummary}. Mit fünf leichten Aufgaben weiterüben.',
      priority: top.score <= 0.25 ? 'hoch' : 'mittel',
      suggestedUnit: top.skillLabel,
    );
  }

  String _nextRubric(LumoSessionState state, List<DnaSkillEntry> weaknesses) {
    if (weaknesses.isNotEmpty) {
      return '${weaknesses.first.skillLabel} (${weaknesses.first.subject})';
    }
    if (state.grade == 1) return 'Plus bis 10 mit Zählbild';
    if (state.grade == 2) return 'Einmaleins-Reihe 2er';
    return 'Schriftliches Plus';
  }
}
