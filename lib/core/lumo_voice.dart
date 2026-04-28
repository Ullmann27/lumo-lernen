import 'package:flutter_tts/flutter_tts.dart';

/// Sprachausgabe für Lumo.
///
/// **Privacy / Play Store:**
/// flutter_tts nutzt die ON-DEVICE-Engine des Betriebssystems
/// (Google TTS auf Android, AVSpeechSynthesizer auf iOS).
/// Es werden KEINE Audio-Daten an externe Server gesendet.
/// Damit ist die Komponente konform zum Google Play
/// Designed-for-Families-Programm und der DSGVO.
///
/// Die Stimme wird so konfiguriert, dass sie
/// möglichst freundlich und kindgerecht klingt:
/// - Sprache: Deutsch (DE-AT bevorzugt, sonst DE-DE)
/// - Etwas höhere Tonlage für eine warme Charakter-Stimme
/// - Leicht reduzierte Geschwindigkeit für junge Hörer
class LumoVoice {
  LumoVoice._internal();
  static final LumoVoice instance = LumoVoice._internal();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _enabled = true;

  bool get isEnabled => _enabled;
  set isEnabled(bool value) => _enabled = value;

  /// Initialisiert die TTS-Engine. Idempotent.
  Future<void> init() async {
    if (_ready) return;
    try {
      // Bevorzugt österreichisches Deutsch, fällt auf DE-DE zurück
      await _tts.setLanguage('de-AT');
    } catch (_) {
      try {
        await _tts.setLanguage('de-DE');
      } catch (_) {/* Sprache nicht verfügbar – System-Default */}
    }
    // Kindgerechte Werte
    await _tts.setSpeechRate(0.45); // 0.5 = neutral; etwas langsamer
    await _tts.setPitch(1.18);      // 1.0 = neutral; warm + freundlich
    await _tts.setVolume(0.95);
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// Spricht den Text aus. Bricht laufende Ausgaben ab.
  Future<void> speak(String text) async {
    if (!_enabled || text.trim().isEmpty) return;
    await init();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // TTS ist optional – Fehler dürfen die App nicht blockieren.
    }
  }

  /// Beendet jede laufende Sprachausgabe.
  Future<void> stop() async {
    if (!_ready) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
