/// Deterministische Mathe-Templates für Volksschule 1-4.
///
/// Der Generator wählt nur noch ein Template und konkretisiert es über Seed.
/// Dadurch entstehen pro Einheit viele Varianten mit stabilem Prompt-Pattern.
class MathTaskTemplates {
  const MathTaskTemplates._();

  static const List<MathTaskTemplate> templates = <MathTaskTemplate>[
    MathTaskTemplate(id: 'g1_add_10', grade: 1, unit: 'Plus bis 10', kind: MathTemplateKind.addition, validRangeA: <int>[1, 6], validRangeB: <int>[1, 6], promptPattern: 'plus-bis-10'),
    MathTaskTemplate(id: 'g1_sub_10', grade: 1, unit: 'Minus bis 10', kind: MathTemplateKind.subtraction, validRangeA: <int>[3, 10], validRangeB: <int>[1, 7], promptPattern: 'minus-bis-10'),
    MathTaskTemplate(id: 'g1_number_line', grade: 1, unit: 'Zahlenstrahl', kind: MathTemplateKind.numberLineMissing, validRangeA: <int>[1, 20], validRangeB: <int>[0, 2], promptPattern: 'zahlenstrahl-fehlt'),
    MathTaskTemplate(id: 'g1_quantity_compare', grade: 1, unit: 'Mengenvergleich', kind: MathTemplateKind.quantityCompare, validRangeA: <int>[1, 8], validRangeB: <int>[1, 8], promptPattern: 'menge-vergleichen'),
    MathTaskTemplate(id: 'g1_number_word', grade: 1, unit: 'Zahl in Worten', kind: MathTemplateKind.numberWord, validRangeA: <int>[0, 20], validRangeB: <int>[0, 1], promptPattern: 'zahlwort-erkennen'),
    MathTaskTemplate(id: 'g1_shapes', grade: 1, unit: 'Geometrie Formen', kind: MathTemplateKind.shapeRecognition, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'formen-erkennen'),
    MathTaskTemplate(id: 'g1_money_more', grade: 1, unit: 'Geld', kind: MathTemplateKind.moneyCompare, validRangeA: <int>[1, 8], validRangeB: <int>[1, 8], promptPattern: 'geld-mehr'),
    MathTaskTemplate(id: 'g1_day_hours', grade: 1, unit: 'Zeit', kind: MathTemplateKind.dayHours, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'tag-stunden'),
    MathTaskTemplate(id: 'g1_symmetry', grade: 1, unit: 'Symmetrie', kind: MathTemplateKind.symmetry, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'symmetrie-form'),

    MathTaskTemplate(id: 'g2_add_20', grade: 2, unit: 'Plus bis 20', kind: MathTemplateKind.addition, validRangeA: <int>[2, 18], validRangeB: <int>[1, 12], promptPattern: 'plus-bis-20'),
    MathTaskTemplate(id: 'g2_sub_20', grade: 2, unit: 'Minus bis 20', kind: MathTemplateKind.subtraction, validRangeA: <int>[8, 20], validRangeB: <int>[1, 14], promptPattern: 'minus-bis-20'),
    MathTaskTemplate(id: 'g2_times_prep', grade: 2, unit: 'Einmaleins Vorbereitung', kind: MathTemplateKind.multiplicationPrep, validRangeA: <int>[2, 5], validRangeB: <int>[2, 10], promptPattern: 'wie-oft-in-zahl'),
    MathTaskTemplate(id: 'g2_word_problem', grade: 2, unit: 'Textaufgaben', kind: MathTemplateKind.wordProblemOneStep, validRangeA: <int>[4, 18], validRangeB: <int>[2, 12], promptPattern: 'sachaufgabe-ein-schritt'),
    MathTaskTemplate(id: 'g2_money_change', grade: 2, unit: 'Geld wechseln', kind: MathTemplateKind.moneyChange, validRangeA: <int>[2, 20], validRangeB: <int>[1, 5], promptPattern: 'geld-wechseln'),
    MathTaskTemplate(id: 'g2_clock', grade: 2, unit: 'Uhrzeit', kind: MathTemplateKind.clockTime, validRangeA: <int>[1, 12], validRangeB: <int>[0, 3], promptPattern: 'uhrzeit-viertel-halbe'),
    MathTaskTemplate(id: 'g2_length', grade: 2, unit: 'Längen', kind: MathTemplateKind.lengthConversion, validRangeA: <int>[1, 10], validRangeB: <int>[0, 5], promptPattern: 'meter-zentimeter'),
    MathTaskTemplate(id: 'g2_even_odd', grade: 2, unit: 'Gerade und ungerade', kind: MathTemplateKind.evenOdd, validRangeA: <int>[1, 100], validRangeB: <int>[0, 0], promptPattern: 'gerade-ungerade'),
    MathTaskTemplate(id: 'g2_half_double', grade: 2, unit: 'Verdoppeln und Halbieren', kind: MathTemplateKind.halfDouble, validRangeA: <int>[2, 50], validRangeB: <int>[0, 1], promptPattern: 'halb-doppelt-groesser'),
    MathTaskTemplate(id: 'g2_tens_ones', grade: 2, unit: 'Zehner und Einer', kind: MathTemplateKind.tensOnes, validRangeA: <int>[10, 99], validRangeB: <int>[0, 1], promptPattern: 'zehner-einer'),

    MathTaskTemplate(id: 'g3_tables', grade: 3, unit: 'Einmaleins', kind: MathTemplateKind.multiplication, validRangeA: <int>[2, 10], validRangeB: <int>[2, 10], promptPattern: 'einmaleins'),
    MathTaskTemplate(id: 'g3_written_add', grade: 3, unit: 'Schriftliche Addition', kind: MathTemplateKind.writtenAddition, validRangeA: <int>[120, 899], validRangeB: <int>[80, 699], promptPattern: 'schriftliche-addition'),
    MathTaskTemplate(id: 'g3_written_sub', grade: 3, unit: 'Schriftliche Subtraktion', kind: MathTemplateKind.writtenSubtraction, validRangeA: <int>[220, 999], validRangeB: <int>[50, 499], promptPattern: 'schriftliche-subtraktion'),
    MathTaskTemplate(id: 'g3_fraction_half', grade: 3, unit: 'Brüche Vorbereitung', kind: MathTemplateKind.fractionHalf, validRangeA: <int>[2, 40], validRangeB: <int>[0, 0], promptPattern: 'haelfte-als-bruchvorbereitung'),
    MathTaskTemplate(id: 'g3_two_step', grade: 3, unit: 'Sachaufgaben zwei Schritte', kind: MathTemplateKind.wordProblemTwoStep, validRangeA: <int>[5, 30], validRangeB: <int>[2, 12], promptPattern: 'sachaufgabe-zwei-schritte'),
    MathTaskTemplate(id: 'g3_perimeter', grade: 3, unit: 'Umfang', kind: MathTemplateKind.perimeter, validRangeA: <int>[2, 18], validRangeB: <int>[2, 18], promptPattern: 'umfang-rechteck'),
    // AT-Lehrplan-Korrektur 2026-06-03: Flaecheninhalt ist Klasse-4-Stoff
    // (BMBWF Mathe-Lehrplan VS). Vorher faelschlich als g3_area gefuehrt
    // -> Klasse 3 sah eine Aufgabe die laut Lehrplan erst Klasse 4 dran ist.
    MathTaskTemplate(id: 'g3_add_100', grade: 3, unit: 'Plus bis 100', kind: MathTemplateKind.addition, validRangeA: <int>[10, 90], validRangeB: <int>[5, 80], promptPattern: 'plus-bis-100'),
    MathTaskTemplate(id: 'g3_sub_100', grade: 3, unit: 'Minus bis 100', kind: MathTemplateKind.subtraction, validRangeA: <int>[20, 100], validRangeB: <int>[5, 70], promptPattern: 'minus-bis-100'),
    // Neue Klasse-3-Lehrplan-Templates (AT Lehrplan 2023):
    MathTaskTemplate(id: 'g3_add_1000', grade: 3, unit: 'Plus bis 1000', kind: MathTemplateKind.addition, validRangeA: <int>[120, 600], validRangeB: <int>[80, 400], promptPattern: 'plus-bis-1000'),
    MathTaskTemplate(id: 'g3_sub_1000', grade: 3, unit: 'Minus bis 1000', kind: MathTemplateKind.subtraction, validRangeA: <int>[300, 999], validRangeB: <int>[100, 500], promptPattern: 'minus-bis-1000'),
    MathTaskTemplate(id: 'g3_division_basic', grade: 3, unit: 'Division einstellig', kind: MathTemplateKind.division, validRangeA: <int>[12, 90], validRangeB: <int>[2, 9], promptPattern: 'geteilt-einstellig'),
    MathTaskTemplate(id: 'g3_money_change_100', grade: 3, unit: 'Geld bis 100 Euro', kind: MathTemplateKind.moneyChange, validRangeA: <int>[5, 50], validRangeB: <int>[1, 5], promptPattern: 'geld-bis-100'),
    MathTaskTemplate(id: 'g3_mass', grade: 3, unit: 'Massen Kilogramm und Gramm', kind: MathTemplateKind.massConversion, validRangeA: <int>[1, 50], validRangeB: <int>[1, 4], promptPattern: 'kg-zu-g'),

    MathTaskTemplate(id: 'g4_written_mul', grade: 4, unit: 'Schriftliche Multiplikation', kind: MathTemplateKind.writtenMultiplication, validRangeA: <int>[12, 999], validRangeB: <int>[2, 12], promptPattern: 'schriftliche-multiplikation'),
    MathTaskTemplate(id: 'g4_written_div', grade: 4, unit: 'Schriftliche Division', kind: MathTemplateKind.division, validRangeA: <int>[20, 999], validRangeB: <int>[2, 12], promptPattern: 'schriftliche-division'),
    MathTaskTemplate(id: 'g4_fraction_add', grade: 4, unit: 'Bruchrechnen einfach', kind: MathTemplateKind.simpleFractionAdd, validRangeA: <int>[1, 8], validRangeB: <int>[1, 8], promptPattern: 'gleichnamige-brueche-addieren'),
    MathTaskTemplate(id: 'g4_decimal', grade: 4, unit: 'Dezimalzahlen', kind: MathTemplateKind.decimals, validRangeA: <int>[1, 99], validRangeB: <int>[1, 99], promptPattern: 'dezimalzahlen-addieren'),
    MathTaskTemplate(id: 'g4_three_step', grade: 4, unit: 'Sachaufgaben drei Schritte', kind: MathTemplateKind.wordProblemThreeStep, validRangeA: <int>[5, 60], validRangeB: <int>[2, 20], promptPattern: 'sachaufgabe-drei-schritte'),
    MathTaskTemplate(id: 'g4_chart', grade: 4, unit: 'Diagramme lesen', kind: MathTemplateKind.chartRead, validRangeA: <int>[4, 40], validRangeB: <int>[4, 40], promptPattern: 'diagramm-lesen'),
    MathTaskTemplate(id: 'g4_compare', grade: 4, unit: 'Vergleichen', kind: MathTemplateKind.compare, validRangeA: <int>[1, 999], validRangeB: <int>[1, 999], promptPattern: 'zahlen-vergleichen'),
    // Neue Klasse-4-Lehrplan-Templates (AT Lehrplan 2023):
    MathTaskTemplate(id: 'g4_add_10000', grade: 4, unit: 'Plus bis 10000', kind: MathTemplateKind.addition, validRangeA: <int>[1200, 6000], validRangeB: <int>[800, 4000], promptPattern: 'plus-bis-10000'),
    MathTaskTemplate(id: 'g4_sub_10000', grade: 4, unit: 'Minus bis 10000', kind: MathTemplateKind.subtraction, validRangeA: <int>[3000, 9999], validRangeB: <int>[800, 4000], promptPattern: 'minus-bis-10000'),
    MathTaskTemplate(id: 'g4_compare_1mio', grade: 4, unit: 'Zahlenraum bis 1 Million', kind: MathTemplateKind.compare, validRangeA: <int>[10000, 999999], validRangeB: <int>[10000, 999999], promptPattern: 'vergleichen-grosse-zahlen'),
    MathTaskTemplate(id: 'g4_time_minutes', grade: 4, unit: 'Zeit Minuten und Stunden', kind: MathTemplateKind.timeMinutes, validRangeA: <int>[1, 50], validRangeB: <int>[1, 4], promptPattern: 'stunden-zu-minuten'),
    MathTaskTemplate(id: 'g4_volume', grade: 4, unit: 'Hohlmaße Liter und Milliliter', kind: MathTemplateKind.volumeConversion, validRangeA: <int>[1, 50], validRangeB: <int>[1, 4], promptPattern: 'l-zu-ml'),
    MathTaskTemplate(id: 'g4_fraction_expand', grade: 4, unit: 'Brüche erweitern', kind: MathTemplateKind.fractionExpand, validRangeA: <int>[2, 30], validRangeB: <int>[2, 6], promptPattern: 'bruch-erweitern'),
    MathTaskTemplate(id: 'g4_average', grade: 4, unit: 'Mittelwert', kind: MathTemplateKind.average, validRangeA: <int>[6, 60], validRangeB: <int>[2, 6], promptPattern: 'durchschnitt'),
    // AT-Lehrplan-konform: Flaecheninhalt erst Klasse 4 (vorher g3_area).
    MathTaskTemplate(id: 'g4_area', grade: 4, unit: 'Flächeninhalt', kind: MathTemplateKind.area, validRangeA: <int>[2, 12], validRangeB: <int>[2, 12], promptPattern: 'flaeche-rechteck'),
    MathTaskTemplate(id: 'g4_symmetry_lines', grade: 4, unit: 'Symmetrieachsen', kind: MathTemplateKind.symmetry, validRangeA: <int>[0, 7], validRangeB: <int>[0, 7], promptPattern: 'symmetrieachsen'),
  ];

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
  static List<MathTaskTemplate> templatesForGradeStrict(int grade, {String? unit}) {
    final capped = grade.clamp(1, 4);
    final pool = templates.where((template) => template.grade == capped).where((template) {
      if (unit == null || unit == 'Alle') return true;
      if (template.unit == unit) return true;
      return _legacyUnitAliases[unit]?.contains(template.unit) ?? false;
    }).toList(growable: false);
    if (pool.isNotEmpty) return pool;
    return templatesForGrade(grade, unit: unit);
  }

  static MathConcreteTask generate({required int grade, required String unit, required int seed}) {
    // 75% aktuelle Klassenstufe (strict), 25% Wiederholung aus Vorjahren.
    final useStrict = seed.abs() % 4 != 0;
    final pool = useStrict
        ? templatesForGradeStrict(grade, unit: unit)
        : templatesForGrade(grade, unit: unit);
    final template = pool[_positive(seed, pool.length)];
    return template.concretize(seed + template.id.hashCode);
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
    'Textaufgaben': <String>['Textaufgaben', 'Sachaufgaben zwei Schritte', 'Sachaufgaben drei Schritte'],
    'Uhrzeit': <String>['Uhrzeit'],
    'Geld': <String>['Geld', 'Geld wechseln'],
    'Geometrie Formen': <String>['Geometrie Formen', 'Umfang', 'Flächeninhalt'],
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
    final a = _valueInRange(validRangeA, seed);
    final b = _valueInRange(validRangeB, seed ~/ 7 + 13);
    switch (kind) {
      case MathTemplateKind.addition:
        final answer = a + b;
        return _numberTask('$a + $b = ?', answer, 'Lege zuerst $a und dann $b dazu. Zusammen sind es $answer.', 'dots');
      case MathTemplateKind.subtraction:
        final minuend = a >= b ? a : a + b;
        final subtrahend = b.clamp(1, minuend).toInt();
        final answer = minuend - subtrahend;
        return _numberTask('$minuend - $subtrahend = ?', answer, 'Starte bei $minuend und gehe $subtrahend Schritte zurück.', 'line');
      case MathTemplateKind.numberLineMissing:
        final start = a;
        final answer = start + 2;
        return _numberTask('Welche Zahl fehlt? $start, ${start + 1}, _, ${start + 3}', answer, 'Am Zahlenstrahl geht es immer um 1 weiter.', 'number_line');
      case MathTemplateKind.quantityCompare:
        final left = a == b ? a + 1 : a;
        final answer = left > b ? 'links' : 'rechts';
        final leftDots = _repeatEmoji('🍎', left);
        final rightDots = _repeatEmoji('🍎', b);
        return _choice('$leftDots oder $rightDots – wo ist mehr?', answer, <String>['links', 'rechts', 'gleich'], 'Vergleiche die Menge, nicht die Länge der Zeile.', 'quantity');
      case MathTemplateKind.numberWord:
        final answer = _numberWords[a] ?? '$a';
        return _choice('Wie schreibt man die Zahl $a als Wort?', answer, _numberWordChoices(a), 'Zahlwörter liest man wie normale Wörter.', 'word_number');
      case MathTemplateKind.shapeRecognition:
        final shapes = <String, String>{'Welche Form hat 3 Ecken?': 'Dreieck', 'Welche Form ist ganz rund?': 'Kreis', 'Welche Form hat 4 gleich lange Seiten?': 'Quadrat', 'Welche Form hat keine Ecke?': 'Kreis', 'Welche Form sieht aus wie ein Ei?': 'Oval', 'Welche Form hat 4 Ecken und zwei längere Seiten?': 'Rechteck'};
        final entry = shapes.entries.elementAt(_positive(seed, shapes.length));
        return _choice(entry.key, entry.value, <String>['Dreieck', 'Kreis', 'Quadrat', 'Rechteck', 'Oval'], 'Schau auf Ecken, Seiten und Rundungen.', 'shape');
      case MathTemplateKind.moneyCompare:
        final left = a;
        final right = a == b ? b + 1 : b;
        final answer = left > right ? '$left €' : '$right €';
        return _choice('Was kostet mehr: $left € oder $right €?', answer, <String>['$left €', '$right €', 'gleich viel'], 'Mehr Euro bedeutet höherer Preis.', 'money');
      case MathTemplateKind.dayHours:
        return _choice('Wie viele Stunden hat ein Tag?', '24', <String>['12', '24', '30'], 'Ein Tag hat 24 Stunden: Tag und Nacht zusammen.', 'clock');
      case MathTemplateKind.symmetry:
        final data = <String, bool>{'Kreis': true, 'Quadrat': true, 'Herz': true, 'krumme Wolke': false, 'Handabdruck': false, 'Blitz': false};
        final entry = data.entries.elementAt(_positive(seed, data.length));
        return _choice('Ist die Form „${entry.key}“ symmetrisch?', entry.value ? 'ja' : 'nein', <String>['ja', 'nein', 'nur manchmal'], 'Symmetrisch heißt: Zwei Seiten passen wie Spiegelbilder zusammen.', 'symmetry');
      case MathTemplateKind.multiplicationPrep:
        final answer = b;
        return _numberTask('Wie oft $a ist ${a * b}?', answer, '$a wird $answer-mal genommen: ${List<String>.filled(answer, '$a').join(' + ')} = ${a * b}.', 'groups');
      case MathTemplateKind.wordProblemOneStep:
        // 2026-06-03: vorher EINE Geschichte (Lisa+Aepfel) - Kind sah staendig
        // dieselbe Aufgabe nur mit anderen Zahlen. Jetzt 8 Szenarien aus dem
        // oesterreichischen Alltag (AT-Lehrplan VS Sachrechnen).
        final answer = a + b;
        final s1 = _positive(seed, _oneStepStories.length);
        final story = _oneStepStories[s1];
        return _numberTask(story.prompt(a, b, answer), answer, story.explain(a, b, answer), 'story');
      case MathTemplateKind.moneyChange:
        final euro = a.clamp(2, 20).toInt();
        return _choice('Wie kann man $euro € in 1-€-Münzen wechseln?', '$euro Münzen', <String>['${euro - 1} Münzen', '$euro Münzen', '${euro + 1} Münzen'], 'Jede 1-€-Münze zählt einen Euro.', 'money_change');
      case MathTemplateKind.clockTime:
        final minutes = <int>[0, 15, 30, 45][b.clamp(0, 3).toInt()];
        final answer = minutes == 0 ? '$a Uhr' : '$a:${minutes.toString().padLeft(2, '0')} Uhr';
        return _choice('Welche Uhrzeit ist gemeint: Stunde $a und Minute $minutes?', answer, <String>[answer, '${(a % 12) + 1}:${minutes.toString().padLeft(2, '0')} Uhr', '$a:00 Uhr'], 'Der kleine Zeiger zeigt die Stunde, der große die Minuten.', 'clock');
      case MathTemplateKind.lengthConversion:
        final answer = a * 100;
        return _numberTask('Wie viele Zentimeter sind $a Meter?', answer, '1 Meter sind 100 Zentimeter. Also $a × 100 = $answer.', 'ruler');
      case MathTemplateKind.evenOdd:
        final answer = a.isEven ? 'gerade' : 'ungerade';
        return _choice('Ist $a gerade oder ungerade?', answer, <String>['gerade', 'ungerade', 'beides'], 'Gerade Zahlen kann man in zwei gleiche Gruppen teilen.', 'parity');
      case MathTemplateKind.halfDouble:
        final even = a.isEven ? a : a + 1;
        if (b.isEven) {
          final answer = even ~/ 2;
          return _numberTask('Was ist die Hälfte von $even?', answer, 'Teile $even in zwei gleiche Gruppen.', 'half');
        }
        final answer = even * 2;
        return _numberTask('Was ist das Doppelte von $even?', answer, 'Doppelt heißt: $even + $even.', 'double');
      case MathTemplateKind.tensOnes:
        final tens = a ~/ 10;
        final ones = a % 10;
        final askTens = b.isEven;
        return _numberTask(askTens ? 'Wie viele Zehner hat $a?' : 'Wie viele Einer hat $a?', askTens ? tens : ones, '$a besteht aus $tens Zehnern und $ones Einern.', 'ten_ones');
      case MathTemplateKind.multiplication:
        final answer = a * b;
        return _numberTask('$a × $b = ?', answer, 'Nutze die Einmaleins-Reihe von $a.', 'times_table');
      case MathTemplateKind.writtenAddition:
        final answer = a + b;
        return _numberTask('Schriftlich: $a + $b = ?', answer, 'Schreibe Einer unter Einer, Zehner unter Zehner, Hunderter unter Hunderter.', 'written_add');
      case MathTemplateKind.writtenSubtraction:
        final minuend = a > b ? a : a + b;
        final answer = minuend - b;
        return _numberTask('Schriftlich: $minuend - $b = ?', answer, 'Rechne von rechts nach links und tausche, wenn nötig.', 'written_sub');
      case MathTemplateKind.fractionHalf:
        final even = a.isEven ? a : a + 1;
        final answer = even ~/ 2;
        return _numberTask('Was ist die Hälfte von $even?', answer, 'Die Hälfte ist einer von zwei gleich großen Teilen.', 'fraction_half');
      case MathTemplateKind.wordProblemTwoStep:
        final answer = a + b - 3;
        final s2 = _positive(seed, _twoStepStories.length);
        final story = _twoStepStories[s2];
        return _numberTask(story.prompt(a, b, answer), answer, story.explain(a, b, answer), 'story_two');
      case MathTemplateKind.perimeter:
        final answer = 2 * (a + b);
        return _numberTask('Ein Rechteck ist $a cm lang und $b cm breit. Wie groß ist der Umfang?', answer, 'Umfang: $a + $b + $a + $b = $answer cm.', 'perimeter');
      case MathTemplateKind.area:
        final answer = a * b;
        return _numberTask('Ein Rechteck ist $a cm lang und $b cm breit. Wie groß ist der Flächeninhalt?', answer, 'Fläche: Länge mal Breite, also $a × $b = $answer cm².', 'area');
      case MathTemplateKind.writtenMultiplication:
        final answer = a * b;
        return _numberTask('Schriftlich: $a × $b = ?', answer, 'Multipliziere jede Stelle von $a mit $b.', 'written_mul');
      case MathTemplateKind.division:
        final divisor = b.clamp(2, 12).toInt();
        final quotient = (a ~/ divisor).clamp(2, 99).toInt();
        final dividend = quotient * divisor;
        return _numberTask('$dividend : $divisor = ?', quotient, 'Teile $dividend in $divisor gleich große Gruppen.', 'division');
      case MathTemplateKind.simpleFractionAdd:
        // FIX: Vorher war right = denominator - left, sodass left+right
        // IMMER == denominator war (z.B. 3/5 + 2/5 = 5/5 = 1). Das war
        // didaktisch falsch und verwirrend - die ganze Aufgabe hatte
        // keine echten Brueche als Ergebnis. Jetzt: left max denominator-2
        // und right max denominator-left-1, damit ein echter Bruch < 1
        // entsteht (z.B. 1/5 + 2/5 = 3/5).
        final denominator = (b + 2).clamp(3, 12).toInt();
        final left = a.clamp(1, denominator - 2).toInt();
        final right = b.clamp(1, denominator - left - 1).toInt();
        final answer = '${left + right}/$denominator';
        return _choice('$left/$denominator + $right/$denominator = ?', answer, <String>[answer, '${left + right}/${denominator + 1}', '$left/$denominator'], 'Bei gleichem Nenner addierst du die Zähler.', 'fraction_add');
      case MathTemplateKind.decimals:
        final left = a / 10;
        final right = b / 10;
        final answer = (left + right).toStringAsFixed(1).replaceAll('.', ',');
        return _choice('${left.toStringAsFixed(1).replaceAll('.', ',')} + ${right.toStringAsFixed(1).replaceAll('.', ',')} = ?', answer, <String>[answer, (left + right + 1).toStringAsFixed(1).replaceAll('.', ','), (left + right - 0.1).toStringAsFixed(1).replaceAll('.', ',')], 'Addiere Zehntel wie normale Zahlen und setze das Komma.', 'decimal');
      case MathTemplateKind.wordProblemThreeStep:
        final answer = (a + b) * 2 - 4;
        final s3 = _positive(seed, _threeStepStories.length);
        final story = _threeStepStories[s3];
        return _numberTask(story.prompt(a, b, answer), answer, story.explain(a, b, answer), 'story_three');
      case MathTemplateKind.chartRead:
        final answer = a + b;
        return _numberTask('Diagramm: Montag $a Kinder, Dienstag $b Kinder. Wie viele zusammen?', answer, 'Lies beide Balken ab und addiere sie.', 'chart');
      case MathTemplateKind.compare:
        final answer = a > b ? '>' : a < b ? '<' : '=';
        return _choice('Welches Zeichen passt? $a ? $b', answer, <String>['<', '>', '='], 'Vergleiche von links nach rechts.', 'compare');
      case MathTemplateKind.massConversion:
        // a Kilogramm in Gramm. 1 kg = 1000 g.
        final kg = a.clamp(1, 9).toInt();
        final answer = kg * 1000;
        return _numberTask('Wie viele Gramm sind $kg kg?', answer, '1 kg sind 1000 g. Also $kg × 1000 = $answer g.', 'mass');
      case MathTemplateKind.volumeConversion:
        // a Liter in Milliliter. 1 l = 1000 ml.
        final liter = a.clamp(1, 9).toInt();
        final answer = liter * 1000;
        return _numberTask('Wie viele Milliliter sind $liter Liter?', answer, '1 l sind 1000 ml. Also $liter × 1000 = $answer ml.', 'volume');
      case MathTemplateKind.timeMinutes:
        // a Stunden in Minuten. 1 h = 60 min.
        final hours = a.clamp(1, 5).toInt();
        final answer = hours * 60;
        return _numberTask('$hours Stunden sind wie viele Minuten?', answer, '1 Stunde hat 60 Minuten. Also $hours × 60 = $answer min.', 'clock');
      case MathTemplateKind.fractionExpand:
        // Erweitere 1/a mit b: ergibt b/(a*b).
        final denom = a.clamp(2, 6).toInt();
        final factor = b.clamp(2, 5).toInt();
        final newNumerator = factor;
        final newDenom = denom * factor;
        final answer = '$newNumerator/$newDenom';
        return _choice(
          'Erweitere den Bruch 1/$denom mit $factor. Wie heißt der neue Bruch?',
          answer,
          <String>[
            answer,
            '$newNumerator/$denom',
            '1/${denom + factor}',
            '${newNumerator + 1}/$newDenom',
          ],
          'Beim Erweitern multiplizierst du Zähler UND Nenner mit derselben Zahl: 1·$factor / $denom·$factor = $answer.',
          'fraction_expand',
        );
      case MathTemplateKind.average:
        // Mittelwert aus a, b und (a+b)/2-ish. Drei Werte deren Durchschnitt
        // ganzzahlig ist: nutze 3-Zahlen die ein Vielfaches von 3 ergeben.
        final base = ((a + b) ~/ 2).clamp(4, 50).toInt();
        final v1 = (base - 2).clamp(1, 999).toInt();
        final v2 = base;
        final v3 = (base + 2).clamp(1, 999).toInt();
        final sum = v1 + v2 + v3;
        final answer = sum ~/ 3;
        return _numberTask(
          'Drei Kinder sammeln Sterne: $v1, $v2 und $v3. Wie viele Sterne im Mittelwert?',
          answer,
          'Addiere alle Werte ($v1+$v2+$v3=$sum) und teile durch die Anzahl (3): $sum:3 = $answer.',
          'chart',
        );
    }
  }

  MathConcreteTask _numberTask(String prompt, int answer, String explanation, String visual) {
    return _choice(prompt, '$answer', _numericDistractors(answer), explanation, visual);
  }

  MathConcreteTask _choice(String prompt, String answer, List<String> rawChoices, String explanation, String visual) {
    final choices = <String>[answer];
    for (final choice in rawChoices) {
      if (choice != answer && !choices.contains(choice)) choices.add(choice);
      if (choices.length == 4) break;
    }
    // Wenn weniger als 3 Choices: paedagogisch sinnvolle Padding-Werte hinzufuegen.
    // Vorher: 'answer_2', 'answer_3' (sah technisch und kaputt aus fuer Kinder).
    // Nachher: bei Zahl-Antworten naheliegende Nachbarzahlen, sonst sinnvolle Alternativen.
    while (choices.length < 3) {
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
    const wordPool = <String>['ja', 'nein', 'gleich', 'mehr', 'weniger', 'links', 'rechts'];
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
    _p1Apfel, _e1Sum,
  ),
  _WordStory(
    _p1Kekse, _e1Sum,
  ),
  _WordStory(
    _p1Bus, _e1Sum,
  ),
  _WordStory(
    _p1Buntstifte, _e1Sum,
  ),
  _WordStory(
    _p1Schulhof, _e1Sum,
  ),
  _WordStory(
    _p1Sticker, _e1Sum,
  ),
  _WordStory(
    _p1Garten, _e1Sum,
  ),
  _WordStory(
    _p1Sport, _e1Sum,
  ),
];

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
];

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
];

String _p3Semmeln(int a, int b, int s) => 'Fuer ein Fest gibt es $a Semmeln und $b Weckerl. Es werden doppelt so viele gekauft, 4 bleiben uebrig. Wie viele wurden gegessen?';
String _p3Buecher(int a, int b, int s) => 'In der Bibliothek stehen $a Kinderbuecher und $b Sachbuecher. Es kommen doppelt so viele neue dazu, 4 werden ausgeliehen. Wie viele Buecher stehen jetzt im Regal?';
String _p3Sammelkarten(int a, int b, int s) => 'Tim hat $a Fussball-Karten und $b Tier-Karten. Beim Geburtstag bekommt er doppelt so viele dazu, 4 verschenkt er an seinen Freund. Wie viele behaelt er?';
String _p3Schultheater(int a, int b, int s) => 'Fuer das Schultheater werden $a Stuehle aus 2A und $b aus 2B geholt. Doppelt so viele Eltern kommen wie Stuehle, 4 Eltern muessen stehen. Wie viele Eltern sitzen?';
String _p3Sportfest(int a, int b, int s) => 'Beim Sportfest laufen $a Buben und $b Maedchen mit. Beim Hindernislauf sind doppelt so viele Teilnehmer, 4 brechen ab. Wie viele kommen ins Ziel?';
String _p3Schulfest(int a, int b, int s) => 'Beim Schulfest stehen $a Limonadenflaschen und $b Saftflaschen bereit. Es werden doppelt so viele verkauft wie bereitgestellt, 4 zerbrechen. Wie viele Flaschen wurden tatsaechlich getrunken?';

String _e3(int a, int b, int s) => 'Drei Schritte: addieren ($a + $b = ${a + b}), verdoppeln (${(a + b) * 2}), 4 abziehen = $s.';
