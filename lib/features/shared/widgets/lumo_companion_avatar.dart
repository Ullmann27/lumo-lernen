import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Reaktionszustaende des Lumo-Companion.
enum LumoCompanionMood {
  /// Ruhig, atmet leicht (Standard).
  idle,

  /// Freut sich - hopst leicht, Augen-Glanz.
  happy,

  /// Denkt nach - Kopf zur Seite, Fragezeichen.
  think,

  /// Bejubelt Erfolg - groesserer Hopser, Konfetti um den Kopf.
  cheer,

  /// Hilft - winkt leicht mit der Pfote.
  help,

  /// Traurig/mitfuehlend - leicht abgesenkt.
  sad,
}

extension LumoCompanionMoodMeta on LumoCompanionMood {
  String get emoji {
    switch (this) {
      case LumoCompanionMood.idle: return '🦊';
      case LumoCompanionMood.happy: return '🦊';
      case LumoCompanionMood.think: return '🤔';
      case LumoCompanionMood.cheer: return '🦊';
      case LumoCompanionMood.help: return '🦊';
      case LumoCompanionMood.sad: return '🦊';
    }
  }

  /// Sticker-Style Symbol als Zusatz zum Fuchs (oben rechts).
  String? get accentEmoji {
    switch (this) {
      case LumoCompanionMood.happy: return '✨';
      case LumoCompanionMood.think: return '💭';
      case LumoCompanionMood.cheer: return '🎉';
      case LumoCompanionMood.help: return '👋';
      case LumoCompanionMood.sad: return '💙';
      default: return null;
    }
  }
}

/// Konsolidierter Lumo-Avatar.
///
/// Eine Datei - alle Praesenzzustaende. Bestehende Widgets
/// (embedded_lumo_fox / free_lumo_fox / lumo_living_avatar) bleiben
/// unangetastet fuer Rueckwaertskompatibilitaet, koennen aber
/// Stueck fuer Stueck durch LumoCompanionAvatar ersetzt werden.
///
/// Animationen:
///   - idle:   leichtes Atmen (Scale 0.99-1.01, 2.4s loop)
///   - happy:  vertikales Hopsen (-3px, 0.8s loop)
///   - think:  leichte Rotation (-3° bis +3°, 1.6s loop)
///   - cheer:  hopst groesser (-7px, 0.4s loop)
///   - help:   winkt mit Pfote-Akzent
///   - sad:    statisch abgesenkt
class LumoCompanionAvatar extends StatefulWidget {
  const LumoCompanionAvatar({
    super.key,
    this.mood = LumoCompanionMood.idle,
    this.size = 80,
    this.showSpeechBubble = false,
    this.speechText,
    this.onTap,
  });

  final LumoCompanionMood mood;
  final double size;

  /// Optional eine Speech-Bubble rechts vom Fuchs.
  final bool showSpeechBubble;
  final String? speechText;
  final VoidCallback? onTap;

  @override
  State<LumoCompanionAvatar> createState() => _LumoCompanionAvatarState();
}

class _LumoCompanionAvatarState extends State<LumoCompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LumoCompanionAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _ctrl.duration = _durationFor(widget.mood);
      _ctrl
        ..reset()
        ..repeat(reverse: widget.mood != LumoCompanionMood.sad);
    }
  }

  Duration _durationFor(LumoCompanionMood mood) {
    switch (mood) {
      case LumoCompanionMood.idle: return const Duration(milliseconds: 2400);
      case LumoCompanionMood.happy: return const Duration(milliseconds: 800);
      case LumoCompanionMood.think: return const Duration(milliseconds: 1600);
      case LumoCompanionMood.cheer: return const Duration(milliseconds: 400);
      case LumoCompanionMood.help: return const Duration(milliseconds: 1200);
      case LumoCompanionMood.sad: return const Duration(milliseconds: 3000);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          double translateY = 0;
          double scale = 1.0;
          double rotation = 0;
          switch (widget.mood) {
            case LumoCompanionMood.idle:
              scale = 1.0 + (t - 0.5) * 0.02;
              break;
            case LumoCompanionMood.happy:
              translateY = -3 * math.sin(t * math.pi);
              break;
            case LumoCompanionMood.think:
              rotation = (t - 0.5) * 0.10;
              break;
            case LumoCompanionMood.cheer:
              translateY = -7 * math.sin(t * math.pi);
              scale = 1.0 + math.sin(t * math.pi) * 0.05;
              break;
            case LumoCompanionMood.help:
              rotation = math.sin(t * math.pi * 2) * 0.05;
              break;
            case LumoCompanionMood.sad:
              translateY = 2;
              break;
          }
          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(scale: scale, child: _buildAvatar()),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    final accent = widget.mood.accentEmoji;
    final hasBubble = widget.showSpeechBubble && widget.speechText != null;
    final avatarBox = Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            LumoColors.orangeLight,
            LumoColors.orange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Text(
        widget.mood.emoji,
        style: TextStyle(fontSize: widget.size * 0.55),
      ),
    );
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarBox,
        if (accent != null)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(accent, style: const TextStyle(fontSize: 14)),
            ),
          ),
      ],
    );
    if (!hasBubble) return stack;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        stack,
        const SizedBox(width: 12),
        Flexible(child: _SpeechBubble(text: widget.speechText!)),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: CustomPaint(
        painter: _BubbleTailPainter(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          margin: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LumoRadius.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: LumoColors.orange.withOpacity(0.25), width: 1.2),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: LumoColors.ink700,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(10, size.height / 2 - 6)
      ..lineTo(0, size.height / 2)
      ..lineTo(10, size.height / 2 + 6)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
