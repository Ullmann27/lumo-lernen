import 'package:flutter/material.dart';

import '../../core/school_exercise_generator.dart';
import '../../domain/school/school_model.dart';
import '../../theme/lumo_visual_tokens.dart';
import 'teacher_widgets.dart';

/// Vorbelegung, z. B. aus der Empfehlung der Lernanalyse.
class AssignPreset {
  const AssignPreset({this.subject, this.unit, this.studentId, this.groupId});
  final String? subject;
  final String? unit;
  final String? studentId;
  final String? groupId;
}

/// Formular „Aufgabe zuweisen“. Gibt die fertige Zuweisung zurück oder null.
Future<Assignment?> showAssignSheet(
  BuildContext context, {
  required SchoolDirectory directory,
  required SchoolClass schoolClass,
  required String Function() newId,
  AssignPreset preset = const AssignPreset(),
}) {
  return showModalBottomSheet<Assignment>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AssignSheet(
      directory: directory,
      schoolClass: schoolClass,
      newId: newId,
      preset: preset,
    ),
  );
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({
    required this.directory,
    required this.schoolClass,
    required this.newId,
    required this.preset,
  });
  final SchoolDirectory directory;
  final SchoolClass schoolClass;
  final String Function() newId;
  final AssignPreset preset;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  late AssignmentTargetKind _kind;
  String? _targetId;
  late String _subject;
  late String _unit;
  int _count = 10;
  int? _dueDays = 7;
  final _goal = TextEditingController();

  List<String> get _units =>
      Curriculum.unitsForGrade(_subject, widget.schoolClass.grade);

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    if (p.studentId != null) {
      _kind = AssignmentTargetKind.student;
      _targetId = p.studentId;
    } else if (p.groupId != null) {
      _kind = AssignmentTargetKind.group;
      _targetId = p.groupId;
    } else {
      _kind = AssignmentTargetKind.wholeClass;
    }
    _subject = Curriculum.subjects.containsKey(p.subject)
        ? p.subject!
        : Curriculum.subjects.keys.first;
    final units = _units;
    _unit = units.contains(p.unit) ? p.unit! : (units.isEmpty ? '' : units.first);
  }

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  Widget _chips<T>({
    required List<(T, String)> options,
    required T? selected,
    required ValueChanged<T> onPick,
  }) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (value, label) in options)
          ChoiceChip(
            key: ValueKey('assign-$label'),
            label: Text(label,
                style: kTeacherLabel.copyWith(
                    fontSize: 13,
                    color: value == selected
                        ? const Color(0xFF03193F)
                        : Colors.white)),
            selected: value == selected,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            selectedColor: LumoVisualTokens.cyanBright,
            backgroundColor: const Color(0x33FFFFFF),
            side: const BorderSide(color: Color(0x8837D2FD)),
            onSelected: (_) => setState(() => onPick(value)),
          ),
      ]);

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t, style: kTeacherLabel.copyWith(fontSize: 15)),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.directory;
    final cid = widget.schoolClass.id;
    final targets = <(String, String, AssignmentTargetKind, String?)>[
      ('class', 'Ganze Klasse', AssignmentTargetKind.wholeClass, null),
      for (final g in d.groupsOf(cid))
        ('g${g.id}', 'Gruppe ${g.name}', AssignmentTargetKind.group, g.id),
      for (final s in d.studentsOf(cid))
        ('s${s.id}', s.name, AssignmentTargetKind.student, s.id),
    ];
    final selectedKey = targets
        .where((t) => t.$3 == _kind && t.$4 == _targetId)
        .map((t) => t.$1)
        .firstOrNull;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Color(0xFF0B2A5C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xCC53DDFD), width: 2)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Aufgabe zuweisen', style: kTeacherLabel.copyWith(fontSize: 22)),
              _label('Für wen?'),
              _chips<String>(
                options: [for (final t in targets) (t.$1, t.$2)],
                selected: selectedKey,
                onPick: (key) {
                  final t = targets.firstWhere((x) => x.$1 == key);
                  _kind = t.$3;
                  _targetId = t.$4;
                },
              ),
              _label('Fach'),
              _chips<String>(
                options: [for (final s in Curriculum.subjects.keys) (s, s)],
                selected: _subject,
                onPick: (s) {
                  _subject = s;
                  final u = _units;
                  _unit = u.isEmpty ? '' : u.first;
                },
              ),
              _label('Thema'),
              DropdownButtonFormField<String>(
                key: const ValueKey('assign-unit'),
                value: _units.contains(_unit) ? _unit : null,
                isExpanded: true,
                dropdownColor: const Color(0xFF0B2A5C),
                iconEnabledColor: LumoVisualTokens.cyanBright,
                style: kTeacherLabel.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0x33FFFFFF),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
                items: [
                  for (final u in _units)
                    DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
              _label('Wie viele Aufgaben?'),
              _chips<int>(
                options: [for (final n in [5, 10, 15, 20]) (n, '$n')],
                selected: _count,
                onPick: (n) => _count = n,
              ),
              _label('Bis wann?'),
              _chips<int?>(
                options: const [
                  (null, 'Keine Frist'),
                  (3, '3 Tage'),
                  (7, '1 Woche'),
                  (14, '2 Wochen'),
                ],
                selected: _dueDays,
                onPick: (n) => _dueDays = n,
              ),
              _label('Lernziel (optional)'),
              TextField(
                controller: _goal,
                maxLength: 60,
                style: kTeacherLabel.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'z. B. Zehnerübergang sicher können',
                  hintStyle: kTeacherMuted,
                  counterStyle: kTeacherMuted,
                  filled: true,
                  fillColor: const Color(0x33FFFFFF),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 6),
              TeacherButton(
                label: 'Zuweisen',
                icon: Icons.send_rounded,
                onTap: _unit.isEmpty
                    ? () {}
                    : () {
                        final now = DateTime.now();
                        Navigator.of(context).pop(Assignment(
                          id: widget.newId(),
                          classId: widget.schoolClass.id,
                          targetKind: _kind,
                          targetId: _targetId,
                          subject: _subject,
                          unit: _unit,
                          title: _unit,
                          taskCount: _count,
                          createdAt: now,
                          dueAt: _dueDays == null
                              ? null
                              : now.add(Duration(days: _dueDays!)),
                          goal: _goal.text.trim(),
                        ));
                      },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
