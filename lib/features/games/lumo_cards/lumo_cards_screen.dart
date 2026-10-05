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
import '../../../core/lumo_asset_paths.dart';
import '../../../core/lumo_music.dart';
import '../../../core/lumo_sound.dart';
import '../../companion/lumo_lottie.dart';
import '../../shared/widgets/lumo_audio_settings_sheet.dart';
import '../../shared/widgets/lumo_premium_effects.dart';
import 'lumo_cards_assets.dart';
import 'lumo_cards_game_controller.dart';
import 'lumo_cards_models.dart';
import '../shared/lumo_game_pause_scope.dart';
import 'widgets/lumo_avatar_picker.dart';
import 'widgets/lumo_card_burst.dart';
import 'widgets/lumo_card_fly.dart';
import 'widgets/lumo_card_table.dart';
import 'widgets/lumo_cards_score_header.dart';
import 'widgets/lumo_color_arrows.dart';
import 'widgets/lumo_color_picker.dart';
import 'widgets/lumo_confetti.dart';
import 'widgets/lumo_discard_pile.dart';
import 'widgets/lumo_draw_pile.dart';
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
    this.seed,
  });

  final LumoAppState appState;
  final String player1Name;
  final String player2Name;
  final bool vsBot;
  final int? seed;

  @override
  State<LumoCardsScreen> createState() => _LumoCardsScreenState();
}

class _LumoCardsScreenState extends State<LumoCardsScreen> {
  late final LumoCardsGameController _controller;
  bool _rewardGiven = false;
  bool _callRewardGiven = false;
  int _roundSerial = 0;

  /// Intro-Splash beim Spielstart (Heinz 2026-05-22). Verschwindet nach
  /// ~2 Sekunden automatisch oder per Tap. Wird beim Restart nicht
  /// erneut gezeigt.
  bool _showIntro = true;

  /// Tier 6 Karten-Polish 2026-05-23: aktiver Partikel-Burst bei +2/+4.
  /// Solange != null wird LumoCardBurst ueber der Arena angezeigt.
  /// Wird via onDone-Callback nach ca. 900 ms automatisch geleert.
  LumoBurstStyle? _activeBurst;
  int _burstKey = 0;

  /// Tier 6 Karten-Polish 2026-05-25: aktiver Karten-Flug von Hand zu
  /// Discard. Wenn gesetzt, rendert der Screen oben ein LumoCardFly mit
  /// Bezier-Bogen + Rotation. Wird ueber onDone-Callback nach ca. 360 ms
  /// automatisch geleert.
  LumoCard? _flyingCard;
  Offset? _flyStart;
  Offset? _flyEnd;
  int _flyKey = 0;

  /// GlobalKey fuer die Discard-Pile - wird gebraucht um die End-Position
  /// des Karten-Flugs zu berechnen.
  final GlobalKey _discardKey = GlobalKey();

  /// Tracking: letzte topCard.id um Karten-Wechsel zu erkennen.
  /// Wird im _onStateChanged-Listener verglichen, NICHT im build() -
  /// build() darf keine Side-Effects haben.
  String? _lastTopCardId;

  /// PR H1 2026-05-23: Star-Burst-Lottie bei richtiger Lernfrage-Antwort.
  /// Detection ueber Phase-Transition (learningQuestion -> playing) +
  /// Stars-Increment beim Kind. Burst spielt ~1.5 s und entfernt sich
  /// dann via Future.delayed-Aufraeumer.
  GamePhase? _prevPhase;
  int _prevKidStars = 0;
  bool _showStarBurst = false;
  int _starBurstKey = 0;

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
      seed: widget.seed,
      grade: widget.appState.state.grade,
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
    // PR H3 2026-05-23: ruhige Background-Music starten sobald der erste
    // Frame steht. LumoMusic respektiert seinen muted-Toggle intern, das
    // play() ist also kein No-op-Risiko wenn der Spieler Musik aus hat.
    // Fehlende m4a-Datei -> stille Box (try/catch + _missing-Set).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => LumoMusic.instance.play(LumoMusicTrack.chillLoop),
    );
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
    // PR H3: Background-Music stoppen wenn der Screen verlassen wird.
    // Singleton-Player bleibt offen fuer den naechsten Screen-Eintritt.
    LumoMusic.instance.stop();
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
      widget.appState.recordLumoCardsResult(won: kindWon).then<void>((_) {
        if (mounted) setState(() {});
      }, onError: (Object _, StackTrace __) {
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.appState.rewardSaveError ??
              'Die Belohnung wartet noch aufs Speichern.'),
          action: SnackBarAction(
            label: 'Erneut versuchen',
            onPressed: () {
              widget.appState.retryRewards().then<void>((_) {
                if (mounted) setState(() {});
              }, onError: (Object _, StackTrace __) {});
            },
          ),
        ));
      });
    }

    // Tier 6 Karten-Polish 2026-05-23: Burst-Trigger bei +2 / +4.
    // Nur bei ECHTEM Wechsel der topCard.id (nicht bei jedem Listener-
    // Tick) und nur fuer Storm-Karten - Number-Karten lassen die Discard-
    // Pile-Slide-Animation aus PR #87 das visuelle Feedback machen.
    final top = s.topCard;
    if (top != null && top.id != _lastTopCardId) {
      _lastTopCardId = top.id;
      if (top.type == LumoCardType.starRain) {
        _activeBurst = LumoBurstStyle.storm;
        _burstKey += 1;
      } else if (top.type == LumoCardType.superRain) {
        _activeBurst = LumoBurstStyle.thunder;
        _burstKey += 1;
      }
    }

    // PR H1 2026-05-23: Star-Burst bei korrekter Lernfrage-Antwort.
    // Detection: prev phase war learningQuestion, jetzt nicht mehr, UND
    // Kind-Stars sind gewachsen -> Antwort richtig (Belohnung +1 Stern
    // im Repository).
    final kidStarsNow = s.players[0].stars;
    final wasLearning = _prevPhase == GamePhase.learningQuestion;
    final isLearningNow = s.phase == GamePhase.learningQuestion;
    if (wasLearning && !isLearningNow && kidStarsNow > _prevKidStars) {
      widget.appState.addStars(kidStarsNow - _prevKidStars);
      _triggerStarBurst();
    }
    _prevPhase = s.phase;
    _prevKidStars = kidStarsNow;

    setState(() {});
  }

  /// PR H1: spielt LumoLottie(star_burst) ueber dem Spielfeld ab, ~1.5 s.
  void _triggerStarBurst() {
    _starBurstKey += 1;
    _showStarBurst = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showStarBurst = false);
    });
  }

  /// Tier 6 Karten-Polish 2026-05-25: zeigt die Fly-Animation von der
  /// Tap-Position zur Discard-Pile, dann wird die Karte gespielt. Wenn
  /// bereits ein Flug laeuft oder die Discard-Pile noch nicht im Tree
  /// ist, wird die Karte sofort gespielt (Fallback ohne Animation).
  void _playCardWithFly(LumoCard card, Offset globalTapPos) {
    if (_flyingCard != null) {
      // Schon ein Flug aktiv - lass ihn fertig laufen, kein zweiter.
      return;
    }
    final discardBox =
        _discardKey.currentContext?.findRenderObject() as RenderBox?;
    if (discardBox == null || !discardBox.attached) {
      _controller.playCard(card);
      return;
    }
    final endPos = discardBox.localToGlobal(
      discardBox.size.center(Offset.zero),
    );
    setState(() {
      _flyingCard = card;
      _flyStart = globalTapPos;
      _flyEnd = endPos;
      _flyKey += 1;
    });
    // Karte wird minimal verzoegert gespielt - der Stack zeigt waehrend-
    // dessen die fliegende Kopie. State-Update + Discard-Pile-Visual
    // wechselt erst nach Animations-Mitte, dann ueberlappt der Flug-
    // Endpunkt mit der neuen Top-Card.
    final serial = _roundSerial;
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || serial != _roundSerial) return;
      _controller.playCard(card);
    });
  }

  void _clearFly() {
    if (!mounted) return;
    setState(() {
      _flyingCard = null;
      _flyStart = null;
      _flyEnd = null;
    });
  }

  /// PR I 2026-05-23: oeffnet das Audio-Settings BottomSheet. Wenn der
  /// Spieler Musik wieder aktiviert, startet die chill_loop sofort -
  /// passt zum aktuellen Lumo-Cards-Kontext. LumoMusic.muted persistiert,
  /// SharedPreferences merken sich die Wahl ueber App-Neustarts hinweg.
  Future<void> _openAudioSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFF6EE),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LumoAudioSettingsSheet(
        onMusicEnabled: () => LumoMusic.instance.play(
          LumoMusicTrack.chillLoop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.state;
    final compact = MediaQuery.sizeOf(context).height < 760;
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
    return LumoGamePauseScope(
        clock: _controller.turnClock,
        onRestart: _restartGame,
        child: Scaffold(
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
                      // Premium-Look 2026-05-25: HUD-Header sitzt jetzt auf
                      // einem Glass-Panel (BackdropFilter Blur + warmer Tint),
                      // hebt sich klar vom Velvet-Tisch ab und sieht weniger
                      // "Standard-Material" aus.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                        child: LumoGlassCard(
                          blur: 14,
                          borderRadius: 22,
                          padding: EdgeInsets.zero,
                          tintColor: const Color(0xFFFFE0B8),
                          child: LumoCardsScoreHeader(
                            round: 1,
                            totalRounds: 1,
                            targetPoints: widget.appState.state.stars,
                            onClose: () {
                              LumoSound.instance.play(SoundEffect.click);
                              _controller.turnClock.pause();
                            },
                            onSettings: () {
                              LumoSound.instance.play(SoundEffect.click);
                              _controller.turnClock.pause();
                            },
                            // PR I 2026-05-23: Audio-Settings BottomSheet
                            onAudioSettings: () {
                              LumoSound.instance.play(SoundEffect.click);
                              _openAudioSettings();
                            },
                          ),
                        ),
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
                      if (!compact)
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: LumoColorArrows(
                                activeColor: s.selectedColor,
                                size: 300,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LumoDrawPile(
                                      cardsLeft: s.drawPile.length,
                                      onDraw: s.phase == GamePhase.playing &&
                                              _isMyTurnVisible(s)
                                          ? () => _controller.drawCard()
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    if (topCard != null)
                                      KeyedSubtree(
                                        key: _discardKey,
                                        // Premium-Look 2026-05-25:
                                        //  - radialer Glow-Halo HINTER der Pile
                                        //    (96x140 Karte + grosser Spread -
                                        //    sieht aus wie ein Spot-Strahler)
                                        //  - LumoFloating: sanftes Schweben +/-4 px,
                                        //    bricht die statische Optik
                                        child: SizedBox(
                                          width: 132,
                                          height: 172,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              IgnorePointer(
                                                child: Container(
                                                  width: 112,
                                                  height: 152,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFFFE0B8)
                                                            .withOpacity(0.55),
                                                        blurRadius: 48,
                                                        spreadRadius: 4,
                                                      ),
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFFFB96B)
                                                            .withOpacity(0.35),
                                                        blurRadius: 22,
                                                        spreadRadius: -2,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              LumoFloating(
                                                amplitude: 4,
                                                duration:
                                                    const Duration(seconds: 4),
                                                child: LumoDiscardPile(
                                                  topCard: topCard,
                                                  selectedColor:
                                                      s.selectedColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
                                onCardTap:
                                    widget.vsBot && s.currentPlayerIndex != 0
                                        ? (_) {}
                                        : (card) => _controller.playCard(card),
                                onCardTapAt:
                                    widget.vsBot && s.currentPlayerIndex != 0
                                        ? null
                                        : _playCardWithFly,
                                height: compact ? 148 : 180,
                              )
                            : _buildLumoThinking(compact ? 148 : 180),
                      _buildControls(s, viewerIndex),
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
              if (s.phase == GamePhase.chooseColor &&
                  (!widget.vsBot || s.currentPlayerIndex == 0))
                LumoColorPicker(onPick: _controller.selectColor),
              if (s.phase == GamePhase.learningQuestion &&
                  (!widget.vsBot || s.currentPlayerIndex == 0) &&
                  s.pendingLearningQuestion != null)
                LumoLearningCardOverlay(
                  question: s.pendingLearningQuestion!,
                  onAnswer: _controller.answerLearningQuestion,
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
                    LumoSound.instance.play(SoundEffect.click);
                    _restartGame();
                  },
                  onExit: () {
                    LumoSound.instance.play(SoundEffect.click);
                    Navigator.of(context).pop();
                  },
                ),
              // Tier 6 Karten-Polish 2026-05-25: fliegende Karte von der
              // Tap-Position zur Discard-Pile. Stack-Positioned (left/top
              // werden im LumoCardFly per Animation gesetzt), IgnorePointer
              // damit Taps weiter zur Hand durchgehen.
              if (_flyingCard != null && _flyStart != null && _flyEnd != null)
                Positioned.fill(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LumoCardFly(
                        key: ValueKey('fly-$_flyKey'),
                        card: _flyingCard!,
                        start: _flyStart!,
                        end: _flyEnd!,
                        onDone: _clearFly,
                      ),
                    ],
                  ),
                ),
              // Tier 6 Karten-Polish 2026-05-23: Partikel-Burst bei +2/+4.
              // Position auf den zentralen Arena-Bereich (in dem die Discard-
              // Pile sitzt). Partikel spawnen von der Mitte des Positioned-
              // Bereichs aus, daher die ungleichmaessigen Insets - die Mitte
              // soll genau ueber dem Discard liegen.
              if (_activeBurst != null)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.30,
                  bottom: MediaQuery.of(context).size.height * 0.32,
                  left: 0,
                  right: 0,
                  child: LumoCardBurst(
                    key: ValueKey('burst-$_burstKey'),
                    style: _activeBurst!,
                    onDone: () {
                      if (mounted) setState(() => _activeBurst = null);
                    },
                  ),
                ),
              // PR H1 2026-05-23: Star-Burst-Lottie bei richtiger Lernfrage.
              // Liegt UEBER der Arena, IgnorePointer damit Tap-Events
              // weiter zur unterliegenden UI durchgehen.
              if (_showStarBurst)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: LumoLottie(
                        key: ValueKey('starburst-$_starBurstKey'),
                        asset: LumoAssetPaths.lottieStarBurst,
                        size: 220,
                        repeat: false,
                      ),
                    ),
                  ),
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
        ));
  }

  void _restartGame() {
    _roundSerial++;
    _rewardGiven = false;
    _callRewardGiven = false;
    _flyingCard = null;
    _flyStart = null;
    _flyEnd = null;
    _controller.restart();
  }

  Widget _buildControls(LumoCardsGameState s, int viewerIndex) {
    final myTurn = _showActionUi(s);
    final lowHand = s.players[viewerIndex].hand.length <= 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(children: [
        IconButton(
          tooltip: 'Avatar wechseln',
          onPressed: _changeAvatar,
          icon: const Icon(Icons.face_rounded, color: Colors.white),
        ),
        Expanded(
            child: Text(
          '${s.players[viewerIndex].name}: ${s.players[viewerIndex].hand.length} Karten',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        )),
        if (myTurn && lowHand && !_callRewardGiven)
          TextButton(
              onPressed: _onLumoCall,
              child: const Text('LUMO! +1',
                  style: TextStyle(color: Color(0xFFFFD974)))),
        if (myTurn)
          FilledButton.icon(
            onPressed:
                _flyingCard == null ? () => _controller.drawCard() : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ziehen'),
          ),
      ]),
    );
  }

  /// Action-Button nur waehrend Spielphase sichtbar.
  bool _showActionUi(LumoCardsGameState s) =>
      s.phase == GamePhase.playing && _isMyTurnVisible(s);

  int _rewardForStreak(int streak) {
    if (streak <= 1) return 3;
    return (3 + (streak - 1)).clamp(3, 6);
  }

  /// 'LUMO!'-Ruf wenn das Kind nur noch 1-2 Karten hat. Gibt einen
  /// Bonus-Stern und zeigt Feedback. Eigene Lumo-Spielmechanik.
  void _onLumoCall() {
    final s = _controller.state;
    if (_callRewardGiven ||
        s.phase != GamePhase.playing ||
        !_isMyTurnVisible(s) ||
        s.currentPlayer.hand.length > 2 ||
        _controller.turnClock.value) {
      return;
    }
    setState(() => _callRewardGiven = true);
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
  /// wir verstecken die Hand und zeigen 'Lumo überlegt …'.
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
              const Flexible(
                  child: Text(
                '🦊 Lumo überlegt …',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
