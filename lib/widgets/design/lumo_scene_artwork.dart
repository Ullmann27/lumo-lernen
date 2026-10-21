import 'package:flutter/material.dart';

/// Original scenery, cropped slightly inside its historical white export edge.
/// No derived image or screenshot UI is baked into this reusable layer.
class LumoSceneArtwork extends StatelessWidget {
  const LumoSceneArtwork({
    super.key,
    required this.asset,
    this.alignment = const Alignment(0, -.3),
  });

  final String asset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: Transform.scale(
          scale: 1.035,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: alignment,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
}
