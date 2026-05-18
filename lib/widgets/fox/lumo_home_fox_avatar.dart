import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../lumo_jump/fox_sprite.dart' as fox;

/// Animierter Lumo-Fuchs auf dem Home-Screen — Persönlichkeits-Avatar.
///
/// Lumo ist ein echter digitaler Freund:
/// - lebt autonom: wandert, dreht sich, tanzt, winkt, kratzt sich, gähnt
/// - kennt den Namen des Kindes und reagiert darauf
/// - kommentiert Sterne und Fortschritt
/// - begrüßt tageszeit-abhängig
/// - reagiert auf Taps mit eigenem Charakter (1. Tap anders als 5. Tap)
/// - zeigt Langeweile wenn niemand interagiert
class LumoHomeFoxAvatar extends StatefulWidget {
  const LumoHomeFoxAvatar({
    super.key,
    this.size = 180,
    this.facingLeft = false,
    this.onTap,
    this.childName = '',
    this.stars = 0,
  });

  final double size;
  final bool facingLeft;
  final VoidCallback? onTap;
  /// Name des Kindes – macht Speech-Bubbles persönlich.
  final String childName;
  /// Aktuelle Sternzahl – Lumo kommentiert Fortschritte.
  final int stars;

  @override
  State<LumoHomeFoxAvatar> createState() => _LumoHomeFoxAvatarState();
}

class _LumoHomeFoxAvatarState extends State<LumoHomeFoxAvatar>
    with TickerProviderStateMixin {

  // ── Animationen ──────────────────────────────────────────────────────
  late final AnimationController _hopCtrl;
  late final AnimationController _wanderCtrl;
  late final AnimationController _waveCtrl; // Wackeln/Winken

  double _wanderFrom   = 0;
  double _wanderTarget = 0;

  // ── Action-State ─────────────────────────────────────────────────────
  fox.FoxAction _tapAction  = fox.FoxAction.idle;
  fox.FoxAction _autoAction = fox.FoxAction.idle;
  bool _autoFacingLeft = false;

  // ── Timers ────────────────────────────────────────────────────────────
  Timer? _resetTimer;
  Timer? _behaviorTimer;
  Timer? _actionResetTimer;
  Timer? _speechTimer;
  Timer? _speechClearTimer;
  Timer? _boredTimer;
  Timer? _wiggleTimer2;

  // ── Zufallsgenerator (einmalig, wiederverwendet) ───────────────────────
  final _rng = math.Random();

  // ── Tap-Zustand ───────────────────────────────────────────────────────
  int _tapCount = 0;
  DateTime? _lastTap;

  // ── Speech-Bubble ─────────────────────────────────────────────────────
  String? _currentSpeech;
  _BubbleStyle _bubbleStyle = _BubbleStyle.normal;

  // ── Maximale Wanderdistanz ────────────────────────────────────────────
  static const double _maxWander = 52.0;

  // ── Wanderinterpolation ───────────────────────────────────────────────
  double get _wanderX =>
      _wanderFrom + (_wanderTarget - _wanderFrom) * _wanderCtrl.value;

  // ── Tageszeit-Kategorie ───────────────────────────────────────────────
  static _TimeOfDay get _timeOfDay {
    final h = DateTime.now().hour;
    if (h < 10) return _TimeOfDay.morning;
    if (h < 14) return _TimeOfDay.midday;
    if (h < 18) return _TimeOfDay.afternoon;
    return _TimeOfDay.evening;
  }

  // ── Kurzer Name (nicht leer) ──────────────────────────────────────────
  String get _name =>
      widget.childName.trim().isEmpty ? '' : ' ${widget.childName.trim()}';

  // ── Speech-Bubble Texte ───────────────────────────────────────────────

  List<String> get _greetingPhrases => [
    switch (_timeOfDay) {
      _TimeOfDay.morning   => 'Guten Morgen$_name! ☀️',
      _TimeOfDay.midday    => 'Na$_name, schon bereit? 📚',
      _TimeOfDay.afternoon => 'Hi$_name! Was lernen wir? 🦊',
      _TimeOfDay.evening   => 'Hallo$_name! Noch am Lernen? 🌙',
    },
  ];

  List<String> get _idlePhrases => [
    'Ich bin hier für dich!',
    'Was möchtest du machen?',
    'Lumo wartet... 🦊',
    'Tippe auf mich! 👆',
    'Psst – ich hab eine Idee!',
    'Lass uns was Cooles machen!',
    'Ich langweile mich schon 😄',
    'Du bist der Boss hier!',
    'Gemeinsam sind wir stark! 💪',
    'Ich glaub an dich$_name!',
  ];

  List<String> get _starPhrases {
    final s = widget.stars;
    if (s == 0) return ['Dein erster Stern wartet auf dich! ⭐'];
    if (s < 10) return ['$s Sterne schon – super Start! ⭐'];
    if (s < 30) return ['Wow, $s Sterne! Du bist auf Kurs! 🌟'];
    if (s < 60) return ['$s Sterne – ich bin stolz auf dich! 🏆'];
    return ['$s Sterne! Du bist ein Lumo-Champion! 🎉'];
  }

  List<String> get _motivationPhrases => [
    'Du schaffst das$_name! 💪',
    'Eine Aufgabe gefällig?',
    'Bereit für Mathe? 🔢',
    'Lesen macht Spaß! 📖',
    'Jede Aufgabe macht dich stärker!',
    'Heute wirst du noch besser!',
    'Ich freu mich auf unsere Session!',
    "Los geht's – du kannst das!",
  ];

  List<String> get _funnyPhrases => [
    'Ich bin der beste Fuchs! 😄',
    'Wusstest du? Füchse sind schlau! 🦊',
    'Ich hab heute Morgen trainiert!',
    'Pst… ich mag Sterne mehr als Karotten 😅',
    'Mein Schwanz ist heute besonders flauschig!',
    'Ich könnte auch Pirouetten drehen!',
    '3, 2, 1… Lumo! 🚀',
    'Hoch die Pfoten! ✋',
  ];

  String _pickRandom(List<String> list) =>
      list[_rng.nextInt(list.length)];

  String _nextSpeechText() {
    final r = _rng.nextDouble();
    if (r < 0.15) return _pickRandom(_greetingPhrases);
    if (r < 0.30) return _pickRandom(_starPhrases);
    if (r < 0.55) return _pickRandom(_motivationPhrases);
    if (r < 0.75) return _pickRandom(_idlePhrases);
    return _pickRandom(_funnyPhrases);
  }

  // ── Tap-Reaktionen ────────────────────────────────────────────────────

  static const _tapReactions = <String>[
    'Oh! Hallo! 👋',
    'Kitzelt das! 😄',
    'Nochmal! Ich mag das!',
    'He he he! 😂',
    'Du bist lustig... 😏',
    'Ich spring gleich weg! 🏃',
    'Ok, ok, ich geb auf! 😅',
    'Du gewinnst! 🏆',
  ];

  @override
  void initState() {
    super.initState();

    _hopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _wanderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _wanderFrom = _wanderTarget;
            _autoAction = fox.FoxAction.idle;
          });
        }
      });

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scheduleBehavior();
    _scheduleSpeech();
    _scheduleBoredCheck();
  }

  @override
  void dispose() {
    _hopCtrl.dispose();
    _wanderCtrl.dispose();
    _waveCtrl.dispose();
    _resetTimer?.cancel();
    _behaviorTimer?.cancel();
    _actionResetTimer?.cancel();
    _speechTimer?.cancel();
    _speechClearTimer?.cancel();
    _boredTimer?.cancel();
    _wiggleTimer2?.cancel();
    super.dispose();
  }

  // ── Autonomes Verhalten ───────────────────────────────────────────────
  // Kürzere Zyklen (2-5 Sek) = lebendiger

  void _scheduleBehavior() {
    // 2-5 Sekunden Pause zwischen Aktionen = deutlich lebhafter
    _behaviorTimer = Timer(Duration(milliseconds: 2000 + _rng.nextInt(3000)), () {
      if (!mounted) return;
      _pickAndExecuteAction();
      _scheduleBehavior();
    });
  }

  void _pickAndExecuteAction() {
    final pick = _rng.nextDouble();

    if (pick < 0.22) {
      // 22 % – Wandern (links/rechts laufen)
      final newTarget =
          ((_rng.nextDouble() * 2 - 1) * _maxWander).clamp(-_maxWander, _maxWander);
      setState(() {
        _wanderFrom     = _wanderX;
        _wanderTarget   = newTarget;
        _autoAction     = fox.FoxAction.run;
        _autoFacingLeft = newTarget < _wanderFrom;
      });
      _wanderCtrl.forward(from: 0);

    } else if (pick < 0.35) {
      // 13 % – Umdrehen und kurz in andere Richtung schauen
      setState(() {
        _autoFacingLeft = !_autoFacingLeft;
        _autoAction     = fox.FoxAction.idle;
      });
      // Nach kurzer Pause wieder zurückdrehen
      _actionResetTimer?.cancel();
      _actionResetTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _autoFacingLeft = !_autoFacingLeft);
      });

    } else if (pick < 0.46) {
      // 11 % – Ducken (gähnen / kratzen)
      setState(() => _autoAction = fox.FoxAction.duck);
      _actionResetTimer?.cancel();
      _actionResetTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _autoAction = fox.FoxAction.idle);
      });

    } else if (pick < 0.55) {
      // 9 % – Kleiner Sprung (Energie-Moment)
      setState(() => _autoAction = fox.FoxAction.jump);
      _hopCtrl.forward(from: 0);
      _actionResetTimer?.cancel();
      _actionResetTimer = Timer(const Duration(milliseconds: 480), () {
        if (mounted) setState(() => _autoAction = fox.FoxAction.idle);
      });

    } else if (pick < 0.62) {
      // 7 % – Rollen / Tanzen (Überschlag)
      setState(() => _autoAction = fox.FoxAction.roll);
      _actionResetTimer?.cancel();
      _actionResetTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _autoAction = fox.FoxAction.idle);
      });

    } else if (pick < 0.72) {
      // 10 % – Schnelles Wackeln links-rechts (Winken)
      _doWiggle();

    } else {
      // 28 % – Idle (ruhig atmen, blinzeln)
      setState(() => _autoAction = fox.FoxAction.idle);
    }
  }

  void _doWiggle() {
    // Lumo wackelt schnell hin und her: run rechts → links → stopp
    setState(() {
      _wanderFrom   = _wanderX;
      _wanderTarget = _wanderX + 18;
      _autoAction   = fox.FoxAction.run;
      _autoFacingLeft = false;
    });
    _wanderCtrl.forward(from: 0);

    _actionResetTimer?.cancel();
    _actionResetTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _wanderCtrl.stop();
      setState(() {
        _wanderFrom   = _wanderX;
        _wanderTarget = _wanderX - 18;
        _autoFacingLeft = true;
      });
      _wanderCtrl.forward(from: 0);
      _wiggleTimer2 = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _wanderCtrl.stop();
        setState(() {
          _wanderTarget = _wanderFrom;
          _wanderFrom   = _wanderX;
          _autoAction   = fox.FoxAction.idle;
          _autoFacingLeft = false;
        });
      });
    });
  }

  // ── Langeweile-Check ──────────────────────────────────────────────────
  // Wenn > 30 Sekunden kein Tap: Lumo zeigt Langeweile-Bubble

  void _scheduleBoredCheck() {
    _boredTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      final sinceLastTap = _lastTap == null
          ? const Duration(hours: 1)
          : DateTime.now().difference(_lastTap!);
      if (sinceLastTap.inSeconds >= 30 && _currentSpeech == null) {
        _showSpeech('Psst… bin ich noch sichtbar? 👀', style: _BubbleStyle.bored);
      }
      _scheduleBoredCheck();
    });
  }

  // ── Speech-Bubble Logik ───────────────────────────────────────────────

  void _scheduleSpeech() {
    // Alle 8-15 Sekunden eine Speech-Bubble (häufiger = lebendiger)
    _speechTimer = Timer(
      Duration(seconds: 8 + _rng.nextInt(8)),
      () {
        if (!mounted) return;
        if (_currentSpeech == null) {
          _showSpeech(_nextSpeechText());
        }
        _scheduleSpeech();
      },
    );
  }

  void _showSpeech(String text, {_BubbleStyle style = _BubbleStyle.normal}) {
    _speechClearTimer?.cancel();
    setState(() {
      _currentSpeech = text;
      _bubbleStyle   = style;
    });
    _speechClearTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _currentSpeech = null);
    });
  }

  // ── Tap-Handler mit Charakter ─────────────────────────────────────────

  void _onTap() {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final isFirstTapToday = _lastTap == null ||
        now.difference(_lastTap!).inHours > 1;
    _lastTap = now;
    _tapCount++;

    // Aktion
    final useRoll = _tapCount % 4 == 0;
    _hopCtrl.forward(from: 0);
    setState(() {
      _tapAction = useRoll ? fox.FoxAction.roll : fox.FoxAction.jump;
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(
      Duration(milliseconds: useRoll ? 700 : 480),
      () {
        if (mounted) setState(() => _tapAction = fox.FoxAction.idle);
      },
    );

    // Tap-Reaktion als Bubble
    String reaction;
    if (isFirstTapToday) {
      // Erste Interaktion: persönliche Begrüßung
      reaction = _pickRandom(_greetingPhrases);
    } else if (_tapCount <= _tapReactions.length) {
      reaction = _tapReactions[_tapCount - 1];
    } else {
      // Danach: zufällig witzige Reaktion
      reaction = _pickRandom(_funnyPhrases);
    }
    _showSpeech(reaction, style: _BubbleStyle.reaction);

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
        final hopY   = -math.sin(_hopCtrl.value * math.pi) * 26.0;
        final offsetX = _wanderX;

        return SizedBox(
          width:  widget.size + _maxWander * 2,
          height: widget.size + 80,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Speech-Bubble oberhalb
              Positioned(
                bottom: widget.size - 4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
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
                          style: _bubbleStyle,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),

              // Fuchs
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

// ── Hilfsenum Tageszeit ───────────────────────────────────────────────────

enum _TimeOfDay { morning, midday, afternoon, evening }

// ── Bubble-Style ──────────────────────────────────────────────────────────

enum _BubbleStyle { normal, reaction, bored }

// ── Speech-Bubble Widget ──────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    super.key,
    required this.text,
    this.style = _BubbleStyle.normal,
  });

  final String      text;
  final _BubbleStyle style;

  static Color _bgColor(_BubbleStyle s) => switch (s) {
    _BubbleStyle.normal   => Colors.white,
    _BubbleStyle.reaction => const Color(0xFFFFF7E6),
    _BubbleStyle.bored    => const Color(0xFFF0F9FF),
  };

  static Color _borderColor(_BubbleStyle s) => switch (s) {
    _BubbleStyle.normal   => Colors.white,
    _BubbleStyle.reaction => const Color(0xFFFFD97D),
    _BubbleStyle.bored    => const Color(0xFFBAE6FD),
  };

  @override
  Widget build(BuildContext context) {
    final bg     = _bgColor(style);
    final border = _borderColor(style);
    return CustomPaint(
      painter: _BubbleTailPainter(color: bg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.11),
              blurRadius: 14,
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
  const _BubbleTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2 - 8, size.height)
        ..lineTo(size.width / 2,     size.height + 11)
        ..lineTo(size.width / 2 + 8, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) => old.color != color;
}
