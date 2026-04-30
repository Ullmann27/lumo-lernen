import '../../../core/school_exercise_generator.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../domain/learning/seed_memory_service.dart';

/// Temporary bridge from the current legacy ExerciseFactory/LumoTask flow to
/// the new adaptive TaskInstance renderer.
///
/// This keeps the current app stable while allowing LearningContent to migrate
/// gradually to AdaptiveTaskRenderer without a big-bang rewrite.
class LegacyLumoTaskAdapter {
  const LegacyLumoTaskAdapter();

  TaskInstance toTaskInstance({
    required LumoTask task,
    required String childId,
    required int difficulty,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final subject = _subject(task.subject);
    final taskType = task.handwriting ? TaskType.writingCanvas : TaskType.multipleChoice;
    final visualType = _visual(task.visual, handwriting: task.handwriting);
    final correctAnswer = _payload(task.answer);

    final rawSeed = '${task.id}|$childId|${task.prompt}|${task.answer}';
    final seedHash = SeedMemoryService.stableSeedHash(rawSeed);

    return TaskInstance(
      taskInstanceId: 'legacy_${SeedMemoryService.stableSeedHash('$rawSeed|${generatedAt.microsecondsSinceEpoch}')}',
      templateId: 'legacy.${task.subject}.${task.unit}',
      childId: childId,
      seedHash: seedHash,
      subject: subject,
      skillId: SkillId('legacy.${task.subject}.${task.unit}'.toLowerCase().replaceAll(' ', '_')),
      taskType: taskType,
      difficulty: difficulty,
      parameters: <String, Object?>{
        'legacyId': task.id,
        'unit': task.unit,
        'visual': task.visual,
        if (task.handwriting) 'symbol': _extractWritingSymbol(task.prompt),
      },
      prompt: task.prompt,
      options: task.choices
          .map((choice) => AnswerOption(
                id: choice,
                label: choice,
                payload: _payload(choice),
              ))
          .toList(growable: false),
      correctAnswer: correctAnswer,
      visualPayload: VisualPayload(
        type: visualType,
        data: _visualData(task),
      ),
      helpPayload: HelpPayload(
        level: task.handwriting ? 1 : 0,
        shortHint: task.explanation,
      ),
      generatedAt: generatedAt,
    );
  }

  LearningSubject _subject(String value) {
    return switch (value) {
      'Deutsch' || 'Rechtschreibung' || 'Schreiben' || 'Lesen' => LearningSubject.deutsch,
      'Sachunterricht' => LearningSubject.sachkunde,
      _ => LearningSubject.mathematik,
    };
  }

  VisualType _visual(String value, {required bool handwriting}) {
    if (handwriting) return VisualType.writingPath;
    return switch (value) {
      'dots' => VisualType.dots,
      'line' => VisualType.numberLine,
      'sequence' => VisualType.numberLine,
      'shape' => VisualType.shape,
      'syllables' => VisualType.syllables,
      'writing' => VisualType.writingPath,
      _ => VisualType.none,
    };
  }

  Map<String, Object?> _visualData(LumoTask task) {
    if (task.handwriting) {
      return <String, Object?>{'symbol': _extractWritingSymbol(task.prompt)};
    }

    final plus = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(task.prompt);
    if (plus != null) {
      return <String, Object?>{
        'operation': 'addition',
        'left': int.tryParse(plus.group(1) ?? '0') ?? 0,
        'right': int.tryParse(plus.group(2) ?? '0') ?? 0,
      };
    }

    final minus = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(task.prompt);
    if (minus != null) {
      return <String, Object?>{
        'operation': 'subtraction',
        'start': int.tryParse(minus.group(1) ?? '0') ?? 0,
        'takeAway': int.tryParse(minus.group(2) ?? '0') ?? 0,
      };
    }

    if (task.visual == 'syllables') {
      final match = RegExp(r'hat\s+([^?]+)\?').firstMatch(task.prompt);
      return <String, Object?>{'word': match?.group(1)?.trim()};
    }

    return const <String, Object?>{};
  }

  Object _payload(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
    return number ?? value;
  }

  String _extractWritingSymbol(String prompt) {
    final letter = RegExp(r'\b([A-Z])\b').firstMatch(prompt);
    if (letter != null) return letter.group(1)!;
    final number = RegExp(r'\b(\d{1,2})\b').firstMatch(prompt);
    if (number != null) return number.group(1)!;
    return 'A';
  }
}
