import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_companion_engine.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_voice.dart';
import '../tutoring/tutoring_flow_card.dart';

typedef _StartSession = void Function({
  required String subject,
  String? unit,
  required String message,
  LumoSessionKind? sessionKind,
});

class SectionContent extends StatelessWidget {
  const SectionContent({super.key, required this.appState, required this.section, required this.onSection});

  final LumoAppState appState;
  final LumoSection section;
  final ValueChanged<LumoSection> onSection;

  void _startSession({
    required String subject,
    String? unit,
    required String message,
    LumoSessionKind? sessionKind,
  }) {
    appState.update(appState.state.copyWith(
      subject: subject,
      unit: unit ?? 'Alle',
      mood: LumoMood.point,
      lumoMessage: message,
      sessionKind: sessionKind ?? LumoSessionKind.quickPractice,
    ));
    onSection(LumoSection.exercises);
  }

  void _startReading() {
    appState.update(appState.state.copyWith(
      subject: 'Lesen',
      unit: 'Aktives Lesen',
      mood: LumoMood.think,
      lumoMessage: 'Ich höre dir\nbeim Lesen zu.\nSatz für Satz.',
    ));
    onSection(LumoSection.reading);
  }

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case LumoSection.tests:
        return _ActionPage(
          title: 'Test',
          subtitle: 'Teste dein Wissen mit kurzen kindgerechten Fragen.',
          emoji: '📋',
          accent: LumoColors.testColor,
          cards: [
            _ActionData('Mini-Test', '10 gemischte Aufgaben zum Aufwärmen.', 'Starten', Icons.flash_on_rounded, () => _startSession(subject: 'Alle', message: 'Mini-Test\nist bereit.\nDu schaffst das!', sessionKind: LumoSessionKind.test)),
            _ActionData('Mathe-Test', 'Rechnen, Zahlen und kleine Denkaufgaben.', 'Starten', Icons.calculate_rounded, () => _startSession(subject: 'Mathematik', message: 'Mathe-Test\nist bereit.\nRuhig rechnen.', sessionKind: LumoSessionKind.test)),
            _ActionData('Deutsch-Test', 'Lesen, Wörter und Satzverständnis.', 'Starten', Icons.menu_book_rounded, () => _startSession(subject: 'Deutsch', message: 'Deutsch-Test\nist bereit.\nLangsam lesen.', sessionKind: LumoSessionKind.test)),
            _ActionData('Schwächen-Test', 'Lumo übt stärker, was noch schwer war.', 'Los', Icons.psychology_rounded, () => _startSession(subject: 'Alle', message: 'Ich wähle\npassende Aufgaben\nfür dich.', sessionKind: LumoSessionKind.test)),
          ],
        );
      case LumoSection.schoolwork:
        return _ActionPage(
          title: 'Schularbeit',
          subtitle: 'Bereite dich ruhig und strukturiert auf eine Schularbeit vor.',
          emoji: '🏆',
          accent: LumoColors.schoolwork,
          cards: [
            _ActionData('Gemischter Test', '30 Aufgaben aus Mathe, Deutsch und Sachunterricht.', 'Starten', Icons.assignment_rounded, () => _startSession(subject: 'Alle', message: 'Gemischte\nSchularbeit\nstartet jetzt.', sessionKind: LumoSessionKind.schoolwork)),
            _ActionData('Mathe-Schularbeit', '30 Aufgaben Rechnen, Geld, Uhrzeit und Zahlen.', 'Starten', Icons.calculate_rounded, () => _startSession(subject: 'Mathematik', message: 'Mathe-Training\nwie Schularbeit.', sessionKind: LumoSessionKind.schoolwork)),
            _ActionData('Deutsch-Schularbeit', '30 Aufgaben Lesen, Schreiben und Rechtschreibung.', 'Starten', Icons.edit_document, () => _startSession(subject: 'Deutsch', message: 'Deutsch-Training\nwie Schularbeit.', sessionKind: LumoSessionKind.schoolwork)),
            _ActionData('Schnelle Wiederholung', '20 Aufgaben gemischt zum Festigen.', 'Üben', Icons.refresh_rounded, () => _startSession(subject: 'Alle', message: 'Wiederholung\nstartet.', sessionKind: LumoSessionKind.exerciseSet)),
          ],
        );
      case LumoSection.missions:
        return _MissionsPage(appState: appState, onSection: onSection, startSession: _startSession, startReading: _startReading);
      case LumoSection.progress:
        return _ProgressPage(appState: appState);
      case LumoSection.rewards:
        return _RewardsPage(appState: appState, onSection: onSection);
      case LumoSection.agent:
        return _AgentPage(appState: appState, onSection: onSection, startSession: _startSession, startReading: _startReading);
      case LumoSection.settings:
        return _SettingsPage(appState: appState);
      default:
        return _ActionPage(title: section.name, subtitle: 'Dieser Bereich wird vorbereitet.', emoji: '✨', accent: LumoColors.orange, cards: [
          _ActionData('Aktiv lesen', 'Lumo hört beim Lesen Satz für Satz zu.', 'Lesen', Icons.record_voice_over_rounded, _startReading),
          _ActionData('Zurück zum Start', 'Gehe zurück zur Übersicht.', 'Start', Icons.home_rounded, () => onSection(LumoSection.home)),
        ]);
    }
  }
}

class _ActionPage extends StatelessWidget {
  const _ActionPage({required this.title, required this.subtitle, required this.emoji, required this.accent, required this.cards});
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;
  final List<_ActionData> cards;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(title: title, subtitle: subtitle, emoji: emoji, accent: accent),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 14, children: cards.map((c) => _ActionCard(data: c, accent: accent)).toList()),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, required this.emoji, required this.accent});
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: lumoCard(gradient: LinearGradient(colors: [Colors.white, accent.withOpacity(.10)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Row(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: accent.withOpacity(.14), borderRadius: BorderRadius.circular(LumoRadius.lg)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 34)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: LumoTextStyles.heading1),
          const SizedBox(height: 6),
          Text(subtitle, style: LumoTextStyles.body),
        ])),
      ]),
    );
  }
}

class _ActionData {
  const _ActionData(this.title, this.description, this.cta, this.icon, this.onTap);
  final String title;
  final String description;
  final String cta;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data, required this.accent});
  final _ActionData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 230,
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: lumoCard(gradient: LinearGradient(colors: [Colors.white, accent.withOpacity(.09)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withOpacity(.13), borderRadius: BorderRadius.circular(LumoRadius.sm)), child: Icon(data.icon, color: accent, size: 21)),
            const SizedBox(width: 10),
            Expanded(child: Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.heading3.copyWith(color: accent))),
          ]),
          const SizedBox(height: 10),
          Expanded(child: Text(data.description, style: LumoTextStyles.cardSub, maxLines: 3, overflow: TextOverflow.ellipsis)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(data.cta, style: LumoTextStyles.cta.copyWith(color: accent)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, color: accent, size: 15),
          ]),
        ]),
      ),
    );
  }
}

class _MissionsPage extends StatelessWidget {
  const _MissionsPage({
    required this.appState,
    required this.onSection,
    required this.startSession,
    required this.startReading,
  });
  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;
  final _StartSession startSession;
  final VoidCallback startReading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      children: [
        TutoringFlowCard(
          appState: appState,
          onStartTutoring: () => startSession(
            subject: 'Alle',
            message: 'Lumo-Nachhilfe\nstartet jetzt.\nWir machen das\nzusammen.',
            sessionKind: LumoSessionKind.tutoring,
          ),
        ),
        const SizedBox(height: 22),
        _ReadingMissionCard(onTap: startReading),
        const SizedBox(height: 22),
        const Text(
          'Tagesmissionen',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: LumoColors.ink900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kleine Ziele, die ein Kind sofort erledigen kann.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: LumoColors.ink500,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: _missionCards()
              .map((card) => _ActionCard(data: card, accent: LumoColors.orange))
              .toList(),
        ),
      ],
    );
  }

  List<_ActionData> _missionCards() => [
        _ActionData('3 Aufgaben lösen', 'Schließe drei einfache Aufgaben ab.', 'Mission starten', Icons.check_circle_rounded, () => startSession(subject: 'Alle', message: 'Mission:\n3 Aufgaben\nlösen!')),
        _ActionData('Mathe-Insel', 'Zahlen und Plus/Minus üben.', 'Starten', Icons.calculate_rounded, () => startSession(subject: 'Mathematik', unit: 'Plus bis 20', message: 'Mathe-Insel\nstartet jetzt.')),
        _ActionData('Lesemut', 'Lumo hört beim Lesen aktiv zu.', 'Starten', Icons.record_voice_over_rounded, startReading),
        _ActionData('Foto-Hilfe', 'Fotografiere eine Aufgabe und lass dir helfen.', 'Foto', Icons.photo_camera_rounded, () => onSection(LumoSection.scanner)),
        _ActionData('Englisch-Start', 'Farben, Tiere und Begrüßung.', 'Starten', Icons.language_rounded, () => startSession(subject: 'Englisch', message: 'Englisch\nstartet jetzt.')),
        _ActionData('Sachforscher', 'Tiere, Pflanzen und Wetter.', 'Starten', Icons.eco_rounded, () => startSession(subject: 'Sachunterricht', message: 'Sachforscher\nMission startet.')),
      ];
}

class _ReadingMissionCard extends StatelessWidget {
  const _ReadingMissionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFFFF7ED)])),
        child: Row(children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.86), borderRadius: BorderRadius.circular(LumoRadius.lg)),
            child: const Center(child: Text('📖', style: TextStyle(fontSize: 34))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aktiv lesen mit Lumo', style: LumoTextStyles.heading2.copyWith(color: LumoColors.blue)),
              const SizedBox(height: 5),
              Text('Lumo hört Satz für Satz zu, hilft bei Fehlern und merkt sich Übungswörter.', style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: LumoColors.blue, borderRadius: BorderRadius.circular(LumoRadius.pill)),
            child: const Text('Lesen', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage({required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    final st = appState.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(title: 'Fortschritt', subtitle: '${st.childName}, hier siehst du, was schon gut klappt.', emoji: '📊', accent: LumoColors.teal),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _ProgressTile(label: 'Sterne', value: '${st.stars}', percent: (st.stars / 50).clamp(0.0, 1.0), color: LumoColors.purple, icon: '⭐'),
          _ProgressTile(label: 'XP Punkte', value: '${st.xp}', percent: ((st.xp % 1000) / 1000).clamp(0.0, 1.0), color: LumoColors.gold, icon: '🏅'),
          _ProgressTile(label: 'Level', value: '${st.level}', percent: st.levelXpPercent / 100, color: LumoColors.teal, icon: '💎'),
          _ProgressTile(label: 'Woche', value: '${st.weeklyProgress}%', percent: st.weeklyProgress / 100, color: LumoColors.blue, icon: '📘'),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: lumoCard(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Aktuelle Lernrichtung', style: LumoTextStyles.heading3),
            const SizedBox(height: 8),
            Text('Fach: ${st.subject}\nThema: ${st.unit}\nKlasse: ${st.grade}', style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
          ]),
        ),
      ]),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.label, required this.value, required this.percent, required this.color, required this.icon});
  final String label;
  final String value;
  final double percent;
  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(width: 8), Text(label, style: LumoTextStyles.label.copyWith(color: color))]),
        const SizedBox(height: 10),
        Text(value, style: LumoTextStyles.kpiValue),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: color.withOpacity(.12))),
      ]),
    );
  }
}

class _RewardsPage extends StatelessWidget {
  const _RewardsPage({required this.appState, required this.onSection});
  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  Widget build(BuildContext context) {
    final stars = appState.state.stars;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(title: 'Belohnungen', subtitle: 'Sammle Abzeichen durch Lernen und kleine Missionen.', emoji: '🎁', accent: LumoColors.gold),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _Badge(label: 'Start-Star', emoji: '⭐', unlocked: stars >= 1),
          _Badge(label: 'Mathe-Mut', emoji: '🔢', unlocked: stars >= 10),
          _Badge(label: 'Lesefuchs', emoji: '📚', unlocked: stars >= 20),
          _Badge(label: 'Super-Lumo', emoji: '🦊', unlocked: stars >= 30),
          _Badge(label: 'Englisch-Held', emoji: '🌍', unlocked: stars >= 35),
          _Badge(label: 'Sachforscher', emoji: '🌱', unlocked: stars >= 40),
        ]),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: () => onSection(LumoSection.missions), icon: const Icon(Icons.flag_rounded), label: const Text('Neue Mission holen')),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.emoji, required this.unlocked});
  final String label;
  final String emoji;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(color: unlocked ? Colors.white : const Color(0xFFFFFAF5)),
      child: Column(children: [
        Opacity(opacity: unlocked ? 1 : .30, child: Text(emoji, style: const TextStyle(fontSize: 42))),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: LumoTextStyles.heading3),
        const SizedBox(height: 4),
        Text(unlocked ? 'Freigeschaltet' : 'Noch gesperrt', style: LumoTextStyles.caption),
      ]),
    );
  }
}

class _AgentPage extends StatefulWidget {
  const _AgentPage({required this.appState, required this.onSection, required this.startSession, required this.startReading});
  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;
  final _StartSession startSession;
  final VoidCallback startReading;

  @override
  State<_AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<_AgentPage> {
  final _controller = TextEditingController();
  final _engine = const LumoCompanionEngine();
  final _speech = LumoSpeechListener();
  String _answer = 'Frag mich etwas oder drücke auf das Mikrofon. Ich höre zu und antworte freundlich.';
  String _heardText = '';
  LumoReply? _lastReply;

  @override
  void initState() {
    super.initState();
    if (widget.appState.state.settings.microphoneEnabled) {
      _speech.initialize();
    }
  }

  @override
  void dispose() {
    _speech.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _ask([String? raw]) {
    final question = (raw ?? _controller.text).trim();
    final reply = _engine.answer(input: question, state: widget.appState.state);
    setState(() {
      _answer = reply.text;
      _lastReply = reply;
      if (question.isNotEmpty) _controller.text = question;
    });
    widget.appState.update(widget.appState.state.copyWith(
      lumoMessage: reply.text,
      mood: reply.mood,
      subject: reply.suggestedSubject ?? widget.appState.state.subject,
      unit: reply.suggestedUnit ?? widget.appState.state.unit,
    ));
    if (widget.appState.state.settings.voiceEnabled) {
      LumoVoice.instance.speak(reply.text, style: _voiceStyleFor(reply.mood));
    }
  }

  VoiceStyle _voiceStyleFor(LumoMood mood) {
    switch (mood) {
      case LumoMood.celebrate:
        return VoiceStyle.celebrate;
      case LumoMood.comfort:
        return VoiceStyle.comfort;
      case LumoMood.think:
        return VoiceStyle.explain;
      case LumoMood.point:
        return VoiceStyle.question;
      case LumoMood.greet:
      case LumoMood.wave:
      case LumoMood.idle:
        return VoiceStyle.greeting;
    }
  }

  Future<void> _toggleMic() async {
    if (!widget.appState.state.settings.microphoneEnabled) {
      setState(() {
        _answer = 'Das Mikrofon ist im Elternbereich ausgeschaltet.';
      });
      return;
    }
    if (_speech.listening) {
      await _speech.stopListening();
      if (_speech.lastWords.trim().isNotEmpty) _ask(_speech.lastWords);
      return;
    }
    setState(() {
      _heardText = '';
      _answer = 'Ich höre zu. Sprich langsam und deutlich.';
    });
    await _speech.startListening(onResult: (words) {
      if (!mounted) return;
      setState(() {
        _heardText = words;
        _controller.text = words;
      });
    });
  }

  void _startSuggested() {
    final reply = _lastReply;
    if (reply == null) return;
    if (reply.suggestedSection == LumoSection.scanner) {
      widget.onSection(LumoSection.scanner);
      return;
    }
    if (reply.suggestedSection == LumoSection.tests) {
      widget.onSection(LumoSection.tests);
      return;
    }
    widget.startSession(
      subject: reply.suggestedSubject ?? widget.appState.state.subject,
      unit: reply.suggestedUnit ?? widget.appState.state.unit,
      message: 'Ich starte\ndie passende\nÜbung für dich.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _speech,
      builder: (context, _) {
        final canStart = _lastReply?.suggestedSection != null || _lastReply?.suggestedSubject != null;
        final micEnabled = widget.appState.state.settings.microphoneEnabled;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Header(title: 'Lumo-KI', subtitle: 'Sprich mit Lumo. Er hört zu, antwortet und kann passende Übungen starten.', emoji: '🎙️', accent: LumoColors.orange),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: lumoCard(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deine Frage an Lumo', hintText: 'z.B. Wie rechne ich Plus?'),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  FilledButton.icon(onPressed: () => _ask(), icon: const Icon(Icons.send_rounded), label: const Text('Lumo fragen')),
                  FilledButton.icon(
                    onPressed: micEnabled ? _toggleMic : null,
                    icon: Icon(_speech.listening ? Icons.stop_rounded : Icons.mic_rounded),
                    label: Text(micEnabled ? (_speech.listening ? 'Stopp' : 'Mit Lumo sprechen') : 'Mikrofon aus'),
                  ),
                  if (canStart) OutlinedButton.icon(onPressed: _startSuggested, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Passende Übung starten')),
                  OutlinedButton.icon(onPressed: widget.startReading, icon: const Icon(Icons.record_voice_over_rounded), label: const Text('Aktiv lesen')),
                  OutlinedButton(onPressed: () => widget.startSession(subject: 'Mathematik', message: 'Mathe\nüben wir jetzt.'), child: const Text('Mathe üben')),
                  OutlinedButton(onPressed: () => widget.startSession(subject: 'Deutsch', message: 'Deutsch\nüben wir jetzt.'), child: const Text('Deutsch üben')),
                  OutlinedButton(onPressed: () => widget.startSession(subject: 'Alle', message: 'Gemischt\nüben wir jetzt.'), child: const Text('Gemischt üben')),
                ]),
                const SizedBox(height: 16),
                if (!micEnabled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.lg)),
                    child: Text('Mikrofon ist im Elternbereich deaktiviert.', style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
                  ),
                if (_speech.listening || _heardText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.lg)),
                    child: Text(_speech.listening ? 'Ich höre: ${_heardText.isEmpty ? '...' : _heardText}' : 'Gehört: $_heardText', style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
                  ),
                if (_speech.error != null) ...[
                  const SizedBox(height: 10),
                  Text('Mikrofon-Hinweis: ${_speech.error}', style: LumoTextStyles.caption.copyWith(color: Colors.redAccent)),
                ],
                const SizedBox(height: 16),
                Text(_answer, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    final st = appState.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(title: 'Elternbereich', subtitle: 'Sichere Einstellungen für Profil, Ton und Lernmodus.', emoji: '⚙️', accent: LumoColors.ink700),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: lumoCard(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Aktiv:', style: LumoTextStyles.heading3),
            const SizedBox(height: 8),
            Text('• Profil: ${st.childName}, Klasse ${st.grade}\n• Lokales Kinderprofil\n• Alters- und Klassenlogik\n• Sicherer Offline-Lumo-Helfer\n• Mikrofon nur lokal für Spracheingabe\n• Foto-Review ohne Online-Upload', style: LumoTextStyles.body),
          ]),
        ),
      ]),
    );
  }
}
