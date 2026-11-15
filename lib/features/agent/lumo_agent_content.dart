import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_context_engine.dart';
import '../../core/lumo_conversation_controller.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_task_dialogue.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

typedef LumoConfirmedTaskAnswer = Future<bool> Function(
    LumoTaskDialogueReply reply);

/// The same conversation is available in the app sheet and beside a real task.
/// Confirmation is delegated to that task's existing authoritative controller.
class LumoAgentContent extends StatefulWidget {
  const LumoAgentContent(
      {super.key,
      required this.appState,
      required this.onSection,
      this.compact = false,
      this.onConfirmedAnswer,
      this.speechForTesting,
      this.onReviewedHelp});
  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;
  final bool compact;
  final LumoConfirmedTaskAnswer? onConfirmedAnswer;
  final LumoSpeechListener? speechForTesting;
  final ValueChanged<LumoTaskDialogueReply>? onReviewedHelp;
  @override
  State<LumoAgentContent> createState() => _LumoAgentContentState();
}

class _LumoAgentContentState extends State<LumoAgentContent>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  late final LumoSpeechListener _speech;
  late final LumoContextEngine _context;
  late final LumoConversationController _conversation;
  bool _foreground = true, _busy = false, _voiceMode = false;
  bool _starting = false, _showHistory = false;
  bool _confirming = false;
  int _capture = 0, _turn = 0, _noMatchCount = 0;
  String _answer = 'Ich bin Lumo, deine digitale Lernfigur. '
      'Du kannst mich zur Aufgabe fragen oder deine Frage tippen.';
  String _source = 'local_ready', _scope = '', _heard = '';
  String? _notice;
  LumoTaskDialogueReply? _draft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech = widget.speechForTesting ?? LumoSpeechListener();
    _context = LumoContextEngine(widget.appState);
    _scope = _context.conversationScope;
    _conversation = LumoConversationController(_context);
    _context.addListener(_contextChanged);
    _conversation.addListener(_changed);
    _speech.addListener(_changed);
  }

  void _changed() {
    if (mounted && _foreground) setState(() {});
  }

  void _contextChanged() {
    final same = _scope == _context.conversationScope;
    _scope = _context.conversationScope;
    _capture++;
    _turn++;
    _voiceMode = false;
    _starting = false;
    unawaited(_speech.cancel());
    _input.clear();
    if (mounted) {
      setState(() {
        _busy = false;
        _draft = null;
        _heard = '';
        if (!same) {
          _answer =
              'Ich bin bei deiner aktuellen Aufgabe. Was möchtest du wissen?';
          _source = 'local_ready';
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _capture++;
      _turn++;
      _voiceMode = false;
      _starting = false;
      _conversation.pause();
      unawaited(_speech.cancel());
      _busy = false;
      _notice = 'Das Gespräch ist pausiert. Deine Aufgabe bleibt erhalten.';
    } else {
      _conversation.resume();
      if (mounted) setState(() {});
    }
  }

  bool _currentCapture(int token, int revision) =>
      mounted &&
      _foreground &&
      _voiceMode &&
      token == _capture &&
      revision == _context.revision;

  Future<void> _startVoice({bool tapped = false}) async {
    if (!mounted || !_foreground || _starting || _speech.listening) return;
    if (!tapped && !_voiceMode) return;
    if (tapped) {
      _voiceMode = true;
      _noMatchCount = 0;
    }
    final token = ++_capture, revision = _context.revision;
    setState(() {
      _starting = true;
      _notice = null;
    });
    await widget.appState.ensureSettingsLoaded();
    if (!_currentCapture(token, revision)) return;
    if (!widget.appState.state.settings.microphoneEnabled) {
      setState(() {
        _voiceMode = false;
        _starting = false;
        _notice =
            'Das Mikrofon ist im Elternbereich ausgeschaltet. Tippen geht weiterhin.';
      });
      return;
    }
    final ready = await _speech.initialize();
    if (!_currentCapture(token, revision)) return;
    if (!ready) {
      setState(() {
        _starting = false;
        _voiceMode = false;
        _notice = _speech.error ??
            'Spracheingabe ist nicht bereit. Du kannst tippen.';
      });
      return;
    }
    try {
      await _speech.startListening(
        onResult: (words) {
          if (!_currentCapture(token, revision)) return;
          setState(() {
            _heard = words;
            _input.text = words;
          });
        },
        onFinalResult: (words) {
          if (!_currentCapture(token, revision)) return;
          final recognition = _speech.lastRecognition;
          unawaited(
              _finishCapture(words, recognition?.confidence, token, revision));
        },
        onNoMatch: () {
          if (_currentCapture(token, revision)) {
            unawaited(_noMatch(token, revision));
          }
        },
      );
      if (_currentCapture(token, revision)) {
        setState(() {
          _starting = false;
        });
      }
    } catch (_) {
      if (!_currentCapture(token, revision)) return;
      setState(() {
        _starting = false;
        _voiceMode = false;
        _notice = 'Das Mikrofon konnte nicht starten. Tippen geht weiterhin.';
      });
    }
  }

  Future<void> _finishCapture(
      String words, double? confidence, int token, int revision) async {
    if (!_currentCapture(token, revision)) return;
    final ended = ++_capture, turn = _turn;
    await _speech.cancel();
    if (!mounted ||
        !_foreground ||
        ended != _capture ||
        turn != _turn ||
        revision != _context.revision) {
      return;
    }
    _starting = false;
    _noMatchCount = 0;
    await _ask(words, confidence: confidence);
  }

  Future<void> _noMatch(int token, int revision) async {
    if (!_currentCapture(token, revision)) return;
    final ended = ++_capture, turn = _turn;
    await _speech.cancel();
    if (!mounted ||
        !_foreground ||
        ended != _capture ||
        turn != _turn ||
        revision != _context.revision) {
      return;
    }
    setState(() {
      _starting = false;
      _notice = 'Ich habe noch keinen vollständigen Satz verstanden. '
          'Nimm dir Zeit oder tippe deine Frage.';
    });
    _conversation.waitForChild();
    // At most two real recognizer restarts for a thinking pause. No artificial
    // thinking delay, auto-answer, partial promotion or unbounded retry loop.
    if (_voiceMode && ++_noMatchCount <= 2) {
      await _startVoice();
    } else if (mounted) {
      setState(() {
        _voiceMode = false;
      });
    }
  }

  Future<void> _interrupt({bool listen = false}) async {
    final token = ++_capture, turn = ++_turn, revision = _context.revision;
    _conversation.interrupt();
    _voiceMode = false;
    _starting = false;
    await _speech.cancel();
    await LumoVoice.instance.stop();
    if (!mounted ||
        !_foreground ||
        token != _capture ||
        turn != _turn ||
        revision != _context.revision) {
      return;
    }
    setState(() {
      _busy = false;
      _notice = 'Gestoppt.';
    });
    if (listen) await _startVoice(tapped: true);
  }

  Future<void> _ask(String raw, {double? confidence}) async {
    final question = raw.trim();
    if (question.isEmpty || !mounted || !_foreground) return;
    if (_draft != null &&
        const ['ja', 'ja genau', 'richtig', 'stimmt']
            .contains(question.toLowerCase()) &&
        (confidence == null || confidence >= .65)) {
      await _confirm();
      return;
    }
    final turn = ++_turn, revision = _context.revision;
    _capture++;
    await _speech.cancel();
    if (!mounted ||
        !_foreground ||
        turn != _turn ||
        revision != _context.revision) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _starting = false;
      _notice = null;
      _draft = null;
    });
    final response =
        await _conversation.ask(question, recognitionConfidence: confidence);
    if (!mounted ||
        !_foreground ||
        turn != _turn ||
        revision != _context.revision) {
      return;
    }
    if (response.source == 'cancelled') {
      setState(() {
        _busy = false;
      });
      return;
    }
    final dialogue = _conversation.lastDialogue;
    if (dialogue != null &&
        !dialogue.needsConfirmation &&
        const {
          LumoTaskDialogueIntent.help,
          LumoTaskDialogueIntent.why,
          LumoTaskDialogueIntent.alternative,
          LumoTaskDialogueIntent.show,
          LumoTaskDialogueIntent.step,
          LumoTaskDialogueIntent.reference,
          LumoTaskDialogueIntent.repeat,
          LumoTaskDialogueIntent.slower,
        }.contains(dialogue.intent)) {
      widget.onReviewedHelp?.call(dialogue);
    }
    if (!mounted ||
        !_foreground ||
        turn != _turn ||
        revision != _context.revision) {
      return;
    }
    final stop = dialogue?.shouldStopSpeech == true ||
        response.source == 'local_stop' ||
        response.source == 'local_alone';
    final alone = dialogue?.intent == LumoTaskDialogueIntent.alone ||
        response.source == 'local_alone';
    _input.clear();
    setState(() {
      _answer = response.reply;
      _source = response.source;
      _draft =
          dialogue?.needsConfirmation == true && dialogue?.draftAnswer != null
              ? dialogue
              : null;
      _heard = '';
      _busy = false;
      if (alone || response.blocked) _voiceMode = false;
    });
    final utteranceId = _conversation.utterance?.id;
    if (!stop) {
      await _conversation.speak(response.reply,
          expectedUtteranceId: utteranceId,
          style: response.blocked ? VoiceStyle.comfort : VoiceStyle.explain);
    }
    if (!mounted ||
        !_foreground ||
        turn != _turn ||
        revision != _context.revision) {
      return;
    }
    if (_voiceMode) await _startVoice();
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    final draft = _draft, callback = widget.onConfirmedAnswer;
    if (draft == null ||
        callback == null ||
        _context.task?.dialogue?.containsReply(draft) != true) {
      if (mounted) {
        setState(() {
          _draft = null;
          _notice = 'Wähle deine Antwort direkt in der Aufgabe.';
        });
      }
      return;
    }
    _confirming = true;
    _draft = null;
    await _interrupt();
    if (!mounted || _context.task?.dialogue?.containsReply(draft) != true) {
      _confirming = false;
      return;
    }
    setState(() {
      _draft = null;
      _busy = true;
    });
    final turn = _turn, revision = _context.revision;
    try {
      final accepted = await callback(draft);
      if (!mounted ||
          !_foreground ||
          turn != _turn ||
          revision != _context.revision) return;
      setState(() {
        _busy = false;
        _notice = accepted
            ? 'Deine bestätigte Antwort wurde an die Aufgabe übergeben.'
            : 'Die Aufgabe hat sich geändert. Bitte antworte dort noch einmal.';
      });
    } catch (_) {
      if (mounted &&
          _foreground &&
          turn == _turn &&
          revision == _context.revision) {
        setState(() {
          _busy = false;
          _notice = 'Die Übergabe konnte nicht bestätigt werden. '
              'Schau bitte auf den Stand deiner Aufgabe.';
        });
      }
    } finally {
      _confirming = false;
    }
  }

  Future<void> _clearHistory() async {
    await _interrupt();
    _conversation.clearMemory();
    _input.clear();
    if (mounted) {
      setState(() {
        _draft = null;
        _heard = '';
        _showHistory = false;
        _answer =
            'Das Gespräch ist gelöscht. Deine Lernfortschritte bleiben erhalten.';
        _source = 'local_ready';
      });
    }
  }

  String get _phaseLabel {
    if (_speech.listening) return 'Hört zu · Mikrofon an';
    if (_starting) return 'Mikrofon wird geöffnet';
    if (_speech.awaitingFinalResult) return 'Erkennung wird abgeschlossen';
    return switch (_conversation.phase) {
      LumoConversationPhase.idle => 'Bereit · Mikrofon aus',
      LumoConversationPhase.listening => 'Hört zu · Mikrofon an',
      LumoConversationPhase.thinking => 'Verarbeitet · Mikrofon aus',
      LumoConversationPhase.speaking => 'Spricht · Mikrofon aus',
      LumoConversationPhase.waiting => 'Wartet auf dich · Mikrofon aus',
      LumoConversationPhase.interrupted => 'Unterbrochen · Mikrofon aus',
      LumoConversationPhase.paused => 'Pausiert · Mikrofon aus',
      LumoConversationPhase.error =>
        'Sprachausgabe nicht bereit · Mikrofon aus',
    };
  }

  Widget _button(String label, IconData icon, VoidCallback? onPressed,
          {String? key}) =>
      OutlinedButton.icon(
          key: key == null ? null : ValueKey(key),
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: LumoVisualTokens.white));

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.state.settings;
    final snapshot = _context.task?.dialogue;
    final targets = _conversation.utterance?.objectIds ?? const <String>[];
    final contents = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.compact) ...[
            LumoGlassCard(
              key: const ValueKey('lumo-agent-hologlass-hero'),
              child: Row(children: [
                LumoCharacter(
                    pose: LumoDesignFoxPose.teacherStick,
                    size: 84,
                    idleHops: false,
                    intro: false,
                    reduceMotion:
                        settings.reduceAnimations || settings.calmMode),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        settings.aiProxyEnabled
                            ? 'Mit Lumo sprechen'
                            : 'Lumo hilft lokal',
                        key: const ValueKey('lumo-agent-title'),
                        style: const TextStyle(
                            color: LumoVisualTokens.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900))),
                IconButton(
                    key: const ValueKey('lumo-agent-parents'),
                    tooltip: 'Elternbereich',
                    onPressed: () => widget.onSection(LumoSection.settings),
                    icon: const Icon(Icons.lock_rounded,
                        color: LumoVisualTokens.white)),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Semantics(
              liveRegion: true,
              child: Text(_phaseLabel,
                  key: const ValueKey('lumo-conversation-state'),
                  style: TextStyle(
                      color: _speech.listening
                          ? LumoVisualTokens.gold
                          : LumoVisualTokens.cyanBright,
                      fontWeight: FontWeight.w900))),
          const SizedBox(height: 8),
          if (!settings.microphoneEnabled)
            const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                    'Mikrofon ist im Elternbereich ausgeschaltet. '
                    'Du kannst deine Frage tippen.',
                    style: TextStyle(color: LumoVisualTokens.gold))),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _button(
                _voiceMode ? 'Zuhören neu starten' : 'Gespräch starten',
                Icons.mic_rounded,
                settings.microphoneEnabled
                    ? () => _interrupt(listen: true)
                    : null,
                key: 'lumo-conversation-start'),
            _button('Unterbrechen & zuhören', Icons.front_hand_rounded,
                () => _interrupt(listen: true),
                key: 'lumo-conversation-interrupt'),
            _button('Stopp', Icons.stop_circle_outlined, () => _interrupt(),
                key: 'lumo-conversation-stop'),
          ]),
          const SizedBox(height: 10),
          Text(_busy ? 'Ich verarbeite deine Frage …' : _answer,
              key: const ValueKey('lumo-conversation-subtitle'),
              style: const TextStyle(
                  color: LumoVisualTokens.white, fontSize: 17, height: 1.4)),
          if (targets.isNotEmpty && snapshot != null) ...[
            const SizedBox(height: 8),
            Text(
                'Dazu gehören: ${snapshot.objects.where((object) => targets.contains(object.id)).map((object) => object.label).join(' · ')}',
                key: const ValueKey('lumo-dialogue-object-focus'),
                style: const TextStyle(
                    color: LumoVisualTokens.gold, fontWeight: FontWeight.w800)),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 10),
            Text('Als Antwort verstanden: ${_draft!.draftAnswer!}',
                key: const ValueKey('lumo-answer-draft'),
                style: const TextStyle(
                    color: LumoVisualTokens.gold, fontSize: 18)),
            Wrap(spacing: 8, children: [
              _button('Ja, diese Antwort', Icons.check_circle_outline,
                  widget.onConfirmedAnswer == null ? null : _confirm,
                  key: 'lumo-answer-confirm'),
              _button('Korrigieren', Icons.edit_outlined, () {
                setState(() {
                  _draft = null;
                  _notice = 'Sag oder tippe, was du gemeint hast.';
                });
                if (_voiceMode) unawaited(_startVoice());
              }),
            ]),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _button('Noch einmal', Icons.replay_rounded,
                _busy ? null : () => _ask('Noch einmal')),
            _button('Langsamer', Icons.slow_motion_video,
                _busy ? null : () => _ask('Langsamer')),
            _button('Anders erklären', Icons.lightbulb_outline,
                _busy ? null : () => _ask('Anders erklären')),
            _button('Allein versuchen', Icons.pan_tool_outlined,
                () => _ask('Ich möchte es allein versuchen')),
          ]),
          const SizedBox(height: 12),
          TextField(
              key: const ValueKey('lumo-agent-question-field'),
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              style: const TextStyle(color: LumoVisualTokens.white),
              onSubmitted: (value) => _ask(value),
              decoration: const InputDecoration(
                  labelText: 'Frag Lumo oder tippe deine Antwort',
                  hintText: 'Warum zuerst zwei?',
                  filled: true,
                  fillColor: LumoVisualTokens.navigation,
                  border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                  key: const ValueKey('lumo-agent-send'),
                  onPressed: () => _ask(_input.text),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Senden'),
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(48, 48)))),
          if (_heard.isNotEmpty)
            Text('Erkannt: $_heard',
                style: const TextStyle(color: LumoVisualTokens.muted)),
          if (_notice != null || _speech.error != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_notice ?? _speech.error!,
                    style: const TextStyle(color: LumoVisualTokens.gold))),
          ValueListenableBuilder<String?>(
              valueListenable: LumoVoice.instance.lastError,
              builder: (_, error, __) => error == null
                  ? const SizedBox.shrink()
                  : Text(error,
                      style: const TextStyle(color: LumoVisualTokens.gold))),
          const SizedBox(height: 8),
          Text(
              _source == 'openai_proxy'
                  ? 'Antwort des freigegebenen Online-Dienstes.'
                  : snapshot != null
                      ? 'Geprüfte Aufgabenhilfe auf diesem Gerät.'
                      : 'Lokale Hilfe mit Regeln. Freie KI benötigt den freigegebenen Online-Dienst.',
              style:
                  const TextStyle(color: LumoVisualTokens.muted, fontSize: 12)),
          const Text(
              'Während Lumo spricht, ist das Mikrofon aus. '
              'Zum Dazwischenreden tippe auf „Unterbrechen & zuhören“.',
              style: TextStyle(color: LumoVisualTokens.muted, fontSize: 12)),
          Wrap(spacing: 8, children: [
            _button('Gespräch ansehen', Icons.history_rounded, () {
              setState(() {
                _showHistory = !_showHistory;
              });
            }),
            _button('Gespräch löschen', Icons.delete_outline, _clearHistory),
          ]),
          if (_showHistory) ...[
            const Text(
                'Nur die letzten vier Wechsel dieser Sitzung. '
                'Keine dauerhafte Gesprächsspeicherung.',
                style: TextStyle(color: LumoVisualTokens.muted, fontSize: 12)),
            for (final turn in _conversation.history)
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      (turn.role == 'user' ? 'Du: ' : 'Lumo: ') + turn.content,
                      style: const TextStyle(color: LumoVisualTokens.white))),
          ],
        ]);
    if (widget.compact) {
      return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: LumoVisualTokens.navigation,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: LumoVisualTokens.cyanBright.withValues(alpha: .45))),
          child: contents);
    }
    return LumoSceneBackground(
        scene: LumoScene.learning,
        dimmed: true,
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: contents))));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _capture++;
    _turn++;
    _voiceMode = false;
    _context.removeListener(_contextChanged);
    _conversation.removeListener(_changed);
    _speech.removeListener(_changed);
    _conversation.dispose();
    _context.dispose();
    _speech.dispose();
    _input.dispose();
    super.dispose();
  }
}
