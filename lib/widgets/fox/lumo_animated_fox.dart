import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The original sheets contain complete foxes. Their cells are NOT equally
/// spaced: the old pre-cut PNGs cut off faces and included neighbouring tails.
/// These bounds follow each visible silhouette, with a shared ground line.
class LumoFoxFrames {
  static const runAsset =
      'assets/lumo_jump/fox/sprite_sheets/fox_run_sheet_transparent.png';
  static const idleAsset =
      'assets/lumo_jump/fox/sprite_sheets/fox_idle_sheet_transparent.png';
  static const run = <Rect>[
    Rect.fromLTRB(13, 276, 193, 491),
    Rect.fromLTRB(206, 280, 380, 488),
    // Original cells 3/4 overlap at their outlines; skip these two cells.
    Rect.fromLTRB(721, 288, 900, 491),
    Rect.fromLTRB(904, 288, 1066, 491),
    Rect.fromLTRB(1076, 281, 1256, 486),
    Rect.fromLTRB(1267, 284, 1439, 490),
    Rect.fromLTRB(1441, 279, 1610, 489),
    Rect.fromLTRB(1616, 284, 1778, 491),
    Rect.fromLTRB(1786, 283, 1957, 482),
    Rect.fromLTRB(1962, 279, 2136, 489),
  ];
  static const idle = <Rect>[
    Rect.fromLTRB(52, 131, 305, 584),
    Rect.fromLTRB(327, 130, 576, 584),
    Rect.fromLTRB(586, 131, 834, 584),
    Rect.fromLTRB(851, 131, 1098, 584),
    Rect.fromLTRB(1111, 131, 1356, 584),
    Rect.fromLTRB(1373, 131, 1618, 584),
    Rect.fromLTRB(1623, 131, 1867, 584),
    Rect.fromLTRB(1884, 131, 2132, 584),
  ];
}

class LumoAnimatedFox extends StatefulWidget {
  const LumoAnimatedFox({
    super.key,
    required this.moving,
    this.facingRight = true,
    this.reducedMotion = false,
    this.size = 76,
  });

  final bool moving;
  final bool facingRight;
  final bool reducedMotion;
  final double size;

  @override
  State<LumoAnimatedFox> createState() => _LumoAnimatedFoxState();
}

class _LumoAnimatedFoxState extends State<LumoAnimatedFox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  ui.Image? _run;
  ui.Image? _idle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = <ui.Image>[];
    try {
      for (final asset in [LumoFoxFrames.runAsset, LumoFoxFrames.idleAsset]) {
        final bytes = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        ));
        try {
          loaded.add((await codec.getNextFrame()).image);
        } finally {
          codec.dispose();
        }
      }
      if (mounted) {
        setState(() {
          _run = loaded[0];
          _idle = loaded[1];
        });
      } else {
        for (final image in loaded) {
          image.dispose();
        }
      }
    } catch (_) {
      for (final image in loaded) {
        image.dispose();
      }
      // The complete master image remains a visible offline fallback.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant LumoAnimatedFox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
      _clock.value = 0;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _run?.dispose();
    _idle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiet =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    if (_run == null || _idle == null) {
      return Image.asset(
        'assets/lumo_jump/fox/master/lumo_fox_master_512.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _FoxPainter(
            image: widget.moving && !quiet ? _run! : _idle!,
            elapsed: quiet ? 0 : _clock.value * 10,
            moving: widget.moving && !quiet,
            facingRight: widget.facingRight,
            reducedMotion: quiet,
          ),
        ),
      ),
    );
  }
}

class _FoxPainter extends CustomPainter {
  const _FoxPainter({
    required this.image,
    required this.elapsed,
    required this.moving,
    required this.facingRight,
    required this.reducedMotion,
  });

  final ui.Image image;
  final double elapsed;
  final bool moving;
  final bool facingRight;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final frames = moving ? LumoFoxFrames.run : LumoFoxFrames.idle;
    final phase = elapsed % 5;
    // Slow breathing, with short blinks/winks, not continuous facial flicker.
    final idleFrame = phase < 2.8
        ? 0
        : phase < 3.12
            ? 1 + (((phase - 2.8) * 10).floor().clamp(0, 2))
            : phase < 4.5
                ? 4
                : 5 + (((phase - 4.5) * 6).floor().clamp(0, 2));
    final frame = moving ? (elapsed * 14).floor() % frames.length : idleFrame;
    final source = frames[frame];
    final breath =
        reducedMotion || moving ? 1.0 : 1 + math.sin(elapsed * 2) * .008;
    final scale = size.height / (moving ? 225 : 470);
    final width = source.width * scale;
    final height = source.height * scale * breath;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 3),
        width: size.width * .48,
        height: 5,
      ),
      Paint()..color = const Color(0x260F2855),
    );
    canvas.save();
    if (moving && !facingRight) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(
          (size.width - width) / 2, size.height - height - 3, width, height),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FoxPainter oldDelegate) =>
      elapsed != oldDelegate.elapsed ||
      moving != oldDelegate.moving ||
      facingRight != oldDelegate.facingRight ||
      image != oldDelegate.image ||
      reducedMotion != oldDelegate.reducedMotion;
}
