import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_child_speech_normalizer.dart';
import 'package:lumo_lernen/core/lumo_task_dialogue.dart';
import 'package:lumo_lernen/core/lumo_task_dialogue_adapter.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';

const _engine = LumoTaskDialogueEngine();
const _normalizer = LumoChildSpeechNormalizer();

LumoTaskDialogueSnapshot _bridge({
  int revision = 1,
  List<String> selectedObjectIds = const [],
}) =>
    LumoTaskDialogueAdapter.fromGuidedLesson(
      lesson: GuidedLessonCatalog.bridgeTen,
      step: GuidedLessonCatalog.bridgeTen.steps
          .firstWhere((step) => step.type == TutoringStepType.showExample),
      sessionId: 'profile-3/learn/session-7',
      taskId: 'guided-7-3',
      stepId: 'example-8-plus-5',
      revision: revision,
      selectedObjectIds: selectedObjectIds,
      acceptingAnswer: false,
    );

LumoTaskDialogueSnapshot _answerTask({int revision = 1}) =>
    LumoTaskDialogueSnapshot(
      sessionId: 'profile-3/exercises/session-8',
      taskId: 'eight-plus-five',
      stepId: 'answer',
      revision: revision,
      learningGoal: 'Zehnerübergang',
      prompt: '8 + 5 = ?',
      answerChoices: const ['12', '13', '14'],
      lastAnswer: '12',
      lastCorrect: null,
    );

LumoTaskDialogueSnapshot _pattern({int helpLevel = 0}) =>
    LumoTaskDialogueAdapter.fromSchoolExercise(
      task: const LumoTask(
        id: 'pattern',
        grade: 1,
        subject: 'Logik',
        unit: 'Muster',
        prompt:
            'Kreis – Dreieck – Kreis – Dreieck – Kreis – ? Welche Form folgt?',
        choices: ['Kreis', 'Dreieck', 'Quadrat'],
        answer: 'Dreieck',
        explanation: 'Nicht an den Dialog geben: Die nächste Form ist Dreieck.',
      ),
      sessionId: 'profile-3/exercises/session-9',
      taskId: 'pattern',
      stepId: 'observe',
      revision: helpLevel + 1,
      helpLevel: helpLevel,
    );

void main() {
  group('reviewed task dialogue', () {
    test('8 + 5 why refers to the two actual ten-frame places', () {
      final snapshot = _bridge();
      expect(snapshot.acceptingAnswer, isFalse);
      final reply =
          _engine.respond(input: 'Warum zuerst zwei?', snapshot: snapshot);
      expect(reply.intent, LumoTaskDialogueIntent.why);
      expect(reply.text, contains('8 Plätze'));
      expect(reply.text, contains('2 Plätze'));
      expect(reply.text, contains('5 neuen Äpfeln'));
      expect(reply.targetObjectIds, ['guided-ten-slot-8', 'guided-ten-slot-9']);
      expect(reply.text, isNot(contains('abgeschlossen')));
      expect(reply.text, isNot(contains('13')));
      expect(reply.source, 'local_reviewed_dialogue');
    });

    test('second step follows the same visible 8 + 5 example', () {
      final reply = _engine.respond(
          input: 'Den zweiten Schritt verstehe ich nicht', snapshot: _bridge());
      expect(reply.intent, LumoTaskDialogueIntent.step);
      expect(reply.text, contains('5 neuen Äpfeln'));
      expect(reply.text, contains('bleiben 3 daneben'));
      expect(reply.targetObjectIds, [
        'guided-bridge-apple-10',
        'guided-bridge-apple-11',
        'guided-bridge-apple-12'
      ]);
    });

    test('why, alternative, repeat form distinct grounded turns', () {
      final snapshot = _bridge();
      final why = _engine.respond(input: 'Warum?', snapshot: snapshot);
      final alternative = _engine.respond(
          input: 'Bitte anders erklären',
          snapshot: snapshot,
          previousReply: why);
      expect(alternative.intent, LumoTaskDialogueIntent.alternative);
      expect(alternative.text, contains('Schachtel mit zehn Plätzen'));
      expect(alternative.text, isNot(why.text));
      final repeat = _engine.respond(
          input: 'Noch einmal', snapshot: snapshot, previousReply: alternative);
      expect(repeat.text, alternative.text);
      expect(repeat.targetObjectIds, alternative.targetObjectIds);
    });

    test('misheard number and correction are ungraded drafts', () {
      final snapshot = _answerTask();
      final initial = _engine.respond(input: 'zwölf', snapshot: snapshot);
      expect(initial.draftAnswer, '12');
      expect(initial.needsConfirmation, isTrue);
      final correction = _engine.respond(
          input: 'Nein, ich meinte dreizehn',
          snapshot: snapshot,
          previousReply: initial);
      expect(correction.intent, LumoTaskDialogueIntent.correction);
      expect(correction.draftAnswer, '13');
      expect(correction.needsConfirmation, isTrue);
      expect(snapshot.lastAnswer, '12');
      expect(snapshot.lastCorrect, isNull);
      expect(correction.text, isNot(contains('falsch')));
    });

    test('uncertain and partial speech cannot become a learning error', () {
      for (final reply in [
        _engine.respond(
            input: 'dreizehn', snapshot: _answerTask(), isFinal: false),
        _engine.respond(
            input: 'dreizehn',
            snapshot: _answerTask(),
            recognitionConfidence: .3),
        _engine.respond(
            input: 'dreizehn',
            snapshot: _answerTask(),
            recognitionConfidence: double.nan),
        _engine.respond(input: 'zwölf oder dreizehn', snapshot: _answerTask()),
      ]) {
        expect(reply.draftAnswer, isNull);
        expect(reply.text, isNot(contains('falsch')));
      }
    });

    test('Banane repeat and slower keep the visible syllable segmentation', () {
      const lesson = GuidedLessonCatalog.syllables;
      final snapshot = LumoTaskDialogueAdapter.fromGuidedLesson(
          lesson: lesson,
          step: lesson.steps.firstWhere((step) => step.word == 'Banane'),
          sessionId: 'read-2',
          taskId: 'banana',
          stepId: 'demonstration',
          revision: 1);
      final initial =
          _engine.respond(input: 'Zeig mir das', snapshot: snapshot);
      final repeat = _engine.respond(
          input: 'Noch einmal', snapshot: snapshot, previousReply: initial);
      final slow = _engine.respond(
          input: 'Langsamer', snapshot: snapshot, previousReply: repeat);
      expect(slow.text, contains('Ba – na – ne'));
      expect(slow.speechParts, ['Ba', 'na', 'ne']);
      expect(slow.targetObjectIds, [
        'guided-spoken-syllable-0',
        'guided-spoken-syllable-1',
        'guided-spoken-syllable-2'
      ]);
      expect(slow.speechRateMultiplier, .75);
      expect(slow.text, repeat.text);
    });

    test('stopping and working alone are explicit cancellation commands', () {
      final stop =
          _engine.respond(input: 'Stopp', snapshot: _bridge(), isFinal: false);
      expect(stop.intent, LumoTaskDialogueIntent.stop);
      expect(stop.shouldStopSpeech, isTrue);
      expect(stop.continueListening, isTrue);
      expect(stop.targetObjectIds, isEmpty);
      final alone = _engine.respond(
          input: 'Ich möchte es allein versuchen', snapshot: _bridge());
      expect(alone.shouldStopSpeech, isTrue);
      expect(alone.continueListening, isFalse);
      expect(alone.draftAnswer, isNull);
    });

    test('a negated stop request is not treated as a stop', () {
      final reply =
          _engine.respond(input: 'Nicht stoppen', snapshot: _bridge());
      expect(reply.shouldStopSpeech, isFalse);
    });

    test('previous reply cannot cross a context revision or another task', () {
      final old = _engine.respond(input: 'Warum?', snapshot: _bridge());
      final current = LumoTaskDialogueSnapshot(
          sessionId: 'profile-3/learn/session-7',
          taskId: 'new-task',
          stepId: 'new-step',
          revision: 2,
          learningGoal: 'Neues Ziel',
          prompt: 'Neuer Text',
          explanations: [
            LumoReviewedTaskExplanation(id: 'new', text: 'Neue geprüfte Hilfe.')
          ]);
      final repeat = _engine.respond(
          input: 'Noch einmal', snapshot: current, previousReply: old);
      expect(repeat.text, 'Neue geprüfte Hilfe.');
      expect(repeat.targetObjectIds, isEmpty);
      expect(repeat.revision, 2);
      expect(current.containsReply(old), isFalse);
      expect(_bridge(revision: 2).containsReply(old), isFalse);
    });

    test('forged repeat text is not validated by matching identifiers alone',
        () {
      final snapshot = _bridge();
      final unreviewed = LumoTaskDialogueReply(
          sessionId: snapshot.sessionId,
          taskId: snapshot.taskId,
          stepId: snapshot.stepId,
          revision: snapshot.revision,
          text: '8 + 5 ist 29.',
          intent: LumoTaskDialogueIntent.help,
          explanationId: 'bridge-fill-ten');
      final repeat = _engine.respond(
          input: 'Noch einmal', snapshot: snapshot, previousReply: unreviewed);
      expect(repeat.text, isNot(contains('29')));
      expect(repeat.text, snapshot.explanations.first.text);
    });

    test('pattern explanation respects approved hint level without next answer',
        () {
      final early =
          _engine.respond(input: 'Was wiederholt sich?', snapshot: _pattern());
      expect(early.text, isNot(contains('Kreis – Dreieck')));
      final allowed = _engine.respond(
          input: 'Was wiederholt sich?', snapshot: _pattern(helpLevel: 1));
      expect(allowed.text, contains('Gruppe „Kreis – Dreieck“'));
      expect(allowed.targetObjectIds, ['task-pattern-0', 'task-pattern-1']);
      expect(allowed.text, isNot(contains('nächste Form ist Dreieck')));
      expect(allowed.text, isNot(contains('kommt Dreieck')));
      expect(allowed.draftAnswer, isNull);
    });

    test('request for a locked step does not expose its contents', () {
      final reply = _engine.respond(
          input: 'Erklär den zweiten Schritt', snapshot: _pattern());
      expect(reply.intent, LumoTaskDialogueIntent.clarification);
      expect(reply.text, isNot(contains('Kreis – Dreieck')));
    });

    test('ambiguous two-there asks; two selected objects resolve', () {
      final ambiguous =
          _engine.respond(input: 'Die zwei da', snapshot: _bridge());
      expect(ambiguous.intent, LumoTaskDialogueIntent.clarification);
      expect(ambiguous.targetObjectIds, isEmpty);
      expect(ambiguous.text, contains('Plätze im Zehnerfeld oder Äpfel'));
      expect(ambiguous.text.toLowerCase(), isNot(contains('tipp')));
      final selected = _engine.respond(
          input: 'Die zwei da',
          snapshot: _bridge(
              selectedObjectIds: ['guided-ten-slot-8', 'guided-ten-slot-9']));
      expect(selected.intent, LumoTaskDialogueIntent.reference);
      expect(selected.text,
          contains('Platz 9 im Zehnerfeld und Platz 10 im Zehnerfeld'));
      expect(
          selected.targetObjectIds, ['guided-ten-slot-8', 'guided-ten-slot-9']);
    });

    test(
        'spoken object labels resolve the reference clarification without taps',
        () {
      final snapshot = _bridge();
      final clarification =
          _engine.respond(input: 'Die zwei da', snapshot: snapshot);
      final described = _engine.respond(
          input: 'Platz neun im Zehnerfeld und Platz zehn im Zehnerfeld',
          snapshot: snapshot,
          previousReply: clarification);
      expect(described.intent, LumoTaskDialogueIntent.reference);
      expect(described.targetObjectIds,
          ['guided-ten-slot-8', 'guided-ten-slot-9']);
      expect(described.draftAnswer, isNull);
    });

    test(
        'no object context never promises an object tap or invents its objects',
        () {
      final snapshot = LumoTaskDialogueSnapshot(
          sessionId: 's',
          taskId: 't',
          stepId: 'step',
          revision: 1,
          learningGoal: 'Lesen',
          prompt: 'Lies den Text');
      final reply = _engine.respond(input: 'Die zwei da', snapshot: snapshot);
      expect(reply.intent, LumoTaskDialogueIntent.clarification);
      expect(reply.text.toLowerCase(), isNot(contains('tipp')));
      expect(reply.text, isNot(contains('Zehnerfeld')));
      expect(reply.text, isNot(contains('Äpfel')));
      expect(reply.targetObjectIds, isEmpty);
    });

    test('an explanation for a missing object or wrong step is refused', () {
      final snapshot = LumoTaskDialogueSnapshot(
          sessionId: 's',
          taskId: 't',
          stepId: 'current',
          revision: 1,
          learningGoal: 'Zählen',
          prompt: 'Zähle',
          explanations: [
            LumoReviewedTaskExplanation(
                id: 'missing',
                text: 'Dieser Fuchs zählt.',
                objectIds: ['missing-fox']),
            LumoReviewedTaskExplanation(
                id: 'wrong-step', text: 'Alte Erklärung.', stepId: 'old'),
          ]);
      final reply = _engine.respond(input: 'Warum?', snapshot: snapshot);
      expect(reply.intent, LumoTaskDialogueIntent.clarification);
      expect(reply.targetObjectIds, isEmpty);
    });

    test('a short outside-task question falls through without invented context',
        () {
      final reply =
          _engine.respond(input: 'Warum fliegen Bienen?', snapshot: _bridge());
      expect(reply.handled, isFalse);
      expect(reply.text, isEmpty);
    });

    test('assessment refuses hints while stop remains reachable', () {
      final task = LumoTaskDialogueSnapshot(
          sessionId: 's',
          taskId: 't',
          stepId: 'test',
          revision: 1,
          learningGoal: 'Test',
          prompt: '8 + 5',
          isAssessment: true,
          explanations: [
            LumoReviewedTaskExplanation(id: 'secret', text: 'Gehe zur 13.')
          ]);
      final reply = _engine.respond(input: 'Warum?', snapshot: task);
      expect(reply.text, contains('Im Test'));
      expect(reply.text, isNot(contains('13')));
      expect(_engine.respond(input: 'Stopp', snapshot: task).shouldStopSpeech,
          isTrue);
    });

    test(
        'child concerns direct to a trusted adult without conversation rewards',
        () {
      final reply =
          _engine.respond(input: 'Jemand tut mir weh', snapshot: _bridge());
      expect(reply.intent, LumoTaskDialogueIntent.concern);
      expect(reply.text, contains('erwachsenen Person'));
      expect(reply.text, contains('digitale Figur'));
      expect(reply.draftAnswer, isNull);
    });

    test('snapshot and explanation collections are detached from caller lists',
        () {
      final ids = <String>['one'];
      final explanation = LumoReviewedTaskExplanation(
          id: 'e', text: 'Ein Objekt.', objectIds: ids);
      final objects = <LumoTaskDialogueObject>[
        const LumoTaskDialogueObject(id: 'one', label: 'Objekt')
      ];
      final snapshot = LumoTaskDialogueSnapshot(
          sessionId: 's',
          taskId: 't',
          stepId: 'step',
          revision: 1,
          learningGoal: 'Zählen',
          prompt: 'Zähle',
          objects: objects,
          explanations: [explanation]);
      ids.clear();
      objects.clear();
      expect(snapshot.objects.length, 1);
      expect(snapshot.explanations.single.objectIds, ['one']);
      expect(() => snapshot.objects.clear(), throwsUnsupportedError);
    });
  });

  group('speech corrections and ambiguity', () {
    test('correction is independent of the displayed choice order', () {
      for (final choices in [
        const ['12', '13', '14'],
        const ['13', '14', '12']
      ]) {
        for (final input in [
          'Nicht zwölf, sondern dreizehn',
          'zwölf, nein, dreizehn',
          'Ich meinte dreizehn'
        ]) {
          final match =
              _normalizer.normalizeAnswer(spokenText: input, choices: choices);
          expect(match.matchedChoice, '13', reason: input);
          expect(match.needsConfirmation, isTrue);
        }
      }
    });

    test('negation and multiple candidates do not select the first choice', () {
      for (final input in [
        'Nicht dreizehn',
        'zwölf oder dreizehn',
        'zwölf dreizehn',
        'dreizehn, nein',
        'zwölf plus eins',
        '-13'
      ]) {
        final match = _normalizer
            .normalizeAnswer(spokenText: input, choices: ['12', '13', '1']);
        expect(match.hasMatch, isFalse, reason: input);
        expect(match.needsConfirmation, isTrue);
      }
    });

    test('equal partial word candidates remain ambiguous', () {
      final match = _normalizer.normalizeAnswer(
          spokenText: 'ban', choices: ['Banane', 'Bank', 'Maus']);
      expect(match.hasMatch, isFalse);
      expect(match.needsConfirmation, isTrue);
    });

    test('a complete multiword choice is preserved', () {
      final match = _normalizer.normalizeAnswer(
          spokenText: 'Ich meine das rote Dreieck',
          choices: ['das rote Dreieck', 'der blaue Kreis']);
      expect(match.matchedChoice, 'das rote Dreieck');
      expect(match.needsConfirmation, isTrue);
    });

    test('partial recognizer result and low confidence cannot select a choice',
        () {
      for (final match in [
        _normalizer.normalizeAnswer(
            spokenText: 'dreizehn', choices: ['13'], isFinal: false),
        _normalizer.normalizeAnswer(
            spokenText: 'dreizehn', choices: ['13'], recognitionConfidence: .2),
      ]) {
        expect(match.hasMatch, isFalse);
        expect(match.needsConfirmation, isTrue);
      }
    });
  });
}
