import 'dart:math';

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
    ],
    'Rechtschreibung': <String>[
      'Haeufige Woerter',
      'Gross und klein',
      'Doppelmitlaut',
      'Dehnungen',
      'Satzzeichen',
      'Wortende',
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
      'Saetze lesen',
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
      'Koerper',
    ],
    'Sachunterricht': <String>[
      'Tiere',
      'Pflanzen',
      'Jahreszeiten',
      'Koerper',
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
    final units = Curriculum.subjects[chosenSubject] ?? Curriculum.subjects['Mathematik']!;
    final candidateUnits = unit == 'Alle' ? units.where((u) => !avoidUnits.contains(u)).toList() : <String>[unit];
    final chosenUnit = candidateUnits.isEmpty ? units[_random.nextInt(units.length)] : _weightedUnit(candidateUnits, weakSkills);
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
      final task = next(grade: grade, subject: subject, weakSkills: weakSkills, avoidUnits: usedUnits);
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
    final subjects = <String>['Mathematik', 'Deutsch', 'Lesen', 'Rechtschreibung', 'Englisch', 'Sachunterricht', 'Schreiben'];
    final tasks = <LumoTask>[];
    final avoid = <String>{};
    for (var i = 0; i < count; i++) {
      final subject = i < subjects.length ? subjects[i] : subjects[_random.nextInt(subjects.length)];
      tasks.add(next(grade: grade, subject: subject, weakSkills: weakSkills, avoidUnits: avoid));
      avoid.add(tasks.last.unit);
      if (avoid.length > 10) avoid.clear();
    }
    tasks.shuffle(_random);
    return tasks;
  }

  String _chooseSubject(String requested, Map<String, int> weakSkills) {
    if (requested != 'Alle') return requested;
    if (weakSkills.isNotEmpty && _random.nextDouble() < .60) {
      final weakUnit = weakSkills.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final subject in Curriculum.subjects.entries) {
        if (subject.value.contains(weakUnit.first.key)) return subject.key;
      }
    }
    final base = <String>['Mathematik', 'Deutsch', 'Lesen', 'Rechtschreibung', 'Englisch', 'Sachunterricht', 'Schreiben'];
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

  LumoTask _build({required int grade, required String subject, required String unit}) {
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

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_serial-${_random.nextInt(99999)}';

  LumoTask _math(int grade, String unit) {
    final maxSmall = grade == 1 ? 10 : 20;
    if (unit.contains('Plus')) {
      final max = unit.contains('100') ? 100 : unit.contains('20') ? 20 : maxSmall;
      final a = 1 + _random.nextInt(max ~/ 2);
      final b = 1 + _random.nextInt(max - a);
      final answer = a + b;
      return _choiceTask('mathe', grade, 'Mathematik', unit, '$a + $b = ?', answer.toString(), 'Lege zuerst $a. Lege dann $b dazu. Zaehle zusammen: $answer.', visual: 'dots');
    }
    if (unit.contains('Minus')) {
      final max = unit.contains('100') ? 100 : unit.contains('20') ? 20 : maxSmall;
      final a = 2 + _random.nextInt(max - 1);
      final b = 1 + _random.nextInt(a - 1);
      final answer = a - b;
      return _choiceTask('mathe', grade, 'Mathematik', unit, '$a - $b = ?', answer.toString(), 'Starte bei $a und gehe $b Schritte zurueck. Du landest bei $answer.', visual: 'line');
    }
    if (unit == 'Zahlenreihe') {
      final start = _random.nextInt(12) + 1;
      final step = <int>[2, 3, 5, 10][_random.nextInt(4)];
      final answer = start + step * 3;
      return _choiceTask('reihe', grade, 'Mathematik', unit, '$start, ${start + step}, ${start + step * 2}, ?', answer.toString(), 'Die Reihe springt immer um $step weiter.', visual: 'sequence');
    }
    if (unit == 'Nachbarzahlen') {
      final n = 2 + _random.nextInt(grade == 1 ? 18 : 98);
      final before = _random.nextBool();
      return _choiceTask('nachbar', grade, 'Mathematik', unit, before ? 'Welche Zahl kommt direkt vor $n?' : 'Welche Zahl kommt direkt nach $n?', before ? '${n - 1}' : '${n + 1}', before ? 'Zaehle einen Schritt zurueck: ${n - 1}.' : 'Zaehle einen Schritt weiter: ${n + 1}.');
    }
    if (unit == 'Zehner und Einer') {
      final tens = 1 + _random.nextInt(9);
      final ones = _random.nextInt(10);
      final n = tens * 10 + ones;
      final askTens = _random.nextBool();
      return _choiceTask('zehner', grade, 'Mathematik', unit, askTens ? 'Wie viele Zehner hat $n?' : 'Wie viele Einer hat $n?', askTens ? '$tens' : '$ones', '$n besteht aus $tens Zehnern und $ones Einern.');
    }
    if (unit == 'Verdoppeln und Halbieren') {
      final n = 1 + _random.nextInt(10);
      if (_random.nextBool()) return _choiceTask('doppelt', grade, 'Mathematik', unit, 'Was ist das Doppelte von $n?', '${n * 2}', 'Doppelt bedeutet: $n + $n = ${n * 2}.');
      final even = (1 + _random.nextInt(10)) * 2;
      return _choiceTask('halb', grade, 'Mathematik', unit, 'Was ist die Haelfte von $even?', '${even ~/ 2}', 'Halbieren bedeutet in zwei gleich grosse Teile teilen.');
    }
    if (unit == 'Geometrie Formen') {
      final shapes = <String, String>{'Welche Form hat 3 Ecken?': 'Dreieck', 'Welche Form ist ganz rund?': 'Kreis', 'Welche Form hat 4 gleich lange Seiten?': 'Quadrat'};
      final entry = shapes.entries.elementAt(_random.nextInt(shapes.length));
      return _choiceTask('form', grade, 'Mathematik', unit, entry.key, entry.value, 'Schau auf Ecken und Seiten der Form.', visual: 'shape');
    }
    if (unit == 'Uhrzeit') {
      final hour = 1 + _random.nextInt(11);
      return _choiceTask('uhr', grade, 'Mathematik', unit, 'Der kleine Zeiger steht auf $hour. Wie viel Uhr ist es?', '$hour Uhr', 'Der kleine Zeiger zeigt die Stunde.');
    }
    if (unit == 'Geld') {
      final a = 1 + _random.nextInt(8);
      final b = 1 + _random.nextInt(8);
      return _choiceTask('geld', grade, 'Mathematik', unit, 'Du hast $a Euro und bekommst $b Euro dazu. Wie viel hast du?', '${a + b} Euro', 'Rechne $a + $b = ${a + b}.');
    }
    if (unit == 'Vergleichen') {
      final a = 1 + _random.nextInt(99);
      final b = 1 + _random.nextInt(99);
      final ans = a > b ? '>' : a < b ? '<' : '=';
      return _choiceTask('vergleich', grade, 'Mathematik', unit, 'Welches Zeichen passt? $a ? $b', ans, 'Vergleiche zuerst die groessere Zahl.');
    }
    if (unit == 'Gerade und ungerade') {
      final n = 1 + _random.nextInt(50);
      final ans = n.isEven ? 'gerade' : 'ungerade';
      return _choiceTask('gerade', grade, 'Mathematik', unit, 'Ist $n gerade oder ungerade?', ans, 'Gerade Zahlen kann man in zwei gleiche Gruppen teilen.');
    }
    if (unit == 'Zahlen zerlegen') {
      final n = 5 + _random.nextInt(15);
      final a = 1 + _random.nextInt(n - 1);
      return _choiceTask('zerlegen', grade, 'Mathematik', unit, '$n = $a + ?', '${n - a}', 'Suche die fehlende Zahl, damit zusammen $n entsteht.');
    }
    final apples = 2 + _random.nextInt(8);
    final more = 1 + _random.nextInt(6);
    return _choiceTask('text', grade, 'Mathematik', 'Textaufgaben', 'Lumo hat $apples Sterne und bekommt $more dazu. Wie viele Sterne hat er?', '${apples + more}', 'Das ist eine Plusgeschichte: $apples + $more = ${apples + more}.');
  }

  LumoTask _german(int grade, String unit) {
    const words = <String>['Mama', 'Mond', 'Sonne', 'Ball', 'Fuchs', 'Haus', 'Rose', 'Apfel', 'Schule', 'Banane', 'Igel', 'Lampe'];
    final word = words[_random.nextInt(words.length)];
    if (unit == 'Anfangslaute') {
      final first = word.substring(0, 1).toUpperCase();
      return _choiceTask('laut', grade, 'Deutsch', unit, 'Mit welchem Laut beginnt $word?', first, 'Sprich $word langsam. Der erste Laut ist $first.');
    }
    if (unit == 'Endlaute') {
      final last = word.substring(word.length - 1).toLowerCase();
      return _choiceTask('endlaut', grade, 'Deutsch', unit, 'Mit welchem Laut endet $word?', last, 'Sprich $word langsam. Der letzte Laut ist $last.');
    }
    if (unit == 'Buchstaben') {
      final letter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[_random.nextInt(26)];
      return LumoTask(id: _id('buchstabe'), grade: grade, subject: 'Deutsch', unit: unit, prompt: 'Zeichne ein grosses $letter.', choices: const <String>['Fertig'], answer: 'Fertig', explanation: 'Ziehe den Buchstaben langsam mit dem Finger nach.', handwriting: true, visual: 'writing');
    }
    if (unit == 'Silben') {
      final items = <String, int>{'Banane': 3, 'Mama': 2, 'Schokolade': 4, 'Fuchs': 1, 'Tomate': 3, 'Elefant': 3, 'Schule': 2, 'Rakete': 3};
      final entry = items.entries.elementAt(_random.nextInt(items.length));
      return _choiceTask('silben', grade, 'Deutsch', unit, 'Wie viele Silben hat ${entry.key}?', '${entry.value}', 'Sprich das Wort langsam und klatsche jeden Teil.', visual: 'syllables');
    }
    if (unit == 'Reime') {
      final pairs = <String, String>{'Haus': 'Maus', 'Ball': 'Fall', 'Hase': 'Nase', 'Sonne': 'Tonne', 'Kanne': 'Tanne'};
      final entry = pairs.entries.elementAt(_random.nextInt(pairs.length));
      return _choiceTask('reim', grade, 'Deutsch', unit, 'Was reimt sich auf ${entry.key}?', entry.value, 'Reimwoerter klingen am Ende gleich.');
    }
    if (unit == 'Artikel') {
      final articles = <String, String>{'Haus': 'das', 'Sonne': 'die', 'Ball': 'der', 'Blume': 'die', 'Kind': 'das', 'Fuchs': 'der'};
      final entry = articles.entries.elementAt(_random.nextInt(articles.length));
      return _choiceTask('artikel', grade, 'Deutsch', unit, 'Welcher Artikel passt zu ${entry.key}?', entry.value, 'Sprich den Artikel mit dem Wort zusammen.');
    }
    if (unit == 'Tunwoerter') {
      final verbs = <String>['laufen', 'malen', 'lesen', 'springen', 'essen'];
      final verb = verbs[_random.nextInt(verbs.length)];
      return _choiceTask('verb', grade, 'Deutsch', unit, 'Welches Wort ist ein Tunwort?', verb, 'Ein Tunwort sagt, was jemand macht.');
    }
    if (unit == 'Wiewoerter') {
      final adj = <String>['gross', 'klein', 'warm', 'schnell', 'weich'];
      final answer = adj[_random.nextInt(adj.length)];
      return _choiceTask('adjektiv', grade, 'Deutsch', unit, 'Welches Wort beschreibt, wie etwas ist?', answer, 'Ein Wiewort beschreibt eine Eigenschaft.');
    }
    if (unit == 'Satz bauen') {
      return _choiceTask('satzbau', grade, 'Deutsch', unit, 'Welcher Satz ist richtig?', 'Der Fuchs liest.', 'Ein Satz beginnt gross und endet mit einem Punkt.', customChoices: <String>['Der Fuchs liest.', 'liest der Fuchs', 'Fuchs der liest']);
    }
    return _choiceTask('satz', grade, 'Deutsch', 'Satz verstehen', 'Der Fuchs liest ein Buch. Was macht der Fuchs?', 'lesen', 'Suche im Satz das Tunwort.');
  }

  LumoTask _spelling(int grade, String unit) {
    final words = grade == 1 ? <String>['und', 'ist', 'Mama', 'Papa', 'Haus', 'Ball', 'Sonne'] : <String>['spielen', 'kommen', 'Schule', 'Freund', 'heute', 'klein', 'gross'];
    final correct = words[_random.nextInt(words.length)];
    if (unit == 'Gross und klein') {
      final nouns = <String>['Haus', 'Kind', 'Fuchs', 'Schule', 'Blume'];
      final noun = nouns[_random.nextInt(nouns.length)];
      return _choiceTask('gross', grade, 'Rechtschreibung', unit, 'Wie schreibt man das Namenwort richtig?', noun, 'Namenwoerter schreibt man gross.');
    }
    if (unit == 'Satzzeichen') {
      return _choiceTask('punkt', grade, 'Rechtschreibung', unit, 'Welches Zeichen kommt am Ende von: Lumo liest', '.', 'Ein Aussagesatz endet mit einem Punkt.');
    }
    if (unit == 'Doppelmitlaut') {
      return _choiceTask('doppel', grade, 'Rechtschreibung', unit, 'Welche Schreibweise ist richtig?', 'kommen', 'Bei kommen hoerst du kurz o, darum mm.', customChoices: <String>['komen', 'kommen', 'komenn']);
    }
    if (unit == 'Wortende') {
      return _choiceTask('ende', grade, 'Rechtschreibung', unit, 'Welches Wort endet mit t?', 'Hund', 'Sprich das Wort langsam bis zum letzten Laut.', customChoices: <String>['Hund', 'Hase', 'Mama']);
    }
    final wrong = correct.toLowerCase();
    return _choiceTask('wort', grade, 'Rechtschreibung', unit, 'Welche Schreibweise ist richtig?', correct, 'Schau jeden Buchstaben langsam an.', customChoices: <String>[correct, wrong, '${correct}e']);
  }

  LumoTask _writing(int grade, String unit) {
    final letters = <String>['A', 'M', 'O', 'S', 'L', 'E', 'F', 'B', 'N', 'T'];
    final letter = letters[_random.nextInt(letters.length)];
    if (unit == 'Wort schreiben') {
      final words = <String>['Mama', 'Lumo', 'Haus', 'Sonne', 'Fuchs'];
      final word = words[_random.nextInt(words.length)];
      return LumoTask(id: _id('schreiben'), grade: grade, subject: 'Schreiben', unit: unit, prompt: 'Schreibe das Wort: $word', choices: const <String>['Fertig'], answer: 'Fertig', explanation: 'Schreibe langsam Buchstabe fuer Buchstabe.', handwriting: true, visual: 'writing');
    }
    if (unit == 'Zahlen schreiben') {
      final n = _random.nextInt(10);
      return LumoTask(id: _id('zahlspur'), grade: grade, subject: 'Schreiben', unit: unit, prompt: 'Schreibe die Zahl $n.', choices: const <String>['Fertig'], answer: 'Fertig', explanation: 'Ziehe die Zahl ruhig mit dem Finger.', handwriting: true, visual: 'writing');
    }
    if (unit == 'Satz abschreiben') {
      return LumoTask(id: _id('satzspur'), grade: grade, subject: 'Schreiben', unit: unit, prompt: 'Schreibe: Lumo lernt.', choices: const <String>['Fertig'], answer: 'Fertig', explanation: 'Schreibe Wort fuer Wort langsam ab.', handwriting: true, visual: 'writing');
    }
    return LumoTask(id: _id('spur'), grade: grade, subject: 'Schreiben', unit: unit, prompt: 'Spure den Buchstaben $letter nach.', choices: const <String>['Fertig'], answer: 'Fertig', explanation: 'Beginne oben und fahre langsam die Form nach.', handwriting: true, visual: 'writing');
  }

  LumoTask _reading(int grade, String unit) {
    if (unit == 'Bild und Wort') return _choiceTask('bildwort', grade, 'Lesen', unit, 'Welches Wort passt zum Tier 🦊?', 'Fuchs', 'Das Bild zeigt einen Fuchs.');
    if (unit == 'Reihenfolge') return _choiceTask('folge', grade, 'Lesen', unit, 'Was kommt zuerst: Schuhe anziehen oder hinausgehen?', 'Schuhe anziehen', 'Ueberlege, was im Alltag zuerst passiert.');
    final sentences = <String, String>{'Lumo malt einen Stern.': 'malt', 'Der Hund rennt.': 'rennt', 'Mia liest.': 'liest', 'Oma backt Kuchen.': 'backt'};
    final entry = sentences.entries.elementAt(_random.nextInt(sentences.length));
    return _choiceTask('lesen', grade, 'Lesen', unit, '${entry.key} Was passiert?', entry.value, 'Lies den Satz langsam und suche, was getan wird.');
  }

  LumoTask _english(int grade, String unit) {
    final data = <String, Map<String, String>>{
      'Farben': <String, String>{'red': 'Rot', 'blue': 'Blau', 'green': 'Gruen', 'yellow': 'Gelb'},
      'Zahlen': <String, String>{'one': 'eins', 'two': 'zwei', 'three': 'drei', 'four': 'vier', 'five': 'fuenf'},
      'Tiere': <String, String>{'cat': 'Katze', 'dog': 'Hund', 'fox': 'Fuchs', 'bird': 'Vogel'},
      'Schulsachen': <String, String>{'book': 'Buch', 'pen': 'Stift', 'bag': 'Tasche'},
      'Begruessung': <String, String>{'hello': 'Hallo', 'bye': 'Tschuess', 'good morning': 'Guten Morgen'},
      'Familie': <String, String>{'mum': 'Mama', 'dad': 'Papa', 'sister': 'Schwester'},
      'Koerper': <String, String>{'hand': 'Hand', 'foot': 'Fuss', 'eye': 'Auge'},
    };
    final map = data[unit] ?? data['Tiere']!;
    final entry = map.entries.elementAt(_random.nextInt(map.length));
    return _choiceTask('englisch', grade, 'Englisch', unit, 'Was heisst ${entry.key}?', entry.value, '${entry.key} bedeutet ${entry.value}.', visual: 'english');
  }

  LumoTask _science(int grade, String unit) {
    final questions = <String, Map<String, String>>{
      'Tiere': <String, String>{'Welches Tier legt Eier?': 'Huhn', 'Welches Tier lebt im Wasser?': 'Fisch'},
      'Pflanzen': <String, String>{'Was braucht eine Pflanze zum Wachsen?': 'Wasser', 'Was ist meist gruen an der Pflanze?': 'Blatt'},
      'Jahreszeiten': <String, String>{'Wann faellt oft Schnee?': 'Winter', 'Wann bluehen viele Blumen?': 'Fruehling'},
      'Koerper': <String, String>{'Womit sehen wir?': 'Augen', 'Womit hoeren wir?': 'Ohren'},
      'Verkehr': <String, String>{'Bei welcher Ampelfarbe darf man gehen?': 'Gruen'},
      'Wetter': <String, String>{'Was faellt aus Wolken?': 'Regen'},
      'Familie und Gemeinschaft': <String, String>{'Was sagt man, wenn man Hilfe bekommt?': 'Danke'},
      'Zeit und Kalender': <String, String>{'Welcher Tag kommt nach Montag?': 'Dienstag'},
    };
    final map = questions[unit] ?? questions['Tiere']!;
    final entry = map.entries.elementAt(_random.nextInt(map.length));
    return _choiceTask('sach', grade, 'Sachunterricht', unit, entry.key, entry.value, 'Denke an deinen Alltag und waehle die passende Antwort.');
  }

  LumoTask _choiceTask(String prefix, int grade, String subject, String unit, String prompt, String answer, String explanation, {String visual = 'auto', List<String>? customChoices}) {
    final choices = customChoices ?? _choices(answer);
    choices.shuffle(_random);
    return LumoTask(id: _id(prefix), grade: grade, subject: subject, unit: unit, prompt: prompt, choices: choices, answer: answer, explanation: explanation, visual: visual, difficulty: grade);
  }

  List<String> _choices(String answer) {
    final number = int.tryParse(answer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (number != null) {
      final set = <String>{answer, '${number + 1}', '${(number - 1).clamp(0, 999)}'};
      while (set.length < 3) set.add('${number + 2 + set.length}');
      return set.toList();
    }
    final pool = <String>['Katze', 'Hund', 'Haus', 'Blau', 'Rot', 'eins', 'zwei', 'lesen', 'laufen', 'Fuchs', 'Wasser', 'Winter', 'Gruen', 'Maus', 'Dreieck', 'Kreis', 'Mama', 'Papa'];
    final set = <String>{answer};
    while (set.length < 3) {
      set.add(pool[_random.nextInt(pool.length)]);
    }
    return set.toList();
  }
}
