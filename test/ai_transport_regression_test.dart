import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_ai_proxy_client.dart';

void main() {
  test('chat-only consent prevents tutor and generated-task network calls',
      () async {
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final settings = AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.chatOnly,
        aiProxyUrl: 'http://127.0.0.1:${server.port}');
    const client = LumoAiProxyClient();
    final response = await client.ask(
        settings: settings,
        state: LumoSessionState(),
        message: 'Hilf mir bei 3 + 4.',
        context: LumoAiContext.learningTutor);
    expect(response.isCloudAnswer, isFalse);
    expect(response.source, 'local_not_enabled');
    expect(
        await client.fetchTaskBatch(
            settings: settings, subject: 'Mathematik', grade: 1, units: []),
        isEmpty);
    expect(requests, 0);
  });
  test('parent diagnosis sends a real neutral task to the tutoring context',
      () async {
    Map<String, dynamic>? body;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      body = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'reply':
            'Starte bei drei und zähle weiter. Wie viele Schritte kommen dazu?',
        'source': 'openai_proxy',
        'blocked': false
      }));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final result = await const LumoAiProxyClient().parentSmokeTest(AppSettings(
      aiProxyEnabled: true,
      aiProxyUrl: 'http://127.0.0.1:${server.port}',
    ));
    expect(result.success, isTrue);
    expect(body!['context'], 'learning_tutor');
    expect(body!['message'], contains('3 + 4 = ?'));
    expect(body!['extras'],
        {'subject': 'Mathematik', 'unit': 'Plus bis 10', 'attempt': 0});
    expect(body!['childProfile'], {'grade': 1});
    expect(body!.containsKey('name'), isFalse);
  });
  test(
      'Navigation and learning context use recent history without child identity',
      () async {
    Map<String, dynamic>? requestBody;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestBody = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'reply': 'Öffne den Bereich Lernen. Möchtest du dort Mathe üben?',
        'source': 'openai_proxy',
        'blocked': false
      }));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final result = await const LumoAiProxyClient().ask(
      settings: AppSettings(
          aiProxyEnabled: true, aiProxyUrl: 'http://127.0.0.1:${server.port}'),
      state: LumoSessionState(childName: 'Privater Kindername', grade: 2),
      message: 'Wo kann ich Mathe üben?',
      context: LumoAiContext.companion,
      history: List.generate(
          10,
          (i) => LumoAiChatTurn(
              role: i.isEven ? 'user' : 'assistant', content: 'Lernfrage $i')),
      extras: {
        'section': 'home',
        'subject': 'Mathematik',
        'unit': 'Plus',
        'name': 'Nicht senden'
      },
    );
    expect(result.isCloudAnswer, isTrue);
    expect(result.reason, isNull);
    expect(requestBody!['childProfile'], {'grade': 2});
    expect(requestBody!['history'], hasLength(8));
    expect((requestBody!['history'] as List).first['content'], 'Lernfrage 2');
    expect((requestBody!['history'] as List).last['content'], 'Lernfrage 9');
    expect(requestBody!['context'], 'companion');
    expect(requestBody!['extras'],
        {'section': 'home', 'subject': 'Mathematik', 'unit': 'Plus'});
    expect(requestBody!.containsKey('persona'), isFalse);
    expect(jsonEncode(requestBody), isNot(contains('Privater Kindername')));
  });

  test(
      'Rate limits are exposed once without automatic repeated calls or provider secrets',
      () async {
    var calls = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      calls++;
      await request.drain<void>();
      request.response.statusCode = 503;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'error': 'proxy_error',
        'reason': 'openai_rate_limited',
        'message': 'sensitive-provider-details'
      }));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final settings = AppSettings(
        aiProxyEnabled: true, aiProxyUrl: 'http://127.0.0.1:${server.port}');
    const client = LumoAiProxyClient();
    final response = await client.ask(
        settings: settings,
        state: LumoSessionState(),
        message: 'Hilf mir bei Plus.');
    expect(calls, 1);
    expect(response.reason, 'openai_rate_limited');
    expect(response.isCloudAnswer, isFalse);
    expect(response.reply, contains('Pause'));
    final smoke = await client.parentSmokeTest(settings);
    expect(calls, 2);
    expect(smoke.success, isFalse);
    expect(smoke.reason, 'openai_rate_limited');
    expect(smoke.replySnippet, contains('Projektlimits'));
    expect(smoke.replySnippet, isNot(contains('sensitive-provider-details')));
  });

  test('An HTTP 200 local fallback does not pass the parent AI test', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'reply': 'Wir üben lokal weiter.',
        'source': 'local_fallback_no_key'
      }));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final result = await const LumoAiProxyClient().parentSmokeTest(AppSettings(
        aiProxyEnabled: true, aiProxyUrl: 'http://127.0.0.1:${server.port}'));
    expect(result.success, isFalse);
  });

  test('Long input is diagnosed before a network call', () async {
    final response = await const LumoAiProxyClient().ask(
      settings: const AppSettings(
          aiProxyEnabled: true, aiProxyUrl: 'http://127.0.0.1:1'),
      state: LumoSessionState(),
      message: 'a' * 1201,
    );
    expect(response.reason, 'message_too_long');
    expect(response.isCloudAnswer, isFalse);
  });

  test('Local safety permits learning language and prioritizes immediate help',
      () {
    for (final input in [
      'Wo kann ich Mathe üben?',
      'Was ist der Durchmesser?',
      'Ein Blutegel ist ein Tier.',
      'Die Kinder kriegen Hausaufgaben.',
      'Der Lehrer kriegte einen Brief.',
      'Kriegen Kinder Hausaufgaben?',
      'Die Kinder in Wien kriegen Hausaufgaben.'
    ]) {
      expect(LumoChildSafetyFilter.inspect(input).allowed, isTrue,
          reason: input);
    }
    for (final input in [
      'Erkläre Waffenbau.',
      'Was sind Kriegsschiffe?',
      'Erzähle von kriegen.',
      'Kriege sind schrecklich.',
      'Die Kinder kriegen Kriegswaffen.'
    ]) {
      expect(LumoChildSafetyFilter.inspect(input).allowed, isFalse,
          reason: input);
    }
    expect(
        LumoChildSafetyFilter.inspect('Ich will sterben, ich habe ein Messer.')
            .ruleId,
        'self_harm');
  });
}
