import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/lumo_companion_guide.dart';
import '../../core/lumo_voice.dart';
import 'lumo_animated_fox.dart';
import 'lumo_companion_requests.dart';
export '../../core/lumo_companion_guide.dart';

/// A reserved floor below the content: Lumo walks above his own controls,
/// never over answers, navigation buttons, keyboards or modal routes.
class LumoFreeCompanion extends StatefulWidget {
  const LumoFreeCompanion(
      {super.key,
      required this.scene,
      required this.onAction,
      this.voiceEnabled = false,
      this.reducedMotion = false,
      this.expression = LumoFoxExpression.idle,
      this.message,
      this.compact = false,
      this.proactive = true});
  final LumoCompanionScene scene;
  final ValueChanged<LumoCompanionAction> onAction;
  final bool voiceEnabled;
  final bool reducedMotion;
  final LumoFoxExpression expression;
  final String? message;
  final bool compact;
  final bool proactive;
  @override
  State<LumoFreeCompanion> createState() => _LumoFreeCompanionState();
}

class _LumoFreeCompanionState extends State<LumoFreeCompanion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _guide = LumoCompanionGuide(now: DateTime.now());
  late final AnimationController _walk = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() {});
    });
  Timer? _initiative;
  Timer? _turnTimer;
  Timer? _reactionTimer;
  LumoFoxExpression? _reaction;
  DateTime _lastActivity = DateTime.now();
  DateTime _lastWalk = DateTime.now();
  DateTime? _restUntil;
  int _nextStation = 0;
  LumoCompanionProposal? _proposal;
  double _from = 1, _to = 1;
  bool _right = true, _sheetOpen = false, _foreground = true;
  double get _position =>
      _from + (_to - _from) * Curves.easeInOutCubic.transform(_walk.value);
  bool get _quiet =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
  bool get _visible =>
      _foreground && !_sheetOpen && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LumoCompanionRequests.instance.moveTarget.addListener(_noteActivity);
    LumoCompanionRequests.instance.appExplanationRequested
        .addListener(_explainAppRequested);
    _initiative =
        Timer.periodic(const Duration(seconds: 2), (_) => _considerIdea());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _foreground = state == AppLifecycleState.resumed);
    if (!_foreground) {
      _turnTimer?.cancel();
      _walk.stop();
    }
    _noteActivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quiet) {
      _turnTimer?.cancel();
      _walk.stop();
    }
  }

  @override
  void didUpdateWidget(covariant LumoFreeCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scene.solvedTasks > oldWidget.scene.solvedTasks) {
      _react(LumoFoxExpression.celebrate);
    } else if (widget.scene.consecutiveWrong >
        oldWidget.scene.consecutiveWrong) {
      _react(LumoFoxExpression.comfort);
    }
    if (oldWidget.scene.section != widget.scene.section ||
        oldWidget.scene.schoolwork != widget.scene.schoolwork ||
        oldWidget.scene.taskInProgress != widget.scene.taskInProgress) {
      _proposal = null;
      _noteActivity();
      if (widget.scene.section != oldWidget.scene.section) {
        _moveTo(widget.scene.hasTask
            ? 1
            : widget.scene.section == 'agent'
                ? 2
                : 0);
      }
    }
    if (widget.reducedMotion) {
      _turnTimer?.cancel();
      _walk.stop();
    }
  }

  void _react(LumoFoxExpression expression) {
    _reactionTimer?.cancel();
    _reaction = expression;
    _reactionTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _reaction = null);
    });
  }

  void _noteActivity() {
    _lastActivity = DateTime.now();
    _guide.noteInteraction(_lastActivity);
  }

  void _considerIdea() {
    if (!mounted || !widget.proactive) return;
    if (_proposal != null) {
      _considerQuietWalk();
      return;
    }
    final proposal = _guide.maybeSuggest(widget.scene,
        now: DateTime.now(), routeVisible: _visible);
    if (proposal != null) {
      setState(() => _proposal = proposal);
      _moveTo(proposal.action == LumoCompanionAction.explainTask ||
              proposal.action == LumoCompanionAction.explainView
          ? 1
          : 0);
    } else {
      _considerQuietWalk();
    }
  }

  void _considerQuietWalk() {
    final now = DateTime.now();
    if (!_visible ||
        _quiet ||
        widget.scene.taskInProgress ||
        widget.scene.schoolwork ||
        widget.scene.section == 'settings' ||
        widget.scene.section == 'profile' ||
        widget.scene.section == 'agent' ||
        _walk.isAnimating ||
        (_restUntil != null && now.isBefore(_restUntil!)) ||
        now.difference(_lastActivity) < const Duration(seconds: 20) ||
        now.difference(_lastWalk) < const Duration(seconds: 45)) {
      return;
    }
    // Visit the next useful control along the reserved floor, never a random
    // point over learning content. No speech or new pop-up accompanies a walk.
    _nextStation = (_nextStation + 1) % 3;
    setState(() => _moveTo(_nextStation));
  }

  void _moveTo(int index) => _moveToFraction(index / 2);

  void _moveToFraction(double target) {
    _turnTimer?.cancel();
    final current = _position;
    final clamped = target.clamp(0.0, 1.0);
    final newRight = clamped >= current;
    _walk.stop();
    _from = _to = current;
    _lastWalk = DateTime.now();
    if (_quiet) {
      _from = _to = clamped;
      _walk.value = 0;
      return;
    }
    if ((clamped - current).abs() < .02) return;
    if (newRight != _right) {
      // Settle on both feet facing the child before leaving in the opposite
      // direction. Never instantly mirror a running fox mid-stride.
      _turnTimer = Timer(const Duration(milliseconds: 180), () {
        if (!mounted || !_foreground) return;
        setState(() => _startWalk(clamped, newRight));
      });
    } else {
      _startWalk(clamped, newRight);
    }
  }

  void _startWalk(double target, bool facingRight) {
    _from = _position;
    _to = target;
    _right = facingRight;
    final width = MediaQuery.sizeOf(context).width;
    final distance = (_to - _from).abs() * math.max(0, width - 90);
    _walk.duration =
        Duration(milliseconds: (700 + distance * 5).round().clamp(700, 2800));
    _walk.forward(from: 0);
  }

  void _dismiss() {
    _guide.dismiss(DateTime.now());
    _restUntil = DateTime.now().add(const Duration(minutes: 10));
    setState(() => _proposal = null);
    _moveTo(2);
  }

  Future<void> _say(String text) async {
    if (!widget.voiceEnabled) return;
    try {
      await LumoVoice.instance.speak(text);
    } catch (_) {/* Text remains available. */}
  }

  Future<void> _showText(String title, String text,
      {bool pause = false}) async {
    _noteActivity();
    setState(() => _sheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(title,
                          style: Theme.of(context).textTheme.headlineSmall)),
                  const SizedBox(width: 12),
                  LumoAnimatedFox(
                      moving: false,
                      size: 66,
                      reducedMotion: _quiet,
                      voiceEnabled: widget.voiceEnabled,
                      expression: LumoFoxExpression.explain),
                ]),
                const SizedBox(height: 16),
                Text(text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5)),
                const SizedBox(height: 20),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  if (widget.voiceEnabled)
                    ValueListenableBuilder<VoiceStatus>(
                      valueListenable: LumoVoice.instance.status,
                      builder: (context, status, _) => OutlinedButton.icon(
                          onPressed: () => status == VoiceStatus.speaking
                              ? LumoVoice.instance.stop()
                              : _say(text),
                          icon: Icon(status == VoiceStatus.speaking
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded),
                          label: Text(status == VoiceStatus.speaking
                              ? 'Vorlesen stoppen'
                              : 'Vorlesen')),
                    ),
                  FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child:
                          Text(pause ? 'Ich bin wieder bereit' : 'Alles klar')),
                ]),
              ]),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _sheetOpen = false);
    await LumoVoice.instance.stop();
    _noteActivity();
  }

  void _explainAppRequested() {
    if (mounted && _visible) _perform(LumoCompanionAction.explainApp);
  }

  Future<void> _perform(LumoCompanionAction action) async {
    _noteActivity();
    if (widget.scene.schoolwork &&
        (action == LumoCompanionAction.explainTask ||
            action == LumoCompanionAction.suggestTask ||
            action == LumoCompanionAction.askLumo)) {
      await _showText(
          'Dein eigener Lernschritt',
          'Während der Schularbeit löst du die Aufgaben selbst. '
              'Nachher können wir schwierige Themen gemeinsam üben.');
      return;
    }
    setState(() => _proposal = null);
    _react(action == LumoCompanionAction.askLumo
        ? LumoFoxExpression.think
        : LumoFoxExpression.explain);
    switch (action) {
      case LumoCompanionAction.explainApp:
        await _showText('So helfe ich dir', LumoCompanionScene.appExplanation);
      case LumoCompanionAction.explainView:
        await _showText(
            'So funktioniert diese Seite', widget.scene.viewExplanation);
      case LumoCompanionAction.takeBreak:
        await _showText(
            'Eine kleine Pause',
            'Leg das Gerät kurz zur Seite. Strecke dich und schau etwas weiter '
                'in die Ferne. Wenn du wieder lernen möchtest, machst du in deinem '
                'Tempo weiter.',
            pause: true);
        if (mounted) widget.onAction(action);
      case LumoCompanionAction.suggestTask:
      case LumoCompanionAction.explainTask:
      case LumoCompanionAction.askLumo:
        widget.onAction(action);
    }
  }

  Future<void> _showMenu({LumoCompanionProposal? proposal}) async {
    if (_sheetOpen) return;
    _noteActivity();
    setState(() => _sheetOpen = true);
    final action = await showModalBottomSheet<LumoCompanionAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Was möchtest du machen?',
              style: Theme.of(context).textTheme.titleLarge),
          if (proposal != null) ...[
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(proposal.text,
                    style: Theme.of(context).textTheme.bodyLarge)),
            FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, proposal.action),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(proposal.acceptLabel)),
            TextButton(
                onPressed: () {
                  _dismiss();
                  Navigator.pop(sheetContext);
                },
                child: const Text('Später – lass mich selbst entdecken')),
            const Divider(),
          ],
          if (widget.scene.hasTask && !widget.scene.schoolwork)
            _menuItem(sheetContext, Icons.lightbulb_outline, 'Aufgabe erklären',
                LumoCompanionAction.explainTask),
          _menuItem(sheetContext, Icons.explore_outlined,
              'Diese Seite erklären', LumoCompanionAction.explainView),
          _menuItem(sheetContext, Icons.help_outline, 'Die ganze App erklären',
              LumoCompanionAction.explainApp),
          if (!widget.scene.schoolwork)
            _menuItem(sheetContext, Icons.chat_bubble_outline,
                'Lumo eine Frage stellen', LumoCompanionAction.askLumo),
          _menuItem(sheetContext, Icons.spa_outlined, 'Ich brauche eine Pause',
              LumoCompanionAction.takeBreak),
        ]),
      )),
    );
    if (!mounted) return;
    setState(() => _sheetOpen = false);
    _noteActivity();
    if (action != null) await _perform(action);
  }

  Widget _menuItem(BuildContext sheetContext, IconData icon, String title,
          LumoCompanionAction action) =>
      ListTile(
          leading: Icon(icon),
          title: Text(title),
          onTap: () => Navigator.pop(sheetContext, action));
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LumoCompanionRequests.instance.moveTarget.removeListener(_noteActivity);
    LumoCompanionRequests.instance.appExplanationRequested
        .removeListener(_explainAppRequested);
    _initiative?.cancel();
    _turnTimer?.cancel();
    _reactionTimer?.cancel();
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foxSize = widget.compact ? 52.0 : 72.0;
    final trackHeight = widget.compact ? 56.0 : 76.0;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final buttonHeight = math.max(40.0, 32 * textScale);
    return Material(
        color: Colors.transparent,
        child: SizedBox(
          key: const ValueKey('lumo-companion-floor'),
          height: trackHeight + buttonHeight,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Column(children: [
              SizedBox(
                  height: trackHeight,
                  child: GestureDetector(
                      key: const ValueKey('lumo-walking-floor'),
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        _noteActivity();
                        final inset =
                            (width / 6 - foxSize / 2).clamp(0.0, width / 2);
                        final travel =
                            math.max(1.0, width - 2 * inset - foxSize);
                        final target =
                            (details.localPosition.dx - inset - foxSize / 2) /
                                travel;
                        setState(() => _moveToFraction(target));
                      },
                      child: AnimatedBuilder(
                        animation: _walk,
                        builder: (context, _) {
                          final inset =
                              (width / 6 - foxSize / 2).clamp(0.0, width / 2);
                          final x = inset +
                              _position *
                                  math.max(0, width - 2 * inset - foxSize);
                          final foxRight = _position > .5;
                          return Stack(clipBehavior: Clip.hardEdge, children: [
                            if (!_walk.isAnimating && !widget.compact)
                              Positioned(
                                left: foxRight ? 12 : x + foxSize + 6,
                                right: foxRight ? width - x + 6 : 12,
                                top: 4,
                                bottom: 4,
                                child: Row(children: [
                                  Expanded(
                                      child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showMenu(proposal: _proposal),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _proposal?.text ??
                                                widget.message
                                                    ?.replaceAll('\n', ' ') ??
                                                (widget.scene.schoolwork
                                                    ? 'Danach üben wir gemeinsam weiter.'
                                                    : 'Tippe mich an. Ich helfe dir gern!'),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(height: 1.3),
                                          )),
                                    ),
                                  )),
                                  if (_proposal != null)
                                    IconButton(
                                        tooltip: 'Vorschlag später ansehen',
                                        onPressed: _dismiss,
                                        icon:
                                            const Icon(Icons.close, size: 18)),
                                ]),
                              ),
                            Positioned(
                              key: const ValueKey('lumo-fox-position'),
                              left: x,
                              bottom: 0,
                              child: Semantics(
                                label:
                                    'Lumo, dein Lernfuchs. Hilfe und Ideen öffnen',
                                button: true,
                                child: InkWell(
                                  key: const ValueKey('lumo-fox-button'),
                                  onTap: () => _showMenu(proposal: _proposal),
                                  borderRadius: BorderRadius.circular(40),
                                  child: LumoAnimatedFox(
                                      size: foxSize,
                                      moving: _walk.isAnimating,
                                      facingRight: _right,
                                      active: _visible,
                                      voiceEnabled: widget.voiceEnabled,
                                      expression:
                                          _reaction ?? widget.expression,
                                      reducedMotion: _quiet),
                                ),
                              ),
                            ),
                          ]);
                        },
                      ))),
              SizedBox(
                  height: buttonHeight,
                  child: Row(children: [
                    _floorButton(Icons.auto_awesome_outlined, 'Idee', 0,
                        () => _showMenu(proposal: _guide.choose(widget.scene))),
                    _floorButton(Icons.lightbulb_outline, 'Erklären', 1, () {
                      if (widget.scene.hasTask && !widget.scene.schoolwork) {
                        _perform(LumoCompanionAction.explainTask);
                      } else {
                        _showMenu();
                      }
                    }),
                    _floorButton(Icons.chat_bubble_outline, 'Fragen', 2,
                        () => _perform(LumoCompanionAction.askLumo)),
                  ])),
            ]);
          }),
        ));
  }

  Widget _floorButton(
          IconData icon, String label, int index, VoidCallback action) =>
      Expanded(
          child: TextButton(
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2)),
        onPressed: () {
          _noteActivity();
          setState(() => _moveTo(index));
          action();
        },
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17),
          const SizedBox(width: 4),
          Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ));
}
