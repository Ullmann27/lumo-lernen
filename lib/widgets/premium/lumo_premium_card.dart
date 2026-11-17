// ════════════════════════════════════════════════════════════════════════
// LUMO PREMIUM CARD — Standard-Karte fuer hochwertige UI
// ════════════════════════════════════════════════════════════════════════
// Verwendung:
//   LumoPremiumCard(
//     onTap: ...,
//     child: ...,
//   )
//
// Mit Tap-Animation (weiches Eindruecken).
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';
import '../design/lumo_glass_optics.dart';
import '../design/lumo_motion.dart';

class LumoPremiumCard extends StatelessWidget {
  const LumoPremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(LumoTokens.space20),
    this.gradient,
    this.color,
    this.borderColor,
    this.elevated = true,
    this.glow,
    this.radius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final bool elevated;
  final Color? glow;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final shape = radius ?? LumoTokens.brLarge;
    final accent = glow ?? borderColor ?? const Color(0xFF52E5FF);
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? LumoTokens.colors.surface) : null,
      gradient: gradient,
      borderRadius: shape,
      boxShadow: elevated
          ? (glow != null
              ? LumoTokens.shadows.glow(glow!)
              : LumoTokens.shadows.softCard)
          : const [],
      border: borderColor == null
          ? null
          : Border.all(color: borderColor!, width: LumoTokens.borderRegular),
    );
    final content = CustomPaint(
      foregroundPainter:
          LumoGlassOptics(radius: shape.topLeft.x, accent: accent),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    // InkWell provides focus, keyboard activation and button semantics.
    // The shared press response respects app and platform reduced motion.
    return Semantics(
      button: true,
      child: LumoPressable(
        radius: shape.topLeft.x,
        glowColor: accent,
        pressedScale: .975,
        child: DecoratedBox(
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            borderRadius: shape,
            child: InkWell(
              onTap: onTap,
              splashFactory: InkRipple.splashFactory,
              borderRadius: shape,
              focusColor: accent.withValues(alpha: .18),
              highlightColor: accent.withValues(alpha: .12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
