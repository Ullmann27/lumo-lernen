import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../app/app_state.dart';
import 'app_settings.dart';

class LumoAiProxyClient {
  const LumoAiProxyClient();

  static const Duration _timeout = Duration(seconds: 12);

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
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
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
    'sexual_content': <String>['sex', 'porno', 'pornografie', 'nackt', 'nacktbilder', 'onlyfans', 'vergewaltigung'],
    'violence_war_weapons': <String>['krieg', 'waffe', 'messer', 'pistole', 'bombe', 'töten', 'toeten', 'mord', 'blut', 'folter', 'anschlag'],
    'self_harm': <String>['ich will sterben', 'mich umbringen', 'suizid', 'selbstmord', 'ritzen', 'mir weh tun'],
    'politics_extremism': <String>['partei', 'wahlkampf', 'hitler', 'nazi', 'terror', 'extremismus', 'propaganda'],
    'drugs_alcohol': <String>['drogen', 'kiffen', 'kokain', 'heroin', 'alkohol trinken', 'betrunken', 'zigarette', 'vape'],
    'private_data': <String>['adresse', 'telefonnummer', 'passwort', 'bankkarte', 'kreditkarte', 'pin code'],
  };

  static LumoSafetyDecision inspect(String value) {
    final text = value.toLowerCase();
    for (final entry in _blockedTerms.entries) {
      if (entry.value.any(text.contains)) {
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
      case 'private_data':
        return 'Private Daten bleiben geheim. Teile nie Adresse, Passwort oder Telefonnummer.';
      case 'violence_war_weapons':
        return 'Darüber sprechen wir in Lumo Lernen nicht. Lass uns lieber über eine friedliche Geschichte oder Schule reden.';
      case 'sexual_content':
        return 'Darüber spreche ich mit Kindern nicht.';
      case 'politics_extremism':
        return 'Darüber reden wir hier nicht. Ich kann dir aber eine Schulfrage oder ein Naturthema erklären.';
      case 'drugs_alcohol':
        return 'Das ist kein Kinderthema. Lass uns über gesunde Gewohnheiten oder Lernen sprechen.';
      default:
        return 'Lass uns über ein sicheres Kinderthema sprechen.';
    }
  }
}
