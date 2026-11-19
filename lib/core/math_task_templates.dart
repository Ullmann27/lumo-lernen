import 'holo_lesson_catalog.dart';
import 'shape_question_data.dart';

/// Deterministische Mathe-Templates für Volksschule 1-4.
///
/// Der Generator wählt nur noch ein Template und konkretisiert es über Seed.
/// Dadurch entstehen pro Einheit viele Varianten mit stabilem Prompt-Pattern.
class MathTaskTemplates {
  const MathTaskTemplates._();

  static const List<MathTaskTemplate> templates = <MathTaskTemplate>[
    // Kleinste Zahl in Geschichten ist 2: „Tom hat 1 Kekse“ wäre falsches Deutsch.
    MathTaskTemplate(id: 'g1_word_problem', grade: 1, unit: 'Textaufgaben', kind: MathTemplateKind.wordProblemOneStep, validRangeA: <int>[2, 9], validRangeB: <int>[2, 6], promptPattern: 'sachaufgabe-ein-schritt'),
    MathTaskTemplate(id: 'g2_sub_story', grade: 2, unit: 'Textaufgaben', kind: MathTemplateKind.wordProblemOneStep, validRangeA: <int>[5, 20], validRangeB: <int>[2, 6], promptPattern: 'sachaufgabe-wegnehmen'),
    MathTaskTemplate(id: 'g1_add_10', grade: 1, unit: 'Plus bis 10', kind: MathTemplateKind.addition, validRangeA: <int>[0, 10], validRangeB: <int>[0, 10], promptPattern: 'plus-bis-10',
    ),
    MathTaskTemplate(id: 'g1_sub_10', grade: 1, unit: 'Minus bis 10', kind: MathTemplateKind.subtraction, validRangeA: <int>[3, 10], validRangeB: <int>[1, 7], promptPattern: 'minus-bis-10',
    ),
    // AT-Lehrplan 2023: Zahlenraum 20 schon in der 1. Schulstufe.
    MathTaskTemplate(id: 'g1_add_20', grade: 1, unit: 'Plus bis 20', kind: MathTemplateKind.addition, validRangeA: <int>[2, 12], validRangeB: <int>[1, 8], promptPattern: 'plus-bis-20',
    ),
    MathTaskTemplate(id: 'g1_sub_20', grade: 1, unit: 'Minus bis 20', kind: MathTemplateKind.subtraction, validRangeA: <int>[10, 20], validRangeB: <int>[1, 9], promptPattern: 'minus-bis-20',
    ),
    MathTaskTemplate(id: 'g1_number_line', grade: 1, unit: 'Zahlenstrahl', kind: MathTemplateKind.numberLineMissing, validRangeA: <int>[0, 17], validRangeB: <int>[0, 2], promptPattern: 'zahlenstrahl-fehlt',
    ),
    MathTaskTemplate(id: 'g1_quantity_compare', grade: 1, unit: 'Mengenvergleich', kind: MathTemplateKind.quantityCompare, validRangeA: <int>[1, 8], validRangeB: <int>[1, 8], promptPattern: 'menge-vergleichen',
    ),
    MathTaskTemplate(id: 'g1_number_word', grade: 1, unit: 'Zahl in Worten', kind: MathTemplateKind.numberWord, validRangeA: <int>[0, 20], validRangeB: <int>[0, 1], promptPattern: 'zahlwort-erkennen',
    ),
    MathTaskTemplate(id: 'g1_shapes', grade: 1, unit: 'Geometrie Formen', kind: MathTemplateKind.shapeRecognition, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'formen-erkennen',
    ),
    MathTaskTemplate(id: 'g1_money_more', grade: 1, unit: 'Geld', kind: MathTemplateKind.moneyCompare, validRangeA: <int>[1, 8], validRangeB: <int>[1, 8], promptPattern: 'geld-mehr',
    ),
    MathTaskTemplate(id: 'g1_day_hours', grade: 1, unit: 'Zeit', kind: MathTemplateKind.dayHours, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'tag-stunden',
    ),
    MathTaskTemplate(id: 'g1_symmetry', grade: 1, unit: 'Symmetrie', kind: MathTemplateKind.symmetry, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'symmetrie-form',
    ),

    MathTaskTemplate(id: 'g2_add_20', grade: 2, unit: 'Plus bis 20', kind: MathTemplateKind.addition, validRangeA: <int>[2, 18], validRangeB: <int>[1, 12], promptPattern: 'plus-bis-20',
    ),
    MathTaskTemplate(id: 'g2_sub_20', grade: 2, unit: 'Minus bis 20', kind: MathTemplateKind.subtraction, validRangeA: <int>[8, 20], validRangeB: <int>[1, 14], promptPattern: 'minus-bis-20',
    ),
    // AT-Lehrplan 2023: Zahlenraum 100 und das kleine Einmaleins gehören in die 2. Schulstufe.
    // Klasse 3 wiederholt sie weiterhin (g3_add_100, g3_sub_100, g3_tables).
    MathTaskTemplate(id: 'g2_add_100', grade: 2, unit: 'Plus bis 100', kind: MathTemplateKind.addition, validRangeA: <int>[10, 70], validRangeB: <int>[5, 30], promptPattern: 'plus-bis-100',
    ),
    MathTaskTemplate(id: 'g2_sub_100', grade: 2, unit: 'Minus bis 100', kind: MathTemplateKind.subtraction, validRangeA: <int>[30, 100], validRangeB: <int>[5, 29], promptPattern: 'minus-bis-100',
    ),
    MathTaskTemplate(id: 'g2_tables', grade: 2, unit: 'Einmaleins', kind: MathTemplateKind.multiplication, validRangeA: <int>[2, 10], validRangeB: <int>[1, 10], promptPattern: 'einmaleins',
    ),
    MathTaskTemplate(id: 'g2_times_prep', grade: 2, unit: 'Einmaleins Vorbereitung', kind: MathTemplateKind.multiplicationPrep, validRangeA: <int>[2, 5], validRangeB: <int>[2, 10], promptPattern: 'wie-oft-in-zahl',
    ),
    MathTaskTemplate(id: 'g2_word_problem', grade: 2, unit: 'Textaufgaben', kind: MathTemplateKind.wordProblemOneStep, validRangeA: <int>[4, 18], validRangeB: <int>[2, 12], promptPattern: 'sachaufgabe-ein-schritt',
    ),
    MathTaskTemplate(id: 'g2_money_change', grade: 2, unit: 'Geld wechseln', kind: MathTemplateKind.moneyChange, validRangeA: <int>[2, 20], validRangeB: <int>[1, 5], promptPattern: 'geld-wechseln',
    ),
    MathTaskTemplate(id: 'g2_clock', grade: 2, unit: 'Uhrzeit', kind: MathTemplateKind.clockTime, validRangeA: <int>[1, 12], validRangeB: <int>[0, 3], promptPattern: 'uhrzeit-viertel-halbe',
    ),
    MathTaskTemplate(id: 'g2_length', grade: 2, unit: 'Längen', kind: MathTemplateKind.lengthConversion, validRangeA: <int>[1, 10], validRangeB: <int>[0, 5], promptPattern: 'meter-zentimeter',
    ),
    MathTaskTemplate(id: 'g2_even_odd', grade: 2, unit: 'Gerade und ungerade', kind: MathTemplateKind.evenOdd, validRangeA: <int>[1, 100], validRangeB: <int>[0, 0], promptPattern: 'gerade-ungerade',
    ),
    MathTaskTemplate(id: 'g2_half_double', grade: 2, unit: 'Verdoppeln und Halbieren', kind: MathTemplateKind.halfDouble, validRangeA: <int>[2, 50], validRangeB: <int>[0, 1], promptPattern: 'halb-doppelt-groesser',
    ),
    MathTaskTemplate(id: 'g2_tens_ones', grade: 2, unit: 'Zehner und Einer', kind: MathTemplateKind.tensOnes, validRangeA: <int>[10, 99], validRangeB: <int>[0, 1], promptPattern: 'zehner-einer',
    ),

    MathTaskTemplate(id: 'g3_tables', grade: 3, unit: 'Einmaleins', kind: MathTemplateKind.multiplication, validRangeA: <int>[0, 10], validRangeB: <int>[0, 10], promptPattern: 'einmaleins',
    ),
    MathTaskTemplate(id: 'g3_written_add', grade: 3, unit: 'Schriftliche Addition', kind: MathTemplateKind.writtenAddition, validRangeA: <int>[120, 899], validRangeB: <int>[80, 699], promptPattern: 'schriftliche-addition',
    ),
    MathTaskTemplate(id: 'g3_written_sub', grade: 3, unit: 'Schriftliche Subtraktion', kind: MathTemplateKind.writtenSubtraction, validRangeA: <int>[220, 999], validRangeB: <int>[50, 499], promptPattern: 'schriftliche-subtraktion',
    ),
    MathTaskTemplate(id: 'g3_fraction_half', grade: 3, unit: 'Brüche Vorbereitung', kind: MathTemplateKind.fractionHalf, validRangeA: <int>[2, 40], validRangeB: <int>[0, 0], promptPattern: 'haelfte-als-bruchvorbereitung',
    ),
    MathTaskTemplate(id: 'g3_two_step', grade: 3, unit: 'Sachaufgaben zwei Schritte', kind: MathTemplateKind.wordProblemTwoStep, validRangeA: <int>[5, 30], validRangeB: <int>[2, 12], promptPattern: 'sachaufgabe-zwei-schritte',
    ),
    MathTaskTemplate(id: 'g3_perimeter', grade: 3, unit: 'Umfang', kind: MathTemplateKind.perimeter, validRangeA: <int>[2, 18], validRangeB: <int>[2, 18], promptPattern: 'umfang-rechteck',
    ),
    // AT-Lehrplan-Korrektur 2026-06-03: Flaecheninhalt ist Klasse-4-Stoff
    // (BMBWF Mathe-Lehrplan VS). Vorher faelschlich als g3_area gefuehrt
    // -> Klasse 3 sah eine Aufgabe die laut Lehrplan erst Klasse 4 dran ist.
    MathTaskTemplate(id: 'g3_add_100', grade: 3, unit: 'Plus bis 100', kind: MathTemplateKind.addition, validRangeA: <int>[10, 90], validRangeB: <int>[5, 80], promptPattern: 'plus-bis-100',
    ),
    MathTaskTemplate(id: 'g3_sub_100', grade: 3, unit: 'Minus bis 100', kind: MathTemplateKind.subtraction, validRangeA: <int>[20, 100], validRangeB: <int>[5, 70], promptPattern: 'minus-bis-100',
    ),
    // Neue Klasse-3-Lehrplan-Templates (AT Lehrplan 2023):
    MathTaskTemplate(id: 'g3_add_1000', grade: 3, unit: 'Plus bis 1000', kind: MathTemplateKind.addition, validRangeA: <int>[120, 600], validRangeB: <int>[80, 400], promptPattern: 'plus-bis-1000',
    ),
    MathTaskTemplate(id: 'g3_sub_1000', grade: 3, unit: 'Minus bis 1000', kind: MathTemplateKind.subtraction, validRangeA: <int>[300, 999], validRangeB: <int>[100, 500], promptPattern: 'minus-bis-1000',
    ),
    MathTaskTemplate(id: 'g3_division_basic', grade: 3, unit: 'Division einstellig', kind: MathTemplateKind.division, validRangeA: <int>[12, 90], validRangeB: <int>[2, 9], promptPattern: 'geteilt-einstellig',
    ),
    MathTaskTemplate(id: 'g3_money_change_100', grade: 3, unit: 'Geld bis 100 Euro', kind: MathTemplateKind.moneyChange, validRangeA: <int>[5, 50], validRangeB: <int>[1, 5], promptPattern: 'geld-bis-100',
    ),
    MathTaskTemplate(id: 'g3_mass', grade: 3, unit: 'Massen Kilogramm und Gramm', kind: MathTemplateKind.massConversion, validRangeA: <int>[1, 50], validRangeB: <int>[1, 4], promptPattern: 'kg-zu-g',
    ),

    MathTaskTemplate(id: 'g4_written_mul', grade: 4, unit: 'Schriftliche Multiplikation', kind: MathTemplateKind.writtenMultiplication, validRangeA: <int>[12, 999], validRangeB: <int>[2, 12], promptPattern: 'schriftliche-multiplikation',
    ),
    MathTaskTemplate(id: 'g4_written_div', grade: 4, unit: 'Schriftliche Division', kind: MathTemplateKind.division, validRangeA: <int>[20, 999], validRangeB: <int>[2, 12], promptPattern: 'schriftliche-division',
    ),
    MathTaskTemplate(id: 'g4_fraction_add', grade: 4, unit: 'Bruchrechnen einfach', kind: MathTemplateKind.simpleFractionAdd, validRangeA: <int>[1, 8], validRangeB: <int>[1, 8], promptPattern: 'gleichnamige-brueche-addieren',
    ),
    MathTaskTemplate(id: 'g4_decimal', grade: 4, unit: 'Dezimalzahlen', kind: MathTemplateKind.decimals, validRangeA: <int>[1, 99], validRangeB: <int>[1, 99], promptPattern: 'dezimalzahlen-addieren',
    ),
    MathTaskTemplate(id: 'g4_three_step', grade: 4, unit: 'Sachaufgaben drei Schritte', kind: MathTemplateKind.wordProblemThreeStep, validRangeA: <int>[5, 60], validRangeB: <int>[2, 20], promptPattern: 'sachaufgabe-drei-schritte',
    ),
    MathTaskTemplate(id: 'g4_chart', grade: 4, unit: 'Diagramme lesen', kind: MathTemplateKind.chartRead, validRangeA: <int>[4, 40], validRangeB: <int>[4, 40], promptPattern: 'diagramm-lesen',
    ),
    MathTaskTemplate(id: 'g4_compare', grade: 4, unit: 'Vergleichen', kind: MathTemplateKind.compare, validRangeA: <int>[1, 999], validRangeB: <int>[1, 999], promptPattern: 'zahlen-vergleichen',
    ),
    // Neue Klasse-4-Lehrplan-Templates (AT Lehrplan 2023):
    MathTaskTemplate(id: 'g4_add_10000', grade: 4, unit: 'Plus bis 10000', kind: MathTemplateKind.addition, validRangeA: <int>[1200, 6000], validRangeB: <int>[800, 4000], promptPattern: 'plus-bis-10000',
    ),
    MathTaskTemplate(id: 'g4_sub_10000', grade: 4, unit: 'Minus bis 10000', kind: MathTemplateKind.subtraction, validRangeA: <int>[3000, 9999], validRangeB: <int>[800, 4000], promptPattern: 'minus-bis-10000',
    ),
    MathTaskTemplate(id: 'g4_compare_1mio', grade: 4, unit: 'Zahlenraum bis 1 Million', kind: MathTemplateKind.compare, validRangeA: <int>[10000, 999999], validRangeB: <int>[10000, 999999], promptPattern: 'vergleichen-grosse-zahlen',
    ),
    MathTaskTemplate(id: 'g4_time_minutes', grade: 4, unit: 'Zeit Minuten und Stunden', kind: MathTemplateKind.timeMinutes, validRangeA: <int>[1, 50], validRangeB: <int>[1, 4], promptPattern: 'stunden-zu-minuten',
    ),
    MathTaskTemplate(id: 'g4_volume', grade: 4, unit: 'Hohlmaße Liter und Milliliter', kind: MathTemplateKind.volumeConversion, validRangeA: <int>[1, 50], validRangeB: <int>[1, 4], promptPattern: 'l-zu-ml',
    ),
    MathTaskTemplate(id: 'g4_fraction_expand', grade: 4, unit: 'Brüche erweitern', kind: MathTemplateKind.fractionExpand, validRangeA: <int>[2, 30], validRangeB: <int>[2, 6], promptPattern: 'bruch-erweitern',
    ),
    MathTaskTemplate(id: 'g4_average', grade: 4, unit: 'Mittelwert', kind: MathTemplateKind.average, validRangeA: <int>[6, 60], validRangeB: <int>[2, 6], promptPattern: 'durchschnitt',
    ),
    // AT-Lehrplan-konform: Flaecheninhalt erst Klasse 4 (vorher g3_area).
    MathTaskTemplate(id: 'g4_area', grade: 4, unit: 'Flächeninhalt', kind: MathTemplateKind.area, validRangeA: <int>[2, 12], validRangeB: <int>[2, 12], promptPattern: 'flaeche-rechteck',
    ),
    MathTaskTemplate(id: 'g4_symmetry_lines', grade: 4, unit: 'Symmetrieachsen', kind: MathTemplateKind.symmetry, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'symmetrieachsen',
    ),
    // 2026-06-05 Iter 20: Form-Nachzeichnen. Kind sieht erst Demo (Strich
    // fuer Strich), dann zeichnet selbst nach. Eigener Renderer. Pro
    // Klassenstufe ein paar Formen mit steigender Komplexitaet.
    MathTaskTemplate(id: 'g1_trace_square', grade: 1, unit: 'Formen Nachzeichnen', kind: MathTemplateKind.shapeTrace, validRangeA: <int>[0, 0], validRangeB: <int>[0, 0], promptPattern: 'nachzeichnen-quadrat',
    ),
    MathTaskTemplate(id: 'g1_trace_circle', grade: 1, unit: 'Formen Nachzeichnen', kind: MathTemplateKind.shapeTrace, validRangeA: <int>[1, 1], validRangeB: <int>[0, 0], promptPattern: 'nachzeichnen-kreis',
    ),
    MathTaskTemplate(id: 'g1_trace_triangle', grade: 1, unit: 'Formen Nachzeichnen', kind: MathTemplateKind.shapeTrace, validRangeA: <int>[2, 2], validRangeB: <int>[0, 0], promptPattern: 'nachzeichnen-dreieck',
    ),
    MathTaskTemplate(id: 'g2_trace_rectangle', grade: 2, unit: 'Formen Nachzeichnen', kind: MathTemplateKind.shapeTrace, validRangeA: <int>[3, 3], validRangeB: <int>[0, 0], promptPattern: 'nachzeichnen-rechteck',
    ),
    MathTaskTemplate(id: 'g2_trace_star', grade: 2, unit: 'Formen Nachzeichnen', kind: MathTemplateKind.shapeTrace, validRangeA: <int>[4, 4], validRangeB: <int>[0, 0], promptPattern: 'nachzeichnen-stern',
    ),
  ];

  static bool supportsUnit(int grade, String unit) {
    if (unit == 'Alle') return true;
    final capped = grade.clamp(1, 4);
    return templates.any((template) => template.grade <= capped &&
        (template.unit == unit ||
            (_legacyUnitAliases[unit]?.contains(template.unit) ?? false)));
  }

  static List<MathTaskTemplate> templatesForGrade(int grade, {String? unit}) {
    final capped = grade.clamp(1, 4);
    final pool = templates.where((template) => template.grade <= capped).where((template) {
      if (unit == null || unit == 'Alle') return true;
      if (template.unit == unit) return true;
      return _legacyUnitAliases[unit]?.contains(template.unit) ?? false;
    }).toList(growable: false);
    if (pool.isNotEmpty) return pool;
    return templates.where((template) => template.grade <= capped).toList(growable: false);
  }

  /// Liefert nur die Templates der EXAKTEN Klasse - keine Wiederholung aus
  /// niedrigeren Klassen. Wird beim regulaeren Ueben genutzt damit das
  /// Niveau zur Schulstufe passt (Heinz 2026-06-03: "nicht zu einfach,
  /// angepasst auf jede Schulstufe").
  static List<MathTaskTemplate> templatesForGradeStrict(int grade, {String? unit,
  }) {
    final capped = grade.clamp(1, 4);
    final pool = templates.where((template) => template.grade == capped).where((template) {
      if (unit == null || unit == 'Alle') return true;
      if (template.unit == unit) return true;
      return _legacyUnitAliases[unit]?.contains(template.unit) ?? false;
    }).toList(growable: false);
    if (pool.isNotEmpty) return pool;
    return templatesForGrade(grade, unit: unit);
  }

  static MathConcreteTask generate({required int grade, required String unit, required int seed,
  }) {
    // 75% aktuelle Klassenstufe (strict), 25% Wiederholung aus Vorjahren.
    final useStrict = seed.abs() % 4 != 0;
    final available = templatesForGrade(grade, unit: unit);
    // Exact cumulative topics outrank current-grade aliases. Otherwise a
    // selected review topic such as 'Geld' can become 'Geld wechseln'.
    final exact = available.where((item) => item.unit == unit).toList();
    final current = exact
        .where((item) => item.grade == grade.clamp(1, 4))
        .toList();
    final selected = exact.isNotEmpty
        ? (useStrict && current.isNotEmpty ? current : exact)
        : (useStrict
            ? templatesForGradeStrict(grade, unit: unit)
            : available);
    // Auswahl und Wiederholungsquote dürfen nicht denselben Modulo nutzen:
    // Bei 16 Templates wären sonst ganze Familien nie erreichbar.
    final template = selected[_positive(_mixSeed(seed + 101), selected.length)];
    return template.concretize(_mixSeed(seed + 809), forGrade: grade.clamp(1, 4).toInt());
  }

  /// Vier Antwortkarten für eine Zahlenaufgabe, auch für Spiele und Logik.
  ///
  /// Die Lösung liegt der Größe nach gleichmäßig verteilt an jeder Stelle,
  /// die falschen Karten stammen zuerst aus [typical] (typische Fehler der
  /// Aufgabenart). Keine Karte ist negativ, doppelt, außerhalb von
  /// [min]..[max] oder in [blocked].
  static List<String> numberChoices(
    int answer,
    int seed, {
    List<int> typical = const <int>[],
    int min = 0,
    int? max,
    Set<int> blocked = const <int>{},
  }) =>
      _numericChoices(answer, seed,
          typical: typical, min: min, max: max, blocked: blocked);

  /// Typische falsche Ergebnisse einer Plusaufgabe a + b.
  static List<int> additionErrors(int a, int b) => _additionErrors(a, b);

  /// Typische falsche Ergebnisse einer Minusaufgabe a − b.
  static List<int> subtractionErrors(int a, int b) => _subtractionErrors(a, b);

  static const Map<String, List<String>> _legacyUnitAliases = <String, List<String>>{
    'Zahlenreihe': <String>['Zahlenstrahl'],
    'Nachbarzahlen': <String>['Zahlenstrahl'],
    'Zahlen zerlegen': <String>['Zehner und Einer', 'Plus bis 20'],
    'Rechenhaeuser': <String>['Plus bis 20'],
    'Rechenhäuser': <String>['Plus bis 20'],
    'Minus ueber 10': <String>['Minus bis 20'],
    'Minus über 10': <String>['Minus bis 20'],
    'Blitzlicht': <String>['Plus bis 20', 'Minus bis 20'],
    'Textaufgaben': <String>['Textaufgaben', 'Sachaufgaben zwei Schritte', 'Sachaufgaben drei Schritte',
        ],
    'Uhrzeit': <String>['Uhrzeit'],
    'Geld': <String>['Geld', 'Geld wechseln'],
    'Geometrie Formen': <String>['Geometrie Formen', 'Umfang', 'Flächeninhalt',
        ],
    'Vergleichen': <String>['Vergleichen', 'Mengenvergleich'],
    'Gerade und ungerade': <String>['Gerade und ungerade'],
    'Verdoppeln und Halbieren': <String>['Verdoppeln und Halbieren'],
  };
}

/// Zahlen ab 10 000 in Dreiergruppen mit geschütztem Leerzeichen:
/// 925 407 statt 925407. Kleinere Zahlen bleiben unverändert.
String groupedNumber(int value) {
  final digits = '$value';
  if (value < 10000) return digits;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u00A0');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Liest eine mit [groupedNumber] geschriebene Zahl.
int? parseGroupedNumber(String text) =>
    int.tryParse(text.replaceAll('\u00A0', ''));

/// „Welches Zeichen passt? 925 407 ⬜ 945 369“ (auch die ältere Schreibweise
/// mit „?“ als Lücke). Gruppe 1 und 2 sind die beiden Zahlen.
final RegExp comparePromptPattern = RegExp(
    '^Welches Zeichen passt\\? ([\\d\u00A0]+) [?⬜] ([\\d\u00A0]+)\$');

/// Klasse 1, Symmetrie: Dinge zum Falten (im Wen-Fall) und ob beide Hälften
/// aufeinanderpassen. Gleich viele „ja“ und „nein“. Buchstaben und Ziffern
/// mit nur waagrechter Achse (B, C, D, E, 3) fehlen bewusst: Dort hängt die
/// Antwort von der Schrift ab.
const List<(String, bool)> symmetryFoldExamples = <(String, bool)>[
  ('ein Herz aus Papier', true),
  ('einen Schmetterling aus Papier', true),
  ('einen Kreis aus Papier', true),
  ('ein Quadrat aus Papier', true),
  ('den Druckbuchstaben A', true),
  ('den Druckbuchstaben H', true),
  ('den Druckbuchstaben M', true),
  ('den Druckbuchstaben O', true),
  ('den Druckbuchstaben T', true),
  ('den Druckbuchstaben U', true),
  ('den Druckbuchstaben V', true),
  ('den Druckbuchstaben W', true),
  ('den Druckbuchstaben Y', true),
  ('die Ziffer 8', true),
  ('die Ziffer 0', true),
  ('den Druckbuchstaben F', false),
  ('den Druckbuchstaben G', false),
  ('den Druckbuchstaben J', false),
  ('den Druckbuchstaben L', false),
  ('den Druckbuchstaben N', false),
  ('den Druckbuchstaben P', false),
  ('den Druckbuchstaben Q', false),
  ('den Druckbuchstaben R', false),
  ('den Druckbuchstaben S', false),
  ('den Druckbuchstaben Z', false),
  ('die Ziffer 2', false),
  ('die Ziffer 5', false),
  ('die Ziffer 6', false),
  ('die Ziffer 7', false),
  ('die Ziffer 9', false),
];

/// Klasse 4, Symmetrieachsen: Figur und Anzahl ihrer Spiegelachsen.
const List<(String, int)> symmetryAxisExamples = <(String, int)>[
  ('ein Quadrat', 4),
  ('ein Rechteck, das kein Quadrat ist', 2),
  ('ein gleichseitiges Dreieck', 3),
  ('ein gleichschenkliges Dreieck, das nicht gleichseitig ist', 1),
  ('ein Dreieck mit drei verschieden langen Seiten', 0),
  ('eine Raute, die kein Quadrat ist', 2),
  ('ein Parallelogramm, das weder Rechteck noch Raute ist', 0),
  ('ein gleichschenkliges Trapez', 1),
  ('ein Drachenviereck, das keine Raute ist', 1),
  ('ein regelmäßiges Fünfeck', 5),
  ('ein regelmäßiges Sechseck', 6),
  ('ein regelmäßiges Achteck', 8),
  ('ein Halbkreis', 1),
  ('ein Herz', 1),
  ('ein Stern mit fünf gleichen Zacken', 5),
  ('der Druckbuchstabe A', 1),
  ('der Druckbuchstabe T', 1),
  ('der Druckbuchstabe M', 1),
  ('der Druckbuchstabe H', 2),
  ('der Druckbuchstabe F', 0),
  ('der Druckbuchstabe Z', 0),
  ('der Druckbuchstabe N', 0),
];

class MathTaskTemplate {
  const MathTaskTemplate({
    required this.id,
    required this.grade,
    required this.unit,
    required this.kind,
    required this.validRangeA,
    required this.validRangeB,
    required this.promptPattern,
  });

  final String id;
  final int grade;
  final String unit;
  final MathTemplateKind kind;
  final List<int> validRangeA;
  final List<int> validRangeB;
  final String promptPattern;

  /// [forGrade] ist die Klasse des Kindes, wenn eine Vorlage in einer höheren
  /// Klasse wiederholt wird. Ohne Angabe gilt die Klasse der Vorlage.
  MathConcreteTask concretize(int seed, {int? forGrade}) {
    final a = _valueInRange(validRangeA, _mixSeed(seed + 17));
    final b = _valueInRange(validRangeB, _mixSeed(seed + 53));
    switch (kind) {
      case MathTemplateKind.addition:
        final limit = int.tryParse(
          RegExp(r'bis (\d+)').firstMatch(unit)?.group(1) ?? '',
        );
        // Passt die Summe nicht in den Zahlenraum, wird der zweite Summand
        // gleichmäßig in den freien Bereich gelegt. Früher wurde er auf
        // „Grenze − a“ gekürzt: Bis zu 40 % der Aufgaben hatten dann genau
        // die Grenze (10, 20, 100, 1000) als Lösung.
        var left = a;
        var right = limit == null ? b : _foldInto(b, validRangeB.first, limit - a);
        if (limit != null && validRangeA.first == 0) {
          // Kleiner Zahlenraum mit 0: jedes Paar a + b ≤ Grenze ist gleich
          // wahrscheinlich, nur 0 + 0 kommt nicht vor.
          var index = 1 + _positive(_mixSeed(seed + 71), (limit + 1) * (limit + 2) ~/ 2 - 1);
          left = 0;
          while (index > limit - left) {
            index -= limit - left + 1;
            left++;
          }
          right = index;
        }
        final answer = left + right;
        return _numberTask(seed, '$left + $right = ?', answer, _additionExplanation(left, right), 'dots',
          typical: _additionErrors(left, right),
        );
      case MathTemplateKind.subtraction:
        final minuend = a ;
        // Wie beim Plus: nicht auf den Minuenden kürzen (das ergab bis zu
        // 18 % Aufgaben mit der Lösung 0), sondern gleichmäßig verteilen.
        final subtrahend = _foldInto(b, validRangeB.first, minuend);
        final answer = minuend - subtrahend;
        return _numberTask(seed, '$minuend - $subtrahend = ?', answer, _subtractionExplanation(minuend, subtrahend), 'line',
          typical: _subtractionErrors(minuend, subtrahend),
        );
      case MathTemplateKind.numberLineMissing:
        // Schritte 1, 2 oder 5, die Lücke an wechselnder Stelle. Früher gab
        // es nur „a, a+1, _, a+3“ (18 Aufgaben).
        final step = const <int>[1, 1, 1, 2, 2, 5][_positive(_mixSeed(seed + 11), 6)];
        final start = step == 5 ? (a % 2) * 5 : a % (20 - 3 * step + 1);
        final sequence = <int>[for (var i = 0; i < 4; i++) start + i * step];
        final gap = _positive(_mixSeed(seed + 37), 4);
        final answer = sequence[gap];
        final shown = <String>[
          for (var i = 0; i < 4; i++) i == gap ? '_' : '${sequence[i]}',
        ];
        final rule = step == 1
            ? 'Die Zahlen werden immer um 1 größer.'
            : 'Die Zahlen werden immer um $step größer.';
        // Karten, die schon in der Reihe stehen, wären sofort auszuschließen.
        return _numberTask(seed, 'Welche Zahl fehlt? ${shown.join(', ')}', answer,
          gap == 0
              ? '$rule Rechne von der zweiten Zahl zurück: ${sequence[1]} − $step = $answer.'
              : '$rule ${sequence[gap - 1]} + $step = $answer.',
          'number_line',
          // Typisch: um 1 statt um den Schritt weitergezählt, einen Schritt zu weit.
          typical: <int>[answer + 1, answer - 1, sequence.last + step, start - step, answer + 10],
          blocked: sequence.toSet(),
        );
      case MathTemplateKind.quantityCompare:
        final left = a;
        final answer = left == b ? 'gleich viele' : left > b ? 'links' : 'rechts';
        final leftDots = _repeatEmoji('🍎', left);
        final rightDots = _repeatEmoji('🍎', b);
        return _choice(seed, '$leftDots oder $rightDots – wo sind mehr Äpfel?', answer, <String>['links', 'rechts', 'gleich viele'],
          'Zähle beide Seiten: links $left, rechts $b. ${left == b ? 'Es sind gleich viele.' : left > b ? '$left ist mehr als $b: links sind mehr.' : '$b ist mehr als $left: rechts sind mehr.'}',
          'quantity',
          keepOrder: true,
        );
      case MathTemplateKind.numberWord:
        final answer = _numberWords[a] ?? '$a';
        return _choice(seed, 'Wie schreibt man die Zahl $a als Wort?', answer, _numberWordChoices(a, seed), _numberWordExplanation(a, answer), 'word_number',
          keepOrder: true,
        );
      case MathTemplateKind.shapeRecognition:
        final entry = shapeQuestions[_positive(seed, shapeQuestions.length)];
        return _choice(seed, entry.$1, entry.$2, entry.$3, entry.$4, 'shape');
      case MathTemplateKind.moneyCompare:
        // Zwei Dinge mit Preis. Früher hieß es „Was kostet mehr: 6 € oder
        // 6 €?“ mit nur zwei Karten, wenn beide Preise gleich waren.
        const things = <(String, String)>[
          ('Der Ball', 'der Ball'), ('Das Buch', 'das Buch'),
          ('Die Puppe', 'die Puppe'), ('Das Auto', 'das Auto'),
          ('Der Teddy', 'der Teddy'), ('Die Kappe', 'die Kappe'),
          ('Das Puzzle', 'das Puzzle'), ('Der Malblock', 'der Malblock'),
        ];
        final firstIndex = _positive(_mixSeed(seed + 29), things.length);
        final first = things[firstIndex];
        final second = things[(firstIndex + 1 + _positive(_mixSeed(seed + 43), things.length - 1)) % things.length];
        final left = a;
        final right = b;
        final answer = left == right ? 'gleich viel' : left > right ? first.$2 : second.$2;
        return _choice(seed, '${first.$1} kostet $left €, ${second.$2} kostet $right €. Was kostet mehr?', answer, <String>[first.$2, second.$2, 'gleich viel'],
          left == right
              ? 'Beide kosten $left €. Sie kosten gleich viel.'
              : '${left > right ? left : right} € ist mehr als ${left > right ? right : left} €. Mehr kostet ${left > right ? first.$2 : second.$2}.',
          'money_compare',
          keepOrder: true,
        );
      case MathTemplateKind.dayHours:
        const facts = <(String, String, List<String>, String)>[
          (
            'Wie viele Stunden hat ein ganzer Tag?',
            '24',
            ['12', '24', '30'],
            'Ein ganzer Tag hat 24 Stunden: der helle und der dunkle Teil zusammen.'
          ),
          (
            'Wie viele Tage hat eine Woche?',
            '7',
            ['5', '7', '10'],
            'Zähle Montag bis Sonntag. Es sind sieben Tage.'
          ),
          (
            'Welche Tageszeit kommt nach dem Morgen und vor dem Nachmittag?',
            'Mittag',
            ['Abend', 'Nacht', 'Mittag'],
            'Die Reihenfolge ist Morgen, Mittag, Nachmittag und Abend.'
          ),
          (
            'Welche Tageszeit folgt auf den Nachmittag?',
            'Abend',
            ['Morgen', 'Mittag', 'Abend'],
            'Nach dem Nachmittag kommt der Abend.'
          ),
          (
            'Was dauert normalerweise länger: Zähneputzen oder eine Nacht schlafen?',
            'eine Nacht schlafen',
            ['Zähneputzen', 'eine Nacht schlafen', 'beides gleich lang'],
            'Zähneputzen dauert wenige Minuten. Eine Nacht schlafen dauert viele Stunden.'
          ),
          (
            'Was dauert normalerweise kürzer: einmal klatschen oder die ganze Jause essen?',
            'einmal klatschen',
            ['die ganze Jause essen', 'einmal klatschen', 'beides gleich lang'],
            'Ein einzelner Klatscher dauert nur einen kurzen Moment.'
          ),
          (
            'Was bedeutet morgen?',
            'der Tag nach heute',
            ['der Tag vor heute', 'der Tag nach heute', 'der heutige Tag'],
            'Gehe von heute einen Tag weiter. Dann ist morgen.'
          ),
          (
            'Was bedeutet gestern?',
            'der Tag vor heute',
            ['der Tag vor heute', 'der Tag nach morgen', 'der heutige Tag'],
            'Gehe von heute einen Tag zurück. Dann ist gestern.'
          ),
          (
            'Welcher Tag kommt nach Montag?',
            'Dienstag',
            ['Sonntag', 'Dienstag', 'Mittwoch'],
            'Die Woche geht so: Montag, Dienstag, Mittwoch, Donnerstag, Freitag, Samstag, Sonntag.'
          ),
          (
            'Welcher Tag kommt vor Sonntag?',
            'Samstag',
            ['Montag', 'Freitag', 'Samstag'],
            'Vor dem Sonntag kommt der Samstag. Beide zusammen sind das Wochenende.'
          ),
          (
            'Welcher Tag kommt nach Freitag?',
            'Samstag',
            ['Donnerstag', 'Samstag', 'Sonntag'],
            'Nach Freitag kommt Samstag. Dann beginnt das Wochenende.'
          ),
          (
            'Heute ist Mittwoch. Welcher Tag ist morgen?',
            'Donnerstag',
            ['Dienstag', 'Donnerstag', 'Freitag'],
            'Morgen ist der Tag nach heute. Nach Mittwoch kommt Donnerstag.'
          ),
          (
            'Heute ist Dienstag. Welcher Tag war gestern?',
            'Montag',
            ['Montag', 'Mittwoch', 'Sonntag'],
            'Gestern ist der Tag vor heute. Vor Dienstag kommt Montag.'
          ),
          (
            'Wie viele Monate hat ein Jahr?',
            '12',
            ['7', '10', '12'],
            'Von Jänner bis Dezember sind es zwölf Monate.'
          ),
          (
            'Welcher Monat kommt nach dem Jänner?',
            'Februar',
            ['Dezember', 'Februar', 'März'],
            'Das Jahr beginnt mit Jänner, Februar, März.'
          ),
          (
            'Welcher Monat ist der letzte im Jahr?',
            'Dezember',
            ['Jänner', 'November', 'Dezember'],
            'Das Jahr endet mit dem Dezember. Danach beginnt ein neues Jahr mit dem Jänner.'
          ),
          (
            'Wie viele Jahreszeiten gibt es?',
            '4',
            ['2', '4', '12'],
            'Frühling, Sommer, Herbst und Winter: Das sind vier Jahreszeiten.'
          ),
          (
            'Welche Jahreszeit kommt nach dem Winter?',
            'Frühling',
            ['Herbst', 'Sommer', 'Frühling'],
            'Nach dem Winter wird es wärmer. Dann ist Frühling.'
          ),
          (
            'Welche Jahreszeit kommt nach dem Sommer?',
            'Herbst',
            ['Herbst', 'Winter', 'Frühling'],
            'Nach dem Sommer kommt der Herbst. Die Blätter werden bunt.'
          ),
          (
            'Wann stehst du auf und frühstückst?',
            'am Morgen',
            ['am Morgen', 'am Abend', 'in der Nacht'],
            'Am Morgen beginnt der Tag. Da stehst du auf und frühstückst.'
          ),
          (
            'Wann gehst du schlafen?',
            'am Abend',
            ['am Morgen', 'zu Mittag', 'am Abend'],
            'Am Abend endet der Tag. Dann gehst du schlafen.'
          ),
          (
            'Was dauert länger: eine Stunde oder eine Minute?',
            'eine Stunde',
            ['eine Minute', 'eine Stunde', 'beides gleich lang'],
            'Eine Stunde ist viel länger als eine Minute. In einer Stunde vergehen 60 Minuten.'
          ),
          (
            'Wie viele Minuten hat eine Stunde?',
            '60',
            ['30', '60', '100'],
            'Eine Stunde hat 60 Minuten. Der lange Zeiger geht in dieser Zeit einmal rundherum.'
          ),
          (
            'Was dauert länger: ein Tag oder eine Woche?',
            'eine Woche',
            ['ein Tag', 'eine Woche', 'beides gleich lang'],
            'Eine Woche hat sieben Tage. Sie dauert länger als ein Tag.'
          ),
        ];
        final fact = facts[_positive(_mixSeed(seed), facts.length)];
        // Kein Uhr-Feld: Zu diesen Fragen gibt es keine Uhrzeit zu zeigen.
        return _choice(seed, fact.$1, fact.$2, fact.$3, fact.$4, 'time_fact');
      case MathTemplateKind.symmetry:
        if (unit == 'Symmetrieachsen') {
          final entry = symmetryAxisExamples[_positive(_mixSeed(seed), symmetryAxisExamples.length)];
          return _numberTask(seed, 'Wie viele Symmetrieachsen hat ${entry.$1}?', entry.$2,
              'Eine Symmetrieachse teilt eine Form in zwei spiegelgleiche Hälften. Prüfe jede mögliche Faltlinie.', 'symmetry',
              // Typisch: Ecken oder Seiten zählen statt Faltlinien, oder gar keine Achse finden.
              typical: const <int>[0, 1, 2, 3, 4, 5, 6, 8, 10], max: 12);
        }
        // Klasse 1: falten statt Fachwörter. Früher gab es vier Fragen wie
        // „Hat ein gleichseitiges Dreieck eine Spiegelachse?“, drei davon
        // mit der Antwort „ja“.
        final entry = symmetryFoldExamples[_positive(_mixSeed(seed), symmetryFoldExamples.length)];
        return _choice(seed, 'Kannst du ${entry.$1} so falten, dass beide Hälften genau aufeinanderpassen?', entry.$2 ? 'ja' : 'nein',
            <String>['ja', 'nein'],
            entry.$2
                ? 'Ja. Falte in der Mitte: Beide Hälften passen genau aufeinander. Die Faltlinie heißt Spiegelachse.'
                : 'Nein. Wie du auch faltest: Die zwei Hälften passen nie genau aufeinander.',
            'symmetry', keepOrder: true);
      case MathTemplateKind.multiplicationPrep:
        final answer = b;
        return _numberTask(seed, 'Wie oft passt $a in ${a * b}?', answer, '$a passt $answer-mal in ${a * b}: ${List<String>.filled(answer, '$a').join(' + ')} = ${a * b}.', 'groups',
          // Typisch: die andere Zahl der Aufgabe nennen oder sich um eins verzählen.
          typical: <int>[a, answer - 1, answer + 1, a * b - a],
        );
      case MathTemplateKind.wordProblemOneStep:
        if (promptPattern == 'sachaufgabe-wegnehmen') {
          final removed = b.clamp(1, a).toInt();
          final answer = a - removed;
          final story = _subtractionStories[_positive(seed, _subtractionStories.length)];
          return _numberTask(seed, story.prompt(a, removed, answer), answer, story.explain(a, removed, answer), 'story',
              typical: _subtractionErrors(a, removed));
        }
        // 2026-06-03: vorher EINE Geschichte (Lisa+Aepfel) - Kind sah staendig
        // dieselbe Aufgabe nur mit anderen Zahlen. Jetzt 8 Szenarien aus dem
        // oesterreichischen Alltag (AT-Lehrplan VS Sachrechnen).
        final answer = a + b;
        final s1 = _positive(seed, _oneStepStories.length);
        final story = _oneStepStories[s1];
        return _numberTask(seed, story.prompt(a, b, answer), answer, story.explain(a, b, answer), 'story',
          typical: _additionErrors(a, b),
        );
      case MathTemplateKind.moneyChange:
        final denomination = grade >= 3 ? <int>[2, 5, 10][b % 3] : (b.isEven ? 2 : 1);
        final amount = grade >= 3 ? a * 2 : a;
        final euro = (amount ~/ denomination).clamp(1, 100).toInt() * denomination;
        final count = euro ~/ denomination;
        final pieces = denomination <= 2 ? 'Münzen' : 'Scheine';
        String counted(int value) => '$value ${value == 1 ? (denomination <= 2 ? 'Münze' : 'Schein') : pieces}';
        return _choice(seed, 'Wie viele $denomination-€-$pieces ergeben $euro €?', counted(count),
            <String>[
              // Typisch: den Betrag oder den Wert des Geldstücks nennen, sich um eins verzählen.
              for (final value in _numericChoices(count, seed,
                  typical: <int>[euro, denomination, count - 1, count + 1, count * 2], min: 1))
                counted(int.parse(value)),
            ],
            'Zähle in $denomination-er-Schritten bis $euro: $count × $denomination € = $euro €.', 'money_change',
            keepOrder: true);
      case MathTemplateKind.clockTime:
        // Die Uhrzeit steht nur auf der Uhr im Bild, nicht in der Frage.
        // Früher hieß die Frage „Stunde 7 und Minute 30?“ – die Lösung
        // 7:30 Uhr musste nur abgeschrieben werden.
        final minutes = <int>[0, 15, 30, 45][b];
        String clock(int hour, int minute) => '${(hour - 1) % 12 + 1}:${minute.toString().padLeft(2, '0')} Uhr';
        final answer = clock(a, minutes);
        final hand = minutes == 0 ? 12 : minutes ~/ 5;
        // Typische Lesefehler: die nächste Stunde genommen (der kurze Zeiger
        // steht schon nahe an der nächsten Zahl), die Zeiger vertauscht, die
        // Zahl beim langen Zeiger als Minuten gelesen, falsche Viertelstunde.
        final wrong = <String>[
          clock(a + 1, minutes),
          clock(hand, (a % 12) * 5),
          if (minutes > 0) clock(a, hand),
          clock(a, (minutes + 30) % 60),
          clock(a, (minutes + 15) % 60),
        ].where((time) => time != answer).toSet().toList();
        final first = wrong.removeAt(0);
        _SeedDice(seed + 61).shuffle(wrong);
        final spoken = switch (minutes) {
          0 => 'Der lange Zeiger steht auf der 12: Es ist eine volle Stunde.',
          15 => 'Der lange Zeiger steht auf der 3: Es ist 15 Minuten nach $a, also Viertel nach $a. Im Osten Österreichs sagt man auch „viertel ${a % 12 + 1}“.',
          30 => 'Der lange Zeiger steht auf der 6: Es ist 30 Minuten nach $a, also halb ${a % 12 + 1}.',
          _ => 'Der lange Zeiger steht auf der 9: Es ist 45 Minuten nach $a, also Viertel vor ${a % 12 + 1}. Im Osten Österreichs sagt man auch „dreiviertel ${a % 12 + 1}“.',
        };
        return _choice(seed, 'Wie spät ist es?', answer,
            <String>[answer, first, ...wrong],
            'Der kurze Zeiger zeigt die Stunde: ${minutes == 0 ? 'Er zeigt genau auf die $a.' : 'Er steht zwischen der $a und der ${a % 12 + 1}. Es gilt die Zahl, an der er schon vorbei ist: die $a.'} $spoken Auf der Uhr steht $answer.', 'clock');
      case MathTemplateKind.lengthConversion:
        if ((forGrade ?? grade) <= 2) {
          // Klasse 2 rechnet im Zahlenraum 100: 1 m = 100 cm, halber Meter,
          // auf 1 Meter ergänzen, Längen vergleichen und zusammenzählen.
          // Früher lagen 293 von 300 Lösungen über 100 („8 Meter und
          // 50 Zentimeter“).
          final variant = _positive(_mixSeed(seed + 67), 8);
          final length = 5 * (1 + (a * 7 + b) % 19);
          if (variant == 0) {
            return _numberTask(seed, 'Wie viele Zentimeter sind 1 Meter?', 100, '1 Meter sind 100 Zentimeter.', 'length_fact',
                typical: const <int>[10, 1000, 50, 60]);
          }
          if (variant == 1) {
            return _numberTask(seed, 'Wie viele Zentimeter sind ein halber Meter?', 50, '1 Meter sind 100 Zentimeter. Die Hälfte davon sind 50 Zentimeter.', 'length_fact',
                typical: const <int>[5, 500, 100, 25, 30]);
          }
          if (variant <= 4) {
            final missing = 100 - length;
            return _numberTask(seed, 'Ein Band ist $length cm lang. Wie viele Zentimeter fehlen auf 1 Meter?', missing, '1 Meter sind 100 cm. Von $length bis 100 fehlen $missing: $length + $missing = 100.', 'length_fact',
                // Typisch: die gegebene Länge genannt, um einen Zehner verrechnet.
                typical: <int>[length, missing + 10, missing - 10, missing + 5, missing - 5]);
          }
          if (variant <= 6) {
            final shorter = length > 90 ? 90 : length;
            final longer = shorter + 5 * (1 + b % ((100 - shorter) ~/ 5));
            return _numberTask(seed, 'Ein Seil ist $longer cm lang, ein Band ist $shorter cm lang. Wie viele Zentimeter ist das Seil länger?', longer - shorter, 'Der Unterschied: $longer − $shorter = ${longer - shorter} cm.', 'length_fact',
                typical: <int>[longer + shorter, longer - shorter + 10, longer - shorter + 5, shorter]);
          }
          final first = 5 * (1 + a % 9);
          final second = 5 * (2 + b);
          return _numberTask(seed, 'Zwei Bänder sind $first cm und $second cm lang. Wie viele Zentimeter sind das zusammen?', first + second, 'Zusammen: $first + $second = ${first + second} cm.', 'length_fact',
              typical: _additionErrors(first, second));
        }
        final extra = b * 10;
        final answer = a * 100 + extra;
        final amount = extra == 0 ? '$a Meter' : '$a Meter und $extra Zentimeter';
        return _numberTask(seed, 'Wie viele Zentimeter sind $amount?', answer,
            '1 Meter sind 100 Zentimeter. Rechne $a × 100 und zähle $extra Zentimeter dazu.', 'ruler',
            // Typisch: falsche Umrechnungszahl, Rest vergessen oder nur addiert.
            typical: <int>[a * 10 + extra ~/ 10, a * 1000 + extra, a * 100 + extra ~/ 10, a * 100, a + extra, a * 10 + extra]);
      case MathTemplateKind.evenOdd:
        final answer = a.isEven ? 'gerade' : 'ungerade';
        // Zwei Karten: „beides“ war nie richtig und nie sinnvoll.
        return _choice(seed, 'Ist $a gerade oder ungerade?', answer, <String>['gerade', 'ungerade'],
          a.isEven
              ? '$a endet auf ${a % 10}. Du kannst $a in Paare aufteilen und nichts bleibt übrig: $a ist gerade.'
              : '$a endet auf ${a % 10}. Beim Bilden von Paaren bleibt eins übrig: $a ist ungerade.',
          'parity',
          keepOrder: true,
        );
      case MathTemplateKind.halfDouble:
        final even = a.isEven ? a : a + 1;
        if (b.isEven) {
          final answer = even ~/ 2;
          return _numberTask(seed, 'Was ist die Hälfte von $even?', answer, 'Teile $even in zwei gleiche Gruppen.', 'half',
            // Typisch: verdoppelt statt halbiert, 2 abgezogen statt geteilt.
            typical: <int>[even * 2, even - 2, answer - 1, answer + 1, answer + 10],
          );
        }
        final answer = even * 2;
        return _numberTask(seed, 'Was ist das Doppelte von $even?', answer, 'Doppelt heißt: $even + $even.', 'double',
          // Typisch: halbiert statt verdoppelt, 2 dazugezählt statt verdoppelt.
          typical: <int>[even ~/ 2, even + 2, answer - 2, answer + 2, answer - 10, answer + 10],
        );
      case MathTemplateKind.tensOnes:
        final tens = a ~/ 10;
        final ones = a % 10;
        final askTens = b.isEven;
        return _numberTask(seed, askTens ? 'Wie viele Zehner hat $a?' : 'Wie viele Einer hat $a?', askTens ? tens : ones, '$a besteht aus $tens Zehnern und $ones Einern.', 'ten_ones',
          // Typisch: die andere Ziffer, die ganze Zahl oder Zehner und Einer zusammengezählt.
          typical: <int>[askTens ? ones : tens, a, tens + ones, askTens ? tens * 10 : ones * 10],
        );
      case MathTemplateKind.multiplication:
        // Klasse 2 beginnt mit den leichten Reihen 2, 5, 10, 3 und 4.
        // Klasse 3 übt alle Reihen, auch mit 0 und 1. Früher waren beide
        // Klassen gleich und begannen sofort mit 9 × 7.
        final left = grade <= 2 ? const <int>[2, 5, 10, 3, 4][_positive(_mixSeed(seed + 73), 5)] : a;
        final right = b;
        final answer = left * right;
        // Überall dieselbe Deutung: a × b heißt „a-mal die b“.
        final repeated = left >= 2 && left <= 10
            ? ' ${List<String>.filled(left, '$right').join(' + ')} = $answer.'
            : ' $left × $right = $answer.';
        return _numberTask(seed, '$left × $right = ?', answer, '$left × $right heißt $left-mal die $right.$repeated', 'times_table',
          // Typisch: Nachbaraufgabe in der Reihe oder plus statt mal gerechnet.
          typical: <int>[left * (right - 1), left * (right + 1), (left - 1) * right, (left + 1) * right, left + right],
        );
      case MathTemplateKind.writtenAddition:
        final right = grade == 3 ? _foldInto(b, validRangeB.first, 1000 - a) : b;
        final answer = a + right;
        return _numberTask(seed, 'Schriftlich: $a + $right = ?', answer, 'Schreibe Einer unter Einer, Zehner unter Zehner, Hunderter unter Hunderter. Beginne bei den Einern. Sind es zehn oder mehr, schreibe die Einer an und merke dir 1. $a + $right = $answer.', 'written_add',
          typical: _additionErrors(a, right),
        );
      case MathTemplateKind.writtenSubtraction:
        final minuend = a > b ? a : a + b;
        final answer = minuend - b;
        return _numberTask(seed, 'Schriftlich: $minuend - $b = ?', answer, 'Beginne bei den Einern. Ergänze von der unteren zur oberen Ziffer. Reicht es nicht, ergänze auf die nächste Zehnerzahl und merke dir 1. $minuend − $b = $answer.', 'written_sub',
          typical: _subtractionErrors(minuend, b),
        );
      case MathTemplateKind.fractionHalf:
        // Halbe, Viertel und Achtel von Mengen. Früher gab es nur „die
        // Hälfte von X“ bis 40 – weniger als in Klasse 2.
        final parts = const <int>[2, 2, 4, 4, 8][_positive(_mixSeed(seed + 47), 5)];
        final whole = parts == 2 ? 2 * (a + 5) : parts * (1 + a % 10);
        final answer = whole ~/ parts;
        final name = switch (parts) { 2 => 'die Hälfte', 4 => 'ein Viertel', _ => 'ein Achtel' };
        final meaning = switch (parts) {
          2 => 'Die Hälfte ist einer von 2 gleich großen Teilen',
          4 => 'Ein Viertel ist einer von 4 gleich großen Teilen',
          _ => 'Ein Achtel ist einer von 8 gleich großen Teilen',
        };
        return _numberTask(seed, 'Was ist $name von $whole?', answer, '$meaning: $whole : $parts = $answer.', 'fraction_half',
          // Typisch: den falschen Bruchteil genommen, verdoppelt statt
          // geteilt, die Zahl der Teile abgezogen.
          typical: <int>[if (parts != 2) whole ~/ 2, if (parts == 2) whole ~/ 4, whole * 2, whole - parts, answer - 1, answer + 1],
        );
      case MathTemplateKind.wordProblemTwoStep:
        // Dritte Zahl 2 bis 9, nie größer als die erste: So bleibt jedes
        // Zwischenergebnis positiv.
        final third = 2 + _positive(_mixSeed(seed + 19), 8);
        final story = _twoStepStories[_positive(seed, _twoStepStories.length)](
            a, b, third > a ? a : third);
        return _numberTask(seed, story.prompt, story.answer, story.explanation, 'story_two',
          typical: story.typical,
        );
      case MathTemplateKind.perimeter:
        // Die längere Seite heißt „lang“. Gleich lange Seiten ergeben ein
        // Quadrat und bekommen eine eigene Frage. Die Karten tragen die
        // Einheit cm.
        final length = a >= b ? a : b;
        final width = a >= b ? b : a;
        if (length == width) {
          return _numberTask(seed, 'Ein Quadrat hat die Seitenlänge $length cm. Wie groß ist der Umfang?', 4 * length, 'Ein Quadrat hat 4 gleich lange Seiten. Umfang: 4 · $length = ${4 * length} cm.', 'perimeter',
            // Typisch: nur zwei Seiten gezählt, Fläche statt Umfang.
            typical: <int>[2 * length, length * length, 3 * length, length],
            suffix: ' cm',
          );
        }
        final answer = 2 * (length + width);
        return _numberTask(seed, 'Ein Rechteck ist $length cm lang und $width cm breit. Wie groß ist der Umfang?', answer, 'Umfang: $length + $width + $length + $width = $answer cm.', 'perimeter',
          // Typisch: nur zwei Seiten addiert, Fläche statt Umfang, eine Seite vergessen.
          typical: <int>[length + width, length * width, 2 * length + width, length + 2 * width],
          suffix: ' cm',
        );
      case MathTemplateKind.area:
        final length = a >= b ? a : b;
        final width = a >= b ? b : a;
        final answer = length * width;
        if (length == width) {
          return _numberTask(seed, 'Ein Quadrat hat die Seitenlänge $length cm. Wie groß ist der Flächeninhalt?', answer, 'Fläche: Seite mal Seite, also $length · $length = $answer cm².', 'area',
            // Typisch: Umfang statt Fläche, Seite nur verdoppelt.
            typical: <int>[4 * length, 2 * length, length * (length + 1), length * (length - 1)],
            suffix: ' cm²',
          );
        }
        return _numberTask(seed, 'Ein Rechteck ist $length cm lang und $width cm breit. Wie groß ist der Flächeninhalt?', answer, 'Fläche: Länge mal Breite, also $length · $width = $answer cm².', 'area',
          // Typisch: Umfang statt Fläche, Seiten nur addiert, Nachbaraufgabe im Einmaleins.
          typical: <int>[2 * (length + width), length + width, length * (width + 1), length * (width - 1)],
          suffix: ' cm²',
        );
      case MathTemplateKind.writtenMultiplication:
        // Einstelliger Faktor: Dafür gilt das Verfahren „jede Stelle mal
        // den Faktor“. Früher kamen auch 10, 11 und 12 vor, zu denen die
        // Erklärung nicht passte.
        final factor = 2 + (b - 2) % 8;
        final answer = a * factor;
        return _numberTask(seed, 'Schriftlich: $a × $factor = ?', answer, _writtenMultiplicationSteps(a, factor), 'written_mul',
          // Typisch: gemerkte Zehner vergessen, einmal zu oft oder zu selten genommen.
          typical: <int>[_productWithoutCarry(a, factor), a * (factor - 1), a * (factor + 1), answer - 10, answer + 10, answer - 100, answer + 100],
        );
      case MathTemplateKind.division:
        if (promptPattern == 'schriftliche-division') {
          // Dreistelliger Dividend, einstelliger Divisor. Der Quotient wird
          // gleichmäßig gewählt (früher war er in 18 % der Aufgaben 99).
          // Jede dritte Aufgabe hat einen Rest.
          final divisor = 2 + (b - 2) % 8;
          final lowest = (100 + divisor - 1) ~/ divisor;
          final highest = 999 ~/ divisor;
          final quotient = lowest + (a - validRangeA.first) % (highest - lowest + 1);
          var rest = _positive(_mixSeed(seed + 97), 3) == 0
              ? 1 + _positive(_mixSeed(seed + 131), divisor - 1)
              : 0;
          if (quotient * divisor + rest > 999) rest = 0;
          final dividend = quotient * divisor + rest;
          final answer = rest == 0 ? '$quotient' : '$quotient Rest $rest';
          return _choice(seed, 'Schriftlich: $dividend : $divisor = ?', answer,
              _divisionChoices(quotient, rest, divisor, seed),
              _writtenDivisionSteps(dividend, divisor), 'division',
              keepOrder: true);
        }
        // Umkehrung des Einmaleins und halbschriftliches Teilen bis 100.
        final divisor = b.clamp(2, 9).toInt();
        final highest = 100 ~/ divisor;
        final quotient = 2 + (a - validRangeA.first) % (highest - 1);
        final dividend = quotient * divisor;
        return _numberTask(seed, '$dividend : $divisor = ?', quotient, 'Wie oft passt $divisor in $dividend? $quotient-mal, denn $quotient · $divisor = $dividend.', 'division',
          // Typisch: Nachbaraufgabe im Einmaleins, eine Null zu viel oder zu wenig, abgezogen statt geteilt.
          typical: <int>[quotient - 1, quotient + 1, if (quotient % 10 == 0) quotient ~/ 10, if (quotient % 10 == 0) quotient * 10, quotient + 10, quotient - 10, if (dividend - divisor < 100) dividend - divisor],
        );
      case MathTemplateKind.simpleFractionAdd:
        final denominator = b + 2;
        final left = 1 + (a - 1) % (denominator - 2);
        final right = 1 + _positive(_mixSeed(seed + 211), denominator - left - 1);
        final numerator = left + right;
        final answer = '$numerator/$denominator';
        return _choice(seed, '$left/$denominator + $right/$denominator = ?', answer,
            _fractionChoices(numerator, denominator, seed, lower: <(int, int)>[
              // Typisch: auch die Nenner addiert; sich bei den Zählern verzählt.
              (numerator, denominator * 2),
              (numerator - 1, denominator),
              (numerator - 2, denominator),
            ], upper: <(int, int)>[
              (numerator + 1, denominator),
              if (numerator + 2 <= denominator) (numerator + 2, denominator),
            ]),
            'Die Teile bleiben gleich groß: Der Nenner bleibt $denominator. Addiere nur die Zähler: $left + $right = $numerator. Kürzen ist hier nicht nötig.', 'fraction_add', keepOrder: true);
      case MathTemplateKind.decimals:
        // Gerechnet wird in ganzen Zehnteln, damit keine Rundungsfehler entstehen.
        String tenths(int value) => '${value ~/ 10},${value % 10}';
        final sum = a + b;
        final answer = tenths(sum);
        return _choice(seed, '${tenths(a)} + ${tenths(b)} = ?', answer, <String>[
            // Typisch: den Übertrag zu den Einern vergessen, um ein Ganzes oder ein Zehntel daneben.
            for (final value in _numericChoices(sum, seed, typical: <int>[sum - 10, sum + 10, sum - 1, sum + 1, _sumWithoutCarry(a, b)]))
              tenths(int.parse(value)),
          ], 'Addiere Zehntel wie normale Zahlen und setze das Komma.', 'decimal',
          keepOrder: true,
        );
      case MathTemplateKind.wordProblemThreeStep:
        // Dritte Zahl 2 bis 9, nie größer als die erste: So bleibt jedes
        // Zwischenergebnis positiv.
        final third = 2 + _positive(_mixSeed(seed + 19), 8);
        final story = _threeStepStories[_positive(seed, _threeStepStories.length)](
            a, b, third > a ? a : third);
        return _numberTask(seed, story.prompt, story.answer, story.explanation, 'story_three',
          typical: story.typical,
        );
      case MathTemplateKind.chartRead:
        // Vier Tage, vier Fragearten: meiste, wenigste, Unterschied, Summe.
        // Früher war jede Aufgabe „Montag a, Dienstag b, wie viele
        // zusammen?“ – eine Plusaufgabe der 2. Klasse.
        const days = <String>['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag'];
        final values = <int>[a + 20, b + 20, 20 + _positive(_mixSeed(seed + 5), 40), 20 + _positive(_mixSeed(seed + 9), 40)];
        // Jeder Wert kommt nur einmal vor, damit „meiste“ eindeutig ist.
        for (var i = 1; i < values.length; i++) {
          while (values.sublist(0, i).contains(values[i])) {
            values[i]++;
          }
        }
        final data = 'Diagramm: ${<String>[for (var i = 0; i < 4; i++) '${days[i]} ${values[i]}'].join(', ')} Kinder.';
        final sorted = <int>[...values]..sort();
        final question = _positive(_mixSeed(seed + 79), 4);
        if (question == 0 || question == 1) {
          final wanted = question == 0 ? sorted.last : sorted.first;
          return _choice(seed, '$data An welchem Tag waren die ${question == 0 ? 'meisten' : 'wenigsten'} Kinder da?', days[values.indexOf(wanted)], days,
              'Vergleiche alle vier Balken: $wanted ist die ${question == 0 ? 'größte' : 'kleinste'} Zahl. Das war am ${days[values.indexOf(wanted)]}.', 'chart',
              keepOrder: true);
        }
        if (question == 2) {
          final first = _positive(_mixSeed(seed + 83), 4);
          final second = (first + 1 + _positive(_mixSeed(seed + 89), 3)) % 4;
          final more = values[first] > values[second] ? first : second;
          final less = more == first ? second : first;
          final difference = values[more] - values[less];
          return _numberTask(seed, '$data Wie viele Kinder waren am ${days[more]} mehr da als am ${days[less]}?', difference,
              'Lies beide Balken ab und rechne den Unterschied: ${values[more]} − ${values[less]} = $difference.', 'chart',
              typical: <int>[values[more] + values[less], values[more], values[less], difference + 10, difference - 10]);
        }
        final sum = values.reduce((x, y) => x + y);
        return _numberTask(seed, '$data Wie viele Kinder waren es an allen vier Tagen zusammen?', sum,
            'Zähle alle vier Balken zusammen: ${values.join(' + ')} = $sum.', 'chart',
            typical: <int>[sum - 10, sum + 10, sum - values.last, sorted.last, sum - 100, sum + 100]);
      case MathTemplateKind.compare:
        // Befund M7: Im Zahlenraum bis zur Million gab es nur Vergleiche.
        // Jede vierte Aufgabe fragt nach dem Stellenwert einer Ziffer,
        // jede vierte nach dem Runden auf Tausender.
        if (a >= 10000) {
          final format = _positive(_mixSeed(seed + 97), 4);
          if (format == 1) return _placeValueMillion(seed, a);
          if (format == 2) return _roundThousand(seed, a);
        }
        // Paare, bei denen man genau hinschauen muss: gleiche Stellenzahl
        // und gleiche erste Ziffer, Zahlendreher, manchmal gleiche Zahlen.
        // Früher waren es zwei Zufallszahlen: Meist entschied der erste
        // Blick, und „=“ war nie richtig.
        var left = a;
        var right = b;
        final mode = _positive(_mixSeed(seed + 13), 10);
        if (mode == 0) {
          right = left;
        } else if (mode <= 3 && left >= 12) {
          // Zahlendreher: zwei benachbarte Ziffern vertauscht.
          final digits = '$left'.split('');
          final at = 1 + _positive(_mixSeed(seed + 61), digits.length - 1);
          final swap = digits[at];
          digits[at] = digits[at - 1];
          digits[at - 1] = swap;
          final turned = int.parse(digits.join());
          right = turned == left || '$turned'.length != '$left'.length ? left + 9 : turned;
        } else if (mode <= 6 && left >= 10) {
          // Gleiche erste Ziffer, der Rest stammt von der zweiten Zahl.
          var place = 1;
          while (place * 10 <= left) {
            place *= 10;
          }
          right = left - left % place + b % place;
          if (right == left) right = left + 1;
        }
        if (_positive(_mixSeed(seed + 31), 2) == 0) {
          final keep = left;
          left = right;
          right = keep;
        }
        final answer = left > right ? '>' : left < right ? '<' : '=';
        final shownLeft = groupedNumber(left), shownRight = groupedNumber(right);
        return _choice(seed, 'Welches Zeichen passt? $shownLeft ⬜ $shownRight', answer, <String>['<', '>', '='],
          answer == '='
              ? 'Beide Zahlen haben an jeder Stelle dieselbe Ziffer. Sie sind gleich groß: $shownLeft = $shownRight.'
              : 'Zähle zuerst die Stellen: Die Zahl mit mehr Stellen ist größer. Bei gleich vielen Stellen vergleichst du von links, Stelle für Stelle. $shownLeft $answer $shownRight.',
          'compare',
          keepOrder: true,
        );
      case MathTemplateKind.massConversion:
        final kg = 1 + (a - 1) % 9;
        final extra = (b - 1) * 100;
        final answer = kg * 1000 + extra;
        final amount = extra == 0 ? '$kg kg' : '$kg kg und $extra g';
        return _numberTask(seed, 'Wie viele Gramm sind $amount?', answer,
            '1 kg sind 1000 g. Rechne $kg × 1000 und zähle $extra g dazu.', 'mass',
            typical: _thousandConversionErrors(kg, extra));
      case MathTemplateKind.volumeConversion:
        final liter = 1 + (a - 1) % 9;
        final extra = (b - 1) * 100;
        final answer = liter * 1000 + extra;
        final amount = extra == 0 ? '$liter Liter' : '$liter Liter und $extra Milliliter';
        return _numberTask(seed, 'Wie viele Milliliter sind $amount?', answer,
            '1 Liter sind 1000 Milliliter. Rechne $liter × 1000 und zähle $extra Milliliter dazu.', 'volume',
            typical: _thousandConversionErrors(liter, extra));
      case MathTemplateKind.timeMinutes:
        // 9 Stundenwerte mal 8 Minutenwerte (früher nur 20 Aufgaben).
        final hours = 1 + (a - 1) % 9;
        final extra = const <int>[0, 10, 15, 20, 30, 40, 45, 50][(b - 1 + _positive(_mixSeed(seed + 3), 8)) % 8];
        final answer = hours * 60 + extra;
        final hoursText = '$hours ${hours == 1 ? 'Stunde' : 'Stunden'}';
        final amount = extra == 0 ? hoursText : '$hoursText und $extra Minuten';
        return _numberTask(seed, 'Wie viele Minuten sind $amount?', answer,
            '1 Stunde hat 60 Minuten. Rechne $hours × 60 und zähle $extra Minuten dazu.', 'time_fact',
            // Typisch: mit 100 statt 60 gerechnet, Rest vergessen, eine Stunde zu viel oder zu wenig.
            typical: <int>[hours * 100 + extra, hours * 60, answer + 60, answer - 60, hours * 10 + extra, hours + extra]);
      case MathTemplateKind.fractionExpand:
        final denom = 2 + (a - 2) % 5;
        final factor = 2 + (b - 2) % 4;
        final numerator = 1 + _positive(_mixSeed(seed + 31), denom - 1);
        final newNumerator = numerator * factor;
        final newDenom = denom * factor;
        final answer = '$newNumerator/$newDenom';
        return _choice(seed, 
          // Befund M11: formales Erweitern geht über den Volksschulstoff
          // hinaus und ist deshalb als Knobelaufgabe gekennzeichnet.
          'Knobelaufgabe: Erweitere den Bruch $numerator/$denom mit $factor. Wie heißt der neue Bruch?',
          answer,
          _fractionChoices(newNumerator, newDenom, seed, lower: <(int, int)>[
            // Typisch: nur den Nenner malgenommen, sich beim Zähler verrechnet.
            (numerator, newDenom),
            (newNumerator - 1, newDenom),
          ], upper: <(int, int)>[
            // Typisch: nur den Zähler malgenommen, dazugezählt statt malgenommen.
            (newNumerator, denom),
            (numerator + factor, denom + factor),
            (newNumerator + 1, newDenom),
          ]),
          'Multipliziere Zähler UND Nenner mit $factor: $numerator · $factor = $newNumerator und $denom · $factor = $newDenom.',
          'fraction_expand',
          keepOrder: true,
        );
      case MathTemplateKind.average:
        // Gerecht teilen: drei Werte mit ganzzahligem Mittel. Früher war die
        // Lösung immer „zweite Zahl minus 1“ und die Werte standen stets
        // aufsteigend da. Jetzt werden zwei Abstände zum Mittel frei
        // gewählt, der dritte gleicht sie aus, die Reihenfolge wechselt.
        final mean = a;
        final reach = mean - 1 < b + 3 ? mean - 1 : b + 3;
        final up = 1 + _positive(_mixSeed(seed + 23), reach);
        final down = 1 + _positive(_mixSeed(seed + 41), reach);
        final values = <int>[mean + up, mean - down, mean + down - up];
        _SeedDice(seed + 59).shuffle(values);
        final v1 = values[0], v2 = values[1], v3 = values[2];
        final sum = v1 + v2 + v3;
        return _numberTask(
          seed,
          'Knobelaufgabe: Drei Kinder sammeln Sterne: $v1, $v2 und $v3. Sie teilen alle Sterne gerecht auf. Wie viele Sterne bekommt jedes Kind?',
          mean,
          'Zähle alle Sterne zusammen: $v1 + $v2 + $v3 = $sum. Teile durch die 3 Kinder: $sum : 3 = $mean. Diese Zahl heißt Mittelwert.',
          'chart',
          // Typisch: nur addiert, einen der drei Werte genannt, durch 2 geteilt.
          typical: <int>[v1, v2, v3, sum ~/ 2, sum, mean + 3, mean - 3],
        );
      case MathTemplateKind.shapeTrace:
        // 2026-06-05 Iter 20: Form-Nachzeichnen.
        // a kodiert die Form: 0=Quadrat, 1=Kreis, 2=Dreieck, 3=Rechteck, 4=Stern.
        // Der ShapeTraceTaskRenderer liest die Form aus der Antwort und
        // zeigt erst Demo, dann Trace-Canvas.
        const shapes = <List<String>>[
          <String>['Quadrat', 'Ein Quadrat hat 4 gleich lange Seiten und 4 rechte Winkel.',
          ],
          <String>['Kreis', 'Ein Kreis ist eine runde Linie ohne Anfang und Ende.',
          ],
          <String>['Dreieck', 'Ein Dreieck hat 3 Ecken und 3 Seiten.'],
          <String>['Rechteck', 'Ein Rechteck hat 4 Ecken und 4 Seiten. Gegenüberliegende Seiten sind gleich lang.',
          ],
          <String>['Stern', 'Ein Stern hat 5 Zacken und 10 Ecken.'],
        ];
        final pick = a.clamp(0, shapes.length - 1).toInt();
        final entry = shapes[pick];
        return MathConcreteTask(
          unit: unit,
          prompt: 'Zeichne ${pick == 1 || pick == 4 ? 'einen' : 'ein'} ${entry[0]} nach',
          answer: entry[0],
          choices: const <String>[],
          explanation: entry[1],
          visual: 'shape_trace',
          difficulty: grade,
          promptPattern: promptPattern,
        );
    }
  }

  /// Zahlenaufgabe mit vier Karten. [typical] sind die typischen falschen
  /// Ergebnisse dieser Aufgabenart, siehe [_numericChoices]. [suffix] hängt
  /// eine Einheit an jede Karte, z. B. „ cm“.
  /// „Welchen Wert hat die Ziffer 7 in 375 412?“ → 70 000. Die gefragte
  /// Ziffer kommt in der Zahl genau einmal vor und ist nicht 0.
  MathConcreteTask _placeValueMillion(int seed, int number) {
    final digits = '$number'.split('');
    final unique = <int>[
      for (var i = 0; i < digits.length; i++)
        if (digits[i] != '0' && digits.where((d) => d == digits[i]).length == 1) i,
    ];
    // Ohne passende Ziffer: eine Stelle so ändern, dass sie eindeutig ist.
    if (unique.isEmpty) {
      digits[1] = '123456789'.split('').firstWhere((d) => !digits.contains(d));
      unique.add(1);
    }
    final index = unique[_positive(_mixSeed(seed + 101), unique.length)];
    final value = int.parse(digits.join());
    final digit = int.parse(digits[index]);
    var place = 1;
    for (var k = index + 1; k < digits.length; k++) {
      place *= 10;
    }
    final answer = digit * place;
    const names = <int, String>{
      1: 'Einer', 10: 'Zehner', 100: 'Hunderter', 1000: 'Tausender',
      10000: 'Zehntausender', 100000: 'Hunderttausender',
    };
    final wrong = <int>[
      if (place >= 10) digit * place ~/ 10,
      digit * place * 10,
      if (place >= 100) digit * place ~/ 100,
      if (place <= 10000) digit * place * 100,
      digit,
    ].where((v) => v != answer).toList();
    return _choice(seed, 'Welchen Wert hat die Ziffer $digit in ${groupedNumber(value)}?', groupedNumber(answer),
      <String>[for (final v in wrong) groupedNumber(v)],
      'Die Ziffer $digit steht an der Stelle der ${names[place]}. Sie bedeutet $digit · ${groupedNumber(place)} = ${groupedNumber(answer)}.',
      'none');
  }

  /// „Runde 375 412 auf Tausender.“ → 375 000. Ab der Hunderterziffer 5
  /// wird aufgerundet.
  MathConcreteTask _roundThousand(int seed, int number) {
    final down = number - number % 1000;
    final up = down + 1000;
    final hundreds = number % 1000 ~/ 100;
    final answer = hundreds >= 5 ? up : down;
    final wrong = <int>[
      hundreds >= 5 ? down : up, // falsche Richtung
      number - number % 100, // auf Hunderter gerundet
      (number + 5000) ~/ 10000 * 10000, // auf Zehntausender gerundet
      answer + 10000,
    ].where((v) => v != answer).toList();
    return _choice(seed, 'Runde ${groupedNumber(number)} auf Tausender.', groupedNumber(answer),
      <String>[for (final v in wrong) groupedNumber(v)],
      'Schau auf die Hunderterziffer: Sie ist $hundreds. ${hundreds >= 5 ? 'Ab 5 rundest du auf' : 'Unter 5 rundest du ab'}: ${groupedNumber(number)} wird ${groupedNumber(answer)}.',
      'none');
  }

  MathConcreteTask _numberTask(int seed, String prompt, int answer, String explanation, String visual, {
    List<int> typical = const <int>[],
    int? max,
    Set<int> blocked = const <int>{},
    String suffix = '',
  }) {
    return _choice(
      seed,
      prompt,
      '$answer$suffix',
      <String>[
        for (final value in _numericChoices(
          answer,
          seed,
          typical: typical,
          // Klasse 1 kennt nur den Zahlenraum bis 20.
          max: max ?? (grade == 1 ? 20 : null),
          blocked: blocked,
        ))
          '$value$suffix',
      ],
      explanation,
      visual,
      keepOrder: true,
    );
  }

  /// [keepOrder] übernimmt die Reihenfolge von [rawChoices] (bereits gemischt
  /// oder eine feste, natürliche Reihenfolge wie <, >, =). Sonst mischt der
  /// Seed die Karten: Manche Anzeigen (Kartenspiel, Sprungspiel, Foto-Übung)
  /// zeigen die Reihenfolge direkt, die Lösung darf dort nicht immer vorn
  /// stehen.
  MathConcreteTask _choice(int seed, String prompt, String answer, List<String> rawChoices, String explanation, String visual, {
    bool keepOrder = false,
  }) {
    final choices = <String>[if (!keepOrder || !rawChoices.contains(answer)) answer];
    for (final choice in rawChoices) {
      if ((keepOrder || choice != answer) && !choices.contains(choice)) choices.add(choice);
      if (choices.length == 4) break;
    }
    // Wenn weniger als 3 Choices: paedagogisch sinnvolle Padding-Werte hinzufuegen.
    // Vorher: 'answer_2', 'answer_3' (sah technisch und kaputt aus fuer Kinder).
    // Nachher: bei Zahl-Antworten naheliegende Nachbarzahlen, sonst sinnvolle Alternativen.
    while (choices.length < 3 && int.tryParse(answer) != null) {
      final fallback = _smartFallback(answer, choices);
      if (fallback == null) break;
      choices.add(fallback);
    }
    if (!keepOrder) _SeedDice(seed + 389).shuffle(choices);
    return MathConcreteTask(
      unit: unit,
      prompt: prompt,
      answer: answer,
      choices: choices,
      explanation: explanation,
      visual: visual,
      difficulty: grade,
      promptPattern: promptPattern,
    );
  }

  /// Findet eine sinnvolle Padding-Antwort, die noch nicht in choices ist.
  /// Bei Zahlen: Nachbar-Zahlen. Bei Worten: einfache Alternativen.
  String? _smartFallback(String answer, List<String> existing) {
    // Versuche die Antwort als Zahl zu parsen (mit oder ohne Einheit)
    final intMatch = RegExp(r'^-?\d+').firstMatch(answer);
    if (intMatch != null) {
      final base = int.tryParse(intMatch.group(0)!) ?? 0;
      final suffix = answer.substring(intMatch.end);
      for (final delta in const <int>[1, -1, 2, -2, 3, -3, 5, 10]) {
        final candidate = '${base + delta}$suffix';
        if (base + delta < 0) continue;
        if (!existing.contains(candidate) && candidate != answer) {
          return candidate;
        }
      }
    }
    // Wort-Fallbacks: einfache Pool-Alternativen
    const wordPool = <String>['ja', 'nein', 'gleich', 'mehr', 'weniger', 'links', 'rechts',
    ];
    for (final w in wordPool) {
      if (!existing.contains(w) && w != answer) return w;
    }
    return null;
  }
}

class MathConcreteTask {
  const MathConcreteTask({
    required this.unit,
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.explanation,
    required this.visual,
    required this.difficulty,
    required this.promptPattern,
  });

  final String unit;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String visual;
  final int difficulty;
  final String promptPattern;
}

enum MathTemplateKind {
  addition,
  subtraction,
  numberLineMissing,
  quantityCompare,
  numberWord,
  shapeRecognition,
  moneyCompare,
  dayHours,
  symmetry,
  multiplicationPrep,
  wordProblemOneStep,
  moneyChange,
  clockTime,
  lengthConversion,
  evenOdd,
  halfDouble,
  tensOnes,
  multiplication,
  writtenAddition,
  writtenSubtraction,
  fractionHalf,
  wordProblemTwoStep,
  perimeter,
  area,
  writtenMultiplication,
  division,
  simpleFractionAdd,
  decimals,
  wordProblemThreeStep,
  chartRead,
  compare,
  // AT-Lehrplan-Erweiterungen 2026-06-03 (Klassen 3 + 4):
  massConversion,
  volumeConversion,
  timeMinutes,
  fractionExpand,
  average,
  // 2026-06-05 Iter 20: Form-Nachzeichnen (Quadrat, Kreis, Dreieck, ...).
  // Demo-Phase + Trace-Phase im eigenen Renderer.
  shapeTrace,
}

// Uses bounded integer operations so the same seed works on mobile and web.
int _mixSeed(int seed) {
  var value = seed & 0x7fffffff;
  value = ((value ^ (value >> 16)) * 2053) & 0x7fffffff;
  value = ((value ^ (value >> 13)) * 4093) & 0x7fffffff;
  return value ^ (value >> 16);
}

int _valueInRange(List<int> range, int seed) {
  final min = range.first;
  final max = range.last;
  if (max <= min) return min;
  return min + _positive(seed, max - min + 1);
}

int _positive(int seed, int length) => length <= 1 ? 0 : (seed & 0x7fffffff) % length;

/// Legt [value] in den Bereich [min]..[max]. Werte, die schon passen,
/// bleiben gleich; größere werden gleichmäßig über den Bereich verteilt
/// statt alle auf [max] gekürzt.
int _foldInto(int value, int min, int max) {
  if (value <= max) return value;
  if (max <= min) return max < 0 ? 0 : max;
  return min + (value - min) % (max - min + 1);
}

/// Kleiner, vom Seed abgeleiteter Würfel. Er nutzt dieselbe begrenzte
/// Ganzzahl-Mischung wie die Aufgabenwahl und liefert deshalb auf Handy und
/// Web dieselbe Folge.
class _SeedDice {
  _SeedDice(int seed) : _state = _mixSeed(seed + 0x2f6b);
  int _state;

  int next(int length) {
    _state = _mixSeed(_state + 0x9e37);
    return _positive(_state, length);
  }

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = next(i + 1);
      final swap = list[i];
      list[i] = list[j];
      list[j] = swap;
    }
  }
}

/// Antwortkarten für Zahlenaufgaben.
///
/// Früher waren die Karten immer Lösung − 1, Lösung, + 1, + 2: Die richtige
/// Antwort war stets die zweitkleinste Karte und ohne Rechnen zu erkennen.
/// Jetzt entscheidet der Seed gleichmäßig, wie viele Karten kleiner als die
/// Lösung sind (0 bis 3). Die falschen Karten stammen zuerst aus [typical],
/// den typischen Fehlern der Aufgabenart (Übertrag vergessen, Rechenart
/// verwechselt, Nachbaraufgabe im Einmaleins …), der wichtigste Fehler
/// steht dort an erster Stelle. Reichen sie nicht, kommen
/// nahe Zahlen dazu, bei großen Zahlen mit gleicher Endziffer.
///
/// Karten sind nie negativ, nie doppelt, liegen in [min]..[max] und nie in
/// [blocked] (z. B. Zahlen, die in der Aufgabe schon sichtbar sind).
List<String> _numericChoices(
  int answer,
  int seed, {
  List<int> typical = const <int>[],
  int min = 0,
  int? max,
  Set<int> blocked = const <int>{},
}) {
  final dice = _SeedDice(seed);
  bool valid(int value) =>
      value != answer &&
      value >= min &&
      (max == null || value <= max) &&
      !blocked.contains(value);

  final lower = <int>[];
  final upper = <int>[];
  void offer(int value) {
    if (!valid(value)) return;
    final side = value < answer ? lower : upper;
    if (!side.contains(value)) side.add(value);
  }

  // Der erste Eintrag ist der wichtigste Fehler der Aufgabenart und kommt
  // zuerst an die Reihe; die übrigen wechseln von Aufgabe zu Aufgabe.
  if (typical.isNotEmpty) offer(typical.first);
  final others = typical.skip(1).toList();
  dice.shuffle(others);
  others.forEach(offer);
  final near = answer < 20
      ? const <int>[1, 2, 3, 4, 5, 6]
      : answer < 100
          ? const <int>[10, 1, 2, 20, 5, 3]
          : answer < 1000
              ? const <int>[10, 100, 1, 20, 2, 50]
              : const <int>[100, 10, 1000, 1, 200, 20];
  for (final offset in near) {
    offer(answer - offset);
    offer(answer + offset);
  }

  // Lage der Lösung der Größe nach: 0 = kleinste Karte, 3 = größte Karte.
  var below = dice.next(4);
  if (below > lower.length) below = lower.length;
  if (3 - below > upper.length) below = 3 - upper.length;
  if (below > lower.length) below = lower.length;
  final values = <int>[
    answer,
    ...lower.take(below),
    ...upper.take(3 - below),
  ];
  dice.shuffle(values);
  return <String>[for (final value in values) '$value'];
}

/// Bruch-Karten: die Lösung [numerator]/[denominator] und drei falsche
/// Brüche. Wie bei [_numericChoices] entscheidet der Seed, wie viele Karten
/// kleiner als die Lösung sind. [lower] und [upper] sind als (Zähler, Nenner)
/// angegeben. Brüche mit gleichem Wert wie die Lösung oder wie eine andere
/// Karte fallen weg, ebenso Zähler unter 1.
List<String> _fractionChoices(
  int numerator,
  int denominator,
  int seed, {
  required List<(int, int)> lower,
  required List<(int, int)> upper,
}) {
  final dice = _SeedDice(seed);
  final taken = <(int, int)>[(numerator, denominator)];
  List<(int, int)> usable(List<(int, int)> source, {required bool smaller}) {
    final out = <(int, int)>[];
    for (final item in source) {
      if (item.$1 < 1 || item.$2 < 1) continue;
      final cross = item.$1 * denominator - numerator * item.$2;
      if (smaller ? cross >= 0 : cross <= 0) continue;
      if ([...taken, ...out].any((other) => other.$1 * item.$2 == item.$1 * other.$2)) continue;
      out.add(item);
    }
    return out;
  }

  final below = usable(lower, smaller: true);
  taken.addAll(below);
  final above = usable(upper, smaller: false);
  var count = dice.next(4);
  if (count > below.length) count = below.length;
  if (3 - count > above.length) count = 3 - above.length;
  if (count > below.length) count = below.length;
  final cards = <(int, int)>[
    (numerator, denominator),
    ...below.take(count),
    ...above.take(3 - count),
  ];
  dice.shuffle(cards);
  return <String>[for (final card in cards) '${card.$1}/${card.$2}'];
}

/// Karten für die schriftliche Division. Zwei Karten sind reine Zahlen, zwei
/// haben einen Rest – so verrät die Form der Karten nicht, ob die Aufgabe
/// aufgeht. Typische Fehler: Rest ignoriert, aufgerundet, falscher Rest,
/// Rest erfunden, Nachbarzahl.
List<String> _divisionChoices(int quotient, int rest, int divisor, int seed) {
  final dice = _SeedDice(seed);
  final side = dice.next(2) == 0 ? -1 : 1;
  final otherRest = rest == 0
      ? 1 + dice.next(divisor - 1)
      : 1 + (rest - 1 + 1 + dice.next(divisor > 2 ? divisor - 2 : 1)) % (divisor - 1);
  final cards = rest == 0
      ? <String>[
          '$quotient',
          '${quotient + side * (dice.next(2) == 0 ? 1 : 10)}',
          '$quotient Rest $otherRest',
          '${quotient - 1} Rest ${1 + dice.next(divisor - 1)}',
        ]
      : <String>[
          '$quotient Rest $rest',
          '$quotient',
          '${quotient + 1}',
          if (otherRest != rest)
            '$quotient Rest $otherRest'
          else
            '${quotient + side} Rest $rest',
        ];
  dice.shuffle(cards);
  return cards;
}

/// Rechenweg der schriftlichen Multiplikation mit einstelligem Faktor,
/// Stelle für Stelle von rechts, mit den gemerkten Zehnern.
String _writtenMultiplicationSteps(int number, int factor) {
  final steps = <String>[];
  var carry = 0;
  var rest = number;
  while (rest > 0) {
    final digit = rest % 10;
    rest ~/= 10;
    final product = digit * factor + carry;
    final added = carry > 0 ? ', plus $carry = $product' : '';
    if (rest > 0) {
      steps.add('$digit · $factor = ${digit * factor}$added, schreibe ${product % 10}'
          '${product >= 10 ? ', merke ${product ~/ 10}' : ''}');
      carry = product ~/ 10;
    } else {
      steps.add('$digit · $factor = ${digit * factor}$added, schreibe $product');
    }
  }
  return 'Beginne bei den Einern: ${steps.join('. ')}. '
      'Ergebnis: $number · $factor = ${number * factor}.';
}

/// Rechenweg der schriftlichen Division, Stelle für Stelle von links, mit
/// Probe.
String _writtenDivisionSteps(int dividend, int divisor) {
  final steps = <String>[];
  var carry = 0;
  var started = false;
  for (final char in '$dividend'.split('')) {
    final current = carry * 10 + int.parse(char);
    final digit = current ~/ divisor;
    carry = current % divisor;
    if (digit == 0 && !started) continue;
    started = true;
    steps.add('$current : $divisor = $digit${carry > 0 ? ' Rest $carry' : ''}');
  }
  final quotient = dividend ~/ divisor;
  final rest = dividend % divisor;
  return 'Teile von links, Stelle für Stelle: ${steps.join(', ')}. '
      'Ergebnis: $quotient${rest > 0 ? ' Rest $rest' : ''}. '
      'Probe: $quotient · $divisor${rest > 0 ? ' + $rest' : ''} = $dividend.';
}

/// Erklärung einer Plusaufgabe, passend zum Zahlenraum, immer mit der
/// fertigen Rechnung am Schluss. „Lege 4443 und dann 2500 dazu“ hilft bei
/// großen Zahlen niemandem.
String _additionExplanation(int a, int b) {
  final sum = a + b;
  if (sum <= 20) {
    if (a < 10 && b < 10 && a > 0 && sum > 10) {
      final toTen = 10 - a;
      return 'Rechne zuerst bis zur 10: $a + $toTen = 10. Dann noch ${b - toTen} dazu: $a + $b = $sum.';
    }
    return 'Lege zuerst $a und dann $b dazu. Zusammen sind es $sum: $a + $b = $sum.';
  }
  if (sum <= 100) {
    final tens = b ~/ 10 * 10, ones = b % 10;
    if (tens == 0 || ones == 0) {
      return 'Zähle $b zu $a dazu. Achte auf den Zehnerübergang: $a + $b = $sum.';
    }
    return 'Rechne zuerst die Zehner, dann die Einer: $a + $tens = ${a + tens}, dann ${a + tens} + $ones = $sum. Also: $a + $b = $sum.';
  }
  return 'Schreibe die Zahlen untereinander und rechne Stelle für Stelle. Beginne bei den Einern und merke dir den Übertrag. $a + $b = $sum.';
}

/// Erklärung einer Minusaufgabe, passend zum Zahlenraum, immer mit dem
/// Ergebnis.
String _subtractionExplanation(int a, int b) {
  final difference = a - b;
  if (a <= 20) {
    if (a > 10 && b > a - 10 && difference < 10) {
      final toTen = a - 10;
      return 'Gehe zuerst bis zur 10 zurück: $a − $toTen = 10. Dann noch ${b - toTen} weg: $a − $b = $difference.';
    }
    return 'Starte bei $a und gehe $b ${b == 1 ? 'Schritt' : 'Schritte'} zurück: $a − $b = $difference.';
  }
  if (a <= 100) {
    final tens = b ~/ 10 * 10, ones = b % 10;
    if (tens == 0 || ones == 0) {
      return 'Ziehe $b von $a ab. Achte auf den Zehnerübergang: $a − $b = $difference.';
    }
    return 'Ziehe zuerst die Zehner ab, dann die Einer: $a − $tens = ${a - tens}, dann ${a - tens} − $ones = $difference. Also: $a − $b = $difference.';
  }
  return 'Schreibe die Zahlen untereinander und rechne Stelle für Stelle. Beginne bei den Einern. $a − $b = $difference.';
}

/// Erklärt, wie das Zahlwort gebaut ist.
String _numberWordExplanation(int number, String word) {
  if (number >= 13 && number <= 19) {
    final ones = _numberWords[number - 10]!;
    final note = number == 16
        ? ' Aus „sechs“ wird dabei „sech“.'
        : number == 17
            ? ' Aus „sieben“ wird dabei „sieb“.'
            : '';
    return 'Bei $number hörst du zuerst die ${number - 10} und dann die 10: $ones und zehn wird zu „$word“.$note';
  }
  if (number == 11 || number == 12) {
    return '„elf“ und „zwölf“ sind eigene Wörter. $number schreibt man „$word“.';
  }
  if (number == 20) {
    return '20 sind zwei Zehner. Das Zahlwort heißt „zwanzig“.';
  }
  return 'Sprich die Zahl langsam und höre auf jeden Laut: $number schreibt man „$word“.';
}

/// Typische falsche Ergebnisse bei a + b: abgezogen statt dazugezählt,
/// Übertrag vergessen, um einen Zehner oder Hunderter daneben.
List<int> _additionErrors(int a, int b) {
  final sum = a + b;
  return <int>[
    (a - b).abs(),
    _sumWithoutCarry(a, b),
    if (sum >= 10) ...<int>[sum - 10, sum + 10],
    if (sum >= 200) ...<int>[sum - 100, sum + 100],
    if (sum < 20) ...<int>[sum - 1, sum + 1, sum + 2],
  ];
}

/// Typische falsche Ergebnisse bei a − b: dazugezählt statt abgezogen,
/// in jeder Spalte „klein von groß“, gemerkte 1 vergessen.
List<int> _subtractionErrors(int a, int b) {
  final difference = a - b;
  return <int>[
    a + b,
    _differenceDigitwise(a, b),
    _differenceWithoutCarry(a, b),
    if (a >= 20) ...<int>[difference + 10, difference - 10],
    if (a >= 200) ...<int>[difference + 100, difference - 100],
    if (a < 20) ...<int>[difference + 1, difference - 1, difference + 2],
  ];
}

/// Typische Fehler beim Umrechnen mit 1000 (kg → g, l → ml): falsche
/// Umrechnungszahl, Rest vergessen, Rest an die falsche Stelle gesetzt.
List<int> _thousandConversionErrors(int whole, int extra) => <int>[
      whole * 100 + extra,
      whole * 1000 + extra ~/ 10,
      whole * 10000 + extra,
      if (extra > 0) whole * 1000,
      whole * 100 + extra ~/ 10,
      whole * 100,
    ];

/// Spaltenweise addiert, ohne den Übertrag mitzunehmen: 47 + 38 → 75.
int _sumWithoutCarry(int a, int b) {
  var result = 0;
  var place = 1;
  var x = a, y = b;
  while (x > 0 || y > 0) {
    result += ((x % 10 + y % 10) % 10) * place;
    place *= 10;
    x ~/= 10;
    y ~/= 10;
  }
  return result;
}

/// In jeder Spalte die kleinere von der größeren Ziffer abgezogen:
/// 62 − 24 → 42.
int _differenceDigitwise(int a, int b) {
  var result = 0;
  var place = 1;
  var x = a, y = b;
  while (x > 0 || y > 0) {
    result += (x % 10 - y % 10).abs() * place;
    place *= 10;
    x ~/= 10;
    y ~/= 10;
  }
  return result;
}

/// Ergänzt, aber die gemerkte 1 in der nächsten Spalte vergessen:
/// 62 − 24 → 48.
int _differenceWithoutCarry(int a, int b) {
  var result = 0;
  var place = 1;
  var x = a, y = b;
  while (x > 0 || y > 0) {
    result += ((x % 10 - y % 10 + 10) % 10) * place;
    place *= 10;
    x ~/= 10;
    y ~/= 10;
  }
  return result;
}

/// Jede Stelle mit einem einstelligen Faktor malgenommen, die gemerkten
/// Zehner aber nicht dazugezählt: 435 · 8 → 3240.
int _productWithoutCarry(int a, int digit) {
  var result = 0;
  var place = 1;
  var x = a;
  while (x > 0) {
    final product = (x % 10) * digit;
    result += (x >= 10 ? product % 10 : product) * place;
    place *= 10;
    x ~/= 10;
  }
  return result;
}

String _repeatEmoji(String emoji, int count) => List<String>.filled(count.clamp(1, 12).toInt(), emoji).join();

const Map<int, String> _numberWords = <int, String>{
  0: 'null',
  1: 'eins',
  2: 'zwei',
  3: 'drei',
  4: 'vier',
  5: 'fünf',
  6: 'sechs',
  7: 'sieben',
  8: 'acht',
  9: 'neun',
  10: 'zehn',
  11: 'elf',
  12: 'zwölf',
  13: 'dreizehn',
  14: 'vierzehn',
  15: 'fünfzehn',
  16: 'sechzehn',
  17: 'siebzehn',
  18: 'achtzehn',
  19: 'neunzehn',
  20: 'zwanzig',
};

/// Zahlwort-Karten: typisch verwechselt werden die Zahl mit und ohne „zehn“
/// (drei – dreizehn) sowie zwölf und zwanzig.
List<String> _numberWordChoices(int number, int seed) {
  final numbers = _numericChoices(
    number,
    seed,
    typical: <int>[number - 10, number + 10, if (number == 12) 20, if (number == 20) 12],
    max: 20,
  );
  return <String>[for (final value in numbers) _numberWords[int.parse(value)]!];
}

// ════════════════════════════════════════════════════════════════════════
// SACHAUFGABEN-POOLS (Heinz 2026-06-03: "modernisierte Aufgaben, mehr Logik")
// ════════════════════════════════════════════════════════════════════════
// Vorher gab es pro Schwierigkeit GENAU EINE Geschichte. Das Kind lernte
// Pattern-Matching ("immer Lisa+Aepfel") statt echtes Sachrechnen.
//
// Jetzt: 8/7/6 vielfaeltige Szenarien aus dem AT-Volksschul-Alltag
// (Schultag, Pausenhof, Familie, Garten, Markt, Sport, Schulausflug).
// Pro Aufruf wird per Seed eine andere Geschichte gewuerfelt.

class _WordStory {
  const _WordStory(this.prompt, this.explain);
  final String Function(int a, int b, int answer) prompt;
  final String Function(int a, int b, int answer) explain;
}

// 1-Schritt (Klasse 1-2): nur Addition mit a + b.
const List<_WordStory> _oneStepStories = <_WordStory>[
  _WordStory(
    _p1Apfel, _e1Sum),
  _WordStory(
    _p1Kekse, _e1Sum),
  _WordStory(
    _p1Bus, _e1Sum),
  _WordStory(
    _p1Buntstifte, _e1Sum),
  _WordStory(
    _p1Schulhof, _e1Sum),
  _WordStory(
    _p1Sticker, _e1Sum),
  _WordStory(
    _p1Garten, _e1Sum),
  _WordStory(
    _p1Sport, _e1Sum),
  _WordStory(_p1Bibliothek, _e1Sum),
  _WordStory(_p1Baum, _e1Sum),
  _WordStory(_p1Jause, _e1Sum),
  _WordStory(_p1Basteln, _e1Sum),
  // Heinz' Holo-Textaufgabe: zählbare Äpfel, Zehnerfeld und Zwillingsaufgabe.
  _WordStory(_p1Korb, _e1Sum),
];

String _p1Korb(int a, int b, int s) => HoloLessonCatalog.korbPrompt(a, b);

String _p1Bibliothek(int a, int b, int s) => 'In der Leseecke liegen $a Bilderbücher. Die Lehrerin bringt $b dazu. Wie viele Bücher sind es zusammen?';
String _p1Baum(int a, int b, int s) => 'Auf dem Baum sitzen $a Vögel. $b fliegen dazu. Wie viele Vögel sitzen jetzt auf dem Baum?';
String _p1Jause(int a, int b, int s) => 'Für die Jause gibt es $a Apfelstücke und $b Birnenstücke. Wie viele Obststücke sind es zusammen?';
String _p1Basteln(int a, int b, int s) => 'Lumo bastelt $a Papiersterne. Mia bastelt $b. Wie viele Sterne haben sie zusammen?';

const List<_WordStory> _subtractionStories = <_WordStory>[
  _WordStory(_pMinusSemmeln, _eMinus),
  _WordStory(_pMinusStifte, _eMinus),
  _WordStory(_pMinusBuecher, _eMinus),
  _WordStory(_pMinusBus, _eMinus),
];
String _pMinusSemmeln(int a, int b, int s) => 'Auf dem Teller liegen $a Semmeln. $b werden gegessen. Wie viele Semmeln bleiben übrig?';
String _pMinusStifte(int a, int b, int s) => 'Lumo hat $a Buntstifte. Er verleiht $b an Mia. Wie viele Buntstifte hat Lumo noch?';
String _pMinusBuecher(int a, int b, int s) => 'Im Regal stehen $a Bücher. $b werden ausgeliehen. Wie viele Bücher stehen noch im Regal?';
String _pMinusBus(int a, int b, int s) => 'Im Bus sitzen $a Kinder. An der Haltestelle steigen $b aus. Wie viele Kinder sitzen noch im Bus?';
String _eMinus(int a, int b, int s) => 'Wegnehmen: $a − $b = $s. Starte mit $a und streiche $b weg.';

String _p1Apfel(int a, int b, int s) => 'Lisa hat $a Äpfel und bekommt $b dazu. Wie viele Äpfel hat sie jetzt?';
String _p1Kekse(int a, int b, int s) => 'Tom hat $a Kekse gebacken. Oma bringt $b weitere. Wie viele Kekse sind es zusammen?';
String _p1Bus(int a, int b, int s) => 'Im Bus sitzen $a Kinder. An der nächsten Haltestelle steigen $b zu. Wie viele Kinder sind jetzt im Bus?';
String _p1Buntstifte(int a, int b, int s) => 'Mia hat $a rote Buntstifte und $b blaue. Wie viele Buntstifte hat sie zusammen?';
String _p1Schulhof(int a, int b, int s) => 'Am Schulhof spielen $a Kinder Fangen und $b Kinder Tempelhüpfen. Wie viele Kinder spielen zusammen?';
String _p1Sticker(int a, int b, int s) => 'Jonas sammelt Sticker. Er hat $a und bekommt $b neue geschenkt. Wie viele Sticker hat er jetzt?';
String _p1Garten(int a, int b, int s) => 'In Omas Garten blühen $a Tulpen und $b Rosen. Wie viele Blumen blühen zusammen?';
String _p1Sport(int a, int b, int s) => 'Beim Schulfest liegen $a Würstelsemmeln und $b Käsesemmeln bereit. Wie viele Semmeln sind das zusammen?';

String _e1Sum(int a, int b, int s) => 'Plusgeschichte: $a + $b = $s. Zähle erst die erste Gruppe, dann die zweite dazu.';

/// Eine fertige Sachaufgabe mit mehreren Schritten.
class _StepStory {
  const _StepStory(this.prompt, this.answer, this.explanation, this.typical);
  final String prompt;
  final int answer;
  final String explanation;

  /// Typische falsche Ergebnisse: nach dem ersten Schritt aufgehört oder
  /// im zweiten Schritt die falsche Rechenart genommen.
  final List<int> typical;
}

/// Baut aus den zwei Zahlen der Vorlage und einer dritten Zahl (2 bis 9)
/// eine Geschichte.
typedef _StoryBuilder = _StepStory Function(int a, int b, int c);

// Zwei Schritte (Klasse 3). Früher rechnete jede Geschichte „a + b − 3“.
// Jetzt wechseln die Rechenwege: dazu und weg, zweimal weg, drei Mengen,
// mal und plus, mal und minus, „mehr als“.
const List<_StoryBuilder> _twoStepStories = <_StoryBuilder>[
  _s2Tulpen,
  _s2Buecherei,
  _s2Schwimmbad,
  _s2Aquarium,
  _s2Markt,
  _s2Bus,
  _s2Papier,
  _s2Lesen,
  _s2Gebaeck,
  _s2Sessel,
  _s2Sticker,
  _s2Garderobe,
];

_StepStory _plusMinus(String prompt, int a, int b, int c) => _StepStory(
      prompt,
      a + b - c,
      'Zwei Schritte: $a + $b = ${a + b}, dann ${a + b} − $c = ${a + b - c}.',
      <int>[a + b, a + b + c, a - c, b - c],
    );

_StepStory _s2Tulpen(int a, int b, int c) => _plusMinus(
    'Im Garten blühen $a Tulpen. $b gehen neu auf, $c werden gepflückt. Wie viele Tulpen blühen jetzt?', a, b, c);
_StepStory _s2Buecherei(int a, int b, int c) => _plusMinus(
    'In der Bücherei stehen $a Bilderbücher. $b kommen neu dazu, $c werden ausgeliehen. Wie viele Bilderbücher stehen jetzt in der Bücherei?', a, b, c);
_StepStory _s2Schwimmbad(int a, int b, int c) => _plusMinus(
    'Im Schwimmbad sind $a Kinder im großen Becken und $b im kleinen Becken. $c Kinder gehen zur Rutsche. Wie viele Kinder sind noch in den Becken?', a, b, c);
_StepStory _s2Aquarium(int a, int b, int c) => _plusMinus(
    'Im Aquarium schwimmen $a Goldfische und $b Neonfische. $c Fische verstecken sich hinter den Pflanzen. Wie viele Fische sieht man?', a, b, c);

_StepStory _minusMinus(String prompt, int start, int b, int c) => _StepStory(
      prompt,
      start - b - c,
      'Zwei Schritte: $start − $b = ${start - b}, dann ${start - b} − $c = ${start - b - c}.',
      <int>[start - b, start - c, start - b + c, b + c],
    );

_StepStory _s2Markt(int a, int b, int c) => _minusMinus(
    'Am Markt liegen ${a + 20} Paradeiser. Am Vormittag werden $b verkauft, am Nachmittag $c. Wie viele Paradeiser sind noch da?', a + 20, b, c);
_StepStory _s2Bus(int a, int b, int c) => _minusMinus(
    'Im Bus sitzen ${a + 20} Kinder. An der ersten Haltestelle steigen $b aus, an der zweiten $c. Wie viele Kinder sitzen noch im Bus?', a + 20, b, c);

_StepStory _plusPlus(String prompt, int a, int b, int c) => _StepStory(
      prompt,
      a + b + c,
      'Zwei Schritte: $a + $b = ${a + b}, dann ${a + b} + $c = ${a + b + c}.',
      <int>[a + b, a + c, a + b - c, b + c],
    );

_StepStory _s2Papier(int a, int b, int c) => _plusPlus(
    'Für die Bastelstunde gibt es $a rote, $b blaue und $c gelbe Papierbögen. Wie viele Papierbögen sind das zusammen?', a, b, c);
_StepStory _s2Lesen(int a, int b, int c) => _plusPlus(
    'Lena liest am Montag $a Seiten, am Dienstag $b Seiten und am Mittwoch $c Seiten. Wie viele Seiten hat sie gelesen?', a, b, c);

_StepStory _s2Gebaeck(int a, int b, int c) {
  final packs = 2 + a % 4;
  return _StepStory(
    'Mama kauft $packs Packungen mit je $c Semmeln und $b einzelne Kipferl. Wie viele Stück Gebäck sind das?',
    packs * c + b,
    'Zwei Schritte: $packs · $c = ${packs * c}, dann ${packs * c} + $b = ${packs * c + b}.',
    <int>[packs * c, packs + c + b, c + b, packs * (c + b)],
  );
}

_StepStory _s2Sessel(int a, int b, int c) {
  final tables = 3 + a % 4;
  final all = tables * c;
  final carried = 2 + b % (all - 2);
  return _StepStory(
    'In der Klasse stehen $tables Tische mit je $c Sesseln. $carried Sessel werden in den Turnsaal getragen. Wie viele Sessel bleiben in der Klasse?',
    all - carried,
    'Zwei Schritte: $tables · $c = $all, dann $all − $carried = ${all - carried}.',
    <int>[all, all + carried, tables + c - carried],
  );
}

_StepStory _s2Sticker(int a, int b, int c) => _StepStory(
      'Anna hat $a Sticker. Ben hat $b Sticker mehr als Anna. Wie viele Sticker haben beide zusammen?',
      a + a + b,
      'Zwei Schritte: Ben hat $a + $b = ${a + b} Sticker. Zusammen: $a + ${a + b} = ${a + a + b}.',
      <int>[a + b, a + a, a + a - b],
    );

_StepStory _s2Garderobe(int a, int b, int c) => _StepStory(
      'In der Garderobe hängen ${a + 5} Jacken. $c Kinder holen ihre Jacke, danach hängen $b Kinder ihre Jacke auf. Wie viele Jacken hängen jetzt dort?',
      a + 5 - c + b,
      'Zwei Schritte: ${a + 5} − $c = ${a + 5 - c}, dann ${a + 5 - c} + $b = ${a + 5 - c + b}.',
      <int>[a + 5 - c, a + 5 - c - b, a + 5 + b + c],
    );

// Drei Schritte (Klasse 4). Früher rechnete jede Geschichte „(a + b) · 2 − 4“.
const List<_StoryBuilder> _threeStepStories = <_StoryBuilder>[
  _s3Obstkiste,
  _s3Sterne,
  _s3Flaschen,
  _s3Buecherei,
  _s3Sportfest,
  _s3Einkauf,
  _s3Karten,
  _s3Zug,
];

_StepStory _s3Obstkiste(int a, int b, int c) => _StepStory(
      'In einer Kiste liegen $a Äpfel und $b Birnen. Eine zweite Kiste ist genau gleich gefüllt. $c Früchte werden gegessen. Wie viele Früchte bleiben?',
      (a + b) * 2 - c,
      'Drei Schritte: $a + $b = ${a + b}, dann ${a + b} · 2 = ${(a + b) * 2}, dann ${(a + b) * 2} − $c = ${(a + b) * 2 - c}.',
      <int>[(a + b) * 2, a + b - c, (a + b) * 2 + c, a + b],
    );

_StepStory _s3Sterne(int a, int b, int c) {
  final days = 3 + c % 3;
  final all = (a + b) * days;
  return _StepStory(
    'Die Klasse bastelt an $days Tagen jeden Tag $a gelbe und $b blaue Sterne. $c Sterne werden verschenkt. Wie viele Sterne bleiben?',
    all - c,
    'Drei Schritte: $a + $b = ${a + b}, dann ${a + b} · $days = $all, dann $all − $c = ${all - c}.',
    <int>[all, a + b - c, all + c, a * days + b - c],
  );
}

_StepStory _s3Flaschen(int a, int b, int c) {
  final juiceCrates = 2 + a % 4;
  final waterCrates = 2 + b % 4;
  final juice = juiceCrates * 6;
  final water = waterCrates * 12;
  return _StepStory(
    'Für das Schulfest gibt es $juiceCrates Kisten mit je 6 Flaschen Saft und $waterCrates Kisten mit je 12 Flaschen Wasser. $c Flaschen bleiben übrig. Wie viele Flaschen wurden getrunken?',
    juice + water - c,
    'Drei Schritte: $juiceCrates · 6 = $juice und $waterCrates · 12 = $water. Zusammen: $juice + $water = ${juice + water}. Dann ${juice + water} − $c = ${juice + water - c}.',
    <int>[juice + water, juice + water + c, juice - c, water - c],
  );
}

_StepStory _s3Buecherei(int a, int b, int c) {
  final start = 200 + a * 5;
  return _StepStory(
    'In der Bücherei stehen $start Bücher. Am Montag werden $a ausgeliehen, am Dienstag $b. Am Mittwoch kommen $c zurück. Wie viele Bücher stehen jetzt in der Bücherei?',
    start - a - b + c,
    'Drei Schritte: $start − $a = ${start - a}, dann ${start - a} − $b = ${start - a - b}, dann ${start - a - b} + $c = ${start - a - b + c}.',
    <int>[start - a - b, start - a - b - c, start - a + c, start + c],
  );
}

_StepStory _s3Sportfest(int a, int b, int c) {
  final groups = 2 + c % 5;
  final started = groups * a;
  return _StepStory(
    'Beim Sportfest starten $groups Gruppen mit je $a Kindern. $b Kinder kommen später dazu, $c Kinder hören früher auf. Wie viele Kinder kommen ins Ziel?',
    started + b - c,
    'Drei Schritte: $groups · $a = $started, dann $started + $b = ${started + b}, dann ${started + b} − $c = ${started + b - c}.',
    <int>[started + b, started - c, started + b + c, groups + a + b - c],
  );
}

_StepStory _s3Einkauf(int a, int b, int c) {
  final booklets = 2 + c % 4;
  final price = 2 + a % 4;
  final book = 8 + b;
  final total = booklets * price + book;
  final paid = total < 50 ? 50 : 100;
  return _StepStory(
    'Tim kauft $booklets Hefte um je $price € und ein Buch um $book €. Er zahlt mit einem $paid-€-Schein. Wie viele Euro bekommt er zurück?',
    paid - total,
    'Drei Schritte: $booklets · $price = ${booklets * price}, dann ${booklets * price} + $book = $total, dann $paid − $total = ${paid - total}.',
    <int>[total, paid - booklets * price, paid - book, paid - price - book],
  );
}

_StepStory _s3Karten(int a, int b, int c) {
  final children = 2 + a % 5;
  final each = 10 + b;
  final given = c < each ? c : each - 1;
  final got = 3 + b % 6;
  return _StepStory(
    '${children * each} Sammelkarten werden gerecht an $children Kinder verteilt. Jedes Kind verschenkt $given Karten und bekommt später $got dazu. Wie viele Karten hat jedes Kind dann?',
    each - given + got,
    'Drei Schritte: ${children * each} : $children = $each, dann $each − $given = ${each - given}, dann ${each - given} + $got = ${each - given + got}.',
    <int>[each, each - given, each + given + got, each - given - got],
  );
}

_StepStory _s3Zug(int a, int b, int c) {
  final wagons = 3 + c % 4;
  final entering = 2 + (a + b) % 9;
  return _StepStory(
    // Die Anzahl der Waggons wird zum Rechnen nicht gebraucht.
    'In einem Zug mit $wagons Waggons sitzen $a Erwachsene und $b Kinder. Am Bahnhof steigen $c Personen aus und $entering ein. Wie viele Personen sitzen jetzt im Zug?',
    a + b - c + entering,
    'Die Zahl der Waggons brauchst du nicht. Drei Schritte: $a + $b = ${a + b}, dann ${a + b} − $c = ${a + b - c}, dann ${a + b - c} + $entering = ${a + b - c + entering}.',
    <int>[a + b - c, a + b + entering, a + b - c - entering, a + b + wagons - c + entering],
  );
}
