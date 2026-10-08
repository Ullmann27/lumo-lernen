import '../../core/german_task_templates.dart';
import '../../core/math_task_templates.dart';
import '../../core/scanned_work_analysis.dart';
import '../../core/school_exercise_generator.dart';

class PhotoLessonPractice {
  const PhotoLessonPractice({required this.tasks, this.notice = ''});

  final List<LumoTask> tasks;
  final String notice;

  static PhotoLessonPractice generate({
    required ScannedWorkAnalysis analysis,
    required int grade,
    required int seed,
  }) {
    final subject = analysis.subject;
    if (!const ['Mathematik', 'Deutsch', 'Englisch', 'Sachunterricht']
        .contains(subject)) {
      return const PhotoLessonPractice(
        tasks: [],
        notice: 'Lumo konnte das Fach nicht sicher erkennen. '
            'Fotografiere bitte die Überschrift und die Aufgabe noch einmal.',
      );
    }
    final cappedGrade = grade.clamp(1, 4).toInt();
    final unit = analysis.nextPracticeUnit;
    final supported = Curriculum.unitsForGrade(subject, cappedGrade).contains(unit) ||
        (subject == 'Mathematik' && MathTaskTemplates.supportsUnit(cappedGrade, unit)) ||
        (subject == 'Deutsch' && GermanTaskTemplates.supportsUnit(cappedGrade, unit));
    final factory = ExerciseFactory(seed: seed);
    final tasks = <LumoTask>[];
    for (var i = 0; i < 5; i++) {
      if (subject == 'Mathematik' && supported) {
        // Preserve the successful math prompt, answer and explanation path.
        final task = MathTaskTemplates.generate(
          grade: cappedGrade,
          unit: unit,
          seed: (seed + i * 7919) & 0x7fffffff,
        );
        tasks.add(LumoTask(
          id: 'photo-math-$seed-$i',
          grade: cappedGrade,
          subject: subject,
          unit: task.unit,
          prompt: task.prompt,
          choices: task.choices,
          answer: task.answer,
          explanation: task.explanation,
          visual: task.visual,
          difficulty: task.difficulty,
        ));
      } else {
        tasks.add(factory.next(
          grade: cappedGrade,
          subject: subject,
          unit: supported ? unit : 'Alle',
        ));
      }
    }
    return PhotoLessonPractice(
      tasks: List<LumoTask>.unmodifiable(tasks),
      notice: supported
          ? ''
          : 'Für „$unit“ sind noch keine passenden Übungen verfügbar. '
              'Hier übst du andere Themen aus $subject. '
              'Das Thema steht bei jeder Aufgabe.',
    );
  }
}
