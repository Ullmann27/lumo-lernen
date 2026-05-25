// ════════════════════════════════════════════════════════════════════════
// LUMO MUSIC — Background-Music-Manager
// ════════════════════════════════════════════════════════════════════════
// PR H3 (Heinz 2026-05-23). Geschwister-Klasse zu LumoSound (PR #94),
// aber dedizierter Player fuer Hintergrund-Loops + Sieg-Jingle. Nutzt
// die schon vorhandene audioplayers-Dependency.
//
// Architektur:
//   - Singleton mit play(track) / stop() / muted-Toggle
//   - Ein einziger AudioPlayer (sequenzielles Wechseln zwischen Tracks)
//   - Lautstaerke fix auf 0.55 (Background, nicht aufdringlich)
//   - try/catch um jeden Audio-Aufruf - fehlende Datei -> stiller Mute
//   - Persistiert mute-Status in SharedPreferences ('lumo_music_muted')
//
// Verwendung:
//   await LumoMusic.instance.init();              // einmal in main()
//   LumoMusic.instance.play(LumoMusicTrack.chillLoop);
//   LumoMusic.instance.stop();
//   LumoMusic.instance.muted = true;
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lumo_asset_paths.dart';

/// Verfuegbare Background-Tracks.
enum LumoMusicTrack {
  /// Ruhige Schleife - Hauptmenue / Lumo Cards.
  chillLoop,

  /// Lebhafte Schleife - Action-Spiele.
  energeticLoop,

  /// Kurzer Sieg-Jingle (kein Loop).
  victoryJingle,
}

class LumoMusic {
  LumoMusic._();
  static final LumoMusic instance = LumoMusic._();

  static const String _mutePrefKey = 'lumo_music_muted';
  static const double _bgVolume = 0.55;

  static String _strip(String fullPath) =>
      fullPath.startsWith('assets/') ? fullPath.substring(7) : fullPath;

  /// Asset-Pfade ohne 'assets/' (audioplayers AssetSource erwartet das).
  static final Map<LumoMusicTrack, String> _assetPath = {
    LumoMusicTrack.chillLoop: _strip(LumoAssetPaths.musicChillLoop),
    LumoMusicTrack.energeticLoop: _strip(LumoAssetPaths.musicEnergeticLoop),
    LumoMusicTrack.victoryJingle: _strip(LumoAssetPaths.musicVictoryJingle),
  };

  AudioPlayer? _player;
  LumoMusicTrack? _current;
  bool _muted = false;
  bool _initialized = false;
  final Set<LumoMusicTrack> _missing = <LumoMusicTrack>{};

  /// Mute-Toggle. Bei true wird laufendes Audio sofort gestoppt.
  bool get muted => _muted;
  set muted(bool value) {
    _muted = value;
    if (value) stop();
    unawaited(_persistMute());
  }

  /// Aktuell laufender Track (oder null wenn nichts spielt).
  LumoMusicTrack? get current => _current;

  Future<void> _persistMute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutePrefKey, _muted);
    } catch (_) {
      // Persistenz scheitern darf die App nicht stoeren.
    }
  }

  /// Laedt persistierten Mute-Status. Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_mutePrefKey) ?? false;
    } catch (_) {
      _muted = false;
    }
  }

  /// Spielt einen Track ab. Bei loop=true wiederholt audioplayers
  /// nahtlos. Wenn schon der gleiche Track laeuft -> no-op.
  Future<void> play(LumoMusicTrack track, {bool loop = true}) async {
    if (_muted) return;
    if (_missing.contains(track)) return;
    if (_current == track && _player != null) return;
    final path = _assetPath[track];
    if (path == null) return;
    try {
      _player ??= AudioPlayer();
      await _player!.setReleaseMode(
          loop ? ReleaseMode.loop : ReleaseMode.release);
      await _player!.setVolume(_bgVolume);
      await _player!.play(AssetSource(path));
      _current = track;
    } catch (e) {
      _missing.add(track);
      if (kDebugMode) {
        debugPrint('LumoMusic: $track skipped ($e)');
      }
    }
  }

  /// Stoppt das aktuelle Audio (falls etwas laeuft).
  Future<void> stop() async {
    final p = _player;
    if (p == null) return;
    try {
      await p.stop();
    } catch (_) {}
    _current = null;
  }

  /// Schliesst den Player vollstaendig. Wird nicht regulaer aufgerufen,
  /// bleibt fuer Tests / App-Shutdown verfuegbar.
  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _missing.clear();
    _initialized = false;
  }
}
