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
  String? _bestLocaleId;
  ValueChanged<String>? _activeFinalCallback;
  VoidCallback? _activeNoMatchCallback;

  bool get available => _available;
  bool get initialized => _initialized;
  bool get listening => _listening;
  String get lastWords => _lastWords;
  String? get error => _error;
  String? get bestLocaleId => _bestLocaleId;

  Future<bool> initialize() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        debugLogging: false,
        onStatus: (status) {
          final normalized = status.toLowerCase();
          final wasListening = _listening;
          _listening = normalized == 'listening';
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
      if (_available) {
        _bestLocaleId = await _bestGermanLocale();
      }
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

  Future<String?> _bestGermanLocale() async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return 'de_AT';
      final ranked = List<stt.LocaleName>.from(locales);
      ranked.sort((a, b) => _localeScore(b).compareTo(_localeScore(a)));
      return ranked.first.localeId;
    } catch (_) {
      return 'de_AT';
    }
  }

  int _localeScore(stt.LocaleName locale) {
    final id = locale.localeId.toLowerCase().replaceAll('_', '-');
    final name = locale.name.toLowerCase();
    var score = 0;
    if (id == 'de-at') score += 160;
    if (id == 'de-de') score += 150;
    if (id.startsWith('de-at')) score += 140;
    if (id.startsWith('de-de')) score += 130;
    if (id.startsWith('de')) score += 100;
    if (name.contains('österreich') || name.contains('austria')) score += 30;
    if (name.contains('deutsch') || name.contains('german')) score += 20;
    return score;
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
      localeId: _bestLocaleId ?? 'de_AT',
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(seconds: 32),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
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
