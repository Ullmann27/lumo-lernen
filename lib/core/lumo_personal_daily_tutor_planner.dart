import 'progress_repository.dart';
import 'learning_journey.dart';
import 'weakness_detection_engine.dart';

enum LumoDailyTutorStepKind { revise, practice, confidence, check }

enum LumoKnowledgeStatus { insufficient, review, assisted, independent, retained }

extension LumoKnowledgeLabel on LumoKnowledgeStatus {
  String get label => switch (this) {
    LumoKnowledgeStatus.insufficient => 'Noch nicht ausreichend geprüft',
    LumoKnowledgeStatus.review => 'Wiederholungsbedarf',
    LumoKnowledgeStatus.assisted => 'Mit Hilfe gelöst',
    LumoKnowledgeStatus.independent => 'Selbstständig gelöst',
    LumoKnowledgeStatus.retained => 'Wiederholt sicher beherrscht',
  };
}

/// One inspectable, profile-grounded action. No inferred personal traits.
class LumoDailyTutorStep {
  const LumoDailyTutorStep({
    required this.kind,
    required this.subject,
    required this.unit,
    required this.durationMinutes,
    this.reason = '',
  });

  final LumoDailyTutorStepKind kind;
  final String subject;
  final String unit;
  final int durationMinutes;
  final String reason;

  String get title => switch (kind) {
        LumoDailyTutorStepKind.revise => 'Gemeinsam wiederholen',
        LumoDailyTutorStepKind.practice => 'Den nächsten Schritt üben',
        LumoDailyTutorStepKind.confidence => 'Zeig, was du kannst',
        LumoDailyTutorStepKind.check => 'Selbst ausprobieren',
      };

  String get description => '$subject · $unit · ca. $durationMinutes Min.';
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

  LumoKnowledgeStatus knowledge(JourneySkill? record) {
    if (record == null) return LumoKnowledgeStatus.insufficient;
    if (record.status == JourneyStatus.retained) return LumoKnowledgeStatus.retained;
    final wrong = record.attempts - record.independentCorrect - record.assistedCorrect;
    if (record.needsPractice && wrong >= 2 && record.attempts >= 3) return LumoKnowledgeStatus.review;
    if (!record.needsPractice && record.independentCorrect > 0) return LumoKnowledgeStatus.independent;
    if (record.assistedCorrect > 0) return LumoKnowledgeStatus.assisted;
    return LumoKnowledgeStatus.insufficient;
  }

  /// Three short, actionable units. A historical aggregate without explicit
  /// assistance/transfer data remains unverified, even when its score is high.
  List<LumoDailyTutorStep> buildEvidencePlan(Map<String, SkillRecord> records,
      Map<String, JourneySkill> journey, {DateTime? now,
      bool Function(SkillRecord record)? isEligible}) {
    final candidates = <String, SkillRecord>{...records};
    for (final entry in journey.entries) {
      candidates.putIfAbsent(entry.key, () => SkillRecord(skillId: entry.key,
        subject: entry.value.subject, unit: entry.value.unit, lastSeen: entry.value.lastSeen));
    }
    final eligible = candidates.values.where((r) => r.subject.trim().isNotEmpty &&
      r.unit.trim().isNotEmpty && (isEligible?.call(r) ?? true)).toList();
    if (eligible.isEmpty) return const [];
    final at = now ?? DateTime.now();
    int priority(SkillRecord r) {
      final evidence = journey[r.skillId];
      final status = knowledge(evidence);
      return status.index * 2 + (evidence != null && !at.isBefore(evidence.dueAt) ? 0 : 1);
    }
    eligible.sort((a, b) {
      final byNeed = priority(a).compareTo(priority(b));
      if (byNeed != 0) return byNeed;
      final bySeen = (journey[a.skillId]?.lastSeen ?? a.lastSeen)
          .compareTo(journey[b.skillId]?.lastSeen ?? b.lastSeen);
      return bySeen != 0 ? bySeen : a.skillId.compareTo(b.skillId);
    });
    // Repetition/assisted work first; absence of evidence never means weakness.
    final needs = eligible.where((r) => [LumoKnowledgeStatus.review,
      LumoKnowledgeStatus.assisted].contains(knowledge(journey[r.skillId]))).toList();
    final first = needs.isNotEmpty ? needs.first : eligible.first;
    final second = eligible.firstWhere((r) => r.skillId != first.skillId, orElse: () => first);
    final strengths = eligible.where((r) => [LumoKnowledgeStatus.retained,
      LumoKnowledgeStatus.independent].contains(knowledge(journey[r.skillId]))).toList();
    LumoDailyTutorStep step(SkillRecord r, LumoDailyTutorStepKind kind, int minutes) =>
      LumoDailyTutorStep(kind: kind, subject: r.subject, unit: r.unit, durationMinutes: minutes,
        reason: knowledge(journey[r.skillId]).label);
    return List.unmodifiable([
      step(first, needs.isNotEmpty ? LumoDailyTutorStepKind.revise : LumoDailyTutorStepKind.practice, 5),
      step(second, LumoDailyTutorStepKind.practice, 4),
      step(strengths.isEmpty ? second : strengths.last,
        strengths.isEmpty ? LumoDailyTutorStepKind.check : LumoDailyTutorStepKind.confidence, 3),
    ]);
  }

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
