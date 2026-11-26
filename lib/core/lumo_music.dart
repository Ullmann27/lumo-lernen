import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lumo_asset_paths.dart';
import 'lumo_voice.dart';

enum LumoMusicTrack { chillLoop, energeticLoop, victoryJingle }

/// Plays bundled music without sharing the speech player or taking its place.
class LumoMusic {
  LumoMusic._();
  static final LumoMusic instance = LumoMusic._();

  static bool get nativeMenuEnabled =>
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  static const String _mutePrefKey = 'lumo_music_muted';
  static const double _backgroundVolume = 0.12;
  static const double duckedVolume = 0.03;
  static const _assets = {
    LumoMusicTrack.chillLoop: LumoAssetPaths.musicChillLoop,
    LumoMusicTrack.energeticLoop: LumoAssetPaths.musicEnergeticLoop,
    LumoMusicTrack.victoryJingle: LumoAssetPaths.musicVictoryJingle,
  };

  Object? _menuOwner;
  bool _muted = false;
  bool _muteOverridden = false;
  bool _initialized = false;
  Future<void>? _initializing;
  Future<void>? _operation;
  int _revision = 0;

  AudioPlayer? _player;
  LumoMusicTrack? _requested;
  LumoMusicTrack? _prepared;
  LumoMusicTrack? _current;
  bool _loop = true;
  bool _preparedLoop = false;
  double _volume = 0.0;

  double get targetVolume => switch (LumoVoice.instance.status.value) {
        VoiceStatus.preparing || VoiceStatus.speaking => duckedVolume,
        _ => _backgroundVolume,
      };
  double get volume => _volume;
  bool get muted => _muted;
  LumoMusicTrack? get current => _current;

  set muted(bool value) {
    _muted = value;
    _muteOverridden = true;
    unawaited(_persistMute());
    if (_initialized) unawaited(_schedule());
  }

  Future<void> _persistMute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutePrefKey, _muted);
    } catch (_) {
      // An audio preference must not determine whether navigation works.
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    final pending = _initializing;
    if (pending != null) return pending;
    final operation = _loadMute();
    _initializing = operation;
    try {
      await operation;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _loadMute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_muteOverridden) _muted = prefs.getBool(_mutePrefKey) ?? false;
    } catch (_) {
      // Keep the current preference if storage is unavailable.
    }
    _initialized = true;
    LumoVoice.instance.status.addListener(_onVoiceChanged);
    if (_requested != null) await _schedule();
  }

  void _onVoiceChanged() {
    if (_requested != null && !_muted) {
      unawaited(_schedule());
    }
  }

  /// Only the active home shell may withdraw its request. A retired shell
  /// releasing its route must not stop a newer shell's soundtrack.
  Future<void> setMenuActive(Object owner, bool active) async {
    if (active) {
      if (identical(_menuOwner, owner)) return;
      _menuOwner = owner;
      await _request(LumoMusicTrack.chillLoop, loop: true);
    } else if (identical(_menuOwner, owner)) {
      _menuOwner = null;
      await _request(null);
    }
  }

  Future<void> play(LumoMusicTrack track, {bool loop = true}) {
    _menuOwner = null;
    return _request(track, loop: loop);
  }

  Future<void> stop() {
    _menuOwner = null;
    return _request(null);
  }

  Future<void> _request(LumoMusicTrack? track, {bool loop = true}) {
    _requested = track;
    _loop = loop;
    return _initialized ? _schedule() : init();
  }

  Future<void> _schedule() {
    final revision = ++_revision;
    final previous = _operation;
    final operation = () async {
      if (previous != null) await previous;
      if (revision != _revision) return;
      try {
        await _reconcile(revision);
      } catch (error) {
        await _releasePlayer();
        if (kDebugMode) debugPrint('LumoMusic: playback skipped ($error)');
      }
    }();
    _operation = operation;
    unawaited(operation.whenComplete(() {
      if (identical(_operation, operation)) _operation = null;
    }));
    return operation;
  }

  Future<void> _reconcile(int revision) async {
    final track = _muted ? null : _requested;
    if (track == null) {
      await _stopPlayer();
      return;
    }

    final player = _player ??= AudioPlayer(playerId: 'lumo-menu-music')
      ..positionUpdater = null;
    final loop = _loop;
    if (_prepared != track || _preparedLoop != loop) {
      await _stopPlayer();
      if (revision != _revision) return;
      await player
          .setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      if (revision != _revision) return;
      await player.setSource(AssetSource(_assets[track]!.substring(7)));
      _prepared = track;
      _preparedLoop = loop;
      if (revision != _revision) return;
    }

    if (_current != track) {
      // Start muted. If navigation or a lifecycle event retires this request
      // while native resume is in flight, that playback never becomes audible.
      await player.setVolume(0.0);
      if (revision != _revision) return;
      await player.resume();
      _current = track;
      if (revision != _revision) return;
    }
    final nextVolume = targetVolume;
    await player.setVolume(nextVolume);
    _volume = nextVolume;
  }

  Future<void> _stopPlayer() async {
    final player = _player;
    if (player == null || _current == null) return;
    await player.setVolume(0.0);
    _volume = 0.0;
    await player.stop();
    _current = null;
    if (!_preparedLoop) _prepared = null;
  }

  Future<void> _releasePlayer() async {
    final player = _player;
    _player = null;
    _prepared = null;
    _current = null;
    _volume = 0.0;
    try {
      await player?.dispose();
    } catch (_) {
      // The caller can continue with a freshly created player on re-entry.
    }
  }

  Future<void> dispose() async {
    await _initializing;
    if (_initialized) {
      LumoVoice.instance.status.removeListener(_onVoiceChanged);
      await stop();
    }
    await _releasePlayer();
    _initialized = false;
    _muteOverridden = false;
  }
}
