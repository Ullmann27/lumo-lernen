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
    final title =
        currentPlayerName == 'Du' ? 'Du bist dran' : '$currentPlayerName ist dran';
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE60B2A5C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isMyTurn ? const Color(0xFFFFD86B) : const Color(0xAA37D2FD),
            width: 1.6),
        boxShadow: [
          BoxShadow(
            color: (isMyTurn ? const Color(0xFFFFD86B) : const Color(0xFF37D2FD))
                .withOpacity(.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
                color: Color(0xFFD6E8FF),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: LayoutBuilder(builder: (context, c) {
        // Schmale Handys: Hinweis über die ganze Breite, Zug-Knopf darunter
        // rechts – nie Buchstabe für Buchstabe umbrechen.
        if (c.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              bubble,
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: LumoTurnPill(isMyTurn: isMyTurn),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: bubble),
            const SizedBox(width: 10),
            LumoTurnPill(isMyTurn: isMyTurn),
          ],
        );
      }),
    );
  }
}
