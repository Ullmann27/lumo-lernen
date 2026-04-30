import 'dart:math' as math;

import 'lumo_learning_domain.dart';
import 'seed_memory_service.dart';
import 'task_template_registry.dart';

class TaskGenerationRequest {
  const TaskGenerationRequest({
    required this.child,
    required this.template,
    required this.difficulty,
    required this.seed,
    this.mode = LearningMode.practice,
    this.now,
  });

  final ChildProfile child;
  final TaskTemplate template;
  final int difficulty;
  final SeedCandidate seed;
  final LearningMode mode;
  final DateTime? now;
}

class TaskInstanceGenerator {
  const TaskInstanceGenerator();

  TaskInstance generate(TaskGenerationRequest request) {
    final templateId = request.template.templateId;
    final random = math.Random(_seedToInt(request.seed.seedHash));

    return switch (templateId) {
      'math.addition.dots.v1' => _mathAdditionDots(request, random),
      'math.subtraction.takeaway.v1' => _mathSubtractionTakeaway(request, random),
      'math.place_value.ten_ones.v1' => _mathPlaceValue(request, random),
      'math.number_line.neighbor.v1' => _mathNumberLineNeighbor(request, random),
      'math.shapes.choice.v1' => _mathShapeChoice(request, random),
      'de.initial_sound.choice.v1' => _initialSoundChoice(request, random),
      'de.syllables.clap.v1' => _syllableChoice(request, random),
      'de.letter_tracing.canvas.v1' => _letterTracing(request, random),
      'science.animals.category.v1' => _scienceAnimalChoice(request, random),
      'science.weather.choice.v1' => _scienceWeatherChoice(request, random),
      _ => _fallbackMultipleChoice(request, random),
    };
  }

  TaskInstance _mathAdditionDots(TaskGenerationRequest request, math.Random random) {
    final max = _maxForDifficulty(request.difficulty, grade: request.child.grade);
    final left = 1 + random.nextInt(math.max(1, max ~/ 2));
    final right = random.nextInt(math.max(1, max - left + 1));
    final answer = left + right;

    return _instance(
      request,
      prompt: '$left + $right = ?',
      parameters: <String, Object?>{'left': left, 'right': right, 'max': max},
      correctAnswer: answer,
      options: _numberOptions(answer, random, min: 0, max: max),
      visualPayload: VisualPayload(type: VisualType.dots, data: <String, Object?>{
        'operation': 'addition',
        'left': left,
        'right': right,
      }),
      helpPayload: const HelpPayload(
        level: 1,
        shortHint: 'Lege beide Mengen zusammen und zaehle alle Punkte.',
        guidedSteps: <String>['Zaehle zuerst die linke Menge.', 'Zaehle dann die rechte Menge dazu.'],
      ),
    );
  }

  TaskInstance _mathSubtractionTakeaway(TaskGenerationRequest request, math.Random random) {
    final max = _maxForDifficulty(request.difficulty, grade: request.child.grade);
    final start = 2 + random.nextInt(math.max(1, max - 1));
    final takeAway = 1 + random.nextInt(start);
    final answer = start - takeAway;

    return _instance(
      request,
      prompt: '$start - $takeAway = ?',
      parameters: <String, Object?>{'start': start, 'takeAway': takeAway, 'max': max},
      correctAnswer: answer,
      options: _numberOptions(answer, random, min: 0, max: max),
      visualPayload: VisualPayload(type: VisualType.dots, data: <String, Object?>{
        'operation': 'subtraction',
        'start': start,
        'takeAway': takeAway,
      }),
      helpPayload: const HelpPayload(
        level: 1,
        shortHint: 'Starte mit der ganzen Menge. Streiche weg, was abgezogen wird.',
        guidedSteps: <String>['Zaehle alle Punkte.', 'Nimm die weg, die abgezogen werden.', 'Zaehle, was bleibt.'],
      ),
    );
  }

  TaskInstance _mathPlaceValue(TaskGenerationRequest request, math.Random random) {
    final max = request.child.grade == 1 ? 60 : 99;
    final number = 10 + random.nextInt(max - 9);
    final tens = number ~/ 10;
    final ones = number % 10;
    final askTens = random.nextBool();
    final answer = askTens ? tens : ones;

    return _instance(
      request,
      prompt: askTens ? 'Wie viele Zehner hat $number?' : 'Wie viele Einer hat $number?',
      parameters: <String, Object?>{'number': number, 'tens': tens, 'ones': ones, 'ask': askTens ? 'tens' : 'ones'},
      correctAnswer: answer,
      options: _numberOptions(answer, random, min: 0, max: 9),
      visualPayload: VisualPayload(type: VisualType.tenOnes, data: <String, Object?>{
        'number': number,
        'tens': tens,
        'ones': ones,
      }),
      helpPayload: const HelpPayload(
        level: 1,
        shortHint: 'Zehner sind Stangen. Einer sind einzelne Punkte.',
      ),
    );
  }

  TaskInstance _mathNumberLineNeighbor(TaskGenerationRequest request, math.Random random) {
    final max = request.child.grade == 1 ? 20 : 100;
    final number = 2 + random.nextInt(max - 2);
    final before = random.nextBool();
    final answer = before ? number - 1 : number + 1;

    return _instance(
      request,
      prompt: before ? 'Welche Zahl kommt direkt vor $number?' : 'Welche Zahl kommt direkt nach $number?',
      parameters: <String, Object?>{'number': number, 'direction': before ? 'before' : 'after'},
      correctAnswer: answer,
      options: _numberOptions(answer, random, min: 0, max: max),
      visualPayload: VisualPayload(type: VisualType.numberLine, data: <String, Object?>{
        'center': number,
        'answer': answer,
        'min': math.max(0, number - 3),
        'max': math.min(max, number + 3),
      }),
      helpPayload: HelpPayload(
        level: 1,
        shortHint: before ? 'Gehe einen Schritt zurueck.' : 'Gehe einen Schritt weiter.',
      ),
    );
  }

  TaskInstance _mathShapeChoice(TaskGenerationRequest request, math.Random random) {
    const shapeQuestions = <String, String>{
      'Welche Form hat 3 Ecken?': 'Dreieck',
      'Welche Form ist ganz rund?': 'Kreis',
      'Welche Form hat 4 gleich lange Seiten?': 'Quadrat',
      'Welche Form hat 4 Ecken und zwei lange Seiten?': 'Rechteck',
    };
    final entry = shapeQuestions.entries.elementAt(random.nextInt(shapeQuestions.length));
    const allShapes = <String>['Dreieck', 'Kreis', 'Quadrat', 'Rechteck'];

    return _instance(
      request,
      prompt: entry.key,
      parameters: <String, Object?>{'targetShape': entry.value},
      correctAnswer: entry.value,
      options: _textOptions(entry.value, allShapes, random),
      visualPayload: const VisualPayload(type: VisualType.shape),
      helpPayload: const HelpPayload(level: 1, shortHint: 'Schau auf Ecken, Rundungen und Seiten.'),
    );
  }

  TaskInstance _initialSoundChoice(TaskGenerationRequest request, math.Random random) {
    const words = <String>['Mama', 'Mond', 'Sonne', 'Ball', 'Fuchs', 'Haus', 'Apfel', 'Igel', 'Lampe'];
    final word = words[random.nextInt(words.length)];
    final answer = word.substring(0, 1).toUpperCase();
    final letters = words.map((word) => word.substring(0, 1).toUpperCase()).toSet().toList();

    return _instance(
      request,
      prompt: 'Mit welchem Laut beginnt $word?',
      parameters: <String, Object?>{'word': word, 'targetLetter': answer},
      correctAnswer: answer,
      options: _textOptions(answer, letters, random),
      visualPayload: const VisualPayload(type: VisualType.none),
      helpPayload: HelpPayload(level: 1, shortHint: 'Sprich $word langsam. Was hoerst du zuerst?'),
    );
  }

  TaskInstance _syllableChoice(TaskGenerationRequest request, math.Random random) {
    const syllables = <String, int>{
      'Mama': 2,
      'Banane': 3,
      'Schule': 2,
      'Tomate': 3,
      'Elefant': 3,
      'Fuchs': 1,
      'Rakete': 3,
    };
    final entry = syllables.entries.elementAt(random.nextInt(syllables.length));

    return _instance(
      request,
      prompt: 'Wie viele Silben hat ${entry.key}?',
      parameters: <String, Object?>{'word': entry.key, 'syllables': entry.value},
      correctAnswer: entry.value,
      options: _numberOptions(entry.value, random, min: 1, max: 4),
      visualPayload: VisualPayload(type: VisualType.syllables, data: <String, Object?>{'word': entry.key}),
      helpPayload: const HelpPayload(level: 1, shortHint: 'Klatsche das Wort langsam mit.'),
    );
  }

  TaskInstance _letterTracing(TaskGenerationRequest request, math.Random random) {
    const letters = <String>['A', 'M', 'O', 'S', 'L', 'E', 'F', 'B', 'N', 'T'];
    final letter = letters[random.nextInt(letters.length)];

    return _instance(
      request,
      prompt: 'Spure den Buchstaben $letter nach.',
      parameters: <String, Object?>{'symbol': letter, 'mode': 'trace'},
      correctAnswer: 'completed',
      options: const <AnswerOption>[],
      visualPayload: VisualPayload(type: VisualType.writingPath, data: <String, Object?>{'symbol': letter}),
      helpPayload: HelpPayload(
        level: request.mode == LearningMode.tutoring ? 2 : 1,
        shortHint: 'Starte am Punkt und folge der Spur.',
      ),
    );
  }

  TaskInstance _scienceAnimalChoice(TaskGenerationRequest request, math.Random random) {
    const questions = <String, String>{
      'Welches Tier legt Eier?': 'Huhn',
      'Welches Tier lebt im Wasser?': 'Fisch',
      'Welches Tier bellt?': 'Hund',
      'Welches Tier ist ein Fuchs?': 'Fuchs',
    };
    final entry = questions.entries.elementAt(random.nextInt(questions.length));
    const pool = <String>['Huhn', 'Fisch', 'Hund', 'Katze', 'Fuchs'];

    return _instance(
      request,
      prompt: entry.key,
      parameters: <String, Object?>{'concept': entry.value},
      correctAnswer: entry.value,
      options: _textOptions(entry.value, pool, random),
      visualPayload: const VisualPayload(type: VisualType.none),
      helpPayload: const HelpPayload(level: 1, shortHint: 'Denke an das Tier und wo es lebt oder was es macht.'),
    );
  }

  TaskInstance _scienceWeatherChoice(TaskGenerationRequest request, math.Random random) {
    const questions = <String, String>{
      'Was faellt aus Wolken?': 'Regen',
      'Was scheint hell am Himmel?': 'Sonne',
      'Was kann im Winter vom Himmel fallen?': 'Schnee',
      'Was bewegt die Blaetter?': 'Wind',
    };
    final entry = questions.entries.elementAt(random.nextInt(questions.length));
    const pool = <String>['Regen', 'Schnee', 'Sonne', 'Wind', 'Wolke'];

    return _instance(
      request,
      prompt: entry.key,
      parameters: <String, Object?>{'concept': entry.value},
      correctAnswer: entry.value,
      options: _textOptions(entry.value, pool, random),
      visualPayload: const VisualPayload(type: VisualType.none),
      helpPayload: const HelpPayload(level: 1, shortHint: 'Denke an Wetter draussen.'),
    );
  }

  TaskInstance _fallbackMultipleChoice(TaskGenerationRequest request, math.Random random) {
    return _instance(
      request,
      prompt: 'Welche Antwort passt?',
      parameters: const <String, Object?>{'fallback': true},
      correctAnswer: 'Richtig',
      options: _textOptions('Richtig', const <String>['Richtig', 'Falsch', 'Vielleicht'], random),
      visualPayload: VisualPayload(type: request.template.visualType),
      helpPayload: const HelpPayload(level: 1, shortHint: 'Lies die Aufgabe langsam.'),
    );
  }

  TaskInstance _instance(
    TaskGenerationRequest request, {
    required String prompt,
    required Map<String, Object?> parameters,
    required Object correctAnswer,
    required List<AnswerOption> options,
    required VisualPayload visualPayload,
    required HelpPayload helpPayload,
  }) {
    final generatedAt = request.now ?? DateTime.now();
    return TaskInstance(
      taskInstanceId: _taskInstanceId(
        childId: request.child.id,
        templateId: request.template.templateId,
        seedHash: request.seed.seedHash,
        generatedAt: generatedAt,
      ),
      templateId: request.template.templateId,
      childId: request.child.id,
      seedHash: request.seed.seedHash,
      subject: request.template.subject,
      skillId: request.template.skillId,
      taskType: request.template.taskType,
      difficulty: request.difficulty,
      parameters: parameters,
      prompt: prompt,
      options: options,
      correctAnswer: correctAnswer,
      visualPayload: visualPayload,
      helpPayload: helpPayload,
      generatedAt: generatedAt,
    );
  }

  List<AnswerOption> _numberOptions(int answer, math.Random random, {required int min, required int max}) {
    final values = <int>{answer};
    final distractors = <int>[
      answer - 1,
      answer + 1,
      answer - 2,
      answer + 2,
      answer + 10,
      answer - 10,
    ].where((value) => value >= min && value <= max).toList();
    distractors.shuffle(random);
    for (final value in distractors) {
      values.add(value);
      if (values.length >= 3) break;
    }
    while (values.length < 3) {
      values.add(min + random.nextInt(math.max(1, max - min + 1)));
    }
    final list = values.toList()..shuffle(random);
    return list.map((value) => AnswerOption(id: '$value', label: '$value', payload: value)).toList();
  }

  List<AnswerOption> _textOptions(String answer, List<String> pool, math.Random random) {
    final values = <String>{answer};
    final shuffled = pool.where((value) => value != answer).toList()..shuffle(random);
    for (final value in shuffled) {
      values.add(value);
      if (values.length >= 3) break;
    }
    final list = values.toList()..shuffle(random);
    return list.map((value) => AnswerOption(id: value, label: value, payload: value)).toList();
  }

  int _maxForDifficulty(int difficulty, {required int grade}) {
    if (grade <= 1) {
      return switch (difficulty) {
        <= 1 => 10,
        2 => 12,
        3 => 20,
        _ => 20,
      };
    }
    return switch (difficulty) {
      <= 1 => 20,
      2 => 30,
      3 => 50,
      _ => 100,
    };
  }

  int _seedToInt(String seedHash) {
    final trimmed = seedHash.length > 8 ? seedHash.substring(seedHash.length - 8) : seedHash;
    return int.tryParse(trimmed, radix: 16) ?? seedHash.hashCode;
  }

  String _taskInstanceId({
    required String childId,
    required String templateId,
    required String seedHash,
    required DateTime generatedAt,
  }) {
    final raw = '$childId|$templateId|$seedHash|${generatedAt.microsecondsSinceEpoch}';
    return 'task_${SeedMemoryService.stableSeedHash(raw)}';
  }
}
