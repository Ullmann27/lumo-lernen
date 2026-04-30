import '../learning/lumo_learning_domain.dart';

enum TutoringStepType {
  greeting,
  explain,
  showExample,
  guidedTask,
  independentTask,
  miniGame,
  recap,
}

class TutoringStep {
  const TutoringStep({
    required this.type,
    required this.subject,
    required this.skillId,
    required this.helpLevel,
    required this.title,
    required this.instruction,
    this.targetTaskType,
    this.durationSeconds = 45,
  });

  final TutoringStepType type;
  final LearningSubject subject;
  final SkillId skillId;
  final int helpLevel;
  final String title;
  final String instruction;
  final TaskType? targetTaskType;
  final int durationSeconds;
}

class TutoringSessionPlan {
  const TutoringSessionPlan({
    required this.childId,
    required this.title,
    required this.focusSkills,
    required this.steps,
    required this.estimatedMinutes,
  });

  final String childId;
  final String title;
  final List<SkillId> focusSkills;
  final List<TutoringStep> steps;
  final int estimatedMinutes;
}

class WeaknessScore {
  const WeaknessScore({required this.skillState, required this.score});
  final SkillState skillState;
  final double score;
}

class TutoringSessionPlanner {
  const TutoringSessionPlanner();

  TutoringSessionPlan plan({
    required String childId,
    required List<SkillState> skillStates,
    LearningSubject fallbackSubject = LearningSubject.mathematik,
    int maxFocusSkills = 3,
  }) {
    final focus = _selectWeaknesses(skillStates, maxFocusSkills: maxFocusSkills);
    final safeFocus = focus.isEmpty
        ? <SkillState>[
            SkillState(
              childId: childId,
              skillId: const SkillId('math.addition'),
              masteryScore: .25,
              repetitionNeed: .50,
              currentDifficulty: 1,
            ),
          ]
        : focus;

    final steps = <TutoringStep>[];
    steps.add(TutoringStep(
      type: TutoringStepType.greeting,
      subject: fallbackSubject,
      skillId: safeFocus.first.skillId,
      helpLevel: 2,
      title: 'Kurzer Start mit Lumo',
      instruction: 'Lumo erklaert: Wir ueben heute nur kleine Schritte. Kein Druck.',
      durationSeconds: 25,
    ));

    for (final state in safeFocus) {
      final subject = _subjectForSkill(state.skillId, fallbackSubject);
      final helpLevel = _helpLevelFor(state);
      steps.addAll([
        TutoringStep(
          type: TutoringStepType.explain,
          subject: subject,
          skillId: state.skillId,
          helpLevel: helpLevel,
          title: 'Mini-Erklaerung',
          instruction: _explanationFor(state.skillId),
          durationSeconds: 45,
        ),
        TutoringStep(
          type: TutoringStepType.showExample,
          subject: subject,
          skillId: state.skillId,
          helpLevel: helpLevel,
          title: 'Lumo zeigt ein Beispiel',
          instruction: _exampleFor(state.skillId),
          targetTaskType: _visualTaskTypeFor(state.skillId),
          durationSeconds: 50,
        ),
        TutoringStep(
          type: TutoringStepType.guidedTask,
          subject: subject,
          skillId: state.skillId,
          helpLevel: helpLevel,
          title: 'Gemeinsam loesen',
          instruction: 'Kind bekommt eine leichte Aufgabe mit sichtbarer Hilfe.',
          targetTaskType: _visualTaskTypeFor(state.skillId),
          durationSeconds: 60,
        ),
      ]);
    }

    steps.add(TutoringStep(
      type: TutoringStepType.miniGame,
      subject: fallbackSubject,
      skillId: safeFocus.first.skillId,
      helpLevel: 1,
      title: 'Fuchs-Minispiel',
      instruction: 'Kurze spielerische Wiederholung mit Beeren, Pfad oder Buchstaben.',
      targetTaskType: _visualTaskTypeFor(safeFocus.first.skillId),
      durationSeconds: 75,
    ));

    steps.add(TutoringStep(
      type: TutoringStepType.recap,
      subject: fallbackSubject,
      skillId: safeFocus.first.skillId,
      helpLevel: 0,
      title: 'Geschafft-Zusammenfassung',
      instruction: 'Lumo sagt konkret, was besser geworden ist und was morgen wiederholt wird.',
      durationSeconds: 35,
    ));

    final seconds = steps.fold<int>(0, (sum, step) => sum + step.durationSeconds);
    return TutoringSessionPlan(
      childId: childId,
      title: 'Persoenliche Lumo-Nachhilfe',
      focusSkills: safeFocus.map((state) => state.skillId).toList(growable: false),
      steps: steps,
      estimatedMinutes: (seconds / 60).ceil(),
    );
  }

  List<SkillState> _selectWeaknesses(List<SkillState> states, {required int maxFocusSkills}) {
    final scored = states.map((state) {
      final weakness = 1.0 - state.masteryScore.clamp(0.0, 1.0);
      final repetition = state.repetitionNeed.clamp(0.0, 1.0);
      final errors = state.recentErrorTypes.isEmpty ? 0.0 : .15;
      final help = state.attempts == 0 ? 0.0 : (state.helpCount / state.attempts).clamp(0.0, 1.0) * .20;
      final score = weakness * .48 + repetition * .28 + errors + help;
      return WeaknessScore(skillState: state, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(maxFocusSkills).map((entry) => entry.skillState).toList(growable: false);
  }

  int _helpLevelFor(SkillState state) {
    var level = 1;
    if (state.masteryScore < .35) level += 1;
    if (state.consecutiveWrong >= 2) level += 1;
    if (state.helpCount > state.correct) level += 1;
    return level.clamp(1, 4).toInt();
  }

  LearningSubject _subjectForSkill(SkillId skillId, LearningSubject fallback) {
    final value = skillId.value;
    if (value.startsWith('de.')) return LearningSubject.deutsch;
    if (value.startsWith('science.')) return LearningSubject.sachkunde;
    if (value.startsWith('math.')) return LearningSubject.mathematik;
    return fallback;
  }

  TaskType _visualTaskTypeFor(SkillId skillId) {
    final value = skillId.value;
    if (value.contains('letter') || value.contains('writing')) return TaskType.writingCanvas;
    if (value.contains('place_value')) return TaskType.tenOnes;
    if (value.contains('line')) return TaskType.numberLine;
    if (value.contains('addition') || value.contains('subtraction')) return TaskType.dotGroups;
    return TaskType.multipleChoice;
  }

  String _explanationFor(SkillId skillId) {
    final value = skillId.value;
    if (value.contains('subtraction')) return 'Minus heisst: Erst ist eine Menge da, dann geht etwas weg.';
    if (value.contains('addition')) return 'Plus heisst: Zwei Mengen kommen zusammen.';
    if (value.contains('place_value')) return 'Zehner sind Stangen, Einer sind einzelne Punkte.';
    if (value.contains('syllable')) return 'Silben hoerst du, wenn du ein Wort langsam klatschst.';
    if (value.contains('letter')) return 'Beim Schreiben zaehlen Startpunkt, Richtung und ganze Form.';
    return 'Wir machen das Thema in kleinen Schritten und mit Hilfe.';
  }

  String _exampleFor(SkillId skillId) {
    final value = skillId.value;
    if (value.contains('subtraction')) return 'Beispiel: 5 Beeren liegen da. 2 rollen weg. Es bleiben 3.';
    if (value.contains('addition')) return 'Beispiel: 3 Beeren und 2 Beeren sind zusammen 5.';
    if (value.contains('place_value')) return 'Beispiel: 24 hat 2 Zehner und 4 Einer.';
    if (value.contains('syllable')) return 'Beispiel: Ba-na-ne hat drei Klatscher.';
    if (value.contains('letter')) return 'Beispiel: Starte am Punkt, folge der Richtung, dann pruefen wir die Form.';
    return 'Lumo zeigt zuerst ein Beispiel, dann probiert das Kind selbst.';
  }
}
