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
import 'lumo_cards_assets.dart';
import 'lumo_cards_game_controller.dart';
import 'lumo_cards_models.dart';
import 'widgets/lumo_action_button.dart';
import 'widgets/lumo_card_table.dart';
import 'widgets/lumo_color_picker.dart';
import 'widgets/lumo_discard_pile.dart';
import 'widgets/lumo_draw_pile.dart';
import 'widgets/lumo_hint_bubble.dart';
import 'widgets/lumo_learning_card_overlay.dart';
import 'widgets/lumo_pass_device_overlay.dart';
import 'widgets/lumo_player_hand.dart';
import 'widgets/lumo_player_hud.dart';
import 'widgets/lumo_result_dialog.dart';
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

    // Fixe Sicht-Perspektive fuer die HUDs: im Bot-Modus sieht das Kind
    // (Spieler 0) immer von unten; der Gegner (Lumo) ist oben. Im Pass-
    // and-Play ist der aktive Spieler der Betrachter.
    final viewerIndex = widget.vsBot ? 0 : s.currentPlayerIndex;
    final oppIndex = 1 - viewerIndex;
    final oppPlayer = s.players[oppIndex];
    final oppActive = s.currentPlayerIndex == oppIndex;

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
                    // ── Gegner-HUD oben: Avatar + Name + Karten-Anzahl +
                    //    Sterne, glueht wenn er dran ist. ──
                    // Im vsBot-Modus ist der Gegner Lumo (Fuchs-Emoji),
                    // im 2-Mensch-Modus bekommt Spieler 2 einen sauberen
                    // Kind-Avatar (Heinz' Asset-Pack 2026-05-22).
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: LumoPlayerHud(
                        name: oppPlayer.name,
                        cardCount: oppPlayer.hand.length,
                        stars: oppPlayer.stars,
                        isActive: oppActive,
                        compact: true,
                        avatarAssetPath: widget.vsBot
                            ? null
                            : LumoCardsAssets.avatarRedGirl,
                        ringColor: const Color(0xFF8B5CF6),
                      ),
                    ),
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
          // Action-Button unten rechts + Hint-Bubble unten links
          // (nur waehrend der Spielphase, nicht ueber den Overlays).
          if (_showActionUi(s))
            Positioned(
              right: 18,
              bottom: 18,
              child: SafeArea(
                top: false,
                left: false,
                child: LumoActionButton(
                  label: _actionLabel(s),
                  icon: _actionIcon(s),
                  enabled: _isMyTurnVisible(s),
                  pulse: _isMyTurnVisible(s),
                  onPressed: _isMyTurnVisible(s)
                      ? () => _controller.drawCard()
                      : null,
                ),
              ),
            ),
          if (_showActionUi(s) && _isMyTurnVisible(s))
            Positioned(
              left: 14,
              bottom: 18,
              child: SafeArea(
                top: false,
                right: false,
                child: LumoHintBubble(message: _hintFor(s)),
              ),
            ),
          if (s.phase == GamePhase.gameOver)
            LumoResultDialog(
              winnerName: s.players[s.winnerIndex ?? 0].name,
              kindWon: s.winnerIndex == 0,
              reward: _rewardForStreak(s.winnerIndex == 0
                  ? widget.appState.lumoCardsWinStreak
                  : 0),
              streak: widget.appState.lumoCardsWinStreak,
              onRestart: () {
                _rewardGiven = false;
                _controller.restart();
              },
              onExit: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  /// Action-Button nur waehrend Spielphase sichtbar.
  bool _showActionUi(LumoCardsGameState s) =>
      s.phase == GamePhase.playing && _isMyTurnVisible(s);

  String _actionLabel(LumoCardsGameState s) => 'Karte ziehen';
  IconData _actionIcon(LumoCardsGameState s) => Icons.add_circle_outline_rounded;

  String _hintFor(LumoCardsGameState s) {
    if (s.phase != GamePhase.playing) return '';
    final top = s.topCard;
    if (top == null) return '';
    final me = s.players[0];
    final hasPlayable = me.hand.any((c) =>
        c.isWild ||
        c.color == s.selectedColor ||
        (c.number != null && c.number == top.number) ||
        (c.isSpecial && c.type == top.type));
    if (!hasPlayable) {
      return 'Keine passende Karte - ziehe eine!';
    }
    return 'Lege eine passende Farbe oder Zahl.';
  }

  int _rewardForStreak(int streak) {
    if (streak <= 1) return 3;
    return (3 + (streak - 1)).clamp(3, 6);
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

}
