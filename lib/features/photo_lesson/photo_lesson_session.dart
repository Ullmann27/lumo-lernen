import 'dart:convert';

import '../../core/learning_attempt_id.dart';
import '../../core/legacy_learning_data.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/task_quality_guard.dart';
import '../../core/writing_target_parser.dart';

/// A checked practice view and its actual attempts. The scanned image and OCR
/// text are deliberately not part of this local, per-child checkpoint.
class PhotoLessonAttempt {
  const PhotoLessonAttempt({
    required this.id,
    required this.taskId,
    required this.given,
    required this.correct,
    required this.helpLevel,
  });

  final String id, taskId, given;

  /// Null means an ungraded handwriting/shape practice, never a wrong answer.
  final bool? correct;
  final int helpLevel;

  Map<String, Object?> toJson() => {
        'id': id,
        'taskId': taskId,
        'given': given,
        'correct': correct,
        'helpLevel': helpLevel,
      };
}

class PhotoLessonSession {
  PhotoLessonSession({
    required this.id,
    required List<LumoTask> tasks,
    this.revision = 0,
    this.cursor = 0,
    this.syncedAttempts = 0,
    List<PhotoLessonAttempt> attempts = const [],
    Map<String, int> helpLevels = const {},
  })  : tasks = List.unmodifiable(tasks),
        attempts = List.unmodifiable(attempts),
        helpLevels = Map.unmodifiable(helpLevels);

  factory PhotoLessonSession.start(List<LumoTask> tasks) {
    final result = PhotoLessonSession(id: newLearningAttemptId(), tasks: tasks);
    PhotoLessonSession.fromJson(result.toJson());
    return result;
  }

  final String id;
  final List<LumoTask> tasks;
  final int revision, cursor, syncedAttempts;
  final List<PhotoLessonAttempt> attempts;
  final Map<String, int> helpLevels;

  LumoTask get task => tasks[cursor];
  int get helpLevel => helpLevels[task.id] ?? 0;
  List<PhotoLessonAttempt> attemptsFor(String taskId) =>
      attempts.where((a) => a.taskId == taskId).toList(growable: false);
  bool completed(String taskId) =>
      attempts.any((a) => a.taskId == taskId && a.correct != false);
  bool get currentCompleted => completed(task.id);
  int get completedCount => tasks.where((t) => completed(t.id)).length;
  bool get complete => completedCount == tasks.length;
  bool get needsEvidenceSync => syncedAttempts < attempts.length;

  /// Only first, unassisted correct attempts count as independent here.
  int get independentCount => tasks.where((task) {
        final values = attemptsFor(task.id);
        return values.isNotEmpty &&
            values.first.correct == true &&
            values.first.helpLevel == 0;
      }).length;

  LumoTask? get recommendedPractice {
    for (final task in tasks) {
      final values = attemptsFor(task.id);
      if (values.any((a) => a.correct == false || a.helpLevel > 0)) return task;
    }
    return null;
  }

  PhotoLessonSession change({
    int? cursor,
    int? syncedAttempts,
    List<PhotoLessonAttempt>? attempts,
    Map<String, int>? helpLevels,
  }) =>
      PhotoLessonSession(
        id: id,
        tasks: tasks,
        revision: revision + 1,
        cursor: cursor ?? this.cursor,
        syncedAttempts: syncedAttempts ?? this.syncedAttempts,
        attempts: attempts ?? this.attempts,
        helpLevels: helpLevels ?? this.helpLevels,
      );

  PhotoLessonSession withHelp(int level) {
    if (level < 1 || level > 3) throw ArgumentError.value(level, 'level');
    final previous = helpLevel;
    return change(helpLevels: {
      ...helpLevels,
      task.id: level > previous ? level : previous
    });
  }

  PhotoLessonSession answer(String given, {required bool? correct}) {
    if (currentCompleted || attempts.length >= 100) {
      throw StateError('This task cannot accept another attempt');
    }
    return change(attempts: [
      ...attempts,
      PhotoLessonAttempt(
        id: '$id.a${attempts.length + 1}',
        taskId: task.id,
        given: given,
        correct: correct,
        helpLevel: helpLevel,
      )
    ]);
  }

  Map<String, Object?> toJson() => {
        'version': 1,
        'id': id,
        'revision': revision,
        'cursor': cursor,
        'syncedAttempts': syncedAttempts,
        'helpLevels': helpLevels,
        'attempts': attempts.map((a) => a.toJson()).toList(growable: false),
        'tasks': tasks
            .map((t) => {
                  'id': t.id,
                  'grade': t.grade,
                  'subject': t.subject,
                  'unit': t.unit,
                  'prompt': t.prompt,
                  'choices': t.choices,
                  'answer': t.answer,
                  'explanation': t.explanation,
                  'handwriting': t.handwriting,
                  'visual': t.visual,
                  'difficulty': t.difficulty,
                  'missionTag': t.missionTag,
                })
            .toList(growable: false),
      };

  factory PhotoLessonSession.fromJson(Object? value) {
    const guard = TaskQualityGuard();
    Never invalid() =>
        throw const FormatException('Unsupported photo practice checkpoint');
    bool text(Object? value, int max) =>
        value is String && value.isNotEmpty && value.length <= max;
    if (value is! Map<String, dynamic> ||
        value.length != 8 ||
        value['version'] != 1 ||
        !text(value['id'], 120) ||
        value['revision'] is! int ||
        (value['revision'] as int) < 0 ||
        value['cursor'] is! int ||
        value['syncedAttempts'] is! int ||
        value['tasks'] is! List ||
        value['attempts'] is! List ||
        value['helpLevels'] is! Map<String, dynamic>) {
      invalid();
    }
    final rawTasks = value['tasks'] as List;
    if (rawTasks.isEmpty || rawTasks.length > 5) invalid();
    final tasks = <LumoTask>[];
    for (final raw in rawTasks) {
      if (raw is! Map<String, dynamic> ||
          raw.length != 12 ||
          !text(raw['id'], 180) ||
          !text(raw['subject'], 80) ||
          !text(raw['unit'], 120) ||
          !text(raw['prompt'], 3000) ||
          !text(raw['answer'], 400) ||
          !text(raw['explanation'], 3000) ||
          !text(raw['visual'], 80) ||
          !text(raw['missionTag'], 80) ||
          raw['grade'] is! int ||
          raw['difficulty'] is! int ||
          raw['handwriting'] is! bool ||
          raw['choices'] is! List ||
          (raw['choices'] as List).length > 12 ||
          (raw['choices'] as List).any((c) => !text(c, 400))) {
        invalid();
      }
      final task = LumoTask(
        id: raw['id'] as String,
        grade: raw['grade'] as int,
        subject: raw['subject'] as String,
        unit: raw['unit'] as String,
        prompt: raw['prompt'] as String,
        choices: List<String>.from(raw['choices'] as List),
        answer: raw['answer'] as String,
        explanation: raw['explanation'] as String,
        handwriting: raw['handwriting'] as bool,
        visual: raw['visual'] as String,
        difficulty: raw['difficulty'] as int,
        missionTag: raw['missionTag'] as String,
      );
      if (!guard.validate(task) || tasks.any((t) => t.id == task.id)) invalid();
      tasks.add(task);
    }
    final cursor = value['cursor'] as int;
    if (cursor < 0 || cursor >= tasks.length) invalid();
    final levels = <String, int>{};
    for (final entry in (value['helpLevels'] as Map<String, dynamic>).entries) {
      if (!tasks.any((t) => t.id == entry.key) ||
          entry.value is! int ||
          (entry.value as int) < 1 ||
          (entry.value as int) > 3) {
        invalid();
      }
      levels[entry.key] = entry.value as int;
    }
    final attempts = <PhotoLessonAttempt>[];
    final completed = <String>{};
    for (final raw in value['attempts'] as List) {
      if (raw is! Map<String, dynamic> ||
          raw.length != 5 ||
          raw['id'] != '${value['id']}.a${attempts.length + 1}' ||
          !text(raw['given'], 400) ||
          raw['taskId'] is! String ||
          !(raw['correct'] == null || raw['correct'] is bool) ||
          raw['helpLevel'] is! int ||
          (raw['helpLevel'] as int) < 0 ||
          (raw['helpLevel'] as int) > (levels[raw['taskId']] ?? 0) ||
          completed.contains(raw['taskId'])) {
        invalid();
      }
      final candidates = tasks.where((t) => t.id == raw['taskId']);
      if (candidates.length != 1) invalid();
      final task = candidates.single;
      final correct = raw['correct'] as bool?;
      if (correct == null) {
        if (!task.handwriting && task.visual != 'shape_trace') invalid();
      } else if (task.visual == 'shape_trace') {
        invalid();
      } else if (task.handwriting) {
        String clean(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (correct !=
            (clean(raw['given'] as String) ==
                clean(WritingTargetParser.parse(task.prompt)))) {
          invalid();
        }
      } else {
        if (!task.choices.contains(raw['given']) ||
            correct != guard.matchesAnswer(task, raw['given'] as String)) {
          invalid();
        }
      }
      attempts.add(PhotoLessonAttempt(
        id: raw['id'] as String,
        taskId: task.id,
        given: raw['given'] as String,
        correct: correct,
        helpLevel: raw['helpLevel'] as int,
      ));
      if (correct != false) completed.add(task.id);
    }
    final synced = value['syncedAttempts'] as int;
    if (attempts.length > 100 || synced < 0 || synced > attempts.length) {
      invalid();
    }
    return PhotoLessonSession(
      id: value['id'] as String,
      tasks: tasks,
      revision: value['revision'] as int,
      cursor: cursor,
      syncedAttempts: synced,
      attempts: attempts,
      helpLevels: levels,
    );
  }
}

class PhotoLessonSessionRepository {
  PhotoLessonSessionRepository(
      {required this.studentId, required this.mayWrite});
  static const storageKey = 'lumo_photo_lesson_session_v1';
  final String studentId;
  final bool Function() mayWrite;

  String get _key => LearningDataNamespace.keyFor(storageKey, studentId);

  Future<PhotoLessonSession?> load() => LearningStorage.run((prefs) async {
        final raw = prefs.getString(_key);
        if (raw == null || raw == 'null') return null;
        if (raw.length > 100000) {
          throw const FormatException('Photo checkpoint too large');
        }
        return PhotoLessonSession.fromJson(jsonDecode(raw));
      });

  /// The expected revision rejects a stale screen. A failed platform write is
  /// reloaded by LearningStorage, so its optimistic cache cannot fake success.
  Future<void> save(PhotoLessonSession value,
          {PhotoLessonSession? replacing}) =>
      LearningStorage.run((prefs) async {
        PhotoLessonSession.fromJson(jsonDecode(jsonEncode(value.toJson())));
        if (!mayWrite()) throw StateError('The learning profile changed');
        final raw = prefs.getString(_key);
        final previous = raw == null || raw == 'null'
            ? null
            : PhotoLessonSession.fromJson(jsonDecode(raw));
        if (previous?.id != replacing?.id ||
            previous?.revision != replacing?.revision) {
          throw StateError('A newer photo practice checkpoint exists');
        }
        await LearningStorage.write(prefs, _key, jsonEncode(value.toJson()));
      });
}
