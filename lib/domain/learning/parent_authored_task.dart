import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/learning_attempt_id.dart';
import 'lumo_learning_domain.dart';

String parentTaskOwnerHash(String studentId) =>
    sha256.convert(utf8.encode(studentId)).toString();

String newParentTaskId(String studentId, {bool attempt = false}) =>
    '${attempt ? 'parent' : 'parent-task'}:${parentTaskOwnerHash(studentId)}:'
    '${newLearningAttemptId().substring('attempt-'.length)}';

String parentTaskSubjectLabel(LearningSubject subject) => switch (subject) {
      LearningSubject.deutsch => 'Deutsch',
      LearningSubject.mathematik => 'Mathematik',
      LearningSubject.sachkunde => 'Sachkunde',
      LearningSubject.englisch => 'Englisch',
      LearningSubject.logik => 'Logik',
    };

/// Authored content has its own namespace and never becomes curriculum evidence.
/// Validation is structural; the existing renderer evaluates the child's answer.
class ParentTaskDraft {
  ParentTaskDraft({
    required this.subject,
    required this.grade,
    required String prompt,
    required String correctAnswer,
    required List<String> options,
    String explanation = '',
  })  : prompt = prompt.trim(),
        correctAnswer = correctAnswer.trim(),
        options = List.unmodifiable(options.map((value) => value.trim())),
        explanation = explanation.trim() {
    if (grade < 1 || grade > 4) {
      throw const FormatException('Bitte eine Klasse von 1 bis 4 wählen.');
    }
    if (this.prompt.isEmpty || this.prompt.length > 1500) {
      throw const FormatException('Die Frage braucht 1 bis 1500 Zeichen.');
    }
    if (this.options.length < 2 || this.options.length > 6) {
      throw const FormatException('Bitte insgesamt 2 bis 6 Antworten angeben.');
    }
    final normalized = this.options
        .map((value) => value.replaceAll(RegExp(r'\s+'), ' '))
        .toSet();
    if (this.options.any((value) => value.isEmpty || value.length > 240) ||
        normalized.length != this.options.length) {
      throw const FormatException(
          'Alle Antworten müssen verschieden sein und 1 bis 240 Zeichen haben.');
    }
    if (this.options.where((value) => value == this.correctAnswer).length != 1) {
      throw const FormatException(
          'Die richtige Antwort muss genau einmal in der Auswahl stehen.');
    }
    if (this.explanation.length > 2000) {
      throw const FormatException('Die Erklärung darf höchstens 2000 Zeichen haben.');
    }
  }

  final LearningSubject subject;
  final int grade;
  final String prompt;
  final String correctAnswer;
  final List<String> options;
  final String explanation;
}

class ParentAuthoredTask {
  ParentAuthoredTask({
    required this.id,
    required this.studentId,
    required this.revision,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (studentId.trim().isEmpty || revision < 1 ||
        !RegExp('^parent-task:${parentTaskOwnerHash(studentId)}:[a-f0-9]{32}\$')
            .hasMatch(id)) {
      throw const FormatException('Ungültige Zuordnung der Elternaufgabe.');
    }
  }

  final String id;
  final String studentId;
  final int revision;
  final ParentTaskDraft content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'studentId': studentId,
        'revision': revision,
        'subject': content.subject.name,
        'grade': content.grade,
        'prompt': content.prompt,
        'correctAnswer': content.correctAnswer,
        'options': content.options,
        'explanation': content.explanation,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ParentAuthoredTask.fromJson(Map<String, dynamic> json) =>
      ParentAuthoredTask(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        revision: json['revision'] as int,
        content: ParentTaskDraft(
          subject: LearningSubject.values.byName(json['subject'] as String),
          grade: json['grade'] as int,
          prompt: json['prompt'] as String,
          correctAnswer: json['correctAnswer'] as String,
          options: (json['options'] as List).cast<String>(),
          explanation: json['explanation'] as String? ?? '',
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// Preserve the exact authored content. No generator may replace this task.
  TaskInstance toTaskInstance({
    required String attemptId,
    required DateTime startedAt,
  }) {
    final digest = sha256.convert(utf8.encode(attemptId)).toString();
    final choices = List<String>.of(content.options)
      ..shuffle(Random(int.parse(digest.substring(0, 8), radix: 16)));
    return TaskInstance(
      taskInstanceId: attemptId,
      templateId: 'parent-authored',
      childId: studentId,
      seedHash: digest,
      subject: content.subject,
      skillId: const SkillId('parent-authored'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: {'source': 'parent', 'parentTaskId': id, 'grade': content.grade},
      prompt: content.prompt,
      options: List.unmodifiable([
        for (var index = 0; index < choices.length; index++)
          AnswerOption(id: 'parent-choice-$index', label: choices[index],
              payload: choices[index]),
      ]),
      correctAnswer: content.correctAnswer,
      visualPayload: const VisualPayload(type: VisualType.none),
      helpPayload: const HelpPayload(),
      generatedAt: startedAt,
    );
  }
}

/// The same durable ID spans presentation, history, wallet and UI receipt.
/// Keeping a task snapshot makes editing/deletion harmless to an accepted result.
class ParentTaskAttempt {
  ParentTaskAttempt({
    required this.id,
    required this.task,
    required this.startedAt,
    this.answer,
    this.correct,
    this.hintUsed = false,
    this.answeredAt,
    this.durationMs = 0,
    this.stars = 0,
    this.xp = 0,
    this.completed = false,
  }) {
    if (!RegExp('^parent:${parentTaskOwnerHash(task.studentId)}:[a-f0-9]{32}\$')
            .hasMatch(id) || durationMs < 0 || stars < 0 || stars > 12 ||
        xp < 0 || xp > 70 ||
        (answered && (!task.content.options.contains(answer) ||
            correct == null || answeredAt == null)) ||
        (!answered && (correct != null || answeredAt != null || completed ||
            stars != 0 || xp != 0)) ||
        (correct == false && (stars != 0 || xp != 0))) {
      throw const FormatException('Ungültiger Elternaufgaben-Versuch.');
    }
  }

  final String id;
  final ParentAuthoredTask task;
  final DateTime startedAt;
  final String? answer;
  final bool? correct;
  final bool hintUsed;
  final DateTime? answeredAt;
  final int durationMs;
  final int stars;
  final int xp;
  final bool completed;
  bool get answered => answer != null;

  ParentTaskAttempt finish() => ParentTaskAttempt(
      id: id, task: task, startedAt: startedAt, answer: answer,
      correct: correct, hintUsed: hintUsed, answeredAt: answeredAt,
      durationMs: durationMs, stars: stars, xp: xp, completed: true);

  Map<String, Object?> toJson() => {
        'id': id,
        'task': task.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'answer': answer,
        'correct': correct,
        'hintUsed': hintUsed,
        'answeredAt': answeredAt?.toIso8601String(),
        'durationMs': durationMs,
        'stars': stars,
        'xp': xp,
        'completed': completed,
      };

  factory ParentTaskAttempt.fromJson(Map<String, dynamic> json) =>
      ParentTaskAttempt(
        id: json['id'] as String,
        task: ParentAuthoredTask.fromJson(
            (json['task'] as Map).cast<String, dynamic>()),
        startedAt: DateTime.parse(json['startedAt'] as String),
        answer: json['answer'] as String?,
        correct: json['correct'] as bool?,
        hintUsed: json['hintUsed'] as bool,
        answeredAt: json['answeredAt'] == null ? null
            : DateTime.parse(json['answeredAt'] as String),
        durationMs: json['durationMs'] as int,
        stars: json['stars'] as int,
        xp: json['xp'] as int,
        completed: json['completed'] as bool,
      );
}
