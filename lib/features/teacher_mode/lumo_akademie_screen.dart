import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/curriculum/academy_topic_units.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../sections/lumo_learning_hub.dart';
import '../learning/learning_navigation.dart';
import '../learning_modules/learning_module_registry.dart';
import '../learning/curriculum_activities_screen.dart';
import '../learning/cross_grade_practice_screen.dart';
import '../learning/cross_grade_writing_screen.dart';
import '../writing/lumo_writing_coach_screen.dart';
import '../writing/lumo_writing_word_coach_screen.dart';
import '../writing/writing_feature_flags.dart';
import '../tutoring/guided_learning_hub.dart';
import '../learning/lab/learning_lab_hub.dart';
import '../story/lumo_story_library_screen.dart';
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
              name: 'Sachunterricht',
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
                  id: 's1_pflanzen',
                  title: 'Pflanzen',
                  icon: Icons.park_rounded,
                  gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  shortDesc: 'Wurzeln, Blätter, Blüten',
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
            LearningSubject(
              id: 'englisch1',
              name: 'Englisch',
              color: LumoColors.blue,
              icon: Icons.language_rounded,
              topics: const [
                LearningTopic(
                  id: 'en1_1',
                  title: 'Farben',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Einfache Wörter erkennen und sprechen',
                ),
                LearningTopic(
                  id: 'en1_2',
                  title: 'Tiere',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Einfache Wörter erkennen und sprechen',
                ),
                LearningTopic(
                  id: 'en1_3',
                  title: 'Begrüßung',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Einfache Wörter erkennen und sprechen',
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
              name: 'Sachunterricht',
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
            LearningSubject(
              id: 'englisch2',
              name: 'Englisch',
              color: LumoColors.blue,
              icon: Icons.language_rounded,
              topics: const [
                LearningTopic(
                  id: 'en2_1',
                  title: 'Zahlen',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Einfache Wörter erkennen und sprechen',
                ),
                LearningTopic(
                  id: 'en2_2',
                  title: 'Körper',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Einfache Wörter erkennen und sprechen',
                ),
                LearningTopic(
                  id: 'en2_3',
                  title: 'Spielzeug',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Einfache Wörter erkennen und sprechen',
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
                LearningTopic(
                  id: 'm3_schrift_add',
                  title: 'Schriftliche Addition',
                  icon: Icons.add_rounded,
                  gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                  shortDesc: 'Zahlen stellenrichtig addieren',
                ),
                LearningTopic(
                  id: 'm3_schrift_sub',
                  title: 'Schriftliche Subtraktion',
                  icon: Icons.remove_rounded,
                  gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                  shortDesc: 'Schrittweise schriftlich rechnen',
                ),
                LearningTopic(
                  id: 'm3_division',
                  title: 'Division einstellig',
                  icon: Icons.calculate_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Teilen und Rest verstehen',
                ),
                LearningTopic(
                  id: 'm3_sachaufgaben',
                  title: 'Sachaufgaben zwei Schritte',
                  icon: Icons.notes_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Text verstehen und rechnen',
                ),
                LearningTopic(
                  id: 'm3_gewicht',
                  title: 'Massen Kilogramm und Gramm',
                  icon: Icons.scale_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Gewicht schätzen und umrechnen',
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
                LearningTopic(
                  id: 'd3_grossschreibung',
                  title: 'Großschreibung',
                  icon: Icons.text_fields_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Namenwörter richtig schreiben',
                ),
                LearningTopic(
                  id: 'd3_faelle',
                  title: 'Wer-Fall und Wen-Fall',
                  icon: Icons.question_answer_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Satzfragen unterscheiden',
                ),
                LearningTopic(
                  id: 'd3_verbformen',
                  title: 'Verbformen',
                  icon: Icons.edit_note_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Verben passend verändern',
                ),
                LearningTopic(
                  id: 'd3_ie',
                  title: 'ie oder i',
                  icon: Icons.spellcheck_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Lange und kurze Laute',
                ),
              ],
            ),
            LearningSubject(
              id: 'sachk3',
              name: 'Sachunterricht',
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
                LearningTopic(
                  id: 's3_wetter',
                  title: 'Wetter',
                  icon: Icons.cloud_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Wetter verstehen und messen',
                ),
                LearningTopic(
                  id: 's3_verkehr',
                  title: 'Verkehr',
                  icon: Icons.traffic_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Sicher im Straßenverkehr',
                ),
                LearningTopic(
                  id: 's3_wasser',
                  title: 'Wasserkreislauf',
                  icon: Icons.water_drop_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Verdunstung und Niederschlag',
                ),
                LearningTopic(
                  id: 's3_ernaehrung',
                  title: 'Ernährung',
                  icon: Icons.restaurant_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Lebensmittel und Gesundheit',
                ),
                LearningTopic(
                  id: 's3_zeit',
                  title: 'Zeit und Kalender',
                  icon: Icons.event_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Wochen, Monate und Stunden',
                ),
                LearningTopic(
                  id: 's3_berufe',
                  title: 'Berufe',
                  icon: Icons.handyman_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Arbeiten und Berufe verstehen',
                ),
              ],
            ),
            LearningSubject(
              id: 'englisch3',
              name: 'Englisch',
              color: LumoColors.blue,
              icon: Icons.language_rounded,
              topics: const [
                LearningTopic(
                  id: 'en3_1',
                  title: 'Wetter',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Wortschatz verstehen und anwenden',
                ),
                LearningTopic(
                  id: 'en3_2',
                  title: 'Essen',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Wortschatz verstehen und anwenden',
                ),
                LearningTopic(
                  id: 'en3_3',
                  title: 'Schulsachen',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Wortschatz verstehen und anwenden',
                ),
                LearningTopic(
                  id: 'en3_4',
                  title: 'Tageszeit',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Morgen, Mittag, Abend und Nacht',
                ),
                LearningTopic(
                  id: 'en3_5',
                  title: 'Alltagssätze',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Einfache Gespräche führen',
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
                LearningTopic(
                  id: 'm4_multiplikation',
                  title: 'Schriftliche Multiplikation',
                  icon: Icons.close_rounded,
                  gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                  shortDesc: 'Größere Zahlen multiplizieren',
                ),
                LearningTopic(
                  id: 'm4_division',
                  title: 'Schriftliche Division',
                  icon: Icons.calculate_rounded,
                  gradient: [Color(0xFFFF8700), Color(0xFFFFB800)],
                  shortDesc: 'Mehrstellige Zahlen teilen',
                ),
                LearningTopic(
                  id: 'm4_dezimal',
                  title: 'Dezimalzahlen',
                  icon: Icons.pin_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Zehntel und Hundertstel',
                ),
                LearningTopic(
                  id: 'm4_bruch_erweitern',
                  title: 'Brüche erweitern',
                  icon: Icons.pie_chart_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Gleichwertige Brüche erkennen',
                ),
                LearningTopic(
                  id: 'm4_diagramme',
                  title: 'Diagramme lesen',
                  icon: Icons.bar_chart_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Daten verstehen und vergleichen',
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
                LearningTopic(
                  id: 'd4_satzglieder',
                  title: 'Satzglieder',
                  icon: Icons.segment_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Wer, was, wem, wen?',
                ),
                LearningTopic(
                  id: 'd4_direkte',
                  title: 'Direkte Rede',
                  icon: Icons.format_quote_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Anführungszeichen anwenden',
                ),
                LearningTopic(
                  id: 'd4_dassdas',
                  title: 'dass oder das',
                  icon: Icons.spellcheck_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Sätze richtig verbinden',
                ),
                LearningTopic(
                  id: 'd4_zusammensetzung',
                  title: 'Zusammensetzungen',
                  icon: Icons.layers_rounded,
                  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  shortDesc: 'Neue Wörter bilden',
                ),
              ],
            ),
            LearningSubject(
              id: 'sachk4',
              name: 'Sachunterricht',
              color: LumoColors.teal,
              icon: Icons.eco_rounded,
              topics: const [
                LearningTopic(
                  id: 's4_europa',
                  title: 'Kontinente und Ozeane',
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
                LearningTopic(
                  id: 's4_oekosystem',
                  title: 'Ökosysteme',
                  icon: Icons.eco_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Lebewesen und Lebensräume',
                ),
                LearningTopic(
                  id: 's4_strom',
                  title: 'Stromkreise',
                  icon: Icons.bolt_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Elektrizität sicher verstehen',
                ),
                LearningTopic(
                  id: 's4_diagramme',
                  title: 'Diagramme lesen',
                  icon: Icons.bar_chart_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Daten vergleichen und deuten',
                ),
                LearningTopic(
                  id: 's4_geografie',
                  title: 'Geografie Österreich',
                  icon: Icons.map_rounded,
                  gradient: [Color(0xFF10A894), Color(0xFF34D399)],
                  shortDesc: 'Flüsse, Berge und Bundesländer',
                ),
              ],
            ),
            LearningSubject(
              id: 'englisch4',
              name: 'Englisch',
              color: LumoColors.blue,
              icon: Icons.language_rounded,
              topics: const [
                LearningTopic(
                  id: 'en4_1',
                  title: 'Verben',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Wortschatz verstehen und anwenden',
                ),
                LearningTopic(
                  id: 'en4_2',
                  title: 'Wochentage',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Wortschatz verstehen und anwenden',
                ),
                LearningTopic(
                  id: 'en4_3',
                  title: 'Hobbys',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Wortschatz verstehen und anwenden',
                ),
                LearningTopic(
                  id: 'en4_4',
                  title: 'Länder',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Länder und ihre Namen',
                ),
                LearningTopic(
                  id: 'en4_5',
                  title: 'Alltagssätze',
                  icon: Icons.language_rounded,
                  gradient: [Color(0xFF2678BE), Color(0xFF52DDF9)],
                  shortDesc: 'Sätze im Alltag anwenden',
                ),
              ],
            ),
          ],
        ),
      ];
}

class LumoAkademieScreen extends StatefulWidget {
  const LumoAkademieScreen(
      {super.key,
      required this.appState,
      this.drawBackground = true,
      this.navigation});
  final LumoAppState appState;
  final bool drawBackground;
  final LearningNavigation? navigation;

  @override
  State<LumoAkademieScreen> createState() => _LumoAkademieScreenState();
}

class _LumoAkademieScreenState extends State<LumoAkademieScreen> {
  late final LearningNavigation _navigation =
      widget.navigation ?? LearningNavigation();
  bool _showTools = false;
  int get _selectedGrade => _navigation.gradeFor(widget.appState.state.grade);
  GradeLevel get _currentGrade =>
      LumoCurriculum.grades.firstWhere((g) => g.grade == _selectedGrade);

  @override
  void dispose() {
    if (widget.navigation == null) _navigation.dispose();
    super.dispose();
  }

  void _beginClearLearningTask(String subject, String unit) {
    // Preserve real interactive modules on the primary path as well as the
    // original writing/story flows; all other units use the local generator.
    for (final s in _currentGrade.subjects.where((s) => s.name == subject)) {
      for (final topic in s.topics) {
        if (AcademyTopicUnits.exerciseUnit(
                topicId: topic.id,
                title: topic.title,
                subject: subject,
                grade: _selectedGrade) ==
            unit) {
          _openTopic(topic, s);
          return;
        }
      }
    }
    if (_selectedGrade != widget.appState.state.grade) {
      Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => CrossGradePracticeScreen(
              profileName: widget.appState.state.childName,
              enrolledGrade: widget.appState.state.grade,
              lessonGrade: _selectedGrade,
              subject: subject,
              unit: unit)));
      return;
    }
    widget.appState.update(widget.appState.state.copyWith(
        section: LumoSection.exercises,
        subject: subject,
        unit: unit,
        mood: LumoMood.point,
        sessionKind: LumoSessionKind.quickPractice,
        lumoMessage:
            'Wir üben ${Curriculum.prettifyUnit(unit)}. Ich helfe dir.'));
  }

  void _openReading() {
    if (_selectedGrade != widget.appState.state.grade) {
      _openStories();
      return;
    }
    widget.appState.update(widget.appState.state.copyWith(
        section: LumoSection.reading, subject: 'Lesen', unit: 'Aktives Lesen'));
  }

  Widget _tools() => LumoGlassCard(
      child: Material(
          color: Colors.transparent,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Dein Lernatelier',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontSize: 21,
                    fontWeight: FontWeight.w900)),
            ListTile(
                key: const ValueKey('academy-stories'),
                leading: const Icon(Icons.auto_stories_rounded,
                    color: LumoVisualTokens.cyanBright),
                title: const Text('Geschichten und Rätsel',
                    style: TextStyle(color: Colors.white)),
                onTap: _openStories),
            for (final subject in _currentGrade.subjects)
              for (final topic in subject.topics.where((t) =>
                  t.isWriting ||
                  t.id == 'd1_schreibcoach' ||
                  t.id == 'd1_woerter' ||
                  t.id == 'd4_aufsatz'))
                ListTile(
                    key: ValueKey('academy-tool-${topic.id}'),
                    leading:
                        Icon(topic.icon, color: LumoVisualTokens.cyanBright),
                    title: Text(topic.title,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(topic.shortDesc,
                        style: const TextStyle(color: LumoVisualTokens.muted)),
                    onTap: () => _openTopic(topic, subject)),
            ListTile(
                key: const ValueKey('akademie-learning-lab'),
                leading: const Icon(Icons.science_rounded,
                    color: LumoVisualTokens.cyanBright),
                title: const Text('Lumos interaktives Lernatelier',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(
                    builder: (_) =>
                        LearningLabHub(appState: widget.appState)))),
            ListTile(
                key: const ValueKey('akademie-guided-learning'),
                leading: const Icon(Icons.school_rounded,
                    color: LumoVisualTokens.cyanBright),
                title: const Text('Lumo erklärt es mir',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(
                    builder: (_) => GuidedLearningHub(
                        appState: widget.appState, discovery: false)))),
            ListTile(
                key: const ValueKey('akademie-voluntary-discovery'),
                leading: const Icon(Icons.explore_rounded,
                    color: LumoVisualTokens.cyanBright),
                title: const Text('Mit Lumo Neues entdecken',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(
                    builder: (_) => GuidedLearningHub(
                        appState: widget.appState, discovery: true)))),
          ])));

  @override
  Widget build(BuildContext context) {
    final hub = SafeArea(
        top: widget.drawBackground,
        bottom: false,
        child: AnimatedBuilder(
            animation: Listenable.merge([widget.appState, _navigation]),
            builder: (context, _) => LumoLearningHub(
                grade: widget.appState.state.grade,
                navigation: _navigation,
                skills: _selectedGrade == widget.appState.state.grade
                    ? widget.appState.learningSkills()
                    : const {},
                onStartUnit: _beginClearLearningTask,
                onReading: _openReading,
                onPracticalSubject: (subject) => Navigator.of(context)
                    .push<void>(MaterialPageRoute(
                        builder: (_) => CurriculumActivitiesScreen(
                            grade: _selectedGrade, subject: subject))),
                onAdvanced: () => setState(() => _showTools = !_showTools),
                tools: _showTools ? _tools() : null)));
    return Scaffold(
        backgroundColor:
            widget.drawBackground ? LumoVisualTokens.night : Colors.transparent,
        body: widget.drawBackground
            ? LumoSceneBackground(
                scene: LumoScene.learning,
                showPlaceholderLabel: false,
                dimmed: true,
                child: hub)
            : hub);
  }

  void _openStories() {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => LumoStoryLibraryScreen(
        appState: widget.appState,
        gradeLevel: _selectedGrade,
      ),
    ));
  }

  void _openTopic(LearningTopic t, LearningSubject s) {
    // Local story selection is independent of the enrolled profile grade.
    // Opening the library does not award regular learning progress.
    if (t.id == 'd3_geschichten') {
      _openStories();
      return;
    }
    // Creative writing cannot be represented by unrelated multiple-choice
    // tasks. The voluntary fourth-grade route stores its own draft.
    if (t.id == 'd4_aufsatz' && _selectedGrade != widget.appState.state.grade) {
      Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => CrossGradeWritingScreen(
          profileName: widget.appState.state.childName,
          enrolledGrade: widget.appState.state.grade,
        ),
      ));
      return;
    }
    // Viewing any non-enrolled grade is real practice, not a teaser or
    // implicit discovery redirect. Progress stays separate from the child's
    // official school grade and its XP/wallet records.
    if (_selectedGrade != widget.appState.state.grade) {
      final unit = AcademyTopicUnits.exerciseUnit(
        topicId: t.id,
        title: t.title,
        subject: s.name,
        grade: _selectedGrade,
      );
      if (unit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            'Für ${s.name} in der $_selectedGrade. Klasse sind noch keine '
            'fertigen Übungen vorhanden.',
          )),
        );
        return;
      }
      Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => CrossGradePracticeScreen(
          profileName: widget.appState.state.childName,
          enrolledGrade: widget.appState.state.grade,
          lessonGrade: _selectedGrade,
          subject: s.name,
          unit: unit,
        ),
      ));
      return;
    }
    // Same-grade science and English retain their registered specialist modules
    // and otherwise start an exact, locally generated curriculum unit.
    if (s.name == 'Englisch' || s.name == 'Sachunterricht') {
      // Eigene Fachmodule (Tiere, Jahreszeiten, Wetter, Verkehr) haben
      // Vorrang vor dem Aufgabengenerator; vorher waren sie von keiner Kachel
      // aus erreichbar, obwohl die Kachel „🎮 Übung“ anzeigt.
      final dedicated =
          LearningModuleRegistry.builderFor(t.id, widget.appState);
      if (dedicated != null) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => dedicated));
        return;
      }
      final subject = s.name;
      final topicUnit = AcademyTopicUnits.exerciseUnit(
        topicId: t.id,
        title: t.title,
        subject: subject,
        grade: _selectedGrade,
      );
      if (topicUnit == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Für ${t.title} gibt es noch keine passende Übung.'),
        ));
        return;
      }
      widget.appState.update(widget.appState.state.copyWith(
        section: LumoSection.exercises,
        subject: subject,
        unit: topicUnit,
        mood: LumoMood.point,
        lumoMessage: 'Wir üben $topicUnit. Ich helfe dir Schritt für Schritt.',
      ));
      return;
    }
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
    // A grade tile is an actionable lesson. Preserve dedicated live modules,
    // then route all generator-backed Mathematics/German topics to actual
    // local exercises instead of the old online-only teacher chat.
    if (s.name == 'Mathematik' || s.name == 'Deutsch') {
      final unit = AcademyTopicUnits.exerciseUnit(
        topicId: t.id,
        title: t.title,
        subject: s.name,
        grade: _selectedGrade,
      );
      if (unit != null) {
        widget.appState.update(widget.appState.state.copyWith(
          section: LumoSection.exercises,
          subject: s.name,
          unit: unit,
          mood: LumoMood.point,
          lumoMessage: 'Wir üben ${Curriculum.prettifyUnit(unit)}.',
        ));
        return;
      }
    }
    if (t.id == 'd4_aufsatz') {
      Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => LumoWritingCoachScreen(appState: widget.appState),
      ));
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
