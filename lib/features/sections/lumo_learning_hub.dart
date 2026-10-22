import 'package:flutter/material.dart';

import '../../core/progress_repository.dart';
import '../../core/school_exercise_generator.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../teacher_mode/widgets/academy_subject_art.dart';

/// A deliberately quiet entrance: subject -> real grade-specific unit -> task.
/// Neither the enrolled grade nor existing progress is changed by browsing.
class LumoLearningHub extends StatefulWidget {
  const LumoLearningHub({
    super.key,
    required this.grade,
    required this.onStartUnit,
    required this.onReading,
    required this.onPracticalSubject,
    required this.onAdvanced,
    this.skills = const {},
  });

  final int grade;
  /// The child's real answer records; drives each subject's topic ring.
  final Map<String, SkillRecord> skills;
  final void Function(String subject, String unit) onStartUnit;
  final VoidCallback onReading;
  final ValueChanged<String> onPracticalSubject;
  final VoidCallback onAdvanced;

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
  // Bright corner for art, deep corner behind the text (white >= 5.3:1).
  static const _cardColors = <String, (Color, Color)>{
    'Mathematik': (Color(0xFFF29A2E), Color(0xFFA9520A)),
    'Deutsch': (Color(0xFF9B5CF0), Color(0xFF7A3FD6)),
    'Englisch': (Color(0xFF3D8BF2), Color(0xFF2A66D3)),
    'Sachunterricht': (Color(0xFF22B597), Color(0xFF0C6E64)),
  };
  _Subject? _selected;
  bool _expanded = false;

  /// Topics of the enrolled grade with at least one correct answer.
  (int, int) _topicProgress(String subject, int grade) {
    final units = Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true);
    final practiced = units
        .where((unit) => widget.skills.values.any((skill) =>
            skill.subject == subject && skill.unit == unit && skill.correct > 0))
        .length;
    return (practiced, units.length);
  }

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
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              ])),
              if (subject == null &&
                  MediaQuery.sizeOf(context).width >= 360 &&
                  accessible <= 1.3)
                const ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Image(
                      key: ValueKey('learning-hub-lumo'),
                      image: AssetImage(
                          'assets/lumo_design/characters/fox_point.webp'),
                      width: 89,
                      height: 112,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
            ]),
            // Other grades and all learning paths belong with the grade, and
            // stay reachable without scrolling past the subject cards.
            if (subject == null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('learning-advanced-entry'),
                onPressed: widget.onAdvanced,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Alle Lernwege & andere Klassen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LumoVisualTokens.cyanBright,
                  minimumSize: const Size.fromHeight(52)),
              ),
            ],
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
                SizedBox(width: width, child: _subjectCard(entry, grade)),
            ]);
          }),
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              key: const PageStorageKey<String>('learning-other-subjects'),
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
              child: _unitCard(subject, unit),
            ),
        ],
      ],
    );
  }

  /// The child's saved record for one topic, or null if never answered.
  SkillRecord? _skillFor(String subject, String unit) {
    for (final skill in widget.skills.values) {
      if (skill.subject == subject && skill.unit == unit) return skill;
    }
    return null;
  }

  Widget _unitCard(_Subject subject, String unit) {
    final (bright, deep) = _cardColors[subject.name] ??
        (subject.accent, const Color(0xFF142E4F));
    final record = _skillFor(subject.name, unit);
    final practiced = record != null && record.attempts > 0;
    final mastery = record?.mastery ?? 0;
    final title = Curriculum.prettifyUnit(unit);
    final status = practiced
        ? '${record.correct} richtig · $mastery % sicher'
        : 'Noch nicht geübt';
    return Semantics(
      label: '$title\n$status',
      button: true,
      onTap: () => widget.onStartUnit(subject.name, unit),
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF132F50),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          key: ValueKey('learning-unit-${subject.name}-$unit'),
          borderRadius: BorderRadius.circular(17),
          onTap: () => widget.onStartUnit(subject.name, unit),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: bright.withOpacity(.45)),
            ),
            child: Row(children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [bright, deep],
                  ),
                ),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(subject.icon, color: Colors.white, size: 25),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(color: Colors.white,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(status,
                      key: ValueKey('learning-unit-progress-${subject.name}-$unit'),
                      style: TextStyle(
                          color: practiced
                              ? const Color(0xFFFFF3C4)
                              : const Color(0xFFB8CFE0),
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700, fontSize: 12)),
                  if (practiced) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: mastery / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(.14),
                        valueColor: AlwaysStoppedAnimation(bright),
                      ),
                    ),
                  ],
                ],
              )),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: LumoVisualTokens.cyanBright),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _subjectCard(_Subject subject, int grade) {
    final (bright, deep) = _cardColors[subject.name] ??
        (subject.accent, const Color(0xFF142E4F));
    final (practiced, total) = _topicProgress(subject.name, grade);
    final status = practiced == 0
        ? 'Noch nicht begonnen'
        : '$practiced von $total Themen geübt';
    const shadow = [Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 1))];
    // One accessible button: name, description and real progress, one per
    // line like Flutter's own merged captions, with the card's tap action.
    return Semantics(
      label: '${subject.name}\n${subject.description}\n$status',
      button: true,
      onTap: () => _choose(subject),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('learning-subject-${subject.name}'),
          onTap: () => _choose(subject),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [bright, deep, deep],
                stops: const [0, .55, 1],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(.35)),
              boxShadow: [
                BoxShadow(color: deep.withOpacity(.55), blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 150),
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: AcademySubjectArt(
                      subjectName: subject.name,
                      subjectId: 'hub-${subject.name}',
                      accent: Colors.white,
                    ),
                  )),
                  const SizedBox(width: 6),
                  _TopicRing(practiced: practiced, total: total),
                ]),
                const SizedBox(height: 10),
                Text(subject.name, maxLines: 2,
                    style: const TextStyle(color: Colors.white,
                        fontFamily: 'Nunito', fontSize: 17,
                        fontWeight: FontWeight.w900, shadows: shadow)),
                const SizedBox(height: 2),
                Text(subject.description, maxLines: 2,
                    style: const TextStyle(color: Colors.white,
                        fontFamily: 'Nunito', fontSize: 12,
                        fontWeight: FontWeight.w700, shadows: shadow)),
                const SizedBox(height: 6),
                Text(status, maxLines: 2,
                    key: ValueKey('learning-subject-progress-${subject.name}'),
                    style: const TextStyle(color: Color(0xFFFFF3C4),
                        fontFamily: 'Nunito', fontSize: 12,
                        fontWeight: FontWeight.w800, shadows: shadow)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static ring (no ticker): practiced topics of the enrolled grade.
class _TopicRing extends StatelessWidget {
  const _TopicRing({required this.practiced, required this.total});
  final int practiced;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : practiced / total;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(.28),
      ),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: Colors.white.withOpacity(.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          Text('${(value * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
                  fontSize: 12, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

