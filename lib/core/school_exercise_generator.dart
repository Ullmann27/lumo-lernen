import 'dart:math';

import 'adventure/lumo_adventure_tasks.dart';
import 'german_task_templates.dart';
import 'english_vocabulary_extensions.dart';
import 'math_task_templates.dart';
import 'primary_school_word_data.dart';
import 'reading_comprehension_data.dart';
import 'science_task_data.dart';
import 'spelling_context_data.dart';

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
  /// Österreichischer Volksschulrahmen 2026.
  ///
  /// Der aktuelle Lehrplan sieht in der 1.–4. Schulstufe u. a. Deutsch,
  /// Sachunterricht, Mathematik, Musik, Kunst und Gestaltung, Technik und
  /// Design sowie Bewegung und Sport als Pflichtgegenstände vor. Eine lebende
  /// Fremdsprache ist in der Grundstufe I verbindliche Übung und in der
  /// Grundstufe II (3./4. Schulstufe) Pflichtgegenstand.
  ///
  /// Lumo verwendet für die automatisiert prüfbaren Kernaufgaben bewusst die
  /// Bereiche Mathematik, Deutsch/Lesen/Schreiben/Rechtschreibung,
  /// Sachunterricht, Englisch (als lebende Fremdsprache) und Logik. Kreative
  /// und körperliche Fächer werden nicht fälschlich als Multiple-Choice-
  /// Schularbeit modelliert, sondern sind als Aktivitäts-/Projektfächer
  /// vorgesehen.
  static List<String> officialSubjectsForGrade(int grade) {
    final g = grade.clamp(1, 4).toInt();
    return <String>[
      'Religion',
      'Deutsch',
      'Sachunterricht',
      'Mathematik',
      'Musik',
      'Kunst und Gestaltung',
      'Technik und Design',
      'Bewegung und Sport',
      if (g >= 3) 'Lebende Fremdsprache',
      if (g <= 2) 'Lebende Fremdsprache (verbindliche Übung)',
      'Verkehrs- und Mobilitätsbildung',
    ];
  }

  static List<String> exerciseSubjectsForGrade(int grade) {
    final g = grade.clamp(1, 4).toInt();
    return <String>[
      'Mathematik',
      'Deutsch',
      'Lesen',
      'Rechtschreibung',
      'Schreiben',
      'Sachunterricht',
      if (g >= 1) 'Englisch',
      'Logik',
    ];
  }

  static const List<String> activitySubjects = <String>[
    'Musik',
    'Kunst und Gestaltung',
    'Technik und Design',
    'Bewegung und Sport',
    'Verkehrs- und Mobilitätsbildung',
  ];

  static const Map<String, List<String>> subjects = <String, List<String>>{
    'Mathematik': <String>[
      'Plus bis 10', 'Minus bis 10', 'Plus bis 20', 'Minus bis 20',
      'Plus bis 100', 'Minus bis 100', 'Zahlenstrahl', 'Mengenvergleich',
      'Zahl in Worten', 'Geometrie Formen', 'Formen Nachzeichnen',
      'Geld', 'Zeit', 'Symmetrie',
      'Einmaleins Vorbereitung', 'Geld wechseln', 'Uhrzeit', 'Längen',
      'Gerade und ungerade', 'Verdoppeln und Halbieren', 'Zehner und Einer',
      'Einmaleins', 'Schriftliche Addition', 'Schriftliche Subtraktion',
      'Brüche Vorbereitung', 'Sachaufgaben zwei Schritte', 'Umfang',
      'Flächeninhalt', 'Schriftliche Multiplikation', 'Schriftliche Division',
      'Bruchrechnen einfach', 'Dezimalzahlen', 'Sachaufgaben drei Schritte',
      'Diagramme lesen', 'Textaufgaben', 'Vergleichen', 'Zahlenreihe',
      'Nachbarzahlen', 'Zahlen zerlegen', 'Minus ueber 10', 'Rechenhaeuser',
      'Blitzlicht',
      'Plus bis 1000', 'Minus bis 1000', 'Division einstellig',
      'Geld bis 100 Euro', 'Massen Kilogramm und Gramm', 'Plus bis 10000',
      'Minus bis 10000', 'Zahlenraum bis 1 Million', 'Zeit Minuten und Stunden',
      'Hohlmaße Liter und Milliliter', 'Brüche erweitern', 'Mittelwert',
      'Symmetrieachsen',
      // Lumos Abenteuer-Aufgaben (lumo_adventure_tasks.dart)
      'Rechengeschichten', 'Zahlenmauer', 'Zahlenrätsel', 'Marktstand',
      'Platzhalter-Rätsel', 'Größer, kleiner, gleich', 'Uhr-Abenteuer',
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
      'Wer-Fall und Wen-Fall', 'Großschreibung', 'ie oder i',
      'Die 4 Fälle', 'dass oder das', 'Umstandswörter', 'Vorvergangenheit',
      'Wortdetektiv', 'Silbenrätsel', 'Begleiter-Rätsel',
      'Gegenteil-Geschichten', 'Wörter zusammensetzen', 'Wortarten-Jagd',
      'Satzbaustelle',
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
    'Englisch': <String>['Farben', 'Zahlen', 'Tiere', 'Schulsachen', 'Begruessung', 'Familie', 'Körper', 'Spielzeug', 'Wetter', 'Essen', 'Tageszeit', 'Verben', 'Wochentage', 'Hobbys', 'Länder'],
    'Sachunterricht': <String>[
      'Tiere', 'Pflanzen', 'Jahreszeiten', 'Körper', 'Verkehr', 'Wetter',
      'Familie und Gemeinschaft', 'Zeit und Kalender', 'Berufe', 'Ernährung',
      'Wasserkreislauf', 'Bundesländer Österreichs', 'Geografie Österreich',
      'Geschichte', 'Kontinente und Ozeane', 'Ökosysteme', 'Stromkreise',
      'Diagramme lesen',
      'Wer bin ich?', 'Monate und Wochentage', 'Österreich-Reise',
    ],
    'Logik': <String>[
      'Muster', 'Reihenfolgen', 'Zahlenmuster', 'Schlussfolgern',
      'Regeln kombinieren', 'Was passt nicht?', 'Geheimcode',
    ],
  };

  /// Selectable topics backed by real task data for this grade. Topics from
  /// the current grade come first; earlier topics remain available to review.
  /// This describes app content availability, not an official curriculum.
  static List<String> unitsForGrade(String subject, int grade, {bool currentGradeOnly = false}) {
    final capped = grade.clamp(1, 4).toInt();
    return <String>{
      ..._templateUnitsForGrade(subject, capped, currentGradeOnly: currentGradeOnly),
      ...LumoAdventureTasks.unitsFor(subject, capped, currentGradeOnly: currentGradeOnly),
    }.toList(growable: false);
  }

  static List<String> _templateUnitsForGrade(String subject, int capped, {required bool currentGradeOnly}) {
    final lowestGrade = currentGradeOnly ? capped : 1;
    if (subject == 'Logik') {
      return <String>[
        if (!currentGradeOnly || capped == 1) ...['Muster', 'Reihenfolgen'],
        if (capped >= 2 && (!currentGradeOnly || capped == 2)) 'Zahlenmuster',
        if (capped >= 3 && (!currentGradeOnly || capped == 3)) 'Schlussfolgern',
        if (capped >= 4) 'Regeln kombinieren',
      ];
    }
    if (subject == 'Mathematik') {
      return <String>{
        for (var level = capped; level >= lowestGrade; level--)
          for (final template in MathTaskTemplates.templates)
            if (template.grade == level) template.unit,
      }.toList(growable: false);
    }
    if (subject == 'Deutsch') {
      return <String>{
        for (var level = capped; level >= lowestGrade; level--)
          for (final template in GermanTaskTemplates.templates)
            if (template.grade == level) template.unit,
        if (!currentGradeOnly) 'St oder Sp',
      }.toList(growable: false);
    }
    if (subject == 'Sachunterricht') {
      return <String>{
        for (var level = capped; level >= lowestGrade; level--)
          for (final question in _scienceQuestions)
            if (question.grade == level) question.unit,
      }.toList(growable: false);
    }
    if (subject == 'Englisch') {
      return <String>{
        for (var level = capped; level >= lowestGrade; level--)
          ..._englishVocabulary[level]!.keys,
      }.toList(growable: false);
    }
    return List<String>.unmodifiable(subjects[subject] ?? const <String>[]);
  }

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
  // Local generator memory complements the existing persisted SessionVarietyGuard.
  // No progress, profile fields, answer attempts or rewards are written here.
  final Map<String, List<String>> _recentProblems = {};
  // A finite science bank is drawn without replacement per grade and unit.
  // Unlike a shuffled answer order, this state represents actual question IDs.
  final Map<String, List<ScienceQuestion>> _scienceDrawPiles = {};
  final Map<String, String> _lastScienceQuestion = {};

  LumoTask _variedTask(int grade, String subject, String unit) {
    // Science has a finite, explicitly curated question bank. Sampling from
    // it through the retry loop would consume unseen questions without ever
    // displaying them. Its separate draw pile enforces no-replacement.
    if (subject == 'Sachunterricht') {
      return _build(grade: grade, subject: subject, unit: unit);
    }
    final scope = '$grade|$subject|$unit';
    final recent = _recentProblems.remove(scope) ?? <String>[];
    final candidates = <String, LumoTask>{};
    for (var attempt = 0; attempt < 60; attempt++) {
      final task = _build(grade: grade, subject: subject, unit: unit);
      final key = '${task.prompt}|${task.answer}';
      candidates[key] = task;
      if (!recent.contains(key)) break;
    }
    // Exhausting a finite bank is normal. Revisit its least recent problem;
    // changing IDs or distractor order must never masquerade as new content.
    final key = candidates.keys
        .reduce((a, b) => recent.indexOf(a) <= recent.indexOf(b) ? a : b);
    recent.remove(key);
    recent.add(key);
    if (recent.length > 24) recent.removeAt(0);
    _recentProblems[scope] = recent;
    if (_recentProblems.length > 32) {
      _recentProblems.remove(_recentProblems.keys.first);
    }
    return candidates[key]!;
  }

  String? _childName;

  LumoTask next({
    required int grade,
    String subject = 'Alle',
    String unit = 'Alle',
    Map<String, int> weakSkills = const <String, int>{},
    Set<String> avoidUnits = const <String>{},
    String? childName,
  }) {
    _childName = childName;
    final cappedGrade = grade.clamp(1, 4).toInt();
    final chosenSubject = _chooseSubject(subject, weakSkills);
    final units = Curriculum.unitsForGrade(chosenSubject, cappedGrade);
    final availableUnit = units.contains(unit) ||
        (chosenSubject == 'Mathematik' && MathTaskTemplates.supportsUnit(cappedGrade, unit)) ||
        (chosenSubject == 'Deutsch' && GermanTaskTemplates.supportsUnit(cappedGrade, unit));
    var selectionPool = units;
    if ((unit == 'Alle' || !availableUnit) && _random.nextInt(4) != 0) {
      final currentUnits = Curriculum.unitsForGrade(chosenSubject, cappedGrade, currentGradeOnly: true);
      if (currentUnits.isNotEmpty) selectionPool = currentUnits;
    }
    var candidateUnits = unit == 'Alle' || !availableUnit
        ? selectionPool.where((u) => !avoidUnits.contains(u)).toList()
        : <String>[unit];
    if (candidateUnits.isEmpty) {
      candidateUnits = units.where((u) => !avoidUnits.contains(u)).toList();
    }
    // Gemischte Runden: etwa 40 % Lumos Abenteuer-Aufgaben, damit Lernen
    // spielerisch bleibt (Geschichten, Rätsel, Zahlenmauern …).
    final adventures = candidateUnits.where((u) => LumoAdventureTasks.handles(chosenSubject, u)).toList();
    if ((unit == 'Alle' || !availableUnit) && adventures.isNotEmpty && _random.nextInt(10) < 4) {
      return _variedTask(cappedGrade, chosenSubject, adventures[_random.nextInt(adventures.length)]);
    }
    final chosenUnit = candidateUnits.isEmpty ? units[_random.nextInt(units.length)] : _weightedUnit(candidateUnits, weakSkills);
    return _variedTask(cappedGrade, chosenSubject, chosenUnit);
  }

  // A cross-subject session must also avoid duplicates when two topic
  // generators happen to produce the same visible problem. This complements
  // the per-topic rotation; task IDs and choice order are NOT identities.
  LumoTask _nextFreshForSession({
    required int grade,
    required String subject,
    required Map<String, int> weakSkills,
    required Set<String> avoidUnits,
    required Set<String> seen,
  }) {
    LumoTask? oldestFallback;
    for (var attempt = 0; attempt < 40; attempt++) {
      final task = next(
          grade: grade,
          subject: subject,
          weakSkills: weakSkills,
          avoidUnits: avoidUnits);
      oldestFallback ??= task;
      final signature =
          '${task.prompt.trim().toLowerCase()}|${task.answer.trim().toLowerCase()}';
      if (seen.add(signature)) return task;
    }
    // Finite banks eventually exhaust. Prefer a real repetition over
    // inventing a nonsense question or corrupting the expected session size.
    return oldestFallback!;
  }

  List<LumoTask> buildSession({
    required int grade,
    required int count,
    String subject = 'Alle',
    Map<String, int> weakSkills = const <String, int>{},
  }) {
    final tasks = <LumoTask>[];
    final usedUnits = <String>{};
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      final task = _nextFreshForSession(
          grade: grade, subject: subject, weakSkills: weakSkills,
          avoidUnits: usedUnits, seen: seen);
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
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      final subject = i < subjects.length ? subjects[i] : subjects[_random.nextInt(subjects.length)];
      tasks.add(_nextFreshForSession(
          grade: grade, subject: subject, weakSkills: weakSkills,
          avoidUnits: avoid, seen: seen));
      avoid.add(tasks.last.unit);
      if (avoid.length > 10) avoid.clear();
    }
    tasks.shuffle(_random);
    return tasks;
  }

  String _chooseSubject(String requested, Map<String, int> weakSkills) {
    if (requested != 'Alle') return Curriculum.subjects.containsKey(requested) ? requested : 'Mathematik';
    if (weakSkills.isNotEmpty && _random.nextDouble() < .60) {
      final weakUnit = weakSkills.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final subject in Curriculum.subjects.entries) {
        if (subject.value.contains(weakUnit.first.key)) return subject.key;
      }
    }
    final base = <String>['Mathematik', 'Deutsch', 'Lesen', 'Rechtschreibung', 'Sachunterricht', 'Schreiben', 'Englisch'];
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
    if (LumoAdventureTasks.handles(subject, unit)) return _adventure(grade, subject, unit);
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
      case 'Logik':
        return _logic(grade, unit);
      default:
        return _math(grade, unit);
    }
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_serial-${_random.nextInt(99999)}';

  LumoTask _logic(int grade, String unit) {
    if (unit == 'Muster') {
      final symbols = <String>['Kreis', 'Dreieck', 'Stern', 'Quadrat']
        ..shuffle(_random);
      final length = grade == 1 ? 2 : 3;
      final pattern = symbols.take(length).toList();
      final shown = <String>[...pattern, ...pattern];
      return _choiceTask(
          'logik-muster',
          grade,
          'Logik',
          unit,
          'Das Muster wiederholt sich immer gleich: ${shown.join(' – ')} – ? Welche Form folgt?',
          pattern.first,
          'Die Gruppe ${pattern.join(' – ')} wiederholt sich. Nach ${pattern.last} kommt wieder ${pattern.first}.',
          customChoices: symbols);
    }
    if (unit == 'Zahlenmuster') {
      final step = 1 + _random.nextInt(grade * 2);
      final start = _random.nextInt(grade == 2 ? 50 : 200);
      final shown = List.generate(4, (i) => start + i * step);
      final answer = start + 4 * step;
      return _choiceTask(
          'logik-zahlenmuster',
          grade,
          'Logik',
          unit,
          'Gehe jedes Mal gleich viele Schritte weiter: ${shown.join(' – ')} – ? Welche Zahl folgt?',
          '$answer',
          'Der Abstand ist immer $step. Nach ${shown.last} kommt ${shown.last} + $step = $answer.',
          customChoices: <String>[
            '$answer',
            '${answer + 1}',
            '${answer - 1}',
            '${answer + step + 1}'
          ]);
    }
    if (unit == 'Regeln kombinieren') {
      final lower = 10 + _random.nextInt(90) * 2;
      final answer = lower + 4;
      return _choiceTask(
          'logik-regeln',
          grade,
          'Logik',
          unit,
          'Welche Zahl erfüllt alle drei Regeln: größer als $lower, kleiner als ${lower + 8} und gerade?',
          '$answer',
          '$answer liegt zwischen $lower und ${lower + 8}. Die Zahl ist gerade, weil man sie ohne Rest in Paare teilen kann. Nur diese Antwort erfüllt alle drei Regeln.',
          customChoices: <String>[
            '$answer',
            '$lower',
            '${lower + 3}',
            '${lower + 8}'
          ]);
    }
    final names = <String>['Lumo', 'Mia', 'Ben', 'Ali', 'Lea']
      ..shuffle(_random);
    final first = names[0], middle = names[1], last = names[2];
    final askedIndex = _random.nextInt(3);
    final asked =
        <String>['ganz links', 'in der Mitte', 'ganz rechts'][askedIndex];
    final answer = <String>[first, middle, last][askedIndex];
    final prompt = unit == 'Schlussfolgern'
        ? 'Drei Figuren stehen nebeneinander. $first steht links von $middle. $middle steht links von $last. Wer steht $asked?'
        : 'Von links nach rechts stehen $first, $middle und $last. Wer steht $asked?';
    return _choiceTask(
        'logik-reihenfolge',
        grade,
        'Logik',
        unit,
        prompt,
        answer,
        'Von links nach rechts ist die Reihenfolge $first – $middle – $last. $answer steht $asked.',
        customChoices: <String>[first, middle, last]);
  }

  /// Lumos Abenteuer-Aufgaben, auf Wunsch mit dem Namen des Kindes.
  LumoTask _adventure(int grade, String subject, String unit) {
    final task = LumoAdventureTasks(_random, childName: _childName)
        .generate(subject: subject, unit: unit, grade: grade);
    return LumoTask(
      id: _id('abenteuer-${task.unit}'),
      grade: grade,
      subject: task.subject,
      unit: task.unit,
      prompt: task.prompt,
      choices: _shuffledChoices(task.choices),
      answer: task.answer,
      explanation: task.explanation,
      visual: task.visual,
      difficulty: grade,
    );
  }

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
    final capped = grade.clamp(1, 4).toInt();
    bool matches(ScienceQuestion question) =>
        unit == 'Alle' ||
        question.unit == unit ||
        _scienceAliases[unit]?.contains(question.unit) == true;

    // New material is drawn from the child's actual grade. If a small unit
    // contains fewer than six prompts, earlier-grade questions can be used as
    // explicitly compatible consolidation, never as a substitute for a full
    // third- or fourth-grade pool.
    final current = _scienceQuestions
        .where((question) => question.grade == capped && matches(question))
        .toList();
    final source = <ScienceQuestion>[...current];
    if (current.length < 6 && capped > 1) {
      source.addAll(_scienceQuestions.where(
          (question) => question.grade < capped && matches(question)));
    }
    if (source.isEmpty) {
      // Legacy invalid units must not cause a crash. next() resolves most
      // unknown units before reaching here. Keep the actual returned unit
      // visible rather than disguising an unrelated exercise.
      source.addAll(
          _scienceQuestions.where((question) => question.grade == capped));
    }

    final unique = <String, ScienceQuestion>{
      for (final question in source)
        '${question.prompt.trim().toLowerCase()}|${question.answer.trim().toLowerCase()}':
            question,
    };
    final scope = '$capped|$unit';
    var pile = _scienceDrawPiles[scope];
    if (pile == null || pile.isEmpty) {
      pile = unique.values.toList()..shuffle(_random);
      // A depleted pool can repeat in a new cycle, but not on the boundary.
      final previous = _lastScienceQuestion[scope];
      if (pile.length > 1 &&
          '${pile.last.prompt}|${pile.last.answer}' == previous) {
        final replacement = pile.indexWhere((item) =>
            '${item.prompt}|${item.answer}' != previous);
        if (replacement >= 0) {
          final temp = pile.last;
          pile[pile.length - 1] = pile[replacement];
          pile[replacement] = temp;
        }
      }
      _scienceDrawPiles[scope] = pile;
      if (_scienceDrawPiles.length > 64) {
        final oldest = _scienceDrawPiles.keys.first;
        _scienceDrawPiles.remove(oldest);
        _lastScienceQuestion.remove(oldest);
      }
    }
    final question = pile.removeLast();
    _lastScienceQuestion[scope] = '${question.prompt}|${question.answer}';
    return LumoTask(
      id: _id('sach-${question.unit}'),
      grade: grade,
      subject: 'Sachunterricht',
      unit: question.unit,
      prompt: question.prompt,
      choices: _shuffledChoices(<String>[
        question.answer,
        ...question.choices.where((choice) => choice != question.answer),
      ]),
      answer: question.answer,
      explanation: question.explanation,
      visual: 'science',
      difficulty: question.grade,
    );
  }

  LumoTask _spelling(int grade, String unit) {
    if (unit == 'Wortende') {
      final pool = wordEndingContexts.where((q) => grade >= 2 || q.$1.length <= 5).toList();
      final q = pool[_random.nextInt(pool.length)];
      return _choiceTask('rs-verlaengern', grade, 'Rechtschreibung', unit,
          'Verlängere das Wort: ${q.$3}. Welcher Buchstabe fehlt in „${q.$1}_“?', q.$2,
          'In ${q.$3} kannst du den Buchstaben hören. Das kurze Wort schreibt man ${q.$1}${q.$2}.',
          customChoices: [q.$2, ...['d','t','b','p','g','k'].where((v) => v != q.$2).take(3)]);
    }
    final contexts = spellingContexts.where((q) => q.unit == unit && q.grade <= grade).toList();
    if (contexts.isNotEmpty && _random.nextInt(4) != 0) {
      final q = contexts[_random.nextInt(contexts.length)];
      final sentenceType = q.answer == '.' ? 'Aussagesatz' : q.answer == '?' ? 'Fragesatz' : 'Ausruf';
      final prompt = unit == 'Satzzeichen'
          ? 'Setze das übliche Satzzeichen für diesen $sentenceType: „${q.sentence}“'
          : '${q.sentence}\nWelche Schreibweise passt in die Lücke?';
      return _choiceTask('rs-kontext', grade, 'Rechtschreibung', unit, prompt, q.answer, q.rule,
          customChoices:[q.answer, ...q.wrong]);
    }
    if (unit == 'St oder Sp') return _stOrSp(grade, 'Rechtschreibung');
    if (unit == 'Gross und klein') {
      final noun = PrimarySchoolWordData.nounForGrade(
          grade, _serial + _random.nextInt(9999));
      final lower = noun.toLowerCase();
      // Labels preserve the contrast through case-insensitive answer adapters.
      final answer = 'Großer Anfang: $noun';
      return _choiceTask(
          'gross',
          grade,
          'Rechtschreibung',
          unit,
          'Wie schreibt man das Namenwort „$lower“ normalerweise im Satz?',
          answer,
          'Namenwörter beginnen mit einem großen Buchstaben: $noun.',
          customChoices: <String>[
            answer,
            'Alles klein: $lower',
            'Alles groß: ${noun.toUpperCase()}'
          ]);
    }
    if (unit == 'Satzzeichen') {
      // 2026-06-03: vorher EIN fester Satz. Jetzt Pool nach Satz-Typ
      // (Aussage / Frage / Ausrufung) mit korrektem Zeichen + Erklaerung.
      const items = <List<String>>[
        <String>[
          'Lumo liest ein Buch',
          '.',
          'Ein Aussagesatz endet mit einem Punkt.'
        ],
        <String>[
          'Heute ist Schule',
          '.',
          'Aussagesätze enden mit einem Punkt.'
        ],
        <String>[
          'Wer hat die Tasche',
          '?',
          'Eine Frage endet mit einem Fragezeichen.'
        ],
        <String>[
          'Wie spät ist es',
          '?',
          'Bei einer Frage steht am Ende ein Fragezeichen.'
        ],
        <String>[
          'Pass auf, Lumo',
          '!',
          'Ein Aufforderungssatz oder Ausruf endet mit einem Rufzeichen.'
        ],
        <String>[
          'Was für ein schöner Tag',
          '!',
          'Ausrufesätze enden mit einem Rufzeichen.'
        ],
      ];
      final pick = items[_random.nextInt(items.length)];
      final sentenceType = pick[1] == '.'
          ? 'Aussagesatz'
          : pick[1] == '?'
              ? 'Fragesatz'
              : 'Ausruf';
      return _choiceTask(
          'punkt',
          grade,
          'Rechtschreibung',
          unit,
          'Setze das übliche Satzzeichen für diesen $sentenceType: „${pick[0]}“',
          pick[1],
          pick[2],
          customChoices: const <String>['.', '?', '!']);
    }
    if (unit == 'Doppelmitlaut') {
      // 2026-06-03: vorher EIN Wort (kommen). Jetzt 10 typische Doppel-
      // Konsonanten-Faelle aus dem AT-Lehrplan.
      const items = <List<String>>[
        <String>[
          'kommen',
          'komen',
          'komenn',
          'Bei kommen hörst du ein kurzes o, darum mm.',
          'Wir ___ nach Hause.'
        ],
        <String>[
          'rennen',
          'renen',
          'renenn',
          'Kurzes e vor nn: rennen.',
          'Die Kinder ___ zum Tor.'
        ],
        <String>[
          'offen',
          'ofen',
          'ofenn',
          'Kurzes o vor ff: offen.',
          'Die Tür ist ___.'
        ],
        <String>[
          'Sommer',
          'Somer',
          'Somerr',
          'Kurzes o vor mm: Sommer.',
          'Im ___ ist es warm.'
        ],
        <String>[
          'Mutter',
          'Muter',
          'Muther',
          'Kurzes u vor tt: Mutter.',
          'Meine ___ hilft mir.'
        ],
        <String>[
          'Affe',
          'Afe',
          'Affee',
          'Kurzes a vor ff: Affe.',
          'Der ___ klettert.'
        ],
        <String>[
          'hoffen',
          'hofen',
          'hophen',
          'Kurzes o vor ff: hoffen.',
          'Wir ___ auf Sonne.'
        ],
        <String>[
          'Wanne',
          'Wane',
          'Wann',
          'Kurzes a vor nn: Wanne.',
          'Das Wasser ist in der ___.'
        ],
        <String>[
          'Wetter',
          'Weter',
          'Wether',
          'Kurzes e vor tt: Wetter.',
          'Heute ist das ___ schön.'
        ],
        <String>[
          'nett',
          'net',
          'neett',
          'Kurzes e vor tt: nett.',
          'Lumo hilft mir und ist ___.'
        ],
      ];
      final pick = items[_random.nextInt(items.length)];
      return _choiceTask('doppel', grade, 'Rechtschreibung', unit,
          '${pick[4]}\nWelche Schreibweise ist richtig?', pick[0], pick[3],
          customChoices: <String>[pick[0], pick[1], pick[2]]);
    }
    if (unit == 'Dehnungen') {
      const items = <List<String>>[
        [
          'Zahn',
          'Zan',
          'Zaahn',
          'Die Mehrzahl heißt Zähne. Merke dir das h in Zahn.'
        ],
        ['Uhr', 'Ur', 'Uuhr', 'Das Wort Uhr schreibt man mit h.'],
        ['Stuhl', 'Stul', 'Stuuhl', 'Im Wort Stuhl steht nach dem u ein h.'],
        ['Biene', 'Bine', 'Bihne', 'Das lange i in Biene schreibt man ie.'],
        ['Wiese', 'Wise', 'Wihse', 'Das lange i in Wiese schreibt man ie.'],
        [
          'spielen',
          'spilen',
          'spihlen',
          'Das lange i in spielen schreibt man ie.'
        ],
        ['fahren', 'faren', 'faahren', 'Das Wort fahren schreibt man mit h.'],
        [
          'wohnen',
          'wonen',
          'woohnen',
          'Im Wort wohnen steht nach dem o ein h.'
        ],
      ];
      final pick = items[_random.nextInt(grade == 1 ? 4 : items.length)];
      return _choiceTask('dehnung', grade, 'Rechtschreibung', unit,
          'Welche Schreibweise ist richtig?', pick[0], pick[3],
          customChoices: <String>[pick[0], pick[1], pick[2]]);
    }
    if (unit == 'Wortende') {
      const items = <List<String>>[
        ['Hun', 'd', 'Hunde'],
        ['Kin', 'd', 'Kinder'],
        ['Han', 'd', 'Hände'],
        ['Ber', 'g', 'Berge'],
        ['Ta', 'g', 'Tage'],
        ['We', 'g', 'Wege'],
        ['Die', 'b', 'Diebe'],
        ['Bro', 't', 'Brote'],
      ];
      final pick = items[_random.nextInt(items.length)];
      return _choiceTask(
          'wortende',
          grade,
          'Rechtschreibung',
          unit,
          'Verlängere das Wort: ${pick[2]}. Welcher Buchstabe fehlt in „${pick[0]}_“?',
          pick[1],
          'In ${pick[2]} hörst du den Buchstaben. Deshalb schreibt man ${pick[0]}${pick[1]}.',
          customChoices: <String>[
            pick[1],
            ...const ['d', 't', 'g', 'k', 'b', 'p']
                .where((letter) => letter != pick[1])
                .take(2)
          ]);
    }
    // Reviewed variants: appending -e/-n can produce a second correct word
    // (e.g. Hund/Hunde), which is not a valid spelling distractor.
    const commonWords = <int, List<List<String>>>{
      1: [
        ['Haus', 'Hauß', 'Hauss'],
        ['Ball', 'Bal', 'Bahl'],
        ['Sonne', 'Sone', 'Sonnne'],
        ['Schule', 'Schuhle', 'Schulee'],
        ['Apfel', 'Apfl', 'Appfel'],
        ['Blume', 'Bluume', 'Blumme'],
      ],
      2: [
        ['Freund', 'Froind', 'Freunt'],
        ['Fenster', 'Fensta', 'Fenstter'],
        ['Garten', 'Garrten', 'Gartten'],
        ['Lehrer', 'Lerer', 'Lehrerr'],
        ['Katze', 'Kaze', 'Kattze'],
        ['Wasser', 'Waser', 'Wassser'],
      ],
      3: [
        ['Sprache', 'Sprahe', 'Schprache'],
        ['Vogel', 'Fogel', 'Vogell'],
        ['Geburtstag', 'Geburtstak', 'Geburstag'],
        ['Geschichte', 'Geschihte', 'Geschichhte'],
        ['Schlüssel', 'Schlüsel', 'Schlüssell'],
        ['Brücke', 'Brüke', 'Brüccke'],
      ],
      4: [
        ['Fahrrad', 'Farad', 'Fahrrat'],
        ['Werkzeug', 'Werkzeuk', 'Werkzeugg'],
        ['Feuerwehr', 'Feuerwer', 'Feurwehr'],
        ['Bibliothek', 'Bibliotek', 'Bibliothekk'],
        ['Erfahrung', 'Erfarung', 'Erfahrunk'],
        ['Gewitter', 'Gewiter', 'Gewitterr'],
      ],
    };
    final bank = commonWords[grade.clamp(1, 4)]!;
    final item = bank[_random.nextInt(bank.length)];
    return _choiceTask(
        'wort',
        grade,
        'Rechtschreibung',
        unit,
        'Welche Schreibweise ist richtig?',
        item[0],
        'So schreibt man das Wort: ${item[0]}. Schau jeden Buchstaben langsam an.',
        customChoices: item);
  }

  LumoTask _stOrSp(int grade, String subject) {
    // 2026-06-03: vorher 8 Woerter. Jetzt 20 Woerter, ausgewogen St/Sp/Sch
    // (Sch als Distraktor war vorher nie als Antwort).
    const data = <String, String>{
      // St-Wörter
      'Stern': 'St', 'Storch': 'St', 'Stift': 'St', 'Stein': 'St',
      'Stube': 'St', 'Stange': 'St', 'Straße': 'St', 'Stuhl': 'St',
      // Sp-Wörter
      'Spiegel': 'Sp', 'Spinne': 'Sp', 'Sport': 'Sp', 'Spaten': 'Sp',
      'Spatz': 'Sp', 'Sprache': 'Sp', 'Spielzeug': 'Sp', 'Specht': 'Sp',
      // Sch-Wörter (vorher nie als Antwort erreichbar)
      'Schule': 'Sch', 'Schaf': 'Sch', 'Schiff': 'Sch', 'Schnee': 'Sch',
    };
    final entry = data.entries.elementAt(_random.nextInt(data.length));
    return _choiceTask(
        'stsp',
        grade,
        subject,
        'St oder Sp',
        'Welche Buchstaben stehen am Anfang von ${entry.key}?',
        entry.value,
        '${entry.key} beginnt mit den Buchstaben ${entry.value}.',
        customChoices: const <String>['St', 'Sp', 'Sch']);
  }

  LumoTask _writing(int grade, String unit) {
    String prompt;
    String explanation;
    if (unit == 'Zahlen schreiben') {
      // The tracing repository supports 0–20; larger numbers used to display A.
      final n = _random.nextInt(21);
      prompt = 'Schreibe die Zahl $n schön und langsam.';
      explanation = 'Achte auf die Form jeder Ziffer.';
    } else if (unit == 'Buchstaben nachspuren') {
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      final letter = letters[_random.nextInt(letters.length)];
      prompt = 'Spure den Buchstaben $letter nach.';
      explanation = 'Beginne am Startpunkt und folge den Strichen der Vorlage.';
    } else if (unit == 'Schwunguebung') {
      prompt = 'Schreibe: ∿';
      explanation = 'Ziehe eine fließende Wellenlinie von links nach rechts.';
    } else if (unit == 'Satz abschreiben') {
      final options = readingPassages[grade.clamp(1, 4)]!;
      final passage = options[_random.nextInt(options.length)];
      // Copy one complete sentence. Avoid long multi-sentence writing targets.
      final sentence = passage.text.split('.').first;
      prompt = 'Schreibe: $sentence.';
      explanation =
          'Schreibe den ganzen Satz. Achte auf Abstände, den großen Anfang und das Satzzeichen.';
    } else {
      final word = PrimarySchoolWordData.nounForGrade(
          grade, _serial + _random.nextInt(9999));
      prompt = 'Schreibe das Wort: $word';
      explanation = 'Sprich das Wort in Silben und schreibe Teil für Teil.';
    }
    return LumoTask(
        id: _id('schreiben'),
        grade: grade,
        subject: 'Schreiben',
        unit: unit,
        prompt: prompt,
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: explanation,
        handwriting: true,
        visual: 'writing',
        difficulty: grade);
  }

  LumoTask _reading(int grade, String unit) {
    if (unit == 'Bild und Wort') {
      const pictures = <String, String>{
        '🐱': 'Katze',
        '🐶': 'Hund',
        '🐸': 'Frosch',
        '🌳': 'Baum',
        '🌻': 'Blume',
        '🍎': 'Apfel',
        '🐟': 'Fisch',
        '🦋': 'Schmetterling'
      };
      final picture =
          pictures.entries.elementAt(_random.nextInt(pictures.length));
      return _choiceTask(
          'lese-bild',
          grade,
          'Lesen',
          unit,
          'Schau genau: ${picture.key}\nWelches Wort passt zu diesem Bild?',
          picture.value,
          'Das Bild zeigt: ${picture.value}. Lies das passende Wort.',
          customChoices: <String>[
            picture.value,
            ...pictures.values.where((word) => word != picture.value).take(3)
          ]);
    }
    if (unit == 'Woerter lesen') {
      const items = <List<String>>[
        ['Dieses Tier bellt.', 'Hund', 'Katze', 'Maus'],
        ['Du liest darin.', 'Buch', 'Ball', 'Bett'],
        ['Er hat einen Stamm und Blätter.', 'Baum', 'Bach', 'Bauch'],
        ['Sie scheint am Tag am Himmel.', 'Sonne', 'Tonne', 'Wanne'],
        ['Du schreibst damit.', 'Stift', 'Stuhl', 'Stein'],
        ['Es hat zwei Räder und Pedale.', 'Fahrrad', 'Fahrbahn', 'Fahrplan'],
      ];
      final item = items[_random.nextInt(grade == 1 ? 5 : items.length)];
      return _choiceTask(
          'lese-wort',
          grade,
          'Lesen',
          unit,
          'Lies: ${item[0]}\nWelches Wort passt?',
          item[1],
          '${item[1]} passt zur Beschreibung: ${item[0]}',
          customChoices: item.sublist(1));
    }
    if (unit == 'Reihenfolge') {
      final sequence =
          readingSequences[_random.nextInt(readingSequences.length)];
      final position = _random.nextInt(3);
      final asked = ['zuerst', 'als Zweites', 'zuletzt'][position];
      final answer = sequence[position];
      return _choiceTask(
          'lese-reihenfolge',
          grade,
          'Lesen',
          unit,
          '${sequence.join(' ')}\nWas passiert $asked?',
          answer,
          'Lies die Schritte von Anfang bis Ende. $asked passiert: $answer',
          customChoices: sequence);
    }
    final passages = readingPassages[grade.clamp(1, 4)]!;
    final passage = passages[_random.nextInt(passages.length)];
    final check = passage.checks[_random.nextInt(passage.checks.length)];
    return _choiceTask(
        'lese-text',
        grade,
        'Lesen',
        unit,
        '${passage.text}\n${check.question}',
        check.answer,
        'Lies die passende Stelle noch einmal: ${passage.text} '
            'Daraus ergibt sich: ${check.answer}',
        customChoices: [check.answer, ...check.wrong]);
  }

  LumoTask _english(int grade, String unit) {
    // AT-Lehrplan VS Lebende Fremdsprache 2026-06-03: pro Klassenstufe ein
    // eigener Wortschatz. Kleinere Kinder = vertraute Themen + nur 4 Vokabeln.
    // Aeltere Kinder = breiterer Wortschatz mit komplexeren Worten/Verben.
    final capped = grade.clamp(1, 4).toInt();
    // Suche zuerst in der exakten Klassenstufe, sonst Fallback auf vorherige
    // Stufen (alte Themen darf das Kind wiederholen).
    Map<String, String>? map;
    var outputUnit = unit;
    for (var g = capped; g >= 1 && map == null; g--) {
      map = _englishVocabulary[g]?[unit];
    }
    // Wenn die Unit ueberhaupt nicht existiert (Legacy): nimm ein zufaelliges
    // Thema aus der exakten Klassenstufe.
    if (map == null) {
      final levelMaps = _englishVocabulary[capped] ?? _englishVocabulary[1]!;
      final keys = levelMaps.keys.toList(growable: false);
      outputUnit = keys[_random.nextInt(keys.length)];
      map = levelMaps[outputUnit];
    }
    final entry = map!.entries.elementAt(_random.nextInt(map.length));
    final distractors = map.values.where((v) => v != entry.value).toSet().toList()..shuffle(_random);
    return _choiceTask(
        'englisch',
        grade,
        'Englisch',
        outputUnit,
        'Was bedeutet „${entry.key}“?',
        entry.value,
        'Das englische Wort „${entry.key}“ bedeutet ${entry.value}.',
        customChoices: [entry.value, ...distractors.take(3)]);
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
    if (choices.length < 4 && _looksNumeric(answer)) {
      final value = int.tryParse(answer.replaceAll(RegExp('[^0-9-]'), ''));
      if (value != null) {
        for (final offset in <int>[1, -1, 2, -2, 5, -5]) {
          final candidate = '${value + offset}';
          if (!choices.any((item) => _normalizeChoice(item) == _normalizeChoice(candidate)) && value + offset >= 0) choices.add(candidate);
          if (choices.length >= 4) break;
        }
      }
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

  bool _looksNumeric(String value) => RegExp(r'^-?\d+').hasMatch(value);
  int _positive(int seed, int length) => length <= 1 ? 0 : (seed & 0x7fffffff) % length;
  String _normalizeChoice(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

final _englishVocabulary = <int, Map<String, Map<String, String>>>{
  for (var grade = 1; grade <= 4; grade++)
    grade: {
      for (final unit in {..._baseEnglishVocabulary[grade]!.keys, ...englishVocabularyExtensions[grade]!.keys})
        unit: {...?_baseEnglishVocabulary[grade]![unit], ...?englishVocabularyExtensions[grade]![unit]},
    },
};

const _baseEnglishVocabulary = <int, Map<String, Map<String, String>>>{
  1: <String, Map<String, String>>{
    'Farben': <String, String>{
      'red': 'rot',
      'blue': 'blau',
      'green': 'grün',
      'yellow': 'gelb'
    },
    'Tiere': <String, String>{
      'dog': 'Hund',
      'cat': 'Katze',
      'bird': 'Vogel',
      'fish': 'Fisch'
    },
    'Begruessung': <String, String>{
      'hello': 'hallo',
      'goodbye': 'auf Wiedersehen',
      'please': 'bitte',
      'thanks': 'danke'
    },
    'Familie': <String, String>{
      'mother': 'Mutter',
      'father': 'Vater',
      'sister': 'Schwester',
      'brother': 'Bruder'
    },
    'Zahlen': <String, String>{
      'one': 'eins',
      'two': 'zwei',
      'three': 'drei',
      'four': 'vier'
    },
    'Körper': <String, String>{
      'hand': 'Hand',
      'foot': 'Fuß',
      'eye': 'Auge',
      'ear': 'Ohr'
    },
    'Schulsachen': <String, String>{
      'book': 'Buch',
      'pen': 'Stift',
      'bag': 'Tasche',
      'ruler': 'Lineal'
    },
  },
  2: <String, Map<String, String>>{
    'Zahlen': <String, String>{
      'one': 'eins',
      'two': 'zwei',
      'three': 'drei',
      'four': 'vier',
      'five': 'fünf'
    },
    'Körper': <String, String>{
      'hand': 'Hand',
      'foot': 'Fuß',
      'eye': 'Auge',
      'ear': 'Ohr',
      'nose': 'Nase'
    },
    'Spielzeug': <String, String>{
      'ball': 'Ball',
      'doll': 'Puppe',
      'car': 'Auto',
      'kite': 'Drachen'
    },
    'Tiere': <String, String>{
      'horse': 'Pferd',
      'cow': 'Kuh',
      'pig': 'Schwein',
      'sheep': 'Schaf',
      'mouse': 'Maus'
    },
  },
  3: <String, Map<String, String>>{
    'Schulsachen': <String, String>{
      'book': 'Buch',
      'pen': 'Stift',
      'bag': 'Tasche',
      'ruler': 'Lineal',
      'desk': 'Tisch'
    },
    'Wetter': <String, String>{
      'sun': 'Sonne',
      'rain': 'Regen',
      'snow': 'Schnee',
      'wind': 'Wind',
      'cloud': 'Wolke'
    },
    'Essen': <String, String>{
      'apple': 'Apfel',
      'bread': 'Brot',
      'milk': 'Milch',
      'water': 'Wasser',
      'cheese': 'Käse'
    },
    'Tageszeit': <String, String>{
      'morning': 'Morgen',
      'evening': 'Abend',
      'night': 'Nacht',
      'today': 'heute'
    },
  },
  4: <String, Map<String, String>>{
    'Verben': <String, String>{
      'run': 'laufen',
      'jump': 'springen',
      'eat': 'essen',
      'drink': 'trinken',
      'read': 'lesen',
      'write': 'schreiben'
    },
    'Wochentage': <String, String>{
      'Monday': 'Montag',
      'Tuesday': 'Dienstag',
      'Friday': 'Freitag',
      'Saturday': 'Samstag',
      'Sunday': 'Sonntag'
    },
    'Hobbys': <String, String>{
      'football': 'Fußball',
      'music': 'Musik',
      'painting': 'Malen',
      'dancing': 'Tanzen',
      'reading': 'Lesen'
    },
    'Länder': <String, String>{
      'Austria': 'Österreich',
      'Germany': 'Deutschland',
      'England': 'England',
      'France': 'Frankreich'
    },
  },
};

const Map<String, List<String>> _scienceAliases = <String, List<String>>{
  'Pflanzen': <String>['Pflanzen'],
  'Tiere': <String>['Tiere'],
  'Wetter': <String>['Wetter'],
  'Körper': <String>['Körper'],
  'Verkehr': <String>['Verkehr'],
  'Jahreszeiten': <String>['Jahreszeiten'],
};

const List<ScienceQuestion> _scienceQuestions = <ScienceQuestion>[
  ...scienceExtensionQuestions,
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Vogel?', answer: 'Spatz', choices: <String>['Spatz', 'Kuh', 'Fisch', 'Ameise'], explanation: 'Ein Spatz hat Federn und Flügel.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Fisch?', answer: 'Forelle', choices: <String>['Forelle', 'Hund', 'Biene', 'Hase'], explanation: 'Fische leben im Wasser und haben Flossen.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Insekt?', answer: 'Biene', choices: <String>['Biene', 'Katze', 'Frosch', 'Schaf'], explanation: 'Insekten haben sechs Beine.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Säugetier?', answer: 'Hund', choices: <String>['Hund', 'Ente', 'Forelle', 'Käfer'], explanation: 'Säugetiere säugen ihre Jungen.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier lebt am Bauernhof?', answer: 'Kuh', choices: <String>['Kuh', 'Wal', 'Pinguin', 'Koralle'], explanation: 'Kühe leben häufig am Bauernhof.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'In welcher Jahreszeit fällt oft Schnee?', answer: 'Winter', choices: <String>['Winter', 'Sommer', 'Frühling', 'Herbst'], explanation: 'Im Winter ist es kalt, oft schneit es.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann blühen viele Blumen neu?', answer: 'Frühling', choices: <String>['Frühling', 'Winter', 'Herbst', 'Nacht'], explanation: 'Im Frühling beginnen viele Pflanzen zu blühen.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann sind die Tage oft heiß?', answer: 'Sommer', choices: <String>['Sommer', 'Winter', 'Herbst', 'Morgen'], explanation: 'Im Sommer ist es oft warm bis heiß.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann fallen viele bunte Blätter?', answer: 'Herbst', choices: <String>['Herbst', 'Sommer', 'Frühling', 'Mittag'], explanation: 'Im Herbst verfärben sich viele Blätter.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was fällt aus Wolken als Wasser?', answer: 'Regen', choices: <String>['Regen', 'Wind', 'Sonne', 'Nebel'], explanation: 'Regen besteht aus Wassertropfen.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was hörst du bei einem Gewitter?', answer: 'Donner', choices: <String>['Donner', 'Schnee', 'Nebel', 'Regenbogen'], explanation: 'Donner ist das laute Geräusch beim Gewitter.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was sieht man nach Regen und Sonne manchmal?', answer: 'Regenbogen', choices: <String>['Regenbogen', 'Frost', 'Nacht', 'Stein'], explanation: 'Ein Regenbogen entsteht durch Sonne und Regentropfen.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was bewegt Blätter in der Luft?', answer: 'Wind', choices: <String>['Wind', 'Mond', 'Sand', 'Eis'], explanation: 'Wind ist bewegte Luft.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was hat einen Stamm und Äste?', answer: 'Baum', choices: <String>['Baum', 'Blume', 'Stein', 'Fisch'], explanation: 'Ein Baum hat Stamm, Äste und Blätter.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was wächst oft bunt im Garten?', answer: 'Blume', choices: <String>['Blume', 'Auto', 'Hund', 'Sackerl'], explanation: 'Blumen blühen oft bunt.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Welcher Teil einer Pflanze ist meist grün?', answer: 'Blatt', choices: <String>['Blatt', 'Rad', 'Schuh', 'Ball'], explanation: 'Blätter sind oft grün und fangen Licht ein.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was braucht eine Pflanze zum Wachsen?', answer: 'Wasser', choices: <String>['Wasser', 'Fernseher', 'Schere', 'Helm'], explanation: 'Pflanzen brauchen Wasser, Licht und Erde.'),
  ScienceQuestion(grade: 1, unit: 'Tag und Nacht', prompt: 'Wann ist es meistens dunkel?', answer: 'Nacht', choices: <String>['Nacht', 'Mittag', 'Sommer', 'Pause'], explanation: 'In der Nacht ist die Sonne nicht zu sehen.'),
  ScienceQuestion(grade: 1, unit: 'Tag und Nacht', prompt: 'Was leuchtet am Tag hell am Himmel?', answer: 'Sonne', choices: <String>['Sonne', 'Tisch', 'Kuh', 'Schuh'], explanation: 'Die Sonne gibt Licht und Wärme.'),
  ScienceQuestion(grade: 1, unit: 'Körper', prompt: 'Womit siehst du?', answer: 'Auge', choices: <String>['Auge', 'Ohr', 'Hand', 'Fuß'], explanation: 'Mit den Augen sehen wir.'),
  ScienceQuestion(grade: 1, unit: 'Körper', prompt: 'Womit hörst du?', answer: 'Ohr', choices: <String>['Ohr', 'Nase', 'Knie', 'Bauch'], explanation: 'Mit den Ohren hören wir.'),
  ScienceQuestion(grade: 1, unit: 'Verkehr', prompt: 'Bei welcher Ampelfarbe darf man gehen?', answer: 'Grün', choices: <String>['Grün', 'Rot', 'Blau', 'Schwarz'], explanation: 'Grün bedeutet: gehen, wenn der Weg frei ist.'),
  ScienceQuestion(grade: 1, unit: 'Familie und Gemeinschaft', prompt: 'Was sagt man, wenn man Hilfe bekommt?', answer: 'Danke', choices: <String>['Danke', 'Stopp', 'Aua', 'Nein'], explanation: 'Danke ist höflich und freundlich.'),
  ScienceQuestion(grade: 1, unit: 'Zeit und Kalender', prompt: 'Welcher Tag kommt nach Montag?', answer: 'Dienstag', choices: <String>['Dienstag', 'Sonntag', 'Freitag', 'Jänner'], explanation: 'Nach Montag kommt Dienstag.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Schwein?', answer: 'Ferkel', choices: <String>['Ferkel', 'Kalb', 'Fohlen', 'Lamm'], explanation: 'Ein junges Schwein heißt Ferkel.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby von der Kuh?', answer: 'Kalb', choices: <String>['Kalb', 'Ferkel', 'Küken', 'Fohlen'], explanation: 'Ein junges Rind heißt Kalb.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Pferd?', answer: 'Fohlen', choices: <String>['Fohlen', 'Kalb', 'Lamm', 'Küken'], explanation: 'Ein junges Pferd heißt Fohlen.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Huhn?', answer: 'Küken', choices: <String>['Küken', 'Ferkel', 'Kalb', 'Welpe'], explanation: 'Ein junges Huhn heißt Küken.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo lebt ein Fisch meistens?', answer: 'im Wasser', choices: <String>['im Wasser', 'im Baum', 'im Nest', 'im Heft'], explanation: 'Fische leben im Wasser.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo bauen viele Vögel ihr Nest?', answer: 'im Baum', choices: <String>['im Baum', 'im Schuh', 'im Topfen', 'im Bus'], explanation: 'Viele Vögel bauen Nester auf Bäumen.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo lebt der Fuchs häufig?', answer: 'im Wald', choices: <String>['im Wald', 'im Meer', 'im Federpennal', 'im Glas'], explanation: 'Füchse leben häufig im Wald.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Welches Tier sammelt Nektar?', answer: 'Biene', choices: <String>['Biene', 'Kuh', 'Hund', 'Forelle'], explanation: 'Bienen besuchen Blüten und sammeln Nektar.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welcher Pflanzenteil nimmt Wasser auf?', answer: 'Wurzel', choices: <String>['Wurzel', 'Blüte', 'Frucht', 'Ast'], explanation: 'Wurzeln nehmen Wasser aus der Erde auf.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welcher Teil trägt Blätter und Blüten?', answer: 'Stamm', choices: <String>['Stamm', 'Schuh', 'Kabel', 'Topf'], explanation: 'Der Stamm oder Stängel trägt andere Pflanzenteile.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Woraus kann eine neue Pflanze wachsen?', answer: 'Samen', choices: <String>['Samen', 'Stein', 'Münze', 'Knopf'], explanation: 'Aus Samen können neue Pflanzen wachsen.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Was lockt oft Bienen an?', answer: 'Blüte', choices: <String>['Blüte', 'Reifen', 'Buch', 'Helm'], explanation: 'Blüten locken Insekten an.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was bedeutet eine rote Ampel?', answer: 'stehen bleiben', choices: <String>['stehen bleiben', 'laufen', 'singen', 'springen'], explanation: 'Rot bedeutet Halt.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was bedeutet ein Stoppschild?', answer: 'anhalten', choices: <String>['anhalten', 'schneller fahren', 'hupen', 'umdrehen'], explanation: 'Bei Stopp muss man anhalten.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Wo überquert man sicherer die Straße?', answer: 'Zebrastreifen', choices: <String>['Zebrastreifen', 'Spielplatz', 'Wiese', 'Küche'], explanation: 'Ein Zebrastreifen hilft beim sicheren Überqueren.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was trägt man beim Radfahren zum Schutz?', answer: 'Helm', choices: <String>['Helm', 'Haube', 'Schal', 'Sackerl'], explanation: 'Ein Helm schützt den Kopf.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer löscht Brände?', answer: 'Feuerwehr', choices: <String>['Feuerwehr', 'Bäcker', 'Gärtner', 'Pilot'], explanation: 'Die Feuerwehr hilft bei Bränden.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer backt Semmeln und Brot?', answer: 'Bäckerin oder Bäcker', choices: <String>['Bäckerin oder Bäcker', 'Ärztin', 'Postler', 'Tischler'], explanation: 'Bäckerinnen und Bäcker backen Brot und Semmeln.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer hilft kranken Menschen?', answer: 'Ärztin oder Arzt', choices: <String>['Ärztin oder Arzt', 'Maurer', 'Pilotin', 'Schneider'], explanation: 'Ärztinnen und Ärzte behandeln kranke Menschen.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer bringt Briefe und Pakete?', answer: 'Postlerin oder Postler', choices: <String>['Postlerin oder Postler', 'Friseur', 'Koch', 'Lehrer'], explanation: 'Die Post stellt Briefe und Pakete zu.'),
  ScienceQuestion(grade: 2, unit: 'Wetter', prompt: 'Was misst ein Thermometer?', answer: 'Temperatur', choices: <String>['Temperatur', 'Länge', 'Geld', 'Lautstärke'], explanation: 'Ein Thermometer zeigt warm oder kalt an.'),
  ScienceQuestion(grade: 2, unit: 'Wetter', prompt: 'Was ist Nebel?', answer: 'Wolken nahe am Boden', choices: <String>['Wolken nahe am Boden', 'Sand im Glas', 'heißer Wind', 'lauter Donner'], explanation: 'Nebel besteht aus kleinen Wassertröpfchen in Bodennähe.'),
  ScienceQuestion(grade: 2, unit: 'Jahreszeiten', prompt: 'Wie viele Jahreszeiten hat ein Jahr?', answer: '4', choices: <String>['4', '2', '7', '12'], explanation: 'Frühling, Sommer, Herbst und Winter sind vier Jahreszeiten.'),
  ScienceQuestion(grade: 2, unit: 'Zeit und Kalender', prompt: 'Wie viele Monate hat ein Jahr?', answer: '12', choices: <String>['12', '7', '4', '24'], explanation: 'Ein Jahr hat zwölf Monate.'),
  ScienceQuestion(grade: 2, unit: 'Körper', prompt: 'Womit riechst du?', answer: 'Nase', choices: <String>['Nase', 'Ohr', 'Knie', 'Hand'], explanation: 'Mit der Nase riechen wir.'),
  ScienceQuestion(grade: 2, unit: 'Körper', prompt: 'Womit schmeckst du?', answer: 'Zunge', choices: <String>['Zunge', 'Auge', 'Fuß', 'Haar'], explanation: 'Mit der Zunge schmecken wir.'),
  ScienceQuestion(grade: 2, unit: 'Familie und Gemeinschaft', prompt: 'Was hilft bei Streit?', answer: 'ruhig reden', choices: <String>['ruhig reden', 'schubsen', 'weglaufen ohne Erklärung', 'auslachen'], explanation: 'Ruhiges Reden hilft beim Lösen von Streit.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welche Frucht ist typisch österreichisch als Marille bekannt?', answer: 'Aprikose heißt in Österreich Marille', choices: <String>['Aprikose heißt in Österreich Marille', 'Banane heißt Marille', 'Topfen heißt Marille', 'Semmel heißt Marille'], explanation: 'In Österreich sagt man Marille.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Welches Tier ist nachtaktiv?', answer: 'Eule', choices: <String>['Eule', 'Huhn', 'Kuh', 'Schaf'], explanation: 'Eulen sind oft nachts unterwegs.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Auf welcher Seite geht man am Gehsteig besonders aufmerksam?', answer: 'weg von der Fahrbahn', choices: <String>['weg von der Fahrbahn', 'mitten auf der Straße', 'auf Schienen', 'im Kreisverkehr'], explanation: 'Am Gehsteig bleibt man weg von der Fahrbahn.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer baut Mauern?', answer: 'Maurer', choices: <String>['Maurer', 'Bäcker', 'Ärztin', 'Pilot'], explanation: 'Maurer bauen Mauern und Gebäude.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer arbeitet mit Metall?', answer: 'Schlosser', choices: <String>['Schlosser', 'Gärtner', 'Lehrer', 'Postler'], explanation: 'Schlosser arbeiten oft mit Metall.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welches Organ pumpt Blut?', answer: 'Herz', choices: <String>['Herz', 'Magen', 'Lunge', 'Haut'], explanation: 'Das Herz pumpt Blut durch den Körper.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welches Organ hilft beim Atmen?', answer: 'Lunge', choices: <String>['Lunge', 'Herz', 'Darm', 'Knochen'], explanation: 'Die Lunge nimmt Sauerstoff auf.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Womit verdauen wir Nahrung weiter?', answer: 'Magen und Darm', choices: <String>['Magen und Darm', 'Auge und Ohr', 'Hand und Fuß', 'Haut und Haar'], explanation: 'Magen und Darm helfen bei der Verdauung.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welche fünf Sinne haben wir?', answer: 'sehen, hören, riechen, schmecken, fühlen', choices: <String>['sehen, hören, riechen, schmecken, fühlen', 'laufen, springen, sitzen, stehen, liegen', 'essen, trinken, schlafen, malen, rechnen', 'rot, blau, grün, gelb, weiß'], explanation: 'Die Sinne helfen uns, die Umwelt wahrzunehmen.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was sollte man oft trinken?', answer: 'Wasser', choices: <String>['Wasser', 'Limo', 'Sirup', 'Eistee'], explanation: 'Wasser ist ein gesundes Getränk.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was gehört zur Obstgruppe?', answer: 'Apfel', choices: <String>['Apfel', 'Hammer', 'Schuh', 'Kabel'], explanation: 'Äpfel sind Obst.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was gibt Energie, soll aber nicht zu viel gegessen werden?', answer: 'Zucker', choices: <String>['Zucker', 'Wasser', 'Salat', 'Luft'], explanation: 'Zu viel Zucker ist ungesund.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was enthält viele Vitamine?', answer: 'Gemüse und Obst', choices: <String>['Gemüse und Obst', 'Steine', 'Plastik', 'Batterien'], explanation: 'Obst und Gemüse enthalten viele Vitamine.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Was passiert, wenn Wasser durch Sonne gasförmig wird?', answer: 'Verdunstung', choices: <String>['Verdunstung', 'Gefrieren', 'Schneiden', 'Messen'], explanation: 'Verdunstung macht aus Wasser Wasserdampf.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Wie nennt man Regen, Schnee oder Hagel zusammen?', answer: 'Niederschlag', choices: <String>['Niederschlag', 'Stromkreis', 'Nahrungskette', 'Hauptstadt'], explanation: 'Niederschlag fällt aus Wolken.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Wohin fließt ein Bach oft?', answer: 'in einen Fluss', choices: <String>['in einen Fluss', 'in ein Heft', 'in eine Lampe', 'in ein Sackerl'], explanation: 'Bäche fließen oft in größere Gewässer.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Was sammelt sich zu Wolken?', answer: 'Wasserdampf', choices: <String>['Wasserdampf', 'Sand', 'Holz', 'Metall'], explanation: 'Wasserdampf kann Wolken bilden.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tierklasse hat Federn?', answer: 'Vögel', choices: <String>['Vögel', 'Fische', 'Insekten', 'Säugetiere'], explanation: 'Vögel haben Federn.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tierklasse hat Schuppen und lebt im Wasser?', answer: 'Fische', choices: <String>['Fische', 'Vögel', 'Spinnen', 'Säugetiere'], explanation: 'Viele Fische haben Schuppen und Kiemen.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tiere haben sechs Beine?', answer: 'Insekten', choices: <String>['Insekten', 'Säugetiere', 'Fische', 'Vögel'], explanation: 'Insekten haben sechs Beine.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tiere säugen ihre Jungen?', answer: 'Säugetiere', choices: <String>['Säugetiere', 'Fische', 'Insekten', 'Vögel'], explanation: 'Säugetiere geben den Jungen Milch.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Wie viele Bundesländer hat Österreich?', answer: '9', choices: <String>['9', '7', '10', '12'], explanation: 'Österreich hat neun Bundesländer.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'In welchem Bundesland liegt Gänserndorf?', answer: 'Niederösterreich', choices: <String>['Niederösterreich', 'Tirol', 'Kärnten', 'Vorarlberg'], explanation: 'Gänserndorf liegt in Niederösterreich.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Wie heißt die Bundeshauptstadt von Österreich?', answer: 'Wien', choices: <String>['Wien', 'Berlin', 'Graz', 'St. Pölten'], explanation: 'Die Bundeshauptstadt Österreichs ist Wien.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Stadt ist Hauptstadt von Niederösterreich?', answer: 'St. Pölten', choices: <String>['St. Pölten', 'Wien', 'Linz', 'Eisenstadt'], explanation: 'St. Pölten ist Landeshauptstadt von Niederösterreich.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welches Bundesland liegt ganz im Osten Österreichs?', answer: 'Burgenland', choices: <String>['Burgenland', 'Tirol', 'Vorarlberg', 'Salzburg'], explanation: 'Das Burgenland liegt im Osten.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Bundesländer grenzen an Niederösterreich?', answer: 'Wien, Oberösterreich, Steiermark, Burgenland', choices: <String>['Wien, Oberösterreich, Steiermark, Burgenland', 'Tirol und Vorarlberg', 'Kärnten und Salzburg', 'nur Wien'], explanation: 'Niederösterreich umgibt Wien und grenzt an mehrere Bundesländer.'),
  ScienceQuestion(grade: 3, unit: 'Verkehr', prompt: 'Was bedeutet Vorrang?', answer: 'jemand darf zuerst fahren oder gehen', choices: <String>['jemand darf zuerst fahren oder gehen', 'alle fahren gleichzeitig', 'niemand schaut', 'nur Autos zählen'], explanation: 'Vorrang regelt, wer zuerst darf.'),
  ScienceQuestion(grade: 3, unit: 'Zeit und Kalender', prompt: 'Was ist ein Kalender?', answer: 'eine Übersicht über Tage, Wochen und Monate', choices: <String>['eine Übersicht über Tage, Wochen und Monate', 'ein Werkzeug zum Sägen', 'ein Tierbuch', 'ein Verkehrsschild'], explanation: 'Ein Kalender ordnet Zeit.'),
  ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Welche Aufgabe hat die Blüte?', answer: 'sie hilft bei der Fortpflanzung', choices: <String>['sie hilft bei der Fortpflanzung', 'sie bremst Autos', 'sie pumpt Blut', 'sie misst Wärme'], explanation: 'Aus Blüten können Früchte und Samen entstehen.'),
  ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Was schützt den Boden und wird aus Pflanzenresten?', answer: 'Humus', choices: <String>['Humus', 'Plastik', 'Glas', 'Metall'], explanation: 'Humus entsteht aus zersetzten Pflanzenresten.'),
  ScienceQuestion(grade: 3, unit: 'Wetter', prompt: 'Was zeigt die Windrichtung?', answer: 'woher der Wind kommt', choices: <String>['woher der Wind kommt', 'wie alt der Wind ist', 'welche Farbe Wind hat', 'wie schwer Sonne ist'], explanation: 'Windrichtung beschreibt, woher Wind weht.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Warum putzen wir Zähne?', answer: 'damit sie gesund bleiben', choices: <String>['damit sie gesund bleiben', 'damit sie wachsen wie Haare', 'damit sie hören', 'damit sie leuchten'], explanation: 'Zähneputzen schützt vor Karies.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was ist eine ausgewogene Jause?', answer: 'Semmel, Käse, Gemüse und Wasser', choices: <String>['Semmel, Käse, Gemüse und Wasser', 'nur Zuckerln', 'nur Limo', 'nur Schlagobers'], explanation: 'Eine gute Jause hat verschiedene gesunde Teile.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Warum brauchen Tiere einen Lebensraum?', answer: 'für Nahrung, Schutz und Nachwuchs', choices: <String>['für Nahrung, Schutz und Nachwuchs', 'für Hefte', 'für Ampeln', 'für Geld'], explanation: 'Ein Lebensraum deckt wichtige Bedürfnisse.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Was ist Grundwasser?', answer: 'Wasser unter der Erde', choices: <String>['Wasser unter der Erde', 'Wasser im Fernseher', 'Wasser in der Sonne', 'Wasser aus Metall'], explanation: 'Grundwasser befindet sich im Boden.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Farbe hat die österreichische Flagge?', answer: 'rot-weiß-rot', choices: <String>['rot-weiß-rot', 'schwarz-rot-gold', 'blau-gelb', 'grün-weiß-grün'], explanation: 'Österreichs Flagge ist rot-weiß-rot.'),
  ScienceQuestion(grade: 3, unit: 'Familie und Gemeinschaft', prompt: 'Was ist eine Regel?', answer: 'eine Vereinbarung, wie man handelt', choices: <String>['eine Vereinbarung, wie man handelt', 'ein Tier', 'ein Möbelstück', 'ein Fluss'], explanation: 'Regeln helfen beim Zusammenleben.'),
  ScienceQuestion(grade: 3, unit: 'Berufe', prompt: 'Wer hilft bei einem Unfall?', answer: 'Rettung', choices: <String>['Rettung', 'Bäckerei', 'Bibliothek', 'Schneiderei'], explanation: 'Die Rettung hilft medizinisch.'),
  ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Welche Pflanze trägt Äpfel?', answer: 'Apfelbaum', choices: <String>['Apfelbaum', 'Tanne', 'Rose', 'Gras'], explanation: 'Äpfel wachsen auf Apfelbäumen.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Was schützt unsere inneren Organe außen?', answer: 'Haut', choices: <String>['Haut', 'Schuh', 'Heft', 'Sackerl'], explanation: 'Die Haut schützt den Körper.'),
  ScienceQuestion(grade: 3, unit: 'Wetter', prompt: 'Was ist Frost?', answer: 'gefrorene Feuchtigkeit bei Kälte', choices: <String>['gefrorene Feuchtigkeit bei Kälte', 'heißer Regen', 'lauter Wind', 'bunter Nebel'], explanation: 'Frost entsteht bei Kälte.'),
  ScienceQuestion(grade: 3, unit: 'Verkehr', prompt: 'Warum sind Reflektoren wichtig?', answer: 'man wird besser gesehen', choices: <String>['man wird besser gesehen', 'man fährt schneller', 'man hört besser', 'man spart Geld'], explanation: 'Reflektoren machen im Dunkeln sichtbar.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was ist Topfen?', answer: 'ein Milchprodukt', choices: <String>['ein Milchprodukt', 'ein Werkzeug', 'ein Fahrzeug', 'ein Bundesland'], explanation: 'Topfen ist ein österreichisches Milchprodukt.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welches Bundesland hat Eisenstadt als Hauptstadt?', answer: 'Burgenland', choices: <String>['Burgenland', 'Tirol', 'Wien', 'Salzburg'], explanation: 'Eisenstadt ist Hauptstadt des Burgenlands.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie heißt der höchste Berg Österreichs?', answer: 'Großglockner', choices: <String>['Großglockner', 'Ötscher', 'Schneeberg', 'Rax'], explanation: 'Der Großglockner ist Österreichs höchster Berg.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welcher große Fluss fließt durch Wien?', answer: 'Donau', choices: <String>['Donau', 'Rhein', 'Elbe', 'Themse'], explanation: 'Die Donau fließt durch Wien.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie heißt Österreichs Bundeshauptstadt?', answer: 'Wien', choices: <String>['Wien', 'Berlin', 'Graz', 'Linz'], explanation: 'Wien ist die Bundeshauptstadt.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie viele Bundesländer hat Österreich?', answer: '9', choices: <String>['9', '8', '10', '11'], explanation: 'Österreich hat neun Bundesländer.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welcher See liegt im Osten Österreichs?', answer: 'Neusiedler See', choices: <String>['Neusiedler See', 'Bodensee', 'Attersee', 'Wörthersee'], explanation: 'Der Neusiedler See liegt im Burgenland und in Ungarn.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'An welches Land grenzt Niederösterreich im Norden?', answer: 'Tschechien', choices: <String>['Tschechien', 'Italien', 'Schweiz', 'Slowenien'], explanation: 'Niederösterreich grenzt im Norden an Tschechien.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Landeshauptstadt gehört zur Steiermark?', answer: 'Graz', choices: <String>['Graz', 'Linz', 'Innsbruck', 'Bregenz'], explanation: 'Graz ist die Hauptstadt der Steiermark.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Landeshauptstadt gehört zu Tirol?', answer: 'Innsbruck', choices: <String>['Innsbruck', 'Klagenfurt', 'St. Pölten', 'Eisenstadt'], explanation: 'Innsbruck ist die Hauptstadt von Tirol.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'In welcher Zeit lebten Menschen als Jäger und Sammler?', answer: 'Steinzeit', choices: <String>['Steinzeit', 'Mittelalter', 'Neuzeit', 'Zukunft'], explanation: 'In der Steinzeit jagten und sammelten viele Menschen.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was war im Mittelalter oft auf einem Hügel gebaut?', answer: 'Burg', choices: <String>['Burg', 'Flughafen', 'U-Bahn', 'Computerraum'], explanation: 'Burgen boten Schutz.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Wer trug im Mittelalter oft Rüstung?', answer: 'Ritter', choices: <String>['Ritter', 'Pilot', 'Programmierer', 'Schaffner'], explanation: 'Ritter trugen Rüstungen.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was hilft uns, Vergangenes zu verstehen?', answer: 'Quellen', choices: <String>['Quellen', 'Ampeln', 'Batterien', 'Jausenboxen'], explanation: 'Historische Quellen erzählen über früher.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was ist Archäologie?', answer: 'Wissenschaft von alten Funden', choices: <String>['Wissenschaft von alten Funden', 'Sport im Schnee', 'Kochen mit Topfen', 'Fahren mit Bus'], explanation: 'Archäologie untersucht Funde aus der Vergangenheit.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Wie viele Kontinente lernen viele Schulkarten?', answer: '7', choices: <String>['7', '3', '9', '12'], explanation: 'Oft werden sieben Kontinente unterschieden.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Auf welchem Kontinent liegt Österreich?', answer: 'Europa', choices: <String>['Europa', 'Afrika', 'Asien', 'Australien'], explanation: 'Österreich liegt in Europa.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Welcher Ozean ist der größte?', answer: 'Pazifik', choices: <String>['Pazifik', 'Atlantik', 'Indischer Ozean', 'Arktischer Ozean'], explanation: 'Der Pazifik ist der größte Ozean.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Was ist ein Ozean?', answer: 'ein sehr großes Meer', choices: <String>['ein sehr großes Meer', 'ein kleiner Bach', 'ein Berg', 'ein Bundesland'], explanation: 'Ozeane sind riesige Meere.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was zeigt eine Nahrungskette?', answer: 'wer wen frisst', choices: <String>['wer wen frisst', 'wer welches Heft hat', 'wer zuerst fährt', 'wer lauter singt'], explanation: 'Nahrungsketten zeigen Energiefluss.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was machen Zersetzer?', answer: 'sie bauen tote Reste ab', choices: <String>['sie bauen tote Reste ab', 'sie bauen Straßen', 'sie schreiben Briefe', 'sie löschen Brände'], explanation: 'Zersetzer helfen, Stoffe zurück in den Boden zu bringen.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was ist ein Lebensraum?', answer: 'Ort, an dem Lebewesen leben', choices: <String>['Ort, an dem Lebewesen leben', 'ein Rechenzeichen', 'ein Kleidungsstück', 'eine Uhrzeit'], explanation: 'Lebensräume bieten Nahrung und Schutz.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Warum sind Bienen wichtig?', answer: 'sie bestäuben viele Pflanzen', choices: <String>['sie bestäuben viele Pflanzen', 'sie fahren Bus', 'sie drucken Bücher', 'sie bauen Mauern'], explanation: 'Bestäubung hilft Pflanzen bei Früchten und Samen.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was braucht ein einfacher Stromkreis?', answer: 'Batterie, Kabel, Lampe und Schalter', choices: <String>['Batterie, Kabel, Lampe und Schalter', 'Semmel, Topfen und Saft', 'Buch, Heft und Lineal', 'Apfel, Birne und Banane'], explanation: 'Ein geschlossener Stromkreis lässt Strom fließen.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Wann leuchtet die Lampe im Stromkreis?', answer: 'wenn der Kreis geschlossen ist', choices: <String>['wenn der Kreis geschlossen ist', 'wenn das Kabel fehlt', 'wenn die Batterie leer ist', 'wenn der Schalter offen ist'], explanation: 'Strom fließt nur im geschlossenen Kreis.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was leitet Strom gut?', answer: 'Metall', choices: <String>['Metall', 'Holz', 'Plastik', 'Papier'], explanation: 'Metalle leiten Strom meist gut.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was ist ein Nichtleiter?', answer: 'Plastik', choices: <String>['Plastik', 'Kupfer', 'Eisen', 'Aluminium'], explanation: 'Plastik leitet Strom schlecht.'),
  ScienceQuestion(grade: 4, unit: 'Diagramme lesen', prompt: 'Was zeigt ein Säulendiagramm?', answer: 'Werte als Balken', choices: <String>['Werte als Balken', 'nur Wörter', 'nur Landkarten', 'nur Uhrzeiten'], explanation: 'Balken machen Mengen vergleichbar.'),
  ScienceQuestion(grade: 4, unit: 'Diagramme lesen', prompt: 'Welche Säule zeigt den größten Wert?', answer: 'die höchste Säule', choices: <String>['die höchste Säule', 'die kürzeste Säule', 'die linke immer', 'die bunte immer'], explanation: 'Höhere Säule bedeutet größerer Wert.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Hymne gehört zu Österreich?', answer: 'Bundeshymne', choices: <String>['Bundeshymne', 'Vereinshymne', 'Schullied', 'Geburtstagslied'], explanation: 'Österreich hat eine Bundeshymne.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Stadt ist Hauptstadt von Oberösterreich?', answer: 'Linz', choices: <String>['Linz', 'Graz', 'Bregenz', 'Klagenfurt'], explanation: 'Linz ist Hauptstadt von Oberösterreich.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Stadt ist Hauptstadt von Kärnten?', answer: 'Klagenfurt', choices: <String>['Klagenfurt', 'Salzburg', 'Wien', 'Eisenstadt'], explanation: 'Klagenfurt ist Kärntens Landeshauptstadt.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Was ist der Äquator?', answer: 'gedachte Linie um die Erde', choices: <String>['gedachte Linie um die Erde', 'ein Fluss in Wien', 'ein Berg in Tirol', 'ein Werkzeug'], explanation: 'Der Äquator teilt die Erde in Nord und Süd.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was ist eine Zeitleiste?', answer: 'eine geordnete Darstellung von Ereignissen', choices: <String>['eine geordnete Darstellung von Ereignissen', 'ein Messbecher', 'ein Stromkabel', 'ein Verkehrsschild'], explanation: 'Zeitleisten ordnen Ereignisse nach Zeit.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was bedeutet nachhaltig?', answer: 'so handeln, dass die Zukunft geschützt wird', choices: <String>['so handeln, dass die Zukunft geschützt wird', 'alles sofort verbrauchen', 'Müll in den Bach werfen', 'Licht immer brennen lassen'], explanation: 'Nachhaltigkeit denkt an morgen.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Warum soll man nicht an Steckdosen spielen?', answer: 'Strom kann gefährlich sein', choices: <String>['Strom kann gefährlich sein', 'Steckdosen sind essbar', 'Steckdosen machen Musik', 'Strom ist immer kalt'], explanation: 'Strom aus Steckdosen ist gefährlich.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Hauptstadt gehört zu Vorarlberg?', answer: 'Bregenz', choices: <String>['Bregenz', 'Innsbruck', 'Linz', 'St. Pölten'], explanation: 'Bregenz ist Hauptstadt von Vorarlberg.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Hauptstadt gehört zu Salzburg?', answer: 'Salzburg', choices: <String>['Salzburg', 'Graz', 'Wien', 'Klagenfurt'], explanation: 'Salzburg ist Stadt und Bundesland-Hauptstadt.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Welcher Kontinent ist sehr kalt und am Südpol?', answer: 'Antarktis', choices: <String>['Antarktis', 'Afrika', 'Europa', 'Asien'], explanation: 'Die Antarktis liegt am Südpol.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was war ein Handwerk im Mittelalter?', answer: 'Schmieden', choices: <String>['Schmieden', 'Programmieren', 'Fernsehen', 'Autofahren'], explanation: 'Schmiede stellten Dinge aus Metall her.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was schützt ein Wald?', answer: 'Boden, Tiere und Klima', choices: <String>['Boden, Tiere und Klima', 'nur Autos', 'nur Computer', 'nur Ampeln'], explanation: 'Wälder sind wichtige Lebensräume.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was macht ein Schalter?', answer: 'er öffnet oder schließt den Stromkreis', choices: <String>['er öffnet oder schließt den Stromkreis', 'er kocht Suppe', 'er misst Zeit', 'er schreibt Wörter'], explanation: 'Schalter steuern, ob Strom fließt.'),
];
