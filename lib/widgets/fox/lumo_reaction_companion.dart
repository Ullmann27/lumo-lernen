import 'package:flutter/material.dart';

import 'lumo_animated_fox.dart';

enum LumoReactionMood { idle, cheer, think }

/// Answer reactions share the complete, smoothly transitioning fox used by
/// the reserved companion floor. The historical cut-up idle frames are unused.
class LumoReactionCompanion extends StatelessWidget {
  const LumoReactionCompanion({
    super.key,
    this.mood = LumoReactionMood.idle,
    this.size = 80,
    this.reducedMotion = false,
    this.onTap,
  });

  final LumoReactionMood mood;
  final double size;
  final bool reducedMotion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LumoAnimatedFox(
          moving: false,
          size: size,
          reducedMotion: reducedMotion,
          expression: switch (mood) {
            LumoReactionMood.idle => LumoFoxExpression.idle,
            LumoReactionMood.cheer => LumoFoxExpression.celebrate,
            LumoReactionMood.think => LumoFoxExpression.think,
          },
        ),
      );
}
