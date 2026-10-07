import 'dart:async';

import 'dart:ui' show ImageFilter;

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
              LumoPausePanel(
                onResume: widget.clock.resume,
                onRestart: () {
                  widget.clock.cancel();
                  widget.onRestart();
                  widget.clock.resume();
                },
                onLeave: () => Navigator.of(context).pop(),
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

/// Gemeinsames Pausenfenster aller Lumo-Spiele: dunkles Glas, Cyan-Kante,
/// goldenes Pausensymbol, große Knöpfe (mind. 52 dp). Texte bleiben gleich,
/// damit Vorlesefunktion und Android-Prüfungen sie wiederfinden.
class LumoPausePanel extends StatelessWidget {
  const LumoPausePanel({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onLeave,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLeave;

  static const _label = TextStyle(
      fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(fit: StackFit.expand, children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const ColoredBox(color: Color(0xA6020A24)),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  key: const ValueKey('lumo-pause-panel'),
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xF2123F86), Color(0xF2071A3E)],
                    ),
                    border: Border.all(color: const Color(0xCC53DDFD), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x6637D2FD), blurRadius: 26),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFE08A), Color(0xFFF5A623)]),
                            boxShadow: [
                              BoxShadow(color: Color(0x88FFD86B), blurRadius: 18),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.pause_rounded,
                                color: Color(0xFF0B2A5C), size: 34),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Spiel pausiert',
                          textAlign: TextAlign.center,
                          style: _label.copyWith(fontSize: 26)),
                      const SizedBox(height: 6),
                      const Text('Dein aktueller Zug wartet auf dich.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD6E8FF))),
                      const SizedBox(height: 18),
                      _PauseButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Fortsetzen',
                        primary: true,
                        onTap: onResume,
                      ),
                      const SizedBox(height: 10),
                      _PauseButton(
                        icon: Icons.replay_rounded,
                        label: 'Neu starten',
                        onTap: onRestart,
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onLeave,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text('Zur Spieleauswahl',
                            style: _label.copyWith(fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onTap,
            child: Ink(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: primary
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF63E4FF), Color(0xFF1E7FE0)])
                    : null,
                color: primary ? null : const Color(0x33FFFFFF),
                border: Border.all(
                    color: primary
                        ? const Color(0xFFBDF4FF)
                        : const Color(0x8837D2FD),
                    width: 1.6),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: LumoPausePanel._label.copyWith(fontSize: 17)),
                ),
              ]),
            ),
          ),
        ),
      );
}
