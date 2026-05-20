// ════════════════════════════════════════════════════════════════════════
// LUMO GLASS PANEL — Glasmorphism fuer Overlays
// ════════════════════════════════════════════════════════════════════════

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';

class LumoGlassPanel extends StatelessWidget {
  const LumoGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LumoTokens.space20),
    this.borderRadius,
    this.blur = 16,
    this.opacity = 0.85,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? LumoTokens.brLarge;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: LumoTokens.colors.surface.withOpacity(opacity),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: LumoTokens.borderThin,
            ),
            boxShadow: LumoTokens.shadows.softCard,
          ),
          child: child,
        ),
      ),
    );
  }
}
