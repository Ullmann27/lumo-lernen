import 'package:flutter/material.dart';

import '../../core/school_exercise_generator.dart';
import '../../theme/lumo_visual_tokens.dart';

/// A deliberately quiet entrance: subject -> real grade-specific unit -> task.
/// Neither the enrolled grade nor existing progress is changed by browsing.
class LumoLearningHub extends StatefulWidget {
  const LumoLearningHub({
    super.key,
    required this.grade,
    required this.onStartUnit,
    required this.onReading,
    required this.onPracticalSubject,
  });

  final int grade;
  final void Function(String subject, String unit) onStartUnit;
  final VoidCallback onReading;
  final ValueChanged<String> onPracticalSubject;

  @override
  State<LumoLearningHub> createState() => _LumoLearningHubState();
}

class _Subject {
  const _Subject(this.name, this.description, this.icon, this.accent);
  final String name;
  final String description;
  final IconData icon;
  final Color accent;
}

class _LumoLearningHubState extends State<LumoLearningHub> {
  static const _main = <_Subject>[
    _Subject('Mathematik', 'Rechnen & Knobeln', Icons.calculate_rounded, Color(0xFFFFC04A)),
    _Subject('Deutsch', 'Sprache & Schreiben', Icons.menu_book_rounded, Color(0xFFD6A0FF)),
    _Subject('Englisch', 'Wörter & Sprechen', Icons.translate_rounded, Color(0xFF83D5FF)),
    _Subject('Sachunterricht', 'Die Welt entdecken', Icons.public_rounded, Color(0xFF70E3D4)),
  ];
  static const _other = <_Subject>[
    _Subject('Lesen', 'Texte verstehen', Icons.auto_stories_rounded, Color(0xFF86E8A1)),
    _Subject('Schreiben', 'Wörter gestalten', Icons.edit_rounded, Color(0xFFFF91BB)),
    _Subject('Logik', 'Rätsel lösen', Icons.psychology_alt_rounded, Color(0xFFB9A6FF)),
    _Subject('Musik', 'Hören & Musizieren', Icons.music_note_rounded, Color(0xFFB9A6FF)),
    _Subject('Kunst und Gestaltung', 'Kreativ werden', Icons.palette_rounded, Color(0xFFFF9E9E)),
    _Subject('Technik und Design', 'Erfinden & Bauen', Icons.handyman_rounded, Color(0xFF80DCE7)),
  ];
  _Subject? _selected;
  bool _expanded = false;

  void _choose(_Subject subject) {
    if (subject.name == 'Lesen') {
      widget.onReading();
    } else if (subject.name == 'Musik' ||
        subject.name == 'Kunst und Gestaltung' ||
        subject.name == 'Technik und Design') {
      widget.onPracticalSubject(subject.name);
    } else {
      setState(() => _selected = subject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grade = widget.grade.clamp(1, 4);
    final subject = _selected;
    final units = subject == null
        ? <String>[]
        : Curriculum.unitsForGrade(subject.name, grade, currentGradeOnly: true);
    final accessible = MediaQuery.textScalerOf(context).scale(1);
    return ListView(
      key: const PageStorageKey<String>('lumo-1992-learning-hub'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF112B50), Color(0xFF1C5571)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.55)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                subject == null ? 'Was möchtest du lernen?' : subject.name,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 23,
                    fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                subject == null
                    ? 'Ein Fach auswählen. Danach siehst du die passenden Themen.'
                    : 'Wähle ein Thema. Danach startet die echte Lernaufgabe.',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w700, color: Color(0xFFD4EAF5)),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('$grade. Klasse · aus deinem Profil',
                    key: const ValueKey('learning-profile-grade'),
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        if (subject == null) ...[
          const Text('Fächer', style: TextStyle(fontFamily: 'Nunito',
              fontSize: 18, fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white)),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 740 && accessible <= 1.3
                ? 4 : 2;
            final width = (constraints.maxWidth - (cols - 1) * 10) / cols;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final entry in _main)
                SizedBox(width: width, child: _subjectCard(entry)),
            ]);
          }),
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              key: const ValueKey('learning-other-subjects'),
              initiallyExpanded: _expanded,
              onExpansionChanged: (v) => setState(() => _expanded = v),
              title: const Text('Weitere Lernbereiche',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900, color: Colors.white)),
              subtitle: const Text('Lesen, Schreiben, Logik, Musik, Kunst und Technik',
                  style: TextStyle(color: Color(0xFFD4EAF5))),
              leading: const Icon(Icons.widgets_rounded,
                  color: LumoVisualTokens.cyanBright),
              children: [
                for (final entry in _other)
                  ListTile(
                    key: ValueKey('learning-extra-${entry.name}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: Icon(entry.icon, color: entry.accent),
                    title: Text(entry.name,
                        style: const TextStyle(fontFamily: 'Nunito',
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    subtitle: Text(entry.description,
                        style: const TextStyle(color: Color(0xFFD4EAF5))),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: LumoVisualTokens.cyanBright),
                    onTap: () => _choose(entry),
                    minVerticalPadding: 12,
                  ),
              ],
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            key: const ValueKey('learning-back-to-subjects'),
            onPressed: () => setState(() => _selected = null),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Alle Fächer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: LumoVisualTokens.cyanBright,
              minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 14),
          Text('Themen · ${subject.name}', style: const TextStyle(
            color: Colors.white, fontFamily: 'Nunito',
            fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 10),
          if (units.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Für dieses Fach sind noch keine Themen verfügbar.',
                  style: TextStyle(color: Colors.white)),
            ),
          for (final unit in units)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: const Color(0xFF132F50),
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  key: ValueKey('learning-unit-${subject.name}-$unit'),
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => widget.onStartUnit(subject.name, unit),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Icon(subject.icon, color: subject.accent, size: 26),
                      const SizedBox(width: 14),
                      Expanded(child: Text(Curriculum.prettifyUnit(unit),
                          style: const TextStyle(color: Colors.white,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800, fontSize: 15))),
                      const Icon(Icons.chevron_right_rounded,
                          color: LumoVisualTokens.cyanBright),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _subjectCard(_Subject subject) {
    return Material(
      color: const Color(0xFF142E4F),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('learning-subject-${subject.name}'),
        onTap: () => _choose(subject),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: subject.accent.withOpacity(.55)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(subject.icon, size: 30, color: subject.accent),
            const SizedBox(height: 7),
            Text(subject.name, maxLines: 2,
                style: const TextStyle(color: Colors.white,
                    fontFamily: 'Nunito', fontSize: 15,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subject.description, maxLines: 2,
                style: const TextStyle(color: Color(0xFFD4EAF5),
                    fontFamily: 'Nunito', fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
