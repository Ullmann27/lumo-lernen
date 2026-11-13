import 'guided_lesson_catalog.dart';
import '../learning/lumo_learning_domain.dart';

/// A bounded, local illustration of the current reviewed lesson. It cannot
/// submit an answer, mutate a child profile or grant a reward.
class NativeLearningActivity {
  const NativeLearningActivity._(this.kind, this._payload);

  final String kind;
  final Map<String, Object> _payload;

  /// Only consume the checked renderer payload and verify its arithmetic
  /// against the actual answer. Complex or unknown tasks keep their renderer.
  static NativeLearningActivity? fromTask(TaskInstance task) {
    final data = task.visualPayload.data;
    if (task.subject == LearningSubject.mathematik) {
      final a =
          data['operation'] == 'subtraction' ? data['start'] : data['left'];
      final b =
          data['operation'] == 'subtraction' ? data['takeAway'] : data['right'];
      if (a is! int || b is! int || a < 0 || b < 1) return null;
      if (data['operation'] == 'addition' &&
          a <= 10 &&
          b <= 10 &&
          a + b <= 20 &&
          task.correctAnswer == a + b) {
        return NativeLearningActivity._(
            'addition', {'kind': 'addition', 'a': a, 'b': b});
      }
      if (data['operation'] == 'addition' &&
          a >= 100 &&
          a <= 890 &&
          a % 10 == 0 &&
          b <= 90 &&
          b % 10 == 0 &&
          a % 100 + b >= 100 &&
          task.correctAnswer == a + b) {
        return NativeLearningActivity._(
            'bridge_hundred', {'kind': 'bridge_hundred', 'a': a, 'b': b});
      }
      if (data['operation'] == 'subtraction' &&
          a <= 20 &&
          b <= a &&
          task.correctAnswer == a - b) {
        return NativeLearningActivity._(
            'subtract_ten', {'kind': 'subtract_ten', 'a': a, 'b': b});
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

  static NativeLearningActivity? fromLesson(
      GuidedLesson lesson, GuidedLessonStep step) {
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
        return NativeLearningActivity._(
            'subtract_ten', {'kind': 'subtract_ten', 'a': step.a, 'b': step.b});
      case GuidedLessonConcept.equalGroups:
        if (step.a < 1 || step.a > 6 || step.b < 1 || step.b > 6) return null;
        return NativeLearningActivity._(
            'equal_groups', {'kind': 'equal_groups', 'a': step.a, 'b': step.b});
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
        return NativeLearningActivity._('bridge_hundred',
            {'kind': 'bridge_hundred', 'a': step.a, 'b': step.b});
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
