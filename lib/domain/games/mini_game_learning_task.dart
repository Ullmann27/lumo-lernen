import 'dart:math';

import '../learning/lumo_learning_domain.dart';
import 'game_level_catalog.dart';
import 'game_level_model.dart';
import 'game_lesson_tasks.dart';
import 'game_math_tasks.dart';

enum MiniGameInput { choice, house, boxes, letters, orderedWords, count }

/// One verified task, used unchanged by rendering, help and answer evaluation.
/// The catalog's level ID remains the durable task-family identifier.
class MiniGameLearningTask {
  const MiniGameLearningTask({
    required this.id,
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.explanation,
    required this.hints,
    required this.subject,
    this.input = MiniGameInput.choice,
    this.visual = const VisualPayload(type: VisualType.none),
    this.house,
    this.initialBoxes = const [],
    this.targetCount,
    this.word = '',
    this.gapIndex,
    this.picture = '',
    this.cue = '',
    this.speech = '',
    this.hour,
    this.minute = 0,
    this.numbers = const [],
    this.count,
  });

  final String id, prompt, answer, explanation, word, picture, cue, speech;
  final List<String> choices, hints;
  final LearningSubject subject;
  final MiniGameInput input;
  final VisualPayload visual;
  final GameHouseTask? house;
  final List<bool> initialBoxes;
  final int? targetCount, gapIndex, hour, count;
  final int minute;
  final List<int> numbers;

  bool accepts(String candidate) => candidate == answer;

  bool get isValid {
    if (id.isEmpty ||
        prompt.trim().isEmpty ||
        answer.trim().isEmpty ||
        explanation.trim().isEmpty ||
        hints.length != 3 ||
        hints.any((hint) => hint.trim().isEmpty)) return false;
    if (input == MiniGameInput.boxes) {
      return initialBoxes.length == 10 &&
          targetCount != null &&
          targetCount! >= 1 &&
          targetCount! <= 10 &&
          answer == '$targetCount';
    }
    if (choices.length < 2 ||
        choices.toSet().length != choices.length ||
        choices.any((choice) => choice.isEmpty)) return false;
    if (input == MiniGameInput.orderedWords) {
      final words = answer.split(' ');
      return words.length == choices.length &&
          words.every(
              (word) => choices.where((choice) => choice == word).length == 1);
    }
    if (choices.where((choice) => choice == answer).length != 1) return false;
    if (input == MiniGameInput.house && house?.isValid != true) return false;
    if (input == MiniGameInput.letters) {
      return gapIndex != null &&
          gapIndex! >= 0 &&
          gapIndex! < word.length &&
          word[gapIndex!] == answer &&
          picture.isNotEmpty &&
          choices.every((choice) => choice.length == 1);
    }
    return input != MiniGameInput.count || count == int.tryParse(answer);
  }

  TaskInstance workspace(
      {required String roundId,
      required String childId,
      required int difficulty}) {
    if (!isValid) throw StateError('Aufgabe ist nicht freigegeben.');
    Object payload(String value) => int.tryParse(value) ?? value;
    return TaskInstance(
      taskInstanceId: '$roundId:$id', templateId: id, childId: childId,
      seedHash: roundId, subject: subject, skillId: SkillId(id),
      taskType: input == MiniGameInput.orderedWords
          ? TaskType.dragDrop
          : TaskType.multipleChoice,
      difficulty: difficulty,
      parameters: {'gameTaskId': id}, prompt: prompt,
      options: [
        for (final choice in choices)
          AnswerOption(id: choice, label: choice, payload: payload(choice))
      ],
      correctAnswer: payload(answer.replaceAll(' €', '')),
      visualPayload: visual,
      helpPayload: HelpPayload(shortHint: hints.first, guidedSteps: hints),
      // A stable local task presentation has no fabricated learning timestamp.
      generatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

abstract final class MiniGameLearningDeck {
  static int taskCount(GameLevel level) => level.id == 25
      ? 6
      : level.id == 13
          ? 10
          : 5;

  static List<MiniGameLearningTask> build(GameLevel level, int seed) {
    final catalog = GameLevelCatalog.byId(level.id);
    if (catalog == null ||
        catalog.miniType != level.miniType ||
        catalog.gradeFloor != level.gradeFloor ||
        seed < 0 ||
        seed >= 1 << 30) {
      throw ArgumentError(
          'Diese Lernspiel-Stufe ist nicht im Katalog freigegeben.');
    }
    if (level.id == 50) {
      throw ArgumentError('Level 50 gehört zur bestehenden Quizshow.');
    }
    final tasks = switch (level.miniType) {
      GameMiniType.colorBoxes => _boxes(level, seed),
      GameMiniType.letterFill => _letters(level, seed),
      GameMiniType.starsPath =>
        List.generate(taskCount(level), (index) => _math(level, index)),
      GameMiniType.numberHouse =>
        List.generate(taskCount(level), (index) => _house(level, index)),
      _ => List.generate(taskCount(level), (index) => _lesson(level, index)),
    };
    if (tasks.length != taskCount(level) ||
        tasks.any((task) => !task.isValid) ||
        tasks.map((task) => task.id).toSet().length != tasks.length) {
      throw StateError('Die Lernspiel-Runde wurde nicht freigegeben.');
    }
    return List.unmodifiable(tasks);
  }

  static String _id(GameLevel level, int index) =>
      'game-level-${level.id}:task-$index';

  static List<String> _arithmeticHints(String prompt, String explanation) {
    final match =
        RegExp(r'(\d+)\s*(?:€\s*)?([+−\-×·])\s*(\d+)').firstMatch(prompt);
    if (match == null)
      return [
        'Vergleiche nur die Mengen in der Aufgabe. Markiere jede Menge einzeln.',
        'Ordne die Dinge in eine Reihe. Zähle jedes Ding genau einmal.',
        explanation,
      ];
    final a = int.parse(match[1]!), b = int.parse(match[3]!);
    return switch (match[2]) {
      '+' => [
          'Zeige zuerst die Menge $a. Dazu kommt die Menge $b.',
          if (a < 10 && b <= 10 && a + b > 10)
            'Im Zehnerfeld mit $a Dingen sind ${10 - a} Plätze frei. Fülle zuerst diese Plätze.'
          else
            'Beginne bei $a und zähle $b weiter. Nutze die Dinge oder die Stellenwerte.',
          explanation,
        ],
      '−' || '-' => [
          'Beginne mit $a. Genau $b sollen weggenommen werden.',
          if (a > 10 && a <= 20 && a - b < 10)
            'Bis zur Zehn nimmst du zuerst ${a - 10} weg. Vom Abzug $b bleibt dann noch ein Teil.'
          else
            'Gehe von $a genau $b Schritte zurück. Prüfe, was übrig bleibt.',
          explanation,
        ],
      _ => [
          'Lege $a gleiche Gruppen mit je $b Dingen.',
          'Zähle die Gruppen in $b-er-Schritten. Jede Gruppe muss gleich groß sein.',
          explanation,
        ],
    };
  }

  static VisualPayload _arithmeticVisual(String prompt, {VisualType? type}) {
    final match =
        RegExp(r'(\d+)\s*(?:€\s*)?([+−\-×·])\s*(\d+)').firstMatch(prompt);
    if (match == null) return VisualPayload(type: type ?? VisualType.none);
    final a = int.parse(match[1]!), b = int.parse(match[3]!);
    final operation = switch (match[2]) {
      '+' => 'addition',
      '−' || '-' => 'subtraction',
      _ => 'multiplication',
    };
    return VisualPayload(
        type: type ??
            (a > 20 || b > 20 ? VisualType.writtenArithmetic : VisualType.dots),
        data: {'a': a, 'b': b, 'operation': operation});
  }

  static MiniGameLearningTask _math(GameLevel level, int index) {
    final task = GameMathTasks.starsPath(level, index);
    final counting = level.id == 4;
    var visual = _arithmeticVisual(task.prompt);
    if (level.id == 6) {
      final values = RegExp(r'\d+')
          .allMatches(task.prompt)
          .map((match) => int.parse(match[0]!))
          .toList();
      visual = VisualPayload(
          type: VisualType.quantityCompare,
          data: {'a': values[0], 'b': values[1], 'operation': 'compare'});
    }
    return MiniGameLearningTask(
      id: _id(level, index),
      prompt: counting ? 'Wie viele Punkte siehst du?' : task.prompt,
      answer: task.answer,
      choices: List.unmodifiable(task.choices),
      explanation: task.explanation,
      hints: _arithmeticHints(task.prompt, task.explanation),
      subject: LearningSubject.mathematik,
      visual: visual,
      input: counting ? MiniGameInput.count : MiniGameInput.choice,
      count: counting ? int.parse(task.answer) : null,
    );
  }

  static MiniGameLearningTask _house(GameLevel level, int index) {
    final task = GameMathTasks.numberHouse(level, index);
    final equation = task.missingLeft
        ? '? + ${task.visibleRoom} = ${task.roof}'
        : '${task.visibleRoom} + ? = ${task.roof}';
    return MiniGameLearningTask(
      id: _id(level, index),
      prompt: 'Welche Zahl fehlt im Rechenhaus?',
      cue: equation,
      answer: '${task.answer}',
      choices: [for (final value in task.choices) '$value'],
      explanation:
          '${task.visibleRoom} + ${task.answer} = ${task.roof}. Beide Zimmer zusammen ergeben die Dachzahl.',
      hints: [
        'Die Dachzahl ${task.roof} ist die ganze Menge. Ein Zimmer enthält ${task.visibleRoom}.',
        'Zähle von ${task.visibleRoom} bis ${task.roof} weiter. Wie viele Schritte fehlen?',
        '${task.visibleRoom} und ${task.answer} ergeben zusammen ${task.roof}.',
      ],
      subject: LearningSubject.mathematik,
      input: MiniGameInput.house,
      house: task,
      visual: VisualPayload(type: VisualType.numberLine),
    );
  }

  static List<MiniGameLearningTask> _boxes(GameLevel level, int seed) {
    final random = Random(seed);
    return List.generate(taskCount(level), (index) {
      final target = 4 + random.nextInt(6);
      final given = target - 1 - random.nextInt(3);
      final positions = List.generate(10, (i) => i)..shuffle(random);
      final boxes = List<bool>.filled(10, false);
      for (final at in positions.take(given)) {
        boxes[at] = true;
      }
      return MiniGameLearningTask(
        id: _id(level, index),
        prompt: 'Male genau $target Kästchen an.',
        answer: '$target',
        choices: const [],
        input: MiniGameInput.boxes,
        subject: LearningSubject.mathematik,
        targetCount: target,
        initialBoxes: List.unmodifiable(boxes),
        explanation: 'Genau $target von 10 Kästchen sind angemalt.',
        hints: [
          'Die Zielzahl ist $target. Zähle zuerst nur die angemalten Kästchen.',
          'Vergleiche deine Menge mit $target. Du kannst jedes Kästchen anmalen oder wieder leeren.',
          'Prüfe Reihe für Reihe: Jeder Haken steht für genau ein angemaltes Kästchen.',
        ],
      );
    });
  }

  // Same 20 word targets and gap indices as the existing LetterFill route.
  // A table is represented by a table, rather than the former chair emoji.
  static const letterBank = <({String word, int gap, String picture})>[
    (word: 'MAUS', gap: 0, picture: 'mouse'),
    (word: 'HUND', gap: 0, picture: 'dog'),
    (word: 'FISCH', gap: 0, picture: 'fish'),
    (word: 'SONNE', gap: 0, picture: 'sun'),
    (word: 'AUTO', gap: 0, picture: 'car'),
    (word: 'BAUM', gap: 0, picture: 'tree'),
    (word: 'APFEL', gap: 0, picture: 'apple'),
    (word: 'BUCH', gap: 0, picture: 'book'),
    (word: 'HAUS', gap: 1, picture: 'house'),
    (word: 'KATZE', gap: 2, picture: 'cat'),
    (word: 'BLUME', gap: 2, picture: 'flower'),
    (word: 'VOGEL', gap: 1, picture: 'bird'),
    (word: 'TISCH', gap: 2, picture: 'table'),
    (word: 'SCHULE', gap: 3, picture: 'school'),
    (word: 'FREUND', gap: 2, picture: 'friend'),
    (word: 'SPIELE', gap: 4, picture: 'games'),
    (word: 'REGEN', gap: 1, picture: 'rain'),
    (word: 'STERN', gap: 2, picture: 'star'),
    (word: 'MILCH', gap: 2, picture: 'milk'),
    (word: 'PFERD', gap: 2, picture: 'horse'),
  ];

  static List<MiniGameLearningTask> _letters(GameLevel level, int seed) {
    final random = Random(seed);
    final words = [...letterBank]..shuffle(random);
    return List.generate(taskCount(level), (index) {
      final entry = words[index];
      final answer = entry.word[entry.gap];
      final options = <String>{answer};
      const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      while (options.length < 4) {
        options.add(alphabet[random.nextInt(26)]);
      }
      final choices = options.toList()..shuffle(random);
      return MiniGameLearningTask(
        id: _id(level, index),
        prompt: 'Welcher Buchstabe fehlt? Setze ihn in die Lücke ein.',
        answer: answer,
        choices: choices,
        input: MiniGameInput.letters,
        subject: LearningSubject.deutsch,
        word: entry.word,
        gapIndex: entry.gap,
        picture: entry.picture,
        speech: entry.word,
        explanation:
            'Das Wort heißt ${entry.word}. In der Lücke steht $answer.',
        hints: [
          'Betrachte das Bild und sprich das Wort. Lies dann die sichtbaren Buchstaben.',
          entry.gap == 0
              ? 'Die Lücke steht am Anfang. Welchen Buchstaben brauchst du zuerst?'
              : 'Die Lücke ist an Stelle ${entry.gap + 1}. Sprich das Wort langsam bis zu dieser Stelle.',
          'Das Wort heißt ${entry.word}. Setze $answer an die markierte Stelle.',
        ],
      );
    });
  }

  static MiniGameLearningTask _lesson(GameLevel level, int index) {
    final task = GameLessonTasks.task(level, index);
    final source = level.id == 30 ? [23, 24, 26, 27, 28][index % 5] : level.id;
    final i = index % 5;
    var subject = level.subject == 'Mathe'
        ? LearningSubject.mathematik
        : level.subject == 'Sachunterricht'
            ? LearningSubject.sachkunde
            : level.subject == 'Deutsch'
                ? LearningSubject.deutsch
                : LearningSubject.logik;
    var visual =
        _arithmeticVisual(task.cue.isNotEmpty ? task.cue : task.prompt);
    var hints = _lessonHints(source, task);
    if (source == 23) {
      visual = VisualPayload(type: VisualType.syllables, data: {
        'word': task.cue,
        'syllables': const [
          ['Son', 'ne'],
          ['Ba', 'na', 'ne'],
          ['E', 'le', 'fant'],
          ['Haus'],
          ['To', 'ma', 'te']
        ][i],
      });
    } else if (source == 18) {
      visual = VisualPayload(type: VisualType.numberCompare, data: {
        'a': [8, 12, 15, 7, 20][i],
        'b': [5, 16, 15, 9, 11][i],
        'operation': 'compare',
      });
    } else if (source == 36 || (source == 40 && i == 0)) {
      final sequence = task.numbers;
      visual = VisualPayload(type: VisualType.sequence, data: {
        'sequence': sequence,
        'step': sequence[1] - sequence[0],
      });
    } else if (source == 40 && i == 3) {
      visual = const VisualPayload(type: VisualType.sequence, data: {
        'sequence': ['Kreis', 'Dreieck', 'Kreis', 'Dreieck', 'Kreis'],
        'period': 2,
      });
      hints = [
        'Schau zuerst nur auf die ersten beiden Formen.',
        'Die Gruppe Kreis – Dreieck beginnt danach wieder von vorn.',
        task.explanation
      ];
    } else if (source == 35) {
      visual = VisualPayload(type: VisualType.none, data: {
        'sceneKind': 'plant_parts',
        'plantPart': ['root', 'stem', 'leaf', 'flower', 'seed'][i],
      });
      subject = LearningSubject.sachkunde;
    } else if ([13, 14].contains(source)) {
      visual = const VisualPayload(type: VisualType.numberLine);
    }
    if ([10, 20, 31].contains(source)) {
      hints = _arithmeticHints(
          task.cue.isNotEmpty ? task.cue : task.prompt, task.explanation);
    }
    return MiniGameLearningTask(
      id: _id(level, index),
      prompt: task.prompt,
      answer: task.answer,
      choices: List.unmodifiable(task.choices),
      explanation: task.explanation,
      hints: hints,
      subject: subject,
      input:
          task.orderWords ? MiniGameInput.orderedWords : MiniGameInput.choice,
      visual: visual,
      picture: source == 23
          ? ['sun', 'banana', 'elephant', 'house', 'tomato'][i]
          : task.picture,
      cue: task.cue,
      speech: task.speech,
      hour: task.hour,
      minute: task.minute,
      numbers: task.numbers,
    );
  }

  static List<String> _lessonHints(int id, GameLessonTask task) => [
        switch (id) {
          13 ||
          14 ||
          36 =>
            'Lies die Zahlen von links nach rechts. Welcher Schritt verbindet sie?',
          18 =>
            'Vergleiche die beiden Mengen. Welche ist größer oder sind beide gleich?',
          21 ||
          22 =>
            'Sprich „${task.speech}“ selbst oder höre dir das Wort noch einmal an.',
          23 =>
            'Sprich „${task.cue}“ in Sprecheinheiten. Klatsche zu jeder Einheit einmal.',
          24 =>
            'Sprich „${task.cue}“ und jedes Antwortwort. Achte auf den gemeinsamen Klang am Ende.',
          26 => 'Betrachte das Bild. Lies dann jedes angebotene Wort genau.',
          27 => 'Sprich das Nomen mit der, die und das. Welcher Artikel passt?',
          28 =>
            'Stelle dir mehrere von „${task.cue}“ vor. Wie heißt das Wort dann?',
          29 => 'Suche einen gemeinsamen Wortstamm zu „${task.cue}“.',
          32 => 'Der kurze Zeiger zeigt die Stunden, der lange die Minuten.',
          33 =>
            'Lies genau, ob nach einem Lebensraum, einem Nest oder nach Eiern gefragt wird.',
          34 =>
            'Welche Wettermerkmale nennt der Satz? Beobachte auch das passende Bild.',
          35 =>
            'Stelle dir eine ganze Pflanze vor: Wurzel, Stängel, Blätter, Blüte und Samen.',
          38 =>
            'Benennt das Wort etwas, sagt es eine Tätigkeit oder beschreibt es eine Eigenschaft?',
          43 => 'Suche ein Wort mit ähnlicher Bedeutung, nicht das Gegenteil.',
          44 =>
            'Etwas Vergangenes ist schon passiert. Sprich den Satz mit „gestern“.',
          47 =>
            'Beginne mit dem im Auftrag genannten Wort. Das Wort mit dem Punkt gehört ans Ende.',
          _ =>
            'Lies den Auftrag genau. Markiere, welche Angaben du für die Antwort brauchst.',
        },
        switch (id) {
          13 || 14 => 'Gehe auf dem Zahlenstrahl jeweils einen Schritt weiter.',
          18 =>
            'Die offene Seite des Vergleichszeichens zeigt zur größeren Menge.',
          21 =>
            'Nur der allererste Laut ist gefragt. Vergleiche ihn mit den angebotenen Buchstaben.',
          22 =>
            'Nur der allerletzte Laut ist gefragt. Sprich das Wort bis ganz zum Ende.',
          23 =>
            'Öffne die Silbenansicht. Tippe jede Sprecheinheit einmal an und zähle mit.',
          24 =>
            'Vergleiche den Klang ab dem letzten betonten Selbstlaut. Der Anfang darf anders sein.',
          26 =>
            'Achte auf den ersten und den letzten Buchstaben. Passt das ganze Wort zum Bild?',
          27 => 'Setze nacheinander „der“, „die“ und „das“ vor „${task.cue}“.',
          28 =>
            'Prüfe Stamm und Endung: Bei manchen Wörtern ändert sich auch ein Selbstlaut.',
          29 =>
            'Der Wortstamm kann im längeren Wort am Anfang stehen. Suche die vertrauten Buchstaben.',
          32 => task.minute == 0
              ? 'Der lange Zeiger steht auf 12: Es ist eine volle Stunde. Lies den kurzen Zeiger.'
              : 'Der lange Zeiger steht auf 6: 30 Minuten sind vergangen. Der kurze steht zwischen zwei Stunden.',
          33 =>
            'Streiche Orte, an denen das beschriebene Tier oder seine Eier normalerweise nicht leben.',
          34 =>
            'Tropfen, Flocken, Licht, Wolken und Donner sind unterschiedliche Hinweise.',
          35 =>
            'Suche den Pflanzenteil, dessen Aufgabe zur Frage passt. Untersuche die beschriftete Szene.',
          36 =>
            'Vergleiche zwei benachbarte Zahlen. Derselbe Abstand gilt für den nächsten Sprung.',
          38 =>
            'Kannst du einen Artikel davor setzen, es tun oder mit „Wie ist es?“ danach fragen?',
          43 =>
            'Setze jedes Wort in denselben kurzen Satz. Bleibt die Bedeutung ähnlich?',
          44 =>
            'Vergleiche das Verb. Die angebotene Zukunft mit „werde“ passt nicht zu gestern.',
          47 =>
            'Frage: Wer tut was? Ordne danach die übrigen Wörter und lies deinen Satz.',
          _ =>
            'Vergleiche jede Antwort mit dem Auftrag. Begründe deine Auswahl mit einem sichtbaren Hinweis.',
        },
        task.explanation,
      ];
}
