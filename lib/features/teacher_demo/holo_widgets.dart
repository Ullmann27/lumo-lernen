import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'demo_class_data.dart';

/// Farben der holografischen Lehrkräfte-Ansicht.
class HoloPalette {
  const HoloPalette._();
  static const Color deep = Color(0xFF040B1C);
  static const Color night = Color(0xFF0A1730);
  static const Color cyan = Color(0xFF38E8FF);
  static const Color blue = Color(0xFF3D7BFF);
  static const Color violet = Color(0xFF9A7BFF);
  static const Color mint = Color(0xFF4DFFB8);
  static const Color amber = Color(0xFFFFC857);
  static const Color rose = Color(0xFFFF6B9A);
  static const Color text = Color(0xFFE6F7FF);
  static const Color muted = Color(0xFF8FB3CC);

  static const Map<String, Color> subjects = {
    'Mathematik': cyan,
    'Deutsch': amber,
    'Englisch': violet,
    'Sachkunde': mint,
  };

  static Color subject(String s) => subjects[s] ?? blue;
}

bool holoAnimationsOff(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Dunkler Hintergrund mit Lichtnebel und feinem Raster für Tiefe.
class HoloBackground extends StatelessWidget {
  const HoloBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.6, -.8),
          radius: 1.6,
          colors: [Color(0xFF12305A), HoloPalette.night, HoloPalette.deep],
          stops: [0, .45, 1],
        ),
      ),
      child: CustomPaint(painter: _GridPainter(), child: child),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HoloPalette.cyan.withValues(alpha: .05)
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Glasfläche mit leuchtendem Rand und gelegentlich durchlaufendem
/// bläulichem Schimmer.
class HoloPanel extends StatefulWidget {
  const HoloPanel({
    super.key,
    required this.child,
    this.accent = HoloPalette.cyan,
    this.padding = const EdgeInsets.all(16),
    this.shimmer = true,
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final bool shimmer;

  @override
  State<HoloPanel> createState() => _HoloPanelState();
}

class _HoloPanelState extends State<HoloPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 5200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.shimmer && !holoAnimationsOff(context)) {
      if (!_sweep.isAnimating) _sweep.repeat();
    } else {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: widget.accent.withValues(alpha: .55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accent.withValues(alpha: .16),
            HoloPalette.night.withValues(alpha: .82),
            HoloPalette.deep.withValues(alpha: .9),
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: widget.accent.withValues(alpha: .28),
              blurRadius: 22,
              spreadRadius: -4),
          const BoxShadow(
              color: Color(0xAA000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, child) => CustomPaint(
            foregroundPainter:
                _ShimmerPainter(_sweep.value, widget.accent, widget.shimmer),
            child: child,
          ),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter(this.t, this.color, this.enabled);
  final double t;
  final Color color;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    // Nur im ersten Viertel des Zyklus sichtbar: ein Schimmer „ab und zu“.
    if (!enabled || t > .25) return;
    final p = t / .25;
    final x = -size.width * .4 + p * size.width * 1.8;
    final rect = Rect.fromLTWH(x - 80, 0, 160, size.height);
    final paint = Paint()
      ..shader = LinearGradient(colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: .22),
        Colors.white.withValues(alpha: .12),
        color.withValues(alpha: 0),
      ], stops: const [0, .45, .55, 1])
          .createShader(rect);
    canvas.save();
    canvas.translate(x, size.height / 2);
    canvas.rotate(-math.pi / 9);
    canvas.translate(-x, -size.height / 2);
    canvas.drawRect(rect.inflate(size.height), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.t != t;
}

/// Holografische Schaltfläche (mindestens 48 dp hoch).
class HoloButton extends StatelessWidget {
  const HoloButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.accent = HoloPalette.cyan,
    this.shimmer = true,
  });

  final String label;
  final bool shimmer;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
        child: Opacity(
          opacity: enabled ? 1 : .45,
          child: HoloPanel(
            accent: accent,
            shimmer: shimmer,
            padding: EdgeInsets.zero,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onPressed,
                splashColor: accent.withValues(alpha: .25),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: accent, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: HoloPalette.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Unübersehbares Schild „DEMO-DATEN“.
class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Achtung: $demoDataLabel',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: HoloPalette.amber.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: HoloPalette.amber),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded, size: 16, color: HoloPalette.amber),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                demoDataLabel,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: HoloPalette.amber,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ehrlicher Hinweis: alles läuft lokal, ohne Server und ohne Abgleich.
class LocalDemoNotice extends StatelessWidget {
  const LocalDemoNotice({super.key});

  static const String text = 'Demo: lokal auf diesem Gerät';

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.phone_android_rounded, size: 16, color: HoloPalette.muted),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            '$text – keine Übertragung an andere Geräte.',
            style: TextStyle(color: HoloPalette.muted, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

/// Überschrift eines Abschnitts mit Leuchtstrich.
class HoloSectionTitle extends StatelessWidget {
  const HoloSectionTitle(this.title, {super.key, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: HoloPalette.cyan, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: HoloPalette.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  HoloPalette.cyan,
                  Color(0x003D7BFF),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
