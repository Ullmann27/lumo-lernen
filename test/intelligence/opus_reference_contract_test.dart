import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';

void main() {
  test(
      'exported Opus reference is produced by the actual verified scene factory',
      () {
    final scene = const LessonSceneEngine().placeValue(
        number: 84, method: ExplanationMethod.interactive, reduceMotion: true);
    final raw = jsonEncode(scene.toJson());
    expect(
        LumoLearningScene.fromJson(jsonDecode(raw)).toJson(), scene.toJson());
    expect(scene.objects.first.quantity * 10 + scene.objects.last.quantity, 84);
    final dir = Platform.environment['LUMO_INTELLIGENCE_EVIDENCE'];
    if (dir != null) {
      final file = File('$dir/place-value-scene-v1.json');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(scene.toJson()));
    }
  });
}
