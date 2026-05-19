import 'adaptive_learning_engine.dart';
import 'lumo_learning_domain.dart';
import 'seed_memory_service.dart';
import 'task_instance_generator.dart';
import 'task_template_registry.dart';

class LearningTaskRequest {
  const LearningTaskRequest({
    required this.child,
    required this.skillStates,
    required this.mode,
    this.subject,
    this.now,
  });

  final ChildProfile child;
  final List<SkillState> skillStates;
  final LearningMode mode;
  final LearningSubject? subject;
  final DateTime? now;
}

class LearningTaskPlan {
  const LearningTaskPlan({
    required this.selectedSkill,
    required this.difficulty,
    required this.template,
    required this.seed,
    required this.task,
  });

  final SkillState selectedSkill;
  final DifficultyWindow difficulty;
  final TaskTemplate template;
  final SeedCandidate seed;
  final TaskInstance task;
}

class AdaptiveLearningOrchestrator {
  AdaptiveLearningOrchestrator({
    required SeedMemoryService seedMemory,
    SkillRegistry? skillRegistry,
    TaskTemplateRegistry? templateRegistry,
    AdaptiveTaskSelector selector = const AdaptiveTaskSelector(),
    DifficultyEngine difficultyEngine = const DifficultyEngine(),
    TaskTypeSelector taskTypeSelector = const TaskTypeSelector(),
    TaskInstanceGenerator generator = const TaskInstanceGenerator(),
  })  : _seedMemory = seedMemory,
        _skillRegistry = skillRegistry ?? lumoSkillRegistry,
        _templateRegistry = templateRegistry ?? lumoTaskTemplateRegistry,
        _selector = selector,
        _difficultyEngine = difficultyEngine,
        _taskTypeSelector = taskTypeSelector,
        _generator = generator;

  final SeedMemoryService _seedMemory;
  final SkillRegistry _skillRegistry;
  final TaskTemplateRegistry _templateRegistry;
  final AdaptiveTaskSelector _selector;
  final DifficultyEngine _difficultyEngine;
  final TaskTypeSelector _taskTypeSelector;
  final TaskInstanceGenerator _generator;

  Future<LearningTaskPlan> nextTask(LearningTaskRequest request) async {
    final subject = request.subject ?? request.child.activeSubject;
    final candidateSkills = _candidateSkillStates(
      child: request.child,
      subject: subject,
      knownStates: request.skillStates,
    );

    final selectedSkill = _selector.selectSkill(
      candidates: candidateSkills,
      mode: request.mode,
      now: request.now,
    );

    final difficulty = _difficultyEngine.windowFor(
      skill: selectedSkill,
      mode: request.mode,
    );

    final templates = _templateRegistry.findTemplates(
      subject: subject,
      skillId: selectedSkill.skillId,
      grade: request.child.grade,
      difficulty: DifficultyWindowFilter(min: difficulty.min, max: difficulty.max),
    );

    if (templates.isEmpty) {
      throw StateError(
        'No task templates for subject=$subject skill=${selectedSkill.skillId} grade=${request.child.grade}.',
      );
    }

    final taskType = _taskTypeSelector.select(
      skill: selectedSkill,
      templates: templates,
      mode: request.mode,
    );

    final matchingTemplates = templates
        .where((template) => template.taskType == taskType)
        .toList(growable: false);
    final template = matchingTemplates.isEmpty ? templates.first : matchingTemplates.first;

    final seed = await _seedMemory.nextUnusedSeed(
      childId: request.child.id,
      templateId: template.templateId,
      seedContext: <String, Object?>{
        'childId': request.child.id,
        'grade': request.child.grade,
        'mode': request.mode.name,
        'subject': subject.name,
        'skillId': selectedSkill.skillId.value,
        'difficulty': difficulty.target,
      },
      cooldown: Duration(days: template.cooldownDays),
      now: request.now,
    );

    final task = _generator.generate(
      TaskGenerationRequest(
        child: request.child,
        template: template,
        difficulty: difficulty.target,
        seed: seed,
        mode: request.mode,
        now: request.now,
      ),
    );

    return LearningTaskPlan(
      selectedSkill: selectedSkill,
      difficulty: difficulty,
      template: template,
      seed: seed,
      task: task,
    );
  }

  List<SkillState> _candidateSkillStates({
    required ChildProfile child,
    required LearningSubject subject,
    required List<SkillState> knownStates,
  }) {
    final definitions = _skillRegistry.forSubjectAndGrade(
      subject: subject,
      grade: child.grade,
    );

    final stateBySkill = <SkillId, SkillState>{
      for (final state in knownStates) state.skillId: state,
    };

    return definitions.map((definition) {
      return stateBySkill[definition.id] ??
          SkillState(
            childId: child.id,
            skillId: definition.id,
            currentDifficulty: child.grade <= 1 ? 1 : 2,
            masteryScore: 0.20,
            repetitionNeed: 0.50,
          );
    }).toList(growable: false);
  }
}

class AdaptiveLearningResultHandler {
  const AdaptiveLearningResultHandler({
    this.skillStateUpdater = const SkillStateUpdater(),
    this.errorClassifier = const ErrorClassifier(),
  });

  final SkillStateUpdater skillStateUpdater;
  final ErrorClassifier errorClassifier;

  TaskResult buildResult({
    required TaskInstance task,
    required SkillState before,
    required Object answerGiven,
    required int responseTimeMs,
    bool helpUsed = false,
    double? handwritingScore,
    bool frustrationSignal = false,
  }) {
    final correct = answerGiven == task.correctAnswer || '$answerGiven' == '${task.correctAnswer}';
    final errors = correct
        ? const <ErrorType>[]
        : errorClassifier.classifyMultipleChoice(task: task, answerGiven: answerGiven);

    return TaskResult(
      taskInstanceId: task.taskInstanceId,
      childId: task.childId,
      skillId: task.skillId,
      correct: correct,
      responseTimeMs: responseTimeMs,
      helpUsed: helpUsed,
      detectedErrorTypes: errors,
      handwritingScore: handwritingScore,
      frustrationSignal: frustrationSignal,
    );
  }

  SkillState updateSkillState({
    required SkillState before,
    required TaskResult result,
    DateTime? now,
  }) {
    return skillStateUpdater.applyResult(
      before: before,
      result: result,
      now: now,
    );
  }
}
