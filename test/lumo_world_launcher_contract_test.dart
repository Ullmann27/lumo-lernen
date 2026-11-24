import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bridge = MethodChannel('lumo_lernen/bridge');
const _request = <String, Object>{
  'version': 1,
  'id': 'school_numbers',
  'requestId': 'world-school-request-001',
  'subject': 'Mathematik',
  'grade': 2,
  'returnGame': 'world',
};
const _receipt = <String, Object>{
  'version': 1,
  'missionId': 'school_numbers',
  'requestId': 'world-school-request-001',
  'subject': 'Mathematik',
  'grade': 2,
  'returnGame': 'world',
  'completed': true,
};

class _OwnerState extends LumoAppState {
  int generation = 0;
  @override
  int get profileGeneration => generation;

  @override
  Future<void> flushRewards() async {}
}

Future<BuildContext> _mount(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Builder(builder: (value) {
      context = value;
      return const Text('World origin');
    })),
  ));
  return context;
}

void _androidTest(
  String name,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    SharedPreferences.setMockInitialValues({
      'lumo_3d_save_salt_v1': 'world-launcher-test-salt',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (call) async {
      calls.add(call);
      return {'destination': 'games'};
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, null);
  });

  test('World requests normalize integral JSON and retain the request ID', () {
    expect(parseWorldMission(jsonEncode(_request), grade: 2), _request);
    expect(
      parseWorldMission(
        jsonEncode({..._request, 'version': 1.0, 'grade': 2.0}),
        grade: 2,
      ),
      _request,
    );
    expect(parseWorldMission(jsonEncode(_request), grade: 3), isNull);
  });

  test('World requests reject incomplete, foreign and oversized messages', () {
    for (final raw in <Object?>[
      null,
      _request,
      '',
      '{',
      '[]',
      'true',
      '1',
      ' ' * 2001,
      jsonEncode({..._request, 'requestId': 'x' * 2001}),
    ]) {
      expect(parseWorldMission(raw, grade: 2), isNull);
    }
    for (final key in _request.keys) {
      final missing = Map<String, Object>.from(_request)..remove(key);
      expect(parseWorldMission(jsonEncode(missing), grade: 2), isNull,
          reason: 'Missing $key');
    }
    for (final change in <Map<String, Object>>[
      {'version': true},
      {'version': '1'},
      {'version': 1.5},
      {'version': 2},
      {'grade': true},
      {'grade': '2'},
      {'grade': 2.5},
      {'grade': 0},
      {'grade': 5},
      {'id': 'another_mission'},
      {'subject': 'Deutsch'},
      {'returnGame': 'kart'},
      {'requestId': 'short'},
      {'requestId': 'bad request'},
      {'requestId': 'x' * 161},
      {'owner': 'another-child'},
      {'childKey': 'another-child'},
      {'stars': 100},
    ]) {
      expect(parseWorldMission(jsonEncode({..._request, ...change}), grade: 2),
          isNull,
          reason: change.toString());
    }
  });

  test('World receipts require completed work and cannot override ownership',
      () {
    expect(parseWorldLearningReceipt(_receipt, grade: 2), _receipt);
    expect(
      parseWorldLearningReceipt({..._receipt, 'version': 1.0, 'grade': 2.0},
          grade: 2),
      _receipt,
    );
    expect(parseWorldLearningReceipt(_receipt, grade: 3), isNull);
    for (final key in _receipt.keys) {
      final missing = Map<String, Object>.from(_receipt)..remove(key);
      expect(parseWorldLearningReceipt(missing, grade: 2), isNull,
          reason: 'Missing receipt $key');
    }
    for (final change in <Map<String, Object?>>[
      {'completed': false},
      {'completed': 'true'},
      {'completed': 1},
      {'completed': null},
      {'version': true},
      {'version': '1'},
      {'version': 1.25},
      {'grade': true},
      {'grade': '2'},
      {'grade': 2.25},
      {'grade': double.nan},
      {'grade': double.infinity},
      {'missionId': 'another_mission'},
      {'subject': 'Deutsch'},
      {'returnGame': 'kart'},
      {'requestId': 'x' * 161},
      {'owner': 'another-child'},
      {'childKey': 'another-child'},
      {'stars': 100},
    ]) {
      expect(
          parseWorldLearningReceipt({..._receipt, ...change}, grade: 2), isNull,
          reason: change.toString());
    }
  });

  _androidTest('valid World launch binds receipt to the captured save key',
      (tester) async {
    final app = _OwnerState();
    addTearDown(app.dispose);
    Map<String, Object?>? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (call) async {
      calls.add(call);
      return {'destination': 'learn', 'worldMission': jsonEncode(_request)};
    });
    final context = await _mount(tester);
    final pending = launchLumo3D(
      context,
      scene: 'world',
      grade: 2,
      appState: app,
      worldLearningReceipt: _receipt,
      onWorldMission: (value) => received = value,
    );
    await tester.pump();
    expect(await pending, isTrue);
    expect(received, _request);
    expect(calls, hasLength(1));
    final payload = calls.single.arguments as Map;
    expect(payload['worldLearningReceipt'], _receipt);
    expect(payload['childKey'], matches(r'^p_[0-9a-f]{32}$'));
    expect(payload['scene'], 'world');
  });

  _androidTest('invalid receipt and another scene never invoke Android',
      (tester) async {
    final context = await _mount(tester);
    expect(
      await launchLumo3D(context,
          scene: 'world',
          grade: 2,
          worldLearningReceipt: {..._receipt, 'completed': false}),
      isFalse,
    );
    expect(
      await launchLumo3D(context,
          scene: 'world',
          grade: 2,
          worldLearningReceipt: {..._receipt, 'owner': 'another-child'}),
      isFalse,
    );
    expect(
      await launchLumo3D(context,
          scene: 'kart', grade: 2, worldLearningReceipt: _receipt),
      isFalse,
    );
    expect(
      await launchLumo3D(context, scene: 'world', grade: 0),
      isFalse,
    );
    expect(calls, isEmpty);
  });

  _androidTest('profile change while World is open discards its school return',
      (tester) async {
    final app = _OwnerState();
    addTearDown(app.dispose);
    final returned = Completer<Map<String, Object>>();
    var callbacks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (call) {
      calls.add(call);
      return returned.future;
    });
    final context = await _mount(tester);
    final pending = launchLumo3D(context,
        scene: 'world',
        grade: 2,
        appState: app,
        onWorldMission: (_) => callbacks++);
    await tester.pump();
    expect(calls, hasLength(1));
    app.generation++;
    returned.complete(
        {'destination': 'learn', 'worldMission': jsonEncode(_request)});
    await tester.pump();
    expect(await pending, isFalse);
    expect(callbacks, 0);
  });

  _androidTest('covered origin never opens a late school mission',
      (tester) async {
    final returned = Completer<Map<String, Object>>();
    var callbacks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (_) => returned.future);
    final context = await _mount(tester);
    final pending = launchLumo3D(context,
        scene: 'world', grade: 2, onWorldMission: (_) => callbacks++);
    await tester.pump();
    unawaited(Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Another page')))));
    await tester.pumpAndSettle();
    returned.complete(
        {'destination': 'learn', 'worldMission': jsonEncode(_request)});
    await tester.pump();
    expect(await pending, isTrue);
    expect(callbacks, 0);
    expect(find.text('Another page'), findsOneWidget);
  });

  _androidTest('unrelated or malformed native returns do not start school',
      (tester) async {
    final context = await _mount(tester);
    var callbacks = 0;
    for (final response in <Map<String, Object>>[
      {'destination': 'games', 'worldMission': jsonEncode(_request)},
      {'destination': 'learn', 'worldMission': '{'},
      {'destination': 'learn', 'worldMission': 'x' * 2001},
      {
        'destination': 'learn',
        'worldMission': jsonEncode({..._request, 'grade': 3}),
      },
      {
        'destination': 'learn',
        'worldMission': jsonEncode({..._request, 'owner': 'another-child'}),
      },
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_bridge, (_) async => response);
      final pending = launchLumo3D(context,
          scene: 'world', grade: 2, onWorldMission: (_) => callbacks++);
      await tester.pump();
      expect(await pending, isTrue);
    }
    expect(callbacks, 0);
  });
}
