import 'dart:math';

import 'german_task_templates.dart';
import 'math_task_templates.dart';
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
      'Plus bis 10', 'Minus bis 10', 'Plus bis 20', 'Minus bis 20',
      'Plus bis 100', 'Minus bis 100', 'Zahlenstrahl', 'Mengenvergleich',
      'Zahl in Worten', 'Geometrie Formen', 'Geld', 'Zeit', 'Symmetrie',
      'Einmaleins Vorbereitung', 'Geld wechseln', 'Uhrzeit', 'Längen',
      'Gerade und ungerade', 'Verdoppeln und Halbieren', 'Zehner und Einer',
      'Einmaleins', 'Schriftliche Addition', 'Schriftliche Subtraktion',
      'Brüche Vorbereitung', 'Sachaufgaben zwei Schritte', 'Umfang',
      'Flächeninhalt', 'Schriftliche Multiplikation', 'Schriftliche Division',
      'Bruchrechnen einfach', 'Dezimalzahlen', 'Sachaufgaben drei Schritte',
      'Diagramme lesen', 'Textaufgaben', 'Vergleichen', 'Zahlenreihe',
      'Nachbarzahlen', 'Zahlen zerlegen', 'Minus ueber 10', 'Rechenhaeuser',
      'Blitzlicht',
    ],
    'Deutsch': <String>[
      'Buchstaben-Lautierung', 'Anfangslaute', 'Endlaute', 'Buchstaben',
      'Silben', 'Reime', 'Wort-Bild-Zuordnung', 'Erste Sätze', 'Artikel',
      'Wortfamilien', 'Einzahl und Mehrzahl', 'Verkleinerungsform',
      'Gegenteile', 'Oberbegriffe', 'Synonyme', 'Wortarten', 'Zeitformen',
      'Steigerung', 'Verbformen', 'Satzglieder', 'Direkte Rede',
      'Kommas in Aufzählungen', 'Zusammensetzungen', 'Wortschatz',
      'Satz verstehen', 'Namenwoerter', 'Tunwoerter', 'Wiewoerter',
      'Satz bauen', 'St oder Sp', 'Wort-Bild schreiben',
    ],
    'Rechtschreibung': <String>[
      'Haeufige Woerter', 'Gross und klein', 'Doppelmitlaut', 'Dehnungen',
      'Satzzeichen', 'Wortende', 'St oder Sp',
    ],
    'Schreiben': <String>[
      'Buchstaben nachspuren', 'Wort schreiben', 'Satz abschreiben',
      'Schwunguebung', 'Zahlen schreiben',
    ],
    'Lesen': <String>['Woerter lesen', 'Sätze lesen', 'Lesesinn', 'Bild und Wort', 'Reihenfolge'],
    'Englisch': <String>['Farben', 'Zahlen', 'Tiere', 'Schulsachen', 'Begruessung', 'Familie', 'Körper'],
    'Sachunterricht': <String>[
      'Tiere', 'Pflanzen', 'Jahreszeiten', 'Körper', 'Verkehr', 'Wetter',
      'Familie und Gemeinschaft', 'Zeit und Kalender', 'Berufe', 'Ernährung',
      'Wasserkreislauf', 'Bundesländer Österreichs', 'Geografie Österreich',
      'Geschichte', 'Kontinente und Ozeane', 'Ökosysteme', 'Stromkreise',
      'Diagramme lesen',
    ],
  };

  /// Wandelt einen Unit-Key (mit "ue", "ae", "oe", "ss" als Code-stabile
  /// Schreibweise) in die hubsche Display-Form mit echten Umlauten um.
  /// Die internen Keys bleiben erhalten, sodass alle vorhandenen
  /// Lookup-Tables (math_task_templates, german_task_templates etc.)
  /// weiterhin matchen.
  ///
  /// Beispiel: "Rechenhaeuser" -> "Rechenhäuser", "Gross und klein"
  /// -> "Groß und klein", "Begruessung" -> "Begrüßung".
  static String prettifyUnit(String key) {
    const map = <String, String>{
      'Minus ueber 10': 'Minus über 10',
      'Rechenhaeuser': 'Rechenhäuser',
      'Haeufige Woerter': 'Häufige Wörter',
      'Gross und klein': 'Groß und klein',
      'Schwunguebung': 'Schwungübung',
      'Begruessung': 'Begrüßung',
      'Namenwoerter': 'Namenwörter',
      'Tunwoerter': 'Tunwörter',
      'Wiewoerter': 'Wiewörter',
      'Woerter lesen': 'Wörter lesen',
      'Namenswoerter': 'Namenswörter',
      'Hauptwoerter': 'Hauptwörter',
    };
    return map[key] ?? key;
  }
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
    return _build(grade: grade.clamp(1, 4).toInt(), subject: chosenSubject, unit: chosenUnit);
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
    final base = <String>['Mathematik', 'Deutsch', 'Lesen', 'Rechtschreibung', 'Sachunterricht', 'Schreiben'];
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
    final seed = _serial + _random.nextInt(9999);
    final generated = MathTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return LumoTask(
      id: _id('mathe-${generated.promptPattern}'),
      grade: grade,
      subject: 'Mathematik',
      unit: generated.unit,
      prompt: generated.prompt,
      choices: _shuffledChoices(generated.choices),
      answer: generated.answer,
      explanation: generated.explanation,
      visual: generated.visual,
      difficulty: generated.difficulty,
    );
  }

  LumoTask _german(int grade, String unit) {
    if (unit == 'St oder Sp') return _stOrSp(grade, 'Deutsch');
    final seed = _serial + _random.nextInt(9999);
    final generated = GermanTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    final outputUnit = unit == 'Namenswoerter' || unit == 'Hauptwoerter' ? unit : generated.unit;
    return LumoTask(
      id: _id('deutsch-${generated.promptPattern}'),
      grade: grade,
      subject: 'Deutsch',
      unit: outputUnit,
      prompt: generated.prompt,
      choices: _shuffledChoices(generated.choices),
      answer: generated.answer,
      explanation: generated.explanation,
      visual: generated.visual,
      difficulty: generated.difficulty,
    );
  }

  LumoTask _science(int grade, String unit) {
    final seed = _serial + _random.nextInt(9999);
    final capped = grade.clamp(1, 4).toInt();
    final pool = _scienceQuestions.where((question) {
      final unitMatches = unit == 'Alle' || question.unit == unit || _scienceAliases[unit]?.contains(question.unit) == true;
      return question.grade <= capped && unitMatches;
    }).toList(growable: false);
    final source = pool.isEmpty ? _scienceQuestions.where((question) => question.grade <= capped).toList(growable: false) : pool;
    final question = source[_positive(seed, source.length)];
    return LumoTask(
      id: _id('sach-${question.unit}'),
      grade: grade,
      subject: 'Sachunterricht',
      unit: question.unit,
      prompt: question.prompt,
      choices: _shuffledChoices(<String>[question.answer, ...question.choices.where((choice) => choice != question.answer)]),
      answer: question.answer,
      explanation: question.explanation,
      visual: 'science',
      difficulty: question.grade,
    );
  }

  LumoTask _spelling(int grade, String unit) {
    if (unit == 'St oder Sp') return _stOrSp(grade, 'Rechtschreibung');
    if (unit == 'Gross und klein') {
      final noun = PrimarySchoolWordData.nounForGrade(grade, _serial + _random.nextInt(9999));
      return _choiceTask('gross', grade, 'Rechtschreibung', unit, 'Wie schreibt man das Namenwort richtig?', noun, 'Namenwörter schreibt man groß.', customChoices: <String>[noun, noun.toLowerCase(), _decapitalize(noun)]);
    }
    if (unit == 'Satzzeichen') {
      return _choiceTask('punkt', grade, 'Rechtschreibung', unit, 'Welches Zeichen kommt am Ende von: Lumo liest', '.', 'Ein Aussagesatz endet mit einem Punkt.', customChoices: const <String>['.', '?', '!']);
    }
    if (unit == 'Doppelmitlaut') {
      return _choiceTask('doppel', grade, 'Rechtschreibung', unit, 'Welche Schreibweise ist richtig?', 'kommen', 'Bei kommen hörst du ein kurzes o, darum mm.', customChoices: const <String>['komen', 'kommen', 'komenn']);
    }
    final word = PrimarySchoolWordData.nounForGrade(grade, _serial + _random.nextInt(9999));
    return _choiceTask('wort', grade, 'Rechtschreibung', unit, 'Welche Schreibweise ist richtig?', word, 'Schau jeden Buchstaben langsam an.', customChoices: _spellingChoicesFor(word));
  }

  LumoTask _stOrSp(int grade, String subject) {
    const data = <String, String>{'Stern': 'St', 'Storch': 'St', 'Stift': 'St', 'Stein': 'St', 'Spiegel': 'Sp', 'Spinne': 'Sp', 'Sport': 'Sp', 'Spaten': 'Sp'};
    final entry = data.entries.elementAt(_random.nextInt(data.length));
    return _choiceTask('stsp', grade, subject, 'St oder Sp', 'Was hörst du am Anfang von ${entry.key}?', entry.value, 'Sprich das Wort langsam: ${entry.key}.', customChoices: const <String>['St', 'Sp', 'Sch']);
  }

  LumoTask _writing(int grade, String unit) {
    if (unit == 'Zahlen schreiben') {
      final n = 1 + _random.nextInt(grade == 1 ? 20 : 100);
      return LumoTask(id: _id('zahl-schreiben'), grade: grade, subject: 'Schreiben', unit: unit, prompt: 'Schreibe die Zahl $n schön und langsam.', choices: const <String>['Fertig'], answer: 'Fertig', explanation: 'Beginne oben und achte auf die Richtung.', handwriting: true, visual: 'writing');
    }
    final word = PrimarySchoolWordData.nounForGrade(grade, _serial + _random.nextInt(9999));
    return LumoTask(id: _id('wort-schreiben'), grade: grade, subject: 'Schreiben', unit: unit, prompt: 'Schreibe: $word', choices: const <String>['Fertig'], answer: 'Fertig', explanation: 'Sprich das Wort in Silben und schreibe Teil für Teil.', handwriting: true, visual: 'writing');
  }

  LumoTask _reading(int grade, String unit) {
    final noun = PrimarySchoolWordData.nounForGrade(grade, _serial + _random.nextInt(9999));
    final article = PrimarySchoolWordData.articleFor(noun) ?? 'das';
    final sentence = '${_capitalize(article)} $noun ist im Bild.';
    if (unit == 'Lesesinn') {
      return _choiceTask('lesesinn', grade, 'Lesen', unit, '$sentence Was ist im Bild?', noun, 'Lies den Satz bis zum Punkt.', customChoices: <String>[noun, PrimarySchoolWordData.nounForGrade(grade, _serial + 3), PrimarySchoolWordData.nounForGrade(grade, _serial + 5)]);
    }
    return _choiceTask('lesen', grade, 'Lesen', unit, 'Lies das Wort: $noun. Welcher Artikel passt?', article, 'Sprich Artikel und Wort zusammen.', customChoices: const <String>['der', 'die', 'das']);
  }

  LumoTask _english(int grade, String unit) {
    const data = <String, Map<String, String>>{
      'Farben': <String, String>{'red': 'rot', 'blue': 'blau', 'green': 'grün', 'yellow': 'gelb'},
      'Zahlen': <String, String>{'one': 'eins', 'two': 'zwei', 'three': 'drei', 'four': 'vier'},
      'Tiere': <String, String>{'dog': 'Hund', 'cat': 'Katze', 'bird': 'Vogel', 'fish': 'Fisch'},
      'Schulsachen': <String, String>{'book': 'Buch', 'pen': 'Stift', 'bag': 'Tasche', 'ruler': 'Lineal'},
      'Begruessung': <String, String>{'hello': 'hallo', 'goodbye': 'auf Wiedersehen', 'please': 'bitte', 'thanks': 'danke'},
      'Familie': <String, String>{'mother': 'Mutter', 'father': 'Vater', 'sister': 'Schwester', 'brother': 'Bruder'},
      'Körper': <String, String>{'hand': 'Hand', 'foot': 'Fuß', 'eye': 'Auge', 'ear': 'Ohr'},
    };
    final map = data[unit] ?? data['Farben']!;
    final entry = map.entries.elementAt(_random.nextInt(map.length));
    return _choiceTask('englisch', grade, 'Englisch', unit, 'Was bedeutet „${entry.key}“?', entry.value, 'Das englische Wort „${entry.key}“ bedeutet ${entry.value}.', customChoices: map.values.toList(growable: false));
  }

  LumoTask _choiceTask(String prefix, int grade, String subject, String unit, String prompt, String answer, String explanation, {String visual = 'auto', List<String>? customChoices}) {
    final choices = _buildChoices(answer, customChoices);
    return LumoTask(id: _id(prefix), grade: grade, subject: subject, unit: unit, prompt: prompt, choices: choices, answer: answer, explanation: explanation, visual: visual, difficulty: grade);
  }

  List<String> _buildChoices(String answer, List<String>? customChoices) {
    final choices = <String>[answer];
    final source = customChoices ?? <String>[answer, '0', '1', '2', '3'];
    for (final choice in source) {
      if (choice.trim().isNotEmpty && _normalizeChoice(choice) != _normalizeChoice(answer) && !choices.any((item) => _normalizeChoice(item) == _normalizeChoice(choice))) choices.add(choice);
      if (choices.length == 4) break;
    }
    if (_looksNumeric(answer)) {
      final value = int.tryParse(answer.replaceAll(RegExp('[^0-9-]'), ''));
      if (value != null) {
        for (final offset in <int>[1, -1, 2, -2, 5, -5]) {
          final candidate = '${value + offset}';
          if (!choices.any((item) => _normalizeChoice(item) == _normalizeChoice(candidate)) && value + offset >= 0) choices.add(candidate);
          if (choices.length == 4) break;
        }
      }
    }
    final fallback = <String>['ja', 'nein', 'vielleicht', 'anderes'];
    for (final item in fallback) {
      if (choices.length >= 3) break;
      if (!choices.any((choice) => _normalizeChoice(choice) == _normalizeChoice(item))) choices.add(item);
    }
    return _shuffledChoices(choices);
  }

  List<String> _shuffledChoices(List<String> choices) {
    final unique = <String>[];
    for (final choice in choices) {
      if (choice.trim().isNotEmpty && !unique.any((item) => _normalizeChoice(item) == _normalizeChoice(choice))) unique.add(choice);
    }
    unique.shuffle(_random);
    return unique;
  }

  List<String> _spellingChoicesFor(String correct) {
    final lower = correct.toLowerCase();
    final distractors = switch (lower) {
      'und' => const <String>['unt', 'un'],
      'ist' => const <String>['is', 'isst'],
      'mama' => const <String>['Mamma', 'Moma'],
      'papa' => const <String>['Pappa', 'Pupa'],
      'haus' => const <String>['Hauß', 'Has'],
      'ball' => const <String>['Bal', 'Bahl'],
      'sonne' => const <String>['Sone', 'Sonnee'],
      'spielen' => const <String>['spilen', 'schpielen'],
      'kommen' => const <String>['komen', 'komenn'],
      'schule' => const <String>['Schuhle', 'Schulee'],
      'freund' => const <String>['Froind', 'Freunt'],
      'heute' => const <String>['hoite', 'heude'],
      'klein' => const <String>['kline', 'kleinn'],
      'groß' || 'gross' => const <String>['gros', 'grohs'],
      _ => <String>[_dropLastLetter(correct), '${correct}e', '${correct}n'],
    };
    return _distinctChoices(correct, <String>[correct, ...distractors], targetCount: 3);
  }

  List<String> _distinctChoices(String answer, List<String> candidates, {required int targetCount}) {
    final result = <String>[];
    void add(String value) {
      if (value.trim().isEmpty) return;
      if (result.any((item) => _normalizeChoice(item) == _normalizeChoice(value))) return;
      result.add(value);
    }

    add(answer);
    for (final candidate in candidates) {
      if (result.length >= targetCount) break;
      add(candidate);
    }
    for (final candidate in <String>['${answer}e', '${answer}n', '${answer}m']) {
      if (result.length >= targetCount) break;
      add(candidate);
    }
    return result;
  }

  String _dropLastLetter(String value) => value.length <= 1 ? '$value?' : value.substring(0, value.length - 1);

  bool _looksNumeric(String value) => RegExp(r'^-?\d+').hasMatch(value);
  int _positive(int seed, int length) => length <= 1 ? 0 : (seed & 0x7fffffff) % length;
  String _capitalize(String value) => value.isEmpty ? value : value.substring(0, 1).toUpperCase() + value.substring(1);
  String _decapitalize(String value) => value.isEmpty ? value : value.substring(0, 1).toLowerCase() + value.substring(1);
  String _normalizeChoice(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

class _ScienceQuestion {
  const _ScienceQuestion({required this.grade, required this.unit, required this.prompt, required this.answer, required this.choices, required this.explanation});
  final int grade;
  final String unit;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
}

const Map<String, List<String>> _scienceAliases = <String, List<String>>{
  'Pflanzen': <String>['Pflanzen'],
  'Tiere': <String>['Tiere'],
  'Wetter': <String>['Wetter'],
  'Körper': <String>['Körper'],
  'Verkehr': <String>['Verkehr'],
  'Jahreszeiten': <String>['Jahreszeiten'],
};

const List<_ScienceQuestion> _scienceQuestions = <_ScienceQuestion>[
  _ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Vogel?', answer: 'Spatz', choices: <String>['Spatz', 'Kuh', 'Fisch', 'Ameise'], explanation: 'Ein Spatz hat Federn und Flügel.'),
  _ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Fisch?', answer: 'Forelle', choices: <String>['Forelle', 'Hund', 'Biene', 'Hase'], explanation: 'Fische leben im Wasser und haben Flossen.'),
  _ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Insekt?', answer: 'Biene', choices: <String>['Biene', 'Katze', 'Frosch', 'Schaf'], explanation: 'Insekten haben sechs Beine.'),
  _ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Säugetier?', answer: 'Hund', choices: <String>['Hund', 'Ente', 'Forelle', 'Käfer'], explanation: 'Säugetiere säugen ihre Jungen.'),
  _ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier lebt am Bauernhof?', answer: 'Kuh', choices: <String>['Kuh', 'Wal', 'Pinguin', 'Koralle'], explanation: 'Kühe leben häufig am Bauernhof.'),
  _ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'In welcher Jahreszeit fällt oft Schnee?', answer: 'Winter', choices: <String>['Winter', 'Sommer', 'Frühling', 'Herbst'], explanation: 'Im Winter ist es kalt, oft schneit es.'),
  _ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann blühen viele Blumen neu?', answer: 'Frühling', choices: <String>['Frühling', 'Winter', 'Herbst', 'Nacht'], explanation: 'Im Frühling beginnen viele Pflanzen zu blühen.'),
  _ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann sind die Tage oft heiß?', answer: 'Sommer', choices: <String>['Sommer', 'Winter', 'Herbst', 'Morgen'], explanation: 'Im Sommer ist es oft warm bis heiß.'),
  _ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann fallen viele bunte Blätter?', answer: 'Herbst', choices: <String>['Herbst', 'Sommer', 'Frühling', 'Mittag'], explanation: 'Im Herbst verfärben sich viele Blätter.'),
  _ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was fällt aus Wolken als Wasser?', answer: 'Regen', choices: <String>['Regen', 'Wind', 'Sonne', 'Nebel'], explanation: 'Regen besteht aus Wassertropfen.'),
  _ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was hörst du bei einem Gewitter?', answer: 'Donner', choices: <String>['Donner', 'Schnee', 'Nebel', 'Regenbogen'], explanation: 'Donner ist das laute Geräusch beim Gewitter.'),
  _ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was sieht man nach Regen und Sonne manchmal?', answer: 'Regenbogen', choices: <String>['Regenbogen', 'Frost', 'Nacht', 'Stein'], explanation: 'Ein Regenbogen entsteht durch Sonne und Regentropfen.'),
  _ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was bewegt Blätter in der Luft?', answer: 'Wind', choices: <String>['Wind', 'Mond', 'Sand', 'Eis'], explanation: 'Wind ist bewegte Luft.'),
  _ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was hat einen Stamm und Äste?', answer: 'Baum', choices: <String>['Baum', 'Blume', 'Stein', 'Fisch'], explanation: 'Ein Baum hat Stamm, Äste und Blätter.'),
  _ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was wächst oft bunt im Garten?', answer: 'Blume', choices: <String>['Blume', 'Auto', 'Hund', 'Sackerl'], explanation: 'Blumen blühen oft bunt.'),
  _ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Welcher Teil einer Pflanze ist meist grün?', answer: 'Blatt', choices: <String>['Blatt', 'Rad', 'Schuh', 'Ball'], explanation: 'Blätter sind oft grün und fangen Licht ein.'),
  _ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was braucht eine Pflanze zum Wachsen?', answer: 'Wasser', choices: <String>['Wasser', 'Fernseher', 'Schere', 'Helm'], explanation: 'Pflanzen brauchen Wasser, Licht und Erde.'),
  _ScienceQuestion(grade: 1, unit: 'Tag und Nacht', prompt: 'Wann ist es meistens dunkel?', answer: 'Nacht', choices: <String>['Nacht', 'Mittag', 'Sommer', 'Pause'], explanation: 'In der Nacht ist die Sonne nicht zu sehen.'),
  _ScienceQuestion(grade: 1, unit: 'Tag und Nacht', prompt: 'Was leuchtet am Tag hell am Himmel?', answer: 'Sonne', choices: <String>['Sonne', 'Tisch', 'Kuh', 'Schuh'], explanation: 'Die Sonne gibt Licht und Wärme.'),
  _ScienceQuestion(grade: 1, unit: 'Körper', prompt: 'Womit siehst du?', answer: 'Auge', choices: <String>['Auge', 'Ohr', 'Hand', 'Fuß'], explanation: 'Mit den Augen sehen wir.'),
  _ScienceQuestion(grade: 1, unit: 'Körper', prompt: 'Womit hörst du?', answer: 'Ohr', choices: <String>['Ohr', 'Nase', 'Knie', 'Bauch'], explanation: 'Mit den Ohren hören wir.'),
  _ScienceQuestion(grade: 1, unit: 'Verkehr', prompt: 'Bei welcher Ampelfarbe darf man gehen?', answer: 'Grün', choices: <String>['Grün', 'Rot', 'Blau', 'Schwarz'], explanation: 'Grün bedeutet: gehen, wenn der Weg frei ist.'),
  _ScienceQuestion(grade: 1, unit: 'Familie und Gemeinschaft', prompt: 'Was sagt man, wenn man Hilfe bekommt?', answer: 'Danke', choices: <String>['Danke', 'Stopp', 'Aua', 'Nein'], explanation: 'Danke ist höflich und freundlich.'),
  _ScienceQuestion(grade: 1, unit: 'Zeit und Kalender', prompt: 'Welcher Tag kommt nach Montag?', answer: 'Dienstag', choices: <String>['Dienstag', 'Sonntag', 'Freitag', 'Jänner'], explanation: 'Nach Montag kommt Dienstag.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Schwein?', answer: 'Ferkel', choices: <String>['Ferkel', 'Kalb', 'Fohlen', 'Lamm'], explanation: 'Ein junges Schwein heißt Ferkel.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby von der Kuh?', answer: 'Kalb', choices: <String>['Kalb', 'Ferkel', 'Küken', 'Fohlen'], explanation: 'Ein junges Rind heißt Kalb.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Pferd?', answer: 'Fohlen', choices: <String>['Fohlen', 'Kalb', 'Lamm', 'Küken'], explanation: 'Ein junges Pferd heißt Fohlen.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Huhn?', answer: 'Küken', choices: <String>['Küken', 'Ferkel', 'Kalb', 'Welpe'], explanation: 'Ein junges Huhn heißt Küken.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo lebt ein Fisch meistens?', answer: 'im Wasser', choices: <String>['im Wasser', 'im Baum', 'im Nest', 'im Heft'], explanation: 'Fische leben im Wasser.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo bauen viele Vögel ihr Nest?', answer: 'im Baum', choices: <String>['im Baum', 'im Schuh', 'im Topfen', 'im Bus'], explanation: 'Viele Vögel bauen Nester auf Bäumen.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo lebt der Fuchs häufig?', answer: 'im Wald', choices: <String>['im Wald', 'im Meer', 'im Federpennal', 'im Glas'], explanation: 'Füchse leben häufig im Wald.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Welches Tier sammelt Nektar?', answer: 'Biene', choices: <String>['Biene', 'Kuh', 'Hund', 'Forelle'], explanation: 'Bienen besuchen Blüten und sammeln Nektar.'),
  _ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welcher Pflanzenteil nimmt Wasser auf?', answer: 'Wurzel', choices: <String>['Wurzel', 'Blüte', 'Frucht', 'Ast'], explanation: 'Wurzeln nehmen Wasser aus der Erde auf.'),
  _ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welcher Teil trägt Blätter und Blüten?', answer: 'Stamm', choices: <String>['Stamm', 'Schuh', 'Kabel', 'Topf'], explanation: 'Der Stamm oder Stängel trägt andere Pflanzenteile.'),
  _ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Woraus kann eine neue Pflanze wachsen?', answer: 'Samen', choices: <String>['Samen', 'Stein', 'Münze', 'Knopf'], explanation: 'Aus Samen können neue Pflanzen wachsen.'),
  _ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Was lockt oft Bienen an?', answer: 'Blüte', choices: <String>['Blüte', 'Reifen', 'Buch', 'Helm'], explanation: 'Blüten locken Insekten an.'),
  _ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was bedeutet eine rote Ampel?', answer: 'stehen bleiben', choices: <String>['stehen bleiben', 'laufen', 'singen', 'springen'], explanation: 'Rot bedeutet Halt.'),
  _ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was bedeutet ein Stoppschild?', answer: 'anhalten', choices: <String>['anhalten', 'schneller fahren', 'hupen', 'umdrehen'], explanation: 'Bei Stopp muss man anhalten.'),
  _ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Wo überquert man sicherer die Straße?', answer: 'Zebrastreifen', choices: <String>['Zebrastreifen', 'Spielplatz', 'Wiese', 'Küche'], explanation: 'Ein Zebrastreifen hilft beim sicheren Überqueren.'),
  _ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was trägt man beim Radfahren zum Schutz?', answer: 'Helm', choices: <String>['Helm', 'Haube', 'Schal', 'Sackerl'], explanation: 'Ein Helm schützt den Kopf.'),
  _ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer löscht Brände?', answer: 'Feuerwehr', choices: <String>['Feuerwehr', 'Bäcker', 'Gärtner', 'Pilot'], explanation: 'Die Feuerwehr hilft bei Bränden.'),
  _ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer backt Semmeln und Brot?', answer: 'Bäckerin oder Bäcker', choices: <String>['Bäckerin oder Bäcker', 'Ärztin', 'Postler', 'Tischler'], explanation: 'Bäckerinnen und Bäcker backen Brot und Semmeln.'),
  _ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer hilft kranken Menschen?', answer: 'Ärztin oder Arzt', choices: <String>['Ärztin oder Arzt', 'Maurer', 'Pilotin', 'Schneider'], explanation: 'Ärztinnen und Ärzte behandeln kranke Menschen.'),
  _ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer bringt Briefe und Pakete?', answer: 'Postlerin oder Postler', choices: <String>['Postlerin oder Postler', 'Friseur', 'Koch', 'Lehrer'], explanation: 'Die Post stellt Briefe und Pakete zu.'),
  _ScienceQuestion(grade: 2, unit: 'Wetter', prompt: 'Was misst ein Thermometer?', answer: 'Temperatur', choices: <String>['Temperatur', 'Länge', 'Geld', 'Lautstärke'], explanation: 'Ein Thermometer zeigt warm oder kalt an.'),
  _ScienceQuestion(grade: 2, unit: 'Wetter', prompt: 'Was ist Nebel?', answer: 'Wolken nahe am Boden', choices: <String>['Wolken nahe am Boden', 'Sand im Glas', 'heißer Wind', 'lauter Donner'], explanation: 'Nebel besteht aus kleinen Wassertröpfchen in Bodennähe.'),
  _ScienceQuestion(grade: 2, unit: 'Jahreszeiten', prompt: 'Wie viele Jahreszeiten hat ein Jahr?', answer: '4', choices: <String>['4', '2', '7', '12'], explanation: 'Frühling, Sommer, Herbst und Winter sind vier Jahreszeiten.'),
  _ScienceQuestion(grade: 2, unit: 'Zeit und Kalender', prompt: 'Wie viele Monate hat ein Jahr?', answer: '12', choices: <String>['12', '7', '4', '24'], explanation: 'Ein Jahr hat zwölf Monate.'),
  _ScienceQuestion(grade: 2, unit: 'Körper', prompt: 'Womit riechst du?', answer: 'Nase', choices: <String>['Nase', 'Ohr', 'Knie', 'Hand'], explanation: 'Mit der Nase riechen wir.'),
  _ScienceQuestion(grade: 2, unit: 'Körper', prompt: 'Womit schmeckst du?', answer: 'Zunge', choices: <String>['Zunge', 'Auge', 'Fuß', 'Haar'], explanation: 'Mit der Zunge schmecken wir.'),
  _ScienceQuestion(grade: 2, unit: 'Familie und Gemeinschaft', prompt: 'Was hilft bei Streit?', answer: 'ruhig reden', choices: <String>['ruhig reden', 'schubsen', 'weglaufen ohne Erklärung', 'auslachen'], explanation: 'Ruhiges Reden hilft beim Lösen von Streit.'),
  _ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welche Frucht ist typisch österreichisch als Marille bekannt?', answer: 'Aprikose heißt in Österreich Marille', choices: <String>['Aprikose heißt in Österreich Marille', 'Banane heißt Marille', 'Topfen heißt Marille', 'Semmel heißt Marille'], explanation: 'In Österreich sagt man Marille.'),
  _ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Welches Tier ist nachtaktiv?', answer: 'Eule', choices: <String>['Eule', 'Huhn', 'Kuh', 'Schaf'], explanation: 'Eulen sind oft nachts unterwegs.'),
  _ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Auf welcher Seite geht man am Gehsteig besonders aufmerksam?', answer: 'weg von der Fahrbahn', choices: <String>['weg von der Fahrbahn', 'mitten auf der Straße', 'auf Schienen', 'im Kreisverkehr'], explanation: 'Am Gehsteig bleibt man weg von der Fahrbahn.'),
  _ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer baut Mauern?', answer: 'Maurer', choices: <String>['Maurer', 'Bäcker', 'Ärztin', 'Pilot'], explanation: 'Maurer bauen Mauern und Gebäude.'),
  _ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer arbeitet mit Metall?', answer: 'Schlosser', choices: <String>['Schlosser', 'Gärtner', 'Lehrer', 'Postler'], explanation: 'Schlosser arbeiten oft mit Metall.'),
  _ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welches Organ pumpt Blut?', answer: 'Herz', choices: <String>['Herz', 'Magen', 'Lunge', 'Haut'], explanation: 'Das Herz pumpt Blut durch den Körper.'),
  _ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welches Organ hilft beim Atmen?', answer: 'Lunge', choices: <String>['Lunge', 'Herz', 'Darm', 'Knochen'], explanation: 'Die Lunge nimmt Sauerstoff auf.'),
  _ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Womit verdauen wir Nahrung weiter?', answer: 'Magen und Darm', choices: <String>['Magen und Darm', 'Auge und Ohr', 'Hand und Fuß', 'Haut und Haar'], explanation: 'Magen und Darm helfen bei der Verdauung.'),
  _ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welche fünf Sinne haben wir?', answer: 'sehen, hören, riechen, schmecken, fühlen', choices: <String>['sehen, hören, riechen, schmecken, fühlen', 'laufen, springen, sitzen, stehen, liegen', 'essen, trinken, schlafen, malen, rechnen', 'rot, blau, grün, gelb, weiß'], explanation: 'Die Sinne helfen uns, die Umwelt wahrzunehmen.'),
  _ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was sollte man oft trinken?', answer: 'Wasser', choices: <String>['Wasser', 'Limo', 'Sirup', 'Eistee'], explanation: 'Wasser ist ein gesundes Getränk.'),
  _ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was gehört zur Obstgruppe?', answer: 'Apfel', choices: <String>['Apfel', 'Hammer', 'Schuh', 'Kabel'], explanation: 'Äpfel sind Obst.'),
  _ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was gibt Energie, soll aber nicht zu viel gegessen werden?', answer: 'Zucker', choices: <String>['Zucker', 'Wasser', 'Salat', 'Luft'], explanation: 'Zu viel Zucker ist ungesund.'),
  _ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was enthält viele Vitamine?', answer: 'Gemüse und Obst', choices: <String>['Gemüse und Obst', 'Steine', 'Plastik', 'Batterien'], explanation: 'Obst und Gemüse enthalten viele Vitamine.'),
  _ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Was passiert, wenn Wasser durch Sonne gasförmig wird?', answer: 'Verdunstung', choices: <String>['Verdunstung', 'Gefrieren', 'Schneiden', 'Messen'], explanation: 'Verdunstung macht aus Wasser Wasserdampf.'),
  _ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Wie nennt man Regen, Schnee oder Hagel zusammen?', answer: 'Niederschlag', choices: <String>['Niederschlag', 'Stromkreis', 'Nahrungskette', 'Hauptstadt'], explanation: 'Niederschlag fällt aus Wolken.'),
  _ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Wohin fließt ein Bach oft?', answer: 'in einen Fluss', choices: <String>['in einen Fluss', 'in ein Heft', 'in eine Lampe', 'in ein Sackerl'], explanation: 'Bäche fließen oft in größere Gewässer.'),
  _ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Was sammelt sich zu Wolken?', answer: 'Wasserdampf', choices: <String>['Wasserdampf', 'Sand', 'Holz', 'Metall'], explanation: 'Wasserdampf kann Wolken bilden.'),
  _ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tierklasse hat Federn?', answer: 'Vögel', choices: <String>['Vögel', 'Fische', 'Insekten', 'Säugetiere'], explanation: 'Vögel haben Federn.'),
  _ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tierklasse hat Schuppen und lebt im Wasser?', answer: 'Fische', choices: <String>['Fische', 'Vögel', 'Spinnen', 'Säugetiere'], explanation: 'Viele Fische haben Schuppen und Kiemen.'),
  _ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tiere haben sechs Beine?', answer: 'Insekten', choices: <String>['Insekten', 'Säugetiere', 'Fische', 'Vögel'], explanation: 'Insekten haben sechs Beine.'),
  _ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tiere säugen ihre Jungen?', answer: 'Säugetiere', choices: <String>['Säugetiere', 'Fische', 'Insekten', 'Vögel'], explanation: 'Säugetiere geben den Jungen Milch.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Wie viele Bundesländer hat Österreich?', answer: '9', choices: <String>['9', '7', '10', '12'], explanation: 'Österreich hat neun Bundesländer.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'In welchem Bundesland liegt Gänserndorf?', answer: 'Niederösterreich', choices: <String>['Niederösterreich', 'Tirol', 'Kärnten', 'Vorarlberg'], explanation: 'Gänserndorf liegt in Niederösterreich.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Wie heißt die Bundeshauptstadt von Österreich?', answer: 'Wien', choices: <String>['Wien', 'Berlin', 'Graz', 'St. Pölten'], explanation: 'Die Bundeshauptstadt Österreichs ist Wien.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Stadt ist Hauptstadt von Niederösterreich?', answer: 'St. Pölten', choices: <String>['St. Pölten', 'Wien', 'Linz', 'Eisenstadt'], explanation: 'St. Pölten ist Landeshauptstadt von Niederösterreich.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welches Bundesland liegt ganz im Osten Österreichs?', answer: 'Burgenland', choices: <String>['Burgenland', 'Tirol', 'Vorarlberg', 'Salzburg'], explanation: 'Das Burgenland liegt im Osten.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Bundesländer grenzen an Niederösterreich?', answer: 'Wien, Oberösterreich, Steiermark, Burgenland', choices: <String>['Wien, Oberösterreich, Steiermark, Burgenland', 'Tirol und Vorarlberg', 'Kärnten und Salzburg', 'nur Wien'], explanation: 'Niederösterreich umgibt Wien und grenzt an mehrere Bundesländer.'),
  _ScienceQuestion(grade: 3, unit: 'Verkehr', prompt: 'Was bedeutet Vorrang?', answer: 'jemand darf zuerst fahren oder gehen', choices: <String>['jemand darf zuerst fahren oder gehen', 'alle fahren gleichzeitig', 'niemand schaut', 'nur Autos zählen'], explanation: 'Vorrang regelt, wer zuerst darf.'),
  _ScienceQuestion(grade: 3, unit: 'Zeit und Kalender', prompt: 'Was ist ein Kalender?', answer: 'eine Übersicht über Tage, Wochen und Monate', choices: <String>['eine Übersicht über Tage, Wochen und Monate', 'ein Werkzeug zum Sägen', 'ein Tierbuch', 'ein Verkehrsschild'], explanation: 'Ein Kalender ordnet Zeit.'),
  _ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Welche Aufgabe hat die Blüte?', answer: 'sie hilft bei der Fortpflanzung', choices: <String>['sie hilft bei der Fortpflanzung', 'sie bremst Autos', 'sie pumpt Blut', 'sie misst Wärme'], explanation: 'Aus Blüten können Früchte und Samen entstehen.'),
  _ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Was schützt den Boden und wird aus Pflanzenresten?', answer: 'Humus', choices: <String>['Humus', 'Plastik', 'Glas', 'Metall'], explanation: 'Humus entsteht aus zersetzten Pflanzenresten.'),
  _ScienceQuestion(grade: 3, unit: 'Wetter', prompt: 'Was zeigt die Windrichtung?', answer: 'woher der Wind kommt', choices: <String>['woher der Wind kommt', 'wie alt der Wind ist', 'welche Farbe Wind hat', 'wie schwer Sonne ist'], explanation: 'Windrichtung beschreibt, woher Wind weht.'),
  _ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Warum putzen wir Zähne?', answer: 'damit sie gesund bleiben', choices: <String>['damit sie gesund bleiben', 'damit sie wachsen wie Haare', 'damit sie hören', 'damit sie leuchten'], explanation: 'Zähneputzen schützt vor Karies.'),
  _ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was ist eine ausgewogene Jause?', answer: 'Semmel, Käse, Gemüse und Wasser', choices: <String>['Semmel, Käse, Gemüse und Wasser', 'nur Zuckerln', 'nur Limo', 'nur Schlagobers'], explanation: 'Eine gute Jause hat verschiedene gesunde Teile.'),
  _ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Warum brauchen Tiere einen Lebensraum?', answer: 'für Nahrung, Schutz und Nachwuchs', choices: <String>['für Nahrung, Schutz und Nachwuchs', 'für Hefte', 'für Ampeln', 'für Geld'], explanation: 'Ein Lebensraum deckt wichtige Bedürfnisse.'),
  _ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Was ist Grundwasser?', answer: 'Wasser unter der Erde', choices: <String>['Wasser unter der Erde', 'Wasser im Fernseher', 'Wasser in der Sonne', 'Wasser aus Metall'], explanation: 'Grundwasser befindet sich im Boden.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Farbe hat die österreichische Flagge?', answer: 'rot-weiß-rot', choices: <String>['rot-weiß-rot', 'schwarz-rot-gold', 'blau-gelb', 'grün-weiß-grün'], explanation: 'Österreichs Flagge ist rot-weiß-rot.'),
  _ScienceQuestion(grade: 3, unit: 'Familie und Gemeinschaft', prompt: 'Was ist eine Regel?', answer: 'eine Vereinbarung, wie man handelt', choices: <String>['eine Vereinbarung, wie man handelt', 'ein Tier', 'ein Möbelstück', 'ein Fluss'], explanation: 'Regeln helfen beim Zusammenleben.'),
  _ScienceQuestion(grade: 3, unit: 'Berufe', prompt: 'Wer hilft bei einem Unfall?', answer: 'Rettung', choices: <String>['Rettung', 'Bäckerei', 'Bibliothek', 'Schneiderei'], explanation: 'Die Rettung hilft medizinisch.'),
  _ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Welche Pflanze trägt Äpfel?', answer: 'Apfelbaum', choices: <String>['Apfelbaum', 'Tanne', 'Rose', 'Gras'], explanation: 'Äpfel wachsen auf Apfelbäumen.'),
  _ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Was schützt unsere inneren Organe außen?', answer: 'Haut', choices: <String>['Haut', 'Schuh', 'Heft', 'Sackerl'], explanation: 'Die Haut schützt den Körper.'),
  _ScienceQuestion(grade: 3, unit: 'Wetter', prompt: 'Was ist Frost?', answer: 'gefrorene Feuchtigkeit bei Kälte', choices: <String>['gefrorene Feuchtigkeit bei Kälte', 'heißer Regen', 'lauter Wind', 'bunter Nebel'], explanation: 'Frost entsteht bei Kälte.'),
  _ScienceQuestion(grade: 3, unit: 'Verkehr', prompt: 'Warum sind Reflektoren wichtig?', answer: 'man wird besser gesehen', choices: <String>['man wird besser gesehen', 'man fährt schneller', 'man hört besser', 'man spart Geld'], explanation: 'Reflektoren machen im Dunkeln sichtbar.'),
  _ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was ist Topfen?', answer: 'ein Milchprodukt', choices: <String>['ein Milchprodukt', 'ein Werkzeug', 'ein Fahrzeug', 'ein Bundesland'], explanation: 'Topfen ist ein österreichisches Milchprodukt.'),
  _ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welches Bundesland hat Eisenstadt als Hauptstadt?', answer: 'Burgenland', choices: <String>['Burgenland', 'Tirol', 'Wien', 'Salzburg'], explanation: 'Eisenstadt ist Hauptstadt des Burgenlands.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie heißt der höchste Berg Österreichs?', answer: 'Großglockner', choices: <String>['Großglockner', 'Ötscher', 'Schneeberg', 'Rax'], explanation: 'Der Großglockner ist Österreichs höchster Berg.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welcher große Fluss fließt durch Wien?', answer: 'Donau', choices: <String>['Donau', 'Rhein', 'Elbe', 'Themse'], explanation: 'Die Donau fließt durch Wien.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie heißt Österreichs Bundeshauptstadt?', answer: 'Wien', choices: <String>['Wien', 'Berlin', 'Graz', 'Linz'], explanation: 'Wien ist die Bundeshauptstadt.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie viele Bundesländer hat Österreich?', answer: '9', choices: <String>['9', '8', '10', '11'], explanation: 'Österreich hat neun Bundesländer.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welcher See liegt im Osten Österreichs?', answer: 'Neusiedler See', choices: <String>['Neusiedler See', 'Bodensee', 'Attersee', 'Wörthersee'], explanation: 'Der Neusiedler See liegt im Burgenland und in Ungarn.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'An welches Land grenzt Niederösterreich im Norden?', answer: 'Tschechien', choices: <String>['Tschechien', 'Italien', 'Schweiz', 'Slowenien'], explanation: 'Niederösterreich grenzt im Norden an Tschechien.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Landeshauptstadt gehört zur Steiermark?', answer: 'Graz', choices: <String>['Graz', 'Linz', 'Innsbruck', 'Bregenz'], explanation: 'Graz ist die Hauptstadt der Steiermark.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Landeshauptstadt gehört zu Tirol?', answer: 'Innsbruck', choices: <String>['Innsbruck', 'Klagenfurt', 'St. Pölten', 'Eisenstadt'], explanation: 'Innsbruck ist die Hauptstadt von Tirol.'),
  _ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'In welcher Zeit lebten Menschen als Jäger und Sammler?', answer: 'Steinzeit', choices: <String>['Steinzeit', 'Mittelalter', 'Neuzeit', 'Zukunft'], explanation: 'In der Steinzeit jagten und sammelten viele Menschen.'),
  _ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was war im Mittelalter oft auf einem Hügel gebaut?', answer: 'Burg', choices: <String>['Burg', 'Flughafen', 'U-Bahn', 'Computerraum'], explanation: 'Burgen boten Schutz.'),
  _ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Wer trug im Mittelalter oft Rüstung?', answer: 'Ritter', choices: <String>['Ritter', 'Pilot', 'Programmierer', 'Schaffner'], explanation: 'Ritter trugen Rüstungen.'),
  _ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was hilft uns, Vergangenes zu verstehen?', answer: 'Quellen', choices: <String>['Quellen', 'Ampeln', 'Batterien', 'Jausenboxen'], explanation: 'Historische Quellen erzählen über früher.'),
  _ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was ist Archäologie?', answer: 'Wissenschaft von alten Funden', choices: <String>['Wissenschaft von alten Funden', 'Sport im Schnee', 'Kochen mit Topfen', 'Fahren mit Bus'], explanation: 'Archäologie untersucht Funde aus der Vergangenheit.'),
  _ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Wie viele Kontinente lernen viele Schulkarten?', answer: '7', choices: <String>['7', '3', '9', '12'], explanation: 'Oft werden sieben Kontinente unterschieden.'),
  _ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Auf welchem Kontinent liegt Österreich?', answer: 'Europa', choices: <String>['Europa', 'Afrika', 'Asien', 'Australien'], explanation: 'Österreich liegt in Europa.'),
  _ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Welcher Ozean ist der größte?', answer: 'Pazifik', choices: <String>['Pazifik', 'Atlantik', 'Indischer Ozean', 'Arktischer Ozean'], explanation: 'Der Pazifik ist der größte Ozean.'),
  _ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Was ist ein Ozean?', answer: 'ein sehr großes Meer', choices: <String>['ein sehr großes Meer', 'ein kleiner Bach', 'ein Berg', 'ein Bundesland'], explanation: 'Ozeane sind riesige Meere.'),
  _ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was zeigt eine Nahrungskette?', answer: 'wer wen frisst', choices: <String>['wer wen frisst', 'wer welches Heft hat', 'wer zuerst fährt', 'wer lauter singt'], explanation: 'Nahrungsketten zeigen Energiefluss.'),
  _ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was machen Zersetzer?', answer: 'sie bauen tote Reste ab', choices: <String>['sie bauen tote Reste ab', 'sie bauen Straßen', 'sie schreiben Briefe', 'sie löschen Brände'], explanation: 'Zersetzer helfen, Stoffe zurück in den Boden zu bringen.'),
  _ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was ist ein Lebensraum?', answer: 'Ort, an dem Lebewesen leben', choices: <String>['Ort, an dem Lebewesen leben', 'ein Rechenzeichen', 'ein Kleidungsstück', 'eine Uhrzeit'], explanation: 'Lebensräume bieten Nahrung und Schutz.'),
  _ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Warum sind Bienen wichtig?', answer: 'sie bestäuben viele Pflanzen', choices: <String>['sie bestäuben viele Pflanzen', 'sie fahren Bus', 'sie drucken Bücher', 'sie bauen Mauern'], explanation: 'Bestäubung hilft Pflanzen bei Früchten und Samen.'),
  _ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was braucht ein einfacher Stromkreis?', answer: 'Batterie, Kabel, Lampe und Schalter', choices: <String>['Batterie, Kabel, Lampe und Schalter', 'Semmel, Topfen und Saft', 'Buch, Heft und Lineal', 'Apfel, Birne und Banane'], explanation: 'Ein geschlossener Stromkreis lässt Strom fließen.'),
  _ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Wann leuchtet die Lampe im Stromkreis?', answer: 'wenn der Kreis geschlossen ist', choices: <String>['wenn der Kreis geschlossen ist', 'wenn das Kabel fehlt', 'wenn die Batterie leer ist', 'wenn der Schalter offen ist'], explanation: 'Strom fließt nur im geschlossenen Kreis.'),
  _ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was leitet Strom gut?', answer: 'Metall', choices: <String>['Metall', 'Holz', 'Plastik', 'Papier'], explanation: 'Metalle leiten Strom meist gut.'),
  _ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was ist ein Nichtleiter?', answer: 'Plastik', choices: <String>['Plastik', 'Kupfer', 'Eisen', 'Aluminium'], explanation: 'Plastik leitet Strom schlecht.'),
  _ScienceQuestion(grade: 4, unit: 'Diagramme lesen', prompt: 'Was zeigt ein Säulendiagramm?', answer: 'Werte als Balken', choices: <String>['Werte als Balken', 'nur Wörter', 'nur Landkarten', 'nur Uhrzeiten'], explanation: 'Balken machen Mengen vergleichbar.'),
  _ScienceQuestion(grade: 4, unit: 'Diagramme lesen', prompt: 'Welche Säule zeigt den größten Wert?', answer: 'die höchste Säule', choices: <String>['die höchste Säule', 'die kürzeste Säule', 'die linke immer', 'die bunte immer'], explanation: 'Höhere Säule bedeutet größerer Wert.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Hymne gehört zu Österreich?', answer: 'Bundeshymne', choices: <String>['Bundeshymne', 'Vereinshymne', 'Schullied', 'Geburtstagslied'], explanation: 'Österreich hat eine Bundeshymne.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Stadt ist Hauptstadt von Oberösterreich?', answer: 'Linz', choices: <String>['Linz', 'Graz', 'Bregenz', 'Klagenfurt'], explanation: 'Linz ist Hauptstadt von Oberösterreich.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Stadt ist Hauptstadt von Kärnten?', answer: 'Klagenfurt', choices: <String>['Klagenfurt', 'Salzburg', 'Wien', 'Eisenstadt'], explanation: 'Klagenfurt ist Kärntens Landeshauptstadt.'),
  _ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Was ist der Äquator?', answer: 'gedachte Linie um die Erde', choices: <String>['gedachte Linie um die Erde', 'ein Fluss in Wien', 'ein Berg in Tirol', 'ein Werkzeug'], explanation: 'Der Äquator teilt die Erde in Nord und Süd.'),
  _ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was ist eine Zeitleiste?', answer: 'eine geordnete Darstellung von Ereignissen', choices: <String>['eine geordnete Darstellung von Ereignissen', 'ein Messbecher', 'ein Stromkabel', 'ein Verkehrsschild'], explanation: 'Zeitleisten ordnen Ereignisse nach Zeit.'),
  _ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was bedeutet nachhaltig?', answer: 'so handeln, dass die Zukunft geschützt wird', choices: <String>['so handeln, dass die Zukunft geschützt wird', 'alles sofort verbrauchen', 'Müll in den Bach werfen', 'Licht immer brennen lassen'], explanation: 'Nachhaltigkeit denkt an morgen.'),
  _ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Warum soll man nicht an Steckdosen spielen?', answer: 'Strom kann gefährlich sein', choices: <String>['Strom kann gefährlich sein', 'Steckdosen sind essbar', 'Steckdosen machen Musik', 'Strom ist immer kalt'], explanation: 'Strom aus Steckdosen ist gefährlich.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Hauptstadt gehört zu Vorarlberg?', answer: 'Bregenz', choices: <String>['Bregenz', 'Innsbruck', 'Linz', 'St. Pölten'], explanation: 'Bregenz ist Hauptstadt von Vorarlberg.'),
  _ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Hauptstadt gehört zu Salzburg?', answer: 'Salzburg', choices: <String>['Salzburg', 'Graz', 'Wien', 'Klagenfurt'], explanation: 'Salzburg ist Stadt und Bundesland-Hauptstadt.'),
  _ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Welcher Kontinent ist sehr kalt und am Südpol?', answer: 'Antarktis', choices: <String>['Antarktis', 'Afrika', 'Europa', 'Asien'], explanation: 'Die Antarktis liegt am Südpol.'),
  _ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was war ein Handwerk im Mittelalter?', answer: 'Schmieden', choices: <String>['Schmieden', 'Programmieren', 'Fernsehen', 'Autofahren'], explanation: 'Schmiede stellten Dinge aus Metall her.'),
  _ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was schützt ein Wald?', answer: 'Boden, Tiere und Klima', choices: <String>['Boden, Tiere und Klima', 'nur Autos', 'nur Computer', 'nur Ampeln'], explanation: 'Wälder sind wichtige Lebensräume.'),
  _ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was macht ein Schalter?', answer: 'er öffnet oder schließt den Stromkreis', choices: <String>['er öffnet oder schließt den Stromkreis', 'er kocht Suppe', 'er misst Zeit', 'er schreibt Wörter'], explanation: 'Schalter steuern, ob Strom fließt.'),
];
