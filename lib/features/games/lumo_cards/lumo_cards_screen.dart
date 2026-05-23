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
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_state.dart';
import 'lumo_cards_assets.dart';
import 'lumo_cards_game_controller.dart';
import 'lumo_cards_models.dart';
import 'widgets/lumo_action_button.dart';
import 'widgets/lumo_avatar_picker.dart';
import 'widgets/lumo_call_button.dart';
import 'widgets/lumo_card_table.dart';
import 'widgets/lumo_cards_score_header.dart';
import 'widgets/lumo_color_arrows.dart';
import 'widgets/lumo_color_picker.dart';
import 'widgets/lumo_confetti.dart';
import 'widgets/lumo_discard_pile.dart';
import 'widgets/lumo_draw_pile.dart';
import 'widgets/lumo_hint_bubble.dart';
import 'widgets/lumo_intro_splash.dart';
import 'widgets/lumo_learning_card_overlay.dart';
import 'widgets/lumo_opponent_hand.dart';
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

  /// Intro-Splash beim Spielstart (Heinz 2026-05-22). Verschwindet nach
  /// ~2 Sekunden automatisch oder per Tap. Wird beim Restart nicht
  /// erneut gezeigt.
  bool _showIntro = true;

  /// Vom Kind gewaehlter Avatar fuer Spieler 1.
  /// Persistiert in SharedPreferences ('lumo_cards_player_avatar').
  String? _playerAvatarPath;
  static const String _avatarPrefKey = 'lumo_cards_player_avatar';

  @override
  void initState() {
    super.initState();
    _controller = LumoCardsGameController(
      player1Name: widget.player1Name,
      player2Name: widget.player2Name,
      vsBot: widget.vsBot,
    );
    _controller.addListener(_onStateChanged);
    // Heinz Crash-Bericht 2026-05-22: '_dependents.isEmpty' Assertion.
    // Frueher hat sich beim ersten Start ein Avatar-Picker-Dialog
    // direkt aus addPostFrameCallback geoeffnet. Das fuehrte zu
    // Race-Conditions zwischen Dialog-Mount und Screen-Build -> Crash.
    // Jetzt: kein automatischer Picker mehr, sondern Default-Avatar
    // direkt setzen. Avatar-Wechsel nur explizit ueber Tap aufs HUD.
    _playerAvatarPath = LumoCardsAssets.avatarBlueBoy;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedAvatar());
  }

  Future<void> _loadSavedAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_avatarPrefKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() => _playerAvatarPath = saved);
      }
    } catch (_) {
      // Pref-Lesen fehlgeschlagen - Default bleibt
    }
  }

  Future<void> _changeAvatar() async {
    final picked = await LumoAvatarPicker.show(
      context,
      title: 'Avatar wechseln',
      currentAvatarPath: _playerAvatarPath,
    );
    if (picked == null) return;
    if (mounted) setState(() => _playerAvatarPath = picked);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarPrefKey, picked);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    // mounted ZUERST pruefen - Bot-Timer kann nach Screen-Pop noch feuern.
    if (!mounted) return;
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.state;
    final current = s.currentPlayer;
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
          // Heinz 2026-05-22 Refactor Build 182:
          //  - LayoutBuilder raus (war Komplexitaets-Quelle)
          //  - Karten groesser (96x140 default)
          //  - Hand-Hoehe fix 180 px
          //  - Gegner-Hand-Fan oben sichtbar (Heinz: 'vom Gegner sollte
          //    man auch sehen')
          //  - Arena kleiner damit alles passt
          LumoCardTable(
            child: SafeArea(
              child: Column(
                children: [
                  LumoCardsScoreHeader(
                    round: 1,
                    totalRounds: 1,
                    targetPoints: widget.appState.state.stars,
                    onClose: () => Navigator.of(context).pop(),
                    onSettings: () {
                      _rewardGiven = false;
                      _controller.restart();
                    },
                  ),
                  // ── Gegner-HUD: Avatar + Name + Karten + Sterne ──
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
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
                  // ── Gegner-Hand-Fan: verdeckte Karten-Rueckseiten ──
                  // (Heinz Wunsch: 'vom Gegner sollte man auch sehen')
                  LumoOpponentHand(
                    cardCount: oppPlayer.hand.length,
                    cardWidth: 50,
                    cardHeight: 70,
                  ),
                  LumoTurnBanner(
                    currentPlayerName: current.name,
                    message: s.lastActionMessage ?? '',
                    isMyTurn: s.currentPlayerIndex == viewerIndex &&
                        s.phase == GamePhase.playing,
                  ),
                  // Mitte: Piles in der Arena. ClipRect schuetzt vor
                  // Overflow auf kleinen Handys (Arena ist 230 px square,
                  // bei wenig vertikalem Platz wird der untere/obere Pfeil
                  // geclippt - kein Crash, nur visuell etwas knapp).
                  Expanded(
                    child: ClipRect(
                      child: Center(
                        child: LumoColorArrows(
                          activeColor: s.selectedColor,
                          size: 230,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LumoDrawPile(
                                cardsLeft: s.drawPile.length,
                                onDraw: s.phase == GamePhase.playing
                                    ? () => _controller.drawCard()
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              if (topCard != null)
                                LumoDiscardPile(
                                  topCard: topCard,
                                  selectedColor: s.selectedColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Hand am Boden - im vsBot-Modus immer die Hand des
                  // Kindes (Spieler 1), egal wer dran ist.
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
                            height: 180,
                          )
                        : _buildLumoThinking(180),
                ],
              ),
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
          // Action-Button unten rechts. Wenn der Spieler nur noch 1-2
          // Karten hat -> LUMO!-Button statt 'Karte ziehen'.
          if (_showActionUi(s))
            Positioned(
              right: 18,
              bottom: 18,
              child: SafeArea(
                top: false,
                left: false,
                child: s.players[viewerIndex].hand.length <= 2
                    ? LumoCallButton(
                        cardsLeft: s.players[viewerIndex].hand.length,
                        totalCards: 7,
                        onPressed: _onLumoCall,
                      )
                    : LumoActionButton(
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
              // Hint-Bubble etwas hoeher damit unten Platz fuer den
              // Spieler-Mini-HUD bleibt.
              bottom: 92,
              child: SafeArea(
                top: false,
                right: false,
                child: LumoHintBubble(message: _hintFor(s)),
              ),
            ),
          // ── Spieler-1-Mini-HUD unten links ──
          // Avatar + Karten-Counter. Tap auf den Avatar oeffnet den
          // Picker (Avatar wechseln). Sichtbar in beiden Modi.
          Positioned(
            left: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              right: false,
              child: GestureDetector(
                onTap: _changeAvatar,
                child: LumoPlayerHud(
                  name: widget.vsBot
                      ? widget.player1Name
                      : s.players[viewerIndex].name,
                  cardCount: s.players[viewerIndex].hand.length,
                  stars: s.players[viewerIndex].stars,
                  isActive: s.currentPlayerIndex == viewerIndex &&
                      s.phase == GamePhase.playing,
                  compact: true,
                  avatarAssetPath: _playerAvatarPath,
                  ringColor: const Color(0xFFFCD34D),
                ),
              ),
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
          // Konfetti-Regen wenn das Kind gewinnt. Liegt UEBER dem Result-
          // Dialog, IgnorePointer drinnen damit der Dialog klickbar bleibt.
          if (s.phase == GamePhase.gameOver && s.winnerIndex == 0)
            const Positioned.fill(child: LumoConfetti()),
          // ── Intro-Splash (Heinz 2026-05-22) ──
          // Liegt UEBER allem - inkl. Result-Dialog/Color-Picker. Wird
          // nur einmal beim Screen-Eintritt gezeigt.
          if (_showIntro)
            LumoIntroSplash(
              onComplete: () {
                if (mounted) setState(() => _showIntro = false);
              },
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
    final opp = s.players[1];
    final playables = me.hand
        .where((c) =>
            c.isWild ||
            c.color == s.selectedColor ||
            (c.number != null && c.number == top.number) ||
            (c.isSpecial && c.type == top.type))
        .toList();

    if (playables.isEmpty) {
      return 'Keine passende Karte - ziehe eine!';
    }

    // Strategische Tipps (Heinz 2026-05-22 'cleverer + strategischer').
    final hasBlock = playables.any((c) =>
        c.type == LumoCardType.lumoJump ||
        c.type == LumoCardType.whirlwind ||
        c.type == LumoCardType.starRain ||
        c.type == LumoCardType.superRain);

    if (opp.hand.length == 1) {
      return hasBlock
          ? 'Lumo hat nur 1 Karte - leg eine Spezialkarte!'
          : 'Achtung: Lumo gewinnt fast! Halte ihn auf!';
    }
    if (opp.hand.length == 2 && hasBlock) {
      return 'Lumo hat nur 2 Karten - Spezialkarte hilft jetzt!';
    }

    // Nur Wild-Karte als einzige Option
    if (playables.length == 1) {
      final only = playables.first;
      if (only.type == LumoCardType.superRain) {
        return 'Sternen-Sturm! Lumo muss 4 Karten ziehen!';
      }
      if (only.type == LumoCardType.colorMagic) {
        return 'Spiel die Wild und waehle eine Farbe!';
      }
    }

    // Wenn die Hand gross ist, hohe Zahlen zuerst loswerden.
    if (me.hand.length >= 9) {
      return 'Spiel deine grossen Zahlen zuerst!';
    }

    return 'Lege eine passende Farbe oder Zahl.';
  }

  int _rewardForStreak(int streak) {
    if (streak <= 1) return 3;
    return (3 + (streak - 1)).clamp(3, 6);
  }

  /// 'LUMO!'-Ruf wenn das Kind nur noch 1-2 Karten hat. Gibt einen
  /// Bonus-Stern und zeigt Feedback. Eigene Lumo-Spielmechanik.
  void _onLumoCall() {
    widget.appState.addStars(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('LUMO! +1 Stern - bring jetzt die letzte Karte!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFFEF4444),
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


}
