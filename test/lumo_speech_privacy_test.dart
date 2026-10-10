import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Android without local recognizer stays text-only instead of using cloud',
      () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const diagnostics = MethodChannel('lumo_lernen/diagnostics');
    const speech = MethodChannel('plugin.csdcorp.com/speech_to_text');
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(diagnostics, (_) async => false);
    messenger.setMockMethodCallHandler(speech, (_) async {
      nativeCalls++;
      return true;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(diagnostics, null);
      messenger.setMockMethodCallHandler(speech, null);
    });
    final listener = LumoSpeechListener(isAndroid: true);
    addTearDown(listener.dispose);
    await listener.startListening();
    expect(listener.listening, false);
    expect(listener.error, contains('keine Cloud-Aufnahme'));
    expect(nativeCalls, 0);
  });
}
