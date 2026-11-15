// Run explicitly with Flutter; this is a source inventory, not device QA.
// flutter test --no-pub tools/nextgen/export_learning_catalog_test.dart
//   --dart-define=LUMO_CATALOG_OUTPUT=/absolute/path/catalog.json
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/cognitive_profile_generator.dart';
import 'package:lumo_lernen/core/curriculum/academy_topic_units.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/lumo_quest_library.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart'
    as domain;
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/reading/reading_text_library.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  test('export the actual finite catalogs without generating student attempts',
      () {
    const output = String.fromEnvironment('LUMO_CATALOG_OUTPUT');
    expect(output, isNotEmpty,
        reason:
            'Choose an explicit inventory output; no student store is used.');
    final revision = Process.runSync('git', ['rev-parse', 'HEAD']);
    expect(revision.exitCode, 0);
    final result = <String, Object?>{
      'sourceHead': revision.stdout.toString().trim(),
      'semantics':
          'Finite catalogs are enumerated; generated task variants are not.',
      'curriculumFamilies': [
        for (var grade = 1; grade <= 4; grade++)
          for (final subject in Curriculum.exerciseSubjectsForGrade(grade))
            for (final unit in Curriculum.unitsForGrade(subject, grade,
                currentGradeOnly: true))
              {'grade': grade, 'subject': subject, 'unit': unit},
      ],
      'mathTemplates': [
        for (final template in MathTaskTemplates.templates)
          {
            'id': template.id,
            'grade': template.grade,
            'unit': template.unit,
            'kind': template.kind.name,
          },
      ],
      'germanTemplates': [
        for (final template in GermanTaskTemplates.templates)
          {
            'id': template.id,
            'grade': template.grade,
            'unit': template.unit,
            'kind': template.kind.name,
          },
      ],
      'academyTopics': [
        for (final grade in LumoCurriculum.grades)
          for (final subject in grade.subjects)
            for (final topic in subject.topics)
              {
                'id': topic.id,
                'grade': grade.grade,
                'subjectId': subject.id,
                'subject': subject.name,
                'title': topic.title,
                'isWriting': topic.isWriting,
                'writingChars': topic.writingChars,
                'registeredModule': LearningModuleRegistry.hasModule(topic.id),
                'exerciseUnit': AcademyTopicUnits.exerciseUnit(
                    topicId: topic.id,
                    title: topic.title,
                    subject: subject.name,
                    grade: grade.grade),
              },
      ],
      'registeredModuleIds': LearningModuleRegistry.registeredTopicIds.toList()
        ..sort(),
      'practicalActivities': [
        for (final activity in PrimaryActivityCatalog.all)
          {
            'id': activity.id,
            'grade': activity.grade,
            'subject': activity.subject,
            'title': activity.title,
            'requiresAdult': activity.requiresAdult,
          },
      ],
      'labTopics': [
        for (final topic in LabCatalog.topics)
          {
            'id': topic.id,
            'grade': topic.minimumGrade,
            'subject': topic.subject,
            'unit': topic.unit,
            'mode': topic.mode.name,
            'problems': [
              for (final problem in topic.problems)
                {
                  'id': problem.id,
                  'mode': problem.mode.name,
                  'hintCount': problem.hints.length,
                },
            ],
          },
      ],
      'guidedLessons': [
        for (final lesson in GuidedLessonCatalog.all)
          {
            'id': lesson.id,
            'grade': lesson.grade,
            'subject': lesson.subject,
            'unit': lesson.schoolUnit,
            'concept': lesson.concept.name,
            'steps': [
              for (var index = 0; index < lesson.steps.length; index++)
                {
                  'index': index,
                  'type': lesson.steps[index].type.name,
                  'answerKind': lesson.steps[index].answerKind?.name,
                  'isIndependent': lesson.steps[index].isIndependent,
                },
            ],
          },
      ],
      'gameLevels': [
        for (final level in GameLevelCatalog.levels)
          {
            'id': level.id,
            'title': level.title,
            'gradeFloor': level.gradeFloor,
            'subject': level.subject,
            'miniType': level.miniType.name,
            'playable': level.miniType.isPlayable,
            // GamesContent routes the final level to the existing Quizshow.
            'effectiveRoute': level.id == 50 ? 'quiz' : 'mini_game',
          },
      ],
      'readingTexts': [
        for (final text in ReadingTextLibrary.all)
          {'id': text.id, 'grade': text.grade, 'title': text.title},
      ],
      'quests': [
        for (final quest in LumoQuestLibrary.all())
          {
            'id': quest.id,
            'grade': quest.gradeLevel,
            'title': quest.title,
            'exercisePages': [
              for (final page in quest.story.pages)
                if (page.exercise != null)
                  {
                    'pageNum': page.pageNum,
                    'type': page.exercise!.type.name,
                  },
            ],
          },
      ],
      'cognitiveQuestions': [
        for (var grade = 1; grade <= 4; grade++)
          for (final question in CognitiveProfileGenerator.forGrade(grade))
            {
              'id': question.id,
              'grade': question.grade,
              'domain': question.domain.name,
            },
      ],
      'enums': {
        'LearningMode': domain.LearningMode.values.map((v) => v.name).toList(),
        'TaskType': domain.TaskType.values.map((v) => v.name).toList(),
        'VisualType': domain.VisualType.values.map((v) => v.name).toList(),
        'MathTemplateKind': MathTemplateKind.values.map((v) => v.name).toList(),
        'GermanTemplateKind':
            GermanTemplateKind.values.map((v) => v.name).toList(),
        'LabMode': LabMode.values.map((v) => v.name).toList(),
        'GuidedLessonConcept':
            GuidedLessonConcept.values.map((v) => v.name).toList(),
        'GuidedAnswerKind': GuidedAnswerKind.values.map((v) => v.name).toList(),
        'TutoringStepType': TutoringStepType.values.map((v) => v.name).toList(),
        'GameMiniType': GameMiniType.values.map((v) => v.name).toList(),
        'StoryExerciseType':
            StoryExerciseType.values.map((v) => v.name).toList(),
        'IqArea': IqArea.values.map((v) => v.name).toList(),
        'CognitiveDomain': CognitiveDomain.values.map((v) => v.name).toList(),
      },
    };
    final file = File(output);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(result)}\n');
  });
}
