import 'guided_lesson_catalog.dart';
import 'native_english_vocabulary.dart';
import '../learning/lumo_learning_domain.dart';
import '../../widgets/fox/lumo_companion_requests.dart';

/// A bounded, local illustration of the current reviewed lesson. It cannot
/// submit an answer, mutate a child profile or grant a reward.
class NativeLearningActivity {
  const NativeLearningActivity._(this.kind, this._payload);

  final String kind;
  final Map<String, Object> _payload;

  /// Every reviewed task can use the existing native companion. Specialised
  /// object scenes take precedence; other tasks retain their exact prompt and
  /// choices. This descriptor deliberately has no answer or reward field.
  static NativeLearningActivity forTask(TaskInstance task) =>
      fromTask(task) ??
      _taskCard(
        taskId: task.taskInstanceId,
        subject: task.subject.name,
        unit: task.parameters['unit']?.toString() ?? '',
        prompt: task.prompt,
        explanation: task.helpPayload.shortHint ?? '',
        choices: task.options.map((option) => option.label).toList(),
      );

  /// Adapts specialist, reading and guided screens without changing their
  /// authoritative evaluators, storage keys or protected writing internals.
  static NativeLearningActivity? fromCompanionContext(
    LumoCompanionTaskContext context,
  ) {
    if (context.isExam ||
        context.taskId.isEmpty ||
        context.prompt.trim().isEmpty) {
      return null;
    }
    return _taskCard(
      taskId: context.taskId,
      subject: context.subject,
      unit: context.unit,
      prompt: context.prompt,
      explanation: context.explanation ?? context.localHelp ?? '',
      choices: context.answerChoices,
      stepId: context.stepId,
    );
  }

  static NativeLearningActivity _taskCard({
    required String taskId,
    required String subject,
    required String unit,
    required String prompt,
    required String explanation,
    required List<String> choices,
    String? stepId,
  }) {
    String bounded(String value, int length) =>
        value.length <= length ? value : value.substring(0, length);
    final visibleChoices = choices
        .where((choice) => choice.trim().isNotEmpty)
        .take(8)
        .map((choice) => bounded(choice, 120))
        .toList(growable: false);
    return NativeLearningActivity._('task_card', {
      'kind': 'task_card',
      'sourceTaskId': bounded(taskId, 180),
      'subject': bounded(subject, 80),
      'unit': bounded(unit, 80),
      'prompt': bounded(prompt, 800),
      'explanation': bounded(explanation, 1200),
      'answerChoices': visibleChoices,
      'objectIds': [
        'task_prompt',
        'task_model',
        for (var i = 0; i < visibleChoices.length; i++) 'answer_$i',
      ],
      if (stepId != null) 'stepId': bounded(stepId, 120),
    });
  }

  /// Only consume the checked renderer payload and verify its arithmetic
  /// against the actual answer. Complex or unknown tasks keep their renderer.
  static NativeLearningActivity? fromTask(TaskInstance task) {
    if (task.subject == LearningSubject.logik) {
      final data = task.visualPayload.data;
      final unit = data['patternUnit'];
      final sequence = data['patternSequence'];
      final choices = data['patternChoices'];
      const shapes = {
        'circle',
        'triangle',
        'star',
        'square',
        'heart',
        'diamond'
      };
      const answerShapes = {
        'Kreis': 'circle',
        'Dreieck': 'triangle',
        'Stern': 'star',
        'Quadrat': 'square',
        'Herz': 'heart',
        'Raute': 'diamond',
      };
      if (unit is List<String> &&
          sequence is List<String> &&
          choices is List<String> &&
          unit.length >= 2 &&
          unit.length <= 4 &&
          sequence.length >= unit.length * 2 &&
          sequence.length <= 12 &&
          sequence.length % unit.length == 0 &&
          choices.length >= 2 &&
          choices.length <= 6 &&
          choices.toSet().length == choices.length &&
          [...unit, ...sequence, ...choices].every(shapes.contains) &&
          List.generate(sequence.length, (i) => unit[i % unit.length])
              .asMap()
              .entries
              .every((entry) => sequence[entry.key] == entry.value) &&
          choices.contains(unit.first) &&
          (answerShapes[task.correctAnswer.toString()] ?? task.correctAnswer) ==
              unit.first &&
          data['verifiedAnswer'] == unit.first) {
        return NativeLearningActivity._('pattern', {
          'kind': 'pattern',
          'patternUnit': List<String>.of(unit),
          'patternSequence': List<String>.of(sequence),
          'patternChoices': List<String>.of(choices),
        });
      }
    }
    if (task.subject == LearningSubject.englisch) {
      final payload = NativeEnglishVocabulary.illustrationFor(task);
      return payload == null
          ? null
          : NativeLearningActivity._('english_objects', payload);
    }
    final data = task.visualPayload.data;
    if (task.subject == LearningSubject.mathematik) {
      if (data['operation'] == 'fraction_addition') {
        final numerator = data['numerator'];
        final denominator = data['denominator'];
        final extra = data['extra'];
        if (numerator is! int ||
            denominator is! int ||
            extra is! int ||
            numerator < 1 ||
            denominator < 2 ||
            denominator > 12 ||
            extra < 1 ||
            numerator + extra > denominator ||
            !_matchesFraction(
              task.correctAnswer,
              numerator + extra,
              denominator,
            )) {
          return null;
        }
        return NativeLearningActivity._('fraction_parts', {
          'kind': 'fraction_parts',
          'a': numerator,
          'b': denominator,
          'extra': extra,
        });
      }
      final a =
          data['operation'] == 'subtraction' ? data['start'] : data['left'];
      final b =
          data['operation'] == 'subtraction' ? data['takeAway'] : data['right'];
      if (a is! int || b is! int || a < 0 || b < 1) return null;
      if (data['operation'] == 'multiplication' &&
          a >= 1 &&
          a <= 6 &&
          b <= 6 &&
          task.correctAnswer == a * b) {
        return NativeLearningActivity._('equal_groups', {
          'kind': 'equal_groups',
          'a': a,
          'b': b,
        });
      }
      if (data['operation'] == 'division' &&
          b >= 2 &&
          b <= 6 &&
          a >= b &&
          a <= 36 &&
          a % b == 0 &&
          a ~/ b <= 6 &&
          task.correctAnswer == a ~/ b) {
        return NativeLearningActivity._('equal_sharing', {
          'kind': 'equal_sharing',
          'a': a,
          'b': b,
        });
      }
      if (data['operation'] == 'addition' &&
          a <= 10 &&
          b <= 10 &&
          a + b <= 20 &&
          task.correctAnswer == a + b) {
        return NativeLearningActivity._('addition', {
          'kind': 'addition',
          'a': a,
          'b': b,
        });
      }
      if (data['operation'] == 'addition' &&
          a >= 100 &&
          a <= 890 &&
          a % 10 == 0 &&
          b <= 90 &&
          b % 10 == 0 &&
          a % 100 + b >= 100 &&
          task.correctAnswer == a + b) {
        return NativeLearningActivity._('bridge_hundred', {
          'kind': 'bridge_hundred',
          'a': a,
          'b': b,
        });
      }
      if (data['operation'] == 'subtraction' &&
          a <= 20 &&
          b <= a &&
          task.correctAnswer == a - b) {
        return NativeLearningActivity._('subtract_ten', {
          'kind': 'subtract_ten',
          'a': a,
          'b': b,
        });
      }
    }
    if (task.subject == LearningSubject.deutsch) {
      final word = data['word'];
      final syllables = data['syllables'];
      if (word is String &&
          word.isNotEmpty &&
          word.length <= 24 &&
          syllables is List<String> &&
          syllables.length >= 2 &&
          syllables.length <= 5 &&
          syllables.join() == word &&
          task.correctAnswer == syllables.length) {
        return NativeLearningActivity._('syllables', {
          'kind': 'syllables',
          'word': word,
          'syllables': List<String>.unmodifiable(syllables),
        });
      }
    }
    return null;
  }

  static bool _matchesFraction(Object? answer, int numerator, int denominator) {
    if (answer is! String) return false;
    final match = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(answer.trim());
    if (match == null) return false;
    final actualNumerator = int.tryParse(match[1]!);
    final actualDenominator = int.tryParse(match[2]!);
    return actualNumerator != null &&
        actualDenominator != null &&
        actualDenominator > 0 &&
        actualNumerator * denominator == numerator * actualDenominator;
  }

  static NativeLearningActivity? fromLesson(
    GuidedLesson lesson,
    GuidedLessonStep step,
  ) {
    switch (lesson.concept) {
      case GuidedLessonConcept.bridgeTen:
        if (step.a < 1 ||
            step.a > 9 ||
            step.b < 1 ||
            step.b > 9 ||
            step.a + step.b <= 10) {
          return null;
        }
        return NativeLearningActivity._('bridge_ten', {
          'kind': 'bridge_ten',
          'a': step.a,
          'b': step.b,
        });
      case GuidedLessonConcept.syllables:
        if (step.word.isEmpty ||
            step.syllables.length < 2 ||
            step.syllables.length > 5 ||
            step.syllables.join() != step.word ||
            step.word.length > 24) {
          return null;
        }
        return NativeLearningActivity._('syllables', {
          'kind': 'syllables',
          'word': step.word,
          'syllables': List<String>.unmodifiable(step.syllables),
        });
      case GuidedLessonConcept.plantParts:
        return NativeLearningActivity._('plant_parts', {
          'kind': 'plant_parts',
          'plantPart': (step.plantPart ?? GuidedPlantPart.root).name,
        });
      case GuidedLessonConcept.subtractTen:
        if (step.a < 1 || step.a > 20 || step.b < 1 || step.b > step.a) {
          return null;
        }
        return NativeLearningActivity._('subtract_ten', {
          'kind': 'subtract_ten',
          'a': step.a,
          'b': step.b,
        });
      case GuidedLessonConcept.equalGroups:
        if (step.a < 1 || step.a > 6 || step.b < 1 || step.b > 6) return null;
        return NativeLearningActivity._('equal_groups', {
          'kind': 'equal_groups',
          'a': step.a,
          'b': step.b,
        });
      case GuidedLessonConcept.bridgeHundred:
        if (step.a < 100 ||
            step.a > 890 ||
            step.a % 10 != 0 ||
            step.b < 10 ||
            step.b > 90 ||
            step.b % 10 != 0 ||
            step.a % 100 + step.b < 100) {
          return null;
        }
        return NativeLearningActivity._('bridge_hundred', {
          'kind': 'bridge_hundred',
          'a': step.a,
          'b': step.b,
        });
      case GuidedLessonConcept.fractionParts:
        if (step.b < 2 ||
            step.b > 12 ||
            step.a < 1 ||
            step.fractionExtra < 0 ||
            step.a + step.fractionExtra > step.b) {
          return null;
        }
        return NativeLearningActivity._('fraction_parts', {
          'kind': 'fraction_parts',
          'a': step.a,
          'b': step.b,
          'extra': step.fractionExtra,
        });
    }
  }

  Map<String, Object> toLaunchOptions() => Map<String, Object>.of(_payload);
}
