import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_companion_engine.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_hint_service.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

LumoTask arithmetic(String prompt) => LumoTask(
      id: 'visible-task',
      grade: 1,
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      prompt: prompt,
      answer: '',
      choices: const [],
      explanation: '',
    );

void main() {
  const hints = TaskHintService();
  test('third help uses the actual ten bridge without supplying the result',
      () {
    final text = hints.explain(arithmetic('7 + 5 = ?'), level: 3);
    expect(text, contains('Von 7 bis 10 fehlen 3'));
    expect(text, contains('3 und 2'));
    expect(text, isNot(contains('12')));
  });
  test('subtraction bridge takes away exactly the requested quantity', () {
    final text = hints.explain(arithmetic('12 − 5 = ?'), level: 3);
    expect(text, contains('2 Schritte bis 10'));
    expect(text, contains('noch 3'));
    expect(text, isNot(contains('Ergebnis ist 7')));
  });
  test('counting strategy understands a visible expression without equals', () {
    expect(hints.explain(arithmetic('Rechne 7 + 5.'), level: 2),
        startsWith('Starte bei 7. Zähle 5 weiter.'));
  });
  test('repeated wrong answers change the unchanged local explanation', () {
    final app = LumoSessionState();
    LumoReply ask(int attempts) => const LumoCompanionEngine().answer(
          input: 'Kannst du es noch einmal erklären?',
          state: app,
          task: LumoCompanionTaskContext(
            subject: 'Mathematik',
            unit: 'Plus bis 20',
            prompt: '7 + 5 = ?',
            taskId: 'same-visible-task',
            attempts: attempts,
            helpLevel: 1,
            lastAnswer: '11',
            lastCorrect: false,
            previousHelp: 'Zähle beide Mengen zusammen.',
            localHelp: 'Zähle beide Mengen zusammen.',
          ),
        );
    expect(ask(2).text, contains('Starte bei 7'));
    expect(ask(3).text, contains('Von 7 bis 10 fehlen 3'));
    expect(ask(3).text, isNot(contains('12')));
  });
  test('hundred boundary decomposes the actual second quantity', () {
    final text = hints.explain(arithmetic('97 + 8 = ?'), level: 3);
    expect(text, contains('Von 97 bis 100 fehlen 3'));
    expect(text, contains('3 und 5'));
    expect(text, isNot(contains('105')));
  });
  test('a fraction without equals is not misread as integer addition', () {
    final text = hints.explain(arithmetic('Rechne 1/4 + 3/4.'), level: 2);
    expect(text, isNot(contains('Starte bei 4')));
  });
  test('a new module-specific explanation is retained', () {
    final reply = const LumoCompanionEngine().answer(
      input: 'Hilf mir',
      state: LumoSessionState(),
      task: const LumoCompanionTaskContext(
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        prompt: '7 + 5 = ?',
        attempts: 3,
        lastCorrect: false,
        previousHelp: 'Zähle beide Mengen zusammen.',
        localHelp: 'Tippe erst auf die drei freien Plätze im Zehnerfeld.',
      ),
    );
    expect(reply.text, contains('drei freien Plätze'));
  });
}
