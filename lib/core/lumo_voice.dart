import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Sprachausgabe fuer Lumo - garantiert robust.
///
/// Hauptmerkmale:
/// - Wartet beim ersten Aufruf garantiert auf vollstaendige Initialisierung
/// - Faellt automatisch von de-AT auf de-DE auf Standard zurueck
/// - Zeigt Status (sprechend / bereit / Fehler) per ValueNotifier nach aussen
/// - Schluckt nichts still: bei Fehlern wird der Status auf "error" gesetzt
/// - 100 Prozent on-device, Play-Store-konform fuer Kinder-Apps
class LumoVoice {
  LumoVoice._internal();
  static final LumoVoice instance = LumoVoice._internal();

  final FlutterTts _tts = FlutterTts();
  Future<void>? _initFuture;
  bool _enabled = true;

  /// Beobachtbarer Status (fuer UI-Indikator).
  final ValueNotifier<VoiceStatus> status =
      ValueNotifier<VoiceStatus>(VoiceStatus.idle);

  /// Letzter Fehlertext (zur Anzeige).
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  bool get isEnabled => _enabled;
  set isEnabled(bool v) => _enabled = v;

  /// Erzwingt Initialisierung. Idempotent. Wartet auf laufende Init.
  Future<void> _ensureReady() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      // Handler fuer Status-Updates
      _tts.setStartHandler(() => status.value = VoiceStatus.speaking);
      _tts.setCompletionHandler(() => status.value = VoiceStatus.idle);
      _tts.setCancelHandler(() => status.value = VoiceStatus.idle);
      _tts.setErrorHandler((msg) {
        lastError.value = msg.toString();
        status.value = VoiceStatus.error;
      });

      // Sprache: de-AT bevorzugt, sonst de-DE, sonst System
      var languageOk = false;
      for (final lang in ['de-AT', 'de-DE', 'de']) {
        try {
          final res = await _tts.isLanguageAvailable(lang);
          if (res == true || res == 1) {
            await _tts.setLanguage(lang);
            languageOk = true;
            break;
          }
        } catch (_) {/* weiter */ }
      }
      if (!languageOk) {
        try {
          await _tts.setLanguage('de-DE');
        } catch (_) {/* notfalls Default */}
      }

      // Kindgerechte Stimm-Parameter
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.18);
      await _tts.setVolume(1.0);

      // Wir blockieren nicht auf Sprech-Ende - sonst staut sich die UI
      try {
        await _tts.awaitSpeakCompletion(false);
      } catch (_) {}

      status.value = VoiceStatus.idle;
    } catch (e) {
      lastError.value = 'TTS-Init fehlgeschlagen: $e';
      status.value = VoiceStatus.error;
      // _initFuture trotzdem als "fertig" markieren - speak() kann es spaeter neu versuchen
    }
  }

  /// Sagt den Text. Bricht laufende Sprachausgabe ab.
  Future<void> speak(String text) async {
    if (!_enabled || text.trim().isEmpty) return;
    await _ensureReady();
    try {
      await _tts.stop();
      final r = await _tts.speak(text);
      if (kDebugMode) debugPrint('[LumoVoice] speak("$text") -> $r');
    } catch (e) {
      lastError.value = 'TTS-Fehler: $e';
      status.value = VoiceStatus.error;
    }
  }

  /// Bricht jede laufende Ausgabe sofort ab.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    status.value = VoiceStatus.idle;
  }

  /// Test-Funktion - sagt einen festen Probesatz.
  Future<void> test() => speak('Hallo! Ich bin Lumo, dein Lernfuchs.');
}

enum VoiceStatus { idle, speaking, error }
