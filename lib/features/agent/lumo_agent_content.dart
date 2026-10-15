import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_voice.dart';
import '../../core/lumo_context_engine.dart';
import '../../core/lumo_conversation_controller.dart';

class LumoAgentContent extends StatefulWidget {
  const LumoAgentContent(
      {super.key, required this.appState, required this.onSection});

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  State<LumoAgentContent> createState() => _LumoAgentContentState();
}

class _LumoAgentContentState extends State<LumoAgentContent>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final LumoAiProxyClient _proxy = const LumoAiProxyClient();
  late final LumoContextEngine _contextEngine;
  late final LumoConversationController _conversation;
  final LumoSpeechListener _speech = LumoSpeechListener();

  bool _loading = false;
  bool _speechReady = false;
  bool _speechListening = false;
  bool _speechInitStarted = false;
  String _answer =
      'Ich bin Lumo. Frag mich etwas zu Mathe, Deutsch, Lesen, Englisch, Sachunterricht, Natur oder einer Geschichte.';
  String _source = 'local_ready';
  String _liveSpeech = '';
  String? _speechLocale;
  String? _speechError;
  bool _blocked = false;
  bool _verifiedCloudReply = false;
  bool _foreground = true;
  int _questionGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contextEngine = LumoContextEngine(widget.appState);
    _conversation = LumoConversationController(_contextEngine);
    _contextEngine.addListener(_situationChanged);
    _speech.addListener(_speechChanged);
    // Render-Warmup: Wenn KI freigegeben ist, Server bereits beim
    // Öffnen anstoßen. Dann ist der erste Chat warm und Heinz
    // sieht keinen 30s-Cold-Start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _proxy.warmup(widget.appState.state.settings);
      // Microphone permissions are requested only after the child taps it.
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionGeneration++;
    _contextEngine.removeListener(_situationChanged);
    _conversation.dispose();
    _contextEngine.dispose();
    _speech.removeListener(_speechChanged);
    _speech.dispose();
    unawaited(LumoVoice.instance.stop());
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _questionGeneration++;
      _conversation.pause();
      unawaited(_speech.cancel());
      unawaited(LumoVoice.instance.stop());
      if (mounted)
        setState(() {
          _speechListening = false;
          _loading = false;
        });
    } else {
      _conversation.resume();
    }
  }

  void _situationChanged() {
    _questionGeneration++;
    unawaited(_speech.cancel());
    _controller.clear();
    if (mounted) {
      setState(() {
        _loading = false;
        _speechListening = false;
        _answer = 'Die Situation hat sich geändert. Frag mich zur aktuellen Aufgabe.';
        _verifiedCloudReply = false;
      });
    }
  }

  Future<void> _ensureSpeechReady() async {
    if (_speechReady || _speechInitStarted) return;
    _speechInitStarted = true;
    try {
      final available = await _speech.initialize();

      if (!available) {
        if (!mounted) return;
        setState(() {
          _speechReady = false;
          _speechError = _speech.error ??
              'Die lokale Spracherkennung ist nicht verfügbar. Du kannst Lumo tippen.';
        });
        return;
      }

      final bestLocale = _speech.bestLocaleId;
      if (!mounted) return;
      setState(() {
        _speechReady = true;
        _speechLocale = bestLocale;
        _speechError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechReady = false;
        _speechError = 'Mikrofon konnte nicht gestartet werden: $e';
      });
    } finally {
      _speechInitStarted = false;
    }
  }

  void _speechChanged() {
    if (!mounted || !_foreground) return;
    _conversation.listening(_speech.listening);
    setState(() {
      _speechListening = _speech.listening;
      _speechError = _speech.error;
    });
  }

  Future<void> _startVoiceQuestion() async {
    if (_loading || _speechListening) return;
    await widget.appState.ensureSettingsLoaded();
    if (!mounted || !_foreground) return;
    final settings = widget.appState.state.settings;
    if (!settings.microphoneEnabled) {
      setState(
          () => _speechError = 'Mikrofon ist im Elternbereich ausgeschaltet.');
      return;
    }

    await LumoVoice.instance.stop();
    await _ensureSpeechReady();
    if (!mounted || !_speechReady) return;

    setState(() {
      _liveSpeech = '';
      _speechError = null;
      _speechListening = true;
    });

    try {
      await _speech.startListening(
        onResult: (recognized) {
          if (!mounted || !_foreground) return;
          final words = recognized.trim();
          setState(() {
            _liveSpeech = words;
            if (words.isNotEmpty) _controller.text = words;
          });
        },
        onFinalResult: (words) {
          if (mounted && _foreground) unawaited(_finishVoiceQuestion(words));
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechListening = false;
        _speechError = 'Sprachaufnahme konnte nicht starten: $e';
      });
    }
  }

  Future<void> _finishVoiceQuestion(String words) async {
    try {
      await _speech.stopListening();
    } catch (_) {}
    if (!mounted || !_foreground) return;
    setState(() => _speechListening = false);
    await _ask(words);
  }

  Future<void> _stopVoiceQuestion() async {
    try {
      await _speech.stopListening();
    } catch (_) {}
    if (!mounted) return;
    final words = _liveSpeech.trim().isNotEmpty
        ? _liveSpeech.trim()
        : _controller.text.trim();
    setState(() => _speechListening = false);
    if (words.isNotEmpty && !_loading) {
      await _ask(words);
    }
  }

  Future<void> _ask([String? raw]) async {
    final question = (raw ?? _controller.text).trim();
    if (question.isEmpty || _loading || !_foreground) return;
    final generation = ++_questionGeneration;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _loading = true;
      _blocked = false;
      _answer = 'Ich denke kurz nach ...';
    });

    final response = await _conversation.ask(question);
    if (!mounted || !_foreground || generation != _questionGeneration) return;
    if (response.source == 'cancelled') {
      setState(() => _loading = false);
      return;
    }
    _controller.clear();
    setState(() {
      _answer = response.reply;
      _source = response.source;
      _verifiedCloudReply = response.isCloudAnswer;
      _blocked = response.blocked;
      _loading = false;
      _liveSpeech = '';
    });
    _applyReply(response.reply, blocked: response.blocked);
  }

  void _applyReply(String reply, {required bool blocked}) {
    widget.appState.update(widget.appState.state.copyWith(
      lumoMessage: reply,
      mood: blocked ? LumoMood.comfort : LumoMood.greet,
    ));
    if (widget.appState.state.settings.voiceEnabled) {
      unawaited(_conversation.speak(reply,
          style: blocked ? VoiceStyle.comfort : VoiceStyle.explain));
    }
  }

  void _quickAsk(String text) => _ask(text);

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.state.settings;
    final proxyReady = settings.aiProxyEnabled && _verifiedCloudReply;
    return LumoSceneBackground(
      scene: LumoScene.learning,
      dimmed: true,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AgentHeader(
                proxyReady: proxyReady,
                enabled: settings.aiProxyEnabled,
                reduceMotion: settings.reduceAnimations || settings.calmMode,
                onSettings: () => widget.onSection(LumoSection.settings)),
            const SizedBox(height: 16),
            _SafetyFrame(proxyReady: proxyReady),
            const SizedBox(height: 16),
            _AnswerBubble(
              answer: _answer,
              loading: _loading,
              blocked: _blocked,
              source: _source,
              onSpeak: () => LumoVoice.instance.speak(_answer,
                  style: _blocked ? VoiceStyle.comfort : VoiceStyle.explain),
              onStop: LumoVoice.instance.stop,
            ),
            const SizedBox(height: 16),
            _QuestionInput(
              controller: _controller,
              loading: _loading,
              microphoneEnabled: settings.microphoneEnabled,
              speechReady: _speechReady,
              listening: _speechListening,
              liveSpeech: _liveSpeech,
              speechLocale: _speechLocale,
              speechError: _speechError,
              onAsk: _ask,
              onMic: _startVoiceQuestion,
              onStopMic: _stopVoiceQuestion,
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _QuickChip(
                  label: '🧮 Mathehilfe',
                  onTap: () => _quickAsk(
                      'Erklär mir 7 plus 5 in kleinen Schritten, bitte mit Beispiel.')),
              _QuickChip(
                  label: '📖 Deutschhilfe',
                  onTap: () => _quickAsk(
                      'Hilf mir bei einem deutschen Satz und erklär ihn kurz.')),
              _QuickChip(
                  label: '🦊 Lies mit mir',
                  onTap: () => _quickAsk(
                      'Erzähl mir eine kurze Geschichte zum Lesen, mit drei Sätzen.')),
              _QuickChip(
                  label: '🐝 Tiere',
                  onTap: () => _quickAsk(
                      'Erzähl mir etwas Kurzes über ein interessantes Tier, kindgerecht.')),
              _QuickChip(
                  label: '🌍 Sachunterricht',
                  onTap: () => _quickAsk(
                      'Erzähl mir eine spannende Sache aus dem Sachunterricht.')),
              _QuickChip(
                  label: '🎈 Englisch',
                  onTap: () => _quickAsk(
                      'Übe mit mir drei einfache englische Wörter und übersetze sie.')),
              _QuickChip(
                  label: '😊 Witz erzählen',
                  onTap: () =>
                      _quickAsk('Erzähl mir bitte einen kindgerechten Witz.')),
              _QuickChip(
                  label: '💡 Lerntipp',
                  onTap: () =>
                      _quickAsk('Gib mir einen kleinen Lerntipp für heute.')),
            ]),
          ]),
        ),
      ),
    ));
  }
}

class _AgentHeader extends StatelessWidget {
  const _AgentHeader(
      {required this.proxyReady,
      required this.enabled,
      required this.reduceMotion,
      required this.onSettings});

  final bool proxyReady;
  final bool enabled;
  final bool reduceMotion;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final title = proxyReady
        ? 'Lumo-KI mit ChatGPT'
        : enabled
            ? 'Lumo-KI ist eingeschaltet'
            : 'Lumo hilft lokal';
    final subtitle = proxyReady
        ? 'Die letzte Antwort kam erfolgreich von der Online-KI.'
        : enabled
            ? 'Die Online-Verbindung wird bei deiner Frage geprüft. Lokale Lernhilfen stehen dir auch ohne Verbindung zur Verfügung.'
            : 'Es wird keine Cloud verwendet. Lumo nutzt nur die lokale Lernhilfe.';
    return LumoGlassCard(
      key: const ValueKey('lumo-agent-hologlass-hero'),
      child: LayoutBuilder(builder: (context, bounds) {
        final compact = bounds.maxWidth < 460;
        final fox = LumoCharacter(
          pose: LumoDesignFoxPose.teacherStick,
          size: compact ? 100 : 130,
          idleHops: false,
          intro: false,
          reduceMotion: reduceMotion || MediaQuery.disableAnimationsOf(context),
        );
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('DEIN LERNBEGLEITER', style: TextStyle(
                color: LumoVisualTokens.cyanBright, fontWeight: FontWeight.w900,
                letterSpacing: 1.1, fontSize: 11)),
            const SizedBox(height: 6),
            Text(title, key: const ValueKey('lumo-agent-title'),
                style: const TextStyle(color: LumoVisualTokens.white,
                    fontSize: 22, fontWeight: FontWeight.w900, height: 1.13)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(
                color: LumoVisualTokens.muted, height: 1.38, fontSize: 14)),
          ],
        );
        final parents = OutlinedButton.icon(
          key: const ValueKey('lumo-agent-parents'),
          onPressed: onSettings,
          icon: const Icon(Icons.lock_rounded, size: 18),
          label: const Text('Eltern'),
          style: OutlinedButton.styleFrom(
              foregroundColor: LumoVisualTokens.white,
              side: const BorderSide(color: LumoVisualTokens.cyanBright),
              minimumSize: const Size(90, 48)),
        );
        if (compact) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  SizedBox(width: 100, height: 120, child: fox),
                  const SizedBox(width: 8),
                  Expanded(child: intro),
                ]),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: parents),
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 138, height: 154, child: fox),
          const SizedBox(width: 14),
          Expanded(child: intro),
          const SizedBox(width: 12),
          parents,
        ]);
      }),
    );
  }
}

class _SafetyFrame extends StatelessWidget {
  const _SafetyFrame({required this.proxyReady});

  final bool proxyReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: lumoCard(color: LumoVisualTokens.navigation),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(proxyReady ? Icons.verified_user_rounded : Icons.shield_rounded,
            color: LumoVisualTokens.cyanBright),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Sicherheitsrahmen: Lumo spricht nur über kindgerechte Themen wie Schule, Freunde, Cartoons, Lesen, Mathe, Deutsch, Englisch, Sachunterricht und Natur. Verbotene Themen werden freundlich umgelenkt.',
            style: LumoTextStyles.body.copyWith(
                color: LumoVisualTokens.white, fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({
    required this.answer,
    required this.loading,
    required this.blocked,
    required this.source,
    required this.onSpeak,
    required this.onStop,
  });

  final String answer;
  final bool loading;
  final bool blocked;
  final String source;
  final VoidCallback onSpeak;
  final VoidCallback onStop;

  String get _friendlySource {
    switch (source) {
      case 'proxy':
      case 'openai_proxy':
        return 'ChatGPT über Lumo-Proxy';
      case 'local_ready':
        return 'Lumo (bereit)';
      case 'local_companion':
        return 'Lumo (lokal)';
      case 'proxy_timeout':
        return 'Lumo (Server schlief)';
      case 'proxy_error':
        return 'Lumo (Server-Fehler)';
      case 'local_policy':
        return 'Lumo (Schutzfilter)';
      default:
        // Niemals interne Codes anzeigen - immer kindgerechter Fallback.
        return 'Lumo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAnswer = answer.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(
        gradient: LinearGradient(
          colors: blocked
              ? [LumoVisualTokens.navigation, LumoVisualTokens.glass]
              : [LumoVisualTokens.glass, LumoVisualTokens.navigation],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(blocked ? Icons.front_hand_rounded : Icons.chat_bubble_rounded,
              color: blocked ? LumoVisualTokens.gold : LumoVisualTokens.cyanBright),
          const SizedBox(width: 8),
          Expanded(
              child: Text(loading ? 'Lumo denkt nach …' : 'Lumo antwortet',
                  style: LumoTextStyles.heading3.copyWith(color: LumoVisualTokens.white))),
          if (loading)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: LumoVisualTokens.cyanBright)),
        ]),
        const SizedBox(height: 10),
        if (showAnswer) ...[
          Text(answer,
              style: LumoTextStyles.body.copyWith(
                  color: LumoVisualTokens.white,
                  fontWeight: FontWeight.w800,
                  height: 1.35)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_friendlySource,
                  style: LumoTextStyles.caption
                      .copyWith(color: LumoVisualTokens.muted)),
              OutlinedButton.icon(
                onPressed: loading ? null : onSpeak,
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                label: const Text('Vorlesen'),
              ),
              OutlinedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop_circle_rounded, size: 18),
                label: const Text('Stopp'),
              ),
            ],
          ),
        ] else
          Text(
            loading
                ? 'Ich überlege gerade. Das dauert nicht lange.'
                : 'Stell mir gerne eine Frage. Wir bleiben bei Schul-, Lern- und Kinderthemen.',
            style: LumoTextStyles.body.copyWith(
                color: LumoVisualTokens.muted,
                fontWeight: FontWeight.w700,
                height: 1.35),
          ),
      ]),
    );
  }
}

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({
    required this.controller,
    required this.loading,
    required this.microphoneEnabled,
    required this.speechReady,
    required this.listening,
    required this.liveSpeech,
    required this.speechLocale,
    required this.speechError,
    required this.onAsk,
    required this.onMic,
    required this.onStopMic,
  });

  final TextEditingController controller;
  final bool loading;
  final bool microphoneEnabled;
  final bool speechReady;
  final bool listening;
  final String liveSpeech;
  final String? speechLocale;
  final String? speechError;
  final ValueChanged<String?> onAsk;
  final VoidCallback onMic;
  final VoidCallback onStopMic;

  @override
  Widget build(BuildContext context) {
    final micLabel = listening ? 'Zuhören …' : 'Sprechen';
    final micIcon = listening ? Icons.graphic_eq_rounded : Icons.mic_rounded;
    final statusText = listening
        ? (liveSpeech.trim().isEmpty
            ? 'Sprich jetzt. Lumo sendet die Frage automatisch.'
            : 'Erkannt: $liveSpeech')
        : microphoneEnabled
            ? 'Spracherkennung: ${speechReady ? (speechLocale ?? 'Deutsch') : 'nach Tippen auf Sprechen'}'
            : 'Mikrofon ist im Elternbereich ausgeschaltet.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: lumoCard(color: LumoVisualTokens.glass),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, bounds) {
          final small = bounds.maxWidth < 360;
          final field = TextField(
            key: const ValueKey('lumo-agent-question-field'),
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            style: const TextStyle(color: LumoVisualTokens.white),
            onSubmitted: loading ? null : (value) => onAsk(value),
            decoration: const InputDecoration(
              labelText: 'Frag Lumo',
              hintText: 'Zum Beispiel: Erklär mir 12 minus 5.',
              labelStyle: TextStyle(color: LumoVisualTokens.cyanBright),
              hintStyle: TextStyle(color: LumoVisualTokens.muted),
              filled: true,
              fillColor: LumoVisualTokens.navigation,
              border: OutlineInputBorder(),
            ),
          );
          final send = FilledButton.icon(
            key: const ValueKey('lumo-agent-send'),
            onPressed: loading ? null : () => onAsk(controller.text),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Senden'),
            style: FilledButton.styleFrom(
              backgroundColor: LumoVisualTokens.cyanBright,
              foregroundColor: LumoVisualTokens.navigation,
              minimumSize: const Size(116, 48)),
          );
          return small
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [field, const SizedBox(height: 10), send])
              : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: field), const SizedBox(width: 10), send,
                ]);
        }),
        const SizedBox(height: 10),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: loading || !microphoneEnabled
                    ? null
                    : (listening ? onStopMic : onMic),
                icon: Icon(micIcon),
                label: Text(micLabel),
              ),
              Text(statusText,
                  style: LumoTextStyles.caption.copyWith(
                      color: listening ? LumoVisualTokens.gold : LumoVisualTokens.muted,
                      fontWeight: FontWeight.w800)),
            ]),
        if (speechError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: LumoVisualTokens.navigation,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LumoVisualTokens.gold, width: 1.0),
            ),
            child: Row(
              children: [
                const Text('🎤', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    speechError!,
                    style: LumoTextStyles.caption.copyWith(
                      color: LumoVisualTokens.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: LumoVisualTokens.white)),
      avatar: const Icon(Icons.auto_awesome_rounded, size: 18,
          color: LumoVisualTokens.cyanBright),
      backgroundColor: LumoVisualTokens.glassRow,
      side: const BorderSide(color: LumoVisualTokens.cyan),
      onPressed: onTap,
    );
  }
}
