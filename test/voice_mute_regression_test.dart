import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'mute cancels current speech and invalidates a request awaiting TTS setup',
      () async {
    final voicesReady = Completer<void>();
    final scanStarted = Completer<void>();
    final calls = <String>[];
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'getVoices') {
        scanStarted.complete();
        await voicesReady.future;
        return [
          {'name': 'de-at-local', 'locale': 'de-AT'}
        ];
      }
      return 1;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      LumoVoice.instance.isEnabled = true;
    });
    final voice = LumoVoice.instance;
    voice.isEnabled = true;
    final pending = voice.speak('Gehe einen kleinen Schritt weiter.');
    await scanStarted.future;
    await voice.configure(enabled: false);
    voicesReady.complete();
    await pending;
    expect(calls.where((m) => m == 'speak'), isEmpty);
    expect(calls, contains('stop'));
    expect(voice.status.value, VoiceStatus.idle);
    await voice.configure(enabled: true);
    await voice.speak('Hallo Lumo.');
    expect(calls.where((m) => m == 'speak'), hasLength(1));
    await voice.configure(enabled: false);
    await voice.speak('Dieser Text bleibt stumm.');
    expect(calls.where((m) => m == 'speak'), hasLength(1));
    expect(voice.status.value, VoiceStatus.idle);
  });
}
