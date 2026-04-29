import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../effects/animated_counter.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accent,
    required this.percent,
  });

  final String label;
  final String value;
  final String sub;    // e.g. "/50" or "Einsteiger" or "Diese Woche"
  final String icon;   // emoji
  final Color accent;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: label + icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: .3,
                ),
              ),
              const Spacer(),
              Text(icon, style: const TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 6),
          // Value row — Counter-Animation falls Zahl, sonst statisch
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _maybeCounter(value, LumoTextStyles.kpiValue),
              const SizedBox(width: 4),
              Text(
                sub,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LumoColors.ink300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 7,
              color: accent,
              backgroundColor: accent.withOpacity(.14),
            ),
          ),
        ],
      ),
    );
  }

  /// Wenn der Wert eine reine Zahl ist → animierter Counter,
  /// sonst statischer Text.
  Widget _maybeCounter(String text, TextStyle style) {
    final n = int.tryParse(text);
    if (n != null) {
      return AnimatedCounter(value: n, style: style);
    }
    return Text(text, style: style);
  }
}

/// Lernfortschritt mit Donut-Ring statt Balken
class KpiCircularCard extends StatelessWidget {
  const KpiCircularCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
    required this.percent,
  });

  final String label;
  final String value;
  final String sub;
  final Color accent;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Row(
        children: [
          // Donut ring
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                strokeWidth: 7,
                color: accent,
                backgroundColor: accent.withOpacity(.14),
                strokeCap: StrokeCap.round,
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: LumoTextStyles.kpiValue.copyWith(fontSize: 26),
                ),
                Text(sub, style: LumoTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
