import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Optionaler Premium-TTS-Pfad fuer Lumo.
///
/// Sicherheit:
/// - komplett deaktiviert, wenn kein Endpoint per dart-define gesetzt ist
/// - API-Key wird nur aus dart-define gelesen und nie geloggt
/// - Text wird vor Versand minimiert und von typischen privaten Details bereinigt
/// - bei jedem Fehler gibt `speak` false zurueck, damit LumoVoice lokal mit
///   flutter_tts weitersprechen kann
class LumoPremiumVoice {
  LumoPremiumVoice({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  static const String endpoint = String.fromEnvironment('LUMO_PREMIUM_TTS_ENDPOINT');
  static const String voiceId = String.fromEnvironment('LUMO_PREMIUM_TTS_VOICE_ID');
  static const String apiKey = String.fromEnvironment('LUMO_PREMIUM_TTS_API_KEY');

  static const Duration _networkTimeout = Duration(seconds: 7);
  static const int _maxTextLength = 240;
  static const int _maxCacheFiles = 80;

  final AudioPlayer _player;
  Directory? _cacheDir;

  bool get configured => endpoint.trim().isNotEmpty;

  Future<bool> speak(String text) async {
    if (!configured) return false;
    final safeText = sanitizeForPremiumTts(text);
    if (safeText.isEmpty) return false;

    try {
      final file = await _cachedOrFetch(safeText);
      if (file == null || !await file.exists()) return false;
      await _player.stop();
      await _player.setFilePath(file.path);
      await _player.play().timeout(const Duration(seconds: 20));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[LumoPremiumVoice] fallback: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }

  Future<File?> _cachedOrFetch(String safeText) async {
    final dir = await _ensureCacheDir();
    final cacheKey = sha256.convert(utf8.encode('$voiceId|$safeText')).toString();
    final file = File('${dir.path}/$cacheKey.mp3');
    if (await file.exists() && await file.length() > 256) return file;

    final bytes = await _fetchAudioBytes(safeText);
    if (bytes == null || bytes.length <= 256) return null;
    await file.writeAsBytes(bytes, flush: true);
    unawaited(_trimCache(dir));
    return file;
  }

  Future<Directory> _ensureCacheDir() async {
    final existing = _cacheDir;
    if (existing != null) return existing;
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/lumo_voice_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }

  Future<List<int>?> _fetchAudioBytes(String safeText) async {
    final uri = Uri.tryParse(endpoint.trim());
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return null;
    }

    final client = HttpClient()..connectionTimeout = _networkTimeout;
    try {
      final request = await client.postUrl(uri).timeout(_networkTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'audio/mpeg, application/octet-stream, application/json');
      if (apiKey.trim().isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      }
      request.write(jsonEncode(<String, Object?>{
        'text': safeText,
        if (voiceId.trim().isNotEmpty) 'voice_id': voiceId.trim(),
        'format': 'mp3',
        'app': 'lumo_lernen',
      }));

      final response = await request.close().timeout(_networkTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final bytes = await consolidateHttpClientResponseBytes(response);
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _trimCache(Directory dir) async {
    try {
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.mp3'))
          .cast<File>()
          .toList();
      if (files.length <= _maxCacheFiles) return;
      files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      for (final file in files.take(files.length - _maxCacheFiles)) {
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  static String sanitizeForPremiumTts(String input) {
    var text = input
        .replaceAll('\n', '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '')
        .trim();

    // Keine offensichtlichen privaten Daten an externe TTS-Endpunkte senden.
    text = text.replaceAll(RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'\b\+?\d[\d\s/().-]{6,}\d\b'), '');
    text = text.replaceAll(RegExp(r'\b\d{4}\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß\-]+\b'), '');

    // Namen aus typischen persoenlichen Anreden entfernen, damit Premium-TTS
    // keine Kinderprofile braucht. Lokale TTS darf den Namen weiterhin sprechen.
    text = text.replaceAll(RegExp(r'\b(Hallo|Hi|Hey|Na)\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß\-]{1,24}[,!]?', caseSensitive: false), r'$1!');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > _maxTextLength) {
      text = text.substring(0, _maxTextLength).trimRight();
    }
    return text;
  }
}
