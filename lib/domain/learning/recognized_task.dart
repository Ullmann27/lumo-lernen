import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/learning_attempt_id.dart';
import 'lumo_learning_domain.dart';
import 'reward_engine.dart';

enum RecognizedTaskKind { calculation, firstLetter, arithmeticSequence }

String recognizedOwnerHash(String ownerId) =>
    sha256.convert(utf8.encode(ownerId)).toString();

/// A deliberately small local grammar. The complete input must match; no
/// expression evaluation, network call or replacement curriculum task occurs.
class RecognizedTask {
  RecognizedTask._({
    required this.source,
    required this.kind,
    required this.prompt,
    required this.answer,
    required List<String> options,
    required this.explanation,
  }) : options = List.unmodifiable(options);

  static const maxInputLength = 240;
  static const maxOperand = 999;
  static const maxResult = 9999;
  final String source;
  final RecognizedTaskKind kind;
  final String prompt;
  final String answer;
  final List<String> options;
  final String explanation;

  String get label => switch (kind) {
        RecognizedTaskKind.calculation => 'Rechnung',
        RecognizedTaskKind.firstLetter => 'Anfangsbuchstabe',
        RecognizedTaskKind.arithmeticSequence => 'Zahlenfolge',
      };
  LearningSubject get subject => switch (kind) {
        RecognizedTaskKind.calculation => LearningSubject.mathematik,
        RecognizedTaskKind.firstLetter => LearningSubject.deutsch,
        RecognizedTaskKind.arithmeticSequence => LearningSubject.logik,
      };

  static RecognizedTask parse(String input) {
    if (input.length > maxInputLength ||
        RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(input)) {
      throw const FormatException(
          'Bitte höchstens 240 Zeichen ohne Sondersteuerzeichen eingeben.');
    }
    final source =
        input.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll('−', '-');
    if (source.isEmpty) {
      throw const FormatException('Bitte zuerst eine Aufgabe eingeben.');
    }
    final calculation = RegExp(
            r'^([+-]?\d{1,4})\s*([+\-xX×*])\s*([+-]?\d{1,4})(?:\s*=\s*\??|\s*\?)?$')
        .firstMatch(source);
    if (calculation != null) {
      final left = int.parse(calculation.group(1)!);
      final right = int.parse(calculation.group(3)!);
      if (left.abs() > maxOperand || right.abs() > maxOperand) {
        throw const FormatException(
            'Für Rechnungen sind ganze Zahlen von -999 bis 999 möglich.');
      }
      final op = calculation.group(2)!;
      final symbol = op == '+' || op == '-' ? op : '×';
      final answer = switch (symbol) {
        '+' => left + right,
        '-' => left - right,
        _ => left * right
      };
      if (answer.abs() > maxResult) {
        throw const FormatException(
            'Das Ergebnis muss zwischen -9999 und 9999 liegen.');
      }
      final expression = '$left $symbol ${right < 0 ? '($right)' : right}';
      return RecognizedTask._(
          source: source,
          kind: RecognizedTaskKind.calculation,
          prompt: '$expression = ?',
          answer: '$answer',
          options: _numberOptions(answer),
          explanation: '$expression = $answer.');
    }

    const word = r'([A-Za-zÄÖÜäöüß]{1,40})';
    final letterPatterns = [
      RegExp('^Anfangsbuchstabe(?: von)? $word\\??\$', caseSensitive: false),
      RegExp('^Mit welchem Buchstaben beginnt $word\\??\$',
          caseSensitive: false),
      RegExp('^$word Anfangsbuchstabe\\??\$', caseSensitive: false),
    ];
    for (final pattern in letterPatterns) {
      final match = pattern.firstMatch(source);
      if (match == null) continue;
      final value = match.group(1)!;
      final first = value.substring(0, 1).toUpperCase();
      if (first.length != 1 || first == 'ß' || first == 'ẞ') {
        throw const FormatException(
            'Bitte ein Wort mit eindeutigem Anfangsbuchstaben verwenden.');
      }
      final choices = <String>{first};
      for (final candidate in const ['A', 'B', 'F', 'H', 'L', 'M', 'S', 'W']) {
        choices.add(candidate);
        if (choices.length == 4) break;
      }
      return RecognizedTask._(
          source: source,
          kind: RecognizedTaskKind.firstLetter,
          prompt: 'Mit welchem Buchstaben beginnt „$value“?',
          answer: first,
          options: choices.toList()..sort(),
          explanation: '„$value“ beginnt mit $first.');
    }

    final sequence =
        RegExp(r'^([+-]?\d{1,4}(?:\s*,\s*[+-]?\d{1,4}){2,7})\s*,?\s*\?$')
                .firstMatch(source) ??
            RegExp(r'^([+-]?\d{1,4}(?:\s+[+-]?\d{1,4}){2,7})\s*\?$')
                .firstMatch(source);
    if (sequence != null) {
      final numbers = sequence
          .group(1)!
          .split(RegExp(r'\s*,\s*|\s+'))
          .map(int.parse)
          .toList();
      final difference = numbers[1] - numbers[0];
      for (var i = 2; i < numbers.length; i++) {
        if (numbers[i] - numbers[i - 1] != difference) {
          throw const FormatException(
              'Die Abstände sind nicht überall gleich. Diese Zahlenfolge ist nicht eindeutig unterstützt.');
        }
      }
      final answer = numbers.last + difference;
      if (numbers.any((value) => value.abs() > maxResult) ||
          answer.abs() > maxResult) {
        throw const FormatException(
            'Zahlenfolge und nächster Wert müssen zwischen -9999 und 9999 liegen.');
      }
      return RecognizedTask._(
          source: source,
          kind: RecognizedTaskKind.arithmeticSequence,
          prompt: 'Setze fort: ${numbers.join(', ')}, ?',
          answer: '$answer',
          options: _numberOptions(answer),
          explanation: difference == 0
              ? 'Die Zahl bleibt gleich. Der nächste Wert ist $answer.'
              : 'Der Abstand ist jedes Mal $difference. Nach ${numbers.last} kommt $answer.');
    }
    throw const FormatException(
        'Noch nicht eindeutig erkannt. Beispiele: 12 + 7, 6 × 3, Anfangsbuchstabe Mama oder 2, 4, 6, ?.');
  }

  static List<String> _numberOptions(int answer) {
    final choices = <int>{answer};
    for (final delta in const [1, -1, 2, -2, 3, -3]) {
      if ((answer + delta).abs() <= maxResult) choices.add(answer + delta);
      if (choices.length == 4) break;
    }
    return (choices.toList()..sort()).map((value) => '$value').toList();
  }

  Map<String, Object?> toJson() => {
        'source': source,
        'kind': kind.name,
        'prompt': prompt,
        'answer': answer,
        'options': options,
        'explanation': explanation
      };

  factory RecognizedTask.fromJson(Map<String, dynamic> json) {
    final parsed = parse(json['source'] as String);
    if (jsonEncode(parsed.toJson()) != jsonEncode(json)) {
      throw const FormatException(
          'Die gespeicherte Aufgabe stimmt nicht mit ihrer Eingabe überein.');
    }
    return parsed;
  }

  TaskInstance toTaskInstance(
      {required String attemptId,
      required String ownerId,
      required DateTime startedAt}) {
    final hash = sha256.convert(utf8.encode(attemptId)).toString();
    final choices = List<String>.of(options)
      ..shuffle(Random(int.parse(hash.substring(0, 8), radix: 16)));
    return TaskInstance(
        taskInstanceId: attemptId,
        templateId: 'typed-recognition',
        childId: ownerId,
        seedHash: hash,
        subject: subject,
        skillId: SkillId('typed-recognition.${kind.name}'),
        taskType: TaskType.multipleChoice,
        difficulty: 1,
        parameters: {'source': 'typed-recognition', 'kind': kind.name},
        prompt: prompt,
        options: List.unmodifiable([
          for (var i = 0; i < choices.length; i++)
            AnswerOption(
                id: 'recognized-$i', label: choices[i], payload: choices[i])
        ]),
        correctAnswer: answer,
        visualPayload: const VisualPayload(type: VisualType.none),
        helpPayload: HelpPayload(
            shortHint: switch (kind) {
              RecognizedTaskKind.calculation =>
                'Achte auf das Rechenzeichen und die Vorzeichen.',
              RecognizedTaskKind.firstLetter =>
                'Sprich das Wort langsam. Höre auf seinen Anfang.',
              RecognizedTaskKind.arithmeticSequence =>
                'Vergleiche alle Abstände zwischen benachbarten Zahlen.',
            },
            guidedSteps: [explanation]),
        generatedAt: startedAt);
  }
}

/// One durable identity spans task display, accepted answer, log and wallet.
class RecognizedTaskAttempt {
  RecognizedTaskAttempt(
      {required this.id,
      required this.ownerId,
      required this.task,
      required this.startedAt,
      this.answer,
      this.hintUsed = false,
      this.answeredAt,
      this.durationMs = 0,
      this.stars = 0,
      this.xp = 0,
      this.completed = false}) {
    if (ownerId.isEmpty ||
        ownerId.length > 160 ||
        !RegExp('^recognized:${recognizedOwnerHash(ownerId)}:[a-f0-9]{32}\$')
            .hasMatch(id) ||
        durationMs < 0 ||
        durationMs > 86400000 ||
        (!answered &&
            (answeredAt != null ||
                stars != 0 ||
                xp != 0 ||
                completed ||
                hintUsed)) ||
        (answered && (!task.options.contains(answer) || answeredAt == null))) {
      throw const FormatException(
          'Ungültiger Versuch für die erkannte Aufgabe.');
    }
    if (answered) {
      final reward = _reward(answer!, hintUsed, durationMs);
      if (stars != reward.stars || xp != reward.xp) {
        throw const FormatException(
            'Der Aufgabenbeleg enthält widersprüchliche Sterne.');
      }
    }
  }
  final String id, ownerId;
  final RecognizedTask task;
  final DateTime startedAt;
  final String? answer;
  final bool hintUsed;
  final DateTime? answeredAt;
  final int durationMs, stars, xp;
  final bool completed;
  bool get answered => answer != null;
  bool get correct => answer == task.answer;

  factory RecognizedTaskAttempt.begin(String ownerId, RecognizedTask task) =>
      RecognizedTaskAttempt(
          id: 'recognized:${recognizedOwnerHash(ownerId)}:'
              '${newLearningAttemptId().substring('attempt-'.length)}',
          ownerId: ownerId,
          task: task,
          startedAt: DateTime.now().toUtc());

  RewardDelta _reward(String value, bool hint, int duration) =>
      const RewardEngine().calculateAnswerReward(
          result: TaskResult(
              taskInstanceId: id,
              childId: ownerId,
              skillId: SkillId('typed-recognition.${task.kind.name}'),
              correct: value == task.answer,
              helpUsed: hint,
              responseTimeMs: duration));

  RecognizedTaskAttempt accept(String value,
      {required bool hintUsed, DateTime? now}) {
    if (answered) return this;
    final at = (now ?? DateTime.now()).toUtc();
    final duration = at.difference(startedAt).inMilliseconds.clamp(0, 86400000);
    final reward = _reward(value, hintUsed, duration);
    return RecognizedTaskAttempt(
        id: id,
        ownerId: ownerId,
        task: task,
        startedAt: startedAt,
        answer: value,
        hintUsed: hintUsed,
        answeredAt: at,
        durationMs: duration,
        stars: reward.stars,
        xp: reward.xp);
  }

  RecognizedTaskAttempt finish() => RecognizedTaskAttempt(
      id: id,
      ownerId: ownerId,
      task: task,
      startedAt: startedAt,
      answer: answer,
      hintUsed: hintUsed,
      answeredAt: answeredAt,
      durationMs: durationMs,
      stars: stars,
      xp: xp,
      completed: true);

  Map<String, Object?> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'task': task.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'answer': answer,
        'hintUsed': hintUsed,
        'answeredAt': answeredAt?.toIso8601String(),
        'durationMs': durationMs,
        'stars': stars,
        'xp': xp,
        'completed': completed
      };

  factory RecognizedTaskAttempt.fromJson(Map<String, dynamic> json) =>
      RecognizedTaskAttempt(
          id: json['id'] as String,
          ownerId: json['ownerId'] as String,
          task: RecognizedTask.fromJson(
              (json['task'] as Map).cast<String, dynamic>()),
          startedAt: DateTime.parse(json['startedAt'] as String),
          answer: json['answer'] as String?,
          hintUsed: json['hintUsed'] as bool,
          answeredAt: json['answeredAt'] == null
              ? null
              : DateTime.parse(json['answeredAt'] as String),
          durationMs: json['durationMs'] as int,
          stars: json['stars'] as int,
          xp: json['xp'] as int,
          completed: json['completed'] as bool);
}
