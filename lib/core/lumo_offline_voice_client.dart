import 'package:flutter/services.dart';

import 'lumo_wav_audio.dart';

/// A private Android CPU inference channel, never an external speech API.
class LumoOfflineVoiceClient {
  const LumoOfflineVoiceClient();
  static const profile = 'lumo-free-supertonic-de-v1';
  static const preset = 'F2';
  static const channel = MethodChannel('lumo_lernen/offline_speech');

  Future<bool> available() async {
    try {
      final data = await channel
          .invokeMapMethod<String, dynamic>('availability')
          .timeout(const Duration(seconds: 3));
      return data?['available'] == true &&
          data?['profile'] == profile &&
          data?['preset'] == preset &&
          data?['language'] == 'de' &&
          data?['local'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List> synthesize({
    required String text,
    required String style,
    required bool localLicenseAccepted,
  }) async {
    if (!localLicenseAccepted || text.trim().isEmpty || text.length > 220) {
      throw const LumoOfflineSpeechException(
          'Neue lokale Sprachtexte benötigen die Sprachlizenz-Freigabe im Elternbereich.');
    }
    try {
      final result =
          await channel.invokeMapMethod<String, dynamic>('synthesize', {
        'text': text,
        'style': style,
        'localLicenseAccepted': true,
      }).timeout(const Duration(seconds: 45));
      final bytes = result?['wav'];
      if (result?['profile'] != profile ||
          result?['preset'] != preset ||
          result?['language'] != 'de' ||
          result?['local'] != true ||
          result?['sampleRate'] != 44100 ||
          bytes is! Uint8List) {
        throw const FormatException('Unverified local voice identity');
      }
      if (LumoWavAudio.parse(bytes).sampleRate != 44100) {
        throw const FormatException('Local model sample rate mismatch');
      }
      return bytes;
    } on LumoOfflineSpeechException {
      rethrow;
    } catch (_) {
      await cancel();
      throw const LumoOfflineSpeechException(
          'Die lokale Lumo-Stimme ist für diesen Satz nicht verfügbar. '
          'Der Text bleibt lesbar; es wird keine andere Stimme aktiviert.');
    }
  }

  Future<void> cancel() async {
    try {
      await channel
          .invokeMethod<void>('cancel')
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // A desktop preview/missing plugin never causes a network fallback.
    }
  }
}

class LumoOfflineSpeechException implements Exception {
  const LumoOfflineSpeechException(this.userMessage);
  final String userMessage;
}
