// ════════════════════════════════════════════════════════════════════════
// LUMO ANIMATED PAGE SHELL — Page-Transition-Wrapper
// ════════════════════════════════════════════════════════════════════════
// Slide+Fade beim Page-Eintritt fuer Premium-Feeling.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';

class LumoAnimatedPageShell extends StatefulWidget {
  const LumoAnimatedPageShell({
    super.key,
    required this.child,
    this.direction = LumoPageEnterDirection.fromBottom,
    this.delay = Duration.zero,
  });

  final Widget child;
  final LumoPageEnterDirection direction;
  final Duration delay;

  @override
  State<LumoAnimatedPageShell> createState() => _LumoAnimatedPageShellState();
}

enum LumoPageEnterDirection { fromBottom, fromTop, fromLeft, fromRight, fade }

class _LumoAnimatedPageShellState extends State<LumoAnimatedPageShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final reduceMotion =
        WidgetsBinding.instance.window.accessibilityFeatures.disableAnimations;

    _ctrl = AnimationController(
      vsync: this,
      duration: reduceMotion
          ? Duration.zero
          : LumoTokens.motion.pageTransition,
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Offset begin;
    switch (widget.direction) {
      case LumoPageEnterDirection.fromBottom:
        begin = const Offset(0, 0.15);
        break;
      case LumoPageEnterDirection.fromTop:
        begin = const Offset(0, -0.15);
        break;
      case LumoPageEnterDirection.fromLeft:
        begin = const Offset(-0.15, 0);
        break;
      case LumoPageEnterDirection.fromRight:
        begin = const Offset(0.15, 0);
        break;
      case LumoPageEnterDirection.fade:
        begin = Offset.zero;
        break;
    }
    _slide = Tween(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Opacity(
          opacity: _fade.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
