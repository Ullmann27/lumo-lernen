import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _legacy = '{"difficulty":"profi","best":{"profi":41}}';
const _a = 'memory-child-a';
const _b = 'memory-child-b';
String _key(String id) =>
    'lumo.memory.stats.v1.${sha256.convert(utf8.encode(id))}';

class _DeferredStore extends InMemorySharedPreferencesStore {
  _DeferredStore(Map<String, Object> initial)
      : super.withData(initial.map((key, value) => MapEntry('flutter.$key', value)));
  String? blockedKey;
  Completer<void>? gate;
  final writes = <({String key, String value})>[];

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key.startsWith('flutter.lumo.memory.stats.v1.')) {
      writes.add((key: key, value: value as String));
      if (key == blockedKey && gate != null) await gate!.future;
    }
    return super.setValue(type, key, value);
  }

  Future<Map<String, Object>> disk() => super.getAll();
}

class _DeferredIdentityApp extends LumoAppState {
  Completer<void>? nextCapture;
  @override
  Future<LearningProfileLease> captureLearningProfile() {
    final original = super.captureLearningProfile();
    final gate = nextCapture;
    nextCapture = null;
    if (gate == null) return original;
    return original.then((owner) async {
      await gate.future;
      return owner;
    });
  }
}

Finder _backs() => find.byWidgetPredicate((widget) =>
    widget.key is ValueKey<String> &&
    (widget.key! as ValueKey<String>).value.startsWith('memory-back-'));

Future<void> _open(WidgetTester tester, LumoAppState app,
    {MemoryDifficulty? difficulty}) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  await tester.pumpWidget(MaterialApp(
      home: LumoMemoryScreen(
          key: UniqueKey(), appState: app, seed: 4, difficulty: difficulty)));
  await tester.pump();
  await tester.pump();
}

Future<void> _choose(WidgetTester tester, MemoryDifficulty difficulty) async {
  await tester.tap(find.byKey(ValueKey('memory-diff-${difficulty.name}')));
  await tester.pump();
  await tester.pump();
}

Future<LumoAppState> _app({LumoAppState? app}) async {
  final result = app ?? LumoAppState();
  result.updateSettings(const AppSettings(
      voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
  await result.school.setActiveStudent(_a);
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Old unowned record stays byte-identical and is assigned to no child',
      (tester) async {
    SharedPreferences.setMockInitialValues({'lumo_memory_v2': _legacy});
    final app = await _app();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app);
    expect(_backs(), findsNWidgets(16));
    expect(find.textContaining('Dein Rekord:'), findsNothing);
    await app.school.setActiveStudent(_b);
    await tester.pump();
    expect(find.textContaining('Das Kinderprofil hat gewechselt.'), findsOneWidget);
    expect(_backs(), findsNothing);
    await _open(tester, app);
    expect(_backs(), findsNWidgets(16));
    expect(find.textContaining('Dein Rekord:'), findsNothing);
    await _choose(tester, MemoryDifficulty.leicht);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_memory_v2'), _legacy);
    expect(prefs.getString(_key(_a)), isNull);
    expect(jsonDecode(prefs.getString(_key(_b))!),
        {'difficulty': 'leicht', 'best': {}});
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Real completed round restores only its child best and difficulty',
      (tester) async {
    final bRaw = jsonEncode({'difficulty': 'mittel', 'best': {'mittel': 11}});
    SharedPreferences.setMockInitialValues({'lumo_memory_v2': _legacy, _key(_b): bRaw});
    var app = await _app();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app, difficulty: MemoryDifficulty.leicht);
    final deck = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
    for (final motif in deck.toSet()) {
      final first = deck.indexOf(motif);
      final second = deck.indexOf(motif, first + 1);
      await tester.tap(find.byKey(ValueKey('memory-card-$first')));
      await tester.tap(find.byKey(ValueKey('memory-card-$second')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 600));
    }
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(_key(_a))!),
        {'difficulty': 'leicht', 'best': {'leicht': 4}});
    expect(prefs.getString(_key(_b)), bRaw);
    expect(prefs.getString('lumo_memory_v2'), _legacy);
    expect(find.text('Du hast gewonnen!'), findsOneWidget);
    await app.school.setActiveStudent(_b);
    await tester.pump();
    await tester.pump();
    expect(find.text('Du hast gewonnen!'), findsNothing,
        reason: 'Previous child result must not remain in a Navigator overlay');
    expect(find.textContaining('Das Kinderprofil hat gewechselt.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();

    // A new application object proves restoration, rather than retained State.
    app = await _app();
    addTearDown(app.dispose);
    await _open(tester, app);
    expect(_backs(), findsNWidgets(8));
    expect(find.text('Dein Rekord: 4 Züge'), findsOneWidget);
    await app.school.setActiveStudent(_b);
    await _open(tester, app);
    expect(_backs(), findsNWidgets(12));
    expect(find.text('Dein Rekord: 11 Züge'), findsOneWidget);
    expect(find.text('Dein Rekord: 4 Züge'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Delayed old-child write cannot overwrite the newly selected child',
      (tester) async {
    final store = _DeferredStore({
      'lumo_memory_v2': _legacy,
      _key(_a): '{"difficulty":"leicht","best":{"leicht":7}}',
      _key(_b): '{"difficulty":"mittel","best":{"mittel":11}}',
    });
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app);
    final gate = Completer<void>();
    store.blockedKey = 'flutter.${_key(_a)}';
    store.gate = gate;
    await _choose(tester, MemoryDifficulty.profi);
    expect(store.writes, hasLength(1));
    await app.school.setActiveStudent(_b);
    await tester.pump();
    expect(_backs(), findsNothing);
    expect(find.textContaining('Dein Rekord:'), findsNothing);
    await _open(tester, app);
    expect(find.text('Dein Rekord: 11 Züge'), findsOneWidget);
    await _choose(tester, MemoryDifficulty.knifflig);
    gate.complete();
    await tester.pump();
    await tester.pump();
    final disk = await store.disk();
    expect(jsonDecode(disk['flutter.${_key(_a)}']! as String),
        {'difficulty': 'profi', 'best': {'leicht': 7}});
    expect(jsonDecode(disk['flutter.${_key(_b)}']! as String),
        {'difficulty': 'knifflig', 'best': {'mittel': 11}});
    expect(disk['flutter.lumo_memory_v2'], _legacy);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Delayed identity load cannot expose old best after profile switch',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      _key(_a): '{"difficulty":"leicht","best":{"leicht":7}}',
      _key(_b): '{"difficulty":"mittel","best":{"mittel":11}}',
    });
    final delayed = _DeferredIdentityApp();
    final app = await _app(app: delayed);
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gate = Completer<void>();
    delayed.nextCapture = gate;
    await _open(tester, app);
    await app.school.setActiveStudent(_b);
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Das Kinderprofil hat gewechselt.'), findsOneWidget);
    expect(find.textContaining('Dein Rekord:'), findsNothing);
    await _open(tester, app);
    expect(find.text('Dein Rekord: 11 Züge'), findsOneWidget);
    expect(find.text('Dein Rekord: 7 Züge'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Pending successive choices retain captured snapshots and final order',
      (tester) async {
    final store = _DeferredStore({
      _key(_a): '{"difficulty":"leicht","best":{"leicht":7}}',
    });
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app);
    final gate = Completer<void>();
    store.blockedKey = 'flutter.${_key(_a)}';
    store.gate = gate;
    await _choose(tester, MemoryDifficulty.mittel);
    await _choose(tester, MemoryDifficulty.profi);
    expect(store.writes, hasLength(1), reason: 'Second write waits for the first');
    expect(jsonDecode(store.writes.single.value)['difficulty'], 'mittel');
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(store.writes, hasLength(2));
    expect(jsonDecode(store.writes.last.value)['difficulty'], 'profi');
    expect(jsonDecode((await store.disk())['flutter.${_key(_a)}']! as String),
        {'difficulty': 'profi', 'best': {'leicht': 7}});
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Unreadable existing child stats are preserved instead of reset',
      (tester) async {
    SharedPreferences.setMockInitialValues({_key(_a): '{broken', 'lumo_memory_v2': _legacy});
    final app = await _app();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, app);
    await _choose(tester, MemoryDifficulty.leicht);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_key(_a)), '{broken');
    expect(prefs.getString('lumo_memory_v2'), _legacy);
    expect(_backs(), findsNWidgets(8));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
