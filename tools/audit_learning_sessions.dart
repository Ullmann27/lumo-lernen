// ignore_for_file: avoid_print, avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';
import '../lib/core/school_exercise_generator.dart';

/// Synthetic local tasks only; no child records, providers or app storage.
void main(List<String> args) {
  final rows = <Map<String, Object>>[];
  final invalid = <Map<String, Object>>[];
  for (var grade = 1; grade <= 4; grade++) {
    for (final subject in Curriculum.exerciseSubjectsForGrade(grade)) {
      for (final unit in [
        'Alle',
        ...Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true)
      ]) {
        final factory = ExerciseFactory(seed: 1937);
        final keys = <String, int>{};
        final prompts = <String>{};
        final explanations = <String>{};
        var consecutive = 0;
        String? previous;
        final count = unit == 'Alle' ? 1000 : 200;
        for (var n = 0; n < count; n++) {
          final t = factory.next(grade: grade, subject: subject, unit: unit);
          final key = '${t.prompt}|${t.answer}';
          if (key == previous) consecutive++;
          previous = key;
          keys.update(key, (v) => v + 1, ifAbsent: () => 1);
          prompts.add(t.prompt);
          explanations.add(t.explanation);
          if (t.choices.toSet().length != t.choices.length ||
              (!t.choices.contains(t.answer) &&
                  !(t.choices.isEmpty && t.visual == 'shape_trace')) ||
              t.prompt.isEmpty ||
              t.explanation.isEmpty) {
            invalid.add({
              'grade': grade,
              'subject': subject,
              'unit': unit,
              'prompt': t.prompt,
              'answer': t.answer,
              'choices': t.choices
            });
          }
        }
        rows.add({
          'grade': grade,
          'subject': subject,
          'unit': unit,
          'tasks': count,
          'distinct_problem_answers': keys.length,
          'distinct_prompts': prompts.length,
          'distinct_explanations': explanations.length,
          'adjacent_repeats': consecutive,
          'most_frequent': keys.values.reduce((a, b) => a > b ? a : b)
        });
      }
    }
  }
  final report = {
    'seed': 1937,
    'task_count': rows.fold<int>(0, (n, r) => n + (r['tasks'] as int)),
    'rows': rows,
    'invalid': invalid,
    'limits':
        'Synthetic generator audit; not a human pedagogical or hardware acceptance. IDs and answer order do not count as variety.'
  };
  File(args.single)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  print('Tasks: ${report['task_count']}; invalid: ${invalid.length}');
  for (final r
      in rows.where((r) => (r['distinct_problem_answers'] as int) < 12)) {
    print(r);
  }
  if (invalid.isNotEmpty) exitCode = 1;
}
