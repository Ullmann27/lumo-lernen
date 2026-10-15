import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy Android TTS word progress is permanently disabled', () async {
    const retiredChannel = MethodChannel('flutter_tts');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(retiredChannel, (call) async {
      calls.add(call);
      return 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(retiredChannel, null));
    final voice = LumoVoice.instance;
    await voice.configure(enabled: true, cloudVoiceEnabled: false);
    voice.clipsEnabled = false;
    final prior = voice.spokenWordRevision.value;
    await voice.speak('Zuerst zählen wir.');
    expect(calls, isEmpty);
    expect(voice.spokenWordRevision.value, prior);
    await voice.stop();
    expect(voice.status.value, VoiceStatus.idle);
    await voice.configure(enabled: true);
    voice.clipsEnabled = true;
  });
}
