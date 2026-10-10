import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/school/school_model.dart';
import 'legacy_learning_data.dart';

/// Lokale Ablage der Schuldaten. Alle Änderungen laufen über diese Klasse,
/// damit Berechtigung und Persistenz an einer Stelle liegen.
class SchoolRepository extends ChangeNotifier {
  static const _key = 'lumo_school_v1';
  static const _activeKey = 'lumo_school_active_student_v1';

  /// Kennung der Lehrkraft auf diesem Gerät (ohne Konto/Server).
  static const localTeacherId = 'teacher-local';

  int _serial = 0;
  String? _activeStudent;
  bool _selectionLoaded = false;
  Future<void>? _selectionTail;
  bool _selectionResetting = false;

  String? get cachedActiveStudentId => _activeStudent;
  bool get hasLoadedSelection => _selectionLoaded;

  Future<T> _selectionOperation<T>(Future<T> Function() action) {
    final previous = _selectionTail;
    Future<T> perform() async {
      if (previous != null) await previous;
      return action();
    }

    final pending = perform();
    final tail =
        pending.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _selectionTail = tail;
    tail.then((_) {
      if (identical(_selectionTail, tail)) _selectionTail = null;
    });
    return pending;
  }

  Future<void> pauseSelectionForReset() async {
    _selectionResetting = true;
    while (_selectionTail != null) {
      await _selectionTail;
    }
  }

  void resumeSelectionAfterReset() => _selectionResetting = false;

  void resetSelectionCache() {
    _activeStudent = null;
    _selectionLoaded = false;
  }

  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_serial++}';

  Future<SchoolDirectory> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const SchoolDirectory();
    try {
      return SchoolDirectory.fromJson(jsonDecode(raw));
    } catch (_) {
      await prefs.remove(_key);
      return const SchoolDirectory();
    }
  }

  Future<void> save(SchoolDirectory d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(d.toJson()));
  }

  /// Welches Schulkind dieses Gerät gerade benutzt (null = niemand zugeordnet).
  Future<String?> activeStudentId() {
    // Capture the committed selection now, rather than after the caller's
    // wallet/progress awaits. A pending switch does not become active early.
    if (_selectionLoaded) return Future<String?>.value(_activeStudent);
    return _selectionOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      _activeStudent = prefs.getString(_activeKey)?.trim();
      if (_activeStudent?.isEmpty ?? false) _activeStudent = null;
      _selectionLoaded = true;
      return _activeStudent;
    });
  }

  Future<void> setActiveStudent(String? id) {
    if (_selectionResetting) {
      return Future.error(StateError('Profile is being reset'));
    }
    return _selectionOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      final selected = id?.trim();
      if (selected == null || selected.isEmpty) {
        if (!await prefs.remove(_activeKey)) {
          await prefs.reload();
          throw StateError('Student selection was not saved');
        }
      } else {
        await LearningStorage.write(prefs, _activeKey, selected);
      }
      final next = selected == null || selected.isEmpty ? null : selected;
      final changed = !_selectionLoaded || _activeStudent != next;
      _activeStudent = next;
      _selectionLoaded = true;
      if (changed) notifyListeners();
    });
  }

  // ── Änderungen ──────────────────────────────────────────────────────

  Future<SchoolDirectory> addClass(String name, int grade) async {
    final d = await load();
    final cls = SchoolClass(
      id: newId('class'),
      name: name.trim(),
      grade: grade.clamp(1, 4).toInt(),
      teacherIds: const [localTeacherId],
    );
    final next = SchoolDirectory(
      classes: [...d.classes, cls],
      students: d.students,
      groups: d.groups,
      assignments: d.assignments,
    );
    await save(next);
    return next;
  }

  Future<SchoolDirectory> addStudent(String classId, String name) async {
    final d = await load();
    if (d.classById(classId) == null || name.trim().isEmpty) return d;
    final next = SchoolDirectory(
      classes: d.classes,
      students: [
        ...d.students,
        SchoolStudent(id: newId('stud'), name: name.trim(), classId: classId),
      ],
      groups: d.groups,
      assignments: d.assignments,
    );
    await save(next);
    return next;
  }

  Future<SchoolDirectory> removeStudent(String studentId) async {
    final d = await load();
    final next = SchoolDirectory(
      classes: d.classes,
      students: d.students.where((s) => s.id != studentId).toList(),
      groups: d.groups,
      assignments: d.assignments
          .where((a) => !(a.targetKind == AssignmentTargetKind.student &&
              a.targetId == studentId))
          .toList(),
    );
    await save(next);
    if (await activeStudentId() == studentId) await setActiveStudent(null);
    return next;
  }

  Future<SchoolDirectory> addTeacher(String classId, String teacherId) async {
    final d = await load();
    final cls = d.classById(classId);
    if (cls == null || cls.teacherIds.contains(teacherId)) return d;
    final next = SchoolDirectory(
      classes: [
        for (final c in d.classes)
          if (c.id == classId)
            c.copyWith(teacherIds: [...c.teacherIds, teacherId])
          else
            c,
      ],
      students: d.students,
      groups: d.groups,
      assignments: d.assignments,
    );
    await save(next);
    return next;
  }

  Future<SchoolDirectory> addGroup(String classId, String name,
      {String? parentId}) async {
    final d = await load();
    if (d.classById(classId) == null || name.trim().isEmpty) return d;
    final next = SchoolDirectory(
      classes: d.classes,
      students: d.students,
      groups: [
        ...d.groups,
        StudentGroup(
            id: newId('group'),
            classId: classId,
            name: name.trim(),
            parentId: parentId),
      ],
      assignments: d.assignments,
    );
    await save(next);
    return next;
  }

  Future<SchoolDirectory> setStudentGroups(
      String studentId, List<String> groupIds) async {
    final d = await load();
    final next = SchoolDirectory(
      classes: d.classes,
      students: [
        for (final s in d.students)
          if (s.id == studentId) s.copyWith(groupIds: groupIds) else s,
      ],
      groups: d.groups,
      assignments: d.assignments,
    );
    await save(next);
    return next;
  }

  Future<SchoolDirectory> addAssignment(Assignment a) async {
    final d = await load();
    if (d.classById(a.classId) == null) return d;
    final next = SchoolDirectory(
      classes: d.classes,
      students: d.students,
      groups: d.groups,
      assignments: [...d.assignments, a],
    );
    await save(next);
    return next;
  }

  Future<SchoolDirectory> archiveAssignment(String id) async {
    final d = await load();
    final next = SchoolDirectory(
      classes: d.classes,
      students: d.students,
      groups: d.groups,
      assignments: [
        for (final a in d.assignments)
          if (a.id == id) a.copyWith(archived: true) else a,
      ],
    );
    await save(next);
    return next;
  }
}
