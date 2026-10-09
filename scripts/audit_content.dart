// ignore_for_file: avoid_print
// Kommandozeilen-Werkzeug (dart run scripts/audit_content.dart): Ausgabe per print ist hier gewollt.
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

void main() {
  var checked = 0;
  final errors = <String>[];
  for (final template in MathTaskTemplates.templates) {
    for (var seed = 0; seed < 300; seed++) {
      final t = template.concretize(seed);
      checked++;
      if (t.choices.isNotEmpty && (!t.choices.contains(t.answer) || t.choices.toSet().length != t.choices.length || t.choices.length < 2)) {
        errors.add('${template.id}: choices ${t.choices}, answer ${t.answer}');
      }
      final range = RegExp(r'bis (\d+)').firstMatch(t.unit);
      if (range != null && (template.kind == MathTemplateKind.addition || template.kind == MathTemplateKind.subtraction)) {
        final limit = int.parse(range.group(1)!);
        final nums = RegExp(r'\b\d+\b').allMatches(t.prompt).map((m) => int.parse(m.group(0)!));
        if (nums.any((n) => n > limit) || (int.tryParse(t.answer) ?? 0) > limit || (int.tryParse(t.answer) ?? 0) < 0) errors.add('${template.id}: numbers exceed $limit: ${t.prompt}');
      }
      if (template.kind == MathTemplateKind.wordProblemThreeStep) {
        final nums = RegExp(r'\b\d+\b').allMatches(t.prompt).map((m) => int.parse(m.group(0)!)).toList();
        if (nums.length != 3 || t.answer != '${2 * (nums[0] + nums[1]) - nums[2]}') errors.add('${template.id}: story does not match calculation: ${t.prompt}');
      }
      if (template.promptPattern == 'sachaufgabe-wegnehmen') {
        final nums = RegExp(r'\b\d+\b').allMatches(t.prompt).map((m) => int.parse(m.group(0)!)).toList();
        if (nums.length != 2 || t.answer != '${nums[0] - nums[1]}' || nums[1] > nums[0]) errors.add('${template.id}: subtraction story does not match: ${t.prompt}');
      }
      if (template.kind == MathTemplateKind.writtenAddition && template.grade == 3) {
        final numbers = RegExp(r'\b\d+\b').allMatches(t.prompt).map((m) => int.parse(m.group(0)!)).toList();
        if (numbers.length != 2 || numbers[0] + numbers[1] > 1000 || t.answer != '${numbers[0] + numbers[1]}') errors.add('${template.id}: written addition exceeds class 3 range');
      }
    }
  }
  for (final template in MathTaskTemplates.templates.where((t) => t.id == 'g1_word_problem' || t.id == 'g2_sub_story')) {
    final prompts = {for (var seed = 0; seed < 160; seed++) template.concretize(seed).prompt};
    if (prompts.length < 40) errors.add('${template.id}: too few distinct stories: ${prompts.length}');
  }
  for (final template in GermanTaskTemplates.templates) {
    for (var seed = 0; seed < 300; seed++) {
      final t = template.concretize(seed);
      checked++;
      if (!t.choices.contains(t.answer) || t.choices.toSet().length != t.choices.length || t.choices.length < 2) errors.add('${template.id}: ambiguous choices ${t.choices}, answer ${t.answer}');
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
          final task = factory.next(grade: grade, subject: subject.key, unit: unit);
          checked++;
          final problems = guard.problems(task);
          if (problems.isNotEmpty) {
            errors.add('${task.subject}/${task.unit}: ${problems.join(', ')}: ${task.prompt}');
          }
        }
      }
    }
  }
  print('Checked $checked generated tasks across all subjects, templates and grades.');
  if (errors.isNotEmpty) throw StateError('${errors.length} failures: ${errors.take(12).join('\n')}');
  print('PASS: exact answers, distinct options, declared number ranges, three-step story calculations.');
}
