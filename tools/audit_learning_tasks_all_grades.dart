// Reproducible sample audit of the existing LUMO core task generator.
// Not an enumeration of all question variations or a teacher-approved curriculum.
import 'dart:convert';
import 'dart:io';
import '../lib/core/school_exercise_generator.dart';

void main(List<String> args) {
  if (args.length > 1) {
    stderr.writeln(
        'Usage: dart run tools/audit_learning_tasks_all_grades.dart [output-directory]');
    exitCode = 64;
    return;
  }
  final out =
      Directory(args.isEmpty ? 'audit/learning-all-grades' : args.first);
  out.createSync(recursive: true);
  final issues = <Map<String, Object?>>[];
  final samples = <Map<String, Object?>>[];
  final families = <Map<String, Object?>>[];
  var scopes = 0;
  for (var grade = 1; grade <= 4; grade++) {
    for (final subject in Curriculum.exerciseSubjectsForGrade(grade)) {
      for (final unit
          in Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true)) {
        scopes++;
        var accepted = 0;
        for (final seed in [0, 1, 17, 1937]) {
          final factory = ExerciseFactory(seed: seed);
          for (var attempt = 0; attempt < 8; attempt++) {
            try {
              final task = factory.nextExact(
                  grade: grade,
                  subject: subject,
                  unit: unit,
                  currentGradeOnly: true);
              final defects = <String>[];
              if (task.grade != grade ||
                  task.subject != subject ||
                  task.unit != unit) {
                defects.add('incorrect_grade_subject_unit');
              }
              if (task.prompt.trim().isEmpty ||
                  task.answer.trim().isEmpty ||
                  task.explanation.trim().isEmpty) {
                defects.add('empty_prompt_answer_or_explanation');
              }
              if (task.choices.isNotEmpty &&
                  !task.choices.contains(task.answer)) {
                defects.add('correct_answer_missing');
              }
              if (task.choices.toSet().length != task.choices.length) {
                defects.add('duplicate_answer_choices');
              }
              final record = <String, Object?>{
                'grade': grade,
                'subject': subject,
                'unit': unit,
                'seed': seed,
                'attempt': attempt,
                'prompt': task.prompt,
                'answer': task.answer,
                'choices': task.choices,
                'explanation': task.explanation,
                'visual': task.visual,
                'handwriting': task.handwriting,
                'difficulty': task.difficulty,
                'issues': defects,
                'semanticCurriculumReview': 'pending',
                'threeDSceneApproval': false,
              };
              samples.add(record);
              accepted++;
              if (defects.isNotEmpty) issues.add(record);
            } catch (error) {
              issues.add({
                'grade': grade,
                'subject': subject,
                'unit': unit,
                'seed': seed,
                'attempt': attempt,
                'status': 'failed_to_generate',
                'exception': error.toString(),
              });
            }
          }
        }
        families.add({
          'grade': grade,
          'subject': subject,
          'unit': unit,
          'generatedSamples': accepted,
          'allVariantsEnumerated': false,
        });
      }
    }
  }
  final encoder = const JsonEncoder.withIndent('  ');
  File('${out.path}/task-samples.jsonl')
      .writeAsStringSync(samples.map(jsonEncode).join('\n') + '\n');
  File('${out.path}/task-families.json')
      .writeAsStringSync(encoder.convert(families));
  File('${out.path}/issues.json').writeAsStringSync(encoder.convert(issues));
  final report = {
    'status': issues.isEmpty ? 'SAMPLED_CONTRACT_PASS' : 'NEEDS_REPAIR',
    'grades': [1, 2, 3, 4],
    'familyCount': scopes,
    'generatedSamples': samples.length,
    'issues': issues.length,
    'allExistingTasksReviewed': false,
    'officialCurriculumApproval': false,
    'allVariantsEnumerated': false,
    'scope':
        'ExerciseFactory core only. Other reading, handwriting, games, lesson banks need separate review.',
  };
  File('${out.path}/summary.json').writeAsStringSync(encoder.convert(report));
  stdout.writeln(encoder.convert(report));
  if (issues.isNotEmpty) exitCode = 1;
}
