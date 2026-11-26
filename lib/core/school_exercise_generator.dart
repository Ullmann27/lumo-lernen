import 'dart:math';

import 'adventure/lumo_adventure_tasks.dart';
import 'curriculum/learning_level.dart';
import 'curriculum/math_unit_order.dart';
import 'data_chart_exercise.dart' show DataChartExercise;
import 'german_task_templates.dart';
import 'english_vocabulary_extensions.dart';
import 'math_task_templates.dart';
import 'primary_school_word_data.dart';
import 'reading_comprehension_data.dart';
import 'science_task_data.dart';
import 'science_quality_extension.dart';
import 'science_variety_extension.dart';
import 'spelling_context_data.dart';
import 'task_quality_guard.dart';

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
    this.chartEntries = const [],
    this.dataChart,
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
  final List<BarChartEntry> chartEntries;
  final DataChartExercise? dataChart;
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
    final units = <String>{
      ..._templateUnitsForGrade(subject, capped, currentGradeOnly: currentGradeOnly),
      ...LumoAdventureTasks.unitsFor(subject, capped, currentGradeOnly: currentGradeOnly),
    };
    // Mathematik follows the school book order (numbers, plus/minus, times
    // tables, sizes, shapes, puzzles), the same order the register shows.
    return subject == 'Mathematik'
        ? List<String>.unmodifiable(MathUnitOrder.sorted(units))
        : units.toList(growable: false);
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

  /// Explicit grade/subject/unit selection for the curriculum audit and
  /// progressively upgraded callers. The old mixed-task API remains intact.
  /// Unrecognized input must never silently turn into a different lesson.
  LumoTask nextExact({
    required int grade,
    required String subject,
    required String unit,
    bool currentGradeOnly = false,
    Map<String, int> weakSkills = const <String, int>{},
    String? childName,
  }) {
    if (grade < 1 || grade > 4) {
      throw ArgumentError.value(grade, 'grade', 'Expected class 1 through 4');
    }
    if (!Curriculum.exerciseSubjectsForGrade(grade).contains(subject)) {
      throw ArgumentError.value(subject, 'subject', 'Unknown explicit subject');
    }
    final available = Curriculum.unitsForGrade(
      subject, grade, currentGradeOnly: currentGradeOnly,
    );
    if (unit == 'Alle' || !available.contains(unit)) {
      throw ArgumentError.value(
        unit, 'unit', 'Topic is not available in the selected subject and grade');
    }
    final task = next(
      grade: grade,
      subject: subject,
      unit: unit,
      weakSkills: weakSkills,
      childName: childName,
    );
    if (task.grade != grade || task.subject != subject || task.unit != unit) {
      throw StateError('Generator changed an explicit grade, subject or unit');
    }
    return task;
  }

  LumoTask next({
    required int grade,
    String subject = 'Alle',
    String unit = 'Alle',
    Map<String, int> weakSkills = const <String, int>{},
    Set<String> avoidUnits = const <String>{},
    String? childName,
    bool gradedOnly = false,
  }) {
    _childName = childName;
    final cappedGrade = grade.clamp(1, 4).toInt();
    final chosenSubject = _chooseSubject(subject, weakSkills,
        grade: cappedGrade, gradedOnly: gradedOnly, unit: unit);
    final allUnits = Curriculum.unitsForGrade(chosenSubject, cappedGrade);
    final availableUnit = allUnits.contains(unit) ||
        (chosenSubject == 'Mathematik' && MathTaskTemplates.supportsUnit(cappedGrade, unit)) ||
        (chosenSubject == 'Deutsch' && GermanTaskTemplates.supportsUnit(cappedGrade, unit));
    // Lumo Expertenwelt (über den Lehrplan hinaus) nur nach ausdrücklicher
    // Auswahl: gemischte Runden, Tests und Schularbeiten ziehen allein aus
    // Schulwissen und Vertiefung der Schulstufe.
    final units = LearningLevels.withoutExpert(chosenSubject, allUnits, cappedGrade);
    var selectionPool = units;
    if ((unit == 'Alle' || !availableUnit) && _random.nextInt(4) != 0) {
      final currentUnits = LearningLevels.withoutExpert(chosenSubject,
          Curriculum.unitsForGrade(chosenSubject, cappedGrade, currentGradeOnly: true),
          cappedGrade);
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
    bool gradedOnly = false,
  }) {
    LumoTask? oldestFallback;
    for (var attempt = 0; attempt < 40; attempt++) {
      final task = next(
          grade: grade,
          subject: subject,
          weakSkills: weakSkills,
          avoidUnits: avoidUnits,
          gradedOnly: gradedOnly);
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
    bool gradedOnly = false,
  }) {
    final tasks = <LumoTask>[];
    final usedUnits = <String>{};
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      final task = _nextFreshForSession(
          grade: grade, subject: subject, weakSkills: weakSkills,
          avoidUnits: usedUnits, seen: seen, gradedOnly: gradedOnly);
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

  /// Subjects of a mixed session. Writing practice is ungraded (a real
  /// attempt always leads on), so a test or Schularbeit ([gradedOnly]) must
  /// not draw it: it would occupy a planned question that can never count
  /// as correct, and a flawless child would score 8 of 10.
  static const _mixedSubjects = <String>[
    'Mathematik', 'Deutsch', 'Lesen', 'Rechtschreibung', 'Sachunterricht',
    'Schreiben', 'Englisch',
  ];

  /// Lernbereiche eines Schulfachs in Tests und Schularbeiten. Lumo führt
  /// Lesen und Rechtschreibung als eigene Bereiche, im Lehrplan gehören sie
  /// zum Fach Deutsch. Eine Deutsch-Schularbeit prüft deshalb Sprache, Lesen
  /// und Rechtschreibung; das unbewertete Schreibtraining bleibt draußen.
  static const Map<String, List<String>> gradedSubjectAreas =
      <String, List<String>>{
    'Deutsch': <String>['Deutsch', 'Lesen', 'Rechtschreibung'],
  };

  /// Fächer, aus denen ein Test oder eine Schularbeit für [subject] zieht.
  static List<String> gradedSubjectsFor(String subject) =>
      gradedSubjectAreas[subject] ?? <String>[subject];

  String _chooseSubject(String requested, Map<String, int> weakSkills,
      {required int grade, bool gradedOnly = false, String unit = 'Alle'}) {
    final areas = gradedSubjectAreas[requested];
    if (gradedOnly && unit == 'Alle' && areas != null) {
      // Hälfte Sprache, je ein Viertel Lesen und Rechtschreibung; eine
      // Schwäche in einem der Bereiche wird bevorzugt geübt.
      if (weakSkills.isNotEmpty && _random.nextDouble() < .5) {
        final weakest = (weakSkills.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
        final owners = <String>[
          for (final area in areas)
            if (Curriculum.unitsForGrade(area, grade).contains(weakest)) area,
        ];
        if (owners.isNotEmpty) return owners[_random.nextInt(owners.length)];
      }
      final roll = _random.nextInt(4);
      return roll < 2 ? areas.first : areas[roll - 1];
    }
    if (requested != 'Alle') return Curriculum.subjects.containsKey(requested) ? requested : 'Mathematik';
    final base = gradedOnly
        ? _mixedSubjects.where((s) => s != 'Schreiben').toList()
        : _mixedSubjects;
    if (weakSkills.isNotEmpty && _random.nextDouble() < .60) {
      final weakUnit = weakSkills.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      // Weak skills are stored by unit name only. Several subjects share
      // names (Tiere, Körper and Wetter in Englisch and Sachunterricht), so
      // the first match in map order sent a Sachunterricht weakness to
      // English practice almost every time. Choose fairly among all
      // subjects that really offer this unit in the child's grade.
      final owners = <String>[
        for (final subject in Curriculum.subjects.keys)
          if (!(gradedOnly && subject == 'Schreiben') &&
              Curriculum.unitsForGrade(subject, grade)
              .contains(weakUnit.first.key))
            subject,
      ];
      if (owners.isNotEmpty) return owners[_random.nextInt(owners.length)];
    }
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
    // Every entry point, including direct cross-grade practice, receives a
    // checked task. Retry within the requested topic; changing subjects is
    // not a repair for an invalid generated variant.
    const quality = TaskQualityGuard();
    for (var attempt = 0; attempt < 32; attempt++) {
      final task = _buildUnchecked(grade: grade, subject: subject, unit: unit);
      if (quality.validate(task)) return task;
    }
    throw StateError('No validated task available for $grade/$subject/$unit');
  }

  LumoTask _buildUnchecked({required int grade, required String subject, required String unit}) {
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
      // Musterarten je Klasse: Klasse 1 A-B, Klasse 2 dazu A-A-B und A-B-C,
      // ab Klasse 3 auch A-B-B und A-B-C-D. Die Reihe bricht an wechselnder
      // Stelle ab, damit die Lösung nicht immer die erste Form ist.
      final shapes = <List<int>>[
        const <int>[0, 1],
        if (grade >= 2) ...const <List<int>>[
          <int>[0, 0, 1],
          <int>[0, 1, 2],
        ],
        if (grade >= 3) ...const <List<int>>[
          <int>[0, 1, 1],
          <int>[0, 1, 2, 3],
        ],
      ];
      final pattern = <String>[
        for (final index in shapes[_random.nextInt(shapes.length)])
          symbols[index],
      ];
      final extra = _random.nextInt(pattern.length);
      final shown = <String>[...pattern, ...pattern, ...pattern.take(extra)];
      final answer = pattern[extra];
      return _choiceTask(
          'logik-muster',
          grade,
          'Logik',
          unit,
          'Das Muster wiederholt sich immer gleich: ${shown.join(' – ')} – ? Welche Form folgt?',
          answer,
          'Die Gruppe ${pattern.join(' – ')} wiederholt sich. Nach ${shown.last} kommt hier $answer.',
          visual: 'pattern',
          customChoices: symbols);
    }
    if (unit == 'Zahlenmuster') {
      // Schritt mindestens 2 (ein Schritt von 1 ist nur Weiterzählen), ein
      // Drittel der Reihen geht zurück.
      final step = 2 + _random.nextInt(grade * 2);
      final backwards = _random.nextInt(3) == 0;
      final low = _random.nextInt(grade == 2 ? 50 : 200);
      final start = backwards ? low + 4 * step : low;
      final signed = backwards ? -step : step;
      final shown = List.generate(4, (i) => start + i * signed);
      final answer = start + 4 * signed;
      return _choiceTask(
          'logik-zahlenmuster',
          grade,
          'Logik',
          unit,
          'Gehe jedes Mal gleich viele Schritte ${backwards ? 'zurück' : 'weiter'}: ${shown.join(' – ')} – ? Welche Zahl folgt?',
          '$answer',
          'Der Abstand ist immer $step. Nach ${shown.last} kommt ${shown.last} ${backwards ? '−' : '+'} $step = $answer.',
          // Die Lösung darf der Größe nach an jeder Stelle liegen. Typische
          // Fehler: einen Schritt zu viel, nur um 1 weitergezählt, verzählt.
          customChoices: MathTaskTemplates.numberChoices(
            answer,
            _random.nextInt(1 << 30),
            typical: <int>[
              answer + signed,
              shown.last + (backwards ? -1 : 1),
              answer - 1,
              answer + 1,
              answer + 2 * signed,
            ],
            blocked: shown.toSet(),
          ));
    }
    if (unit == 'Regeln kombinieren') {
      // Befund M25: Früher gab es nur „… und gerade“. Jetzt wechselt die
      // dritte Regel: gerade, ungerade oder eine Zahl aus einer Reihe des
      // Einmaleins. Mehrere Zahlen erfüllen alle Regeln, nur eine davon
      // wird zur Karte.
      const properties = <String>[
        'gerade',
        'ungerade',
        'in der 3er-Reihe',
        'in der 4er-Reihe',
        'in der 5er-Reihe',
      ];
      final property = properties[_random.nextInt(properties.length)];
      bool fits(int value) => combinedRuleProperty(property, value);
      final step = switch (property) {
        'in der 3er-Reihe' => 3,
        'in der 4er-Reihe' => 4,
        'in der 5er-Reihe' => 5,
        _ => 2,
      };
      final lower = 10 + _random.nextInt(80);
      final upper = lower + 3 * step + 2;
      final matching = <int>[
        for (var v = lower + 1; v < upper; v++)
          if (fits(v)) v,
      ];
      final answer = matching[_random.nextInt(matching.length)];
      final reason = switch (property) {
        'gerade' => 'Die Zahl ist gerade, man kann sie ohne Rest in Paare teilen.',
        'ungerade' => 'Die Zahl ist ungerade, beim Paarebilden bleibt eins übrig.',
        _ => '$answer = ${answer ~/ step} · $step, die Zahl steht also $property.',
      };
      return _choiceTask(
          'logik-regeln',
          grade,
          'Logik',
          unit,
          // „Welche dieser Zahlen“: Mehrere Zahlen erfüllen die Regeln, aber
          // nur eine davon steht auf den Karten (Prüfbericht Punkt 11).
          'Welche dieser Zahlen erfüllt alle drei Regeln: größer als $lower, kleiner als $upper und $property?',
          '$answer',
          '$answer liegt zwischen $lower und $upper. $reason Von den Zahlen auf den Karten erfüllt nur diese alle drei Regeln.',
          // Falsche Karten verletzen je eine Regel: die Grenzen selbst,
          // Zahlen dazwischen ohne die Eigenschaft, passende Zahlen außerhalb.
          customChoices: MathTaskTemplates.numberChoices(
            answer,
            _random.nextInt(1 << 30),
            typical: <int>[
              for (var v = lower + 1; v < upper; v++)
                if (!fits(v)) v,
              if (!fits(lower)) lower,
              if (!fits(upper)) upper,
              for (var v = lower; v > lower - 3 * step && v > 0; v--)
                if (fits(v)) v,
              for (var v = upper; v < upper + 3 * step; v++)
                if (fits(v)) v,
            ],
            blocked: matching.toSet(),
          ));
    }
    final names = <String>['Lumo', 'Mia', 'Ben', 'Ali', 'Lea']
      ..shuffle(_random);
    // Befund M24: In Klasse 4 auch vier Freunde oder eine verneinte Angabe
    // („Ben steht nicht am Rand.“), damit wirklich geschlossen werden muss.
    final variant =
        unit == 'Schlussfolgern' && grade >= 4 ? _random.nextInt(3) : 0;
    final count = variant == 2 ? 4 : 3;
    final order = names.take(count).toList();
    final places = count == 4
        ? const <String>[
            'ganz links',
            'an zweiter Stelle von links',
            'an dritter Stelle von links',
            'ganz rechts',
          ]
        : const <String>['ganz links', 'in der Mitte', 'ganz rechts'];
    final askedIndex = _random.nextInt(count);
    final asked = places[askedIndex];
    final answer = order[askedIndex];
    String leftOf(String left, String right) => _random.nextBool()
        ? '$left steht links von $right.'
        : '$right steht rechts von $left.';
    var prompt =
        'Von links nach rechts stehen ${order[0]}, ${order[1]} und ${order[2]}. Wer steht $asked?';
    if (unit == 'Schlussfolgern') {
      // Die Angaben stehen in wechselnder Reihenfolge und Richtung.
      // Früher wurden die Namen immer von links nach rechts genannt, die
      // Lösung war ohne Schluss abzulesen.
      final clues = switch (variant) {
        1 => <String>[
            '${order[1]} steht nicht am Rand.',
            leftOf(order[0], order[2]),
          ],
        _ => <String>[
            for (var k = 0; k + 1 < count; k++) leftOf(order[k], order[k + 1]),
          ],
      }
        ..shuffle(_random);
      prompt =
          '${count == 4 ? 'Vier' : 'Drei'} Freunde stehen nebeneinander. ${clues.join(' ')} Wer steht $asked?';
    }
    // Die Karten in fester, vom Rätsel unabhängiger Reihenfolge.
    final cards = <String>[...order]..sort();
    return _choiceTask(
        'logik-reihenfolge',
        grade,
        'Logik',
        unit,
        prompt,
        answer,
        'Von links nach rechts ist die Reihenfolge ${order.join(' – ')}. $answer steht $asked.',
        customChoices: cards);
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
      chartEntries: generated.chartEntries,
      dataChart: generated.dataChart,
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
          customChoices: _wordEndingChoices(q.$2));
    }
    // Ab 12 eigenen Sätzen übt eine Klasse nur ihre eigenen Wörter; sonst
    // werden Sätze früherer Klassen zur Festigung dazugenommen.
    final upToGrade = spellingContexts.where((q) => q.unit == unit && q.grade <= grade).toList();
    final ownGrade = upToGrade.where((q) => q.grade == grade).toList();
    final contexts = ownGrade.length >= 12 ? ownGrade : upToGrade;
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
      // Das Kind sucht das Namenwort im Satz, statt immer dieselbe Antwort
      // "großer Anfang" zu wählen. Eigennamen und Gefühle passen nicht in
      // die Satzmuster und bleiben außen vor.
      final nouns = PrimarySchoolWordData.nounsForGrade(grade)
          .where((word) => !const <String>{'Österreich', 'Gefühle'}
              .contains(PrimarySchoolWordData.categoryFor(word)))
          .toList(growable: false);
      final noun = nouns[_random.nextInt(nouns.length)];
      final lower = noun.toLowerCase();
      final article = PrimarySchoolWordData.articleFor(noun)!;
      // Nur Sätze im Wer-Fall: so stimmt die Form bei jedem Namenwort
      // (kein "den Elefant"). Das Namenwort steht an wechselnder Stelle.
      final patterns = <(String, List<String>)>[
        ('${article[0].toUpperCase()}${article.substring(1)} $lower ist da.', <String>['ist', 'da']),
        ('Dort ist $article $lower zu sehen.', <String>['ist', 'sehen']),
        ('Ist $article $lower schon da?', <String>['schon', 'da']),
      ];
      final pattern = patterns[_random.nextInt(patterns.length)];
      return _choiceTask(
          'gross',
          grade,
          'Rechtschreibung',
          unit,
          'Welches Wort muss groß geschrieben werden?\n„${pattern.$1}“',
          lower,
          'Namenwörter beginnen mit einem großen Buchstaben: $noun.',
          customChoices: <String>[lower, ...pattern.$2]);
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
        ['Uhr', 'Uhrr', 'Uuhr', 'Das Wort Uhr schreibt man mit h.'],
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
        ['Abenteuer', 'Abendteuer', 'Abenteur'],
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

  /// Wortende: Der Verwechslungspartner (d/t, g/k, b/p) steht immer zur Wahl.
  List<String> _wordEndingChoices(String answer) {
    const partners = <String, String>{
      'd': 't', 't': 'd', 'g': 'k', 'k': 'g', 'b': 'p', 'p': 'b',
    };
    final partner = partners[answer]!;
    return <String>[
      answer,
      partner,
      ...const <String>['d', 't', 'g', 'k', 'b', 'p']
          .where((letter) => letter != answer && letter != partner)
          .take(2),
    ];
  }

  LumoTask _stOrSp(int grade, String subject) {
    // 2026-06-03: vorher 8 Woerter. Jetzt 20 Woerter, ausgewogen St/Sp/Sch
    // (Sch als Distraktor war vorher nie als Antwort).
    // Fachprüfung 2026-11 (D-M11): Früher stand das ganze Wort in der Frage
    // ("Welche Buchstaben stehen am Anfang von Stuhl?"). Jetzt zeigt ein Bild
    // das Wort, und der Wortanfang fehlt. Nur Wörter mit eindeutigem Bild.
    const data = <(String, String, String)>[
      // St-Wörter
      ('Stern', 'St', '⭐'), ('Stuhl', 'St', '🪑'), ('Stift', 'St', '✏️'),
      ('Straße', 'St', '🛣️'), ('Stiefel', 'St', '👢'), ('Strand', 'St', '🏖️'),
      // Sp-Wörter
      ('Spinne', 'Sp', '🕷️'), ('Spielzeug', 'Sp', '🧸'),
      ('Spaghetti', 'Sp', '🍝'), ('Spiel', 'Sp', '🎲'), ('Spritze', 'Sp', '💉'),
      // Sch-Wörter
      ('Schule', 'Sch', '🏫'), ('Schaf', 'Sch', '🐑'), ('Schiff', 'Sch', '🚢'),
      ('Schnee', 'Sch', '❄️'), ('Schere', 'Sch', '✂️'), ('Schuh', 'Sch', '👟'),
      ('Schlange', 'Sch', '🐍'),
    ];
    final entry = data[_random.nextInt(data.length)];
    final rest = entry.$1.substring(entry.$2.length);
    final rule = entry.$2 == 'Sch'
        ? 'Hier hörst und schreibst du Sch.'
        : 'Am Wortanfang hörst du „Sch${entry.$2[1].toLowerCase()}“, schreibst aber ${entry.$2}.';
    return _choiceTask(
        'stsp',
        grade,
        subject,
        'St oder Sp',
        'Schau das Bild an: ${entry.$3}\nWas fehlt am Wortanfang? __$rest',
        entry.$2,
        'Das Wort heißt ${entry.$1}. $rule',
        customChoices: const <String>['St', 'Sp', 'Sch']);
  }

  // Schreiben steigt mit der Klasse (Fachprüfung 2026-11, D-M18):
  // Kl. 1 Groß- und Kleinbuchstaben, Kl. 2 Kleinbuchstaben mit Umlauten und
  // ß, ab Kl. 3 Wörter und kurze Sätze, Kl. 4 Sätze mit Satzzeichen und
  // wörtlicher Rede. Einzelne Zeichen nutzen nur geprüfte Spurvorlagen.
  static const _writingLowercase = 'abcdefghijklmnopqrstuvwxyzäöüß';
  static const _writingTrickyWords = <int, List<String>>{
    3: <String>['Straße', 'Füße', 'Grüße', 'Mädchen', 'Schlüssel', 'Gemüse',
      'Löwe', 'Quelle', 'Hexe', 'Käse', 'Brücke', 'Zwetschke', 'Bäcker',
      'Küche', 'Größe', 'Mäuse', 'Quark', 'Boxer'],
    4: <String>['Fußgänger', 'Gebäude', 'Bibliothek', 'Rhythmus', 'Qualle',
      'Taxi', 'Pyjama', 'Geräusch', 'Überraschung', 'Gießkanne',
      'Märchenbuch', 'Spaß', 'Xylophon', 'Pyramide', 'Äquator',
      'Gemüsesuppe', 'Süßigkeit', 'Häuschen'],
  };
  static const _writingNumberWords = <int, String>{
    11: 'elf', 12: 'zwölf', 13: 'dreizehn', 14: 'vierzehn', 15: 'fünfzehn',
    16: 'sechzehn', 17: 'siebzehn', 18: 'achtzehn', 19: 'neunzehn',
    20: 'zwanzig', 30: 'dreißig', 40: 'vierzig', 50: 'fünfzig',
    60: 'sechzig', 70: 'siebzig', 80: 'achtzig', 90: 'neunzig',
    100: 'hundert', 23: 'dreiundzwanzig', 47: 'siebenundvierzig',
    66: 'sechsundsechzig', 99: 'neunundneunzig', 200: 'zweihundert',
    500: 'fünfhundert', 1000: 'tausend',
  };
  static const _writingSentencesGrade1 = <String>[
    'Der Hund bellt.',
    'Mama malt.',
    'Oma liest ein Buch.',
    'Wir spielen Ball.',
    'Die Sonne scheint.',
    'Ich bin froh.',
  ];
  static const _writingSentencesGrade2 = <String>[
    'Der Bus kommt um acht Uhr.',
    'Lena füttert die Katze.',
    'Im Winter fällt Schnee.',
    'Ich packe meine Schultasche.',
    'Papa kocht heute Nudeln.',
    'Wir gehen in den Park.',
  ];
  static const _writingSentencesGrade3 = <String>[
    'Im Herbst fallen die Blätter.',
    'Die Straße ist nass und glatt.',
    'Wir fahren mit dem Zug nach Graz.',
    'Mein Bruder spielt gern Fußball.',
    'Am Sonntag besuchen wir Oma.',
    'Die Kinder lachen in der Pause.',
    'Ich gieße die Blumen im Garten.',
    'Der Igel schläft unter dem Laub.',
    'Wann beginnt die Turnstunde?',
    'Heute ist es sehr heiß!',
    'Der Bäcker backt frisches Brot.',
    'Unsere Klasse fährt in den Zoo.',
    'Im Winter bauen wir einen Schneemann.',
    'Die Katze schläft auf dem Sofa.',
    'Hast du deine Hausübung gemacht?',
    'Mein Fahrrad hat eine neue Klingel.',
  ];
  static const _writingSentencesGrade4 = <String>[
    'Lumo fragt: „Kommst du mit?“',
    'Mama ruft: „Das Essen ist fertig!“',
    'Ben sagt: „Ich habe meine Haube vergessen.“',
    '„Wo ist mein Heft?“, fragt Lea.',
    'Wir kaufen Äpfel, Birnen und Zwetschken.',
    'Die Lehrerin sagt: „Packt eure Sachen ein.“',
    'Am Montag, Mittwoch und Freitag habe ich Training.',
    '„Komm schnell!“, ruft Opa.',
    'Ich glaube, dass es morgen schneit.',
    'Weil es regnet, bleiben wir drinnen.',
    'Oma fragt: „Wer möchte Kuchen?“',
    'Im Rucksack sind Jause, Trinkflasche und Jacke.',
    '„Ich habe gewonnen!“, jubelt Mia.',
    'Wenn die Sonne scheint, gehen wir baden.',
    'Der Trainer ruft: „Alle zum Tor!“',
    'Ich weiß, dass du das schaffst.',
  ];

  LumoTask _writing(int grade, String unit) {
    String prompt;
    String explanation;
    if (unit == 'Zahlen schreiben') {
      if (grade <= 1) {
        // The tracing repository supports 0–20; larger numbers used to display A.
        final n = _random.nextInt(21);
        prompt = 'Schreibe die Zahl $n schön und langsam.';
        explanation = 'Achte auf die Form jeder Ziffer.';
      } else {
        final entries = _writingNumberWords.entries
            .where((e) => switch (grade) {
                  2 => e.key <= 20 || (e.key <= 100 && e.key % 10 == 0),
                  3 => true,
                  _ => e.key > 20,
                })
            .toList();
        final entry = entries[_random.nextInt(entries.length)];
        prompt = 'Die Zahl ${entry.key} als Zahlwort. '
            'Schreibe das Wort: ${entry.value}';
        explanation = '${entry.key} schreibt man als Wort „${entry.value}“. '
            'Zahlwörter schreibst du klein.';
      }
    } else if (unit == 'Buchstaben nachspuren') {
      if (grade >= 3) {
        final words = _writingTrickyWords[grade.clamp(3, 4)]!;
        final word = words[_random.nextInt(words.length)];
        prompt = 'Schreibe das Wort: $word';
        explanation = 'Schau dir die schwierigen Buchstaben genau an '
            '(ä, ö, ü, ß, qu, x, y) und schreibe sie sauber.';
      } else if (grade == 1 && _random.nextBool()) {
        const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        final letter = letters[_random.nextInt(letters.length)];
        prompt = 'Spure den Buchstaben $letter nach.';
        explanation =
            'Beginne am Startpunkt und folge den Strichen der Vorlage.';
      } else {
        final pool = grade == 1
            ? _writingLowercase.substring(0, 26)
            : _writingLowercase;
        final letter = pool[_random.nextInt(pool.length)];
        prompt = 'Schreibe: $letter';
        explanation = 'Spure den kleinen Buchstaben $letter nach. '
            'Er steht zwischen den Schreiblinien.';
      }
    } else if (unit == 'Schwunguebung') {
      if (grade >= 3) {
        const swingWords = <String>[
          'Welle', 'Sonne', 'Wolle', 'Muschel', 'Schnecke', 'Locke',
          'Wolke', 'Schlange', 'Melone', 'Nudel', 'Lamm', 'Mimose',
          'Ballon', 'Wiese', 'Mühle', 'Lilie'
        ];
        final word = swingWords[_random.nextInt(swingWords.length)];
        prompt = 'Schreibe das Wort: $word';
        explanation = 'Schreibe das Wort in einem ruhigen Schwung, '
            'ohne zwischen den Buchstaben lange abzusetzen.';
      } else {
        // Auch eine Schwungübung trainiert einen lesbaren Buchstaben statt
        // ein unbekanntes mathematisches Symbol als "Schreibaufgabe".
        // Alle Buchstaben haben echte, geprüfte Ein-Strich-Vorlagen.
        final curveLetters = grade == 1
            ? const <String>['S', 'C', 'O', 'U']
            : const <String>['s', 'c', 'o', 'u', 'e'];
        final letter = curveLetters[_random.nextInt(curveLetters.length)];
        prompt = 'Schreibe: $letter';
        explanation =
            'Spure den Buchstaben $letter in einem ruhigen Schwung nach. '
            'Beginne beim markierten Startpunkt.';
      }
    } else if (unit == 'Satz abschreiben') {
      if (grade >= 3) {
        final sentences =
            grade == 3 ? _writingSentencesGrade3 : _writingSentencesGrade4;
        final sentence = sentences[_random.nextInt(sentences.length)];
        prompt = 'Schreibe: $sentence';
        explanation = grade == 3
            ? 'Schreibe den ganzen Satz. Achte auf den großen Anfang, '
                'die Namenwörter und das Satzzeichen.'
            : 'Schreibe den ganzen Satz. Achte auf Beistriche, '
                'Doppelpunkt und Anführungszeichen.';
      } else {
        final options = readingPassages[grade.clamp(1, 4)]!;
        // Copy one complete sentence. Avoid long multi-sentence writing targets.
        final sentences = <String>{
          for (final passage in options) '${passage.text.split('.').first}.',
          ...(grade == 1 ? _writingSentencesGrade1 : _writingSentencesGrade2),
        }.toList();
        final sentence = sentences[_random.nextInt(sentences.length)];
        prompt = 'Schreibe: $sentence';
        explanation =
            'Schreibe den ganzen Satz. Achte auf Abstände, den großen Anfang und das Satzzeichen.';
      }
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
        '🦋': 'Schmetterling',
        '🐭': 'Maus',
        '🐴': 'Pferd',
        '🐷': 'Schwein',
        '🦆': 'Ente',
        '🐝': 'Biene',
        '🍌': 'Banane',
        '🍓': 'Erdbeere',
        '🚗': 'Auto',
        '🏠': 'Haus',
        '🌙': 'Mond',
        '🐌': 'Schnecke',
        '🦔': 'Igel'
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
            ...(pictures.values.where((word) => word != picture.value).toList()
                  ..shuffle(_random))
                .take(3)
          ]);
    }
    if (unit == 'Woerter lesen') {
      // Erste Zahl: ab welcher Klasse. Ablenker sehen ähnlich aus, damit
      // genau gelesen wird (Fachprüfung D-M12).
      const allItems = <(int, List<String>)>[
        (1, ['Dieses Tier bellt.', 'Hund', 'Katze', 'Maus']),
        (1, ['Du liest darin.', 'Buch', 'Ball', 'Bett']),
        (1, ['Er hat einen Stamm und Blätter.', 'Baum', 'Bach', 'Bauch']),
        (1, ['Sie scheint am Tag am Himmel.', 'Sonne', 'Tonne', 'Wanne']),
        (1, ['Du schreibst damit.', 'Stift', 'Stuhl', 'Stein']),
        (1, ['Damit isst du Suppe.', 'Löffel', 'Löwe', 'Lupe']),
        (1, ['Er lebt im Wasser und hat Flossen.', 'Fisch', 'Tisch', 'Fleisch']),
        (1, ['Darin schläfst du.', 'Bett', 'Brett', 'Bart']),
        (1, ['Es ist grün und wächst am Ast.', 'Blatt', 'Bild', 'Platz']),
        (1, ['Damit spielst du Fußball.', 'Ball', 'Bank', 'Band']),
        (1, ['Dieses Tier miaut.', 'Katze', 'Tatze', 'Kasse']),
        (1, ['Dieses Tier gibt Milch.', 'Kuh', 'Schuh', 'Kugel']),
        (1, ['Du ziehst ihn an den Fuß.', 'Schuh', 'Schule', 'Stuhl']),
        (1, ['Darauf sitzt du am Tisch.', 'Sessel', 'Kessel', 'Schlüssel']),
        (1, ['Er leuchtet in der Nacht am Himmel.', 'Mond', 'Mund', 'Hund']),
        (1, ['Damit kämmst du deine Haare.', 'Kamm', 'Kamel', 'Lamm']),
        (1, ['Es ist ein rotes Obst vom Baum.', 'Apfel', 'Ampel', 'Gabel']),
        (2, ['Es hat zwei Räder und Pedale.', 'Fahrrad', 'Fahrbahn', 'Fahrplan']),
        (2, ['Damit sperrst du die Tür auf.', 'Schlüssel', 'Schüssel', 'Schaufel']),
        (2, ['Damit putzt du deine Zähne.', 'Zahnbürste', 'Zahnlücke', 'Haarbürste']),
        (2, ['Dort leihst du Bücher aus.', 'Bücherei', 'Bäckerei', 'Brücke']),
        (2, ['Er bringt Briefe und Pakete.', 'Postler', 'Polster', 'Poster']),
        (3, ['Hier starten und landen Flugzeuge.', 'Flughafen', 'Flussufer', 'Fahrplan']),
        (3, ['Es zeigt dir, wie warm es ist.', 'Thermometer', 'Tachometer', 'Taschenrechner']),
      ];
      final items = <List<String>>[
        for (final entry in allItems)
          if (entry.$1 <= grade) entry.$2,
      ];
      final item = items[_random.nextInt(items.length)];
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
      // Die Sätze stehen durcheinander, sonst wäre die Antwort immer die
      // Position im Text (Fachprüfung D-M12).
      final shuffled = List<String>.of(sequence);
      while (_sameOrder(shuffled, sequence)) {
        shuffled.shuffle(_random);
      }
      return _choiceTask(
          'lese-reihenfolge',
          grade,
          'Lesen',
          unit,
          'Die Sätze sind durcheinander: ${shuffled.join(' ')}\n'
              'Was passiert $asked?',
          answer,
          'Richtige Reihenfolge: ${sequence.join(' → ')}',
          customChoices: sequence);
    }
    final passages = (unit == 'Lesesinn'
        ? readingInferences
        : readingPassages)[grade.clamp(1, 4)]!;
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

  static bool _sameOrder(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    // Wörter, die im Deutschen gleich lauten (orange, Hand, Tiger), prüfen
    // beim Lesen nichts und werden nicht gefragt (Fachprüfung E-L7).
    final askable = map!.entries
        .where((e) => e.key.toLowerCase() != e.value.toLowerCase())
        .toList();
    final entries = askable.isEmpty ? map.entries.toList() : askable;
    final entry = entries[_random.nextInt(entries.length)];
    // Ablenker: nie ein zweites richtiges oder fast gleiches Wort (Morgen /
    // am Morgen / morgen, Tasche / Schultasche) und möglichst dieselbe Art
    // (Wort neben Wörtern, Satz neben Sätzen), damit die Länge nichts verrät.
    final others = map.entries
        .where((other) =>
            other.key != entry.key &&
            !_englishNearSame(other.value, entry.value))
        .toList();
    final sameKind = others
        .where((other) => _isSentence(other.key) == _isSentence(entry.key))
        .toList();
    final pool = (sameKind.length >= 2 ? sameKind : others)..shuffle(_random);
    final sentence = _isSentence(entry.key);
    // Ab Klasse 3 wird auch die Gegenrichtung geübt: deutsches Wort lesen,
    // englisches Wort wählen.
    if (capped >= 3 && _random.nextBool()) {
      return _choiceTask(
          'englisch-de-en',
          grade,
          'Englisch',
          outputUnit,
          sentence
              ? 'Wie heißt dieser Satz auf Englisch? „${entry.value}“'
              : 'Wie heißt „${entry.value}“ auf Englisch?',
          entry.key,
          '„${entry.value}“ heißt auf Englisch „${entry.key}“.',
          customChoices: [entry.key, ...pool.take(3).map((other) => other.key)]);
    }
    return _choiceTask(
        'englisch',
        grade,
        'Englisch',
        outputUnit,
        sentence
            ? 'Was bedeutet dieser Satz? „${entry.key}“'
            : 'Was bedeutet „${entry.key}“?',
        entry.value,
        sentence
            ? 'Der englische Satz „${entry.key}“ bedeutet: ${entry.value}'
            : 'Das englische Wort „${entry.key}“ bedeutet ${entry.value}.',
        customChoices: [entry.value, ...pool.take(3).map((other) => other.value)]);
  }

  bool _isSentence(String text) => RegExp(r'[.?!]$').hasMatch(text.trim());

  /// Zwei deutsche Bedeutungen sind zu ähnlich, um nebeneinander zur Wahl zu
  /// stehen: gleich bis auf Großschreibung und Vorwort (Morgen, morgen, am
  /// Morgen) oder eines endet auf das andere (Tasche, Schultasche).
  bool _englishNearSame(String a, String b) {
    String core(String value) => value
        .toLowerCase()
        .replaceFirst(RegExp(r'^(am|im|in der|die|der|das) '), '')
        .trim();
    final x = core(a), y = core(b);
    if (x == y) return true;
    final shorter = x.length <= y.length ? x : y;
    final longer = x.length <= y.length ? y : x;
    return shorter.length >= 4 &&
        !shorter.contains(' ') &&
        !longer.contains(' ') &&
        longer.endsWith(shorter);
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
      'desk': 'Schultisch'
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
      'Great Britain': 'Großbritannien',
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
  ...scienceQualityExtensionQuestions,
  ...scienceVarietyQuestions,
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Vogel?', answer: 'Spatz', choices: <String>['Spatz', 'Kuh', 'Fisch', 'Ameise'], explanation: 'Ein Spatz hat Federn und Flügel.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Fisch?', answer: 'Forelle', choices: <String>['Forelle', 'Hund', 'Biene', 'Hase'], explanation: 'Fische leben im Wasser und haben Flossen.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier ist ein Insekt?', answer: 'Biene', choices: <String>['Biene', 'Katze', 'Frosch', 'Schaf'], explanation: 'Insekten haben sechs Beine.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier hat ein Fell?', answer: 'Hund', choices: <String>['Hund', 'Ente', 'Forelle', 'Käfer'], explanation: 'Hunde haben ein Fell. Enten haben Federn, Forellen haben Schuppen.'),
  ScienceQuestion(grade: 1, unit: 'Tiere', prompt: 'Welches Tier lebt am Bauernhof?', answer: 'Kuh', choices: <String>['Kuh', 'Reh', 'Eichhörnchen', 'Igel'], explanation: 'Kühe leben am Bauernhof. Reh, Eichhörnchen und Igel leben frei in der Natur.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'In welcher Jahreszeit fällt oft Schnee?', answer: 'Winter', choices: <String>['Winter', 'Sommer', 'Frühling', 'Herbst'], explanation: 'Im Winter ist es kalt, oft schneit es.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann blühen viele Blumen neu?', answer: 'Frühling', choices: <String>['Frühling', 'Winter', 'Herbst', 'Sommer'], explanation: 'Im Frühling beginnen viele Pflanzen zu blühen.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann sind die Tage oft heiß?', answer: 'Sommer', choices: <String>['Sommer', 'Winter', 'Herbst', 'Frühling'], explanation: 'Im Sommer ist es oft warm bis heiß.'),
  ScienceQuestion(grade: 1, unit: 'Jahreszeiten', prompt: 'Wann fallen viele bunte Blätter von den Bäumen?', answer: 'Herbst', choices: <String>['Herbst', 'Sommer', 'Frühling', 'Winter'], explanation: 'Im Herbst verfärben sich viele Blätter.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was fällt aus Wolken als Wasser?', answer: 'Regen', choices: <String>['Regen', 'Wind', 'Sonne', 'Nebel'], explanation: 'Regen besteht aus Wassertropfen.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was hörst du bei einem Gewitter?', answer: 'Donner', choices: <String>['Donner', 'Schnee', 'Nebel', 'Regenbogen'], explanation: 'Donner ist das laute Geräusch beim Gewitter.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was siehst du manchmal am Himmel, wenn es regnet und zugleich die Sonne scheint?', answer: 'Regenbogen', choices: <String>['Regenbogen', 'Nebel', 'Schnee', 'Sternschnuppe'], explanation: 'Ein Regenbogen entsteht durch Sonne und Regentropfen.'),
  ScienceQuestion(grade: 1, unit: 'Wetter', prompt: 'Was bewegt Blätter in der Luft?', answer: 'Wind', choices: <String>['Wind', 'Nebel', 'Sonne', 'Mond'], explanation: 'Wind ist bewegte Luft.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was hat einen Stamm und Äste?', answer: 'Baum', choices: <String>['Baum', 'Blume', 'Gras', 'Pilz'], explanation: 'Ein Baum hat Stamm, Äste und Blätter.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was blüht oft bunt im Garten?', answer: 'Blume', choices: <String>['Blume', 'Stein', 'Moos', 'Pilz'], explanation: 'Blumen blühen oft bunt.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Welcher Teil einer Pflanze ist meist grün?', answer: 'Blatt', choices: <String>['Blatt', 'Wurzel', 'Blüte', 'Frucht'], explanation: 'Blätter sind meist grün. Sie fangen das Sonnenlicht ein.'),
  ScienceQuestion(grade: 1, unit: 'Pflanzen', prompt: 'Was braucht eine Pflanze zum Wachsen?', answer: 'Wasser', choices: <String>['Wasser', 'Limonade', 'Milch', 'Kakao'], explanation: 'Pflanzen brauchen Wasser, Licht und Erde.'),
  ScienceQuestion(grade: 1, unit: 'Tag und Nacht', prompt: 'Wann ist es meistens dunkel?', answer: 'Nacht', choices: <String>['Nacht', 'Mittag', 'Vormittag', 'Nachmittag'], explanation: 'In der Nacht ist die Sonne nicht zu sehen.'),
  ScienceQuestion(grade: 1, unit: 'Tag und Nacht', prompt: 'Was leuchtet am Tag hell am Himmel?', answer: 'Sonne', choices: <String>['Sonne', 'Mond', 'Stern', 'Laterne'], explanation: 'Die Sonne gibt Licht und Wärme.'),
  ScienceQuestion(grade: 1, unit: 'Körper', prompt: 'Womit siehst du?', answer: 'Auge', choices: <String>['Auge', 'Ohr', 'Hand', 'Fuß'], explanation: 'Mit den Augen sehen wir.'),
  ScienceQuestion(grade: 1, unit: 'Körper', prompt: 'Womit hörst du?', answer: 'Ohr', choices: <String>['Ohr', 'Nase', 'Knie', 'Bauch'], explanation: 'Mit den Ohren hören wir.'),
  ScienceQuestion(grade: 1, unit: 'Verkehr', prompt: 'Bei welcher Ampelfarbe darf man gehen?', answer: 'Grün', choices: <String>['Grün', 'Rot', 'Blau', 'Schwarz'], explanation: 'Grün bedeutet: gehen, wenn der Weg frei ist.'),
  ScienceQuestion(grade: 1, unit: 'Familie und Gemeinschaft', prompt: 'Was sagt man, wenn man Hilfe bekommt?', answer: 'Danke', choices: <String>['Danke', 'Hallo', 'Tschüss', 'Guten Morgen'], explanation: 'Danke ist höflich und freundlich.'),
  ScienceQuestion(grade: 1, unit: 'Zeit und Kalender', prompt: 'Welche Tage gehören zum Wochenende?', answer: 'Samstag und Sonntag', choices: <String>['Samstag und Sonntag', 'Montag und Dienstag', 'Mittwoch und Donnerstag', 'Freitag und Montag'], explanation: 'Samstag und Sonntag sind das Wochenende. Da ist meistens keine Schule.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Schwein?', answer: 'Ferkel', choices: <String>['Ferkel', 'Kalb', 'Fohlen', 'Lamm'], explanation: 'Ein junges Schwein heißt Ferkel.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby von der Kuh?', answer: 'Kalb', choices: <String>['Kalb', 'Ferkel', 'Küken', 'Fohlen'], explanation: 'Ein junges Rind heißt Kalb.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Pferd?', answer: 'Fohlen', choices: <String>['Fohlen', 'Kalb', 'Lamm', 'Küken'], explanation: 'Ein junges Pferd heißt Fohlen.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wie heißt das Baby vom Huhn?', answer: 'Küken', choices: <String>['Küken', 'Ferkel', 'Kalb', 'Welpe'], explanation: 'Ein junges Huhn heißt Küken.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo lebt ein Fisch meistens?', answer: 'im Wasser', choices: <String>['im Wasser', 'im Baum', 'im Nest', 'in einer Höhle'], explanation: 'Fische leben im Wasser.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo bauen viele Vögel ihr Nest?', answer: 'im Baum', choices: <String>['im Baum', 'im Wasser', 'unter der Erde', 'im Schnee'], explanation: 'Viele Vögel bauen Nester auf Bäumen.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Wo lebt der Fuchs bei uns häufig?', answer: 'im Wald', choices: <String>['im Wald', 'im Meer', 'im Teich', 'auf dem Gletscher'], explanation: 'Füchse leben bei uns häufig im Wald und am Waldrand.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Welches Tier sammelt Nektar?', answer: 'Biene', choices: <String>['Biene', 'Kuh', 'Hund', 'Forelle'], explanation: 'Bienen besuchen Blüten und sammeln Nektar.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welcher Pflanzenteil nimmt Wasser auf?', answer: 'Wurzel', choices: <String>['Wurzel', 'Blüte', 'Frucht', 'Ast'], explanation: 'Wurzeln nehmen Wasser aus der Erde auf.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Welcher Teil einer Blume trägt Blätter und Blüten?', answer: 'Stängel', choices: <String>['Stängel', 'Wurzel', 'Samen', 'Frucht'], explanation: 'Der Stängel trägt Blätter und Blüten. Beim Baum heißt er Stamm.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Woraus kann eine neue Pflanze wachsen?', answer: 'Samen', choices: <String>['Samen', 'Stein', 'Sand', 'Rinde'], explanation: 'Aus Samen können neue Pflanzen wachsen.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Was lockt oft Bienen an?', answer: 'Blüte', choices: <String>['Blüte', 'Wurzel', 'Rinde', 'Stamm'], explanation: 'Blüten locken Insekten an.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was bedeutet eine rote Ampel?', answer: 'stehen bleiben', choices: <String>['stehen bleiben', 'schnell hinüberlaufen', 'langsam losgehen', 'nur auf Autos achten'], explanation: 'Rot bedeutet Halt. Du wartest, bis es grün wird.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was bedeutet ein Stoppschild?', answer: 'anhalten', choices: <String>['anhalten', 'schneller fahren', 'hupen', 'umdrehen'], explanation: 'Bei Stopp muss man anhalten.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Wo überquerst du die Straße am sichersten?', answer: 'am Zebrastreifen (Schutzweg)', choices: <String>['am Zebrastreifen (Schutzweg)', 'zwischen parkenden Autos', 'in einer Kurve', 'hinter einem Bus'], explanation: 'Der Zebrastreifen heißt auch Schutzweg. Schau trotzdem immer nach links und rechts.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Was trägt man beim Radfahren zum Schutz?', answer: 'Helm', choices: <String>['Helm', 'Haube', 'Kappe', 'Stirnband'], explanation: 'Nur ein Helm schützt den Kopf bei einem Sturz.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer schneidet und frisiert Haare?', answer: 'Friseurin oder Friseur', choices: <String>['Friseurin oder Friseur', 'Bäckerin oder Bäcker', 'Tischlerin oder Tischler', 'Gärtnerin oder Gärtner'], explanation: 'Friseurinnen und Friseure schneiden und frisieren Haare.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer backt Semmeln und Brot?', answer: 'Bäckerin oder Bäcker', choices: <String>['Bäckerin oder Bäcker', 'Ärztin oder Arzt', 'Postlerin oder Postler', 'Tischlerin oder Tischler'], explanation: 'Bäckerinnen und Bäcker backen Brot und Semmeln.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer hilft kranken Menschen?', answer: 'Ärztin oder Arzt', choices: <String>['Ärztin oder Arzt', 'Maurerin oder Maurer', 'Pilotin oder Pilot', 'Schneiderin oder Schneider'], explanation: 'Ärztinnen und Ärzte behandeln kranke Menschen.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer bringt Briefe und Pakete?', answer: 'Postlerin oder Postler', choices: <String>['Postlerin oder Postler', 'Friseurin oder Friseur', 'Köchin oder Koch', 'Lehrerin oder Lehrer'], explanation: 'Die Post stellt Briefe und Pakete zu.'),
  ScienceQuestion(grade: 2, unit: 'Wetter', prompt: 'Was misst ein Thermometer?', answer: 'Temperatur', choices: <String>['Temperatur', 'Länge', 'Geld', 'Lautstärke'], explanation: 'Ein Thermometer zeigt warm oder kalt an.'),
  ScienceQuestion(grade: 2, unit: 'Wetter', prompt: 'Was ist Nebel?', answer: 'eine Wolke direkt am Boden', choices: <String>['eine Wolke direkt am Boden', 'Staub, der in der Luft schwebt', 'gefrorener Regen', 'Rauch aus dem Kamin'], explanation: 'Nebel besteht aus winzigen Wassertröpfchen in Bodennähe, wie eine Wolke am Boden.'),
  ScienceQuestion(grade: 2, unit: 'Jahreszeiten', prompt: 'Wie viele Jahreszeiten hat ein Jahr?', answer: '4', choices: <String>['4', '2', '7', '12'], explanation: 'Frühling, Sommer, Herbst und Winter sind vier Jahreszeiten.'),
  ScienceQuestion(grade: 2, unit: 'Zeit und Kalender', prompt: 'Welcher Monat ist der letzte im Jahr?', answer: 'Dezember', choices: <String>['Dezember', 'November', 'Jänner', 'Juli'], explanation: 'Das Jahr beginnt im Jänner und endet im Dezember.'),
  ScienceQuestion(grade: 2, unit: 'Körper', prompt: 'Womit riechst du?', answer: 'Nase', choices: <String>['Nase', 'Ohr', 'Knie', 'Hand'], explanation: 'Mit der Nase riechen wir.'),
  ScienceQuestion(grade: 2, unit: 'Körper', prompt: 'Womit schmeckst du?', answer: 'Zunge', choices: <String>['Zunge', 'Ellbogen', 'Fuß', 'Auge'], explanation: 'Mit der Zunge schmecken wir.'),
  ScienceQuestion(grade: 2, unit: 'Familie und Gemeinschaft', prompt: 'Was hilft bei Streit?', answer: 'ruhig reden', choices: <String>['ruhig reden', 'schubsen', 'weglaufen ohne Erklärung', 'auslachen'], explanation: 'Ruhiges Reden hilft beim Lösen von Streit.'),
  ScienceQuestion(grade: 2, unit: 'Pflanzen', prompt: 'Wie heißt die Aprikose in Österreich?', answer: 'Marille', choices: <String>['Marille', 'Ribisel', 'Zwetschke', 'Weichsel'], explanation: 'In Österreich sagt man Marille. Ribisel sind Johannisbeeren, Weichseln sind Sauerkirschen.'),
  ScienceQuestion(grade: 2, unit: 'Tiere', prompt: 'Welches Tier ist nachtaktiv?', answer: 'Eule', choices: <String>['Eule', 'Huhn', 'Kuh', 'Schaf'], explanation: 'Eulen sind oft nachts unterwegs.'),
  ScienceQuestion(grade: 2, unit: 'Verkehr', prompt: 'Wo gehst du auf dem Gehsteig am sichersten?', answer: 'auf der Seite bei den Häusern', choices: <String>['auf der Seite bei den Häusern', 'ganz am Randstein', 'auf der Fahrbahn', 'zwischen parkenden Autos'], explanation: 'Auf der Häuserseite bist du am weitesten von der Fahrbahn entfernt.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer baut Mauern?', answer: 'Maurerin oder Maurer', choices: <String>['Maurerin oder Maurer', 'Bäckerin oder Bäcker', 'Ärztin oder Arzt', 'Pilotin oder Pilot'], explanation: 'Maurerinnen und Maurer bauen Mauern und Gebäude.'),
  ScienceQuestion(grade: 2, unit: 'Berufe', prompt: 'Wer arbeitet mit Metall?', answer: 'Schlosserin oder Schlosser', choices: <String>['Schlosserin oder Schlosser', 'Gärtnerin oder Gärtner', 'Lehrerin oder Lehrer', 'Postlerin oder Postler'], explanation: 'Schlosserinnen und Schlosser bearbeiten Metall, zum Beispiel für Geländer und Tore.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Was gibt deinem Körper Halt und Form?', answer: 'das Skelett', choices: <String>['das Skelett', 'das Blut', 'der Magen', 'die Lunge'], explanation: 'Das Skelett besteht aus über 200 Knochen. Es stützt den Körper und schützt Organe.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welches Organ hilft beim Atmen?', answer: 'Lunge', choices: <String>['Lunge', 'Herz', 'Darm', 'Knochen'], explanation: 'Die Lunge nimmt Sauerstoff auf.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Womit verdauen wir Nahrung weiter?', answer: 'Magen und Darm', choices: <String>['Magen und Darm', 'Auge und Ohr', 'Hand und Fuß', 'Haut und Haar'], explanation: 'Magen und Darm helfen bei der Verdauung.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Welche fünf Sinne haben wir?', answer: 'sehen, hören, riechen, schmecken, fühlen', choices: <String>['sehen, hören, riechen, schmecken, fühlen', 'laufen, springen, sitzen, stehen, liegen', 'essen, trinken, schlafen, malen, rechnen', 'rot, blau, grün, gelb, weiß'], explanation: 'Die Sinne helfen uns, die Umwelt wahrzunehmen.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was sollte man oft trinken?', answer: 'Wasser', choices: <String>['Wasser', 'Limo', 'Sirup', 'Eistee'], explanation: 'Wasser ist ein gesundes Getränk.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was gehört zum Obst?', answer: 'Apfel', choices: <String>['Apfel', 'Karotte', 'Semmel', 'Käse'], explanation: 'Äpfel sind Obst. Karotten sind Gemüse.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was gibt Energie, soll aber nicht zu viel gegessen werden?', answer: 'Zucker', choices: <String>['Zucker', 'Wasser', 'Salat', 'Luft'], explanation: 'Zu viel Zucker ist ungesund.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was enthält viele Vitamine?', answer: 'Gemüse und Obst', choices: <String>['Gemüse und Obst', 'Zuckerl und Kaugummi', 'Chips', 'Limonade'], explanation: 'Obst und Gemüse enthalten viele Vitamine.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Wie heißt es, wenn Wasser in der Sonnenwärme zu unsichtbarem Wasserdampf wird?', answer: 'Verdunstung', choices: <String>['Verdunstung', 'Gefrieren', 'Schmelzen', 'Versickern'], explanation: 'Bei der Verdunstung wird flüssiges Wasser zu Wasserdampf.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Wie nennt man Regen, Schnee oder Hagel zusammen?', answer: 'Niederschlag', choices: <String>['Niederschlag', 'Verdunstung', 'Grundwasser', 'Luftfeuchtigkeit'], explanation: 'Niederschlag fällt aus Wolken.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Wohin fließt ein Bach meistens?', answer: 'in einen Fluss', choices: <String>['in einen Fluss', 'zurück zur Quelle', 'auf einen Berg hinauf', 'in eine Wolke'], explanation: 'Bäche fließen bergab und münden meist in einen Fluss.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Woraus bestehen Wolken?', answer: 'aus winzigen Wassertröpfchen', choices: <String>['aus winzigen Wassertröpfchen', 'aus Rauch, der aus den Kaminen steigt', 'aus feinem Staub', 'aus weißer Watte'], explanation: 'Wolken bestehen aus winzigen Wassertröpfchen oder Eiskristallen. Sie entstehen, wenn Wasserdampf in der Höhe abkühlt.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tierklasse hat Federn?', answer: 'Vögel', choices: <String>['Vögel', 'Fische', 'Insekten', 'Säugetiere'], explanation: 'Vögel haben Federn.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tierklasse hat Schuppen und lebt im Wasser?', answer: 'Fische', choices: <String>['Fische', 'Vögel', 'Spinnen', 'Säugetiere'], explanation: 'Viele Fische haben Schuppen und Kiemen.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tiere haben sechs Beine?', answer: 'Insekten', choices: <String>['Insekten', 'Säugetiere', 'Fische', 'Vögel'], explanation: 'Insekten haben sechs Beine.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Welche Tiere säugen ihre Jungen?', answer: 'Säugetiere', choices: <String>['Säugetiere', 'Fische', 'Insekten', 'Vögel'], explanation: 'Säugetiere geben den Jungen Milch.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welches Bundesland ist das kleinste?', answer: 'Wien', choices: <String>['Wien', 'Vorarlberg', 'Burgenland', 'Salzburg'], explanation: 'Wien hat die kleinste Fläche, aber die meisten Einwohnerinnen und Einwohner.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'In welchem Bundesland liegt Innsbruck?', answer: 'Tirol', choices: <String>['Tirol', 'Salzburg', 'Kärnten', 'Vorarlberg'], explanation: 'Innsbruck ist die Landeshauptstadt von Tirol.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Wie heißt die Bundeshauptstadt von Österreich?', answer: 'Wien', choices: <String>['Wien', 'Berlin', 'Graz', 'St. Pölten'], explanation: 'Die Bundeshauptstadt Österreichs ist Wien.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Stadt ist Hauptstadt von Niederösterreich?', answer: 'St. Pölten', choices: <String>['St. Pölten', 'Wien', 'Linz', 'Eisenstadt'], explanation: 'St. Pölten ist Landeshauptstadt von Niederösterreich.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welches Bundesland liegt ganz im Osten Österreichs?', answer: 'Burgenland', choices: <String>['Burgenland', 'Tirol', 'Vorarlberg', 'Salzburg'], explanation: 'Das Burgenland liegt im Osten.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Bundesländer grenzen an Niederösterreich?', answer: 'Wien, Oberösterreich, Steiermark, Burgenland', choices: <String>['Wien, Oberösterreich, Steiermark, Burgenland', 'Tirol und Vorarlberg', 'Kärnten und Salzburg', 'nur Wien'], explanation: 'Niederösterreich umgibt Wien und grenzt an mehrere Bundesländer.'),
  ScienceQuestion(grade: 3, unit: 'Verkehr', prompt: 'Was bedeutet Vorrang?', answer: 'jemand darf zuerst fahren oder gehen', choices: <String>['jemand darf zuerst fahren oder gehen', 'niemand muss mehr schauen', 'alle fahren gleichzeitig los', 'nur Autos dürfen fahren, niemand geht'], explanation: 'Vorrang regelt, wer zuerst darf.'),
  ScienceQuestion(grade: 3, unit: 'Zeit und Kalender', prompt: 'Was ist ein Kalender?', answer: 'eine Übersicht über Tage, Wochen und Monate', choices: <String>['eine Übersicht über Tage, Wochen und Monate', 'eine Uhr für Stunden und Minuten', 'eine Landkarte', 'ein Stundenplan nur für die Schule'], explanation: 'Ein Kalender ordnet Zeit.'),
  ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Welche Aufgabe hat die Blüte?', answer: 'aus ihr entstehen Früchte und Samen', choices: <String>['aus ihr entstehen Früchte und Samen', 'sie nimmt Wasser aus dem Boden auf', 'sie hält die Pflanze im Boden fest', 'sie trägt die Blätter'], explanation: 'Aus bestäubten Blüten können Früchte und Samen entstehen.'),
  ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Was entsteht im Boden aus abgestorbenen Pflanzenresten?', answer: 'Humus', choices: <String>['Humus', 'Kies', 'Sand', 'Granit'], explanation: 'Humus entsteht aus zersetzten Pflanzenresten. Er macht den Boden fruchtbar.'),
  ScienceQuestion(grade: 3, unit: 'Wetter', prompt: 'Was zeigt die Windrichtung?', answer: 'woher der Wind kommt', choices: <String>['woher der Wind kommt', 'wie stark der Wind weht', 'wie warm der Wind ist', 'wie lange der Wind weht'], explanation: 'Die Windrichtung beschreibt, woher der Wind weht. Westwind kommt aus dem Westen.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Warum putzen wir die Zähne?', answer: 'damit sie gesund bleiben', choices: <String>['damit sie gesund bleiben', 'damit sie schneller wachsen', 'damit sie spitzer werden', 'damit sie größer werden'], explanation: 'Zähneputzen schützt vor Karies.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was ist eine ausgewogene Jause?', answer: 'Semmel, Käse, Gemüse und Wasser', choices: <String>['Semmel, Käse, Gemüse und Wasser', 'nur Zuckerln', 'nur Limo', 'nur Schlagobers'], explanation: 'Eine gute Jause hat verschiedene gesunde Teile.'),
  ScienceQuestion(grade: 3, unit: 'Tiere', prompt: 'Warum brauchen Tiere einen Lebensraum?', answer: 'für Nahrung, Schutz und Nachwuchs', choices: <String>['für Nahrung, Schutz und Nachwuchs', 'nur zum Schlafen', 'nur zum Spielen', 'nur zum Verstecken'], explanation: 'Ein Lebensraum deckt wichtige Bedürfnisse.'),
  ScienceQuestion(grade: 3, unit: 'Wasserkreislauf', prompt: 'Was ist Grundwasser?', answer: 'Wasser unter der Erde', choices: <String>['Wasser unter der Erde', 'Wasser in den Wolken', 'Wasser im Meer', 'Wasser in der Regentonne'], explanation: 'Grundwasser sammelt sich unter der Erde. Daraus kommt viel Trinkwasser.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welche Farben hat die österreichische Flagge?', answer: 'rot-weiß-rot', choices: <String>['rot-weiß-rot', 'schwarz-rot-gold', 'blau-gelb', 'grün-weiß-grün'], explanation: 'Österreichs Flagge ist rot-weiß-rot.'),
  ScienceQuestion(grade: 3, unit: 'Familie und Gemeinschaft', prompt: 'Was ist eine Regel?', answer: 'eine Abmachung, an die sich alle halten', choices: <String>['eine Abmachung, an die sich alle halten', 'ein Wunsch, der nur für ein Kind gilt', 'eine Strafe für einen Fehler', 'ein Geheimnis zwischen zwei Kindern'], explanation: 'Regeln sind Abmachungen. Sie helfen beim Zusammenleben.'),
  ScienceQuestion(grade: 3, unit: 'Berufe', prompt: 'Wer hilft bei einem Unfall?', answer: 'Rettung', choices: <String>['Rettung', 'Bäckerei', 'Bibliothek', 'Schneiderei'], explanation: 'Die Rettung hilft medizinisch.'),
  ScienceQuestion(grade: 3, unit: 'Pflanzen', prompt: 'Welcher Nadelbaum behält seine Nadeln auch im Winter?', answer: 'Fichte', choices: <String>['Fichte', 'Lärche', 'Buche', 'Ahorn'], explanation: 'Die Fichte ist immergrün. Die Lärche wirft ihre Nadeln im Herbst ab, Buche und Ahorn sind Laubbäume.'),
  ScienceQuestion(grade: 3, unit: 'Körper', prompt: 'Was bedeckt und schützt deinen ganzen Körper?', answer: 'die Haut', choices: <String>['die Haut', 'die Haare', 'die Knochen', 'die Muskeln'], explanation: 'Die Haut bedeckt den ganzen Körper und schützt ihn.'),
  ScienceQuestion(grade: 3, unit: 'Wetter', prompt: 'Was bedeutet Frost?', answer: 'Temperaturen unter 0 Grad', choices: <String>['Temperaturen unter 0 Grad', 'heißer Regen', 'starker Wind', 'dichter Nebel'], explanation: 'Bei Frost ist es kälter als 0 Grad. Wasser gefriert dann zu Eis.'),
  ScienceQuestion(grade: 3, unit: 'Verkehr', prompt: 'Warum sind Reflektoren wichtig?', answer: 'man wird besser gesehen', choices: <String>['man wird besser gesehen', 'man fährt schneller', 'man hört besser', 'man spart Geld'], explanation: 'Reflektoren machen im Dunkeln sichtbar.'),
  ScienceQuestion(grade: 3, unit: 'Ernährung', prompt: 'Was ist Topfen?', answer: 'ein Milchprodukt', choices: <String>['ein Milchprodukt', 'ein Gartenwerkzeug', 'ein Fahrzeug', 'ein Bundesland'], explanation: 'Topfen ist ein österreichisches Milchprodukt.'),
  ScienceQuestion(grade: 3, unit: 'Bundesländer Österreichs', prompt: 'Welches Bundesland hat Eisenstadt als Hauptstadt?', answer: 'Burgenland', choices: <String>['Burgenland', 'Tirol', 'Wien', 'Salzburg'], explanation: 'Eisenstadt ist Hauptstadt des Burgenlands.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie heißt der höchste Berg Österreichs?', answer: 'Großglockner', choices: <String>['Großglockner', 'Ötscher', 'Schneeberg', 'Rax'], explanation: 'Der Großglockner ist Österreichs höchster Berg.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'In welches Meer mündet die Donau?', answer: 'Schwarzes Meer', choices: <String>['Schwarzes Meer', 'Nordsee', 'Mittelmeer', 'Ostsee'], explanation: 'Die Donau fließt von Deutschland durch Österreich bis ins Schwarze Meer.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Wie viele Nachbarländer hat Österreich?', answer: '8', choices: <String>['8', '6', '7', '9'], explanation: 'Deutschland, Tschechien, Slowakei, Ungarn, Slowenien, Italien, Schweiz und Liechtenstein.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welches dieser Länder ist ein Nachbarland Österreichs?', answer: 'Ungarn', choices: <String>['Ungarn', 'Frankreich', 'Polen', 'Kroatien'], explanation: 'Ungarn grenzt im Osten an Österreich. Frankreich, Polen und Kroatien haben keine Grenze zu Österreich.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welcher See liegt im Osten Österreichs?', answer: 'Neusiedler See', choices: <String>['Neusiedler See', 'Bodensee', 'Attersee', 'Wörthersee'], explanation: 'Der Neusiedler See liegt im Burgenland und in Ungarn.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'An welches Land grenzt Niederösterreich im Norden?', answer: 'Tschechien', choices: <String>['Tschechien', 'Italien', 'Schweiz', 'Slowenien'], explanation: 'Niederösterreich grenzt im Norden an Tschechien.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Landeshauptstadt gehört zur Steiermark?', answer: 'Graz', choices: <String>['Graz', 'Linz', 'Innsbruck', 'Bregenz'], explanation: 'Graz ist die Hauptstadt der Steiermark.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Landeshauptstadt gehört zu Tirol?', answer: 'Innsbruck', choices: <String>['Innsbruck', 'Klagenfurt', 'St. Pölten', 'Eisenstadt'], explanation: 'Innsbruck ist die Hauptstadt von Tirol.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'In welcher Zeit lebten Menschen als Jäger und Sammler?', answer: 'Steinzeit', choices: <String>['Steinzeit', 'Mittelalter', 'Neuzeit', 'Zukunft'], explanation: 'In der Steinzeit jagten und sammelten viele Menschen.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was war im Mittelalter oft auf einem Hügel gebaut?', answer: 'Burg', choices: <String>['Burg', 'Flughafen', 'U-Bahn', 'Computerraum'], explanation: 'Burgen boten Schutz.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Wer trug im Mittelalter oft Rüstung?', answer: 'Ritter', choices: <String>['Ritter', 'Pilot', 'Programmierer', 'Schaffner'], explanation: 'Ritter trugen Rüstungen.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was hilft uns, Vergangenes zu verstehen?', answer: 'Quellen', choices: <String>['Quellen', 'Ampeln', 'Batterien', 'Jausenboxen'], explanation: 'Historische Quellen erzählen über früher.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was ist Archäologie?', answer: 'Wissenschaft von alten Funden', choices: <String>['Wissenschaft von alten Funden', 'Wissenschaft vom Wetter von morgen', 'Sport im Schnee', 'Kochen mit Topfen'], explanation: 'Archäologie untersucht Funde aus der Vergangenheit.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Wie viele Kontinente werden meistens gezählt?', answer: '7', choices: <String>['7', '3', '9', '12'], explanation: 'Meist zählt man sieben: Europa, Asien, Afrika, Nordamerika, Südamerika, Australien und die Antarktis.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Welcher Kontinent ist der größte?', answer: 'Asien', choices: <String>['Asien', 'Afrika', 'Europa', 'Australien'], explanation: 'Asien ist der größte Kontinent. Europa ist viel kleiner.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Welcher Ozean ist der größte?', answer: 'Pazifik', choices: <String>['Pazifik', 'Atlantik', 'Indischer Ozean', 'Arktischer Ozean'], explanation: 'Der Pazifik ist der größte Ozean.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Was ist ein Ozean?', answer: 'ein sehr großes Meer', choices: <String>['ein sehr großes Meer', 'ein kleiner Bach im Wald', 'ein Berg', 'ein Bundesland'], explanation: 'Ozeane sind riesige Meere.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was zeigt eine Nahrungskette?', answer: 'wer wen frisst', choices: <String>['wer wen frisst', 'wer welches Heft hat', 'wer zuerst fährt', 'wer lauter singt'], explanation: 'Beispiel: Das Gras wird vom Hasen gefressen, der Hase vom Fuchs.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was machen Zersetzer?', answer: 'sie bauen tote Reste ab', choices: <String>['sie bauen tote Reste ab', 'sie bauen neue Straßen', 'sie schreiben lange Briefe', 'sie löschen Brände'], explanation: 'Zersetzer helfen, Stoffe zurück in den Boden zu bringen.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was ist ein Lebensraum?', answer: 'Ort, an dem Lebewesen leben', choices: <String>['Ort, an dem Lebewesen leben', 'ein Kleidungsstück für den Winter', 'ein Rechenzeichen', 'eine Uhrzeit'], explanation: 'Lebensräume bieten Nahrung und Schutz.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Warum sind Bienen wichtig?', answer: 'sie bestäuben viele Pflanzen', choices: <String>['sie bestäuben viele Pflanzen', 'sie fahren Bus', 'sie drucken Bücher', 'sie bauen Mauern'], explanation: 'Bestäubung hilft Pflanzen bei Früchten und Samen.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was braucht ein einfacher Stromkreis?', answer: 'Batterie, Kabel und Lampe', choices: <String>['Batterie, Kabel und Lampe', 'Batterie, Schnur und Lampe', 'Kabel, Lampe und Papier', 'Batterie, Holzstab und Lampe'], explanation: 'Der Strom fließt von der Batterie durch die Kabel zur Lampe und zurück. Schnur, Papier und Holz leiten keinen Strom.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Wann leuchtet die Lampe im Stromkreis?', answer: 'wenn der Kreis geschlossen ist', choices: <String>['wenn der Kreis geschlossen ist', 'wenn das Kabel fehlt', 'wenn die Batterie leer ist', 'wenn der Schalter offen ist'], explanation: 'Strom fließt nur im geschlossenen Kreis.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was leitet Strom gut?', answer: 'Metall', choices: <String>['Metall', 'Holz', 'Plastik', 'Papier'], explanation: 'Metalle leiten Strom meist gut.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was ist ein Nichtleiter?', answer: 'Plastik', choices: <String>['Plastik', 'Kupfer', 'Eisen', 'Aluminium'], explanation: 'Plastik leitet Strom schlecht.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welcher ist der größte See, der zur Gänze in Österreich liegt?', answer: 'Attersee', choices: <String>['Attersee', 'Neusiedler See', 'Bodensee', 'Wörthersee'], explanation: 'Der Attersee liegt in Oberösterreich. Neusiedler See und Bodensee teilt sich Österreich mit Nachbarländern.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Stadt ist Hauptstadt von Oberösterreich?', answer: 'Linz', choices: <String>['Linz', 'Graz', 'Bregenz', 'Klagenfurt'], explanation: 'Linz ist Hauptstadt von Oberösterreich.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Stadt ist Hauptstadt von Kärnten?', answer: 'Klagenfurt', choices: <String>['Klagenfurt', 'Salzburg', 'Wien', 'Eisenstadt'], explanation: 'Klagenfurt ist Kärntens Landeshauptstadt.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Was ist der Äquator?', answer: 'gedachte Linie um die Erde', choices: <String>['gedachte Linie um die Erde', 'ein hoher Berg in Tirol', 'ein langer Fluss durch Wien', 'ein Werkzeug'], explanation: 'Der Äquator teilt die Erde in Nord und Süd.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Wie hieß die große Römerstadt an der Donau in Niederösterreich?', answer: 'Carnuntum', choices: <String>['Carnuntum', 'Rom', 'Pompeji', 'Athen'], explanation: 'Carnuntum lag an der Donau östlich von Wien. Heute kann man dort eine Römerstadt besichtigen.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was bedeutet nachhaltig?', answer: 'so handeln, dass die Zukunft geschützt wird', choices: <String>['so handeln, dass die Zukunft geschützt wird', 'alles sofort verbrauchen, was man hat', 'das Licht immer brennen lassen, auch nachts', 'Müll einfach in den Bach werfen'], explanation: 'Nachhaltigkeit denkt an morgen.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Warum soll man nicht an Steckdosen spielen?', answer: 'Strom kann gefährlich sein', choices: <String>['Strom kann gefährlich sein', 'Steckdosen sind essbar', 'Steckdosen machen Musik', 'Strom ist immer kalt'], explanation: 'Strom aus Steckdosen ist gefährlich.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Hauptstadt gehört zu Vorarlberg?', answer: 'Bregenz', choices: <String>['Bregenz', 'Innsbruck', 'Linz', 'St. Pölten'], explanation: 'Bregenz ist Hauptstadt von Vorarlberg.'),
  ScienceQuestion(grade: 4, unit: 'Geografie Österreich', prompt: 'Welche Landeshauptstadt gehört zum Bundesland Salzburg?', answer: 'Salzburg', choices: <String>['Salzburg', 'Graz', 'Wien', 'Klagenfurt'], explanation: 'Die Stadt Salzburg ist die Landeshauptstadt des Bundeslandes Salzburg.'),
  ScienceQuestion(grade: 4, unit: 'Kontinente und Ozeane', prompt: 'Welcher Kontinent ist sehr kalt und am Südpol?', answer: 'Antarktis', choices: <String>['Antarktis', 'Afrika', 'Europa', 'Asien'], explanation: 'Die Antarktis liegt am Südpol.'),
  ScienceQuestion(grade: 4, unit: 'Geschichte', prompt: 'Was war ein Handwerk im Mittelalter?', answer: 'Schmieden', choices: <String>['Schmieden', 'Programmieren', 'Fernsehen', 'Autofahren'], explanation: 'Schmiede stellten Dinge aus Metall her.'),
  ScienceQuestion(grade: 4, unit: 'Ökosysteme', prompt: 'Was schützt ein Wald?', answer: 'Boden, Tiere und Klima', choices: <String>['Boden, Tiere und Klima', 'nur Autos', 'nur Computer', 'nur Ampeln'], explanation: 'Wälder sind wichtige Lebensräume.'),
  ScienceQuestion(grade: 4, unit: 'Stromkreise', prompt: 'Was macht ein Schalter?', answer: 'er öffnet oder schließt den Stromkreis', choices: <String>['er öffnet oder schließt den Stromkreis', 'er misst die Zeit bis zum Einschalten', 'er kocht Suppe', 'er schreibt Wörter auf ein Blatt Papier'], explanation: 'Schalter steuern, ob Strom fließt.'),
];

/// Dritte Regel der Logik-Einheit „Regeln kombinieren“. Wird auch von der
/// Qualitätsprüfung verwendet.
bool combinedRuleProperty(String property, int value) => switch (property) {
      'gerade' => value.isEven,
      'ungerade' => value.isOdd,
      'in der 3er-Reihe' => value % 3 == 0,
      'in der 4er-Reihe' => value % 4 == 0,
      'in der 5er-Reihe' => value % 5 == 0,
      _ => false,
    };
