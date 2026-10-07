import 'attempt.dart';

/// Rollen im Schulmodell. Berechtigungen werden über [SchoolAccess]
/// entschieden, nie in der Oberfläche. Ein Schüler sieht nur eigene Daten.
enum SchoolRole { student, teacher, parent, admin }

class SchoolStudent {
  const SchoolStudent({
    required this.id,
    required this.name,
    required this.classId,
    this.groupIds = const [],
  });

  final String id;

  /// Nur der Vorname (Datensparsamkeit).
  final String name;
  final String classId;
  final List<String> groupIds;

  SchoolStudent copyWith({String? name, String? classId, List<String>? groupIds}) =>
      SchoolStudent(
        id: id,
        name: name ?? this.name,
        classId: classId ?? this.classId,
        groupIds: groupIds ?? this.groupIds,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'cls': classId, 'groups': groupIds};

  static SchoolStudent? tryFromJson(Object? j) {
    if (j is! Map || j['id'] is! String || j['cls'] is! String) return null;
    return SchoolStudent(
      id: j['id'] as String,
      name: '${j['name'] ?? ''}',
      classId: j['cls'] as String,
      groupIds: [for (final g in (j['groups'] as List? ?? const [])) '$g'],
    );
  }
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.grade,
    this.teacherIds = const [],
  });

  final String id;
  final String name;
  final int grade;
  final List<String> teacherIds;

  SchoolClass copyWith({String? name, int? grade, List<String>? teacherIds}) =>
      SchoolClass(
        id: id,
        name: name ?? this.name,
        grade: grade ?? this.grade,
        teacherIds: teacherIds ?? this.teacherIds,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'grade': grade, 'teachers': teacherIds};

  static SchoolClass? tryFromJson(Object? j) {
    if (j is! Map || j['id'] is! String) return null;
    return SchoolClass(
      id: j['id'] as String,
      name: '${j['name'] ?? ''}',
      grade: (j['grade'] as num?)?.toInt() ?? 1,
      teacherIds: [for (final t in (j['teachers'] as List? ?? const [])) '$t'],
    );
  }
}

/// Gruppe oder Untergruppe ([parentId]) innerhalb einer Klasse.
class StudentGroup {
  const StudentGroup(
      {required this.id,
      required this.classId,
      required this.name,
      this.parentId});
  final String id;
  final String classId;
  final String name;
  final String? parentId;

  Map<String, dynamic> toJson() =>
      {'id': id, 'cls': classId, 'name': name, if (parentId != null) 'parent': parentId};

  static StudentGroup? tryFromJson(Object? j) {
    if (j is! Map || j['id'] is! String || j['cls'] is! String) return null;
    return StudentGroup(
      id: j['id'] as String,
      classId: j['cls'] as String,
      name: '${j['name'] ?? ''}',
      parentId: j['parent'] as String?,
    );
  }
}

enum AssignmentTargetKind { wholeClass, group, student }

class Assignment {
  const Assignment({
    required this.id,
    required this.classId,
    required this.targetKind,
    required this.subject,
    required this.unit,
    required this.title,
    required this.createdAt,
    this.targetId,
    this.taskCount = 10,
    this.dueAt,
    this.goal = '',
    this.archived = false,
  });

  final String id;
  final String classId;
  final AssignmentTargetKind targetKind;

  /// Gruppen- oder Schüler-Id; bei ganzer Klasse null.
  final String? targetId;
  final String subject;
  final String unit;
  final String title;
  final int taskCount;
  final DateTime createdAt;
  final DateTime? dueAt;
  final String goal;
  final bool archived;

  Assignment copyWith({bool? archived}) => Assignment(
        id: id,
        classId: classId,
        targetKind: targetKind,
        targetId: targetId,
        subject: subject,
        unit: unit,
        title: title,
        taskCount: taskCount,
        createdAt: createdAt,
        dueAt: dueAt,
        goal: goal,
        archived: archived ?? this.archived,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cls': classId,
        'kind': targetKind.name,
        if (targetId != null) 'tid': targetId,
        'sub': subject,
        'unit': unit,
        'title': title,
        'n': taskCount,
        'created': createdAt.toIso8601String(),
        if (dueAt != null) 'due': dueAt!.toIso8601String(),
        if (goal.isNotEmpty) 'goal': goal,
        if (archived) 'arch': true,
      };

  static Assignment? tryFromJson(Object? j) {
    if (j is! Map || j['id'] is! String || j['cls'] is! String) return null;
    final created = DateTime.tryParse('${j['created']}');
    if (created == null) return null;
    final kind = AssignmentTargetKind.values
        .where((k) => k.name == j['kind'])
        .firstOrNull;
    if (kind == null) return null;
    return Assignment(
      id: j['id'] as String,
      classId: j['cls'] as String,
      targetKind: kind,
      targetId: j['tid'] as String?,
      subject: '${j['sub'] ?? ''}',
      unit: '${j['unit'] ?? ''}',
      title: '${j['title'] ?? ''}',
      taskCount: (j['n'] as num?)?.toInt() ?? 10,
      createdAt: created,
      dueAt: DateTime.tryParse('${j['due']}'),
      goal: '${j['goal'] ?? ''}',
      archived: j['arch'] == true,
    );
  }
}

/// Stand einer Aufgabe für ein Kind: gezählt werden Aufgaben zum selben
/// Thema, die nach dem Zuweisen gelöst wurden.
class AssignmentProgress {
  const AssignmentProgress(
      {required this.done, required this.correct, required this.target});
  final int done;
  final int correct;
  final int target;

  bool get completed => done >= target;
  double get fraction => target == 0 ? 1 : (done / target).clamp(0.0, 1.0);

  static AssignmentProgress of(Assignment a, Iterable<Attempt> studentAttempts) {
    final mine = studentAttempts.where((t) =>
        t.subject == a.subject &&
        t.unit == a.unit &&
        !t.at.isBefore(a.createdAt));
    return AssignmentProgress(
      done: mine.length,
      correct: mine.where((t) => t.correct).length,
      target: a.taskCount,
    );
  }
}

/// Wer darf was sehen? Läuft heute lokal; sobald es ein Backend gibt, muss
/// dieselbe Regel dort serverseitig erzwungen werden.
class SchoolAccess {
  const SchoolAccess(this.directory);
  final SchoolDirectory directory;

  bool teacherMayViewStudent(String teacherId, String studentId) {
    final student = directory.studentById(studentId);
    if (student == null) return false;
    final cls = directory.classById(student.classId);
    return cls != null && cls.teacherIds.contains(teacherId);
  }

  bool teacherMayManageClass(String teacherId, String classId) =>
      directory.classById(classId)?.teacherIds.contains(teacherId) ?? false;

  /// Ein Schüler sieht ausschließlich sich selbst.
  bool studentMayViewStudent(String viewerId, String studentId) =>
      viewerId == studentId;
}

/// Alle Schuldaten (Klassen, Schüler, Gruppen, Aufgaben) als ein Block.
class SchoolDirectory {
  const SchoolDirectory({
    this.classes = const [],
    this.students = const [],
    this.groups = const [],
    this.assignments = const [],
  });

  final List<SchoolClass> classes;
  final List<SchoolStudent> students;
  final List<StudentGroup> groups;
  final List<Assignment> assignments;

  SchoolClass? classById(String id) =>
      classes.where((c) => c.id == id).firstOrNull;
  SchoolStudent? studentById(String id) =>
      students.where((s) => s.id == id).firstOrNull;

  List<SchoolStudent> studentsOf(String classId) =>
      students.where((s) => s.classId == classId).toList();
  List<StudentGroup> groupsOf(String classId) =>
      groups.where((g) => g.classId == classId).toList();

  /// Gruppe samt aller Untergruppen.
  Set<String> groupWithDescendants(String groupId) {
    final out = <String>{groupId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final g in groups) {
        if (g.parentId != null && out.contains(g.parentId) && out.add(g.id)) {
          grew = true;
        }
      }
    }
    return out;
  }

  /// Betrifft die Aufgabe dieses Kind?
  bool assignmentAppliesTo(Assignment a, SchoolStudent s) {
    if (a.classId != s.classId || a.archived) return false;
    switch (a.targetKind) {
      case AssignmentTargetKind.wholeClass:
        return true;
      case AssignmentTargetKind.student:
        return a.targetId == s.id;
      case AssignmentTargetKind.group:
        final ids = groupWithDescendants(a.targetId ?? '');
        return s.groupIds.any(ids.contains);
    }
  }

  List<Assignment> assignmentsFor(SchoolStudent s) =>
      assignments.where((a) => assignmentAppliesTo(a, s)).toList();

  Map<String, dynamic> toJson() => {
        'classes': classes.map((c) => c.toJson()).toList(),
        'students': students.map((s) => s.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'assignments': assignments.map((a) => a.toJson()).toList(),
      };

  static SchoolDirectory fromJson(Object? j) {
    if (j is! Map) return const SchoolDirectory();
    List<T> list<T>(String key, T? Function(Object?) f) => [
          for (final e in (j[key] as List? ?? const []))
            if (f(e) case final T v) v,
        ];
    return SchoolDirectory(
      classes: list('classes', SchoolClass.tryFromJson),
      students: list('students', SchoolStudent.tryFromJson),
      groups: list('groups', StudentGroup.tryFromJson),
      assignments: list('assignments', Assignment.tryFromJson),
    );
  }
}
