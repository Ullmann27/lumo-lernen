// ════════════════════════════════════════════════════════════════════════
// LUMO TEACHER SCREEN — ChatGPT-Lehrer-Modus
// ════════════════════════════════════════════════════════════════════════
// Lumo erklärt ein Thema. Kind kann Fragen stellen. ChatGPT antwortet
// als kindgerechter Volksschul-Lehrer.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/lumo_voice.dart';
import '../../core/lumo_image_generator.dart';
import 'lumo_akademie_screen.dart';
import 'topic_curriculum.dart';

class LumoTeacherScreen extends StatefulWidget {
  const LumoTeacherScreen({
    super.key,
    required this.appState,
    required this.topic,
    required this.subject,
    required this.grade,
  });

  final LumoAppState appState;
  final LearningTopic topic;
  final LearningSubject subject;
  final int grade;

  @override
  State<LumoTeacherScreen> createState() => _LumoTeacherScreenState();
}

class _LumoTeacherScreenState extends State<LumoTeacherScreen>
    with TickerProviderStateMixin {
  final LumoAiProxyClient _ai = const LumoAiProxyClient();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<LumoAiChatTurn> _history = [];

  bool _loading = false;
  late final AnimationController _lumoPulseCtrl;

  // ── Themen-spezifische Schnellfragen ──
  List<String> get _quickQuestions {
    final ctx = TopicCurriculum.of(widget.topic.id);
    // Heinz-Wunsch: Topic-spezifische Quick-Fragen!
    // Frueher waren generische Fragen wie 'Erklaere das Wesen von Mathe'
    // angezeigt - das passte nicht zum konkreten Topic.
    if (ctx != null && ctx.quickQuestions.isNotEmpty) {
      return ctx.quickQuestions;
    }
    // Fallback: zumindest topic-titled, nicht generisch
    return [
      'Erklaere mir ${widget.topic.title} mit einem Beispiel',
      'Mach mir eine ${widget.topic.title}-Aufgabe',
      'Zeig mir ein Bild zu ${widget.topic.title}',
    ];
  }

  @override
  void initState() {
    super.initState();
    _lumoPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    // Lumo begrüßt automatisch
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _lumoPulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _greet() async {
    final greeting = _buildGreeting();
    setState(() {
      _messages.add(_ChatMessage(text: greeting, isLumo: true));
    });
    // Voice ist optional - silent fail
    try {
      LumoVoice.instance.speak(greeting);
    } catch (_) {}
  }

  String _buildGreeting() {
    final ctx = TopicCurriculum.of(widget.topic.id);
    if (ctx != null) {
      // Topic-spezifische Begruessung mit konkretem Beispiel
      final firstQuestion = ctx.quickQuestions.isNotEmpty
          ? ctx.quickQuestions.first
          : 'was du wissen willst';
      return 'Hallo! Ich bin Lumo und heute lernen wir "${ctx.title}" '
          'fuer die ${ctx.grade}. Klasse. '
          'Frag mich zum Beispiel: "$firstQuestion". '
          'Wenn du ein Bild sehen willst, sag mir einfach "Zeig mir ..."!';
    }
    return 'Hallo! Ich bin Lumo und heute lernen wir "${widget.topic.title}" '
        'aus ${widget.subject.name}. '
        'Sag mir was du wissen willst - und wenn du ein Bild sehen magst, '
        'sag einfach "Zeig mir ein/eine ..."!';
  }

  Future<void> _ask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    HapticFeedback.lightImpact();
    setState(() {
      // UI zeigt nur die Original-Frage, nicht den eingebetteten Kontext
      _messages.add(_ChatMessage(text: trimmed, isLumo: false));
      _loading = true;
      _controller.clear();
    });
    _scrollToBottom();

    // ── KONTEXT-INJECTION (Loesung fuer "ChatGPT redet vom falschen Thema") ──
    // Heinz' Feedback: ChatGPT bekommt Bruchrechnen-Topic aber antwortet
    // mit "3 Aepfel + 2 Aepfel" (1. Klasse Aufgabe). Grund: Render-Backend
    // ignoriert extras-Parameter mit der Persona.
    // Loesung: Wir embedden den kompletten Lehrplan-Kontext direkt in die
    // Message - so kommt er garantiert beim Modell an.
    final ctx = TopicCurriculum.of(widget.topic.id);
    final messageForAi = ctx != null
        ? '${ctx.buildPromptHeader()}KINDFRAGE: $trimmed'
        : '[Thema: ${widget.topic.title} aus ${widget.subject.name} Klasse ${widget.grade}]\n$trimmed';

    _history.add(LumoAiChatTurn(role: 'user', content: messageForAi));

    try {
      final response = await _ai.ask(
        settings: widget.appState.state.settings,
        state: widget.appState.state,
        message: messageForAi,
        history: _history,
        context: LumoAiContext.companion,
        extras: {
          'mode': 'teacher',
          'grade': widget.grade,
          'subject': widget.subject.name,
          'topic': widget.topic.title,
          'topic_id': widget.topic.id,
        },
      );

      final reply = response.reply.trim().isEmpty
          ? 'Hmm, lass uns das nochmal probieren. Frag mich konkreter!'
          : response.reply;

      setState(() {
        _messages.add(_ChatMessage(text: reply, isLumo: true));
        _loading = false;
      });
      _history.add(LumoAiChatTurn(role: 'assistant', content: reply));
      _scrollToBottom();

      try {
        LumoVoice.instance.speak(reply);
      } catch (_) {}

      // Heinz' Bildgenerator (strikt kindersicher):
      // Wenn Kind nach einem Bild gefragt hat ('zeig mir', 'wie schaut'),
      // automatisch ein Bild ueber Pollinations.ai generieren.
      // Inhalts-Sicherheit ueber LumoImageGenerator.checkSafety()
      // (60+ Block-Woerter, Comic-Style-Wrapper, no realistic).
      if (LumoImageGenerator.seemsImageRequest(trimmed)) {
        _generateImage(trimmed);
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
            text:
                'Ups, ich konnte gerade nicht antworten. Probier es nochmal!',
            isLumo: true,
            isError: true));
        _loading = false;
      });
    }
  }

  /// Bildgenerator-Helfer (Heinz-Auftrag).
  /// Positive Allowlist: nur Tiere, Pflanzen, Essen, Spielzeug, etc.
  /// werden gemalt. Kein Negativ-Wortschatz im Code.
  void _generateImage(String childPrompt) {
    final url = LumoImageGenerator.instance.buildSafeImageUrl(childPrompt);
    if (url == null) {
      // Nicht in Allowlist -> positiver Hinweis (kein Schimpfen)
      final result = LumoImageGenerator.check(childPrompt);
      setState(() {
        _messages.add(_ChatMessage(
          text: result.hint ?? 'Sag mir was Liebes - ein Tier, eine Blume, ein Spielzeug?',
          isLumo: true,
        ));
      });
      _scrollToBottom();
      return;
    }
    setState(() {
      _messages.add(_ChatMessage(
        text: 'Schau mal - hier ist ein Bild fuer dich!',
        isLumo: true,
        imageUrl: url,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildChat()),
            _buildQuickActions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final g = widget.topic.gradient;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: g,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: g[0].withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.school_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Klasse ${widget.grade}',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            const SizedBox(width: 16),
            // Animierter Lumo
            AnimatedBuilder(
              animation: _lumoPulseCtrl,
              builder: (_, __) {
                final s = 1.0 + _lumoPulseCtrl.value * 0.05;
                return Transform.scale(
                  scale: s,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/lumo_sprite_pack/lumo_main.png',
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.pets_rounded,
                            color: Colors.white,
                            size: 30),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.topic.title,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  Text(widget.subject.name,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildBubble(_messages[i]);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isLumo = msg.isLumo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isLumo ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isLumo) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.topic.gradient,
                ),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.pets_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints:
                  const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: msg.isError
                    ? const Color(0xFFFEE2E2)
                    : (isLumo ? Colors.white : widget.topic.gradient[0]),
                gradient: !isLumo && !msg.isError
                    ? LinearGradient(colors: widget.topic.gradient)
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isLumo
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                  bottomRight: isLumo
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                ),
                border: isLumo && !msg.isError
                    ? Border.all(color: const Color(0xFFE5E7EB))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isLumo
                            ? Colors.black
                            : widget.topic.gradient[0])
                        .withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: msg.isError
                          ? const Color(0xFFB91C1C)
                          : (isLumo ? const Color(0xFF1F2937) : Colors.white),
                    ),
                  ),
                  // Bildgenerator-Bubble (Heinz' Feature)
                  if (msg.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        msg.imageUrl!,
                        width: 240,
                        height: 240,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              color: widget.topic.gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: widget.topic.gradient[0],
                                      strokeWidth: 3),
                                  const SizedBox(height: 8),
                                  Text('Bild wird gemalt...',
                                      style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: widget.topic.gradient[1])),
                                ],
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, st) => Container(
                          width: 240,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                                'Bild konnte ich nicht laden. Versuch nochmal!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.topic.gradient),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.pets_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _lumoPulseCtrl,
                  builder: (_, __) {
                    final v = ((_lumoPulseCtrl.value * 3 - i) % 1).abs();
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.topic.gradient[0]
                            .withOpacity(0.4 + v * 0.6),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(
          child: GestureDetector(
            onTap: () => _ask(_quickQuestions[i]),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.topic.gradient[0].withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                _quickQuestions[i],
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.topic.gradient[0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !_loading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _ask,
                  decoration: const InputDecoration(
                    hintText: 'Frag Lumo etwas...',
                    hintStyle: TextStyle(
                        fontFamily: 'Nunito',
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loading ? null : () => _ask(_controller.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _loading
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : widget.topic.gradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _loading
                      ? null
                      : [
                          BoxShadow(
                            color: widget.topic.gradient[0].withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Icon(
                  _loading
                      ? Icons.hourglass_top_rounded
                      : Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage(
      {required this.text,
      required this.isLumo,
      this.isError = false,
      this.imageUrl});
  final String text;
  final bool isLumo;
  final bool isError;
  /// Wenn gesetzt: Image-Bubble wird im Chat angezeigt (Pollinations.ai URL).
  /// Heinz' Bildgenerator-Feature: nur kindersichere Inhalte.
  final String? imageUrl;
}
