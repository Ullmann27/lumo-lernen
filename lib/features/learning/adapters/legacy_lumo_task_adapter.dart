import '../../../core/safe_fallback_pool.dart';
import '../../../core/school_exercise_generator.dart';
import '../../../core/task_quality_guard.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../domain/learning/seed_memory_service.dart';

/// Temporary bridge from the current legacy ExerciseFactory/LumoTask flow to
/// the new adaptive TaskInstance renderer.
///
/// This keeps the current app stable while allowing LearningContent to migrate
/// gradually to AdaptiveTaskRenderer without a big-bang rewrite.
class LegacyLumoTaskAdapter {
  const LegacyLumoTaskAdapter();

  static const _qualityGuard = TaskQualityGuard();
  static const _fallbackPool = SafeFallbackPool();
  static int _fallbackCounter = 0;

  TaskInstance toTaskInstance({
    required LumoTask task,
    required String childId,
    required int difficulty,
    DateTime? now,
  }) {
    final fixedTask = _qualityCheckedTask(task);
    final generatedAt = now ?? DateTime.now();
    final subject = _subject(fixedTask.subject);
    final taskType = fixedTask.handwriting ? TaskType.writingCanvas : _taskType(fixedTask.visual);
    final visualType = _visual(fixedTask.visual, handwriting: fixedTask.handwriting);
    final correctAnswer = _payload(fixedTask.answer);

    final rawSeed = '${fixedTask.id}|$childId|${fixedTask.prompt}|${fixedTask.answer}';
    final seedHash = SeedMemoryService.stableSeedHash(rawSeed);

    return TaskInstance(
      taskInstanceId: 'legacy_${SeedMemoryService.stableSeedHash('$rawSeed|${generatedAt.microsecondsSinceEpoch}')}',
      templateId: 'legacy.${fixedTask.subject}.${fixedTask.unit}',
      childId: childId,
      seedHash: seedHash,
      subject: subject,
      skillId: SkillId('legacy.${fixedTask.subject}.${fixedTask.unit}'.toLowerCase().replaceAll(' ', '_')),
      taskType: taskType,
      difficulty: difficulty,
      parameters: <String, Object?>{
        'legacyId': fixedTask.id,
        'unit': fixedTask.unit,
        'visual': fixedTask.visual,
        if (fixedTask.handwriting) 'symbol': _extractWritingSymbol(fixedTask.prompt),
      },
      prompt: fixedTask.prompt,
      options: fixedTask.choices
          .map((choice) => AnswerOption(
                id: choice,
                label: choice,
                payload: _payload(choice),
              ))
          .toList(growable: false),
      correctAnswer: correctAnswer,
      visualPayload: VisualPayload(
        type: visualType,
        data: _visualData(fixedTask),
      ),
      helpPayload: HelpPayload(
        level: _helpLevel(fixedTask),
        shortHint: fixedTask.explanation,
        guidedSteps: _guidedSteps(fixedTask),
      ),
      generatedAt: generatedAt,
    );
  }

  LumoTask _qualityCheckedTask(LumoTask task) {
    final sanitized = _sanitizeTask(task);
    if (_qualityGuard.validate(sanitized)) return sanitized;
    final fallback = _safeFallbackTask(sanitized);
    final repaired = _sanitizeTask(fallback);
    return _qualityGuard.validate(repaired) ? repaired : fallback;
  }

  LumoTask _safeFallbackTask(LumoTask task) {
    if (task.handwriting) return task;
    return _fallbackPool.pick(
      subject: task.subject == 'Mathematik' ? 'Mathematik' : 'Deutsch',
      grade: task.grade,
      counter: _fallbackCounter++,
      unit: task.unit,
      difficulty: task.difficulty,
      missionTag: task.missionTag,
    );
  }

  /// Sicherheitsnetz fuer alte Generator-Aufgaben:
  /// - falsche Endlaut-Aufgaben werden korrigiert,
  /// - Antwortkarten werden eindeutig gemacht,
  /// - Rechtschreibkarten bekommen keine nur-gross/klein-duplizierten Woerter,
  /// - Bild-Wort-Aufgaben behalten genau eine richtige Antwort.
  LumoTask _sanitizeTask(LumoTask task) {
    var answer = task.answer;
    var choices = List<String>.from(task.choices);
    var explanation = task.explanation;

    final endingMatch = RegExp(r'endet\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(task.prompt);
    if (endingMatch != null) {
      final ending = (endingMatch.group(1) ?? '').toLowerCase();
      final normalizedAnswer = _normalizeWord(answer);
      final hasValidAnswer = normalizedAnswer.endsWith(ending);
      final validChoices = choices.where((choice) => _normalizeWord(choice).endsWith(ending)).toList(growable: false);
      if (!hasValidAnswer || validChoices.length != 1) {
        answer = _wordEndingWith(ending);
        choices = <String>[answer, ..._wordsNotEndingWith(ending, count: 3)];
        explanation = 'Sprich jedes Wort langsam. Nur $answer endet mit $ending.';
      }
    }

    if (task.subject == 'Rechtschreibung' && task.unit == 'Haeufige Woerter') {
      choices = _spellingChoicesFor(answer);
    }

    if (task.unit == 'Wortende') {
      choices = _singleCorrectEndingChoices(answer, task.prompt, choices);
    }

    if (task.unit == 'Wort-Bild schreiben') {
      choices = _distinctChoices(answer, fallbackPool: const <String>['Haus', 'Fuchs', 'Sonne', 'Rose', 'Apfel', 'Ball', 'Igel']);
    } else {
      choices = _distinctChoices(answer, fallbackPool: _fallbackChoicesFor(answer));
    }

    return LumoTask(
      id: task.id,
      grade: task.grade,
      subject: task.subject,
      unit: task.unit,
      prompt: task.prompt,
      choices: choices,
      answer: answer,
      explanation: explanation,
      handwriting: task.handwriting,
      visual: task.visual,
      difficulty: task.difficulty,
      missionTag: task.missionTag,
    );
  }

  List<String> _singleCorrectEndingChoices(String answer, String prompt, List<String> choices) {
    final match = RegExp(r'endet\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(prompt);
    if (match == null) return choices;
    final ending = (match.group(1) ?? '').toLowerCase();
    final correct = _normalizeWord(answer).endsWith(ending) ? answer : _wordEndingWith(ending);
    return <String>[correct, ..._wordsNotEndingWith(ending, count: 4)];
  }

  List<String> _distinctChoices(String answer, {required List<String> fallbackPool, int targetCount = 3}) {
    final result = <String>[];
    void add(String value) {
      final normalized = _normalizeChoice(value);
      if (normalized.isEmpty) return;
      if (result.any((item) => _normalizeChoice(item) == normalized)) return;
      result.add(value);
    }

    add(answer);
    for (final choice in fallbackPool) {
      if (result.length >= targetCount) break;
      add(choice);
    }
    while (result.length < targetCount) {
      add('$answer ${result.length + 1}');
    }
    return result;
  }

  List<String> _fallbackChoicesFor(String answer) {
    final n = int.tryParse(answer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (n != null) return <String>['$n', '${n + 1}', '${n == 0 ? 2 : n - 1}', '${n + 2}'];
    return <String>[answer, 'Haus', 'Sonne', 'Ball', 'Fuchs', 'Mama', 'Igel'];
  }

  List<String> _spellingChoicesFor(String correct) {
    final lower = correct.toLowerCase();
    final distractors = switch (lower) {
      'und' => const <String>['unt', 'un'],
      'ist' => const <String>['is', 'isst'],
      'mama' => const <String>['Mamma', 'Moma'],
      'papa' => const <String>['Pappa', 'Pupa'],
      'haus' => const <String>['Hauß', 'Has'],
      'ball' => const <String>['Bal', 'Bahl'],
      'sonne' => const <String>['Sone', 'Sonne Sonne'],
      'spielen' => const <String>['spilen', 'schpielen'],
      'kommen' => const <String>['komen', 'komenn'],
      'schule' => const <String>['Schuhle', 'schule'],
      'freund' => const <String>['Froind', 'Freunt'],
      'heute' => const <String>['hoite', 'heude'],
      'klein' => const <String>['kline', 'Klein'],
      'gross' => const <String>['gros', 'grohs'],
      _ => <String>['${correct}e', '${correct}n'],
    };
    return _distinctChoices(correct, fallbackPool: <String>[correct, ...distractors, 'Haus', 'Sonne', 'Ball']);
  }

  String _wordEndingWith(String ending) {
    final bank = <String, List<String>>{
      't': <String>['Stift', 'Hut', 'Boot', 'Brot', 'Blatt'],
      'd': <String>['Hund', 'Kind', 'Mond', 'Rad'],
      's': <String>['Haus', 'Fuchs', 'Glas', 'Bus'],
      'e': <String>['Hase', 'Rose', 'Sonne', 'Lampe'],
      'n': <String>['Banane', 'Kaninchen', 'Ofen'],
      'l': <String>['Ball', 'Igel', 'Apfel'],
    };
    final words = bank[ending] ?? <String>['Stift'];
    return words.first;
  }

  List<String> _wordsNotEndingWith(String ending, {required int count}) {
    final bank = <String>['Hase', 'Mama', 'Sonne', 'Rose', 'Apfel', 'Fuchs', 'Ball', 'Igel', 'Schule', 'Banane'];
    return bank
        .where((word) => !_normalizeWord(word).endsWith(ending))
        .take(count)
        .toList(growable: false);
  }

  String _normalizeChoice(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _normalizeWord(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');

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
    final word = RegExp(r'Schreibe\s+das\s+Wort:\s*(.+)$', caseSensitive: false).firstMatch(prompt);
    if (word != null) return word.group(1)!.trim();

    final copySentence = RegExp(r'Schreibe:\s*(.+)$', caseSensitive: false).firstMatch(prompt);
    if (copySentence != null) return copySentence.group(1)!.trim();

    final traceLetter = RegExp(r'(?:Buchstaben|grosses|großes)\s+([A-ZÄÖÜ])\b', caseSensitive: false).firstMatch(prompt);
    if (traceLetter != null) return traceLetter.group(1)!.toUpperCase();

    final number = RegExp(r'Zahl\s+(\d{1,2})', caseSensitive: false).firstMatch(prompt);
    if (number != null) return number.group(1)!;

    final singleLetter = RegExp(r'\b([A-ZÄÖÜ])\b').firstMatch(prompt);
    if (singleLetter != null) return singleLetter.group(1)!;

    return 'A';
  }
}
