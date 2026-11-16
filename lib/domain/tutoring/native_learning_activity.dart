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

  /// Only a verified task-specific visual may enter native 3D.
  /// Text-only tasks retain their actual Flutter renderer and tutor.
  static NativeLearningActivity? forTask(TaskInstance task) => fromTask(task);

  /// A companion text context does not validate 3D objects or concepts.
  static NativeLearningActivity? fromCompanionContext(
    LumoCompanionTaskContext context,
  ) {
    return null;
  }

  /// Only consume the checked renderer payload and verify its arithmetic
  /// against the actual answer. Complex or unknown tasks keep their renderer.
  static NativeLearningActivity? fromTask(TaskInstance task) {
    if (task.subject == LearningSubject.englisch) {
      final payload = NativeEnglishVocabulary.illustrationFor(task);
      return payload == null
          ? null
          : NativeLearningActivity._('english_objects', payload);
    }
    if (task.subject == LearningSubject.mathematik &&
        task.visualPayload.type == VisualType.clock) {
      final dial = task.visualPayload.data;
      final hour = dial['hour'];
      final minute = dial['minute'];
      final answer = RegExp(r'^\s*(\d{1,2}):(\d{2})(?:\s*Uhr)?\s*$')
          .firstMatch(task.correctAnswer.toString());
      final labels = task.options
          .map((option) => option.label.trim())
          .toList(growable: false);
      if (hour is int &&
          hour >= 1 && hour <= 12 &&
          minute is int && minute >= 0 && minute < 60 &&
          answer != null &&
          int.tryParse(answer.group(1)!) == hour &&
          int.tryParse(answer.group(2)!) == minute &&
          labels.length >= 2 && labels.length <= 6 &&
          labels.every((label) => label.isNotEmpty && label.length <= 120) &&
          labels.toSet().length == labels.length &&
          labels.contains(task.correctAnswer.toString().trim())) {
        return NativeLearningActivity._('clock', {
          'kind': 'clock',
          'hour': hour,
          'minute': minute,
          'subject': 'Mathematik',
          'unit': 'Uhrzeit',
          'prompt': task.prompt.length <= 800
              ? task.prompt
              : task.prompt.substring(0, 800),
          'explanation': (task.helpPayload.shortHint ?? '').length <= 1200
              ? (task.helpPayload.shortHint ?? '')
              : (task.helpPayload.shortHint ?? '').substring(0, 1200),
          'answerChoices': labels,
        });
      }
      return null;
    }
    final data = task.subject == LearningSubject.mathematik
        ? _arithmeticPayload(task.prompt, task.visualPayload.data)
        : task.visualPayload.data;
    if (task.subject == LearningSubject.logik && data['period'] is int) {
      return fromPattern(
        sequence: data['sequence'],
        choices: task.options.map((option) => option.payload).toList(),
        period: data['period'],
        expected: task.correctAnswer,
      );
    }
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
      final a = data['operation'] == 'subtraction'
          ? data['start'] ?? data['left']
          : data['left'];
      final b = data['operation'] == 'subtraction'
          ? data['takeAway'] ?? data['right']
          : data['right'];
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

  /// Preserve supported legacy arithmetic wording without inferring an
  /// operation from two unrelated numbers in a word problem. The caller still
  /// verifies these operands against the authoritative answer and scene range.
  static Map<String, Object?> _arithmeticPayload(
      String prompt, Map<String, Object?> data) {
    if (data['operation'] != null) return data;
    final match = RegExp(
      r'^\s*(?:Wie viel ist\s+|Schriftlich:\s*)?(\d+)\s*([+−\-×·*:÷])\s*(\d+)\s*(?:=\s*)?\?\s*$',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (match == null) return data;
    final left = int.tryParse(match[1]!);
    final right = int.tryParse(match[3]!);
    if (left == null || right == null) return data;
    final operation = switch (match[2]) {
      '+' => 'addition',
      '-' || '−' => 'subtraction',
      '×' || '·' || '*' => 'multiplication',
      ':' || '÷' => 'division',
      _ => null,
    };
    return {
      ...data,
      'operation': operation,
      'left': left,
      'right': right,
    };
  }

  /// The same repeated group that the existing task evaluator has checked.
  /// No answer or reward is serialized: the native activity is an illustration.
  static NativeLearningActivity? fromPattern({
    required Object? sequence,
    required Object? choices,
    required Object? period,
    required Object? expected,
  }) {
    final values = _patternTokens(sequence, minimum: 4, maximum: 12);
    final options = _patternTokens(choices, minimum: 2, maximum: 6);
    if (values == null ||
        options == null ||
        period is! int ||
        period < 1 ||
        period > 4 ||
        values.length < period * 2 ||
        options.toSet().length != options.length ||
        expected is! String) {
      return null;
    }
    var smallestPeriod = 0;
    for (var candidate = 1; candidate <= 4; candidate++) {
      if (values.length < candidate * 2) break;
      var repeats = true;
      for (var index = candidate; index < values.length; index++) {
        if (values[index] != values[index % candidate]) {
          repeats = false;
          break;
        }
      }
      if (repeats) {
        smallestPeriod = candidate;
        break;
      }
    }
    if (smallestPeriod != period) return null;
    final next = values[values.length % period];
    if (expected != next || !options.contains(next)) return null;
    return NativeLearningActivity._('pattern', {
      'kind': 'pattern',
      'sequence': List<String>.unmodifiable(values),
      'choices': List<String>.unmodifiable(options),
      'period': period,
    });
  }

  static List<String>? _patternTokens(Object? raw,
      {required int minimum, required int maximum}) {
    if (raw is! List || raw.length < minimum || raw.length > maximum) {
      return null;
    }
    final tokens = <String>[];
    for (final token in raw) {
      if (token is! String ||
          token.isEmpty ||
          token.trim() != token ||
          token.runes.length > 24 ||
          token.runes.any((value) =>
              value < 32 ||
              (value >= 127 && value <= 159) ||
              value == 0x2028 ||
              value == 0x2029)) {
        return null;
      }
      tokens.add(token);
    }
    return tokens;
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
