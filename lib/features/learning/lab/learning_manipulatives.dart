import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_motion.dart';

const _ink = LumoVisualTokens.white;
const _muted = LumoVisualTokens.muted;
const _cyan = LumoVisualTokens.cyan;
const _gold = LumoVisualTokens.gold;
const _violet = Color(0xFFA899FF);

const _labelStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 14,
  fontWeight: FontWeight.w900,
  color: _ink,
  height: 1.3,
);
const _bodyStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: _muted,
  height: 1.4,
);

Duration _duration(BuildContext context, bool reduceMotion) =>
    reduceMotion || LumoMotion.reduced(context) || !TickerMode.of(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

/// A controlled ten-frame: counters are moved individually from the supply.
///
/// The board never supplies an answer to the surrounding exercise. Only
/// [reveal] exposes the number of spaces needed to complete the ten-frame.
class QuantityBridgeBoard extends StatelessWidget {
  const QuantityBridgeBoard({
    super.key,
    required this.start,
    required this.addend,
    required this.moved,
    required this.onChanged,
    this.enabled = true,
    this.reveal = false,
    this.reduceMotion = false,
  });

  final int start;
  final int addend;
  final int moved;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool reveal;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final initial = start.clamp(0, 10);
    final supply = math.max(0, addend);
    final placed = moved.clamp(0, supply);
    final inFrame = math.min(placed, 10 - initial);
    final overflow = placed - inFrame;

    void move(int delta) => onChanged((placed + delta).clamp(0, supply));

    Widget placedCounter(int index, {double? size}) => _CounterButton(
          key: ValueKey('quantity-placed-$index'),
          label: 'Verschobener Stein ${index + 1}, zurück in den Vorrat',
          color: _cyan,
          size: size,
          onPressed: enabled ? () => move(-1) : null,
          reduceMotion: reduceMotion,
        );

    return _LabSurface(
      accent: _cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BoardHeading(
            icon: Icons.grid_view_rounded,
            title: 'Dein Zehnerfeld',
            subtitle: 'Schiebe die Steine. Was entdeckst du?',
            accent: _cyan,
          ),
          const SizedBox(height: 16),
          _InsetDeck(
            child: LayoutBuilder(builder: (context, constraints) {
              final cell = (constraints.maxWidth - 16) / 5;
              return Column(
                children: List.generate(2, (row) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: row == 0 ? 4 : 0),
                    child: Row(
                      children: List.generate(5, (column) {
                        final index = row * 5 + column;
                        final isFixed = index < initial;
                        final movedIndex = index - initial;
                        final isMoved = movedIndex >= 0 && movedIndex < inFrame;
                        return Padding(
                          padding: EdgeInsets.only(right: column < 4 ? 4 : 0),
                          child: SizedBox(
                            width: cell,
                            height: math.max(48, cell),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF061B38),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF325578),
                                ),
                              ),
                              child: isFixed
                                  ? Semantics(
                                      label:
                                          'Stein ${index + 1}, liegt schon da',
                                      child: ExcludeSemantics(
                                        child: Center(
                                          child: _Counter(
                                            color: _gold,
                                            diameter: math.min(34, cell - 6),
                                          ),
                                        ),
                                      ),
                                    )
                                  : isMoved
                                      ? placedCounter(movedIndex, size: cell)
                                      : Semantics(
                                          label: 'Freier Platz ${index + 1}',
                                          child: const Center(
                                            child: _EmptySocket(),
                                          ),
                                        ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            }),
          ),
          if (overflow > 0) ...[
            const SizedBox(height: 12),
            const Text('Daneben abgelegt', style: _bodyStyle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                overflow,
                (index) => placedCounter(inFrame + index),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Vorrat · antippen und verschieben', style: _labelStyle),
          const SizedBox(height: 8),
          _InsetDeck(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: supply == placed
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Alle Steine liegen auf der Fläche.',
                          style: _bodyStyle),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(supply - placed, (offset) {
                        final index = placed + offset;
                        return _CounterButton(
                          key: ValueKey('quantity-bank-$index'),
                          label:
                              'Vorratsstein ${index + 1}, ins Feld verschieben',
                          color: _cyan,
                          onPressed: enabled ? () => move(1) : null,
                          reduceMotion: reduceMotion,
                        );
                      }),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ActionButton(
                key: const ValueKey('quantity-remove'),
                label: 'Einen Stein zurücklegen',
                reduceMotion: reduceMotion,
                icon: Icons.remove_rounded,
                text: 'Zurück',
                onPressed: enabled && placed > 0 ? () => move(-1) : null,
              ),
              _ActionButton(
                key: const ValueKey('quantity-add'),
                label: 'Einen Stein ins Feld verschieben',
                reduceMotion: reduceMotion,
                icon: Icons.add_rounded,
                text: 'Verschieben',
                onPressed: enabled && placed < supply ? () => move(1) : null,
              ),
            ],
          ),
          if (reveal) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text('Bis 10 fehlen ${10 - initial}.',
                  textAlign: TextAlign.center,
                  style: _labelStyle.copyWith(color: _gold)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A controlled fraction model with equal, independently selectable pieces.
///
/// A piece can be changed directly on the disc or with its numbered button.
/// Piece identities use zero-based indices; the UI counts from one.
class FractionBuildBoard extends StatelessWidget {
  const FractionBuildBoard({
    super.key,
    required this.denominator,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.reduceMotion = false,
  }) : assert(denominator >= 1 && denominator <= 8);

  final int denominator;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final pieces =
        selected.where((index) => index >= 0 && index < denominator).toSet();
    void toggle(int index) {
      final next = {...pieces};
      if (!next.add(index)) next.remove(index);
      onChanged(next);
    }

    return _LabSurface(
      accent: _gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BoardHeading(
            icon: Icons.pie_chart_rounded,
            title: 'Baue deinen Bruch',
            subtitle: 'Wähle gleich große Teile aus.',
            accent: _gold,
          ),
          const SizedBox(height: 16),
          _InsetDeck(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 264),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final diameter = constraints.maxWidth;
                    return Stack(
                      key: const ValueKey('fraction-disc'),
                      children: [
                        Positioned.fill(
                          top: 7,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF071327),
                              border: Border.all(
                                  color: const Color(0xFF405474), width: 2),
                            ),
                          ),
                        ),
                        for (var index = 0; index < denominator; index++)
                          Positioned.fill(
                            bottom: 7,
                            child: ClipPath(
                              clipper: _FractionClipper(index, denominator),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  excludeFromSemantics: true,
                                  canRequestFocus: false,
                                  onTap: enabled ? () => toggle(index) : null,
                                  splashColor: _gold.withValues(alpha: .16),
                                  highlightColor: _gold.withValues(alpha: .1),
                                  child: AnimatedContainer(
                                    duration: _duration(context, reduceMotion),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: pieces.contains(index)
                                            ? const [
                                                Color(0xFFFFE8A4),
                                                _gold,
                                                Color(0xFFE49B21),
                                              ]
                                            : const [
                                                Color(0xFF406183),
                                                Color(0xFF244569),
                                                Color(0xFF173353),
                                              ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          bottom: 7,
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _FractionRimPainter(denominator),
                            ),
                          ),
                        ),
                        for (var index = 0; index < denominator; index++)
                          Positioned(
                            left: diameter / 2 +
                                math.cos(-math.pi / 2 +
                                        (index + .5) *
                                            math.pi *
                                            2 /
                                            denominator) *
                                    diameter *
                                    .32 -
                                24,
                            top: (diameter - 7) / 2 +
                                math.sin(-math.pi / 2 +
                                        (index + .5) *
                                            math.pi *
                                            2 /
                                            denominator) *
                                    (diameter - 7) *
                                    .32 -
                                24,
                            child: IgnorePointer(
                              child: ExcludeSemantics(
                                child: SizedBox.square(
                                  dimension: 48,
                                  child: Center(
                                    child: Text('${index + 1}',
                                        style: _labelStyle.copyWith(
                                          fontSize: 16,
                                          color: pieces.contains(index)
                                              ? const Color(0xFF4F340A)
                                              : _ink,
                                        )),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Teile auswählen', style: _labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(denominator, (index) {
              return _TileButton(
                key: ValueKey('fraction-piece-$index'),
                label: 'Teil ${index + 1} von $denominator',
                selected: pieces.contains(index),
                accent: _gold,
                reduceMotion: reduceMotion,
                onPressed: enabled ? () => toggle(index) : null,
                child: Text('${index + 1}', style: _labelStyle),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tippe einen Teil erneut an, um ihn zurückzulegen.',
            textAlign: TextAlign.center,
            style: _bodyStyle,
          ),
        ],
      ),
    );
  }
}

/// A controlled word or sequence workbench; duplicate strings remain distinct.
///
/// [selected] contains source indices in the child's chosen order. A tap on a
/// placed tile removes that index without changing the other tiles' order.
class LearningTokenWorkbench extends StatelessWidget {
  const LearningTokenWorkbench({
    super.key,
    required this.tokens,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.reduceMotion = false,
  });

  final List<String> tokens;
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;
  final bool enabled;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    // Ignore stale or repeated indices without mutating caller-owned state.
    final seen = <int>{};
    final order = selected
        .where(
            (index) => index >= 0 && index < tokens.length && seen.add(index))
        .toList();
    final available = List.generate(tokens.length, (index) => index)
        .where((index) => !seen.contains(index))
        .toList();

    Widget token(int index, {required bool inWork}) => _TileButton(
          key: ValueKey('token-${inWork ? 'work' : 'bank'}-$index'),
          label: inWork
              ? '${tokens[index]}, Platz ${order.indexOf(index) + 1}, zurücklegen'
              : '${tokens[index]}, Baustein ${index + 1}, anlegen',
          accent: _violet,
          selected: inWork,
          reduceMotion: reduceMotion,
          onPressed: enabled
              ? () => onChanged(inWork
                  ? order.where((item) => item != index).toList()
                  : [...order, index])
              : null,
          child: Text(tokens[index],
              textAlign: TextAlign.center,
              softWrap: true,
              style: _labelStyle.copyWith(fontSize: 16)),
        );

    return _LabSurface(
      accent: _violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BoardHeading(
            icon: Icons.view_agenda_rounded,
            title: 'Deine Werkbank',
            subtitle: 'Lege die Bausteine in deine Reihenfolge.',
            accent: _violet,
          ),
          const SizedBox(height: 16),
          const Text('Deine Reihe', style: _labelStyle),
          const SizedBox(height: 8),
          _InsetDeck(
            child: AnimatedSize(
              duration: _duration(context, reduceMotion),
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 80),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: order.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(children: [
                            Icon(Icons.touch_app_rounded,
                                size: 22, color: _violet),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text('Hier beginnt deine Reihe.',
                                  style: _bodyStyle),
                            ),
                          ]),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final index in order)
                                token(index, inWork: true),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Bausteine · antippen und anlegen', style: _labelStyle),
          const SizedBox(height: 8),
          _InsetDeck(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: available.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Alle Bausteine liegen in deiner Reihe.',
                          style: _bodyStyle),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final index in available)
                          token(index, inWork: false),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tippe einen gelegten Baustein an, um ihn zurückzulegen.',
              textAlign: TextAlign.center, style: _bodyStyle),
        ],
      ),
    );
  }
}

class _LabSurface extends StatelessWidget {
  const _LabSurface({required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF153B63), Color(0xFF09294E), Color(0xFF061E40)],
          ),
          border: Border.all(color: accent.withValues(alpha: .35)),
          boxShadow: const [
            BoxShadow(color: Color(0xFF020F28), offset: Offset(0, 6)),
            BoxShadow(
                color: Color(0x33000000), offset: Offset(0, 8), blurRadius: 10),
          ],
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      );
}

class _BoardHeading extends StatelessWidget {
  const _BoardHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: .3)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: _labelStyle.copyWith(fontSize: 18), softWrap: true),
                const SizedBox(height: 4),
                Text(subtitle, style: _bodyStyle),
              ],
            ),
          ),
        ],
      );
}

class _InsetDeck extends StatelessWidget {
  const _InsetDeck({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF061B39), Color(0xFF102E50)],
          ),
          border: Border.all(color: const Color(0xFF385778)),
          boxShadow: const [
            BoxShadow(color: Color(0xFF3B5574), offset: Offset(0, 2)),
          ],
        ),
        child: Padding(padding: padding, child: child),
      );
}

class _Counter extends StatelessWidget {
  const _Counter({required this.color, this.diameter = 34});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) => Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.45, -.65),
            radius: 1.2,
            colors: [
              Color.lerp(color, Colors.white, .68)!,
              color,
              Color.lerp(color, const Color(0xFF092445), .44)!
            ],
            stops: const [0, .45, 1],
          ),
          border: Border.all(color: color.withValues(alpha: .9)),
          boxShadow: [
            BoxShadow(
                color: Color.lerp(color, const Color(0xFF04152C), .65)!,
                offset: const Offset(0, 4)),
            const BoxShadow(
                color: Color(0x66000000), offset: Offset(0, 6), blurRadius: 4),
          ],
        ),
        child: Center(
          child: Container(
            width: diameter * .65,
            height: diameter * .65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .4)),
            ),
          ),
        ),
      );
}

class _EmptySocket extends StatelessWidget {
  const _EmptySocket();

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0B2443),
          border: Border.all(color: const Color(0xFF294969)),
        ),
      );
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.reduceMotion,
    this.size,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool reduceMotion;
  final double? size;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          label: label,
          button: true,
          enabled: onPressed != null,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: Size(size ?? 48, 48),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              animationDuration: _duration(context, reduceMotion),
            ),
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _Counter(
                    color: color, diameter: math.min(34, (size ?? 48) - 6)),
              ),
            ),
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.text,
    required this.onPressed,
    required this.reduceMotion,
  });

  final String label;
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          label: label,
          button: true,
          enabled: onPressed != null,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              animationDuration: _duration(context, reduceMotion),
              foregroundColor: _ink,
              disabledForegroundColor: _muted.withValues(alpha: .45),
              backgroundColor: const Color(0xFF164779),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF3E78A4)),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 6),
                  Flexible(child: Text(text, style: _labelStyle)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TileButton extends StatelessWidget {
  const _TileButton({
    super.key,
    required this.label,
    required this.child,
    required this.onPressed,
    required this.selected,
    required this.accent,
    required this.reduceMotion,
  });

  final String label;
  final Widget child;
  final VoidCallback? onPressed;
  final bool selected;
  final Color accent;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          label: label,
          selected: selected,
          button: true,
          enabled: onPressed != null,
          child: AnimatedContainer(
            duration: _duration(context, reduceMotion),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [
                        Color.lerp(accent, const Color(0xFF17395C), .55)!,
                        Color.lerp(accent, const Color(0xFF0B2244), .77)!,
                      ]
                    : const [Color(0xFF2B4D74), Color(0xFF173657)],
              ),
              border: Border.all(
                  color: selected ? accent : const Color(0xFF597494),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: selected
                        ? Color.lerp(accent, const Color(0xFF04152C), .8)!
                        : const Color(0xFF081931),
                    offset: const Offset(0, 4)),
              ],
            ),
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                animationDuration: _duration(context, reduceMotion),
                foregroundColor: _ink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      );
}

Path _fractionPath(Size size, int index, int denominator) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2 - 2;
  if (denominator == 1) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }
  final start = -math.pi / 2 + index * math.pi * 2 / denominator;
  final sweep = math.pi * 2 / denominator;
  return Path()
    ..moveTo(center.dx, center.dy)
    ..lineTo(center.dx + math.cos(start) * radius,
        center.dy + math.sin(start) * radius)
    ..arcTo(
        Rect.fromCircle(center: center, radius: radius), start, sweep, false)
    ..close();
}

class _FractionClipper extends CustomClipper<Path> {
  const _FractionClipper(this.index, this.denominator);

  final int index;
  final int denominator;

  @override
  Path getClip(Size size) => _fractionPath(size, index, denominator);

  @override
  bool shouldReclip(covariant _FractionClipper oldClipper) =>
      oldClipper.index != index || oldClipper.denominator != denominator;
}

class _FractionRimPainter extends CustomPainter {
  const _FractionRimPainter(this.denominator);

  final int denominator;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A2542)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var index = 0; index < denominator; index++) {
      canvas.drawPath(_fractionPath(size, index, denominator), paint);
    }
    final radius = math.min(size.width, size.height) / 2 - 2;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2), radius: radius - 1),
      -math.pi * .95,
      math.pi * .8,
      false,
      Paint()
        ..color = const Color(0x88EDF8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _FractionRimPainter oldDelegate) =>
      oldDelegate.denominator != denominator;
}
