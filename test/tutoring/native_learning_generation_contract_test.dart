import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  const adapter = LegacyLumoTaskAdapter();

  test('current repeating group is derived and checked before native launch', () {
    final task = adapter.toTaskInstance(
      task: const LumoTask(
        id: 'current-pattern', grade: 1, subject: 'Logik', unit: 'Muster',
        prompt: 'Das Muster wiederholt sich immer gleich: Kreis – Dreieck – Kreis – Dreieck – ? Welche Form folgt?',
        answer: 'Kreis', choices: ['Kreis', 'Dreieck', 'Stern', 'Quadrat'],
        explanation: 'Suche die wiederkehrende Gruppe.',
      ),
      childId: 'synthetic', difficulty: 1,
    );
    final native = NativeLearningActivity.fromTask(task)!;
    expect(native.kind, 'pattern');
    expect(native.toLaunchOptions()['patternUnit'], ['circle', 'triangle']);
    expect(native.toLaunchOptions()['patternSequence'],
        ['circle', 'triangle', 'circle', 'triangle']);
    expect(native.toLaunchOptions().containsKey('verifiedAnswer'), isFalse);
    expect(native.toLaunchOptions().containsKey('correctAnswer'), isFalse);
  });

  test('checked non-specialised task receives a 3D card with original choices', () {
    final task = adapter.toTaskInstance(
      task: const LumoTask(
        id: 'current-addition-100', grade: 2, subject: 'Mathematik',
        unit: 'Plus bis 100', prompt: '27 + 15 = ?', answer: '42',
        choices: ['42', '32', '43'], explanation: 'Zerlege 15 in 10 und 5.',
        visual: 'counters',
      ),
      childId: 'synthetic', difficulty: 1,
    );
    expect(NativeLearningActivity.fromTask(task), isNull);
    final card = NativeLearningActivity.forTask(task).toLaunchOptions();
    expect(card['kind'], 'task_card');
    expect(card['prompt'], task.prompt);
    expect(card['answerChoices'], ['42', '32', '43']);
    expect(card['sourceTaskId'], task.taskInstanceId);
    expect(card.keys, isNot(contains('correctAnswer')));
    expect(card.keys, isNot(contains('childId')));
    expect(card.keys, isNot(contains('reward')));
  });

  test('specialist context uses its permitted hint and keeps assessment closed', () {
    const context = LumoCompanionTaskContext(
      taskId: 'article-4', subject: 'Deutsch', unit: 'Artikel',
      prompt: 'Welcher Begleiter passt zu „Baum“?',
      localHelp: 'Sprich die Wortgruppe laut.',
      answerChoices: ['der', 'die', 'das'], stepId: 'answer',
    );
    final card = NativeLearningActivity.fromCompanionContext(context)!;
    expect(card.toLaunchOptions()['explanation'], context.localHelp);
    expect(card.toLaunchOptions()['stepId'], 'answer');
    expect(card.toLaunchOptions()['answerChoices'], ['der', 'die', 'das']);
    expect(NativeLearningActivity.fromCompanionContext(
      const LumoCompanionTaskContext(taskId: 'exam-1', subject: 'Deutsch',
          unit: 'Artikel', prompt: 'Prüfungsaufgabe', isExam: true)), isNull);
    expect(NativeLearningActivity.fromCompanionContext(
      const LumoCompanionTaskContext(subject: 'Deutsch', unit: 'Artikel',
          prompt: 'Noch keine stabile Aufgabe')), isNull);
  });
}
