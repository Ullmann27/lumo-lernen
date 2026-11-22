import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/achievements/achievement_claim.dart';
import 'package:lumo_lernen/core/achievements/achievement_events.dart';
import 'package:lumo_lernen/core/achievements/achievement_repository.dart';
import 'package:lumo_lernen/core/achievements/achievement_tracker.dart';
import 'package:lumo_lernen/core/achievements/lumo_achievement.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_quest_library.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/rewards/achievements_wall_screen.dart';
import 'package:lumo_lernen/features/live/lumo_live_pro_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _local = 'local-achievement-test';

class _ControlledStore extends InMemorySharedPreferencesStore {
  _ControlledStore()
      : super.withData({
          'flutter.${LegacyLearningDataRepository.localIdKey}': _local,
        });
  bool rejectWallet = false;
  bool nativeCacheOnFailure = false;
  bool rejectAchievement = false;
  Completer<void>? walletEntered, releaseWallet;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (rejectAchievement && key.contains(AchievementRepository.baseKey))
      return false;
    if (key == 'flutter.lumo_reward_wallet_v1') {
      if (rejectWallet) {
        if (nativeCacheOnFailure) await super.setValue(type, key, value);
        return false;
      }
      if (walletEntered != null && !walletEntered!.isCompleted) {
        walletEntered!.complete();
        await releaseWallet!.future;
      }
    }
    return super.setValue(type, key, value);
  }
}

class _LostReplyWallet extends RewardWalletRepository {
  bool loseReply = true;
  @override
  Future<RewardWallet> claimAchievement(
      {required AchievementClaim claim,
      required void Function() validateOwner}) async {
    final saved = await super
        .claimAchievement(claim: claim, validateOwner: validateOwner);
    if (loseReply) {
      loseReply = false;
      throw StateError(
          'Process ended before the UI received the durable reply');
    }
    return saved;
  }
}

class _Speech extends LumoSpeechListener {
  ValueChanged<String>? result;
  @override
  bool get available => true;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<void> startListening(
      {ValueChanged<String>? onResult,
      ValueChanged<String>? onFinalResult,
      VoidCallback? onNoMatch}) async {
    result = onFinalResult;
  }

  @override
  Future<void> cancel() async {}
}

Future<LumoAppState> _app({RewardWalletRepository? wallet}) async {
  final app =
      LumoAppState(walletRepository: wallet ?? RewardWalletRepository());
  await app.ensureSettingsLoaded();
  await app.loadLearningProfile();
  await app.hydrateFromWallet();
  return app;
}

Future<void> _ready(AchievementTracker tracker) async {
  await tracker.refresh();
  for (var i = 0; i < 200 && !tracker.ready; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(tracker.error, isNull);
  expect(tracker.ready, isTrue);
}

Future<void> _answer(LumoAppState app,
        {bool correct = true, String taskId = 'actual-answer'}) =>
    app.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Plus',
        correct: correct,
        taskId: taskId,
        requireSaved: true,
        prompt: '2 + 3',
        given: correct ? '5' : '4',
        expected: '5');

Future<void> _pumpIo(WidgetTester tester, [int frames = 25]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {LegacyLearningDataRepository.localIdKey: _local});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  test(
      'a real recorded answer unlocks and double-claim pays once without game inflation',
      () async {
    final app = await _app();
    final tracker = AchievementTracker(app);
    addTearDown(() {
      tracker.dispose();
      app.dispose();
    });
    await _ready(tracker);
    expect(tracker.unlockedCount(), 0);
    await _answer(app);
    await _ready(tracker);
    expect(tracker.snapshot!.unlocked, contains('first_steps'));
    final results = await Future.wait(
        [tracker.claim('first_steps'), tracker.claim('first_steps')]);
    expect(results, [true, false]);
    await _ready(tracker);
    final wallet = await RewardWalletRepository().load();
    expect(wallet.stars, 5);
    expect(wallet.gameResultIds, isEmpty);
    expect(wallet.achievementClaims.single.achievementId, 'first_steps');
    expect(wallet.earnedStarsByOwner[_local], 5);
    expect(tracker.isClaimed('first_steps'), isTrue);
    expect((await app.attemptLog.load()).length, 1);
    expect(app.learningProfile.skills.values.single.correct, 1);
  });

  test(
      'global legacy balance never unlocks a childs stars badge, owned credits do',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'lumo_reward_wallet_v1',
        jsonEncode(
            const RewardWallet(stars: 900, totalEarnedStars: 900).toJson()));
    final app = await _app();
    final tracker = AchievementTracker(app);
    addTearDown(() {
      tracker.dispose();
      app.dispose();
    });
    await _ready(tracker);
    expect(tracker.counter(AchievementMetric.starsTotal), 0);
    expect(tracker.snapshot!.unlocked, isNot(contains('stars_100')));
    final owner = await app.captureLearningProfile();
    app.addRewards(stars: 100, xp: 0, lease: owner);
    await app.flushRewards();
    await _ready(tracker);
    expect(tracker.counter(AchievementMetric.starsTotal), 100);
    expect(tracker.snapshot!.unlocked, contains('stars_100'));
    await app.school.setActiveStudent('child-b');
    expect(tracker.snapshot, isNull);
    await _ready(tracker);
    expect(tracker.counter(AchievementMetric.starsTotal), 0);
    expect(app.state.stars, 1000);
  });

  test('failed wallet write remains unclaimed, retry pays exactly once',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    final tracker = AchievementTracker(app);
    addTearDown(() {
      tracker.dispose();
      app.dispose();
    });
    await _answer(app);
    await _ready(tracker);
    store.rejectWallet = true;
    expect(await tracker.claim('first_steps'), isFalse);
    expect(tracker.isClaimed('first_steps'), isFalse);
    expect((await RewardWalletRepository().load()).stars, 0);
    store.rejectWallet = false;
    await _ready(tracker);
    expect(await tracker.claim('first_steps'), isTrue);
    expect((await RewardWalletRepository().load()).stars, 5);
  });

  test(
      'process loss after wallet commit is reconciled on restart without a second payout',
      () async {
    var app = await _app(wallet: _LostReplyWallet());
    var tracker = AchievementTracker(app);
    await _answer(app);
    await _ready(tracker);
    expect(await tracker.claim('first_steps'), isFalse);
    await tracker.refresh();
    tracker.dispose();
    app.dispose();
    app = await _app();
    tracker = AchievementTracker(app);
    addTearDown(() {
      tracker.dispose();
      app.dispose();
    });
    await _ready(tracker);
    expect(tracker.isClaimed('first_steps'), isFalse);
    expect(tracker.snapshot!.pendingClaims, contains('first_steps'));
    expect(await tracker.claim('first_steps'), isTrue);
    final owner = await app.captureLearningProfile();
    final receipt = AchievementClaim(
        ownerId: owner.studentId, achievementId: 'first_steps');
    await app.claimAchievement(lease: owner, claim: receipt);
    final wallet = await RewardWalletRepository().load();
    expect(wallet.stars, 5);
    expect(wallet.achievementClaims.length, 1);
  });

  test(
      'a negative native commit with a visible memory receipt still requires positive retry',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    var app = await _app();
    var tracker = AchievementTracker(app);
    await _answer(app);
    await _ready(tracker);
    store.rejectWallet = true;
    store.nativeCacheOnFailure = true;
    expect(await tracker.claim('first_steps'), isFalse);
    await tracker.refresh();
    tracker.dispose();
    app.dispose();
    // A new Dart repository can read the unconfirmed Android memory snapshot.
    app = await _app();
    tracker = AchievementTracker(app);
    addTearDown(() {
      tracker.dispose();
      app.dispose();
    });
    await _ready(tracker);
    expect(tracker.wallet!.achievementClaims.length, 1);
    expect(tracker.snapshot!.pendingClaims, contains('first_steps'));
    expect(tracker.isClaimed('first_steps'), isFalse);
    expect(await tracker.claim('first_steps'), isFalse);
    store.rejectWallet = false;
    await _ready(tracker);
    expect(await tracker.claim('first_steps'), isTrue);
    expect(tracker.isClaimed('first_steps'), isTrue);
    expect(tracker.wallet!.stars, 5);
    expect(tracker.wallet!.achievementClaims.length, 1);
  });

  test(
      'a claim settling during A-to-B hides A immediately and only A owns its receipt',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    final tracker = AchievementTracker(app);
    addTearDown(() {
      tracker.dispose();
      app.dispose();
    });
    await app.school.setActiveStudent('child-a');
    await _answer(app);
    await _ready(tracker);
    store.walletEntered = Completer<void>();
    store.releaseWallet = Completer<void>();
    final claiming = tracker.claim('first_steps');
    await store.walletEntered!.future;
    await app.school.setActiveStudent('child-b');
    expect(tracker.snapshot, isNull);
    expect(tracker.isClaimed('first_steps'), isFalse);
    store.releaseWallet!.complete();
    expect(await claiming, isFalse);
    await _ready(tracker);
    expect(tracker.snapshot!.studentId, 'child-b');
    expect(tracker.snapshot!.unlocked, isEmpty);
    expect(tracker.wallet!.achievementClaims.single.ownerId, 'child-a');
    await app.school.setActiveStudent('child-a');
    await _ready(tracker);
    expect(tracker.isClaimed('first_steps'), isFalse);
    expect(await tracker.claim('first_steps'), isTrue);
    expect((await RewardWalletRepository().load()).stars, 5);
  });

  test('delegator refuses locked achievements and receipts for another child',
      () async {
    final app = await _app();
    addTearDown(app.dispose);
    final owner = await app.captureLearningProfile();
    await expectLater(
        app.claimAchievement(
            lease: owner,
            claim: AchievementClaim(
                ownerId: owner.studentId, achievementId: 'streak_30')),
        throwsStateError);
    await _answer(app);
    final tracker = AchievementTracker(app);
    addTearDown(tracker.dispose);
    await _ready(tracker);
    await expectLater(
        app.claimAchievement(
            lease: owner,
            claim: const AchievementClaim(
                ownerId: 'other-child', achievementId: 'first_steps')),
        throwsStateError);
    expect((await RewardWalletRepository().load()).achievementClaims, isEmpty);
  });

  test(
      'existing 150-star catalog bonus is paid in full with a stable profile receipt',
      () async {
    final app = await _app();
    addTearDown(app.dispose);
    final owner = await app.captureLearningProfile();
    await AchievementRepository(studentId: owner.studentId).syncDurableProgress(
        totalTasks: 30,
        correctTasks: 30,
        mathCorrect: 30,
        germanCorrect: 0,
        longestLearningStreak: 30,
        earnedStars: 0);
    final tracker = AchievementTracker(app);
    addTearDown(tracker.dispose);
    await _ready(tracker);
    expect(await tracker.claim('streak_30'), isTrue);
    final wallet = await RewardWalletRepository().load();
    expect(wallet.stars, 150);
    expect(wallet.achievementClaims.single.stars, 150);
  });

  for (final wrongBefore in [false, true]) {
    test('actual AppState mission hooks respect preceding wrong=$wrongBefore',
        () async {
      final app = await _app();
      addTearDown(app.dispose);
      app.updateSettings(const AppSettings(missionTasksPerStation: 2));
      await app.loadDailyMission();
      final stations = app.dailyMission!.stations;
      if (wrongBefore) {
        await app.recordLearningAnswer(
            subject: stations.first.subject,
            unit: 'Mission',
            correct: false,
            taskId: 'earlier-wrong',
            requireSaved: true);
      }
      var index = 0;
      for (final station in stations) {
        for (var i = 0; i < 2; i++) {
          await app.recordLearningAnswer(
              subject: station.subject,
              unit: 'Mission',
              correct: true,
              taskId: 'mission-${index++}',
              requireSaved: true);
        }
      }
      final owner = await app.captureLearningProfile();
      final saved =
          await AchievementRepository(studentId: owner.studentId).load();
      expect(app.dailyMission!.isComplete, isTrue);
      expect(saved.unlocked.containsKey('perfect_mission'), !wrongBefore);
      expect((await app.attemptLog.load()).length, wrongBefore ? 7 : 6);
    });
  }

  test(
      'achievement storage failure never retries or doubles the canonical school answer',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    addTearDown(app.dispose);
    store.rejectAchievement = true;
    await _answer(app);
    expect((await app.attemptLog.load()).length, 1);
    expect(app.learningProfile.skills.values.single.correct, 1);
    store.rejectAchievement = false;
    final tracker = AchievementTracker(app);
    addTearDown(tracker.dispose);
    await _ready(tracker);
    expect(tracker.snapshot!.unlocked, contains('first_steps'));
    expect(tracker.counter(AchievementMetric.totalTasks), 1);
  });

  test('accepted participation keeps its captured owner across profile change',
      () async {
    final app = await _app();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('child-a');
    final owner = await app.captureLearningProfile();
    await app.school.setActiveStudent('child-b');
    expect(
        await recordAchievementParticipation(
            app, owner, AchievementParticipation.live),
        isTrue);
    expect((await AchievementRepository(studentId: 'child-a').load()).unlocked,
        contains('live_first'));
    expect((await AchievementRepository(studentId: 'child-b').load()).unlocked,
        isEmpty);
  });

  testWidgets(
      'real wall waits for storage, blocks double taps, and shows durable claimed state',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    addTearDown(app.dispose);
    await _answer(app);
    await tester
        .pumpWidget(MaterialApp(home: AchievementsWallScreen(appState: app)));
    await _pumpIo(tester);
    final button = find.byKey(const ValueKey('claim-first_steps'));
    await Scrollable.ensureVisible(tester.element(button), alignment: .45);
    await _pumpIo(tester, 3);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    store.walletEntered = Completer<void>();
    store.releaseWallet = Completer<void>();
    await tester.tap(button);
    await _pumpIo(tester, 4);
    expect(store.walletEntered!.isCompleted, isTrue);
    expect(find.textContaining('Sterne sind gespeichert.'), findsNothing);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(app.state.stars, 0);
    store.releaseWallet!.complete();
    await _pumpIo(tester);
    expect(find.text('Schon eingesammelt.'), findsOneWidget);
    expect(find.textContaining('5 Sterne sind gespeichert.'), findsOneWidget);
    expect(app.state.stars, 5);
    await app.school.setActiveStudent('child-b');
    await _pumpIo(tester);
    expect(find.text('Schon eingesammelt.'), findsNothing);
    expect(find.byKey(const ValueKey('claim-first_steps')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'actual LIVE speech callback unlocks only after a real result, not on opening',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'lumo_app_settings_v1',
        jsonEncode(const AppSettings(
                voiceEnabled: false,
                autoReadEnabled: false,
                soundEnabled: false,
                calmMode: true,
                microphoneEnabled: true)
            .toJson()));
    final app = await _app();
    final speech = _Speech();
    addTearDown(() {
      speech.dispose();
      app.dispose();
    });
    LumoCompanionRequests.instance.clearLearningScope();
    final owner = await app.captureLearningProfile();
    final repo = AchievementRepository(studentId: owner.studentId);
    await tester.pumpWidget(MaterialApp(
        home: LumoLiveProScreen(appState: app, speechListener: speech)));
    await _pumpIo(tester);
    expect((await repo.load()).unlocked, isNot(contains('live_first')));
    final speak = find.text('Sprechen').last;
    await Scrollable.ensureVisible(tester.element(speak), alignment: .5);
    await tester.tap(speak);
    await _pumpIo(tester);
    expect(speech.result, isNotNull);
    expect((await repo.load()).unlocked, isNot(contains('live_first')));
    speech.result!('Haus');
    await _pumpIo(tester);
    expect((await repo.load()).unlocked, contains('live_first'));
    expect(app.state.stars, 0,
        reason: 'An unlock still needs an explicit claim.');
    await tester.pumpWidget(const SizedBox.shrink());
    LumoCompanionRequests.instance.clearLearningScope();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'all four actual quests reach the saved completion hook through their real answers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await _app();
    addTearDown(app.dispose);
    final owner = await app.captureLearningProfile();
    final repo = AchievementRepository(studentId: owner.studentId);
    Future<void> tap(Finder target) async {
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await tester.tap(target);
      await _pumpIo(tester, 8);
    }

    for (final quest in LumoQuestLibrary.all()) {
      LumoCompanionRequests.instance.clearLearningScope();
      await tester.pumpWidget(MaterialApp(
          home: LumoStoryReaderScreen(
              story: quest.story, storyId: quest.id, appState: app)));
      await _pumpIo(tester);
      expect((await repo.load()).quests, isNot(contains(quest.id)));
      for (final page in quest.story.pages) {
        final exercise = page.exercise;
        if (exercise != null) {
          await tap(
              find.widgetWithText(OutlinedButton, exercise.correctAnswer));
        }
        await tap(find.byKey(const ValueKey('lumo-story-continue')));
      }
      final summary = find.byKey(const ValueKey('story-summary-text'));
      await Scrollable.ensureVisible(tester.element(summary), alignment: .5);
      await tester.enterText(
          summary, 'Lumo hilft und zählt. ${quest.story.keyPoints.join(' ')}');
      await tap(find.byKey(const ValueKey('lumo-summary-evaluate')));
      await tap(find.byKey(const ValueKey('lumo-summary-finish')));
      expect(
          find.text('Heft in deine Bibliothek gespeichert!'), findsOneWidget);
      expect((await repo.load()).quests, contains(quest.id));
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpIo(tester, 2);
    }
    final snapshot = await repo.load();
    expect(snapshot.quests.length, 4);
    expect(snapshot.unlocked.keys, containsAll(['first_quest', 'all_quests']));
    expect((await RewardWalletRepository().load()).achievementClaims, isEmpty);
    LumoCompanionRequests.instance.clearLearningScope();
    expect(tester.takeException(), isNull);
  });
}
