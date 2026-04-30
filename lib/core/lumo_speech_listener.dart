import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LumoSpeechListener extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _available = false;
  bool _initialized = false;
  bool _listening = false;
  bool _finalDelivered = false;
  String _lastWords = '';
  String? _error;
  ValueChanged<String>? _activeFinalCallback;
  VoidCallback? _activeNoMatchCallback;

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
          final wasListening = _listening;
          _listening = status == 'listening';
          if (wasListening && !_listening && _lastWords.trim().isNotEmpty) {
            _deliverFinal(_lastWords);
          }
          notifyListeners();
        },
        onError: (error) {
          _error = error.errorMsg;
          _listening = false;
          if (_lastWords.trim().isNotEmpty) {
            _deliverFinal(_lastWords);
          } else if (_isNoMatchError(error.errorMsg)) {
            _activeNoMatchCallback?.call();
          }
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

  Future<void> startListening({
    ValueChanged<String>? onResult,
    ValueChanged<String>? onFinalResult,
    VoidCallback? onNoMatch,
  }) async {
    final ok = await initialize();
    if (!ok) return;
    _lastWords = '';
    _error = null;
    _finalDelivered = false;
    _activeFinalCallback = onFinalResult;
    _activeNoMatchCallback = onNoMatch;
    _listening = true;
    notifyListeners();

    await _speech.listen(
      localeId: 'de_AT',
      listenMode: stt.ListenMode.confirmation,
      listenFor: const Duration(seconds: 9),
      pauseFor: const Duration(milliseconds: 1200),
      partialResults: true,
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onResult?.call(_lastWords);
        if (result.finalResult) {
          _listening = false;
          _deliverFinal(_lastWords);
          _stopSilently();
        }
        notifyListeners();
      },
    );
  }

  void _deliverFinal(String words) {
    final text = words.trim();
    if (_finalDelivered || text.isEmpty) return;
    _finalDelivered = true;
    _activeFinalCallback?.call(text);
  }

  bool _isNoMatchError(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('no_match') || normalized.contains('no match');
  }

  Future<void> _stopSilently() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _listening = false;
    if (_lastWords.trim().isNotEmpty) _deliverFinal(_lastWords);
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
