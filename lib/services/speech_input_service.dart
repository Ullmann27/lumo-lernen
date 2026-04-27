// Stub – Real STT requires speech_to_text plugin and parent consent
class SpeechInputService {
  bool _consentGranted = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  void grantConsent() => _consentGranted = true;
  void revokeConsent() => _consentGranted = false;

  Future<void> startListening(void Function(String) onResult) async {
    if (!_consentGranted) {
      throw Exception('Elternerlaubnis für Mikrofon erforderlich.');
    }
    _isListening = true;
    // Stub: In production, use speech_to_text plugin
  }

  Future<void> stopListening() async {
    _isListening = false;
  }
}
