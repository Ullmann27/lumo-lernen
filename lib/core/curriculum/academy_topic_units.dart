import '../school_exercise_generator.dart';

/// Keeps academy labels and real generated exercise units in sync.
/// No guessing a nearby topic when a selected curriculum tile is unavailable.
class AcademyTopicUnits {
  const AcademyTopicUnits._();

  static const Map<String, String> _aliases = {
    'm1_zahlen10': 'Mengenvergleich',
    'm1_formen': 'Geometrie Formen',
    'm2_zahlen100': 'Plus bis 100',
    'm2_einmaleins': 'Einmaleins Vorbereitung',
    'm2_uhr': 'Uhrzeit',
    'm2_geld': 'Geld wechseln',
    'm3_zahlen1000': 'Plus bis 1000',
    'm3_einmaleins_voll': 'Einmaleins',
    'm3_geometrie': 'Umfang',
    'm4_million': 'Zahlenraum bis 1 Million',
    'm4_bruch': 'Bruchrechnen einfach',
    'm4_textaufgaben': 'Sachaufgaben drei Schritte',
    'd1_schreibcoach': 'Buchstaben-Lautierung',
    'd1_buchstaben_alle': 'Buchstaben-Lautierung',
    'd1_woerter': 'Wort-Bild-Zuordnung',
    'd2_saetze': 'Erste Sätze',
    'd2_artikel': 'Artikel',
    'd2_mehrzahl': 'Einzahl und Mehrzahl',
    'd3_wortarten': 'Wortarten',
    'd3_zeitformen': 'Zeitformen',
    'd4_grammatik': 'Die 4 Fälle',
    's1_koerper': 'Körper',
    's3_oesterreich': 'Bundesländer Österreichs',
    's3_natur': 'Pflanzen',
    's4_europa': 'Kontinente und Ozeane',
    'en1_3': 'Begruessung',
  };

  /// null is deliberate: the UI must not claim that a different subject
  /// is the user's requested unit merely because it is in the same grade.
  /// Story/writing lessons have dedicated flows instead of multiple-choice.
  static String? exerciseUnit({
    required String topicId,
    required String title,
    required String subject,
    required int grade,
  }) {
    if (grade < 1 || grade > 4 ||
        topicId == 'd3_geschichten' || topicId == 'd4_aufsatz') {
      return null;
    }
    final unit = _aliases[topicId] ?? title;
    return Curriculum.unitsForGrade(subject, grade).contains(unit)
        ? unit
        : null;
  }
}
