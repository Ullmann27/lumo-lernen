import 'progress_repository.dart';
import 'learning_journey.dart';
import 'school_exercise_generator.dart';
import '../domain/learning_intelligence/concept_graph.dart';
import '../domain/learning_intelligence/lumo_intelligence_engine.dart';
import 'weakness_detection_engine.dart';

enum LumoDailyTutorStepKind { revise, practice, confidence, check }

enum LumoKnowledgeStatus {
  insufficient,
  review,
  assisted,
  independent,
  retained
}

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
    this.pauseAfter = false,
  });

  final LumoDailyTutorStepKind kind;
  final String subject;
  final String unit;
  final int durationMinutes;
  final String reason;
  final bool pauseAfter;

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
/// Observed focus units originate in those records; a supplied grade may add
/// eligible curriculum units as explicitly unverified checks. No empty-profile
/// defaults or fabricated weaknesses are generated.
class LumoPersonalDailyTutorPlanner {
  const LumoPersonalDailyTutorPlanner();

  LumoKnowledgeStatus knowledge(JourneySkill? record) {
    if (record == null) return LumoKnowledgeStatus.insufficient;
    if (record.status == JourneyStatus.retained)
      return LumoKnowledgeStatus.retained;
    final wrong =
        record.attempts - record.independentCorrect - record.assistedCorrect;
    if (record.needsPractice && wrong >= 2 && record.attempts >= 3)
      return LumoKnowledgeStatus.review;
    if (!record.needsPractice && record.independentCorrect > 0)
      return LumoKnowledgeStatus.independent;
    if (record.assistedCorrect > 0) return LumoKnowledgeStatus.assisted;
    return LumoKnowledgeStatus.insufficient;
  }

  /// Three short, actionable units. A historical aggregate without explicit
  /// assistance/transfer data remains unverified, even when its score is high.
  List<LumoDailyTutorStep> buildEvidencePlan(
      Map<String, SkillRecord> records, Map<String, JourneySkill> journey,
      {DateTime? now,
      int? grade,
      bool Function(SkillRecord record)? isEligible}) {
    final candidates = <String, SkillRecord>{...records};
    for (final entry in journey.entries) {
      candidates.putIfAbsent(
          entry.key,
          () => SkillRecord(
              skillId: entry.key,
              subject: entry.value.subject,
              unit: entry.value.unit,
              lastSeen: entry.value.lastSeen));
    }
    final eligible = candidates.values
        .where((r) =>
            r.subject.trim().isNotEmpty &&
            r.unit.trim().isNotEmpty &&
            (isEligible?.call(r) ?? true) &&
            (grade == null ||
                Curriculum.unitsForGrade(r.subject, grade,
                        currentGradeOnly: true)
                    .contains(r.unit)))
        .toList();
    if (eligible.isEmpty) return const [];
    final at = now ?? DateTime.now();
    int priority(SkillRecord r) {
      final evidence = journey[r.skillId];
      final status = knowledge(evidence);
      if (status == LumoKnowledgeStatus.review) return 0;
      if (_reviewDue(evidence, at)) return 1;
      if (status == LumoKnowledgeStatus.assisted) return 2;
      if (status == LumoKnowledgeStatus.insufficient) return 3;
      return 4;
    }

    eligible.sort((a, b) {
      final byNeed = priority(a).compareTo(priority(b));
      if (byNeed != 0) return byNeed;
      final aEvidence = journey[a.skillId];
      final bEvidence = journey[b.skillId];
      if (_reviewDue(aEvidence, at) && _reviewDue(bEvidence, at)) {
        final byDue = aEvidence!.dueAt.compareTo(bEvidence!.dueAt);
        if (byDue != 0) return byDue;
      }
      final bySeen = (journey[a.skillId]?.lastSeen ?? a.lastSeen)
          .compareTo(journey[b.skillId]?.lastSeen ?? b.lastSeen);
      return bySeen != 0 ? bySeen : a.skillId.compareTo(b.skillId);
    });
    // Repeated errors and due recall receive attention before new work.
    // A due date is a scheduling observation, never a claim of forgetting.
    final first = eligible.first;
    if (grade != null) {
      return _balanced(first, eligible, journey, grade, at,
          isEligible: isEligible);
    }
    final second = eligible.firstWhere((r) => r.skillId != first.skillId,
        orElse: () => first);
    final strengths = eligible
        .where((r) => _confirmedStrength(journey[r.skillId]))
        .toList();
    LumoDailyTutorStep step(
            SkillRecord r, LumoDailyTutorStepKind kind, int minutes) =>
        LumoDailyTutorStep(
            kind: kind,
            subject: r.subject,
            unit: r.unit,
            durationMinutes: minutes,
            reason: _reason(journey[r.skillId], at));
    return List.unmodifiable([
      step(first, _openingKind(journey[first.skillId], at), 5),
      step(second, LumoDailyTutorStepKind.practice, 4),
      step(
          strengths.isEmpty ? second : strengths.last,
          strengths.isEmpty
              ? LumoDailyTutorStepKind.check
              : LumoDailyTutorStepKind.confidence,
          3),
    ]);
  }

  /// Recency alone never establishes forgotten knowledge. Only observations
  /// that already justify practice or recall have a meaningful review date.
  bool _reviewDue(JourneySkill? record, DateTime at) =>
      record != null &&
      knowledge(record) != LumoKnowledgeStatus.insufficient &&
      !at.isBefore(record.dueAt);

  bool _confirmedStrength(JourneySkill? record) =>
      record != null &&
      (record.status == JourneyStatus.independentlyChecked ||
          record.status == JourneyStatus.retained);

  LumoDailyTutorStepKind _openingKind(JourneySkill? record, DateTime at) {
    final status = knowledge(record);
    if (status == LumoKnowledgeStatus.review ||
        status == LumoKnowledgeStatus.assisted ||
        _reviewDue(record, at)) {
      return LumoDailyTutorStepKind.revise;
    }
    return status == LumoKnowledgeStatus.insufficient
        ? LumoDailyTutorStepKind.check
        : LumoDailyTutorStepKind.practice;
  }

  String _reason(JourneySkill? record, DateTime at) {
    final status = knowledge(record);
    if (_reviewDue(record, at) &&
        (status == LumoKnowledgeStatus.independent ||
            status == LumoKnowledgeStatus.retained)) {
      return 'Kurze Wiederholung nach einer Lernpause · ${status.label}';
    }
    return status.label;
  }

  List<LumoDailyTutorStep> _balanced(SkillRecord first, List<SkillRecord> known,
      Map<String, JourneySkill> journey, int grade, DateTime at,
      {bool Function(SkillRecord record)? isEligible}) {
    final graph = LumoConceptGraph.reference();
    const intelligence = LumoIntelligenceEngine();
    bool ready(SkillRecord r) {
      final nodes = graph.forTask(r.subject, r.unit);
      return nodes.isNotEmpty &&
          nodes.every((n) => graph.prerequisitesOf(n.id).every((id) => [
                ConceptCertainty.transferConfirmed,
                ConceptCertainty.retained
              ].contains(intelligence.assess(graph[id]!, journey).certainty)));
    }

    final pool = <SkillRecord>[
      ...known.where((r) => r.skillId != first.skillId)
    ];
    for (final subject in [
      first.subject,
      ...Curriculum.exerciseSubjectsForGrade(grade)
          .where((s) => s != first.subject)
    ]) {
      for (final unit
          in Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true)) {
        final id = SkillRecord.makeId(subject, unit);
        if (id == first.skillId || pool.any((r) => r.skillId == id)) continue;
        final candidate =
            SkillRecord(skillId: id, subject: subject, unit: unit);
        if (isEligible?.call(candidate) ?? true) pool.add(candidate);
      }
    }
    if (pool.isEmpty)
      return [
        LumoDailyTutorStep(
            kind: _openingKind(journey[first.skillId], at),
            subject: first.subject,
            unit: first.unit,
            durationMinutes: 5,
            reason: _reason(journey[first.skillId], at))
      ];
    final second = pool.firstWhere(ready, orElse: () => pool.first);
    final strengths = known
        .where((r) =>
            r.skillId != first.skillId &&
            r.skillId != second.skillId &&
            [JourneyStatus.independentlyChecked, JourneyStatus.retained]
                .contains(journey[r.skillId]?.status))
        .toList();
    final third = strengths.isNotEmpty
        ? strengths.last
        : pool.firstWhere((r) => r.skillId != second.skillId,
            orElse: () => second);
    LumoDailyTutorStep step(SkillRecord r, LumoDailyTutorStepKind kind,
            int minutes, String reason, {bool pause = false}) =>
        LumoDailyTutorStep(
            kind: kind,
            subject: r.subject,
            unit: r.unit,
            durationMinutes: minutes,
            reason: reason,
            pauseAfter: pause);
    // A due recall or supported practice may start with revision. Unobserved
    // curriculum units stay checks and never become claimed weaknesses.
    return List.unmodifiable([
      step(first, _openingKind(journey[first.skillId], at), 5,
          _reason(journey[first.skillId], at)),
      step(
          second,
          ready(second)
              ? LumoDailyTutorStepKind.practice
              : LumoDailyTutorStepKind.check,
          4,
          ready(second)
              ? 'Passender Einstieg nach geprüften Voraussetzungen'
              : 'Kurzer Einstieg: Voraussetzungen noch nicht ausreichend geprüft',
          pause: true),
      step(
          third,
          strengths.isNotEmpty
              ? LumoDailyTutorStepKind.confidence
              : LumoDailyTutorStepKind.check,
          3,
          strengths.isNotEmpty
              ? 'Bestätigte Übertragung aus deinem Lernweg'
              : 'Eine andere kurze Selbstprobe, ohne behauptete Stärke'),
    ]);
  }

  List<LumoDailyTutorStep> build(
    Map<String, SkillRecord> records, {
    bool Function(SkillRecord record)? isEligible,
  }) {
    final eligible = records.values
        .where((r) =>
            r.attempts >= 3 &&
            r.subject.trim().isNotEmpty &&
            r.unit.trim().isNotEmpty &&
            (isEligible?.call(r) ?? true))
        .toList(growable: false);
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
