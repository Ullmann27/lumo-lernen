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
import '../../widgets/fox/lumo_idle_fox.dart';
import '../../widgets/premium/lumo_magic_background.dart';
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
                    shortDesc: 'Zählen, vergleichen, sortieren'),
                LearningTopic(
                    id: 'm1_plus10',
                    title: 'Plus bis 10',
                    icon: Icons.add_circle_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: '2+3, 5+4 ...'),
                LearningTopic(
                    id: 'm1_minus10',
                    title: 'Minus bis 10',
                    icon: Icons.remove_circle_rounded,
                    gradient: [Color(0xFFFF625D), Color(0xFFFF9A5C)],
                    shortDesc: '7-3, 10-6 ...'),
                LearningTopic(
                    id: 'm1_formen',
                    title: 'Formen',
                    icon: Icons.category_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Kreis, Quadrat, Dreieck'),
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
                    shortDesc: 'Lumo schaut beim Schreiben zu!'),
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
                    ]),
                LearningTopic(
                    id: 'd1_woerter',
                    title: 'Erste Wörter',
                    icon: Icons.text_fields_rounded,
                    gradient: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
                    shortDesc: 'MAMA, PAPA, OMA...'),
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
                    shortDesc: 'Bauernhof, Wald, Zoo'),
                LearningTopic(
                    id: 's1_farben',
                    title: 'Farben',
                    icon: Icons.palette_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    shortDesc: 'Rot, Blau, Grün...'),
                LearningTopic(
                    id: 's1_koerper',
                    title: 'Mein Körper',
                    icon: Icons.accessibility_new_rounded,
                    gradient: [Color(0xFFFF625D), Color(0xFFFF9A5C)],
                    shortDesc: 'Augen, Hände, Füße'),
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
                    shortDesc: 'Zehner & Einer'),
                LearningTopic(
                    id: 'm2_einmaleins',
                    title: 'Kleines 1×1',
                    icon: Icons.close_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: '2er, 5er, 10er-Reihe'),
                LearningTopic(
                    id: 'm2_uhr',
                    title: 'Die Uhr',
                    icon: Icons.access_time_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    shortDesc: 'Stunden & Minuten'),
                LearningTopic(
                    id: 'm2_geld',
                    title: 'Geld',
                    icon: Icons.euro_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: 'Euro & Cent'),
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
                    shortDesc: 'Subjekt + Prädikat'),
                LearningTopic(
                    id: 'd2_artikel',
                    title: 'Der/Die/Das',
                    icon: Icons.text_format_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Artikel finden'),
                LearningTopic(
                    id: 'd2_mehrzahl',
                    title: 'Mehrzahl',
                    icon: Icons.numbers_rounded,
                    gradient: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
                    shortDesc: 'Ein Hund - viele Hunde'),
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
                    shortDesc: 'Frühling bis Winter'),
                LearningTopic(
                    id: 's2_wetter',
                    title: 'Wetter',
                    icon: Icons.cloud_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    shortDesc: 'Regen, Sonne, Schnee'),
                LearningTopic(
                    id: 's2_verkehr',
                    title: 'Verkehr',
                    icon: Icons.directions_walk_rounded,
                    gradient: [Color(0xFFFF625D), Color(0xFFFF9A5C)],
                    shortDesc: 'Sicher auf der Straße'),
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
                    shortDesc: 'Hunderter, Zehner, Einer'),
                LearningTopic(
                    id: 'm3_einmaleins_voll',
                    title: 'Großes 1×1',
                    icon: Icons.close_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: 'Alle Reihen bis 10'),
                LearningTopic(
                    id: 'm3_geometrie',
                    title: 'Geometrie',
                    icon: Icons.architecture_rounded,
                    gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                    shortDesc: 'Umfang, Fläche'),
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
                    shortDesc: 'Nomen, Verb, Adjektiv'),
                LearningTopic(
                    id: 'd3_zeitformen',
                    title: 'Zeitformen',
                    icon: Icons.timer_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Gestern, Heute, Morgen'),
                LearningTopic(
                    id: 'd3_geschichten',
                    title: 'Geschichten',
                    icon: Icons.auto_stories_rounded,
                    gradient: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
                    shortDesc: 'Lesen & Verstehen'),
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
                    shortDesc: 'Bundesländer & Hauptstädte'),
                LearningTopic(
                    id: 's3_natur',
                    title: 'Natur',
                    icon: Icons.park_rounded,
                    gradient: [Color(0xFF059669), Color(0xFF34D399)],
                    shortDesc: 'Pflanzen & Tiere'),
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
                    shortDesc: 'Große Zahlen'),
                LearningTopic(
                    id: 'm4_bruch',
                    title: 'Bruchrechnen',
                    icon: Icons.pie_chart_rounded,
                    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    shortDesc: '1/2, 1/4, 1/3'),
                LearningTopic(
                    id: 'm4_textaufgaben',
                    title: 'Textaufgaben',
                    icon: Icons.notes_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Sachrechnen'),
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
                    shortDesc: 'Fälle, Satzglieder'),
                LearningTopic(
                    id: 'd4_aufsatz',
                    title: 'Aufsätze',
                    icon: Icons.edit_note_rounded,
                    gradient: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
                    shortDesc: 'Erzählen & Beschreiben'),
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
                    shortDesc: 'Länder & Hauptstädte'),
                LearningTopic(
                    id: 's4_geschichte',
                    title: 'Geschichte',
                    icon: Icons.castle_rounded,
                    gradient: [Color(0xFF7C2D12), Color(0xFFB45309)],
                    shortDesc: 'Vom Mittelalter bis heute'),
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
  late final AnimationController _heroCtrl;
  int _selectedGrade = 1;

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
      // LumoMagicBackground liefert den Premium-Hintergrund mit sanften
      // Sternen + Wolken. Scaffold-bg wird transparent, sonst doppelter
      // Hintergrund.
      backgroundColor: Colors.transparent,
      body: LumoMagicBackground(
        intensity: 0.9,
        starCount: 14,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── HERO BANNER ────────────────────────────────────
              SliverToBoxAdapter(child: _buildHero()),
              // ── KLASSEN-SELECTOR ───────────────────────────────
              SliverToBoxAdapter(child: _buildGradePicker()),
              // ── FACH-KACHELN ───────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList.builder(
                  itemCount: _currentGrade.subjects.length,
                  itemBuilder: (_, i) => _buildSubjectSection(
                      _currentGrade.subjects[i], i),
                ),
              ),
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
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A2F), Color(0xFFEC4899), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A2F).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Text('LUMO AKADEMIE',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Lumo zeigt\ndir alles!',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.05),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mathe • Deutsch • Sachkunde',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: LumoIdleFox(size: 56),
            ),
          ),
        ],
      ),
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
            child: Text('Welche Klasse?',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937))),
          ),
          SizedBox(
            height: 110,
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
      onTap: () => setState(() => _selectedGrade = g.grade),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 130,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [g.color, g.color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? g.color : const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: g.color.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${g.grade}.',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : g.color)),
            Text(g.title,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF374151))),
            Text(g.ageRange,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withOpacity(0.85)
                        : const Color(0xFF6B7280))),
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
                    color: s.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 10),
                Text(s.name,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937))),
                const Spacer(),
                Text('${s.topics.length} Themen',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280))),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openTopic(t, s),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: t.gradient[0].withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                              color: Color(0xFF1F2937))),
                      const SizedBox(height: 2),
                      Text(t.shortDesc,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                if (t.isWriting)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('✏️ Schreiben',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E))),
                  )
                else if (LearningModuleRegistry.hasModule(t.id))
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🎮 Übung',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46))),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('💬 Chat',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5B21B6))),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: t.gradient[0], size: 28),
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
      ));
      return;
    }
    // 0b) Wortmodus (Phase 5): Diktat mit Buchstabenfeldern.
    if (t.id == 'd1_woerter' && WritingFeatureFlags.enableWordMode) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            LumoWritingWordCoachScreen(appState: widget.appState),
      ));
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
      ));
      return;
    }
    // 2) Pruefe ob Topic ein registriertes echtes Modul hat
    final moduleBuilder =
        LearningModuleRegistry.builderFor(t.id, widget.appState);
    if (moduleBuilder != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => moduleBuilder,
      ));
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
    ));
  }
}
