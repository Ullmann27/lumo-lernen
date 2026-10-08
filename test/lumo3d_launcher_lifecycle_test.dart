import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

const _bridge = MethodChannel('lumo_lernen/bridge');

/// Delays the actual platform write performed by the first lifetime-wallet load.
class _DelayedWalletStore extends InMemorySharedPreferencesStore {
  _DelayedWalletStore()
      : super.withData({
          'flutter.lumo_3d_save_salt_v1': 'lifecycle-test-salt',
        });

  final walletWriteStarted = Completer<void>();
  final releaseWalletWrite = Completer<void>();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.lumo_reward_wallet_v1') {
      walletWriteStarted.complete();
      await releaseWalletWrite.future;
    }
    return super.setValue(valueType, key, value);
  }
}

class _ControlledState extends LumoAppState {
  _ControlledState(this.save);

  final Future<void> Function() save;
  int flushCalls = 0;
  int generation = 0;
  bool resetInProgress = false;

  @override
  int get profileGeneration => generation;

  @override
  bool get resetting => resetInProgress;

  @override
  Future<void> flushRewards() {
    flushCalls++;
    return save();
  }
}

Future<BuildContext> _mount(WidgetTester tester) async {
  late BuildContext launchContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            launchContext = context;
            return const Text('Spielewelt');
          },
        ),
      ),
    ),
  );
  return launchContext;
}

// Reset test-only platform state before Flutter verifies global invariants.
void launcherTestWidgets(
  String description,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(description, (tester) async {
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

  setUp(() {
    calls.clear();
    SharedPreferences.setMockInitialValues({'lumo_3d_save_salt_v1': 'lifecycle-test-salt'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (call) async {
          calls.add(call);
          return <String, Object?>{'destination': 'games'};
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, null);
    debugDefaultTargetPlatformOverride = null;
  });

  // Keep this before the other launches: the production lifetime-wallet
  // singleton performs its first disk load once per Dart isolate.
  launcherTestWidgets(
    'profile change during lifetime-wallet load cancels stale native launch',
    (tester) async {
      final store = _DelayedWalletStore();
      SharedPreferencesStorePlatform.instance = store;
      final state = _ControlledState(() async {});
      addTearDown(state.dispose);
      final context = await _mount(tester);
      final staleLaunch = launchLumo3D(context, appState: state);
      addTearDown(() async {
        if (!store.releaseWalletWrite.isCompleted) {
          store.releaseWalletWrite.complete();
        }
        await staleLaunch;
      });
      await tester.pump();
      expect(store.walletWriteStarted.isCompleted, isTrue);
      expect(calls, isEmpty);
      state.generation++;
      state.state.childName = 'Neues Kind';
      store.releaseWalletWrite.complete();
      await tester.pump();
      expect(
        await staleLaunch,
        isFalse,
        reason: 'A profile changed while lifetime-wallet storage was pending.',
      );
      expect(calls, isEmpty);
      // Cancelling the stale request must release the launch lock.
      expect(await launchLumo3D(context, appState: state), isTrue);
      expect(calls, hasLength(1));
    },
  );

  launcherTestWidgets('saves rewards first and waits for native return', (
    tester,
  ) async {
    final saved = Completer<void>();
    final returned = Completer<Map<String, Object?>>();
    final state = _ControlledState(() => saved.future);
    addTearDown(state.dispose);
    state.state.stars = 19;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (call) {
          calls.add(call);
          return returned.future;
        });
    final context = await _mount(tester);
    final result = launchLumo3D(
      context,
      scene: 'jump',
      grade: 3,
      subject: 'Deutsch',
      appState: state,
    );
    var finished = false;
    unawaited(result.then((_) => finished = true));
    await tester.pump();
    expect(calls, isEmpty);
    expect(state.flushCalls, 1);
    state.state.stars = 27;
    saved.complete();
    await tester.pump();
    expect(calls.single.method, 'launch3D');
    expect(calls.single.arguments, allOf(
      containsPair('scene', 'jump'), containsPair('grade', 3),
      containsPair('subject', 'Deutsch'), containsPair('stars', 27),
      containsPair('lifetimeStars', greaterThanOrEqualTo(27)),
      containsPair('childKey', matches(r'^p_[0-9a-f]{32}$'))));
    expect(finished, isFalse);
    returned.complete(<String, Object?>{'destination': 'games'});
    await tester.pump();
    expect(await result, isTrue);
  });

  launcherTestWidgets('does not launch from an already removed context', (
    tester,
  ) async {
    final context = await _mount(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    final result = await launchLumo3D(context);
    expect(calls, isEmpty);
    expect(result, isFalse);
  });

  launcherTestWidgets('leaving during reward save cancels the delayed launch', (
    tester,
  ) async {
    final saved = Completer<void>();
    final state = _ControlledState(() => saved.future);
    addTearDown(state.dispose);
    final context = await _mount(tester);
    final result = launchLumo3D(context, appState: state);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    saved.complete();
    await tester.pump();
    final launched = await result;
    expect(calls, isEmpty);
    expect(launched, isFalse);
  });

  launcherTestWidgets(
    'a newer route prevents launch from a covered games page',
    (tester) async {
      final saved = Completer<void>();
      final state = _ControlledState(() => saved.future);
      addTearDown(state.dispose);
      final context = await _mount(tester);
      final result = launchLumo3D(context, appState: state);
      await tester.pump();
      unawaited(
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Anderer Bereich')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(context.mounted, isTrue);
      saved.complete();
      await tester.pump();
      final launched = await result;
      expect(calls, isEmpty);
      expect(launched, isFalse);
    },
  );

  launcherTestWidgets('profile change during save cancels old launch request', (
    tester,
  ) async {
    final saved = Completer<void>();
    final state = _ControlledState(() => saved.future);
    addTearDown(state.dispose);
    final context = await _mount(tester);
    final result = launchLumo3D(context, appState: state);
    await tester.pump();
    state.generation++;
    saved.complete();
    await tester.pump();
    final launched = await result;
    expect(calls, isEmpty);
    expect(launched, isFalse);
  });

  launcherTestWidgets('reset in progress prevents a launch and reward flush', (
    tester,
  ) async {
    final state = _ControlledState(() async {})..resetInProgress = true;
    addTearDown(state.dispose);
    final context = await _mount(tester);
    final result = await launchLumo3D(context, appState: state);
    expect(calls, isEmpty);
    expect(state.flushCalls, 0);
    expect(result, isFalse);
  });

  launcherTestWidgets('two taps while saving start only one native game', (
    tester,
  ) async {
    final saved = Completer<void>();
    final state = _ControlledState(() => saved.future);
    addTearDown(state.dispose);
    final context = await _mount(tester);
    final first = launchLumo3D(context, appState: state);
    final second = launchLumo3D(context, appState: state);
    await tester.pump();
    saved.complete();
    await tester.pump();
    final results = await Future.wait(<Future<bool>>[first, second]);
    expect(calls, hasLength(1));
    expect(state.flushCalls, 1);
    expect(results, <bool>[true, false]);
  });

  launcherTestWidgets(
    'recreated games page cannot launch while native game is open',
    (tester) async {
      final returned = Completer<Map<String, Object?>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_bridge, (call) {
            calls.add(call);
            return returned.future;
          });
      final firstContext = await _mount(tester);
      final first = launchLumo3D(firstContext);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      final secondContext = await _mount(tester);
      final second = launchLumo3D(secondContext);
      await tester.pump();
      returned.complete(<String, Object?>{'destination': 'games'});
      await tester.pump();
      final results = await Future.wait(<Future<bool>>[first, second]);
      expect(calls, hasLength(1));
      expect(results, <bool>[true, false]);
    },
  );

  launcherTestWidgets(
    'reward save failure blocks launch and explains safe retry',
    (tester) async {
      var fail = true;
      final state = _ControlledState(() async {
        if (fail) throw StateError('test save failed');
      });
      addTearDown(state.dispose);
      final context = await _mount(tester);
      final first = await launchLumo3D(context, appState: state);
      await tester.pump();
      expect(first, isFalse);
      expect(calls, isEmpty);
      final notices = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ');
      expect(notices, contains('Sterne'));
      expect(notices, isNot(contains('schließe Lumo')));
      fail = false;
      expect(await launchLumo3D(context, appState: state), isTrue);
      expect(calls, hasLength(1));
    },
  );

  launcherTestWidgets('native busy error is not a restart instruction', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (_) async {
          throw PlatformException(code: 'game_running');
        });
    final context = await _mount(tester);
    expect(await launchLumo3D(context), isFalse);
    await tester.pump();
    final notices = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .join(' ');
    expect(notices, contains('bereits'));
    expect(notices, isNot(contains('schließe Lumo')));
  });

  launcherTestWidgets('native failure releases lock for a later retry', (
    tester,
  ) async {
    var fail = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (call) async {
          calls.add(call);
          if (fail) throw PlatformException(code: 'game_unavailable');
          return <String, Object?>{'destination': 'games'};
        });
    final context = await _mount(tester);
    expect(await launchLumo3D(context), isFalse);
    fail = false;
    expect(await launchLumo3D(context), isTrue);
    expect(calls, hasLength(2));
  });

  launcherTestWidgets(
    'null native response is not a confirmed successful return',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_bridge, (_) async => null);
      final context = await _mount(tester);
      expect(await launchLumo3D(context), isFalse);
    },
  );

  launcherTestWidgets(
    'missing native plugin fails safely and remains retryable',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_bridge, (_) async {
            throw MissingPluginException('test missing plugin');
          });
      final context = await _mount(tester);
      expect(await launchLumo3D(context), isFalse);
      expect(tester.takeException(), isNull);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _bridge,
            (_) async => <String, Object?>{'destination': 'games'},
          );
      expect(await launchLumo3D(context), isTrue);
    },
  );

  launcherTestWidgets('non Android does not flush rewards or invoke bridge', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = _ControlledState(() async {});
    addTearDown(state.dispose);
    final context = await _mount(tester);
    expect(await launchLumo3D(context, appState: state), isFalse);
    expect(calls, isEmpty);
    expect(state.flushCalls, 0);
    await tester.pump();
    expect(find.textContaining('Android-App'), findsOneWidget);
  });
}
