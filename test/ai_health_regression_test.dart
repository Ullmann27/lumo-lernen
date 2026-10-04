import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_ai_proxy_client.dart';

void main() {
  test('Health only confirms AI after a successful upstream request', () async {
    var payload = <String, Object?>{};
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(payload));
      request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final url = 'http://127.0.0.1:${server.port}';
    const client = LumoAiProxyClient();
    for (final upstream in [
      null,
      'not_checked',
      'openai_authentication_failed',
      'openai_quota_exceeded',
      'openai_rate_limited',
      'openai_unavailable',
      'ready',
    ]) {
      payload = {
        'ok': true,
        'service': 'lumo-ai-proxy',
        'openAiConfigured': true,
        if (upstream != null) 'upstreamStatus': upstream,
        'openAiAvailable': upstream == 'ready',
      };
      final result = await client.checkHealth(url);
      expect(result.reachable, isTrue);
      expect(result.openAiConfigured, isTrue);
      expect(result.fullyOk, upstream == 'ready', reason: '$upstream');
      if (upstream != 'ready') {
        expect(result.message, isNot(contains('OpenAI ist verbunden')));
      }
    }
  });
}
