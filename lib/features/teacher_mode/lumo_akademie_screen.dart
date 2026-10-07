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

import '../../widgets/fox/lumo_character.dart';
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../deutsch/lumo_deutsch_screen.dart';
import '../learning_modules/learning_module_registry.dart';
import '../learning/curriculum_activities_screen.dart';
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
                    'A',
                    'B',
                    'C',
                    'D',
                    'E',
                    'F',
                    'G',
                    'H',
                    'I',
                    'J',
                    'K',
                    'L',
                    'M',
                    'N',
                    'O',
                    'P',
                    'Q',
                    'R',
                    'S',
                    'T',
                    'U',
                    'V',
                    'W',
                    'X',
                    'Y',
                    'Z',
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
  const LumoAkademieScreen({
    super.key,
    required this.appState,
    this.drawBackground = true,
  });
  final LumoAppState appState;

  /// Im App-Rahmen malt die Shell die Szene vollflächig hinter Kopfzeile und
  /// Inhalt; allein geöffnet zeichnet der Bildschirm sie selbst.
  final bool drawBackground;

  @override
  State<LumoAkademieScreen> createState() => _LumoAkademieScreenState();
}

class _LumoAkademieScreenState extends State<LumoAkademieScreen>
    with TickerProviderStateMixin {
  // Farben und Symbole wie die sechs Fachkacheln in Bild 03.
  static const _learningAreas = <_LearningArea>[
    _LearningArea(
      title: 'Mathe',
      subject: 'Mathematik',
      subtitle: 'Zahlen und Rechnen',
      icon: Icons.calculate_rounded,
      color: Color(0xFFE08A26),
      art: _SubjectArtKind.math,
      curriculumIndex: 0,
    ),
    _LearningArea(
      title: 'Deutsch',
      subject: 'Deutsch',
      subtitle: 'Wörter und Sätze',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF6A38D6),
      art: _SubjectArtKind.book,
      curriculumIndex: 1,
    ),
    _LearningArea(
      title: 'Lesen',
      subject: 'Lesen',
      subtitle: 'Laut vorlesen',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF239A63),
      art: _SubjectArtKind.books,
      section: LumoSection.reading,
    ),
    _LearningArea(
      title: 'Schreiben',
      subject: 'Schreiben',
      subtitle: 'Schreiben und nachspuren',
      icon: Icons.draw_rounded,
      color: Color(0xFFC63A86),
      art: _SubjectArtKind.pencil,
      section: LumoSection.exercises,
    ),
    _LearningArea(
      title: 'Englisch',
      subject: 'Englisch',
      subtitle: 'Farben, Tiere und Wörter',
      icon: Icons.public_rounded,
      color: Color(0xFF2B5FD8),
      art: _SubjectArtKind.hi,
      section: LumoSection.exercises,
    ),
    _LearningArea(
      title: 'Sachkunde',
      subject: 'Sachunterricht',
      subtitle: 'Tiere, Natur und Welt',
      icon: Icons.eco_rounded,
      color: Color(0xFF14917F),
      art: _SubjectArtKind.globe,
      curriculumIndex: 2,
    ),
    _LearningArea(
      title: 'Musik',
      subject: 'Musik',
      subtitle: 'Hören, singen, gestalten',
      icon: Icons.music_note_rounded,
      color: Color(0xFF9B59E6),
      art: _SubjectArtKind.music,
      practical: true,
    ),
    _LearningArea(
      title: 'Kunst',
      subject: 'Kunst und Gestaltung',
      subtitle: 'Gestalten und erklären',
      icon: Icons.palette_rounded,
      color: Color(0xFFE45A9D),
      art: _SubjectArtKind.art,
      practical: true,
    ),
    _LearningArea(
      title: 'Technik',
      subject: 'Technik und Design',
      subtitle: 'Planen, bauen, prüfen',
      icon: Icons.build_rounded,
      color: Color(0xFF2FBAC8),
      art: _SubjectArtKind.tools,
      practical: true,
    ),
    _LearningArea(
      title: 'Bewegung',
      subject: 'Bewegung und Sport',
      subtitle: 'Bewegen und fair handeln',
      icon: Icons.sports_gymnastics_rounded,
      color: Color(0xFF35B876),
      art: _SubjectArtKind.sport,
      practical: true,
    ),
    _LearningArea(
      title: 'Mobilität',
      subject: 'Verkehrs- und Mobilitätsbildung',
      subtitle: 'Sicher unterwegs',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFFD99A31),
      art: _SubjectArtKind.traffic,
      practical: true,
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

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      top: widget.drawBackground,
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildTitleRow()),
          SliverToBoxAdapter(child: _buildGradePicker()),
          SliverToBoxAdapter(child: _buildLearningAreas()),
          SliverToBoxAdapter(child: _buildContinueBanner()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _buildSubjectSection(
                _currentGrade.subjects[_selectedSubjectIndex],
                _selectedSubjectIndex,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
    return Scaffold(
      backgroundColor:
          widget.drawBackground ? LumoVisualTokens.night : Colors.transparent,
      body: widget.drawBackground
          ? LumoSceneBackground(
              scene: LumoScene.learning,
              showPlaceholderLabel: false,
              dimmed: true,
              child: content,
            )
          : content,
    );
  }

  /// Bild 03: Lumo mit Tablet in der Mitte, links seine Sprechblase,
  /// rechts schräg „Kleine Schritte Große Zukunft!“.
  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _heroCtrl,
      builder: (_, child) {
        final v = Curves.easeOutCubic.transform(_heroCtrl.value);
        return Transform.translate(
          offset: Offset(0, (1 - v) * 24),
          child: Opacity(opacity: v, child: child),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = (width * .5).clamp(170.0, 270.0);
          final foxSize = height * 1.12;
          final Widget fox = LumoCharacter(
            pose: LumoDesignFoxPose.tabletThumb,
            size: foxSize,
            reduceMotion: _reduceMotion,
            // Antippen: Lumo wackelt kitzlig.
            onTap: () {},
          );
          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (width - foxSize) / 2 + width * .03,
                  bottom: -6,
                  child: RepaintBoundary(child: fox),
                ),
                Positioned(
                  left: 12,
                  top: height * .08,
                  width: width * .31,
                  child: const LumoHeroBubble(
                    title: 'Du kannst das!',
                    text: 'Jede Aufgabe bringt dich weiter!',
                  ),
                ),
                Positioned(
                  right: -4,
                  top: height * .42,
                  width: width * .27,
                  child: Transform.rotate(
                    angle: -.08,
                    child: const LumoHeroBubble(
                      text: 'Kleine Schritte\nGroße Zukunft!',
                      handwritten: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Für Bildschirmleser und die Android-Prüfung bleibt der
                // Bereichsname erhalten, sichtbar ist nur „Lernen“ wie im Bild.
                Semantics(
                  container: true,
                  label: 'LUMO AKADEMIE',
                  child: const Text(
                    'Lernen',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Color(0x88000000), blurRadius: 10)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Heute lernen. Morgen mehr können!',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.cyanBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: _buildGoals()),
        ],
      ),
    );
  }

  Widget _buildGoals() {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final done = widget.appState.learningDailyDone();
        final goal = widget.appState.state.settings.dailyGoal.clamp(1, 500);
        final progress = (done / goal).clamp(0.0, 1.0).toDouble();
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 176),
          child: LumoGlassCard(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            radius: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: _AnimatedRing(
                    value: progress,
                    reduceMotion: _reduceMotion,
                    strokeWidth: 3.5,
                    child: const Icon(Icons.track_changes_rounded,
                        color: LumoVisualTokens.cyanBright, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Deine Ziele',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$done von $goal Aufgaben geschafft',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: LumoVisualTokens.cyanBright, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Banner unter den Fächern: Lumo jubelt, „Weiter geht's!“ öffnet das
  /// erste Thema des gewählten Fachs. Der Text richtet sich nach dem echten
  /// Tagesfortschritt.
  Widget _buildContinueBanner() {
    final subject = _currentGrade.subjects[_selectedSubjectIndex];
    final topic = subject.topics.first;
    final done = widget.appState.learningDailyDone();
    final title = done > 0 ? 'Super gemacht!' : 'Auf geht’s!';
    final text = done > 0
        ? 'Du lernst fleißig und machst tolle Fortschritte!'
        : 'Heute wartet ${topic.title} auf dich.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
        radius: 22,
        child: Row(
          children: [
            const LumoFoxPose(pose: LumoDesignFoxPose.cheer, size: 74),
            const SizedBox(width: 4),
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
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('akademie-continue'),
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => _openTopic(topic, subject),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E6FD9), Color(0xFF1453B8)],
                        ),
                        border: Border.all(color: LumoVisualTokens.cyanBright),
                        boxShadow: [
                          BoxShadow(
                            color: LumoVisualTokens.cyan.withOpacity(.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Weiter geht’s!',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningAreas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final isWide = constraints.maxWidth >= 720;
          final textScale =
              MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6).toDouble();
          final coreAreas =
              _learningAreas.where((area) => !area.practical).toList();
          final practicalAreas =
              _learningAreas.where((area) => area.practical).toList();

          final coreColumns = isWide ? 6 : 3;
          final coreWidth =
              (constraints.maxWidth - (coreColumns - 1) * gap) / coreColumns;
          final coreHeight =
              (coreWidth * 1.02).clamp(112.0, 168.0).toDouble() * textScale;

          Widget practicalStrip() {
            if (isWide) {
              final width = (constraints.maxWidth -
                      (practicalAreas.length - 1) * gap) /
                  practicalAreas.length;
              final height = (width * .86).clamp(108.0, 148.0).toDouble() * textScale;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final area in practicalAreas)
                    SizedBox(
                      width: width,
                      height: height,
                      child: _buildLearningAreaTile(area),
                    ),
                ],
              );
            }

            final width = (constraints.maxWidth * .34).clamp(108.0, 132.0).toDouble();
            final height = (width * .94).clamp(108.0, 124.0).toDouble() * textScale;
            return SizedBox(
              height: height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: practicalAreas.length,
                separatorBuilder: (_, __) => const SizedBox(width: gap),
                itemBuilder: (context, index) => SizedBox(
                  width: width,
                  height: height,
                  child: _buildLearningAreaTile(practicalAreas[index]),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final area in coreAreas)
                    SizedBox(
                      width: coreWidth,
                      height: coreHeight,
                      child: _buildLearningAreaTile(area),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  'Weitere Fächer',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.cyanBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              practicalStrip(),
            ],
          );
        },
      ),
    );
  }

  /// Deutsch öffnet den Bereich aus Bild 04; zurück zeigt die Akademie
  /// die Deutsch-Themen der gewählten Klasse („Wörter“).
  Future<void> _openDeutsch() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
          builder: (_) => LumoDeutschScreen(appState: widget.appState)),
    );
    if (mounted) setState(() => _selectedSubjectIndex = 1);
  }

  void _openLearningArea(_LearningArea area) {
    if (area.subject == 'Deutsch') {
      _openDeutsch();
      return;
    }
    if (area.practical) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CurriculumActivitiesScreen(
            grade: _selectedGrade,
            subject: area.subject,
          ),
        ),
      );
      return;
    }
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
  }

  /// Fachkachel wie in Bild 03: Symbol oben, Ring mit Prozent, Titel,
  /// Sterne für richtige Antworten und „richtig / geübt“ aus echten Werten.
  Widget _buildLearningAreaTile(_LearningArea area) {
    final skillList = widget.appState
        .learningSkills()
        .values
        .where((skill) =>
            skill.subject.trim().toLowerCase() == area.subject.toLowerCase())
        .toList();
    final correct = skillList.fold<int>(0, (sum, skill) => sum + skill.correct);
    final attempts =
        skillList.fold<int>(0, (sum, skill) => sum + skill.attempts);
    final mastery = skillList.isEmpty
        ? 0
        : (skillList.fold<int>(0, (sum, skill) => sum + skill.mastery) ~/
            skillList.length);
    final selected = area.curriculumIndex == _selectedSubjectIndex;
    final dark = Color.lerp(area.color, Colors.black, .35)!;
    return Semantics(
      button: true,
      selected: selected,
      label: '${area.title}. ${area.subtitle}. $mastery Prozent gemeistert, '
          '$correct von $attempts richtig',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('learning-area-${area.title.toLowerCase()}'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openLearningArea(area),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(area.color, Colors.white, .12)!, dark],
              ),
              border: Border.all(
                color: selected
                    ? LumoVisualTokens.cyanBright
                    : Colors.white.withOpacity(.30),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (selected ? LumoVisualTokens.cyan : area.color)
                      .withOpacity(.40),
                  blurRadius: selected ? 16 : 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final ring = (c.maxWidth * .3).clamp(30.0, 44.0);
                return Stack(children: [
                  // Symbol groß oben, Ring und Titel überlappen es leicht.
                  Positioned(
                    top: 4,
                    left: c.maxWidth * .22,
                    right: 4,
                    height: c.maxHeight * .36,
                    child: Center(child: _SubjectArt(area: area)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Row(
                          children: [
                            SizedBox(
                              width: ring,
                              height: ring,
                              child: _AnimatedRing(
                                value: mastery / 100,
                                reduceMotion: _reduceMotion,
                                strokeWidth: 3.2,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      '$mastery%',
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      area.title,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: LumoVisualTokens.gold,
                                            size: 15),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$correct',
                                          style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$correct / $attempts richtig',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: Colors.white.withOpacity(.88),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dark.withOpacity(.75),
                              ),
                              child: const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          for (final g in LumoCurriculum.grades) ...[
            if (g != LumoCurriculum.grades.first) const SizedBox(width: 8),
            Expanded(child: _buildGradeChip(g)),
          ],
        ],
      ),
    );
  }

  Widget _buildGradeChip(GradeLevel g) {
    final isSelected = g.grade == _selectedGrade;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${g.title}, ${g.ageRange}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('grade-pill-${g.grade}'),
        onTap: () => setState(() {
          _selectedGrade = g.grade;
          _selectedSubjectIndex = 0;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height:
              32 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF7FE9FF), LumoVisualTokens.cyan],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isSelected ? null : LumoVisualTokens.glass.withOpacity(.72),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(.85)
                  : LumoVisualTokens.cyan.withOpacity(.45),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: LumoVisualTokens.cyan.withOpacity(.55),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              g.title,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? LumoVisualTokens.night
                    : LumoVisualTokens.white,
              ),
            ),
          ),
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
                Expanded(
                  child: Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                    ),
                  ),
                ),
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
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
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
                      ),
                    ),
                  )
                else if (LearningModuleRegistry.hasModule(t.id))
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
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
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '💬 Chat',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5B21B6),
                          ),
                        ),
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
    // 0) Schreibcoach LIVE (Heinz' Premium-Feature)
    if (t.id == 'd1_schreibcoach') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LumoWritingCoachScreen(appState: widget.appState),
        ),
      );
      return;
    }
    // 0b) Wortdiktat (Phase 5): Buchstabenfelder + WritingProgressRepo.
    if (t.id == 'd1_woerter' && WritingFeatureFlags.enableWordMode) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LumoWritingWordCoachScreen(appState: widget.appState),
        ),
      );
      return;
    }
    // 1) Buchstaben-Schreiben (eigenes echtes Modul)
    if (t.isWriting && t.writingChars.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
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
    final moduleBuilder = LearningModuleRegistry.builderFor(
      t.id,
      widget.appState,
    );
    if (moduleBuilder != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => moduleBuilder));
      return;
    }
    // 3) Fallback: ChatGPT-Lernchat
    Navigator.of(context).push(
      MaterialPageRoute(
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
    required this.art,
    this.curriculumIndex,
    this.section,
    this.practical = false,
  });

  final _SubjectArtKind art;
  final String title;
  final String subject;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int? curriculumIndex;
  final LumoSection? section;
  final bool practical;
}

enum _SubjectArtKind { math, book, books, pencil, hi, globe, music, art, tools, sport, traffic }

/// Großes, leuchtendes Fachsymbol oben in der Kachel.
class _SubjectArt extends StatelessWidget {
  const _SubjectArt({required this.area});

  final _LearningArea area;

  @override
  Widget build(BuildContext context) {
    const glow = [
      Shadow(color: Color(0x99FFFFFF), blurRadius: 12),
      Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
    ];
    return LayoutBuilder(builder: (context, c) {
      final size = c.maxHeight.clamp(24.0, 64.0);
      switch (area.art) {
        case _SubjectArtKind.math:
          // + − × ÷ wie die Rechenzeichen im Bild.
          return SizedBox(
            width: size * 1.1,
            height: size,
            child: FittedBox(
              child: Text(
                '+ −\n× ÷',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  height: .95,
                  fontSize: 30,
                  color: const Color(0xFFFFF0C9),
                  shadows: [
                    ...glow,
                    Shadow(
                        color: area.color.withOpacity(.9),
                        blurRadius: 2,
                        offset: const Offset(1.5, 1.5)),
                  ],
                ),
              ),
            ),
          );
        case _SubjectArtKind.hi:
          return Container(
            height: size * .62,
            padding: EdgeInsets.symmetric(horizontal: size * .18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * .4),
              boxShadow: const [
                BoxShadow(color: Color(0x88FFFFFF), blurRadius: 14),
              ],
            ),
            child: FittedBox(
              child: Text(
                'Hi!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: area.color,
                ),
              ),
            ),
          );
        case _SubjectArtKind.book:
        case _SubjectArtKind.books:
        case _SubjectArtKind.pencil:
        case _SubjectArtKind.globe:
        case _SubjectArtKind.music:
        case _SubjectArtKind.art:
        case _SubjectArtKind.tools:
        case _SubjectArtKind.sport:
        case _SubjectArtKind.traffic:
          final icon = switch (area.art) {
            _SubjectArtKind.book => Icons.menu_book_rounded,
            _SubjectArtKind.books => Icons.library_books_rounded,
            _SubjectArtKind.pencil => Icons.edit_rounded,
            _SubjectArtKind.music => Icons.music_note_rounded,
            _SubjectArtKind.art => Icons.palette_rounded,
            _SubjectArtKind.tools => Icons.build_rounded,
            _SubjectArtKind.sport => Icons.sports_gymnastics_rounded,
            _SubjectArtKind.traffic => Icons.directions_walk_rounded,
            _ => Icons.public_rounded,
          };
          final tint = switch (area.art) {
            _SubjectArtKind.book => const Color(0xFFE9DEFF),
            _SubjectArtKind.books => const Color(0xFFC9FFE3),
            _SubjectArtKind.pencil => const Color(0xFFFFD6EC),
            _SubjectArtKind.music => const Color(0xFFEAD8FF),
            _SubjectArtKind.art => const Color(0xFFFFD8EB),
            _SubjectArtKind.tools => const Color(0xFFD1FBFF),
            _SubjectArtKind.sport => const Color(0xFFD4FFE6),
            _SubjectArtKind.traffic => const Color(0xFFFFE8B7),
            _ => const Color(0xFFC6F4FF),
          };
          return Icon(icon, size: size, color: tint, shadows: glow);
      }
    });
  }
}

/// Fortschrittsring, der sich im Uhrzeigersinn zum echten Wert zeichnet.
class _AnimatedRing extends StatelessWidget {
  const _AnimatedRing({
    required this.value,
    required this.reduceMotion,
    required this.child,
    this.strokeWidth = 3,
  });

  final double value;
  final bool reduceMotion;
  final double strokeWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withOpacity(.22),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  LumoVisualTokens.cyanBright),
            ),
            Center(child: child),
          ],
        ),
      );
}
