import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lumos Bewegungen auf der Lernbühne (`idle`, `run`, `point`, `talk`, …).
enum LumoActorMotion {
  idle,
  run,
  point,
  talk,
  listen,
  think,
  cheer,
  comfort,
  wave;

  /// Einmalige Bewegungen enden auf ihrem letzten Feld; Schleifen laufen weiter.
  bool get isReaction =>
      this == cheer || this == comfort || this == wave || this == point;
}

/// Ein Bildstreifen aus gleich großen Feldern (Raster mit [columns] Spalten).
class LumoActorClip {
  const LumoActorClip({
    required this.image,
    required this.frames,
    required this.columns,
    required this.fps,
    required this.loop,
    this.stridePx,
  });

  final ui.Image image;
  final int frames;
  final int columns;
  final double fps;
  final bool loop;

  /// Weg je Lauf-Schleife in Feld-Pixeln (nur `run`).
  final double? stridePx;

  Duration get duration =>
      Duration(microseconds: (frames / fps * 1000000).round());

  /// Feld zum Zeitpunkt [elapsed] seit Beginn der Bewegung.
  int frameAt(Duration elapsed) {
    final index = (elapsed.inMicroseconds / 1000000 * fps).floor();
    if (loop) return index % frames;
    return index.clamp(0, frames - 1);
  }

  Rect sourceRect(int frame, Size field) {
    final f = frame.clamp(0, frames - 1);
    return Rect.fromLTWH((f % columns) * field.width,
        (f ~/ columns) * field.height, field.width, field.height);
  }
}

/// Der geladene Bildsatz nach dem Vertrag `lumo_actor.json`.
///
/// Alle Streifen schauen nach rechts; `anchor` ist der Fußpunkt im Feld und
/// in allen Feldern gleich, damit Lumo beim Wechsel der Bewegung nicht springt.
class LumoActorLibrary {
  LumoActorLibrary({
    required this.field,
    required this.anchor,
    required this.clips,
    this.shadow,
  });

  static const String assetBase = 'assets/lumo_actor';

  final Size field;
  final Offset anchor;
  final Map<LumoActorMotion, LumoActorClip> clips;
  final ui.Image? shadow;

  /// Pflichtbewegungen, ohne die die Bühne aus bleibt.
  static const required = <LumoActorMotion>{
    LumoActorMotion.idle,
    LumoActorMotion.run,
    LumoActorMotion.point,
  };

  /// Die App-weite Instanz. Null, solange kein vollständiger Satz geladen ist:
  /// dann bleibt die Bühne aus und der bisherige Lumo-Knopf bleibt sichtbar.
  static final ValueNotifier<LumoActorLibrary?> shared =
      ValueNotifier<LumoActorLibrary?>(null);
  static Future<LumoActorLibrary?>? _loading;

  /// Lädt den ausgelieferten Satz einmal beim App-Start (nicht in Tests).
  static Future<LumoActorLibrary?> preload({AssetBundle? bundle}) {
    return _loading ??= () async {
      try {
        final library = await load(bundle ?? rootBundle, basePath: assetBase);
        shared.value = library;
        return library;
      } catch (error) {
        debugPrint('lumo_actor_unavailable: $error');
        return null;
      }
    }();
  }

  @visibleForTesting
  static void debugReset() {
    _loading = null;
    shared.value = null;
  }

  /// Bewegung oder – falls sie im Satz fehlt – eine passende Ersatzbewegung.
  LumoActorClip clipFor(LumoActorMotion motion) =>
      clips[motion] ?? clips[LumoActorMotion.idle]!;

  static LumoActorLibrary parse(
      Map<String, Object?> json, Map<String, ui.Image> images) {
    if (json['version'] != 1) {
      throw const FormatException('lumo_actor.json: version 1 erwartet');
    }
    List<num> pair(String key) {
      final value = json[key];
      if (value is! List || value.length != 2) {
        throw FormatException('lumo_actor.json: $key fehlt');
      }
      return value.cast<num>();
    }

    final frame = pair('frame');
    final anchor = pair('anchor');
    final rawClips = json['clips'];
    if (rawClips is! Map) {
      throw const FormatException('lumo_actor.json: clips fehlt');
    }
    final clips = <LumoActorMotion, LumoActorClip>{};
    for (final motion in LumoActorMotion.values) {
      final raw = rawClips[motion.name];
      if (raw is! Map) continue;
      final file = raw['file'];
      final image = images[file];
      final frames = (raw['frames'] as num?)?.toInt() ?? 0;
      final columns = (raw['columns'] as num?)?.toInt() ?? frames;
      final fps = (raw['fps'] as num?)?.toDouble() ?? 12;
      if (image == null || frames <= 0 || columns <= 0 || fps <= 0) continue;
      clips[motion] = LumoActorClip(
        image: image,
        frames: frames,
        columns: columns,
        fps: fps,
        loop: raw['loop'] != false,
        stridePx: (raw['stride_px'] as num?)?.toDouble(),
      );
    }
    final missing = required.difference(clips.keys.toSet());
    if (missing.isNotEmpty) {
      throw FormatException(
          'lumo_actor.json: Pflichtbewegungen fehlen: ${missing.map((m) => m.name).join(', ')}');
    }
    if (clips[LumoActorMotion.run]!.stridePx == null) {
      throw const FormatException('lumo_actor.json: run braucht stride_px');
    }
    return LumoActorLibrary(
      field: Size(frame[0].toDouble(), frame[1].toDouble()),
      anchor: Offset(anchor[0].toDouble(), anchor[1].toDouble()),
      clips: clips,
      shadow: images['shadow.webp'],
    );
  }

  /// Liest `lumo_actor.json` und alle genannten Streifen aus [bundle].
  static Future<LumoActorLibrary> load(AssetBundle bundle,
      {required String basePath}) async {
    final json =
        jsonDecode(await bundle.loadString('$basePath/lumo_actor.json'))
            as Map<String, Object?>;
    final rawClips = json['clips'];
    final files = <String>{
      if (rawClips is Map)
        for (final clip in rawClips.values)
          if (clip is Map && clip['file'] is String) clip['file'] as String,
    };
    final images = <String, ui.Image>{};
    Future<void> decode(String file, {bool optional = false}) async {
      try {
        final data = await bundle.load('$basePath/$file');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        images[file] = (await codec.getNextFrame()).image;
      } catch (_) {
        if (!optional) rethrow;
      }
    }

    for (final file in files) {
      await decode(file);
    }
    await decode('shadow.webp', optional: true);
    return parse(json, images);
  }
}
