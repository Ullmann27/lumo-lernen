// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS — Asset-Mapping
// ════════════════════════════════════════════════════════════════════════
// Zentrale Stelle fuer alle Lumo-Cards Asset-Pfade. Heinz' Wunsch:
// 'Keine Assetpfade wild direkt in Widgets verteilen.'
//
// Verhalten:
//  - Wenn echte PNG-Dateien unter assets/lumo_cards/... vorhanden sind,
//    werden ihre Pfade hier gebaut und koennen via Image.asset(...)
//    geladen werden.
//  - Wenn KEINE PNGs vorhanden sind (aktueller Zustand), liefert die
//    Klasse trotzdem deterministische Pfade. Widgets sollten dann
//    `Image.asset(..., errorBuilder: ...)` benutzen oder via
//    `LumoCardsAssets.hasCardAssets` pruefen.
//
// pubspec.yaml ist bereits so erweitert dass die geplanten Ordner
// gescannt werden - leere Ordner schaden nicht.
// ════════════════════════════════════════════════════════════════════════

import 'lumo_cards_models.dart';

class LumoCardsAssets {
  LumoCardsAssets._();

  // ── Basis-Pfad ──
  static const String _root = 'assets/lumo_cards';

  // ── UI-Assets ──
  static const String logo = '$_root/ui/lumo_cards_logo.png';

  // ── Karten-Rueckseite ──
  static const String cardBack = '$_root/cards/back/card_back_default.png';

  /// Asset-Schluessel pro Farbe.
  /// Achtung: die enum-Namen sind aus historischen Gruenden noch
  /// 'orange/purple/blue/green', der visuelle Look (Mockup-Edition)
  /// faerbt sie auf Rot/Gelb/Blau/Gruen. Dateinamen folgen dem Mockup-
  /// Look, damit Heinz' PNG-Files (red_0, yellow_3, ...) sauber gemappt
  /// werden koennen.
  static String _colorFolder(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return 'red';
      case LumoCardColor.purple:
        return 'yellow';
      case LumoCardColor.blue:
        return 'blue';
      case LumoCardColor.green:
        return 'green';
    }
  }

  /// Pfad zur Zahlenkarte. Beispiel: red_0.png, yellow_7.png.
  static String numberCard({
    required LumoCardColor color,
    required int number,
  }) {
    final folder = _colorFolder(color);
    return '$_root/cards/$folder/${folder}_$number.png';
  }

  /// Pfad zur farbigen Spezialkarte (Skip / Reverse / Draw 2).
  static String? specialCard({
    required LumoCardColor color,
    required LumoCardType type,
  }) {
    final folder = _colorFolder(color);
    switch (type) {
      case LumoCardType.lumoJump:
        return '$_root/cards/$folder/${folder}_skip.png';
      case LumoCardType.starRain:
        return '$_root/cards/$folder/${folder}_draw_two.png';
      case LumoCardType.whirlwind:
        return '$_root/cards/$folder/${folder}_reverse.png';
      case LumoCardType.thinkPause:
        return '$_root/cards/$folder/${folder}_think_pause.png';
      case LumoCardType.colorMagic:
      case LumoCardType.superRain:
      case LumoCardType.number:
        return null;
    }
  }

  // ── Wild-Karten (farb-unabhaengig, schwarz) ──
  static const String wildColor = '$_root/cards/special/color_magic.png';
  static const String wildDrawFour = '$_root/cards/special/wild_draw_four.png';

  // ── Effekt-Layer ──
  static const String glowGreen = '$_root/fx/glow_green.png';
  static const String glowYellow = '$_root/fx/glow_yellow.png';
  static const String glowRing = '$_root/fx/glow_ring.png';
  static const String sparkle = '$_root/fx/sparkle.png';
  static const String impactBurst = '$_root/fx/impact_burst.png';
  static const String confetti = '$_root/fx/confetti.png';

  // ── Spieler-Avatare (Platzhalter, Heinz kann eigene einlegen) ──
  static const String avatarLumo = '$_root/avatars/lumo.png';
  static const String avatarPlayer = '$_root/avatars/player.png';

  // ── Tisch-Hintergrund (optional) ──
  static const String tableBackdrop = '$_root/table/table_backdrop.png';
  static const String tableArenaGlow = '$_root/table/arena_glow.png';

  /// Gibt den Pfad zur passenden Asset-Datei fuer eine LumoCard.
  /// Liefert null fuer Karten ohne dediziertes Bild (z.B. Wild auf
  /// nicht-Wild-Routing).
  static String? assetFor(LumoCard card) {
    if (card.type == LumoCardType.number) {
      if (card.number == null) return null;
      return numberCard(color: card.color, number: card.number!);
    }
    if (card.type == LumoCardType.colorMagic) return wildColor;
    if (card.type == LumoCardType.superRain) return wildDrawFour;
    return specialCard(color: card.color, type: card.type);
  }
}
