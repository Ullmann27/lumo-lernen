import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LumoAvatar extends StatefulWidget {
  final double size;
  const LumoAvatar({super.key, this.size = 120});

  @override
  State<LumoAvatar> createState() => _LumoAvatarState();
}

class _LumoAvatarState extends State<LumoAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _FoxPainter()),
      ),
    );
  }
}

class _FoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()..isAntiAlias = true;

    // Body
    paint.color = AppTheme.orange;
    canvas.drawCircle(Offset(s * 0.5, s * 0.62), s * 0.30, paint);

    // Head
    canvas.drawCircle(Offset(s * 0.5, s * 0.38), s * 0.28, paint);

    // Ears (left)
    final leftEar = Path()
      ..moveTo(s * 0.28, s * 0.18)
      ..lineTo(s * 0.16, s * 0.02)
      ..lineTo(s * 0.40, s * 0.14)
      ..close();
    canvas.drawPath(leftEar, paint);

    // Ears (right)
    final rightEar = Path()
      ..moveTo(s * 0.72, s * 0.18)
      ..lineTo(s * 0.84, s * 0.02)
      ..lineTo(s * 0.60, s * 0.14)
      ..close();
    canvas.drawPath(rightEar, paint);

    // White face patch
    paint.color = Colors.white;
    canvas.drawCircle(Offset(s * 0.5, s * 0.42), s * 0.18, paint);

    // Eyes
    paint.color = const Color(0xFF2D2D2D);
    canvas.drawCircle(Offset(s * 0.42, s * 0.35), s * 0.04, paint);
    canvas.drawCircle(Offset(s * 0.58, s * 0.35), s * 0.04, paint);

    // Eye shine
    paint.color = Colors.white;
    canvas.drawCircle(Offset(s * 0.44, s * 0.33), s * 0.015, paint);
    canvas.drawCircle(Offset(s * 0.60, s * 0.33), s * 0.015, paint);

    // Nose
    paint.color = const Color(0xFFE07050);
    final nosePath = Path()
      ..moveTo(s * 0.5, s * 0.43)
      ..lineTo(s * 0.45, s * 0.48)
      ..lineTo(s * 0.55, s * 0.48)
      ..close();
    canvas.drawPath(nosePath, paint);

    // Stars decoration
    paint.color = AppTheme.yellow;
    _drawStar(canvas, Offset(s * 0.08, s * 0.1), s * 0.06, paint);
    _drawStar(canvas, Offset(s * 0.92, s * 0.12), s * 0.05, paint);
    _drawStar(canvas, Offset(s * 0.87, s * 0.78), s * 0.04, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;
      if (i == 0) {
        path.moveTo(
          center.dx + radius * math.cos(outerAngle),
          center.dy + radius * math.sin(outerAngle),
        );
      } else {
        path.lineTo(
          center.dx + radius * math.cos(outerAngle),
          center.dy + radius * math.sin(outerAngle),
        );
      }
      path.lineTo(
        center.dx + radius * 0.4 * math.cos(innerAngle),
        center.dy + radius * 0.4 * math.sin(innerAngle),
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
