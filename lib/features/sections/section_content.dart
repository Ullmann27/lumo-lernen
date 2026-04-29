import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';

class SectionContent extends StatelessWidget {
  const SectionContent({super.key, required this.appState, required this.section, required this.onSection});

  final LumoAppState appState;
  final LumoSection section;
  final ValueChanged<LumoSection> onSection;

  void _startSession({required String subject, String unit = 'Alle', required String message}) {
    appState.update(appState.state.copyWith(subject: subject, unit: unit, mood: LumoMood.point, lumoMessage: message));
    onSection(LumoSection.exercises);
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
            _ActionData('Mini-Test', '5 schnelle gemischte Aufgaben zum Aufwärmen.', 'Starten', Icons.flash_on_rounded, () => _startSession(subject: 'Alle', message: 'Mini-Test\nist bereit.\nDu schaffst das!')),
            _ActionData('Mathe-Test', 'Rechnen, Zahlen und kleine Denkaufgaben.', 'Starten', Icons.calculate_rounded, () => _startSession(subject: 'Mathematik', message: 'Mathe-Test\nist bereit.\nRuhig rechnen.')),
            _ActionData('Deutsch-Test', 'Lesen, Wörter und Satzverständnis.', 'Starten', Icons.menu_book_rounded, () => _startSession(subject: 'Deutsch', message: 'Deutsch-Test\nist bereit.\nLangsam lesen.')),
            _ActionData('Schwächen-Test', 'Lumo übt stärker, was noch schwer war.', 'Los', Icons.psychology_rounded, () => _startSession(subject: 'Alle', message: 'Ich wähle\npassende Aufgaben\nfür dich.')),
          ],
        );
      case LumoSection.schoolwork:
        return _ActionPage(
          title: 'Schularbeit',
          subtitle: 'Bereite dich ruhig und strukturiert auf eine Schularbeit vor.',
          emoji: '🏆',
          accent: LumoColors.schoolwork,
          cards: [
            _ActionData('Gemischter Test', 'Mathe, Deutsch, Lesen und Sachunterricht gemischt.', 'Starten', Icons.assignment_rounded, () => _startSession(subject: 'Alle', message: 'Gemischte\nSchularbeit\nstartet jetzt.')),
            _ActionData('Mathe-Schularbeit', 'Rechnen, Geld, Uhrzeit und Zahlen.', 'Starten', Icons.calculate_rounded, () => _startSession(subject: 'Mathematik', message: 'Mathe-Training\nwie Schularbeit.')),
            _ActionData('Deutsch-Schularbeit', 'Lesen, Schreiben und Rechtschreibung.', 'Starten', Icons.edit_document, () => _startSession(subject: 'Deutsch', message: 'Deutsch-Training\nwie Schularbeit.')),
            _ActionData('Schnelle Wiederholung', 'Kurzer Mix zum Festigen.', 'Üben', Icons.refresh_rounded, () => _startSession(subject: 'Alle', message: 'Kurze\nWiederholung\nstartet.')),
          ],
        );
      case LumoSection.missions:
        return _MissionsPage(onSection: onSection, startSession: _startSession);
      case LumoSection.progress:
        return _ProgressPage(appState: appState);
      case LumoSection.rewards:
        return _RewardsPage(appState: appState, onSection: onSection);
      case LumoSection.agent:
        return _AgentPage(appState: appState, onSection: onSection, startSession: _startSession);
      case LumoSection.settings:
        return _SettingsPage(appState: appState);
      default:
        return _ActionPage(title: section.name, subtitle: 'Dieser Bereich wird vorbereitet.', emoji: '✨', accent: LumoColors.orange, cards: [
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
  const _MissionsPage({required this.onSection, required this.startSession});
  final ValueChanged<LumoSection> onSection;
  final void Function({required String subject, String unit, required String message}) startSession;

  @override
  Widget build(BuildContext context) {
    return _ActionPage(
      title: 'Missionen',
      subtitle: 'Kleine Ziele, die ein Kind sofort erledigen kann.',
      emoji: '🚩',
      accent: LumoColors.orange,
      cards: [
        _ActionData('3 Aufgaben lösen', 'Schließe drei einfache Aufgaben ab.', 'Mission starten', Icons.check_circle_rounded, () => startSession(subject: 'Alle', message: 'Mission:\n3 Aufgaben\nlösen!')),
        _ActionData('Mathe-Insel', 'Zahlen und Plus/Minus üben.', 'Starten', Icons.calculate_rounded, () => startSession(subject: 'Mathematik', unit: 'Plus bis 20', message: 'Mathe-Insel\nstartet jetzt.')),
        _ActionData('Lesemut', 'Deutsch lesen und Wörter erkennen.', 'Starten', Icons.menu_book_rounded, () => startSession(subject: 'Lesen', message: 'Lesemut\nstartet jetzt.')),
        _ActionData('Foto-Hilfe', 'Fotografiere eine Aufgabe und lass dir helfen.', 'Foto', Icons.photo_camera_rounded, () => onSection(LumoSection.scanner)),
        _ActionData('Englisch-Start', 'Farben, Tiere und Begrüßung.', 'Starten', Icons.language_rounded, () => startSession(subject: 'Englisch', message: 'Englisch\nstartet jetzt.')),
        _ActionData('Sachforscher', 'Tiere, Pflanzen und Wetter.', 'Starten', Icons.eco_rounded, () => startSession(subject: 'Sachunterricht', message: 'Sachforscher\nMission startet.')),
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
  const _AgentPage({required this.appState, required this.onSection, required this.startSession});
  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;
  final void Function({required String subject, String unit, required String message}) startSession;

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
      } else if (q.contains('englisch')) {
        _answer = 'Englisch lernst du am besten mit kleinen Wörtern. Starte mit Farben, Zahlen und Tieren.';
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
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.icon(onPressed: _ask, icon: const Icon(Icons.send_rounded), label: const Text('Lumo fragen')),
              OutlinedButton(onPressed: () => widget.startSession(subject: 'Mathematik', message: 'Mathe\nüben wir jetzt.'), child: const Text('Mathe üben')),
              OutlinedButton(onPressed: () => widget.startSession(subject: 'Deutsch', message: 'Deutsch\nüben wir jetzt.'), child: const Text('Deutsch üben')),
              OutlinedButton(onPressed: () => widget.startSession(subject: 'Alle', message: 'Gemischt\nüben wir jetzt.'), child: const Text('Gemischt üben')),
            ]),
            const SizedBox(height: 16),
            Text(_answer, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
          ]),
        ),
      ]),
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
            Text('• Profil: ${st.childName}, Klasse ${st.grade}\n• Lokales Kinderprofil\n• Alters- und Klassenlogik\n• Sicherer Offline-Lumo-Helfer\n• Foto-Review ohne Online-Upload', style: LumoTextStyles.body),
          ]),
        ),
      ]),
    );
  }
}
