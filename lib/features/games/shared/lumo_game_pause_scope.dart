import 'dart:async';

import 'package:flutter/material.dart';

/// One pending turn action. Pausing preserves the remaining thinking time;
/// restarting cancels it so an old bot move cannot touch the new board.
class LumoGameTurnClock extends ValueNotifier<bool> {
  LumoGameTurnClock() : super(false);

  Timer? _timer;
  VoidCallback? _action;
  Duration _remaining = Duration.zero;
  DateTime? _due;

  void schedule(Duration delay, VoidCallback action) {
    cancel();
    _action = action;
    _remaining = delay;
    if (!value) _arm();
  }

  void _arm() {
    if (_action == null) return;
    _due = DateTime.now().add(_remaining);
    _timer = Timer(_remaining, () {
      final action = _action;
      _action = null;
      _timer = null;
      _due = null;
      action?.call();
    });
  }

  void pause() {
    if (value) return;
    if (_due != null) {
      final left = _due!.difference(DateTime.now());
      _remaining = left.isNegative ? Duration.zero : left;
    }
    _timer?.cancel();
    _timer = null;
    value = true;
  }

  void resume() {
    if (!value) return;
    value = false;
    _arm();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _action = null;
    _due = null;
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}

/// Shared Android-back / lifecycle pause for Flutter board games.
class LumoGamePauseScope extends StatefulWidget {
  const LumoGamePauseScope({
    super.key,
    required this.clock,
    required this.child,
    required this.onRestart,
  });

  final LumoGameTurnClock clock;
  final Widget child;
  final VoidCallback onRestart;

  @override
  State<LumoGamePauseScope> createState() => _LumoGamePauseScopeState();
}

class _LumoGamePauseScopeState extends State<LumoGamePauseScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.clock.pause();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.clock,
      builder: (context, paused, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.clock.pause();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            TickerMode(enabled: !paused, child: widget.child),
            if (paused)
              Material(
                color: Colors.black54,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Spiel pausiert',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                const Text(
                                    'Dein aktueller Zug wartet auf dich.',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: widget.clock.resume,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Fortsetzen'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    widget.clock.cancel();
                                    widget.onRestart();
                                    widget.clock.resume();
                                  },
                                  icon: const Icon(Icons.replay_rounded),
                                  label: const Text('Neu starten'),
                                ),
                                TextButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Zur Spieleauswahl'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

/// Android Back from a completed board game returns to the games selection;
/// the child must never get stranded on an already rewarded finished board.
class LumoGameResultBack extends StatelessWidget {
  const LumoGameResultBack({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            Navigator.of(context).pop(); // result dialog
            Navigator.of(context).pop(); // game
          }
        },
        child: child,
      );
}
