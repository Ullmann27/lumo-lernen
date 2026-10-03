import 'dart:async';

import 'package:flutter/material.dart';

import 'lumo_animated_fox.dart';

/// Uses the same complete character as the learner's reserved companion floor.
/// Greeting is finite; no unsolicited spins, rolls or automatic speech.
class LumoHomeFoxAvatar extends StatefulWidget {
  const LumoHomeFoxAvatar({
    super.key,
    this.size = 220,
    this.facingLeft = false,
    this.childName = 'Freund',
    this.reducedMotion = false,
    this.voiceEnabled = false,
    this.onTap,
  });
  final double size;
  final bool facingLeft;
  final String childName;
  final bool reducedMotion;
  final bool voiceEnabled;
  final VoidCallback? onTap;

  @override
  State<LumoHomeFoxAvatar> createState() => _LumoHomeFoxAvatarState();
}

class _LumoHomeFoxAvatarState extends State<LumoHomeFoxAvatar> {
  LumoFoxExpression _expression = LumoFoxExpression.greet;
  Timer? _greeting;

  @override
  void initState() {
    super.initState();
    _finishGreeting();
  }

  void _finishGreeting() {
    _greeting?.cancel();
    _greeting = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _expression = LumoFoxExpression.idle);
    });
  }

  @override
  void dispose() {
    _greeting?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: widget.onTap != null,
        label: 'Lumo begrüßt ${widget.childName}',
        child: GestureDetector(
          onTap: () {
            setState(() => _expression = LumoFoxExpression.greet);
            _finishGreeting();
            widget.onTap?.call();
          },
          child: LumoAnimatedFox(
            size: widget.size,
            moving: false,
            facingRight: !widget.facingLeft,
            reducedMotion: widget.reducedMotion,
            voiceEnabled: widget.voiceEnabled,
            expression: _expression,
          ),
        ),
      );
}
