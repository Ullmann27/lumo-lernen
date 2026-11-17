import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

const _bridge = MethodChannel('lumo_lernen/bridge');
const _token = '0123456789abcdef0123456789abcdef';
const _otherToken = 'fedcba9876543210fedcba9876543210';

class _GatedApp extends LumoAppState {
  _GatedApp() : super(walletRepository: RewardWalletRepository());
  Completer<void>? gate;
  int flushCalls = 0;

  @override
  Future<void> flushRewards() async {
    flushCalls++;
    if (gate != null) await gate!.future;
    await super.flushRewards();
  }
}

Future<_GatedApp> _app() async {
  final app = _GatedApp();
  addTearDown(() {
    if (app.gate != null && !app.gate!.isCompleted) app.gate!.complete();
    app.dispose();
  });
  await app.school.setActiveStudent('table-launch-child-a');
  return app;
}

Future<BuildContext> _mount(WidgetTester tester) async {
  late BuildContext result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            result = context;
            return const Text('Spielewelt');
          },
        ),
      ),
    ),
  );
  return result;
}

Future<void> _until(WidgetTester tester, bool Function() predicate) async {
  for (var step = 0; step < 100; step++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (predicate()) return;
  }
  fail('The expected launcher event did not occur within 100 × 20 ms.');
}

void _androidTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, timeout: const Timeout(Duration(seconds: 20)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    calls.clear();
    SharedPreferences.setMockInitialValues({
      'lumo_3d_save_salt_v1': 'table-launch-regression-salt',
      'lumo_reward_wallet_v1': jsonEncode(const RewardWallet().toJson()),
    });
    messenger.setMockMethodCallHandler(_bridge, (call) async {
      if (call.method != 'launch3D') throw MissingPluginException(call.method);
      calls.add(call);
      return <String, Object?>{'destination': 'games'};
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(_bridge, null);
    debugDefaultTargetPlatformOverride = null;
  });

  _androidTest('Table launch rejects malformed or misplaced authority tokens', (
    tester,
  ) async {
    final app = await _app();
    final context = await _mount(tester);
    for (final scene in ['memory', 'quiz']) {
      for (final token in <String?>[null, '', 'short', _token.toUpperCase()]) {
        expect(
          await launchLumo3D(
            context,
            scene: scene,
            appState: app,
            tableToken: token,
          ),
          isFalse,
        );
      }
      expect(
        await launchLumo3D(context, scene: scene, tableToken: _token),
        isFalse,
        reason: 'A table authority must have a captured application profile.',
      );
      expect(
        await launchLumo3D(
          context,
          scene: scene,
          appState: app,
          tableToken: _token,
          connectFourToken: _otherToken,
        ),
        isFalse,
      );
    }
    for (final scene in ['kart', 'jump', 'build', 'puzzle', 'treasure']) {
      expect(
        await launchLumo3D(
          context,
          scene: scene,
          appState: app,
          tableToken: _token,
        ),
        isFalse,
      );
    }
    expect(calls, isEmpty);
    expect(app.flushCalls, 0);
  });

  for (final game in ['memory', 'quiz']) {
    _androidTest('$game sends the same token and waits for an actual return', (
      tester,
    ) async {
      final app = await _app();
      final context = await _mount(tester);
      final returned = Completer<Map<String, Object?>>();
      messenger.setMockMethodCallHandler(_bridge, (call) {
        calls.add(call);
        return returned.future;
      });
      addTearDown(() {
        if (!returned.isCompleted) returned.complete({'destination': 'games'});
      });
      final pending = launchLumo3D(
        context,
        scene: game,
        appState: app,
        tableToken: _token,
      );
      var done = false;
      unawaited(pending.then((_) => done = true));
      await _until(tester, () => calls.isNotEmpty);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'launch3D');
      final options = Map<String, Object?>.from(calls.single.arguments as Map);
      expect(options['scene'], game);
      expect(options['tableToken'], _token);
      expect(options['childKey'], matches(r'^p_[0-9a-f]{32}$'));
      expect(options.containsKey('cardsToken'), isFalse);
      expect(options.containsKey('connectFourToken'), isFalse);
      expect(options.containsKey('learning'), isFalse);
      expect(app.flushCalls, 1);
      expect(done, isFalse);
      returned.complete({'destination': 'games'});
      await _until(tester, () => done);
      expect(await pending, isTrue);
    });

    _androidTest(
      '$game cannot launch after profile change during reward flush',
      (tester) async {
        final app = await _app();
        app.gate = Completer<void>();
        final context = await _mount(tester);
        final pending = launchLumo3D(
          context,
          scene: game,
          appState: app,
          tableToken: _token,
        );
        await _until(tester, () => app.flushCalls == 1);
        expect(calls, isEmpty);
        await app.school.setActiveStudent('table-launch-child-b');
        app.gate!.complete();
        await tester.pump();
        expect(await pending, isFalse);
        expect(calls, isEmpty);
        final retry = launchLumo3D(
          context,
          scene: game,
          appState: app,
          tableToken: _otherToken,
        );
        await _until(tester, () => calls.isNotEmpty);
        expect(await retry, isTrue);
        expect((calls.single.arguments as Map)['tableToken'], _otherToken);
      },
    );

    _androidTest(
      '$game old return cannot acknowledge a different active child',
      (tester) async {
        final app = await _app();
        final context = await _mount(tester);
        final returned = Completer<Map<String, Object?>>();
        messenger.setMockMethodCallHandler(_bridge, (call) {
          calls.add(call);
          return returned.future;
        });
        addTearDown(() {
          if (!returned.isCompleted)
            returned.complete({'destination': 'games'});
        });
        final pending = launchLumo3D(
          context,
          scene: game,
          appState: app,
          tableToken: _token,
        );
        await _until(tester, () => calls.isNotEmpty);
        final oldArguments = Map<String, Object?>.from(
          calls.single.arguments as Map,
        );
        await app.school.setActiveStudent('table-launch-child-b');
        returned.complete({'destination': 'games'});
        await tester.pump();
        expect(await pending, isFalse);
        expect(calls, hasLength(1));
        expect(calls.single.arguments, oldArguments);
        expect(app.school.cachedActiveStudentId, 'table-launch-child-b');
      },
    );
  }

  _androidTest(
    'Memory and Quiz share the existing single native-launch lease',
    (tester) async {
      final app = await _app();
      final context = await _mount(tester);
      final returned = Completer<Map<String, Object?>>();
      messenger.setMockMethodCallHandler(_bridge, (call) {
        calls.add(call);
        return returned.future;
      });
      addTearDown(() {
        if (!returned.isCompleted) returned.complete({'destination': 'games'});
      });
      final first = launchLumo3D(
        context,
        scene: 'memory',
        appState: app,
        tableToken: _token,
      );
      await _until(tester, () => calls.isNotEmpty);
      expect(
        await launchLumo3D(
          context,
          scene: 'quiz',
          appState: app,
          tableToken: _otherToken,
        ),
        isFalse,
      );
      expect(calls, hasLength(1));
      returned.complete({'destination': 'games'});
      await tester.pump();
      expect(await first, isTrue);
    },
  );

  _androidTest(
    'Missing plugin is a failed launch and releases the shared lease',
    (tester) async {
      final app = await _app();
      final context = await _mount(tester);
      messenger.setMockMethodCallHandler(_bridge, (call) async {
        calls.add(call);
        throw MissingPluginException('No installed engine in this test');
      });
      final failed = launchLumo3D(
        context,
        scene: 'quiz',
        appState: app,
        tableToken: _token,
      );
      await _until(tester, () => calls.isNotEmpty);
      expect(await failed, isFalse);
      messenger.setMockMethodCallHandler(_bridge, (call) async {
        calls.add(call);
        return <String, Object?>{'destination': 'games'};
      });
      final next = launchLumo3D(
        context,
        scene: 'memory',
        appState: app,
        tableToken: _otherToken,
      );
      await _until(tester, () => calls.length == 2);
      expect(await next, isTrue);
    },
  );

  _androidTest(
    'A missing destination does not become a successful table return',
    (tester) async {
      final app = await _app();
      final context = await _mount(tester);
      messenger.setMockMethodCallHandler(_bridge, (call) async {
        calls.add(call);
        return <String, Object?>{};
      });
      final pending = launchLumo3D(
        context,
        scene: 'memory',
        appState: app,
        tableToken: _token,
      );
      await _until(tester, () => calls.isNotEmpty);
      expect(await pending, isFalse);
    },
  );
}
