import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/lumo_companion_host.dart';
import '../fox/lumo_companion_requests.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../fox/lumo_character.dart';
import 'lumo_design_system.dart';
import 'lumo_motion.dart';

/// Presentation only. Task generation, answer evaluation, storage leases and
/// rewards remain owned by the existing learning module and its progress scope.
class LumoLearningModuleFrame extends StatefulWidget {
  const LumoLearningModuleFrame({
    super.key,
    required this.appState,
    required this.title,
    required this.moduleTitle,
    required this.icon,
    required this.taskIndex,
    required this.totalTasks,
    required this.correctAnswers,
    required this.canLeave,
    required this.child,
    this.progressLabel = 'Aufgabe',
    this.hasMistake = false,
    this.scrollable = true,
    this.characterController,
    this.correctCaption = 'richtig',
    this.progressComplete = false,
    this.onNavigate,
    this.scrollResetKey,
    this.footer,
    this.guidance = 'Gemeinsam schaffen wir das!',
    this.mistakeGuidance = 'Fehler helfen beim Lernen.',
    this.companionUnit,
  });

  final LumoAppState appState;
  final String title;
  final String moduleTitle;
  final IconData icon;
  final int taskIndex;
  final int totalTasks;
  final int correctAnswers;
  final String progressLabel;
  final bool hasMistake;
  final bool scrollable;
  final LumoCharacterController? characterController;
  final String correctCaption;
  final bool progressComplete;
  final Future<void> Function(LumoSection section)? onNavigate;
  final Object? scrollResetKey;
  final Widget? footer;
  final String guidance;
  final String mistakeGuidance;
  final String? companionUnit;
  final bool Function() canLeave;
  final Widget child;

  @override
  State<LumoLearningModuleFrame> createState() =>
      _LumoLearningModuleFrameState();
}

class _LumoLearningModuleFrameState extends State<LumoLearningModuleFrame> {
  late final _lumo = widget.characterController ?? LumoCharacterController();
  final _taskScroll = ScrollController();
  ScrollController? get _scrollController =>
      widget.scrollResetKey == null ? null : _taskScroll;
  String get _guidance =>
      widget.hasMistake ? widget.mistakeGuidance : widget.guidance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.characterController != null) return;
      if (!LumoLessonStyle.reducedMotion(context, widget.appState)) {
        _lumo.hello();
      }
    });
  }

  @override
  void didUpdateWidget(covariant LumoLearningModuleFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollResetKey != null &&
        widget.scrollResetKey != oldWidget.scrollResetKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _taskScroll.hasClients) _taskScroll.jumpTo(0);
      });
    }
    // Plus already emits its genuine answer reactions through this controller.
    // Do not create a second success/error stream for that established module.
    if (widget.characterController != null) return;
    final celebrate = widget.correctAnswers > oldWidget.correctAnswers;
    final comfort = widget.hasMistake && !oldWidget.hasMistake;
    if (!celebrate && !comfort) return;
    // A correct count is incremented by the module only after its real save.
    // Do not manufacture success from a timer, animation or selected answer.
    final task = widget.taskIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.taskIndex != task) return;
      if (celebrate) {
        _lumo.cheer();
      } else {
        _lumo.comfort();
      }
    });
  }

  @override
  void dispose() {
    _taskScroll.dispose();
    if (widget.characterController == null) _lumo.dispose();
    super.dispose();
  }

  Future<void> _leaveTo(LumoSection section) async {
    if (!widget.canLeave()) return;
    final navigate = widget.onNavigate;
    if (navigate != null) {
      await navigate(section);
      return;
    }
    final app = widget.appState;
    final popped = await Navigator.of(context).maybePop();
    if (popped && section != LumoSection.learn) {
      app.setSection(section);
    }
  }

  Widget _hero({required bool wide, double availableHeight = double.infinity}) {
    final quiet = LumoLessonStyle.reducedMotion(context, widget.appState);
    return LayoutBuilder(builder: (context, constraints) {
      if (wide) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LumoCharacter(
              key: const ValueKey('learning-module-lumo'),
              pose: LumoDesignFoxPose.bookPoint,
              controller: _lumo,
              size: (constraints.maxWidth * .84).clamp(150.0, 300.0),
              reduceMotion: quiet,
              idleHops: false,
              onTap: _requestHelp,
            ),
            const SizedBox(height: 12),
            LumoGlassCard(
              surfaceOpacity: LumoLessonStyle.glassOpacity,
              padding: const EdgeInsets.all(16),
              child: Text(
                _guidance,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: LumoVisualTokens.white,
                ),
              ),
            ),
          ],
        );
      }
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.35;
      if (largeText) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              LumoCharacter(
                key: const ValueKey('learning-module-lumo'),
                pose: LumoDesignFoxPose.bookPoint,
                controller: _lumo,
                size: 108,
                reduceMotion: quiet,
                idleHops: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _guidance,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LumoVisualTokens.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Keep the complete original pose below the profile header. A larger
      // image in a shorter Stack previously hid the forehead behind that bar.
      final foxSize = availableHeight < 620 ? 112.0 : 132.0;
      return SizedBox(
        height: foxSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: (constraints.maxWidth - foxSize) / 2,
              bottom: 0,
              child: LumoCharacter(
                key: const ValueKey('learning-module-lumo'),
                pose: LumoDesignFoxPose.bookPoint,
                controller: _lumo,
                size: foxSize,
                reduceMotion: quiet,
                idleHops: false,
                onTap: _requestHelp,
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              width: constraints.maxWidth * .28,
              child: LumoHeroBubble(
                text: _guidance,
                handwritten: true,
              ),
            ),
            Positioned(
              right: 12,
              top: 26,
              width: constraints.maxWidth * .23,
              child: const LumoHeroBubble(
                text: 'Kleine Schritte. Große Zukunft!',
                handwritten: true,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _requestHelp() {
    final task = LumoCompanionRequests.instance.taskContext.value;
    if (task == null ||
        task.unit != (widget.companionUnit ?? widget.moduleTitle) ||
        !task.answering ||
        task.isExam ||
        task.profileGeneration != widget.appState.profileGeneration ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    LumoCompanionRequests.instance.requestTaskHelp();
  }

  Widget _helpOffer() => LumoCompanionHost(
      appState: widget.appState,
      section: 'learn',
      taskUnit: widget.companionUnit ?? widget.moduleTitle,
      offerOnly: true,
      onSection: _leaveTo);

  Widget _progress() {
    final index = widget.taskIndex.clamp(0, widget.totalTasks - 1);
    final complete = widget.progressComplete ? 1.0 : index / widget.totalTasks;
    final quiet = LumoLessonStyle.reducedMotion(context, widget.appState);
    return Semantics(
      label: '${widget.progressLabel} ${index + 1} von ${widget.totalTasks}, '
          '${widget.correctAnswers} ${widget.correctCaption}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                '${widget.progressLabel} ${index + 1} / ${widget.totalTasks}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: LumoVisualTokens.white,
                ),
              ),
              Text(
                '${widget.correctAnswers} ${widget.correctCaption}',
                key: const ValueKey('learning-module-correct-count'),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: LumoVisualTokens.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: complete),
              duration: quiet ? Duration.zero : LumoMotion.value,
              builder: (context, value, _) => LinearProgressIndicator(
                key: const ValueKey('learning-module-progress'),
                value: value,
                minHeight: 8,
                backgroundColor: LumoVisualTokens.glassRow,
                color: LumoVisualTokens.cyanBright,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({bool fill = false}) {
    final contents = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            key: const ValueKey('learning-module-back'),
            tooltip: 'Zur Lernübersicht',
            onPressed: () => _leaveTo(LumoSection.learn),
            style: IconButton.styleFrom(
              backgroundColor: LumoVisualTokens.lessonAnswer,
              foregroundColor: LumoVisualTokens.white,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon,
                        size: 18, color: LumoVisualTokens.cyanBright),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: LumoVisualTokens.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.moduleTitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LumoVisualTokens.cyanBright,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _progress(),
      const SizedBox(height: 10),
      _helpOffer(),
      if (fill) Expanded(child: widget.child) else widget.child,
    ];
    return LumoGlassCard(
      key: const ValueKey('learning-module-adventure-card'),
      surfaceOpacity: LumoLessonStyle.glassOpacity,
      padding: const EdgeInsets.all(12),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: contents,
      ),
    );
  }

  Widget _fixedCard(double availableHeight) => availableHeight >= 440
      ? _card(fill: true)
      : SingleChildScrollView(
          child: SizedBox(height: 560, child: _card(fill: true)),
        );

  // Short landscape has its own task area. The portrait profile/header and
  // global navigation consumed most of its height; the real back action keeps
  // the overview reachable and still respects the module's pending save.
  Widget _landscape() => LayoutBuilder(builder: (context, constraints) {
        return _LumoLessonViewport(
          height: constraints.maxHeight - 24,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 136,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Zur Lernübersicht',
                          onPressed: () => _leaveTo(LumoSection.learn),
                          style: IconButton.styleFrom(
                            backgroundColor: LumoVisualTokens.lessonAnswer,
                            foregroundColor: LumoVisualTokens.white,
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(height: 6),
                        Text(widget.moduleTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: LumoVisualTokens.white)),
                        LumoCharacter(
                          key: const ValueKey('learning-module-lumo'),
                          pose: LumoDesignFoxPose.bookPoint,
                          controller: _lumo,
                          size: 92,
                          reduceMotion: LumoLessonStyle.reducedMotion(
                              context, widget.appState),
                          idleHops: false,
                        ),
                        _progress(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: LumoGlassCard(
                      key: const ValueKey('learning-module-adventure-card'),
                      surfaceOpacity: LumoLessonStyle.glassOpacity,
                      padding: const EdgeInsets.all(12),
                      radius: 26,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _helpOffer(),
                        widget.scrollable
                            ? widget.child
                            : SizedBox(height: 440, child: widget.child),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    final quiet = LumoLessonStyle.reducedMotion(context, widget.appState);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: quiet),
      child: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        body: LumoSceneBackground(
          scene: LumoScene.library,
          dimmed: true,
          child: SafeArea(
            child: LumoLessonStyle.shortLandscape(context)
                ? _landscape()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: LumoTopBar(appState: widget.appState),
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return _LumoLessonViewport(
                              height: constraints.maxHeight - 28,
                              child: Builder(builder: (context) {
                                final wide = constraints.maxWidth >= 760;
                                final compactLandscape =
                                    constraints.maxHeight < 400 &&
                                        constraints.maxWidth >= 560;
                                if (wide || compactLandscape) {
                                  return Center(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 1240),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 12, 20, 16),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              flex: compactLandscape ? 1 : 2,
                                              child: SingleChildScrollView(
                                                child: _hero(wide: true),
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            Expanded(
                                              flex: compactLandscape ? 3 : 5,
                                              child: widget.scrollable
                                                  ? SingleChildScrollView(
                                                      controller:
                                                          _scrollController,
                                                      child: _card())
                                                  : _fixedCard(
                                                      constraints.maxHeight -
                                                          28),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                if (!widget.scrollable) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 8, 12, 12),
                                    child:
                                        _fixedCard(constraints.maxHeight - 20),
                                  );
                                }
                                return SingleChildScrollView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    children: [
                                      _hero(
                                          wide: false,
                                          availableHeight:
                                              constraints.maxHeight),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: _card(),
                                      ),
                                    ],
                                  ),
                                );
                              }));
                        }),
                      ),
                      if (widget.footer != null) widget.footer!,
                      LumoBottomNavigation(
                        active: LumoSection.learn,
                        onSelect: _leaveTo,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Geometry only. The post-SafeArea space is authoritative even when a
/// device folds or Android system bars change; no learning state is stored.
class _LumoLessonViewport extends InheritedWidget {
  const _LumoLessonViewport({required this.height, required super.child});
  final double height;
  @override
  bool updateShouldNotify(_LumoLessonViewport oldWidget) =>
      oldWidget.height != height;
}

/// Small extensions to the existing Lumo tokens, not a second theme or state
/// architecture. Semantic feedback colors remain supplied by each module.
abstract final class LumoLessonStyle {
  static const glassOpacity = .90;

  static bool shortLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 560 && size.height < 480;
  }

  static double viewportHeight(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_LumoLessonViewport>()
          ?.height ??
      MediaQuery.sizeOf(context).height;

  static bool reducedMotion(BuildContext context, LumoAppState app) =>
      app.state.settings.reduceAnimations ||
      app.state.settings.calmMode ||
      LumoMotion.reduced(context);

  static BoxDecoration answer({
    required Color background,
    required Color border,
    double radius = 20,
  }) =>
      BoxDecoration(
        color: background,
        gradient: background == LumoVisualTokens.lessonAnswer
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LumoVisualTokens.lessonAnswer,
                  LumoVisualTokens.lessonAnswerDeep,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: .2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );
}

/// Keep the pictured problem beside its choices on short landscape displays.
/// Large text retains a vertically scrolling layout instead of shrinking type.
class LumoLessonTaskLayout extends StatelessWidget {
  const LumoLessonTaskLayout({
    super.key,
    required this.task,
    required this.answers,
    this.spacing = 16,
  });
  final Widget task;
  final Widget answers;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (LumoLessonStyle.shortLandscape(context) &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.35) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: task),
          const SizedBox(width: 12),
          Expanded(child: answers),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [task, SizedBox(height: spacing), answers],
    );
  }
}

class LumoLessonSurface extends StatelessWidget {
  const LumoLessonSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        width: double.infinity,
        decoration: BoxDecoration(
          color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: LumoVisualTokens.cyan.withValues(alpha: .6),
          ),
        ),
        child: child,
      );
}

/// Keeps the established 2 x 2 answer choice, but derives readable tile height
/// from the actual card width and text scaling instead of stretching a phone
/// grid over a tablet or shrinking every label into a FittedBox.
class LumoLessonAnswerGrid extends StatelessWidget {
  const LumoLessonAnswerGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 1.8,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.minimumHeight = 68,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics physics;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth =
              (constraints.maxWidth - (crossAxisCount - 1) * crossAxisSpacing) /
                  crossAxisCount;
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final availableHeight = LumoLessonStyle.viewportHeight(context);
          final maxHeight = constraints.maxWidth < 500
              ? availableHeight < 660
                  ? 72.0
                  : 84.0
              : availableHeight < 610
                  ? 88.0
                  : 112.0;
          final tileHeight = (tileWidth / childAspectRatio)
              .clamp(minimumHeight * textScale, maxHeight * textScale);
          return GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: tileWidth / tileHeight,
            shrinkWrap: shrinkWrap,
            physics: physics,
            children: children,
          );
        },
      );
}

/// Real Material arrow, independent of Unicode fallback fonts. Numbers and
/// their order are supplied by the existing exercise, not computed here.
class LumoLessonNumberFlow extends StatelessWidget {
  const LumoLessonNumberFlow({
    super.key,
    required this.before,
    required this.after,
    this.fontSize = 48,
  });

  final String before;
  final String after;
  final double fontSize;

  @override
  Widget build(BuildContext context) => LumoLessonSurface(
        child: Semantics(
          label: '$before, danach $after',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(before,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 32, color: LumoVisualTokens.cyanBright),
                ),
                Text(after,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white)),
              ],
            ),
          ),
        ),
      );
}

class LumoLessonAnswerTap extends StatelessWidget {
  const LumoLessonAnswerTap({
    super.key,
    required this.onTap,
    required this.child,
    this.correct,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool? correct;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: correct == null
            ? null
            : correct!
                ? 'Richtige Antwort'
                : 'Noch nicht richtig',
        child: LumoPressable(
          enabled: onTap != null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    child,
                    if (correct != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Icon(
                          correct!
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 19,
                          color: correct!
                              ? const Color(0xFF065F46)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
