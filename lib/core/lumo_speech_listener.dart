import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'lumo_voice.dart';

/// Recognition evidence belongs to one capture, never to a learning score.
/// Missing confidence remains unknown. A final transcript is still a proposed
/// transcription and must be confirmed before any learning answer is graded.
class LumoSpeechRecognition {
  LumoSpeechRecognition({
    required this.captureId,
    required this.text,
    required this.isFinal,
    this.confidence,
    List<String> alternatives = const [],
  }) : alternatives = List.unmodifiable(alternatives);

  final int captureId;
  final String text;
  final bool isFinal;
  final double? confidence;
  final List<String> alternatives;

  bool get needsConfirmation =>
      !isFinal || confidence == null || confidence! < .75;
}

enum LumoSpeechErrorKind {
  none,
  noMatch,
  permissionDenied,
  languageUnavailable,
  unavailable,
  interrupted,
}

/// Owns the plugin's process-wide singleton. speech_to_text keeps the callbacks
/// from its first successful initialize call, so a widget must not own them.
/// A retired widget can neither receive a new widget's transcript nor stop its
/// microphone. Native operations are serialized across all listening screens.
class LumoSpeechRecognizer {
  LumoSpeechRecognizer._(this._speech);

  @visibleForTesting
  LumoSpeechRecognizer.withEngine(stt.SpeechToText engine) : this._(engine);

  static final LumoSpeechRecognizer shared = LumoSpeechRecognizer._(
    stt.SpeechToText(),
  );

  final stt.SpeechToText _speech;
  Future<bool>? _initializing;
  Future<void> _operations = Future<void>.value();
  bool _available = false;
  _SpeechLease? _pending;
  _SpeechLease? _active;

  Future<bool> initialize() async {
    if (_available) return true;
    final pending = _initializing;
    if (pending != null) return pending;
    final operation = _speech.initialize(
      debugLogging: false,
      // The plugin otherwise promotes the last partial result to final after
      // a timeout. Zero disables that conversion in the locked 7.5.0 plugin.
      finalTimeout: Duration.zero,
      onStatus: (status) => _active?.onStatus(status),
      onError: (error) => _active?.onError(error.errorMsg),
    );
    _initializing = operation;
    try {
      _available = await operation;
      return _available;
    } finally {
      if (identical(_initializing, operation)) _initializing = null;
    }
  }

  Future<List<stt.LocaleName>> locales() => _speech.locales();

  Future<void> _listen(_SpeechLease lease, String localeId) async {
    final retired = {_active, _pending}..remove(null);
    _active = null;
    _pending = lease;
    for (final previous in retired) {
      previous!.onSuperseded();
    }
    await _serialize(() async {
      // No owner receives the callbacks caused by ending the previous capture.
      await _speech.cancel();
      if (!identical(_pending, lease)) return;
      _pending = null;
      _active = lease;
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          onDevice: true,
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 45),
          // Android may impose a shorter pause. We do not represent this
          // request as a guarantee that the microphone stays open that long.
          pauseFor: const Duration(seconds: 6),
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (result) {
          if (identical(_active, lease)) lease.onResult(result);
        },
      );
    });
  }

  Future<void> _stop(_SpeechLease lease) => _serialize(() async {
    if (identical(_active, lease)) await _speech.stop();
  });

  Future<void> _cancel(_SpeechLease lease) async {
    if (!identical(_active, lease) && !identical(_pending, lease)) return;
    if (identical(_active, lease)) _active = null;
    if (identical(_pending, lease)) _pending = null;
    await _serialize(_speech.cancel);
  }

  Future<void> _serialize(Future<void> Function() action) async {
    final previous = _operations;
    final finished = Completer<void>();
    _operations = finished.future;
    try {
      await previous;
      await action();
    } finally {
      finished.complete();
    }
  }
}

class _SpeechLease {
  const _SpeechLease({
    required this.onResult,
    required this.onStatus,
    required this.onError,
    required this.onSuperseded,
  });

  final ValueChanged<SpeechRecognitionResult> onResult;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onError;
  final VoidCallback onSuperseded;
}

class LumoSpeechListener extends ChangeNotifier {
  LumoSpeechListener({
    bool? isAndroid,
    LumoSpeechRecognizer? recognizer,
    Future<void> Function()? stopPlayback,
  }) : _isAndroid = isAndroid ?? Platform.isAndroid,
       _recognizer = recognizer ?? LumoSpeechRecognizer.shared,
       _stopPlayback = stopPlayback ?? LumoVoice.instance.stop;

  final bool _isAndroid;
  final LumoSpeechRecognizer _recognizer;
  final Future<void> Function() _stopPlayback;
  static int _captureSerial = 0;

  bool _available = false;
  bool _initialized = false;
  bool _listening = false;
  bool _starting = false;
  bool _awaitingFinalResult = false;
  bool _terminal = true;
  bool _disposed = false;
  String _lastWords = '';
  String? _error;
  LumoSpeechErrorKind _errorKind = LumoSpeechErrorKind.none;
  String? _bestLocaleId;
  LumoSpeechRecognition? _lastRecognition;
  Future<bool>? _initializing;
  _SpeechLease? _lease;
  Timer? _finalDeadline;
  ValueChanged<String>? _activeFinalCallback;
  VoidCallback? _activeNoMatchCallback;
  int _generation = 0;

  bool get available => _available;
  bool get initialized => _initialized;
  bool get listening => _listening;
  bool get starting => _starting;
  bool get awaitingFinalResult => _awaitingFinalResult;
  String get lastWords => _lastWords;
  String? get error => _error;
  LumoSpeechErrorKind get errorKind => _errorKind;
  String? get bestLocaleId => _bestLocaleId;
  LumoSpeechRecognition? get lastRecognition => _lastRecognition;

  /// The speaker and microphone never run together through this adapter.
  /// Touch interrupt is supported; acoustic echo cancellation is not provided.
  bool get supportsAcousticBargeIn => false;

  Future<bool> initialize() async {
    if (_disposed) return false;
    if (_available) return true;
    final pending = _initializing;
    if (pending != null) return pending;
    final operation = _initialize();
    _initializing = operation;
    try {
      return await operation;
    } finally {
      if (identical(_initializing, operation)) _initializing = null;
    }
  }

  Future<bool> _initialize() async {
    try {
      if (_isAndroid) {
        final local = await const MethodChannel(
          'lumo_lernen/diagnostics',
        ).invokeMethod<bool>('onDeviceSpeechAvailable');
        if (_disposed) return false;
        if (local != true) {
          _setError(
            LumoSpeechErrorKind.unavailable,
            'Lokale Spracherkennung ist auf diesem Gerät nicht bereit. '
            'Du kannst deine Frage tippen. Es wird keine Cloud-Aufnahme gestartet.',
          );
          return false;
        }
      }
      final ready = await _recognizer.initialize();
      if (_disposed) return false;
      if (!ready) {
        _setError(
          LumoSpeechErrorKind.unavailable,
          'Die Spracheingabe ist nicht bereit. Prüfe die Mikrofonfreigabe '
          'in den Geräteeinstellungen. Du kannst deine Frage auch tippen.',
        );
        return false;
      }
      final locales = await _recognizer.locales();
      if (_disposed) return false;
      final german = locales.where((locale) {
        final id = locale.localeId.toLowerCase().replaceAll('_', '-');
        return id == 'de' || id.startsWith('de-');
      }).toList()..sort((a, b) => _localeScore(b).compareTo(_localeScore(a)));
      if (german.isEmpty) {
        _setError(
          LumoSpeechErrorKind.languageUnavailable,
          'Eine deutsche Spracherkennung ist auf diesem Gerät noch nicht '
          'bestätigt. Du kannst tippen; deine Eltern können die lokale '
          'deutsche Sprache in den Geräteeinstellungen prüfen.',
        );
        return false;
      }
      // A listed locale is a capability hint, not proof that its offline model
      // is installed. A language error at listen time remains text-only.
      _bestLocaleId = german.first.localeId;
      _available = true;
      _error = null;
      _errorKind = LumoSpeechErrorKind.none;
      return true;
    } catch (_) {
      if (!_disposed) {
        _setError(
          LumoSpeechErrorKind.unavailable,
          'Die lokale Spracheingabe konnte nicht gestartet werden. '
          'Du kannst deine Frage tippen.',
        );
      }
      return false;
    } finally {
      if (!_disposed) {
        _initialized = true;
        notifyListeners();
      }
    }
  }

  int _localeScore(stt.LocaleName locale) {
    final id = locale.localeId.toLowerCase().replaceAll('_', '-');
    if (id == 'de-de') return 300;
    if (id.startsWith('de-de-')) return 290;
    if (id == 'de-at') return 200;
    if (id.startsWith('de-at-')) return 190;
    return 100;
  }

  Future<void> startListening({
    ValueChanged<String>? onResult,
    ValueChanged<String>? onFinalResult,
    VoidCallback? onNoMatch,
  }) async {
    if (_disposed) return;
    final generation = ++_generation;
    final previous = _retire();
    _starting = true;
    _lastWords = '';
    _lastRecognition = null;
    _error = null;
    _errorKind = LumoSpeechErrorKind.none;
    notifyListeners();
    try {
      if (previous != null) await _recognizer._cancel(previous);
      if (!_isCurrent(generation)) return;
      await _stopPlayback();
      if (!_isCurrent(generation)) return;
      final ok = await initialize();
      if (!_isCurrent(generation)) return;
      if (!ok) {
        _starting = false;
        notifyListeners();
        return;
      }
      final captureId = ++_captureSerial;
      _terminal = false;
      _activeFinalCallback = onFinalResult;
      _activeNoMatchCallback = onNoMatch;
      final lease = _SpeechLease(
        onResult: (result) {
          if (!_isCurrent(generation) || _terminal) return;
          final rawConfidence = result.hasConfidenceRating
              ? result.confidence
              : null;
          final confidence =
              rawConfidence != null &&
                  rawConfidence.isFinite &&
                  rawConfidence >= 0 &&
                  rawConfidence <= 1
              ? rawConfidence
              : null;
          _lastWords = result.recognizedWords;
          _lastRecognition = LumoSpeechRecognition(
            captureId: captureId,
            text: _lastWords,
            isFinal: result.finalResult,
            confidence: confidence,
            alternatives: result.alternates
                .map((entry) => entry.recognizedWords.trim())
                .where((words) => words.isNotEmpty)
                .toSet()
                .take(8)
                .toList(growable: false),
          );
          onResult?.call(_lastWords);
          if (!_isCurrent(generation) || _terminal) return;
          if (result.finalResult) {
            final words = _lastWords.trim();
            if (words.isEmpty) {
              _finishWithoutResult(generation);
            } else {
              final callback = _activeFinalCallback;
              final completed = _retire();
              if (completed != null) {
                unawaited(_cancelQuietly(completed));
              }
              callback?.call(words);
              notifyListeners();
            }
          } else {
            notifyListeners();
          }
        },
        onStatus: (status) {
          if (!_isCurrent(generation) || _terminal) return;
          final normalized = status.toLowerCase();
          if (normalized == 'listening') {
            _starting = false;
            _listening = true;
            _awaitingFinalResult = false;
            _finalDeadline?.cancel();
            _finalDeadline = null;
          } else if (normalized == 'notlistening' || normalized == 'done') {
            _waitForFinal(generation);
          }
          notifyListeners();
        },
        onError: (code) {
          if (!_isCurrent(generation) || _terminal) return;
          final normalized = code.toLowerCase();
          if (normalized.contains('no_match') ||
              normalized.contains('no match') ||
              normalized.contains('speech_timeout')) {
            _finishWithoutResult(generation);
            return;
          }
          final kind =
              normalized.contains('permission') ||
                  normalized.contains('not_allowed')
              ? LumoSpeechErrorKind.permissionDenied
              : normalized.contains('language')
              ? LumoSpeechErrorKind.languageUnavailable
              : LumoSpeechErrorKind.unavailable;
          final message = switch (kind) {
            LumoSpeechErrorKind.permissionDenied =>
              'Das Mikrofon ist nicht freigegeben. Du kannst tippen oder '
                  'deine Eltern um Hilfe mit der Gerätefreigabe bitten.',
            LumoSpeechErrorKind.languageUnavailable =>
              'Die deutsche Sprache ist lokal noch nicht bereit. '
                  'Du kannst tippen. Es wird keine Cloud-Aufnahme gestartet.',
            _ =>
              'Die Spracheingabe wurde unterbrochen. Deine Lernantwort '
                  'wurde dadurch nicht bewertet. Du kannst tippen oder es '
                  'noch einmal versuchen.',
          };
          final failed = _retire();
          _available = false;
          _setError(kind, message);
          if (failed != null) unawaited(_cancelQuietly(failed));
          notifyListeners();
        },
        onSuperseded: () {
          if (!_isCurrent(generation)) return;
          _generation++;
          _retire();
          _setError(
            LumoSpeechErrorKind.interrupted,
            'Das Mikrofon wird jetzt in einer anderen Ansicht verwendet.',
          );
          notifyListeners();
        },
      );
      _lease = lease;
      await _recognizer._listen(lease, _bestLocaleId!);
    } catch (_) {
      if (!_isCurrent(generation)) return;
      final failed = _retire();
      _setError(
        LumoSpeechErrorKind.unavailable,
        'Die lokale Spracheingabe konnte nicht gestartet werden. '
        'Du kannst deine Frage tippen.',
      );
      if (failed != null) await _cancelQuietly(failed);
      notifyListeners();
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _setError(LumoSpeechErrorKind kind, String message) {
    _errorKind = kind;
    _error = message;
  }

  void _waitForFinal(int generation) {
    _starting = false;
    _listening = false;
    _awaitingFinalResult = true;
    // This is a deadline for a real platform result, not a fabricated final.
    _finalDeadline ??= Timer(const Duration(seconds: 3), () {
      _finalDeadline = null;
      _finishWithoutResult(generation);
    });
  }

  void _finishWithoutResult(int generation) {
    if (!_isCurrent(generation) || _terminal) return;
    final callback = _activeNoMatchCallback;
    final ended = _retire();
    _setError(
      LumoSpeechErrorKind.noMatch,
      _lastWords.trim().isEmpty
          ? 'Ich habe keine vollständige Frage verstanden. Lass dir Zeit; '
                'du kannst noch einmal sprechen oder tippen.'
          : 'Ich habe deinen Satz noch nicht sicher verstanden. '
                'Bitte sprich ihn noch einmal oder ergänze den sichtbaren Text.',
    );
    if (ended != null) unawaited(_cancelQuietly(ended));
    callback?.call();
    notifyListeners();
  }

  _SpeechLease? _retire() {
    final previous = _lease;
    _lease = null;
    _finalDeadline?.cancel();
    _finalDeadline = null;
    _starting = false;
    _listening = false;
    _awaitingFinalResult = false;
    _terminal = true;
    _activeFinalCallback = null;
    _activeNoMatchCallback = null;
    return previous;
  }

  Future<void> _cancelQuietly(_SpeechLease lease) async {
    try {
      await _recognizer._cancel(lease);
    } catch (_) {
      // The lease has already been invalidated synchronously.
    }
  }

  Future<void> stopListening() async {
    if (_disposed) return;
    if (_starting && !_listening) {
      await cancel();
      return;
    }
    final lease = _lease;
    final generation = _generation;
    if (lease == null || _terminal) return;
    _waitForFinal(generation);
    notifyListeners();
    try {
      await _recognizer._stop(lease);
    } catch (_) {
      _finishWithoutResult(generation);
    }
  }

  Future<void> cancel() async {
    if (_disposed) return;
    _generation++;
    final lease = _retire();
    _lastWords = '';
    _lastRecognition = null;
    _error = null;
    _errorKind = LumoSpeechErrorKind.none;
    notifyListeners();
    if (lease != null) await _cancelQuietly(lease);
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    final lease = _retire();
    if (lease != null) unawaited(_cancelQuietly(lease));
    super.dispose();
  }
}
