import 'package:flutter/material.dart';

/// Ink belongs to the pale task cards, independent of the app's night palette.
abstract final class LumoBoardColors {
  static const backdrop = Color(0xFF06162F);
  static const ink = Color(0xFF17334B);
  static const mutedInk = Color(0xFF48627B);
  static const cyan = Color(0xFF64DFFF);
  static const gold = Color(0xFFFFD66B);
  static const action = Color(0xFF0D718F);
}

Duration lumoBoardMotionDuration(BuildContext context,
        {bool reduceMotion = false,
        Duration duration = const Duration(milliseconds: 180)}) =>
    reduceMotion || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : duration;

/// Original world art beneath quiet, readable game surfaces. No backdrop blur
/// or extra runtime renderer; foreground quantities stay visually distinct.
class LumoBoardGameStage extends StatelessWidget {
  const LumoBoardGameStage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF102C50),
              LumoBoardColors.backdrop,
              Color(0xFF0C2446)
            ],
          ),
        ),
        child: Stack(fit: StackFit.expand, children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Opacity(
                  opacity: .34,
                  child: Image.asset('assets/lumo_design/bg/bg_games.png',
                      fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x25071632), Color(0xB306162F)],
                  ),
                ),
              ),
            ),
          ),
          child,
        ]),
      );
}

BoxDecoration lumoBoardGlass({Color accent = const Color(0xFF449FB3)}) =>
    BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFCFEFF), Color(0xFFF0F7FC)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: accent.withValues(alpha: .55), width: 1.5),
      boxShadow: [
        const BoxShadow(
            color: Color(0x50010A1E), blurRadius: 24, offset: Offset(0, 10)),
        BoxShadow(
            color: accent.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 8)),
      ],
    );

/// Scrollable task surface for small displays and larger text. Its child has
/// no flex children: the actual task, grid and answer remain reachable by swipe.
class LumoScrollableBoardPage extends StatelessWidget {
  const LumoScrollableBoardPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LumoBoardGameStage(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: lumoBoardGlass(),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
}

/// A shared round track driven entirely by the active game's real counters.
/// Completed steps have a check, the current step a number and cyan outline.
class LumoBoardRoundProgress extends StatelessWidget {
  const LumoBoardRoundProgress({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.correct,
    this.label = 'Aufgabe',
    this.reduceMotion = false,
  });

  final int currentIndex;
  final int total;
  final int correct;
  final String label;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final current = (currentIndex + 1).clamp(1, total);
    final duration = reduceMotion || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      label: '$label $current von $total, $correct richtig',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF173B60), Color(0xFF0C2445)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x8064DFFF)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x38010A1E), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: Text('$label $current / $total',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white)),
            ),
            const Icon(Icons.star_rounded,
                size: 19, color: LumoBoardColors.gold),
            const SizedBox(width: 4),
            Text('$correct',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: LumoBoardColors.gold)),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            for (var index = 0; index < total; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  key: ValueKey('board-round-step-$index'),
                  duration: duration,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index < currentIndex
                        ? LumoBoardColors.gold
                        : index == currentIndex
                            ? const Color(0xFF246B8B)
                            : const Color(0xFF193858),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: index == currentIndex
                            ? LumoBoardColors.cyan
                            : const Color(0x303B91BA)),
                  ),
                  child: index < currentIndex
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: LumoBoardColors.ink)
                      : Text('${index + 1}',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: index == currentIndex
                                  ? Colors.white
                                  : const Color(0xFF9DB6D2))),
                ),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}
