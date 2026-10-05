import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/school_repository.dart';
import '../../domain/school/attempt.dart';
import '../../domain/school/learning_analysis.dart';
import '../../domain/school/school_model.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../report/student_report_view.dart';
import 'assign_task_sheet.dart';
import 'teacher_widgets.dart';

/// Einzelansicht eines Kindes für die Lehrkraft: Lernbericht, Empfehlung der
/// Analyse (bestätigen, ändern oder ignorieren) und Zuordnung des Geräts.
class TeacherStudentScreen extends StatefulWidget {
  const TeacherStudentScreen({
    super.key,
    required this.appState,
    required this.studentId,
    required this.classId,
  });

  final LumoAppState appState;
  final String studentId;
  final String classId;

  @override
  State<TeacherStudentScreen> createState() => _TeacherStudentScreenState();
}

class _TeacherStudentScreenState extends State<TeacherStudentScreen> {
  SchoolDirectory _dir = const SchoolDirectory();
  List<Attempt> _attempts = const [];
  String? _activeId;
  bool _loaded = false;
  bool _suggestionHandled = false;

  SchoolRepository get _repo => widget.appState.school;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final dir = await _repo.load();
    final all = await widget.appState.attemptLog.load(studentId: widget.studentId);
    final active = await _repo.activeStudentId();
    if (!mounted) return;
    setState(() {
      _dir = dir;
      _attempts = all;
      _activeId = active;
      _loaded = true;
    });
  }

  Future<void> _assign({AssignPreset preset = const AssignPreset()}) async {
    final cls = _dir.classById(widget.classId);
    if (cls == null) return;
    final a = await showAssignSheet(context,
        directory: _dir,
        schoolClass: cls,
        newId: () => _repo.newId('asg'),
        preset: AssignPreset(
            subject: preset.subject,
            unit: preset.unit,
            studentId: widget.studentId));
    if (a == null) return;
    await _repo.addAssignment(a);
    _suggestionHandled = true;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final student = _dir.studentById(widget.studentId);
    final access = SchoolAccess(_dir);
    final allowed = student != null &&
        access.teacherMayViewStudent(
            SchoolRepository.localTeacherId, widget.studentId);
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
                  child: Text(student?.name ?? 'Schüler',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kTeacherLabel.copyWith(fontSize: 22)),
                ),
              ]),
            ),
            Expanded(
              child: !_loaded
                  ? const Center(
                      child: CircularProgressIndicator(color: LumoVisualTokens.cyan))
                  : !allowed
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Dieses Kind gehört nicht zu deinen Klassen.',
                                style: kTeacherMuted),
                          ))
                      : _body(student),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _body(SchoolStudent student) {
    final analysis = LearningAnalysis.analyze(_attempts);
    final assignments = _dir.assignmentsFor(student);
    final suggestion = analysis.suggestion;
    final isActive = _activeId == student.id;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            if (suggestion != null && !_suggestionHandled) ...[
              TeacherPanel(
                title: 'Empfehlung von Lumo',
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(suggestion.text, style: kTeacherLabel.copyWith(fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    TeacherButton(
                      label: 'Bestätigen und zuweisen',
                      icon: Icons.check_circle_rounded,
                      onTap: () => _assign(
                          preset: AssignPreset(
                              subject: suggestion.subject,
                              unit: _unitFor(suggestion))),
                    ),
                    TeacherButton(
                      label: 'Ändern',
                      icon: Icons.tune_rounded,
                      filled: false,
                      onTap: () => _assign(),
                    ),
                    TeacherButton(
                      label: 'Ignorieren',
                      icon: Icons.not_interested_rounded,
                      filled: false,
                      onTap: () => setState(() => _suggestionHandled = true),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            TeacherPanel(
              title: 'Aufgaben',
              trailing: TeacherButton(
                key: const ValueKey('student-assign'),
                label: 'Zuweisen',
                icon: Icons.add_rounded,
                onTap: _assign,
              ),
              child: assignments.isEmpty
                  ? const Text('Keine offenen Aufgaben.', style: kTeacherMuted)
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final a in assignments)
                        _AssignmentRow(
                          assignment: a,
                          progress: AssignmentProgress.of(a, _attempts),
                        ),
                    ]),
            ),
            const SizedBox(height: 12),
            TeacherPanel(
              title: 'Dieses Gerät',
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                    isActive
                        ? '${student.name} nutzt dieses Gerät. Neue Aufgaben landen im Lernbericht von ${student.name}.'
                        : 'Wenn ${student.name} dieses Gerät benutzt, ordne es zu. Dann werden neue Aufgaben ${student.name} zugerechnet.',
                    style: kTeacherMuted),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TeacherButton(
                    key: const ValueKey('student-link-device'),
                    label: isActive ? 'Zuordnung lösen' : 'Gerät zuordnen',
                    icon: isActive ? Icons.link_off_rounded : Icons.link_rounded,
                    filled: !isActive,
                    onTap: () async {
                      await _repo.setActiveStudent(isActive ? null : student.id);
                      await _reload();
                    },
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            StudentReportContent(
                analysis: analysis, attempts: _attempts, showSuggestion: false),
          ],
        ),
      ),
    );
  }

  String? _unitFor(PracticeSuggestion s) {
    // Die Kompetenz „Addition mit Zehnerübergang“ gehört zum Thema der
    // zuletzt geübten Aufgabe dieser Kompetenz.
    for (final a in _attempts.reversed) {
      if (a.competency == s.competency) return a.unit;
    }
    return null;
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.assignment, required this.progress});
  final Assignment assignment;
  final AssignmentProgress progress;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueAt;
    final overdue = due != null && !progress.completed && DateTime.now().isAfter(due);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${assignment.subject}: ${assignment.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: kTeacherLabel.copyWith(fontSize: 14)),
          ),
          Icon(
              progress.completed
                  ? Icons.check_circle_rounded
                  : (overdue ? Icons.schedule_rounded : Icons.radio_button_unchecked),
              color: progress.completed
                  ? const Color(0xFF7BE08C)
                  : (overdue ? const Color(0xFFFFB86B) : Colors.white54),
              size: 22),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 8,
            color: progress.completed
                ? const Color(0xFF7BE08C)
                : LumoVisualTokens.cyanBright,
            backgroundColor: const Color(0x33FFFFFF),
          ),
        ),
        Text(
            '${progress.done > progress.target ? progress.target : progress.done} von ${progress.target} Aufgaben'
            '${progress.done > 0 ? ' · ${progress.correct} richtig' : ''}'
            '${due == null ? '' : ' · bis ${due.day}.${due.month}.'}'
            '${overdue ? ' (überfällig)' : ''}',
            style: kTeacherMuted),
        if (assignment.goal.isNotEmpty)
          Text('Ziel: ${assignment.goal}', style: kTeacherMuted),
      ]),
    );
  }
}
