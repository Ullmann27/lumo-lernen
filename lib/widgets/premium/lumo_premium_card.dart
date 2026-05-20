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

class LumoPremiumCard extends StatefulWidget {
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
  State<LumoPremiumCard> createState() => _LumoPremiumCardState();
}

class _LumoPremiumCardState extends State<LumoPremiumCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadows = widget.elevated
        ? (widget.glow != null
            ? LumoTokens.shadows.glow(widget.glow!)
            : LumoTokens.shadows.softCard)
        : <BoxShadow>[];

    final card = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.gradient == null
              ? (widget.color ?? LumoTokens.colors.surface)
              : null,
          gradient: widget.gradient,
          borderRadius: widget.radius ?? LumoTokens.brLarge,
          boxShadow: shadows,
          border: widget.borderColor != null
              ? Border.all(
                  color: widget.borderColor!, width: LumoTokens.borderRegular)
              : null,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap!();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
