import 'package:flutter/material.dart';
import 'package:clock/clock.dart';

import '../../app/app_state.dart';
import '../../app/lumo_companion_host.dart';
import '../../core/lumo_companion_guide.dart';
import '../../features/learning_modules/learning_module_progress.dart';
import '../fox/lumo_companion_requests.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../fox/lumo_character.dart';
import 'lumo_design_system.dart';
import 'lumo_motion.dart';
import 'lumo_lesson_progress.dart';

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
    this.companionGuide,
    this.immersive = false,
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
  final LumoCompanionGuide? companionGuide;

  /// The task owns its character stage; retain the same navigation and progress.
  final bool immersive;
  final bool Function() canLeave;
  final Widget child;

  @override
  State<LumoLearningModuleFrame> createState() =>
      _LumoLearningModuleFrameState();
}

class _LumoLearningModuleFrameState extends State<LumoLearningModuleFrame> {
  late final _guide =
      widget.companionGuide ?? LumoCompanionGuide(now: clock.now());
  late final _lumo = widget.characterController ?? LumoCharacterController();
  final _taskScroll = ScrollController();
  late final _profileGeneration = widget.appState.profileGeneration;
  Object? _presentedTask;
  int _methodHelpLevel = 0;
  bool _quiet = false;
  bool _helpOpen = false;
  bool get _reduced =>
      _quiet || LumoLessonStyle.reducedMotion(context, widget.appState);
  LearningModuleProgress? get _moduleProgress => context
      .findAncestorWidgetOfExactType<LearningModuleProgressScope>()
      ?.progress;
  _ModuleMethod get _method => _ModuleMethod.forTitle(widget.moduleTitle);
  ScrollController? get _scrollController =>
      widget.scrollResetKey == null ? null : _taskScroll;
  String get _guidance => widget.hasMistake
      ? widget.mistakeGuidance
      : widget.guidance == 'Gemeinsam schaffen wir das!'
          ? 'Dein Ziel: ${_method.goal}'
          : widget.guidance;

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
    final quiet = _reduced;
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
    if (_helpOpen ||
        !widget.canLeave() ||
        widget.progressComplete ||
        widget.appState.resetting ||
        widget.appState.profileGeneration != _profileGeneration ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    final task = LumoCompanionRequests.instance.taskContext.value;
    if (task != null &&
        task.unit == (widget.companionUnit ?? widget.moduleTitle) &&
        task.answering &&
        !task.isExam &&
        task.profileGeneration == widget.appState.profileGeneration) {
      // A module with an exact current-task contract owns its targeted help.
      _moduleProgress?.notePresentationHelp();
      LumoCompanionRequests.instance.requestTaskHelp();
      return;
    }
    final progress = _moduleProgress;
    if (progress == null) return;
    _methodHelpLevel = (_methodHelpLevel + 1).clamp(1, 3);
    progress.notePresentationHelp(level: _methodHelpLevel);
    _helpOpen = true;
    // The frame only knows the method. Exact quantities and answers remain
    // with the real task owner; they are never guessed from a module title.
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: LumoVisualTokens.lessonAnswer,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .6),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('LUMO · Schritt $_methodHelpLevel von 3',
                      style: const TextStyle(
                          color: LumoVisualTokens.cyanBright,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text('Lernziel: ${_method.goal}',
                      key: const ValueKey('learning-module-goal'),
                      style: const TextStyle(
                          color: LumoVisualTokens.cyanBright,
                          fontSize: 14,
                          height: 1.3)),
                  const SizedBox(height: 10),
                  Semantics(
                      liveRegion: true,
                      child: Text(_method.hints[_methodHelpLevel - 1],
                          key: const ValueKey('learning-module-method-hint'),
                          style: const TextStyle(
                              color: LumoVisualTokens.white,
                              fontSize: 18,
                              height: 1.4))),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                      key: const ValueKey('learning-module-self-try'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.touch_app_rounded),
                      label: const Text('Ich möchte es selbst versuchen')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                      key: const ValueKey('learning-module-alternative-help'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48)),
                      onPressed: () => updateSheet(() {
                            _methodHelpLevel = _methodHelpLevel % 3 + 1;
                            progress.notePresentationHelp(
                                level: _methodHelpLevel);
                          }),
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Anders erklären')),
                ]),
          ),
        ),
      ),
    ).whenComplete(() {
      _helpOpen = false;
      if (mounted) setState(() {});
    });
  }

  Widget _learningMenu() => SizedBox(
        width: 48,
        height: 48,
        child: PopupMenuButton<String>(
          key: const ValueKey('learning-module-tools'),
          tooltip: 'Lernhilfe und ruhiger Modus',
          color: LumoVisualTokens.lessonAnswer,
          icon: Icon(
              _quiet
                  ? Icons.self_improvement_rounded
                  : Icons.lightbulb_outline_rounded,
              color: Colors.white),
          onSelected: (value) {
            if (value == 'help') {
              _requestHelp();
            } else {
              setState(() => _quiet = !_quiet);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                key: const ValueKey('learning-module-help'),
                value: 'help',
                enabled: !widget.progressComplete,
                child: const Text('Hilf mir',
                    style: TextStyle(color: Colors.white))),
            PopupMenuItem(
                key: const ValueKey('learning-module-calm'),
                value: 'calm',
                child: Text(
                    _quiet ? 'Ruhiger Modus ist aktiv' : 'Ruhiger Modus',
                    style: const TextStyle(color: Colors.white))),
          ],
        ),
      );

  Widget _helpOffer() => LumoCompanionHost(
      guide: _guide,
      appState: widget.appState,
      section: 'learn',
      taskUnit: widget.companionUnit ?? widget.moduleTitle,
      offerOnly: true,
      onSection: _leaveTo);

  Widget _progress() {
    final index = widget.taskIndex.clamp(0, widget.totalTasks - 1);
    final complete = widget.progressComplete ? 1.0 : index / widget.totalTasks;
    final quiet = _reduced;
    if (MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical <
            900 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.35) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: const Color(0xB3051836),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .3))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(
                    '${widget.progressLabel} ${index + 1} / ${widget.totalTasks}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: LumoVisualTokens.white)),
                Text('${widget.correctAnswers} ${widget.correctCaption}',
                    key: const ValueKey('learning-module-correct-count'),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: LumoVisualTokens.gold)),
              ]),
          const SizedBox(height: 4),
          SizedBox(
              height: 8,
              child: LumoLessonProgress(
                  key: const ValueKey('learning-module-progress'),
                  value: complete,
                  totalTasks: widget.totalTasks,
                  reduceMotion: quiet)),
        ]),
      );
    }
    return Semantics(
      label: '${widget.progressLabel} ${index + 1} von ${widget.totalTasks}, '
          '${widget.correctAnswers} ${widget.correctCaption}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xB3051836),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: LumoVisualTokens.cyan.withValues(alpha: .3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF163650),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: LumoVisualTokens.gold.withValues(alpha: .4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: LumoVisualTokens.gold,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                          child: Text(
                        '${widget.correctAnswers} ${widget.correctCaption}',
                        key: const ValueKey('learning-module-correct-count'),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: LumoVisualTokens.gold,
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            LumoLessonProgress(
              key: const ValueKey('learning-module-progress'),
              value: complete,
              totalTasks: widget.totalTasks,
              reduceMotion: quiet,
            ),
          ],
        ),
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
              side: BorderSide(
                color: LumoVisualTokens.cyan.withValues(alpha: .35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                  ),
                ),
                const SizedBox(height: 4),
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
          _learningMenu(),
        ],
      ),
      const SizedBox(height: 8),
      _progress(),
      const SizedBox(height: 10),
      _helpOffer(),
      if (fill) Expanded(child: widget.child) else widget.child,
    ];
    if (widget.immersive) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: contents),
      );
    }
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
                          reduceMotion: _reduced,
                          idleHops: false,
                        ),
                        _progress(),
                        _learningMenu(),
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
    final key = (
      widget.moduleTitle,
      widget.taskIndex,
      widget.scrollResetKey,
      _profileGeneration
    );
    if (_presentedTask != key) {
      _presentedTask = key;
      _methodHelpLevel = 0;
    }
    _moduleProgress?.beginPresentedTask(key);
    final quiet = _reduced;
    return Listener(
      onPointerDown: (_) => LumoCompanionRequests.instance.noteActivity(),
      onPointerMove: (_) => LumoCompanionRequests.instance.noteActivity(),
      onPointerSignal: (_) => LumoCompanionRequests.instance.noteActivity(),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: quiet),
        child: Scaffold(
          backgroundColor: LumoVisualTokens.night,
          body: LumoSceneBackground(
            scene: LumoScene.library,
            backgroundAsset: widget.immersive
                ? 'assets/lumo_design/bg/bg_glass_islands.png'
                : null,
            dimmed: true,
            child: SafeArea(
              child: widget.immersive
                  ? Column(children: [
                      Expanded(
                          child: LayoutBuilder(
                              builder: (context, bounds) => _LumoLessonViewport(
                                    height: bounds.maxHeight,
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      child: Center(
                                          child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 900),
                                              child: _card())),
                                    ),
                                  ))),
                      if (widget.footer != null) widget.footer!,
                      LumoBottomNavigation(
                          active: LumoSection.learn, onSelect: _leaveTo),
                    ])
                  : LumoLessonStyle.shortLandscape(context)
                      ? _landscape()
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Align(
                                alignment: Alignment.center,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 900),
                                  child: LumoTopBar(appState: widget.appState),
                                ),
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                  builder: (context, constraints) {
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
                                            constraints: const BoxConstraints(
                                                maxWidth: 1240),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      20, 12, 20, 16),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    flex: compactLandscape
                                                        ? 1
                                                        : 2,
                                                    child:
                                                        SingleChildScrollView(
                                                      child: _hero(wide: true),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 24),
                                                  Expanded(
                                                    flex: compactLandscape
                                                        ? 3
                                                        : 5,
                                                    child: widget.scrollable
                                                        ? SingleChildScrollView(
                                                            controller:
                                                                _scrollController,
                                                            child: _card())
                                                        : _fixedCard(constraints
                                                                .maxHeight -
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
                                          child: _fixedCard(
                                              constraints.maxHeight - 20),
                                        );
                                      }
                                      return SingleChildScrollView(
                                        controller: _scrollController,
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: Column(
                                          children: [
                                            _hero(
                                                wide: false,
                                                availableHeight:
                                                    constraints.maxHeight),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
      ),
    );
  }
}

/// Method hints never reveal or invent the current problem's answer.
class _ModuleMethod {
  const _ModuleMethod(this.goal, this.hints);
  final String goal;
  final List<String> hints;

  static _ModuleMethod forTitle(String title) => switch (title) {
        'Plus bis 10' =>
          const _ModuleMethod('Mengen zusammenlegen und zählen.', [
            'Sieh dir die erste Menge und die zweite Menge einzeln an.',
            'Beginne mit der ersten Zahl. Zähle für jedes Objekt der zweiten Menge einen Schritt weiter.',
            'Lege für jede der beiden Zahlen entsprechend viele Finger oder Plättchen. Zähle dann jedes genau einmal.',
          ]),
        'Minus bis 10' =>
          const _ModuleMethod('Wegnehmen und die übrige Menge bestimmen.', [
            'Wie viele sind am Anfang da? Wie viele werden weggenommen?',
            'Markiere oder verdecke genau die Menge, die weggenommen wird.',
            'Zähle nur die Dinge, die übrig bleiben. Die weggenommenen zählst du nicht mehr mit.',
          ]),
        'Zahlen bis 10' => const _ModuleMethod(
              'Mengen, Zahlwörter und Nachbarzahlen verbinden.', [
            'Lies zuerst genau: Sollst du zählen, vergleichen oder die nächste Zahl finden?',
            'Gehe die Zahlen der Reihe nach durch. Jede Menge gehört zu genau einer Anzahl.',
            'Nutze deine Finger oder zeichne Punkte. Zähle jeden Punkt nur einmal und vergleiche mit der Frage.',
          ]),
        'Zahlen bis 100' => const _ModuleMethod(
              'Zehner und Einer erkennen und Zahlen vergleichen.', [
            'Betrachte zuerst die Zehnerstelle, danach die Einerstelle.',
            'Ein Zehner steht für zehn Einer. Zerlege die Zahl in Zehner und Einer.',
            'Stelle die Zahlen mit Zehnerbündeln und einzelnen Punkten dar. Prüfe damit die Frage.',
          ]),
        'Die Uhr' =>
          const _ModuleMethod('Stunden- und Minutenzeiger unterscheiden.', [
            'Finde den kurzen Stundenzeiger und den langen Minutenzeiger.',
            'Der Minutenzeiger zählt von der 12 aus: zur nächsten großen Zahl sind es fünf Minuten.',
            'Lies erst die Stunde ab, danach die Minuten. Wenn der kurze Zeiger zwischen zwei Stunden steht, ist die frühere Stunde gemeint.',
          ]),
        'Geld lernen' =>
          const _ModuleMethod('Geldwerte zählen und vergleichen.', [
            'Lies den Wert auf jeder Münze oder jedem Schein. Die Anzahl der Münzen ist nicht der Geldwert.',
            'Rechne Euro und Cent zunächst getrennt zusammen. Ein Euro entspricht hundert Cent.',
            'Schreibe jeden Geldwert auf und addiere ihn genau einmal. Vergleiche danach gleiche Einheiten.',
          ]),
        'Einmaleins 2/5/10' ||
        'Großes 1×1' =>
          const _ModuleMethod('Gleich große Gruppen zusammenfassen.', [
            'Zähle die Gruppen und dann die Dinge in einer Gruppe.',
            'Addiere dieselbe Gruppengröße so oft, wie es Gruppen gibt.',
            'Zeichne für jede Gruppe gleich viele Punkte. Vergleiche die Gesamtzahl mit deiner Rechnung.',
          ]),
        'Bruchrechnen' =>
          const _ModuleMethod('Gleich große Teile eines Ganzen beschreiben.', [
            'Prüfe zuerst, in wie viele gleich große Teile das Ganze geteilt ist.',
            'Die Zahl unten beschreibt alle gleich großen Teile. Die Zahl oben beschreibt die ausgewählten Teile.',
            'Vergleiche Brüche mit gleich großen Ganzen. Markiere die Teile, bevor du die Antwort auswählst.',
          ]),
        'Formen erkennen' => const _ModuleMethod(
              'Formen an Ecken, Seiten und Rundungen erkennen.', [
            'Sieh auf den Umriss. Die Farbe entscheidet nicht, welche Form es ist.',
            'Zähle Ecken und gerade Seiten. Hat die Form eine Rundung?',
            'Fahre den Rand mit dem Finger nach. Eine gedrehte Form hat weiterhin dieselben Ecken und Seiten.',
          ]),
        'Der / Die / Das' =>
          const _ModuleMethod('Nomen mit ihrem passenden Artikel verbinden.', [
            'Sprich das Wort langsam und überlege, wie du es in einem Satz verwendest.',
            'Setze nacheinander der, die und das vor das Wort. Welche Verbindung kennst du?',
            'Lerne das Nomen als Paar mit seinem Artikel. Wenn du unsicher bist, frage nach dem ganzen Wortpaar.',
          ]),
        'Mehrzahl bilden' => const _ModuleMethod(
              'Einzahl und Mehrzahl eines Wortes unterscheiden.', [
            'Stell dir erst ein Ding vor und dann mehrere davon.',
            'Sprich das Wort mit „ein“ und danach mit „viele“. Höre auf das Wortende und mögliche Umlaute.',
            'Lies jede angebotene Mehrzahl im Satz „Hier sind viele …“. Prüfe das ganze Wort, nicht nur seinen letzten Buchstaben.',
          ]),
        'Wortarten' => const _ModuleMethod(
              'Nomen, Verben und Adjektive im Zusammenhang erkennen.', [
            'Lies das ganze Wort und, wenn vorhanden, den Satz dazu.',
            'Nomen benennen etwas. Verben können eine Tätigkeit oder einen Zustand ausdrücken. Adjektive beschreiben Eigenschaften.',
            'Probiere einen Satz: „Das ist …“, „Wir …“ oder „Es ist …“. Prüfe die Bedeutung im gegebenen Zusammenhang.',
          ]),
        'Zeitformen' => const _ModuleMethod(
              'Handlungen zeitlich einordnen und Verbformen vergleichen.', [
            'Suche Hinweise darauf, ob etwas jetzt geschieht, schon geschah oder erst geschehen wird.',
            'Finde das Verb. Lies auch ein mögliches Hilfsverb wie „hat“, „ist“ oder „wird“ mit.',
            'Sprich den Satz mit einem passenden Zeitwort wie heute, gestern oder morgen. Prüfe, ob die Verbform dazu passt.',
          ]),
        'Wort-Diktat' => const _ModuleMethod(
              'Ein gehörtes Wort aufmerksam in Laute und Buchstaben gliedern.',
              [
                'Höre das Wort noch einmal vollständig an, bevor du schreibst.',
                'Sprich es langsam in Silben. Achte auf Anfang, Mitte und Ende.',
                'Lies dein geschriebenes Wort Buchstabe für Buchstabe zurück. Vergleiche es mit dem gehörten Wort.',
              ]),
        'Tiere lernen' =>
          const _ModuleMethod('Tiere anhand beobachtbarer Merkmale zuordnen.', [
            'Schau genau: Welche Körperteile und Merkmale kannst du erkennen?',
            'Vergleiche ein Merkmal nach dem anderen, zum Beispiel Beine, Flügel, Fell oder Schuppen.',
            'Lies die Antwortmöglichkeiten und prüfe jede an den sichtbaren Merkmalen. Ein einzelnes Merkmal reicht nicht immer.',
          ]),
        'Farben lernen' => const _ModuleMethod(
              'Farben benennen und passende Begriffe zuordnen.', [
            'Schau dir das gesuchte Feld und seinen Farbnamen genau an.',
            'Vergleiche die angebotenen Namen einzeln mit dem Feld.',
            'Wenn sich Farben für dich schwer unterscheiden lassen, nutze die Namen oder bitte jemanden, das Feld zu benennen.',
          ]),
        'Jahreszeiten' => const _ModuleMethod(
              'Jahreszeiten und typische Beobachtungen verbinden.', [
            'Welche Veränderung wird beschrieben: Wachstum, Wärme, fallende Blätter oder Winterruhe?',
            'Gehe das Jahr der Reihe nach durch: Frühling, Sommer, Herbst, Winter.',
            'Vergleiche mehrere Hinweise. Einzelne warme oder kalte Tage bestimmen allein noch keine Jahreszeit.',
          ]),
        'Wetter lernen' => const _ModuleMethod(
              'Wetter beobachten und passende Begriffe verwenden.', [
            'Schau auf die Hinweise zu Sonne, Wolken, Niederschlag und Wind.',
            'Beschreibe zuerst, was du tatsächlich sehen kannst.',
            'Vergleiche diese Beobachtung mit jeder Antwort. Vermute kein anderes Wetter, das nicht gezeigt oder beschrieben wird.',
          ]),
        'Verkehr & Sicherheit' => const _ModuleMethod(
              'Sichere Handlungen in Verkehrssituationen erkennen.', [
            'Wer ist zu sehen, und wo könnte eine Gefahr entstehen?',
            'Überlege, welche Handlung genug Zeit zum Schauen, Warten und Reagieren lässt.',
            'Prüfe die Antwortmöglichkeiten einzeln: Welche schützt die beteiligten Menschen? Besprich unklare Situationen mit einer erwachsenen Person.',
          ]),
        _ => const _ModuleMethod(
              'Die Aufgabe verstehen und einen eigenen Lösungsweg prüfen.', [
            'Lies die Frage noch einmal. Was genau sollst du herausfinden?',
            'Zeige auf die wichtige Information und betrachte nur diesen Teil.',
            'Erkläre in eigenen Worten, was du schon weißt. Prüfe damit die möglichen Antworten.',
          ]),
      };
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LumoVisualTokens.lessonPanel.withValues(alpha: .94),
              LumoVisualTokens.navigation.withValues(alpha: .91),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: LumoVisualTokens.cyanBright.withValues(alpha: .53),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
                color: LumoVisualTokens.cyan.withValues(alpha: .10),
                blurRadius: 20,
                spreadRadius: -7,
                offset: const Offset(0, 7)),
          ],
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
