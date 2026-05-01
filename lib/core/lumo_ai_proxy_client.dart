import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../app/app_state.dart';
import 'app_settings.dart';

class LumoAiProxyClient {
  const LumoAiProxyClient();

  static const Duration _timeout = Duration(seconds: 12);
  static const Duration _batchTimeout = Duration(seconds: 30);

  bool isConfigured(AppSettings settings) {
    return settings.aiProxyEnabled && _validatedBaseUri(settings.aiProxyUrl) != null;
  }

  Future<LumoAiProxyResponse> ask({
    required AppSettings settings,
    required LumoSessionState state,
    required String message,
    List<LumoAiChatTurn> history = const <LumoAiChatTurn>[],
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

    final endpoint = _chatEndpoint(baseUri);
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.postUrl(endpoint).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final payload = <String, dynamic>{
        'message': text,
        'childProfile': <String, dynamic>{
          'name': state.childName,
          'grade': state.grade,
        },
        'history': history.take(8).map((turn) => turn.toJson()).toList(growable: false),
      };
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(_timeout);
      final raw = await response.transform(utf8.decoder).join().timeout(_timeout);
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
        source: decoded['source'] as String? ?? 'proxy',
      );
    } on TimeoutException {
      return const LumoAiProxyResponse(
        reply: 'Der Lumo-KI-Server braucht zu lange. Ich bleibe bei dir und helfe lokal weiter.',
        blocked: false,
        source: 'proxy_timeout',
      );
    } catch (_) {
      return const LumoAiProxyResponse(
        reply: 'Ich kann den Lumo-KI-Server gerade nicht erreichen. Wir üben sicher offline weiter.',
        blocked: false,
        source: 'proxy_error',
      );
    } finally {
      client.close(force: true);
    }
  }

  Uri? _validatedBaseUri(String raw) {
    // Use central sanitizer first - strips /health, /chat, trailing slash
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

  /// Prueft ob der Proxy-Server erreichbar ist und OpenAI konfiguriert hat.
  ///
  /// Sendet KEINE Kinderdaten, KEINE Chat-History, nur ein einfaches GET.
  /// Wird vom Elternbereich als "Server pruefen"-Button aufgerufen.
  Future<LumoAiHealthStatus> checkHealth(String rawUrl) async {
    final baseUri = _validatedBaseUri(rawUrl);
    if (baseUri == null) {
      return const LumoAiHealthStatus(
        reachable: false,
        openAiConfigured: false,
        message: 'Die URL sieht nicht richtig aus. Bitte korrekte https-Adresse eintragen.',
      );
    }
    final endpoint = _healthEndpoint(baseUri);
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(endpoint).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return LumoAiHealthStatus(
          reachable: false,
          openAiConfigured: false,
          message: 'Server gerade nicht erreichbar (Code ${response.statusCode}). Lumo bleibt lokal aktiv.',
        );
      }
      final raw = await response.transform(utf8.decoder).join().timeout(_timeout);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const LumoAiHealthStatus(
          reachable: true,
          openAiConfigured: false,
          message: 'Server antwortet, aber das Format ist unklar.',
        );
      }
      final ok = decoded['ok'] == true;
      final openAi = decoded['openAiConfigured'] == true;
      if (ok && openAi) {
        return const LumoAiHealthStatus(
          reachable: true,
          openAiConfigured: true,
          message: 'Server erreichbar. OpenAI ist verbunden.',
        );
      }
      if (ok && !openAi) {
        return const LumoAiHealthStatus(
          reachable: true,
          openAiConfigured: false,
          message: 'Server erreichbar, aber OpenAI-Schluessel fehlt am Server.',
        );
      }
      return const LumoAiHealthStatus(
        reachable: true,
        openAiConfigured: false,
        message: 'Server antwortet, aber meldet einen Fehler.',
      );
    } on TimeoutException {
      return const LumoAiHealthStatus(
        reachable: false,
        openAiConfigured: false,
        message: 'Server schlaeft vielleicht oder antwortet zu langsam. Lumo bleibt lokal aktiv.',
      );
    } catch (_) {
      return const LumoAiHealthStatus(
        reachable: false,
        openAiConfigured: false,
        message: 'Server gerade nicht erreichbar. Lumo bleibt lokal aktiv.',
      );
    } finally {
      client.close(force: true);
    }
  }
  Uri _tasksEndpoint(Uri baseUri) {
    final normalizedPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}tasks'
        : baseUri.path.isEmpty
            ? '/tasks'
            : '${baseUri.path}/tasks';
    return baseUri.replace(path: normalizedPath, query: '');
  }

  /// Fordert eine Charge KI-generierter Aufgaben vom Proxy an.
  ///
  /// units = Schwaechen aus dem Lernprofil (LearningProfileEngine).
  /// Der Server gibt eine bereits sicher gefilterte Liste zurueck.
  /// Eine zweite Pruefung erfolgt in Flutter via TaskQualityGuard.
  ///
  /// Bei Fehler oder ausgeschaltetem Proxy: leere Liste, kein Crash.
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

    final endpoint = _tasksEndpoint(baseUri);
    final client = HttpClient()..connectionTimeout = _batchTimeout;
    try {
      final request = await client.postUrl(endpoint).timeout(_batchTimeout);
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
      final response = await request.close().timeout(_batchTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <LumoAiTaskDraft>[];
      }
      final raw = await response.transform(utf8.decoder).join().timeout(_batchTimeout);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <LumoAiTaskDraft>[];
      final list = decoded['tasks'];
      if (list is! List) return const <LumoAiTaskDraft>[];
      final out = <LumoAiTaskDraft>[];
      for (final item in list) {
        if (item is! Map) continue;
        final draft = LumoAiTaskDraft.tryFrom(item);
        if (draft == null) continue;
        // Lokale Safety-Pruefung als zweite Linie
        final inputSafety = LumoChildSafetyFilter.inspect(draft.prompt);
        final answerSafety = LumoChildSafetyFilter.inspect(draft.answer);
        if (!inputSafety.allowed || !answerSafety.allowed) continue;
        out.add(draft);
      }
      return out;
    } on TimeoutException {
      return const <LumoAiTaskDraft>[];
    } catch (_) {
      return const <LumoAiTaskDraft>[];
    } finally {
      client.close(force: true);
    }
  }
}

class LumoAiHealthStatus {
  const LumoAiHealthStatus({
    required this.reachable,
    required this.openAiConfigured,
    required this.message,
  });

  final bool reachable;
  final bool openAiConfigured;
  final String message;

  bool get fullyOk => reachable && openAiConfigured;
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

/// Eine vom Lumo-Proxy gelieferte Aufgabe (Roh-Entwurf).
///
/// Dieser Typ ist absichtlich KEIN LumoTask. Er wird vom Cache
/// gespeichert, bei Verwendung in einen LumoTask konvertiert und
/// zusaetzlich vom TaskQualityGuard validiert.
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
