import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.withData({});
  bool reject = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async => reject && key.contains('scenes') ? false : super.setValue(type, key, value);
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  LearningProfileEngine engine(String id) => LearningProfileEngine(repository: ProgressRepository(studentId: id));
  SceneObservation feedback() => SceneObservation.methodFeedback(id: 'method-a', conceptId: 'math.tens_ones',
    problemId: 'problem-84', method: ExplanationMethod.verbal, understood: false, at: DateTime.utc(2026, 10, 29));
  test('methods survive restart and remain strictly separated between siblings', () async {
    final a = engine('a');
    await a.recordSceneObservation(feedback());
    final restarted = engine('a'); await restarted.loadSceneMemory();
    final sibling = engine('b'); await sibling.loadSceneMemory();
    expect(restarted.sceneMemory.records.single.outcome, SceneOutcome.notUnderstood);
    expect(sibling.sceneMemory.records, isEmpty);
  });
  test('failed write retries the identical receipt without duplicate competence', () async {
    final store = _Store(); SharedPreferencesStorePlatform.instance = store;
    final a = engine('a');
    final lesson = PlaceValueLessonSession(sourceNumber: 84, targetNumber: 57, sourceProblemId: 'problem-84');
    lesson.beginTransfer(); lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    store.reject = true;
    await expectLater(a.recordSceneCompletion(subject: 'Mathematik', unit: 'Zehner und Einer',
      proof: proof, method: ExplanationMethod.pictorial), throwsA(isA<Object>()));
    store.reject = false;
    await a.recordSceneCompletion(subject: 'Mathematik', unit: 'Zehner und Einer', proof: proof, method: ExplanationMethod.pictorial);
    final restarted = engine('a'); await restarted.loadSceneMemory(); await restarted.loadJourney();
    expect(restarted.sceneMemory.records, hasLength(1));
    expect(restarted.journey.records.values.single.transferCorrect, 1);
    expect(restarted.journey.records.values.single.attempts, 1);
  });
  test('unknown stored versions and malformed bytes are preserved on failed record', () async {
    final key = LearningDataNamespace.keyFor('lumo_learning_scenes_v1', 'a');
    for (final raw in ['{broken', jsonEncode({'version': 2, 'records': []})]) {
      SharedPreferences.setMockInitialValues({key: raw});
      final a = engine('a');
      await expectLater(a.recordSceneObservation(feedback()), throwsFormatException);
      expect((await SharedPreferences.getInstance()).getString(key), raw);
      expect(a.sceneMemory.records, isEmpty);
    }
  });
}
