import '../learning/lumo_learning_domain.dart';

enum LumoGameType {
  foxPath,
  berryCollector,
  letterCatch,
  scienceSort,
  learningSnake,
}

enum GameDifficultyPace {
  calm,
  normal,
  challenge,
}

class LumoLearningGameDefinition {
  const LumoLearningGameDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.subjects,
    required this.supportedTaskTypes,
    required this.targetSkills,
    this.defaultPace = GameDifficultyPace.calm,
    this.maxDurationSeconds = 180,
  });

  final String id;
  final LumoGameType type;
  final String title;
  final String description;
  final List<LearningSubject> subjects;
  final List<TaskType> supportedTaskTypes;
  final List<SkillId> targetSkills;
  final GameDifficultyPace defaultPace;
  final int maxDurationSeconds;
}

class GamePlanItem {
  const GamePlanItem({
    required this.index,
    required this.prompt,
    required this.skillId,
    required this.taskType,
    this.correctTarget,
  });

  final int index;
  final String prompt;
  final SkillId skillId;
  final TaskType taskType;
  final Object? correctTarget;
}

class LumoGameSessionPlan {
  const LumoGameSessionPlan({
    required this.id,
    required this.game,
    required this.childId,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final LumoLearningGameDefinition game;
  final String childId;
  final List<GamePlanItem> items;
  final DateTime createdAt;
}

class LumoLearningGameRegistry {
  const LumoLearningGameRegistry();

  static const games = <LumoLearningGameDefinition>[
    LumoLearningGameDefinition(
      id: 'game.fox_path.v1',
      type: LumoGameType.foxPath,
      title: 'Fuchs-Pfad',
      description: 'Lumo laeuft ueber einen Waldpfad. Richtige Antworten oeffnen Bruecken und Tore.',
      subjects: <LearningSubject>[LearningSubject.mathematik, LearningSubject.deutsch, LearningSubject.sachkunde],
      supportedTaskTypes: <TaskType>[TaskType.multipleChoice, TaskType.numberLine, TaskType.dotGroups],
      targetSkills: <SkillId>[SkillId('math.addition'), SkillId('math.subtraction'), SkillId('de.initial_sound'), SkillId('science.animals')],
    ),
    LumoLearningGameDefinition(
      id: 'game.berry_collector.v1',
      type: LumoGameType.berryCollector,
      title: 'Beeren sammeln',
      description: 'Kind legt, sammelt oder nimmt Beeren weg. Jede Beere ist eine Mengenhandlung.',
      subjects: <LearningSubject>[LearningSubject.mathematik],
      supportedTaskTypes: <TaskType>[TaskType.dotGroups, TaskType.numberLine],
      targetSkills: <SkillId>[SkillId('math.addition'), SkillId('math.subtraction'), SkillId('math.quantity')],
    ),
    LumoLearningGameDefinition(
      id: 'game.letter_catch.v1',
      type: LumoGameType.letterCatch,
      title: 'Buchstaben-Zauber',
      description: 'Buchstaben schweben langsam. Das Kind faengt Laute, Gross/Klein oder schreibt sie nach.',
      subjects: <LearningSubject>[LearningSubject.deutsch],
      supportedTaskTypes: <TaskType>[TaskType.multipleChoice, TaskType.writingCanvas],
      targetSkills: <SkillId>[SkillId('de.initial_sound'), SkillId('de.upper_lower'), SkillId('de.letter_tracing')],
    ),
    LumoLearningGameDefinition(
      id: 'game.science_sort.v1',
      type: LumoGameType.scienceSort,
      title: 'Lumo-Labor',
      description: 'Tiere, Wetter und Natur werden in kindgerechte Lebenswelten sortiert.',
      subjects: <LearningSubject>[LearningSubject.sachkunde],
      supportedTaskTypes: <TaskType>[TaskType.multipleChoice, TaskType.dragDrop],
      targetSkills: <SkillId>[SkillId('science.animals'), SkillId('science.weather'), SkillId('science.plants')],
    ),
    LumoLearningGameDefinition(
      id: 'game.learning_snake.v1',
      type: LumoGameType.learningSnake,
      title: 'Lumo-Schlange',
      description: 'Eine ruhige Snake-Variante: Lumo sammelt nur passende Zahlen, Buchstaben oder Bilder.',
      subjects: <LearningSubject>[LearningSubject.mathematik, LearningSubject.deutsch],
      supportedTaskTypes: <TaskType>[TaskType.multipleChoice, TaskType.numberLine],
      targetSkills: <SkillId>[SkillId('math.number_line'), SkillId('math.addition'), SkillId('de.initial_sound')],
      defaultPace: GameDifficultyPace.normal,
    ),
  ];

  LumoLearningGameDefinition pickFor({
    required LearningSubject subject,
    required List<SkillId> weakSkills,
  }) {
    for (final weak in weakSkills) {
      for (final game in games) {
        if (game.subjects.contains(subject) && game.targetSkills.contains(weak)) {
          return game;
        }
      }
    }
    return games.firstWhere(
      (game) => game.subjects.contains(subject),
      orElse: () => games.first,
    );
  }
}

class LumoGamePlanner {
  const LumoGamePlanner({this.registry = const LumoLearningGameRegistry()});

  final LumoLearningGameRegistry registry;

  LumoGameSessionPlan plan({
    required String childId,
    required LearningSubject subject,
    required List<SkillId> weakSkills,
    int itemCount = 6,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    final game = registry.pickFor(subject: subject, weakSkills: weakSkills);
    final targets = weakSkills.isEmpty ? game.targetSkills : weakSkills;
    final items = <GamePlanItem>[];

    for (var i = 0; i < itemCount; i++) {
      final skill = targets[i % targets.length];
      final taskType = game.supportedTaskTypes[i % game.supportedTaskTypes.length];
      items.add(GamePlanItem(
        index: i + 1,
        prompt: _promptFor(game.type, skill),
        skillId: skill,
        taskType: taskType,
      ));
    }

    return LumoGameSessionPlan(
      id: 'game_${createdAt.microsecondsSinceEpoch}_${game.id}',
      game: game,
      childId: childId,
      items: items,
      createdAt: createdAt,
    );
  }

  String _promptFor(LumoGameType type, SkillId skill) {
    final value = skill.value;
    if (type == LumoGameType.berryCollector) {
      if (value.contains('subtraction')) return 'Nimm die richtige Anzahl Beeren weg.';
      return 'Sammle genau die richtige Anzahl Beeren.';
    }
    if (type == LumoGameType.letterCatch) {
      if (value.contains('letter')) return 'Spure den leuchtenden Buchstaben nach.';
      return 'Fange den Buchstaben mit dem richtigen Anfangslaut.';
    }
    if (type == LumoGameType.scienceSort) return 'Sortiere das Bild in die richtige Lumo-Welt.';
    if (type == LumoGameType.learningSnake) return 'Sammle nur das richtige Feld ein.';
    return 'Oeffne Lumo den naechsten Weg.';
  }
}
