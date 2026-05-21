// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS SCREEN — Top-Level der Karten-Mini-App
// ════════════════════════════════════════════════════════════════════════
// Pass-and-Play 2-Spieler-Karten-Ablegespiel. Eigenstaendiges Lumo-Design,
// keine UNO-Bezuege.
//
// Heinz' MVP:
//  - 2 Spieler am Tablet
//  - Pass-and-Play (Tablet-Uebergabe-Overlay zwischen Zuegen)
//  - 5 Spezialkarten (Lumo-Sprung, Sternenregen, Farbzauber, Wirbelwind,
//    Denkpause)
//  - Denkpause oeffnet kleine lokale Lernfrage
//  - Gewinn, Sterne, 'Nochmal spielen', 'Zurueck'
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import 'lumo_cards_game_controller.dart';
import 'lumo_cards_models.dart';
import 'widgets/lumo_card_table.dart';
import 'widgets/lumo_color_picker.dart';
import 'widgets/lumo_discard_pile.dart';
import 'widgets/lumo_draw_pile.dart';
import 'widgets/lumo_learning_card_overlay.dart';
import 'widgets/lumo_pass_device_overlay.dart';
import 'widgets/lumo_player_hand.dart';
import 'widgets/lumo_turn_banner.dart';

class LumoCardsScreen extends StatefulWidget {
  const LumoCardsScreen({
    super.key,
    required this.appState,
    this.player1Name = 'Spieler 1',
    this.player2Name = 'Spieler 2',
  });

  final LumoAppState appState;
  final String player1Name;
  final String player2Name;

  @override
  State<LumoCardsScreen> createState() => _LumoCardsScreenState();
}

class _LumoCardsScreenState extends State<LumoCardsScreen> {
  late final LumoCardsGameController _controller;
  bool _rewardGiven = false;

  @override
  void initState() {
    super.initState();
    _controller = LumoCardsGameController(
      player1Name: widget.player1Name,
      player2Name: widget.player2Name,
    );
    _controller.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _say('Willkommen bei Lumo Cards! ${widget.player1Name} faengt an.');
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _say(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _onStateChanged() {
    final s = _controller.state;
    // Sterne aus Lernfragen ans App-State weiterreichen.
    // Nur einmal pro Gewinner: Bonus fuer den Sieg.
    if (s.phase == GamePhase.gameOver &&
        s.winnerIndex != null &&
        !_rewardGiven) {
      _rewardGiven = true;
      widget.appState.addStars(3);
      widget.appState.addXp(20);
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
      _say('${s.players[s.winnerIndex!].name} gewinnt! Glueckwunsch!');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.state;
    final current = s.currentPlayer;
    final opponent = s.otherPlayer;
    final topCard = s.topCard;

    // Heinz Bug 2026-05-21: Hand wurde nicht angezeigt + Layout-Overflow.
    // Loesung: LayoutBuilder fuer responsive Hoehen + Stack wo das Pass-
    // Overlay GARANTIERT ueber allem liegt (auch ueber der SafeArea).
    return Scaffold(
      body: Stack(
        children: [
          // ── Hauptlayout ──
          LumoCardTable(
            child: SafeArea(
              child: LayoutBuilder(builder: (ctx, c) {
                // Hand-Hoehe responsive: 142..170 abhaengig von verfuegbarem
                // Platz. So gibt es nie Bottom-Overflow.
                final handHeight =
                    (c.maxHeight * 0.22).clamp(132.0, 172.0);
                return Column(
                  children: [
                    _buildTopBar(),
                    LumoTurnBanner(
                      currentPlayerName: current.name,
                      message: s.lastActionMessage ?? '',
                      opponentName: opponent.name,
                      opponentCardCount: opponent.hand.length,
                    ),
                    // Mitte: Piles - der Expanded sorgt fuer den
                    // restlichen Platz, kein Overflow moeglich.
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LumoDrawPile(
                              cardsLeft: s.drawPile.length,
                              onDraw: s.phase == GamePhase.playing
                                  ? () => _controller.drawCard()
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            if (topCard != null)
                              LumoDiscardPile(
                                topCard: topCard,
                                selectedColor: s.selectedColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Hand am Boden - fix Hoehe damit nichts ueberlaeuft.
                    if (topCard != null)
                      LumoPlayerHand(
                        cards: current.hand,
                        topCard: topCard,
                        selectedColor: s.selectedColor,
                        onCardTap: (card) => _controller.playCard(card),
                        height: handHeight,
                      ),
                  ],
                );
              }),
            ),
          ),
          // ── Overlays ÜBER der SafeArea ──
          // Garantiert vollflaechig, deckt auch Status-/Navi-Bar ab,
          // damit das Kind die geheimen Karten des Gegners NICHT
          // versehentlich sieht.
          if (s.phase == GamePhase.passDevice)
            LumoPassDeviceOverlay(
              nextPlayerName: current.name,
              onReady: _controller.confirmHandover,
            ),
          if (s.phase == GamePhase.chooseColor)
            LumoColorPicker(onPick: _controller.selectColor),
          if (s.phase == GamePhase.learningQuestion &&
              s.pendingLearningQuestion != null)
            LumoLearningCardOverlay(
              question: s.pendingLearningQuestion!,
              onAnswer: _controller.answerLearningQuestion,
            ),
          if (s.phase == GamePhase.gameOver) _buildGameOverOverlay(s),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, MediaQuery.of(context).padding.top + 4, 16, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Lumo Cards',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Neu starten',
            onPressed: () {
              _rewardGiven = false;
              _controller.restart();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(LumoCardsGameState s) {
    final winner = s.players[s.winnerIndex ?? 0];
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFCD34D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFCA8A04), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text(
                '${winner.name} gewinnt!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Du bekommst 3 Sterne und 20 XP!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C2D12).withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      _rewardGiven = false;
                      _controller.restart();
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Nochmal',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                        )),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Zurueck',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                        )),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C2D12),
                      side: const BorderSide(
                          color: Color(0xFF7C2D12), width: 1.6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
