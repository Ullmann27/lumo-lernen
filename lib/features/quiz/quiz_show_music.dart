// Eigenständige Quiz-Bühnenmusik. Verwendet vorhandene lizenzierte App-Musik.
// Kein Netzwerk, keine zusätzliche Berechtigung und keine Test-Audioausgabe.
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class QuizShowMusic {
  QuizShowMusic({required this.enabled});

  final bool enabled;
  AudioPlayer? _player;
  bool _disposed = false;

  Future<void> start() async {
    if (!enabled || _disposed) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      if (_disposed) return;
      await player.play(
        AssetSource('audio/music/energetic_loop.m4a'),
        volume: 0.12,
      );
    } catch (_) {
      // Fehler beim optionalen Ton dürfen das Quiz nicht blockieren.
    }
  }

  Future<void> pauseForLockIn() async {
    if (!enabled || _disposed) return;
    try {
      await _player?.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (!enabled || _disposed) return;
    try {
      await _player?.resume();
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!enabled || _disposed) return;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } catch (_) {}
  }
}
