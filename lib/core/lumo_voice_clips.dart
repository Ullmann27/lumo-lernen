import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pre-produced German Lumo speech. Runtime is entirely offline; no child's
/// text is submitted to the generation service.
///
/// Der bestehende Sulafat-Katalog ist die Offline-Quelle. Variable Texte
/// dürfen ausschließlich über den freigegebenen Sulafat-Server gesprochen
/// werden, niemals durch eine Geräte-Ersatzstimme.
class LumoVoiceClips {
  LumoVoiceClips._();

  static const String catalogAsset = 'assets/audio/voice/lumo/catalog.json';

  static Map<String, LumoVoiceClip>? _clips;
  static Map<String, String> _aliases = const {};
  static Future<void>? _loading;

  /// Gleiche Normalisierung wie `normalize_key` im Generator.
  static String keyFor(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .join(' ');

  static Future<void> ensureLoaded([AssetBundle? bundle]) =>
      _loading ??= _load(bundle ?? rootBundle);

  static Future<void> _load(AssetBundle bundle) async {
    try {
      final raw = await bundle.loadString(catalogAsset);
      _clips = parseCatalog(raw);
      final catalog = jsonDecode(raw) as Map<String, dynamic>;
      final aliases = catalog['aliases'] as Map<String, dynamic>? ?? const {};
      _aliases = aliases.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      _clips = const {};
      if (kDebugMode) debugPrint('[LumoVoiceClips] kein Katalog: $e');
    }
  }

  @visibleForTesting
  static Map<String, LumoVoiceClip> parseCatalog(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final fps = (json['fps'] as num?)?.toInt() ?? 20;
    final clips = json['clips'] as Map<String, dynamic>;
    return {
      for (final e in clips.entries)
        e.key: LumoVoiceClip(
          id: e.value['id'] as String,
          text: e.value['text'] as String,
          duration: Duration(milliseconds: (e.value['ms'] as num).toInt()),
          envelope: (e.value['env'] as String)
              .codeUnits
              .map((c) => (c - 48).clamp(0, 9) / 9)
              .toList(growable: false),
          fps: fps,
        ),
    };
  }

  @visibleForTesting
  static void debugSetCatalog(Map<String, LumoVoiceClip>? clips) {
    _clips = clips;
    _aliases = const {};
    _loading = clips == null ? null : Future<void>.value();
  }

  /// Clip für genau diesen Text, falls vorhanden und geladen.
  static LumoVoiceClip? lookup(String text) {
    final key = keyFor(text);
    return _clips?[key] ?? _clips?[_aliases[key]];
  }

  static int get count => _clips?.length ?? 0;
}

class LumoVoiceClip {
  const LumoVoiceClip({
    required this.id,
    required this.text,
    required this.duration,
    required this.envelope,
    required this.fps,
  });

  final String id;
  final String text;
  final Duration duration;

  /// Lautstärke 0–1 je 1/[fps] Sekunde, steuert Lumos Mund.
  final List<double> envelope;
  final int fps;

  /// Pfad relativ zu `assets/` (audioplayers AssetSource).
  String get assetSource => 'audio/voice/lumo/$id.m4a';

  double mouthAt(Duration position) {
    if (envelope.isEmpty) return 0;
    final i = (position.inMilliseconds * fps / 1000).floor();
    if (i < 0 || i >= envelope.length) return 0;
    return envelope[i];
  }
}
