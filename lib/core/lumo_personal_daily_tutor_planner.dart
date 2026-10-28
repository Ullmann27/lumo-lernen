import 'progress_repository.dart';
import 'weakness_detection_engine.dart';

enum LumoDailyTutorStepKind { revise, practice, confidence }

/// One inspectable, profile-grounded action. No inferred personal traits.
class LumoDailyTutorStep {
  const LumoDailyTutorStep({
    required this.kind,
    required this.subject,
    required this.unit,
    required this.durationMinutes,
  });

  final LumoDailyTutorStepKind kind;
  final String subject;
  final String unit;
  final int durationMinutes;

  String get title => switch (kind) {
        LumoDailyTutorStepKind.revise => 'Gemeinsam wiederholen',
        LumoDailyTutorStepKind.practice => 'Den nächsten Schritt üben',
        LumoDailyTutorStepKind.confidence => 'Zeig, was du kannst',
      };

  String get description => '$subject · $unit';
}

/// Read-only daily recommendations from *actual* saved skill evidence.
///
/// There are no guesses when the child has not yet answered enough
/// questions. The caller supplies records belonging to one active profile,
/// and an eligibility check for their current grade's existing curriculum.
/// All returned units originate in those records, never from fabricated
/// weaknesses or empty-profile defaults.
class LumoPersonalDailyTutorPlanner {
  const LumoPersonalDailyTutorPlanner();

  List<LumoDailyTutorStep> build(
    Map<String, SkillRecord> records, {
    bool Function(SkillRecord record)? isEligible,
  }) {
    final eligible = records.values.where((r) =>
        r.attempts >= 3 &&
        r.subject.trim().isNotEmpty &&
        r.unit.trim().isNotEmpty &&
        (isEligible?.call(r) ?? true)).toList(growable: false);
    if (eligible.isEmpty) return const [];

    const detector = WeaknessDetectionEngine();
    final evidence = {for (final r in eligible) r.skillId: r};
    final weak = detector.findWeaknesses(evidence);
    final mastered = detector.findMastered(evidence);
    final used = <String>{};
    final plan = <LumoDailyTutorStep>[];

    void add(SkillRecord r, LumoDailyTutorStepKind kind, int minutes) {
      if (!used.add(r.skillId)) return;
      plan.add(LumoDailyTutorStep(
        kind: kind,
        subject: r.subject,
        unit: r.unit,
        durationMinutes: minutes,
      ));
    }

    if (weak.isNotEmpty) add(weak.first, LumoDailyTutorStepKind.revise, 5);
    if (weak.length >= 2) add(weak[1], LumoDailyTutorStepKind.practice, 5);

    // Celebrate something already demonstrated, not a random easy question.
    mastered.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    for (final strength in mastered) {
      if (!used.contains(strength.skillId)) {
        add(strength, LumoDailyTutorStepKind.confidence, 3);
        break;
      }
    }
    return List.unmodifiable(plan);
  }
}
