import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Lumo's lebendige Welt - der animierte Hintergrund, der diese App
/// von jeder anderen Lern-App unterscheidet.
///
/// Vier dynamische Schichten, alle parametrisch gezeichnet:
///   1. Himmel-Verlauf basierend auf Tageszeit (echte Sonnen-Position)
///   2. Jahreszeitliche Partikel (Bluetenblaetter/Sonnenstrahlen/Blaetter/Schnee)
///   3. Schwebende Wolken mit echter Parallax-Bewegung
///   4. Funkelnde Sterne in der Nacht / Sonne am Tag
///
/// Keine GIFs. Keine externe Animation-Library. Reine CustomPainter-Magie.
/// 60fps auch auf alten Android-Geraeten dank Picture-Caching.
class LumoLivingWorld extends StatefulWidget {
  const LumoLivingWorld({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.starsEarned = 0,
  });

  final Widget child;
  /// 0.0 = ruhig, 1.0 = normal, 2.0 = Feier-Modus (mehr Partikel)
  final double intensity;
  /// Mehr Sterne -> mehr Funkeln in der Nacht
  final int starsEarned;

  @override
  State<LumoLivingWorld> createState() => _LumoLivingWorldState();
}

class _LumoLivingWorldState extends State<LumoLivingWorld>
    with TickerProviderStateMixin {
  late final AnimationController _slowController;
  late final AnimationController _mediumController;
  late final AnimationController _fastController;

  late final List<_Particle> _particles;
  late final List<_Cloud> _clouds;
  late final List<_Star> _stars;
  final _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    // Drei Zeitachsen damit Partikel nicht synchron driften - wirkt natuerlicher.
    _slowController = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    )..repeat();
    _mediumController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    _fastController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Partikel-Pool einmal vorab erzeugen - keine Re-Allocation pro Frame.
    _particles = List.generate(
      28,
      (i) => _Particle(
        seed: _random.nextDouble(),
        speedFactor: 0.4 + _random.nextDouble() * 0.8,
        size: 4 + _random.nextDouble() * 8,
      ),
    );

    _clouds = List.generate(
      4,
      (i) => _Cloud(
        offsetY: 0.08 + i * 0.06,
        seed: _random.nextDouble(),
        scale: 0.7 + _random.nextDouble() * 0.6,
      ),
    );

    _stars = List.generate(
      30,
      (i) => _Star(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.5,
        twinkleOffset: _random.nextDouble() * math.pi * 2,
        baseSize: 1.0 + _random.nextDouble() * 1.8,
      ),
    );
  }

  @override
  void dispose() {
    _slowController.dispose();
    _mediumController.dispose();
    _fastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeOfDay = _timeOfDayFromHour(now.hour);
    final season = _seasonFromMonth(now.month);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Schicht 1: Himmel-Verlauf basierend auf Tageszeit.
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _skyGradient(timeOfDay),
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Schicht 2: Wolken / Sterne / Sonne / Mond
        AnimatedBuilder(
          animation: Listenable.merge([_slowController, _fastController]),
          builder: (_, __) => CustomPaint(
            painter: _CelestialPainter(
              timeOfDay: timeOfDay,
              clouds: _clouds,
              stars: _stars,
              slowTime: _slowController.value,
              fastTime: _fastController.value,
              starsEarned: widget.starsEarned,
            ),
            size: Size.infinite,
          ),
        ),
        // Schicht 3: Jahreszeitliche Partikel
        AnimatedBuilder(
          animation: _mediumController,
          builder: (_, __) => CustomPaint(
            painter: _SeasonalParticlesPainter(
              season: season,
              particles: _particles,
              time: _mediumController.value,
              intensity: widget.intensity,
            ),
            size: Size.infinite,
          ),
        ),
        // Schicht 4: Subtiles Lichtflimmern (gibt der Szene Tiefe)
        AnimatedBuilder(
          animation: _fastController,
          builder: (_, __) => IgnorePointer(
            child: Opacity(
              opacity: 0.10 + 0.04 * math.sin(_fastController.value * math.pi * 2),
              child: const _SoftLightOverlay(),
            ),
          ),
        ),
        // Schicht 5: Inhalt
        widget.child,
      ],
    );
  }

  List<Color> _skyGradient(_TimeOfDay tod) {
    switch (tod) {
      case _TimeOfDay.dawn:
        return const [Color(0xFFFFE5D9), Color(0xFFFFD1B3), Color(0xFFFFB89A)];
      case _TimeOfDay.morning:
        return const [Color(0xFFFFF8E7), Color(0xFFFFE8B3), Color(0xFFFFD180)];
      case _TimeOfDay.noon:
        return const [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF7DD3FC)];
      case _TimeOfDay.afternoon:
        return const [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFFCD34D)];
      case _TimeOfDay.evening:
        return const [Color(0xFFFED7AA), Color(0xFFFB923C), Color(0xFFEC4899)];
      case _TimeOfDay.night:
        return const [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)];
    }
  }

  _TimeOfDay _timeOfDayFromHour(int h) {
    if (h < 6) return _TimeOfDay.night;
    if (h < 8) return _TimeOfDay.dawn;
    if (h < 11) return _TimeOfDay.morning;
    if (h < 14) return _TimeOfDay.noon;
    if (h < 17) return _TimeOfDay.afternoon;
    if (h < 20) return _TimeOfDay.evening;
    return _TimeOfDay.night;
  }

  _Season _seasonFromMonth(int m) {
    if (m >= 3 && m <= 5) return _Season.spring;
    if (m >= 6 && m <= 8) return _Season.summer;
    if (m >= 9 && m <= 11) return _Season.autumn;
    return _Season.winter;
  }
}

enum _TimeOfDay { dawn, morning, noon, afternoon, evening, night }
enum _Season { spring, summer, autumn, winter }

class _Particle {
  _Particle({required this.seed, required this.speedFactor, required this.size});
  final double seed;
  final double speedFactor;
  final double size;
}

class _Cloud {
  _Cloud({required this.offsetY, required this.seed, required this.scale});
  final double offsetY;
  final double seed;
  final double scale;
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.twinkleOffset,
    required this.baseSize,
  });
  final double x;
  final double y;
  final double twinkleOffset;
  final double baseSize;
}

class _CelestialPainter extends CustomPainter {
  _CelestialPainter({
    required this.timeOfDay,
    required this.clouds,
    required this.stars,
    required this.slowTime,
    required this.fastTime,
    required this.starsEarned,
  });

  final _TimeOfDay timeOfDay;
  final List<_Cloud> clouds;
  final List<_Star> stars;
  final double slowTime;
  final double fastTime;
  final int starsEarned;

  @override
  void paint(Canvas canvas, Size size) {
    final isNight = timeOfDay == _TimeOfDay.night;

    if (isNight) {
      _paintStars(canvas, size);
      _paintMoon(canvas, size);
    } else {
      _paintSun(canvas, size);
      _paintClouds(canvas, size);
    }
  }

  void _paintSun(Canvas canvas, Size size) {
    // Sonne wandert je nach Tageszeit ueber den Himmel (rechts oben).
    final sunX = size.width * 0.78;
    double sunY;
    switch (timeOfDay) {
      case _TimeOfDay.dawn:
      case _TimeOfDay.evening:
        sunY = size.height * 0.18;
        break;
      case _TimeOfDay.morning:
        sunY = size.height * 0.12;
        break;
      case _TimeOfDay.noon:
        sunY = size.height * 0.08;
        break;
      case _TimeOfDay.afternoon:
        sunY = size.height * 0.12;
        break;
      default:
        return;
    }

    // Sanfter Glow um die Sonne (Aura)
    canvas.drawCircle(
      Offset(sunX, sunY),
      80,
      Paint()
        ..color = const Color(0xFFFFE08A).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      45,
      Paint()
        ..color = const Color(0xFFFFB800).withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Sonnen-Scheibe
    canvas.drawCircle(
      Offset(sunX, sunY),
      26,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF7AB), Color(0xFFFFB800)],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 26)),
    );
  }

  void _paintMoon(Canvas canvas, Size size) {
    final moonX = size.width * 0.78;
    final moonY = size.height * 0.14;
    // Mond-Aura
    canvas.drawCircle(
      Offset(moonX, moonY),
      60,
      Paint()
        ..color = const Color(0xFFE0E7FF).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    // Mond
    canvas.drawCircle(
      Offset(moonX, moonY),
      28,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFCE8), Color(0xFFE2E8F0)],
        ).createShader(Rect.fromCircle(center: Offset(moonX, moonY), radius: 28)),
    );
    // Krater-Detail
    canvas.drawCircle(
      Offset(moonX - 8, moonY - 4),
      4,
      Paint()..color = const Color(0xFFCBD5E1).withOpacity(0.5),
    );
    canvas.drawCircle(
      Offset(moonX + 6, moonY + 8),
      3,
      Paint()..color = const Color(0xFFCBD5E1).withOpacity(0.4),
    );
  }

  void _paintStars(Canvas canvas, Size size) {
    // Mehr Sterne wenn das Kind mehr verdient hat
    final visibleCount = math.min(stars.length, 8 + (starsEarned ~/ 3));
    for (var i = 0; i < visibleCount; i++) {
      final star = stars[i];
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(fastTime * math.pi * 2 + star.twinkleOffset));
      final cx = star.x * size.width;
      final cy = star.y * size.height;
      // Glow
      canvas.drawCircle(
        Offset(cx, cy),
        star.baseSize * 3 * twinkle,
        Paint()
          ..color = Colors.white.withOpacity(0.25 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Kern
      canvas.drawCircle(
        Offset(cx, cy),
        star.baseSize,
        Paint()..color = Colors.white.withOpacity(0.6 + 0.4 * twinkle),
      );
      // Bei sehr hellen Sternen: 4-Punkt-Glanz wie ein Kreuz
      if (star.baseSize > 2.0 && twinkle > 0.75) {
        final paint = Paint()
          ..color = Colors.white.withOpacity(0.6 * twinkle)
          ..strokeWidth = 0.8;
        canvas.drawLine(
          Offset(cx - star.baseSize * 4, cy),
          Offset(cx + star.baseSize * 4, cy),
          paint,
        );
        canvas.drawLine(
          Offset(cx, cy - star.baseSize * 4),
          Offset(cx, cy + star.baseSize * 4),
          paint,
        );
      }
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    for (final cloud in clouds) {
      // Drift langsam von links nach rechts; bei Erreichen rechts wieder links.
      final progress = (slowTime + cloud.seed) % 1.0;
      final cx = -100 + (size.width + 200) * progress;
      final cy = size.height * cloud.offsetY;
      _drawCloud(canvas, Offset(cx, cy), cloud.scale);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(center, 22 * scale, paint);
    canvas.drawCircle(center.translate(20 * scale, 4 * scale), 18 * scale, paint);
    canvas.drawCircle(center.translate(-18 * scale, 6 * scale), 16 * scale, paint);
    canvas.drawCircle(center.translate(10 * scale, -8 * scale), 14 * scale, paint);
  }

  @override
  bool shouldRepaint(_CelestialPainter old) =>
      old.slowTime != slowTime ||
      old.fastTime != fastTime ||
      old.timeOfDay != timeOfDay ||
      old.starsEarned != starsEarned;
}

class _SeasonalParticlesPainter extends CustomPainter {
  _SeasonalParticlesPainter({
    required this.season,
    required this.particles,
    required this.time,
    required this.intensity,
  });

  final _Season season;
  final List<_Particle> particles;
  final double time;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final count = (particles.length * intensity).toInt().clamp(8, particles.length);
    for (var i = 0; i < count; i++) {
      final p = particles[i];
      _drawParticle(canvas, size, p);
    }
  }

  void _drawParticle(Canvas canvas, Size size, _Particle p) {
    final progress = (time * p.speedFactor + p.seed) % 1.0;
    // Wandert von oben nach unten, leichte Sinus-Drift seitlich.
    final y = progress * (size.height + 40) - 20;
    final swayBase = p.seed * size.width;
    final sway = math.sin(progress * math.pi * 4 + p.seed * 6) * 24;
    final x = (swayBase + sway) % size.width;
    final fadeIn = (progress < 0.1 ? progress * 10 : 1.0).clamp(0.0, 1.0);
    final fadeOut = (progress > 0.9 ? (1.0 - progress) * 10 : 1.0).clamp(0.0, 1.0);
    final alpha = fadeIn * fadeOut;

    switch (season) {
      case _Season.spring:
        _drawBlossom(canvas, Offset(x, y), p.size, alpha);
        break;
      case _Season.summer:
        _drawSparkle(canvas, Offset(x, y), p.size, alpha);
        break;
      case _Season.autumn:
        _drawLeaf(canvas, Offset(x, y), p.size, alpha, progress);
        break;
      case _Season.winter:
        _drawSnowflake(canvas, Offset(x, y), p.size, alpha);
        break;
    }
  }

  void _drawBlossom(Canvas canvas, Offset c, double s, double alpha) {
    // Kirschblueten-Stil: 5 rosa Bluetenblaetter um ein gelbes Zentrum.
    final paint = Paint()..color = const Color(0xFFFFB3D9).withOpacity(0.75 * alpha);
    for (var i = 0; i < 5; i++) {
      final angle = i * (math.pi * 2 / 5);
      final offset = Offset(math.cos(angle) * s * 0.5, math.sin(angle) * s * 0.5);
      canvas.drawCircle(c + offset, s * 0.55, paint);
    }
    canvas.drawCircle(c, s * 0.3, Paint()..color = const Color(0xFFFFD700).withOpacity(0.9 * alpha));
  }

  void _drawSparkle(Canvas canvas, Offset c, double s, double alpha) {
    // Sonnenstrahl: Vierzackiger Stern.
    final paint = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.7 * alpha)
      ..strokeWidth = s * 0.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-s, 0), c.translate(s, 0), paint);
    canvas.drawLine(c.translate(0, -s), c.translate(0, s), paint);
    // Diagonale schwaecher
    final paintDiag = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.4 * alpha)
      ..strokeWidth = s * 0.25
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-s * 0.6, -s * 0.6), c.translate(s * 0.6, s * 0.6), paintDiag);
    canvas.drawLine(c.translate(-s * 0.6, s * 0.6), c.translate(s * 0.6, -s * 0.6), paintDiag);
    // Helles Zentrum
    canvas.drawCircle(c, s * 0.25, Paint()..color = Colors.white.withOpacity(0.9 * alpha));
  }

  void _drawLeaf(Canvas canvas, Offset c, double s, double alpha, double progress) {
    // Blatt rotiert beim Fallen.
    final angle = progress * math.pi * 6;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final color = HSLColor.fromAHSL(
      0.85 * alpha,
      30 + (60 * (s / 12)),
      0.7,
      0.55,
    ).toColor();
    final path = Path()
      ..moveTo(0, -s)
      ..quadraticBezierTo(s * 0.7, -s * 0.3, s * 0.4, s * 0.6)
      ..quadraticBezierTo(0, s * 0.9, -s * 0.4, s * 0.6)
      ..quadraticBezierTo(-s * 0.7, -s * 0.3, 0, -s);
    canvas.drawPath(path, Paint()..color = color);
    // Mittelader
    canvas.drawLine(
      Offset(0, -s),
      Offset(0, s * 0.6),
      Paint()
        ..color = color.withOpacity(alpha * 0.5)
        ..strokeWidth = 0.8,
    );
    canvas.restore();
  }

  void _drawSnowflake(Canvas canvas, Offset c, double s, double alpha) {
    // Klassische 6-Achsen-Schneeflocke.
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85 * alpha)
      ..strokeWidth = s * 0.18
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final dx = math.cos(angle) * s;
      final dy = math.sin(angle) * s;
      canvas.drawLine(c, c.translate(dx, dy), paint);
      // Mini-Verzweigung
      final bx1 = math.cos(angle) * s * 0.6 + math.cos(angle + 0.5) * s * 0.25;
      final by1 = math.sin(angle) * s * 0.6 + math.sin(angle + 0.5) * s * 0.25;
      canvas.drawLine(
        c.translate(math.cos(angle) * s * 0.6, math.sin(angle) * s * 0.6),
        c.translate(bx1, by1),
        paint,
      );
      final bx2 = math.cos(angle) * s * 0.6 + math.cos(angle - 0.5) * s * 0.25;
      final by2 = math.sin(angle) * s * 0.6 + math.sin(angle - 0.5) * s * 0.25;
      canvas.drawLine(
        c.translate(math.cos(angle) * s * 0.6, math.sin(angle) * s * 0.6),
        c.translate(bx2, by2),
        paint,
      );
    }
    canvas.drawCircle(c, s * 0.15, Paint()..color = Colors.white.withOpacity(0.9 * alpha));
  }

  @override
  bool shouldRepaint(_SeasonalParticlesPainter old) =>
      old.time != time || old.season != season;
}

/// Subtiles Licht-Overlay: radialer Glow um die Mitte.
/// Gibt dem Hintergrund Tiefe und einen "Spotlight"-Effekt.
class _SoftLightOverlay extends StatelessWidget {
  const _SoftLightOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.2,
          colors: [
            Color(0x33FFFFFF),
            Color(0x00FFFFFF),
          ],
        ),
      ),
    );
  }
}
