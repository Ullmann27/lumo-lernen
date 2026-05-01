import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/lumo_companion_engine.dart';
import '../../core/lumo_voice.dart';

class LumoAgentContent extends StatefulWidget {
  const LumoAgentContent({super.key, required this.appState, required this.onSection});

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  State<LumoAgentContent> createState() => _LumoAgentContentState();
}

class _LumoAgentContentState extends State<LumoAgentContent> {
  final TextEditingController _controller = TextEditingController();
  final LumoAiProxyClient _proxy = const LumoAiProxyClient();
  final LumoCompanionEngine _localEngine = const LumoCompanionEngine();
  final List<LumoAiChatTurn> _history = <LumoAiChatTurn>[];

  bool _loading = false;
  String _answer = 'Ich bin Lumo. Frag mich etwas zu Mathe, Deutsch, Lesen, Englisch, Sachunterricht, Natur oder einer Geschichte.';
  String _source = 'local_ready';
  bool _blocked = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask([String? raw]) async {
    final question = (raw ?? _controller.text).trim();
    if (question.isEmpty || _loading) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final settings = widget.appState.state.settings;
    setState(() {
      _loading = true;
      _blocked = false;
      _answer = 'Ich denke kurz nach ...';
    });

    if (_proxy.isConfigured(settings)) {
      final response = await _proxy.ask(
        settings: settings,
        state: widget.appState.state,
        message: question,
        history: List<LumoAiChatTurn>.unmodifiable(_history),
      );
      if (!mounted) return;
      _remember(question, response.reply);
      setState(() {
        _answer = response.reply;
        _source = response.source;
        _blocked = response.blocked;
        _loading = false;
      });
      _applyReply(response.reply, blocked: response.blocked);
      return;
    }

    final local = _localEngine.answer(input: question, state: widget.appState.state);
    if (!mounted) return;
    _remember(question, local.text);
    setState(() {
      _answer = '${local.text}\n\nHinweis für Eltern: Die erweiterte Lumo-KI ist im Elternbereich ausgeschaltet.';
      _source = 'local_companion';
      _blocked = false;
      _loading = false;
    });
    widget.appState.update(widget.appState.state.copyWith(
      lumoMessage: local.text,
      mood: local.mood,
      subject: local.suggestedSubject ?? widget.appState.state.subject,
      unit: local.suggestedUnit ?? widget.appState.state.unit,
    ));
    if (widget.appState.state.settings.voiceEnabled) {
      LumoVoice.instance.speak(local.text);
    }
  }

  void _remember(String question, String reply) {
    _history.add(LumoAiChatTurn(role: 'user', content: question));
    _history.add(LumoAiChatTurn(role: 'assistant', content: reply));
    while (_history.length > 8) {
      _history.removeAt(0);
    }
    _controller.clear();
  }

  void _applyReply(String reply, {required bool blocked}) {
    widget.appState.update(widget.appState.state.copyWith(
      lumoMessage: reply,
      mood: blocked ? LumoMood.comfort : LumoMood.greet,
    ));
    if (widget.appState.state.settings.voiceEnabled) {
      LumoVoice.instance.speak(reply);
    }
  }

  void _quickAsk(String text) => _ask(text);

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.state.settings;
    final proxyReady = _proxy.isConfigured(settings);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AgentHeader(proxyReady: proxyReady, enabled: settings.aiProxyEnabled, onSettings: () => widget.onSection(LumoSection.settings)),
            const SizedBox(height: 16),
            _SafetyFrame(proxyReady: proxyReady),
            const SizedBox(height: 16),
            _AnswerBubble(answer: _answer, loading: _loading, blocked: _blocked, source: _source),
            const SizedBox(height: 16),
            _QuestionInput(controller: _controller, loading: _loading, onAsk: _ask),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _QuickChip(label: 'Erklär mir 7 + 5', onTap: () => _quickAsk('Erklär mir 7 plus 5 in kleinen Schritten.')),
              _QuickChip(label: 'Hilf mir bei Deutsch', onTap: () => _quickAsk('Hilf mir bei einem deutschen Satz.')),
              _QuickChip(label: 'Englisch üben', onTap: () => _quickAsk('Übe mit mir drei einfache englische Wörter.')),
              _QuickChip(label: 'Naturfrage', onTap: () => _quickAsk('Erzähl mir etwas Kurzes über Bienen.')),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _AgentHeader extends StatelessWidget {
  const _AgentHeader({required this.proxyReady, required this.enabled, required this.onSettings});

  final bool proxyReady;
  final bool enabled;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final title = proxyReady ? 'Lumo-KI ist bereit' : 'Lumo hilft lokal';
    final subtitle = proxyReady
        ? 'Der Elternbereich hat den kindergesicherten KI-Proxy freigegeben.'
        : enabled
            ? 'Der KI-Schalter ist aktiv, aber die Proxy-URL fehlt oder ist ungültig.'
            : 'Die erweiterte KI ist ausgeschaltet. Lumo nutzt nur lokale Lernhilfe.';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFEFF6FF)])),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.lg)),
          child: const Center(child: Text('🦊', style: TextStyle(fontSize: 34))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: LumoTextStyles.heading2),
            const SizedBox(height: 5),
            Text(subtitle, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
          ]),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(onPressed: onSettings, icon: const Icon(Icons.lock_rounded), label: const Text('Eltern')),
      ]),
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
      decoration: lumoCard(color: proxyReady ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(proxyReady ? Icons.verified_user_rounded : Icons.shield_rounded, color: proxyReady ? const Color(0xFF16A34A) : LumoColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Sicherheitsrahmen: Lumo spricht nur über kindgerechte Themen wie Schule, Freunde, Cartoons, Lesen, Mathe, Deutsch, Englisch, Sachunterricht und Natur. Verbotene Themen werden freundlich umgelenkt.',
            style: LumoTextStyles.body.copyWith(color: LumoColors.ink700, fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.answer, required this.loading, required this.blocked, required this.source});

  final String answer;
  final bool loading;
  final bool blocked;
  final String source;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(
        gradient: LinearGradient(
          colors: blocked ? [const Color(0xFFFFF7ED), Colors.white] : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(blocked ? Icons.front_hand_rounded : Icons.chat_bubble_rounded, color: blocked ? LumoColors.orange : LumoColors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text('Lumo antwortet', style: LumoTextStyles.heading3)),
          if (loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: LumoColors.orange)),
        ]),
        const SizedBox(height: 10),
        Text(answer, style: LumoTextStyles.body.copyWith(color: LumoColors.ink800, fontWeight: FontWeight.w800, height: 1.35)),
        const SizedBox(height: 10),
        Text('Quelle: $source', style: LumoTextStyles.caption.copyWith(color: LumoColors.ink400)),
      ]),
    );
  }
}

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({required this.controller, required this.loading, required this.onAsk});

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String?> onAsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: lumoCard(),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: loading ? null : (value) => onAsk(value),
            decoration: const InputDecoration(
              labelText: 'Frag Lumo',
              hintText: 'Zum Beispiel: Erklär mir 12 minus 5.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: loading ? null : () => onAsk(controller.text),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Senden'),
        ),
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
      label: Text(label),
      avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
      onPressed: onTap,
    );
  }
}
