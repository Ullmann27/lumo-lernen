import 'independent_evidence.dart';

/// How much real evidence exists for one topic.
///
/// A percentage after one or two answers claims more than anyone knows. The
/// child and the parents therefore read a stage that is backed by counted
/// answers: first "am Anfang", then "in Übung", and "sicher" only after
/// enough tasks were solved alone on at least two different days.
enum SkillEvidenceStage { starting, practicing, secure }

class SkillEvidence {
  const SkillEvidence._({
    required this.stage,
    required this.answers,
    required this.independentCorrect,
    required this.independentDays,
  });

  /// Below this many recorded answers nothing is said about ability.
  static const int startingAnswers = 5;

  /// Tasks solved alone (first try, no help) needed for "sicher".
  static const int secureIndependentCorrect = 6;

  /// Different calendar days with a task solved alone needed for "sicher".
  static const int secureDays = 2;

  /// Share of independent answers that must be right for "sicher".
  static const double secureAccuracy = .8;

  factory SkillEvidence.from({
    required int answers,
    required IndependentEvidence independent,
    required int independentDays,
  }) {
    final total = answers < 0 ? 0 : answers;
    final days = independentDays < 0 ? 0 : independentDays;
    final SkillEvidenceStage stage;
    if (total < startingAnswers) {
      stage = SkillEvidenceStage.starting;
    } else if (independent.correct >= secureIndependentCorrect &&
        days >= secureDays &&
        independent.accuracy >= secureAccuracy &&
        independent.wrongStreak < 2) {
      stage = SkillEvidenceStage.secure;
    } else {
      stage = SkillEvidenceStage.practicing;
    }
    return SkillEvidence._(
      stage: stage,
      answers: total,
      independentCorrect: independent.correct,
      independentDays: days,
    );
  }

  final SkillEvidenceStage stage;
  final int answers;
  final int independentCorrect;
  final int independentDays;

  bool get isSecure => stage == SkillEvidenceStage.secure;

  /// Short stage for the child, without a percentage.
  String get label => switch (stage) {
        SkillEvidenceStage.starting => 'am Anfang ($answers von $startingAnswers)',
        SkillEvidenceStage.practicing => 'in Übung',
        SkillEvidenceStage.secure => 'sicher',
      };

  /// The counted facts behind the stage, for tiles and the parent report.
  String get facts {
    final solved = independentCorrect == 1
        ? '1 Aufgabe allein gelöst'
        : '$independentCorrect Aufgaben allein gelöst';
    return switch (stage) {
      SkillEvidenceStage.starting => solved,
      SkillEvidenceStage.practicing =>
        independentCorrect >= secureIndependentCorrect &&
                independentDays < secureDays
            ? '$solved · noch an einem zweiten Tag zeigen'
            : solved,
      SkillEvidenceStage.secure => '$solved an $independentDays Tagen',
    };
  }
}
