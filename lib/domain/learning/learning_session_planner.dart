import 'lumo_learning_domain.dart';

enum LearningSessionKind {
  quickPractice,
  exerciseSet,
  test,
  schoolwork,
  tutoring,
}

class SessionSubjectWeight {
  const SessionSubjectWeight({required this.subject, required this.weight});
  final LearningSubject subject;
  final int weight;
}

class PlannedTaskSlot {
  const PlannedTaskSlot({
    required this.index,
    required this.subject,
    this.skillId,
    required this.mode,
    required this.allowHelp,
  });

  final int index;
  final LearningSubject subject;
  final SkillId? skillId;
  final LearningMode mode;
  final bool allowHelp;
}

class LearningSessionPlan {
  const LearningSessionPlan({
    required this.id,
    required this.kind,
    required this.title,
    required this.totalQuestions,
    required this.slots,
    required this.createdAt,
  });

  final String id;
  final LearningSessionKind kind;
  final String title;
  final int totalQuestions;
  final List<PlannedTaskSlot> slots;
  final DateTime createdAt;
}

class LearningSessionPlanner {
  const LearningSessionPlanner();

  LearningSessionPlan plan({
    required LearningSessionKind kind,
    required List<SkillState> skillStates,
    int? totalQuestions,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    final count = totalQuestions ?? _defaultCount(kind);
    final mode = _modeFor(kind);
    final allowHelp = kind != LearningSessionKind.schoolwork;
    final subjectSequence = _subjectSequence(kind: kind, total: count);
    final weakBySubject = _weakSkillsBySubject(skillStates);
    final usedSkills = <String>{};

    final slots = <PlannedTaskSlot>[];
    for (var i = 0; i < count; i++) {
      final subject = subjectSequence[i];
      final skill = _pickSkillForSubject(
        subject: subject,
        weakBySubject: weakBySubject,
        usedSkills: usedSkills,
        index: i,
      );
      if (skill != null) usedSkills.add(skill.value);
      slots.add(PlannedTaskSlot(
        index: i + 1,
        subject: subject,
        skillId: skill,
        mode: mode,
        allowHelp: allowHelp,
      ));
    }

    return LearningSessionPlan(
      id: 'session_${createdAt.microsecondsSinceEpoch}_${kind.name}',
      kind: kind,
      title: _titleFor(kind, count),
      totalQuestions: count,
      slots: slots,
      createdAt: createdAt,
    );
  }

  int _defaultCount(LearningSessionKind kind) {
    return switch (kind) {
      LearningSessionKind.quickPractice => 10,
      LearningSessionKind.exerciseSet => 20,
      LearningSessionKind.test => 10,
      LearningSessionKind.schoolwork => 30,
      LearningSessionKind.tutoring => 8,
    };
  }

  LearningMode _modeFor(LearningSessionKind kind) {
    return switch (kind) {
      LearningSessionKind.quickPractice => LearningMode.practice,
      LearningSessionKind.exerciseSet => LearningMode.practice,
      LearningSessionKind.test => LearningMode.subjectTest,
      LearningSessionKind.schoolwork => LearningMode.exam,
      LearningSessionKind.tutoring => LearningMode.tutoring,
    };
  }

  String _titleFor(LearningSessionKind kind, int count) {
    return switch (kind) {
      LearningSessionKind.quickPractice => 'Kurze Uebung ($count Fragen)',
      LearningSessionKind.exerciseSet => 'Gemischte Uebung ($count Fragen)',
      LearningSessionKind.test => 'Test ($count Fragen)',
      LearningSessionKind.schoolwork => 'Schularbeit-Training ($count Fragen)',
      LearningSessionKind.tutoring => 'Lumo-Nachhilfe ($count Schritte)',
    };
  }

  List<LearningSubject> _subjectSequence({required LearningSessionKind kind, required int total}) {
    final weights = switch (kind) {
      LearningSessionKind.quickPractice => const <SessionSubjectWeight>[
          SessionSubjectWeight(subject: LearningSubject.mathematik, weight: 4),
          SessionSubjectWeight(subject: LearningSubject.deutsch, weight: 4),
          SessionSubjectWeight(subject: LearningSubject.sachkunde, weight: 2),
        ],
      LearningSessionKind.exerciseSet => const <SessionSubjectWeight>[
          SessionSubjectWeight(subject: LearningSubject.mathematik, weight: 4),
          SessionSubjectWeight(subject: LearningSubject.deutsch, weight: 4),
          SessionSubjectWeight(subject: LearningSubject.sachkunde, weight: 2),
        ],
      LearningSessionKind.test => const <SessionSubjectWeight>[
          SessionSubjectWeight(subject: LearningSubject.mathematik, weight: 4),
          SessionSubjectWeight(subject: LearningSubject.deutsch, weight: 4),
          SessionSubjectWeight(subject: LearningSubject.sachkunde, weight: 2),
        ],
      LearningSessionKind.schoolwork => const <SessionSubjectWeight>[
          SessionSubjectWeight(subject: LearningSubject.mathematik, weight: 10),
          SessionSubjectWeight(subject: LearningSubject.deutsch, weight: 10),
          SessionSubjectWeight(subject: LearningSubject.sachkunde, weight: 10),
        ],
      LearningSessionKind.tutoring => const <SessionSubjectWeight>[
          SessionSubjectWeight(subject: LearningSubject.mathematik, weight: 5),
          SessionSubjectWeight(subject: LearningSubject.deutsch, weight: 3),
          SessionSubjectWeight(subject: LearningSubject.sachkunde, weight: 1),
        ],
    };

    final expanded = <LearningSubject>[];
    for (final weight in weights) {
      expanded.addAll(List<LearningSubject>.filled(weight.weight, weight.subject));
    }

    final result = <LearningSubject>[];
    var cursor = 0;
    while (result.length < total) {
      final subject = expanded[cursor % expanded.length];
      if (result.isEmpty || result.last != subject || expanded.toSet().length == 1) {
        result.add(subject);
      } else {
        result.add(expanded[(cursor + 1) % expanded.length]);
      }
      cursor++;
    }
    return result;
  }

  Map<LearningSubject, List<SkillState>> _weakSkillsBySubject(List<SkillState> states) {
    final map = <LearningSubject, List<SkillState>>{
      LearningSubject.mathematik: <SkillState>[],
      LearningSubject.deutsch: <SkillState>[],
      LearningSubject.sachkunde: <SkillState>[],
    };

    for (final state in states) {
      map[_subjectForSkill(state.skillId)]!.add(state);
    }

    for (final entry in map.entries) {
      entry.value.sort((a, b) {
        final aScore = (1 - a.masteryScore) + a.repetitionNeed;
        final bScore = (1 - b.masteryScore) + b.repetitionNeed;
        return bScore.compareTo(aScore);
      });
    }
    return map;
  }

  SkillId? _pickSkillForSubject({
    required LearningSubject subject,
    required Map<LearningSubject, List<SkillState>> weakBySubject,
    required Set<String> usedSkills,
    required int index,
  }) {
    final candidates = weakBySubject[subject] ?? const <SkillState>[];
    if (candidates.isEmpty) return null;
    for (final candidate in candidates) {
      if (!usedSkills.contains(candidate.skillId.value)) return candidate.skillId;
    }
    return candidates[index % candidates.length].skillId;
  }

  LearningSubject _subjectForSkill(SkillId skillId) {
    final value = skillId.value;
    if (value.startsWith('de.')) return LearningSubject.deutsch;
    if (value.startsWith('science.')) return LearningSubject.sachkunde;
    return LearningSubject.mathematik;
  }
}
