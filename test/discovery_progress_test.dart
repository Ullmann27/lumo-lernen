import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/discovery_progress.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _target = DiscoveryLearningTarget(topicId: 'equal_groups', grade: 2);
const _base = 'lumo_progress_discovery_v1';

class _FalseDiscoveryStore extends InMemorySharedPreferencesStore {
  _FalseDiscoveryStore() : super.withData({});
  String? rejectedKey;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == rejectedKey) return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh discovery is closed, bounded and independent of school progress',
      () async {
    final engine =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await engine.loadDiscovery();
    expect(engine.discovery.enabled, false);
    expect(engine.discovery.maxGrade, 1);
    await expectLater(engine.introduceDiscovery(_target),
        throwsA(isA<DiscoveryNotAllowed>()));
    expect(engine.hasUnsavedChanges, false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(),
        isNot(contains(LearningDataNamespace.keyFor(_base, 'a'))));
  });

  test('higher-stage discovery never changes regular counters, Daily or topics',
      () async {
    final engine =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await engine.recordAnswer(
        subject: 'Mathematik', unit: 'Plus bis 10', isCorrect: true);
    final prefs = await SharedPreferences.getInstance();
    final keys = ['skills', 'daily', 'last']
        .map((part) => LearningDataNamespace.keyFor('lumo_progress_$part', 'a'))
        .toList();
    final before = {for (final key in keys) key: prefs.getString(key)};
    await engine.setDiscoveryPermission(enabled: true, maxGrade: 2);
    await engine.introduceDiscovery(_target);
    await engine.recordDiscoveryAnswer(
        target: _target, step: DiscoveryStepKind.guided, correct: false);
    await engine.recordDiscoveryAnswer(
        target: _target,
        step: DiscoveryStepKind.guided,
        correct: true,
        hintUsed: true);
    await engine.recordDiscoveryAnswer(
        target: _target, step: DiscoveryStepKind.independent, correct: true);
    await engine.recordDiscoveryAnswer(
        target: _target, step: DiscoveryStepKind.check, correct: true);
    expect(engine.dailyDone(), 1);
    expect(engine.skills.singleValue.correct, 1);
    expect({for (final key in keys) key: prefs.getString(key)}, before);
    final topic = engine.discovery.topics['equal_groups']!;
    expect(topic.introduced, true);
    expect(topic.guidedWrong, 1);
    expect(topic.guidedCorrect, 1);
    expect(topic.hintsUsed, 1);
    expect(topic.independentlyChecked, true);
  });

  test('discovery-only load and flush preserve previously saved school data',
      () async {
    final previous =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await previous.recordAnswer(
        subject: 'Deutsch', unit: 'Silben', isCorrect: true);
    final onlyDiscovery =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await onlyDiscovery.setDiscoveryPermission(enabled: true, maxGrade: 2);
    await onlyDiscovery.introduceDiscovery(_target);
    await onlyDiscovery.flush();
    final restored =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await restored.load();
    expect(restored.skills.singleValue.subject, 'Deutsch');
    expect(restored.skills.singleValue.correct, 1);
    expect(restored.dailyDone(), 1);
  });

  test('permission revocation preserves discoveries and blocks new actions',
      () async {
    final engine =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await engine.setDiscoveryPermission(enabled: true, maxGrade: 2);
    await engine.introduceDiscovery(_target);
    await engine.setDiscoveryPermission(enabled: false, maxGrade: 2);
    await expectLater(
        engine.recordDiscoveryAnswer(
            target: _target, step: DiscoveryStepKind.guided, correct: true),
        throwsA(isA<DiscoveryNotAllowed>()));
    expect(engine.discovery.topics['equal_groups']!.introduced, true);
    expect(engine.discovery.topics['equal_groups']!.guidedCorrect, 0);
    await engine.setDiscoveryPermission(enabled: true, maxGrade: 1);
    await expectLater(engine.introduceDiscovery(_target),
        throwsA(isA<DiscoveryNotAllowed>()));
  });

  test('another child has neither the permission nor the discovered progress',
      () async {
    final a =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await a.setDiscoveryPermission(enabled: true, maxGrade: 2);
    await a.introduceDiscovery(_target);
    final b =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'b'));
    await b.loadDiscovery();
    expect(b.discovery.enabled, false);
    expect(b.discovery.topics, isEmpty);
    final restoredA =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await restoredA.loadDiscovery();
    expect(restoredA.discovery.topics['equal_groups']!.introduced, true);
  });

  for (final bad in [
    '',
    '{broken',
    '{}',
    jsonEncode({...DiscoveryProgress().toJson(), 'version': 2}),
    jsonEncode({...DiscoveryProgress().toJson(), 'newerPrivateField': true}),
    jsonEncode({...DiscoveryProgress().toJson(), 'enabled': 'yes'}),
  ]) {
    test('bad or newer bytes stay intact and fail closed: $bad', () async {
      final key = LearningDataNamespace.keyFor(_base, 'a');
      SharedPreferences.setMockInitialValues({key: bad});
      final engine =
          LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
      await expectLater(engine.loadDiscovery(), throwsFormatException);
      await expectLater(
          engine.setDiscoveryPermission(enabled: true, maxGrade: 2),
          throwsFormatException);
      expect((await SharedPreferences.getInstance()).getString(key), bad);
      expect(engine.discovery.enabled, false);
    });
  }

  test('retry flushes the same answer after a native false without recounting',
      () async {
    final store = _FalseDiscoveryStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('a');
    final lease = await app.captureLearningProfile();
    await app.prepareLearningLease(lease);
    await lease.profile.setDiscoveryPermission(enabled: true, maxGrade: 2);
    final progress = LearningModuleProgress(
        appState: app,
        subject: 'Mathematik',
        unit: 'Einmaleins entdecken',
        discoveryTarget: _target);
    addTearDown(progress.dispose);
    store.rejectedKey = 'flutter.${LearningDataNamespace.keyFor(_base, 'a')}';
    final completion = progress.saveAnswer(
        correct: true, discoveryStep: DiscoveryStepKind.independent);
    for (var i = 0; i < 40 && progress.error == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(progress.error, isNotNull);
    expect(progress.hasPending, true);
    expect(
        lease.profile.discovery.topics['equal_groups']!.independentCorrect, 1);
    store.rejectedKey = null;
    progress.retry();
    expect(await completion.timeout(const Duration(seconds: 5)), true);
    expect(app.learningDailyDone(), 0);
    final restored = ProgressRepository(studentId: 'a');
    expect(
        (await restored.loadDiscovery())
            .topics['equal_groups']!
            .independentCorrect,
        1);
  });

  test('the shared discovery writer does not touch wallet or regular logs',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('a');
    await app.hydrateFromWallet();
    final lease = await app.captureLearningProfile();
    await app.prepareLearningLease(lease);
    await lease.profile.setDiscoveryPermission(enabled: true, maxGrade: 2);
    final prefs = await SharedPreferences.getInstance();
    final before = {
      for (final key in prefs.getKeys())
        if (!key.contains(_base)) key: prefs.get(key)
    };
    final progress = LearningModuleProgress(
        appState: app,
        subject: 'Mathematik',
        unit: 'Einmaleins entdecken',
        discoveryTarget: _target);
    addTearDown(progress.dispose);
    expect(await progress.saveDiscoveryIntroduction(), true);
    expect(
        await progress.saveAnswer(
            correct: true, discoveryStep: DiscoveryStepKind.guided),
        true);
    await prefs.reload();
    expect({
      for (final key in prefs.getKeys())
        if (!key.contains(_base)) key: prefs.get(key)
    }, before);
    expect(() => progress.saveBonus(stars: 9, xp: 9), throwsStateError);
    expect(() => progress.saveReward(stars: 9, xp: 9), throwsStateError);
    expect(app.state.grade, 1);
  });

  test('a rejected grant stays ineffective until the same permission is saved',
      () async {
    final store = _FalseDiscoveryStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('a');
    final lease = await app.captureLearningProfile();
    await app.prepareLearningLease(lease);
    final writer = LearningModuleProgress(
        appState: app, subject: 'Eltern', unit: 'Entdeckungen');
    addTearDown(writer.dispose);
    store.rejectedKey = 'flutter.${LearningDataNamespace.keyFor(_base, 'a')}';
    final completion =
        writer.saveDiscoveryPermission(enabled: true, maxGrade: 2);
    for (var i = 0; i < 40 && writer.error == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(writer.error, isNotNull);
    expect(lease.profile.discoveryPermissionPending, true);
    expect(lease.profile.canDiscover(2), false);
    await expectLater(lease.profile.introduceDiscovery(_target),
        throwsA(isA<DiscoveryNotAllowed>()));
    store.rejectedKey = null;
    writer.retry();
    expect(await completion.timeout(const Duration(seconds: 5)), true);
    expect(lease.profile.canDiscover(2), true);
    expect(app.state.settings.aiProxyEnabled, false);
    expect(app.state.settings.cloudVoiceEnabled, false);
    expect(app.state.settings.microphoneEnabled, false);
    expect(app.state.settings.scannerEnabled, false);
    expect(app.learningDailyDone(), 0);
  });
}

extension _OnlyRecord on Map<String, SkillRecord> {
  SkillRecord get singleValue => values.single;
}
