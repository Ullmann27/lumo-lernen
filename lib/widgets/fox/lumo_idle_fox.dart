import 'package:flutter/material.dart';

import 'lumo_animated_fox.dart';

/// Complete original-sheet fox with quiet breathing and occasional blinks.
class LumoIdleFox extends StatelessWidget {
  const LumoIdleFox({
    super.key,
    this.size = 120,
    this.facingRight = true,
    this.frameDuration = const Duration(milliseconds: 110),
    this.fit = BoxFit.contain,
    this.reducedMotion = false,
  });

  final double size;
  final bool facingRight;
  // Retained for source compatibility. Idle now follows the same calm timeline
  // as the main companion rather than flickering through 8 frames each second.
  final Duration frameDuration;
  final BoxFit fit;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => LumoAnimatedFox(
        moving: false,
        size: size,
        facingRight: facingRight,
        reducedMotion: reducedMotion,
      );
}
