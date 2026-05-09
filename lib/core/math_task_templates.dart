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
    MathTaskTemplate(id: 'g3_area', grade: 3, unit: 'Flächeninhalt', kind: MathTemplateKind.area, validRangeA: <int>[2, 12], validRangeB: <int>[2, 12], promptPattern: 'flaeche-rechteck'),
    MathTaskTemplate(id: 'g3_add_100', grade: 3, unit: 'Plus bis 100', kind: MathTemplateKind.addition, validRangeA: <int>[10, 90], validRangeB: <int>[5, 80], promptPattern: 'plus-bis-100'),
    MathTaskTemplate(id: 'g3_sub_100', grade: 3, unit: 'Minus bis 100', kind: MathTemplateKind.subtraction, validRangeA: <int>[20, 100], validRangeB: <int>[5, 70], promptPattern: 'minus-bis-100'),

    MathTaskTemplate(id: 'g4_written_mul', grade: 4, unit: 'Schriftliche Multiplikation', kind: MathTemplateKind.writtenMultiplication, validRangeA: <int>[12, 999], validRangeB: <int>[2, 12], promptPattern: 'schriftliche-multiplikation'),
    MathTaskTemplate(id: 'g4_written_div', grade: 4, unit: 'Schriftliche Division', kind: MathTemplateKind.division, validRangeA: <int>[20, 999], validRangeB: <int>[2, 12], promptPattern: 'schriftliche-division'),
    MathTaskTemplate(id: 'g4_fraction_add', grade: 4, unit: 'Bruchrechnen einfach', kind: MathTemplateKind.simpleFractionAdd, validRangeA: <int>[1, 8], validRangeB: <int>[1, 8], promptPattern: 'gleichnamige-brueche-addieren'),
    MathTaskTemplate(id: 'g4_decimal', grade: 4, unit: 'Dezimalzahlen', kind: MathTemplateKind.decimals, validRangeA: <int>[1, 99], validRangeB: <int>[1, 99], promptPattern: 'dezimalzahlen-addieren'),
    MathTaskTemplate(id: 'g4_three_step', grade: 4, unit: 'Sachaufgaben drei Schritte', kind: MathTemplateKind.wordProblemThreeStep, validRangeA: <int>[5, 60], validRangeB: <int>[2, 20], promptPattern: 'sachaufgabe-drei-schritte'),
    MathTaskTemplate(id: 'g4_chart', grade: 4, unit: 'Diagramme lesen', kind: MathTemplateKind.chartRead, validRangeA: <int>[4, 40], validRangeB: <int>[4, 40], promptPattern: 'diagramm-lesen'),
    MathTaskTemplate(id: 'g4_compare', grade: 4, unit: 'Vergleichen', kind: MathTemplateKind.compare, validRangeA: <int>[1, 999], validRangeB: <int>[1, 999], promptPattern: 'zahlen-vergleichen'),
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

  static MathConcreteTask generate({required int grade, required String unit, required int seed}) {
    final pool = templatesForGrade(grade, unit: unit);
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
        final answer = a + b;
        return _numberTask('Lisa hat $a Äpfel und bekommt $b dazu. Wie viele Äpfel hat sie?', answer, 'Das ist eine Plusgeschichte: $a + $b = $answer.', 'story');
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
        return _numberTask('Im Garten wachsen $a Tulpen. $b kommen dazu, 3 werden gepflückt. Wie viele bleiben?', answer, 'Zuerst plus, dann minus: $a + $b - 3 = $answer.', 'story_two');
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
        final denominator = (b + 2).clamp(3, 12).toInt();
        final left = a.clamp(1, denominator - 1).toInt();
        final right = (denominator - left).clamp(1, denominator - 1).toInt();
        final answer = '${left + right}/$denominator';
        return _choice('$left/$denominator + $right/$denominator = ?', answer, <String>[answer, '${left + right}/${denominator + 1}', '$left/$denominator'], 'Bei gleichem Nenner addierst du die Zähler.', 'fraction_add');
      case MathTemplateKind.decimals:
        final left = a / 10;
        final right = b / 10;
        final answer = (left + right).toStringAsFixed(1).replaceAll('.', ',');
        return _choice('${left.toStringAsFixed(1).replaceAll('.', ',')} + ${right.toStringAsFixed(1).replaceAll('.', ',')} = ?', answer, <String>[answer, (left + right + 1).toStringAsFixed(1).replaceAll('.', ','), (left + right - 0.1).toStringAsFixed(1).replaceAll('.', ',')], 'Addiere Zehntel wie normale Zahlen und setze das Komma.', 'decimal');
      case MathTemplateKind.wordProblemThreeStep:
        final answer = (a + b) * 2 - 4;
        return _numberTask('Für ein Fest gibt es $a Semmeln und $b Weckerl. Es werden doppelt so viele gekauft, 4 bleiben übrig. Wie viele wurden gegessen?', answer, 'Rechne in drei Schritten: addieren, verdoppeln, 4 abziehen.', 'story_three');
      case MathTemplateKind.chartRead:
        final answer = a + b;
        return _numberTask('Diagramm: Montag $a Kinder, Dienstag $b Kinder. Wie viele zusammen?', answer, 'Lies beide Balken ab und addiere sie.', 'chart');
      case MathTemplateKind.compare:
        final answer = a > b ? '>' : a < b ? '<' : '=';
        return _choice('Welches Zeichen passt? $a ? $b', answer, <String>['<', '>', '='], 'Vergleiche von links nach rechts.', 'compare');
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
    while (choices.length < 3) {
      choices.add('${answer}_${choices.length}');
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
