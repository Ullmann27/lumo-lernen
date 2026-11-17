import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_session.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_player_hand.dart';
import 'package:lumo_lernen/features/games/shared/lumo_game_pause_scope.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/tutoring/guided_learning_hub.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _bridge = MethodChannel('lumo_lernen/bridge');
const _cards = MethodChannel('lumo_lernen/cards_table');

class _Routes extends NavigatorObserver {
  final removed = <Route<dynamic>>[];

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    removed.add(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    removed.add(route);
  }
}

/// Only the Android boundary is controlled. AppShell, its actual private
/// EmbeddedGameService, route navigation, lesson, Cards and persistence run.
///
/// This models the MainActivity/GameEventStore callerReturnSession contract:
/// the durable return remains in the store, but pendingGameEvents hides that
/// navigation only from the matching live pendingGame owner. ActivityResult
/// consumes that exact session before completing the launch3D result. A missing
/// owner (new Activity/process) and unmarked legacy returns remain navigable.
/// The actual Kotlin store is exercised separately by its Android contract test;
/// this widget fixture cannot establish Kotlin execution or device behaviour.
class _AndroidReturn {
  static const _session = '916b3cae-0d12-4eca-8078-8aa50f8341a2';
  final result = Completer<Map<String, Object?>>();
  final calls = <MethodCall>[];
  final events = <String, Object?>{'results': <Object?>[]};
  Map<String, dynamic>? launch;
  String? liveCallerSession;
  bool pendingGame = false;
  int reads = 0;
  int returnReads = 0;
  int maskedReads = 0;
  int visibleReturnReads = 0;
  int returnAcks = 0;
  int consumedReturns = 0;
  int failedAcks = 0;
  int acknowledgementsToFail = 0;
  final acknowledgedResults = <String>[];

  void recordReturn(String destination, {String? callerSession}) {
    events['destination'] = destination;
    if (callerSession != null) {
      events['callerReturnSession'] = callerSession;
    } else {
      events.remove('callerReturnSession');
    }
  }

  void deliverResult(String destination, {String? callerSession}) {
    if (callerSession != null && callerSession != liveCallerSession) return;
    if (pendingGame &&
        callerSession != null &&
        liveCallerSession == callerSession &&
        events['destination'] == destination &&
        events['callerReturnSession'] == callerSession) {
      events.remove('destination');
      events.remove('callerReturnSession');
      consumedReturns++;
    }
    pendingGame = false;
    liveCallerSession = null;
    result.complete({'destination': destination});
  }

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'launch3D':
        launch = Map<String, dynamic>.from(call.arguments as Map);
        pendingGame = true;
        liveCallerSession =
            const ['learning', 'cards'].contains(launch!['scene'])
                ? _session
                : null;
        if (liveCallerSession != null) {
          events.remove('destination');
          events.remove('callerReturnSession');
        }
        return result.future;
      case 'pendingGameEvents':
        reads++;
        if (events.containsKey('destination')) returnReads++;
        final visible = Map<String, Object?>.from(events);
        if (pendingGame &&
            liveCallerSession != null &&
            events['callerReturnSession'] == liveCallerSession) {
          visible.remove('destination');
          visible.remove('callerReturnSession');
          maskedReads++;
        }
        if (visible.containsKey('destination')) visibleReturnReads++;
        return jsonEncode(visible);
      case 'acknowledgeGameEvents':
        if (acknowledgementsToFail > 0) {
          acknowledgementsToFail--;
          failedAcks++;
          throw PlatformException(code: 'storage');
        }
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final ids = List<String>.from(args['resultIds'] as List);
        acknowledgedResults.addAll(ids);
        events['results'] = (events['results'] as List)
            .where((event) => event is! Map || !ids.contains(event['resultId']))
            .toList();
        if (args['destination'] != null &&
            args['destination'] == events['destination'] &&
            !(pendingGame &&
                liveCallerSession != null &&
                events.containsKey('callerReturnSession'))) {
          events.remove('destination');
          events.remove('callerReturnSession');
          returnAcks++;
        }
        return true;
      default:
        return null;
    }
  }
}

class _CardsMailbox {
  Map<String, dynamic>? opened;
  int closes = 0;

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'open') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      opened = jsonDecode(args['state'] as String) as Map<String, dynamic>;
    }
    if (call.method == 'poll') return '{}';
    if (call.method == 'close') closes++;
    return true;
  }
}

Future<void> _frames(WidgetTester tester, [int count = 24]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 32));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _frames(tester, 10);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _frames(tester);
}

Future<LumoAppState> _shell(WidgetTester tester, _Routes observer,
    {LumoSection initialSection = LumoSection.learn}) async {
  await tester.binding.setSurfaceSize(const Size(690, 1100));
  final date = DateTime(2026, 11, 13);
  await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      navigatorObservers: [observer],
      home: AppShell(
          profile: UserProfile(
              id: 'native-return-synthetic-child',
              name: 'Testkind',
              age: 7,
              grade: 1,
              createdAt: date,
              lastActiveAt: date),
          initialSection: initialSection)));
  await _frames(tester, 50);
  final app = find.byType(LumoAkademieScreen).evaluate().isNotEmpty
      ? tester
          .widget<LumoAkademieScreen>(find.byType(LumoAkademieScreen))
          .appState
      : tester.widget<GamesContent>(find.byType(GamesContent)).appState;
  expect(app.settingsLoaded, isTrue);
  return app;
}

Future<void> _guidedExample(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('learning-advanced-entry')));
  await _tap(tester, find.byKey(const ValueKey('akademie-guided-learning')));
  expect(find.byType(GuidedLearningHub), findsOneWidget);
  await _tap(tester, find.byKey(const ValueKey('guided-open-bridge_ten')));
  await _tap(tester, find.byKey(const ValueKey('guided-continue')));
  await _tap(tester, find.byKey(const ValueKey('guided-answer-6')));
  await _tap(tester, find.byKey(const ValueKey('guided-continue')));
  expect(find.text('Acht und fünf'), findsOneWidget);
}

Future<void> _disposeShell(WidgetTester tester, _AndroidReturn android) async {
  if (!android.result.isCompleted) {
    android.deliverResult('learn', callerSession: android.liveCallerSession);
  }
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await _frames(tester, 10);
  await tester.pumpWidget(const SizedBox.shrink());
  await _frames(tester, 10);
  // The singleton transaction queue may last have been advanced by the fake
  // widget clock. Move its final reset to the real async zone while pumping the
  // originating clock; otherwise the next test's ordinary setUp awaits a future
  // owned by the previous, already closed fake clock.
  late Future<void> reset;
  await tester.runAsync(() async {
    reset = RewardWalletRepository.instance.reset();
  });
  await _frames(tester, 10);
  await tester.runAsync(() => reset);
  await tester.binding.setSurfaceSize(null);
  debugDefaultTargetPlatformOverride = null;
}

Future<void> _nativeReturn(WidgetTester tester, _AndroidReturn android,
    String destination, bool resultBeforeResume) async {
  expect(android.launch, isNotNull,
      reason:
          'The actual production button must first launch its native scene.');
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  final readsBefore = android.reads;
  final callerSession = android.liveCallerSession;
  android.recordReturn(destination, callerSession: callerSession);
  // The return is still durable. Hiding it is tied to the live Android caller,
  // not to the current Dart route or a blanket suppression of all game events.
  expect(android.events['destination'], destination);
  expect(android.events['callerReturnSession'], callerSession);
  if (resultBeforeResume) {
    android.deliverResult(destination, callerSession: callerSession);
  }
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await _frames(tester, 30);
  if (!resultBeforeResume) {
    if (callerSession != null) {
      expect(android.events['destination'], destination,
          reason: 'A warm read must not destroy the cold-return fallback.');
      expect(android.maskedReads, greaterThanOrEqualTo(1));
    }
    android.deliverResult(destination, callerSession: callerSession);
    await _frames(tester, 30);
  }
  expect(android.reads, greaterThan(readsBefore),
      reason: 'The real EmbeddedGameService still drains on resume.');
  if (callerSession != null) {
    expect(android.visibleReturnReads, 0);
    expect(android.returnAcks, 0);
    expect(android.consumedReturns, 1);
    expect(android.events.containsKey('destination'), isFalse);
    expect(android.events.containsKey('callerReturnSession'), isFalse);
  } else {
    expect(android.visibleReturnReads, greaterThanOrEqualTo(1));
    expect(android.returnAcks, 1);
    expect(android.consumedReturns, 0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _AndroidReturn android;
  late _CardsMailbox cards;

  setUp(() async {
    android = _AndroidReturn();
    cards = _CardsMailbox();
    SharedPreferences.setMockInitialValues({
      'lumo_3d_save_salt_v1': 'native-return-synthetic-salt',
      'lumo_music_muted': true,
      'lumo_sfx_muted': true,
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              soundEnabled: false,
              aiProxyEnabled: false,
              reduceAnimations: true)
          .toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    LumoMusic.instance.muted = true;
    LumoSound.instance.muted = true;
    await RewardWalletRepository.instance.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, android.handle);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_cards, cards.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_cards, null);
  });

  for (final resultBeforeResume in [true, false]) {
    for (final scene in ['learning', 'cards']) {
      testWidgets(
          '$scene native return retains actual origin route; result before resume=$resultBeforeResume',
          (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final observer = _Routes();
        try {
          final app = await _shell(tester, observer);
          late State originState;
          late Route originRoute;
          String? taskId;
          LumoGameTurnClock? cardsClock;
          List<String>? cardsHand;
          if (scene == 'learning') {
            await _guidedExample(tester);
            originState = tester.state(find.byType(GuidedLessonScreen));
            originRoute =
                ModalRoute.of(tester.element(find.byType(GuidedLessonScreen)))!;
            taskId = LumoCompanionRequests.instance.taskContext.value!.taskId;
            await _tap(tester, find.byKey(const ValueKey('guided-open-3d')));
          } else {
            // A real Navigator push keeps the same production shell and its
            // service below the actual Cards controller/persistence screen.
            app.setSection(LumoSection.games);
            await _frames(tester);
            unawaited(Navigator.of(tester.element(find.byType(AppShell)))
                .push<void>(MaterialPageRoute(
                    builder: (_) => LumoCardsScreen(
                        appState: app, seed: 20, skipIntro: true))));
            await _frames(tester, 50);
            expect(find.byType(LumoCardsScreen), findsOneWidget);
            originState = tester.state(find.byType(LumoCardsScreen));
            originRoute =
                ModalRoute.of(tester.element(find.byType(LumoCardsScreen)))!;
            // _controller and its turnClock are final. Observing that exact
            // public clock instance proves the production controller was not
            // disposed/recreated without exposing private fields in the app.
            cardsClock = tester
                .widget<LumoGamePauseScope>(find.byType(LumoGamePauseScope))
                .clock;
            cardsHand = tester
                .widget<LumoPlayerHand>(find.byType(LumoPlayerHand))
                .cards
                .map((card) => card.id)
                .toList();
            await _tap(
                tester, find.byKey(const ValueKey('cards-native-table')));
            expect(cards.opened?['roundId'], isA<String>());
            expect((cards.opened!['hand'] as List).map((card) => card['id']),
                cardsHand);
          }
          expect(android.launch?['scene'], scene);
          expect(originRoute.isCurrent, isTrue);
          final walletBefore =
              RewardWalletRepository.instance.snapshot.toJson();
          final destination = scene == 'learning' ? 'learn' : 'games';
          await _nativeReturn(tester, android, destination, resultBeforeResume);
          debugPrint(
              '[NativeOriginReturn] scene=$scene resultBeforeResume=$resultBeforeResume '
              'reads=${android.reads} masked=${android.maskedReads} '
              'consumed=${android.consumedReturns} '
              'originCurrent=${originRoute.isCurrent} '
              'originRemoved=${observer.removed.contains(originRoute)} '
              'originMounted=${originState.mounted}');
          expect(originRoute.isCurrent, isTrue,
              reason:
                  'Native illustration/table return must preserve its originating route.');
          expect(originState.mounted, isTrue);
          expect(observer.removed, isNot(contains(originRoute)));
          if (scene == 'learning') {
            expect(find.text('Acht und fünf'), findsOneWidget);
            expect(tester.state(find.byType(GuidedLessonScreen)),
                same(originState));
            expect(LumoCompanionRequests.instance.taskContext.value!.taskId,
                taskId);
          } else {
            expect(
                tester.state(find.byType(LumoCardsScreen)), same(originState));
            expect(
                tester
                    .widget<LumoGamePauseScope>(find.byType(LumoGamePauseScope))
                    .clock,
                same(cardsClock));
            expect(
                tester
                    .widget<LumoPlayerHand>(find.byType(LumoPlayerHand))
                    .cards
                    .map((card) => card.id),
                cardsHand);
            final owner = await app.captureLearningProfile();
            final persisted = await LumoCardsSessionRepository(
                    studentId: owner.studentId,
                    grade: app.state.grade,
                    vsBot: true)
                .load(player1Name: 'Du', player2Name: 'Lumo');
            expect(persisted?.id, cards.opened!['roundId']);
            expect(persisted?.state.players[0].hand.map((card) => card.id),
                cardsHand);
            expect(cards.closes, 1);
          }
          expect(
              RewardWalletRepository.instance.snapshot.toJson(), walletBefore,
              reason: 'Opening and returning must not invent a reward.');
          expect(tester.takeException(), isNull);
        } finally {
          await _disposeShell(tester, android);
        }
      }, timeout: const Timeout(Duration(seconds: 60)));
    }

    testWidgets(
        'warm learning return drains and replays rewards once; result before resume=$resultBeforeResume',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final observer = _Routes();
      try {
        final app = await _shell(tester, observer);
        await _guidedExample(tester);
        final originState = tester.state(find.byType(GuidedLessonScreen));
        final originRoute =
            ModalRoute.of(tester.element(find.byType(GuidedLessonScreen)))!;
        await _tap(tester, find.byKey(const ValueKey('guided-open-3d')));
        final before = RewardWalletRepository.instance.snapshot;
        // An independent, already completed native Kart reward is still in the
        // durable mailbox. It must not be hidden with the warm return marker.
        android.events['results'] = [
          {
            'game': 'kart',
            'resultId': 'separate-completed-race',
            'status': 'completed',
            'stars': 7,
            'xp': 11,
          }
        ];
        android.acknowledgementsToFail = 1;
        await _nativeReturn(tester, android, 'learn', resultBeforeResume);
        expect(android.failedAcks, 1);
        expect((android.events['results'] as List), hasLength(1));
        expect(app.state.stars, before.stars + 7);
        expect(app.state.xp, before.xp + 11);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await _frames(tester, 30);
        expect(android.acknowledgedResults, ['separate-completed-race']);
        expect(android.events['results'], isEmpty);
        expect(app.state.stars, before.stars + 7);
        expect(app.state.xp, before.xp + 11);
        final persistedWallet = await RewardWalletRepository().load();
        expect(persistedWallet.stars, before.stars + 7);
        expect(persistedWallet.xp, before.xp + 11);
        expect(
            persistedWallet.gameResultIds, contains('separate-completed-race'));
        expect(originRoute.isCurrent, isTrue);
        expect(
            tester.state(find.byType(GuidedLessonScreen)), same(originState));
        expect(observer.removed, isNot(contains(originRoute)));
        expect(tester.takeException(), isNull);
        debugPrint(
            '[NativeOriginReward] resultBeforeResume=$resultBeforeResume '
            'failedAck=1 replayedOnce=true originCurrent=true');
      } finally {
        await _disposeShell(tester, android);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  }

  for (final destination in ['learn', 'games']) {
    testWidgets('legacy native Kart return still navigates to $destination',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final observer = _Routes();
      try {
        final app = await _shell(tester, observer);
        late BuildContext originContext;
        final route = MaterialPageRoute<void>(builder: (context) {
          originContext = context;
          return const Scaffold(body: Text('Existing nested game route'));
        });
        unawaited(
            Navigator.of(tester.element(find.byType(AppShell))).push(route));
        await _frames(tester);
        // Call the real legacy launcher; only its Android boundary is mocked.
        final launched =
            launchLumo3D(originContext, appState: app, scene: 'kart');
        await _frames(tester);
        expect(android.launch?['scene'], 'kart');
        expect(android.liveCallerSession, isNull);
        await _nativeReturn(tester, android, destination, false);
        await launched;
        expect(route.isCurrent, isFalse);
        expect(observer.removed, contains(route));
        expect(app.state.section,
            destination == 'learn' ? LumoSection.learn : LumoSection.games);
        expect(android.returnAcks, 1);
        expect(tester.takeException(), isNull);
        debugPrint('[NativeOriginLegacy] destination=$destination '
            'navigated=true acknowledged=1');
      } finally {
        await _disposeShell(tester, android);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    testWidgets('cold owner loss keeps durable return to $destination',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final observer = _Routes();
      try {
        // A recreated MainActivity has no pendingGame Result and owns no prior
        // session. Its real startup service must deliver the persisted fallback.
        android.recordReturn(destination,
            callerSession: 'cb31f7a4-2ccc-4f25-817a-ab4efc6bc5a7');
        expect(android.pendingGame, isFalse);
        expect(android.liveCallerSession, isNull);
        final app = await _shell(tester, observer,
            initialSection:
                destination == 'learn' ? LumoSection.games : LumoSection.learn);
        expect(android.launch, isNull);
        expect(android.visibleReturnReads, 1);
        expect(android.maskedReads, 0);
        expect(android.returnAcks, 1);
        expect(android.consumedReturns, 0);
        expect(android.events.containsKey('destination'), isFalse);
        expect(android.events.containsKey('callerReturnSession'), isFalse);
        expect(app.state.section,
            destination == 'learn' ? LumoSection.learn : LumoSection.games);
        expect(tester.takeException(), isNull);
        debugPrint('[NativeOriginCold] destination=$destination '
            'navigated=true acknowledged=1');
      } finally {
        await _disposeShell(tester, android);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  }
}
