/// Core domain model for the adaptive Lumo Lernen task engine.
///
/// This file is intentionally UI-free. It can be tested without Flutter widgets
/// and later backed by Drift/Isar repositories.

enum LearningSubject {
  deutsch,
  mathematik,
  sachkunde,
}

enum LearningMode {
  practice,
  tutoring,
  blitzTest,
  subjectTest,
  weaknessTest,
  exam,
}

enum TaskType {
  multipleChoice,
  numberLine,
  dotGroups,
  tenOnes,
  writingCanvas,
  imageWord,
  readingComprehension,
  dragDrop,
  trueFalse,
}

enum VisualType {
  none,
  dots,
  numberLine,
  sequence,
  shape,
  tenOnes,
  clock,
  money,
  syllables,
  writingPath,
  // Neu fuer Heinz' erweiterte Templates (Mai 2026):
  quantityCompare,
  fractionPizza,
  barChart,
  rhymeBubble,
  syllableClap,
  wordFamilyTree,
  sentenceBlocks,
  wordTypeColor,
  articleCards,
}

enum ErrorType {
  none,

  // Deutsch / Schreiben
  letterConfusion,
  soundMisread,
  syllableCountWrong,
  wordImageMismatch,
  mirroredWriting,
  wrongStrokeOrder,
  incompleteShape,
  wrongStartPoint,
  wrongDirection,

  // Mathematik
  plusMinusConfusion,
  countingError,
  quantityError,
  tenTransitionWeak,
  wordProblemMisread,
  doubleHalfConfusion,
  placeValueWeak,

  // Sachkunde
  conceptConfusion,
  categoryConfusion,
  everydayKnowledgeWeak,
}

class SkillId {
  const SkillId(this.value);
  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is SkillId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.familyId,
    required this.name,
    required this.grade,
    this.activeSubject = LearningSubject.mathematik,
    this.createdAt,
  });

  final String id;
  final String familyId;
  final String name;
  final int grade;
  final LearningSubject activeSubject;
  final DateTime? createdAt;
}

class SkillState {
  const SkillState({
    required this.childId,
    required this.skillId,
    this.attempts = 0,
    this.correct = 0,
    this.wrong = 0,
    this.helpCount = 0,
    this.avgResponseTimeMs = 0,
    this.frustrationSignals = 0,
    this.lastSeenAt,
    this.masteryScore = 0,
    this.decayScore = 0,
    this.repetitionNeed = 0,
    this.preferredTaskType,
    this.handwritingScore,
    this.recentErrorTypes = const <ErrorType>[],
    this.currentDifficulty = 1,
    this.consecutiveCorrect = 0,
    this.consecutiveWrong = 0,
  });

  final String childId;
  final SkillId skillId;
  final int attempts;
  final int correct;
  final int wrong;
  final int helpCount;
  final int avgResponseTimeMs;
  final int frustrationSignals;
  final DateTime? lastSeenAt;
  final double masteryScore;
  final double decayScore;
  final double repetitionNeed;
  final TaskType? preferredTaskType;
  final double? handwritingScore;
  final List<ErrorType> recentErrorTypes;
  final int currentDifficulty;
  final int consecutiveCorrect;
  final int consecutiveWrong;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  SkillState copyWith({
    int? attempts,
    int? correct,
    int? wrong,
    int? helpCount,
    int? avgResponseTimeMs,
    int? frustrationSignals,
    DateTime? lastSeenAt,
    double? masteryScore,
    double? decayScore,
    double? repetitionNeed,
    TaskType? preferredTaskType,
    double? handwritingScore,
    List<ErrorType>? recentErrorTypes,
    int? currentDifficulty,
    int? consecutiveCorrect,
    int? consecutiveWrong,
  }) {
    return SkillState(
      childId: childId,
      skillId: skillId,
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      helpCount: helpCount ?? this.helpCount,
      avgResponseTimeMs: avgResponseTimeMs ?? this.avgResponseTimeMs,
      frustrationSignals: frustrationSignals ?? this.frustrationSignals,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      masteryScore: masteryScore ?? this.masteryScore,
      decayScore: decayScore ?? this.decayScore,
      repetitionNeed: repetitionNeed ?? this.repetitionNeed,
      preferredTaskType: preferredTaskType ?? this.preferredTaskType,
      handwritingScore: handwritingScore ?? this.handwritingScore,
      recentErrorTypes: recentErrorTypes ?? this.recentErrorTypes,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
    );
  }
}

class DifficultyRange {
  const DifficultyRange(this.min, this.max);
  final int min;
  final int max;

  bool contains(int value) => value >= min && value <= max;
}

class ParameterSpec {
  const ParameterSpec({
    this.minNumber,
    this.maxNumber,
    this.allowedWords = const <String>[],
    this.allowedSymbols = const <String>[],
    this.requiresUniqueOptions = true,
  });

  final int? minNumber;
  final int? maxNumber;
  final List<String> allowedWords;
  final List<String> allowedSymbols;
  final bool requiresUniqueOptions;
}

class TaskTemplate {
  const TaskTemplate({
    required this.templateId,
    required this.subject,
    required this.skillId,
    required this.taskType,
    required this.minGrade,
    required this.maxGrade,
    required this.difficultyRange,
    required this.visualType,
    required this.parameterSpec,
    this.detectableErrors = const <ErrorType>[],
    this.cooldownDays = 21,
  });

  final String templateId;
  final LearningSubject subject;
  final SkillId skillId;
  final TaskType taskType;
  final int minGrade;
  final int maxGrade;
  final DifficultyRange difficultyRange;
  final VisualType visualType;
  final ParameterSpec parameterSpec;
  final List<ErrorType> detectableErrors;
  final int cooldownDays;
}

class AnswerOption {
  const AnswerOption({required this.id, required this.label, this.payload});
  final String id;
  final String label;
  final Object? payload;
}

class VisualPayload {
  const VisualPayload({required this.type, this.data = const <String, Object?>{}});
  final VisualType type;
  final Map<String, Object?> data;
}

class HelpPayload {
  const HelpPayload({
    this.level = 0,
    this.shortHint,
    this.guidedSteps = const <String>[],
  });

  final int level;
  final String? shortHint;
  final List<String> guidedSteps;
}

class TaskInstance {
  const TaskInstance({
    required this.taskInstanceId,
    required this.templateId,
    required this.childId,
    required this.seedHash,
    required this.subject,
    required this.skillId,
    required this.taskType,
    required this.difficulty,
    required this.parameters,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.visualPayload,
    required this.helpPayload,
    required this.generatedAt,
  });

  final String taskInstanceId;
  final String templateId;
  final String childId;
  final String seedHash;
  final LearningSubject subject;
  final SkillId skillId;
  final TaskType taskType;
  final int difficulty;
  final Map<String, Object?> parameters;
  final String prompt;
  final List<AnswerOption> options;
  final Object correctAnswer;
  final VisualPayload visualPayload;
  final HelpPayload helpPayload;
  final DateTime generatedAt;
}

class TaskResult {
  const TaskResult({
    required this.taskInstanceId,
    required this.childId,
    required this.skillId,
    required this.correct,
    required this.responseTimeMs,
    this.helpUsed = false,
    this.detectedErrorTypes = const <ErrorType>[],
    this.handwritingScore,
    this.frustrationSignal = false,
  });

  final String taskInstanceId;
  final String childId;
  final SkillId skillId;
  final bool correct;
  final int responseTimeMs;
  final bool helpUsed;
  final List<ErrorType> detectedErrorTypes;
  final double? handwritingScore;
  final bool frustrationSignal;
}
