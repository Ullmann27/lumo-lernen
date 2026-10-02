/// Deterministische Mathe-Templates für Volksschule 1-4.
///
/// Der Generator wählt nur noch ein Template und konkretisiert es über Seed.
/// Dadurch entstehen pro Einheit viele Varianten mit stabilem Prompt-Pattern.
class MathTaskTemplates {
  const MathTaskTemplates._();

  static const List<MathTaskTemplate> templates = <MathTaskTemplate>[
    MathTaskTemplate(id: 'g1_word_problem', grade: 1, unit: 'Textaufgaben', kind: MathTemplateKind.wordProblemOneStep, validRangeA: <int>[1, 7], validRangeB: <int>[1, 5], promptPattern: 'sachaufgabe-ein-schritt'),
    MathTaskTemplate(id: 'g2_sub_story', grade: 2, unit: 'Textaufgaben', kind: MathTemplateKind.wordProblemOneStep, validRangeA: <int>[5, 20], validRangeB: <int>[1, 5], promptPattern: 'sachaufgabe-wegnehmen'),
    MathTaskTemplate(id: 'g1_add_10', grade: 1, unit: 'Plus bis 10', kind: MathTemplateKind.addition, validRangeA: <int>[1, 6], validRangeB: <int>[1, 6], promptPattern: 'plus-bis-10',
    ),
    MathTaskTemplate(id: 'g1_sub_10', grade: 1, unit: 'Minus bis 10', kind: MathTemplateKind.subtraction, validRangeA: <int>[3, 10], validRangeB: <int>[1, 7], promptPattern: 'minus-bis-10',
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

    MathTaskTemplate(id: 'g3_tables', grade: 3, unit: 'Einmaleins', kind: MathTemplateKind.multiplication, validRangeA: <int>[2, 10], validRangeB: <int>[2, 10], promptPattern: 'einmaleins',
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
    final pool = useStrict
        ? templatesForGradeStrict(grade, unit: unit)
        : templatesForGrade(grade, unit: unit);
    // Auswahl und Wiederholungsquote dürfen nicht denselben Modulo nutzen:
    // Bei 16 Templates wären sonst ganze Familien nie erreichbar.
    final template = pool[_positive(_mixSeed(seed + 101), pool.length)];
    return template.concretize(_mixSeed(seed + 809));
  }

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

  MathConcreteTask concretize(int seed) {
    final a = _valueInRange(validRangeA, _mixSeed(seed + 17));
    final b = _valueInRange(validRangeB, _mixSeed(seed + 53));
    switch (kind) {
      case MathTemplateKind.addition:
        final limit = int.tryParse(
          RegExp(r'bis (\d+)').firstMatch(unit)?.group(1) ?? '',
        );
        final right = limit == null ? b : b.clamp(1, limit - a).toInt();
        final answer = a + right;
        return _numberTask('$a + $right = ?', answer, 'Lege zuerst $a und dann $right dazu. Zusammen sind es $answer.', 'dots',
        );
      case MathTemplateKind.subtraction:
        final minuend = a ;
        final subtrahend = b.clamp(1, minuend).toInt();
        final answer = minuend - subtrahend;
        return _numberTask('$minuend - $subtrahend = ?', answer, 'Starte bei $minuend und gehe $subtrahend Schritte zurück.', 'line',
        );
      case MathTemplateKind.numberLineMissing:
        final start = a;
        final answer = start + 2;
        return _numberTask('Welche Zahl fehlt? $start, ${start + 1}, _, ${start + 3}', answer, 'Am Zahlenstrahl geht es immer um 1 weiter.', 'number_line',
        );
      case MathTemplateKind.quantityCompare:
        final left = a;
        final answer = left == b ? 'gleich' : left > b ? 'links' : 'rechts';
        final leftDots = _repeatEmoji('🍎', left);
        final rightDots = _repeatEmoji('🍎', b);
        return _choice('$leftDots oder $rightDots – wo ist mehr?', answer, <String>['links', 'rechts', 'gleich'], 'Vergleiche die Menge, nicht die Länge der Zeile.', 'quantity',
        );
      case MathTemplateKind.numberWord:
        final answer = _numberWords[a] ?? '$a';
        return _choice('Wie schreibt man die Zahl $a als Wort?', answer, _numberWordChoices(a), 'Zahlwörter liest man wie normale Wörter.', 'word_number',
        );
      case MathTemplateKind.shapeRecognition:
        final shapes = <String, String>{'Welche Form hat 3 Ecken?': 'Dreieck', 'Welche Form ist ganz rund?': 'Kreis', 'Welche Form hat 4 gleich lange Seiten?': 'Quadrat', 'Welche Form hat keine Ecke?': 'Kreis', 'Welche Form sieht aus wie ein Ei?': 'Oval', 'Welche Form hat 4 Ecken und zwei längere Seiten?': 'Rechteck',
        };
        final entry = shapes.entries.elementAt(_positive(seed, shapes.length));
        return _choice(entry.key, entry.value, <String>['Dreieck', 'Kreis', 'Quadrat', 'Rechteck', 'Oval'], 'Schau auf Ecken, Seiten und Rundungen.', 'shape',
        );
      case MathTemplateKind.moneyCompare:
        final left = a;
        final right = b;
        final answer = left == right ? 'gleich viel' : left > right ? '$left €' : '$right €';
        return _choice('Was kostet mehr: $left € oder $right €?', answer, <String>['$left €', '$right €', 'gleich viel'], 'Mehr Euro bedeutet höherer Preis.', 'money',
        );
      case MathTemplateKind.dayHours:
        return _choice('Wie viele Stunden hat ein Tag?', '24', <String>['12', '24', '30'], 'Ein Tag hat 24 Stunden: Tag und Nacht zusammen.', 'clock',
        );
      case MathTemplateKind.symmetry:
        if (unit == 'Symmetrieachsen') {
          const examples = <(String, int)>[
            ('ein Quadrat', 4),
            ('ein Rechteck, das kein Quadrat ist', 2),
            ('ein gleichseitiges Dreieck', 3),
            ('ein gleichschenkliges Dreieck, das nicht gleichseitig ist', 1),
          ];
          final entry = examples[_positive(_mixSeed(seed), examples.length)];
          return _numberTask('Wie viele Symmetrieachsen hat ${entry.$1}?', entry.$2,
              'Eine Symmetrieachse teilt eine Form in zwei spiegelgleiche Hälften. Prüfe jede mögliche Faltlinie.', 'symmetry');
        }
        const data = <String, bool>{
          'ein Kreis': true, 'ein Quadrat': true,
          'ein gleichseitiges Dreieck': true,
          'ein Dreieck mit drei verschieden langen Seiten': false,
        };
        final entry = data.entries.elementAt(_positive(_mixSeed(seed), data.length));
        return _choice('Hat ${entry.key} eine Spiegelachse?', entry.value ? 'ja' : 'nein',
            <String>['ja', 'nein'], 'Beim Spiegeln an einer Achse müssen beide Hälften genau aufeinanderpassen.', 'symmetry');
      case MathTemplateKind.multiplicationPrep:
        final answer = b;
        return _numberTask('Wie oft $a ist ${a * b}?', answer, '$a wird $answer-mal genommen: ${List<String>.filled(answer, '$a').join(' + ')} = ${a * b}.', 'groups',
        );
      case MathTemplateKind.wordProblemOneStep:
        if (promptPattern == 'sachaufgabe-wegnehmen') {
          final removed = b.clamp(1, a).toInt();
          final answer = a - removed;
          final story = _subtractionStories[_positive(seed, _subtractionStories.length)];
          return _numberTask(story.prompt(a, removed, answer), answer, story.explain(a, removed, answer), 'story');
        }
        // 2026-06-03: vorher EINE Geschichte (Lisa+Aepfel) - Kind sah staendig
        // dieselbe Aufgabe nur mit anderen Zahlen. Jetzt 8 Szenarien aus dem
        // oesterreichischen Alltag (AT-Lehrplan VS Sachrechnen).
        final answer = a + b;
        final s1 = _positive(seed, _oneStepStories.length);
        final story = _oneStepStories[s1];
        return _numberTask(story.prompt(a, b, answer), answer, story.explain(a, b, answer), 'story',
        );
      case MathTemplateKind.moneyChange:
        final denomination = grade >= 3 ? <int>[2, 5, 10][b % 3] : (b.isEven ? 2 : 1);
        final amount = grade >= 3 ? a * 2 : a;
        final euro = (amount ~/ denomination).clamp(1, 100).toInt() * denomination;
        final count = euro ~/ denomination;
        final pieces = denomination <= 2 ? 'Münzen' : 'Scheine';
        String counted(int value) => '$value ${value == 1 ? (denomination <= 2 ? 'Münze' : 'Schein') : pieces}';
        return _choice('Wie viele $denomination-€-$pieces ergeben $euro €?', counted(count),
            <String>[counted(count), counted(count + 1), counted(count == 1 ? count + 2 : count - 1)],
            'Zähle in $denomination-er-Schritten bis $euro: $count × $denomination € = $euro €.', 'money_change');
      case MathTemplateKind.clockTime:
        final minutes = <int>[0, 15, 30, 45][b];
        String clock(int hour, int minute) => '${(hour - 1) % 12 + 1}:${minute.toString().padLeft(2, '0')} Uhr';
        final answer = clock(a, minutes);
        return _choice('Welche Uhrzeit ist gemeint: Stunde $a und Minute $minutes?', answer,
            <String>[answer, clock(a + 1, minutes), clock(a, (minutes + 15) % 60), clock(a, (minutes + 30) % 60)],
            'Die Zahl vor dem Doppelpunkt nennt die Stunde. Danach stehen die Minuten; 00 heißt eine volle Stunde.', 'clock');
      case MathTemplateKind.lengthConversion:
        final extra = b * 10;
        final answer = a * 100 + extra;
        final amount = extra == 0 ? '$a Meter' : '$a Meter und $extra Zentimeter';
        return _numberTask('Wie viele Zentimeter sind $amount?', answer,
            '1 Meter sind 100 Zentimeter. Rechne $a × 100 und zähle $extra Zentimeter dazu.', 'ruler');
      case MathTemplateKind.evenOdd:
        final answer = a.isEven ? 'gerade' : 'ungerade';
        return _choice('Ist $a gerade oder ungerade?', answer, <String>['gerade', 'ungerade', 'beides'], 'Gerade Zahlen kann man in zwei gleiche Gruppen teilen.', 'parity',
        );
      case MathTemplateKind.halfDouble:
        final even = a.isEven ? a : a + 1;
        if (b.isEven) {
          final answer = even ~/ 2;
          return _numberTask('Was ist die Hälfte von $even?', answer, 'Teile $even in zwei gleiche Gruppen.', 'half',
          );
        }
        final answer = even * 2;
        return _numberTask('Was ist das Doppelte von $even?', answer, 'Doppelt heißt: $even + $even.', 'double',
        );
      case MathTemplateKind.tensOnes:
        final tens = a ~/ 10;
        final ones = a % 10;
        final askTens = b.isEven;
        return _numberTask(askTens ? 'Wie viele Zehner hat $a?' : 'Wie viele Einer hat $a?', askTens ? tens : ones, '$a besteht aus $tens Zehnern und $ones Einern.', 'ten_ones',
        );
      case MathTemplateKind.multiplication:
        final answer = a * b;
        return _numberTask('$a × $b = ?', answer, 'Nutze die Einmaleins-Reihe von $a.', 'times_table',
        );
      case MathTemplateKind.writtenAddition:
        final right = grade == 3 ? b.clamp(1, 1000 - a).toInt() : b;
        final answer = a + right;
        return _numberTask('Schriftlich: $a + $right = ?', answer, 'Schreibe Einer unter Einer, Zehner unter Zehner, Hunderter unter Hunderter.', 'written_add',
        );
      case MathTemplateKind.writtenSubtraction:
        final minuend = a > b ? a : a + b;
        final answer = minuend - b;
        return _numberTask('Schriftlich: $minuend - $b = ?', answer, 'Rechne von rechts nach links und tausche, wenn nötig.', 'written_sub',
        );
      case MathTemplateKind.fractionHalf:
        final even = a.isEven ? a : a + 1;
        final answer = even ~/ 2;
        return _numberTask('Was ist die Hälfte von $even?', answer, 'Die Hälfte ist einer von zwei gleich großen Teilen.', 'fraction_half',
        );
      case MathTemplateKind.wordProblemTwoStep:
        final answer = a + b - 3;
        final s2 = _positive(seed, _twoStepStories.length);
        final story = _twoStepStories[s2];
        return _numberTask(story.prompt(a, b, answer), answer, story.explain(a, b, answer), 'story_two',
        );
      case MathTemplateKind.perimeter:
        final answer = 2 * (a + b);
        return _numberTask('Ein Rechteck ist $a cm lang und $b cm breit. Wie groß ist der Umfang?', answer, 'Umfang: $a + $b + $a + $b = $answer cm.', 'perimeter',
        );
      case MathTemplateKind.area:
        final answer = a * b;
        return _numberTask('Ein Rechteck ist $a cm lang und $b cm breit. Wie groß ist der Flächeninhalt?', answer, 'Fläche: Länge mal Breite, also $a × $b = $answer cm².', 'area',
        );
      case MathTemplateKind.writtenMultiplication:
        final answer = a * b;
        return _numberTask('Schriftlich: $a × $b = ?', answer, 'Multipliziere jede Stelle von $a mit $b.', 'written_mul',
        );
      case MathTemplateKind.division:
        final divisor = b.clamp(2, 12).toInt();
        final quotient = (a ~/ divisor).clamp(2, 99).toInt();
        final dividend = quotient * divisor;
        return _numberTask('$dividend : $divisor = ?', quotient, 'Teile $dividend in $divisor gleich große Gruppen.', 'division',
        );
      case MathTemplateKind.simpleFractionAdd:
        final denominator = b + 2;
        final left = 1 + (a - 1) % (denominator - 2);
        final right = 1 + _positive(_mixSeed(seed + 211), denominator - left - 1);
        final numerator = left + right;
        final answer = '$numerator/$denominator';
        return _choice('$left/$denominator + $right/$denominator = ?', answer,
            <String>[answer, '${numerator - 1}/$denominator', '${numerator + 1}/$denominator'],
            'Die Teile bleiben gleich groß: Der Nenner bleibt $denominator. Addiere nur die Zähler: $left + $right = $numerator. Kürzen ist hier nicht nötig.', 'fraction_add');
      case MathTemplateKind.decimals:
        final left = a / 10;
        final right = b / 10;
        final answer = (left + right).toStringAsFixed(1).replaceAll('.', ',');
        return _choice('${left.toStringAsFixed(1).replaceAll('.', ',')} + ${right.toStringAsFixed(1).replaceAll('.', ',')} = ?', answer, <String>[answer, (left + right + 1).toStringAsFixed(1).replaceAll('.', ','), (left + right - 0.1).toStringAsFixed(1).replaceAll('.', ','),
          ], 'Addiere Zehntel wie normale Zahlen und setze das Komma.', 'decimal',
        );
      case MathTemplateKind.wordProblemThreeStep:
        final answer = (a + b) * 2 - 4;
        final s3 = _positive(seed, _threeStepStories.length);
        final story = _threeStepStories[s3];
        return _numberTask(story.prompt(a, b, answer), answer, story.explain(a, b, answer), 'story_three',
        );
      case MathTemplateKind.chartRead:
        final answer = a + b;
        return _numberTask('Diagramm: Montag $a Kinder, Dienstag $b Kinder. Wie viele zusammen?', answer, 'Lies beide Balken ab und addiere sie.', 'chart',
        );
      case MathTemplateKind.compare:
        final answer = a > b ? '>' : a < b ? '<' : '=';
        return _choice('Welches Zeichen passt? $a ? $b', answer, <String>['<', '>', '='], 'Vergleiche von links nach rechts.', 'compare',
        );
      case MathTemplateKind.massConversion:
        final kg = 1 + (a - 1) % 9;
        final extra = (b - 1) * 100;
        final answer = kg * 1000 + extra;
        final amount = extra == 0 ? '$kg kg' : '$kg kg und $extra g';
        return _numberTask('Wie viele Gramm sind $amount?', answer,
            '1 kg sind 1000 g. Rechne $kg × 1000 und zähle $extra g dazu.', 'mass');
      case MathTemplateKind.volumeConversion:
        final liter = 1 + (a - 1) % 9;
        final extra = (b - 1) * 100;
        final answer = liter * 1000 + extra;
        final amount = extra == 0 ? '$liter Liter' : '$liter Liter und $extra Milliliter';
        return _numberTask('Wie viele Milliliter sind $amount?', answer,
            '1 Liter sind 1000 Milliliter. Rechne $liter × 1000 und zähle $extra Milliliter dazu.', 'volume');
      case MathTemplateKind.timeMinutes:
        final hours = 1 + (a - 1) % 5;
        final extra = (b - 1) * 15;
        final answer = hours * 60 + extra;
        final hoursText = '$hours ${hours == 1 ? 'Stunde' : 'Stunden'}';
        final amount = extra == 0 ? hoursText : '$hoursText und $extra Minuten';
        return _numberTask('Wie viele Minuten sind $amount?', answer,
            '1 Stunde hat 60 Minuten. Rechne $hours × 60 und zähle $extra Minuten dazu.', 'clock');
      case MathTemplateKind.fractionExpand:
        final denom = 2 + (a - 2) % 5;
        final factor = 2 + (b - 2) % 4;
        final numerator = 1 + _positive(_mixSeed(seed + 31), denom - 1);
        final newNumerator = numerator * factor;
        final newDenom = denom * factor;
        final answer = '$newNumerator/$newDenom';
        return _choice(
          'Erweitere den Bruch $numerator/$denom mit $factor. Wie heißt der neue Bruch?',
          answer,
          <String>[answer, '$numerator/$newDenom', '${newNumerator + 1}/$newDenom'],
          'Multipliziere Zähler UND Nenner mit $factor: $numerator · $factor = $newNumerator und $denom · $factor = $newDenom.',
          'fraction_expand',
        );
      case MathTemplateKind.average:
        // Mittelwert aus a, b und (a+b)/2-ish. Drei Werte deren Durchschnitt
        // ganzzahlig ist: nutze 3-Zahlen die ein Vielfaches von 3 ergeben.
        final base = a;
        final v1 = base - b;
        final v2 = base + 1;
        final v3 = base + b - 1;
        final sum = v1 + v2 + v3;
        final answer = sum ~/ 3;
        return _numberTask(
          'Drei Kinder sammeln Sterne: $v1, $v2 und $v3. Wie viele Sterne im Mittelwert?',
          answer,
          'Addiere alle Werte ($v1+$v2+$v3=$sum) und teile durch die Anzahl (3): $sum:3 = $answer.',
          'chart',
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
          <String>['Rechteck', 'Ein Rechteck hat 4 Ecken und 2 verschieden lange Seiten.',
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

  MathConcreteTask _numberTask(String prompt, int answer, String explanation, String visual,
  ) {
    return _choice(prompt, '$answer', _numericDistractors(answer), explanation, visual,
    );
  }

  MathConcreteTask _choice(String prompt, String answer, List<String> rawChoices, String explanation, String visual,
  ) {
    final choices = <String>[answer];
    for (final choice in rawChoices) {
      if (choice != answer && !choices.contains(choice)) choices.add(choice);
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

List<String> _numericDistractors(int answer) {
  final offsets = <int>[1, -1, 2, -2, 5, -5, 10, -10];
  final values = <String>['$answer'];
  for (final offset in offsets) {
    final candidate = answer + offset;
    if (candidate >= 0 && !values.contains('$candidate')) values.add('$candidate');
    if (values.length == 4) break;
  }
  return values;
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

List<String> _numberWordChoices(int number) {
  final answer = _numberWords[number] ?? '$number';
  final choices = <String>[answer];
  for (final offset in <int>[1, -1, 2, -2, 3]) {
    final candidate = _numberWords[(number + offset).clamp(0, 20).toInt()];
    if (candidate != null && !choices.contains(candidate)) choices.add(candidate);
    if (choices.length == 4) break;
  }
  return choices;
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
];

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

String _p1Apfel(int a, int b, int s) => 'Lisa hat $a Aepfel und bekommt $b dazu. Wie viele Aepfel hat sie?';
String _p1Kekse(int a, int b, int s) => 'Tom hat $a Kekse gebacken. Oma bringt $b weitere. Wie viele Kekse sind es?';
String _p1Bus(int a, int b, int s) => 'Im Bus sitzen $a Kinder. An der naechsten Station steigen $b zu. Wie viele Kinder sind jetzt im Bus?';
String _p1Buntstifte(int a, int b, int s) => 'Mia hat $a rote Buntstifte und $b blaue. Wie viele Buntstifte hat sie zusammen?';
String _p1Schulhof(int a, int b, int s) => 'Am Schulhof spielen $a Kinder Fangen und $b Hupfkaestchen. Wie viele Kinder spielen?';
String _p1Sticker(int a, int b, int s) => 'Jonas sammelt Sticker. Er hat $a und bekommt $b neue geschenkt. Wie viele hat er?';
String _p1Garten(int a, int b, int s) => 'In Omas Garten bluehen $a Tulpen. $b Rosen kommen dazu. Wie viele Blumen sind das?';
String _p1Sport(int a, int b, int s) => 'Beim Schulfest gibt es $a Wuerstel und $b Brote. Wie viele Snacks sind das?';

String _e1Sum(int a, int b, int s) => 'Plusgeschichte: $a + $b = $s. Zaehle erst die erste, dann die zweite Gruppe zusammen.';

// 2-Schritt (Klasse 2-3): a + b - 3, mehrstufige Logik.
const List<_WordStory> _twoStepStories = <_WordStory>[
  _WordStory(_p2Tulpen, _e2),
  _WordStory(_p2Pausenbrot, _e2),
  _WordStory(_p2Markt, _e2),
  _WordStory(_p2Klassenfahrt, _e2),
  _WordStory(_p2Spielzeug, _e2),
  _WordStory(_p2Aquarium, _e2),
  _WordStory(_p2Schwimmbad, _e2),
  _WordStory(_p2Werkstatt, _e2),
  _WordStory(_p2Buecherei, _e2),
];

String _p2Werkstatt(int a, int b, int s) => 'Für die Bastelwerkstatt gibt es $a rote und $b blaue Papierbögen. 3 Bögen werden verbraucht. Wie viele Bögen bleiben?';
String _p2Buecherei(int a, int b, int s) => 'Die Bücherei hat $a Bilderbücher. $b kommen dazu. 3 Bücher werden ausgeliehen. Wie viele bleiben in der Bücherei?';

String _p2Tulpen(int a, int b, int s) => 'Im Garten wachsen $a Tulpen. $b kommen dazu, 3 werden gepflueckt. Wie viele bleiben?';
String _p2Pausenbrot(int a, int b, int s) => 'In der Schultasche sind $a Aepfel und $b Birnen. Lisa isst 3 Stueck. Wie viele bleiben uebrig?';
String _p2Markt(int a, int b, int s) => 'Am Markt gibt es $a Karotten und $b Paradeiser. 3 werden verkauft. Wie viele Gemueseteile sind noch da?';
String _p2Klassenfahrt(int a, int b, int s) => 'Bei der Klassenfahrt fahren $a Kinder und $b Erwachsene mit. 3 muessen krank zurueckbleiben. Wie viele Personen fahren wirklich mit?';
String _p2Spielzeug(int a, int b, int s) => 'Im Spielzimmer liegen $a Autos und $b Bauklotz-Stuecke. 3 Stuecke werden weggeraeumt. Wie viele Spielsachen liegen noch herum?';
String _p2Aquarium(int a, int b, int s) => 'Im Aquarium schwimmen $a Goldfische und $b Neonfische. 3 schwimmen hinter Pflanzen und sind versteckt. Wie viele sieht man?';
String _p2Schwimmbad(int a, int b, int s) => 'Im Schwimmbad sind $a Kinder im grossen und $b im kleinen Becken. 3 gehen in die Sauna. Wie viele schwimmen noch?';

String _e2(int a, int b, int s) => 'Zwei Schritte: zuerst zusammen $a + $b, dann minus 3 = $s.';

// 3-Schritt (Klasse 3-4): (a + b) * 2 - 4, komplexere Verkettung.
const List<_WordStory> _threeStepStories = <_WordStory>[
  _WordStory(_p3Semmeln, _e3),
  _WordStory(_p3Buecher, _e3),
  _WordStory(_p3Sammelkarten, _e3),
  _WordStory(_p3Schultheater, _e3),
  _WordStory(_p3Sportfest, _e3),
  _WordStory(_p3Schulfest, _e3),
  _WordStory(_p3Bastelstern, _e3),
  _WordStory(_p3Obstkiste, _e3),
];

String _p3Bastelstern(int a, int b, int s) => 'Die Klasse bastelt $a gelbe und $b blaue Sterne. Am nächsten Tag bastelt sie noch einmal dieselbe Anzahl Sterne. 4 Sterne werden verschenkt. Wie viele Sterne bleiben?';
String _p3Obstkiste(int a, int b, int s) => 'In einer Kiste liegen $a Äpfel und $b Birnen. Eine zweite Kiste enthält genau gleich viele Früchte. 4 Früchte werden gegessen. Wie viele bleiben insgesamt?';

String _p3Semmeln(int a, int b, int s) => 'Fuer ein Fest werden $a Semmeln und $b Weckerl gekauft. Danach wird noch einmal dieselbe Anzahl Gebaeckstuecke gekauft. 4 bleiben uebrig. Wie viele wurden gegessen?';
String _p3Buecher(int a, int b, int s) => 'Im Regal stehen $a Kinderbuecher und $b Sachbuecher. Es kommt noch einmal dieselbe Anzahl Buecher dazu. 4 werden ausgeliehen. Wie viele Buecher stehen jetzt im Regal?';
String _p3Sammelkarten(int a, int b, int s) => 'Tim hat $a Fussball-Karten und $b Tier-Karten. Er bekommt noch einmal dieselbe Anzahl Karten geschenkt. 4 verschenkt er weiter. Wie viele Karten hat er jetzt?';
String _p3Schultheater(int a, int b, int s) => 'Fuer das Schultheater werden $a Stuehle aus 2A und $b aus 2B geholt. Danach kommt noch einmal dieselbe Anzahl Stuehle dazu. 4 werden weggeraeumt. Wie viele Stuehle stehen bereit?';
String _p3Sportfest(int a, int b, int s) => 'Beim Sportfest starten $a Buben und $b Maedchen. Danach startet noch einmal dieselbe Anzahl Kinder. 4 Kinder brechen ab. Wie viele Kinder kommen ins Ziel?';
String _p3Schulfest(int a, int b, int s) => 'Beim Schulfest stehen $a Limonadenflaschen und $b Saftflaschen bereit. Es kommt noch einmal dieselbe Anzahl Flaschen dazu. 4 zerbrechen. Wie viele Flaschen bleiben heil?';

String _e3(int a, int b, int s) => 'Drei Schritte: addieren ($a + $b = ${a + b}), verdoppeln (${(a + b) * 2}), 4 abziehen = $s.';
