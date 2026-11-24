import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../domain/learning/parent_authored_task.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../learning/renderers/adaptive_task_renderer.dart';
import 'parent_task_workspace_controller.dart';

class ParentTaskPracticeScreen extends StatefulWidget {
  const ParentTaskPracticeScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<ParentTaskPracticeScreen> createState() =>
      _ParentTaskPracticeScreenState();
}

class _ParentTaskPracticeScreenState extends State<ParentTaskPracticeScreen> {
  late final _controller = ParentTaskWorkspaceController(widget.appState);
  final Set<String> _resumed = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_resumeSavedAnswer);
  }

  void _resumeSavedAnswer() {
    final attempt = _controller.activeAttempt;
    if (!_controller.ready ||
        attempt == null ||
        !attempt.answered ||
        attempt.completed ||
        _controller.error != null ||
        !_resumed.add(attempt.id)) {
      return;
    }
    scheduleMicrotask(() {
      if (mounted && _controller.ready) unawaited(_controller.retryResult());
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_resumeSavedAnswer);
    _controller.dispose();
    super.dispose();
  }

  Widget _result(ParentTaskAttempt attempt) => Card(
        key: const ValueKey('parent-task-result'),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    attempt.correct!
                        ? 'Richtig gelöst!'
                        : 'Danke fürs Ausprobieren!',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(attempt.task.content.prompt),
                const SizedBox(height: 8),
                Text('Deine Antwort: ${attempt.answer}'),
                Text('Richtige Antwort: ${attempt.task.content.correctAnswer}'),
                if (attempt.task.content.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Erklärung von deinen Eltern',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(attempt.task.content.explanation),
                ],
                const SizedBox(height: 16),
                if (attempt.completed) ...[
                  Text(attempt.stars > 0
                      ? '${attempt.stars} Sterne · ${attempt.xp} XP'
                      : 'Kein Stern geht verloren.'),
                  const Text(
                      'Dein Ergebnis ist als Elternaufgabe gespeichert.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      key: const ValueKey('parent-task-back-to-list'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 52)),
                      onPressed:
                          _controller.ready ? _controller.leaveAttempt : null,
                      icon: const Icon(Icons.list_rounded),
                      label: const Text('Zur Aufgabenliste')),
                ] else ...[
                  Text(_controller.busy
                      ? 'Dein Ergebnis wird gespeichert …'
                      : 'Deine Antwort bleibt offen, bis das Ergebnis gespeichert ist.'),
                  if (!_controller.busy)
                    FilledButton.icon(
                        key: const ValueKey('parent-task-retry-result'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 52)),
                        onPressed:
                            _controller.ready ? _controller.retryResult : null,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Ergebnis speichern')),
                ],
              ],
            )),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final attempt = _controller.activeAttempt;
          return PopScope(
            canPop: !_controller.busy && !_controller.hasPendingResult,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bitte dein Ergebnis zuerst speichern.')));
              }
            },
            child: Scaffold(
              backgroundColor: const Color(0xFF081A38),
              appBar: AppBar(title: const Text('Aufgaben von deinen Eltern')),
              body: SafeArea(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Elternaufgaben',
                          style: TextStyle(
                              color: LumoVisualTokens.gold,
                              fontWeight: FontWeight.w800)),
                      const Text('Hier übst du die Fragen deiner Eltern.',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      if (_controller.loading)
                        const Center(child: CircularProgressIndicator()),
                      if (_controller.error != null)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(children: [
                                  Text(_controller.error!,
                                      key: const ValueKey(
                                          'parent-task-practice-error')),
                                  if (attempt == null)
                                    TextButton(
                                        style: TextButton.styleFrom(
                                            minimumSize: const Size(48, 48)),
                                        onPressed: _controller.busy
                                            ? null
                                            : _controller.reload,
                                        child: const Text('Erneut laden')),
                                ]))),
                      if (_controller.current && !_controller.loading) ...[
                        if (attempt == null) ...[
                          if (_controller.workspace!.tasks.isEmpty)
                            const Text(
                                'Für dieses Kinderprofil gibt es noch keine Elternaufgaben.',
                                style: TextStyle(color: Colors.white)),
                          for (final task in _controller.workspace!.tasks)
                            Card(
                                child: ListTile(
                              key: ValueKey('parent-task-start-${task.id}'),
                              minVerticalPadding: 16,
                              title: Text(task.content.prompt),
                              subtitle: Text(
                                  '${parentTaskSubjectLabel(task.content.subject)} · Klasse ${task.content.grade}'),
                              trailing:
                                  const Icon(Icons.play_circle_fill_rounded),
                              onTap: _controller.ready
                                  ? () => _controller.start(task.id)
                                  : null,
                            )),
                        ] else if (attempt.answered)
                          _result(attempt)
                        else ...[
                          Text(
                              '${parentTaskSubjectLabel(attempt.task.content.subject)} · Klasse ${attempt.task.content.grade}',
                              style: const TextStyle(
                                  color: LumoVisualTokens.muted)),
                          const SizedBox(height: 12),
                          AbsorbPointer(
                              absorbing: !_controller.ready,
                              child: AdaptiveTaskRenderer(
                                key: ValueKey(attempt.id),
                                task: attempt.task.toTaskInstance(
                                    attemptId: attempt.id,
                                    startedAt: attempt.startedAt),
                                allowRetry: false,
                                reduceMotion: widget
                                    .appState.state.settings.reduceAnimations,
                                onAnswered: _controller.answer,
                              )),
                          const SizedBox(height: 16),
                          TextButton(
                              style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48)),
                              onPressed: _controller.ready
                                  ? _controller.leaveAttempt
                                  : null,
                              child: const Text('Andere Elternaufgabe wählen')),
                        ],
                      ],
                    ]),
              )),
            ),
          );
        },
      );
}
