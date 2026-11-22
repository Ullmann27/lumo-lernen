import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/learning/parent_authored_task.dart';
import 'legacy_learning_data.dart';

class ParentTaskWorkspace {
  ParentTaskWorkspace({required this.studentId,
      List<ParentAuthoredTask> tasks = const [], this.activeAttempt})
      : tasks = List.unmodifiable(tasks);

  final String studentId;
  final List<ParentAuthoredTask> tasks;
  final ParentTaskAttempt? activeAttempt;
  bool get hasChildContent => tasks.isNotEmpty || activeAttempt != null;

  Map<String, Object?> toJson() => {
    'version': 1,
    'studentId': studentId,
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'activeAttempt': activeAttempt?.toJson(),
  };
}

/// Every read/modify/write shares LearningStorage's queue. Separate widgets and
/// repository instances cannot overwrite a task added by another operation.
class ParentTaskRepository {
  ParentTaskRepository({required this.studentId, bool Function()? mayWrite})
      : _mayWrite = mayWrite ?? _allowed {
    if (studentId.trim().isEmpty) throw ArgumentError.value(studentId);
  }

  static const storageBase = 'lumo_parent_tasks_v1';
  static final ValueNotifier<String?> changes = ValueNotifier(null);
  static bool _allowed() => true;
  final String studentId;
  final bool Function() _mayWrite;
  String get storageKey => LearningDataNamespace.keyFor(storageBase, studentId);

  Future<ParentTaskWorkspace> load() =>
      LearningStorage.run((prefs) async => _read(prefs));

  ParentTaskWorkspace _read(SharedPreferences prefs) {
    final raw = prefs.getString(storageKey);
    if (raw == null) return ParentTaskWorkspace(studentId: studentId);
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (json['version'] != 1 || json['studentId'] != studentId) {
        throw const FormatException();
      }
      final tasks = (json['tasks'] as List).map((item) =>
          ParentAuthoredTask.fromJson((item as Map).cast<String, dynamic>())).toList();
      final attempt = json['activeAttempt'] == null ? null
          : ParentTaskAttempt.fromJson(
              (json['activeAttempt'] as Map).cast<String, dynamic>());
      if (tasks.any((task) => task.studentId != studentId) ||
          tasks.map((task) => task.id).toSet().length != tasks.length ||
          (attempt != null && attempt.task.studentId != studentId)) {
        throw const FormatException();
      }
      return ParentTaskWorkspace(studentId: studentId,
          tasks: tasks, activeAttempt: attempt);
    } catch (_) {
      // Never erase or silently replace a damaged/future-version collection.
      throw const FormatException(
          'Elternaufgaben konnten nicht gelesen werden. Die gespeicherten Daten bleiben erhalten.');
    }
  }

  Future<ParentTaskWorkspace> _change(
      ParentTaskWorkspace Function(ParentTaskWorkspace) change) async {
    final result = await LearningStorage.run((prefs) async {
      if (!_mayWrite()) throw StateError('Das Kinderprofil ist nicht mehr verfügbar.');
      final next = change(_read(prefs));
      if (!_mayWrite()) throw StateError('Das Kinderprofil ist nicht mehr verfügbar.');
      await LearningStorage.write(prefs, storageKey, jsonEncode(next.toJson()));
      return next;
    });
    // ValueNotifier normally coalesces equal values; every completed mutation
    // must notify both the editor and an already mounted Home card.
    changes.value = null;
    changes.value = studentId;
    return result;
  }

  Future<ParentTaskWorkspace> save(ParentTaskDraft draft,
      {ParentAuthoredTask? previous}) => _change((current) {
    final now = DateTime.now().toUtc();
    final tasks = List<ParentAuthoredTask>.of(current.tasks);
    if (previous == null) {
      tasks.add(ParentAuthoredTask(id: newParentTaskId(studentId),
          studentId: studentId, revision: 1, content: draft,
          createdAt: now, updatedAt: now));
    } else {
      final index = tasks.indexWhere((task) => task.id == previous.id);
      if (previous.studentId != studentId || index < 0 ||
          tasks[index].revision != previous.revision) {
        throw StateError('Die Aufgabe wurde inzwischen geändert. Bitte neu öffnen.');
      }
      tasks[index] = ParentAuthoredTask(id: previous.id, studentId: studentId,
          revision: previous.revision + 1, content: draft,
          createdAt: tasks[index].createdAt, updatedAt: now);
    }
    return ParentTaskWorkspace(studentId: studentId,
        tasks: tasks, activeAttempt: current.activeAttempt);
  });

  Future<ParentTaskWorkspace> remove(ParentAuthoredTask task) => _change((current) {
    final existing = current.tasks.where((value) => value.id == task.id);
    if (task.studentId != studentId || existing.isEmpty ||
        existing.single.revision != task.revision) {
      throw StateError('Die Aufgabe wurde inzwischen geändert. Bitte neu öffnen.');
    }
    final active = current.activeAttempt;
    return ParentTaskWorkspace(studentId: studentId,
        tasks: current.tasks.where((value) => value.id != task.id).toList(),
        activeAttempt: active?.task.id == task.id && !active!.answered
            ? null : active);
  });

  Future<ParentTaskWorkspace> begin(String taskId) => _change((current) {
    if (current.activeAttempt != null) return current;
    final task = current.tasks.where((value) => value.id == taskId).firstOrNull;
    if (task == null) throw StateError('Diese Elternaufgabe wurde entfernt.');
    return ParentTaskWorkspace(studentId: studentId, tasks: current.tasks,
        activeAttempt: ParentTaskAttempt(id: newParentTaskId(studentId, attempt: true),
            task: task, startedAt: DateTime.now().toUtc()));
  });

  Future<ParentTaskWorkspace> accept(ParentTaskAttempt answered) => _change((current) {
    final active = current.activeAttempt;
    if (active == null || active.id != answered.id ||
        answered.task.studentId != studentId || !answered.answered ||
        answered.task.id != active.task.id ||
        answered.task.revision != active.task.revision) {
      throw StateError('Dieser Versuch ist nicht mehr geöffnet.');
    }
    if (active.answered) return current; // First accepted answer is immutable.
    return ParentTaskWorkspace(studentId: studentId,
        tasks: current.tasks, activeAttempt: answered);
  });

  Future<ParentTaskWorkspace> complete(String attemptId) => _change((current) {
    final active = current.activeAttempt;
    if (active == null || active.id != attemptId || !active.answered) {
      throw StateError('Kein gespeichertes Ergebnis für diesen Versuch.');
    }
    return ParentTaskWorkspace(studentId: studentId,
        tasks: current.tasks, activeAttempt: active.finish());
  });

  /// A new practice round starts only after the child explicitly leaves the
  /// prior receipt. An accepted but unfinished result can never be discarded.
  Future<ParentTaskWorkspace> leaveAttempt(String attemptId) => _change((current) {
    final active = current.activeAttempt;
    if (active == null) return current;
    if (active.id != attemptId || (active.answered && !active.completed)) {
      throw StateError('Bitte das offene Ergebnis zuerst fertig speichern.');
    }
    return ParentTaskWorkspace(studentId: studentId, tasks: current.tasks);
  });
}
