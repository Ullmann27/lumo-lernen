// ════════════════════════════════════════════════════════════════════════
// LUMO LOTTIE — Wrapper-Widget mit PNG-Fallback
// ════════════════════════════════════════════════════════════════════════
// Tier D aus dem Asset-Integrations-Plan (Heinz 2026-05-23).
//
// Rendert ein Lottie-Asset, mit:
//  - try/catch um den Loader (kaputtes JSON -> Fallback statt Crash)
//  - optionalem PNG-Pfad als Fallback wenn Lottie nicht laedt
//  - delegate auf das offizielle lottie-Package (MIT, open source)
//
// Verwendung:
//   const LumoLottie(asset: LumoAssetPaths.lottieLoading, size: 96)
//
// Falls das lottie-Package zur Build-Zeit unverfuegbar ist (z.B. wenn
// pubspec noch nicht aktualisiert wurde), gibt es einen einzigen
// zentralen Punkt der angepasst werden muss.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LumoLottie extends StatelessWidget {
  const LumoLottie({
    super.key,
    required this.asset,
    this.size = 96,
    this.repeat = true,
    this.fallbackPngAsset,
  });

  /// Lottie-JSON-Pfad (z.B. LumoAssetPaths.lottieLoading)
  final String asset;

  /// Quadratische Anzeige-Groesse in Logical Pixels.
  final double size;

  /// Bei Loop-Animationen (Spinner, Idle, Sad/Think) true belassen.
  /// Fuer einmalige Animationen (Star-Burst, Cheer) auf false setzen.
  final bool repeat;

  /// Optional: PNG-Pfad als Fallback wenn Lottie crasht / nicht laedt.
  /// Z.B. fuer LumoCompanionPose-Lottie kann hier der pose.pngPath
  /// uebergeben werden.
  final String? fallbackPngAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        asset,
        repeat: repeat,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          // Kaputtes JSON / fehlendes Asset -> PNG-Fallback wenn vorhanden,
          // sonst stille Box. Kein Crash.
          final fallback = fallbackPngAsset;
          if (fallback != null) {
            return Image.asset(
              fallback,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
