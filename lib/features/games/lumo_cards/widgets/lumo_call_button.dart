// ════════════════════════════════════════════════════════════════════════
// LUMO CALL BUTTON — 'LUMO!'-Ruf wenn der Spieler bald gewinnt
// ════════════════════════════════════════════════════════════════════════
// Klassische Karten-Spielmechanik: wenn der Spieler nur noch EINE Karte
// hat, kann er den Spielnamen 'LUMO!' rufen. Tut er das nicht, kann der
// Gegner spaeter Strafkarten geben (im MVP zaehlen wir nur den Klick als
// Bonus +1 Stern und visuelles Feedback).
//
// 'LUMO' ist unser eigener Spielname - kein fremdes Trade-Dress.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LumoCallButton extends StatefulWidget {
  const LumoCallButton({
    super.key,
    required this.onPressed,
    required this.cardsLeft,
    required this.totalCards,
  });

  /// Wird gerufen wenn das Kind den Button drueckt.
  final VoidCallback onPressed;

  /// Karten in der Hand des Spielers.
  final int cardsLeft;

  /// Maximale Karten am Anfang (fuer den Progress-Indikator).
  final int totalCards;

  @override
  State<LumoCallButton> createState() => _LumoCallButtonState();
}

class _LumoCallButtonState extends State<LumoCallButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Button leuchtet nur wenn der Spieler bald gewinnt (1-2 Karten).
    final isUrgent = widget.cardsLeft <= 2;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final t = isUrgent
            ? (math.sin(_pulse.value * math.pi * 2) * 0.5 + 0.5)
            : 0.0;
        final scale = 1.0 + t * 0.06;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Opacity(
        opacity: isUrgent ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: isUrgent
                ? [
                    BoxShadow(
                      color: const Color(0xFFFCD34D).withOpacity(0.6),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isUrgent ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A4C), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.65), width: 2.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: Color(0xFFFCD34D), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.cardsLeft}/${widget.totalCards}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'LUMO!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUrgent
                          ? 'Ruf jetzt!'
                          : 'Bald nur noch eine',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
