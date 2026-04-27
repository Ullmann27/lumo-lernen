// Stub – Real TTS/STT requires platform plugin and consent
class VoiceDirector {
  bool _enabled = false;
  bool get enabled => _enabled;

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  Future<void> speak(String text) async {
    // Stub: In production, integrate flutter_tts or platform TTS
    // Requires parent consent before activation
  }
}
