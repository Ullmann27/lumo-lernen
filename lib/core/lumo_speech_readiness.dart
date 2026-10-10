import 'dart:convert';
import 'dart:io';
import 'lumo_sulafat_client.dart';

/// An unbilled configuration probe, deliberately not an audible voice test.
class LumoSpeechReadiness {
  const LumoSpeechReadiness(this.message, {this.configured = false});
  final String message;
  final bool configured;

  static Future<LumoSpeechReadiness> check(String baseUrl) async {
    final uri = Uri.tryParse(baseUrl.trim());
    final local = uri?.host == 'localhost' || uri?.host == '127.0.0.1';
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !(local && uri.scheme == 'http'))) {
      return const LumoSpeechReadiness('Sprachserver-Adresse ist ungültig.');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final endpoint = uri.replace(
          path: '${uri.path.replaceFirst(RegExp(r'/+$'), '')}/speech/status',
          query: '',
          fragment: '');
      final request =
          await client.getUrl(endpoint).timeout(const Duration(seconds: 12));
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        return const LumoSpeechReadiness(
            'Der Server hat noch keinen Sulafat-Diagnose-Endpunkt. '
            'Eine grüne KI-Verbindung bestätigt keine Online-Stimme.');
      }
      if (response.statusCode != 200) {
        return LumoSpeechReadiness(
            'Sprachserver meldet HTTP ${response.statusCode}. '
            'Es wird keine andere Stimme eingesetzt.');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 10))) {
        if (bytes.length + chunk.length > 16384) {
          return const LumoSpeechReadiness('Ungültige Sprachserver-Diagnose.');
        }
        bytes.addAll(chunk);
      }
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map ||
          data['voice'] != 'Sulafat' ||
          data['profile'] != LumoSulafatClient.referenceProfile ||
          data['model'] != LumoSulafatClient.referenceModel) {
        return const LumoSpeechReadiness(
            'Der Server bestätigt nicht das Original-Sulafat-Profil.');
      }
      final configured = data['configured'] == true;
      return LumoSpeechReadiness(
          configured
              ? 'Sulafat ist serverseitig konfiguriert. Eine erfolgreiche Hörprobe '
                  'ist damit noch nicht bestätigt.'
              : 'Sulafat ist serverseitig noch nicht aktiviert oder der Gemini-Zugang fehlt.',
          configured: configured);
    } catch (_) {
      return const LumoSpeechReadiness('Sprachserver derzeit nicht erreichbar. '
          'Vorhandene Originalaufnahmen bleiben verfügbar.');
    } finally {
      client.close(force: true);
    }
  }
}
