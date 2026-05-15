import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../app/app_state.dart';
import 'app_settings.dart';

class LumoAiProxyClient {
  const LumoAiProxyClient();

  static const Duration _timeout = Duration(seconds: 18);
  static const Duration _coldStartTimeout = Duration(seconds: 45);
  static const Duration _batchTimeout = Duration(seconds: 30);

  bool isConfigured(AppSettings settings) {
    return settings.aiProxyEnabled && _validatedBaseUri(settings.aiProxyUrl) != null;
  }

  Future<LumoAiProxyResponse> ask({
    required AppSettings settings,
    required LumoSessionState state,
    required String message,
    List<LumoAiChatTurn> history = const <LumoAiChatTurn>[],
    LumoAiContext context = LumoAiContext.companion,
    Map<String, Object?>? extras,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      return const LumoAiProxyResponse(
        reply: 'Frag mich etwas zu Schule, Lesen, Mathe, Deutsch oder Natur.',
        blocked: false,
        source: 'local_empty',
      );
    }

    final localSafety = LumoChildSafetyFilter.inspect(text);
    if (!localSafety.allowed) {
      return LumoAiProxyResponse(
        reply: '${localSafety.redirect} Möchtest du lieber Mathe, Deutsch, Lesen oder Natur üben?',
        blocked: true,
        ruleId: localSafety.ruleId,
        source: 'local_flutter_policy',
      );
    }

    final baseUri = _validatedBaseUri(settings.aiProxyUrl);
    if (!settings.aiProxyEnabled || baseUri == null) {
      return const LumoAiProxyResponse(
        reply: 'Die Lumo-KI ist im Elternbereich noch nicht freigegeben. Ich kann dir lokal bei Mathe, Deutsch und Lesen helfen.',
        blocked: false,
        source: 'local_not_enabled',
      );
    }

    final firstAttempt = await _runChatAttempt(baseUri, text, history, state, _timeout, context: context, extras: extras);
    if (firstAttempt != null) return firstAttempt;

    final secondAttempt = await _runChatAttempt(baseUri, text, history, state, _coldStartTimeout, isRetry: true, context: context, extras: extras);
    if (secondAttempt != null) return secondAttempt;

    return const LumoAiProxyResponse(
      reply: 'Der Lumo-KI-Server antwortet auch nach längerem Warten nicht. Lumo hilft dir lokal weiter.',
      blocked: false,
      source: 'proxy_unreachable',
    );
  }

  Future<LumoAiProxyResponse?> _runChatAttempt(
    Uri baseUri,
    String text,
    List<LumoAiChatTurn> history,
    LumoSessionState state,
    Duration timeout, {
    bool isRetry = false,
    LumoAiContext context = LumoAiContext.companion,
    Map<String, Object?>? extras,
  }) async {
    final endpoint = _chatEndpoint(baseUri);
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(endpoint).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final payload = <String, dynamic>{
        'message': text,
        'childProfile': <String, dynamic>{
          'name': state.childName,
          'grade': state.grade,
        },
        'history': history.take(8).map((turn) => turn.toJson()).toList(growable: false),
        // Bereichs-Kontext: der Proxy kennt jetzt aus welchem Modul
        // die Anfrage kommt und kann ein angepasstes System-Prompt waehlen.
        'context': context.key,
        'persona': context.personaHint,
        if (extras != null && extras.isNotEmpty) 'extras': extras,
      };
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(timeout);
      final raw = await response.transform(utf8.decoder).join().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return LumoAiProxyResponse(
          reply: 'Der Lumo-KI-Server antwortet gerade nicht. Wir üben ohne Cloud weiter.',
          blocked: false,
          source: 'proxy_http_${response.statusCode}',
        );
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const LumoAiProxyResponse(
          reply: 'Die Serverantwort war nicht lesbar. Wir bleiben bei der lokalen Lernhilfe.',
          blocked: false,
          source: 'proxy_bad_json',
        );
      }
      final reply = (decoded['reply'] as String?)?.trim();
      if (reply == null || reply.isEmpty) {
        return const LumoAiProxyResponse(
          reply: 'Ich habe keine gute Antwort bekommen. Lass uns eine Lernaufgabe probieren.',
          blocked: false,
          source: 'proxy_empty_reply',
        );
      }
      final outputSafety = LumoChildSafetyFilter.inspect(reply);
      if (!outputSafety.allowed) {
        return LumoAiProxyResponse(
          reply: '${outputSafety.redirect} Soll ich dir eine leichte Schulfrage stellen?',
          blocked: true,
          ruleId: outputSafety.ruleId,
          source: 'local_output_policy',
        );
      }
      return LumoAiProxyResponse(
        reply: reply,
        blocked: decoded['blocked'] as bool? ?? false,
        ruleId: decoded['ruleId'] as String?,
        source: decoded['source'] as String? ?? (isRetry ? 'proxy_retry' : 'proxy'),
      );
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } catch (_) {
      return const LumoAiProxyResponse(
        reply: 'Verbindung zum KI-Server nicht möglich. Lumo hilft dir lokal weiter.',
        blocked: false,
        source: 'proxy_error',
      );
    } finally {
      client.close(force: true);
    }
  }

  Uri? _validatedBaseUri(String raw) {
    final clean = AppSettings.sanitizeProxyUrl(raw);
    final uri = Uri.tryParse(clean);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }

  Uri _chatEndpoint(Uri baseUri) {
    final normalizedPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}chat'
        : baseUri.path.isEmpty
            ? '/chat'
            : '${baseUri.path}/chat';
    return baseUri.replace(path: normalizedPath, query: '');
  }

  Uri _healthEndpoint(Uri baseUri) {
    final normalizedPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}health'
        : baseUri.path.isEmpty
            ? '/health'
            : '${baseUri.path}/health';
    return baseUri.replace(path: normalizedPath, query: '');
  }

  /// Root-Endpoint mit explizitem '/' statt leerem Path.
  /// Hintergrund: Dart's HttpClient kann bei leerem path
  /// zu unklaren Request-Lines fuehren, manche Loadbalancer
  /// (auch Render) reagieren mit 301-Redirect oder 400.
  /// Mit '/' ist es eindeutig: GET / HTTP/1.1.
  Uri _rootEndpoint(Uri baseUri) => baseUri.replace(path: '/', query: '');

  Future<LumoAiHealthStatus> checkHealth(String rawUrl) async {
    final baseUri = _validatedBaseUri(rawUrl);
    if (baseUri == null) {
      return LumoAiHealthStatus(
        reachable: false,
        openAiConfigured: false,
        message: 'Die URL sieht nicht richtig aus. Bitte korrekte https-Adresse eintragen.',
        checkedUrl: rawUrl.trim().isEmpty ? '(leer)' : rawUrl.trim(),
      );
    }

    final firstAttempt = await _runHealthAttempt(baseUri, _timeout);
    if (firstAttempt != null) return firstAttempt;

    final secondAttempt = await _runHealthAttempt(baseUri, _coldStartTimeout, isRetry: true);
    if (secondAttempt != null) return secondAttempt;

    return LumoAiHealthStatus(
      reachable: false,
      openAiConfigured: false,
      message: 'Server antwortet auch nach längerem Warten nicht. Bitte Render-Service prüfen. Lumo bleibt lokal aktiv.',
      checkedUrl: baseUri.toString(),
    );
  }

  Future<LumoAiHealthStatus?> _runHealthAttempt(
    Uri baseUri,
    Duration timeout, {
    bool isRetry = false,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    final rootUri = _rootEndpoint(baseUri);
    final healthUri = _healthEndpoint(baseUri);
    try {
      final root = await _getHealthStatus(client, rootUri, timeout);
      final rootStatus = _statusFromHealthJson(
        root.rawBody,
        fallbackPrefix: 'Root-Adresse erreichbar.',
        statusCode: root.statusCode,
        endpoint: rootUri.toString(),
        checkedUrl: baseUri.toString(),
      );
      if (rootStatus?.fullyOk == true) return rootStatus;

      final primary = await _getHealthStatus(client, healthUri, timeout);
      final healthStatus = _statusFromHealthJson(
        primary.rawBody,
        statusCode: primary.statusCode,
        endpoint: healthUri.toString(),
        checkedUrl: baseUri.toString(),
      );
      if (healthStatus != null) return healthStatus;

      if (rootStatus != null) return rootStatus;

      if (primary.statusCode < 200 || primary.statusCode >= 300) {
        if (primary.statusCode == 404) {
          return LumoAiHealthStatus(
            reachable: false,
            openAiConfigured: false,
            message: 'Server-Service antwortet, aber /health und Root-Health sind nicht lesbar. Bitte Render-Deploy prüfen. URL: $baseUri',
            statusCode: primary.statusCode,
            endpoint: healthUri.toString(),
            checkedUrl: baseUri.toString(),
          );
        }
        if (primary.statusCode >= 500) {
          return LumoAiHealthStatus(
            reachable: false,
            openAiConfigured: false,
            message: 'Server hat einen Fehler (Code ${primary.statusCode}). Bitte später erneut prüfen. Lumo bleibt lokal aktiv.',
            statusCode: primary.statusCode,
            endpoint: healthUri.toString(),
            checkedUrl: baseUri.toString(),
          );
        }
        return LumoAiHealthStatus(
          reachable: false,
          openAiConfigured: false,
          message: 'Server gerade nicht erreichbar (Code ${primary.statusCode}). Lumo bleibt lokal aktiv.',
          statusCode: primary.statusCode,
          endpoint: healthUri.toString(),
          checkedUrl: baseUri.toString(),
        );
      }
      return LumoAiHealthStatus(
        reachable: true,
        openAiConfigured: false,
        message: 'Server antwortet, aber das Format ist unklar.',
        statusCode: primary.statusCode,
        endpoint: healthUri.toString(),
        checkedUrl: baseUri.toString(),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return LumoAiHealthStatus(
        reachable: false,
        openAiConfigured: false,
        message: 'Server gerade nicht erreichbar. Lumo bleibt lokal aktiv.',
        endpoint: rootUri.toString(),
        checkedUrl: baseUri.toString(),
      );
    } finally {
      client.close(force: true);
    }
  }

  void warmup(AppSettings settings) {
    if (!settings.aiProxyEnabled) return;
    final baseUri = _validatedBaseUri(settings.aiProxyUrl);
    if (baseUri == null) return;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    () async {
      try {
        final endpoint = _rootEndpoint(baseUri);
        final request = await client.getUrl(endpoint).timeout(const Duration(seconds: 4));
        final response = await request.close().timeout(const Duration(seconds: 4));
        await response.drain<void>();
      } catch (_) {
        // Wakeup ist best-effort.
      } finally {
        client.close(force: true);
      }
    }();
  }

  /// Eltern-Diagnose-Aufruf gegen /chat. Sendet eine neutrale
  /// Test-Nachricht ohne Kinderprofil, gibt Source und Antwort
  /// zurueck. Niemals von Kindern aufgerufen.
  Future<LumoAiSmokeTestResult> parentSmokeTest(AppSettings settings) async {
    final baseUri = _validatedBaseUri(settings.aiProxyUrl);
    if (!settings.aiProxyEnabled) {
      return const LumoAiSmokeTestResult(
        success: false,
        statusCode: 0,
        source: 'parent_disabled',
        replySnippet: 'Eltern-KI-Schalter ist aus. Bitte zuerst aktivieren.',
        endpoint: '',
      );
    }
    if (baseUri == null) {
      return LumoAiSmokeTestResult(
        success: false,
        statusCode: 0,
        source: 'invalid_url',
        replySnippet: 'Proxy-URL ist nicht gueltig.',
        endpoint: settings.aiProxyUrl,
      );
    }
    final endpoint = _chatEndpoint(baseUri);
    final client = HttpClient()..connectionTimeout = _coldStartTimeout;
    try {
      final request = await client.postUrl(endpoint).timeout(_coldStartTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final payload = <String, dynamic>{
        'message': 'Sag hallo in einem kurzen Satz.',
        'childProfile': <String, dynamic>{
          'name': 'Eltern-Test',
          'grade': 1,
        },
        'history': const <Map<String, String>>[],
      };
      request.write(jsonEncode(payload));
      final response = await request.close().timeout(_coldStartTimeout);
      final raw = await response.transform(utf8.decoder).join().timeout(_coldStartTimeout);
      final code = response.statusCode;
      String source = 'unknown';
      String replySnippet = '';
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          source = decoded['source']?.toString() ?? 'unknown';
          final reply = decoded['reply']?.toString() ?? '';
          replySnippet = reply.length > 150 ? '${reply.substring(0, 150)}...' : reply;
        }
      } catch (_) {
        replySnippet = raw.length > 150 ? '${raw.substring(0, 150)}...' : raw;
      }
      return LumoAiSmokeTestResult(
        success: code >= 200 && code < 300 && replySnippet.isNotEmpty,
        statusCode: code,
        source: source,
        replySnippet: replySnippet,
        endpoint: endpoint.toString(),
      );
    } on TimeoutException {
      return LumoAiSmokeTestResult(
        success: false,
        statusCode: 0,
        source: 'timeout',
        replySnippet: 'Server hat nicht innerhalb von 45 Sekunden geantwortet.',
        endpoint: endpoint.toString(),
      );
    } catch (e) {
      return LumoAiSmokeTestResult(
        success: false,
        statusCode: 0,
        source: 'error',
        replySnippet: 'Fehler: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}',
        endpoint: endpoint.toString(),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<_HealthHttpResult> _getHealthStatus(HttpClient client, Uri endpoint, Duration timeout) async {
    final request = await client.getUrl(endpoint).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(timeout);
    final raw = await response.transform(utf8.decoder).join().timeout(timeout);
    return _HealthHttpResult(statusCode: response.statusCode, rawBody: raw);
  }

  LumoAiHealthStatus? _statusFromHealthJson(
    String raw, {
    String? fallbackPrefix,
    int? statusCode,
    String? endpoint,
    String? checkedUrl,
  }) {
    final decoded = _tryDecodeHealthJson(raw);
    if (decoded == null) return null;
    final ok = _truthy(decoded['ok']) || _truthy(decoded['healthy']) || _truthy(decoded['ready']);
    final openAi = _truthy(decoded['openAiConfigured']) ||
        _truthy(decoded['openAIConfigured']) ||
        _truthy(decoded['openaiConfigured']) ||
        _truthy(decoded['open_ai_configured']) ||
        _truthy(decoded['openai']) ||
        _truthy(decoded['configured']);
    final service = decoded['service']?.toString().toLowerCase() ?? '';
    final isLumoProxy = service.contains('lumo') && service.contains('proxy');
    final prefix = fallbackPrefix == null ? '' : '$fallbackPrefix ';
    final snippet = raw.length > 200 ? '${raw.substring(0, 200)}...' : raw;

    if ((ok && openAi) || (isLumoProxy && openAi)) {
      return LumoAiHealthStatus(
        reachable: true,
        openAiConfigured: true,
        message: '${prefix}Server erreichbar. OpenAI ist verbunden.',
        statusCode: statusCode,
        endpoint: endpoint,
        service: service.isEmpty ? null : service,
        rawBodySnippet: snippet,
        checkedUrl: checkedUrl,
      );
    }
    if (ok && isLumoProxy && !decoded.containsKey('openAiConfigured')) {
      return LumoAiHealthStatus(
        reachable: true,
        openAiConfigured: false,
        message: '${prefix}Server erreichbar. OpenAI-Status ist unklar.',
        statusCode: statusCode,
        endpoint: endpoint,
        service: service.isEmpty ? null : service,
        rawBodySnippet: snippet,
        checkedUrl: checkedUrl,
      );
    }
    if (ok && !openAi) {
      return LumoAiHealthStatus(
        reachable: true,
        openAiConfigured: false,
        message: '${prefix}Server erreichbar, aber OpenAI-Schlüssel fehlt am Server.',
        statusCode: statusCode,
        endpoint: endpoint,
        service: service.isEmpty ? null : service,
        rawBodySnippet: snippet,
        checkedUrl: checkedUrl,
      );
    }
    return LumoAiHealthStatus(
      reachable: true,
      openAiConfigured: false,
      message: '${prefix}Server antwortet, aber meldet einen Fehler.',
      statusCode: statusCode,
      endpoint: endpoint,
      service: service.isEmpty ? null : service,
      rawBodySnippet: snippet,
      checkedUrl: checkedUrl,
    );
  }

  Map<String, Object?>? _tryDecodeHealthJson(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map) return null;
      return Map<String, Object?>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  bool _truthy(Object? value) {
    if (value == true) return true;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes' || text == 'ok';
  }

  Uri _tasksEndpoint(Uri baseUri) {
    final normalizedPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}tasks'
        : baseUri.path.isEmpty
            ? '/tasks'
            : '${baseUri.path}/tasks';
    return baseUri.replace(path: normalizedPath, query: '');
  }

  Future<List<LumoAiTaskDraft>> fetchTaskBatch({
    required AppSettings settings,
    required String subject,
    required int grade,
    required List<String> units,
    int count = 10,
    String? childName,
  }) async {
    if (!settings.aiProxyEnabled) return const <LumoAiTaskDraft>[];
    final baseUri = _validatedBaseUri(settings.aiProxyUrl);
    if (baseUri == null) return const <LumoAiTaskDraft>[];

    final firstAttempt = await _runTaskBatchAttempt(
      baseUri: baseUri,
      subject: subject,
      grade: grade,
      units: units,
      count: count,
      childName: childName,
      timeout: _batchTimeout,
    );
    if (firstAttempt != null) return firstAttempt;

    final secondAttempt = await _runTaskBatchAttempt(
      baseUri: baseUri,
      subject: subject,
      grade: grade,
      units: units,
      count: count,
      childName: childName,
      timeout: _coldStartTimeout,
    );
    return secondAttempt ?? const <LumoAiTaskDraft>[];
  }

  Future<List<LumoAiTaskDraft>?> _runTaskBatchAttempt({
    required Uri baseUri,
    required String subject,
    required int grade,
    required List<String> units,
    required int count,
    String? childName,
    required Duration timeout,
  }) async {
    final endpoint = _tasksEndpoint(baseUri);
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(endpoint).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final payload = <String, dynamic>{
        'subject': subject,
        'grade': grade,
        'units': units.take(6).toList(growable: false),
        'count': count.clamp(3, 20),
        if (childName != null && childName.isNotEmpty) 'childName': childName,
      };
      request.write(jsonEncode(payload));
      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <LumoAiTaskDraft>[];
      }
      final raw = await response.transform(utf8.decoder).join().timeout(timeout);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <LumoAiTaskDraft>[];
      final list = decoded['tasks'];
      if (list is! List) return const <LumoAiTaskDraft>[];
      final out = <LumoAiTaskDraft>[];
      for (final item in list) {
        if (item is! Map) continue;
        final draft = LumoAiTaskDraft.tryFrom(item);
        if (draft == null) continue;
        final inputSafety = LumoChildSafetyFilter.inspect(draft.prompt);
        final answerSafety = LumoChildSafetyFilter.inspect(draft.answer);
        if (!inputSafety.allowed || !answerSafety.allowed) continue;
        out.add(draft);
      }
      return out;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } catch (_) {
      return const <LumoAiTaskDraft>[];
    } finally {
      client.close(force: true);
    }
  }
}

class _HealthHttpResult {
  const _HealthHttpResult({required this.statusCode, required this.rawBody});

  final int statusCode;
  final String rawBody;
}

class LumoAiHealthStatus {
  const LumoAiHealthStatus({
    required this.reachable,
    required this.openAiConfigured,
    required this.message,
    this.statusCode,
    this.endpoint,
    this.service,
    this.rawBodySnippet,
    this.checkedUrl,
  });

  final bool reachable;
  final bool openAiConfigured;
  final String message;

  /// Diagnose-Felder. Sichtbar im Elternbereich, hilfreich
  /// fuer Heinz beim Verstehen warum die Anzeige rot/gelb ist.
  /// Niemals API-Key, niemals Kinderdaten.
  final int? statusCode;
  final String? endpoint;
  final String? service;
  final String? rawBodySnippet;
  final String? checkedUrl;

  bool get fullyOk => reachable && openAiConfigured;
}

class LumoAiSmokeTestResult {
  const LumoAiSmokeTestResult({
    required this.success,
    required this.statusCode,
    required this.source,
    required this.replySnippet,
    required this.endpoint,
  });

  final bool success;
  final int statusCode;
  final String source;
  final String replySnippet;
  final String endpoint;
}

class LumoAiProxyResponse {
  const LumoAiProxyResponse({
    required this.reply,
    required this.blocked,
    required this.source,
    this.ruleId,
  });

  final String reply;
  final bool blocked;
  final String source;
  final String? ruleId;
}

class LumoAiChatTurn {
  const LumoAiChatTurn({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role,
        'content': content,
      };
}

class LumoSafetyDecision {
  const LumoSafetyDecision({
    required this.allowed,
    required this.ruleId,
    required this.redirect,
  });

  final bool allowed;
  final String? ruleId;
  final String redirect;
}

class LumoChildSafetyFilter {
  const LumoChildSafetyFilter._();

  static const Map<String, List<String>> _blockedTerms = <String, List<String>>{
    'sexual_content': <String>['sex', 'porno', 'pornografie', 'nackt', 'nacktheit', 'nacktbilder', 'onlyfans', 'vergewaltigung', 'erektion', 'masturbation'],
    'violence_war_weapons': <String>['krieg', 'gewalt', 'waffe', 'messer', 'pistole', 'gewehr', 'bombe', 'töten', 'toeten', 'mord', 'blut', 'folter', 'anschlag', 'erschießen', 'erschiessen', 'pruegeln', 'prügeln'],
    'self_harm': <String>['ich will sterben', 'mich umbringen', 'suizid', 'selbstmord', 'ritzen', 'mir weh tun', 'mich verletzen'],
    'politics_extremism': <String>['partei', 'wahlkampf', 'hitler', 'nazi', 'terror', 'terrorist', 'extremismus', 'propaganda', 'rassismus'],
    'hate_speech': <String>['ich hasse alle', 'auslaender raus', 'ausländer raus', 'sind dumm', 'minderwertig'],
    'drugs_alcohol': <String>['drogen', 'kiffen', 'kokain', 'heroin', 'cannabis', 'alkohol trinken', 'betrunken', 'zigarette', 'vape', 'e-zigarette'],
    'private_data': <String>['adresse', 'telefonnummer', 'handynummer', 'passwort', 'bankkarte', 'kreditkarte', 'pin code'],
    'stranger_danger': <String>['will mich treffen', 'wir treffen uns heimlich', 'sag es deinen eltern nicht', 'sag es niemandem', 'unser geheimnis', 'ich darf nicht reden'],
  };

  static LumoSafetyDecision inspect(String value) {
    final text = value.toLowerCase();
    for (final entry in _blockedTerms.entries) {
      if (entry.value.any((term) => text.contains(term))) {
        return LumoSafetyDecision(
          allowed: false,
          ruleId: entry.key,
          redirect: _redirectFor(entry.key),
        );
      }
    }
    return const LumoSafetyDecision(allowed: true, ruleId: null, redirect: '');
  }

  static String _redirectFor(String ruleId) {
    switch (ruleId) {
      case 'self_harm':
        return 'Das klingt sehr ernst. Bitte sag sofort einem Erwachsenen in deiner Nähe Bescheid.';
      case 'stranger_danger':
        return 'Das ist wichtig. Erzähl bitte sofort einem Erwachsenen in deiner Familie davon. Du musst kein Geheimnis behalten, das dich unwohl fühlen lässt.';
      case 'private_data':
        return 'Private Daten bleiben geheim. Teile nie Adresse, Passwort oder Telefonnummer.';
      case 'violence_war_weapons':
        return 'Darüber sprechen wir in Lumo Lernen nicht. Lass uns lieber über eine friedliche Geschichte oder Schule reden.';
      case 'sexual_content':
        return 'Darüber spreche ich mit Kindern nicht.';
      case 'politics_extremism':
        return 'Darüber reden wir hier nicht. Ich kann dir aber eine Schulfrage oder ein Naturthema erklären.';
      case 'hate_speech':
        return 'So reden wir nicht über andere Menschen. Lass uns über etwas Positives oder eine Lernfrage sprechen.';
      case 'drugs_alcohol':
        return 'Das ist kein Kinderthema. Lass uns über gesunde Gewohnheiten oder Lernen sprechen.';
      default:
        return 'Lass uns über ein sicheres Kinderthema sprechen.';
    }
  }
}

class LumoAiTaskDraft {
  const LumoAiTaskDraft({
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.explanation,
    required this.visual,
  });

  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String visual;

  static LumoAiTaskDraft? tryFrom(Map raw) {
    final prompt = (raw['prompt'] as String?)?.trim() ?? '';
    final answer = (raw['answer'] as String?)?.trim() ?? '';
    final explanation = (raw['explanation'] as String?)?.trim() ?? '';
    final visual = (raw['visual'] as String?)?.trim() ?? 'auto';
    final choicesRaw = raw['choices'];
    if (prompt.isEmpty || answer.isEmpty) return null;
    if (choicesRaw is! List || choicesRaw.length < 2) return null;
    final choices = <String>[];
    for (final c in choicesRaw) {
      final v = c?.toString().trim() ?? '';
      if (v.isEmpty) continue;
      choices.add(v);
    }
    if (choices.length < 2) return null;
    if (!choices.any((c) => c.toLowerCase() == answer.toLowerCase())) return null;
    return LumoAiTaskDraft(
      prompt: prompt,
      answer: answer,
      choices: choices,
      explanation: explanation,
      visual: visual,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'prompt': prompt,
        'answer': answer,
        'choices': choices,
        'explanation': explanation,
        'visual': visual,
      };

  factory LumoAiTaskDraft.fromJson(Map<String, dynamic> json) {
    return LumoAiTaskDraft(
      prompt: json['prompt'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      choices: (json['choices'] as List?)?.map((e) => e.toString()).toList(growable: false) ?? const <String>[],
      explanation: json['explanation'] as String? ?? '',
      visual: json['visual'] as String? ?? 'auto',
    );
  }
}

/// Bereichs-Kontext fuer KI-Anfragen.
/// Wird mit jedem Request mitgeschickt und ermoeglicht dem Proxy,
/// das passende System-Prompt + die passende Persona zu waehlen.
enum LumoAiContext {
  /// Allgemeiner Lumo-Chat (Standard).
  companion(
    'companion',
    'Du bist Lumo, ein freundlicher fuchsfoermiger Lernbegleiter fuer ein Volksschulkind in Oesterreich. Antworte kurz, warm, immer auf Deutsch. Keine fremden Sprachen. Keine sensiblen Themen.',
  ),

  /// Lern-Tutor: hilft konkret bei Aufgaben, ohne die Loesung zu verraten.
  learningTutor(
    'learning_tutor',
    'Du bist Lumo der Lern-Tutor. Das Kind braucht Hilfe bei einer Aufgabe. Gib NIE die Loesung. Stelle stattdessen 1 leichte Lenk-Frage oder zeige einen kleinen Schritt. Maximal 2 Saetze. Oesterreichisches Deutsch.',
  ),

  /// Lese-Buddy: hilft beim Lesen, erklaert Woerter kindgerecht.
  readingBuddy(
    'reading_buddy',
    'Du bist Lumo der Lese-Buddy. Das Kind liest gerade einen Text. Wenn es nach einem Wort fragt: erklaere es in EINEM einfachen Satz, kindgerecht. Wenn unsicher: ermutige es, langsam zu lesen.',
  ),

  /// Schreib-Assistent: hilft beim Schreiben/Rechtschreibung.
  writingHelper(
    'writing_helper',
    'Du bist Lumo der Schreib-Helfer. Das Kind schreibt gerade. Hilf bei der Rechtschreibung kurz und kindgerecht. Bei Geschichten: gib 1 Idee, kein ganzes Werk.',
  ),

  /// Mathe-Coach: erklaert Mathe-Konzepte mit Alltagsbeispielen.
  mathCoach(
    'math_coach',
    'Du bist Lumo der Mathe-Coach. Erklaere Mathe-Konzepte mit Alltagsbeispielen aus Oesterreich (Aepfel, Semmeln, Schillingmuenzen, etc). Maximal 3 Saetze.',
  ),

  /// Sachunterricht: erklaert Welt-Wissen kindgerecht.
  scienceExplorer(
    'science_explorer',
    'Du bist Lumo der Welt-Entdecker. Erklaere Sachunterricht-Themen kurz, mit einem WOW-Fakt. Maximal 3 Saetze, kindgerecht.',
  ),

  /// Eltern-Berater: spricht mit Eltern, NICHT mit Kind. Andere Sprache.
  parentAdvisor(
    'parent_advisor',
    'Du sprichst jetzt mit einem Elternteil, nicht mit dem Kind. Du kannst paedagogische Tipps geben, Lernstand erklaeren, Foerdervorschlaege machen. Mehr fachlich, aber freundlich. Oesterreichisches Deutsch.',
  );

  const LumoAiContext(this.key, this.personaHint);
  final String key;
  final String personaHint;
}
