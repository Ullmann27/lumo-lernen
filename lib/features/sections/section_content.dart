import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_companion_engine.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../rewards/reward_shop_content.dart';
import '../shared/widgets/lumo_subject_dashboard.dart';
import '../shared/widgets/lumo_subject_tile.dart';
import '../tutoring/tutoring_flow_card.dart';
import '../tutoring/guided_learning_hub.dart';
import '../tutoring/guided_lesson_screen.dart';
import '../../domain/tutoring/guided_lesson_catalog.dart';

typedef _StartSession = void Function({
  required String subject,
  String? unit,
  required String message,
  LumoSessionKind? sessionKind,
});

class SectionContent extends StatelessWidget {
  const SectionContent({super.key, required this.appState, required this.section, required this.onSection,
  });

  final LumoAppState appState;
  final LumoSection section;
  final FutureOr<void> Function(LumoSection) onSection;

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
    ),
    );
    onSection(LumoSection.exercises);
  }

  void _startReading() {
    appState.update(appState.state.copyWith(
      subject: 'Lesen',
      unit: 'Aktives Lesen',
      mood: LumoMood.think,
      lumoMessage: 'Ich höre dir\nbeim Lesen zu.\nSatz für Satz.',
    ),
    );
    onSection(LumoSection.reading);
  }

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case LumoSection.learn:
        // The legacy Deutsch menu contained hard-coded first-grade lessons
        // and fictional stars. Show only real generator-backed grade topics.
        final grade = appState.state.grade.clamp(1, 4);
        final units = Curriculum.unitsForGrade(
            'Deutsch', grade, currentGradeOnly: true);
        return _ActionPage(
          title: 'Deutsch · $grade. Klasse',
          subtitle: 'Wähle ein Thema mit echten Aufgaben für deine Schulstufe.',
          emoji: '📘',
          accent: LumoColors.purple,
          cards: [
            for (final unit in units.take(12))
              _ActionData(
                Curriculum.prettifyUnit(unit),
                'Üben, verstehen und mit Lumo Schritt für Schritt lernen.',
                'Aufgabe starten',
                Icons.menu_book_rounded,
                () => _startSession(
                  subject: 'Deutsch',
                  unit: unit,
                  message: 'Wir lernen ${Curriculum.prettifyUnit(unit)}.',
                  sessionKind: LumoSessionKind.quickPractice,
                ),
              ),
          ],
        );
      case LumoSection.schoolwork:
        return _ActionPage(
          title: 'Schularbeit',
          subtitle: 'Bereite dich ruhig und strukturiert auf eine Schularbeit vor.',
          emoji: '🏆',
          accent: LumoColors.schoolwork,
          cards: [
            _ActionData(
              'Gemischter Lerncheck',
              '30 Aufgaben aus Mathe, Deutsch, Sachunterricht und Englisch.',
              'Starten',
              Icons.assignment_rounded,
              () => _startSession(
                subject: 'Alle',
                message: 'Gemischter\nLerncheck\nstartet jetzt.',
                sessionKind: LumoSessionKind.schoolwork,
              ),
            ),
            _ActionData(
              'Mathe-Schularbeit',
              '30 Aufgaben: Rechnen, Größen, Geld, Zeit, Geometrie und Sachaufgaben.',
              'Starten',
              Icons.calculate_rounded,
              () => _startSession(
                subject: 'Mathematik',
                message: 'Mathe-Training\nwie Schularbeit.',
                sessionKind: LumoSessionKind.schoolwork,
              ),
            ),
            _ActionData(
              'Deutsch-Schularbeit',
              '30 Aufgaben: Lesen, Sprache, Rechtschreibung und Schreiben.',
              'Starten',
              Icons.edit_document,
              () => _startSession(
                subject: 'Deutsch',
                message: 'Deutsch-Training\nwie Schularbeit.',
                sessionKind: LumoSessionKind.schoolwork,
              ),
            ),
            _ActionData(
              'Sachunterricht-Lerncheck',
              'Natur, Körper, Gemeinschaft, Österreich, Verkehr, Technik und Umwelt.',
              'Starten',
              Icons.public_rounded,
              () => _startSession(
                subject: 'Sachunterricht',
                message: 'Sachunterricht\nLerncheck\nstartet.',
                sessionKind: LumoSessionKind.test,
              ),
            ),
            _ActionData(
                'Englisch-Lerncheck',
                'Hören/Lesen, Wortschatz und einfache Alltagssituationen.',
                'Starten',
                Icons.language_rounded,
                () => _startSession(
                  subject: 'Englisch',
                  message: 'English Check\nstarts now.',
                  sessionKind: LumoSessionKind.test,
                ),
              ),
            _ActionData(
              'Schnelle Wiederholung',
              '20 Aufgaben gemischt zum Festigen.',
              'Üben',
              Icons.refresh_rounded,
              () => _startSession(
                subject: 'Alle',
                message: 'Wiederholung\nstartet.',
                sessionKind: LumoSessionKind.exerciseSet,
              ),
            ),
          ],
        );
      case LumoSection.missions:
        return _MissionsPage(appState: appState, onSection: onSection, startSession: _startSession, startReading: _startReading,
        );
      case LumoSection.progress:
        return _ProgressPage(appState: appState);
      case LumoSection.rewards:
        return RewardShopContent(appState: appState);
      case LumoSection.agent:
        return _AgentPage(appState: appState, onSection: onSection, startSession: _startSession, startReading: _startReading,
        );
      case LumoSection.settings:
        return _SettingsPage(appState: appState);
      case LumoSection.exercises:
        // No mock stars, recycled first-class topics or unavailable units.
        // The curated template pool keeps harder grades on their own level.
        final mathGrade = appState.state.grade.clamp(1, 4);
        final units = Curriculum.unitsForGrade(
            'Mathematik', mathGrade, currentGradeOnly: true);
        return _ActionPage(
          title: 'Mathematik · $mathGrade. Klasse',
          subtitle: 'Echte Aufgaben aus dem Lernstoff deiner Schulstufe.',
          emoji: '🔢',
          accent: LumoColors.math,
          cards: [
            for (final unit in units.take(12))
              _ActionData(
                Curriculum.prettifyUnit(unit),
                'Aufgaben mit Antworten und verständlichen Erklärungen.',
                'Aufgabe starten',
                Icons.calculate_rounded,
                () => _startSession(
                  subject: 'Mathematik',
                  unit: unit,
                  message: 'Wir üben ${Curriculum.prettifyUnit(unit)}.',
                  sessionKind: LumoSessionKind.quickPractice,
                ),
              ),
          ],
        );
      default:
        return _ActionPage(title: section.name, subtitle: 'Dieser Bereich wird vorbereitet.', emoji: '✨', accent: LumoColors.orange, cards: [
          _ActionData('Aktiv lesen', 'Lumo hört beim Lesen Satz für Satz zu.', 'Lesen', Icons.record_voice_over_rounded, _startReading,
            ),
          _ActionData('Zurück zum Start', 'Gehe zurück zur Übersicht.', 'Start', Icons.home_rounded, () => onSection(LumoSection.home),
            ),
        ],
        );
    }
  }
}

class _ActionPage extends StatelessWidget {
  const _ActionPage({required this.title, required this.subtitle, required this.emoji, required this.accent, required this.cards,
  });
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;
  final List<_ActionData> cards;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(title: title, subtitle: subtitle, emoji: emoji, accent: accent),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: cards.map((c) => _ActionCard(data: c, accent: accent)).toList(),
            ),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, required this.emoji, required this.accent,
  });
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xEE0B315F), Color(0xF0081D43), Color(0xEA0B2A55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.48), width: 1.2),
        boxShadow: [
          BoxShadow(color: LumoVisualTokens.cyan.withOpacity(.16), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withOpacity(.82), accent.withOpacity(.34)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(LumoRadius.lg),
              border: Border.all(color: Colors.white.withOpacity(.30)),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 34))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LumoTextStyles.heading1.copyWith(
                    color: LumoVisualTokens.white,
                    shadows: const [Shadow(color: Color(0x8837D2FD), blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: LumoVisualTokens.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  const _ActionData(this.title, this.description, this.cta, this.icon, this.onTap,
  );
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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xDD123D72), Color(0xEE0A2852)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withOpacity(.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent.withOpacity(.75), accent.withOpacity(.25)]),
                  borderRadius: BorderRadius.circular(LumoRadius.sm),
                  border: Border.all(color: Colors.white.withOpacity(.22)),
                  ), child: Icon(data.icon, color: Colors.white, size: 21),
                ),
            const SizedBox(width: 10),
            Expanded(child: Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.heading3.copyWith(color: LumoVisualTokens.white),
                  ),
                ),
          ],
            ),
          const SizedBox(height: 10),
          Expanded(child: Text(data.description, style: LumoTextStyles.cardSub.copyWith(color: LumoVisualTokens.muted), maxLines: 3, overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(data.cta, style: LumoTextStyles.cta.copyWith(color: LumoVisualTokens.cyanBright),
                ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, color: LumoVisualTokens.cyanBright, size: 15),
          ],
            ),
        ],
        ),
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
  final FutureOr<void> Function(LumoSection) onSection;
  final _StartSession startSession;
  final VoidCallback startReading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      children: [
        TutoringFlowCard(
          appState: appState,
          onStartTutoring: (recommendation) => startSession(
            subject: recommendation.subject,
            unit: recommendation.unit,
            message: recommendation.message,
            sessionKind: recommendation.isTutoring
                ? LumoSessionKind.tutoring
                : LumoSessionKind.quickPractice,
          ),
          onStartGuidedLearning: (lesson) => _openGuided(context, lesson),
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
            color: LumoVisualTokens.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kleine Ziele, die ein Kind sofort erledigen kann.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: LumoVisualTokens.muted,
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

  Future<void> _openGuided(BuildContext context, GuidedLesson? lesson) async {
    // Capture navigation before the Missions page is unmounted. Set the actual
    // learning section first so the existing CompanionHost owns the real task.
    final navigator = Navigator.of(context);
    final generation = appState.profileGeneration;
    await onSection(LumoSection.learn);
    if (!navigator.mounted ||
        generation != appState.profileGeneration ||
        appState.state.section != LumoSection.learn) {
      return;
    }
    await navigator.push<void>(MaterialPageRoute(
      builder: (_) => lesson == null
          ? GuidedLearningHub(appState: appState, discovery: false)
          : GuidedLessonScreen(
              appState: appState, lesson: lesson, discovery: false),
    ));
  }

  List<_ActionData> _missionCards() => [
        _ActionData('3 Aufgaben lösen', 'Schließe drei einfache Aufgaben ab.', 'Mission starten', Icons.check_circle_rounded, () => startSession(subject: 'Alle', message: 'Mission:\n3 Aufgaben\nlösen!',
      ),
    ),
        _ActionData('Mathe-Insel', 'Zahlen und Plus/Minus üben.', 'Starten', Icons.calculate_rounded, () => startSession(subject: 'Mathematik', unit: 'Plus bis 20', message: 'Mathe-Insel\nstartet jetzt.',
      ),
    ),
        _ActionData('Lesemut', 'Lumo hört beim Lesen aktiv zu.', 'Starten', Icons.record_voice_over_rounded, startReading,
    ),
        _ActionData('Foto-Hilfe', 'Fotografiere eine Aufgabe und lass dir helfen.', 'Foto', Icons.photo_camera_rounded, () => onSection(LumoSection.scanner),
    ),
        _ActionData('Englisch-Start', 'Farben, Tiere und Begrüßung.', 'Starten', Icons.language_rounded, () => startSession(subject: 'Englisch', message: 'Englisch\nstartet jetzt.',
      ),
    ),
        _ActionData('Sachforscher', 'Tiere, Pflanzen und Wetter.', 'Starten', Icons.eco_rounded, () => startSession(subject: 'Sachunterricht', message: 'Sachforscher\nMission startet.',
      ),
    ),
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
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xE8123D72), Color(0xEE0A2852)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.45)),
          boxShadow: [
            BoxShadow(color: LumoVisualTokens.cyan.withOpacity(.16), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2A7EE0), Color(0xFF174B86)]),
              borderRadius: BorderRadius.circular(LumoRadius.lg),
              border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.45)),
              ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/lumo_design/icons/book_open.png',
                fit: BoxFit.contain,
                semanticLabel: 'Lesen mit Lumo',
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aktiv lesen mit Lumo', style: LumoTextStyles.heading2.copyWith(color: LumoVisualTokens.white,
                    ),
                  ),
              const SizedBox(height: 5),
              Text('Lumo hört Satz für Satz zu, hilft bei Fehlern und merkt sich Übungswörter.', style: LumoTextStyles.body.copyWith(color: LumoVisualTokens.muted,
                    ),
                  ),
            ],
              ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: LumoColors.blue, borderRadius: BorderRadius.circular(LumoRadius.pill),
              ),
            child: const Text('Lesen', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white,
                ),
              ),
          ),
        ],
        ),
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
        _Header(title: 'Fortschritt', subtitle: '${st.childName}, hier siehst du, was schon gut klappt.', emoji: '📊', accent: LumoColors.teal,
          ),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _ProgressTile(label: 'Sterne', value: '${st.stars}', percent: (st.stars / 50).clamp(0.0, 1.0), color: LumoColors.purple, icon: '⭐',
              ),
          _ProgressTile(label: 'XP Punkte', value: '${st.xp}', percent: ((st.xp % 1000) / 1000).clamp(0.0, 1.0), color: LumoColors.gold, icon: '🏅',
              ),
          _ProgressTile(label: 'Level', value: '${st.level}', percent: st.levelXpPercent / 100, color: LumoColors.teal, icon: '💎',
              ),
          _ProgressTile(label: 'Wochenziel', value: '${appState.weeklyProgressPercent}%', percent: appState.weeklyProgressPercent / 100, color: LumoColors.blue, icon: '📘',
              ),
        ],
          ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xE6123760), Color(0xE609264B)],
                ),
                borderRadius: BorderRadius.circular(LumoRadius.xl),
                border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.32)),
              ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Aktuelle Lernrichtung', style: LumoTextStyles.heading3,
                ),
            const SizedBox(height: 8),
            Text('Fach: ${st.subject}\nThema: ${st.unit}\nKlasse: ${st.grade}', style: LumoTextStyles.body.copyWith(color: LumoColors.ink700),
                ),
          ],
            ),
        ),
      ],
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.label, required this.value, required this.percent, required this.color, required this.icon,
  });
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
      decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xE6123760), Color(0xE609264B)],
                ),
                borderRadius: BorderRadius.circular(LumoRadius.xl),
                border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.32)),
              ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(width: 8), Text(label, style: LumoTextStyles.label.copyWith(color: color)),
            ],
          ),
        const SizedBox(height: 10),
        Text(value, style: LumoTextStyles.kpiValue),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: color.withOpacity(.12),
            ),
          ),
      ],
      ),
    );
  }
}
class _AgentPage extends StatefulWidget {
  const _AgentPage({required this.appState, required this.onSection, required this.startSession, required this.startReading,
  });
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
    ),
    );
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
    },
    );
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
            _Header(title: 'Lumo-KI', subtitle: 'Sprich mit Lumo. Er hört zu, antwortet und kann passende Übungen starten.', emoji: '🎙️', accent: LumoColors.orange,
              ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xE6123760), Color(0xE609264B)],
                ),
                borderRadius: BorderRadius.circular(LumoRadius.xl),
                border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.32)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deine Frage an Lumo', hintText: 'z.B. Wie rechne ich Plus?',
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  FilledButton.icon(onPressed: () => _ask(), icon: const Icon(Icons.send_rounded), label: const Text('Lumo fragen'),
                        ),
                  FilledButton.icon(
                    onPressed: micEnabled ? _toggleMic : null,
                    icon: Icon(_speech.listening ? Icons.stop_rounded : Icons.mic_rounded,
                          ),
                    label: Text(micEnabled ? (_speech.listening ? 'Stopp' : 'Mit Lumo sprechen') : 'Mikrofon aus',
                          ),
                  ),
                  if (canStart) OutlinedButton.icon(onPressed: _startSuggested, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Passende Übung starten'),
                          ),
                  OutlinedButton.icon(onPressed: widget.startReading, icon: const Icon(Icons.record_voice_over_rounded), label: const Text('Aktiv lesen'),
                        ),
                  OutlinedButton(onPressed: () => widget.startSession(subject: 'Mathematik', message: 'Mathe\nüben wir jetzt.',
                          ), child: const Text('Mathe üben'),
                        ),
                  OutlinedButton(onPressed: () => widget.startSession(subject: 'Deutsch', message: 'Deutsch\nüben wir jetzt.',
                          ), child: const Text('Deutsch üben'),
                        ),
                  OutlinedButton(onPressed: () => widget.startSession(subject: 'Alle', message: 'Gemischt\nüben wir jetzt.',
                          ), child: const Text('Gemischt üben'),
                        ),
                ],
                    ),
                const SizedBox(height: 16),
                if (!micEnabled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xD90B2A55), borderRadius: BorderRadius.circular(LumoRadius.lg), border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.25)),
                        ),
                    child: Text('Mikrofon ist im Elternbereich deaktiviert.', style: LumoTextStyles.body.copyWith(color: LumoVisualTokens.white,
                          ),
                        ),
                  ),
                if (_speech.listening || _heardText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xD90B2A55), borderRadius: BorderRadius.circular(LumoRadius.lg), border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.25)),
                        ),
                    child: Text(_speech.listening ? 'Ich höre: ${_heardText.isEmpty ? '...' : _heardText}' : 'Gehört: $_heardText', style: LumoTextStyles.body.copyWith(color: LumoVisualTokens.white,
                          ),
                        ),
                  ),
                if (_speech.error != null) ...[
                  const SizedBox(height: 10),
                  Text('Mikrofon-Hinweis: ${_speech.error}', style: LumoTextStyles.caption.copyWith(color: Colors.redAccent,
                        ),
                      ),
                ],
                const SizedBox(height: 16),
                Text(_answer, style: LumoTextStyles.body.copyWith(color: LumoVisualTokens.white,
              ),
            ),
          ],
                ),
              ),
            ],
          ),
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
        _Header(title: 'Elternbereich', subtitle: 'Sichere Einstellungen für Profil, Ton und Lernmodus.', emoji: '⚙️', accent: LumoColors.ink700,
          ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xE6123760), Color(0xE609264B)],
                ),
                borderRadius: BorderRadius.circular(LumoRadius.xl),
                border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.32)),
              ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aktiv:', style: LumoTextStyles.heading3.copyWith(color: LumoVisualTokens.white)),
            const SizedBox(height: 8),
            Text('• Profil: ${st.childName}, Klasse ${st.grade}\n• Lokales Kinderprofil\n• Alters- und Klassenlogik\n• Sicherer Offline-Lumo-Helfer\n• Mikrofon nur lokal für Spracheingabe\n• Foto-Review ohne Online-Upload', style: LumoTextStyles.body.copyWith(color: LumoVisualTokens.muted),
                ),
          ],
            ),
        ),
      ],
      ),
    );
  }
}
