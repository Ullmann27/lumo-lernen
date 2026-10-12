import 'package:flutter/material.dart';

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
            colors: [Color(0xFFDFEFF1), Color(0xFFE4E8FA), Color(0xFFF3E9D8)],
          ),
        ),
        child: Stack(fit: StackFit.expand, children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Opacity(
                  opacity: .19,
                  child: Image.asset('assets/lumo_design/bg/bg_games.png',
                      fit: BoxFit.cover, filterQuality: FilterQuality.medium),
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
        colors: [Color(0xF7FFFFFF), Color(0xE3EDF5FA)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: accent.withValues(alpha: .45), width: 1.5),
      boxShadow: [
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
                child: child,
              ),
            ),
          ),
        ),
      );
}
