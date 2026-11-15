/// Release-effective checks for the separate card and quiz question banks.
///
/// Arithmetic and explicit word operations are derived from the prompt, never
/// from the stored correct index. Other items belong to a closed, reviewed
/// catalogue, including its distractors. Unknown facts are not guessed.
class ChoiceQuestionQuality {
  const ChoiceQuestionQuality._();

  static List<String> problems({
    required String prompt,
    required List<String> options,
    required int correctIndex,
    int minOptions = 2,
    int maxOptions = 4,
    bool requireReviewedPrompt = true,
  }) {
    final issues = <String>[];
    if (prompt.trim().isEmpty) issues.add('empty_prompt');
    if (options.length < minOptions || options.length > maxOptions) {
      issues.add('option_count');
    }
    if (options.any((option) => option.trim().isEmpty)) {
      issues.add('empty_option');
    }
    if (options.map(_key).toSet().length != options.length) {
      issues.add('equivalent_options');
    }
    if (correctIndex < 0 || correctIndex >= options.length) {
      issues.add('invalid_correct_index');
      return issues;
    }
    final rule = _rule(prompt.trim(), options);
    if (rule == null) {
      if (requireReviewedPrompt) issues.add('unreviewed_prompt');
      return issues;
    }
    if (rule.allowed != null &&
        options.any((option) => !rule.allowed!.contains(_key(option)))) {
      issues.add('unreviewed_distractor');
    }
    final matches = [
      for (var index = 0; index < options.length; index++)
        if (rule.accepts(options[index])) index,
    ];
    if (matches.length != 1) {
      issues.add('answer_not_unique');
    } else if (matches.single != correctIndex) {
      issues.add('incorrect_answer');
    }
    return issues;
  }

  static String _key(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final quantity =
        RegExp(r'^([+-]?\d+(?:[.,]\d+)?)\s*(€|Euro|cm|km)?$').firstMatch(clean);
    if (quantity != null) {
      final number = num.parse(quantity[1]!.replaceAll(',', '.')).toDouble();
      final unit = quantity[2] == '€' ? 'Euro' : (quantity[2] ?? '');
      return 'number:$number:$unit';
    }
    final clock = RegExp(r'^(\d{1,2}):(\d{2})(?: Uhr)?$').firstMatch(clean);
    if (clock != null) {
      return 'clock:${int.parse(clock[1]!)}:${int.parse(clock[2]!)}';
    }
    return clean.toLowerCase();
  }

  static _ChoiceRule _answer(String expected,
          {Set<String>? allowed, bool caseSensitive = false}) =>
      _ChoiceRule(
          (option) => caseSensitive
              ? option.trim() == expected
              : _key(option) == _key(expected),
          allowed: allowed?.map(_key).toSet());

  static _ChoiceRule _number(num expected, [String unit = '']) =>
      _answer('$expected${unit.isEmpty ? '' : ' $unit'}');

  static _ChoiceRule? _rule(String prompt, List<String> options) {
    final arithmetic = RegExp(
            r'^(?:(?:Wie viel|Was) ist |Schriftlich:\s*)?(-?\d+)\s*(\+|[-−]|mal|[·×x*]|geteilt durch|[:÷/])\s*(-?\d+)\s*(?:\?|=\s*\??)$')
        .firstMatch(prompt);
    if (arithmetic != null) {
      final a = int.parse(arithmetic[1]!);
      final b = int.parse(arithmetic[3]!);
      final op = arithmetic[2]!;
      if (op == '+') return _number(a + b);
      if (op == '-' || op == '−') return _number(a - b);
      if (const {'mal', '·', '×', 'x', '*'}.contains(op)) {
        return _number(a * b);
      }
      if (b == 0 || a % b != 0) return null;
      return _number(a ~/ b);
    }

    final comparison =
        RegExp(r'^Welches Zeichen passt\? (\d+) \? (\d+)$').firstMatch(prompt);
    if (comparison != null) {
      final a = int.parse(comparison[1]!);
      final b = int.parse(comparison[2]!);
      return _answer(a < b
          ? '<'
          : a > b
              ? '>'
              : '=');
    }
    final neighbours = RegExp(r'^(?:Was|Welche Zahl) kommt (nach|vor) (\d+)\?$')
        .firstMatch(prompt);
    if (neighbours != null) {
      return _number(
          int.parse(neighbours[2]!) + (neighbours[1] == 'nach' ? 1 : -1));
    }
    final fraction = RegExp(r'^Was ist (die Hälfte|ein Viertel) von (\d+)\?$')
        .firstMatch(prompt);
    if (fraction != null) {
      return _number(
          int.parse(fraction[2]!) / (fraction[1] == 'die Hälfte' ? 2 : 4));
    }
    final greaterPair = RegExp(r'^Welche Zahl ist größer: (\d+) oder (\d+)\?$')
        .firstMatch(prompt);
    if (greaterPair != null) {
      final a = int.parse(greaterPair[1]!);
      final b = int.parse(greaterPair[2]!);
      return a == b ? _answer('Beide gleich') : _number(a > b ? a : b);
    }
    if (const {
      'Welche Zahl ist größer?',
      'Welche Zahl ist kleiner?',
      'Welche Menge ist mehr?'
    }.contains(prompt)) {
      final values = options.map(int.tryParse).toList();
      if (values.any((value) => value == null)) return null;
      final numbers = values.cast<int>()..sort();
      return _number(
          prompt == 'Welche Zahl ist kleiner?' ? numbers.first : numbers.last);
    }
    if (prompt == 'Welche Zahl ist gerade?') {
      return _ChoiceRule((option) => int.tryParse(option)?.isEven ?? false);
    }
    final bound =
        RegExp(r'^Was ist (größer|kleiner) als (\d+)\?$').firstMatch(prompt);
    if (bound != null) {
      final number = int.parse(bound[2]!);
      return _ChoiceRule((option) {
        final candidate = int.tryParse(option);
        return candidate != null &&
            (bound[1] == 'größer' ? candidate > number : candidate < number);
      });
    }
    final bounds = RegExp(
            r'^Welche Zahl ist größer als (\d+), kleiner als (\d+) und gerade\?$')
        .firstMatch(prompt);
    if (bounds != null) {
      final lower = int.parse(bounds[1]!);
      final upper = int.parse(bounds[2]!);
      return _ChoiceRule((option) {
        final number = int.tryParse(option);
        return number != null &&
            number > lower &&
            number < upper &&
            number.isEven;
      });
    }
    final money = RegExp(r'^Wie viel sind (\d+) Euro plus (\d+) Cent\?$')
        .firstMatch(prompt);
    if (money != null) {
      return _number(int.parse(money[1]!) + int.parse(money[2]!) / 100, 'Euro');
    }
    final hour = RegExp(r'^Wie spät ist (\d+) Uhr\?$').firstMatch(prompt);
    if (hour != null) {
      final h = int.parse(hour[1]!);
      return h >= 1 && h <= 12 ? _answer('$h:00') : null;
    }
    final halfHour = RegExp(r'^(?:Halb (\d+) ist|Wie spät ist halb (\d+))\?$')
        .firstMatch(prompt);
    if (halfHour != null) {
      final h = int.parse(halfHour[1] ?? halfHour[2]!);
      return h >= 1 && h <= 12 ? _answer('${h == 1 ? 12 : h - 1}:30') : null;
    }
    final series = RegExp(r'^Setze das Verdoppeln fort: ([0-9, ]+), \.\.\.\?$')
        .firstMatch(prompt);
    if (series != null) {
      final values =
          series[1]!.split(',').map((s) => int.parse(s.trim())).toList();
      if (values.length < 3 ||
          List.generate(
                  values.length - 1, (i) => values[i + 1] != 2 * values[i])
              .any((wrong) => wrong)) {
        return null;
      }
      return _number(values.last * 2);
    }

    final letter =
        RegExp(r'^Mit welchem Buchstaben beginnt "([A-Za-zÄÖÜäöüß]+)"\?$')
            .firstMatch(prompt);
    if (letter != null) return _answer(letter[1]![0]);
    final letterFind =
        RegExp(r'^Finde den Buchstaben ([A-ZÄÖÜ])\.$').firstMatch(prompt);
    if (letterFind != null) return _answer(letterFind[1]!);
    final wordFind =
        RegExp(r'^Finde das Wort: ([A-Za-zÄÖÜäöüß]+)$').firstMatch(prompt);
    if (wordFind != null) return _answer(wordFind[1]!);
    final letterCount =
        RegExp(r'^Wie viele Buchstaben hat das Wort "([A-Za-zÄÖÜäöüß]+)"\?$')
            .firstMatch(prompt);
    if (letterCount != null) return _number(letterCount[1]!.runes.length);
    final syllables =
        RegExp(r'^Wie klatscht man ([A-Za-zÄÖÜäöüß]+)\?$').firstMatch(prompt);
    if (syllables != null) {
      final expected = _syllables[syllables[1]!];
      return expected == null ? null : _answer(expected);
    }
    final plural = RegExp(
            r'^Wie heißt die Mehrzahl: eine? ([A-Za-zÄÖÜäöüß]+), viele \.\.\.\?$')
        .firstMatch(prompt);
    if (plural != null) {
      final expected = _plurals[plural[1]!];
      return expected == null ? null : _answer(expected);
    }
    final rhyme = RegExp(r'^Was reimt sich auf "?([A-Za-zÄÖÜäöüß]+)"?\?$')
        .firstMatch(prompt);
    if (rhyme != null) {
      final expected = _rhymes[rhyme[1]!];
      return expected == null
          ? null
          : _answer(expected, allowed: _rhymeVocabulary);
    }
    final article = RegExp(
            r'^Welcher Artikel passt in der Grundform: ___ (Sonne|Buch|Tisch)\?$')
        .firstMatch(prompt);
    if (article != null) {
      return _answer(
          const {'Sonne': 'Die', 'Buch': 'Das', 'Tisch': 'Der'}[article[1]]!);
    }

    // These exact stories have been checked independently of the stored index.
    // Changes to their wording/numbers require a new rule, not a silent guess.
    final storyAnswer = switch (prompt) {
      'Lisa hat 3 Äpfel und bekommt 4 dazu. Wie viele Äpfel hat sie dann?' =>
        3 + 4,
      'Tom hat 10 Karten und gibt 2 weg. Wie viele Karten bleiben ihm?' =>
        10 - 2,
      '2 Kinder haben je 5 Sterne. Wie viele Sterne haben sie zusammen?' =>
        2 * 5,
      'Ein Buch hat 20 Seiten. 5 Seiten sind schon gelesen. Wie viele Seiten fehlen noch?' =>
        20 - 5,
      'Auf 4 Tischen liegen je 3 Stifte. Wie viele Stifte sind es zusammen?' =>
        4 * 3,
      'Im Korb liegen 6 Äpfel. Zwei Kinder nehmen je einen Apfel. Wie viele bleiben?' =>
        6 - 2,
      'Lumo denkt an eine Zahl. Plus 5 ergibt 17. Welche Zahl meint Lumo?' =>
        17 - 5,
      '12 Karten werden gleich auf 4 Kinder verteilt. Wie viele Karten bekommt jedes Kind?' =>
        12 ~/ 4,
      'Lumo liest morgens 8 Seiten und abends 7 Seiten. Wie viele Seiten liest er in 3 Tagen?' =>
        (8 + 7) * 3,
      _ => null,
    };
    if (storyAnswer != null) return _number(storyAnswer);
    if (prompt ==
        'Drei Hefte kosten je 4 Euro. Du bezahlst mit 20 Euro. Wie viel Geld bekommst du zurück?') {
      return _number(20 - 3 * 4, 'Euro');
    }
    if (prompt ==
        'Ein Rechteck ist 8 cm lang und 5 cm breit. Wie groß ist sein Umfang?') {
      return _number(2 * (8 + 5), 'cm');
    }
    if (prompt ==
        'Ein Bus fährt dreimal 18 km und danach noch 6 km. Wie viele Kilometer sind es insgesamt?') {
      return _number(3 * 18 + 6, 'km');
    }
    final reviewed = _reviewed[prompt];
    return reviewed == null
        ? null
        : _answer(reviewed.$1,
            allowed: reviewed.$2,
            caseSensitive:
                prompt == 'Welcher Fischname ist richtig geschrieben?');
  }

  static const _syllables = {
    'Mama': 'Ma-ma',
    'Sonne': 'Son-ne',
    'Hase': 'Ha-se',
    'Blume': 'Blu-me',
    'Katze': 'Kat-ze',
  };
  static const _plurals = {
    'Hund': 'Hunde',
    'Katze': 'Katzen',
    'Ball': 'Bälle',
    'Buch': 'Bücher',
    'Kind': 'Kinder',
    'Haus': 'Häuser',
    'Baum': 'Bäume',
    'Apfel': 'Äpfel',
    'Maus': 'Mäuse',
    'Stift': 'Stifte',
  };
  static const _rhymes = {
    'Haus': 'Maus',
    'Ball': 'Fall',
    'Sonne': 'Tonne',
    'Hase': 'Nase',
    'Buch': 'Tuch',
    'Kind': 'Wind',
    'Schule': 'Kuhle',
    'Baum': 'Raum',
    'Licht': 'Gesicht',
    'Hand': 'Sand',
    'Hose': 'Rose',
    'Katze': 'Tatze',
  };
  static const _rhymeVocabulary = {
    'Haus',
    'Maus',
    'Hund',
    'Auto',
    'Buch',
    'Ball',
    'Stern',
    'Katze',
    'Blume',
    'Fall',
    'Sonne',
    'Tonne',
    'Hase',
    'Nase',
    'Tuch',
    'Kind',
    'Wind',
    'Schule',
    'Kuhle',
    'Baum',
    'Raum',
    'Licht',
    'Gesicht',
    'Hand',
    'Sand',
    'Hose',
    'Rose',
    'Tasse',
    'Tatze',
  };

  // Closed catalogue: every offered distractor was reviewed along with its
  // exact question. This is not a general-purpose fact inference engine.
  // Sources for changed science claims: QUESTION_BANK_COVERAGE.md.
  static const _reviewed = <String, (String, Set<String>)>{
    'Was hat 3 Ecken?': ('Dreieck', {'Dreieck', 'Kreis', 'Ball', 'Sonne'}),
    'Was ist rund?': ('Kreis', {'Kreis', 'Quadrat', 'Buch', 'Haus'}),
    'Was hat 4 gleiche Seiten?': (
      'Quadrat',
      {'Quadrat', 'Kreis', 'Dreieck', 'Linie'}
    ),
    'Wie viele Finger an einer Hand?': ('5', {'5', '4', '6', '10'}),
    'Wie viele Finger hat eine Hand?': ('5', {'5', '4', '6', '10'}),
    'Welche Zahl fehlt: 1,2,3,_?': ('4', {'4', '5', '2', '6'}),
    'Welche Form hat keine Ecken?': (
      'Kreis',
      {'Kreis', 'Dreieck', 'Quadrat', 'Haus'}
    ),
    'Wie viele Ecken hat ein Quadrat?': ('4', {'4', '3', '5', '0', '6'}),
    'Wie viele Ecken hat ein Dreieck?': ('3', {'3', '4', '2', '0', '5'}),
    'Wie heißt eine Form mit 5 Ecken?': (
      'Fünfeck',
      {'Quadrat', 'Fünfeck', 'Sechseck', 'Kreis'}
    ),
    'Wie viele Minuten hat eine Stunde?': ('60', {'30', '45', '60', '100'}),
    'Wie viele Sekunden hat eine Minute?': ('60', {'30', '50', '60', '100'}),
    'Wie viele Tage hat eine Woche?': ('7', {'5', '6', '7', '8'}),
    'Was ist ein Tier?': ('Hund', {'Hund', 'Tisch', 'Buch', 'Haus'}),
    'Welches Wort beschreibt ein Tier?': (
      'Hund',
      {'Hund', 'Tisch', 'Auto', 'Buch'}
    ),
    'Was kann man essen?': ('Apfel', {'Apfel', 'Stuhl', 'Schuh', 'Buch'}),
    'Was ist ein Fahrzeug?': ('Auto', {'Auto', 'Baum', 'Hase', 'Milch'}),
    'Was liest man?': ('Buch', {'Buch', 'Ball', 'Tasse', 'Lampe'}),
    'Was trägt man am Fuß?': ('Schuh', {'Schuh', 'Hut', 'Jacke', 'Tisch'}),
    'Was spendet der Erde Licht und Wärme?': (
      'Sonne',
      {'Sonne', 'Eis', 'Schnee', 'Regen'}
    ),
    'Welches Tier lebt mit Kiemen im Wasser?': (
      'Fisch',
      {'Fisch', 'Vogel', 'Hase', 'Katze'}
    ),
    'Was braucht man zum Schreiben?': (
      'Stift',
      {'Stift', 'Löffel', 'Ball', 'Uhr'}
    ),
    'Was ist ein Möbel?': ('Tisch', {'Tisch', 'Apfel', 'Hund', 'Sonne'}),
    'Was zeigt die Zeit?': ('Uhr', {'Uhr', 'Buch', 'Haus', 'Baum'}),
    'Welches Wort beschreibt eine Farbe?': (
      'Rot',
      {'Hund', 'Rot', 'Tisch', 'Buch'}
    ),
    'Was isst man zum Frühstück?': ('Brot', {'Auto', 'Brot', 'Stein', 'Stuhl'}),
    'Welche Jacke schützt dich vor Regen?': (
      'Regenjacke',
      {'Hut', 'Regenjacke', 'Schwimmreifen', 'Sandalen'}
    ),
    'Welches Tier sagt "Wuff"?': ('Hund', {'Katze', 'Hund', 'Vogel', 'Fisch'}),
    'Welches Tier sagt "Miau"?': ('Katze', {'Katze', 'Hund', 'Kuh', 'Schwein'}),
    'Wo wohnen Fische?': (
      'Im Wasser',
      {'Im Baum', 'Im Wasser', 'Im Haus', 'In der Luft'}
    ),
    'Welche Farbe hat frisches, gesundes Gras meistens?': (
      'Grün',
      {'Rot', 'Grün', 'Blau', 'Gelb'}
    ),
    'Welche Farbe bekommt eine grüne Supermarktbanane beim Reifen meistens?': (
      'Gelb',
      {'Rot', 'Blau', 'Gelb', 'Grün'}
    ),
    'Was fällt vom Himmel wenn es regnet?': (
      'Wassertropfen',
      {'Schnee', 'Wassertropfen', 'Blätter', 'Steine'}
    ),
    'In welcher Jahreszeit ist es in Österreich meist am kältesten?': (
      'Winter',
      {'Sommer', 'Frühling', 'Winter', 'Herbst'}
    ),
    'Wie viele Augen hat ein Mensch?': ('2', {'1', '2', '3', '4'}),
    'Womit hören wir?': (
      'Mit den Ohren',
      {'Mit den Augen', 'Mit den Ohren', 'Mit dem Mund', 'Mit den Händen'}
    ),
    'Womit riechen wir?': (
      'Mit der Nase',
      {'Mit den Ohren', 'Mit der Nase', 'Mit den Augen', 'Mit den Füßen'}
    ),
    'Was ist das Gegenteil von "groß"?': (
      'Klein',
      {'Schnell', 'Klein', 'Langsam', 'Bunt'}
    ),
    'Was ist das Gegenteil von "hell"?': (
      'Dunkel',
      {'Bunt', 'Weiß', 'Dunkel', 'Warm'}
    ),
    'Was ist das Gegenteil von "alt"?': (
      'Jung',
      {'Jung', 'Klein', 'Schnell', 'Bunt'}
    ),
    'Wie bewegen sich Vögel mit ihren Flügeln durch die Luft?': (
      'Fliegen',
      {'Schwimmen', 'Fliegen', 'Bellen', 'Grasen'}
    ),
    'Wie bewegen sich Fische mit ihren Flossen durch das Wasser?': (
      'Schwimmen',
      {'Fliegen', 'Klettern', 'Schwimmen', 'Bellen'}
    ),
    'Was braucht eine grüne Pflanze außer Wasser, Luft und Nährstoffen zum Wachsen?':
        ('Licht', {'Eis', 'Schokolade', 'Licht', 'Spielzeug'}),
    'Worin verankern die Wurzeln einen Baum im Garten?': (
      'In der Erde',
      {'In der Erde', 'Im Wasser', 'In den Wolken', 'Im Schrank'}
    ),
    'In welcher Jahreszeit werden bei uns viele Laubblätter bunt?': (
      'Herbst',
      {'Sommer', 'Herbst', 'Winter', 'Frühling'}
    ),
    'In welcher Jahreszeit blühen bei uns meist die Tulpen?': (
      'Frühling',
      {'Winter', 'Frühling', 'Herbst', 'Nachts'}
    ),
    'Wer behandelt kranke Menschen?': (
      'Arzt',
      {'Lehrer', 'Arzt', 'Bäcker', 'Friseur'}
    ),
    'Wer backt Brot?': ('Bäcker', {'Arzt', 'Lehrer', 'Bäcker', 'Polizist'}),
    'Wer löscht Feuer?': (
      'Feuerwehrmann',
      {'Bäcker', 'Feuerwehrmann', 'Arzt', 'Briefträger'}
    ),
    'Welches Tier legt Eier?': ('Huhn', {'Kuh', 'Schaf', 'Huhn', 'Pferd'}),
    'Welches Tier gibt Milch?': (
      'Kuh',
      {'Huhn', 'Kuh', 'Schmetterling', 'Schlange'}
    ),
    'Bei welcher Farbe zeigt die Fußgängerampel das gehende Männchen?': (
      'Grün',
      {'Rot', 'Gelb', 'Grün', 'Blau'}
    ),
    'Was ist ein "Verb"?': (
      'Ein Tu-Wort',
      {'Ein Tier', 'Ein Tu-Wort', 'Eine Farbe', 'Ein Name'}
    ),
    'Was ist ein "Nomen"?': (
      'Ein Name-Wort',
      {'Ein Tu-Wort', 'Ein Name-Wort', 'Eine Farbe', 'Ein Zeichen'}
    ),
    'Welches Wort ist ein Verb?': (
      'laufen',
      {'Haus', 'laufen', 'schön', 'schnell'}
    ),
    'Welches Wort ist ein Adjektiv (Wie-Wort)?': (
      'Schnell',
      {'Laufen', 'Hund', 'Schnell', 'Tisch'}
    ),
    'Welcher Fischname ist richtig geschrieben?': (
      'Stör',
      {'Schtohr', 'Stohr', 'Stoa', 'Stör'}
    ),
    'Welches Wort hat ein "ie"?': (
      'Liebe',
      {'Hund', 'Liebe', 'Tasse', 'Stuhl'}
    ),
    'Wie schreibt man die Zahl 12?': (
      'Zwölf',
      {'Zwölf', 'Zwoolf', 'Zwelf', 'Zwlf'}
    ),
    'Mit welchem Satzzeichen endet ein Aussagesatz?': (
      'Punkt',
      {'Komma', 'Punkt', 'Fragezeichen', 'Strich'}
    ),
    'Wie endet eine Frage?': (
      'Fragezeichen',
      {'Punkt', 'Komma', 'Fragezeichen', 'Klammer'}
    ),
    'Was bedeutet "flüstern"?': (
      'Leise sprechen',
      {'Laut sprechen', 'Leise sprechen', 'Schreien', 'Singen'}
    ),
    'Was bedeutet "trauern"?': (
      'Traurig sein',
      {'Sich freuen', 'Traurig sein', 'Lachen', 'Singen'}
    ),
    'Wie heißt die Hauptstadt von Österreich?': (
      'Wien',
      {'Salzburg', 'Linz', 'Wien', 'Graz'}
    ),
    'Wie heißt die Hauptstadt von Deutschland?': (
      'Berlin',
      {'München', 'Berlin', 'Hamburg', 'Köln'}
    ),
    'Welches ist das größte Tier der Erde?': (
      'Blauwal',
      {'Elefant', 'Giraffe', 'Blauwal', 'Bär'}
    ),
    'Auf welchen Kontinenten leben heute wildlebende Löwen?': (
      'Afrika und Asien',
      {'Nur Europa', 'Afrika und Asien', 'Nur Amerika', 'Nur Australien'}
    ),
    'Wie viele Planeten hat unser Sonnensystem?': ('8', {'7', '8', '9', '12'}),
    'Was ist die Sonne?': (
      'Ein Stern',
      {'Ein Planet', 'Ein Stern', 'Ein Mond', 'Ein Komet'}
    ),
    'Welches Gas aus der Atemluft braucht unser Körper zum Leben?': (
      'Sauerstoff',
      {'Wasser', 'Stickstoff', 'Sauerstoff', 'Kohlendioxid'}
    ),
    'Wie viele Knochen hat ein Erwachsener etwa?': (
      '200',
      {'100', '150', '200', '250'}
    ),
    'Welches Organ pumpt das Blut?': (
      'Herz',
      {'Lunge', 'Magen', 'Herz', 'Leber'}
    ),
    'Wie heißt der längste Fluss in Österreich?': (
      'Donau',
      {'Donau', 'Inn', 'Mur', 'Drau'}
    ),
    'Lumo steht vor Mia. Mia steht vor Tom. Wer steht ganz vorne?': (
      'Lumo',
      {'Tom', 'Mia', 'Lumo', 'Alle gleich'}
    ),
    'Mia ist älter als Tom. Tom ist älter als Lea. Wer ist am jüngsten?': (
      'Lea',
      {'Mia', 'Tom', 'Lea', 'Alle gleich alt'}
    ),
  };
}

class _ChoiceRule {
  _ChoiceRule(this.accepts, {this.allowed});
  final bool Function(String) accepts;
  final Set<String>? allowed;
}
