// ════════════════════════════════════════════════════════════════════════
// LUMO TURN BANNER — kleine Lumo-Sprechblase oben
// ════════════════════════════════════════════════════════════════════════
// Zeigt 'X ist dran' und eine letzte Aktion-Message vom Spiel.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'lumo_turn_pill.dart';

class LumoTurnBanner extends StatelessWidget {
  const LumoTurnBanner({
    super.key,
    required this.currentPlayerName,
    required this.message,
    this.isMyTurn = true,
  });

  final String currentPlayerName;
  final String message;

  /// Heinz HUD-Asset 2026-05-22: prominente "DEIN ZUG"/"GEGNER"-Pille.
  /// Steuerung kommt vom Screen, da der Banner sonst nicht weiss wer
  /// "ich" ist (Pass-and-Play kontextabhaengig).
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lumo + Bubble
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lumo-Fuchs Avatar.
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A2F).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('🦊', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFF59E0B), width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currentPlayerName ist dran',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7C2D12),
                          ),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7C2D12),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Turn-Pille im HUD-Asset-Stil (Heinz 2026-05-22) ──
          // Ersetzt die alte Gegner-Karten-Pille - die Karten-Anzahl wird
          // jetzt durch das Gegner-HUD oben angezeigt (vermeidet doppelte
          // Info).
          LumoTurnPill(isMyTurn: isMyTurn),
        ],
      ),
    );
  }
}
