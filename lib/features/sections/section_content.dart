import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';

class SectionContent extends StatelessWidget {
  const SectionContent({
    super.key,
    required this.appState,
    required this.section,
    required this.onSection,
  });

  final LumoAppState appState;
  final LumoSection section;
  final ValueChanged<LumoSection> onSection;

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
            _ActionData('Mini-Test', '5 schnelle Aufgaben zum Aufwärmen.', 'Starten', Icons.flash_on_rounded, () => onSection(LumoSection.exercises)),
            _ActionData('Fach-Test', 'Wähle ein Fach und sammle Sterne.', 'Üben', Icons.school_rounded, () => onSection(LumoSection.learn)),
            _ActionData('Wiederholung', 'Übe Themen, die noch schwer waren.', 'Los', Icons.refresh_rounded, () => onSection(LumoSection.exercises)),
          ],
        );
      case LumoSection.schoolwork:
        return _ActionPage(
          title: 'Schularbeit',
          subtitle: 'Bereite dich ruhig und strukturiert auf eine Schularbeit vor.',
          emoji: '🏆',
          accent: LumoColors.schoolwork,
          cards: [
            _ActionData('Gemischter Test', 'Mathe, Deutsch und Lesen gemischt.', 'Starten', Icons.assignment_rounded, () => onSection(LumoSection.exercises)),
            _ActionData('Mit Note üben', 'Am Ende bekommst du eine freundliche Einschätzung.', 'Starten', Icons.workspace_premium_rounded, () => onSection(LumoSection.tests)),
            _ActionData('Schwächen üben', 'Lumo sucht die passenden Wiederholungen aus.', 'Üben', Icons.psychology_rounded, () => onSection(LumoSection.exercises)),
          ],
        );
      case LumoSection.missions:
        return _MissionsPage(onSection: onSection);
      case LumoSection.progress:
        return _ProgressPage(appState: appState);
      case LumoSection.rewards:
        return _RewardsPage(appState: appState, onSection: onSection);
      case LumoSection.agent:
        return _AgentPage(appState: appState, onSection: onSection);
      case LumoSection.settings:
        return _SettingsPage();
      default:
        return _ActionPage(
          title: section.name,
          subtitle: 'Dieser Bereich wird vorbereitet.',
          emoji: '✨',
          accent: LumoColors.orange,
          cards: [
            _ActionData('Zurück zum Start', 'Gehe zurück zur Übersicht.', 'Start', Icons.home_rounded, () => onSection(LumoSection.home)),
          ],
        );
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
  const _MissionsPage({required this.onSection});
  final ValueChanged<LumoSection> onSection;

  @override
  Widget build(BuildContext context) {
    return _ActionPage(
      title: 'Missionen',
      subtitle: 'Kleine Ziele, die ein Kind sofort erledigen kann.',
      emoji: '🚩',
      accent: LumoColors.orange,
      cards: [
        _ActionData('3 Aufgaben lösen', 'Schließe drei einfache Aufgaben ab.', 'Mission starten', Icons.check_circle_rounded, () => onSection(LumoSection.exercises)),
        _ActionData('Mathe-Insel', 'Zahlen und Plus/Minus üben.', 'Starten', Icons.calculate_rounded, () => onSection(LumoSection.learn)),
        _ActionData('Lesemut', 'Deutsch lesen und Wörter erkennen.', 'Starten', Icons.menu_book_rounded, () => onSection(LumoSection.learn)),
        _ActionData('Foto-Hilfe', 'Fotografiere eine Aufgabe und lass dir helfen.', 'Foto', Icons.photo_camera_rounded, () => onSection(LumoSection.scanner)),
      ],
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
        _Header(title: 'Fortschritt', subtitle: 'Hier sieht das Kind, was schon gut klappt.', emoji: '📊', accent: LumoColors.teal),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _ProgressTile(label: 'Sterne', value: '${st.stars}', percent: (st.stars / 50).clamp(0.0, 1.0), color: LumoColors.purple, icon: '⭐'),
          _ProgressTile(label: 'XP Punkte', value: '${st.xp}', percent: ((st.xp % 1000) / 1000).clamp(0.0, 1.0), color: LumoColors.gold, icon: '🏅'),
          _ProgressTile(label: 'Level', value: '${st.level}', percent: st.levelXpPercent / 100, color: LumoColors.teal, icon: '💎'),
          _ProgressTile(label: 'Woche', value: '${st.weeklyProgress}%', percent: st.weeklyProgress / 100, color: LumoColors.blue, icon: '📘'),
        ]),
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
  const _AgentPage({required this.appState, required this.onSection});
  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  State<_AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<_AgentPage> {
  final _controller = TextEditingController();
  String _answer = 'Frag mich etwas zu Mathe, Deutsch oder Lernen. Ich antworte einfach und freundlich.';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    final q = _controller.text.trim().toLowerCase();
    setState(() {
      if (q.contains('plus') || q.contains('+') || q.contains('mathe')) {
        _answer = 'Bei Plus zählst du beide Mengen zusammen. Beispiel: 3 + 2 bedeutet: erst 3, dann noch 2 dazu. Das ergibt 5.';
      } else if (q.contains('minus') || q.contains('-')) {
        _answer = 'Bei Minus nimmst du etwas weg. Beispiel: 7 - 2 bedeutet: von 7 bleiben nach dem Wegnehmen 5 übrig.';
      } else if (q.contains('lesen') || q.contains('deutsch')) {
        _answer = 'Lies langsam Silbe für Silbe. Wenn ein Wort schwer ist, teile es in kleine Teile.';
      } else {
        _answer = 'Gute Frage! Ich helfe dir Schritt für Schritt. Wähle am besten auch ein Fach aus, dann üben wir passend weiter.';
      }
    });
    widget.appState.update(widget.appState.state.copyWith(lumoMessage: _answer, mood: LumoMood.think));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(title: 'Lumo-KI', subtitle: 'Ein sicherer Lernfreund mit einfachen Antworten.', emoji: '🤖', accent: LumoColors.orange),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: lumoCard(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Deine Frage an Lumo', hintText: 'z.B. Wie rechne ich Plus?')),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _ask, icon: const Icon(Icons.send_rounded), label: const Text('Lumo fragen')),
            const SizedBox(height: 16),
            Text(_answer, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
          ]),
        ),
      ]),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(title: 'Elternbereich', subtitle: 'Sichere Einstellungen für Profil, Ton und Lernmodus.', emoji: '⚙️', accent: LumoColors.ink700),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: lumoCard(),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aktiv:', style: LumoTextStyles.heading3),
            SizedBox(height: 8),
            Text('• Lokales Kinderprofil\n• Alters- und Klassenlogik\n• Sicherer Offline-Lumo-Helfer\n• Foto-Review ohne Online-Upload', style: LumoTextStyles.body),
          ]),
        ),
      ]),
    );
  }
}
