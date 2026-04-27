// Stub – Real TTS requires flutter_tts plugin and parent consent
class TtsService {
  bool _consentGranted = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  void grantConsent() => _consentGranted = true;
  void revokeConsent() => _consentGranted = false;

  Future<void> speak(String text) async {
    if (!_consentGranted) return; // Silent fail without consent
    _isPlaying = true;
    // Stub: In production, use flutter_tts plugin
    // await _tts.speak(text);
    _isPlaying = false;
  }

  Future<void> stop() async {
    _isPlaying = false;
  }
}
