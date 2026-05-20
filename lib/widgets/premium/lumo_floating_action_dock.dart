// ════════════════════════════════════════════════════════════════════════
// LUMO FLOATING ACTION DOCK — Schwebende Aktions-Buttons
// ════════════════════════════════════════════════════════════════════════
// Heinz' Auftrag: max 3 Elemente, SafeArea, responsive, nicht ueber Navi.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../theme/lumo_breakpoints.dart';
import '../../theme/lumo_design_tokens.dart';

class LumoDockAction {
  const LumoDockAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
    this.badgeCount,
    this.isPrimary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final int? badgeCount;
  final bool isPrimary;
}

class LumoFloatingActionDock extends StatelessWidget {
  const LumoFloatingActionDock({
    super.key,
    required this.actions,
    this.alignment = Alignment.bottomRight,
    this.bottomPadding = 24,
  })  : assert(actions.length >= 1 && actions.length <= 3);

  final List<LumoDockAction> actions;
  final Alignment alignment;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isCompact = LumoBreakpoints.isCompact(context);
    final buttonSize = isCompact ? 56.0 : 64.0;
    final primarySize = isCompact ? 64.0 : 72.0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          right: LumoTokens.space16,
          left: LumoTokens.space16,
          bottom: bottomPadding,
        ),
        child: Align(
          alignment: alignment,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final a in actions.where((x) => !x.isPrimary)) ...[
                _buildAction(context, a, buttonSize),
                const SizedBox(height: LumoTokens.space12),
              ],
              for (final a in actions.where((x) => x.isPrimary))
                _buildAction(context, a, primarySize, isPrimary: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, LumoDockAction a, double size,
      {bool isPrimary = false}) {
    final gradient = a.gradient ??
        (isPrimary
            ? LumoTokens.colors.heroOrange
            : LumoTokens.colors.heroLila);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: LumoTokens.shadows.floating,
              ),
              alignment: Alignment.center,
              child: Icon(a.icon,
                  color: Colors.white, size: isPrimary ? 30 : 26),
            ),
          ),
        ),
        if (a.badgeCount != null && a.badgeCount! > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: BoxDecoration(
                color: LumoTokens.colors.errorSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${a.badgeCount}',
                style: LumoTokens.typo.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
