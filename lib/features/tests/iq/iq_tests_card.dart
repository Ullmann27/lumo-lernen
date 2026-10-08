import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_motion.dart';
import 'iq_figure_painter.dart';
import 'iq_style.dart';

const _violet = Color(0xFF9170FF);

/// Die Karte „Lumo Knobel-Test“ auf der Tests-Seite: zeigt das letzte echte
/// Ergebnis (Denkpunkte und Datum) oder „Noch nicht gemacht“.
class IqTestsCard extends StatelessWidget {
  const IqTestsCard({super.key, required this.last, required this.onOpen});

  /// Das letzte gespeicherte Ergebnis dieses Kindes.
  final IqTestResult? last;
  final VoidCallback onOpen;

  static const _months = [
    'Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', //
    'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  static String dateLabel(DateTime d) => '${d.day}. ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final result = last;
    final lastLine = result == null
        ? 'Noch nicht gemacht'
        : 'Zuletzt: ${result.thinkingPoints} Denkpunkte';
    final dateLine = result == null ? null : dateLabel(result.finishedAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Semantics(
        button: true,
        label: 'Lumo Knobel-Test · IQ-Test für Kinder. $lastLine'
            '${dateLine == null ? '' : ', $dateLine'}',
        excludeSemantics: true,
        onTap: onOpen,
        child: LumoPressable(
          radius: 24,
          glowColor: _violet,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xF0312F9A), Color(0xF00F3F86), Color(0xF4072654)],
                  stops: [0, .55, 1],
                ),
                border: Border.all(color: _violet.withValues(alpha: .8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _violet.withValues(alpha: .35),
                    blurRadius: 26,
                    spreadRadius: -4,
                  ),
                  const BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Stack(
                  children: [
                    // Blasse Formen im Hintergrund geben der Karte Tiefe.
                    const Positioned(
                      right: -22,
                      top: -26,
                      child: Opacity(
                        opacity: .16,
                        child: IqFigureView(
                          IqFigure(IqShape.star, tint: IqTint.gold),
                          size: 128,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 70,
                      bottom: -34,
                      child: Opacity(
                        opacity: .10,
                        child: IqFigureView(
                          IqFigure(IqShape.hexagon, tint: IqTint.cyan),
                          size: 96,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const _MiniMatrix(),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lumo Knobel-Test',
                                      style: iqText(
                                        20,
                                        weight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'IQ-Test für Kinder',
                                      style: iqText(
                                        14,
                                        color: LumoVisualTokens.cyanBright,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '24 Rätsel in 6 Bereichen · ohne Zeitdruck',
                                      style: iqText(
                                        11.5,
                                        weight: FontWeight.w700,
                                        color: LumoVisualTokens.muted,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      LumoVisualTokens.gold.withValues(alpha: .5),
                                      LumoVisualTokens.gold.withValues(alpha: .1),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: LumoVisualTokens.gold.withValues(alpha: .8),
                                  ),
                                ),
                                child: const Icon(Icons.emoji_events_rounded,
                                    size: 21, color: LumoVisualTokens.gold),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lastLine,
                                      key: const ValueKey('iq-card-last'),
                                      style: iqText(
                                        13.5,
                                        weight: FontWeight.w900,
                                        color: result == null
                                            ? LumoVisualTokens.muted
                                            : LumoVisualTokens.white,
                                      ),
                                    ),
                                    if (dateLine != null)
                                      Text(
                                        dateLine,
                                        style: iqText(
                                          11.5,
                                          weight: FontWeight.w700,
                                          color: LumoVisualTokens.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const _StartPill(),
                            ],
                          ),
                        ],
                      ),
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

/// Mini-Muster-Matrix mit gesuchtem Feld als Bild der Karte.
class _MiniMatrix extends StatelessWidget {
  const _MiniMatrix();

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0x66061C46),
            border: Border.all(color: Colors.white.withValues(alpha: .22)),
          ),
          child: Padding(padding: const EdgeInsets.all(3), child: child),
        );
    return ExcludeSemantics(
      child: Container(
        width: 82,
        height: 82,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _violet.withValues(alpha: .55),
              LumoVisualTokens.cyan.withValues(alpha: .28),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .4)),
          boxShadow: iqGlow(_violet, alpha: .5, blur: 18),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            cell(const IqFigureView(IqFigure(IqShape.circle, tint: IqTint.cyan))),
            cell(const IqFigureView(IqFigure(IqShape.square, tint: IqTint.orange))),
            cell(const IqFigureView(IqFigure(IqShape.triangle, tint: IqTint.pink))),
            cell(
              Center(
                child: Text(
                  '?',
                  style: iqText(
                    22,
                    weight: FontWeight.w900,
                    color: LumoVisualTokens.gold,
                    shadows: [
                      Shadow(
                        color: LumoVisualTokens.gold.withValues(alpha: .7),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartPill extends StatelessWidget {
  const _StartPill();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8BEFFF), LumoVisualTokens.cyan],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .85), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: LumoVisualTokens.cyan.withValues(alpha: .5),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start',
                style: iqText(15, weight: FontWeight.w900, color: LumoVisualTokens.night),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: LumoVisualTokens.night, size: 22),
            ],
          ),
        ),
      );
}
