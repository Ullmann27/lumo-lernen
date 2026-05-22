// ════════════════════════════════════════════════════════════════════════
// LUMO HINT BUBBLE — kleine Lumo-Tipp-Sprechblase
// ════════════════════════════════════════════════════════════════════════
// Wird unten links im Lumo-Cards Screen platziert. Zeigt einen kurzen
// kontextabhaengigen Tipp wie "Lege eine passende Farbe oder Zahl."
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoHintBubble extends StatelessWidget {
  const LumoHintBubble({
    super.key,
    required this.message,
    this.showFox = true,
  });

  final String message;
  final bool showFox;

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.2, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(message),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showFox) ...[
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A2F).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text('🦊', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C2D12),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
