import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../lumo_jump/fox_sprite.dart' as fox;

/// Animierter Lumo-Fuchs auf dem Home-Screen.
///
/// Nutzt die echten 3D-Pixar-Sprites aus assets/lumo_jump/fox/.
/// - Standardmaessig: FoxAction.idle + autonomes Wandern, Ducken, Springen
/// - Bei Tap: kurzer Hop + FoxAction.jump-Animation
/// - Bei jedem 3. Tap: FoxAction.roll (Easter-Egg)
/// - Periodische Speech-Bubbles ("Lass uns lernen!" etc.)
/// - Kopf dreht sich automatisch in Laufrichtung
///
/// Der Avatar hat keinen eigenen GameState - er ist rein dekorativ.
class LumoHomeFoxAvatar extends StatefulWidget {
  const LumoHomeFoxAvatar({
    super.key,
    this.size = 180,
    this.facingLeft = false,
    this.onTap,
  });

  final double size;
  final bool facingLeft;
  final VoidCallback? onTap;

  @override
  State<LumoHomeFoxAvatar> createState() => _LumoHomeFoxAvatarState();
}

class _LumoHomeFoxAvatarState extends State<LumoHomeFoxAvatar>
    with TickerProviderStateMixin {
  // ── Hop-Animation (bei Tap) ──────────────────────────────────────────
  late final AnimationController _hopCtrl;

  // ── Wander-Animation (autonome Bewegung) ────────────────────────────
  late final AnimationController _wanderCtrl;
  double _wanderFrom   = 0;
  double _wanderTarget = 0;

  // ── Action-State ─────────────────────────────────────────────────────
  fox.FoxAction _tapAction  = fox.FoxAction.idle;  // durch Tap ausgelöst
  fox.FoxAction _autoAction = fox.FoxAction.idle;  // autonom
  bool _autoFacingLeft = false;  // Richtung beim autonomen Wandern

  // ── Timers ────────────────────────────────────────────────────────────
  Timer? _resetTimer;
  Timer? _behaviorTimer;
  Timer? _actionResetTimer;   // kurzlebiger Timer für Duck/Jump-Rücksetz
  Timer? _speechTimer;
  Timer? _speechClearTimer;
  int _tapCount = 0;

  // ── Speech-Bubbles ────────────────────────────────────────────────────
  String? _currentSpeech;

  static const _phrases = <String>[
    'Lass uns lernen! 🦊',
    'Schaffst du die Aufgabe?',
    'Heute wirst du super! 🌟',
    'Was möchtest du machen?',
    'Komm, ich helf dir!',
    'Du schaffst das! 💪',
    'Eine Aufgabe gefällig?',
    'Lumo ist bereit! ✨',
  ];

  // ── Maximale Wanderdistanz in Pixeln ─────────────────────────────────
  static const double _maxWander = 52.0;

  // ── Aktuell interpolierte X-Position ─────────────────────────────────
  double get _wanderX =>
      _wanderFrom + (_wanderTarget - _wanderFrom) * _wanderCtrl.value;

  @override
  void initState() {
    super.initState();

    _hopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _wanderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Wanderung abgeschlossen → Position festhalten, idle
          setState(() {
            _wanderFrom   = _wanderTarget;
            _autoAction   = fox.FoxAction.idle;
          });
        }
      });

    _scheduleBehavior();
    _scheduleSpeech();
  }

  @override
  void dispose() {
    _hopCtrl.dispose();
    _wanderCtrl.dispose();
    _resetTimer?.cancel();
    _behaviorTimer?.cancel();
    _actionResetTimer?.cancel();
    _speechTimer?.cancel();
    _speechClearTimer?.cancel();
    super.dispose();
  }

  // ── Autonomes Verhalten ───────────────────────────────────────────────

  void _scheduleBehavior() {
    final r = math.Random();
    _behaviorTimer = Timer(Duration(seconds: 4 + r.nextInt(5)), () {
      if (!mounted) return;
      final pick = r.nextDouble();

      if (pick < 0.30) {
        // 30 % – Wandern
        final newTarget =
            ((r.nextDouble() * 2 - 1) * _maxWander).clamp(-_maxWander, _maxWander);
        setState(() {
          _wanderFrom     = _wanderX;
          _wanderTarget   = newTarget;
          _autoAction     = fox.FoxAction.run;
          _autoFacingLeft = newTarget < _wanderFrom;
        });
        _wanderCtrl.forward(from: 0);
      } else if (pick < 0.45) {
        // 15 % – Kurz ducken
        setState(() => _autoAction = fox.FoxAction.duck);
        _actionResetTimer?.cancel();
        _actionResetTimer = Timer(const Duration(milliseconds: 1100), () {
          if (mounted) setState(() => _autoAction = fox.FoxAction.idle);
        });
      } else if (pick < 0.55) {
        // 10 % – Kleiner Hüpfer
        setState(() => _autoAction = fox.FoxAction.jump);
        _hopCtrl.forward(from: 0);
        _actionResetTimer?.cancel();
        _actionResetTimer = Timer(const Duration(milliseconds: 520), () {
          if (mounted) setState(() => _autoAction = fox.FoxAction.idle);
        });
      } else {
        // 45 % – Idle (atmen, blinzeln)
        setState(() => _autoAction = fox.FoxAction.idle);
      }

      _scheduleBehavior();
    });
  }

  void _scheduleSpeech() {
    _speechTimer = Timer(
      Duration(seconds: 12 + math.Random().nextInt(9)),
      () {
        if (!mounted) return;
        setState(() {
          _currentSpeech = _phrases[math.Random().nextInt(_phrases.length)];
        });
        _speechClearTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _currentSpeech = null);
        });
        _scheduleSpeech();
      },
    );
  }

  // ── Tap-Handler ───────────────────────────────────────────────────────

  void _onTap() {
    HapticFeedback.lightImpact();
    _tapCount++;
    final useRoll = _tapCount % 3 == 0;
    _hopCtrl.forward(from: 0);
    setState(() {
      _tapAction = useRoll ? fox.FoxAction.roll : fox.FoxAction.jump;
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(
      Duration(milliseconds: useRoll ? 800 : 520),
      () {
        if (mounted) setState(() => _tapAction = fox.FoxAction.idle);
      },
    );
    widget.onTap?.call();
  }

  // ── Effektive Anzeigewerte ────────────────────────────────────────────

  fox.FoxAction get _displayAction =>
      _tapAction != fox.FoxAction.idle ? _tapAction : _autoAction;

  bool get _displayFacingLeft =>
      _tapAction != fox.FoxAction.idle ? widget.facingLeft : _autoFacingLeft;

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hopCtrl, _wanderCtrl]),
      builder: (_, __) {
        final hopY   = -math.sin(_hopCtrl.value * math.pi) * 24.0;
        final offsetX = _wanderX;

        return SizedBox(
          width:  widget.size + _maxWander * 2,
          height: widget.size + 72,  // Platz für Speech-Bubble oben
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Speech-Bubble oberhalb des Fuchses
              Positioned(
                bottom: widget.size - 4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: anim,
                      curve: Curves.elasticOut,
                    ),
                    child: child,
                  ),
                  child: _currentSpeech != null
                      ? _SpeechBubble(
                          key: ValueKey(_currentSpeech),
                          text: _currentSpeech!,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),

              // Fuchs mit Wander + Hop
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onTap,
                  child: Transform.translate(
                    offset: Offset(offsetX, hopY),
                    child: fox.FoxSprite(
                      action:      _displayAction,
                      size:        widget.size,
                      facingLeft:  _displayFacingLeft,
                      showShadow:  true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Speech-Bubble ─────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily:  'Nunito',
            fontSize:    13,
            fontWeight:  FontWeight.w800,
            color:       Color(0xFF1F2937),
            height:      1.3,
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2 - 8, size.height)
      ..lineTo(size.width / 2,     size.height + 10)
      ..lineTo(size.width / 2 + 8, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
