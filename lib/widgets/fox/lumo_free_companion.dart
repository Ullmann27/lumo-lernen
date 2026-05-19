// ════════════════════════════════════════════════════════════════════════
// LUMO FREE COMPANION
// ════════════════════════════════════════════════════════════════════════
// Heinz' Auftrag: 'Lumo soll nicht mehr im rechten Kasten gefangen sein.
// Er soll als frei beweglicher, lebendiger Companion frei ueber der App
// existieren. Kind tippt irgendwo -> Lumo laeuft hin. Tap auf Lumo ->
// Reaktion. Doppel-Tap -> Kitzeln/Lachen. Lumo kehrt zur Home-Position
// zurueck. Mundbewegung an VoiceStatus gekoppelt.'
//
// Architektur:
//   - LumoFreeCompanion ist ein Overlay-Layer der ueber der App liegt
//   - Hintergrund-Tap (auf "freie Flaeche") = move-to
//   - Tap auf Lumo = Reaktion (Winken)
//   - Doppel-Tap auf Lumo = Kitzeln/Lachen
//   - Long-Press = Erklaerung sprechen
//   - Auto-Return-Home nach 8s Inaktivitaet
//
// Wichtig:
//   - Hintergrund-Hit-Test nur sammelt taps, blockiert keine Buttons.
//   - Companion-Hit-Test ist klein (nur auf dem Avatar selbst).
//   - SafeArea respektieren (Home-Position dynamisch).
//   - Responsive: kleiner auf Handy, groesser auf Tablet.
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/lumo_voice.dart';

enum LumoCompanionState {
  idle,
  walking,
  speaking,
  waving,
  tickled,
  celebrating,
  comforting,
  returningHome,
}

class LumoFreeCompanion extends StatefulWidget {
  const LumoFreeCompanion({
    super.key,
    this.foxAssetPath = 'assets/lumo_sprite_pack/lumo_main.png',
    this.size,
    this.homeAlignment = Alignment.bottomRight,
    this.homeMargin = const EdgeInsets.fromLTRB(0, 0, 28, 28),
    this.tapEnabled = true,
    this.returnHomeAfter = const Duration(seconds: 8),
  });

  /// Pfad zum Fox-Sprite (Fallback Emoji wenn nicht ladbar).
  final String foxAssetPath;

  /// Avatar-Groesse. Wenn null wird responsive berechnet.
  final double? size;

  /// Wo Lumo zur Home-Position zurueckkehrt.
  final Alignment homeAlignment;

  /// Margin von der Home-Ecke.
  final EdgeInsets homeMargin;

  /// Wenn false reagiert Lumo nicht auf Taps (nur visueller Idle).
  final bool tapEnabled;

  /// Nach dieser Zeit ohne Tap kehrt Lumo nach Hause zurueck.
  final Duration returnHomeAfter;

  @override
  State<LumoFreeCompanion> createState() => _LumoFreeCompanionState();
}

class _LumoFreeCompanionState extends State<LumoFreeCompanion>
    with TickerProviderStateMixin {
  // ── State ──
  LumoCompanionState _state = LumoCompanionState.idle;
  Offset? _currentPos;       // absolute Position des Avatar-Centers
  Offset? _homePos;          // berechnete Home-Position
  String _bubbleText = '';
  bool _facingRight = true;
  bool _mouthOpen = false;

  Timer? _returnTimer;
  Timer? _bubbleTimer;
  Timer? _mouthTimer;
  Timer? _wanderTimer;        // NEU: autonomes Wandern
  Timer? _idleBehaviorTimer;  // NEU: zufaellige Idle-Ticks
  VoidCallback? _voiceListener;

  final math.Random _rng = math.Random();

  // ── Controllers ──
  late final AnimationController _moveCtrl;
  late final AnimationController _bobCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _tickleCtrl;
  late final AnimationController _bubbleCtrl;
  // Lebens-Controllers (intern bewegen, auch wenn Lumo steht)
  late final AnimationController _breathCtrl;
  late final AnimationController _tailCtrl;
  late final AnimationController _blinkCtrl;
  Timer? _blinkTimer;

  Offset _moveFrom = Offset.zero;
  Offset _moveTo = Offset.zero;

  @override
  void initState() {
    super.initState();

    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _tickleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    // ── INTERNE LEBENS-ANIMATIONEN (Heinz: 'Lumo darf kein Standbild sein') ──
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _tailCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    // Augen-Blinzeln: alle 3-6 Sek einmal
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (!mounted) return;
      if (_rng.nextDouble() < 0.6) {
        _blinkCtrl.forward().then((_) {
          if (!mounted) return;
          _blinkCtrl.reverse();
        });
      }
    });

    // VoiceStatus -> mouthOpen Animation
    _voiceListener = () => _onVoiceStatus(LumoVoice.instance.status.value);
    LumoVoice.instance.status.addListener(_voiceListener!);

    // ── Autonomes Wandern starten ──
    // Heinz: 'Lumo soll selbstständig sein, ganz alleine, nicht der
    // Maus folgen.' Alle 8-15s zu zufaelligem Safe-Zone-Punkt laufen.
    _wanderTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _maybeAutoWander();
    });
    // ── Zufaellige Idle-Mikro-Reaktionen ──
    _idleBehaviorTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _maybeIdleBehavior();
    });
  }

  void _onVoiceStatus(VoiceStatus s) {
    if (!mounted) return;
    if (s == VoiceStatus.speaking) {
      _mouthTimer?.cancel();
      _mouthTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
        if (!mounted) return;
        setState(() => _mouthOpen = !_mouthOpen);
      });
      if (_state != LumoCompanionState.walking) {
        setState(() => _state = LumoCompanionState.speaking);
      }
    } else {
      _mouthTimer?.cancel();
      _mouthTimer = null;
      if (mounted) {
        setState(() {
          _mouthOpen = false;
          if (_state == LumoCompanionState.speaking) {
            _state = LumoCompanionState.idle;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _returnTimer?.cancel();
    _bubbleTimer?.cancel();
    _mouthTimer?.cancel();
    _wanderTimer?.cancel();
    _idleBehaviorTimer?.cancel();
    _blinkTimer?.cancel();
    if (_voiceListener != null) {
      LumoVoice.instance.status.removeListener(_voiceListener!);
    }
    _moveCtrl.dispose();
    _bobCtrl.dispose();
    _waveCtrl.dispose();
    _tickleCtrl.dispose();
    _bubbleCtrl.dispose();
    _breathCtrl.dispose();
    _tailCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  // ── Responsive Avatar-Groesse ──
  // Heinz: 'Mindestens 50% groesser'.
  // Vorher: 110 / 140 / 170 / 200
  // Jetzt:  170 / 215 / 255 / 305 (~50% groesser)
  double _effectiveSize(Size screen) {
    if (widget.size != null) return widget.size!;
    final w = screen.width;
    if (w < 380) return 170;
    if (w < 600) return 215;
    if (w < 900) return 255;
    return 305;
  }

  // ── FRAME-BASIERTE WALK-CYCLE ──
  // Heinz: 'Lumo darf kein Standbild sein - er soll laufen wie im Zeichentrick'.
  // 8 Walk-Frames (sprite pack vom 19.05.2026) werden bei Bewegung zykliert.
  // Bei stillstand wird das main-Sprite genutzt.
  String _currentSprite() {
    // Beim Laufen: Walk-Frames zykeln
    if (_moveCtrl.isAnimating) {
      // 8 Frames, 4 Schritte pro Sekunde -> Frame-Index basiert auf Zeit
      final t = _moveCtrl.lastElapsedDuration?.inMilliseconds ?? 0;
      final frameIdx = ((t / 110).floor() % 8) + 1;  // 1..8
      final dir = _facingRight ? 'walk_right' : 'walk_left';
      // Frame-Format: walk_right_01.png .. walk_right_08.png
      final fname = '${dir}_${frameIdx.toString().padLeft(2, '0')}.png';
      return 'assets/lumo_sprite_pack/$dir/$fname';
    }
    // Beim Jubeln: Cheer-Frame
    if (_state == LumoCompanionState.celebrating ||
        _state == LumoCompanionState.tickled) {
      final t = _tickleCtrl.lastElapsedDuration?.inMilliseconds ?? 0;
      final frameIdx = ((t / 130).floor() % 8) + 1;
      final fname = 'cheer_${frameIdx.toString().padLeft(2, '0')}.png';
      return 'assets/lumo_sprite_pack/cheer/$fname';
    }
    // Default: main-Sprite (das schoene Lumo-Stand-Bild)
    return widget.foxAssetPath;
  }

  // ── Public API ──
  void moveTo(Offset target) {
    if (!widget.tapEnabled) return;
    final from = _currentPos ?? _homePos ?? target;
    _moveFrom = from;
    _moveTo = target;

    // Distanz-basierte Dauer (300-1200ms)
    final dist = (target - from).distance;
    final ms = (300 + dist * 1.4).clamp(300, 1200).round();
    _moveCtrl.duration = Duration(milliseconds: ms);

    setState(() {
      _state = LumoCompanionState.walking;
      _facingRight = target.dx >= from.dx;
    });
    _moveCtrl.reset();
    _moveCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _currentPos = _moveTo;
        _state = LumoCompanionState.idle;
      });
      _scheduleReturnHome();
    });
  }

  // ── AUTONOMES WANDERN ──
  // Heinz: 'Lumo soll selbstständig sein. Etwas einfallen lassen.'
  //
  // Lumo wandert von alleine alle 8-15s zu einer SICHEREN ZONE:
  //   - unteres Viertel (y > 0.72 * height)
  //   - oder ganz rechts (x > 0.78 * width) - aber NUR unten
  // NIEMALS in der Mitte stehen, wo die Spielkarten sind. So
  // blockiert Lumo nichts und wirkt trotzdem lebendig.
  DateTime _lastWanderAt = DateTime.now();
  double _wanderCooldownSec = 9.0;

  void _maybeAutoWander() {
    if (!mounted) return;
    if (_state == LumoCompanionState.walking) return;
    if (_state == LumoCompanionState.speaking) return;

    final secsSince = DateTime.now().difference(_lastWanderAt).inSeconds;
    if (secsSince < _wanderCooldownSec) return;

    // Naechste Wanderung in 8-15 Sekunden
    _wanderCooldownSec = 8.0 + _rng.nextDouble() * 7.0;
    _lastWanderAt = DateTime.now();

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final s = box.size;
    final target = _pickSafeWanderPoint(s);
    _autoWalkTo(target);
  }

  /// Waehlt einen zufaelligen Punkt in den "sicheren" Bildschirm-Zonen
  /// (untere Raender, rechts unten). Vermeidet die Mitte wo Cards sind.
  Offset _pickSafeWanderPoint(Size s) {
    // 4 Zonen, alle im unteren Drittel oder rechts-unten:
    final zones = <Rect>[
      // rechts unten (Home-Bereich)
      Rect.fromLTWH(s.width * 0.72, s.height * 0.72,
          s.width * 0.24, s.height * 0.22),
      // mitte unten
      Rect.fromLTWH(s.width * 0.40, s.height * 0.78,
          s.width * 0.30, s.height * 0.16),
      // links unten
      Rect.fromLTWH(s.width * 0.05, s.height * 0.78,
          s.width * 0.25, s.height * 0.16),
      // ganz rechts mittig (Random-Visit)
      Rect.fromLTWH(s.width * 0.84, s.height * 0.40,
          s.width * 0.14, s.height * 0.30),
    ];
    final zone = zones[_rng.nextInt(zones.length)];
    return Offset(
      zone.left + _rng.nextDouble() * zone.width,
      zone.top + _rng.nextDouble() * zone.height,
    );
  }

  void _autoWalkTo(Offset target) {
    if (!mounted) return;
    final from = _currentPos ?? _homePos ?? target;
    _moveFrom = from;
    _moveTo = target;

    final dist = (target - from).distance;
    final ms = (500 + dist * 1.4).clamp(500, 1600).round();
    _moveCtrl.duration = Duration(milliseconds: ms);

    setState(() {
      _state = LumoCompanionState.walking;
      _facingRight = target.dx >= from.dx;
    });
    _moveCtrl.reset();
    _moveCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _currentPos = _moveTo;
        _state = LumoCompanionState.idle;
      });
    });
  }

  /// Zufaellige Idle-Mikro-Reaktionen: Lumo macht ab und zu
  /// kleine Sachen auch wenn niemand interagiert.
  void _maybeIdleBehavior() {
    if (!mounted) return;
    if (_state != LumoCompanionState.idle) return;
    if (_bubbleText.isNotEmpty) return;

    final roll = _rng.nextDouble();
    if (roll < 0.18) {
      // 18%: kurzes Winken
      setState(() => _state = LumoCompanionState.waving);
      _waveCtrl.reset();
      _waveCtrl.forward().then((_) {
        if (!mounted) return;
        setState(() => _state = LumoCompanionState.idle);
      });
    } else if (roll < 0.30) {
      // 12%: kurzer Spruch
      final spruch = _idleSayings[_rng.nextInt(_idleSayings.length)];
      _showBubble(spruch, duration: const Duration(milliseconds: 2400));
    } else if (roll < 0.42) {
      // 12%: kurz drehen (Richtung wechseln)
      setState(() => _facingRight = !_facingRight);
    }
    // 58%: nichts - bleibt entspannt
  }

  static const _idleSayings = [
    'Was machen wir jetzt?',
    'Klicke ruhig auf etwas!',
    'Ich warte hier auf dich.',
    'Hihi 😊',
    'Bereit für Abenteuer?',
    'Was lernen wir heute?',
  ];

  void returnHome() {
    final home = _homePos;
    if (home == null) return;
    final from = _currentPos ?? home;
    _moveFrom = from;
    _moveTo = home;

    final dist = (home - from).distance;
    final ms = (400 + dist * 1.2).clamp(400, 1100).round();
    _moveCtrl.duration = Duration(milliseconds: ms);

    setState(() {
      _state = LumoCompanionState.returningHome;
      _facingRight = home.dx >= from.dx;
    });
    _moveCtrl.reset();
    _moveCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _currentPos = home;
        _state = LumoCompanionState.idle;
      });
    });
  }

  void _scheduleReturnHome() {
    _returnTimer?.cancel();
    _returnTimer = Timer(widget.returnHomeAfter, () {
      if (!mounted) return;
      if (_state == LumoCompanionState.idle) {
        returnHome();
      }
    });
  }

  void _showBubble(String text, {Duration? duration}) {
    setState(() => _bubbleText = text);
    _bubbleCtrl.forward();
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(duration ?? const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _bubbleCtrl.reverse();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _bubbleText = '');
      });
    });
  }

  static const _waveLines = [
    'Hihi! Was machen wir als Nächstes?',
    'Hallo! Schön, dass du da bist!',
    'Bereit für ein Abenteuer?',
    'Wir schaffen das zusammen!',
    'Magst du mit mir spielen?',
    'Was möchtest du heute lernen?',
    'Du bist großartig! ⭐',
    'Hey! Tipp doch eine Karte an.',
    'Lust auf Mathe oder Lesen?',
    'Ich freue mich auf dich!',
  ];
  static const _tickleLines = [
    'Hihihi! Das kitzelt!',
    'Iiiiih! 🌟',
    'Hör auf, hihi!',
    'Du bist witzig!',
    'Hahaha! 😄',
    'Au au au, kitzlig!',
    'Wuiii! Nochmal!',
    'Du machst mich glücklich! 💛',
  ];

  void _onTapLumo() {
    if (!widget.tapEnabled) return;
    setState(() => _state = LumoCompanionState.waving);
    _waveCtrl.reset();
    _waveCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _state = LumoCompanionState.idle);
    });
    final txt = _waveLines[math.Random().nextInt(_waveLines.length)];
    _showBubble(txt);
    _trySpeak(txt);
    _scheduleReturnHome();
  }

  void _onDoubleTapLumo() {
    if (!widget.tapEnabled) return;
    setState(() => _state = LumoCompanionState.tickled);
    _tickleCtrl.reset();
    _tickleCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _state = LumoCompanionState.idle);
    });
    final txt = _tickleLines[math.Random().nextInt(_tickleLines.length)];
    _showBubble(txt, duration: const Duration(milliseconds: 2000));
    _scheduleReturnHome();
  }

  void _onLongPressLumo() {
    if (!widget.tapEnabled) return;
    const txt = 'Tippe irgendwo – ich komme zu dir!';
    _showBubble(txt, duration: const Duration(milliseconds: 3200));
    _trySpeak(txt);
    _scheduleReturnHome();
  }

  void _trySpeak(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {
      // Silent fail - Voice ist optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = Size(constraints.maxWidth, constraints.maxHeight);
        final foxSize = _effectiveSize(screen);

        // Home-Position dynamisch berechnen
        _homePos ??= _calcHomePos(screen, foxSize);
        _currentPos ??= _homePos;

        return AnimatedBuilder(
          animation: Listenable.merge([
            _moveCtrl,
            _bobCtrl,
            _waveCtrl,
            _tickleCtrl,
            _bubbleCtrl,
            _breathCtrl,
            _tailCtrl,
            _blinkCtrl,
          ]),
          builder: (context, _) {
            // Aktuelle Position (waehrend Move animiert, sonst _currentPos)
            Offset pos;
            if (_moveCtrl.isAnimating) {
              final t = Curves.easeInOutCubic.transform(_moveCtrl.value);
              pos = Offset.lerp(_moveFrom, _moveTo, t)!;
            } else {
              pos = _currentPos ?? Offset.zero;
            }

            // Idle-Bobbing
            final bob = math.sin(_bobCtrl.value * math.pi) * 2.5;
            // Walk-Bob (waehrend Bewegung)
            final walkBob = _moveCtrl.isAnimating
                ? math.sin(_moveCtrl.value * math.pi * 6) * 3.5
                : 0.0;
            // Wave-Bob (kleiner Hopser beim Winken)
            final waveBob = _state == LumoCompanionState.waving
                ? -math.sin(_waveCtrl.value * math.pi) * 8
                : 0.0;
            // Tickle: kleine Wackel-Rotation
            final tickleRot = _state == LumoCompanionState.tickled
                ? math.sin(_tickleCtrl.value * math.pi * 6) * 0.12
                : 0.0;
            final tickleScale = _state == LumoCompanionState.tickled
                ? 1.0 + math.sin(_tickleCtrl.value * math.pi) * 0.08
                : 1.0;

            // ── LEBENS-ANIMATIONEN (immer aktiv) ────────────────────
            // Atem: vertikale Skalierung 1.0..1.04 (Brust hebt sich)
            final breathScale =
                1.0 + math.sin(_breathCtrl.value * math.pi) * 0.04;
            // Schwanz-Winkel: -0.35..+0.35 rad (~20° wedeln)
            final tailAngle =
                math.sin(_tailCtrl.value * math.pi * 2 - math.pi / 2) * 0.35;
            // Blink: 0 (Augen offen) ... 1 (Augen ganz zu)
            final blinkAmt = _blinkCtrl.value;

            final yOff = bob + walkBob + waveBob;
            final renderX = pos.dx - foxSize / 2;
            final renderY = pos.dy - foxSize + yOff;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Heinz' Feedback: 'Lumo darf nichts ueberdecken /
                // blockieren'. Deshalb KEIN Hintergrund-Tap-Detector
                // mehr - Buttons darunter funktionieren direkt.
                // Lumo wandert von alleine in sicheren Zonen.

                // ── Sprechblase ueber Lumo ──
                if (_bubbleText.isNotEmpty)
                  Positioned(
                    left: (pos.dx - 130)
                        .clamp(8.0, math.max(8.0, screen.width - 268)),
                    top: (renderY - 70).clamp(8.0, screen.height - 100),
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: Curves.elasticOut
                            .transform(_bubbleCtrl.value)
                            .clamp(0.0, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: _SpeechBubble(text: _bubbleText),
                      ),
                    ),
                  ),

                // ── Lumo selbst ──
                // Heinz: 'Lumo darf nichts ueberdecken'. Daher:
                // HitArea NUR auf dem Zentrum des Avatars (60% Breite,
                // 70% Hoehe). Der Rest der Bounding-Box laesst Taps
                // durch zu den darunterliegenden Buttons.
                Positioned(
                  left: renderX,
                  top: renderY,
                  child: SizedBox(
                    width: foxSize,
                    height: foxSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Tap-Detector NUR auf dem Zentrum (60% x 70%)
                        Positioned(
                          left: foxSize * 0.20,
                          top: foxSize * 0.15,
                          width: foxSize * 0.60,
                          height: foxSize * 0.70,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _onTapLumo,
                            onDoubleTap: _onDoubleTapLumo,
                            onLongPress: _onLongPressLumo,
                          ),
                        ),
                        // Visueller Avatar (IgnorePointer = Tap geht
                        // durch zu darunterliegenden Buttons wenn
                        // er nicht ins HitArea-Center faellt)
                        IgnorePointer(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateZ(tickleRot)
                              ..scale(
                                  (_facingRight ? 1.0 : -1.0) * tickleScale,
                                  tickleScale,
                                  1.0),
                            child: SizedBox(
                              width: foxSize,
                              height: foxSize,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Bodenschatten
                                  Positioned(
                                    bottom: 2,
                                    child: Container(
                                      width: foxSize * 0.62,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.32),
                                        borderRadius:
                                            BorderRadius.circular(foxSize),
                                      ),
                                    ),
                                  ),
                                  // SCHWANZ-Overlay (hinter dem Sprite,
                                  // wedelt links/rechts) - Heinz wollte
                                  // Schwanzbewegung
                                  Positioned(
                                    bottom: foxSize * 0.18,
                                    left: foxSize * 0.05,
                                    child: Transform.rotate(
                                      angle: tailAngle,
                                      alignment: Alignment.bottomRight,
                                      child: Container(
                                        width: foxSize * 0.18,
                                        height: foxSize * 0.34,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFF97316),
                                              Color(0xFFFB923C),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(foxSize),
                                            topRight: Radius.circular(foxSize),
                                            bottomLeft:
                                                Radius.circular(foxSize * 0.4),
                                            bottomRight:
                                                Radius.circular(foxSize * 0.6),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(1, 2),
                                            ),
                                          ],
                                        ),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            width: foxSize * 0.10,
                                            height: foxSize * 0.10,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFFFFFF),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Fox sprite mit ATEM-SKALIERUNG
                                  // (vertikal pulsiert leicht - "atmet")
                                  // FRAME-CYCLE: beim Laufen Walk-Sprites,
                                  // beim Jubeln Cheer-Sprites (Heinz' ZIP)
                                  Transform.scale(
                                    scaleY: breathScale,
                                    alignment: Alignment.bottomCenter,
                                    child: Image.asset(
                                      _currentSprite(),
                                      width: foxSize,
                                      height: foxSize,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, __, ___) =>
                                          _FallbackFox(size: foxSize),
                                    ),
                                  ),
                                  // AUGEN-BLINK-Overlay: zwei kleine
                                  // Lidschlag-Streifen wenn _blinkCtrl > 0
                                  if (blinkAmt > 0.05)
                                    Positioned(
                                      top: foxSize * 0.32,
                                      left: foxSize * 0.28,
                                      child: SizedBox(
                                        width: foxSize * 0.44,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: List.generate(
                                              2,
                                              (i) => Container(
                                                    width: foxSize * 0.10,
                                                    height: foxSize *
                                                        0.06 *
                                                        blinkAmt,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF97316),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              foxSize),
                                                    ),
                                                  )),
                                        ),
                                      ),
                                    ),
                                  // Mund-Highlight (Voice-synchron)
                                  if (_mouthOpen)
                                    Positioned(
                                      top: foxSize * 0.48,
                                      child: Container(
                                        width: foxSize * 0.16,
                                        height: foxSize * 0.10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C2D12),
                                          borderRadius:
                                              BorderRadius.circular(foxSize),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.4),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Offset _calcHomePos(Size screen, double foxSize) {
    final r = widget.homeAlignment.resolve(TextDirection.ltr);
    // Wir wollen den Center-Bottom des Fuchses am Home-Punkt
    final cx = ((r.x + 1) / 2) * screen.width;
    final cy = ((r.y + 1) / 2) * screen.height;
    // Margin anwenden
    return Offset(
      cx - widget.homeMargin.right + widget.homeMargin.left,
      cy - widget.homeMargin.bottom + widget.homeMargin.top,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Speech-Bubble
// ────────────────────────────────────────────────────────────────────────
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260, minWidth: 130),
      child: CustomPaint(
        painter: _BubblePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C2D12),
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glow hinter Bubble
    final glowPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-2, -2, w + 4, h + 4 - 6),
          const Radius.circular(18)),
      glowPaint,
    );

    // Body
    final body = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h - 6), const Radius.circular(18));
    canvas.drawRRect(rect, body);

    // Outline
    final outline = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rect, outline);

    // Tail
    final tail = Path()
      ..moveTo(w * 0.42, h - 6)
      ..lineTo(w * 0.52, h)
      ..lineTo(w * 0.56, h - 6)
      ..close();
    canvas.drawPath(tail, body);
    canvas.drawPath(tail, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ────────────────────────────────────────────────────────────────────────
// Fallback wenn Sprite fehlt
// ────────────────────────────────────────────────────────────────────────
class _FallbackFox extends StatelessWidget {
  const _FallbackFox({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF97316),
        shape: BoxShape.circle,
      ),
      child: const Center(child: Text('🦊', style: TextStyle(fontSize: 50))),
    );
  }
}
