// Source inventory, not a claim of pedagogical or device acceptance.
// Run with: dart run tool/nextgen_learning_inventory.dart
import 'dart:convert';

import '../lib/core/school_exercise_generator.dart';
import '../lib/core/math_task_templates.dart';
import '../lib/core/german_task_templates.dart';
import '../lib/core/curriculum/primary_activity_catalog.dart';
import '../lib/domain/learning/lumo_learning_domain.dart';
import '../lib/domain/tutoring/guided_lesson_catalog.dart';
import '../lib/features/learning/lab/learning_lab_catalog.dart';
import '../lib/features/reading/reading_text_library.dart';

void main() {
  print(const JsonEncoder.withIndent('  ').convert({
    'unit_scopes': [
      for (var grade = 1; grade <= 4; grade++)
        for (final subject in Curriculum.exerciseSubjectsForGrade(grade))
          for (final unit in Curriculum.unitsForGrade(subject, grade,
              currentGradeOnly: true))
            {'grade': grade, 'subject': subject, 'unit': unit},
    ],
    'math_templates': [
      for (final template in MathTaskTemplates.templates)
        {
          'id': template.id,
          'grade': template.grade,
          'unit': template.unit,
          'kind': template.kind.name,
          'range_a': template.validRangeA,
          'range_b': template.validRangeB
        },
    ],
    'german_templates': [
      for (final template in GermanTaskTemplates.templates)
        {
          'id': template.id,
          'grade': template.grade,
          'unit': template.unit,
          'kind': template.kind.name
        },
    ],
    'declared_task_types': TaskType.values.map((type) => type.name).toList(),
    'declared_visual_types':
        VisualType.values.map((type) => type.name).toList(),
    'declared_learning_modes':
        LearningMode.values.map((mode) => mode.name).toList(),
    'guided_lessons': [
      for (final lesson in GuidedLessonCatalog.all)
        {
          'id': lesson.id,
          'grade': lesson.grade,
          'title': lesson.title,
          'subject': lesson.subject,
          'unit': lesson.schoolUnit,
          'concept': lesson.concept.name,
          'steps': [
            for (final step in lesson.steps)
              {
                'type': step.type.name,
                'title': step.title,
                'answer_kind': step.answerKind?.name,
                'assessed': step.isQuestion,
                'independent': step.isIndependent
              }
          ]
        },
    ],
    'lab_topics': [
      for (final topic in LabCatalog.topics)
        {
          'id': topic.id,
          'title': topic.title,
          'minimum_grade': topic.minimumGrade,
          'subject': topic.subject,
          'unit': topic.unit,
          'mode': topic.mode.name,
          'goal': topic.goal,
          'problems': [
            for (final problem in topic.problems)
              {
                'id': problem.id,
                'valid': problem.isValid,
                'mode': problem.mode.name
              }
          ]
        },
    ],
    'reading_texts': [
      for (final value in ReadingTextLibrary.all)
        {
          'id': value.id,
          'grade': value.grade,
          'title': value.title,
          'line_count': value.lines.length,
          'word_count': value.words.length
        },
    ],
    'practical_activities': [
      for (final activity in PrimaryActivityCatalog.all)
        {
          'id': activity.id,
          'grade': activity.grade,
          'subject': activity.subject,
          'title': activity.title,
          'goal': activity.competency,
          'instruction': activity.instruction,
          'evidence': activity.evidence,
          'requires_adult': activity.requiresAdult
        },
    ],
  }));
}
