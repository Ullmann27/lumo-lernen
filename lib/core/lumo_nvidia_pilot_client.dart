import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_settings.dart';
import 'lumo_ai_learning_access.dart';
import 'lumo_ai_learning_policy_bridge.dart';
import 'lumo_ai_proxy_client.dart';

/// Explicit, opt-in NVIDIA transport. Existing chat and offline paths never
/// invoke this class. A verified parent's short-lived bearer is passed in
/// memory; credentials and consent are NEVER embedded or stored in the APK.
class LumoNvidiaPilotClient {
  const LumoNvidiaPilotClient();

  static const _timeout = Duration(seconds: 25);
  static const _contexts = <String>{
    'companion', 'learning_tutor', 'math_coach',
    'reading_buddy', 'writing_helper', 'science_explorer',
  };

  Future<LumoNvidiaPilotResult> ask({
    required AppSettings settings,
    required String verifiedParentBearer,
    required String message,
    required String context,
    required int grade,
  }) async {
    final area = context == 'reading_buddy'
        ? LumoAiLearningArea.readingHelp
        : context == 'companion'
            ? LumoAiLearningArea.chat
            : LumoAiLearningArea.taskHelp;
    final prompt = message.trim();
    final bearer = verifiedParentBearer.trim();
    final personal = RegExp(r'[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}').hasMatch(prompt) ||
        RegExp(r'\+?\d[\d\s()/.-]{7,}\d').hasMatch(prompt);
    if (!settings.lumoAiLearningAccess.allows(area) ||
        !_contexts.contains(context) ||
        grade < 1 || grade > 4 ||
        prompt.isEmpty || prompt.length > 800 ||
        !LumoChildSafetyFilter.inspect(prompt).allowed ||
        personal || bearer.isEmpty || bearer.length > 4000) {
      return const LumoNvidiaPilotResult(
        reply: 'Die NVIDIA-Lernhilfe ist nicht freigegeben. Lumo hilft dir lokal weiter.',
        available: false, reason: 'local_not_authorized',
      );
    }
    // A verified parent's bearer must NEVER be sent to a user-configurable
    // arbitrary HTTPS proxy. Restrict the pilot to the trusted Lumo proxy;
    // loopback is allowed only for local automated tests.
    final base = Uri.tryParse(settings.aiProxyUrl.trim());
    final official = Uri.parse(AppSettings.defaultAiProxyUrl);
    final trustedProduction = base != null &&
        base.scheme == 'https' && base.host == official.host &&
        (base.port == 443 || !base.hasPort);
    final localTest = base != null &&
        (base.host == 'localhost' || base.host == '127.0.0.1') &&
        (base.scheme == 'http' || base.scheme == 'https');
    if (base == null || base.host.isEmpty || base.userInfo.isNotEmpty ||
        base.hasQuery || base.hasFragment ||
        (!trustedProduction && !localTest)) {
      return const LumoNvidiaPilotResult(
        reply: 'Der sichere KI-Server ist nicht erreichbar.',
        available: false, reason: 'invalid_proxy_url',
      );
    }
    final path = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final endpoint = base.replace(
      path: path + '/nvidia/pilot/chat',
      query: '', fragment: '',
    );
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.postUrl(endpoint).timeout(_timeout);
      request.followRedirects = false; // Never forward parent token.
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ' + bearer);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(<String, Object>{
        'message': prompt, 'context': context, 'grade': grade,
      }));
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>().timeout(_timeout);
        return const LumoNvidiaPilotResult(
          reply: 'Die NVIDIA-Lernhilfe ist gerade nicht verfügbar. Wir lernen lokal weiter.',
          available: false, reason: 'pilot_unavailable',
        );
      }
      final parts = <int>[];
      await for (final chunk in response.timeout(_timeout)) {
        parts.addAll(chunk);
        if (parts.length > 8192) {
          return const LumoNvidiaPilotResult(
            reply: 'Die Antwort war zu groß. Lumo hilft lokal weiter.',
            available: false, reason: 'oversized_response',
          );
        }
      }
      final decoded = jsonDecode(utf8.decode(parts));
      if (decoded is! Map<String, dynamic> ||
          decoded['source'] != 'nvidia_nemotron_pilot' ||
          decoded['reply'] is! String) {
        return const LumoNvidiaPilotResult(
          reply: 'Die Antwort war unvollständig. Lumo hilft lokal weiter.',
          available: false, reason: 'invalid_reply',
        );
      }
      final reply = (decoded['reply'] as String).trim();
      if (reply.isEmpty || reply.length > 600 ||
          !LumoChildSafetyFilter.inspect(reply).allowed) {
        return const LumoNvidiaPilotResult(
          reply: 'Lumo schlägt eine neue Lernfrage vor.',
          available: false, reason: 'unsafe_reply',
        );
      }
      return LumoNvidiaPilotResult(
        reply: reply, available: true,
        blocked: decoded['blocked'] == true,
      );
    } catch (_) {
      return const LumoNvidiaPilotResult(
        reply: 'Ohne Internet hilft dir Lumo weiterhin lokal.',
        available: false, reason: 'network_error',
      );
    } finally {
      client.close(force: true);
    }
  }
}

class LumoNvidiaPilotResult {
  const LumoNvidiaPilotResult({
    required this.reply, required this.available,
    this.blocked = false, this.reason,
  });
  final String reply;
  final bool available;
  final bool blocked;
  final String? reason;
}
