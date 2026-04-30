import '../learning/lumo_learning_domain.dart';

enum AgentEventType {
  screenOpened,
  taskStarted,
  taskAnswered,
  writingSubmitted,
  readingStarted,
  readingSentenceHeard,
  readingErrorDetected,
  tutoringStepStarted,
  tutoringStepAnswered,
  scanImported,
  rewardGranted,
  parentReportRequested,
}

enum AgentActionType {
  speak,
  showHint,
  startPractice,
  startReading,
  startTutoring,
  repeatSentence,
  showSyllables,
  showSchoolbookVisual,
  grantReward,
  createRecommendation,
  createParentInsight,
  continueFlow,
  reduceDifficulty,
  increaseDifficulty,
}

enum AgentTone {
  warm,
  focused,
  coaching,
  celebrating,
  calming,
  parentNeutral,
}

class AgentEvent {
  const AgentEvent({
    required this.type,
    required this.childId,
    required this.occurredAt,
    this.subject,
    this.skillId,
    this.unit,
    this.correct,
    this.responseTimeMs,
    this.helpUsed = false,
    this.errorTypes = const <ErrorType>[],
    this.payload = const <String, Object?>{},
  });

  final AgentEventType type;
  final String childId;
  final DateTime occurredAt;
  final LearningSubject? subject;
  final SkillId? skillId;
  final String? unit;
  final bool? correct;
  final int? responseTimeMs;
  final bool helpUsed;
  final List<ErrorType> errorTypes;
  final Map<String, Object?> payload;
}

class AgentAction {
  const AgentAction({
    required this.type,
    required this.tone,
    required this.message,
    this.priority = 0,
    this.payload = const <String, Object?>{},
  });

  final AgentActionType type;
  final AgentTone tone;
  final String message;
  final int priority;
  final Map<String, Object?> payload;
}

class AgentDecision {
  const AgentDecision({
    required this.primary,
    this.secondary = const <AgentAction>[],
    this.memoryTags = const <String>[],
    this.recommendationSkillIds = const <SkillId>[],
  });

  final AgentAction primary;
  final List<AgentAction> secondary;
  final List<String> memoryTags;
  final List<SkillId> recommendationSkillIds;
}

class AgentSessionMemory {
  AgentSessionMemory({required this.childId});

  final String childId;
  int totalEvents = 0;
  int correctStreak = 0;
  int wrongStreak = 0;
  int helpCount = 0;
  int readingInterventions = 0;
  final Map<String, int> errorCountsBySkill = <String, int>{};
  final List<String> recentMessages = <String>[];

  void record(AgentEvent event) {
    totalEvents++;
    if (event.correct == true) {
      correctStreak++;
      wrongStreak = 0;
    } else if (event.correct == false) {
      wrongStreak++;
      correctStreak = 0;
    }
    if (event.helpUsed) helpCount++;
    if (event.type == AgentEventType.readingErrorDetected) readingInterventions++;
    final skill = event.skillId?.value ?? event.unit;
    if (skill != null && event.errorTypes.isNotEmpty) {
      errorCountsBySkill[skill] = (errorCountsBySkill[skill] ?? 0) + event.errorTypes.length;
    }
  }

  String pickFresh(String seed, List<String> messages) {
    final available = messages.where((m) => !recentMessages.contains(m)).toList();
    final pool = available.isEmpty ? messages : available;
    final index = (seed.hashCode + totalEvents + wrongStreak * 7 + correctStreak * 3).abs() % pool.length;
    final picked = pool[index];
    recentMessages.add(picked);
    while (recentMessages.length > 12) {
      recentMessages.removeAt(0);
    }
    return picked;
  }
}
