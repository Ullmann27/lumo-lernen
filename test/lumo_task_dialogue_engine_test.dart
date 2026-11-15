import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_task_dialogue_engine.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  const engine = LumoTaskDialogueEngine();

  LumoCompanionTaskContext task({
    String prompt = 'Rechne 8 + 5.',
    String unit = 'Zehnerübergang',
    String? help = 'Im Zehnerfeld sind acht Punkte besetzt.',
    int level = 1,
    bool exam = false,
    bool answering = true,
    int attempts = 0,
  }) =>
      LumoCompanionTaskContext(
        subject: 'Mathematik',
        unit: unit,
        prompt: prompt,
        taskId: 'chat4-fixture',
        helpLevel: level,
        attempts: attempts,
        localHelp: help,
        isExam: exam,
        answering: answering,
      );

  test('8+5: reason for two visible free ten-frame slots', () {
    final decision = engine.respond(
      input: 'Warum zuerst zwei?',
      task: task(),
    );
    expect(decision, isNotNull);
    expect(decision!.text, contains('zwei Plätze frei'));
    expect(decision.text, contains('fünf'));
    expect(decision.focus, 'ten-frame');
    expect(decision.text, isNot(contains('dreizehn')));
  });

  test('8+5: second step is tied to remaining three, no direct solution', () {
    final decision = engine.respond(
        input: 'Den zweiten Schritt verstehe ich nicht', task: task());
    expect(decision!.text, contains('drei'));
    expect(decision.text, contains('zweiten Schritt'));
    expect(decision.text, isNot(contains('dreizehn')));
  });

  test('8+5: different explanation remains at hint stage', () {
    final decision =
        engine.respond(input: 'Kannst du es anders erklären?', task: task());
    expect(decision!.text, contains('zehn freie Plätze'));
    expect(decision.text, isNot(contains('dreizehn')));
  });

  test('speech correction is confirmation, not a graded answer', () {
    final before = task(attempts: 2);
    final decision =
        engine.respond(input: 'Nein, ich meinte dreizehn', task: before);
    expect(decision!.action, LumoTaskDialogueAction.correction);
    expect(decision.text, contains('dreizehn'));
    expect(decision.text, contains('bestätigen'));
    expect(before.attempts, 2);
    expect(before.lastCorrect, isNull);
  });

  test('syllables Ba-na-ne: locally verified spelling plus replay', () {
    final banana = task(
        prompt: 'Wie viele Silben hat Banane?',
        unit: 'Silben lesen',
        help: 'Sprich das Wort in Silben.');
    final replay = engine.respond(
        input: 'Noch einmal', task: banana);
    final slower = engine.respond(
        input: 'Langsamer bitte', task: banana);
    expect(replay!.action, LumoTaskDialogueAction.replay);
    expect(slower!.action, LumoTaskDialogueAction.slower);
    expect(replay.subtitle, 'Ba · na · ne');
    expect(slower.subtitle, replay.subtitle);
    expect(slower.text, contains('Ba. na. ne'));
    expect(slower.focus, 'syllables');
  });

  test('stopp applies even when task context is missing', () {
    final stop = engine.respond(input: 'Stopp', task: null);
    expect(stop!.action, LumoTaskDialogueAction.stop);
    expect(stop.text, isEmpty);
  });

  test('pattern: low hint does not reveal repeating pair', () {
    final shapes = task(
        unit: 'Muster',
        prompt: 'Kreis – Dreieck – Kreis – Dreieck – Kreis. Was folgt?',
        help: 'Vergleiche die Formen.',
        level: 1);
    final response =
        engine.respond(input: 'Was wiederholt sich?', task: shapes);
    expect(response!.focus, 'pattern');
    expect(response.text, contains('erste und die dritte'));
    expect(response.text, isNot(contains('Gruppe Kreis, Dreieck')));
    final approved = engine.respond(
        input: 'Was wiederholt sich?',
        task: task(
            unit: 'Muster',
            prompt: shapes.prompt,
            help: shapes.localHelp,
            level: 2));
    expect(approved!.text, contains('Gruppe Kreis, Dreieck'));
  });

  test('ambiguous selection asks which objects', () {
    final answer =
        engine.respond(input: 'Zeig mir die zwei da', task: task());
    expect(answer!.action, LumoTaskDialogueAction.clarify);
    expect(answer.text, contains('Welche zwei'));
  });

  test('child requests independent work without further help', () {
    final answer = engine.respond(
        input: 'Ich möchte es allein versuchen', task: task());
    expect(answer!.action, LumoTaskDialogueAction.independent);
    expect(answer.text, contains('keinen weiteren Tipp'));
  });

  test('exam never leaks an answer or a step', () {
    final answer = engine.respond(
        input: 'Warum zuerst zwei?', task: task(exam: true));
    expect(answer!.text, contains('Im Test'));
    expect(answer.text, isNot(contains('zwei Plätze')));
  });

  test('finished task never continues its explanation', () {
    final answer = engine.respond(
        input: 'Noch einmal', task: task(answering: false));
    expect(answer!.text, contains('schon beendet'));
  });

  test('unrecognised input remains explicitly unhandled', () {
    expect(engine.respond(input: 'Wer hat Geburtstag?', task: task()), isNull);
    expect(engine.respond(input: 'Warum?', task: null), isNull);
  });
}
