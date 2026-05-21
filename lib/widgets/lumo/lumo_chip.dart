// ════════════════════════════════════════════════════════════════════════
// LUMO CHIP — Wiederverwendbare Pill / Tag / Badge
// ════════════════════════════════════════════════════════════════════════
//
// Vorher: ueberall ad-hoc Container mit BorderRadius.circular(99). Resultat:
// jedes File hatte andere Padding/Schriftgroessen/Borderwidths.
//
// Jetzt: ein einziger Chip-Widget mit klaren Varianten - direkt aus dem
// Figma-Komponenten-Set abgeleitet.
//
// Varianten (siehe Figma "🧩 02 — Components"):
//   LumoChip.primary('PRO')           → Goldgelb fuer Premium
//   LumoChip.brand('Willkommen 👋')   → Orange-getoent mit Border
//   LumoChip.success('NEU')           → Gruen fuer neue Features
//   LumoChip.muted('Übung')           → Soft-Lila fuer Modi
//   LumoChip.streak('7 Tage', '🔥')   → Goldgelb mit Glow fuer Streaks
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import 'lumo_design_kit.dart';

enum LumoChipVariant { primary, brand, success, muted, streak, ghost }

class LumoChip extends StatelessWidget {
  const LumoChip({
    super.key,
    required this.label,
    this.icon,
    this.variant = LumoChipVariant.brand,
    this.onTap,
  });

  /// Primary (Goldgelb + dunkler Text) - fuer PRO-Badges.
  const LumoChip.primary({super.key, required this.label, this.icon, this.onTap})
      : variant = LumoChipVariant.primary;

  /// Brand (Orange-Tint + Orange Border) - fuer freundliche Begruessungen.
  const LumoChip.brand({super.key, required this.label, this.icon, this.onTap})
      : variant = LumoChipVariant.brand;

  /// Success (Gruen + weisser Text) - fuer "NEU" oder Erfolgs-Marker.
  const LumoChip.success({super.key, required this.label, this.icon, this.onTap})
      : variant = LumoChipVariant.success;

  /// Muted (Soft-Lila + Lila Text) - fuer Modus-Anzeigen ("Übung", "Test").
  const LumoChip.muted({super.key, required this.label, this.icon, this.onTap})
      : variant = LumoChipVariant.muted;

  /// Streak (Goldgelb + Glow) - fuer Streak-Anzeigen mit Emoji.
  const LumoChip.streak({super.key, required this.label, this.icon, this.onTap})
      : variant = LumoChipVariant.streak;

  /// Ghost (transparenter Hintergrund mit Border) - dezent.
  const LumoChip.ghost({super.key, required this.label, this.icon, this.onTap})
      : variant = LumoChipVariant.ghost;

  final String label;
  final String? icon;
  final LumoChipVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(variant);

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(LumoKit.radiusPill),
        border: spec.border == null
            ? null
            : Border.all(color: spec.border!, width: 1.4),
        boxShadow: spec.glow == null
            ? null
            : [
                BoxShadow(
                  color: spec.glow!.withOpacity(0.45),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: spec.fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumoKit.radiusPill),
      child: content,
    );
  }

  static _ChipSpec _specFor(LumoChipVariant v) {
    switch (v) {
      case LumoChipVariant.primary:
        return _ChipSpec(
          bg: const Color(0xFFFCD34D),
          fg: LumoColors.ink900,
        );
      case LumoChipVariant.brand:
        return _ChipSpec(
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFFF97316),
          border: const Color(0xFFFED7AA),
        );
      case LumoChipVariant.success:
        return _ChipSpec(
          bg: const Color(0xFF10B981),
          fg: Colors.white,
        );
      case LumoChipVariant.muted:
        return _ChipSpec(
          bg: const Color(0xFFF3E8FF),
          fg: const Color(0xFF6D28D9),
          border: const Color(0xFFC4B5FD),
        );
      case LumoChipVariant.streak:
        return _ChipSpec(
          bg: const Color(0xFFFCD34D),
          fg: LumoColors.ink900,
          glow: const Color(0xFFFCD34D),
        );
      case LumoChipVariant.ghost:
        return _ChipSpec(
          bg: Colors.transparent,
          fg: LumoColors.ink700,
          border: const Color(0x33000000),
        );
    }
  }
}

class _ChipSpec {
  const _ChipSpec({required this.bg, required this.fg, this.border, this.glow});
  final Color bg;
  final Color fg;
  final Color? border;
  final Color? glow;
}
