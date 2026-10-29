import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/scenes/learning_scene_contract.dart';
import 'package:lumo_lernen/features/learning/scenes/place_value/place_value_scene_director.dart';

void main() {
  late PlaceValueSceneDirector director;
  late List<LumoPlaceValueTransfer> results;

  bool send(LearningSceneInput input,
          {String? id, int? value, int? revision}) =>
      director.handle(LearningSceneEvent(
          sceneId: director.sceneId,
          revision: revision ?? director.request.revision,
          input: input,
          objectId: id,
          value: value));

  setUp(() {
    results = [];
    director =
        PlaceValueSceneDirector(number: 84, onTransferChecked: results.add);
  });
  tearDown(() => director.dispose());

  test('84 is shown as eight rods and four ones; nothing is scored yet', () {
    final scene = director.request;
    expect(scene.stage, LearningSceneStage.explore);
    expect(scene.objects.where((o) => o.type == 'ten_rod'), hasLength(8));
    expect(scene.objects.where((o) => o.type == 'unit_cube'), hasLength(4));
    expect(scene.facts.containsKey('target'), isFalse);
    expect(scene.allows(LearningSceneInput.startConstruction), isFalse);
    expect(results, isEmpty);
  });

  test('a stale or forbidden action changes nothing', () {
    expect(send(LearningSceneInput.countObject, id: 'ten-0', revision: 99),
        isFalse);
    expect(send(LearningSceneInput.bundleTen), isFalse);
    expect(send(LearningSceneInput.countObject, id: 'ten-8'), isFalse);
    expect(send(LearningSceneInput.answerChoice, value: 4), isFalse);
    expect(director.request.revision, 0);
  });

  test('counting toggles; all eight rods unlock building, never a score', () {
    send(LearningSceneInput.countObject, id: 'ten-2');
    send(LearningSceneInput.countObject, id: 'ten-2');
    expect(director.request.fact('counted'), 0);
    for (var i = 0; i < 8; i++) {
      send(LearningSceneInput.countObject, id: 'ten-$i');
    }
    expect(director.request.fact('counted'), 8);
    expect(director.request.lumo, LumoPerformanceIntent.approve);
    expect(
        director.request.allows(LearningSceneInput.startConstruction), isTrue);
    expect(results, isEmpty);
  });

  test('bundling needs exactly ten loose cubes and conserves the number', () {
    send(LearningSceneInput.startBundling);
    var scene = director.request;
    expect(scene.objects.where((o) => o.type == 'ten_rod'), hasLength(7));
    expect(scene.objects.where((o) => o.type == 'unit_cube'), hasLength(14));
    for (var i = 0; i < 9; i++) {
      send(LearningSceneInput.selectObject, id: 'loose-$i');
    }
    expect(director.request.allows(LearningSceneInput.bundleTen), isFalse);
    send(LearningSceneInput.selectObject, id: 'loose-13');
    expect(send(LearningSceneInput.bundleTen), isTrue);
    scene = director.request;
    expect(scene.instruction, contains('8 Zehner und 4 Einer'));
    expect(scene.objects.where((o) => o.type == 'ten_rod'), hasLength(8));
    expect(results, isEmpty);
  });

  test('Lumo may demonstrate bundling without any effect on the result', () {
    send(LearningSceneInput.startBundling);
    send(LearningSceneInput.replayDemonstration);
    expect(director.request.lumo, LumoPerformanceIntent.demonstrate);
    expect(director.request.fact('demonstrations'), 1);
    for (var i = 0; i < 10; i++) {
      send(LearningSceneInput.selectObject, id: 'loose-$i');
    }
    send(LearningSceneInput.bundleTen);
    send(LearningSceneInput.startConstruction);
    for (var i = 0; i < 5; i++) {
      send(LearningSceneInput.addTen);
    }
    for (var i = 0; i < 7; i++) {
      send(LearningSceneInput.addOne);
    }
    send(LearningSceneInput.submitConstruction);
    send(LearningSceneInput.answerChoice, value: 7);
    expect(results.single.independent, isTrue);
  });

  test('a different number built and explained reports transfer once', () {
    for (var i = 0; i < 8; i++) {
      send(LearningSceneInput.countObject, id: 'ten-$i');
    }
    send(LearningSceneInput.startConstruction);
    expect(director.request.fact('target'), 57);
    for (var i = 0; i < 5; i++) {
      send(LearningSceneInput.addTen);
    }
    for (var i = 0; i < 7; i++) {
      send(LearningSceneInput.addOne);
    }
    expect(results, isEmpty);
    send(LearningSceneInput.submitConstruction);
    expect(director.request.stage, LearningSceneStage.explain);
    expect(director.request.choices, List.generate(10, (i) => i));
    send(LearningSceneInput.answerChoice, value: 7);
    expect(director.request.stage, LearningSceneStage.done);
    expect(director.request.lumo, LumoPerformanceIntent.celebrate);
    expect(results.single.number, 57);
    expect(results.single.correct, isTrue);
    expect(results.single.independent, isTrue);
    expect(send(LearningSceneInput.answerChoice, value: 7), isFalse);
    expect(results, hasLength(1));
  });

  test('a corrected mistake stays practice, never independent transfer', () {
    for (var i = 0; i < 8; i++) {
      send(LearningSceneInput.countObject, id: 'ten-$i');
    }
    send(LearningSceneInput.startConstruction);
    send(LearningSceneInput.submitConstruction);
    expect(director.request.feedback, contains('Jede Stange zählt zehn'));
    expect(director.request.lumo, LumoPerformanceIntent.encourage);
    for (var i = 0; i < 5; i++) {
      send(LearningSceneInput.addTen);
    }
    for (var i = 0; i < 7; i++) {
      send(LearningSceneInput.addOne);
    }
    send(LearningSceneInput.submitConstruction);
    send(LearningSceneInput.answerChoice, value: 3);
    expect(director.request.feedback, contains('volle Bündel'));
    send(LearningSceneInput.answerChoice, value: 7);
    expect(results.single.independent, isFalse);
    expect(director.request.lumo, LumoPerformanceIntent.encourage);
  });

  test('small numbers build a larger target', () {
    final small = PlaceValueSceneDirector(number: 23);
    addTearDown(small.dispose);
    expect(small.target, 50);
  });
}
