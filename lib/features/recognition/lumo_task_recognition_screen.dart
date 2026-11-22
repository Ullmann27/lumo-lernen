import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../domain/learning/recognized_task.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../learning/renderers/adaptive_task_renderer.dart';
import 'recognized_task_controller.dart';

class LumoTaskRecognitionScreen extends StatefulWidget {
  const LumoTaskRecognitionScreen({super.key, required this.appState});
  final LumoAppState appState;
  @override
  State<LumoTaskRecognitionScreen> createState() =>
      _LumoTaskRecognitionScreenState();
}

class _LumoTaskRecognitionScreenState extends State<LumoTaskRecognitionScreen> {
  late final _controller = RecognizedTaskController(widget.appState);
  final _input = TextEditingController();
  final _resumed = <String>{};
  late int _inputGeneration = widget.appState.profileGeneration;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  void _changed() {
    if (_inputGeneration != widget.appState.profileGeneration) {
      _inputGeneration = widget.appState.profileGeneration;
      _input.clear();
    }
    final attempt = _controller.active;
    if (_controller.ready &&
        attempt != null &&
        attempt.answered &&
        !attempt.completed &&
        _controller.error == null &&
        _resumed.add(attempt.id)) {
      scheduleMicrotask(() {
        if (mounted && _controller.ready) unawaited(_controller.retryResult());
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    _input.dispose();
    super.dispose();
  }

  Widget _button(String text, String key, VoidCallback? action) => FilledButton(
      key: ValueKey(key),
      style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
      onPressed: action,
      child: Text(text));

  Widget _editor() => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Welche Aufgabe möchtest du üben?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
                'Eine ganze Rechnung mit +, − oder ×, ein Anfangsbuchstabe oder eine Zahlenfolge mit gleichen Abständen.'),
            const SizedBox(height: 14),
            TextField(
                key: const ValueKey('recognition-input'),
                controller: _input,
                enabled: _controller.ready,
                minLines: 1,
                maxLines: 3,
                maxLength: RecognizedTask.maxInputLength,
                decoration: const InputDecoration(
                    labelText: 'Deine Aufgabe',
                    hintText: 'Zum Beispiel 12 + 7',
                    border: OutlineInputBorder()),
                onChanged: (_) => _controller.inputChanged()),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final example in const [
                '12 + 7',
                'Anfangsbuchstabe Mama',
                '2, 4, 6, ?'
              ])
                TextButton(
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: !_controller.ready
                        ? null
                        : () {
                            _input.text = example;
                            _controller.inputChanged();
                          },
                    child: Text(example)),
            ]),
            _button(
                'Aufgabe erkennen',
                'recognition-parse',
                !_controller.ready
                    ? null
                    : () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _controller.recognize(_input.text);
                      }),
            if (_controller.preview case final task?) ...[
              const SizedBox(height: 18),
              Text('Erkannt: ${task.label}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(task.prompt,
                  key: const ValueKey('recognition-preview'),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _button('Genau diese Aufgabe starten', 'recognition-start',
                  _controller.ready ? _controller.startPreview : null),
            ],
          ])));

  Widget _result(RecognizedTaskAttempt attempt) => Card(
      key: const ValueKey('recognition-result'),
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
                attempt.correct
                    ? 'Richtig gelöst!'
                    : 'Danke fürs Ausprobieren!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(attempt.task.prompt),
            Text('Deine Antwort: ${attempt.answer}'),
            Text('Richtige Antwort: ${attempt.task.answer}'),
            const SizedBox(height: 10),
            Text(attempt.task.explanation),
            const SizedBox(height: 14),
            if (attempt.completed) ...[
              Text(attempt.stars > 0
                  ? '${attempt.stars} Sterne · ${attempt.xp} XP'
                  : 'Kein Stern geht verloren.'),
              const Text(
                  'Als eigene Textaufgabe gespeichert. Dein Lernplan bleibt unverändert.'),
              const SizedBox(height: 12),
              _button(
                  'Andere Aufgabe eingeben',
                  'recognition-again',
                  !_controller.ready
                      ? null
                      : () async {
                          if (await _controller.leave()) _input.clear();
                        }),
            ] else ...[
              Text(_controller.busy
                  ? 'Dein Ergebnis wird gespeichert …'
                  : 'Deine Antwort wartet noch auf sicheres Speichern.'),
              if (!_controller.busy)
                _button('Speichern erneut versuchen', 'recognition-retry',
                    _controller.ready ? _controller.retryResult : null),
            ],
          ])));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final attempt = _controller.active;
        return Scaffold(
            backgroundColor: LumoVisualTokens.night,
            appBar: AppBar(title: const Text('Aufgabe eintippen')),
            body: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_controller.loading || _controller.busy)
                                    const LinearProgressIndicator(),
                                  if (_controller.error != null)
                                    Card(
                                        color: const Color(0xFFFFEFE2),
                                        child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(children: [
                                              Text(_controller.error!,
                                                  key: const ValueKey(
                                                      'recognition-error')),
                                              if (!_controller.current)
                                                TextButton(
                                                    onPressed:
                                                        _controller.reload,
                                                    style: TextButton.styleFrom(
                                                        minimumSize:
                                                            const Size(48, 48)),
                                                    child: const Text(
                                                        'Erneut laden')),
                                            ]))),
                                  if (_controller.current &&
                                      !_controller.loading) ...[
                                    if (attempt == null)
                                      _editor()
                                    else if (attempt.answered)
                                      _result(attempt)
                                    else ...[
                                      Text(
                                          'Deine erkannte ${attempt.task.label}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18)),
                                      const SizedBox(height: 12),
                                      AbsorbPointer(
                                          absorbing: !_controller.ready,
                                          child: AdaptiveTaskRenderer(
                                              key: ValueKey(attempt.id),
                                              task: attempt.task.toTaskInstance(
                                                  attemptId: attempt.id,
                                                  ownerId: attempt.ownerId,
                                                  startedAt: attempt.startedAt),
                                              allowRetry: false,
                                              reduceMotion: widget
                                                  .appState
                                                  .state
                                                  .settings
                                                  .reduceAnimations,
                                              onAnswered: _controller.answer)),
                                      const SizedBox(height: 14),
                                      _button(
                                          'Andere Aufgabe eingeben',
                                          'recognition-cancel-task',
                                          _controller.ready
                                              ? _controller.leave
                                              : null),
                                    ],
                                  ],
                                ]))))));
      });
}
