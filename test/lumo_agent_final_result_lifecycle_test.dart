import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stop wins over a final transcript awaiting native cancellation',
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
    const speech = MethodChannel('plugin.csdcorp.com/speech_to_text');
    final messenger = tester.binding.defaultBinaryMessenger;
    final heldCancel = Completer<void>();
    final enteredCancel = Completer<void>();
    var holdNextCancel = false;
    var listenCalls = 0;
    messenger.setMockMethodCallHandler(speech, (call) async {
      if (call.method == 'cancel' && holdNextCancel) {
        holdNextCancel = false;
        enteredCancel.complete();
        await heldCancel.future;
        return null;
      }
      return switch (call.method) {
        'initialize' => true,
        'locales' => <String>['de_AT:Deutsch (Österreich)'],
        'listen' => ++listenCalls > 0,
        'stop' || 'cancel' => null,
        _ => throw StateError('Unexpected speech method: ${call.method}'),
      };
    });
    addTearDown(() async {
      if (!heldCancel.isCompleted) heldCancel.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      messenger.setMockMethodCallHandler(speech, null);
      app.dispose();
      LumoVoice.instance.isEnabled = originalVoiceEnabled;
      await tester.binding.setSurfaceSize(null);
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LumoAgentContent(appState: app, onSection: (_) {}),
      ),
    ));
    await tester.pump();

    Future<void> platform(String method, Object value) async {
      final done = Completer<void>();
      // This is an explicitly synthetic native channel event. The production
      // widget/listener/plugin perform their normal work; no audio is claimed.
      messenger.handlePlatformMessage(
        speech.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, value)),
        (_) => done.complete(),
      );
      await done.future;
    }

    final speak = find.widgetWithText(FilledButton, 'Sprechen');
    await tester.ensureVisible(speak);
    await tester.tap(speak);
    await tester.pump();
    expect(listenCalls, 1);
    await platform('notifyStatus', 'listening');
    await tester.pump();

    holdNextCancel = true;
    final result = SpeechRecognitionResult.init([
      SpeechRecognitionWords('Was ist eine Biene?', null, .9),
    ], ResultType.finalResult);
    await platform('textRecognition', jsonEncode(result.toJson()));
    await tester.pump();
    expect(enteredCancel.isCompleted, isTrue,
        reason:
            'The final callback must actually be suspended at native cancel.');

    final stop = find.byKey(const ValueKey('lumo-conversation-stop'));
    await tester.ensureVisible(stop);
    await tester.tap(stop);
    await tester.pump();
    const stopped = 'Ich habe aufgehört. Du kannst in Ruhe weitermachen.';
    expect(find.text(stopped), findsOneWidget);

    heldCancel.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(stopped), findsOneWidget,
        reason: 'An old final transcript must not start a turn after Stop.');
    expect(listenCalls, 1, reason: 'Stop does not reopen the microphone.');
    expect((app.state.stars, app.state.xp), (0, 0));
    expect(app.state.solved, isEmpty);
    expect(tester.takeException(), isNull);

    // Leaving the conversation retires the owner. A synchronous recognizer
    // cancellation during controller disposal must not notify the dead view.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
