import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import 'lumo_glass_optics.dart';
import 'lumo_motion.dart';
import 'lumo_scene_artwork.dart';

/// A real navigation surface with independent landscape, object and labels.
/// Compact cards provide secondary routes without another disclosure step.
class LumoAdventureCard extends StatelessWidget {
  const LumoAdventureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.scene,
    required this.onTap,
    this.accent = LumoVisualTokens.cyan,
    this.compact = false,
    this.artworkKey,
  });

  final String title, subtitle, artwork, scene;
  final VoidCallback onTap;
  final Color accent;
  final bool compact;
  final Key? artworkKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final large = MediaQuery.textScalerOf(context).scale(1) > 1.2;
        final artSize = math.min(box.maxWidth * .62, compact ? 90.0 : 110.0);
        return Semantics(
          button: true,
          label: '$title. $subtitle',
          onTap: onTap,
          excludeSemantics: true,
          child: LumoPressable(
            radius: 22,
            glowColor: accent,
            child: Material(
              color: LumoVisualTokens.navigation,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                LumoSceneArtwork(
                    asset: scene, alignment: const Alignment(.3, -.45)),
                DecoratedBox(
                    decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0x1603193F),
                      const Color(0xC0061839),
                      const Color(0xFF061839)
                    ],
                    stops: const [0, .58, 1],
                  ),
                )),
                Positioned(
                  right: compact ? -6 : null,
                  left: compact ? null : 6,
                  top: compact ? -4 : 2,
                  child: IgnorePointer(
                      child: Image.asset(artwork,
                          key: artworkKey,
                          width: artSize,
                          height: artSize,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true)),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: LumoVisualTokens.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact
                                      ? 15
                                      : (box.maxWidth > 260 ? 24 : 18),
                                  height: 1.1)),
                          if (!compact && !large) ...[
                            const SizedBox(height: 4),
                            Text(subtitle,
                                maxLines: 2,
                                style: const TextStyle(
                                    color: Color(0xFFD9EEFF),
                                    fontSize: 12,
                                    height: 1.15)),
                          ],
                        ]),
                  ),
                ),
                if (!compact)
                  const Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(Icons.chevron_right_rounded,
                          color: LumoVisualTokens.white, size: 22)),
                IgnorePointer(
                    child: CustomPaint(
                        painter: LumoGlassOptics(radius: 22, accent: accent))),
                Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(22),
                      focusColor: accent.withValues(alpha: .22),
                      hoverColor: accent.withValues(alpha: .08),
                    )),
              ]),
            ),
          ),
        );
      });
}
