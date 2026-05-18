import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../lumo_jump/fox_sprite.dart' as fox;

/// Animierter Lumo-Fuchs auf dem Home-Screen.
///
/// Nutzt die echten 3D-Pixar-Sprites aus assets/lumo_jump/fox/.
/// - Standardmaessig: FoxAction.idle (8 Frames mit Atem-Animation)
/// - Bei Tap: kurzer Hop + FoxAction.jump-Animation
/// - Bei laengerem Druck: FoxAction.roll (lustig)
/// - Schaut in die gewuenschte Richtung (facing)
///
/// Der Avatar hat keinen eigenen GameState - er ist rein dekorativ
/// und reagiert nur auf Tap-Eingaben.
class LumoHomeFoxAvatar extends StatefulWidget {
  const LumoHomeFoxAvatar({
    super.key,
    this.size = 180,
    this.facingLeft = false,
    this.onTap,
  });

  final double size;
  final bool facingLeft;
  final VoidCallback? onTap;

  @override
  State<LumoHomeFoxAvatar> createState() => _LumoHomeFoxAvatarState();
}

class _LumoHomeFoxAvatarState extends State<LumoHomeFoxAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hopCtrl;
  fox.FoxAction _action = fox.FoxAction.idle;
  Timer? _resetTimer;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _hopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _hopCtrl.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _tapCount++;
    // Bei doppelt-Tap: Roll-Animation als kleines Easter-Egg
    final useRoll = _tapCount % 3 == 0;
    _hopCtrl.forward(from: 0);
    setState(() {
      _action = useRoll ? fox.FoxAction.roll : fox.FoxAction.jump;
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(
      Duration(milliseconds: useRoll ? 800 : 520),
      () {
        if (mounted) setState(() => _action = fox.FoxAction.idle);
      },
    );
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hopCtrl,
      builder: (_, __) {
        // Hop-Kurve: parabolisch hoch (Einheit: pixel)
        final t = _hopCtrl.value;
        final hopY = -math.sin(t * math.pi) * 24;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          child: Transform.translate(
            offset: Offset(0, hopY),
            child: fox.FoxSprite(
              action: _action,
              size: widget.size,
              facingLeft: widget.facingLeft,
              showShadow: true,
            ),
          ),
        );
      },
    );
  }
}
