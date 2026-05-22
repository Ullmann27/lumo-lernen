// ════════════════════════════════════════════════════════════════════════
// LUMO ACTION BUTTON — grosser pulsierender Aktions-Button
// ════════════════════════════════════════════════════════════════════════
// Wird typischerweise unten rechts im Lumo-Cards Screen platziert.
// Pulsiert wenn aktiv (Aktion moeglich), bleibt ruhig wenn deaktiviert.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum LumoActionButtonStyle { primary, success, danger, neutral }

class LumoActionButton extends StatefulWidget {
  const LumoActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = LumoActionButtonStyle.primary,
    this.enabled = true,
    this.pulse = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LumoActionButtonStyle style;
  final bool enabled;

  /// Pulse-Effekt nur wenn aktiv UND pulse=true.
  final bool pulse;

  @override
  State<LumoActionButton> createState() => _LumoActionButtonState();
}

class _LumoActionButtonState extends State<LumoActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient(widget.style);
    final isActive = widget.enabled && widget.onPressed != null;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        // Pulse-Skalierung: zwischen 1.0 und 1.04 wenn aktiv+pulse.
        final t = (widget.pulse && isActive)
            ? (math.sin(_ctrl.value * math.pi * 2) * 0.5 + 0.5)
            : 0.0;
        final scale = 1.0 + t * 0.04;
        final glow = isActive ? (0.35 + t * 0.30) : 0.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colors[1].withOpacity(glow),
                        blurRadius: 20 + t * 12,
                        offset: const Offset(0, 6),
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withOpacity(.6), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<Color> _gradient(LumoActionButtonStyle s) {
    switch (s) {
      case LumoActionButtonStyle.primary:
        return const [Color(0xFFFFB96B), Color(0xFFFF7A2F)];
      case LumoActionButtonStyle.success:
        return const [Color(0xFF34D399), Color(0xFF059669)];
      case LumoActionButtonStyle.danger:
        return const [Color(0xFFFCA5A5), Color(0xFFDC2626)];
      case LumoActionButtonStyle.neutral:
        return const [Color(0xFFC4B5FD), Color(0xFF7C3AED)];
    }
  }
}
