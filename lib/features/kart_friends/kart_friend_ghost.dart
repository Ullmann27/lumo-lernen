import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// „Lumo-Geist“: die beste Kart-Fahrt eines Freundes als kleine Datei.
///
/// Die App prüft hier nur Kopf, Größe und Prüfsumme, damit Kind und Eltern sofort
/// sehen, von wem der Geist ist und auf welcher Strecke. Die vollständige Prüfung
/// der Fahrlinie macht das Spiel selbst (`kart_ghost_codec.gd` in Godot) – erst
/// danach fährt der Geist. Fremde Dateien werden nur abgelehnt, nie gespeichert.
class KartFriendGhost {
  const KartFriendGhost._({
    required this.name,
    required this.track,
    required this.timeMs,
    required this.driver,
    required this.kart,
    required this.bytes,
  });

  static const int maxFileBytes = 65536;
  static const int format = 1;
  static const String textPrefix = 'LUMOGEIST1:';
  static final RegExp _id = RegExp(r'^[a-z0-9_]{1,40}$');
  static final RegExp _version = RegExp(r'^[a-z0-9_:.-]{1,48}$');
  static final RegExp _name =
      RegExp(r"^[\p{L}\p{M} '\-]{1,16}$", unicode: true);

  final String name;
  final String track;
  final int timeMs;
  final String driver;
  final String kart;
  final Uint8List bytes;

  /// Für Freundesgeister verfügbare Strecken (Kennung wie im Spiel: kart_catalog.gd,
  /// kart_expansion_tracks.gd). Unbekannte Kennungen lehnt das Spiel ab.
  static const Map<String, String> trackNames = {
    'sonnenhafen': 'Sonnenhafen',
    'zauberwald': 'Zauberwald',
    'bergwelt': 'Himmelsinseln',
    'holo_city': 'Holo City',
    'crystal_canyon': 'Kristall-Canyon',
    'jungle_temple': 'Dschungel-Tempel',
    'candy_cloud': 'Candy Cloud Circuit',
    'volcano_night': 'Volcano Night Run',
    'winter_sprint': 'Winter-Sprint',
    'galaxy_ringway': 'Galaxy Ringway',
    'desert_drift': 'Desert Dune Drift',
    'learning_lab': 'Funkel-Labor',
    'jungle_emerald_3600': 'Dschungelherz',
    'windwerk_3000': 'Lumos Windwerk',
  };

  String get trackName => trackNames[track] ?? 'eine Kart-Strecke';

  /// „1:23,4“
  String get timeText {
    final minutes = timeMs ~/ 60000;
    final tenths = ((timeMs % 60000) / 100).round();
    final seconds = tenths ~/ 10;
    return '$minutes:${seconds.toString().padLeft(2, '0')},${tenths % 10}';
  }

  /// Textform für die Startoption `kartFriendGhost` (Base64url ohne `=`).
  String get launchText =>
      textPrefix + base64Url.encode(bytes).replaceAll('=', '');

  /// Liest Datei-Bytes. Wirft nie: liefert entweder einen Geist oder eine Meldung.
  static KartFriendGhostResult read(Uint8List? data) {
    if (data == null || data.isEmpty) {
      return const KartFriendGhostResult.error('Die Datei ist leer.');
    }
    if (data.length > maxFileBytes) {
      return const KartFriendGhostResult.error(
          'Diese Datei ist zu groß für einen Lumo-Geist.');
    }
    if (data.length < 4 ||
        data[0] != 0x4C ||
        data[1] != 0x47 ||
        data[2] != 0x53 ||
        data[3] != 0x54) {
      return const KartFriendGhostResult.error('Das ist kein Lumo-Geist.');
    }
    const damaged = KartFriendGhostResult.error(
        'Der Geist ist beschädigt angekommen. Bitte lass ihn dir noch einmal schicken.');
    if (data.length < 4 + 1 + 6 + 4 + 2 + 2 + 12 + 4 + 8) return damaged;
    if (data[4] > format) {
      return const KartFriendGhostResult.error(
          'Dieser Geist kommt aus einer neueren Lumo-Version. Bitte Lumo aktualisieren.');
    }
    if (data[4] != format) return damaged;
    final body = Uint8List.sublistView(data, 0, data.length - 8);
    final digest = sha256.convert(body).bytes;
    for (var i = 0; i < 8; i++) {
      if (digest[i] != data[data.length - 8 + i]) return damaged;
    }
    var at = 5;
    final texts = <String>[];
    for (var i = 0; i < 6; i++) {
      if (at >= body.length) return damaged;
      final size = body[at];
      if (size == 0 || size > 64 || at + 1 + size > body.length) return damaged;
      try {
        texts.add(utf8.decode(body.sublist(at + 1, at + 1 + size)));
      } on FormatException {
        return damaged;
      }
      at += 1 + size;
    }
    for (var i = 0; i < 5; i++) {
      if (!(i == 1 ? _version : _id).hasMatch(texts[i])) return damaged;
    }
    if (!_name.hasMatch(texts[5]) || texts[5].trim() != texts[5]) {
      return damaged;
    }
    if (at + 24 > body.length) return damaged;
    final view = ByteData.sublistView(body);
    final timeMs = view.getUint32(at, Endian.little);
    final count = view.getUint16(at + 4, Endian.little);
    final packed = view.getUint32(at + 20, Endian.little);
    if (timeMs < 5000 || timeMs > 1200000 || count < 2 || count > 15000) {
      return damaged;
    }
    if (packed == 0 || at + 24 + packed != body.length) return damaged;
    return KartFriendGhostResult.ok(KartFriendGhost._(
      name: texts[5],
      track: texts[0],
      timeMs: timeMs,
      driver: texts[2],
      kart: texts[3],
      bytes: Uint8List.fromList(data),
    ));
  }

  /// Die Startoption darf nur diese Form haben (gleiche Regel im Android-Host).
  static bool isLaunchText(String text) =>
      text.length <= textPrefix.length + 87382 &&
      RegExp(r'^LUMOGEIST1:[A-Za-z0-9_-]{40,}$').hasMatch(text);
}

class KartFriendGhostResult {
  const KartFriendGhostResult.ok(KartFriendGhost this.ghost) : message = null;
  const KartFriendGhostResult.error(String this.message) : ghost = null;

  final KartFriendGhost? ghost;
  final String? message;
}
