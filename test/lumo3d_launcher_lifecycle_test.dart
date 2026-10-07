import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/app/app_state.dart';
import '../lib/features/lumo3d/lumo3d_launcher.dart';

const _bridge = MethodChannel('lumo_lernen/bridge');

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
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) {
        launchContext = context;
        return const Text('Spielewelt');
      }),
    ),
  ));
  return launchContext;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
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

  testWidgets('saves rewards first and waits for native return', (tester) async {
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
    final result = launchLumo3D(context,
        scene: 'jump', grade: 3, subject: 'Deutsch', appState: state);
    var finished = false;
    unawaited(result.then((_) => finished = true));
    await tester.pump();
    expect(calls, isEmpty);
    expect(state.flushCalls, 1);
    state.state.stars = 27;
    saved.complete();
    await tester.pump();
    expect(calls.single.method, 'launch3D');
    expect(calls.single.arguments, <String, Object?>{
      'scene': 'jump', 'grade': 3, 'subject': 'Deutsch', 'stars': 27,
    });
    expect(finished, isFalse);
    returned.complete(<String, Object?>{'destination': 'games'});
    await tester.pump();
    expect(await result, isTrue);
  });

  testWidgets('does not launch from an already removed context', (tester) async {
    final context = await _mount(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    final result = await launchLumo3D(context);
    expect(calls, isEmpty);
    expect(result, isFalse);
  });

  testWidgets('leaving during reward save cancels the delayed launch',
      (tester) async {
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

  testWidgets('a newer route prevents launch from a covered games page',
      (tester) async {
    final saved = Completer<void>();
    final state = _ControlledState(() => saved.future);
    addTearDown(state.dispose);
    final context = await _mount(tester);
    final result = launchLumo3D(context, appState: state);
    await tester.pump();
    unawaited(Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Anderer Bereich')),
    )));
    await tester.pumpAndSettle();
    expect(context.mounted, isTrue);
    saved.complete();
    await tester.pump();
    final launched = await result;
    expect(calls, isEmpty);
    expect(launched, isFalse);
  });

  testWidgets('profile change during save cancels old launch request',
      (tester) async {
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

  testWidgets('reset in progress prevents a launch and reward flush',
      (tester) async {
    final state = _ControlledState(() async {})..resetInProgress = true;
    addTearDown(state.dispose);
    final context = await _mount(tester);
    final result = await launchLumo3D(context, appState: state);
    expect(calls, isEmpty);
    expect(state.flushCalls, 0);
    expect(result, isFalse);
  });

  testWidgets('two taps while saving start only one native game',
      (tester) async {
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

  testWidgets('recreated games page cannot launch while native game is open',
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
  });

  testWidgets('reward save failure blocks launch and explains safe retry',
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
    final notices = tester.widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '').join(' ');
    expect(notices, contains('Sterne'));
    expect(notices, isNot(contains('schließe Lumo')));
    fail = false;
    expect(await launchLumo3D(context, appState: state), isTrue);
    expect(calls, hasLength(1));
  });

  testWidgets('native busy error is not a restart instruction', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (_) async {
      throw PlatformException(code: 'game_running');
    });
    final context = await _mount(tester);
    expect(await launchLumo3D(context), isFalse);
    await tester.pump();
    final notices = tester.widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '').join(' ');
    expect(notices, contains('bereits'));
    expect(notices, isNot(contains('schließe Lumo')));
  });

  testWidgets('native failure releases lock for a later retry', (tester) async {
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

  testWidgets('null native response is not a confirmed successful return',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (_) async => null);
    final context = await _mount(tester);
    expect(await launchLumo3D(context), isFalse);
  });

  testWidgets('missing native plugin fails safely and remains retryable',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, null);
    final context = await _mount(tester);
    expect(await launchLumo3D(context), isFalse);
    expect(tester.takeException(), isNull);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_bridge, (_) async =>
            <String, Object?>{'destination': 'games'});
    expect(await launchLumo3D(context), isTrue);
  });

  testWidgets('non Android does not flush rewards or invoke bridge',
      (tester) async {
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
