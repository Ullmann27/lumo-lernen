// ════════════════════════════════════════════════════════════════════════
// LUMO SOUND — Sound-Effect Manager
// ════════════════════════════════════════════════════════════════════════
// Tier 3 aus dem approvten Plan (Heinz 2026-05-23).
//
// Generisches SFX-System fuer das Lumo-Cards-Spiel und beliebige andere
// Module. Singleton-Pattern, eigener AudioPlayer pro SoundEffect (Pool)
// fuer niedrige Latenz, robust gegen fehlende Dateien.
//
// Verwendung:
//
//   await LumoSound.instance.init();   // einmal beim App-Start
//   LumoSound.instance.play(SoundEffect.cardPlay);
//   LumoSound.instance.muted = true;   // SFX stumm
//
// Sound-Dateien liegen unter assets/audio/sfx/. Wenn eine Datei fehlt
// passiert nichts (silent fallback) - das Spiel laeuft also auch ohne
// SFX-Files weiter, die spaeter eingespielt werden koennen.
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Alle verfuegbaren Sound-Effekte. Asset-Pfade in [LumoSound._assetPath].
enum SoundEffect {
  cardPlay,
  cardDraw,
  plus2,
  plus4,
  win,
  lose,
  click,
  error,
}

class LumoSound {
  LumoSound._();
  static final LumoSound instance = LumoSound._();

  static const String _mutePrefKey = 'lumo_sfx_muted';

  /// Asset-Pfade ohne 'assets/' Praefix - audioplayers nimmt den Pfad
  /// relativ zum assets/-Root.
  static const Map<SoundEffect, String> _assetPath = {
    SoundEffect.cardPlay: 'audio/sfx/card_whoosh.m4a',
    SoundEffect.cardDraw: 'audio/sfx/card_draw.m4a',
    SoundEffect.plus2: 'audio/sfx/plus2_storm.m4a',
    SoundEffect.plus4: 'audio/sfx/plus4_thunder.m4a',
    SoundEffect.win: 'audio/sfx/win_fanfare.m4a',
    SoundEffect.lose: 'audio/sfx/lose_buzz.m4a',
    SoundEffect.click: 'audio/sfx/click.m4a',
    SoundEffect.error: 'audio/sfx/error.m4a',
  };

  /// Set von Sounds die schon als 'fehlt' markiert wurden - so spammen
  /// wir bei jedem Spielzug nicht erneut einen Audio-Decode-Fehler.
  final Set<SoundEffect> _missing = <SoundEffect>{};

  /// AudioPlayer-Pool: ein Player pro SoundEffect erlaubt paralleles
  /// Abspielen verschiedener Sounds (Card-Play + Plus-2 gleichzeitig).
  final Map<SoundEffect, AudioPlayer> _pool = <SoundEffect, AudioPlayer>{};

  bool _muted = false;
  bool _initialized = false;

  /// SFX stumm an/aus. Persistiert in SharedPreferences.
  bool get muted => _muted;
  set muted(bool value) {
    _muted = value;
    _persistMute();
  }

  Future<void> _persistMute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutePrefKey, _muted);
    } catch (_) {
      // Persistenz scheitern darf das Spiel nicht stoeren.
    }
  }

  /// Laedt persistierten Mute-Status. Idempotent - nach init() macht ein
  /// weiterer Aufruf nichts.
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

  /// Spielt einen Sound-Effekt ab. Idempotent + robust gegen fehlende
  /// Dateien (kein Crash, kein Log-Spam bei wiederholtem Fehlen).
  Future<void> play(SoundEffect effect) async {
    if (_muted) return;
    if (_missing.contains(effect)) return;
    final path = _assetPath[effect];
    if (path == null) return;
    try {
      var player = _pool[effect];
      if (player == null) {
        player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _pool[effect] = player;
      }
      // Wenn der Sound noch laeuft: stoppen, dann neu starten (z.B. bei
      // schneller Karten-Folge spielt jeder Tap den neuen Sound sofort).
      await player.stop();
      await player.play(AssetSource(path));
    } catch (e) {
      // Fehlt das Asset oder schlaegt der Decoder fehl: einmal merken,
      // dann beim naechsten Mal sofort skippen.
      _missing.add(effect);
      if (kDebugMode) {
        debugPrint('LumoSound: $effect skipped ($e)');
      }
    }
  }

  /// Alle Player schliessen (z.B. wenn die App in den Hintergrund geht
  /// oder beim App-Shutdown). Wird zur Zeit nicht aktiv aufgerufen, weil
  /// Singleton bis App-Tod lebt - aber bleibt verfuegbar fuer Tests.
  Future<void> dispose() async {
    for (final p in _pool.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _pool.clear();
    _missing.clear();
    _initialized = false;
  }
}
