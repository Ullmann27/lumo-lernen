import 'package:flutter/material.dart';

import 'fox/lumo_idle_fox.dart';

/// Eingebettete Lumo-Darstellung. Frueher wurde hier das Cartoon-JPG
/// (assets/images/lumo_fox.jpg) angezeigt - das ist raus. Jetzt rendert
/// EmbeddedLumoFox die 8-Frame-Idle-Animation (LumoIdleFox).
///
/// jpgAssetPath bleibt als Konstante erhalten, damit alte Verweise
/// (z.B. precacheImage in lumo_tour.dart) den Build nicht brechen -
/// das eigentliche Rendering ignoriert den Pfad.
class EmbeddedLumoFox extends StatelessWidget {
  const EmbeddedLumoFox({super.key, required this.size});
  final double size;

  static const String jpgAssetPath = 'assets/images/lumo_fox.jpg';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.42,
      child: Center(child: LumoIdleFox(size: size * 1.4)),
    );
  }
}

