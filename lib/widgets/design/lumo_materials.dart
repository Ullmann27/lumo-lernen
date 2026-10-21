import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import 'lumo_glass_optics.dart';
import 'lumo_motion.dart';

/// Shared lighting direction: cool upper-left reflection, dark contact edge.
/// Gradients and thin painted bevels avoid backdrop blur and shader layers.
abstract final class LumoMaterials {
  static BoxDecoration glass({
    double radius = 24,
    Color base = LumoVisualTokens.glass,
    Color? border,
    double opacity = .82,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .24, 1],
          colors: [
            Color.lerp(base, LumoVisualTokens.glassHighlight, .65)!
                .withValues(alpha: (opacity + .10).clamp(0, 1)),
            base.withValues(alpha: opacity),
            LumoVisualTokens.glassDeep
                .withValues(alpha: (opacity + .12).clamp(0, 1)),
          ],
        ),
        border: Border.all(
          color: border ?? LumoVisualTokens.cyanBright.withValues(alpha: .27),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5000081C),
            blurRadius: 18,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, .48, 1],
    colors: [
      LumoVisualTokens.goldLight,
      LumoVisualTokens.gold,
      LumoVisualTokens.goldDeep,
    ],
  );
}

/// The principal action retains native focus, semantics and keyboard handling.
/// Text grows naturally; no fixed height can clip a large-text label.
class LumoGoldAction extends StatelessWidget {
  const LumoGoldAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => LumoPressable(
        glowColor: LumoVisualTokens.gold,
        radius: 18,
        pressedScale: .975,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LumoMaterials.gold,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35FFC94A),
                blurRadius: 22,
                spreadRadius: -5,
                offset: Offset(0, 5),
              ),
              BoxShadow(
                color: Color(0xFF9C6419),
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: CustomPaint(
            foregroundPainter: const LumoGlassOptics(
                radius: 18, accent: LumoVisualTokens.goldLight),
            child: LayoutBuilder(
                builder: (context, bounds) => FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: LumoVisualTokens.navigation,
                        minimumSize: const Size(48, 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                          textStyle: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: bounds.maxWidth < 160 ? 14 : 16,
                            fontWeight: FontWeight.w900),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (bounds.maxWidth >= 160) ...[
                            Icon(icon, size: 23),
                            const SizedBox(width: 6),
                          ],
                          Flexible(child: Text(label)),
                        ],
                      ),
                    )),
          ),
        ),
      );
}
