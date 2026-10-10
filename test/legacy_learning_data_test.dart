import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/lumo_cosmos.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FailingLegacyStore extends InMemorySharedPreferencesStore {
  _FailingLegacyStore(Map<String, Object> initial)
      : super.withData(
            initial.map((key, value) => MapEntry('flutter.$key', value)));

  String? rejectKey;
  bool rejectCommit = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == rejectKey) return false;
    if (rejectCommit &&
        key == 'flutter.${LegacyLearningDataRepository.claimKey}' &&
        (jsonDecode(value as String) as Map)['state'] == 'committed') {
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

class _AssignmentPausedWallet extends RewardWalletRepository {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<RewardWallet> applyRewardDelta(
      {int starsDelta = 0, int xpDelta = 0}) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }
}

Map<String, Object> _legacy() => {
      'lumo_progress_skills': jsonEncode({
        'mathematik::plus bis 10': SkillRecord(
          skillId: 'mathematik::plus bis 10',
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          correct: 7,
        ).toJson(),
      }),
      'lumo_progress_daily': '{"2026-10-09":7}',
      'lumo_progress_last': '{"Mathematik":"Plus bis 10"}',
      'lumo_cosmos_items_v1': '[{"t":1,"x":0.3,"y":0.6,"s":1.0,"r":0.0}]',
      'lumo_cosmos_meta_v1': '{"c":7,"s":2,"d":"2026-10-09"}',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('local identity is stable across service instances and profile renames',
      () async {
    final first = await LegacyLearningDataRepository().localStudentId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lumo_active_profile', '{"name":"Lena","grade":1}');
    expect(await LegacyLearningDataRepository().localStudentId(), first);
    await prefs.setString('lumo_active_profile', '{"name":"Lena","grade":3}');
    await prefs.reload();
    expect(await LegacyLearningDataRepository().localStudentId(), first);
    expect(first, startsWith('local-'));
  });

  test('unowned legacy remains visible for an explicit parent decision',
      () async {
    final seed = _legacy();
    SharedPreferences.setMockInitialValues(seed);
    final a =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    final b =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'b'));
    await a.load();
    await b.load();
    expect(a.skills, isEmpty);
    expect(b.skills, isEmpty);
    final status = await LegacyLearningDataRepository().inspect();
    expect(status.hasData, isTrue);
    expect(status.hasProgress, isTrue);
    expect(status.hasCosmos, isTrue);
    expect(status.canAssign, isTrue);
    expect(status.assignedStudentId, isNull);
    final prefs = await SharedPreferences.getInstance();
    for (final entry in seed.entries) {
      expect(prefs.get(entry.key), entry.value);
    }
  });

  test(
      'explicit assignment moves visibility to exactly one child and preserves originals',
      () async {
    final seed = _legacy();
    SharedPreferences.setMockInitialValues(seed);
    final legacy = LegacyLearningDataRepository();
    await legacy.assignTo('a');
    await legacy.assignTo('a'); // Idempotent retry after a lost completion.
    final a =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    final b =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'b'));
    await a.load();
    await b.load();
    final cosmosA = CosmosWorld(studentId: 'a');
    final cosmosB = CosmosWorld(studentId: 'b');
    await cosmosA.load();
    await cosmosB.load();
    expect(a.skills.values.single.correct, 7);
    expect(a.daily['2026-10-09'], 7);
    expect(a.lastTopics['Mathematik'], 'Plus bis 10');
    expect(b.skills, isEmpty);
    expect(cosmosA.totalCorrect, 7);
    expect(cosmosA.totalItems, 1);
    expect(cosmosB.totalItems, 0);
    final status = await legacy.inspect();
    expect(status.assignedStudentId, 'a');
    expect(status.canAssign, isFalse);
    await expectLater(
        legacy.assignTo('b'), throwsA(isA<LegacyLearningDataException>()));
    final prefs = await SharedPreferences.getInstance();
    for (final entry in seed.entries) {
      expect(prefs.get(entry.key), entry.value);
    }
  });

  test('assignment refuses to overwrite a child who already learned', () async {
    SharedPreferences.setMockInitialValues(_legacy());
    final a =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await a.load();
    await a.recordAnswer(subject: 'Deutsch', unit: 'Artikel', isCorrect: true);
    await expectLater(
      LegacyLearningDataRepository().assignTo('a'),
      throwsA(isA<LegacyLearningDataException>()
          .having((error) => error.code, 'code', 'destination-not-empty')),
    );
    expect(a.skills.keys, ['deutsch::artikel']);
    expect((await LegacyLearningDataRepository().inspect()).canAssign, isTrue);
  });

  test('opening an untouched child world still allows explicit assignment',
      () async {
    final seed = _legacy();
    SharedPreferences.setMockInitialValues(seed);
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('a');
    await app.loadLearningProfile();
    final before = await app.captureLearningProfile();
    await before.cosmos.load();
    expect(before.cosmos.totalItems, 0);
    await app.resolveLegacyLearningData('a');
    expect(app.learningSkills().values.single.correct, 7);
    final after = await app.captureLearningProfile();
    await after.cosmos.load();
    expect(after.cosmos.totalItems, 1);
    expect(after.cosmos.totalCorrect, 7);
    expect(app.canUseLearningLease(before), isFalse);
    await app.flushLearningProgress(lease: before);
    await app.flushCosmos(lease: before);
    final reopened =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await reopened.load();
    expect(reopened.skills.values.single.correct, 7);
    final prefs = await SharedPreferences.getInstance();
    for (final entry in seed.entries) {
      expect(prefs.get(entry.key), entry.value);
    }
  });

  test('failed local identity persistence can retry on the same repository',
      () async {
    final store = _FailingLegacyStore({})
      ..rejectKey = 'flutter.${LegacyLearningDataRepository.localIdKey}';
    SharedPreferencesStorePlatform.instance = store;
    final repository = ProgressRepository();
    await expectLater(repository.loadSkills(), throwsStateError);
    store.rejectKey = null;
    expect(await repository.loadSkills(), isEmpty);
    final owner = await repository.studentId;
    expect(owner, await LegacyLearningDataRepository().localStudentId());
  });

  test('interrupted staging can only resume for its reserved child', () async {
    final seed = _legacy();
    final store = _FailingLegacyStore(seed)
      ..rejectKey = 'flutter.${LegacyLearningDataRepository.stageKey}';
    SharedPreferencesStorePlatform.instance = store;
    final legacy = LegacyLearningDataRepository();
    await expectLater(
        legacy.assignTo('a'), throwsA(isA<LegacyLearningDataException>()));
    final status = await LegacyLearningDataRepository().inspect();
    expect(status.pendingAssignment, isTrue);
    expect(status.reservedStudentId, 'a');
    expect(status.assignedStudentId, isNull);
    expect(status.canAssign, isFalse);
    await expectLater(
        legacy.assignTo('b'), throwsA(isA<LegacyLearningDataException>()));
    final a =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await expectLater(a.load(), throwsStateError);
    store.rejectKey = null;
    await LegacyLearningDataRepository().assignTo('a');
    await a.load();
    expect(a.skills.values.single.correct, 7);
    final raw = await store.getAll();
    for (final entry in seed.entries) {
      expect(raw['flutter.${entry.key}'], entry.value);
    }
  });

  test('malformed original data is retained and cannot be blindly assigned',
      () async {
    SharedPreferences.setMockInitialValues({'lumo_progress_skills': '{broken'});
    final status = await LegacyLearningDataRepository().inspect();
    expect(status.hasData, isTrue);
    expect(status.canAssign, isFalse);
    expect(status.problem, 'damaged-legacy');
    await expectLater(
      LegacyLearningDataRepository().assignTo('a'),
      throwsA(isA<LegacyLearningDataException>()),
    );
    expect(
        (await SharedPreferences.getInstance())
            .getString('lumo_progress_skills'),
        '{broken');
  });

  test(
      'a pending accepted module answer blocks assignment during its wallet write',
      () async {
    SharedPreferences.setMockInitialValues(_legacy());
    final wallet = _AssignmentPausedWallet();
    final app = LumoAppState(walletRepository: wallet);
    final progress = LearningModuleProgress(
        appState: app, subject: 'Deutsch', unit: 'Artikel');
    addTearDown(() {
      if (!wallet.release.isCompleted) wallet.release.complete();
      progress.dispose();
      app.dispose();
    });
    await app.school.setActiveStudent('a');
    await app.loadLearningProfile();
    final answer = progress.saveAnswer(correct: true, stars: 1, xp: 5);
    await wallet.entered.future;
    await expectLater(
        app.resolveLegacyLearningData('a'),
        throwsA(isA<LegacyLearningDataException>()
            .having((error) => error.code, 'code', 'assignment-busy')));
    expect((await app.legacyLearningData.inspect()).canAssign, isTrue);
    wallet.release.complete();
    expect(await answer, isTrue);
    expect(app.learningSkills()['deutsch::artikel']!.correct, 1);
    expect(app.learningSkills()['mathematik::plus bis 10'], isNull);
    expect((await app.attemptLog.load()).single.studentId, 'a');
  });

  test(
      'a failed final claim stays reserved across restart until the same owner retries',
      () async {
    final seed = _legacy();
    final store = _FailingLegacyStore(seed)..rejectCommit = true;
    SharedPreferencesStorePlatform.instance = store;
    await expectLater(
        LegacyLearningDataRepository().assignTo('a'), throwsStateError);
    await (await SharedPreferences.getInstance()).reload();
    final afterRestart = LegacyLearningDataRepository();
    final status = await afterRestart.inspect();
    expect(status.pendingAssignment, isTrue);
    expect(status.reservedStudentId, 'a');
    expect(status.assignedStudentId, isNull);
    await expectLater(afterRestart.assignTo('b'), throwsStateError);
    await expectLater(
        ProgressRepository(studentId: 'a').loadSkills(), throwsStateError);
    expect(await ProgressRepository(studentId: 'b').loadSkills(), isEmpty);
    store.rejectCommit = false;
    await afterRestart.assignTo('a');
    expect(
        (await ProgressRepository(studentId: 'a').loadSkills())
            .values
            .single
            .correct,
        7);
    final disk = await store.getAll();
    for (final entry in seed.entries) {
      expect(disk['flutter.${entry.key}'], entry.value);
    }
  });

  test(
      'a failed reservation exposes no ownership and permits a later deliberate choice',
      () async {
    final store = _FailingLegacyStore(_legacy())
      ..rejectKey = 'flutter.${LegacyLearningDataRepository.claimKey}';
    SharedPreferencesStorePlatform.instance = store;
    await expectLater(
        LegacyLearningDataRepository().assignTo('a'), throwsStateError);
    final status = await LegacyLearningDataRepository().inspect();
    expect(status.canAssign, isTrue);
    expect(status.pendingAssignment, isFalse);
    expect(status.assignedStudentId, isNull);
    store.rejectKey = null;
    await LegacyLearningDataRepository().assignTo('b');
    expect((await LegacyLearningDataRepository().inspect()).assignedStudentId,
        'b');
    expect(await ProgressRepository(studentId: 'a').loadSkills(), isEmpty);
  });

  test(
      'sole local history is retained but a school directory prevents automatic claiming',
      () async {
    final seed = _legacy();
    SharedPreferences.setMockInitialValues(seed);
    final local = ProgressRepository();
    expect((await local.loadSkills()).values.single.correct, 7);
    expect((await LegacyLearningDataRepository().inspect()).assignedStudentId,
        await local.studentId);
    SharedPreferences.setMockInitialValues({
      ...seed,
      'lumo_school_v1': '{"students":[{"id":"a"},{"id":"b"}]}',
    });
    expect(await ProgressRepository().loadSkills(), isEmpty);
    expect((await LegacyLearningDataRepository().inspect()).canAssign, isTrue);
  });

  test(
      'an earned Cosmos destination cannot be overwritten by a legacy assignment',
      () async {
    SharedPreferences.setMockInitialValues(_legacy());
    final world = CosmosWorld(studentId: 'a');
    await world.grantReward(
        subjectId: 'lesen', isMath: false, isPerfect: false);
    await expectLater(
        LegacyLearningDataRepository().assignTo('a'),
        throwsA(isA<LegacyLearningDataException>()
            .having((error) => error.code, 'code', 'destination-not-empty')));
    final restored = CosmosWorld(studentId: 'a');
    await restored.load();
    expect(restored.totalCorrect, 1);
    expect(restored.totalItems, 1);
  });

  test(
      'decoded legacy fields that cannot be loaded are retained without claiming',
      () async {
    final seed = {
      ..._legacy(),
      'lumo_progress_skills': '{"math":{"skillId":42,"correct":7}}',
    };
    SharedPreferences.setMockInitialValues(seed);
    await expectLater(
        LegacyLearningDataRepository().assignTo('a'),
        throwsA(isA<LegacyLearningDataException>()
            .having((error) => error.code, 'code', 'damaged-legacy')));
    expect((await LegacyLearningDataRepository().inspect()).assignedStudentId,
        isNull);
    expect(
        (await SharedPreferences.getInstance())
            .getString('lumo_progress_skills'),
        seed['lumo_progress_skills']);
  });
}
