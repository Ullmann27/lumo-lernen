import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/design/lumo_night_scope.dart';

/// Shared presentation for the voluntary cross-grade learning routes.
///
/// Keep curriculum generation, XP, enrolment and local persistence in the
/// owning screens. This widget only supplies the existing approved library
/// scene, glass treatment and a real Lumo pose from the project's assets.
class CrossGradeVisualScene extends StatelessWidget {
  const CrossGradeVisualScene({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) => LumoNightScope(
        child: LumoSceneBackground(
          scene: LumoScene.library,
          dimmed: true,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor:
                  LumoVisualTokens.navigation.withValues(alpha: .94),
              foregroundColor: LumoVisualTokens.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            body: body,
          ),
        ),
      );
}

/// The original illustrated Lumo guides children without covering controls.
/// Existing official artwork is intentionally reused, never redrawn.
class CrossGradeLumoHeader extends StatelessWidget {
  const CrossGradeLumoHeader({
    super.key,
    required this.child,
    this.foxPose = LumoDesignFoxPose.bookPoint,
  });

  final Widget child;
  final LumoDesignFoxPose foxPose;

  @override
  Widget build(BuildContext context) => LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: child),
            const SizedBox(width: 5),
            RepaintBoundary(
              child: LumoFoxPose(pose: foxPose, size: 84),
            ),
          ],
        ),
      );
}

/// Same glass geometry as the main Learning screen. Does not create an
/// overlay or pointer listener, so the complete answer and save area remains
/// accessible even on a narrow Fold cover display.
class CrossGradeGlassPanel extends StatelessWidget {
  const CrossGradeGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => LumoGlassCard(
        padding: padding,
        color: LumoVisualTokens.glass,
        child: child,
      );
}

/// Real voluntary practice progress only: this never grants or displays XP.
class CrossGradeProgressRibbon extends StatelessWidget {
  const CrossGradeProgressRibbon({
    super.key,
    required this.answered,
    required this.correct,
  });

  final int answered;
  final int correct;

  @override
  Widget build(BuildContext context) {
    final total = answered < 0 ? 0 : answered;
    final solved = correct.clamp(0, total);
    final ratio = total == 0 ? 0.0 : solved / total;
    final percent = (ratio * 100).round();
    final disableMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      label: 'Richtig beantwortete freiwillige Übungen',
      value: '$solved von $total, $percent Prozent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFF6CF76), size: 17),
              const SizedBox(width: 7),
              const Expanded(
                child: Text('Dein Übungsfortschritt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              Text('$percent %',
                  key: const ValueKey('cross-grade-progress-percent'),
                  style: const TextStyle(
                      color: Color(0xFF65E6FC),
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: disableMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                key: const ValueKey('cross-grade-progress-bar'),
                minHeight: 8,
                value: value,
                backgroundColor: const Color(0xFF163658),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF47DDFC)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
