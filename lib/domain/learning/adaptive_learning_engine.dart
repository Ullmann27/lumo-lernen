import 'dart:math';

import 'lumo_learning_domain.dart';

class ScoredSkill {
  const ScoredSkill({required this.state, required this.score});
  final SkillState state;
  final double score;
}

class DifficultyWindow {
  const DifficultyWindow({required this.min, required this.target, required this.max});
  final int min;
  final int target;
  final int max;
}

class AdaptiveTaskSelector {
  const AdaptiveTaskSelector();

  SkillState selectSkill({
    required List<SkillState> candidates,
    required LearningMode mode,
    DateTime? now,
  }) {
    if (candidates.isEmpty) {
      throw ArgumentError('AdaptiveTaskSelector requires at least one SkillState.');
    }

    final currentTime = now ?? DateTime.now();
    final scored = candidates.map((skill) {
      final weakness = 1.0 - skill.masteryScore.clamp(0.0, 1.0);
      final repetition = skill.repetitionNeed.clamp(0.0, 1.0);
      final decay = _daysSince(skill.lastSeenAt, currentTime) / 14.0;
      final decayScore = max(skill.decayScore, decay.clamp(0.0, 1.0));
      final frustrationPenalty = (skill.frustrationSignals * 0.04).clamp(0.0, 0.25);
      final unseenBoost = skill.attempts == 0 ? 0.18 : 0.0;

      final modeScore = switch (mode) {
        LearningMode.tutoring => weakness * 0.48 + repetition * 0.34 + decayScore * 0.10,
        LearningMode.practice => weakness * 0.34 + repetition * 0.28 + decayScore * 0.20,
        LearningMode.weaknessTest => weakness * 0.70 + decayScore * 0.10,
        LearningMode.blitzTest => decayScore * 0.35 + weakness * 0.25,
        LearningMode.subjectTest => decayScore * 0.30 + weakness * 0.30,
        LearningMode.exam => decayScore * 0.25 + weakness * 0.25,
      };

      return ScoredSkill(
        state: skill,
        score: modeScore + unseenBoost - frustrationPenalty,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.first.state;
  }

  int _daysSince(DateTime? value, DateTime now) {
    if (value == null) return 30;
    return now.difference(value).inDays.clamp(0, 365).toInt();
  }
}

class DifficultyEngine {
  const DifficultyEngine();

  DifficultyWindow windowFor({
    required SkillState skill,
    required LearningMode mode,
    int minDifficulty = 1,
    int maxDifficulty = 6,
  }) {
    var target = skill.currentDifficulty.clamp(minDifficulty, maxDifficulty).toInt();

    if (skill.consecutiveCorrect >= 3 && skill.masteryScore >= 0.78 && skill.helpCount <= skill.attempts * 0.25) {
      target += 1;
    }

    if (skill.consecutiveWrong >= 2 || skill.frustrationSignals >= 2) {
      target -= 1;
    }

    if (mode == LearningMode.tutoring) {
      target -= 1;
    }

    if (mode == LearningMode.exam) {
      target += skill.masteryScore >= 0.75 ? 1 : 0;
    }

    target = target.clamp(minDifficulty, maxDifficulty).toInt();
    return DifficultyWindow(
      min: max(minDifficulty, target - 1),
      target: target,
      max: min(maxDifficulty, target + 1),
    );
  }
}

class TaskTypeSelector {
  const TaskTypeSelector();

  TaskType select({
    required SkillState skill,
    required List<TaskTemplate> templates,
    required LearningMode mode,
  }) {
    if (templates.isEmpty) {
      throw ArgumentError('TaskTypeSelector requires at least one TaskTemplate.');
    }

    final preferred = skill.preferredTaskType;
    if (preferred != null && templates.any((template) => template.taskType == preferred)) {
      return preferred;
    }

    if (mode == LearningMode.tutoring) {
      final visualTemplate = templates.where((template) => template.visualType != VisualType.none).toList();
      if (visualTemplate.isNotEmpty) return visualTemplate.first.taskType;
    }

    final writingError = skill.recentErrorTypes.any((error) =>
        error == ErrorType.mirroredWriting ||
        error == ErrorType.wrongStrokeOrder ||
        error == ErrorType.incompleteShape ||
        error == ErrorType.wrongDirection);

    if (writingError && templates.any((template) => template.taskType == TaskType.writingCanvas)) {
      return TaskType.writingCanvas;
    }

    return templates.first.taskType;
  }
}

class SkillStateUpdater {
  const SkillStateUpdater();

  SkillState applyResult({
    required SkillState before,
    required TaskResult result,
    DateTime? now,
  }) {
    final attempts = before.attempts + 1;
    final correct = before.correct + (result.correct ? 1 : 0);
    final wrong = before.wrong + (result.correct ? 0 : 1);
    final helpCount = before.helpCount + (result.helpUsed ? 1 : 0);
    final avgResponse = before.attempts == 0
        ? result.responseTimeMs
        : ((before.avgResponseTimeMs * before.attempts + result.responseTimeMs) / attempts).round();
    final frustration = before.frustrationSignals + (result.frustrationSignal ? 1 : 0);

    final recentErrors = <ErrorType>[
      ...before.recentErrorTypes,
      ...result.detectedErrorTypes,
    ];
    final trimmedErrors = recentErrors.length <= 8
        ? recentErrors
        : recentErrors.sublist(recentErrors.length - 8);

    final consecutiveCorrect = result.correct ? before.consecutiveCorrect + 1 : 0;
    final consecutiveWrong = result.correct ? 0 : before.consecutiveWrong + 1;

    final handwritingScore = result.handwritingScore == null
        ? before.handwritingScore
        : _rollingAverage(before.handwritingScore, result.handwritingScore!, before.attempts);

    final updated = before.copyWith(
      attempts: attempts,
      correct: correct,
      wrong: wrong,
      helpCount: helpCount,
      avgResponseTimeMs: avgResponse,
      frustrationSignals: frustration,
      lastSeenAt: now ?? DateTime.now(),
      recentErrorTypes: trimmedErrors,
      handwritingScore: handwritingScore,
      consecutiveCorrect: consecutiveCorrect,
      consecutiveWrong: consecutiveWrong,
    );

    final mastery = computeMastery(updated);
    final repetition = computeRepetitionNeed(updated.copyWith(masteryScore: mastery));
    final nextDifficulty = _nextDifficulty(updated.copyWith(masteryScore: mastery));

    return updated.copyWith(
      masteryScore: mastery,
      repetitionNeed: repetition,
      currentDifficulty: nextDifficulty,
    );
  }

  double computeMastery(SkillState state) {
    final accuracy = state.accuracy.clamp(0.0, 1.0);
    final helpRatio = state.attempts == 0 ? 0.0 : (state.helpCount / state.attempts).clamp(0.0, 1.0);
    final frustrationPenalty = (state.frustrationSignals * 0.05).clamp(0.0, 0.30);
    final decayPenalty = state.decayScore.clamp(0.0, 0.40);
    final handwriting = (state.handwritingScore ?? 1.0).clamp(0.0, 1.0);

    return (accuracy * 0.55 +
            handwriting * 0.15 +
            (1 - helpRatio) * 0.15 +
            (1 - frustrationPenalty) * 0.10 +
            (1 - decayPenalty) * 0.05)
        .clamp(0.0, 1.0);
  }

  double computeRepetitionNeed(SkillState state) {
    final weakness = 1.0 - state.masteryScore.clamp(0.0, 1.0);
    final recentWrong = state.consecutiveWrong >= 2 ? 0.25 : 0.0;
    final errorBoost = state.recentErrorTypes.isEmpty ? 0.0 : 0.10;
    return (weakness * 0.55 + state.decayScore * 0.25 + recentWrong + errorBoost).clamp(0.0, 1.0);
  }

  double _rollingAverage(double? oldValue, double newValue, int previousAttempts) {
    if (oldValue == null || previousAttempts <= 0) return newValue.clamp(0.0, 1.0);
    return ((oldValue * previousAttempts + newValue) / (previousAttempts + 1)).clamp(0.0, 1.0);
  }

  int _nextDifficulty(SkillState state) {
    var next = state.currentDifficulty;
    if (state.consecutiveCorrect >= 3 && state.masteryScore >= 0.78) next += 1;
    if (state.consecutiveWrong >= 2 || state.frustrationSignals >= 3) next -= 1;
    return next.clamp(1, 6).toInt();
  }
}

class ErrorClassifier {
  const ErrorClassifier();

  List<ErrorType> classifyMultipleChoice({
    required TaskInstance task,
    required Object answerGiven,
  }) {
    if (answerGiven == task.correctAnswer) return const <ErrorType>[];

    if (task.subject == LearningSubject.mathematik) {
      final given = int.tryParse('$answerGiven'.replaceAll(RegExp(r'[^0-9-]'), ''));
      final expected = int.tryParse('${task.correctAnswer}'.replaceAll(RegExp(r'[^0-9-]'), ''));
      if (given != null && expected != null) {
        if ((given - expected).abs() == 1) return const <ErrorType>[ErrorType.countingError];
        if ((given - expected).abs() == 10) return const <ErrorType>[ErrorType.placeValueWeak];
      }
      if (task.prompt.contains('+') || task.prompt.contains('-')) {
        return const <ErrorType>[ErrorType.plusMinusConfusion];
      }
      return const <ErrorType>[ErrorType.quantityError];
    }

    if (task.subject == LearningSubject.deutsch) {
      if (task.skillId.value.contains('silbe')) return const <ErrorType>[ErrorType.syllableCountWrong];
      if (task.skillId.value.contains('laut')) return const <ErrorType>[ErrorType.soundMisread];
      return const <ErrorType>[ErrorType.wordImageMismatch];
    }

    return const <ErrorType>[ErrorType.conceptConfusion];
  }
}
