import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _IdentityStore extends InMemorySharedPreferencesStore {
  _IdentityStore() : super.withData({});
  bool rejectIdentity = true;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (rejectIdentity &&
        key == 'flutter.${LegacyLearningDataRepository.localIdKey}') {
      return false;
    }
    return super.setValue(type, key, value);
  }
}

class _PausedStore extends InMemorySharedPreferencesStore {
  _PausedStore(this.pauseKey) : super.withData({});
  final String pauseKey;
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == pauseKey &&
        !entered.isCompleted &&
        (key.contains('attempt_log') || value == 'b')) {
      entered.complete();
      await release.future;
    }
    return super.setValue(type, key, value);
  }
}

Future<void> _turns() async {
  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _PausedWallet extends RewardWalletRepository {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('switching A to B shows B own skills and daily progress', () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('student-a');
    await app.recordLearningAnswer(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      correct: true,
      requireSaved: true,
    );
    expect(app.learningDailyDone(), 1);

    await app.school.setActiveStudent('student-b');
    await app.loadLearningProfile();
    expect(app.learningSkills(), isEmpty);
    expect(app.learningDailyDone(), 0);
    expect(app.state.learningRecommendationUnit, isNot('Plus bis 10'));

    await app.recordLearningAnswer(
      subject: 'Deutsch',
      unit: 'Artikel',
      correct: false,
      requireSaved: true,
    );
    expect(app.learningSkills().keys, ['deutsch::artikel']);
    expect(app.learningSkills()['deutsch::artikel']!.wrong, 1);

    await app.school.setActiveStudent('student-a');
    await app.loadLearningProfile();
    expect(app.learningSkills().keys, ['mathematik::plus bis 10']);
    expect(app.learningSkills()['mathematik::plus bis 10']!.correct, 1);
    expect(app.learningDailyDone(), 1);
  });

  test('a fresh app restores only the selected student after restart',
      () async {
    final app = LumoAppState();
    await app.school.setActiveStudent('student-a');
    await app.recordLearningAnswer(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      correct: true,
      requireSaved: true,
    );
    await app.school.setActiveStudent('student-b');
    await app.recordLearningAnswer(
      subject: 'Deutsch',
      unit: 'Artikel',
      correct: true,
      requireSaved: true,
    );
    app.dispose();

    final restarted = LumoAppState();
    addTearDown(restarted.dispose);
    await restarted.loadLearningProfile();
    expect(restarted.learningSkills().keys, ['deutsch::artikel']);
    expect(restarted.learningDailyDone(), 1);
    await restarted.school.setActiveStudent('student-a');
    await restarted.loadLearningProfile();
    expect(restarted.learningSkills().keys, ['mathematik::plus bis 10']);
    expect(restarted.learningDailyDone(), 1);
  });

  test('module captures A before a delayed wallet and leaves visible B empty',
      () async {
    final wallet = _PausedWallet();
    final app = LumoAppState(walletRepository: wallet);
    final progress = LearningModuleProgress(
        appState: app, subject: 'Mathematik', unit: 'Minus bis 10');
    addTearDown(() {
      if (!wallet.release.isCompleted) wallet.release.complete();
      progress.dispose();
      app.dispose();
    });
    await app.school.setActiveStudent('student-a');
    await app.loadLearningProfile();
    final saved = progress.saveAnswer(
        correct: true,
        stars: 1,
        xp: 5,
        cosmosSubjectId: 'm1_minus10',
        cosmosIsMath: true);
    await wallet.entered.future;
    await app.school.setActiveStudent('student-b');
    await app.loadLearningProfile();
    wallet.release.complete();
    expect(await saved, isFalse); // A's old screen cannot advance B's UI.
    expect(app.learningSkills(), isEmpty);
    expect(app.learningDailyDone(), 0);
    final a = LearningProfileEngine(
        repository: ProgressRepository(studentId: 'student-a'));
    await a.load();
    expect(a.skills['mathematik::minus bis 10']?.correct, 1);
    expect(a.dailyDone(), 1);
    final attempts = await app.attemptLog.load();
    expect(attempts, hasLength(1));
    expect(attempts.single.studentId, 'student-a');
    final leaseB = await app.captureLearningProfile();
    await app.loadCosmos(lease: leaseB);
    expect(leaseB.cosmos.totalItems, 0);
    await app.school.setActiveStudent('student-a');
    final leaseA = await app.captureLearningProfile();
    await app.loadCosmos(lease: leaseA);
    expect(leaseA.cosmos.totalItems, 1);
    expect(leaseA.cosmos.totalCorrect, 1);
    expect(progress.hasPending, isFalse);
  });

  test('resetting A learning preserves B progress and B attempt history',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    for (final id in ['a', 'b']) {
      await app.school.setActiveStudent(id);
      await app.recordLearningAnswer(
          subject: 'Deutsch',
          unit: 'Artikel',
          correct: true,
          requireSaved: true);
      await app.grantCosmosReward(
          subjectId: 'lesen',
          isMath: false,
          isPerfect: false,
          requireSaved: true);
    }
    await app.school.setActiveStudent('a');
    await app.loadLearningProfile();
    final oldA = await app.captureLearningProfile();
    await app.resetLearningProfile();
    expect(app.learningSkills(), isEmpty);
    expect(app.canUseLearningLease(oldA), isFalse);
    expect(await app.attemptLog.load(studentId: 'a'), isEmpty);
    expect(await app.attemptLog.load(studentId: 'b'), hasLength(1));
    final freshA = await app.captureLearningProfile();
    await app.loadCosmos(lease: freshA);
    expect(freshA.cosmos.totalItems, 0);
    await app.school.setActiveStudent('b');
    await app.loadLearningProfile();
    expect(app.learningDailyDone(), 1);
    expect(app.learningSkills()['deutsch::artikel']!.correct, 1);
    final b = await app.captureLearningProfile();
    await app.loadCosmos(lease: b);
    expect(b.cosmos.totalItems, 1);
  });

  test(
      'a first local identity write failure can retry the same accepted module answer',
      () async {
    final store = _IdentityStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    final progress = LearningModuleProgress(
        appState: app, subject: 'Deutsch', unit: 'Artikel');
    addTearDown(() {
      progress.dispose();
      app.dispose();
    });
    final failed = Completer<void>();
    progress.addListener(() {
      if (progress.error != null && !failed.isCompleted) failed.complete();
    });
    final saved = progress.saveAnswer(correct: true, stars: 1, xp: 5);
    await failed.future;
    expect(app.learningDailyDone(), 0);
    store.rejectIdentity = false;
    progress.retry();
    expect(await saved.timeout(const Duration(seconds: 2)), isTrue);
    expect(app.learningDailyDone(), 1);
    expect((await app.attemptLog.load()).single.studentId, 'self');
    expect((await RewardWalletRepository().load()).stars, 1);
  });

  test(
      'independent A and B answers preserve both logs when the first log write is delayed',
      () async {
    final store = _PausedStore('flutter.lumo_attempt_log_v1');
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(() {
      if (!store.release.isCompleted) store.release.complete();
      app.dispose();
    });
    await app.school.setActiveStudent('a');
    final a = await app.captureLearningProfile();
    await app.prepareLearningLease(a);
    await app.school.setActiveStudent('b');
    final b = await app.captureLearningProfile();
    await app.prepareLearningLease(b);
    final first = app.recordLearningAnswer(
        subject: 'Deutsch',
        unit: 'Artikel',
        correct: true,
        requireSaved: true,
        lease: a);
    await store.entered.future;
    final second = app.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        correct: true,
        requireSaved: true,
        lease: b);
    await _turns();
    store.release.complete();
    await Future.wait([first, second]);
    await (await SharedPreferences.getInstance()).reload();
    final attempts = await app.attemptLog.load();
    expect(attempts, hasLength(2));
    expect(attempts.map((attempt) => attempt.studentId).toSet(), {'a', 'b'});
    expect(app.unsavedAttempts, 0);
  });

  test('full reset waits for an old student selection before clearing storage',
      () async {
    final store = _PausedStore('flutter.lumo_school_active_student_v1');
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(() {
      if (!store.release.isCompleted) store.release.complete();
      app.dispose();
    });
    await app.school.setActiveStudent('a');
    final selection = app.school.setActiveStudent('b');
    await store.entered.future;
    final reset = app.resetAllProfile();
    await _turns();
    store.release.complete();
    await Future.wait([selection, reset]);
    expect(await app.school.activeStudentId(), isNull);
    final disk = await store.getAll();
    expect(disk['flutter.lumo_school_active_student_v1'], isNull);
    expect(app.learningSkills(), isEmpty);
  });
}
