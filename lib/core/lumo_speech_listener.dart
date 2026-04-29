import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LumoSpeechListener extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _available = false;
  bool _initialized = false;
  bool _listening = false;
  String _lastWords = '';
  String? _error;

  bool get available => _available;
  bool get initialized => _initialized;
  bool get listening => _listening;
  String get lastWords => _lastWords;
  String? get error => _error;

  Future<bool> initialize() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          _listening = status == 'listening';
          notifyListeners();
        },
        onError: (error) {
          _error = error.errorMsg;
          _listening = false;
          notifyListeners();
        },
      );
      _initialized = true;
      notifyListeners();
      return _available;
    } catch (e) {
      _error = 'Spracheingabe konnte nicht gestartet werden: $e';
      _available = false;
      _initialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<void> startListening({ValueChanged<String>? onResult}) async {
    final ok = await initialize();
    if (!ok) return;
    _lastWords = '';
    _error = null;
    _listening = true;
    notifyListeners();

    await _speech.listen(
      localeId: 'de_AT',
      listenMode: stt.ListenMode.confirmation,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onResult?.call(_lastWords);
        if (result.finalResult) {
          _listening = false;
        }
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _listening = false;
    notifyListeners();
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    _listening = false;
    notifyListeners();
  }
}
