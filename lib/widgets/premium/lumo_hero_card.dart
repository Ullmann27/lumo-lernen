// ════════════════════════════════════════════════════════════════════════
// LUMO HERO CARD — Grosse Premium-Karten fuer Spielewelt/Tageskarte
// ════════════════════════════════════════════════════════════════════════
// Verwendung: Lumo Jump, Lumo Kart, "Heute starten" auf Home.
// Mit Hero-Schatten, optional Image/Icon, Tap-Animation.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';
import 'lumo_premium_card.dart';

class LumoHeroCard extends StatelessWidget {
  const LumoHeroCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconWidget,
    this.gradient,
    this.glowColor,
    this.onTap,
    this.badge,
    this.height,
    this.fullWidth = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? iconWidget;
  final Gradient? gradient;
  final Color? glowColor;
  final VoidCallback? onTap;
  final String? badge;
  final double? height;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? LumoTokens.colors.heroOrange;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: LumoPremiumCard(
        onTap: onTap,
        gradient: g,
        padding: const EdgeInsets.all(LumoTokens.space24),
        glow: glowColor,
        radius: LumoTokens.brXLarge,
        child: Stack(
          children: [
            // Decorative blob (sub Visual interest)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Badge top-right
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LumoTokens.space12,
                      vertical: LumoTokens.space4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: LumoTokens.brPill,
                  ),
                  child: Text(
                    badge!,
                    style: LumoTokens.typo.labelSmall.copyWith(
                      color: LumoTokens.colors.textDark,
                    ),
                  ),
                ),
              ),
            // Content
            Row(
              children: [
                if (iconWidget != null)
                  iconWidget!
                else if (icon != null)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: LumoTokens.brLarge,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 40, color: Colors.white),
                  ),
                if (icon != null || iconWidget != null)
                  const SizedBox(width: LumoTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: LumoTokens.typo.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: LumoTokens.space4),
                        Text(
                          subtitle!,
                          style: LumoTokens.typo.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: LumoTokens.space8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
