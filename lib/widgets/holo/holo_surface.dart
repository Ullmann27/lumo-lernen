import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// Hologramm-Primitiv fuer die neue Lumo-Lernwelt.
///
/// Vokabelbaustein fuer die im Master-Prompt geforderte holografische
/// Lern-UI. Das Primitiv ist bewusst standalone: es wird in dieser Phase
/// nirgends importiert und beruehrt weder die Shell, noch die Navigation,
/// noch die Karten, noch die Lumo-Buehne. Es kann in spaeteren, kleinen
/// Folge-Commits gezielt in einzelne Komponenten eingearbeitet werden.
///
/// Designprinzipien (siehe Master-Prompt Anhang):
///   - warme statt kalte Hologramme
///   - milchig, weich leuchtend, halbtransparent, glasartig
///   - leicht pulsierende Raender, additive Glow-Flaechen
///   - depth shadow unter schwebenden Modulen
///   - dynamic highlight sweep beim Aktivieren
///
/// Das Primitiv ist ein einfacher Container, der seinen [child] als
/// schwebende Hologramm-Flaeche inszeniert. Konsumenten setzen Inhalt,
/// Akzentfarbe und Aktivitaetszustand; alle visuellen Effekte werden
/// automatisch vom Primitiv geleistet.
class HoloSurface extends StatefulWidget {
  const HoloSurface({
    super.key,
    required this.child,
    this.accent = LumoColors.orange,
    this.active = false,
    this.elevated = true,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 26,
    this.glowIntensity = 1.0,
    this.pulseEnabled = true,
  });

  /// Der Inhalt der Hologramm-Flaeche.
  final Widget child;

  /// Akzentfarbe, die fuer Glow, Lichtkante und Highlight-Sweep
  /// verwendet wird. Default ist Lumo-Orange.
  final Color accent;

  /// Wenn true, wird die Hologramm-Flaeche als "aktiv" inszeniert:
  /// staerkerer Glow, animierte Lichtkante, hervorgehobener Akzent.
  /// Konsumenten setzen das z.B. bei Hover oder Fokus.
  final bool active;

  /// Wenn true, schwebt die Flaeche mit Doppel-Schatten ueber dem
  /// Hintergrund. Wenn false, liegt sie flacher (z.B. eingebettet).
  final bool elevated;

  final EdgeInsets padding;
  final double borderRadius;

  /// Skaliert die Glow-Intensitaet. 0.0 = kein Glow, 1.0 = Standard,
  /// 1.5 = starker Glow fuer Premium-Hervorhebung.
  final double glowIntensity;

  /// Wenn true, pulst der Rand sanft im Atemrhythmus (3.5 s/Zyklus).
  /// Konsumenten koennen das deaktivieren, wenn die Flaeche statisch
  /// sein soll oder wenn mehrere Holo-Flaechen gleichzeitig aktiv sind.
  final bool pulseEnabled;

  @override
  State<HoloSurface> createState() => _HoloSurfaceState();
}

class _HoloSurfaceState extends State<HoloSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    if (widget.pulseEnabled) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HoloSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseEnabled && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.pulseEnabled && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          // Atem-Pulse 0.0..1.0 mit easeInOutSine
          final t = reduced
              ? 0.5
              : Curves.easeInOutSine.transform(_pulse.value);

          // Aktiver Modus erhoeht Glow und Border-Opazitaet
          final glow = widget.glowIntensity *
              (widget.active ? 1.4 : 1.0) *
              (0.85 + t * 0.30);

          final borderOpacity = widget.active ? 0.85 : 0.55;

          return Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: _buildSurfaceGradient(t),
              border: Border.all(
                color: Colors.white.withOpacity(borderOpacity),
                width: 1.4,
              ),
              boxShadow: widget.elevated
                  ? [
                      // 1. Akzent-Glow nach unten (warmer Halo)
                      BoxShadow(
                        color: widget.accent.withOpacity(0.20 * glow),
                        blurRadius: 28 * glow,
                        offset: Offset(0, 14 * glow),
                        spreadRadius: -4,
                      ),
                      // 2. Tiefenschatten in dunklem Warm-Ton
                      BoxShadow(
                        color: const Color(0xFF3D342C).withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      // 3. Inneres Lichthighlight oben links
                      BoxShadow(
                        color: Colors.white.withOpacity(0.85),
                        blurRadius: 6,
                        offset: const Offset(-2, -2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: widget.accent.withOpacity(0.10 * glow),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            // Wenn aktiv, zeichnen wir zusaetzlich einen sanften
            // Highlight-Sweep ueber die Oberflaeche.
            child: widget.active
                ? Stack(
                    children: [
                      _HighlightSweep(
                        progress: t,
                        accent: widget.accent,
                        borderRadius: widget.borderRadius,
                      ),
                      child!,
                    ],
                  )
                : child!,
          );
        },
        child: widget.child,
      ),
    );
  }

  /// Baut den milchig-warmen Glassmorphism-Gradienten.
  /// Die Akzentfarbe scheint nur ganz subtil durch.
  LinearGradient _buildSurfaceGradient(double t) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.90),
        Colors.white.withOpacity(0.78),
        Color.lerp(
          Colors.white.withOpacity(0.82),
          widget.accent.withOpacity(0.08 + t * 0.04),
          0.5,
        )!,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }
}

/// Animierte Lichtkante, die als Sweep ueber aktive Hologramm-Flaechen
/// laeuft. Wirkt wie ein leichter Lichtbogen, der die Flaeche "auflaedt".
class _HighlightSweep extends StatelessWidget {
  const _HighlightSweep({
    required this.progress,
    required this.accent,
    required this.borderRadius,
  });

  final double progress;
  final Color accent;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: IgnorePointer(
          child: CustomPaint(
            painter: _SweepPainter(
              progress: progress,
              accent: accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Diagonal von oben links nach unten rechts wandern lassen
    final dx = size.width * (progress * 1.8 - 0.4);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.0),
          accent.withOpacity(0.18),
          Colors.white.withOpacity(0.45),
          accent.withOpacity(0.18),
          accent.withOpacity(0.0),
        ],
        stops: const [0.0, 0.40, 0.50, 0.60, 1.0],
      ).createShader(
        Rect.fromLTWH(dx - size.width * 0.5, -size.height * 0.2,
            size.width, size.height * 1.4),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.progress != progress;
}

/// Floating-Container fuer Module, die in der mittleren Lernlandschaft
/// als kleine Plattformen schweben sollen.
///
/// Erweitert HoloSurface um eine subtile Idle-Float-Bewegung in der
/// Y-Achse (4 Sekunden Zyklus, plus-minus 3 Pixel) und um einen
/// optionalen Schatten-Versatz, der die Schwebehoehe verstaerkt.
///
/// Verwendung in spaeteren Commits: Module wie KPI-Karten, Lernkarten
/// und Tagesziel-Widget koennen ohne strukturellen Eingriff in einen
/// FloatingHolo gehuellt werden, um ihnen die schwebende Wirkung zu
/// geben.
class FloatingHolo extends StatefulWidget {
  const FloatingHolo({
    super.key,
    required this.child,
    this.accent = LumoColors.orange,
    this.active = false,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 26,
    this.floatAmplitude = 3.0,
    this.floatPeriod = const Duration(milliseconds: 4000),
    this.phaseShift = 0.0,
  });

  final Widget child;
  final Color accent;
  final bool active;
  final EdgeInsets padding;
  final double borderRadius;

  /// Maximaler Hub in Pixel.
  final double floatAmplitude;

  /// Zyklus-Dauer.
  final Duration floatPeriod;

  /// Phasenverschiebung 0.0..1.0. Bei mehreren FloatingHolos kann
  /// damit der Eindruck einer ungeordneten, organischen Bewegung
  /// erreicht werden, statt einer synchronen Pumpbewegung.
  final double phaseShift;

  @override
  State<FloatingHolo> createState() => _FloatingHoloState();
}

class _FloatingHoloState extends State<FloatingHolo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: widget.floatPeriod,
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final phase = (_float.value + widget.phaseShift) * 2 * math.pi;
          final dy = reduced ? 0.0 : math.sin(phase) * widget.floatAmplitude;
          return Transform.translate(
            offset: Offset(0, dy),
            child: child,
          );
        },
        child: HoloSurface(
          accent: widget.accent,
          active: widget.active,
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
