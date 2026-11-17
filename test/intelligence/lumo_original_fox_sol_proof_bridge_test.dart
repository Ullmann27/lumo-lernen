import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';
import 'package:lumo_lernen/features/learning/scenes/learning_scene_contract.dart';
import 'package:lumo_lernen/features/learning/scenes/place_value/place_value_scene_director.dart';

void send(PlaceValueSceneDirector director, LearningSceneInput input,
    {String? objectId, int? value}) {
  final scene = director.request;
  expect(scene.allows(input), isTrue);
  expect(director.handle(LearningSceneEvent(
    sceneId: scene.sceneId,
    revision: scene.revision,
    input: input,
    objectId: objectId,
    value: value,
  )), isTrue);
}

void build(PlaceValueSceneDirector director, {int tens = 5, int ones = 7}) {
  for (var i = 0; i < 8; i++) {
    send(director, LearningSceneInput.countObject, objectId: 'ten-$i');
  }
  send(director, LearningSceneInput.startConstruction);
  for (var i = 0; i < tens; i++) {
    send(director, LearningSceneInput.addTen);
  }
  for (var i = 0; i < ones; i++) {
    send(director, LearningSceneInput.addOne);
  }
  send(director, LearningSceneInput.submitConstruction);
}

void main() {
  test('animated original Lumo returns only Sol-issued scoped completion proof',
      () {
    final lesson = PlaceValueLessonSession(
      sourceNumber: 84,
      targetNumber: 57,
      sourceProblemId: 'problem-84',
      sourceTaskId: 'task-84',
      generation: 8,
    );
    final results = <LumoPlaceValueTransfer>[];
    final director = PlaceValueSceneDirector(
      number: 84,
      lesson: lesson,
      onTransferChecked: results.add,
    );
    build(director);
    expect(director.request.stage, LearningSceneStage.explain);
    expect(results, isEmpty);
    send(director, LearningSceneInput.answerChoice, value: 7);
    expect(results, hasLength(1));
    final proof = results.single.proof;
    expect(proof, isNotNull);
    expect(proof!.sourceTaskId, 'task-84');
    expect(proof.sourceProblemId, 'problem-84');
    expect(proof.generation, 8);
    expect(proof.independent, isTrue);
    expect(results.single.independent, isTrue);
    expect(lesson.stage, TransferStage.completed);
    expect(director.request.lumo, LumoPerformanceIntent.celebrate);
    director.dispose();
  });

  test('a corrected construction cannot become independent because of animation',
      () {
    final lesson = PlaceValueLessonSession(
      sourceNumber: 84,
      targetNumber: 57,
      sourceProblemId: 'problem-84',
    );
    final results = <LumoPlaceValueTransfer>[];
    final director = PlaceValueSceneDirector(
      number: 84,
      lesson: lesson,
      onTransferChecked: results.add,
    );
    build(director, tens: 4);
    expect(results, isEmpty);
    expect(director.request.stage, LearningSceneStage.construct);
    send(director, LearningSceneInput.addTen);
    send(director, LearningSceneInput.submitConstruction);
    send(director, LearningSceneInput.answerChoice, value: 7);
    expect(results.single.proof, isNotNull);
    expect(results.single.proof!.independent, isFalse);
    expect(director.request.lumo, LumoPerformanceIntent.encourage);
    director.dispose();
  });

  test('demonstration never creates a learning receipt', () {
    final lesson = PlaceValueLessonSession(
      sourceNumber: 84, targetNumber: 57, sourceProblemId: 'problem-84');
    final results = <LumoPlaceValueTransfer>[];
    final director = PlaceValueSceneDirector(
        number: 84, lesson: lesson, onTransferChecked: results.add);
    send(director, LearningSceneInput.startBundling);
    send(director, LearningSceneInput.replayDemonstration);
    expect(results, isEmpty);
    expect(lesson.stage, TransferStage.explanation);
    director.dispose();
  });

  test('source number mismatch never joins two task scopes', () {
    final foreign = PlaceValueLessonSession(
      sourceNumber: 57, targetNumber: 84, sourceProblemId: 'other-child');
    expect(() => PlaceValueSceneDirector(number: 84, lesson: foreign),
        throwsArgumentError);
  });

  test('assisted transfer remains assisted even when visually perfect', () {
    final lesson = PlaceValueLessonSession(
      sourceNumber: 84, targetNumber: 57, sourceProblemId: 'p84');
    final results = <LumoPlaceValueTransfer>[];
    final director = PlaceValueSceneDirector(
        number: 84, lesson: lesson, onTransferChecked: results.add);
    build(director);
    lesson.markTransferHelp();
    send(director, LearningSceneInput.answerChoice, value: 7);
    expect(results.single.proof?.independent, isFalse);
    director.dispose();
  });
}
