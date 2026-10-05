import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../domain/school/school_model.dart';
import '../../theme/lumo_visual_tokens.dart';

/// „Von deiner Lehrerin“: zeigt dem Kind offene Aufgaben seiner Lehrkraft
/// mit Fortschritt. Ein Tipp startet genau dieses Thema. Ohne Zuordnung des
/// Geräts oder ohne offene Aufgaben bleibt das Feld unsichtbar.
class StudentAssignmentsCard extends StatefulWidget {
  const StudentAssignmentsCard(
      {super.key, required this.appState, required this.onStart});
  final LumoAppState appState;
  final void Function(String subject, String unit) onStart;

  @override
  State<StudentAssignmentsCard> createState() => _StudentAssignmentsCardState();
}

class _Open {
  _Open(this.assignment, this.progress);
  final Assignment assignment;
  final AssignmentProgress progress;
}

class _StudentAssignmentsCardState extends State<StudentAssignmentsCard> {
  List<_Open> _open = const [];

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = widget.appState.school;
      final id = await repo.activeStudentId();
      if (id == null) {
        if (mounted && _open.isNotEmpty) setState(() => _open = const []);
        return;
      }
      final dir = await repo.load();
      final student = dir.studentById(id);
      if (student == null) return;
      final attempts =
          await widget.appState.attemptLog.load(studentId: student.id);
      final open = <_Open>[];
      for (final a in dir.assignmentsFor(student)) {
        final p = AssignmentProgress.of(a, attempts);
        if (!p.completed) open.add(_Open(a, p));
      }
      if (!mounted) return;
      setState(() => _open = open);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_open.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('student-assignments'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xD90B2A5C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LumoVisualTokens.gold.withOpacity(.8), width: 1.6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [
          Icon(Icons.mark_email_unread_rounded, color: LumoVisualTokens.gold),
          SizedBox(width: 8),
          Expanded(
            child: Text('Von deiner Lehrerin',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 6),
        for (final o in _open)
          InkWell(
            key: ValueKey('assignment-${o.assignment.unit}'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => widget.onStart(o.assignment.subject, o.assignment.unit),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${o.assignment.subject}: ${o.assignment.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: o.progress.fraction,
                        minHeight: 8,
                        color: LumoVisualTokens.gold,
                        backgroundColor: const Color(0x33FFFFFF),
                      ),
                    ),
                    Text(
                        '${o.progress.done} von ${o.progress.target} Aufgaben',
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD6E8FF))),
                  ]),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.play_circle_fill_rounded,
                    color: LumoVisualTokens.cyanBright, size: 36),
              ]),
            ),
          ),
      ]),
    );
  }
}
