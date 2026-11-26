import '../../domain/learning/skill_evidence.dart';
import 'package:flutter/material.dart';
import '../learning/learning_navigation.dart';

import '../../core/curriculum/learning_level.dart';
import '../../core/curriculum/math_unit_order.dart';
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
    this.navigation,
    this.tools,
  });

  final int grade;
  final LearningNavigation? navigation;
  final Widget? tools;

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
    _Subject('Mathematik', 'Rechnen & Knobeln', Icons.calculate_rounded,
        Color(0xFFFFC04A)),
    _Subject('Deutsch', 'Sprache & Schreiben', Icons.menu_book_rounded,
        Color(0xFFD6A0FF)),
    _Subject('Englisch', 'Wörter & Sprechen', Icons.translate_rounded,
        Color(0xFF83D5FF)),
    _Subject('Sachunterricht', 'Die Welt entdecken', Icons.public_rounded,
        Color(0xFF70E3D4)),
  ];
  static const _other = <_Subject>[
    _Subject('Lesen', 'Texte verstehen', Icons.auto_stories_rounded,
        Color(0xFF86E8A1)),
    _Subject('Rechtschreibung', 'Wörter sicher schreiben',
        Icons.spellcheck_rounded, Color(0xFFF4B4DA)),
    _Subject(
        'Schreiben', 'Wörter gestalten', Icons.edit_rounded, Color(0xFFFF91BB)),
    _Subject('Logik', 'Rätsel lösen', Icons.psychology_alt_rounded,
        Color(0xFFB9A6FF)),
    _Subject('Musik', 'Hören & Musizieren', Icons.music_note_rounded,
        Color(0xFFB9A6FF)),
    _Subject('Kunst und Gestaltung', 'Kreativ werden', Icons.palette_rounded,
        Color(0xFFFF9E9E)),
    _Subject('Technik und Design', 'Erfinden & Bauen', Icons.handyman_rounded,
        Color(0xFF80DCE7)),
    _Subject('Bewegung und Sport', 'Sicher bewegen',
        Icons.sports_gymnastics_rounded, Color(0xFF61E69A)),
    _Subject('Verkehrs- und Mobilitätsbildung', 'Sicher unterwegs',
        Icons.directions_walk_rounded, Color(0xFFFFC65C)),
  ];
  // Bright corner for art, deep corner behind the text (white >= 5.3:1).
  static const _cardColors = <String, (Color, Color)>{
    'Mathematik': (Color(0xFFF29A2E), Color(0xFFA9520A)),
    'Deutsch': (Color(0xFF9B5CF0), Color(0xFF7A3FD6)),
    'Englisch': (Color(0xFF3D8BF2), Color(0xFF2A66D3)),
    'Sachunterricht': (Color(0xFF22B597), Color(0xFF0C6E64)),
  };
  late final LearningNavigation _navigation =
      widget.navigation ?? LearningNavigation();
  _Subject? get _selected {
    for (final subject in [..._main, ..._other]) {
      if (subject.name == _navigation.subject) return subject;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _navigation.addListener(_navigationChanged);
  }

  void _navigationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _navigation.removeListener(_navigationChanged);
    if (widget.navigation == null) _navigation.dispose();
    super.dispose();
  }

  bool _expanded = false;

  /// Topics of the enrolled grade with at least one correct answer. The
  /// voluntary Lumo Expertenwelt is not part of the grade's school topics.
  (int, int) _topicProgress(String subject, int grade) {
    final units = LearningLevels.withoutExpert(subject,
        Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true),
        grade);
    final practiced = units
        .where((unit) => widget.skills.values.any((skill) =>
            skill.subject == subject &&
            skill.unit == unit &&
            skill.correct > 0))
        .length;
    return (practiced, units.length);
  }

  void _choose(_Subject subject) {
    if (subject.name == 'Musik' ||
        subject.name == 'Kunst und Gestaltung' ||
        subject.name == 'Technik und Design' ||
        subject.name == 'Bewegung und Sport' ||
        subject.name == 'Verkehrs- und Mobilitätsbildung') {
      widget.onPracticalSubject(subject.name);
    } else {
      _navigation.selectSubject(subject.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grade = _navigation.gradeFor(widget.grade);
    final subject = _selected;
    final availableUnits = subject == null
        ? <String>[]
        : Curriculum.unitsForGrade(subject.name, grade, currentGradeOnly: true);
    final units = subject?.name == 'Sachunterricht'
        ? <String>{
            ...Curriculum.subjects['Sachunterricht']!
                .where(availableUnits.contains),
            ...availableUnits,
          }
        : availableUnits;
    final accessible = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 460;
    final gradeStatus = Text(
      grade == widget.grade
          ? '$grade. Klasse · aus deinem Profil'
          : '$grade. Klasse · frei lernen',
      key: const ValueKey('learning-profile-grade'),
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: subject == null ? const Color(0xFFD4EAF5) : Colors.white,
      ),
    );
    return ListView(
      key: const PageStorageKey<String>('lumo-1992-learning-hub'),
      padding: EdgeInsets.fromLTRB(16, subject == null ? 12 : 16, 16, 36),
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
            padding: subject == null
                ? const EdgeInsets.fromLTRB(14, 10, 14, 10)
                : const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                            subject?.name ??
                                (compact
                                    ? 'Fach wählen'
                                    : 'Was möchtest du lernen?'),
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: subject == null && compact ? 18 : 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                          SizedBox(height: subject == null ? 4 : 12),
                          if (subject == null)
                            gradeStatus
                          else
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: gradeStatus,
                              ),
                            ),
                        ])),
                    if (subject == null && accessible <= 1.3)
                      ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Image(
                            key: const ValueKey('learning-hub-lumo'),
                            image: const AssetImage(
                                'assets/lumo_design/characters/fox_point.webp'),
                            width: compact ? 58 : 72,
                            height: compact ? 56 : 72,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ]),
                  if (subject == null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      for (var level = 1; level <= 4; level++) ...[
                        if (level > 1) const SizedBox(width: 6),
                        Expanded(
                            child: OutlinedButton(
                          key: ValueKey('grade-pill-$level'),
                          onPressed: () => _navigation.selectGrade(level),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            foregroundColor: grade == level
                                ? LumoVisualTokens.night
                                : Colors.white,
                            backgroundColor: grade == level
                                ? LumoVisualTokens.cyanBright
                                : Colors.white.withOpacity(.06),
                          ),
                          child: Text('$level. Klasse',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800)),
                        )),
                      ],
                    ]),
                  ],
                ]),
          ),
        ),
        SizedBox(height: subject == null ? 12 : 16),
        if (subject == null) ...[
          LayoutBuilder(builder: (context, constraints) {
            final cols =
                constraints.maxWidth >= 640 && accessible <= 1.3 ? 4 : 2;
            final width = (constraints.maxWidth - (cols - 1) * 10) / cols;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final entry in _main)
                SizedBox(
                  width: width,
                  child: _subjectCard(entry, grade, compact: width < 155),
                ),
            ]);
          }),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey('learning-advanced-entry'),
            onPressed: widget.onAdvanced,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Lernwerkzeuge & Geschichten'),
            style: OutlinedButton.styleFrom(
                foregroundColor: LumoVisualTokens.cyanBright,
                minimumSize: const Size.fromHeight(52)),
          ),
          if (widget.tools != null) ...[
            const SizedBox(height: 12),
            widget.tools!,
          ],
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
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              subtitle: const Text(
                  'Lesen, Rechtschreibung, Schreiben, Logik und kreative Fächer',
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
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
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
            onPressed: _navigation.backToSubjects,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Alle Fächer'),
            style: OutlinedButton.styleFrom(
                foregroundColor: LumoVisualTokens.cyanBright,
                minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 14),
          if (subject.name == 'Lesen') ...[
            FilledButton.icon(
              key: const ValueKey('learning-active-reading'),
              onPressed: widget.onReading,
              icon: const Icon(Icons.record_voice_over_rounded),
              label: const Text('Mit Lumo laut lesen'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 14),
          ],
          Text('Themen · ${subject.name}',
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
          const SizedBox(height: 10),
          if (units.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Für dieses Fach sind noch keine Themen verfügbar.',
                  style: TextStyle(color: Colors.white)),
            ),
          // One column for the whole register: the grouped list is short
          // enough to build at once, so every topic is reachable by scrolling
          // to it, also the ones at the end of the school order.
          // Mathematik in drei Ebenen: Schulwissen (in Schulbuch-Gruppen),
          // Vertiefung und die freiwillige Lumo Expertenwelt.
          if (subject.name == 'Mathematik')
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (level, levelUnits)
                    in LearningLevels.grouped(subject.name, units, grade)) ...[
                  _levelHeader(level, grade),
                  if (level == LumoLearningLevel.schulwissen)
                    for (final (group, groupUnits)
                        in MathUnitOrder.grouped(levelUnits)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                        child: Text(group,
                            key: ValueKey('learning-unit-group-$group'),
                            style: const TextStyle(
                                color: LumoVisualTokens.cyanBright,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ),
                      for (final unit in groupUnits)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _unitCard(subject, unit),
                        ),
                    ]
                  else
                    for (final unit in levelUnits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _unitCard(subject, unit, level: level),
                      ),
                ],
              ],
            )
          else
            for (final unit in units)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _unitCard(subject, unit),
              ),
        ],
      ],
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  /// The child's saved record for one topic, or null if never answered.
  SkillRecord? _skillFor(String subject, String unit) {
    for (final skill in widget.skills.values) {
      if (skill.subject == subject && skill.unit == unit) return skill;
    }
    return null;
  }

  /// Überschrift einer Lernebene mit kurzer Erklärung für Kind und Eltern.
  Widget _levelHeader(LumoLearningLevel level, int grade) {
    final expert = level == LumoLearningLevel.expertenwelt;
    final color =
        expert ? const Color(0xFFFFD36B) : LumoVisualTokens.cyanBright;
    final title = level == LumoLearningLevel.schulwissen
        ? '${level.title} · $grade. Klasse'
        : level.title;
    return Semantics(
      header: true,
      label: '$title. ${level.description}',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('learning-level-${level.name}'),
        margin: const EdgeInsets.fromLTRB(0, 14, 0, 4),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.55)),
        ),
        child: Row(children: [
          Icon(
              switch (level) {
                LumoLearningLevel.schulwissen => Icons.school_rounded,
                LumoLearningLevel.vertiefung => Icons.trending_up_rounded,
                LumoLearningLevel.expertenwelt => Icons.auto_awesome_rounded,
              },
              color: color,
              size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(level.description,
                    style: const TextStyle(
                        color: Color(0xFFE2F1FF),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _unitCard(_Subject subject, String unit,
      {LumoLearningLevel level = LumoLearningLevel.schulwissen}) {
    final (bright, deep) =
        _cardColors[subject.name] ?? (subject.accent, const Color(0xFF142E4F));
    final record = _skillFor(subject.name, unit);
    final practiced = record != null && record.attempts > 0;
    final title = Curriculum.prettifyUnit(unit);
    final isMath = subject.name == 'Mathematik';
    final example = isMath ? MathUnitOrder.exampleOf(unit) : null;
    final symbol = isMath ? MathUnitOrder.symbolOf(unit) : null;
    final icon = switch ((subject.name, unit)) {
      ('Sachunterricht', 'Tiere') => Icons.pets_rounded,
      ('Sachunterricht', 'Pflanzen') => Icons.park_rounded,
      _ => subject.icon,
    };
    // No percentage: a stage that is backed by counted answers. "Sicher"
    // needs enough tasks solved alone on at least two different days.
    final evidence = record?.evidence;
    final status = practiced
        ? '${_capitalized(evidence!.label)} · ${evidence.facts}'
        : 'Noch nicht geübt';
    final evidenceShare = evidence == null
        ? 0.0
        : evidence.isSecure
            ? 1.0
            : (evidence.independentCorrect /
                    (SkillEvidence.secureIndependentCorrect + 1))
                .clamp(0.0, .86);
    final badge = switch (level) {
      LumoLearningLevel.schulwissen => null,
      LumoLearningLevel.vertiefung => 'Vertiefung',
      LumoLearningLevel.expertenwelt => 'Lumo Expertenwelt · freiwillig',
    };
    return Semantics(
      label: badge == null ? '$title\n$status' : '$title\n$badge\n$status',
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
                  child: symbol == null
                      ? Icon(icon, color: Colors.white, size: 25)
                      : Center(
                          child: Text(symbol,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  if (badge != null)
                    Text(badge,
                        key: ValueKey(
                            'learning-unit-level-${subject.name}-$unit'),
                        style: TextStyle(
                            color: level == LumoLearningLevel.expertenwelt
                                ? const Color(0xFFFFD36B)
                                : LumoVisualTokens.cyanBright,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  if (example != null)
                    Text(example,
                        key: ValueKey(
                            'learning-unit-example-${subject.name}-$unit'),
                        style: const TextStyle(
                            color: Color(0xFFE2F1FF),
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5)),
                  const SizedBox(height: 3),
                  Text(status,
                      key: ValueKey(
                          'learning-unit-progress-${subject.name}-$unit'),
                      style: TextStyle(
                          color: practiced
                              ? const Color(0xFFFFF3C4)
                              : const Color(0xFFB8CFE0),
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  if (practiced) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        // Tasks solved alone on the way to "sicher"; the
                        // bar is only full once that stage is reached.
                        value: evidenceShare,
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

  Widget _subjectCard(_Subject subject, int grade, {required bool compact}) {
    final (bright, deep) =
        _cardColors[subject.name] ?? (subject.accent, const Color(0xFF142E4F));
    final (practiced, total) = _topicProgress(subject.name, grade);
    final status = practiced == 0
        ? 'Noch nicht begonnen'
        : '$practiced von $total Themen geübt';
    const shadow = [
      Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 1))
    ];
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
                BoxShadow(
                    color: deep.withOpacity(.55),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 150),
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12, vertical: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: FittedBox(
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
                    Text(subject.name,
                        maxLines: 2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            shadows: shadow)),
                    const SizedBox(height: 2),
                    Text(subject.description,
                        maxLines: 2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            shadows: shadow)),
                    const SizedBox(height: 6),
                    Text(status,
                        maxLines: 2,
                        key: ValueKey(
                            'learning-subject-progress-${subject.name}'),
                        style: const TextStyle(
                            color: Color(0xFFFFF3C4),
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            shadows: shadow)),
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
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}
