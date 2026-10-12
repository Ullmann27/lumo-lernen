import 'dart:io';

import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';

void main() {
  var checked = 0;
  final errors = <String>[];
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
        final nums = RegExp(r'\b\d+\b')
            .allMatches(t.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        if (nums.length != 3 ||
            t.answer != '${2 * (nums[0] + nums[1]) - nums[2]}') {
          errors.add(
              '${template.id}: story does not match calculation: ${t.prompt}');
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
