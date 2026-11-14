import 'dart:convert';
import 'dart:io';

import '../../lib/core/math_task_templates.dart';
import '../../lib/core/school_exercise_generator.dart';

/// Shared by the Flutter regression and a package-free Dart execution.
/// Every generated task comes from the real production generators.
Map<String, Object?> verifyMathExactTopicSelection() {
  const seedsPerTopic = 32;
  final failures = <Map<String, Object?>>[];
  final unitsByGrade = <String, List<String>>{};
  final fixedCases = <Map<String, Object?>>[];
  final sameTopicGrades = <int>{};
  var checks = 0;
  var templateCalls = 0;
  var factoryCalls = 0;

  void check(
    bool condition,
    String contract,
    Map<String, Object?> context,
  ) {
    checks++;
    if (!condition) {
      failures.add(<String, Object?>{'contract': contract, ...context});
    }
  }

  void checkTemplate(
    MathConcreteTask task,
    int grade,
    String unit,
    int seed,
    String group,
  ) {
    final context = <String, Object?>{
      'group': group,
      'grade': grade,
      'requested_unit': unit,
      'seed': seed,
      'actual_unit': task.unit,
      'actual_difficulty': task.difficulty,
      'actual_pattern': task.promptPattern,
    };
    check(task.unit == unit, 'template preserves exact topic', context);
    // Check the underlying template, not just a relabelled output unit.
    check(
      MathTaskTemplates.templates.any(
        (template) =>
            template.unit == unit &&
            template.grade <= grade &&
            template.grade == task.difficulty &&
            template.promptPattern == task.promptPattern,
      ),
      'pattern and difficulty belong to the selected allowed topic',
      context,
    );
    check(task.answer.isNotEmpty, 'template has an answer', context);
    check(
      task.visual == 'shape_trace'
          ? task.choices.isEmpty
          : task.choices.contains(task.answer),
      'answer is usable by the actual renderer',
      context,
    );
  }

  const knownCases = <(int, String)>[
    (2, 'Geld'),
    (3, 'Geometrie Formen'),
    (4, 'Geometrie Formen'),
  ];
  for (final (grade, unit) in knownCases) {
    const seed = 1;
    templateCalls++;
    final task = MathTaskTemplates.generate(
      grade: grade,
      unit: unit,
      seed: seed,
    );
    fixedCases.add(<String, Object?>{
      'grade': grade,
      'requested_unit': unit,
      'seed': seed,
      'actual_unit': task.unit,
      'actual_difficulty': task.difficulty,
      'actual_pattern': task.promptPattern,
    });
    checkTemplate(task, grade, unit, seed, 'reported counterexample');
  }

  for (var grade = 1; grade <= 4; grade++) {
    // Use the real cumulative list: earlier topics remain selectable to review.
    final units = Curriculum.unitsForGrade('Mathematik', grade);
    unitsByGrade['$grade'] = units;
    check(units.isNotEmpty, 'cumulative topic list is not empty', {
      'grade': grade,
    });
    check(
      units.contains('Geld') && units.contains('Geometrie Formen'),
      'earlier exact topics remain in the cumulative curriculum',
      {'grade': grade, 'units': units},
    );
    for (final unit in units) {
      final hasTemplate = MathTaskTemplates.templates.any(
        (template) => template.unit == unit && template.grade <= grade,
      );
      for (var seed = 0; seed < seedsPerTopic; seed++) {
        if (hasTemplate) {
          templateCalls++;
          final task = MathTaskTemplates.generate(
            grade: grade,
            unit: unit,
            seed: seed,
          );
          checkTemplate(task, grade, unit, seed, 'cumulative topic');
        }
        factoryCalls++;
        final context = <String, Object?>{
          'group': 'cumulative nextExact',
          'grade': grade,
          'requested_unit': unit,
          'seed': seed,
        };
        try {
          final task = ExerciseFactory(seed: seed).nextExact(
            grade: grade,
            subject: 'Mathematik',
            unit: unit,
            weakSkills: const {
              'Geld wechseln': 6,
              'Umfang': 6,
              'Flächeninhalt': 6,
            },
            childName: 'Mira',
          );
          context.addAll({
            'actual_grade': task.grade,
            'actual_subject': task.subject,
            'actual_unit': task.unit,
            'actual_difficulty': task.difficulty,
          });
          check(
            task.grade == grade &&
                task.subject == 'Mathematik' &&
                task.unit == unit,
            'factory preserves grade, subject and exact topic despite weaknesses',
            context,
          );
          check(
            task.difficulty >= 1 && task.difficulty <= grade,
            'factory difficulty stays within the requested grade',
            context,
          );
          check(
            task.answer.isNotEmpty &&
                (task.visual == 'shape_trace'
                    ? task.choices.isEmpty
                    : task.choices.contains(task.answer)),
            'factory answer is usable by the actual renderer',
            context,
          );
        } catch (error) {
          check(false, 'nextExact accepts every allowed cumulative topic', {
            ...context,
            'error_type': error.runtimeType.toString(),
            'error': error.toString(),
          });
        }
      }
    }
  }

  // Preserve current-grade practice and allowed earlier-grade review within
  // the same topic. Do not replace this with a cross-topic alias.
  for (var seed = 0; seed < 128; seed++) {
    templateCalls++;
    final task = MathTaskTemplates.generate(
      grade: 2,
      unit: 'Textaufgaben',
      seed: seed,
    );
    sameTopicGrades.add(task.difficulty);
    checkTemplate(task, 2, 'Textaufgaben', seed, 'same-topic grade mixing');
    if (seed % 4 != 0) {
      check(
        task.difficulty == 2,
        'current-grade slots remain current when an exact template exists',
        {'grade': 2, 'seed': seed, 'actual_difficulty': task.difficulty},
      );
    }
  }
  check(
    sameTopicGrades.contains(1) &&
        sameTopicGrades.contains(2) &&
        sameTopicGrades.length == 2,
    'same-topic current practice and earlier review both remain reachable',
    {'observed_grades': sameTopicGrades.toList()..sort()},
  );

  // Real legacy shortcuts retain their canonical targets; the generator
  // must not turn an alias into a fabricated exact output unit.
  const aliases = <String, String>{
    'Zahlenreihe': 'Zahlenstrahl',
    'Nachbarzahlen': 'Zahlenstrahl',
    'Rechenhaeuser': 'Plus bis 20',
  };
  for (final entry in aliases.entries) {
    for (var seed = 0; seed < 16; seed++) {
      templateCalls++;
      final task = MathTaskTemplates.generate(
        grade: 2,
        unit: entry.key,
        seed: seed,
      );
      checkTemplate(task, 2, entry.value, seed, 'legacy ' + entry.key);
    }
  }

  return <String, Object?>{
    'scope': 'pure Dart production generator contract; no widget or Android assertions',
    'checks': checks,
    'template_calls': templateCalls,
    'factory_calls': factoryCalls,
    'seeds_per_cumulative_topic': seedsPerTopic,
    'cumulative_topic_count':
        unitsByGrade.values.fold<int>(0, (sum, units) => sum + units.length),
    'units_by_grade': unitsByGrade,
    'fixed_cases': fixedCases,
    'same_topic_observed_grades': sameTopicGrades.toList()..sort(),
    'failure_count': failures.length,
    'failures': failures,
  };
}

void main() {
  final report = verifyMathExactTopicSelection();
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  if ((report['failures']! as List).isNotEmpty) exitCode = 1;
}
