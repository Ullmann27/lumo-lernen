import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  const adapter = LegacyLumoTaskAdapter();

  test('current repeating group is derived and checked before native launch',
      () {
    final task = adapter.toTaskInstance(
      task: const LumoTask(
        id: 'current-pattern',
        grade: 1,
        subject: 'Logik',
        unit: 'Muster',
        prompt:
            'Das Muster wiederholt sich immer gleich: Kreis – Dreieck – Kreis – Dreieck – ? Welche Form folgt?',
        answer: 'Kreis',
        choices: ['Kreis', 'Dreieck', 'Stern', 'Quadrat'],
        explanation: 'Suche die wiederkehrende Gruppe.',
      ),
      childId: 'synthetic',
      difficulty: 1,
    );
    final native = NativeLearningActivity.fromTask(task)!;
    expect(native.kind, 'pattern');
    expect(native.toLaunchOptions()['period'], 2);
    expect(native.toLaunchOptions()['sequence'],
        ['Kreis', 'Dreieck', 'Kreis', 'Dreieck']);
    expect(native.toLaunchOptions().containsKey('verifiedAnswer'), isFalse);
    expect(native.toLaunchOptions().containsKey('correctAnswer'), isFalse);
  });

  test('unsupported 100 addition does not launch a misleading 3D answer card',
      () {
    final task = adapter.toTaskInstance(
      task: const LumoTask(
        id: 'current-addition-100',
        grade: 2,
        subject: 'Mathematik',
        unit: 'Plus bis 100',
        prompt: '27 + 15 = ?',
        answer: '42',
        choices: ['42', '32', '43'],
        explanation: 'Zerlege 15 in 10 und 5.',
        visual: 'counters',
      ),
      childId: 'synthetic',
      difficulty: 1,
    );
    expect(NativeLearningActivity.fromTask(task), isNull);
    expect(NativeLearningActivity.forTask(task), isNull,
        reason: 'Flutter keeps the checked arithmetic task and its visual aids');
  });

  test('text-only specialist contexts remain in their real Flutter lesson',
      () {
    const context = LumoCompanionTaskContext(
      taskId: 'article-4',
      subject: 'Deutsch',
      unit: 'Artikel',
      prompt: 'Welcher Begleiter passt zu „Baum“?',
      localHelp: 'Sprich die Wortgruppe laut.',
      answerChoices: ['der', 'die', 'das'],
      stepId: 'answer',
    );
    expect(NativeLearningActivity.fromCompanionContext(context), isNull);
    expect(
        NativeLearningActivity.fromCompanionContext(
            const LumoCompanionTaskContext(
                taskId: 'exam-1',
                subject: 'Deutsch',
                unit: 'Artikel',
                prompt: 'Prüfungsaufgabe',
                isExam: true)),
        isNull);
  });
}
