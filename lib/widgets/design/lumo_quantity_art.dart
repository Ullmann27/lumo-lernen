import 'package:flutter/material.dart';

/// Original local Blender renders, not an emoji or external network image.
/// A shared 128px decode is sufficient for the small countable objects on
/// high-density phones and avoids a separate full-resolution decode per item.
class LumoQuantityArt extends StatelessWidget {
  const LumoQuantityArt.apple({super.key, this.size = 24})
      : asset = 'assets/lumo_design/icons/apple_red.png';
  const LumoQuantityArt.candy({super.key, this.size = 34})
      : asset = 'assets/lumo_design/icons/candy_blue.png';

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: 128,
        cacheHeight: 128,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      );
}
