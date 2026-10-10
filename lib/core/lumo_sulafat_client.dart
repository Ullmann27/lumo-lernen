import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'lumo_wav_audio.dart';

/// Cancels the actual HTTP connection, not just a late UI callback.
class LumoSpeechCancellation {
  bool cancelled = false;
  void Function()? _close;
  void attach(void Function() close) {
    _close = close;
    if (cancelled) close();
  }

  void detach() => _close = null;
  void cancel() {
    cancelled = true;
    _close?.call();
  }
}

/// Exchanges only a voluntarily enabled utterance with the existing Lumo
/// proxy. The proxy (not this APK) holds the Google Gemini API key.
/// Returned WAV is produced with the same Sulafat speaker as Lumo's
/// pre-recorded welcome sample. No other speaker can be returned.
class LumoSulafatClient {
  const LumoSulafatClient();

  static const int maxSegmentCharacters = 440;
  static const String referenceProfile = 'lumo-sulafat-reference-v1';
  static const String referenceModel = 'gemini-2.5-pro-preview-tts';

  static List<String> segments(String input) {
    final words = input.trim().split(RegExp(r'\s+'));
    final result = <String>[];
    var buffer = '';
    for (final word in words) {
      if (word.isEmpty) continue;
      if (word.length > maxSegmentCharacters) {
        if (buffer.isNotEmpty) {
          result.add(buffer);
          buffer = '';
        }
        for (var i = 0; i < word.length; i += maxSegmentCharacters) {
          final end = i + maxSegmentCharacters < word.length
              ? i + maxSegmentCharacters
              : word.length;
          result.add(word.substring(i, end));
        }
        continue;
      }
      final candidate = buffer.isEmpty ? word : '$buffer $word';
      if (candidate.length > maxSegmentCharacters) {
        result.add(buffer);
        buffer = word;
      } else {
        buffer = candidate;
      }
    }
    if (buffer.isNotEmpty) result.add(buffer);
    return result;
  }

  Future<Uint8List> synthesize({
    required String text,
    required String style,
    required String baseUrl,
    LumoSpeechCancellation? cancellation,
  }) async {
    if (cancellation?.cancelled == true)
      throw const HttpException('Abgebrochen');
    final parsed = Uri.tryParse(baseUrl.trim());
    if (parsed == null || parsed.host.isEmpty) {
      throw const FormatException('Lumo-Sprachserver fehlt.');
    }
    final local = parsed.host == 'localhost' || parsed.host == '127.0.0.1';
    if (parsed.scheme != 'https' && !(local && parsed.scheme == 'http')) {
      throw const FormatException('Sulafat benötigt HTTPS.');
    }
    final endpoint = parsed.replace(
      path: '${parsed.path.replaceFirst(RegExp(r'/+$'), '')}/speech',
      query: '',
      fragment: '',
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    cancellation?._close = () => client.close(force: true);
    try {
      final request = await client.postUrl(endpoint).timeout(
            const Duration(seconds: 14),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set('cache-control', 'no-store');
      request.add(utf8.encode(jsonEncode({'text': text, 'style': style})));
      final response = await request.close().timeout(
            const Duration(seconds: 35),
          );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Sulafat-Sprachserver nicht verfügbar (${response.statusCode})',
          uri: endpoint,
        );
      }
      final buffer = BytesBuilder(copy: false);
      var received = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        received += chunk.length;
        if (received > 12000000 || cancellation?.cancelled == true) {
          throw const FormatException('Sprachdatei zu groß oder abgebrochen.');
        }
        buffer.add(chunk);
      }
      final body = utf8.decode(buffer.takeBytes());
      final data = jsonDecode(body);
      if (data is! Map ||
          data['voice'] != 'Sulafat' ||
          data['profile'] != referenceProfile ||
          data['model'] != referenceModel ||
          data['format'] != 'audio/wav' ||
          data['audioBase64'] is! String) {
        throw const FormatException('Falsche Stimme vom Sprachserver.');
      }
      final bytes = base64Decode(data['audioBase64'] as String);
      LumoWavAudio.parse(bytes);
      return bytes;
    } finally {
      cancellation?._close = null;
      client.close(force: true);
    }
  }
}
