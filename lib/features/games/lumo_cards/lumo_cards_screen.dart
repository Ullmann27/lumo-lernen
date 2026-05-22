// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS SCREEN — Top-Level der Karten-Mini-App
// ════════════════════════════════════════════════════════════════════════
// Eigenstaendiges Lumo-Design, keine UNO-Bezuege.
//
// Modi:
//  - vsBot=true (Default): Kind spielt gegen Lumo (Bot). Sofort spielbar.
//  - vsBot=false: 2 Menschen am Tablet (Pass-and-Play).
//
// Heinz 2026-05-21 'zu langweilig' -> Solo-Bot + Streak + Animation
// machen das Spiel sofort spannend.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
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
    this.player1Name = 'Du',
    this.player2Name = 'Lumo',
    this.vsBot = true,
  });

  final LumoAppState appState;
  final String player1Name;
  final String player2Name;
  final bool vsBot;

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
      vsBot: widget.vsBot,
    );
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }
  }

  void _onStateChanged() {
    final s = _controller.state;
    // Bei Game-Over: Streak-System ueber AppState aufrufen.
    // Nur einmal pro Gewinner.
    if (s.phase == GamePhase.gameOver &&
        s.winnerIndex != null &&
        !_rewardGiven) {
      _rewardGiven = true;
      final kindWon = s.winnerIndex == 0;
      widget.appState.recordLumoCardsResult(won: kindWon);
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
                            // AnimatedSwitcher: jede neue Karte fliegt
                            // mit kleinem Bounce zur Mitte. Trigger ueber
                            // ValueKey(topCard.id).
                            if (topCard != null)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 360),
                                transitionBuilder: (child, anim) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, -0.6),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOutBack,
                                    )),
                                    child: ScaleTransition(
                                      scale: anim,
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(topCard.id),
                                  child: LumoDiscardPile(
                                    topCard: topCard,
                                    selectedColor: s.selectedColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Hand am Boden - im vsBot-Modus zeigen wir IMMER
                    // die Hand des Kindes (Spieler 1), auch wenn Lumo
                    // gerade dran ist. Sonst wuerde das Kind die
                    // Geheim-Karten von Lumo sehen.
                    if (topCard != null)
                      _isMyTurnVisible(s)
                          ? LumoPlayerHand(
                              cards: widget.vsBot
                                  ? s.players[0].hand
                                  : current.hand,
                              topCard: topCard,
                              selectedColor: s.selectedColor,
                              onCardTap: widget.vsBot && s.currentPlayerIndex != 0
                                  ? (_) {}
                                  : (card) => _controller.playCard(card),
                              height: handHeight,
                            )
                          : _buildLumoThinking(handHeight),
                  ],
                );
              }),
            ),
          ),
          // ── Overlays ÜBER der SafeArea ──
          // Garantiert vollflaechig, deckt auch Status-/Navi-Bar ab.
          // Im vsBot-Modus: kein Pass-Device-Overlay (Lumo's Zuege
          // laufen automatisch ab).
          if (!widget.vsBot && s.phase == GamePhase.passDevice)
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

  /// Sichtbar = Kind ist dran ODER 2-Mensch-Modus. Bei vsBot+Lumo-dran:
  /// wir verstecken die Hand und zeigen 'Lumo ueberlegt...'.
  bool _isMyTurnVisible(LumoCardsGameState s) {
    if (!widget.vsBot) return true;
    return s.currentPlayerIndex == 0;
  }

  Widget _buildLumoThinking(double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFFFF7A2F),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '🦊 Lumo ueberlegt...',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
            ],
          ),
        ),
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
    final kindWon = s.winnerIndex == 0;
    final streak = widget.appState.lumoCardsWinStreak;
    final reward = kindWon
        ? (streak <= 1 ? 3 : (3 + (streak - 1)).clamp(3, 6))
        : 1;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: kindWon
                  ? const [Color(0xFFFFFBEB), Color(0xFFFCD34D)]
                  : const [Color(0xFFFEF2F2), Color(0xFFFCA5A5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: kindWon
                  ? const Color(0xFFCA8A04)
                  : const Color(0xFFB91C1C),
              width: 3,
            ),
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
              Text(kindWon ? '🏆' : '🦊',
                  style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text(
                kindWon ? '${winner.name} gewinnt!' : 'Lumo gewinnt diesmal!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
              const SizedBox(height: 8),
              if (kindWon && streak >= 2) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D).withOpacity(0.55),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: const Color(0xFFCA8A04), width: 1.6),
                  ),
                  child: Text(
                    'Streak x$streak! ${'🔥' * streak.clamp(1, 5)}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7C2D12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                kindWon
                    ? 'Du bekommst $reward Sterne!'
                    : 'Du bekommst 1 Trost-Stern. Naechstes Mal du!',
                textAlign: TextAlign.center,
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
