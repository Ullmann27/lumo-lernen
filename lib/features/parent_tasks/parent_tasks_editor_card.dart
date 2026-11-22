import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../domain/learning/parent_authored_task.dart';
import 'parent_task_workspace_controller.dart';

/// Settings entry: root's existing parent area owns the access policy.
class ParentTasksEditorCard extends StatefulWidget {
  const ParentTasksEditorCard({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<ParentTasksEditorCard> createState() => _ParentTasksEditorCardState();
}

class _ParentTasksEditorCardState extends State<ParentTasksEditorCard> {
  late final _controller = ParentTaskWorkspaceController(widget.appState);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit([ParentAuthoredTask? task]) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _ParentTaskEditorDialog(controller: _controller, task: task),
      );

  Future<void> _remove(ParentAuthoredTask task) async {
    final owner = _controller.lease?.studentId;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Elternaufgabe entfernen?'),
              content: const Text(
                  'Bereits gespeicherte Ergebnisse bleiben im Lernbericht erhalten.'),
              actions: [
                TextButton(
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Behalten')),
                FilledButton(
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Entfernen')),
              ],
            ));
    if (confirmed == true && mounted && _controller.lease?.studentId == owner) {
      await _controller.remove(task);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final tasks = _controller.workspace?.tasks ?? <ParentAuthoredTask>[];
          return Card(
            key: const ValueKey('parent-tasks-editor'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Eigene Elternaufgaben',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                        'Formuliere eigene Fragen für das ausgewählte Kind. '
                        'Es übt sie auf der Startseite unter „Aufgaben von deinen Eltern“. '
                        'Die Ergebnisse sind als Elternaufgaben gekennzeichnet und '
                        'verändern keine Lehrplan- oder Prüfungsbewertung.'),
                    if (_controller.loading)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator())),
                    if (!_controller.loading && _controller.current) ...[
                      const SizedBox(height: 12),
                      Text(
                          'Für ${_controller.profileName} · ${tasks.length} '
                          '${tasks.length == 1 ? 'Aufgabe' : 'Aufgaben'}',
                          key: const ValueKey('parent-tasks-profile')),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        key: const ValueKey('parent-task-add'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 52)),
                        onPressed: _controller.ready ? () => _edit() : null,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Eigene Aufgabe anlegen'),
                      ),
                      for (final task in tasks)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(task.content.prompt,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      '${parentTaskSubjectLabel(task.content.subject)} · Klasse ${task.content.grade}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ])),
                            IconButton(
                                key: ValueKey('parent-task-edit-${task.id}'),
                                tooltip: 'Aufgabe bearbeiten',
                                constraints: const BoxConstraints(
                                    minWidth: 48, minHeight: 48),
                                onPressed: _controller.ready
                                    ? () => _edit(task)
                                    : null,
                                icon: const Icon(Icons.edit_outlined)),
                            IconButton(
                                key: ValueKey('parent-task-delete-${task.id}'),
                                tooltip: 'Aufgabe entfernen',
                                constraints: const BoxConstraints(
                                    minWidth: 48, minHeight: 48),
                                onPressed: _controller.ready
                                    ? () => _remove(task)
                                    : null,
                                icon: const Icon(Icons.delete_outline)),
                          ]),
                        ),
                    ],
                    if (_controller.error != null) ...[
                      const SizedBox(height: 8),
                      Text(_controller.error!,
                          key: const ValueKey('parent-tasks-error')),
                      TextButton(
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48)),
                          onPressed:
                              _controller.busy ? null : _controller.reload,
                          child: const Text('Erneut laden')),
                    ],
                  ]),
            ),
          );
        },
      );
}

class _ParentTaskEditorDialog extends StatefulWidget {
  const _ParentTaskEditorDialog({required this.controller, this.task});
  final ParentTaskWorkspaceController controller;
  final ParentAuthoredTask? task;

  @override
  State<_ParentTaskEditorDialog> createState() =>
      _ParentTaskEditorDialogState();
}

class _ParentTaskEditorDialogState extends State<_ParentTaskEditorDialog> {
  late final String _owner = widget.controller.lease!.studentId;
  late final _question =
      TextEditingController(text: widget.task?.content.prompt);
  late final _correct =
      TextEditingController(text: widget.task?.content.correctAnswer);
  late final _others = TextEditingController(
      text: widget.task?.content.options
          .where((value) => value != widget.task!.content.correctAnswer)
          .join('\n'));
  late final _explanation =
      TextEditingController(text: widget.task?.content.explanation);
  late LearningSubject _subject =
      widget.task?.content.subject ?? LearningSubject.mathematik;
  late int _grade =
      widget.task?.content.grade ?? widget.controller.appState.state.grade;
  String? _validation;

  @override
  void dispose() {
    _question.dispose();
    _correct.dispose();
    _others.dispose();
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final draft = ParentTaskDraft(
          subject: _subject,
          grade: _grade,
          prompt: _question.text,
          correctAnswer: _correct.text,
          options: [
            _correct.text,
            ..._others.text
                .split('\n')
                .where((value) => value.trim().isNotEmpty)
          ],
          explanation: _explanation.text);
      setState(() => _validation = null);
      final saved = await widget.controller.save(draft, previous: widget.task);
      if (mounted && saved) Navigator.pop(context);
    } on FormatException catch (error) {
      setState(() => _validation = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final sameOwner = widget.controller.current &&
              widget.controller.lease?.studentId == _owner;
          final enabled = sameOwner && widget.controller.ready;
          return PopScope(
            canPop: !widget.controller.busy,
            child: AlertDialog(
              title: Text(widget.task == null
                  ? 'Eigene Aufgabe anlegen'
                  : 'Elternaufgabe bearbeiten'),
              scrollable: true,
              content: SizedBox(
                  width: 480,
                  child: sameOwner
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              DropdownButtonFormField<LearningSubject>(
                                key: const ValueKey('parent-task-subject'),
                                initialValue: _subject,
                                decoration:
                                    const InputDecoration(labelText: 'Fach'),
                                items: [
                                  for (final subject in LearningSubject.values)
                                    DropdownMenuItem(
                                        value: subject,
                                        child: Text(
                                            parentTaskSubjectLabel(subject)))
                                ],
                                onChanged: enabled
                                    ? (value) =>
                                        setState(() => _subject = value!)
                                    : null,
                              ),
                              DropdownButtonFormField<int>(
                                key: const ValueKey('parent-task-grade'),
                                initialValue: _grade,
                                decoration:
                                    const InputDecoration(labelText: 'Klasse'),
                                items: [
                                  for (var grade = 1; grade <= 4; grade++)
                                    DropdownMenuItem(
                                        value: grade,
                                        child: Text('Klasse $grade'))
                                ],
                                onChanged: enabled
                                    ? (value) => setState(() => _grade = value!)
                                    : null,
                              ),
                              TextField(
                                  key: const ValueKey('parent-task-question'),
                                  controller: _question,
                                  enabled: enabled,
                                  minLines: 2,
                                  maxLines: 5,
                                  maxLength: 1500,
                                  decoration: const InputDecoration(
                                      labelText: 'Deine Frage')),
                              TextField(
                                  key: const ValueKey('parent-task-correct'),
                                  controller: _correct,
                                  enabled: enabled,
                                  maxLength: 240,
                                  decoration: const InputDecoration(
                                      labelText: 'Richtige Antwort')),
                              TextField(
                                  key: const ValueKey(
                                      'parent-task-other-answers'),
                                  controller: _others,
                                  enabled: enabled,
                                  minLines: 2,
                                  maxLines: 6,
                                  decoration: const InputDecoration(
                                      labelText: 'Andere Antworten',
                                      helperText:
                                          '1 bis 5 andere Antworten, eine pro Zeile.\n'
                                          'Die richtige Antwort wird automatisch aufgenommen.',
                                      helperMaxLines: 3)),
                              const SizedBox(height: 8),
                              TextField(
                                  key:
                                      const ValueKey('parent-task-explanation'),
                                  controller: _explanation,
                                  enabled: enabled,
                                  minLines: 2,
                                  maxLines: 5,
                                  maxLength: 2000,
                                  decoration: const InputDecoration(
                                      labelText: 'Erklärung (freiwillig)',
                                      helperText:
                                          'Wird nach der Antwort gezeigt.')),
                              if (_validation ?? widget.controller.error
                                  case final String problem)
                                Text(problem,
                                    key: const ValueKey(
                                        'parent-task-validation'),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)),
                            ])
                      : const Text('Das Kinderprofil wurde gewechselt. '
                          'Bitte die Aufgabe im gewünschten Profil neu öffnen.')),
              actions: [
                TextButton(
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: widget.controller.busy
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Schließen')),
                if (sameOwner)
                  FilledButton(
                      key: const ValueKey('parent-task-save'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: enabled ? _save : null,
                      child: Text(widget.controller.busy
                          ? 'Wird gespeichert …'
                          : 'Aufgabe speichern')),
              ],
            ),
          );
        },
      );
}
