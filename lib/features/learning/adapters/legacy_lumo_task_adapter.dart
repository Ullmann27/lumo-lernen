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
    final taskType = task.handwriting ? TaskType.writingCanvas : _taskType(task.visual);
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
        level: _helpLevel(task),
        shortHint: task.explanation,
        guidedSteps: _guidedSteps(task),
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

  TaskType _taskType(String value) {
    return switch (value) {
      'line' => TaskType.numberLine,
      'sequence' => TaskType.numberLine,
      'dots' => TaskType.dotGroups,
      'ten_ones' => TaskType.tenOnes,
      'number_house' => TaskType.multipleChoice,
      'sound_choice' => TaskType.multipleChoice,
      'writing_line' => TaskType.multipleChoice,
      'blitz_grid' => TaskType.multipleChoice,
      _ => TaskType.multipleChoice,
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
      'ten_ones' => VisualType.tenOnes,
      'number_house' => VisualType.none,
      'sound_choice' => VisualType.none,
      'writing_line' => VisualType.none,
      'blitz_grid' => VisualType.none,
      _ => VisualType.none,
    };
  }

  Map<String, Object?> _visualData(LumoTask task) {
    if (task.handwriting) {
      return <String, Object?>{'symbol': _extractWritingSymbol(task.prompt)};
    }

    if (task.visual == 'number_house') {
      return _numberHouseData(task);
    }

    if (task.visual == 'sound_choice') {
      return _soundChoiceData(task);
    }

    if (task.visual == 'writing_line') {
      return _writingLineData(task);
    }

    if (task.visual == 'blitz_grid') {
      return _blitzGridData(task);
    }

    if (task.visual == 'ten_ones') {
      final n = RegExp(r'(\d+)').firstMatch(task.prompt);
      final value = int.tryParse(n?.group(1) ?? '') ?? 0;
      return <String, Object?>{'tens': value ~/ 10, 'ones': value % 10, 'value': value};
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

  Map<String, Object?> _numberHouseData(LumoTask task) {
    final match = RegExp(r'Rechenhaus\s+(\d+):\s*(\d+)\s*\+\s*\?').firstMatch(task.prompt);
    final target = int.tryParse(match?.group(1) ?? '') ?? _payloadInt(task.answer);
    final left = int.tryParse(match?.group(2) ?? '') ?? 0;
    final right = _payloadInt(task.answer);
    return <String, Object?>{
      'target': target,
      'left': left,
      'right': right,
      'rows': <Object?>[
        <Object?>[left, right],
        <Object?>[(left + 1).clamp(0, target), (target - left - 1).clamp(0, target)],
        <Object?>[0, target],
      ],
    };
  }

  Map<String, Object?> _soundChoiceData(LumoTask task) {
    final match = RegExp(r'St oder Sp\?\s*(.+)$').firstMatch(task.prompt);
    return <String, Object?>{
      'word': match?.group(1)?.trim() ?? task.prompt,
      'choices': const <String>['St', 'Sp'],
    };
  }

  Map<String, Object?> _writingLineData(LumoTask task) {
    final plural = RegExp(r'Aus 1 mach 2:\s*(.+)\s*->').firstMatch(task.prompt);
    final wordImage = RegExp(r'Bild\s*(.+)\?').firstMatch(task.prompt);
    return <String, Object?>{
      'word': plural?.group(1)?.trim() ?? task.answer,
      'target': task.answer,
      'icon': wordImage?.group(1)?.trim(),
    };
  }

  Map<String, Object?> _blitzGridData(LumoTask task) {
    final main = task.prompt.replaceFirst('Blitzlicht:', '').replaceAll('?', '').trim();
    return <String, Object?>{
      'items': <Object?>[main, _variantExpression(main, 1), _variantExpression(main, 2), _variantExpression(main, 3)],
    };
  }

  List<String> _guidedSteps(LumoTask task) {
    if (task.visual == 'line' && task.prompt.contains('-')) {
      final minus = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(task.prompt);
      final start = int.tryParse(minus?.group(1) ?? '') ?? 0;
      final takeAway = int.tryParse(minus?.group(2) ?? '') ?? 0;
      if (start > 10 && takeAway > start - 10) {
        final first = start - 10;
        final second = takeAway - first;
        return <String>['Erst $first weg bis zur 10.', 'Dann noch $second weg.', 'Jetzt bleibt ${start - takeAway}.'];
      }
    }
    if (task.visual == 'number_house') {
      return const <String>['Schau auf die Dachzahl.', 'Welche Zahl fehlt im Zimmer?', 'Beide Zahlen zusammen ergeben das Dach.'];
    }
    if (task.visual == 'sound_choice') {
      return const <String>['Sprich das Wort langsam.', 'Hoerst du am Anfang St oder Sp?', 'Waehle die passende Karte.'];
    }
    return const <String>[];
  }

  int _helpLevel(LumoTask task) {
    if (task.handwriting) return 1;
    if (task.visual == 'line' && task.prompt.contains('-')) return 2;
    if (task.visual == 'number_house' || task.visual == 'sound_choice' || task.visual == 'writing_line') return 1;
    return 0;
  }

  String _variantExpression(String expression, int offset) {
    final match = RegExp(r'(\d+)\s*([+-])\s*(\d+)').firstMatch(expression);
    if (match == null) return expression;
    final left = (int.tryParse(match.group(1) ?? '') ?? 0) + offset;
    final op = match.group(2) ?? '+';
    final right = int.tryParse(match.group(3) ?? '') ?? 0;
    return '$left $op $right =';
  }

  Object _payload(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
    return number ?? value;
  }

  int _payloadInt(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
  }

  String _extractWritingSymbol(String prompt) {
    final letter = RegExp(r'\b([A-Z])\b').firstMatch(prompt);
    if (letter != null) return letter.group(1)!;
    final number = RegExp(r'\b(\d{1,2})\b').firstMatch(prompt);
    if (number != null) return number.group(1)!;
    return 'A';
  }
}
