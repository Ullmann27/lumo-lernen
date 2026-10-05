import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/school_repository.dart';
import '../../domain/school/attempt.dart';
import '../../domain/school/learning_analysis.dart';
import '../../domain/school/school_model.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import 'assign_task_sheet.dart';
import 'teacher_student_screen.dart';
import 'teacher_widgets.dart';

/// Lehrer-Dashboard: Klasse, aktive Kinder, offene Aufgaben, Kinder mit
/// Unterstützungsbedarf und Kompetenzübersicht. Nur lernrelevante Daten.
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _StudentRow {
  _StudentRow(this.student, this.attempts)
      : analysis = LearningAnalysis.analyze(attempts);
  final SchoolStudent student;
  final List<Attempt> attempts;
  final LearningAnalysis analysis;
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  SchoolDirectory _dir = const SchoolDirectory();
  List<Attempt> _attempts = const [];
  String? _classId;
  bool _loaded = false;

  SchoolRepository get _repo => widget.appState.school;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final dir = await _repo.load();
    final all = await widget.appState.attemptLog.load();
    if (!mounted) return;
    // Nur Klassen, die diese Lehrkraft betreuen darf.
    final access = SchoolAccess(dir);
    final mine = dir.classes
        .where((c) => access.teacherMayManageClass(SchoolRepository.localTeacherId, c.id))
        .toList();
    setState(() {
      _dir = dir;
      _attempts = all;
      _classId = mine.any((c) => c.id == _classId)
          ? _classId
          : (mine.isEmpty ? null : mine.first.id);
      _loaded = true;
    });
  }

  List<SchoolClass> get _myClasses {
    final access = SchoolAccess(_dir);
    return _dir.classes
        .where((c) => access.teacherMayManageClass(SchoolRepository.localTeacherId, c.id))
        .toList();
  }

  Future<void> _addClass() async {
    final name = await askText(context, title: 'Neue Klasse', hint: 'z. B. 2a');
    if (name == null || name.trim().isEmpty || !mounted) return;
    final grade = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0B2A5C),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Welche Klassenstufe?', style: kTeacherLabel.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var g = 1; g <= 4; g++)
                TeacherButton(
                  key: ValueKey('class-grade-$g'),
                  label: '$g. Klasse',
                  icon: Icons.school_rounded,
                  onTap: () => Navigator.of(ctx).pop(g),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (grade == null) return;
    final d = await _repo.addClass(name, grade);
    _classId = d.classes.last.id;
    await _reload();
  }

  Future<void> _addStudent(SchoolClass c) async {
    final name = await askText(context, title: 'Kind hinzufügen', hint: 'Vorname');
    if (name == null) return;
    await _repo.addStudent(c.id, name);
    await _reload();
  }

  Future<void> _addGroup(SchoolClass c) async {
    final name = await askText(context, title: 'Neue Gruppe', hint: 'z. B. Rechengruppe');
    if (name == null) return;
    await _repo.addGroup(c.id, name);
    await _reload();
  }

  Future<void> _addTeacher(SchoolClass c) async {
    final name = await askText(context, title: 'Lehrkraft hinzufügen', hint: 'Name der Kollegin / des Kollegen');
    if (name == null || name.trim().isEmpty) return;
    await _repo.addTeacher(c.id, name.trim().toLowerCase());
    await _reload();
  }

  Future<void> _removeStudent(SchoolStudent s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0B2A5C),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${s.name} aus der Klasse entfernen?',
                textAlign: TextAlign.center,
                style: kTeacherLabel.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            const Text('Zugewiesene Einzelaufgaben werden gelöscht. Der Lernbericht auf dem Gerät bleibt erhalten.',
                textAlign: TextAlign.center, style: kTeacherMuted),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TeacherButton(
                      label: 'Abbrechen',
                      icon: Icons.close_rounded,
                      filled: false,
                      onTap: () => Navigator.of(ctx).pop(false))),
              const SizedBox(width: 10),
              Expanded(
                  child: TeacherButton(
                      key: const ValueKey('confirm-remove'),
                      label: 'Entfernen',
                      icon: Icons.delete_rounded,
                      onTap: () => Navigator.of(ctx).pop(true))),
            ]),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    await _repo.removeStudent(s.id);
    await _reload();
  }

  Future<void> _assign(SchoolClass c) async {
    final a = await showAssignSheet(context,
        directory: _dir, schoolClass: c, newId: () => _repo.newId('asg'));
    if (a == null) return;
    await _repo.addAssignment(a);
    await _reload();
  }

  Future<void> _openStudent(SchoolStudent s) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => TeacherStudentScreen(
          appState: widget.appState, studentId: s.id, classId: s.classId),
    ));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final classes = _myClasses;
    final cls = classes.where((c) => c.id == _classId).firstOrNull;
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.library,
        dimmed: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(children: [
                IconButton(
                  tooltip: 'Zurück',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text('Lehrerbereich',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kTeacherLabel.copyWith(fontSize: 22)),
                ),
              ]),
            ),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator(color: LumoVisualTokens.cyan))
                  : cls == null
                      ? _EmptyState(onAdd: _addClass)
                      : _content(classes, cls),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _content(List<SchoolClass> classes, SchoolClass cls) {
    final students = _dir.studentsOf(cls.id);
    final rows = [
      for (final s in students)
        _StudentRow(s, _attempts.where((a) => a.studentId == s.id).toList()),
    ];
    final today = DateTime.now();
    bool isToday(DateTime? t) =>
        t != null && t.year == today.year && t.month == today.month && t.day == today.day;
    final activeToday = rows.where((r) => isToday(r.analysis.lastActivity)).length;
    final classAssignments =
        _dir.assignments.where((a) => a.classId == cls.id && !a.archived).toList();
    int openFor(Assignment a) {
      var open = 0;
      for (final r in rows) {
        if (!_dir.assignmentAppliesTo(a, r.student)) continue;
        if (!AssignmentProgress.of(a, r.attempts).completed) open++;
      }
      return open;
    }

    final openTotal = classAssignments.fold<int>(0, (sum, a) => sum + openFor(a));
    final needHelp = rows.where((r) => r.analysis.weak.isNotEmpty).toList();

    // Kompetenzen, bei denen mehrere Kinder Hilfe brauchen.
    final weakCount = <String, int>{};
    for (final r in rows) {
      for (final w in r.analysis.weak) {
        weakCount[w.competency] = (weakCount[w.competency] ?? 0) + 1;
      }
    }
    final weakSorted = weakCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              for (final c in classes)
                ChoiceChip(
                  key: ValueKey('class-${c.name}'),
                  label: Text('${c.name} · ${c.grade}. Kl.',
                      style: kTeacherLabel.copyWith(
                          fontSize: 14,
                          color: c.id == cls.id ? const Color(0xFF03193F) : Colors.white)),
                  selected: c.id == cls.id,
                  showCheckmark: false,
                  selectedColor: LumoVisualTokens.cyanBright,
                  backgroundColor: const Color(0x33FFFFFF),
                  side: const BorderSide(color: Color(0x8837D2FD)),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => setState(() => _classId = c.id),
                ),
              TeacherButton(
                key: const ValueKey('add-class'),
                label: 'Klasse',
                icon: Icons.add_rounded,
                filled: false,
                onTap: _addClass,
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _Stat(Icons.groups_rounded, '${students.length}', 'Kinder'),
              _Stat(Icons.bolt_rounded, '$activeToday', 'heute aktiv'),
              _Stat(Icons.assignment_late_rounded, '$openTotal', 'offene Aufgaben'),
              _Stat(Icons.support_rounded, '${needHelp.length}', 'brauchen Hilfe'),
            ]),
            const SizedBox(height: 12),
            if (needHelp.isNotEmpty) ...[
              TeacherPanel(
                title: 'Unterstützung nötig',
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final r in needHelp)
                    InkWell(
                      key: ValueKey('help-${r.student.name}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openStudent(r.student),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          const Icon(Icons.flag_rounded, color: Color(0xFFFFB86B), size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                '${r.student.name}: ${r.analysis.insights.firstWhere((i) => i.kind == InsightKind.weakness).text}',
                                style: kTeacherLabel.copyWith(fontSize: 14, height: 1.25)),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                        ]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            TeacherPanel(
              title: 'Kinder',
              trailing: Wrap(spacing: 8, children: [
                TeacherButton(
                  key: const ValueKey('add-student'),
                  label: 'Kind',
                  icon: Icons.person_add_rounded,
                  onTap: () => _addStudent(cls),
                ),
              ]),
              child: students.isEmpty
                  ? const Text('Noch keine Kinder in dieser Klasse. Füge das erste Kind hinzu.', style: kTeacherMuted)
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final r in rows) _StudentTile(
                        row: r,
                        onOpen: () => _openStudent(r.student),
                        onRemove: () => _removeStudent(r.student),
                      ),
                    ]),
            ),
            const SizedBox(height: 12),
            TeacherPanel(
              title: 'Aufgaben der Klasse',
              trailing: TeacherButton(
                key: const ValueKey('class-assign'),
                label: 'Zuweisen',
                icon: Icons.assignment_add,
                onTap: students.isEmpty ? () {} : () => _assign(cls),
              ),
              child: classAssignments.isEmpty
                  ? const Text('Noch keine Aufgaben zugewiesen.', style: kTeacherMuted)
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final a in classAssignments)
                        _ClassAssignmentRow(
                          assignment: a,
                          dir: _dir,
                          rows: rows,
                        ),
                    ]),
            ),
            if (weakSorted.isNotEmpty) ...[
              const SizedBox(height: 12),
              TeacherPanel(
                title: 'Kompetenzen mit Hilfebedarf',
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final e in weakSorted.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                          '${e.key}: ${e.value} ${e.value == 1 ? 'Kind' : 'Kinder'}',
                          style: kTeacherLabel.copyWith(fontSize: 14)),
                    ),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            TeacherPanel(
              title: 'Klasse ${cls.name}',
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Lehrkräfte: ${cls.teacherIds.length}  ·  Gruppen: ${_dir.groupsOf(cls.id).length}',
                    style: kTeacherMuted),
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  TeacherButton(
                    key: const ValueKey('add-group'),
                    label: 'Gruppe anlegen',
                    icon: Icons.group_add_rounded,
                    filled: false,
                    onTap: () => _addGroup(cls),
                  ),
                  TeacherButton(
                    key: const ValueKey('add-teacher'),
                    label: 'Lehrkraft hinzufügen',
                    icon: Icons.co_present_rounded,
                    filled: false,
                    onTap: () => _addTeacher(cls),
                  ),
                ]),
                const SizedBox(height: 10),
                const Text(
                    'Hinweis: Die Daten liegen heute nur auf diesem Gerät. Anmeldung und Abgleich zwischen Geräten brauchen einen Server und sind noch nicht eingerichtet.',
                    style: kTeacherMuted),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.school_rounded, color: LumoVisualTokens.cyanBright, size: 56),
            const SizedBox(height: 12),
            Text('Willkommen im Lehrerbereich',
                textAlign: TextAlign.center,
                style: kTeacherLabel.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            const Text(
                'Lege eine Klasse an, füge Kinder hinzu und sieh, wo sie Unterstützung brauchen.',
                textAlign: TextAlign.center,
                style: kTeacherMuted),
            const SizedBox(height: 16),
            TeacherButton(
              key: const ValueKey('create-first-class'),
              label: 'Klasse anlegen',
              icon: Icons.add_rounded,
              onTap: onAdd,
            ),
          ]),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.caption);
  final IconData icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xD90B2A5C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x8837D2FD)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: LumoVisualTokens.cyanBright, size: 22),
          Text(value, style: kTeacherLabel.copyWith(fontSize: 20)),
          Text(caption, style: kTeacherMuted.copyWith(fontSize: 12)),
        ]),
      );
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.row, required this.onOpen, required this.onRemove});
  final _StudentRow row;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  String _last(DateTime? t) {
    if (t == null) return 'noch nicht geübt';
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(t.year, t.month, t.day))
        .inDays;
    if (days == 0) return 'heute aktiv';
    if (days == 1) return 'gestern aktiv';
    return 'vor $days Tagen';
  }

  @override
  Widget build(BuildContext context) {
    final a = row.analysis;
    final weak = a.weak.isNotEmpty;
    return Row(children: [
      Expanded(
        child: InkWell(
          key: ValueKey('student-${row.student.name}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(Icons.account_circle_rounded,
                  size: 34,
                  color: weak ? const Color(0xFFFFB86B) : LumoVisualTokens.cyanBright),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(row.student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTeacherLabel.copyWith(fontSize: 16)),
                  Text(
                      '${_last(a.lastActivity)} · ${a.totalAttempts} Aufgaben · ${a.totalMinutes} min',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kTeacherMuted.copyWith(fontSize: 12)),
                ]),
              ),
              if (weak)
                const Icon(Icons.flag_rounded, color: Color(0xFFFFB86B), size: 20),
            ]),
          ),
        ),
      ),
      IconButton(
        key: ValueKey('remove-${row.student.name}'),
        tooltip: '${row.student.name} entfernen',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
        onPressed: onRemove,
      ),
    ]);
  }
}

class _ClassAssignmentRow extends StatelessWidget {
  const _ClassAssignmentRow(
      {required this.assignment, required this.dir, required this.rows});
  final Assignment assignment;
  final SchoolDirectory dir;
  final List<_StudentRow> rows;

  String _target() {
    switch (assignment.targetKind) {
      case AssignmentTargetKind.wholeClass:
        return 'ganze Klasse';
      case AssignmentTargetKind.group:
        return dir.groups
                .where((g) => g.id == assignment.targetId)
                .map((g) => 'Gruppe ${g.name}')
                .firstOrNull ??
            'Gruppe';
      case AssignmentTargetKind.student:
        return dir.studentById(assignment.targetId ?? '')?.name ?? 'Kind';
    }
  }

  @override
  Widget build(BuildContext context) {
    var total = 0, done = 0;
    for (final r in rows) {
      if (!dir.assignmentAppliesTo(assignment, r.student)) continue;
      total++;
      if (AssignmentProgress.of(assignment, r.attempts).completed) done++;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${assignment.subject}: ${assignment.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: kTeacherLabel.copyWith(fontSize: 14)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 8,
            color: done == total && total > 0
                ? const Color(0xFF7BE08C)
                : LumoVisualTokens.cyanBright,
            backgroundColor: const Color(0x33FFFFFF),
          ),
        ),
        Text('${_target()} · $done von $total fertig · ${assignment.taskCount} Aufgaben',
            style: kTeacherMuted.copyWith(fontSize: 12)),
      ]),
    );
  }
}
