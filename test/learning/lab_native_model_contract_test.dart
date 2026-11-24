import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  const kinds = <LabMode, String>{
    LabMode.bridge: 'bridge_ten',
    LabMode.word: 'syllables',
    LabMode.english: 'english_objects',
    LabMode.nature: 'plant_parts',
    LabMode.fraction: 'fraction_parts',
    LabMode.pattern: 'pattern',
  };

  test('every reviewed Lab problem has a meaningful native object', () {
    for (final topic in LabCatalog.topics) {
      for (final problem in topic.problems) {
        expect(problem.isValid, isTrue, reason: problem.id);
        final activity = NativeLearningActivity.fromLabProblem(
          problem,
          visiblePrompt: problem.prompt,
        );
        expect(activity, isNotNull, reason: problem.id);
        expect(activity!.kind, kinds[problem.mode], reason: problem.id);
        final payload = activity.toLaunchOptions();
        expect(payload['kind'], kinds[problem.mode]);
        expect(payload['prompt'], problem.prompt);
        expect(payload['sourceTaskId'], problem.id);
        expect(payload.containsKey('correctAnswer'), isFalse);
        expect(payload.containsKey('reward'), isFalse);
        expect(payload.containsKey('childId'), isFalse);
        final guided = NativeLearningActivity.fromLabProblem(
          problem,
          visiblePrompt: problem.guidedPrompt,
        );
        expect(guided, isNotNull, reason: problem.id);
        expect(guided!.kind, kinds[problem.mode]);
        expect(guided.toLaunchOptions()['prompt'], problem.guidedPrompt);
      }
    }
  });

  test('English lab uses checked local animals or real school objects', () {
    final topic =
        LabCatalog.topics.firstWhere((t) => t.mode == LabMode.english);
    for (final problem in topic.problems) {
      final payload = NativeLearningActivity.fromLabProblem(
        problem,
        visiblePrompt: problem.prompt,
      )!.toLaunchOptions();
      final objects = payload['objects'] as List<String>;
      expect(objects.length, 3);
      expect(objects.toSet().length, 3);
      expect(objects, contains(problem.expected));
      expect(payload['meaning'], isNotEmpty);
    }
  });

  test('arbitrary lesson text cannot smuggle an unrelated 3D board', () {
    final reviewed = LabCatalog.topics.first.problems.first;
    expect(
        NativeLearningActivity.fromLabProblem(
          reviewed,
          visiblePrompt: 'Nicht die echte Aufgabe',
        ),
        isNull);
    const falseAnswer = LabProblem(
      id: 'bridge-8-5',
      mode: LabMode.bridge,
      start: 8,
      addend: 5,
      modelTarget: 2,
      prompt: '8 + 5 = ?',
      guidedPrompt: '8 + 5',
      expected: '999',
      workedExample: 'Falsch',
      hints: ['a', 'b', 'c', 'd', 'e'],
      reflection: 'Falsch',
    );
    expect(
        NativeLearningActivity.fromLabProblem(
          falseAnswer,
          visiblePrompt: falseAnswer.prompt,
        ),
        isNull);
    const textOnly = LumoCompanionTaskContext(
      subject: 'Deutsch',
      unit: 'Lesen',
      prompt: 'Wie heißt das Wort?',
    );
    expect(NativeLearningActivity.fromCompanionContext(textOnly), isNull);
  });
}
