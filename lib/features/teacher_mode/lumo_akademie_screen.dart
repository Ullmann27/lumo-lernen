// ════════════════════════════════════════════════════════════════════════
// LUMO AKADEMIE — Lehrer-Modus mit Klassen-Pyramide
// ════════════════════════════════════════════════════════════════════════
// Heinz: 'Lernmodus mit ChatGPT verbunden, gezielt nach Kategorie,
// Strategie wie kleine Kinder das lernen, Lumo als Lehrer.'
//
// Aufbau:
//   1. Klassen-Picker (1-4 Volksschule)
//   2. Pro Klasse: Fach-Auswahl (Mathe/Deutsch/Sachkunde)
//   3. Pro Fach: Themen-Liste mit Progression (1-10, 10-20, etc.)
//   4. Pro Thema: Lumo erklärt + Übung
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../core/school_exercise_generator.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../learning/learning_content.dart';
import '../learning_modules/learning_module_registry.dart';

// Datenstruktur für Lehrpläne
class LearningTopic {
  const LearningTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.shortDesc,
    this.isWriting = false,
    this.writingChars = const [],
    // ── Detaillierte Lehrplan-Inhalte (fuer ChatGPT-Prompt) ──
    this.detailedScope = '',
    this.exampleTask = '',
    this.coreVocabulary = const [],
    this.forbiddenContent = '',
    this.complexityHint = '',
    this.subjectKey = '',
    this.unitKey = '',
  });
  final String id;
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final String shortDesc;
  final bool isWriting;
  final List<String> writingChars;

  /// Was genau in diesem Topic gelernt wird - sehr konkret.
  /// Beispiel: 'Bruchrechnen: Brueche kennen lernen (1/2, 1/3, 1/4),
  /// Brueche aus Bildern ablesen, einfache Vergleiche.'
  final String detailedScope;

  /// Konkretes Beispiel-Task wie ChatGPT antworten soll.
  final String exampleTask;

  /// Schluesselwoerter die ChatGPT VERWENDEN soll.
  final List<String> coreVocabulary;

  /// Was NICHT angesprochen werden darf.
  final String forbiddenContent;

  /// Hinweis zur Klassenstufe.
  final String complexityHint;

  /// Lokaler Generator-Schluessel. Themen ohne Spezialmodul werden damit
  /// direkt als echte Aufgabenserie gestartet – niemals als Chat-Fallback.
  final String subjectKey;
  final String unitKey;
}

class LearningSubject {
  const LearningSubject({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.topics,
  });
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final List<LearningTopic> topics;
}

class GradeLevel {
  const GradeLevel({
    required this.grade,
    required this.title,
    required this.subtitle,
    required this.ageRange,
    required this.color,
    required this.subjects,
  });
  final int grade;
  final String title;
  final String subtitle;
  final String ageRange;
  final Color color;
  final List<LearningSubject> subjects;
}

// ── LEHRPLAN-DEFINITIONEN ──────────────────────────────────────────────
class LumoCurriculum {
  static List<GradeLevel> get grades =>
      <GradeLevel>[for (var grade = 1; grade <= 4; grade++) _grade(grade)];

  static GradeLevel _grade(int grade) => GradeLevel(
        grade: grade,
        title: '$grade. Klasse',
        subtitle: switch (grade) {
          1 => 'Grundlagen entdecken',
          2 => 'Sicher aufbauen',
          3 => 'Wissen vertiefen',
          _ => 'Volksschule meistern',
        },
        ageRange: switch (grade) {
          1 => '6–7 Jahre',
          2 => '7–8 Jahre',
          3 => '8–9 Jahre',
          _ => '9–10 Jahre',
        },
        color: switch (grade) {
          1 => LumoColors.teal,
          2 => LumoColors.purple,
          3 => LumoColors.blue,
          _ => LumoColors.orange,
        },
        subjects: <LearningSubject>[
          _subject(grade, 'Mathematik', 'Mathematik', LumoColors.math,
              Icons.calculate_rounded),
          _subject(grade, 'Deutsch', 'Deutsch', LumoColors.german,
              Icons.menu_book_rounded),
          _subject(grade, 'Lesen', 'Lesen', LumoColors.teal,
              Icons.auto_stories_rounded),
          _subject(grade, 'Schreiben', 'Schreiben', LumoColors.purple,
              Icons.draw_rounded),
          _subject(grade, 'Rechtschreibung', 'Rechtschreibung',
              const Color(0xFFB52E73), Icons.spellcheck_rounded),
          _subject(grade, 'Englisch', 'Englisch', const Color(0xFF167BC0),
              Icons.public_rounded),
          _subject(grade, 'Sachunterricht', 'Sachkunde',
              const Color(0xFF167A84), Icons.eco_rounded),
          _subject(grade, 'Logik', 'Logik', const Color(0xFF6D4CC7),
              Icons.psychology_alt_rounded),
        ],
      );

  static LearningSubject _subject(
    int grade,
    String subjectKey,
    String displayName,
    Color color,
    IconData icon,
  ) {
    final units = Curriculum.unitsForGrade(
      subjectKey,
      grade,
      currentGradeOnly: true,
    );
    return LearningSubject(
      id: '${_slug(subjectKey)}$grade',
      name: displayName,
      color: color,
      icon: icon,
      topics: <LearningTopic>[
        for (final unit in units)
          LearningTopic(
            id: _topicId(grade, subjectKey, unit),
            title: Curriculum.prettifyUnit(unit),
            icon: _topicIcon(subjectKey, unit),
            gradient: _topicGradient(subjectKey),
            shortDesc: _topicDescription(grade, subjectKey, unit),
            subjectKey: subjectKey,
            unitKey: unit,
          ),
      ],
    );
  }

  static String _topicId(int grade, String subject, String unit) {
    final key = '$grade|$subject|$unit';
    const special = <String, String>{
      '1|Mathematik|Plus bis 10': 'm1_plus10',
      '1|Mathematik|Minus bis 10': 'm1_minus10',
      '1|Mathematik|Geometrie Formen': 'm1_formen',
      '1|Sachunterricht|Tiere': 's1_tiere',
      '2|Mathematik|Einmaleins Vorbereitung': 'm2_einmaleins',
      '2|Mathematik|Geld': 'm2_geld',
      '2|Mathematik|Zeit': 'm2_uhr',
      '2|Mathematik|Uhrzeit': 'm2_uhr',
      '2|Deutsch|Artikel': 'd2_artikel',
      '2|Deutsch|Einzahl und Mehrzahl': 'd2_mehrzahl',
      '2|Sachunterricht|Jahreszeiten': 's2_jahreszeiten',
      '2|Sachunterricht|Wetter': 's2_wetter',
      '2|Sachunterricht|Verkehr': 's2_verkehr',
      '3|Mathematik|Einmaleins': 'm3_einmaleins_voll',
      '3|Deutsch|Wortarten': 'd3_wortarten',
      '3|Deutsch|Zeitformen': 'd3_zeitformen',
      '4|Mathematik|Bruchrechnen einfach': 'm4_bruch',
    };
    return special[key] ?? 'task_${grade}_${_slug(subject)}_${_slug(unit)}';
  }

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static List<Color> _topicGradient(String subject) => switch (subject) {
        'Mathematik' => const <Color>[Color(0xFFD67920), Color(0xFFF3A43B)],
        'Deutsch' => const <Color>[Color(0xFF5F2FBE), Color(0xFF8A63E6)],
        'Lesen' => const <Color>[Color(0xFF167A84), Color(0xFF35A7B0)],
        'Schreiben' => const <Color>[Color(0xFF8E3D9D), Color(0xFFB85FC7)],
        'Rechtschreibung' =>
          const <Color>[Color(0xFFB52E73), Color(0xFFE35A9B)],
        'Englisch' => const <Color>[Color(0xFF167BC0), Color(0xFF43A7E8)],
        'Sachunterricht' =>
          const <Color>[Color(0xFF16845D), Color(0xFF43B889)],
        _ => const <Color>[Color(0xFF6D4CC7), Color(0xFF9278E2)],
      };

  static IconData _topicIcon(String subject, String unit) {
    final u = unit.toLowerCase();
    if (u.contains('plus')) return Icons.add_circle_rounded;
    if (u.contains('minus')) return Icons.remove_circle_rounded;
    if (u.contains('mal') || u.contains('einmaleins')) {
      return Icons.close_rounded;
    }
    if (u.contains('division') || u.contains('teilen')) {
      return Icons.percent_rounded;
    }
    if (u.contains('bruch')) return Icons.pie_chart_rounded;
    if (u.contains('geld')) return Icons.euro_rounded;
    if (u.contains('zeit') || u.contains('uhr')) return Icons.schedule_rounded;
    if (u.contains('geometr') || u.contains('form')) {
      return Icons.category_rounded;
    }
    if (u.contains('lesen') || subject == 'Lesen') {
      return Icons.auto_stories_rounded;
    }
    if (u.contains('schreib') || subject == 'Schreiben') {
      return Icons.edit_rounded;
    }
    if (subject == 'Englisch') return Icons.language_rounded;
    if (subject == 'Sachunterricht') return Icons.explore_rounded;
    if (subject == 'Logik') return Icons.extension_rounded;
    return Icons.school_rounded;
  }

  static String _topicDescription(int grade, String subject, String unit) {
    final pretty = Curriculum.prettifyUnit(unit);
    if (subject == 'Mathematik') {
      return '$grade. Klasse · $pretty gezielt üben';
    }
    if (subject == 'Lesen') {
      return '$grade. Klasse · lesen, verstehen und antworten';
    }
    if (subject == 'Schreiben') {
      return '$grade. Klasse · sicher schreiben und festigen';
    }
    if (subject == 'Rechtschreibung') {
      return '$grade. Klasse · Rechtschreibung Schritt für Schritt';
    }
    if (subject == 'Englisch') {
      return '$grade. Klasse · Wortschatz spielerisch trainieren';
    }
    if (subject == 'Sachunterricht') {
      return '$grade. Klasse · Wissen entdecken und prüfen';
    }
    if (subject == 'Logik') {
      return '$grade. Klasse · denken, ordnen und kombinieren';
    }
    return '$grade. Klasse · $pretty mit echten Aufgaben';
  }
}

// ════════════════════════════════════════════════════════════════════════
// HAUPT-SCREEN: LUMO AKADEMIE
// ════════════════════════════════════════════════════════════════════════

class LumoAkademieScreen extends StatefulWidget {
  const LumoAkademieScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoAkademieScreen> createState() => _LumoAkademieScreenState();
}

class _LumoAkademieScreenState extends State<LumoAkademieScreen>
    with TickerProviderStateMixin {
  static const _learningAreas = <_LearningArea>[
    _LearningArea(
      title: 'Mathe',
      subject: 'Mathematik',
      subtitle: 'Rechnen, Größen und Geometrie',
      icon: Icons.calculate_rounded,
      color: LumoVisualTokens.learning,
      curriculumIndex: 0,
    ),
    _LearningArea(
      title: 'Deutsch',
      subject: 'Deutsch',
      subtitle: 'Grammatik, Wörter und Sätze',
      icon: Icons.menu_book_rounded,
      color: LumoVisualTokens.games,
      curriculumIndex: 1,
    ),
    _LearningArea(
      title: 'Lesen',
      subject: 'Lesen',
      subtitle: 'Lesen und wirklich verstehen',
      icon: Icons.auto_stories_rounded,
      color: LumoVisualTokens.tests,
      curriculumIndex: 2,
    ),
    _LearningArea(
      title: 'Schreiben',
      subject: 'Schreiben',
      subtitle: 'Schreiben sicher aufbauen',
      icon: Icons.draw_rounded,
      color: LumoVisualTokens.rewards,
      curriculumIndex: 3,
    ),
    _LearningArea(
      title: 'Rechtschreibung',
      subject: 'Rechtschreibung',
      subtitle: 'Wörter und Regeln festigen',
      icon: Icons.spellcheck_rounded,
      color: Color(0xFFB52E73),
      curriculumIndex: 4,
    ),
    _LearningArea(
      title: 'Englisch',
      subject: 'Englisch',
      subtitle: 'Wortschatz passend zur Klasse',
      icon: Icons.public_rounded,
      color: Color(0xFF167BC0),
      curriculumIndex: 5,
    ),
    _LearningArea(
      title: 'Sachkunde',
      subject: 'Sachunterricht',
      subtitle: 'Natur, Österreich und Welt',
      icon: Icons.eco_rounded,
      color: Color(0xFF167A84),
      curriculumIndex: 6,
    ),
    _LearningArea(
      title: 'Logik',
      subject: 'Logik',
      subtitle: 'Muster und Denken',
      icon: Icons.psychology_alt_rounded,
      color: Color(0xFF6D4CC7),
      curriculumIndex: 7,
    ),
  ];

  late final AnimationController _heroCtrl;
  int _selectedGrade = 1;
  int _selectedSubjectIndex = 0;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _selectedGrade = widget.appState.state.grade.clamp(1, 4);
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  GradeLevel get _currentGrade =>
      LumoCurriculum.grades.firstWhere((g) => g.grade == _selectedGrade);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.learning,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── HERO BANNER ────────────────────────────────────
              SliverToBoxAdapter(child: _buildHero()),
              SliverToBoxAdapter(child: _buildGoals()),
              // ── KLASSEN-SELECTOR ───────────────────────────────
              SliverToBoxAdapter(child: _buildGradePicker()),
              SliverToBoxAdapter(child: _buildLearningAreas()),
              // ── FACH-KACHELN ───────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: _buildSubjectSection(
                    _currentGrade.subjects[_selectedSubjectIndex],
                    _selectedSubjectIndex,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildContinueBanner()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _heroCtrl,
      builder: (_, __) {
        final v = Curves.easeOutCubic.transform(_heroCtrl.value);
        return Transform.translate(
          offset: Offset(0, (1 - v) * 30),
          child: Opacity(opacity: v, child: _heroContent()),
        );
      },
    );
  }

  Widget _heroContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          margin: EdgeInsets.fromLTRB(
            compact ? 12 : 20,
            compact ? 12 : 16,
            compact ? 12 : 20,
            12,
          ),
          child: LumoGlassCard(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              compact ? 14 : 18,
              compact ? 8 : 10,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_rounded,
                              color: LumoVisualTokens.cyan, size: 20),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'LUMO AKADEMIE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: LumoVisualTokens.cyanBright,
                                fontSize: compact ? 10 : 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: compact ? .4 : 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lernen',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: compact ? 26 : 30,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Heute lernen. Morgen mehr können!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                LumoFoxPose(
                  pose: LumoDesignFoxPose.tabletThumb,
                  size: compact ? 76 : 124,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoals() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final done = widget.appState.learningDailyDone();
          final goal = widget.appState.state.settings.dailyGoal.clamp(1, 500);
          final progress = (done / goal).clamp(0.0, 1.0).toDouble();
          return LumoGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.track_changes_rounded,
                    color: LumoVisualTokens.cyanBright, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deine Ziele',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$done von $goal Aufgaben geschafft',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: LumoVisualTokens.navigation,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              LumoVisualTokens.cyanBright),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right_rounded,
                    color: LumoVisualTokens.cyanBright, size: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueBanner() {
    final subject = _currentGrade.subjects[_selectedSubjectIndex];
    if (subject.topics.isEmpty) return const SizedBox.shrink();

    final subjectKey = subject.topics.first.subjectKey.isEmpty
        ? (subject.name == 'Sachkunde' ? 'Sachunterricht' : subject.name)
        : subject.topics.first.subjectKey;
    final lastUnit = widget.appState.learningProfile.lastTopics[subjectKey];
    final lastIndex = lastUnit == null
        ? -1
        : subject.topics.indexWhere((topic) => topic.unitKey == lastUnit);
    final hasCurrentHistory = lastIndex >= 0;
    final topic = hasCurrentHistory
        ? subject.topics[lastIndex]
        : subject.topics.first;

    final title = hasCurrentHistory ? 'Weiterlernen' : 'Lumo empfiehlt';
    final subtitle = hasCurrentHistory
        ? '${topic.title} · $_selectedGrade. Klasse'
        : 'Starte mit ${topic.title} · passend zur $_selectedGrade. Klasse';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openTopic(topic, subject),
          child: LumoGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            borderColor: LumoVisualTokens.cyan.withOpacity(.55),
            child: Row(
              children: [
                LumoFoxPose(
                  pose: hasCurrentHistory
                      ? LumoDesignFoxPose.cheer
                      : LumoDesignFoxPose.teacherStick,
                  size: 82,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: LumoVisualTokens.cyanBright,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearningAreas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              '2. Fach wählen',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 3 : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _learningAreas
                    .map((area) => SizedBox(
                          width: width,
                          height: 154,
                          child: _buildLearningAreaTile(area),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLearningAreaTile(_LearningArea area) {
    final skills = widget.appState.learningSkills().values.where((skill) =>
        skill.subject.trim().toLowerCase() == area.subject.toLowerCase());
    final skillList = skills.toList();
    final completed =
        skillList.fold<int>(0, (sum, skill) => sum + skill.correct);
    final mastery = skillList.isEmpty
        ? 0
        : (skillList.fold<int>(0, (sum, skill) => sum + skill.mastery) ~/
            skillList.length);
    final subtitle = skillList.isEmpty
        ? '${area.subtitle} · Noch keine Lernwerte'
        : '${area.subtitle} · $completed richtig';

    return Stack(
      children: [
        Positioned.fill(
          child: LumoColorTile(
            icon: area.icon,
            title: area.title,
            subtitle: subtitle,
            color: area.color,
            onTap: () {
              final curriculumIndex = area.curriculumIndex;
              if (curriculumIndex != null) {
                setState(() => _selectedSubjectIndex = curriculumIndex);
                return;
              }
              final section = area.section!;
              final reading = section == LumoSection.reading;
              widget.appState.update(widget.appState.state.copyWith(
                section: section,
                subject: area.subject,
                unit: reading ? 'Aktives Lesen' : 'Alle',
                mood: reading ? LumoMood.think : LumoMood.point,
                lumoMessage: reading
                    ? 'Lies laut vor.\nIch höre dir zu\nund helfe freundlich.'
                    : '${area.title}\nist bereit.\nStarten wir!',
              ));
            },
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Semantics(
            label: '$mastery Prozent gemeistert',
            child: IgnorePointer(
              child: SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: mastery / 100,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withOpacity(.28),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          LumoVisualTokens.cyanBright),
                    ),
                    Text(
                      '$mastery%',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 0, 0, 12),
            child: Text(
              '1. Klasse wählen',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white,
              ),
            ),
          ),
          SizedBox(
            height:
                110 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: LumoCurriculum.grades.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildGradeChip(LumoCurriculum.grades[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeChip(GradeLevel g) {
    final isSelected = g.grade == _selectedGrade;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedGrade = g.grade;
        _selectedSubjectIndex = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 130,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    LumoVisualTokens.cyan,
                    LumoVisualTokens.cyan.withOpacity(0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : LumoVisualTokens.glass.withOpacity(0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? LumoVisualTokens.cyanBright
                : LumoVisualTokens.cyan.withOpacity(0.48),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LumoVisualTokens.cyan.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${g.grade}.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? LumoVisualTokens.night
                    : LumoVisualTokens.cyanBright,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              g.title,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? LumoVisualTokens.night
                    : LumoVisualTokens.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              g.ageRange,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? LumoVisualTokens.night.withOpacity(0.72)
                    : LumoVisualTokens.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSection(LearningSubject s, int idx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 0, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: s.color.withOpacity(0.7)),
                  ),
                  child: Icon(s.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  s.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${s.topics.length} Themen',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LumoVisualTokens.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Row(
            children: [
              Icon(
                Icons.looks_3_rounded,
                color: LumoVisualTokens.cyanBright,
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'Themenbereich wählen',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: LumoVisualTokens.cyanBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._topicBuckets(s).asMap().entries.map(
                (entry) => _buildTopicBucket(
                  entry.value,
                  s,
                  initiallyExpanded: entry.key == 0,
                ),
              ),
        ],
      ),
    );
  }

  List<_TopicBucket> _topicBuckets(LearningSubject subject) {
    final grouped = <String, List<LearningTopic>>{};
    final order = <String>[];

    void add(String title, LearningTopic topic) {
      if (!grouped.containsKey(title)) {
        grouped[title] = <LearningTopic>[];
        order.add(title);
      }
      grouped[title]!.add(topic);
    }

    for (final topic in subject.topics) {
      final raw = (topic.unitKey.isEmpty ? topic.title : topic.unitKey)
          .toLowerCase();

      final group = switch (subject.name) {
        'Mathematik' => raw.contains('textauf') ||
                raw.contains('sachauf')
            ? 'Sachaufgaben'
            : raw.contains('einmaleins') ||
                    raw.contains('multiplik') ||
                    raw.contains('division') ||
                    raw.contains('geteilt')
                ? 'Mal & Teilen'
                : raw.contains('geld') ||
                        raw.contains('länge') ||
                        raw.contains('massen') ||
                        raw.contains('zeit') ||
                        raw.contains('uhr') ||
                        raw.contains('liter') ||
                        raw.contains('milliliter')
                    ? 'Größen & Alltag'
                    : raw.contains('geometr') ||
                            raw.contains('form') ||
                            raw.contains('symmetr') ||
                            raw.contains('umfang') ||
                            raw.contains('fläche') ||
                            raw.contains('diagramm')
                        ? 'Formen & Daten'
                        : raw.contains('bruch') ||
                                raw.contains('dezimal') ||
                                raw.contains('mittelwert')
                            ? 'Brüche & Dezimalzahlen'
                            : 'Zahlen & Rechnen',
        'Deutsch' => raw.contains('satz') ||
                raw.contains('direkte rede') ||
                raw.contains('komma') ||
                raw.contains('zusammensetz')
            ? 'Sätze & Sprache'
            : raw.contains('wortart') ||
                    raw.contains('namen') ||
                    raw.contains('tunwo') ||
                    raw.contains('wiewo') ||
                    raw.contains('fall') ||
                    raw.contains('verbform') ||
                    raw.contains('zeitform') ||
                    raw.contains('steiger')
                ? 'Grammatik'
                : raw.contains('groß') ||
                        raw.contains('ie oder i') ||
                        raw.contains('dass') ||
                        raw.contains('st oder sp')
                    ? 'Rechtschreibung'
                    : 'Wörter & Wortschatz',
        'Lesen' => raw.contains('schluss') ||
                raw.contains('information')
            ? 'Informationen & Schlüsse'
            : raw.contains('kern') || raw.contains('textart')
                ? 'Textaufbau verstehen'
                : 'Lesen & Verstehen',
        'Schreiben' => raw.contains('text plan') ||
                raw.contains('geschichte') ||
                raw.contains('beschreibung') ||
                raw.contains('meinung') ||
                raw.contains('informationstext')
            ? 'Texte planen & verfassen'
            : raw.contains('satz') || raw.contains('nachricht')
                ? 'Sätze & Nachrichten'
                : 'Schreib-Grundlagen',
        'Rechtschreibung' => raw.contains('satz') ||
                raw.contains('komma') ||
                raw.contains('dass')
            ? 'Sätze richtig schreiben'
            : raw.contains('doppel') ||
                    raw.contains('dehnung') ||
                    raw.contains('ie oder i') ||
                    raw.contains('st oder sp') ||
                    raw.contains('wortstamm') ||
                    raw.contains('wortende')
                ? 'Rechtschreib-Regeln'
                : 'Wortbilder & Großschreibung',
        'Englisch' => raw.contains('famil') ||
                raw.contains('begr') ||
                raw.contains('zahlen') ||
                raw.contains('farben') ||
                raw.contains('körper')
            ? 'Basics & Menschen'
            : raw.contains('schule') ||
                    raw.contains('essen') ||
                    raw.contains('tages') ||
                    raw.contains('wochen')
                ? 'Schule & Alltag'
                : 'Natur & Freizeit',
        'Sachkunde' => raw.contains('österreich') ||
                raw.contains('bundes') ||
                raw.contains('kontinent') ||
                raw.contains('geschichte') ||
                raw.contains('geografie')
            ? 'Österreich & Welt'
            : raw.contains('strom') ||
                    raw.contains('diagramm') ||
                    raw.contains('wasser')
                ? 'Forschen & Technik'
                : raw.contains('famil') ||
                        raw.contains('beruf') ||
                        raw.contains('verkehr') ||
                        raw.contains('zeit')
                    ? 'Alltag & Gemeinschaft'
                    : 'Natur & Körper',
        'Logik' => raw.contains('regel') ||
                raw.contains('mehrschritt') ||
                raw.contains('zahlenrätsel') ||
                raw.contains('aussagen')
            ? 'Mehrschritt & Rätsel'
            : raw.contains('schluss') ||
                    raw.contains('wenn-dann') ||
                    raw.contains('ausschluss')
                ? 'Folgern & Ausschließen'
                : 'Muster & Ordnen',
        _ => 'Themen',
      };

      add(group, topic);
    }

    final preferredOrder = switch (subject.name) {
      'Mathematik' => const <String>[
          'Zahlen & Rechnen',
          'Mal & Teilen',
          'Größen & Alltag',
          'Formen & Daten',
          'Brüche & Dezimalzahlen',
          'Sachaufgaben',
        ],
      'Deutsch' => const <String>[
          'Wörter & Wortschatz',
          'Grammatik',
          'Rechtschreibung',
          'Sätze & Sprache',
        ],
      'Lesen' => const <String>[
          'Lesen & Verstehen',
          'Informationen & Schlüsse',
          'Textaufbau verstehen',
        ],
      'Schreiben' => const <String>[
          'Schreib-Grundlagen',
          'Sätze & Nachrichten',
          'Texte planen & verfassen',
        ],
      'Rechtschreibung' => const <String>[
          'Wortbilder & Großschreibung',
          'Rechtschreib-Regeln',
          'Sätze richtig schreiben',
        ],
      'Englisch' => const <String>[
          'Basics & Menschen',
          'Schule & Alltag',
          'Natur & Freizeit',
        ],
      'Sachkunde' => const <String>[
          'Natur & Körper',
          'Alltag & Gemeinschaft',
          'Forschen & Technik',
          'Österreich & Welt',
        ],
      'Logik' => const <String>[
          'Muster & Ordnen',
          'Folgern & Ausschließen',
          'Mehrschritt & Rätsel',
        ],
      _ => const <String>['Themen'],
    };

    final sorted = <String>[
      for (final title in preferredOrder)
        if (grouped.containsKey(title)) title,
      for (final title in order)
        if (!preferredOrder.contains(title)) title,
    ];

    return <_TopicBucket>[
      for (final title in sorted)
        _TopicBucket(title: title, topics: grouped[title]!),
    ];
  }

  Widget _buildTopicBucket(
    _TopicBucket bucket,
    LearningSubject subject, {
    required bool initiallyExpanded,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: LumoVisualTokens.glass.withOpacity(.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: subject.color.withOpacity(.42),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: subject.color.withOpacity(.08),
          ),
          child: ExpansionTile(
            key: ValueKey(
              '${_selectedGrade}_${subject.id}_${bucket.title}',
            ),
            initiallyExpanded: initiallyExpanded,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
            iconColor: LumoVisualTokens.cyanBright,
            collapsedIconColor: LumoVisualTokens.muted,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: subject.color.withOpacity(.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _bucketIcon(bucket.title),
                color: LumoVisualTokens.white,
                size: 20,
              ),
            ),
            title: Text(
              bucket.title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white,
              ),
            ),
            subtitle: Text(
              '${bucket.topics.length} ${bucket.topics.length == 1 ? 'Thema' : 'Themen'}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: LumoVisualTokens.muted,
              ),
            ),
            children: [
              for (final topic in bucket.topics)
                _buildTopicCard(topic, subject),
            ],
          ),
        ),
      ),
    );
  }

  IconData _bucketIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('zahlen') || lower.contains('rechnen')) {
      return Icons.pin_rounded;
    }
    if (lower.contains('mal') || lower.contains('teilen')) {
      return Icons.grid_3x3_rounded;
    }
    if (lower.contains('größe') || lower.contains('alltag')) {
      return Icons.straighten_rounded;
    }
    if (lower.contains('form') || lower.contains('daten')) {
      return Icons.category_rounded;
    }
    if (lower.contains('bruch') || lower.contains('dezimal')) {
      return Icons.pie_chart_rounded;
    }
    if (lower.contains('satz') || lower.contains('sprache')) {
      return Icons.short_text_rounded;
    }
    if (lower.contains('grammatik') || lower.contains('regel')) {
      return Icons.spellcheck_rounded;
    }
    if (lower.contains('lesen') || lower.contains('text')) {
      return Icons.auto_stories_rounded;
    }
    if (lower.contains('schreiben')) return Icons.edit_rounded;
    if (lower.contains('welt')) return Icons.public_rounded;
    if (lower.contains('natur')) return Icons.eco_rounded;
    if (lower.contains('technik')) return Icons.science_rounded;
    if (lower.contains('logik') ||
        lower.contains('folgern') ||
        lower.contains('rätsel') ||
        lower.contains('muster')) {
      return Icons.psychology_alt_rounded;
    }
    return Icons.school_rounded;
  }

  Widget _buildTopicCard(LearningTopic t, LearningSubject s) {
    // 2026-06-06 Iter 27: Topic-Cards in der Akademie aufgewertet.
    // Heinz: 'Aufgaben und Akademie sehen nicht eindrucksvoll aus'. Vorher
    // schlichte weisse Card mit grauem Border. Jetzt: Subject-Akzent als
    // Top-Streifen, Hintergrund-Verlauf nach unten, kraeftigerer Glow.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openTopic(t, s),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LumoVisualTokens.glass.withOpacity(0.9),
                  Color.alphaBlend(
                      t.gradient[0].withOpacity(0.14), LumoVisualTokens.glass),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              // 2026-06-06 FIX: Border mit unterschiedlichen Farben +
              // borderRadius rendert nicht in Flutter (Widget unsichtbar).
              // Loesung: Uniform-Border, dafuer den Top-Streifen als
              // visuellen Akzent ueber Box-Shadow inset oder einfach
              // weglassen.
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: LumoVisualTokens.cyan.withOpacity(0.48),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: LumoVisualTokens.cyan.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: t.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: t.gradient[0].withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(t.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: LumoVisualTokens.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.shortDesc,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: LumoVisualTokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (t.isWriting)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✏️ Schreiben',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  )
                else if (LearningModuleRegistry.hasModule(t.id))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🎮 Übung',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LumoVisualTokens.cyan.withOpacity(.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: LumoVisualTokens.cyan.withOpacity(.45),
                      ),
                    ),
                    child: const Text(
                      '✦ Aufgaben',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.cyanBright,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: t.gradient[0],
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopic(LearningTopic t, LearningSubject s) {
    // Bestehende hochwertige Spezialmodule bleiben erhalten.
    final moduleBuilder =
        LearningModuleRegistry.builderFor(t.id, widget.appState);
    if (moduleBuilder != null) {
      widget.appState.update(widget.appState.state.copyWith(
        grade: _selectedGrade,
        subject: t.subjectKey.isEmpty ? s.name : t.subjectKey,
        unit: t.unitKey.isEmpty ? t.title : t.unitKey,
        sessionKind: LumoSessionKind.quickPractice,
        mood: LumoMood.point,
      ));
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => moduleBuilder));
      return;
    }

    // Alle anderen Themen laufen als echte lokale Aufgabenserie im gleichen
    // Renderer wie die normalen Lernaufgaben. Kein Chat, keine Cloud-Pflicht.
    final subject = t.subjectKey.isEmpty
        ? (s.name == 'Sachkunde' ? 'Sachunterricht' : s.name)
        : t.subjectKey;
    final unit = t.unitKey.isEmpty ? t.title : t.unitKey;
    widget.appState.update(widget.appState.state.copyWith(
      grade: _selectedGrade,
      subject: subject,
      unit: unit,
      sessionKind: LumoSessionKind.quickPractice,
      mood: LumoMood.point,
      lumoMessage:
          '${Curriculum.prettifyUnit(unit)}\\n${_selectedGrade}. Klasse\\nLos geht’s!',
    ));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: LumoVisualTokens.night,
          appBar: AppBar(
            backgroundColor: LumoVisualTokens.navigation.withOpacity(.96),
            foregroundColor: LumoVisualTokens.white,
            elevation: 0,
            title: Text(
              Curriculum.prettifyUnit(unit),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: LearningContent(appState: widget.appState),
        ),
      ),
    );
  }
}

class _TopicBucket {
  const _TopicBucket({
    required this.title,
    required this.topics,
  });

  final String title;
  final List<LearningTopic> topics;
}

class _LearningArea {
  const _LearningArea({
    required this.title,
    required this.subject,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.curriculumIndex,
    this.section,
  });

  final String title;
  final String subject;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int? curriculumIndex;
  final LumoSection? section;
}
