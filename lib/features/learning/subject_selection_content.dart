import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/school_exercise_generator.dart';

class SubjectSelectionContent extends StatelessWidget {
  const SubjectSelectionContent({
    super.key,
    required this.appState,
    required this.onSection,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  static const _subjects = <_SubjectInfo>[
    _SubjectInfo('Mathematik', '🔢', LumoColors.math, 'Zahlen, Rechnen, Formen'),
    _SubjectInfo('Deutsch', '📚', LumoColors.german, 'Lesen, Wörter, Sätze'),
    _SubjectInfo('Lesen', '📖', LumoColors.blue, 'Wörter und Texte verstehen'),
    _SubjectInfo('Rechtschreibung', '✏️', LumoColors.practice, 'Wörter richtig schreiben'),
    _SubjectInfo('Schreiben', '📝', LumoColors.scanner, 'Finger schreiben und nachspuren'),
    _SubjectInfo('Englisch', '🌍', LumoColors.english, 'Farben, Tiere, Wörter'),
    _SubjectInfo('Sachunterricht', '🌱', LumoColors.teal, 'Welt, Tiere, Wetter'),
  ];

  void _startSubject(_SubjectInfo subject) {
    appState.update(appState.state.copyWith(
      subject: subject.title,
      unit: 'Alle',
      mood: LumoMood.point,
      lumoMessage: '${subject.title}\nist bereit.\nStarten wir!',
    ));
    onSection(LumoSection.exercises);
  }

  void _startUnit(String subject, String unit) {
    appState.update(appState.state.copyWith(
      subject: subject,
      unit: unit,
      mood: LumoMood.point,
      lumoMessage: '$unit\nüben wir jetzt\ngemeinsam.',
    ));
    onSection(LumoSection.exercises);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: lumoCard(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF0E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: LumoColors.orangeSurface,
                borderRadius: BorderRadius.circular(LumoRadius.lg),
              ),
              child: const Center(child: Text('🎒', style: TextStyle(fontSize: 34))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Was möchtest du üben?', style: LumoTextStyles.heading1),
              const SizedBox(height: 6),
              Text('Klasse ${appState.state.grade} • Lumo wählt passende Aufgaben zu deinem Profil.', style: LumoTextStyles.body),
            ])),
          ]),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: _subjects.map((s) => _SubjectCard(info: s, onTap: () => _startSubject(s))).toList(),
        ),
        const SizedBox(height: 26),
        const Text('Unterthemen', style: LumoTextStyles.heading2),
        const SizedBox(height: 12),
        ..._subjects.map((s) => _UnitGroup(
          subject: s,
          units: Curriculum.subjects[s.title] ?? const <String>[],
          onUnit: (unit) => _startUnit(s.title, unit),
        )),
      ]),
    );
  }
}

class _SubjectInfo {
  const _SubjectInfo(this.title, this.emoji, this.color, this.subtitle);
  final String title;
  final String emoji;
  final Color color;
  final String subtitle;
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.info, required this.onTap});
  final _SubjectInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 218,
        height: 142,
        padding: const EdgeInsets.all(16),
        decoration: lumoCard(
          gradient: LinearGradient(
            colors: [Colors.white, info.color.withOpacity(.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(info.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Expanded(child: Text(info.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.heading3.copyWith(color: info.color))),
          ]),
          const SizedBox(height: 10),
          Expanded(child: Text(info.subtitle, style: LumoTextStyles.cardSub, maxLines: 2, overflow: TextOverflow.ellipsis)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Starten', style: LumoTextStyles.cta.copyWith(color: info.color)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, color: info.color, size: 15),
          ]),
        ]),
      ),
    );
  }
}

class _UnitGroup extends StatelessWidget {
  const _UnitGroup({required this.subject, required this.units, required this.onUnit});
  final _SubjectInfo subject;
  final List<String> units;
  final ValueChanged<String> onUnit;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(color: Colors.white.withOpacity(.86)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(subject.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(subject.title, style: LumoTextStyles.heading3.copyWith(color: subject.color)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: units.take(10).map((unit) => GestureDetector(
            onTap: () => onUnit(unit),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: subject.color.withOpacity(.10),
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                border: Border.all(color: subject.color.withOpacity(.18)),
              ),
              child: Text(unit, style: LumoTextStyles.cta.copyWith(color: subject.color)),
            ),
          )).toList(),
        ),
      ]),
    );
  }
}
