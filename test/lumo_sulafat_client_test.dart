import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_sulafat_client.dart';

void main() {
  test('long learning text is segmented without losing any word', () {
    final original = List<String>.generate(
        120, (i) => 'Buchstabe${i + 1}').join(' ');
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
    expect(AppSettings.fromJson(<String, dynamic>{}).cloudVoiceEnabled, isFalse);
  });

  test('client refuses mismatched voice and accepts original Sulafat', () async {
    final wav = Uint8List(48)
      ..setAll(0, ascii.encode('RIFF'))
      ..setAll(8, ascii.encode('WAVE'));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final bodySeen = <String>[];
    var wrongVoice = true;
    server.listen((request) async {
      bodySeen.add(await utf8.decoder.bind(request).join());
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'voice': wrongVoice ? 'Android' : 'Sulafat',
        'format': 'audio/wav',
        'audioBase64': base64Encode(wav),
      }));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final client = LumoSulafatClient();
    final url = 'http://127.0.0.1:${server.port}';
    await expectLater(client.synthesize(
      text: 'Schreibe ein A.', style: 'explain', baseUrl: url,
    ), throwsA(isA<FormatException>()));
    wrongVoice = false;
    final accepted = await client.synthesize(
      text: 'Schreibe ein A.', style: 'explain', baseUrl: url,
    );
    expect(accepted, wav);
    expect(bodySeen.length, 2);
    expect(bodySeen.last, contains('Schreibe ein A.'));
  });
}
