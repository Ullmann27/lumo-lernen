import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_speech_listener.dart';
import '../../domain/learning/recognized_task.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../learning/renderers/adaptive_task_renderer.dart';
import 'recognized_task_controller.dart';

class LumoTaskRecognitionScreen extends StatefulWidget {
  const LumoTaskRecognitionScreen({
    super.key,
    required this.appState,
    this.speechListener,
  });
  final LumoAppState appState;

  /// The screen owns this listener, including cancellation and disposal.
  /// Production uses the existing shared, local-only recognizer.
  final LumoSpeechListener? speechListener;
  @override
  State<LumoTaskRecognitionScreen> createState() =>
      _LumoTaskRecognitionScreenState();
}

class _LumoTaskRecognitionScreenState extends State<LumoTaskRecognitionScreen>
    with WidgetsBindingObserver {
  late final _controller = RecognizedTaskController(widget.appState);
  late final _speech = widget.speechListener ?? LumoSpeechListener();
  final _input = TextEditingController();
  final _resumed = <String>{};
  late int _inputGeneration = widget.appState.profileGeneration;
  int _speechGeneration = 0;
  bool _preparingSpeech = false, _foreground = true, _attached = true;
  String _heardWords = '';
  String? _speechError;
  ModalRoute<dynamic>? _route;

  bool get _canEdit =>
      mounted &&
      _attached &&
      _foreground &&
      (_route?.isCurrent ?? true) &&
      _controller.ready &&
      _controller.active == null;
  bool get _speechActive =>
      _preparingSpeech ||
      _speech.starting ||
      _speech.listening ||
      _speech.awaitingFinalResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_changed);
    _speech.addListener(_speechChanged);
    widget.appState.addListener(_settingsChanged);
    // Do not initialize the microphone or request permission before a tap.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    if (!(_route?.isCurrent ?? true)) _cancelSpeech();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _cancelSpeech();
  }

  @override
  void deactivate() {
    _attached = false;
    _cancelSpeech();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _attached = true;
  }

  void _changed() {
    if (_inputGeneration != widget.appState.profileGeneration) {
      _inputGeneration = widget.appState.profileGeneration;
      _cancelSpeech();
      _input.clear();
    }
    if (_speechActive && !_canEdit) _cancelSpeech();
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
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(_settingsChanged);
    _speechGeneration++;
    _speech.removeListener(_speechChanged);
    _speech.dispose();
    _controller.removeListener(_changed);
    _controller.dispose();
    _input.dispose();
    super.dispose();
  }

  void _settingsChanged() {
    if (_speechActive && !widget.appState.state.settings.microphoneEnabled) {
      _cancelSpeech();
      if (mounted && _attached) {
        setState(
          () => _speechError =
              'Mikrofon ist im Elternbereich ausgeschaltet. Du kannst tippen.',
        );
      }
    }
  }

  void _speechChanged() {
    if (!mounted || !_attached) return;
    setState(() => _speechError = _speech.error);
  }

  void _cancelSpeech() {
    _speechGeneration++;
    _preparingSpeech = false;
    _heardWords = '';
    _speechError = null;
    unawaited(_speech.cancel());
  }

  Future<void> _startSpeech() async {
    if (!_canEdit || _speechActive) return;
    final generation = ++_speechGeneration;
    final profileGeneration = widget.appState.profileGeneration;
    final owner = _controller.lease!;
    bool current() =>
        _canEdit &&
        generation == _speechGeneration &&
        profileGeneration == widget.appState.profileGeneration &&
        identical(owner, _controller.lease) &&
        widget.appState.isCurrentLearningLease(owner);
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.inputChanged();
    setState(() {
      _preparingSpeech = true;
      _heardWords = '';
      _speechError = null;
    });
    try {
      await widget.appState.ensureSettingsLoaded();
      if (!current()) return;
      if (!widget.appState.state.settings.microphoneEnabled) {
        setState(
          () => _speechError =
              'Mikrofon ist im Elternbereich ausgeschaltet. Du kannst tippen.',
        );
        return;
      }
      await _speech.startListening(
        onResult: (words) {
          if (current()) setState(() => _heardWords = words);
        },
        onFinalResult: (words) {
          if (!current() || !widget.appState.state.settings.microphoneEnabled)
            return;
          // A native final proposes a task; it never submits a learning
          // answer. The existing preview still requires an explicit start.
          _speechGeneration++;
          _preparingSpeech = false;
          _heardWords = '';
          _input.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
          _controller.inputChanged();
          _controller.recognize(words);
        },
      );
    } catch (_) {
      if (current()) {
        setState(
          () => _speechError =
              'Spracheingabe konnte nicht starten. Du kannst deine Aufgabe tippen.',
        );
      }
    } finally {
      if (current()) setState(() => _preparingSpeech = false);
    }
  }

  Widget _speechControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const ValueKey('recognition-speech'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
            onPressed: !_controller.ready
                ? null
                : _speechActive
                ? _cancelSpeech
                : _startSpeech,
            icon: Icon(_speechActive ? Icons.close_rounded : Icons.mic_rounded),
            label: Text(
              _speechActive ? 'Aufnahme abbrechen' : 'Aufgabe sprechen',
            ),
          ),
          if (_speech.listening)
            OutlinedButton(
              key: const ValueKey('recognition-speech-finish'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
              onPressed: _speech.stopListening,
              child: const Text('Fertig gesprochen'),
            ),
        ],
      ),
      if (_speechActive) ...[
        const SizedBox(height: 8),
        Text(
          _speech.awaitingFinalResult
              ? 'Deine Aufnahme wird abgeschlossen …'
              : _speech.listening
              ? 'Ich höre zu. Sprich deine Aufgabe.'
              : 'Mikrofon wird vorbereitet …',
          key: const ValueKey('recognition-speech-status'),
        ),
      ],
      if (_heardWords.isNotEmpty)
        Text(
          'Gehört: $_heardWords',
          key: const ValueKey('recognition-speech-partial'),
        ),
      if (_speechError != null) ...[
        const SizedBox(height: 8),
        Text(_speechError!, key: const ValueKey('recognition-speech-error')),
      ],
    ],
  );

  Widget _button(String text, String key, VoidCallback? action) => FilledButton(
    key: ValueKey(key),
    style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
    onPressed: action,
    child: Text(text),
  );

  Widget _editor() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welche Aufgabe möchtest du üben?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Eine ganze Rechnung mit +, − oder ×, ein Anfangsbuchstabe oder eine Zahlenfolge mit gleichen Abständen.',
          ),
          const SizedBox(height: 12),
          _speechControls(),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('recognition-input'),
            controller: _input,
            enabled: _controller.ready && !_speechActive,
            minLines: 1,
            maxLines: 3,
            maxLength: RecognizedTask.maxInputLength,
            decoration: const InputDecoration(
              labelText: 'Deine Aufgabe',
              hintText: 'Zum Beispiel 12 + 7',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              _cancelSpeech();
              _controller.inputChanged();
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final example in const [
                '12 + 7',
                'Anfangsbuchstabe Mama',
                '2, 4, 6, ?',
              ])
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: !_controller.ready || _speechActive
                      ? null
                      : () {
                          _cancelSpeech();
                          _input.text = example;
                          _controller.inputChanged();
                        },
                  child: Text(example),
                ),
            ],
          ),
          _button(
            'Aufgabe erkennen',
            'recognition-parse',
            !_controller.ready || _speechActive
                ? null
                : () {
                    _cancelSpeech();
                    FocusManager.instance.primaryFocus?.unfocus();
                    _controller.recognize(_input.text);
                  },
          ),
          if (_controller.preview case final task?) ...[
            const SizedBox(height: 18),
            Text(
              'Erkannt: ${task.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              task.prompt,
              key: const ValueKey('recognition-preview'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _button(
              'Genau diese Aufgabe starten',
              'recognition-start',
              _controller.ready && !_speechActive
                  ? () {
                      _cancelSpeech();
                      unawaited(_controller.startPreview());
                    }
                  : null,
            ),
          ],
        ],
      ),
    ),
  );

  Widget _result(RecognizedTaskAttempt attempt) => Card(
    key: const ValueKey('recognition-result'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            attempt.correct ? 'Richtig gelöst!' : 'Danke fürs Ausprobieren!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(attempt.task.prompt),
          Text('Deine Antwort: ${attempt.answer}'),
          Text('Richtige Antwort: ${attempt.task.answer}'),
          const SizedBox(height: 10),
          Text(attempt.task.explanation),
          const SizedBox(height: 14),
          if (attempt.completed) ...[
            Text(
              attempt.stars > 0
                  ? '${attempt.stars} Sterne · ${attempt.xp} XP'
                  : 'Kein Stern geht verloren.',
            ),
            const Text(
              'Als eigene Textaufgabe gespeichert. Dein Lernplan bleibt unverändert.',
            ),
            const SizedBox(height: 12),
            _button(
              'Andere Aufgabe eingeben',
              'recognition-again',
              !_controller.ready
                  ? null
                  : () async {
                      if (await _controller.leave()) _input.clear();
                    },
            ),
          ] else ...[
            Text(
              _controller.busy
                  ? 'Dein Ergebnis wird gespeichert …'
                  : 'Deine Antwort wartet noch auf sicheres Speichern.',
            ),
            if (!_controller.busy)
              _button(
                'Speichern erneut versuchen',
                'recognition-retry',
                _controller.ready ? _controller.retryResult : null,
              ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final attempt = _controller.active;
      return Scaffold(
        backgroundColor: LumoVisualTokens.night,
        appBar: AppBar(title: const Text('Aufgabe erkennen')),
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
                          child: Column(
                            children: [
                              Text(
                                _controller.error!,
                                key: const ValueKey('recognition-error'),
                              ),
                              if (!_controller.current)
                                TextButton(
                                  onPressed: _controller.reload,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                  child: const Text('Erneut laden'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (_controller.current && !_controller.loading) ...[
                      if (attempt == null)
                        _editor()
                      else if (attempt.answered)
                        _result(attempt)
                      else ...[
                        Text(
                          'Deine erkannte ${attempt.task.label}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AbsorbPointer(
                          absorbing: !_controller.ready,
                          child: AdaptiveTaskRenderer(
                            key: ValueKey(attempt.id),
                            task: attempt.task.toTaskInstance(
                              attemptId: attempt.id,
                              ownerId: attempt.ownerId,
                              startedAt: attempt.startedAt,
                            ),
                            allowRetry: false,
                            reduceMotion:
                                widget.appState.state.settings.reduceAnimations,
                            onAnswered: _controller.answer,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _button(
                          'Andere Aufgabe eingeben',
                          'recognition-cancel-task',
                          _controller.ready ? _controller.leave : null,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
