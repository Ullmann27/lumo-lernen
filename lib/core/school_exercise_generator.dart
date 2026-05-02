import 'dart:math';

import 'primary_school_word_data.dart';

class LumoTask {
  const LumoTask({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.prompt,
    required this.choices,
    required this.answer,
    required this.explanation,
    this.handwriting = false,
    this.visual = 'auto',
    this.difficulty = 1,
    this.missionTag = 'normal',
  });

  final String id;
  final int grade;
  final String subject;
  final String unit;
  final String prompt;
  final List<String> choices;
  final String answer;
  final String explanation;
  final bool handwriting;
  final String visual;
  final int difficulty;
  final String missionTag;
}

class Curriculum {
  static const Map<String, List<String>> subjects = <String, List<String>>{
    'Mathematik': <String>[
      'Plus bis 10',
      'Minus bis 10',
      'Plus bis 20',
      'Minus bis 20',
      'Plus bis 100',
      'Minus bis 100',
      'Zahlenreihe',
      'Nachbarzahlen',
      'Zehner und Einer',
      'Verdoppeln und Halbieren',
      'Textaufgaben',
      'Geometrie Formen',
      'Uhrzeit',
      'Geld',
      'Vergleichen',
      'Gerade und ungerade',
      'Zahlen zerlegen',
      'Minus ueber 10',
      'Rechenhaeuser',
      'Blitzlicht',
    ],
    'Deutsch': <String>[
      'Anfangslaute',
      'Endlaute',
      'Buchstaben',
      'Silben',
      'Reime',
      'Wortschatz',
      'Satz verstehen',
      'Artikel',
      'Namenwoerter',
      'Tunwoerter',
      'Wiewoerter',
      'Satz bauen',
      'St oder Sp',
      'Einzahl und Mehrzahl',
      'Wort-Bild schreiben',
    ],
    'Rechtschreibung': <String>[
      'Haeufige Woerter',
      'Gross und klein',
      'Doppelmitlaut',
      'Dehnungen',
      'Satzzeichen',
      'Wortende',
      'St oder Sp',
    ],
    'Schreiben': <String>[
      'Buchstaben nachspuren',
      'Wort schreiben',
      'Satz abschreiben',
      'Schwunguebung',
      'Zahlen schreiben',
    ],
    'Lesen': <String>[
      'Woerter lesen',
      'Sätze lesen',
      'Lesesinn',
      'Bild und Wort',
      'Reihenfolge',
    ],
    'Englisch': <String>[
      'Farben',
      'Zahlen',
      'Tiere',
      'Schulsachen',
      'Begruessung',
      'Familie',
      'Körper',
    ],
    'Sachunterricht': <String>[
      'Tiere',
      'Pflanzen',
      'Jahreszeiten',
      'Körper',
      'Verkehr',
      'Wetter',
      'Familie und Gemeinschaft',
      'Zeit und Kalender',
    ],
  };
}

class ExerciseFactory {
  ExerciseFactory({int? seed}) : _random = Random(seed);

  final Random _random;
  int _serial = 0;

  LumoTask next({
    required int grade,
    String subject = 'Alle',
    String unit = 'Alle',
    Map<String, int> weakSkills = const <String, int>{},
    Set<String> avoidUnits = const <String>{},
  }) {
    final chosenSubject = _chooseSubject(subject, weakSkills);
    final units =
        Curriculum.subjects[chosenSubject] ?? Curriculum.subjects['Mathematik']!;
    final candidateUnits = unit == 'Alle'
        ? units.where((u) => !avoidUnits.contains(u)).toList()
        : <String>[unit];
    final chosenUnit = candidateUnits.isEmpty
        ? units[_random.nextInt(units.length)]
        : _weightedUnit(candidateUnits, weakSkills);
    return _build(grade: grade, subject: chosenSubject, unit: chosenUnit);
  }

  List<LumoTask> buildSession({
    required int grade,
    required int count,
    String subject = 'Alle',
    Map<String, int> weakSkills = const <String, int>{},
  }) {
    final tasks = <LumoTask>[];
    final usedUnits = <String>{};
    for (var i = 0; i < count; i++) {
      final task = next(
        grade: grade,
        subject: subject,
        weakSkills: weakSkills,
        avoidUnits: usedUnits,
      );
      tasks.add(task);
      usedUnits.add(task.unit);
      if (usedUnits.length > 12) usedUnits.clear();
    }
    return tasks;
  }

  List<LumoTask> buildBalancedSchoolwork({
    required int grade,
    required Map<String, int> weakSkills,
    int count = 14,
  }) {
    final subjects = <String>[
      'Mathematik',
      'Deutsch',
      'Lesen',
      'Rechtschreibung',
      'Englisch',
      'Sachunterricht',
      'Schreiben',
    ];
    final tasks = <LumoTask>[];
    final avoid = <String>{};
    for (var i = 0; i < count; i++) {
      final subject =
          i < subjects.length ? subjects[i] : subjects[_random.nextInt(subjects.length)];
      tasks.add(
        next(
          grade: grade,
          subject: subject,
          weakSkills: weakSkills,
          avoidUnits: avoid,
        ),
      );
      avoid.add(tasks.last.unit);
      if (avoid.length > 10) avoid.clear();
    }
    tasks.shuffle(_random);
    return tasks;
  }

  String _chooseSubject(String requested, Map<String, int> weakSkills) {
    if (requested != 'Alle') return requested;
    if (weakSkills.isNotEmpty && _random.nextDouble() < .60) {
      final weakUnit = weakSkills.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final subject in Curriculum.subjects.entries) {
        if (subject.value.contains(weakUnit.first.key)) return subject.key;
      }
    }
    final base = <String>[
      'Mathematik',
      'Deutsch',
      'Lesen',
      'Rechtschreibung',
      'Sachunterricht',
      'Schreiben',
    ];
    return base[_random.nextInt(base.length)];
  }

  String _weightedUnit(List<String> units, Map<String, int> weakSkills) {
    final weighted = <String>[];
    for (final unit in units) {
      weighted.add(unit);
      final extra = weakSkills[unit] ?? 0;
      for (var i = 0; i < extra.clamp(0, 6); i++) {
        weighted.add(unit);
      }
    }
    return weighted[_random.nextInt(weighted.length)];
  }

  LumoTask _build({
    required int grade,
    required String subject,
    required String unit,
  }) {
    _serial++;
    switch (subject) {
      case 'Mathematik':
        return _math(grade, unit);
      case 'Deutsch':
        return _german(grade, unit);
      case 'Rechtschreibung':
        return _spelling(grade, unit);
      case 'Schreiben':
        return _writing(grade, unit);
      case 'Lesen':
        return _reading(grade, unit);
      case 'Englisch':
        return _english(grade, unit);
      case 'Sachunterricht':
        return _science(grade, unit);
      default:
        return _math(grade, unit);
    }
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_serial-${_random.nextInt(99999)}';

  LumoTask _math(int grade, String unit) {
    final maxSmall = grade == 1 ? 10 : 20;
    if (unit == 'Minus ueber 10') return _minusBridgeTen(grade, unit);
    if (unit == 'Rechenhaeuser') return _numberHouse(grade, unit);
    if (unit == 'Blitzlicht') return _blitzlicht(grade, unit);

    if (unit.contains('Plus')) {
      final max = unit.contains('100')
          ? 100
          : unit.contains('20')
              ? 20
              : maxSmall;
      final a = 1 + _random.nextInt(max ~/ 2);
      final b = 1 + _random.nextInt(max - a);
      final answer = a + b;
      return _choiceTask(
        'mathe',
        grade,
        'Mathematik',
        unit,
        '$a + $b = ?',
        '$answer',
        'Lege zuerst $a. Lege dann $b dazu. Zaehle zusammen: $answer.',
        visual: 'dots',
      );
    }

    if (unit.contains('Minus')) {
      if (unit.contains('20') && _random.nextDouble() < .65) {
        return _minusBridgeTen(grade, unit);
      }
      final max = unit.contains('100')
          ? 100
          : unit.contains('20')
              ? 20
              : maxSmall;
      final a = 2 + _random.nextInt(max - 1);
      final b = 1 + _random.nextInt(a - 1);
      final answer = a - b;
      return _choiceTask(
        'mathe',
        grade,
        'Mathematik',
        unit,
        '$a - $b = ?',
        '$answer',
        'Starte bei $a und gehe $b Schritte zurueck. Du landest bei $answer.',
        visual: 'line',
      );
    }

    if (unit == 'Zahlenreihe') {
      final start = _random.nextInt(12) + 1;
      final step = <int>[2, 3, 5, 10][_random.nextInt(4)];
      final answer = start + step * 3;
      return _choiceTask(
        'reihe',
        grade,
        'Mathematik',
        unit,
        '$start, ${start + step}, ${start + step * 2}, ?',
        '$answer',
        'Die Reihe springt immer um $step weiter.',
        visual: 'sequence',
      );
    }

    if (unit == 'Nachbarzahlen') {
      final n = 2 + _random.nextInt(grade == 1 ? 18 : 98);
      final before = _random.nextBool();
      return _choiceTask(
        'nachbar',
        grade,
        'Mathematik',
        unit,
        before
            ? 'Welche Zahl kommt direkt vor $n?'
            : 'Welche Zahl kommt direkt nach $n?',
        before ? '${n - 1}' : '${n + 1}',
        before
            ? 'Zaehle einen Schritt zurueck: ${n - 1}.'
            : 'Zaehle einen Schritt weiter: ${n + 1}.',
      );
    }

    if (unit == 'Zehner und Einer') {
      final tens = 1 + _random.nextInt(9);
      final ones = _random.nextInt(10);
      final n = tens * 10 + ones;
      final askTens = _random.nextBool();
      return _choiceTask(
        'zehner',
        grade,
        'Mathematik',
        unit,
        askTens ? 'Wie viele Zehner hat $n?' : 'Wie viele Einer hat $n?',
        askTens ? '$tens' : '$ones',
        '$n besteht aus $tens Zehnern und $ones Einern.',
        visual: 'ten_ones',
      );
    }

    if (unit == 'Verdoppeln und Halbieren') {
      final n = 1 + _random.nextInt(10);
      if (_random.nextBool()) {
        return _choiceTask(
          'doppelt',
          grade,
          'Mathematik',
          unit,
          'Was ist das Doppelte von $n?',
          '${n * 2}',
          'Doppelt bedeutet: $n + $n = ${n * 2}.',
        );
      }
      final even = (1 + _random.nextInt(10)) * 2;
      return _choiceTask(
        'halb',
        grade,
        'Mathematik',
        unit,
        'Was ist die Hälfte von $even?',
        '${even ~/ 2}',
        'Halbieren bedeutet in zwei gleich große Teile teilen.',
      );
    }

    if (unit == 'Geometrie Formen') {
      final shapes = <String, String>{
        'Welche Form hat 3 Ecken?': 'Dreieck',
        'Welche Form ist ganz rund?': 'Kreis',
        'Welche Form hat 4 gleich lange Seiten?': 'Quadrat',
      };
      final entry = shapes.entries.elementAt(_random.nextInt(shapes.length));
      return _choiceTask(
        'form',
        grade,
        'Mathematik',
        unit,
        entry.key,
        entry.value,
        'Schau auf Ecken und Seiten der Form.',
        visual: 'shape',
      );
    }

    if (unit == 'Uhrzeit') {
      final hour = 1 + _random.nextInt(11);
      return _choiceTask(
        'uhr',
        grade,
        'Mathematik',
        unit,
        'Der kleine Zeiger steht auf $hour. Wie viel Uhr ist es?',
        '$hour Uhr',
        'Der kleine Zeiger zeigt die Stunde.',
      );
    }

    if (unit == 'Geld') {
      final a = 1 + _random.nextInt(8);
      final b = 1 + _random.nextInt(8);
      return _choiceTask(
        'geld',
        grade,
        'Mathematik',
        unit,
        'Du hast $a Euro und bekommst $b Euro dazu. Wie viel hast du?',
        '${a + b} Euro',
        'Rechne $a + $b = ${a + b}.',
      );
    }

    if (unit == 'Vergleichen') {
      final a = 1 + _random.nextInt(99);
      final b = 1 + _random.nextInt(99);
      final ans = a > b
          ? '>'
          : a < b
              ? '<'
              : '=';
      return _choiceTask(
        'vergleich',
        grade,
        'Mathematik',
        unit,
        'Welches Zeichen passt? $a ? $b',
        ans,
        'Vergleiche zuerst die groessere Zahl.',
        customChoices: const <String>['<', '>', '='],
      );
    }

    if (unit == 'Gerade und ungerade') {
      final n = 1 + _random.nextInt(50);
      final ans = n.isEven ? 'gerade' : 'ungerade';
      return _choiceTask(
        'gerade',
        grade,
        'Mathematik',
        unit,
        'Ist $n gerade oder ungerade?',
        ans,
        'Gerade Zahlen kann man in zwei gleiche Gruppen teilen.',
        customChoices: const <String>['gerade', 'ungerade'],
      );
    }

    if (unit == 'Zahlen zerlegen') return _numberHouse(grade, unit);

    final apples = 2 + _random.nextInt(8);
    final more = 1 + _random.nextInt(6);
    return _choiceTask(
      'text',
      grade,
      'Mathematik',
      'Textaufgaben',
      'Lumo hat $apples Sterne und bekommt $more dazu. Wie viele Sterne hat er?',
      '${apples + more}',
      'Das ist eine Plusgeschichte: $apples + $more = ${apples + more}.',
    );
  }

  LumoTask _minusBridgeTen(int grade, String unit) {
    final start = 11 + _random.nextInt(9);
    final toTen = start - 10;
    final rest = 1 + _random.nextInt(9 - toTen);
    final takeAway = toTen + rest;
    final answer = start - takeAway;
    return _choiceTask(
      'minus10',
      grade,
      'Mathematik',
      unit,
      '$start - $takeAway = ?',
      '$answer',
      'Rechne wie im Heft: Erst $toTen weg bis zur 10. Dann noch $rest weg. Also $start - $toTen - $rest = $answer.',
      visual: 'line',
    );
  }

  LumoTask _numberHouse(int grade, String unit) {
    final target = grade == 1 ? 5 + _random.nextInt(6) : 10 + _random.nextInt(11);
    final left = _random.nextInt(target + 1);
    final answer = target - left;
    return _choiceTask(
      'haus',
      grade,
      'Mathematik',
      unit,
      'Rechenhaus $target: $left + ? = $target',
      '$answer',
      'Das Dach sagt $target. Im Zimmer steht $left. Die fehlende Zahl ist $answer, denn $left + $answer = $target.',
      visual: 'number_house',
    );
  }

  LumoTask _blitzlicht(int grade, String unit) {
    final a = 10 + _random.nextInt(10);
    final b = 1 + _random.nextInt(9);
    final minus = _random.nextBool();
    final answer = minus ? a - b : a + b;
    return _choiceTask(
      'blitz',
      grade,
      'Mathematik',
      unit,
      'Blitzlicht: ${minus ? '$a - $b' : '$a + $b'} = ?',
      '$answer',
      'Blitzlicht heisst: kurz schauen, ruhig rechnen, dann antworten.',
      visual: 'blitz_grid',
    );
  }

  LumoTask _german(int grade, String unit) {
    if (unit == 'St oder Sp') return _stOrSp(grade, 'Deutsch');
    if (unit == 'Einzahl und Mehrzahl') return _pluralTask(grade, 'Deutsch');
    if (unit == 'Wort-Bild schreiben') return _wordImageWriting(grade);

    if (unit == 'Anfangslaute') {
      final word = PrimarySchoolWordData.firstSoundWordForGrade(
            grade,
            seed: _serial + _random.nextInt(9999),
          ) ??
          PrimarySchoolWordData.nounForGrade(grade, _serial);
      final first = word.substring(0, 1).toUpperCase();
      return _choiceTask(
        'laut',
        grade,
        'Deutsch',
        unit,
        'Mit welchem Laut beginnt $word?',
        first,
        'Sprich $word langsam. Der erste Laut ist $first.',
        customChoices: _soundChoices(first, uppercase: true),
      );
    }

    if (unit == 'Endlaute') {
      final word = PrimarySchoolWordData.endSoundWordForGrade(
            grade,
            seed: _serial + _random.nextInt(9999),
          ) ??
          PrimarySchoolWordData.nounForGrade(grade, _serial);
      final last = word.substring(word.length - 1).toLowerCase();
      return _choiceTask(
        'endlaut',
        grade,
        'Deutsch',
        unit,
        'Mit welchem Laut endet $word?',
        last,
        'Sprich $word langsam. Der letzte Laut ist $last.',
        customChoices: _soundChoices(last, uppercase: false),
      );
    }

    if (unit == 'Buchstaben') {
      final letter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[_random.nextInt(26)];
      return LumoTask(
        id: _id('buchstabe'),
        grade: grade,
        subject: 'Deutsch',
        unit: unit,
        prompt: 'Zeichne ein großes $letter.',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: 'Ziehe den Buchstaben langsam mit dem Finger nach.',
        handwriting: true,
        visual: 'writing',
      );
    }

    if (unit == 'Silben') {
      final word = _wordWithSyllablesForGrade(grade);
      final syllables = PrimarySchoolWordData.syllablesFor(word) ?? <String>[word];
      final answer = '${syllables.length}';
      return _choiceTask(
        'silben',
        grade,
        'Deutsch',
        unit,
        'Wie viele Silben hat $word?',
        answer,
        'Sprich das Wort langsam und klatsche jeden Teil.',
        visual: 'syllables',
        customChoices: _numberChoices(syllables.length, min: 1, max: 5),
      );
    }

    if (unit == 'Reime') {
      final pair = PrimarySchoolWordData.rhymePairForSeed(
        _serial + _random.nextInt(9999),
      );
      final questionWord = pair.first;
      final answer = pair.last;
      final distractors = _pickDistinct(
        PrimarySchoolWordData.nounsForGrade(grade),
        count: 2,
        exclude: <String>{questionWord, answer},
      );
      return _choiceTask(
        'reim',
        grade,
        'Deutsch',
        unit,
        'Was reimt sich auf $questionWord?',
        answer,
        'Reimwörter klingen am Ende gleich.',
        customChoices: <String>[answer, ...distractors],
      );
    }

    if (unit == 'Artikel') {
      final words = PrimarySchoolWordData.articles.keys.toList();
      final word = words[(_serial + _random.nextInt(9999)) % words.length];
      final answer = PrimarySchoolWordData.articleFor(word) ?? 'der';
      return _choiceTask(
        'artikel',
        grade,
        'Deutsch',
        unit,
        'Welcher Artikel passt zu $word?',
        answer,
        'Sprich den Artikel mit dem Wort zusammen.',
        customChoices: const <String>['der', 'die', 'das'],
      );
    }

    if (unit == 'Tunwoerter') {
      final answer = PrimarySchoolWordData.verbForSeed(
        _serial + _random.nextInt(9999),
      );
      final distractors = _pickDistinct(
        <String>[
          ...PrimarySchoolWordData.nounsForGrade(grade),
          ...PrimarySchoolWordData.adjectives,
        ],
        count: 2,
        exclude: <String>{answer},
      );
      return _choiceTask(
        'verb',
        grade,
        'Deutsch',
        unit,
        'Welches Wort ist ein Tunwort?',
        answer,
        'Ein Tunwort sagt, was jemand macht.',
        customChoices: <String>[answer, ...distractors],
      );
    }

    if (unit == 'Wiewoerter') {
      final answer = PrimarySchoolWordData.adjectiveForSeed(
        _serial + _random.nextInt(9999),
      );
      final distractors = _pickDistinct(
        <String>[
          ...PrimarySchoolWordData.nounsForGrade(grade),
          ...PrimarySchoolWordData.verbs,
        ],
        count: 2,
        exclude: <String>{answer},
      );
      return _choiceTask(
        'adjektiv',
        grade,
        'Deutsch',
        unit,
        'Welches Wort beschreibt, wie etwas ist?',
        answer,
        'Ein Wiewort beschreibt eine Eigenschaft.',
        customChoices: <String>[answer, ...distractors],
      );
    }

    if (unit == 'Satz bauen') {
      final noun = PrimarySchoolWordData.nounForGrade(
        grade,
        _serial + _random.nextInt(9999),
      );
      final article = PrimarySchoolWordData.articleFor(noun) ?? 'das';
      final verb = PrimarySchoolWordData.verbForSeed(
        _serial + _random.nextInt(9999),
      );
      final correct = '${_capitalize(article)} $noun $verb.';
      return _choiceTask(
        'satzbau',
        grade,
        'Deutsch',
        unit,
        'Welcher Satz ist richtig?',
        correct,
        'Ein Satz beginnt groß und endet mit einem Punkt.',
        customChoices: <String>[
          correct,
          '$verb $article $noun',
          '$noun $article $verb',
        ],
      );
    }

    if (unit == 'Namenwoerter' ||
        unit == 'Namenswoerter' ||
        unit == 'Hauptwoerter') {
      final answer = PrimarySchoolWordData.nounForGrade(
        grade,
        _serial + _random.nextInt(9999),
      );
      final distractors = _pickDistinct(
        <String>[
          ...PrimarySchoolWordData.verbs,
          ...PrimarySchoolWordData.adjectives,
        ],
        count: 2,
        exclude: <String>{answer},
      );
      return _choiceTask(
        'nomen',
        grade,
        'Deutsch',
        unit,
        'Welches Wort ist ein Namenswort?',
        answer,
        'Namenswörter sind Dinge, Personen oder Tiere und werden groß geschrieben.',
        customChoices: <String>[answer, ...distractors],
      );
    }

    return _sentenceUnderstanding(grade, unit);
  }

  LumoTask _sentenceUnderstanding(int grade, String unit) {
    final noun = PrimarySchoolWordData.nounForGrade(
      grade,
      _serial + _random.nextInt(9999),
    );
    final article = PrimarySchoolWordData.articleFor(noun) ?? 'das';
    final verb = PrimarySchoolWordData.verbForSeed(
      _serial + _random.nextInt(9999),
    );
    final adjective = PrimarySchoolWordData.adjectiveForSeed(
      _serial + _random.nextInt(9999),
    );
    final distractors = _pickDistinct(
      <String>[noun, adjective, ...PrimarySchoolWordData.nounsForGrade(grade)],
      count: 2,
      exclude: <String>{verb},
    );
    final sentence = '${_capitalize(article)} $noun $verb $adjective.';
    return _choiceTask(
      'satz',
      grade,
      'Deutsch',
      unit == 'Wortschatz' ? 'Wortschatz' : 'Satz verstehen',
      '$sentence Was macht $article $noun?',
      verb,
      'Suche im Satz das Tunwort.',
      customChoices: <String>[verb, ...distractors],
    );
  }

  LumoTask _spelling(int grade, String unit) {
    if (unit == 'St oder Sp') return _stOrSp(grade, 'Rechtschreibung');
    final words = grade == 1
        ? <String>['und', 'ist', 'Mama', 'Papa', 'Haus', 'Ball', 'Sonne']
        : <String>['spielen', 'kommen', 'Schule', 'Freund', 'heute', 'klein', 'gross'];
    final correct = words[_random.nextInt(words.length)];
    if (unit == 'Gross und klein') {
      final noun = PrimarySchoolWordData.nounForGrade(grade, _serial);
      return _choiceTask(
        'gross',
        grade,
        'Rechtschreibung',
        unit,
        'Wie schreibt man das Namenwort richtig?',
        noun,
        'Namenwoerter schreibt man gross.',
      );
    }
    if (unit == 'Satzzeichen') {
      return _choiceTask(
        'punkt',
        grade,
        'Rechtschreibung',
        unit,
        'Welches Zeichen kommt am Ende von: Lumo liest',
        '.',
        'Ein Aussagesatz endet mit einem Punkt.',
        customChoices: const <String>['.', '?', '!'],
      );
    }
    if (unit == 'Doppelmitlaut') {
      return _choiceTask(
        'doppel',
        grade,
        'Rechtschreibung',
        unit,
        'Welche Schreibweise ist richtig?',
        'kommen',
        'Bei kommen hoerst du kurz o, darum mm.',
        customChoices: const <String>['komen', 'kommen', 'komenn'],
      );
    }
    if (unit == 'Wortende') {
      return _choiceTask(
        'ende',
        grade,
        'Rechtschreibung',
        unit,
        'Welches Wort endet mit t?',
        'Brot',
        'Sprich das Wort langsam bis zum letzten Laut. Brot endet mit t.',
        customChoices: const <String>['Brot', 'Rose', 'Maus'],
      );
    }
    return _choiceTask(
      'wort',
      grade,
      'Rechtschreibung',
      unit,
      'Welche Schreibweise ist richtig?',
      correct,
      'Schau jeden Buchstaben langsam an.',
      customChoices: <String>[correct, correct.toLowerCase(), '${correct}e'],
    );
  }

  LumoTask _stOrSp(int grade, String subject) {
    const data = <String, String>{
      'Stern': 'St',
      'Storch': 'St',
      'Stift': 'St',
      'Stein': 'St',
      'Spiegel': 'Sp',
      'Spinne': 'Sp',
      'Sport': 'Sp',
      'Spaten': 'Sp',
    };
    final entry = data.entries.elementAt(_random.nextInt(data.length));
    return _choiceTask(
      'stsp',
      grade,
      subject,
      'St oder Sp',
      'St oder Sp? ${entry.key}',
      entry.value,
      'Sprich den Anfang langsam. Hoerst du St oder Sp?',
      visual: 'sound_choice',
      customChoices: const <String>['St', 'Sp'],
    );
  }

  LumoTask _pluralTask(int grade, String subject) {
    const data = <String, String>{
      'Schwan': 'Schwaene',
      'Glas': 'Glaeser',
      'Haus': 'Haeuser',
      'Kind': 'Kinder',
      'Blume': 'Blumen',
      'Ball': 'Baelle',
    };
    final entry = data.entries.elementAt(_random.nextInt(data.length));
    return _choiceTask(
      'plural',
      grade,
      subject,
      'Einzahl und Mehrzahl',
      'Aus 1 mach 2: ${entry.key} -> ?',
      entry.value,
      'Aus einem Wort fuer eins wird ein Wort fuer mehrere. Sprich beide Woerter langsam.',
      visual: 'writing_line',
      customChoices: <String>[entry.value, entry.key, '${entry.key}e'],
    );
  }

  LumoTask _wordImageWriting(int grade) {
    const data = <String, String>{
      '🏠': 'Haus',
      '🦊': 'Fuchs',
      '☀️': 'Sonne',
      '🌹': 'Rose',
      '🍎': 'Apfel',
    };
    final entry = data.entries.elementAt(_random.nextInt(data.length));
    final choices = _pickDistinct(
      PrimarySchoolWordData.nounsForGrade(grade),
      count: 3,
      exclude: <String>{entry.value},
    );
    return _choiceTask(
      'bildwort',
      grade,
      'Deutsch',
      'Wort-Bild schreiben',
      'Welches Wort passt zum Bild ${entry.key}?',
      entry.value,
      'Schau das Bild an und lies das passende Wort langsam.',
      visual: 'writing_line',
      customChoices: <String>[entry.value, ...choices.take(2)],
    );
  }

  LumoTask _writing(int grade, String unit) {
    final letters = <String>['A', 'M', 'O', 'S', 'L', 'E', 'F', 'B', 'N', 'T'];
    final letter = letters[_random.nextInt(letters.length)];
    if (unit == 'Wort schreiben') {
      final word = PrimarySchoolWordData.nounForGrade(grade, _serial);
      return LumoTask(
        id: _id('schreiben'),
        grade: grade,
        subject: 'Schreiben',
        unit: unit,
        prompt: 'Schreibe das Wort: $word',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: 'Schreibe langsam Buchstabe fuer Buchstabe.',
        handwriting: true,
        visual: 'writing',
      );
    }
    if (unit == 'Zahlen schreiben') {
      final n = _random.nextInt(10);
      return LumoTask(
        id: _id('zahlspur'),
        grade: grade,
        subject: 'Schreiben',
        unit: unit,
        prompt: 'Schreibe die Zahl $n.',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: 'Ziehe die Zahl ruhig mit dem Finger.',
        handwriting: true,
        visual: 'writing',
      );
    }
    if (unit == 'Satz abschreiben') {
      return LumoTask(
        id: _id('satzspur'),
        grade: grade,
        subject: 'Schreiben',
        unit: unit,
        prompt: 'Schreibe: Lumo lernt.',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: 'Schreibe Wort fuer Wort langsam ab.',
        handwriting: true,
        visual: 'writing',
      );
    }
    return LumoTask(
      id: _id('spur'),
      grade: grade,
      subject: 'Schreiben',
      unit: unit,
      prompt: 'Zeichne ein großes $letter.',
      choices: const <String>['Fertig'],
      answer: 'Fertig',
      explanation: 'Ziehe die Linie langsam und ruhig nach.',
      handwriting: true,
      visual: 'writing',
    );
  }

  LumoTask _reading(int grade, String unit) {
    final noun = PrimarySchoolWordData.nounForGrade(
      grade,
      _serial + _random.nextInt(9999),
    );
    final article = PrimarySchoolWordData.articleFor(noun) ?? 'das';
    final verb = PrimarySchoolWordData.verbForSeed(_serial + _random.nextInt(9999));

    if (unit == 'Woerter lesen' || unit == 'Bild und Wort') {
      return _choiceTask(
        'lesenwort',
        grade,
        'Lesen',
        unit,
        'Lies das Wort: $noun',
        noun,
        'Schau jeden Buchstaben an und lies langsam.',
        customChoices: <String>[
          noun,
          ..._pickDistinct(
            PrimarySchoolWordData.nounsForGrade(grade),
            count: 2,
            exclude: <String>{noun},
          ),
        ],
      );
    }

    if (unit == 'Reihenfolge') {
      final correct = '${_capitalize(article)} $noun $verb.';
      return _choiceTask(
        'reihenfolge',
        grade,
        'Lesen',
        unit,
        'Welche Reihenfolge ergibt einen Satz?',
        correct,
        'Ein Satz hat eine sinnvolle Reihenfolge.',
        customChoices: <String>[correct, '$verb $article $noun', '$noun $verb $article'],
      );
    }

    final sentence = '${_capitalize(article)} $noun $verb.';
    return _choiceTask(
      'lesesinn',
      grade,
      'Lesen',
      unit,
      '$sentence Was passiert im Satz?',
      verb,
      'Lies den Satz noch einmal und suche das Tunwort.',
      customChoices: <String>[verb, noun, article],
    );
  }

  LumoTask _english(int grade, String unit) {
    const data = <String, Map<String, String>>{
      'Farben': <String, String>{'red': 'rot', 'blue': 'blau', 'green': 'gruen'},
      'Zahlen': <String, String>{'one': 'eins', 'two': 'zwei', 'three': 'drei'},
      'Tiere': <String, String>{'dog': 'Hund', 'cat': 'Katze', 'bird': 'Vogel'},
      'Schulsachen': <String, String>{'pen': 'Stift', 'book': 'Buch', 'bag': 'Tasche'},
      'Begruessung': <String, String>{'hello': 'hallo', 'bye': 'tschüss', 'thanks': 'danke'},
      'Familie': <String, String>{'mum': 'Mama', 'dad': 'Papa', 'child': 'Kind'},
      'Körper': <String, String>{'hand': 'Hand', 'foot': 'Fuß', 'head': 'Kopf'},
    };
    final bank = data[unit] ?? data['Farben']!;
    final entry = bank.entries.elementAt(_random.nextInt(bank.length));
    return _choiceTask(
      'englisch',
      grade,
      'Englisch',
      unit,
      'Was bedeutet ${entry.key}?',
      entry.value,
      'Lies das englische Wort und denke an die Bedeutung.',
      customChoices: <String>[entry.value, ...bank.values.where((v) => v != entry.value).take(2)],
    );
  }

  LumoTask _science(int grade, String unit) {
    final questions = <String, Map<String, String>>{
      'Tiere': <String, String>{'Welches Tier kann fliegen?': 'Vogel'},
      'Pflanzen': <String, String>{'Was braucht eine Pflanze zum Wachsen?': 'Wasser'},
      'Jahreszeiten': <String, String>{'Wann schmilzt oft der Schnee?': 'Fruehling'},
      'Körper': <String, String>{'Womit hoerst du?': 'Ohren'},
      'Verkehr': <String, String>{'Bei welcher Farbe bleibst du stehen?': 'Rot'},
      'Wetter': <String, String>{'Was faellt aus einer Wolke?': 'Regen'},
      'Familie und Gemeinschaft': <String, String>{'Was hilft in der Gruppe?': 'teilen'},
      'Zeit und Kalender': <String, String>{'Was kommt nach Montag?': 'Dienstag'},
    };
    final bank = questions[unit] ?? questions['Tiere']!;
    final entry = bank.entries.first;
    return _choiceTask(
      'sach',
      grade,
      'Sachunterricht',
      unit,
      entry.key,
      entry.value,
      'Denke an Alltag und Schule.',
      customChoices: <String>[entry.value, 'Sonne', 'Stift'],
    );
  }

  LumoTask _choiceTask(
    String prefix,
    int grade,
    String subject,
    String unit,
    String prompt,
    String answer,
    String explanation, {
    String visual = 'auto',
    List<String>? customChoices,
  }) {
    final choices = customChoices == null
        ? _numericOrWordChoices(answer)
        : _distinctChoices(<String>[answer, ...customChoices]);
    choices.shuffle(_random);
    return LumoTask(
      id: _id(prefix),
      grade: grade,
      subject: subject,
      unit: unit,
      prompt: prompt,
      choices: choices,
      answer: answer,
      explanation: explanation,
      visual: visual,
    );
  }

  List<String> _numericOrWordChoices(String answer) {
    final n = int.tryParse(answer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (n != null) return _numberChoices(n);
    return _distinctChoices(<String>[answer, 'Blume', 'Kerze', 'Biene']);
  }

  List<String> _numberChoices(int answer, {int min = 0, int max = 120}) {
    final values = <String>{'$answer'};
    for (final delta in <int>[1, -1, 2, -2, 3]) {
      if (values.length >= 3) break;
      final value = (answer + delta).clamp(min, max).toInt();
      values.add('$value');
    }
    return values.toList();
  }

  List<String> _soundChoices(String answer, {required bool uppercase}) {
    final bank = uppercase
        ? const <String>['A', 'B', 'D', 'F', 'K', 'L', 'M', 'R', 'S', 'T']
        : const <String>['a', 'e', 'l', 'n', 'r', 's', 't', 'd', 'm', 'f'];
    return _distinctChoices(<String>[answer, ...bank]).take(3).toList();
  }

  List<String> _distinctChoices(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (result.any((item) => item.trim().toLowerCase() == normalized)) continue;
      result.add(value);
      if (result.length >= 4) break;
    }
    while (result.length < 3) {
      result.add('Antwort ${result.length + 1}');
    }
    return result;
  }

  List<String> _pickDistinct(
    List<String> pool, {
    required int count,
    Set<String> exclude = const <String>{},
  }) {
    final normalizedExclude = exclude.map((e) => e.toLowerCase()).toSet();
    final shuffled = List<String>.from(pool)..shuffle(_random);
    final result = <String>[];
    for (final item in shuffled) {
      if (result.length >= count) break;
      if (normalizedExclude.contains(item.toLowerCase())) continue;
      if (result.any((existing) => existing.toLowerCase() == item.toLowerCase())) {
        continue;
      }
      result.add(item);
    }
    return result;
  }

  String _wordWithSyllablesForGrade(int grade) {
    final words = List<String>.from(PrimarySchoolWordData.nounsForGrade(grade))
      ..shuffle(_random);
    for (final word in words) {
      final syllables = PrimarySchoolWordData.syllablesFor(word);
      if (syllables != null && syllables.isNotEmpty) return word;
    }
    return PrimarySchoolWordData.nounForGrade(grade, _serial);
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value.substring(0, 1).toUpperCase() + value.substring(1);
  }
}

class _SatzbauVariant {
  const _SatzbauVariant(this.correct, this.wrong1, this.wrong2);

  final String correct;
  final String wrong1;
  final String wrong2;
}
