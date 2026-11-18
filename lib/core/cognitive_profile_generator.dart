import '../domain/cognitive/cognitive_profile.dart';

class CognitiveProfileGenerator {
  const CognitiveProfileGenerator._();

  // v2: Fragen nach der Fachprüfung vom 17.11.2026 sprachlich überarbeitet.
  static const testVersion = 'lumo-cog-v2-2026-11-18';
  static const questionsPerDomain = 10;
  static const totalQuestions = questionsPerDomain * 5;

  // Je Eintrag: gegebenes Wort, Lösung, Frage, zwei Ablenker aus demselben
  // Sachfeld. Früher kamen zwei Ablenker aus den Nachbarfragen und passten
  // nie („Nacht ist meist …“ → Gemüse, Kätzchen). Fachwörter wie These,
  // Hypothese, Konsum oder Synonym sind durch Alltagswörter ersetzt.
  static final _verbalBanks = <int, List<List<String>>>{
    1: <List<String>>[
      [
        'Welpe',
        'Kätzchen',
        'Ein junger Hund heißt Welpe. Eine junge Katze heißt …',
        'Fohlen',
        'Küken'
      ],
      [
        'hell',
        'dunkel',
        'Tag ist meist hell. Nacht ist meist …',
        'laut',
        'bunt'
      ],
      [
        'Obst',
        'Gemüse',
        'Apfel gehört zu Obst. Karotte gehört zu …',
        'Süßigkeiten',
        'Getränken'
      ],
      ['fliegt', 'schwimmt', 'Vogel fliegt. Fisch …', 'hüpft', 'klettert'],
      [
        'Fuß',
        'Hand',
        'Schuh gehört zum Fuß. Handschuh gehört zur …',
        'Nase',
        'Brust'
      ],
      [
        'kalt',
        'klein',
        'Gegenteil von warm ist kalt. Gegenteil von groß ist …',
        'lang',
        'schwer'
      ],
      [
        'Mittwoch',
        'Donnerstag',
        'Montag, Dienstag, Mittwoch – welcher Tag folgt?',
        'Freitag',
        'Sonntag'
      ],
      [
        'Farbe',
        'Form',
        'Rot ist eine Farbe. Kreis ist eine …',
        'Zahl',
        'Größe'
      ],
      [
        'essen',
        'trinken',
        'Bei Hunger können wir essen. Bei Durst können wir …',
        'schlafen',
        'spielen'
      ],
      [
        'lesen',
        'hören',
        'Ein Buch kann man lesen. Ein Lied kann man …',
        'malen',
        'essen'
      ],
    ],
    2: <List<String>>[
      [
        'Honig',
        'Milch',
        'Biene passt zu Honig. Kuh passt zu …',
        'Eiern',
        'Wolle'
      ],
      [
        'Herbst',
        'Winter',
        'Frühling, Sommer, Herbst – was folgt?',
        'Frühling',
        'Sommer'
      ],
      [
        'Straße',
        'Wasser',
        'Auto fährt auf der Straße. Schiff fährt auf dem …',
        'Gleis',
        'Weg'
      ],
      [
        'laut',
        'schnell',
        'Leise ist das Gegenteil von laut. Langsam ist das Gegenteil von …',
        'groß',
        'leicht'
      ],
      [
        'Brot',
        'Möbel',
        'Bäcker macht Brot. Tischler macht …',
        'Kuchen',
        'Kleider'
      ],
      [
        'Wald',
        'Stadt',
        'Viele Bäume bilden einen Wald. Viele Häuser bilden eine …',
        'Wiese',
        'Insel'
      ],
      [
        'Ordination',
        'Schule',
        'Die Ärztin arbeitet in der Ordination. Die Lehrerin arbeitet in der …',
        'Küche',
        'Werkstatt'
      ],
      [
        'sehen',
        'hören',
        'Mit dem Auge sehen wir. Mit dem Ohr …',
        'riechen',
        'schmecken'
      ],
      ['Zeit', 'Länge', 'Minute misst Zeit. Meter misst …', 'Gewicht', 'Wärme'],
      [
        'schwimmen',
        'fliegen',
        'Ein Fisch kann schwimmen. Ein Vogel kann …',
        'bellen',
        'kriechen'
      ],
    ],
    3: <List<String>>[
      [
        'Buch',
        'Film',
        'Kapitel gehört zum Buch. Szene gehört zum …',
        'Bild',
        'Lied'
      ],
      [
        'Temperatur',
        'Gewicht',
        'Thermometer misst Temperatur. Waage misst …',
        'Länge',
        'Größe'
      ],
      [
        'Folge',
        'Antwort',
        'Ursache führt zu Folge. Frage führt zu …',
        'Aufgabe',
        'Fehler'
      ],
      [
        'Richtung',
        'Zeit',
        'Kompass zeigt Richtung. Uhr zeigt …',
        'Wetter',
        'Weg'
      ],
      [
        'sehen',
        'riechen',
        'Mit dem Auge kann man sehen. Mit der Nase kann man …',
        'hören',
        'tasten'
      ],
      [
        'Löffel',
        'Gabel',
        'Suppe isst man mit dem Löffel. Spaghetti isst man mit der …',
        'Schüssel',
        'Tasse'
      ],
      [
        'Buch',
        'Musikstück',
        'Autor schreibt ein Buch. Komponist schreibt ein …',
        'Bild',
        'Gedicht'
      ],
      [
        'Bahnhof',
        'Flughafen',
        'Ein Zug hält am Bahnhof. Ein Flugzeug landet am …',
        'Hafen',
        'Parkplatz'
      ],
      [
        'Bäckerei',
        'Apotheke',
        'Brot kauft man in der Bäckerei. Medikamente kauft man in der …',
        'Fleischerei',
        'Trafik'
      ],
      [
        'Beobachtung',
        'Ergebnis',
        'Ein Versuch liefert eine Beobachtung. Eine Rechnung liefert ein …',
        'Aufgabe',
        'Rätsel'
      ],
    ],
    4: <List<String>>[
      [
        'Wahl',
        'Experiment',
        'Wer abstimmen will, macht eine Wahl. Wer etwas erforschen will, macht ein …',
        'Fest',
        'Gesetz'
      ],
      [
        'Holz',
        'Glas',
        'Ein Tisch ist oft aus Holz. Ein Fenster ist meist aus …',
        'Papier',
        'Wolle'
      ],
      [
        'Woche',
        'Jahr',
        'Sieben Tage sind eine Woche. Zwölf Monate sind ein …',
        'Monat',
        'Tag'
      ],
      [
        'Schmetterling',
        'Frosch',
        'Aus einer Raupe wird ein Schmetterling. Aus einer Kaulquappe wird ein …',
        'Fisch',
        'Käfer'
      ],
      [
        'Kilogramm',
        'Tonnen',
        'Ein Sack Kartoffeln wiegt einige Kilogramm. Ein Lastwagen wiegt einige …',
        'Gramm',
        'Liter'
      ],
      [
        'Absatz',
        'Buch',
        'Mehrere Sätze bilden einen Absatz. Mehrere Kapitel bilden ein …',
        'Satz',
        'Wort'
      ],
      [
        'Ursache',
        'Wirkung',
        'Regen ist die Ursache. Nasse Straßen sind die …',
        'Regel',
        'Lösung'
      ],
      [
        'pumpen',
        'atmen',
        'Mit dem Herz kann man Blut pumpen. Mit der Lunge kann man …',
        'sehen',
        'denken'
      ],
      [
        'Kapitän',
        'Pilot',
        'Ein Schiff steuert der Kapitän. Ein Flugzeug steuert der …',
        'Schaffner',
        'Gärtner'
      ],
      [
        'Eis',
        'Sand',
        'Am Nordpol gibt es viel Eis. In der Wüste gibt es viel …',
        'Schnee',
        'Wasser'
      ],
    ],
  };

  static List<CognitiveQuestion> forGrade(int grade) {
    final g = grade.clamp(1, 4);
    final out = <CognitiveQuestion>[];
    for (var i = 0; i < questionsPerDomain; i++) {
      out.add(_pattern(g, i));
      out.add(_quantitative(g, i));
      out.add(_verbal(g, i));
      out.add(_spatial(g, i));
      out.add(_memory(g, i));
    }
    return List.unmodifiable(out);
  }

  /// Validates the visible problem, including its arithmetic or spatial rule.
  /// Language analogies are checked against the reviewed finite word bank.
  static List<String> problems(CognitiveQuestion q) {
    final issues = <String>[];
    final canonical = q.choices.map((s) => s.trim().toLowerCase()).toList();
    if (q.id.isEmpty ||
        q.grade < 1 ||
        q.grade > 4 ||
        q.difficulty < 1 ||
        q.difficulty > 5 ||
        q.prompt.trim().isEmpty ||
        q.explanation.trim().isEmpty) {
      issues.add('invalid_metadata');
    }
    if (canonical.length != 4 ||
        canonical.toSet().length != 4 ||
        canonical.any((s) => s.isEmpty) ||
        q.choices.where((s) => s == q.correctAnswer).length != 1) {
      issues.add('ambiguous_choices');
    }
    String? expected;
    switch (q.domain) {
      case CognitiveDomain.patternReasoning:
        if (q.prompt.startsWith('Welche Zahl folgt?')) {
          final values = RegExp(r'\d+')
              .allMatches(q.prompt)
              .map((m) => int.parse(m[0]!))
              .toList();
          if (values.length == 4) {
            final step = values[1] - values[0];
            if (step != 0 &&
                values[2] - values[1] == step &&
                values[3] - values[2] == step) {
              expected = '${values.last + step}';
            }
          }
        } else if (q.prompt.startsWith('Setze das Muster fort:')) {
          final symbols = q.prompt.split(':').last.trim().split(RegExp(r'\s+'));
          if (symbols.isNotEmpty && symbols.last == '?') {
            final shown = symbols.sublist(0, symbols.length - 1);
            for (var period = 1; period <= shown.length ~/ 2; period++) {
              if ([
                for (var i = 0; i < shown.length; i++)
                  shown[i] == shown[i % period]
              ].every((v) => v)) {
                expected = shown[shown.length % period];
                break;
              }
            }
          }
        }
      case CognitiveDomain.quantitativeReasoning:
        final patterns = <String>[
          r'^Lumo hat (\d+) Sterne und bekommt (\d+) dazu\. Wie viele hat er\?$',
          r'^(\d+) gleiche Gruppen haben je (\d+) Punkte\. Wie viele Punkte sind es\?$',
          r'^Rechne im Kopf: \((\d+) \+ (\d+)\) × 2 = \?$',
          r'^(\d+) gleiche Dinge kosten je (\d+) Euro\. Bezahlt werden (\d+) Euro\. Wie viel Geld bekommt man zurück\?$',
        ];
        if (q.grade >= 1 && q.grade <= 4) {
          final match = RegExp(patterns[q.grade - 1]).firstMatch(q.prompt);
          if (match != null) {
            final a = int.parse(match[1]!), b = int.parse(match[2]!);
            expected = '${switch (q.grade) {
              1 => a + b,
              2 => a * b,
              3 => (a + b) * 2,
              _ => int.parse(match[3]!) - a * b,
            }}';
          }
        }
      case CognitiveDomain.verbalReasoning:
        final entries = _verbalBanks[q.grade] ?? const <List<String>>[];
        final matching =
            entries.where((entry) => entry[2] == q.prompt).toList();
        if (matching.length == 1) expected = matching.single[1];
      case CognitiveDomain.spatialReasoning:
        const arrows = ['↑', '→', '↓', '←'];
        final degrees = RegExp(
                r'^Der Pfeil ([↑→↓←]) wird um (90|180|270)° (im|gegen den) Uhrzeigersinn gedreht\. Wohin zeigt er danach\?$')
            .firstMatch(q.prompt);
        final turn = RegExp(
                r'^Der Pfeil ([↑→↓←]) macht (eine Vierteldrehung|eine halbe Drehung|eine Dreivierteldrehung) (im|gegen den) Uhrzeigersinn\. ')
            .firstMatch(q.prompt);
        final match = degrees ?? turn;
        if (match != null) {
          final steps = degrees != null
              ? int.parse(match[2]!) ~/ 90
              : const <String, int>{
                  'eine Vierteldrehung': 1,
                  'eine halbe Drehung': 2,
                  'eine Dreivierteldrehung': 3,
                }[match[2]]!;
          expected = arrows[(arrows.indexOf(match[1]!) +
                  (match[3] == 'im' ? steps : -steps)) %
              arrows.length];
        }
      case CognitiveDomain.workingMemory:
        final stimulus = q.stimulus;
        if (stimulus == null ||
            q.stimulusVisibleMs <= 0 ||
            !RegExp(r'^\d(?:\s+\d)+$').hasMatch(stimulus)) {
          issues.add('invalid_memory_stimulus');
          break;
        }
        final digits = stimulus.trim().split(RegExp(r'\s+'));
        final position = RegExp(r'^Welche Zahl stand an (\d+)\. Stelle\?$')
            .firstMatch(q.prompt);
        if (position != null) {
          final index = int.parse(position[1]!) - 1;
          if (index >= 0 && index < digits.length) expected = digits[index];
        } else if (q.prompt ==
            'Welche Antwort zeigt die gemerkte Folge rückwärts?') {
          expected = digits.reversed.join(' – ');
        }
    }
    if (expected == null || expected != q.correctAnswer) {
      issues.add('answer_not_supported_by_givens');
    }
    return issues;
  }

  static CognitiveQuestion _pattern(int g, int i) {
    if (i.isEven) {
      final step = g + 1 + (i % 3);
      final start = 1 + g * 2 + i;
      final a = start;
      final b = a + step;
      final c = b + step;
      final d = c + step;
      final answer = d + step;
      return _choice(
        id: 'g${g}_pattern_$i',
        grade: g,
        domain: CognitiveDomain.patternReasoning,
        prompt: 'Welche Zahl folgt?  $a – $b – $c – $d – ?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer + step}',
          '${answer - 1}',
          '${answer + 1}'
        ],
        explanation: 'Der Abstand ist jedes Mal $step.',
        difficulty: 1 + i ~/ 2,
        rotate: i,
      );
    }
    const shapes = <String>['●', '▲', '■', '◆'];
    // Mehrere Musterarten und wechselnde Abbruchstellen, damit die Lösung
    // nicht immer die erste Form ist und keine Frage doppelt vorkommt.
    final k = i ~/ 2;
    final units = g <= 2
        ? const <String>['AB', 'AB', 'AAB', 'ABC', 'ABB']
        : const <String>['ABC', 'AAB', 'ABB', 'ABCD', 'AABB'];
    final unit = units[k];
    final offset = (g + k) % shapes.length;
    final symbols = <String>[
      for (final letter in unit.split(''))
        shapes[(offset + 'ABCD'.indexOf(letter)) % shapes.length],
    ];
    final period = symbols.length;
    // Mindestens zwei ganze Durchgänge, danach bricht die Reihe ab.
    final shownLength = period * 2 + (g + k) % period;
    final shown = <String>[
      for (var n = 0; n < shownLength; n++) symbols[n % period],
    ];
    final answer = symbols[shownLength % period];
    return _choice(
      id: 'g${g}_pattern_$i',
      grade: g,
      domain: CognitiveDomain.patternReasoning,
      prompt: 'Setze das Muster fort:  ${shown.join(' ')} ?',
      answer: answer,
      rawChoices: shapes,
      explanation:
          'Diese Formen wiederholen sich immer gleich: ${symbols.join(' ')}.',
      difficulty: 1 + i ~/ 2,
      rotate: i,
    );
  }

  static CognitiveQuestion _quantitative(int g, int i) {
    final base = 2 + i + g;
    if (g == 1) {
      final add = 1 + i % 5;
      final answer = base + add;
      return _choice(
        id: 'g${g}_quant_$i',
        grade: g,
        domain: CognitiveDomain.quantitativeReasoning,
        prompt:
            'Lumo hat $base Sterne und bekommt $add dazu. Wie viele hat er?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer - 1}',
          '${answer + 1}',
          '${answer + 2}'
        ],
        explanation: '$base + $add = $answer.',
        difficulty: 1 + i ~/ 2,
        rotate: i + 1,
      );
    }
    if (g == 2) {
      final groups = 2 + i % 4;
      final each = 2 + (i + 1) % 5;
      final answer = groups * each;
      return _choice(
        id: 'g${g}_quant_$i',
        grade: g,
        domain: CognitiveDomain.quantitativeReasoning,
        prompt:
            '$groups gleiche Gruppen haben je $each Punkte. Wie viele Punkte sind es?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer + each}',
          '${answer - each}',
          '${groups + each}',
          // Bei 2 × 2 sind Ergebnis und „Gruppen + je“ beide 4.
          // Echte Rechenfehler anbieten statt Platzhalter zu brauchen.
          '${answer + 1}',
          '${answer - 1}',
        ],
        explanation: '$groups × $each = $answer.',
        difficulty: 1 + i ~/ 2,
        rotate: i + 1,
      );
    }
    if (g == 3) {
      final a = 10 + i * 3;
      final b = 3 + i % 5;
      final answer = (a + b) * 2;
      return _choice(
        id: 'g${g}_quant_$i',
        grade: g,
        domain: CognitiveDomain.quantitativeReasoning,
        prompt: 'Rechne im Kopf: ($a + $b) × 2 = ?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer - 2}',
          '${answer + 2}',
          '${a + b}'
        ],
        explanation: 'Zuerst addieren, dann verdoppeln.',
        difficulty: 1 + i ~/ 2,
        rotate: i + 1,
      );
    }
    final price = 4 + i;
    final count = 2 + i % 4;
    // Das Wechselgeld wechselt von Aufgabe zu Aufgabe (3 bis 9 Euro); früher war es immer 10.
    final answer = 3 + (i * 2) % 7;
    final paid = price * count + answer;
    return _choice(
      id: 'g${g}_quant_$i',
      grade: g,
      domain: CognitiveDomain.quantitativeReasoning,
      prompt:
          '$count gleiche Dinge kosten je $price Euro. Bezahlt werden $paid Euro. Wie viel Geld bekommt man zurück?',
      answer: '$answer',
      // Typische Fehler: Gesamtpreis statt Wechselgeld, um eins verrechnet.
      rawChoices: <String>[
        '$answer',
        '${price * count}',
        '${answer + 1}',
        '${answer - 1}',
        '${answer + 2}',
      ],
      explanation:
          '$count × $price = ${price * count}. Von $paid bleiben $answer Euro.',
      difficulty: 1 + i ~/ 2,
      rotate: i + 1,
    );
  }

  static CognitiveQuestion _verbal(int g, int i) {
    final banks = _verbalBanks;
    final item = banks[g]![i];
    final answer = item[1];
    final distractorA = item[0];
    final distractorB = item[3];
    final distractorC = item[4];
    return _choice(
      id: 'g${g}_verbal_$i',
      grade: g,
      domain: CognitiveDomain.verbalReasoning,
      prompt: item[2],
      answer: answer,
      rawChoices: <String>[
        answer,
        distractorA,
        distractorB,
        distractorC,
        // Weitere echte Begriffe statt künstlicher Platzhalter, falls
        // eine Antwort in den benachbarten Wortpaaren doppelt vorkommt.
        ...banks[g]!.map((entry) => entry[1]),
      ],
      explanation: 'Die Beziehung muss auf beide Wortpaare gleich passen.',
      difficulty: 1 + i ~/ 2,
      rotate: i + 2,
    );
  }

  static CognitiveQuestion _spatial(int g, int i) {
    const arrows = <String>['↑', '→', '↓', '←'];
    // Jede Frage eines Tests ist eine eigene Kombination aus Startpfeil,
    // Drehweite und Richtung (früher kam dieselbe Frage bis zu dreimal vor).
    // Schritt 5 ist teilerfremd zu 16 und 24, so entstehen 10 verschiedene.
    final turnsAvailable = g >= 3 ? 3 : 2;
    final combo = (g * 3 + i * 5) % (4 * 2 * turnsAvailable);
    final startIndex = combo % 4;
    final clockwise = (combo ~/ 4).isEven;
    final quarterTurns = 1 + combo ~/ 8;
    final delta = clockwise ? quarterTurns : -quarterTurns;
    final answerIndex = (startIndex + delta) % 4;
    final normalized = answerIndex < 0 ? answerIndex + 4 : answerIndex;
    final start = arrows[startIndex];
    final answer = arrows[normalized];
    final degrees = quarterTurns * 90;
    return _choice(
      id: 'g${g}_spatial_$i',
      grade: g,
      domain: CognitiveDomain.spatialReasoning,
      // „um 90° nach rechts gedreht“ lasen Kinder als „zeigt dann nach
      // rechts“. Jetzt heißt es „Vierteldrehung im Uhrzeigersinn“; Grad
      // kommen erst in Klasse 4 vor.
      prompt: g >= 4
          ? 'Der Pfeil $start wird um $degrees° ${clockwise ? 'im' : 'gegen den'} Uhrzeigersinn gedreht. Wohin zeigt er danach?'
          : 'Der Pfeil $start macht ${const <String>[
              'eine Vierteldrehung',
              'eine halbe Drehung',
              'eine Dreivierteldrehung'
            ][quarterTurns - 1]} ${clockwise ? 'im' : 'gegen den'} Uhrzeigersinn. Im Uhrzeigersinn heißt: so wie sich die Zeiger einer Uhr drehen. Wohin zeigt der Pfeil danach?',
      answer: answer,
      rawChoices: arrows,
      explanation:
          'Drehe den Pfeil gedanklich um $quarterTurns Vierteldrehung${quarterTurns == 1 ? '' : 'en'}.',
      difficulty: 1 + i ~/ 2,
      rotate: i + 3,
    );
  }

  static CognitiveQuestion _memory(int g, int i) {
    // Altersgemäße Längen: Klasse 1 zwei bis vier Ziffern, Klasse 4 vier
    // bis sechs (früher bis zu neun). Rückwärts eine Ziffer kürzer.
    const shortest = <int, int>{1: 2, 2: 3, 3: 3, 4: 4};
    final forward = shortest[g]! + (i ~/ 4);
    final length = i.isEven ? forward : (forward - 1).clamp(3, 9);
    final digits = <int>[];
    for (var k = 0; k < length; k++) {
      // Schritt 4 je Frage: neun verschiedene Startziffern, keine Folge
      // doppelt (früher wiederholte sie sich alle drei Fragen).
      digits.add(1 + ((g * 7 + i * 4 + k * 5) % 9));
    }
    final stimulus = digits.join('  ');
    if (i.isEven) {
      final position = 1 + (i % length);
      final answer = '${digits[position - 1]}';
      final options = <String>[
        answer,
        '${digits[position % length]}',
        '${digits[(position + 1) % length]}',
        '${1 + (digits[position - 1] + 3) % 9}',
      ];
      return _choice(
        id: 'g${g}_memory_$i',
        grade: g,
        domain: CognitiveDomain.workingMemory,
        prompt: 'Welche Zahl stand an $position. Stelle?',
        answer: answer,
        rawChoices: <String>[
          ...options,
          // Eine Merkaufgabe braucht vier verschiedene echte Ziffern.
          for (var digit = 1; digit <= 9; digit++) '$digit',
        ],
        explanation:
            'Die Folge war ${digits.join(' – ')}. An $position. Stelle stand $answer.',
        difficulty: 1 + i ~/ 2,
        rotate: i,
        stimulus: stimulus,
        stimulusVisibleMs: 3500 + g * 350,
      );
    }
    final backwards = digits.reversed.toList();
    final reversed = backwards.join(' – ');
    // Ablenker beginnen mit derselben Ziffer wie die Lösung und enden gleich;
    // nur in der Mitte ist etwas vertauscht oder falsch. Früher begann nur
    // die richtige Karte mit der zuletzt gezeigten Ziffer.
    List<int> swapped(int a, int b) {
      final copy = <int>[...backwards];
      final t = copy[a];
      copy[a] = copy[b];
      copy[b] = t;
      return copy;
    }

    final middle = backwards.length ~/ 2;
    final changed = <int>[...backwards]..[middle] =
        1 + (backwards[middle] + 3) % 9;
    final raw = <String>[
      reversed,
      if (backwards.length >= 4) swapped(1, 2).join(' – '),
      changed.join(' – '),
      swapped(0, 1).join(' – '),
      swapped(backwards.length - 2, backwards.length - 1).join(' – '),
      digits.join(' – '),
    ];
    return _choice(
      id: 'g${g}_memory_$i',
      grade: g,
      domain: CognitiveDomain.workingMemory,
      prompt: 'Welche Antwort zeigt die gemerkte Folge rückwärts?',
      answer: reversed,
      rawChoices: <String>[
        ...raw,
        // Weitere plausible Merkfolgen mit genau einer falschen Ziffer.
        // Die vollständige Sequenz bleibt lesbar, auch bei Dopplungen.
        for (var offset = 1; offset <= 8; offset++)
          '${(digits.last + offset - 1) % 9 + 1} – ${digits.reversed.skip(1).join(' – ')}',
      ],
      explanation: 'Beginne bei der letzten Zahl und gehe zur ersten zurück.',
      difficulty: 1 + i ~/ 2,
      rotate: i,
      stimulus: stimulus,
      stimulusVisibleMs: 3500 + g * 350,
    );
  }

  static CognitiveQuestion _choice({
    required String id,
    required int grade,
    required CognitiveDomain domain,
    required String prompt,
    required String answer,
    required List<String> rawChoices,
    required String explanation,
    required int difficulty,
    required int rotate,
    String? stimulus,
    int stimulusVisibleMs = 0,
  }) {
    // Die richtige Lösung gehört immer in die ersten vier Auswahlfelder.
    // Fehlende Ablenker sind ein Fehler im jeweiligen Aufgabentyp – niemals
    // bedeutungslose Platzhalter für Kinder erzeugen.
    final unique = <String>[answer];
    for (final candidate in rawChoices) {
      if (candidate.trim().isNotEmpty && !unique.contains(candidate)) {
        unique.add(candidate);
      }
    }
    if (unique.length < 4) {
      throw StateError('Weniger als vier echte Antworten für $id');
    }
    final choices = unique.take(4).toList();
    final shift = rotate % choices.length;
    final rotated = <String>[
      ...choices.skip(shift),
      ...choices.take(shift),
    ];
    final question = CognitiveQuestion(
      id: id,
      grade: grade,
      domain: domain,
      prompt: prompt,
      choices: List.unmodifiable(rotated),
      correctAnswer: answer,
      explanation: explanation,
      difficulty: difficulty.clamp(1, 5),
      stimulus: stimulus,
      stimulusVisibleMs: stimulusVisibleMs,
    );
    final issues = problems(question);
    if (issues.isNotEmpty) {
      throw StateError("Unchecked cognitive question $id: $issues");
    }
    return question;
  }
}
