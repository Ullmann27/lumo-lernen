import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_motion.dart';
import 'iq_style.dart';

/// Sanftes Pulsieren (0 → 1 → 0). Bei „Bewegung reduzieren“ steht der Wert
/// still und es läuft keine Dauer-Animation.
class IqPulse extends StatefulWidget {
  const IqPulse({
    super.key,
    required this.builder,
    this.period = const Duration(milliseconds: 1600),
    this.restingValue = .55,
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration period;
  final double restingValue;

  @override
  State<IqPulse> createState() => _IqPulseState();
}

class _IqPulseState extends State<IqPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period);
  bool? _running;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldRun = !LumoMotion.reduced(context);
    if (_running == shouldRun) return;
    _running = shouldRun;
    if (shouldRun) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_running != true) return widget.builder(context, widget.restingValue);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(
        context,
        Curves.easeInOut.transform(_controller.value),
      ),
    );
  }
}

/// Zählt beim ersten Aufbau von 0 bis [value] (außer bei reduzierter Bewegung).
class IqCountUp extends StatelessWidget {
  const IqCountUp({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 1300),
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (LumoMotion.reduced(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v),
    );
  }
}

/// Große Glasfläche für Rätsel, Anleitungen und Auswertung.
class IqPanel extends StatelessWidget {
  const IqPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent = LumoVisualTokens.cyan,
    this.radius = 26,
    this.strong = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accent;
  final double radius;

  /// Hellerer Rand und Lichthof (für die wichtigste Fläche einer Seite).
  final bool strong;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xEB153F71), accent, strong ? .10 : .05)!,
              const Color(0xF0071B3C),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: strong ? .62 : .38),
            width: strong ? 1.4 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: strong ? .26 : .14),
              blurRadius: strong ? 30 : 22,
              spreadRadius: -6,
            ),
            const BoxShadow(
              color: Color(0x44000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(padding: padding, child: child),
      );
}

/// Glas-Kachel für ein Feld (Figur, Zahl, Merk-Feld).
class IqTile extends StatelessWidget {
  const IqTile({
    super.key,
    required this.child,
    this.radius = 18,
    this.accent = LumoVisualTokens.cyan,
    this.highlighted = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final Color accent;
  final bool highlighted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF21C4E83), Color(0xF50B2B55)],
          ),
          border: Border.all(
            color: accent.withValues(alpha: highlighted ? .95 : .30),
            width: highlighted ? 2.2 : 1.1,
          ),
          boxShadow: [
            if (highlighted) ...iqGlow(accent, alpha: .5, blur: 22),
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .10),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      );
}

/// Gestrichelter Kreis (Platz für die gesuchte Zahl).
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - width) / 2;
    final center = size.center(Offset.zero);
    const dashes = 22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi / dashes * .9,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.width != width;
}

/// Leuchtende Zahlen-Blase. Ohne [number] ist es der Platz für die gesuchte
/// Zahl: gestrichelter Ring und ein pulsierendes Fragezeichen.
class IqNumberBubble extends StatelessWidget {
  const IqNumberBubble({
    super.key,
    this.number,
    this.size = 64,
    this.color = LumoVisualTokens.cyan,
    this.highlighted = false,
  });

  final int? number;
  final double size;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final n = number;
    if (n == null) return _questionBubble();
    final digits = '$n'.length;
    final fontSize = size * (digits >= 3 ? .34 : digits == 2 ? .42 : .5);
    final tone = highlighted ? LumoVisualTokens.gold : color;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.35, -.5),
            radius: 1.05,
            colors: [
              Color.lerp(tone, Colors.white, .62)!,
              tone,
              Color.lerp(tone, const Color(0xFF0B1D45), .62)!,
            ],
            stops: const [0, .45, 1],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: .7),
            width: 1.1,
          ),
          boxShadow: [
            ...iqGlow(tone, alpha: highlighted ? .6 : .42, blur: size * .5),
            const BoxShadow(
              color: Color(0x44000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * .07,
              left: size * .2,
              right: size * .2,
              height: size * .36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .55),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size * .1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$n',
                  style: iqText(
                    fontSize,
                    weight: FontWeight.w900,
                    color: highlighted ? const Color(0xFF3A2A00) : Colors.white,
                    shadows: highlighted
                        ? null
                        : const [Shadow(color: Color(0x88031230), blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionBubble() => IqPulse(
        builder: (context, t) => SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LumoVisualTokens.gold.withValues(alpha: .08 + .08 * t),
              boxShadow: iqGlow(LumoVisualTokens.gold,
                  alpha: .22 + .3 * t, blur: size * .5),
            ),
            child: CustomPaint(
              painter: _DashedRingPainter(
                LumoVisualTokens.gold.withValues(alpha: .7 + .3 * t),
                2.2,
              ),
              child: Center(
                child: Text(
                  '?',
                  style: iqText(
                    size * .52,
                    weight: FontWeight.w900,
                    color: LumoVisualTokens.gold,
                    shadows: [
                      Shadow(
                        color: LumoVisualTokens.gold.withValues(alpha: .6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Gesuchtes Feld: pulsierender goldener Rahmen mit „?“ – oder, wenn schon
/// eine Antwort markiert ist, die Vorschau dieser Antwort.
class IqQuestionTile extends StatelessWidget {
  const IqQuestionTile({
    super.key,
    this.preview,
    this.previewId,
    this.radius = 18,
    this.questionSize = 40,
  });

  final Widget? preview;

  /// Wechselt die Vorschau, spielt das Feld seinen kleinen Pop-Effekt.
  final Object? previewId;
  final double radius;
  final double questionSize;

  @override
  Widget build(BuildContext context) {
    final shown = preview;
    if (shown != null) {
      return TweenAnimationBuilder<double>(
        key: ValueKey(previewId),
        tween: Tween<double>(begin: LumoMotion.reduced(context) ? 1 : .6, end: 1),
        duration: LumoMotion.reduced(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, v, child) =>
            Transform.scale(scale: v.clamp(0.0, 1.2).toDouble(), child: child),
        child: IqTile(
          radius: radius,
          accent: LumoVisualTokens.gold,
          highlighted: true,
          padding: const EdgeInsets.all(6),
          child: shown,
        ),
      );
    }
    return IqPulse(
      builder: (context, t) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: LumoVisualTokens.gold.withValues(alpha: .07 + .07 * t),
          border: Border.all(
            color: LumoVisualTokens.gold.withValues(alpha: .55 + .4 * t),
            width: 2,
          ),
          boxShadow: iqGlow(LumoVisualTokens.gold, alpha: .15 + .3 * t),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                '?',
                style: iqText(
                  questionSize,
                  weight: FontWeight.w900,
                  color: LumoVisualTokens.gold,
                  shadows: [
                    Shadow(
                      color: LumoVisualTokens.gold.withValues(alpha: .6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runde Plakette mit dem Symbol eines Denkbereichs.
class IqAreaMedallion extends StatelessWidget {
  const IqAreaMedallion(this.area, {super.key, this.size = 44, this.glow = true});

  final IqArea area;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final style = iqAreaStyle(area);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.3, -.4),
          colors: [
            Color.lerp(style.color, Colors.white, .25)!.withValues(alpha: .85),
            style.color.withValues(alpha: .28),
          ],
        ),
        border: Border.all(color: style.color.withValues(alpha: .95), width: 1.5),
        boxShadow: glow ? iqGlow(style.color, alpha: .45, blur: size * .5) : null,
      ),
      child: Icon(style.icon, size: size * .54, color: Colors.white),
    );
  }
}

/// Hauptknopf: Pille mit Verlauf, mindestens 56 dp hoch.
class IqPrimaryButton extends StatelessWidget {
  const IqPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 58,
    this.outlined = false,
    this.color = LumoVisualTokens.cyan,
    this.fontSize = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool outlined;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    // Im Querformat (wenig Höhe) darf der Knopf etwas flacher sein.
    final height = MediaQuery.sizeOf(context).height < 500
        ? math.min(this.height, 52.0)
        : this.height;
    final textColor = !enabled
        ? LumoVisualTokens.muted.withValues(alpha: .75)
        : outlined
            ? Colors.white
            : LumoVisualTokens.night;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: LumoPressable(
        enabled: enabled,
        radius: 99,
        glowColor: color,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: AnimatedContainer(
            duration: LumoMotion.reduced(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            height: height,
            padding: EdgeInsets.symmetric(horizontal: fontSize >= 17 ? 22 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: !enabled
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2B4A74), Color(0xFF1B3459)],
                    )
                  : outlined
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF14468F), Color(0xFF0B2D63)],
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(color, Colors.white, .55)!,
                            color,
                          ],
                        ),
              border: Border.all(
                color: !enabled
                    ? Colors.white.withValues(alpha: .14)
                    : outlined
                        ? LumoVisualTokens.cyanBright
                        : Colors.white.withValues(alpha: .85),
                width: 1.5,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .5),
                        blurRadius: 18,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: iqText(fontSize,
                          weight: FontWeight.w900, color: textColor),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: textColor, size: fontSize + 6),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runder Symbolknopf mit mindestens 48 dp Tippfläche.
class IqRoundButton extends StatelessWidget {
  const IqRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = LumoVisualTokens.cyanBright,
    this.size = 48,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        onTap: onPressed,
        child: Tooltip(
          message: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: SizedBox.square(
              dimension: math.max(size, 48),
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xAA0B2B58),
                    border: Border.all(
                      color: color.withValues(alpha: onPressed == null ? .25 : .7),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: onPressed == null
                        ? LumoVisualTokens.muted.withValues(alpha: .5)
                        : color,
                    size: size * .5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Fortschrittsbalken in sechs Abschnitten – einer je Denkbereich.
class IqSegmentedProgress extends StatelessWidget {
  const IqSegmentedProgress({
    super.key,
    required this.done,
    required this.perArea,
    this.height = 9,
  });

  /// Anzahl schon beantworteter Rätsel.
  final int done;
  final int perArea;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduced = LumoMotion.reduced(context);
    return Row(
      children: [
        for (var i = 0; i < IqArea.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                end: ((done - i * perArea) / perArea).clamp(0.0, 1.0).toDouble(),
              ),
              duration: reduced ? Duration.zero : const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => _Segment(
                value: value,
                color: iqAreaStyle(IqArea.values[i]).color,
                height: height,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.value, required this.color, required this.height});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            color: Colors.white.withValues(alpha: .12),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  gradient: LinearGradient(
                    colors: [Color.lerp(color, Colors.white, .35)!, color],
                  ),
                  boxShadow: value > 0 ? iqGlow(color, alpha: .6, blur: 8) : null,
                ),
              ),
            ),
          ),
        ),
      );
}

/// Kleine Pille: Symbol und Text.
class IqChip extends StatelessWidget {
  const IqChip({
    super.key,
    required this.label,
    this.icon,
    this.color = LumoVisualTokens.cyan,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xEB071A38), color, .16),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: .6)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: dense ? 10 : 12, vertical: dense ? 5 : 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: dense ? 15 : 18, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: iqText(dense ? 12 : 13.5,
                      weight: FontWeight.w900,
                      color: Color.lerp(color, Colors.white, .55)!),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Untere Leiste mit dem Hauptknopf: gleiche Breite und Abstände auf jeder
/// Seite, mit weichem Verlauf zum Inhalt.
class IqBottomBar extends StatelessWidget {
  const IqBottomBar({super.key, required this.child, this.maxWidth = 520});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LumoVisualTokens.night.withValues(alpha: 0),
              LumoVisualTokens.night.withValues(alpha: .92),
            ],
          ),
        ),
        child: Padding(
          padding: MediaQuery.sizeOf(context).height < 500
              ? const EdgeInsets.fromLTRB(16, 4, 16, 6)
              : const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      );
}
