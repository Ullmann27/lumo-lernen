import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_sulafat_client.dart';

Uint8List validSpeechWav() {
  final wav = Uint8List(48);
  final data = ByteData.sublistView(wav);
  void tag(int at, String text) => wav.setRange(at, at + 4, ascii.encode(text));
  tag(0, 'RIFF');
  data.setUint32(4, 40, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 24000, Endian.little);
  data.setUint32(28, 48000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, 4, Endian.little);
  return wav;
}

void main() {
  test('long learning text is segmented without losing any word', () {
    final original =
        List<String>.generate(120, (i) => 'Buchstabe${i + 1}').join(' ');
    final fragments = LumoSulafatClient.segments(original);
    expect(fragments.length, greaterThan(1));
    for (final part in fragments) {
      expect(part.length, lessThanOrEqualTo(440));
    }
    expect(fragments.join(' '), original);
  });

  test('cloud speech requires explicit parental consent', () {
    expect(const AppSettings().cloudVoiceEnabled, isFalse);
    final permitted = const AppSettings().copyWith(cloudVoiceEnabled: true);
    expect(AppSettings.fromJson(permitted.toJson()).cloudVoiceEnabled, isTrue);
    expect(
        AppSettings.fromJson(<String, dynamic>{}).cloudVoiceEnabled, isFalse);
  });

  test('client refuses mismatched voice and accepts original Sulafat',
      () async {
    final wav = validSpeechWav();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final bodySeen = <String>[];
    var wrongVoice = true;
    server.listen((request) async {
      bodySeen.add(await utf8.decoder.bind(request).join());
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'voice': wrongVoice ? 'Android' : 'Sulafat',
        'profile': LumoSulafatClient.referenceProfile,
        'model': LumoSulafatClient.referenceModel,
        'format': 'audio/wav',
        'audioBase64': base64Encode(wav),
      }));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final client = LumoSulafatClient();
    final url = 'http://127.0.0.1:${server.port}';
    await expectLater(
        client.synthesize(
          text: 'Schreibe ein A.',
          style: 'explain',
          baseUrl: url,
        ),
        throwsA(isA<FormatException>()));
    wrongVoice = false;
    final accepted = await client.synthesize(
      text: 'Schreibe ein A.',
      style: 'explain',
      baseUrl: url,
    );
    expect(accepted, wav);
    expect(bodySeen.length, 2);
    expect(bodySeen.last, contains('Schreibe ein A.'));
  });

  test('cancel closes an in-flight request before any late audio arrives',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final entered = Completer<void>();
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      entered.complete();
      // Intentionally no response: cancellation must not await a server timer.
    });
    final cancellation = LumoSpeechCancellation();
    final result = const LumoSulafatClient().synthesize(
      text: 'Schau die Zahlen an.',
      style: 'explain',
      baseUrl: 'http://127.0.0.1:${server.port}',
      cancellation: cancellation,
    );
    final checked = expectLater(result, throwsA(isA<Exception>()));
    await entered.future;
    cancellation.cancel();
    await checked.timeout(const Duration(seconds: 2));
  });
}
