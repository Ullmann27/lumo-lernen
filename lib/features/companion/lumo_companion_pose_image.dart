// ════════════════════════════════════════════════════════════════════════
// LUMO COMPANION POSE IMAGE — rendert eine Pose mit PNG-Fallback
// ════════════════════════════════════════════════════════════════════════
// Tier B aus dem Asset-Integrations-Plan (Heinz 2026-05-23).
//
// Verwendet die LumoCompanionPose Enum aus PR A. Zeigt das passende PNG
// aus assets/companion/. Falls das Asset zur Build-Zeit fehlen sollte
// (z.B. bei einem unvollstaendigen Repo-Stand), kommt ein Emoji-Fallback
// statt ein roter ErrorWidget-Crash.
//
// Optional ein weicher gelber Glow-Ring fuer 'cheer'/'surprised'-Posen.
//
// Performance: cacheWidth + cacheHeight basierend auf Anzeige-Groesse,
// keine pro-Frame-Animation. Sauber als const-Widget verwendbar.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../core/lumo_companion_pose.dart';

class LumoCompanionPoseImage extends StatelessWidget {
  const LumoCompanionPoseImage({
    super.key,
    required this.pose,
    this.size = 96.0,
    this.showGlow = false,
    this.semanticLabel,
  });

  final LumoCompanionPose pose;
  final double size;

  /// Wenn true: weicher gelber Strahlenkranz aussen rum (fuer Sieg,
  /// Belohnung, Lob).
  final bool showGlow;

  /// Optional eigener Accessibility-Label. Default = pose.semanticLabel.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cw = (size * 3).round();
    final ch = (size * 3).round();
    final label = semanticLabel ?? pose.semanticLabel;
    final image = Image.asset(
      pose.pngPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: cw,
      cacheHeight: ch,
      semanticLabel: label,
      errorBuilder: (_, __, ___) => _emojiFallback(),
    );
    if (!showGlow) return SizedBox(width: size, height: size, child: image);

    // Glow-Variante: weicher Strahlenkranz, statisch (kein Pulse, kein
    // Controller - bleibt verlustfrei bei vielen Instanzen gleichzeitig).
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC83D).withOpacity(0.45),
              blurRadius: 28,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: const Color(0xFFFF7A2F).withOpacity(0.30),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: image,
      ),
    );
  }

  Widget _emojiFallback() {
    // Maskottchen-Fallback wenn das Asset zur Laufzeit fehlt.
    return Center(
      child: Text(
        '🦊',
        style: TextStyle(fontSize: size * 0.7, height: 1.0),
      ),
    );
  }
}
