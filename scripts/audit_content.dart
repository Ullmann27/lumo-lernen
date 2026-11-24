import 'dart:io';

import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';

void main() {
  var checked = 0;
  final errors = <String>[];
  final threeStepShapesSeen = <String>{};
  for (final template in MathTaskTemplates.templates) {
    for (var seed = 0; seed < 300; seed++) {
      final t = template.concretize(seed);
      checked++;
      if (t.choices.isNotEmpty &&
          (!t.choices.contains(t.answer) ||
              t.choices.toSet().length != t.choices.length ||
              t.choices.length < 2)) {
        errors.add('${template.id}: choices ${t.choices}, answer ${t.answer}');
      }
      final range = RegExp(r'bis (\d+)').firstMatch(t.unit);
      if (range != null &&
          (template.kind == MathTemplateKind.addition ||
              template.kind == MathTemplateKind.subtraction)) {
        final limit = int.parse(range.group(1)!);
        final nums = RegExp(r'\b\d+\b')
            .allMatches(t.prompt)
            .map((m) => int.parse(m.group(0)!));
        if (nums.any((n) => n > limit) ||
            (int.tryParse(t.answer) ?? 0) > limit ||
            (int.tryParse(t.answer) ?? 0) < 0) {
          errors.add('${template.id}: numbers exceed $limit: ${t.prompt}');
        }
      }
      if (template.kind == MathTemplateKind.wordProblemThreeStep) {
        // Read the story itself, independent of the generator: each story
        // shape has its own reading of the numbers and its own calculation.
        final readings = [
          for (final story in _threeStepStoryReadings)
            if (story.read(t.prompt) case final result?) (story.name, result),
        ];
        if (readings.length != 1) {
          errors.add('${template.id}: story shape not recognised exactly once '
              '(${readings.map((r) => r.$1).toList()}): ${t.prompt}');
        } else {
          final (name, result) = readings.single;
          threeStepShapesSeen.add(name);
          if (result.problem != null) {
            errors.add('${template.id}/$name: ${result.problem}: ${t.prompt}');
          } else if (t.answer != '${result.answer}' || result.answer <= 0) {
            errors.add('${template.id}/$name: story does not match calculation '
                '(story gives ${result.answer}, task says ${t.answer}): '
                '${t.prompt}');
          } else if (!t.explanation.endsWith('= ${t.answer}.')) {
            errors.add('${template.id}/$name: explanation does not end with '
                'the answer: ${t.explanation}');
          }
        }
      }
      if (template.promptPattern == 'sachaufgabe-wegnehmen') {
        final nums = RegExp(r'\b\d+\b')
            .allMatches(t.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        if (nums.length != 2 ||
            t.answer != '${nums[0] - nums[1]}' ||
            nums[1] > nums[0]) {
          errors.add(
              '${template.id}: subtraction story does not match: ${t.prompt}');
        }
      }
      if (template.kind == MathTemplateKind.writtenAddition &&
          template.grade == 3) {
        final numbers = RegExp(r'\b\d+\b')
            .allMatches(t.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        if (numbers.length != 2 ||
            numbers[0] + numbers[1] > 1000 ||
            t.answer != '${numbers[0] + numbers[1]}') {
          errors.add('${template.id}: written addition exceeds class 3 range');
        }
      }
    }
  }
  // Every story shape must really be produced, otherwise a reading above
  // could silently go untested.
  final missingShapes = {
    for (final story in _threeStepStoryReadings) story.name
  }.difference(threeStepShapesSeen);
  if (missingShapes.isNotEmpty) {
    errors.add('g4_three_step: story shapes never generated: $missingShapes');
  }
  for (final template in MathTaskTemplates.templates
      .where((t) => t.id == 'g1_word_problem' || t.id == 'g2_sub_story')) {
    final prompts = {
      for (var seed = 0; seed < 160; seed++) template.concretize(seed).prompt
    };
    if (prompts.length < 40) {
      errors.add('${template.id}: too few distinct stories: ${prompts.length}');
    }
  }
  for (final template in GermanTaskTemplates.templates) {
    for (var seed = 0; seed < 300; seed++) {
      final t = template.concretize(seed);
      checked++;
      if (!t.choices.contains(t.answer) ||
          t.choices.toSet().length != t.choices.length ||
          t.choices.length < 2) {
        errors.add(
            '${template.id}: ambiguous choices ${t.choices}, answer ${t.answer}');
      }
    }
  }
  // Audit the complete active factory too: English, science, reading,
  // spelling and writing must pass the same gate as cached AI exercises.
  const guard = TaskQualityGuard();
  for (var grade = 1; grade <= 4; grade++) {
    final factory = ExerciseFactory(seed: grade);
    for (final subject in Curriculum.subjects.entries) {
      for (final unit in subject.value) {
        for (var sample = 0; sample < 20; sample++) {
          final task =
              factory.next(grade: grade, subject: subject.key, unit: unit);
          checked++;
          final problems = guard.problems(task);
          if (problems.isNotEmpty) {
            errors.add(
                '${task.subject}/${task.unit}: ${problems.join(', ')}: ${task.prompt}');
          }
        }
      }
    }
  }
  // Guided instruction is real product content too. Check its local answer
  // representations independently, not just a language model's assurance.
  var guidedChecked = 0;
  for (final lesson in GuidedLessonCatalog.all) {
    lesson.discoveryTarget.validate();
    for (final step in lesson.steps.where((step) => step.isQuestion)) {
      checked++;
      guidedChecked++;
      final expected = switch (step.answerKind!) {
        GuidedAnswerKind.tensValue => '${10 * step.a}',
        GuidedAnswerKind.gapToHundred => '${100 - step.a % 100}',
        GuidedAnswerKind.hundredRemainder => '${step.b - (100 - step.a % 100)}',
        GuidedAnswerKind.hundredSum => '${step.a + step.b}',
        GuidedAnswerKind.fractionParts =>
          '${step.a + step.fractionExtra}/${step.b}',
        GuidedAnswerKind.count => '${step.a}',
        GuidedAnswerKind.gapToTen => '${10 - step.a}',
        GuidedAnswerKind.remainder => '${step.a + step.b - 10}',
        GuidedAnswerKind.sum => '${step.a + step.b}',
        GuidedAnswerKind.toPreviousTen => '${step.a - (step.a ~/ 10) * 10}',
        GuidedAnswerKind.subtractRemainder => '${step.b - (step.a - 10)}',
        GuidedAnswerKind.difference => '${step.a - step.b}',
        GuidedAnswerKind.syllableCount => '${const {
              'Sonne': 2,
              'Tomate': 3,
              'Blume': 2,
              'Rakete': 3,
            }[step.word] ?? -1}',
        GuidedAnswerKind.plantPart => switch (step.plantPart) {
            GuidedPlantPart.root => 'Wurzel',
            GuidedPlantPart.stem => 'Stängel',
            GuidedPlantPart.leaf => 'Blatt',
            GuidedPlantPart.flower => 'Blüte',
            null => 'invalid plant part',
          },
        GuidedAnswerKind.groups =>
          '${List.filled(step.a, step.b).fold<int>(0, (a, b) => a + b)}',
        GuidedAnswerKind.repeatedAddition => [
            for (var group = 0; group < step.a; group++) '${step.b}'
          ].join(' + '),
      };
      if (step.expected != expected ||
          !step.choices.contains(expected) ||
          step.choices.toSet().length != step.choices.length) {
        errors.add('${lesson.id}: invalid guided answer for ${step.title}');
      }
      if (step.answerKind == GuidedAnswerKind.syllableCount &&
          (step.syllables.join() != step.word ||
              step.syllables.any((piece) => piece.isEmpty))) {
        errors
            .add('${lesson.id}: invalid spoken segmentation for ${step.word}');
      }
      if (step.answerKind == GuidedAnswerKind.repeatedAddition) {
        final sums = step.choices.map((choice) =>
            choice.split(' + ').map(int.parse).fold<int>(0, (a, b) => a + b));
        if (sums.where((sum) => sum == step.a * step.b).length != 1) {
          errors.add('${lesson.id}: ambiguous equal-group representations');
        }
      }
    }
  }
  stdout.writeln('Checked $checked generated and guided tasks across '
      'all subjects, templates and grades; $guidedChecked guided answer steps.');
  if (errors.isNotEmpty) {
    throw StateError(
        '${errors.length} failures: ${errors.take(12).join('\n')}');
  }
  stdout.writeln(
      'PASS: exact answers, distinct options, declared number ranges, three-step story calculations.');
}

/// Result of reading one three-step story: the answer the story itself
/// demands, or why the story cannot be solved sensibly by a child.
class _StoryResult {
  const _StoryResult(this.answer, [this.problem]);
  final int answer;
  final String? problem;
}

class _StoryReading {
  const _StoryReading(this.name, this.pattern, this.solve);
  final String name;
  final RegExp pattern;
  final _StoryResult Function(List<int> n) solve;

  _StoryResult? read(String prompt) {
    final match = pattern.firstMatch(prompt);
    if (match == null) return null;
    return solve([
      for (var i = 1; i <= match.groupCount; i++) int.parse(match.group(i)!)
    ]);
  }
}

/// Checks that every intermediate result a child writes down is a
/// non-negative whole number, then returns the final result.
_StoryResult _steps(List<int> intermediate) {
  for (final value in intermediate) {
    if (value < 0) {
      return _StoryResult(value, 'negative intermediate result $value');
    }
  }
  return _StoryResult(intermediate.last);
}

// One reading per story the generator can tell. The patterns are anchored
// to the whole prompt, so a changed or new story fails the audit until its
// calculation is described here as well.
final List<_StoryReading> _threeStepStoryReadings = [
  _StoryReading(
    'Obstkiste',
    RegExp(r'^In einer Kiste liegen (\d+) Äpfel und (\d+) Birnen\. Eine zweite '
        r'Kiste ist genau gleich gefüllt\. (\d+) Früchte werden gegessen\. '
        r'Wie viele Früchte bleiben\?$'),
    (n) => _steps([n[0] + n[1], (n[0] + n[1]) * 2, (n[0] + n[1]) * 2 - n[2]]),
  ),
  _StoryReading(
    'Sterne',
    RegExp(r'^Die Klasse bastelt an (\d+) Tagen jeden Tag (\d+) gelbe und '
        r'(\d+) blaue Sterne\. (\d+) Sterne werden verschenkt\. '
        r'Wie viele Sterne bleiben\?$'),
    (n) => _steps(
        [n[1] + n[2], (n[1] + n[2]) * n[0], (n[1] + n[2]) * n[0] - n[3]]),
  ),
  _StoryReading(
    'Flaschen',
    RegExp(r'^Für das Schulfest gibt es (\d+) Kisten mit je (\d+) Flaschen '
        r'Saft und (\d+) Kisten mit je (\d+) Flaschen Wasser\. (\d+) '
        r'Flaschen bleiben übrig\. Wie viele Flaschen wurden getrunken\?$'),
    (n) => _steps([
      n[0] * n[1],
      n[2] * n[3],
      n[0] * n[1] + n[2] * n[3],
      n[0] * n[1] + n[2] * n[3] - n[4],
    ]),
  ),
  _StoryReading(
    'Bücherei',
    RegExp(r'^In der Bücherei stehen (\d+) Bücher\. Am Montag werden (\d+) '
        r'ausgeliehen, am Dienstag (\d+)\. Am Mittwoch kommen (\d+) zurück\. '
        r'Wie viele Bücher stehen jetzt in der Bücherei\?$'),
    (n) => n[3] > n[1] + n[2]
        ? const _StoryResult(0, 'more books returned than were borrowed')
        : _steps([n[0] - n[1], n[0] - n[1] - n[2], n[0] - n[1] - n[2] + n[3]]),
  ),
  _StoryReading(
    'Sportfest',
    RegExp(r'^Beim Sportfest starten (\d+) Gruppen mit je (\d+) Kindern\. '
        r'(\d+) Kinder kommen später dazu, (\d+) Kinder hören früher auf\. '
        r'Wie viele Kinder kommen ins Ziel\?$'),
    (n) => _steps([n[0] * n[1], n[0] * n[1] + n[2], n[0] * n[1] + n[2] - n[3]]),
  ),
  _StoryReading(
    'Einkauf',
    RegExp(r'^Tim kauft (\d+) Hefte um je (\d+) € und ein Buch um (\d+) €\. '
        r'Er zahlt mit einem (\d+)-€-Schein\. '
        r'Wie viele Euro bekommt er zurück\?$'),
    (n) {
      final total = n[0] * n[1] + n[2];
      if (n[3] != 50 && n[3] != 100) {
        return _StoryResult(0, 'no such banknote: ${n[3]} €');
      }
      // A child pays with the smallest note that is enough.
      if (n[3] == 100 && total < 50) {
        return const _StoryResult(0, 'pays with 100 € although 50 € suffice');
      }
      return _steps([n[0] * n[1], total, n[3] - total]);
    },
  ),
  _StoryReading(
    'Karten',
    RegExp(r'^(\d+) Sammelkarten werden gerecht an (\d+) Kinder verteilt\. '
        r'Jedes Kind verschenkt (\d+) Karten und bekommt später (\d+) dazu\. '
        r'Wie viele Karten hat jedes Kind dann\?$'),
    (n) => n[1] == 0 || n[0] % n[1] != 0
        ? const _StoryResult(0, 'cards cannot be shared fairly')
        : _steps(
            [n[0] ~/ n[1], n[0] ~/ n[1] - n[2], n[0] ~/ n[1] - n[2] + n[3]]),
  ),
  _StoryReading(
    'Zug',
    // The number of wagons is a deliberately superfluous detail.
    RegExp(r'^In einem Zug mit \d+ Waggons sitzen (\d+) Erwachsene und (\d+) '
        r'Kinder\. Am Bahnhof steigen (\d+) Personen aus und (\d+) ein\. '
        r'Wie viele Personen sitzen jetzt im Zug\?$'),
    (n) => _steps([n[0] + n[1], n[0] + n[1] - n[2], n[0] + n[1] - n[2] + n[3]]),
  ),
];
