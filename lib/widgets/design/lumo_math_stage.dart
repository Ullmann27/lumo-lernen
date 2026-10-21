import 'package:flutter/material.dart';

import '../fox/lumo_character.dart';
import 'lumo_character_stage.dart';
import 'lumo_design_system.dart';

/// Shares the Home's original character, terrace and lighting. The owning
/// lesson supplies the actual visualization and genuine response controller.
class LumoMathStage extends StatelessWidget {
  const LumoMathStage({super.key, required this.visualization,
    required this.reduceMotion, this.controller});
  final Widget visualization;
  final bool reduceMotion;
  final LumoCharacterController? controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final foxSize = (box.maxWidth * .43).clamp(104.0, 230.0);
    final fox = LumoCharacterStage(size: foxSize,
      pose: LumoDesignFoxPose.bookPoint, reduceMotion: reduceMotion,
      controller: controller);
    if (MediaQuery.textScalerOf(context).scale(1) > 1.5) {
      return Column(children: [fox, const SizedBox(height: 8), visualization]);
    }
    return Row(children: [
      Expanded(child: visualization),
      const SizedBox(width: 8),
      fox,
    ]);
  });
}
