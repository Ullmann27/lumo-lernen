import 'progress_repository.dart';
import 'school_exercise_generator.dart';

enum LearningRecommendationKind {
  firstSteps,
  support,
  refresh,
  continueTopic,
  explore
}

/// A concrete, offline activity. Subject and unit are generator keys, while
/// [title], [message] and [reason] are intended for display.
class LearningActivityRecommendation {
  const LearningActivityRecommendation({
    required this.kind,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.title,
    required this.message,
    required this.reason,
    required this.cta,
    required this.suggestedDifficulty,
    required this.evidenceAttempts,
  });

  final LearningRecommendationKind kind;
  final int grade;
  final String subject;
  final String unit;
  final String title;
  final String message;
  final String reason;
  final String cta;

  /// Informational suggestion for consumers that support difficulty control.
  /// Choosing the activity alone does not change the generator's difficulty.
  final int suggestedDifficulty;
  final int evidenceAttempts;

  bool get isTutoring => kind == LearningRecommendationKind.support;
}

/// Recommends a runnable activity using only supplied, local learning records.
///
/// Callers must pass the current child's records. SkillRecord has no child or
/// grade field: historical performance is evidence about the named topic, not
/// proof of mastery at the current grade. Grade limits activity availability.
/// This service performs no I/O and never modifies records or existing APIs.
class ProgressRecommendationService {
  const ProgressRecommendationService();

  LearningActivityRecommendation recommend({
    required int grade,
    required Map<String, SkillRecord> skills,
    String? preferredSubject,
    DateTime? now,
  }) {
    final currentGrade = grade.clamp(1, 4).toInt();
    final today = now ?? DateTime.now();
    final catalog = _catalog(currentGrade);
    final scope =
        catalog.containsKey(preferredSubject) ? preferredSubject : null;
    final records =
        skills.values.map((record) => record.normalized()).where((record) {
      return record.attempts > 0 &&
          (scope == null || record.subject == scope) &&
          (catalog[record.subject]?.contains(record.unit) ?? false);
    }).toList()
          ..sort(_mostRecentFirst);

    // Three successful answers in a row outweigh older errors: do not trap a
    // child in remedial practice after they have recovered.
    final support = records
        .where((record) =>
            record.attempts >= 3 &&
            record.currentStreak < 3 &&
            (record.currentMisses >= 2 || record.weaknessScore >= .5))
        .toList()
      ..sort((a, b) {
        final misses = b.currentMisses.compareTo(a.currentMisses);
        if (misses != 0) return misses;
        final weakness = b.weaknessScore.compareTo(a.weaknessScore);
        return weakness != 0 ? weakness : _mostRecentFirst(a, b);
      });
    if (support.isNotEmpty) {
      final record = support.first;
      return _fromRecord(
        record,
        grade: currentGrade,
        kind: LearningRecommendationKind.support,
        title: 'Gemeinsam Schritt für Schritt',
        message:
            'Wir schauen uns ${_label(record.unit)} in Ruhe an. Ich helfe dir dabei.',
        reason:
            '${record.wrong} von ${record.attempts} gespeicherten Antworten waren noch nicht richtig. Deshalb üben wir dieses Thema mit Hilfe.',
        cta: 'Mit Lumo üben',
        difficulty: (record.difficulty - 1).clamp(1, 5).toInt(),
      );
    }

    final stale = records
        .where((record) =>
            record.attempts >= 3 &&
            !record.lastSeen.isAfter(today) &&
            today.difference(record.lastSeen) >= const Duration(days: 3))
        .toList()
      ..sort((a, b) {
        final age = a.lastSeen.compareTo(b.lastSeen);
        return age != 0 ? age : _mostRecentFirst(a, b);
      });
    if (stale.isNotEmpty) {
      final record = stale.first;
      final days = today.difference(record.lastSeen).inDays;
      return _fromRecord(
        record,
        grade: currentGrade,
        kind: LearningRecommendationKind.refresh,
        title: 'Kurz auffrischen',
        message: 'Lass uns ${_label(record.unit)} noch einmal ausprobieren.',
        reason:
            'Die letzte gespeicherte Antwort zu diesem Thema liegt $days Tage zurück. Eine kurze Wiederholung hilft beim Erinnern.',
        cta: 'Thema auffrischen',
      );
    }

    final unfinished = records.where((record) => !_wellPractised(record));
    if (unfinished.isNotEmpty) {
      final record = unfinished.first;
      return _fromRecord(
        record,
        grade: currentGrade,
        kind: LearningRecommendationKind.continueTopic,
        title: 'Hier machen wir weiter',
        message:
            'Weiter geht es mit ${_label(record.unit)}. Wir gehen in deinem Tempo vor.',
        reason:
            'Zu diesem Thema sind ${record.attempts} Antworten gespeichert, davon ${record.correct} richtig. Wir knüpfen an deine letzte Übung an.',
        cta: 'Weiterüben',
      );
    }

    final subject =
        scope ?? (records.isEmpty ? 'Mathematik' : records.first.subject);
    final options = catalog[subject]!;
    final completedUnits = records
        .where((record) => record.subject == subject)
        .map((record) => record.unit)
        .toSet();
    final untried = options.where((unit) => !completedUnits.contains(unit));
    if (untried.isEmpty && records.isNotEmpty) {
      final record = records.last;
      return _fromRecord(
        record,
        grade: currentGrade,
        kind: LearningRecommendationKind.refresh,
        title: 'Gelerntes festigen',
        message:
            'Du hast hier schon viel geübt. Wiederholen wir ${_label(record.unit)} kurz.',
        reason:
            'Alle verfügbaren Themen in $subject haben bereits gespeicherte Antworten. Deshalb wiederholen wir ein bekanntes Thema.',
        cta: 'Kurz wiederholen',
      );
    }

    final unit = untried.isEmpty ? options.first : untried.first;
    final first = records.isEmpty;
    return LearningActivityRecommendation(
      kind: first
          ? LearningRecommendationKind.firstSteps
          : LearningRecommendationKind.explore,
      grade: currentGrade,
      subject: subject,
      unit: unit,
      title: first ? 'Dein nächster Lernschritt' : 'Ein neues Thema entdecken',
      message: 'Probieren wir ${_label(unit)} gemeinsam aus.',
      reason: first
          ? 'Für diese Auswahl gibt es noch keine passenden gespeicherten Antworten. Wir starten mit einem Thema für Klasse $currentGrade.'
          : 'Deine zuletzt geübten Themen laufen gut. Zu ${_label(unit)} gibt es noch keine gespeicherten Antworten.',
      cta: 'Übung starten',
      suggestedDifficulty: 1,
      evidenceAttempts: 0,
    );
  }

  LearningActivityRecommendation _fromRecord(
    SkillRecord record, {
    required int grade,
    required LearningRecommendationKind kind,
    required String title,
    required String message,
    required String reason,
    required String cta,
    int? difficulty,
  }) =>
      LearningActivityRecommendation(
        kind: kind,
        grade: grade,
        subject: record.subject,
        unit: record.unit,
        title: title,
        message: message,
        reason: reason,
        cta: cta,
        suggestedDifficulty: difficulty ?? record.difficulty,
        evidenceAttempts: record.attempts,
      );

  static bool _wellPractised(SkillRecord record) =>
      record.attempts >= 5 && record.currentStreak >= 5 && record.mastery >= 75;

  static int _mostRecentFirst(SkillRecord a, SkillRecord b) {
    final recent = b.lastSeen.compareTo(a.lastSeen);
    if (recent != 0) return recent;
    final subject = a.subject.compareTo(b.subject);
    return subject != 0 ? subject : a.unit.compareTo(b.unit);
  }

  static String _label(String unit) => Curriculum.prettifyUnit(unit);

  // Exact template keys avoid legacy aliases silently routing to an unrelated
  // generator fallback. Lower-grade topics remain available for reinforcement.
  Map<String, List<String>> _catalog(int grade) {
    const starters = <int, String>{
      1: 'Plus bis 10',
      2: 'Plus bis 20',
      3: 'Einmaleins',
      4: 'Schriftliche Multiplikation'
    };
    return <String, List<String>>{
      for (final subject in Curriculum.subjects.keys)
        subject: Curriculum.unitsForGrade(subject, grade),
      'Mathematik': <String>{
        starters[grade]!,
        ...Curriculum.unitsForGrade('Mathematik', grade),
      }.toList(),
    };
  }
}
