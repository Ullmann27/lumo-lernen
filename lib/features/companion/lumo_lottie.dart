// ════════════════════════════════════════════════════════════════════════
// LUMO LOTTIE — Wrapper-Widget (PNG-Fallback-Modus, Build 199+)
// ════════════════════════════════════════════════════════════════════════
// CI-Rescue 2026-05-25: das lottie-Package wurde voruebergehend aus
// pubspec.yaml entfernt, weil es den Android-Native-Build seit 13 Commits
// rot gemacht hat (Build 199-212 alle ROT). Heinz braucht zuerst eine
// installierbare APK mit allen Funktionen.
//
// Das Widget bleibt API-kompatibel:
//   - Alle Aufrufstellen funktionieren weiter
//   - Wenn ein fallbackPngAsset gesetzt ist, wird das PNG angezeigt
//   - Sonst eine stille SizedBox in der angegebenen Groesse
//
// Sobald das lottie-Package wieder mit dem aktuellen Flutter-Stack
// kompatibel ist, kann diese Datei zurueck auf Lottie.asset(...) gedreht
// werden. Bis dahin: PNG-Fallback genuegt fuer den Loading-Spinner +
// die 6 Companion-Lottie-Animationen (Heinz hat fuer alle Posen auch
// statische PNGs geliefert).
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoLottie extends StatelessWidget {
  const LumoLottie({
    super.key,
    required this.asset,
    this.size = 96,
    this.repeat = true,
    this.fallbackPngAsset,
  });

  /// Bleibt aus API-Gruenden im Konstruktor, wird im PNG-Fallback-Modus
  /// aber nicht geladen.
  final String asset;

  final double size;

  /// Wird im PNG-Modus ignoriert (PNG ist statisch).
  final bool repeat;

  /// PNG-Pfad als Fallback. Wenn null: stille Box in 'size' x 'size'.
  final String? fallbackPngAsset;

  @override
  Widget build(BuildContext context) {
    final fallback = fallbackPngAsset;
    if (fallback == null) {
      return SizedBox(width: size, height: size);
    }
    return Image.asset(
      fallback,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
  }
}
