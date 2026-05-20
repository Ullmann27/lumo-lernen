// ════════════════════════════════════════════════════════════════════════
// LUMO STAGE HEADER — Premium Header mit Sterne/Streak/Level
// ════════════════════════════════════════════════════════════════════════
// Heinz' Auftrag: 'Begruessung oben, Level/Sterne/Streak kompakt'.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';

class LumoStageHeader extends StatelessWidget {
  const LumoStageHeader({
    super.key,
    required this.greeting,
    this.subtitle,
    this.stars,
    this.xp,
    this.streak,
    this.level,
    this.onAvatarTap,
    this.padding,
  });

  final String greeting;
  final String? subtitle;
  final int? stars;
  final int? xp;
  final int? streak;
  final int? level;
  final VoidCallback? onAvatarTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(LumoTokens.space20, LumoTokens.space16,
              LumoTokens.space20, LumoTokens.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar / Level
          if (level != null)
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LumoTokens.colors.heroOrange,
                  shape: BoxShape.circle,
                  boxShadow: LumoTokens.shadows.glow(
                      LumoTokens.colors.lumoOrange,
                      intensity: 0.6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$level',
                  style: LumoTokens.typo.headlineSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (level != null) const SizedBox(width: LumoTokens.space12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: LumoTokens.typo.headlineLarge.copyWith(
                    color: LumoTokens.colors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: LumoTokens.typo.bodyMedium.copyWith(
                      color: LumoTokens.colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Stats Chips
          if (stars != null || xp != null || streak != null)
            const SizedBox(width: LumoTokens.space8),
          if (stars != null)
            _StatChip(
              icon: Icons.star_rounded,
              color: LumoTokens.colors.gold,
              value: stars!,
            ),
          if (streak != null) ...[
            const SizedBox(width: LumoTokens.space8),
            _StatChip(
              icon: Icons.local_fire_department_rounded,
              color: LumoTokens.colors.lumoOrange,
              value: streak!,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: LumoTokens.space10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: LumoTokens.brPill,
        boxShadow: LumoTokens.shadows.subtle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: LumoTokens.typo.labelLarge.copyWith(
              color: LumoTokens.colors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
