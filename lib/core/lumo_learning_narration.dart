import 'dart:async';

import 'package:flutter/foundation.dart';

import 'lumo_voice.dart';

/// Owns explicit explanation playback for one learning page.
///
/// Uses the central player and its selected voice. Pause deliberately stops
/// preparation/audio; repeat starts the retained explanation from the beginning.
/// Automatic feedback is discarded while any central narration is busy.
class LumoLearningNarration extends ChangeNotifier {
  LumoLearningNarration({LumoVoice? voice})
      : _voice = voice ?? LumoVoice.instance;

  final LumoVoice _voice;
  String? _currentText;
  bool _isPaused = false;
  bool _isActive = false;
  bool _disposed = false;
  int _revision = 0;

  String? get currentText => _currentText;
  bool get isPaused => _isPaused;
  bool get isActive => _isActive;

  bool get _voiceBusy => switch (_voice.status.value) {
        VoiceStatus.preparing ||
        VoiceStatus.speaking ||
        VoiceStatus.paused =>
          true,
        VoiceStatus.idle || VoiceStatus.error => false,
      };

  /// The newest explicit request cancels preparation and audio immediately.
  Future<void> read(String text) async {
    if (_disposed || text.trim().isEmpty) return;
    _currentText = text.trim();
    await _play(_currentText!, style: VoiceStyle.explain, interrupt: true);
  }

  /// Feedback never waits behind an explanation or displaces another player.
  Future<void> feedback(String text) async {
    if (_disposed ||
        text.trim().isEmpty ||
        _isActive ||
        _isPaused ||
        _voiceBusy) {
      return;
    }
    await _play(text.trim(), style: VoiceStyle.warm, interrupt: false);
  }

  Future<void> _play(String text,
      {required VoiceStyle style, required bool interrupt}) async {
    final revision = ++_revision;
    final identity = _voice.identity;
    _isActive = true;
    _isPaused = false;
    notifyListeners();
    try {
      if (interrupt) await _voice.stop();
      if (!_isCurrent(revision) || identity != _voice.identity) return;
      await _voice.speakAndWait(text, style: style);
    } finally {
      // stop, pause, disposal and a newer read retire this completion.
      if (_isCurrent(revision)) {
        _isActive = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int revision) => !_disposed && revision == _revision;

  Future<void> repeat() async {
    final text = _currentText;
    if (_disposed || text == null) return;
    await read(text);
  }

  /// Cancels even a slow first line, retaining the explanation for repeat.
  Future<void> pause() async {
    if (_disposed) return;
    ++_revision;
    _isActive = false;
    _isPaused = _currentText != null;
    notifyListeners();
    await _voice.stop();
  }

  /// Use for leaving a task or replacing its explanation.
  Future<void> stop() async {
    if (_disposed) return;
    ++_revision;
    _currentText = null;
    _isActive = false;
    _isPaused = false;
    notifyListeners();
    await _voice.stop();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_revision;
    _currentText = null;
    _isActive = false;
    _isPaused = false;
    unawaited(_voice.stop());
    super.dispose();
  }
}
