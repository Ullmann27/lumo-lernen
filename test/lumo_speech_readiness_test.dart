import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_speech_readiness.dart';
import 'package:lumo_lernen/core/lumo_sulafat_client.dart';

void main() {
  test('old deployment is not mistaken for working online voice', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final paths = <String>[];
    var enabled = false;
    server.listen((request) async {
      paths.add('${request.method} ${request.uri.path}');
      request.response.statusCode = enabled ? 200 : 404;
      request.response.write(jsonEncode({
        'configured': true,
        'voice': 'Sulafat',
        'profile': LumoSulafatClient.referenceProfile,
        'model': LumoSulafatClient.referenceModel,
        'providerVerified': false
      }));
      await request.response.close();
    });
    final url = 'http://127.0.0.1:${server.port}';
    final old = await LumoSpeechReadiness.check(url);
    expect(old.configured, false);
    expect(old.message, contains('keinen Sulafat-Diagnose-Endpunkt'));
    enabled = true;
    final current = await LumoSpeechReadiness.check(url);
    expect(current.configured, true);
    expect(current.message, contains('noch nicht bestätigt'));
    expect(paths, ['GET /speech/status', 'GET /speech/status']);
  });
}
