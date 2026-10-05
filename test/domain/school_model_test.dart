import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Attempt _t(String student, String unit, bool ok, DateTime at, [int i = 0]) =>
    Attempt(
      id: '$student-$unit-$i-${at.microsecondsSinceEpoch}',
      studentId: student,
      subject: 'Mathematik',
      unit: unit,
      competency: unit,
      correct: ok,
      at: at,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Klasse, Schüler, Gruppen und Untergruppen werden gespeichert',
      () async {
    final repo = SchoolRepository();
    var d = await repo.addClass('2a', 2);
    final classId = d.classes.single.id;
    d = await repo.addStudent(classId, 'Alina');
    d = await repo.addStudent(classId, 'Ben');
    d = await repo.addGroup(classId, 'Rechengruppe');
    final parent = d.groups.single.id;
    d = await repo.addGroup(classId, 'Zehnerübergang', parentId: parent);
    final reloaded = await repo.load();
    expect(reloaded.classes.single.name, '2a');
    expect(reloaded.studentsOf(classId).map((s) => s.name), ['Alina', 'Ben']);
    expect(reloaded.groupWithDescendants(parent).length, 2);
  });

  test('Leere Namen und fremde Klassen werden abgelehnt', () async {
    final repo = SchoolRepository();
    var d = await repo.addClass('1b', 1);
    d = await repo.addStudent(d.classes.single.id, '  ');
    expect(d.students, isEmpty);
    d = await repo.addStudent('gibt-es-nicht', 'Mia');
    expect(d.students, isEmpty);
  });

  test('Zuweisung trifft Klasse, Gruppe (mit Untergruppe) und Einzelkind',
      () async {
    final repo = SchoolRepository();
    var d = await repo.addClass('3c', 3);
    final c = d.classes.single.id;
    d = await repo.addStudent(c, 'Alina');
    d = await repo.addStudent(c, 'Ben');
    d = await repo.addStudent(c, 'Cem');
    d = await repo.addGroup(c, 'Gruppe A');
    final a = d.groups.single.id;
    d = await repo.addGroup(c, 'Untergruppe A1', parentId: a);
    final a1 = d.groups.last.id;
    final alina = d.students[0].id, ben = d.students[1].id, cem = d.students[2].id;
    d = await repo.setStudentGroups(alina, [a]);
    d = await repo.setStudentGroups(ben, [a1]);
    final now = DateTime(2026, 10, 5);
    Assignment asg(AssignmentTargetKind k, [String? id]) => Assignment(
        id: repo.newId('asg'),
        classId: c,
        targetKind: k,
        targetId: id,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        title: 'Plus üben',
        createdAt: now);
    d = await repo.addAssignment(asg(AssignmentTargetKind.group, a));
    d = await repo.addAssignment(asg(AssignmentTargetKind.student, cem));
    d = await repo.addAssignment(asg(AssignmentTargetKind.wholeClass));
    SchoolStudent s(String id) => d.studentById(id)!;
    expect(d.assignmentsFor(s(alina)).length, 2); // Gruppe + Klasse
    expect(d.assignmentsFor(s(ben)).length, 2); // Untergruppe zählt zur Gruppe
    expect(d.assignmentsFor(s(cem)).length, 2); // Einzelkind + Klasse
  });

  test('Fortschritt zählt nur Aufgaben zum Thema nach dem Zuweisen', () {
    final created = DateTime(2026, 10, 5, 9);
    final a = Assignment(
        id: 'x',
        classId: 'c',
        targetKind: AssignmentTargetKind.wholeClass,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        title: 't',
        taskCount: 4,
        createdAt: created);
    final attempts = [
      _t('s', 'Plus bis 20', true, created.subtract(const Duration(hours: 1))),
      _t('s', 'Minus bis 20', true, created.add(const Duration(hours: 1))),
      _t('s', 'Plus bis 20', true, created.add(const Duration(hours: 1)), 1),
      _t('s', 'Plus bis 20', false, created.add(const Duration(hours: 2)), 2),
    ];
    final p = AssignmentProgress.of(a, attempts);
    expect((p.done, p.correct, p.completed), (2, 1, false));
    final done = AssignmentProgress.of(a, [
      ...attempts,
      _t('s', 'Plus bis 20', true, created.add(const Duration(hours: 3)), 3),
      _t('s', 'Plus bis 20', true, created.add(const Duration(hours: 4)), 4),
    ]);
    expect(done.completed, isTrue);
  });

  test('Berechtigung: Lehrkraft nur eigene Klassen, Schüler nur sich selbst',
      () async {
    final repo = SchoolRepository();
    var d = await repo.addClass('4a', 4);
    final c = d.classes.single.id;
    d = await repo.addStudent(c, 'Dora');
    final sid = d.students.single.id;
    final access = SchoolAccess(d);
    expect(access.teacherMayViewStudent(SchoolRepository.localTeacherId, sid),
        isTrue);
    expect(access.teacherMayViewStudent('fremde-lehrkraft', sid), isFalse);
    expect(access.studentMayViewStudent(sid, sid), isTrue);
    expect(access.studentMayViewStudent('anderes-kind', sid), isFalse);
    d = await repo.addTeacher(c, 'kollegin');
    expect(SchoolAccess(d).teacherMayViewStudent('kollegin', sid), isTrue);
  });

  test('Schüler entfernen löscht dessen Einzelaufgaben und die Zuordnung',
      () async {
    final repo = SchoolRepository();
    var d = await repo.addClass('1a', 1);
    final c = d.classes.single.id;
    d = await repo.addStudent(c, 'Eli');
    final sid = d.students.single.id;
    await repo.setActiveStudent(sid);
    d = await repo.addAssignment(Assignment(
        id: 'a1',
        classId: c,
        targetKind: AssignmentTargetKind.student,
        targetId: sid,
        subject: 'Deutsch',
        unit: 'Umlaute',
        title: 'u',
        createdAt: DateTime(2026)));
    d = await repo.removeStudent(sid);
    expect(d.students, isEmpty);
    expect(d.assignments, isEmpty);
    expect(await repo.activeStudentId(), isNull);
  });

  test('Kaputte Schuldaten führen nicht zum Absturz', () async {
    SharedPreferences.setMockInitialValues({'lumo_school_v1': '{kaputt'});
    final d = await SchoolRepository().load();
    expect(d.classes, isEmpty);
  });
}
