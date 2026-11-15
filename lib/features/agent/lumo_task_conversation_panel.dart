import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_context_engine.dart';
import '../../core/lumo_conversation_controller.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_task_dialogue_engine.dart';
import '../../core/lumo_voice.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

/// Real task-local half-duplex voice dialogue. No transcript is persisted.
/// The parent-owned lesson is the only source of truth for scoring, and this
/// widget never submits answers or modifies the learning progress repository.
class LumoTaskConversationPanel extends StatefulWidget {
  const LumoTaskConversationPanel({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<LumoTaskConversationPanel> createState() =>
      _LumoTaskConversationPanelState();
}

class _LumoTaskConversationPanelState extends State<LumoTaskConversationPanel>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _speech = LumoSpeechListener();
  late final LumoContextEngine _context;
  late final LumoConversationController _conversation;

  int _epoch = 0;
  int _silences = 0;
  bool _foreground = true;
  bool _continuous = false;
  bool _listening = false;
  bool _processing = false;
  String _answer = 'Frag mich zur Aufgabe. Du kannst auch eine andere Erklärung verlangen.';
  String _notice = '';
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _context = LumoContextEngine(widget.appState);
    _conversation = LumoConversationController(_context);
    _context.addListener(_scopeChanged);
    _conversation.addListener(_refresh);
    _speech.addListener(_refresh);
    widget.appState.addListener(_settingsChanged);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _scopeChanged() {
    ++_epoch;
    _continuous = false;
    _conversation.interrupt();
    unawaited(_speech.cancel());
    if (mounted) {
      setState(() {
        _listening = false;
        _processing = false;
        _answer = 'Die Aufgabe hat gewechselt. Frag mich zur neuen Aufgabe.';
        _transcript = '';
      });
    }
  }

  void _settingsChanged() {
    if (!_continuous || widget.appState.state.settings.microphoneEnabled) return;
    unawaited(_interrupt(continueListening: false));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _continuous = false;
      ++_epoch;
      _conversation.pause();
      unawaited(_speech.cancel());
      unawaited(LumoVoice.instance.stop());
      if (mounted) {
        setState(() {
          _listening = false;
          _processing = false;
        });
      }
    } else {
      _conversation.resume();
      _refresh();
    }
  }

  bool get _mayContinue =>
      mounted && _foreground && _continuous &&
      widget.appState.state.settings.microphoneEnabled;

  Future<void> _listen({bool newSession = false}) async {
    if (!mounted || !_foreground || _listening || _processing) return;
    // Loading parent settings can change the context revision. Resolve that
    // before activating the new listening session so the first tap works.
    await widget.appState.ensureSettingsLoaded();
    if (!mounted || !_foreground) return;
    if (newSession) {
      _continuous = true;
      _silences = 0;
    }
    final token = _epoch;
    if (!_mayContinue || token != _epoch) {
      if (mounted && !widget.appState.state.settings.microphoneEnabled) {
        setState(() {
          _continuous = false;
          _notice = 'Das Mikrofon muss im Elternbereich freigegeben werden. '
              'Du kannst weiterhin tippen.';
        });
      }
      return;
    }
    await LumoVoice.instance.stop();
    final ready = await _speech.initialize();
    if (!_mayContinue || token != _epoch) return;
    if (!ready) {
      setState(() {
        _continuous = false;
        _notice = _speech.error ??
            'Lokale Spracherkennung fehlt auf diesem Gerät. '
                'Du kannst deine Frage tippen.';
      });
      return;
    }
    setState(() {
      _listening = true;
      _transcript = '';
      _notice = '';
    });
    _conversation.listening(true);
    try {
      await _speech.startListening(
        onResult: (text) {
          if (!mounted || token != _epoch || !_foreground) return;
          if (_isStop(text)) {
            unawaited(_interrupt(continueListening: true));
            return;
          }
          setState(() => _transcript = text);
        },
        onFinalResult: (text) {
          if (!mounted || token != _epoch || !_foreground) return;
          _silences = 0;
          unawaited(_submit(text));
        },
        onNoMatch: () {
          if (!_mayContinue || token != _epoch) return;
          _silences++;
          setState(() => _listening = false);
          if (_silences >= 2) {
            setState(() {
              _continuous = false;
              _notice = 'Ich höre gerade keine Antwort. '
                  'Du kannst tippen oder das Mikrofon erneut starten.';
            });
          } else {
            scheduleMicrotask(() => unawaited(_listen()));
          }
        },
      );
    } catch (_) {
      if (mounted && token == _epoch) {
        setState(() {
          _listening = false;
          _continuous = false;
          _notice = 'Spracherkennung ist nicht bereit. '
              'Die Texteingabe bleibt verfügbar.';
        });
      }
    }
  }

  bool _isStop(String input) => RegExp(
    r'^\s*(stopp|stop|halt|hör auf)[.! ]*$',
    caseSensitive: false,
  ).hasMatch(input);

  Future<void> _submit(String question) async {
    final text = question.trim();
    if (text.isEmpty || !mounted || !_foreground || _processing) return;
    if (_isStop(text)) {
      await _interrupt(continueListening: true);
      return;
    }
    final token = ++_epoch;
    // The audio gate is real: the microphone is closed before any TTS begins.
    await _speech.cancel();
    if (!mounted || !_foreground || token != _epoch) return;
    setState(() {
      _listening = false;
      _processing = true;
      _notice = '';
    });
    final answer = await _conversation.ask(text);
    if (!mounted || !_foreground || token != _epoch) return;
    if (answer.source == 'cancelled') {
      setState(() => _processing = false);
      return;
    }
    setState(() {
      _processing = false;
      _answer = answer.reply;
      _transcript = '';
      _input.clear();
    });
    await _speakAnswer(answer.reply,
        slower: _conversation.lastTaskAction == LumoTaskDialogueAction.slower);
    if (_mayContinue && token == _epoch) {
      unawaited(_listen());
    }
  }

  Future<void> _speakAnswer(String text, {bool slower = false}) async {
    final settings = widget.appState.state.settings;
    if (!settings.voiceEnabled || text.isEmpty) return;
    if (slower) {
      await LumoVoice.instance.configure(
          rate: (settings.voiceRate * 0.8).clamp(0.245, 0.56).toDouble());
    }
    try {
      await _conversation.speak(text, style: VoiceStyle.explain);
    } finally {
      if (slower) {
        await LumoVoice.instance.configure(rate: settings.voiceRate);
      }
    }
  }

  Future<void> _repeat({bool slower = false}) async {
    if (_processing || !mounted || _answer.trim().isEmpty) return;
    final token = ++_epoch;
    await _speech.cancel();
    if (!mounted || token != _epoch) return;
    setState(() => _listening = false);
    await _speakAnswer(_answer, slower: slower);
    if (_mayContinue && token == _epoch) {
      unawaited(_listen());
    }
  }

  /// Interrupts the current TTS, pending model answer and mouth envelope.
  /// A stopped turn cannot be delivered later or affect another task.
  Future<void> _interrupt({required bool continueListening}) async {
    final restart = continueListening && _continuous;
    ++_epoch;
    _continuous = restart;
    _conversation.interrupt();
    await _speech.cancel();
    await LumoVoice.instance.stop();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _processing = false;
      _transcript = '';
      _notice = restart ? 'Ich höre wieder zu.' : '';
    });
    if (_mayContinue) unawaited(_listen());
  }

  String get _phase {
    if (!_foreground) return 'pausiert';
    if (_processing) return 'verarbeitet';
    if (_listening) return 'hört zu';
    switch (LumoVoice.instance.status.value) {
      case VoiceStatus.speaking:
        return 'spricht';
      case VoiceStatus.preparing:
        return 'bereitet Sprache vor';
      case VoiceStatus.error:
        return 'Stimme nicht verfügbar';
      case VoiceStatus.paused:
        return 'pausiert';
      case VoiceStatus.idle:
        break;
    }
    return _continuous ? 'wartet' : 'bereit';
  }

  @override
  void dispose() {
    ++_epoch;
    _continuous = false;
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(_settingsChanged);
    _context.removeListener(_scopeChanged);
    _conversation.removeListener(_refresh);
    _speech.removeListener(_refresh);
    _conversation.dispose();
    _context.dispose();
    _speech.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = _context.task;
    final phase = _phase;
    final settings = widget.appState.state.settings;
    return Column(
      key: const ValueKey('lumo-task-conversation-panel'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          LumoCharacter(
            pose: _listening
                ? LumoDesignFoxPose.armsOpen
                : _processing
                    ? LumoDesignFoxPose.bookPoint
                    : LumoDesignFoxPose.teacherStick,
            size: 86,
            intro: false,
            idleHops: false,
            reduceMotion: settings.reduceAnimations || settings.calmMode,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LUMO · LERNBEGLEITER',
                style: TextStyle(fontWeight: FontWeight.w800)),
              Text('Status: ' + phase,
                key: const ValueKey('lumo-task-voice-status')),
              Text(task?.prompt ?? 'Keine Aufgabe geöffnet',
                maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
        const SizedBox(height: 14),
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lumo sagt', style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(_processing ? 'Ich prüfe deine Frage ...' : _answer,
                      key: const ValueKey('lumo-task-answer'),
                      style: const TextStyle(fontSize: 17, height: 1.4)),
                  ValueListenableBuilder<LumoConversationCue?>(
                    valueListenable: _conversation.activeCue,
                    builder: (_, cue, __) {
                      if (cue == null || cue.subtitle == _answer) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(cue.subtitle,
                          key: const ValueKey('lumo-task-subtitles')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_transcript.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Erkannt: ' + _transcript,
              key: const ValueKey('lumo-task-transcript')),
        ),
        if (_notice.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_notice, key: const ValueKey('lumo-task-notice')),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            key: const ValueKey('lumo-task-start-mic'),
            onPressed: _processing || _continuous
                ? null : () => unawaited(_listen(newSession: true)),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Gespräch starten'),
          ),
          if (_continuous) OutlinedButton.icon(
            key: const ValueKey('lumo-task-end-mic'),
            onPressed: () => unawaited(
                _interrupt(continueListening: false)),
            icon: const Icon(Icons.call_end_rounded),
            label: const Text('Gespräch beenden'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('lumo-task-repeat'),
            onPressed: _processing ? null :
                () => unawaited(_repeat()),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Noch einmal'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('lumo-task-slower'),
            onPressed: _processing ? null :
                () => unawaited(_repeat(slower: true)),
            icon: const Icon(Icons.slow_motion_video_rounded),
            label: const Text('Langsamer'),
          ),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: _input,
          key: const ValueKey('lumo-task-text-input'),
          maxLines: 2,
          onSubmitted: _processing
              ? null : (value) => unawaited(_submit(value)),
          decoration: const InputDecoration(
            labelText: 'Schreib deine Frage oder Korrektur',
            hintText: 'Warum zuerst zwei?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const ValueKey('lumo-task-text-send'),
          onPressed: _processing ? null :
              () => unawaited(_submit(_input.text)),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Fragen'),
        ),
        if (!settings.microphoneEnabled) const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Mikrofon im Elternbereich deaktiviert. '
              'Die Text- und Lernhilfe bleibt nutzbar.'),
        ),
        if (LumoVoice.instance.lastError.value != null &&
            settings.voiceEnabled) const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Diese Antwort kann gerade nicht vorgelesen werden. '
              'Du kannst sie oben lesen.'),
        ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(children: [
              Icon(_listening ? Icons.mic_rounded : Icons.mic_off_rounded,
                  color: _listening ? Colors.greenAccent : null),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Mikrofon: ' + phase,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    key: const ValueKey('lumo-task-voice-indicator')),
              ),
              OutlinedButton.icon(
                key: const ValueKey('lumo-task-stop'),
                onPressed: () => unawaited(
                    _interrupt(continueListening: true)),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stopp'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
