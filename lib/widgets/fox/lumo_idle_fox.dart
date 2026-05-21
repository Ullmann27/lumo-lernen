// ════════════════════════════════════════════════════════════════════════
// LUMO IDLE FOX — 8-Frame Sprite-Animation
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: keine altmodischen Cartoon-Fuchs-Bilder mehr (lumo_fox.png,
// lumo_fox.jpg, lumo_main.png mit Karte/Etikett). Stattdessen die echte
// Idle-Animation aus assets/lumo_jump/fox/idle/ - 8 Frames im Loop mit
// transparenter PNG-Optik, modern und kindgerecht.
//
// Eigenschaften:
//   - reine StatefulWidget-Loesung, kein zusaetzliches Paket
//   - schaltet beim Wechsel der Frame-Liste automatisch zurueck
//   - respektiert MediaQuery.disableAnimations (Barrierefreiheit)
//   - errorBuilder fallback auf 🦊 Emoji
//   - Transform.scale fuer facingRight/Left (Mirror)
//   - precacheImage im didChangeDependencies fuer fluessigen Start
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoIdleFox extends StatefulWidget {
  const LumoIdleFox({
    super.key,
    this.size = 120,
    this.facingRight = true,
    this.frameDuration = const Duration(milliseconds: 110),
    this.fit = BoxFit.contain,
  });

  /// Hoehe der Fuchs-Figur. Breite wird ueber das Bild-AspectRatio bestimmt.
  final double size;

  /// Soll der Fuchs nach rechts schauen?
  final bool facingRight;

  /// Wie lange ein einzelnes Frame angezeigt wird. 110ms => ~9 FPS, ruhig
  /// und kindgerecht.
  final Duration frameDuration;

  final BoxFit fit;

  /// Pfade der 8 Idle-Frames (assets/lumo_jump/fox/idle/fox_idle_01..08).
  static const List<String> frames = [
    'assets/lumo_jump/fox/idle/fox_idle_01.png',
    'assets/lumo_jump/fox/idle/fox_idle_02.png',
    'assets/lumo_jump/fox/idle/fox_idle_03.png',
    'assets/lumo_jump/fox/idle/fox_idle_04.png',
    'assets/lumo_jump/fox/idle/fox_idle_05.png',
    'assets/lumo_jump/fox/idle/fox_idle_06.png',
    'assets/lumo_jump/fox/idle/fox_idle_07.png',
    'assets/lumo_jump/fox/idle/fox_idle_08.png',
  ];

  @override
  State<LumoIdleFox> createState() => _LumoIdleFoxState();
}

class _LumoIdleFoxState extends State<LumoIdleFox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _frameIndex = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.frameDuration * LumoIdleFox.frames.length,
    )..addListener(_onTick);
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Frames im Speicher vorhalten - aber NACH dem Frame, damit
      // _dependents.isEmpty assertion bei schneller Navigation nicht
      // crasht (Heinz-Bug: WordCoach Pause-Screen).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final path in LumoIdleFox.frames) {
          precacheImage(AssetImage(path), context);
        }
      });
    }
    // Animationen ggf. abschalten (Barrierefreiheit).
    final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disable) {
      _controller.stop();
      if (_frameIndex != 0) {
        setState(() => _frameIndex = 0);
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _onTick() {
    final next =
        (_controller.value * LumoIdleFox.frames.length).floor() %
            LumoIdleFox.frames.length;
    if (next != _frameIndex && mounted) {
      setState(() => _frameIndex = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      LumoIdleFox.frames[_frameIndex],
      height: widget.size,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => SizedBox(
        height: widget.size,
        width: widget.size,
        child: Center(
          child: Text(
            '🦊',
            style: TextStyle(fontSize: widget.size * 0.6),
          ),
        ),
      ),
    );
    if (widget.facingRight) return image;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
      child: image,
    );
  }
}
