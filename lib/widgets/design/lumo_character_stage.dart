import 'package:flutter/material.dart';

import '../fox/lumo_character.dart';
import 'lumo_design_system.dart';

/// Original, separately layered artwork. The terrace grounds the character;
/// the light is a cheap gradient, not a backdrop filter or a second fox image.
class LumoCharacterStage extends StatelessWidget {
  const LumoCharacterStage({
    super.key,
    required this.size,
    required this.pose,
    required this.reduceMotion,
    this.controller,
    this.onTap,
  });

  final double size;
  final LumoDesignFoxPose pose;
  final bool reduceMotion;
  final LumoCharacterController? controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 1.06,
        child: Stack(children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(.2, .1),
                    radius: .65,
                    colors: [Color(0x4037D2FD), Color(0x0037D2FD)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset('assets/lumo_design/nature/platform.webp',
                height: size * .34,
                fit: BoxFit.fill,
                excludeFromSemantics: true),
          ),
          LumoCharacter(
            size: size,
            pose: pose,
            reduceMotion: reduceMotion,
            controller: controller,
            intro: false,
            idleHops: false,
            onTap: onTap,
          ),
        ]),
      );
}
