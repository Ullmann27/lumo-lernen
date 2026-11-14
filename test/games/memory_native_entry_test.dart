import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:lumo_lernen/features/lumo3d/native_table_transport.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Unavailable implements NativeTableTransport {
  int opens = 0;
  final closed = <String>[];
  Completer<void>? openGate;
  @override
  Future<void> open(String token, Map<String, Object?> state) async {
    opens++;
    if (openGate != null) {
      await openGate!.future;
      return;
    }
    throw MissingPluginException('No native renderer in this widget test');
  }
  @override
  Future<Map<String, dynamic>> poll(String token) async => {};
  @override
  Future<void> publish(String token, Map<String, Object?> state) async {}
  @override
  Future<void> close(String token) async { closed.add(token); }
}

Future<void> _until(WidgetTester tester, bool Function() predicate, String why,
    {int attempts = 50, Duration step = const Duration(milliseconds: 20)}) async {
  for (var i = 0; i < attempts; i++) {
    if (predicate()) return;
    await tester.pump(step);
  }
  expect(predicate(), isTrue, reason: why);
}

Future<String> _roundKey(LumoAppState app) async {
  final owner = await app.captureLearningProfile();
  return 'lumo.memory.round.v1.${sha256.convert(utf8.encode(owner.studentId))}';
}

Future<Map<String, dynamic>> _round(LumoAppState app) async {
  final prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString(await _roundKey(app))!) as Map<String, dynamic>;
}

Future<LumoAppState> _app() async {
  final app = LumoAppState();
  app.updateSettings(const AppSettings(
      voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
  await app.school.setActiveStudent('native-memory-widget-child');
  return app;
}

Future<void> _open(WidgetTester tester, LumoAppState app, _Unavailable transport,
    {int Function()? turnMilliseconds}) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  await tester.pumpWidget(MaterialApp(
    home: LumoMemoryScreen(key: UniqueKey(), appState: app, seed: 4,
        difficulty: MemoryDifficulty.leicht, nativeTransport: transport,
        turnMilliseconds: turnMilliseconds),
  ));
  await _until(tester, () => find.byKey(const ValueKey('memory-card-7')).evaluate().length == 1,
      'actual loaded Memory board');
  await tester.pump();
}

Future<void> _tapAndSave(WidgetTester tester, LumoAppState app, int index) async {
  final before = (await _round(app))['revision'] as int;
  await tester.tap(find.byKey(ValueKey('memory-card-$index')));
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (((await _round(app))['revision'] as int) > before) return;
  }
  fail('Real card touch did not produce a durable owner round');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Missing native plugin leaves real Flutter cards usable with no cover or snackbar',
      (tester) async {
    final app = await _app();
    final transport = _Unavailable();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app, transport);
    await _until(tester, () => transport.closed.isNotEmpty, 'failed native token closed');
    expect(transport.opens, 1);
    expect(find.byKey(const ValueKey('memory-native-opening')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const ValueKey('lumo-pause-panel')), findsNothing);
    expect(find.byKey(const ValueKey('memory-card-0')).hitTestable(), findsOneWidget);
    await _tapAndSave(tester, app, 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('memory-back-0')), findsNothing);
    expect(((await _round(app))['rules'] as Map)['faceUp'][0], true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A real Flutter pair resolves while optional native Open is still pending',
      (tester) async {
    final app = await _app();
    final gate = Completer<void>();
    final transport = _Unavailable()..openGate = gate;
    var launches = 0;
    const bridge = MethodChannel('lumo_lernen/bridge');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'launch3D') launches++;
      throw MissingPluginException();
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, null));
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app, transport);
    await _until(tester, () => transport.opens == 1, 'actual availability attempt');
    expect(find.byKey(const ValueKey('memory-native-opening')), findsNothing);
    final cards = ((await _round(app))['rules'] as Map)['cards'] as List;
    final other = cards.indexWhere((motif) => motif != cards[0]);
    expect(other, greaterThan(0));
    await _tapAndSave(tester, app, 0);
    await _tapAndSave(tester, app, other);
    final id = (await _round(app))['id'];
    expect(((await _round(app))['rules'] as Map)['phase'], 'resolve');
    // Deliberately leave Open unresolved through a complete real child turn.
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pump();
    final resolved = (await _round(app))['rules'] as Map;
    expect(gate.isCompleted, false);
    expect(resolved['phase'], 'botFirst');
    expect(resolved['turn'], 'lumo');
    expect(resolved['kindMoves'], 1);
    expect(resolved['faceUp'], everyElement(false));
    gate.complete();
    await _until(tester, () => transport.closed.length >= 2, 'late Open token cleaned again');
    expect(launches, 0, reason: 'a user turn wins over a delayed automatic launch');
    expect((await _round(app))['id'], id);
    expect((await _round(app))['paused'], false);
    expect(find.byType(SnackBar), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(((await _round(app))['rules'] as Map)['phase'], 'botSecond',
        reason: 'late native cleanup cannot reset the already scheduled bot turn');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('An unfinished round reopens paused with the same card and explicit Resume',
      (tester) async {
    final app = await _app();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app, _Unavailable());
    await _tapAndSave(tester, app, 0);
    final original = await _round(app);
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, app, _Unavailable());
    await _until(tester, () => find.byKey(const ValueKey('lumo-pause-panel')).evaluate().isNotEmpty,
        'actual restored-round pause');
    final restored = await _round(app);
    expect(restored['id'], original['id']);
    expect(restored['rules'], original['rules']);
    expect(restored['paused'], true);
    await tester.tap(find.text('Fortsetzen'));
    await _until(tester, () => find.byKey(const ValueKey('lumo-pause-panel')).evaluate().isEmpty,
        'actual resume acknowledged');
    expect((await _round(app))['id'], original['id']);
    expect((await _round(app))['paused'], false);
    expect(find.byKey(const ValueKey('memory-back-0')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Lifecycle pause saves the current pair phase and does not silently resume',
      (tester) async {
    final app = await _app();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app, _Unavailable());
    await _tapAndSave(tester, app, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await _until(tester, () => find.byKey(const ValueKey('lumo-pause-panel')).evaluate().isNotEmpty,
        'backgrounding pauses Memory');
    final paused = await _round(app);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect((await _round(app))['rules'], paused['rules']);
    expect((await _round(app))['paused'], true);
    expect(find.byKey(const ValueKey('lumo-pause-panel')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Pause accounts for monotonic elapsed time without an intervening frame',
      (tester) async {
    final app = await _app();
    var milliseconds = 0;
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app, _Unavailable(), turnMilliseconds: () => milliseconds);
    final cards = ((await _round(app))['rules'] as Map)['cards'] as List;
    final other = cards.indexWhere((motif) => motif != cards[0]);
    expect(other, greaterThan(0));
    await _tapAndSave(tester, app, 0);
    await _tapAndSave(tester, app, other);
    expect(((await _round(app))['rules'] as Map)['remainingMs'], 850);
    // No pump/frame between the independent clock change and the real pause
    // input: reduced animations may leave the last frame timestamp stale.
    milliseconds = 300;
    await tester.tap(find.byKey(const ValueKey('memory-close')));
    await _until(tester,
        () => find.byKey(const ValueKey('lumo-pause-panel')).evaluate().isNotEmpty,
        'actual pause input acknowledged');
    for (var i = 0; i < 50 && (await _round(app))['paused'] != true; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    final paused = await _round(app);
    expect(paused['paused'], true);
    expect((paused['rules'] as Map)['phase'], 'resolve');
    expect((paused['rules'] as Map)['remainingMs'], 550);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Profile change removes the old round and leaves its original bytes separate',
      (tester) async {
    final app = await _app();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app, _Unavailable());
    await _tapAndSave(tester, app, 0);
    final prefs = await SharedPreferences.getInstance();
    final oldKey = await _roundKey(app);
    final oldRaw = prefs.getString(oldKey);
    await app.school.setActiveStudent('other-memory-child');
    await tester.pump();
    expect(find.textContaining('Das Kinderprofil hat gewechselt.'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-card-0')), findsNothing);
    await _open(tester, app, _Unavailable());
    expect((await _round(app))['owner'], isNot((jsonDecode(oldRaw!) as Map)['owner']));
    expect(prefs.getString(oldKey), oldRaw);
    expect(((await _round(app))['rules'] as Map)['faceUp'], everyElement(false));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
