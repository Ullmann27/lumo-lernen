import '../domain/tutoring/guided_lesson_catalog.dart';
import '../domain/tutoring/tutoring_session_planner.dart';
import 'lumo_task_dialogue.dart';
import 'primary_school_word_data.dart';
import 'school_exercise_generator.dart';
import 'task_hint_service.dart';

/// Adapts existing authored lessons and their visible task data. Assessment,
/// grading and persistence stay in their existing lesson controllers.
abstract final class LumoTaskDialogueAdapter {
  static LumoTaskDialogueSnapshot fromGuidedLesson({
    required GuidedLesson lesson,
    required GuidedLessonStep step,
    required String sessionId,
    required String taskId,
    required String stepId,
    required int revision,
    int helpLevel = 0,
    bool isAssessment = false,
    bool? acceptingAnswer,
    List<String>? answerChoices,
    List<String> selectedObjectIds = const [],
    String? lastAnswer,
    bool? lastCorrect,
  }) {
    final objects = <LumoTaskDialogueObject>[];
    final explanations = <LumoReviewedTaskExplanation>[];
    final demonstration = step.type == TutoringStepType.showExample;
    final bridge = lesson.concept == GuidedLessonConcept.bridgeTen &&
        step.a > 0 && step.a < 10 && step.b > 0 && step.a + step.b > 10;

    if (bridge) {
      for (var i = 0; i < 10; i++) {
        objects.add(LumoTaskDialogueObject(
          id: 'guided-ten-slot-$i',
          label: 'Platz ${i + 1} im Zehnerfeld',
          groupId: 'ten-frame',
        ));
      }
      for (var i = 0; i < step.a + step.b; i++) {
        objects.add(LumoTaskDialogueObject(
          id: 'guided-bridge-apple-$i',
          label: 'Apfel ${i + 1}',
          groupId: i < step.a ? 'initial-apples' : 'added-apples',
        ));
      }
      final gap = 10 - step.a;
      final freeSlots = [for (var i = step.a; i < 10; i++) 'guided-ten-slot-$i'];
      final remaining = [
        for (var i = 10; i < step.a + step.b; i++) 'guided-bridge-apple-$i'
      ];
      // A task asking for the gap must not receive that answer as a hint.
      final mayNameGap = demonstration || step.answerKind != GuidedAnswerKind.gapToTen;
      if (demonstration) {
        explanations.add(LumoReviewedTaskExplanation(
          id: 'bridge-fill-ten',
          stepId: stepId,
          stepNumber: 1,
          text: 'Am Anfang sind ${step.a} Plätze im Zehnerfeld belegt. '
              'Bis zehn fehlen $gap Plätze. Deshalb nehmen wir zuerst $gap '
              'von den ${step.b} neuen Äpfeln.',
          why: 'Weil im Zehnerfeld am Anfang ${step.a} Plätze belegt sind '
              'und $gap Plätze bis zehn fehlen. Jeder dieser freien Plätze '
              'bekommt einen Apfel. Deshalb nehmen wir zuerst $gap '
              'von den ${step.b} neuen Äpfeln.',
          alternativeText: 'Stell dir eine Schachtel mit zehn Plätzen vor. '
              '${step.a} sind schon besetzt. Die $gap übrigen Plätze '
              'füllen wir zuerst; der Rest bleibt daneben.',
          objectIds: freeSlots,
          keywords: const ['zuerst', 'zwei', 'freie plätze', 'zehnerfeld'],
        ));
        explanations.add(LumoReviewedTaskExplanation(
          id: 'bridge-remainder',
          stepId: stepId,
          stepNumber: 2,
          text: 'Von den ${step.b} neuen Äpfeln haben wir schon $gap '
              'in den Zehner gelegt. Es bleiben ${step.b - gap} daneben. '
              'Diese übrigen Äpfel kommen als Nächstes zum vollen Zehner dazu.',
          why: 'Die ${step.b} neuen Äpfel werden in zwei Teile aufgeteilt. '
              '$gap füllen den Zehner. Die übrigen ${step.b - gap} '
              'dürfen wir nicht vergessen und nicht doppelt zählen.',
          alternativeText: 'Decke den vollen Zehner kurz gedanklich ab. '
              'Schau nur auf die Äpfel daneben. Das ist der zweite Teil.',
          objectIds: remaining,
          keywords: const ['rest', 'übrig', 'danach', 'zweite'],
        ));
      } else {
        explanations.add(LumoReviewedTaskExplanation(
          id: 'guided-hint',
          stepId: stepId,
          stepNumber: 1,
          text: step.help(level: helpLevel + 1),
          alternativeText: helpLevel > 0 ? step.help(level: 2) : null,
          objectIds: step.answerKind == GuidedAnswerKind.remainder
              ? remaining : freeSlots,
          keywords: const ['zuerst', 'freie plätze', 'zehnerfeld'],
        ));
        if (mayNameGap) {
          explanations.add(LumoReviewedTaskExplanation(
            id: 'bridge-why',
            stepId: stepId,
            minimumHelpLevel: 1,
            text: 'Ergänze zuerst von ${step.a} bis zehn. '
                'Die freien Plätze zeigen diesen ersten Teil.',
            why: 'Von ${step.a} bis zehn fehlen $gap. '
                'Darum verwenden wir zuerst genau diesen Teil '
                'der ${step.b} neuen Äpfel.',
            alternativeText: 'Gehe von ${step.a} in einzelnen Schritten bis zehn. '
                'Zähle nur diese Schritte; den Rest zählst du danach.',
            objectIds: freeSlots,
            keywords: const ['warum', 'wieso', 'weshalb'],
          ));
        }
        explanations.add(LumoReviewedTaskExplanation(
          id: 'bridge-second-step',
          stepId: stepId,
          stepNumber: 2,
          minimumHelpLevel: 1,
          text: 'Im zweiten Schritt betrachtest du den Teil der ${step.b} '
              'Äpfel, der noch nicht im Zehner liegt. '
              'Zähle diese Äpfel dazu, ohne einen zweimal zu zählen.',
          objectIds: step.answerKind == GuidedAnswerKind.remainder
              ? remaining : const [],
          keywords: const ['rest', 'danach'],
        ));
      }
    } else if (lesson.concept == GuidedLessonConcept.syllables && step.word.isNotEmpty) {
      final segmented = demonstration || !step.isQuestion;
      if (segmented) {
        for (var i = 0; i < step.syllables.length; i++) {
          objects.add(LumoTaskDialogueObject(
            id: 'guided-spoken-syllable-$i',
            label: step.syllables[i],
            groupId: 'spoken-word',
          ));
        }
      } else {
        objects.add(LumoTaskDialogueObject(
          id: 'guided-unsegmented-word', label: step.word, groupId: 'spoken-word'));
      }
      explanations.add(LumoReviewedTaskExplanation(
        id: 'guided-syllables',
        stepId: stepId,
        stepNumber: 1,
        text: segmented
            ? '${step.syllables.join(' – ')}. Sprich jedes Sprechstück einzeln. '
                'Klatsche bei jedem Sprechstück einmal.'
            : step.help(level: helpLevel + 1),
        why: 'Bei Silben hören wir auf die Sprechstücke im Wort. '
            'Wir zählen die Klatscher beim Sprechen und nicht die Buchstaben.',
        alternativeText: segmented
            ? 'Lege zu jedem Sprechstück einen Finger auf den Tisch: '
                '${step.syllables.join(' – ')}.'
            : helpLevel > 0 ? step.help(level: 2) : null,
        objectIds: objects.map((object) => object.id).toList(growable: false),
        speechParts: segmented ? step.syllables : [step.word],
        keywords: const ['silben', 'sprechen', 'wort', 'klatschen'],
      ));
    } else {
      if (step.a > 0 && step.b == 0 && lesson.subject == 'Mathematik') {
        for (var i = 0; i < step.a; i++) {
          objects.add(LumoTaskDialogueObject(
            id: 'guided-count-apple-$i', label: 'Apfel ${i + 1}', groupId: 'count-apples'));
        }
      }
      explanations.add(LumoReviewedTaskExplanation(
        id: 'guided-hint',
        stepId: stepId,
        stepNumber: 1,
        text: step.isQuestion ? step.help(level: helpLevel + 1) : step.instruction,
        alternativeText: step.isQuestion && helpLevel > 0 ? step.help(level: 2) : null,
        objectIds: objects.map((object) => object.id).toList(growable: false),
      ));
    }

    return LumoTaskDialogueSnapshot(
      sessionId: sessionId,
      taskId: taskId,
      stepId: stepId,
      revision: revision,
      learningGoal: '${lesson.title}: ${step.title}',
      prompt: step.instruction,
      objects: objects,
      selectedObjectIds: selectedObjectIds,
      explanations: explanations,
      answerChoices: answerChoices ?? (step.isQuestion ? step.choices : const []),
      answerFormat: step.isQuestion ? LumoTaskAnswerFormat.choice : LumoTaskAnswerFormat.none,
      helpLevel: helpLevel,
      isAssessment: isAssessment,
      acceptingAnswer: acceptingAnswer ?? step.isQuestion,
      lastAnswer: lastAnswer,
      lastCorrect: lastCorrect,
    );
  }

  static LumoTaskDialogueSnapshot fromSchoolExercise({
    required LumoTask task,
    required String sessionId,
    required String taskId,
    required String stepId,
    required int revision,
    int helpLevel = 0,
    bool isAssessment = false,
    bool acceptingAnswer = true,
    List<String> selectedObjectIds = const [],
    List<LumoTaskDialogueObject>? visibleObjects,
    String? lastAnswer,
    bool? lastCorrect,
  }) {
    final objects = <LumoTaskDialogueObject>[...?visibleObjects];
    final explanations = <LumoReviewedTaskExplanation>[
      LumoReviewedTaskExplanation(
        id: 'task-hint',
        stepId: stepId,
        stepNumber: 1,
        text: const TaskHintService().explain(task, level: helpLevel + 1),
        alternativeText: helpLevel > 0 ? const TaskHintService().explain(task, level: 2) : null,
      ),
    ];

    if (task.subject == 'Logik' && task.unit.toLowerCase().contains('muster')) {
      final sequence = RegExp(
        r'(?:Kreis|Dreieck|Stern|Quadrat)(?:\s*[–—-]\s*(?:Kreis|Dreieck|Stern|Quadrat)){3,}',
        caseSensitive: false,
      ).firstMatch(task.prompt)?.group(0);
      if (sequence != null) {
        final shapes = sequence.split(RegExp(r'\s*[–—-]\s*'));
        final period = _smallestPeriod(shapes);
        if (period != null) {
          final shapeObjects = [
            for (var i = 0; i < shapes.length; i++)
              LumoTaskDialogueObject(
                id: 'task-pattern-$i',
                label: '${shapes[i]} an Stelle ${i + 1}',
                groupId: 'pattern-group-${i ~/ period}',
              ),
          ];
          if (visibleObjects == null) objects.addAll(shapeObjects);
          final ids = objects.map((object) => object.id).toSet();
          final targets = shapeObjects.take(period).map((object) => object.id).where(ids.contains).toList();
          explanations.add(LumoReviewedTaskExplanation(
            id: 'pattern-repeating-group',
            stepId: stepId,
            stepNumber: 2,
            minimumHelpLevel: 1,
            text: 'Die Gruppe „${shapes.take(period).join(' – ')}“ wiederholt sich. '
                'Vergleiche diese Gruppe mit den nächsten Formen. '
                'Überlege dann selbst, an welcher Stelle die Reihe weitergeht.',
            why: 'Nach jeweils $period Formen beginnt dieselbe Gruppe '
                'in derselben Reihenfolge erneut.',
            alternativeText: 'Decke gedanklich eine ganze Gruppe ab. '
                'Suche dieselbe Gruppe danach noch einmal in der Reihe.',
            objectIds: targets,
            keywords: const ['wiederholt', 'gruppe', 'muster'],
          ));
        }
      }
    }

    // Only explicit local word data is segmented. Guessing syllables from
    // arbitrary spelling would fabricate a learning explanation.
    if (task.unit.toLowerCase().contains('silb')) {
      final word = RegExp(r'Silben\s+hat\s+([A-Za-zÄÖÜäöüß]+)', caseSensitive: false)
          .firstMatch(task.prompt)?.group(1);
      final parts = word == null ? null : PrimarySchoolWordData.syllablesFor(word);
      if (parts != null && parts.isNotEmpty) {
        explanations.add(LumoReviewedTaskExplanation(
          id: 'task-spoken-syllables',
          stepId: stepId,
          minimumHelpLevel: 2,
          text: '${parts.join(' – ')}. Klatsche bei jedem Sprechstück einmal. '
              'Zähle deine Klatscher selbst.',
          why: 'Silben sind die Sprechstücke des Wortes. '
              'Die Zahl der Buchstaben ist etwas anderes.',
          alternativeText: 'Lege bei jedem Sprechstück einen Finger '
              'auf den Tisch: ${parts.join(' – ')}.',
          speechParts: parts,
          keywords: const ['wort', 'silben', 'sprechen'],
        ));
      }
    }
    return LumoTaskDialogueSnapshot(
      sessionId: sessionId,
      taskId: taskId,
      stepId: stepId,
      revision: revision,
      learningGoal: '${task.subject}: ${task.unit}',
      prompt: task.prompt,
      objects: objects,
      selectedObjectIds: selectedObjectIds,
      explanations: explanations,
      answerChoices: task.choices,
      answerFormat: task.handwriting
          ? LumoTaskAnswerFormat.none
          : task.choices.isNotEmpty
              ? LumoTaskAnswerFormat.choice
              : LumoTaskAnswerFormat.none,
      helpLevel: helpLevel,
      isAssessment: isAssessment,
      acceptingAnswer: acceptingAnswer,
      lastAnswer: lastAnswer,
      lastCorrect: lastCorrect,
    );
  }

  static int? _smallestPeriod(List<String> sequence) {
    for (var period = 1; period * 2 <= sequence.length; period++) {
      var repeats = true;
      for (var i = period; i < sequence.length; i++) {
        if (sequence[i].toLowerCase() != sequence[i % period].toLowerCase()) {
          repeats = false;
          break;
        }
      }
      if (repeats) return period;
    }
    return null;
  }
}
