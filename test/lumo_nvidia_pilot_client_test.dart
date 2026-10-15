import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_nvidia_pilot_client.dart';

void main() {
  test('Default-off NVIDIA pilot never opens a network connection', () async {
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final settings = AppSettings(
      aiProxyUrl: 'http://127.0.0.1:' + server.port.toString(),
    );
    final result = await const LumoNvidiaPilotClient().ask(
      settings: settings,
      verifiedParentBearer: 'test-only',
      message: 'Hilf mir bei 7 + 5.',
      context: 'math_coach',
      grade: 1,
    );
    expect(result.available, false);
    expect(result.reason, 'local_not_authorized');
    expect(requests, 0);
  });

  test('Verified-parent bearer is sent only to proxy pilot route; no child identity or history', () async {
    String? requestPath;
    String? authorization;
    Map<String, dynamic>? body;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestPath = request.uri.path;
      authorization = request.headers.value('authorization');
      body = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'reply': 'Denke zuerst bis zehn. Wie viel fehlt noch?',
        'source': 'nvidia_nemotron_pilot',
        'blocked': false,
      }));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final result = await const LumoNvidiaPilotClient().ask(
      settings: AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.learningHelp,
        aiProxyUrl: 'http://127.0.0.1:' + server.port.toString(),
      ),
      verifiedParentBearer: 'ephemeral-test-token',
      message: 'Wie geht 7 + 5?',
      context: 'math_coach',
      grade: 1,
    );
    expect(result.available, true);
    expect(requestPath, '/nvidia/pilot/chat');
    expect(authorization, 'Bearer ephemeral-test-token');
    expect(body, {'message':'Wie geht 7 + 5?', 'context':'math_coach', 'grade':1});
    expect(jsonEncode(body), isNot(contains('ephemeral-test-token')));
  });

  test('Reading request without reading consent is local-only', () async {
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final result = await const LumoNvidiaPilotClient().ask(
      settings: AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.learningHelp,
        aiProxyUrl: 'http://127.0.0.1:' + server.port.toString(),
      ),
      verifiedParentBearer: 'test-token',
      message: 'Erkläre mir das Wort Wiese.',
      context: 'reading_buddy',
      grade: 2,
    );
    expect(result.reason, 'local_not_authorized');
    expect(requests, 0);
  });

  test('NVIDIA pilot never follows a redirect carrying a parent bearer', () async {
    var leaked = false;
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      leaked = true;
      await request.drain<void>();
      await request.response.close();
    });
    addTearDown(() => target.close(force: true));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 307;
      request.response.headers.set(
        'location', 'http://127.0.0.1:' +
          target.port.toString() + '/steal-bearer',
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final result = await const LumoNvidiaPilotClient().ask(
      settings: AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.chatOnly,
        aiProxyUrl: 'http://127.0.0.1:' + server.port.toString(),
      ),
      verifiedParentBearer: 'test-sensitive-token',
      message: 'Kannst du mir helfen?',
      context: 'companion',
      grade: 2,
    );
    expect(result.available, false);
    expect(leaked, false);
  });
}
