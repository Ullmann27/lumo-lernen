import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('locked plugin cannot manufacture a final from a partial timeout',
      (
    tester,
  ) async {
    const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'locales') return ['de_DE:Deutsch'];
      return true;
    });
    final listener = LumoSpeechListener(
      isAndroid: false,
      recognizer: LumoSpeechRecognizer.withEngine(
        SpeechToText.withMethodChannel(),
      ),
      stopPlayback: () async {},
    );
    addTearDown(() async {
      await listener.cancel();
      listener.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });

    Future<void> platform(String method, Object value) async {
      final done = Completer<void>();
      // These are simulated native method-channel events, not recorded speech.
      messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, value)),
        (_) => done.complete(),
      );
      await done.future;
    }

    String result(String words, ResultType type) => jsonEncode(
          SpeechRecognitionResult.init([
            SpeechRecognitionWords(words, null, .8),
          ], type)
              .toJson(),
        );

    final finals = <String>[];
    await listener.startListening(onFinalResult: finals.add);
    await platform('notifyStatus', 'listening');
    await platform('textRecognition', result('drei', ResultType.partial));
    await listener.stopListening();
    // The package's default finalTimeout is two seconds. The adapter's genuine
    // final deadline is three seconds, so this interval detects promotion.
    await tester.pump(const Duration(milliseconds: 2500));
    expect(finals, isEmpty);
    expect(listener.lastRecognition?.isFinal, false);
    expect(listener.awaitingFinalResult, true);
    await platform(
      'textRecognition',
      result('ich meinte dreizehn', ResultType.finalResult),
    );
    expect(finals, ['ich meinte dreizehn']);
    expect(listener.lastRecognition?.isFinal, true);
  });
}
