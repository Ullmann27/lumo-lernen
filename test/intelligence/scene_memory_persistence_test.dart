import 'dart:convert';
import 'package:lumo_lernen/app/app_state.dart';
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
  String? rejectContains;
  bool rejectAcknowledgment = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      (rejectAcknowledgment &&
                  key.contains('scene_pending') &&
                  value == 'null') ||
              (reject && key.contains('scenes')) ||
              (rejectContains != null && key.contains(rejectContains!))
          ? false
          : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  LearningProfileEngine engine(String id) =>
      LearningProfileEngine(repository: ProgressRepository(studentId: id));
  SceneObservation feedback() => SceneObservation.methodFeedback(
      id: 'method-a',
      conceptId: 'math.tens_ones',
      problemId: 'problem-84',
      method: ExplanationMethod.verbal,
      understood: false,
      at: DateTime.utc(2026, 10, 29));
  test('methods survive restart and remain strictly separated between siblings',
      () async {
    final a = engine('a');
    await a.recordSceneObservation(feedback());
    final restarted = engine('a');
    await restarted.loadSceneMemory();
    final sibling = engine('b');
    await sibling.loadSceneMemory();
    expect(restarted.sceneMemory.records.single.outcome,
        SceneOutcome.notUnderstood);
    expect(sibling.sceneMemory.records, isEmpty);
  });
  test(
      'failed write retries the identical receipt without duplicate competence',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final a = engine('a');
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'problem-84');
    lesson.beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    store.reject = true;
    await expectLater(
        a.recordSceneCompletion(
            subject: 'Mathematik',
            unit: 'Zehner und Einer',
            proof: proof,
            method: ExplanationMethod.pictorial),
        throwsA(isA<Object>()));
    store.reject = false;
    await a.recordSceneCompletion(
        subject: 'Mathematik',
        unit: 'Zehner und Einer',
        proof: proof,
        method: ExplanationMethod.pictorial);
    final restarted = engine('a');
    await restarted.loadSceneMemory();
    await restarted.loadJourney();
    expect(restarted.sceneMemory.records, hasLength(1));
    expect(restarted.journey.records.values.single.transferCorrect, 1);
    expect(restarted.journey.records.values.single.attempts, 1);
  });
  test(
      'unknown stored versions and malformed bytes are preserved on failed record',
      () async {
    final key = LearningDataNamespace.keyFor('lumo_learning_scenes_v1', 'a');
    for (final raw in [
      '{broken',
      jsonEncode({'version': 2, 'records': []})
    ]) {
      SharedPreferences.setMockInitialValues({key: raw});
      final a = engine('a');
      await expectLater(
          a.recordSceneObservation(feedback()), throwsFormatException);
      expect((await SharedPreferences.getInstance()).getString(key), raw);
      expect(a.sceneMemory.records, isEmpty);
    }
  });
  test('accepted scene feedback retains the original profile across a switch',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('a');
    await app.loadLearningProfile();
    final accepted = app.saveLearningScene(observation: feedback());
    await app.school.setActiveStudent('b');
    await accepted;
    expect((await ProgressRepository(studentId: 'a').loadSceneMemory()).records,
        hasLength(1));
    expect((await ProgressRepository(studentId: 'b').loadSceneMemory()).records,
        isEmpty);
  });
  test('a foreign explicit lease cannot redirect a validated child receipt',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('a');
    await app.loadLearningProfile();
    final original = await app.captureLearningProfile();
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84,
        targetNumber: 57,
        sourceProblemId: 'source-a',
        generation: original.generation)
      ..beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    await app.school.setActiveStudent('b');
    await app.loadLearningProfile();
    final other = await app.captureLearningProfile();
    expect(
        await app.saveLearningSceneCompletion(
            subject: 'Mathematik',
            unit: 'Zehner und Einer',
            proof: proof,
            method: ExplanationMethod.pictorial,
            lease: other),
        isFalse);
    expect((await ProgressRepository(studentId: 'b').loadJourney()).records,
        isEmpty);
    expect((await ProgressRepository(studentId: 'b').loadSceneMemory()).records,
        isEmpty);
    expect(
        await app.saveLearningSceneCompletion(
            subject: 'Mathematik',
            unit: 'Zehner und Einer',
            proof: proof,
            method: ExplanationMethod.pictorial,
            lease: original),
        isTrue);
    expect(
        (await ProgressRepository(studentId: 'a').loadJourney())
            .records
            .values
            .single
            .transferCorrect,
        1);
    expect((await ProgressRepository(studentId: 'b').loadJourney()).records,
        isEmpty);
  });
  test('ordinary flush recovers both journals after a partial journey write',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final a = engine('a');
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'problem-84');
    lesson.beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    store.rejectContains = 'journey';
    await expectLater(
        a.recordSceneCompletion(
            subject: 'Mathematik',
            unit: 'Zehner und Einer',
            proof: proof,
            method: ExplanationMethod.pictorial),
        throwsA(isA<Object>()));
    store.rejectContains = null;
    await a.flush();
    final restored = engine('a');
    await restored.loadSceneMemory();
    await restored.loadJourney();
    expect(restored.sceneMemory.records, hasLength(1));
    expect(restored.journey.records.values.single.transferCorrect, 1);
  });

  test(
      'restart replays a durable pending receipt after an interrupted second write',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final a = engine('a');
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'problem-84');
    lesson.beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    store.reject = true;
    await expectLater(
        a.recordSceneCompletion(
            subject: 'Mathematik',
            unit: 'Zehner und Einer',
            proof: proof,
            method: ExplanationMethod.pictorial),
        throwsA(isA<Object>()));
    store.reject = false;
    final restarted = engine('a');
    await restarted.loadSceneMemory();
    await restarted.loadJourney();
    expect(restarted.sceneMemory.records, hasLength(1));
    expect(restarted.journey.records.values.single.transferCorrect, 1);
    final secondRestart = engine('a');
    await secondRestart.loadSceneMemory();
    await secondRestart.loadJourney();
    expect(secondRestart.journey.records.values.single.attempts, 1);
  });
  test(
      'a failed acknowledgment is recovered on restart without replaying competence',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final a = engine('a');
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'problem-84')
      ..beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    store.rejectAcknowledgment = true;
    await expectLater(
        a.recordSceneCompletion(
            subject: 'Mathematik',
            unit: 'Zehner und Einer',
            proof: proof,
            method: ExplanationMethod.pictorial),
        throwsA(isA<Object>()));
    store.rejectAcknowledgment = false;
    final restored = engine('a');
    await restored.loadSceneMemory();
    await restored.loadJourney();
    expect(restored.journey.records.values.single.attempts, 1);
    expect(restored.sceneMemory.records, hasLength(1));
    expect(restored.hasPendingSceneReceipt, isFalse);
  });
  test(
      'unknown pending receipt version stays untouched and blocks a conflicting write',
      () async {
    final key =
        LearningDataNamespace.keyFor('lumo_learning_scene_pending_v1', 'a');
    final bytes = jsonEncode({'version': 99, 'future': true});
    SharedPreferences.setMockInitialValues({key: bytes});
    final a = engine('a');
    await expectLater(
        a.recordSceneObservation(feedback()), throwsFormatException);
    expect((await SharedPreferences.getInstance()).getString(key), bytes);
    expect(a.sceneMemory.records, isEmpty);
  });
  test(
      'explicit reset clears a pending receipt without resurrecting old evidence',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final a = engine('a');
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'problem-84')
      ..beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    store.reject = true;
    await expectLater(
        a.recordSceneCompletion(
            subject: 'Mathematik',
            unit: 'Zehner und Einer',
            proof: proof,
            method: ExplanationMethod.pictorial),
        throwsA(isA<Object>()));
    store.reject = false;
    await a.reset();
    final restored = engine('a');
    await restored.loadSceneMemory();
    await restored.loadJourney();
    expect(restored.sceneMemory.records, isEmpty);
    expect(restored.journey.records, isEmpty);
  });
}
