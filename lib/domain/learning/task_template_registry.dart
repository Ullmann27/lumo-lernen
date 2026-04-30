import 'lumo_learning_domain.dart';

class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.subject,
    required this.title,
    required this.gradeMin,
    required this.gradeMax,
    this.description,
  });

  final SkillId id;
  final LearningSubject subject;
  final String title;
  final int gradeMin;
  final int gradeMax;
  final String? description;
}

class SkillRegistry {
  const SkillRegistry(this.skills);

  final List<SkillDefinition> skills;

  List<SkillDefinition> forSubjectAndGrade({
    required LearningSubject subject,
    required int grade,
  }) {
    return skills
        .where((skill) =>
            skill.subject == subject &&
            skill.gradeMin <= grade &&
            skill.gradeMax >= grade)
        .toList(growable: false);
  }

  SkillDefinition? find(SkillId id) {
    for (final skill in skills) {
      if (skill.id == id) return skill;
    }
    return null;
  }
}

class TaskTemplateRegistry {
  const TaskTemplateRegistry(this.templates);

  final List<TaskTemplate> templates;

  List<TaskTemplate> findTemplates({
    required LearningSubject subject,
    required SkillId skillId,
    required int grade,
    DifficultyWindowFilter? difficulty,
    TaskType? taskType,
  }) {
    return templates.where((template) {
      if (template.subject != subject) return false;
      if (template.skillId != skillId) return false;
      if (template.minGrade > grade || template.maxGrade < grade) return false;
      if (taskType != null && template.taskType != taskType) return false;
      if (difficulty != null && !difficulty.overlaps(template.difficultyRange)) return false;
      return true;
    }).toList(growable: false);
  }

  TaskTemplate? findById(String templateId) {
    for (final template in templates) {
      if (template.templateId == templateId) return template;
    }
    return null;
  }
}

class DifficultyWindowFilter {
  const DifficultyWindowFilter({required this.min, required this.max});
  final int min;
  final int max;

  bool overlaps(DifficultyRange range) => range.max >= min && range.min <= max;
}

class LumoSkillIds {
  LumoSkillIds._();

  // Mathematik
  static const mathQuantity = SkillId('math.quantity');
  static const mathNumberWriting = SkillId('math.number_writing');
  static const mathAddition = SkillId('math.addition');
  static const mathSubtraction = SkillId('math.subtraction');
  static const mathDecompose = SkillId('math.decompose');
  static const mathDoubleHalf = SkillId('math.double_half');
  static const mathNumberLine = SkillId('math.number_line');
  static const mathPlaceValue = SkillId('math.place_value');
  static const mathWordProblem = SkillId('math.word_problem');
  static const mathShapes = SkillId('math.shapes');
  static const mathClock = SkillId('math.clock');
  static const mathMoney = SkillId('math.money');

  // Deutsch
  static const germanInitialSound = SkillId('de.initial_sound');
  static const germanFinalSound = SkillId('de.final_sound');
  static const germanSyllables = SkillId('de.syllables');
  static const germanRhymes = SkillId('de.rhymes');
  static const germanLetterTracing = SkillId('de.letter_tracing');
  static const germanLetterWriting = SkillId('de.letter_writing');
  static const germanReading = SkillId('de.reading');
  static const germanImageWord = SkillId('de.image_word');
  static const germanUpperLower = SkillId('de.upper_lower');

  // Sachkunde
  static const scienceAnimals = SkillId('science.animals');
  static const sciencePlants = SkillId('science.plants');
  static const scienceSeasons = SkillId('science.seasons');
  static const scienceWeather = SkillId('science.weather');
  static const scienceBody = SkillId('science.body');
  static const scienceTraffic = SkillId('science.traffic');
  static const scienceEnvironment = SkillId('science.environment');
}

final lumoSkillRegistry = SkillRegistry(const <SkillDefinition>[
  SkillDefinition(id: LumoSkillIds.mathQuantity, subject: LearningSubject.mathematik, title: 'Mengen erkennen', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathNumberWriting, subject: LearningSubject.mathematik, title: 'Zahlen schreiben', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathAddition, subject: LearningSubject.mathematik, title: 'Addition', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathSubtraction, subject: LearningSubject.mathematik, title: 'Subtraktion', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathDecompose, subject: LearningSubject.mathematik, title: 'Zahlen zerlegen', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathDoubleHalf, subject: LearningSubject.mathematik, title: 'Verdoppeln und Halbieren', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathNumberLine, subject: LearningSubject.mathematik, title: 'Zahlenstrahl', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathPlaceValue, subject: LearningSubject.mathematik, title: 'Zehner und Einer', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathWordProblem, subject: LearningSubject.mathematik, title: 'Textaufgaben', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathShapes, subject: LearningSubject.mathematik, title: 'Formen', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathClock, subject: LearningSubject.mathematik, title: 'Uhrzeit', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.mathMoney, subject: LearningSubject.mathematik, title: 'Geld', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanInitialSound, subject: LearningSubject.deutsch, title: 'Anfangslaut erkennen', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanFinalSound, subject: LearningSubject.deutsch, title: 'Endlaut erkennen', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanSyllables, subject: LearningSubject.deutsch, title: 'Silben klatschen', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanRhymes, subject: LearningSubject.deutsch, title: 'Reimwoerter', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanLetterTracing, subject: LearningSubject.deutsch, title: 'Buchstaben nachspuren', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanLetterWriting, subject: LearningSubject.deutsch, title: 'Buchstaben frei schreiben', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanReading, subject: LearningSubject.deutsch, title: 'Leseverstaendnis', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanImageWord, subject: LearningSubject.deutsch, title: 'Wort-Bild-Zuordnung', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.germanUpperLower, subject: LearningSubject.deutsch, title: 'Gross und klein', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.scienceAnimals, subject: LearningSubject.sachkunde, title: 'Tiere', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.sciencePlants, subject: LearningSubject.sachkunde, title: 'Pflanzen', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.scienceSeasons, subject: LearningSubject.sachkunde, title: 'Jahreszeiten', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.scienceWeather, subject: LearningSubject.sachkunde, title: 'Wetter', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.scienceBody, subject: LearningSubject.sachkunde, title: 'Koerper', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.scienceTraffic, subject: LearningSubject.sachkunde, title: 'Verkehr', gradeMin: 1, gradeMax: 2),
  SkillDefinition(id: LumoSkillIds.scienceEnvironment, subject: LearningSubject.sachkunde, title: 'Natur und Umwelt', gradeMin: 1, gradeMax: 2),
]);

final lumoTaskTemplateRegistry = TaskTemplateRegistry(const <TaskTemplate>[
  TaskTemplate(
    templateId: 'math.addition.dots.v1',
    subject: LearningSubject.mathematik,
    skillId: LumoSkillIds.mathAddition,
    taskType: TaskType.dotGroups,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 4),
    visualType: VisualType.dots,
    parameterSpec: ParameterSpec(minNumber: 0, maxNumber: 20),
    detectableErrors: <ErrorType>[ErrorType.countingError, ErrorType.plusMinusConfusion],
  ),
  TaskTemplate(
    templateId: 'math.subtraction.takeaway.v1',
    subject: LearningSubject.mathematik,
    skillId: LumoSkillIds.mathSubtraction,
    taskType: TaskType.dotGroups,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 4),
    visualType: VisualType.dots,
    parameterSpec: ParameterSpec(minNumber: 0, maxNumber: 20),
    detectableErrors: <ErrorType>[ErrorType.countingError, ErrorType.plusMinusConfusion],
  ),
  TaskTemplate(
    templateId: 'math.place_value.ten_ones.v1',
    subject: LearningSubject.mathematik,
    skillId: LumoSkillIds.mathPlaceValue,
    taskType: TaskType.tenOnes,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(2, 5),
    visualType: VisualType.tenOnes,
    parameterSpec: ParameterSpec(minNumber: 10, maxNumber: 99),
    detectableErrors: <ErrorType>[ErrorType.placeValueWeak],
  ),
  TaskTemplate(
    templateId: 'math.number_line.neighbor.v1',
    subject: LearningSubject.mathematik,
    skillId: LumoSkillIds.mathNumberLine,
    taskType: TaskType.numberLine,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 5),
    visualType: VisualType.numberLine,
    parameterSpec: ParameterSpec(minNumber: 0, maxNumber: 100),
    detectableErrors: <ErrorType>[ErrorType.countingError],
  ),
  TaskTemplate(
    templateId: 'math.shapes.choice.v1',
    subject: LearningSubject.mathematik,
    skillId: LumoSkillIds.mathShapes,
    taskType: TaskType.multipleChoice,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 3),
    visualType: VisualType.shape,
    parameterSpec: ParameterSpec(allowedWords: <String>['Dreieck', 'Kreis', 'Quadrat', 'Rechteck']),
    detectableErrors: <ErrorType>[ErrorType.conceptConfusion],
  ),
  TaskTemplate(
    templateId: 'de.initial_sound.choice.v1',
    subject: LearningSubject.deutsch,
    skillId: LumoSkillIds.germanInitialSound,
    taskType: TaskType.multipleChoice,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 4),
    visualType: VisualType.none,
    parameterSpec: ParameterSpec(allowedWords: <String>['Mama', 'Mond', 'Sonne', 'Ball', 'Fuchs', 'Haus']),
    detectableErrors: <ErrorType>[ErrorType.soundMisread, ErrorType.letterConfusion],
  ),
  TaskTemplate(
    templateId: 'de.syllables.clap.v1',
    subject: LearningSubject.deutsch,
    skillId: LumoSkillIds.germanSyllables,
    taskType: TaskType.multipleChoice,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 4),
    visualType: VisualType.syllables,
    parameterSpec: ParameterSpec(allowedWords: <String>['Mama', 'Banane', 'Schule', 'Tomate', 'Elefant']),
    detectableErrors: <ErrorType>[ErrorType.syllableCountWrong],
  ),
  TaskTemplate(
    templateId: 'de.letter_tracing.canvas.v1',
    subject: LearningSubject.deutsch,
    skillId: LumoSkillIds.germanLetterTracing,
    taskType: TaskType.writingCanvas,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 5),
    visualType: VisualType.writingPath,
    parameterSpec: ParameterSpec(allowedSymbols: <String>['A', 'M', 'O', 'S', 'L', 'E', 'F', 'B', 'N', 'T']),
    detectableErrors: <ErrorType>[ErrorType.mirroredWriting, ErrorType.wrongStrokeOrder, ErrorType.incompleteShape, ErrorType.wrongDirection],
  ),
  TaskTemplate(
    templateId: 'science.animals.category.v1',
    subject: LearningSubject.sachkunde,
    skillId: LumoSkillIds.scienceAnimals,
    taskType: TaskType.multipleChoice,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 4),
    visualType: VisualType.none,
    parameterSpec: ParameterSpec(allowedWords: <String>['Huhn', 'Fisch', 'Hund', 'Katze', 'Fuchs']),
    detectableErrors: <ErrorType>[ErrorType.categoryConfusion, ErrorType.conceptConfusion],
  ),
  TaskTemplate(
    templateId: 'science.weather.choice.v1',
    subject: LearningSubject.sachkunde,
    skillId: LumoSkillIds.scienceWeather,
    taskType: TaskType.multipleChoice,
    minGrade: 1,
    maxGrade: 2,
    difficultyRange: DifficultyRange(1, 4),
    visualType: VisualType.none,
    parameterSpec: ParameterSpec(allowedWords: <String>['Regen', 'Schnee', 'Sonne', 'Wind', 'Wolke']),
    detectableErrors: <ErrorType>[ErrorType.conceptConfusion, ErrorType.everydayKnowledgeWeak],
  ),
]);
