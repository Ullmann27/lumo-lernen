import '../../../core/primary_school_word_data.dart';
import '../../../core/safe_fallback_pool.dart';
import '../../../core/school_exercise_generator.dart';
import '../../../core/task_quality_guard.dart';
import '../../../core/writing_target_parser.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../domain/learning/seed_memory_service.dart';

/// Temporary bridge from the current legacy ExerciseFactory/LumoTask flow to
/// the new adaptive TaskInstance renderer.
///
/// This keeps the current app stable while allowing LearningContent to migrate
/// gradually to AdaptiveTaskRenderer without a big-bang rewrite.
class LegacyLumoTaskAdapter {
  const LegacyLumoTaskAdapter();

  static const _qualityGuard = TaskQualityGuard();
  static const _fallbackPool = SafeFallbackPool();
  static int _fallbackCounter = 0;

  TaskInstance toTaskInstance({
    required LumoTask task,
    required String childId,
    required int difficulty,
    DateTime? now,
  }) {
    final fixedTask = _qualityCheckedTask(task);
    final generatedAt = now ?? DateTime.now();
    final subject = _subject(fixedTask.subject);
    final taskType = fixedTask.handwriting ? TaskType.writingCanvas : _taskType(fixedTask.visual);
    final visualType = _visual(fixedTask.visual, handwriting: fixedTask.handwriting);
    final correctAnswer = _payload(fixedTask.answer);

    final rawSeed = '${fixedTask.id}|$childId|${fixedTask.prompt}|${fixedTask.answer}';
    final seedHash = SeedMemoryService.stableSeedHash(rawSeed);

    return TaskInstance(
      taskInstanceId: 'legacy_${SeedMemoryService.stableSeedHash('$rawSeed|${generatedAt.microsecondsSinceEpoch}')}',
      templateId: 'legacy.${fixedTask.subject}.${fixedTask.unit}',
      childId: childId,
      seedHash: seedHash,
      subject: subject,
      skillId: SkillId('legacy.${fixedTask.subject}.${fixedTask.unit}'.toLowerCase().replaceAll(' ', '_')),
      taskType: taskType,
      difficulty: difficulty,
      parameters: <String, Object?>{
        'legacyId': fixedTask.id,
        'unit': fixedTask.unit,
        'visual': fixedTask.visual,
        if (fixedTask.handwriting) 'symbol': WritingTargetParser.parse(fixedTask.prompt),
      },
      prompt: fixedTask.prompt,
      options: fixedTask.choices
          .map((choice) => AnswerOption(
                id: choice,
                label: choice,
                payload: _payload(choice),
              ))
          .toList(growable: false),
      correctAnswer: correctAnswer,
      visualPayload: VisualPayload(
        type: visualType,
        data: _visualData(fixedTask),
      ),
      helpPayload: HelpPayload(
        level: _helpLevel(fixedTask),
        shortHint: fixedTask.explanation,
        guidedSteps: _guidedSteps(fixedTask),
      ),
      generatedAt: generatedAt,
    );
  }

  LumoTask _qualityCheckedTask(LumoTask task) {
    final sanitized = _sanitizeTask(task);
    if (_qualityGuard.validate(sanitized)) return sanitized;
    final fallback = _safeFallbackTask(sanitized);
    final repaired = _sanitizeTask(fallback);
    return _qualityGuard.validate(repaired) ? repaired : fallback;
  }

  LumoTask _safeFallbackTask(LumoTask task) {
    if (task.handwriting) return task;
    return _fallbackPool.pick(
      subject: task.subject == 'Mathematik' ? 'Mathematik' : 'Deutsch',
      grade: task.grade,
      counter: _fallbackCounter++,
      unit: task.unit,
      difficulty: task.difficulty,
      missionTag: task.missionTag,
    );
  }

  /// Sicherheitsnetz fuer alte Generator-Aufgaben:
  /// - falsche Endlaut-Aufgaben werden korrigiert,
  /// - Antwortkarten werden eindeutig gemacht,
  /// - Rechtschreibkarten bekommen keine nur-gross/klein-duplizierten Woerter,
  /// - Bild-Wort-Aufgaben behalten genau eine richtige Antwort,
  /// - generische Dauer-Distraktoren wie Auto/Sonne/Haus werden reduziert,
  /// - Antwortkarten werden rotiert, damit die richtige Antwort nicht immer
  ///   an derselben Stelle steht.
  LumoTask _sanitizeTask(LumoTask task) {
    var answer = task.answer;
    var choices = List<String>.from(task.choices);
    var explanation = task.explanation;

    final endingMatch = RegExp(r'endet\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(task.prompt);
    if (endingMatch != null) {
      final ending = (endingMatch.group(1) ?? '').toLowerCase();
      final normalizedAnswer = _normalizeWord(answer);
      final hasValidAnswer = normalizedAnswer.endsWith(ending);
      final validChoices = choices.where((choice) => _normalizeWord(choice).endsWith(ending)).toList(growable: false);
      if (!hasValidAnswer || validChoices.length != 1) {
        answer = _wordEndingWith(ending);
        choices = <String>[answer, ..._wordsNotEndingWith(ending, count: 3)];
        explanation = 'Sprich jedes Wort langsam. Nur $answer endet mit $ending.';
      }
    }

    if (task.subject == 'Rechtschreibung' && task.unit == 'Haeufige Woerter') {
      choices = _spellingChoicesFor(answer);
    }

    if (task.unit == 'Wortende') {
      choices = _singleCorrectEndingChoices(answer, task.prompt, choices);
    }

    if (task.unit == 'Wort-Bild schreiben') {
      choices = _distinctChoices(answer, fallbackPool: const <String>['Blume', 'Rose', 'Apfel', 'Biene', 'Kerze', 'Igel']);
    } else {
      // KRITISCH: Wenn das Template bereits sinnvolle Choices liefert
      // (z.B. Geometrie ['Dreieck','Kreis','Quadrat','Rechteck','Oval']),
      // dann diese BEHALTEN und nur Lucken mit Kategorie-passenden
      // Distraktoren fuellen. Vorher wurden Form-Antworten durch
      // 'Blume'/'Kerze' ersetzt - kompletter Quatsch fuer Geometrie.
      final templateChoices = choices.where((c) => _normalizeChoice(c).isNotEmpty).toList();
      // Sicherstellen dass die richtige Antwort in den Choices ist.
      if (!templateChoices.any((c) => _normalizeChoice(c) == _normalizeChoice(answer))) {
        templateChoices.insert(0, answer);
      }
      if (templateChoices.length >= 3) {
        // Template hat genug gute Choices - alle behalten, deduplizieren.
        choices = _distinctChoices(answer, fallbackPool: templateChoices);
      } else {
        // Template hat zu wenig Choices - mit Kategorie-Pool auffuellen.
        final pool = <String>[
          ...templateChoices,
          ..._fallbackChoicesFor(answer),
        ];
        choices = _distinctChoices(answer, fallbackPool: pool);
      }
    }

    choices = _rotateChoices(choices, '${task.id}|${task.prompt}|$answer');

    final repaired = LumoTask(
      id: task.id,
      grade: task.grade,
      subject: task.subject,
      unit: task.unit,
      prompt: task.prompt,
      choices: choices,
      answer: answer,
      explanation: explanation,
      handwriting: task.handwriting,
      visual: task.visual,
      difficulty: task.difficulty,
      missionTag: task.missionTag,
    );
    return _variedTask(repaired);
  }

  LumoTask _variedTask(LumoTask task) {
    if (task.handwriting) return task;
    final prompt = task.prompt.toLowerCase();

    if (prompt.contains('welcher satz ist richtig')) {
      return _sentenceVariant(task);
    }
    if (prompt.contains('der fuchs liest ein buch')) {
      return _readingActionVariant(task);
    }
    if (prompt.contains('welches wort ist ein namenswort') || prompt.contains('welches wort ist ein hauptwort')) {
      return _nounVariant(task);
    }
    if (prompt.contains('welches wort ist ein tunwort')) {
      return _verbVariant(task);
    }
    if (prompt.contains('beschreibt, wie') || prompt.contains('welches wort ist ein wiewort')) {
      return _adjectiveVariant(task);
    }
    if (prompt.contains('reimt sich auf') && _containsOverusedText('${task.prompt} ${task.answer} ${task.choices.join(' ')}')) {
      return _rhymeVariant(task);
    }
    if ((task.unit == 'Anfangslaute' || task.unit == 'Endlaute') && _containsOverusedText(task.prompt)) {
      return _soundVariant(task);
    }

    return _replaceOverusedDistractors(task);
  }

  LumoTask _sentenceVariant(LumoTask task) {
    const variants = <List<String>>[
      <String>['Die Katze schläft.', 'schläft die Katze', 'Katze die schläft'],
      <String>['Der Igel trinkt.', 'trinkt der Igel', 'Igel der trinkt'],
      <String>['Die Biene fliegt.', 'fliegt die Biene', 'Biene die fliegt'],
      <String>['Das Kind malt.', 'malt das Kind', 'Kind das malt'],
      <String>['Oma liest leise.', 'liest leise Oma', 'leise Oma liest'],
      <String>['Der Vogel singt.', 'singt der Vogel', 'Vogel der singt'],
      <String>['Lumo zählt Sterne.', 'zählt Lumo Sterne', 'Sterne Lumo zählt'],
    ];
    final v = variants[_varietyIndex(task, variants.length)];
    return _copyTask(
      task,
      prompt: 'Welcher Satz ist richtig?',
      answer: v[0],
      choices: _rotateChoices(<String>[v[0], v[1], v[2]], '${task.id}|satz'),
      explanation: 'Ein Satz beginnt groß und endet mit einem Punkt.',
    );
  }

  LumoTask _readingActionVariant(LumoTask task) {
    const variants = <List<String>>[
      <String>['Die Katze schläft auf der Decke. Was macht die Katze?', 'schlafen', 'Katze', 'Decke'],
      <String>['Oma backt einen Kuchen. Was macht Oma?', 'backen', 'Oma', 'Kuchen'],
      <String>['Der Igel trinkt Wasser. Was macht der Igel?', 'trinken', 'Igel', 'Wasser'],
      <String>['Das Kind malt ein Bild. Was macht das Kind?', 'malen', 'Kind', 'Bild'],
      <String>['Der Vogel singt im Baum. Was macht der Vogel?', 'singen', 'Vogel', 'Baum'],
    ];
    final v = variants[_varietyIndex(task, variants.length)];
    return _copyTask(
      task,
      prompt: v[0],
      answer: v[1],
      choices: _rotateChoices(<String>[v[1], v[2], v[3]], '${task.id}|leseaktion'),
      explanation: 'Suche im Satz das Tunwort.',
    );
  }

  LumoTask _nounVariant(LumoTask task) {
    const nouns = <String>['Baum', 'Blume', 'Katze', 'Maus', 'Apfel', 'Rose', 'Buch', 'Lampe', 'Biene', 'Kerze', 'Wolke', 'Tasche'];
    const distractors = <String>['lesen', 'rot', 'malen', 'klein', 'tanzen', 'schnell', 'springen', 'warm', 'laufen', 'leise'];
    final answer = nouns[_varietyIndex(task, nouns.length)];
    final offset = _varietyIndex(task, distractors.length);
    final wrong = <String>[
      distractors[offset],
      distractors[(offset + 3) % distractors.length],
    ];
    return _copyTask(
      task,
      answer: answer,
      choices: _rotateChoices(<String>[answer, ...wrong], '${task.id}|nomen'),
      explanation: 'Namenswörter sind Dinge, Personen oder Tiere und werden groß geschrieben.',
    );
  }

  LumoTask _verbVariant(LumoTask task) {
    const verbs = <String>['laufen', 'malen', 'lesen', 'springen', 'singen', 'lachen', 'spielen', 'tanzen', 'schreiben', 'rechnen'];
    const distractors = <String>['Blume', 'Kerze', 'leise', 'Biene', 'Wolke', 'klein', 'Apfel', 'Rose'];
    final answer = verbs[_varietyIndex(task, verbs.length)];
    final offset = _varietyIndex(task, distractors.length);
    return _copyTask(
      task,
      answer: answer,
      choices: _rotateChoices(<String>[answer, distractors[offset], distractors[(offset + 2) % distractors.length]], '${task.id}|verb'),
      explanation: 'Ein Tunwort sagt, was jemand macht.',
    );
  }

  LumoTask _adjectiveVariant(LumoTask task) {
    const adjectives = <String>['groß', 'klein', 'warm', 'schnell', 'weich', 'kalt', 'hell', 'dunkel', 'schön', 'leise', 'rund', 'langsam'];
    const distractors = <String>['Blume', 'Kerze', 'lesen', 'Biene', 'Apfel', 'malen', 'Rose', 'tanzen'];
    final answer = adjectives[_varietyIndex(task, adjectives.length)];
    final offset = _varietyIndex(task, distractors.length);
    return _copyTask(
      task,
      answer: answer,
      choices: _rotateChoices(<String>[answer, distractors[offset], distractors[(offset + 2) % distractors.length]], '${task.id}|adjektiv'),
      explanation: 'Ein Wiewort beschreibt eine Eigenschaft.',
    );
  }

  LumoTask _rhymeVariant(LumoTask task) {
    const pairs = <List<String>>[
      <String>['Hase', 'Nase', 'Blume', 'Kerze'],
      <String>['Ball', 'Fall', 'Biene', 'Rose'],
      <String>['Kanne', 'Tanne', 'Apfel', 'Wolke'],
      <String>['Stein', 'Bein', 'Blume', 'Tasche'],
      <String>['Hut', 'Mut', 'Kerze', 'Biene'],
    ];
    final v = pairs[_varietyIndex(task, pairs.length)];
    return _copyTask(
      task,
      prompt: 'Was reimt sich auf ${v[0]}?',
      answer: v[1],
      choices: _rotateChoices(<String>[v[1], v[2], v[3]], '${task.id}|reim'),
      explanation: 'Reimwörter klingen am Ende gleich.',
    );
  }

  LumoTask _soundVariant(LumoTask task) {
    const startWords = <String>['Tasse', 'Lampe', 'Igel', 'Nase', 'Rose', 'Kerze', 'Wolke', 'Biene'];
    const endWords = <String>['Brot', 'Rad', 'Glas', 'Rose', 'Apfel', 'Garten', 'Stift', 'Blatt'];
    final isEnd = task.unit == 'Endlaute';
    final words = isEnd ? endWords : startWords;
    final word = words[_varietyIndex(task, words.length)];
    final answer = isEnd ? word.substring(word.length - 1).toLowerCase() : word.substring(0, 1).toUpperCase();
    return _copyTask(
      task,
      prompt: isEnd ? 'Mit welchem Laut endet $word?' : 'Mit welchem Laut beginnt $word?',
      answer: answer,
      choices: _rotateChoices(_soundChoices(answer), '${task.id}|laut'),
      explanation: isEnd ? 'Sprich $word langsam. Der letzte Laut ist $answer.' : 'Sprich $word langsam. Der erste Laut ist $answer.',
    );
  }

  LumoTask _replaceOverusedDistractors(LumoTask task) {
    if (!_containsOverusedText(task.choices.join(' '))) return task;
    final targetCount = task.choices.length.clamp(3, 5).toInt();
    final result = <String>[task.answer];
    for (final choice in task.choices) {
      if (_normalizeChoice(choice) == _normalizeChoice(task.answer)) continue;
      if (_isOverused(choice)) continue;
      if (result.length >= targetCount) break;
      if (!result.any((item) => _normalizeChoice(item) == _normalizeChoice(choice))) result.add(choice);
    }
    for (final choice in _fallbackChoicesFor(task.answer)) {
      if (result.length >= targetCount) break;
      if (_isOverused(choice)) continue;
      if (!result.any((item) => _normalizeChoice(item) == _normalizeChoice(choice))) result.add(choice);
    }
    return _copyTask(task, choices: _rotateChoices(result, '${task.id}|generic-clean'));
  }

  LumoTask _copyTask(
    LumoTask task, {
    String? prompt,
    String? answer,
    List<String>? choices,
    String? explanation,
    String? visual,
  }) {
    return LumoTask(
      id: task.id,
      grade: task.grade,
      subject: task.subject,
      unit: task.unit,
      prompt: prompt ?? task.prompt,
      choices: choices ?? task.choices,
      answer: answer ?? task.answer,
      explanation: explanation ?? task.explanation,
      handwriting: task.handwriting,
      visual: visual ?? task.visual,
      difficulty: task.difficulty,
      missionTag: task.missionTag,
    );
  }

  List<String> _singleCorrectEndingChoices(String answer, String prompt, List<String> choices) {
    final match = RegExp(r'endet\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(prompt);
    if (match == null) return choices;
    final ending = (match.group(1) ?? '').toLowerCase();
    final correct = _normalizeWord(answer).endsWith(ending) ? answer : _wordEndingWith(ending);
    return <String>[correct, ..._wordsNotEndingWith(ending, count: 4)];
  }

  List<String> _distinctChoices(String answer, {required List<String> fallbackPool, int targetCount = 3}) {
    final result = <String>[];
    void add(String value) {
      final normalized = _normalizeChoice(value);
      if (normalized.isEmpty) return;
      if (result.any((item) => _normalizeChoice(item) == normalized)) return;
      result.add(value);
    }

    add(answer);
    for (final choice in fallbackPool) {
      if (result.length >= targetCount) break;
      add(choice);
    }
    while (result.length < targetCount) {
      add('$answer ${result.length + 1}');
    }
    return result;
  }

  List<String> _rotateChoices(List<String> choices, String seed) {
    if (choices.length < 2) return choices;
    final offset = (seed.hashCode & 0x7fffffff) % choices.length;
    return <String>[...choices.skip(offset), ...choices.take(offset)];
  }

  int _varietyIndex(LumoTask task, int length) {
    if (length <= 1) return 0;
    return ('${task.id}|${task.prompt}|${task.answer}'.hashCode & 0x7fffffff) % length;
  }

  bool _containsOverusedText(String value) {
    final normalized = _normalizeChoice(value);
    return _overusedWords.any((word) => RegExp('(^|\\s)$word(\\s|4)').hasMatch(normalized));
  }

  bool _isOverused(String value) => _overusedWords.contains(_normalizeChoice(value));

  static const Set<String> _overusedWords = <String>{
    'auto',
    'sonne',
    'haus',
    'mama',
    'hund',
    'fuchs',
  };

  List<String> _soundChoices(String answer) {
    const bank = <String>['A', 'B', 'E', 'I', 'K', 'L', 'N', 'R', 'T', 'W'];
    final result = <String>[answer];
    for (final item in bank) {
      if (result.length >= 3) break;
      if (_normalizeChoice(item) != _normalizeChoice(answer)) result.add(item);
    }
    return result;
  }

  List<String> _fallbackChoicesFor(String answer) {
    final n = int.tryParse(answer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (n != null) return <String>['$n', '${n + 1}', '${n == 0 ? 2 : n - 1}', '${n + 2}'];
    // Kategorie-bewusste Distraktoren: erst pruefen, ob die Antwort
    // zu einer bekannten Kategorie gehoert (Form, Farbe, Tier, etc).
    // Dann NUR Distraktoren aus derselben Kategorie liefern.
    // Vorher kamen 'Blume'/'Kerze' als Antworten bei Geometrie-Aufgaben - kaputt.
    final category = _categoryOfAnswer(answer);
    if (category != null) return <String>[answer, ...category];
    // Fallback: gemischter Wort-Pool fuer komplett unbekannte Antworten.
    return <String>[answer, 'Blume', 'Kerze', 'Biene', 'Wolke', 'Baum', 'Katze', 'Apfel', 'Rose', 'Igel'];
  }

  /// Erkennt die semantische Kategorie der Antwort und liefert passende
  /// Distraktoren aus derselben Kategorie zurueck.
  /// Verhindert dass z.B. bei 'Kreis' (Geometrie) 'Blume' als Antwort kommt.
  List<String>? _categoryOfAnswer(String answer) {
    final a = answer.trim();
    // Geometrische Formen
    const shapes = <String>['Dreieck', 'Kreis', 'Quadrat', 'Rechteck', 'Oval', 'Stern', 'Raute', 'Pentagon', 'Sechseck'];
    if (shapes.contains(a)) return shapes.where((s) => s != a).take(3).toList();
    // Farben
    const colors = <String>['Rot', 'Blau', 'Gruen', 'Grün', 'Gelb', 'Orange', 'Lila', 'Schwarz', 'Weiss', 'Weiß'];
    if (colors.contains(a)) return colors.where((s) => s != a).take(3).toList();
    // Wochentage
    const weekdays = <String>['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    if (weekdays.contains(a)) return weekdays.where((s) => s != a).take(3).toList();
    // Monate
    const months = <String>['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    if (months.contains(a)) return months.where((s) => s != a).take(3).toList();
    // Jahreszeiten
    const seasons = <String>['Frühling', 'Sommer', 'Herbst', 'Winter'];
    if (seasons.contains(a)) return seasons.where((s) => s != a).take(3).toList();
    // Tiere
    const animals = <String>['Hund', 'Katze', 'Maus', 'Hase', 'Igel', 'Biene', 'Vogel', 'Fisch', 'Pferd', 'Kuh', 'Schaf', 'Ente'];
    if (animals.contains(a)) return animals.where((s) => s != a).take(3).toList();
    // Pflanzen
    const plants = <String>['Blume', 'Rose', 'Tulpe', 'Baum', 'Strauch', 'Gras', 'Apfel'];
    if (plants.contains(a)) return plants.where((s) => s != a).take(3).toList();
    // Wortarten
    const wordTypes = <String>['Nomen', 'Verb', 'Adjektiv', 'Artikel', 'Pronomen'];
    if (wordTypes.contains(a)) return wordTypes.where((s) => s != a).take(3).toList();
    // Artikel
    const articles = <String>['der', 'die', 'das'];
    if (articles.contains(a.toLowerCase())) return articles.where((s) => s != a.toLowerCase()).take(2).toList();
    // Ja/Nein-Fragen
    const yesno = <String>['ja', 'nein', 'vielleicht'];
    if (yesno.contains(a.toLowerCase())) return yesno.where((s) => s != a.toLowerCase()).toList();
    // Vergleich
    const compare = <String>['mehr', 'weniger', 'gleich', 'gleich viel'];
    if (compare.contains(a.toLowerCase())) return compare.where((s) => s != a.toLowerCase()).take(2).toList();
    // Richtung
    const direction = <String>['links', 'rechts', 'oben', 'unten', 'gerade'];
    if (direction.contains(a.toLowerCase())) return direction.where((s) => s != a.toLowerCase()).take(3).toList();
    return null;
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
      'sonne' => const <String>['Sone', 'Sonne Sonne'],
      'spielen' => const <String>['spilen', 'schpielen'],
      'kommen' => const <String>['komen', 'komenn'],
      'schule' => const <String>['Schuhle', 'schule'],
      'freund' => const <String>['Froind', 'Freunt'],
      'heute' => const <String>['hoite', 'heude'],
      'klein' => const <String>['kline', 'Klein'],
      'gross' => const <String>['gros', 'grohs'],
      _ => <String>['${correct}e', '${correct}n'],
    };
    return _distinctChoices(correct, fallbackPool: <String>[correct, ...distractors, 'Blume', 'Kerze', 'Biene']);
  }

  String _wordEndingWith(String ending) {
    final bank = <String, List<String>>{
      't': <String>['Stift', 'Hut', 'Boot', 'Brot', 'Blatt'],
      'd': <String>['Rad', 'Wald', 'Bild', 'Kind'],
      's': <String>['Glas', 'Bus', 'Reis'],
      'e': <String>['Hase', 'Rose', 'Lampe', 'Blume', 'Tasse'],
      'n': <String>['Banane', 'Kaninchen', 'Ofen', 'Garten'],
      'l': <String>['Apfel', 'Igel', 'Pinsel'],
    };
    final words = bank[ending] ?? <String>['Stift'];
    return words.first;
  }

  List<String> _wordsNotEndingWith(String ending, {required int count}) {
    final bank = <String>['Hase', 'Rose', 'Apfel', 'Igel', 'Schule', 'Banane', 'Blume', 'Kerze', 'Biene', 'Wolke', 'Tasche', 'Garten'];
    return bank
        .where((word) => !_normalizeWord(word).endsWith(ending))
        .take(count)
        .toList(growable: false);
  }

  String _normalizeChoice(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _normalizeWord(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');

  LearningSubject _subject(String value) {
    return switch (value) {
      'Deutsch' || 'Rechtschreibung' || 'Schreiben' || 'Lesen' => LearningSubject.deutsch,
      'Sachunterricht' => LearningSubject.sachkunde,
      _ => LearningSubject.mathematik,
    };
  }

  TaskType _taskType(String value) {
    return switch (value) {
      'line' => TaskType.numberLine,
      'sequence' => TaskType.numberLine,
      'dots' => TaskType.dotGroups,
      'ten_ones' => TaskType.tenOnes,
      'number_house' => TaskType.multipleChoice,
      'sound_choice' => TaskType.multipleChoice,
      'writing_line' => TaskType.multipleChoice,
      'blitz_grid' => TaskType.multipleChoice,
      _ => TaskType.multipleChoice,
    };
  }

  VisualType _visual(String value, {required bool handwriting}) {
    if (handwriting) return VisualType.writingPath;
    return switch (value) {
      'dots' => VisualType.dots,
      'line' => VisualType.numberLine,
      'sequence' => VisualType.numberLine,
      'shape' => VisualType.shape,
      'syllables' => VisualType.syllables,
      'writing' => VisualType.writingPath,
      'ten_ones' => VisualType.tenOnes,
      'number_house' => VisualType.none,
      'sound_choice' => VisualType.none,
      'writing_line' => VisualType.none,
      'blitz_grid' => VisualType.none,
      // Heinz' neue Templates (Mai 2026):
      'number_line' => VisualType.numberLine,
      'quantity_compare' => VisualType.quantityCompare,
      'clock' => VisualType.clock,
      'money_coins' => VisualType.money,
      'shape_choice' => VisualType.shape,
      'fraction_pizza' => VisualType.fractionPizza,
      'bar_chart' => VisualType.barChart,
      // Deutsch:
      'rhyme_bubble' => VisualType.rhymeBubble,
      'syllable_clap' => VisualType.syllableClap,
      'word_family_tree' => VisualType.wordFamilyTree,
      'sentence_blocks' => VisualType.sentenceBlocks,
      'word_type_color' => VisualType.wordTypeColor,
      'article_cards' => VisualType.articleCards,
      'letters' => VisualType.none,
      _ => VisualType.none,
    };
  }

  Map<String, Object?> _visualData(LumoTask task) {
    if (task.handwriting) {
      return <String, Object?>{'symbol': WritingTargetParser.parse(task.prompt)};
    }

    final soundTask = _basicSoundTaskData(task);
    if (soundTask != null) return soundTask;

    if (task.visual == 'number_house') {
      return _numberHouseData(task);
    }

    if (task.visual == 'sound_choice') {
      return _soundChoiceData(task);
    }

    if (task.visual == 'writing_line') {
      return _writingLineData(task);
    }

    if (task.visual == 'blitz_grid') {
      return _blitzGridData(task);
    }

    if (task.visual == 'ten_ones') {
      final n = RegExp(r'(\d+)').firstMatch(task.prompt);
      final value = int.tryParse(n?.group(1) ?? '') ?? 0;
      return <String, Object?>{'tens': value ~/ 10, 'ones': value % 10, 'value': value};
    }

    final plus = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(task.prompt);
    if (plus != null) {
      return <String, Object?>{
        'operation': 'addition',
        'left': int.tryParse(plus.group(1) ?? '0') ?? 0,
        'right': int.tryParse(plus.group(2) ?? '0') ?? 0,
      };
    }

    final minus = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(task.prompt);
    if (minus != null) {
      return <String, Object?>{
        'operation': 'subtraction',
        'start': int.tryParse(minus.group(1) ?? '0') ?? 0,
        'takeAway': int.tryParse(minus.group(2) ?? '0') ?? 0,
      };
    }

    if (task.visual == 'syllables') {
      final match = RegExp(r'hat\s+([^?]+)\?').firstMatch(task.prompt);
      final word = match?.group(1)?.trim();
      final syllables = word == null ? null : PrimarySchoolWordData.syllablesFor(word);
      return <String, Object?>{
        'word': word,
        if (syllables != null) 'syllables': syllables,
      };
    }

    // Heinz' neue Visuals (Mai 2026): jeweils Daten aus Prompt extrahieren,
    // damit die Visuals nicht auf 12:00 / 1/2 / leeres Diagramm zurueckfallen.

    if (task.visual == 'clock') {
      // Stunde X und Minute Y im Prompt? -> Datenpunkt
      final hourMin = RegExp(r'Stunde\s+(\d{1,2}).*?Minute\s+(\d{1,2})').firstMatch(task.prompt);
      if (hourMin != null) {
        return <String, Object?>{
          'hour': int.tryParse(hourMin.group(1)!) ?? 12,
          'minute': int.tryParse(hourMin.group(2)!) ?? 0,
        };
      }
      // Alternativ Antwortmuster "7:30 Uhr" oder "07:30"
      final answerTime = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(task.answer);
      if (answerTime != null) {
        return <String, Object?>{
          'hour': int.tryParse(answerTime.group(1)!) ?? 12,
          'minute': int.tryParse(answerTime.group(2)!) ?? 0,
        };
      }
      return const <String, Object?>{};
    }

    if (task.visual == 'fraction_pizza') {
      // 1/2 im Prompt oder in der Antwort
      final fracInPrompt = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(task.prompt);
      if (fracInPrompt != null) {
        return <String, Object?>{
          'numerator': int.tryParse(fracInPrompt.group(1)!) ?? 1,
          'denominator': int.tryParse(fracInPrompt.group(2)!) ?? 2,
        };
      }
      // "Was ist die Hälfte von 8?" -> 1/2
      if (task.prompt.toLowerCase().contains('hälfte') || task.prompt.toLowerCase().contains('haelfte')) {
        return <String, Object?>{'numerator': 1, 'denominator': 2};
      }
      if (task.prompt.toLowerCase().contains('viertel')) {
        return <String, Object?>{'numerator': 1, 'denominator': 4};
      }
      if (task.prompt.toLowerCase().contains('drittel')) {
        return <String, Object?>{'numerator': 1, 'denominator': 3};
      }
      return const <String, Object?>{};
    }

    if (task.visual == 'money_coins' || task.visual == 'money' || task.visual == 'money_change') {
      // Euro-Betrag im Prompt - akzeptiert '1,50€', '1,50 Euro', '1.50 EUR'
      final euro = RegExp(r'(\d+)\s*(?:[.,](\d{1,2}))?\s*(?:€|Euro|EUR)', caseSensitive: false).firstMatch(task.prompt);
      if (euro != null) {
        final e = int.tryParse(euro.group(1)!) ?? 0;
        final c = int.tryParse(euro.group(2) ?? '0') ?? 0;
        return <String, Object?>{'cents': e * 100 + c, 'amount': e * 100 + c};
      }
      return const <String, Object?>{};
    }

    if (task.visual == 'quantity_compare' || task.visual == 'quantity') {
      // Zwei Zahlen im Prompt vergleichen
      final nums = RegExp(r'\d+').allMatches(task.prompt).map((m) => int.parse(m.group(0)!)).toList();
      if (nums.length >= 2) {
        return <String, Object?>{'left': nums[0], 'right': nums[1]};
      }
      return const <String, Object?>{};
    }

    if (task.visual == 'rhyme_bubble') {
      // Wort aus "reimt sich auf X" - NUR diese Formulierung erlauben,
      // damit 'auf das Bild schauen' nicht 'das' als Reim-Wort extrahiert.
      final match = RegExp(r'reimt sich auf\s+([A-Za-zÄÖÜäöüß]+)', caseSensitive: false).firstMatch(task.prompt);
      final word = match?.group(1)?.trim();
      return <String, Object?>{
        if (word != null && word.isNotEmpty) 'word': word,
      };
    }

    if (task.visual == 'syllable_clap') {
      // Aus 'Wie viele Silben hat X?'
      final match = RegExp(r'hat\s+([A-Za-zÄÖÜäöüß]+)').firstMatch(task.prompt);
      final word = match?.group(1)?.trim();
      final syllables = word == null ? null : PrimarySchoolWordData.syllablesFor(word);
      return <String, Object?>{
        if (word != null) 'word': word,
        if (syllables != null) 'syllables': syllables,
      };
    }

    if (task.visual == 'word_family_tree') {
      // "Welche Wörter gehören zu fahren?"
      final match = RegExp(r'zu\s+([A-Za-zÄÖÜäöüß]+)').firstMatch(task.prompt);
      final root = match?.group(1)?.trim();
      return <String, Object?>{
        if (root != null) 'root': root,
      };
    }

    return const <String, Object?>{};
  }

  Map<String, Object?>? _basicSoundTaskData(LumoTask task) {
    if (task.unit == 'Anfangslaute') {
      final match = RegExp(r'Mit welchem Laut beginnt\s+(.+?)\?').firstMatch(task.prompt);
      final word = match?.group(1)?.trim();
      if (word == null || word.isEmpty) return null;
      return <String, Object?>{
        'word': word,
        'highlight': 'start',
        'sound': task.answer,
      };
    }
    if (task.unit == 'Endlaute') {
      final match = RegExp(r'Mit welchem Laut endet\s+(.+?)\?').firstMatch(task.prompt);
      final word = match?.group(1)?.trim();
      if (word == null || word.isEmpty) return null;
      return <String, Object?>{
        'word': word,
        'highlight': 'end',
        'sound': task.answer,
      };
    }
    return null;
  }

  Map<String, Object?> _numberHouseData(LumoTask task) {
    final match = RegExp(r'Rechenhaus\s+(\d+):\s*(\d+)\s*\+\s*\?').firstMatch(task.prompt);
    final target = int.tryParse(match?.group(1) ?? '') ?? _payloadInt(task.answer);
    final left = int.tryParse(match?.group(2) ?? '') ?? 0;
    final right = _payloadInt(task.answer);
    return <String, Object?>{
      'target': target,
      'left': left,
      'right': right,
      'rows': <Object?>[
        <Object?>[left, right],
        <Object?>[(left + 1).clamp(0, target), (target - left - 1).clamp(0, target)],
        <Object?>[0, target],
      ],
    };
  }

  Map<String, Object?> _soundChoiceData(LumoTask task) {
    final match = RegExp(r'St oder Sp\?\s*(.+)$').firstMatch(task.prompt);
    return <String, Object?>{
      'word': match?.group(1)?.trim() ?? task.prompt,
      'choices': const <String>['St', 'Sp'],
    };
  }

  Map<String, Object?> _writingLineData(LumoTask task) {
    final plural = RegExp(r'Aus 1 mach 2:\s*(.+)\s*->').firstMatch(task.prompt);
    final wordImage = RegExp(r'Bild\s*(.+)\?').firstMatch(task.prompt);
    return <String, Object?>{
      'word': plural?.group(1)?.trim() ?? task.answer,
      'target': task.answer,
      'icon': wordImage?.group(1)?.trim(),
    };
  }

  Map<String, Object?> _blitzGridData(LumoTask task) {
    final main = task.prompt.replaceFirst('Blitzlicht:', '').replaceAll('?', '').trim();
    return <String, Object?>{
      'items': <Object?>[main, _variantExpression(main, 1), _variantExpression(main, 2), _variantExpression(main, 3)],
    };
  }

  List<String> _guidedSteps(LumoTask task) {
    if (task.visual == 'line' && task.prompt.contains('-')) {
      final minus = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(task.prompt);
      final start = int.tryParse(minus?.group(1) ?? '') ?? 0;
      final takeAway = int.tryParse(minus?.group(2) ?? '') ?? 0;
      if (start > 10 && takeAway > start - 10) {
        final first = start - 10;
        final second = takeAway - first;
        return <String>['Erst $first weg bis zur 10.', 'Dann noch $second weg.', 'Jetzt bleibt ${start - takeAway}.'];
      }
    }
    if (task.visual == 'number_house') {
      return const <String>['Schau auf die Dachzahl.', 'Welche Zahl fehlt im Zimmer?', 'Beide Zahlen zusammen ergeben das Dach.'];
    }
    if (task.visual == 'sound_choice') {
      return const <String>['Sprich das Wort langsam.', 'Hoerst du am Anfang St oder Sp?', 'Waehle die passende Karte.'];
    }
    return const <String>[];
  }

  int _helpLevel(LumoTask task) {
    if (task.handwriting) return 1;
    if (task.visual == 'line' && task.prompt.contains('-')) return 2;
    if (task.visual == 'number_house' || task.visual == 'sound_choice' || task.visual == 'writing_line') return 1;
    return 0;
  }

  String _variantExpression(String expression, int offset) {
    final match = RegExp(r'(\d+)\s*([+-])\s*(\d+)').firstMatch(expression);
    if (match == null) return expression;
    final left = (int.tryParse(match.group(1) ?? '') ?? 0) + offset;
    final op = match.group(2) ?? '+';
    final right = int.tryParse(match.group(3) ?? '') ?? 0;
    return '$left $op $right =';
  }

  Object _payload(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
    return number ?? value;
  }

  int _payloadInt(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
  }
}
