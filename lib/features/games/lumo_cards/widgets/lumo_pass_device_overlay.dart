// ════════════════════════════════════════════════════════════════════════
// LUMO PASS DEVICE OVERLAY — Tablet uebergeben
// ════════════════════════════════════════════════════════════════════════
// Voll deckendes Overlay zwischen den Zuegen. Verhindert dass der naechste
// Spieler die Karten des vorherigen Spielers sieht.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoPassDeviceOverlay extends StatelessWidget {
  const LumoPassDeviceOverlay({
    super.key,
    required this.nextPlayerName,
    required this.onReady,
  });

  final String nextPlayerName;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C2D12), Color(0xFF431407)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🦊', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 18),
                Text(
                  'Gib das Tablet an',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextPlayerName,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFCD34D),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: onReady,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFCD34D),
                    foregroundColor: const Color(0xFF7C2D12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99)),
                  ),
                  child: const Text(
                    'Bereit',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Tippe wenn du es bist.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
