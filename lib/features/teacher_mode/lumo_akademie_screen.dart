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
import '../../widgets/design/lumo_design_system.dart';
import '../learning_modules/learning_module_registry.dart';
import '../writing/lumo_writing_coach_screen.dart';
import '../writing/lumo_writing_word_coach_screen.dart';
import '../writing/writing_feature_flags.dart';
import 'lumo_teacher_screen.dart';
import 'letter_writing_screen.dart';

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
  static List<GradeLevel> get grades => [
        // KLASSE 1
        GradeLevel(
          grade: 1,
          title: '1. Klasse',
          subtitle: 'Erste Schritte',
          ageRange: '6-7 Jahre',
          color: LumoColors.teal,
          subjects: [
            LearningSubject(
              id: 'mathe1',
              name: 'Mathematik',
              color: LumoColors.math,
              icon: Icons.calculate_rounded,
              topics: const [
                LearningTopic(
                    id: 'm1_zahlen10',
                    title: 'Zahlen 1-10',
                    icon: Icons.format_list_numbered_rounded,
                    gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                    shortDesc: 'Zählen, vergleichen, sortieren',
            ),
                LearningTopic(
                    id: 'm1_plus10',
                    title: 'Plus bis 10',
                    icon: Icons.add_circle_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: '2+3, 5+4 ...',
            ),
                LearningTopic(
                    id: 'm1_minus10',
                    title: 'Minus bis 10',
                    icon: Icons.remove_circle_rounded,
                    gradient: [Color(0xFFFF625D), Color(0xFFFF9A5C)],
                    shortDesc: '7-3, 10-6 ...',
            ),
                LearningTopic(
                    id: 'm1_formen',
                    title: 'Formen',
                    icon: Icons.category_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Kreis, Quadrat, Dreieck',
            ),
              ],
            ),
            LearningSubject(
              id: 'deutsch1',
              name: 'Deutsch',
              color: LumoColors.german,
              icon: Icons.menu_book_rounded,
              topics: const [
                LearningTopic(
                    id: 'd1_schreibcoach',
                    title: '✨ Schreibcoach LIVE',
                    icon: Icons.draw_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
                    shortDesc: 'Lumo schaut beim Schreiben zu!',
            ),
                LearningTopic(
                    id: 'd1_buchstaben_alle',
                    title: 'Alle Buchstaben A-Z',
                    icon: Icons.edit_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Alle 26 Buchstaben üben',
                    isWriting: true,
                    writingChars: [
                      'A','B','C','D','E','F','G','H','I','J','K','L','M',
                      'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
                    ,
              ],
            ),
                LearningTopic(
                    id: 'd1_woerter',
                    title: 'Erste Wörter',
                    icon: Icons.text_fields_rounded,
                    gradient: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
                    shortDesc: 'MAMA, PAPA, OMA...',
            ),
              ],
            ),
            LearningSubject(
              id: 'sachk1',
              name: 'Sachkunde',
              color: LumoColors.teal,
              icon: Icons.eco_rounded,
              topics: const [
                LearningTopic(
                    id: 's1_tiere',
                    title: 'Tiere',
                    icon: Icons.pets_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: 'Bauernhof, Wald, Zoo',
            ),
                LearningTopic(
                    id: 's1_farben',
                    title: 'Farben',
                    icon: Icons.palette_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    shortDesc: 'Rot, Blau, Grün...',
            ),
                LearningTopic(
                    id: 's1_koerper',
                    title: 'Mein Körper',
                    icon: Icons.accessibility_new_rounded,
                    gradient: [Color(0xFFFF625D), Color(0xFFFF9A5C)],
                    shortDesc: 'Augen, Hände, Füße',
            ),
              ],
            ),
          ],
        ),
        // KLASSE 2
        GradeLevel(
          grade: 2,
          title: '2. Klasse',
          subtitle: 'Aufbau',
          ageRange: '7-8 Jahre',
          color: LumoColors.purple,
          subjects: [
            LearningSubject(
              id: 'mathe2',
              name: 'Mathematik',
              color: LumoColors.math,
              icon: Icons.calculate_rounded,
              topics: const [
                LearningTopic(
                    id: 'm2_zahlen100',
                    title: 'Zahlen bis 100',
                    icon: Icons.format_list_numbered_rounded,
                    gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                    shortDesc: 'Zehner & Einer',
            ),
                LearningTopic(
                    id: 'm2_einmaleins',
                    title: 'Kleines 1×1',
                    icon: Icons.close_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: '2er, 5er, 10er-Reihe',
            ),
                LearningTopic(
                    id: 'm2_uhr',
                    title: 'Die Uhr',
                    icon: Icons.access_time_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    shortDesc: 'Stunden & Minuten',
            ),
                LearningTopic(
                    id: 'm2_geld',
                    title: 'Geld',
                    icon: Icons.euro_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: 'Euro & Cent',
            ),
              ],
            ),
            LearningSubject(
              id: 'deutsch2',
              name: 'Deutsch',
              color: LumoColors.german,
              icon: Icons.menu_book_rounded,
              topics: const [
                LearningTopic(
                    id: 'd2_saetze',
                    title: 'Sätze bilden',
                    icon: Icons.format_quote_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Subjekt + Prädikat',
            ),
                LearningTopic(
                    id: 'd2_artikel',
                    title: 'Der/Die/Das',
                    icon: Icons.text_format_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Artikel finden',
            ),
                LearningTopic(
                    id: 'd2_mehrzahl',
                    title: 'Mehrzahl',
                    icon: Icons.numbers_rounded,
                    gradient: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
                    shortDesc: 'Ein Hund - viele Hunde',
            ),
              ],
            ),
            LearningSubject(
              id: 'sachk2',
              name: 'Sachkunde',
              color: LumoColors.teal,
              icon: Icons.eco_rounded,
              topics: const [
                LearningTopic(
                    id: 's2_jahreszeiten',
                    title: 'Jahreszeiten',
                    icon: Icons.wb_sunny_rounded,
                    gradient: [Color(0xFFFFB800), Color(0xFFFCD34D)],
                    shortDesc: 'Frühling bis Winter',
            ),
                LearningTopic(
                    id: 's2_wetter',
                    title: 'Wetter',
                    icon: Icons.cloud_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    shortDesc: 'Regen, Sonne, Schnee',
            ),
                LearningTopic(
                    id: 's2_verkehr',
                    title: 'Verkehr',
                    icon: Icons.directions_walk_rounded,
                    gradient: [Color(0xFFFF625D), Color(0xFFFF9A5C)],
                    shortDesc: 'Sicher auf der Straße',
            ),
              ],
            ),
          ],
        ),
        // KLASSE 3
        GradeLevel(
          grade: 3,
          title: '3. Klasse',
          subtitle: 'Vertiefung',
          ageRange: '8-9 Jahre',
          color: LumoColors.blue,
          subjects: [
            LearningSubject(
              id: 'mathe3',
              name: 'Mathematik',
              color: LumoColors.math,
              icon: Icons.calculate_rounded,
              topics: const [
                LearningTopic(
                    id: 'm3_zahlen1000',
                    title: 'Zahlen bis 1000',
                    icon: Icons.format_list_numbered_rounded,
                    gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                    shortDesc: 'Hunderter, Zehner, Einer',
            ),
                LearningTopic(
                    id: 'm3_einmaleins_voll',
                    title: 'Großes 1×1',
                    icon: Icons.close_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Alle Reihen bis 10',
            ),
                LearningTopic(
                    id: 'm3_geometrie',
                    title: 'Geometrie',
                    icon: Icons.architecture_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: 'Umfang, Fläche',
            ),
              ],
            ),
            LearningSubject(
              id: 'deutsch3',
              name: 'Deutsch',
              color: LumoColors.german,
              icon: Icons.menu_book_rounded,
              topics: const [
                LearningTopic(
                    id: 'd3_wortarten',
                    title: 'Wortarten',
                    icon: Icons.category_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Nomen, Verb, Adjektiv',
            ),
                LearningTopic(
                    id: 'd3_zeitformen',
                    title: 'Zeitformen',
                    icon: Icons.timer_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Gestern, Heute, Morgen',
            ),
                LearningTopic(
                    id: 'd3_geschichten',
                    title: 'Geschichten',
                    icon: Icons.auto_stories_rounded,
                    gradient: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
                    shortDesc: 'Lesen & Verstehen',
            ),
              ],
            ),
            LearningSubject(
              id: 'sachk3',
              name: 'Sachkunde',
              color: LumoColors.teal,
              icon: Icons.eco_rounded,
              topics: const [
                LearningTopic(
                    id: 's3_oesterreich',
                    title: 'Österreich',
                    icon: Icons.map_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: 'Bundesländer & Hauptstädte',
            ),
                LearningTopic(
                    id: 's3_natur',
                    title: 'Natur',
                    icon: Icons.park_rounded,
                    gradient: [Color(0xFF059669), Color(0xFF34D399)],
                    shortDesc: 'Pflanzen & Tiere',
            ),
              ],
            ),
          ],
        ),
        // KLASSE 4
        GradeLevel(
          grade: 4,
          title: '4. Klasse',
          subtitle: 'Meister',
          ageRange: '9-10 Jahre',
          color: LumoColors.orange,
          subjects: [
            LearningSubject(
              id: 'mathe4',
              name: 'Mathematik',
              color: LumoColors.math,
              icon: Icons.calculate_rounded,
              topics: const [
                LearningTopic(
                    id: 'm4_million',
                    title: 'Zahlen bis 1 Million',
                    icon: Icons.format_list_numbered_rounded,
                    gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                    shortDesc: 'Große Zahlen',
            ),
                LearningTopic(
                    id: 'm4_bruch',
                    title: 'Bruchrechnen',
                    icon: Icons.pie_chart_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: '1/2, 1/4, 1/3',
            ),
                LearningTopic(
                    id: 'm4_textaufgaben',
                    title: 'Textaufgaben',
                    icon: Icons.notes_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Sachrechnen',
            ),
              ],
            ),
            LearningSubject(
              id: 'deutsch4',
              name: 'Deutsch',
              color: LumoColors.german,
              icon: Icons.menu_book_rounded,
              topics: const [
                LearningTopic(
                    id: 'd4_grammatik',
                    title: 'Grammatik',
                    icon: Icons.psychology_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Fälle, Satzglieder',
            ),
                LearningTopic(
                    id: 'd4_aufsatz',
                    title: 'Aufsätze',
                    icon: Icons.edit_note_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Erzählen & Beschreiben',
            ),
              ],
            ),
            LearningSubject(
              id: 'sachk4',
              name: 'Sachkunde',
              color: LumoColors.teal,
              icon: Icons.eco_rounded,
              topics: const [
                LearningTopic(
                    id: 's4_europa',
                    title: 'Europa',
                    icon: Icons.public_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    shortDesc: 'Länder & Hauptstädte',
            ),
                LearningTopic(
                    id: 's4_geschichte',
                    title: 'Geschichte',
                    icon: Icons.castle_rounded,
                    gradient: [Color(0xFF7C2D12), Color(0xFFB45309)],
                    shortDesc: 'Vom Mittelalter bis heute',
            ),
              ],
            ),
          ],
        ),
      ];
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
      subtitle: 'Zahlen und Rechnen',
      icon: Icons.calculate_rounded,
      color: LumoVisualTokens.learning,
      curriculumIndex: 0,
    ),
    _LearningArea(
      title: 'Deutsch',
      subject: 'Deutsch',
      subtitle: 'Wörter und Sätze',
      icon: Icons.menu_book_rounded,
      color: LumoVisualTokens.games,
      curriculumIndex: 1,
    ),
    _LearningArea(
      title: 'Lesen',
      subject: 'Lesen',
      subtitle: 'Laut vorlesen',
      icon: Icons.auto_stories_rounded,
      color: LumoVisualTokens.tests,
      section: LumoSection.reading,
    ),
    _LearningArea(
      title: 'Schreiben',
      subject: 'Schreiben',
      subtitle: 'Schreiben und nachspuren',
      icon: Icons.draw_rounded,
      color: LumoVisualTokens.rewards,
      section: LumoSection.exercises,
    ),
    _LearningArea(
      title: 'Englisch',
      subject: 'Englisch',
      subtitle: 'Farben, Tiere und Wörter',
      icon: Icons.public_rounded,
      color: Color(0xFF167BC0),
      section: LumoSection.exercises,
    ),
    _LearningArea(
      title: 'Sachkunde',
      subject: 'Sachunterricht',
      subtitle: 'Tiere, Natur und Welt',
      icon: Icons.eco_rounded,
      color: Color(0xFF167A84),
      curriculumIndex: 2,
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
                sliver: SliverList.builder(
                  itemCount: 1,
                  itemBuilder: (_, __) => _buildSubjectSection(
                      _currentGrade.subjects[_selectedSubjectIndex],
                      _selectedSubjectIndex),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.school_rounded,
                        color: LumoVisualTokens.cyan, size: 20),
                    SizedBox(width: 7),
                    Text('LUMO AKADEMIE',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.cyanBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'Lernen',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Heute lernen. Morgen mehr können!',
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
            const LumoFoxPose(
              pose: LumoDesignFoxPose.tabletThumb,
              size: 124,
            ),
          ],
        ),
      ),
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
    final topic = subject.topics.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openTopic(topic, subject),
          child: LumoGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                const LumoFoxPose(
                    pose: LumoDesignFoxPose.cheer, size: 82),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super gemacht!',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Du lernst fleißig und machst tolle Fortschritte!',
                        style: TextStyle(
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
                const Icon(Icons.arrow_forward_rounded,
                    color: LumoVisualTokens.cyanBright),
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
              'Fächer',
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
    final completed = skillList.fold<int>(0, (sum, skill) => sum + skill.correct);
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
              'Welche Klasse?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white,
              ),
            ),
          ),
          SizedBox(
            height: 110 *
                MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: LumoCurriculum.grades.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) =>
                  _buildGradeChip(LumoCurriculum.grades[i]),
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
            Text('${g.grade}.',
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
            Text(g.title,
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
            Text(g.ageRange,
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
                Text(s.name,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white,
                  ),
                ),
                const Spacer(),
                Text('${s.topics.length} Themen',
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
          // Topics
          ...s.topics.map((t) => _buildTopicCard(t, s)).toList(),
        ],
      ),
    );
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
                  Color.alphaBlend(t.gradient[0].withOpacity(0.14),
                      LumoVisualTokens.glass),
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
                      Text(t.title,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: LumoVisualTokens.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(t.shortDesc,
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
                        horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('✏️ Schreiben',
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
                        horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🎮 Übung',
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
                        horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('💬 Chat',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5B21B6),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: t.gradient[0], size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopic(LearningTopic t, LearningSubject s) {
    // 0) Schreibcoach LIVE (Heinz' Premium-Feature)
    if (t.id == 'd1_schreibcoach') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LumoWritingCoachScreen(appState: widget.appState),
      ),
      );
      return;
    }
    // 0b) Wortdiktat (Phase 5): Buchstabenfelder + WritingProgressRepo.
    if (t.id == 'd1_woerter' && WritingFeatureFlags.enableWordMode) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            LumoWritingWordCoachScreen(appState: widget.appState),
      ),
      );
      return;
    }
    // 1) Buchstaben-Schreiben (eigenes echtes Modul)
    if (t.isWriting && t.writingChars.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LetterWritingScreen(
          appState: widget.appState,
          topic: t,
          subject: s,
        ),
      ),
      );
      return;
    }
    // 2) Pruefe ob Topic ein registriertes echtes Modul hat
    final moduleBuilder =
        LearningModuleRegistry.builderFor(t.id, widget.appState,
    );
    if (moduleBuilder != null) {
      Navigator.of(context,
      ).push(MaterialPageRoute(
        builder: (_) => moduleBuilder));
      return;
    }
    // 3) Fallback: ChatGPT-Lernchat
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LumoTeacherScreen(
        appState: widget.appState,
        topic: t,
        subject: s,
        grade: _selectedGrade,
      ),
    ),
    );
  }
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
