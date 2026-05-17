import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../navigation/adaptive_nav.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _buttonController;
  late final AnimationController _particleController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowRadius;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonOpacity;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5),
      ),
    );
    _glowRadius = Tween<double>(begin: 20, end: 50).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    _titleSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0),
      ),
    );

    _buttonScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _logoController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await _textController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _buttonController.forward();
  }

  void _navigateToApp() {
    if (_navigating) return;
    setState(() => _navigating = true);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AdaptiveNav(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _logoController,
          _textController,
          _buttonController,
          _particleController,
        ]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1A1035),
                    const Color(0xFF0D2137),
                    _bgController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF2D1B69),
                    const Color(0xFF1A3A5C),
                    _bgController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFFFF6B35),
                    const Color(0xFFFF8C42),
                    _bgController.value,
                  )!.withOpacity(0.8),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating particles
                ..._buildParticles(context),
                // Glow behind logo
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Glow + Logo
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.orange.withOpacity(0.3),
                                      blurRadius: _glowRadius.value * 2,
                                      spreadRadius: _glowRadius.value * 0.5,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF4ECDC4)
                                          .withOpacity(0.2),
                                      blurRadius: _glowRadius.value,
                                      spreadRadius: _glowRadius.value * 0.2,
                                    ),
                                  ],
                                ),
                              ),
                              // Logo circle background
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                              // Fox Avatar
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CustomPaint(
                                  painter: _SplashFoxPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // App Name
                      Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'Lumo',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color:
                                          AppTheme.orange.withOpacity(0.7),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'LERNEN',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppTheme.turquoise.withOpacity(0.9),
                                  letterSpacing: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tagline
                      Opacity(
                        opacity: _subtitleOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            '✨ Dein smarter Lernbegleiter',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      // Start Button
                      Transform.scale(
                        scale: _buttonScale.value,
                        child: Opacity(
                          opacity: _buttonOpacity.value,
                          child: GestureDetector(
                            onTap: _navigateToApp,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8C42),
                                    Color(0xFFFF5F15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.orange.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Los geht\'s!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.rocket_launch_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final particles = <Widget>[];
    final random = math.Random(42);

    for (int i = 0; i < 18; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final particleSize = random.nextDouble() * 6 + 2;
      final speed = random.nextDouble() * 0.4 + 0.1;
      final offset = ((_particleController.value + speed * i) % 1.0);
      final opacity = math.sin(offset * math.pi).clamp(0.0, 1.0);
      final colors = [
        AppTheme.orange,
        AppTheme.turquoise,
        AppTheme.yellow,
        Colors.white,
      ];
      final color = colors[i % colors.length];

      particles.add(
        Positioned(
          left: x,
          top: (y - offset * 80) % size.height,
          child: Opacity(
            opacity: opacity * 0.6,
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: particleSize * 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return particles;
  }
}

class _SplashFoxPainter extends CustomPainter {
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
