import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_cosmos.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FailingCosmosStore extends InMemorySharedPreferencesStore {
  _FailingCosmosStore() : super.withData({});
  bool reject = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (reject && key == 'flutter.lumo_cosmos_v2::a') return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('worlds and reward listeners belong only to their stable student',
      () async {
    final a = CosmosWorld(studentId: 'a');
    final b = CosmosWorld(studentId: 'b');
    var aNotifications = 0;
    var bNotifications = 0;
    a.addListener((_) => aNotifications++);
    b.addListener((_) => bNotifications++);
    // No explicit load: the first accepted reward must wait for its world.
    await a.grantReward(subjectId: 'math', isMath: true, isPerfect: false);
    await b.load();
    expect(a.totalCorrect, 1);
    expect(a.totalItems, 1);
    expect(b.totalCorrect, 0);
    expect(b.totalItems, 0);
    expect(aNotifications, 1);
    expect(bNotifications, 0);

    await b.grantReward(subjectId: 'lesen', isMath: false, isPerfect: false);
    expect(a.totalCorrect, 1);
    expect(b.totalCorrect, 1);
    expect(a.items.single.type, CosmosItemType.tree);
    expect(b.items.single.type, CosmosItemType.bush);
    expect(aNotifications, 1);
    expect(bNotifications, 1);
  });

  test('reward before load preserves the saved world across restart', () async {
    final first = CosmosWorld(studentId: 'a');
    await first.grantReward(subjectId: 'math', isMath: true, isPerfect: false);
    final restarted = CosmosWorld(studentId: 'a');
    await restarted.grantReward(
        subjectId: 'math', isMath: true, isPerfect: false);
    final restoredAgain = CosmosWorld(studentId: 'a');
    await restoredAgain.load();
    expect(restoredAgain.totalCorrect, 2);
    expect(restoredAgain.totalItems, 2);
  });

  test('failed atomic world write stays retryable without duplicate reward',
      () async {
    final store = _FailingCosmosStore();
    SharedPreferencesStorePlatform.instance = store;
    final a = CosmosWorld(studentId: 'a');
    await a.load();
    var notifications = 0;
    a.addListener((_) => notifications++);
    store.reject = true;
    await expectLater(
      a.grantReward(subjectId: 'math', isMath: true, isPerfect: false),
      throwsStateError,
    );
    expect(a.totalCorrect, 1);
    expect(notifications, 0);
    expect(a.hasPendingSave, isTrue);
    store.reject = false;
    await a.flush();
    await a.flush();
    expect(notifications, 1);
    final restarted = CosmosWorld(studentId: 'a');
    await restarted.load();
    expect(restarted.totalCorrect, 1);
    expect(restarted.totalItems, 1);
    expect(a.hasPendingSave, isFalse);
  });

  test('simultaneous first rewards share one load and preserve every item',
      () async {
    final a = CosmosWorld(studentId: 'a');
    await Future.wait([
      a.grantReward(subjectId: 'math', isMath: true, isPerfect: false),
      a.grantReward(subjectId: 'math', isMath: true, isPerfect: false),
    ]);
    final restored = CosmosWorld(studentId: 'a');
    await restored.load();
    expect(restored.totalCorrect, 2);
    expect(restored.totalItems, 2);
  });

  test(
      'module retries A world failure after switching to B without duplicate learning',
      () async {
    final store = _FailingCosmosStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    final progress = LearningModuleProgress(
        appState: app, subject: 'Mathematik', unit: 'Minus bis 10');
    addTearDown(() {
      progress.dispose();
      app.dispose();
    });
    await app.school.setActiveStudent('a');
    await app.loadLearningProfile();
    final a = await app.captureLearningProfile();
    store.reject = true;
    final failed = Completer<void>();
    progress.addListener(() {
      if (progress.error != null && !failed.isCompleted) failed.complete();
    });
    final answer = progress.saveAnswer(
        correct: true,
        stars: 1,
        xp: 5,
        cosmosSubjectId: 'm1_minus10',
        cosmosIsMath: true);
    await failed.future;
    expect(a.profile.dailyDone(), 1);
    expect(a.cosmos.totalCorrect, 1);
    expect(a.cosmos.hasPendingSave, isTrue);
    await app.school.setActiveStudent('b');
    await app.loadLearningProfile();
    store.reject = false;
    progress.retry();
    expect(await answer, isFalse);
    expect(app.learningSkills(), isEmpty);
    expect(a.profile.dailyDone(), 1);
    final restoredA = CosmosWorld(studentId: 'a');
    final restoredB = CosmosWorld(studentId: 'b');
    await restoredA.load();
    await restoredB.load();
    expect(restoredA.totalCorrect, 1);
    expect(restoredA.totalItems, 1);
    expect(restoredB.totalItems, 0);
    final attempts = await app.attemptLog.load();
    expect(attempts, hasLength(1));
    expect(attempts.single.studentId, 'a');
  });

  test('a damaged stored world is not replaced by an empty reward snapshot',
      () async {
    const damaged = '{"items":[{"t":1,"x":"broken","y":0.3,"s":1.0}],'
        '"meta":{"c":9,"s":1,"d":"2026-10-09"}}';
    SharedPreferences.setMockInitialValues({'lumo_cosmos_v2::a': damaged});
    final a = CosmosWorld(studentId: 'a');
    await expectLater(
        a.grantReward(subjectId: 'math', isMath: true, isPerfect: false),
        throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getString('lumo_cosmos_v2::a'), damaged);
    expect(a.isLoaded, isFalse);
  });
}
