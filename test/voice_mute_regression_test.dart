import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mute and unknown text cannot activate the retired Android TTS', () async {
    final invoked = <String>[];
    const retiredChannel = MethodChannel('flutter_tts');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(retiredChannel, (call) async {
      invoked.add(call.method);
      throw StateError('Die alte Android-Stimme darf niemals spielen.');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(retiredChannel, null));
    final voice = LumoVoice.instance;
    await voice.configure(enabled: true, cloudVoiceEnabled: false);
    voice.clipsEnabled = false;
    await voice.speak('Gehe einen kleinen Schritt weiter.');
    expect(voice.selectedVoiceName, 'Sulafat');
    expect(voice.status.value, VoiceStatus.error,
        reason: 'Unbekannter Text ohne Elternfreigabe bleibt stumm.');
    expect(invoked, isEmpty);
    await voice.configure(enabled: false);
    await voice.speak('Dieser Text bleibt stumm.');
    expect(invoked, isEmpty);
    expect(voice.status.value, VoiceStatus.idle);
    await voice.configure(enabled: true);
    voice.clipsEnabled = true;
  });
}
