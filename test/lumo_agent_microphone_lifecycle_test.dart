import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a microphone start pending during pause cannot revive on resume',
      (tester) async {
    const settings = AppSettings(
      microphoneEnabled: true,
      voiceEnabled: false,
      autoReadEnabled: false,
      reduceAnimations: true,
    );
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(settings.toJson()),
    });
    final app = LumoAppState();
    await app.ensureSettingsLoaded();
    final originalVoiceEnabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    final initialize = Completer<bool>();
    final calls = <MethodCall>[];
    const speech = MethodChannel('plugin.csdcorp.com/speech_to_text');
    final messenger = tester.binding.defaultBinaryMessenger;
    void resumeApp() {
      if (tester.binding.lifecycleState == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      }
      if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }

    messenger.setMockMethodCallHandler(speech, (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => initialize.future,
        'locales' => <String>['de_AT:Deutsch (Österreich)'],
        'listen' => true,
        'stop' || 'cancel' => null,
        _ => throw StateError('Unexpected speech method: ${call.method}'),
      };
    });
    addTearDown(() async {
      if (!initialize.isCompleted) initialize.complete(false);
      resumeApp();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      messenger.setMockMethodCallHandler(speech, null);
      app.dispose();
      LumoVoice.instance.isEnabled = originalVoiceEnabled;
      await tester.binding.setSurfaceSize(null);
    });
    resumeApp();
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LumoAgentContent(appState: app, onSection: (_) {}),
      ),
    ));
    await tester.pump();

    final speak = find.widgetWithText(FilledButton, 'Sprechen');
    await tester.ensureVisible(speak);
    await tester.tap(speak);
    await tester.pump();
    expect(calls.where((call) => call.method == 'initialize'), hasLength(1));
    expect(calls.where((call) => call.method == 'listen'), isEmpty);

    // Reproduce a real pending native initialization. Returning to the app
    // before it completes must not make the old tap a new recording request.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    resumeApp();
    await tester.pump();
    initialize.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls.where((call) => call.method == 'listen'), isEmpty,
        reason: 'The microphone request belongs to the pre-pause context.');
    expect(find.text('Zuhören …'), findsNothing);

    // Cancellation must not permanently disable the microphone. Only a new
    // explicit tap may start the actual on-device recognition path.
    await tester.tap(speak);
    await tester.pump();
    final listens = calls.where((call) => call.method == 'listen');
    expect(listens, hasLength(1));
    expect((listens.single.arguments as Map)['onDevice'], isTrue);
    expect(find.text('Zuhören …'), findsOneWidget);
    expect((app.state.stars, app.state.xp), (0, 0));
    expect(app.state.solved, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
