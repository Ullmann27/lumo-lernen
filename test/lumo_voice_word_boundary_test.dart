import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native TTS word boundaries are ignored after completion and mute',
      () async {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVoices') {
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
    Future<void> native(String method, [Object? arguments]) async {
      final response = Completer<void>();
      ServicesBinding.instance.channelBuffers.push(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall(method, arguments)),
        (_) => response.complete(),
      );
      await response.future;
    }

    const word = {
      'text': 'Zuerst zählen wir.',
      'start': 0,
      'end': 6,
      'word': 'Zuerst',
    };
    final voice = LumoVoice.instance;
    voice.isEnabled = true;
    await voice.speak(word['text']! as String);
    final before = voice.spokenWordRevision.value;
    await native('speak.onStart');
    await native('speak.onProgress', word);
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.spokenWordRevision.value, before + 1);
    await native('speak.onComplete');
    await native('speak.onProgress', word);
    expect(voice.spokenWordRevision.value, before + 1);
    await voice.configure(enabled: false);
    await native('speak.onStart');
    await native('speak.onProgress', word);
    expect(voice.spokenWordRevision.value, before + 1);
    expect(voice.status.value, VoiceStatus.idle);
    await voice.stop();
    expect(voice.status.value, VoiceStatus.idle);
  });
}
