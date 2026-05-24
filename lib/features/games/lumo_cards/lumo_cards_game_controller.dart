// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS — Game Controller
// ════════════════════════════════════════════════════════════════════════
// Duenner ChangeNotifier-Wrapper um die immutable Regel-Engine. Haelt den
// aktuellen GameState, leitet alle Aktionen an LumoCardsRules weiter und
// notifiziert die UI.
//
// Modi:
//  - vsBot=true (default): Kind spielt gegen Lumo. Lumo's Zug wird
//    automatisch ausgefuehrt nach kurzer Denkpause.
//  - vsBot=false: 2 Menschen am Tablet (Pass-and-Play wie urspruenglich).
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/lumo_sound.dart';
import '../../../core/lumo_voice.dart';
import 'learning_question_repository.dart';
import 'lumo_cards_deck.dart';
import 'lumo_cards_models.dart';
import 'lumo_cards_rules.dart';

class LumoCardsGameController extends ChangeNotifier {
  LumoCardsGameController({
    required String player1Name,
    required String player2Name,
    this.vsBot = true,
    this.enableVoice = true,
    int? seed,
  })  : _rng = seed == null ? Random() : Random(seed),
        _player1Name = player1Name,
        _player2Name = player2Name {
    _startNewGame();
  }

  final Random _rng;
  final String _player1Name;
  final String _player2Name;

  /// Wenn true: Spieler 2 wird vom Bot (Lumo) gespielt.
  final bool vsBot;

  /// Sprachausgabe an/aus.
  final bool enableVoice;

  static const int _initialHandSize = 7;

  late LumoCardsGameState _state;
  LumoCardsGameState get state => _state;

  /// Bot-Timer (cancelled on dispose).
  Timer? _botTimer;
  DateTime _lastSpeakAt = DateTime(2000);

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  /// Startet eine neue Runde mit frischem Deck.
  void _startNewGame() {
    final deck = LumoCardsDeck.buildDeck(rng: _rng);
    // 7 Karten pro Spieler.
    final (hand1, rest1) = LumoCardsDeck.draw(deck, _initialHandSize);
    final (hand2, rest2) = LumoCardsDeck.draw(rest1, _initialHandSize);
    // Erste Karte fuer Discard: keine Wild-Karte als Start, sonst muesste
    // Spieler 1 sofort eine Farbe waehlen. Wir suchen die erste Nicht-
    // Wild-Karte im Rest.
    var drawPile = rest2;
    LumoCard topCard;
    while (true) {
      final (drawn, restAfter) = LumoCardsDeck.draw(drawPile, 1);
      if (drawn.isEmpty) {
        // Notfall (sollte nie passieren): nimm trotzdem eine Wild-Karte.
        topCard = LumoCard(
          id: 'fallback',
          color: LumoCardColor.orange,
          type: LumoCardType.number,
          number: 1,
        );
        break;
      }
      drawPile = restAfter;
      if (!drawn.first.isWild) {
        topCard = drawn.first;
        break;
      }
      // Wild-Karte zurueck nach unten in den Stapel mischen.
      drawPile = [...drawPile, drawn.first];
    }

    _state = LumoCardsGameState(
      players: [
        LumoPlayer(id: 'p1', name: _player1Name, hand: hand1),
        LumoPlayer(id: 'p2', name: _player2Name, hand: hand2),
      ],
      currentPlayerIndex: 0,
      drawPile: drawPile,
      discardPile: [topCard],
      selectedColor: topCard.color,
      phase: GamePhase.playing,
      lastActionMessage: vsBot
          ? '$_player1Name faengt an. Lege eine passende Karte!'
          : '$_player1Name faengt an. Lege eine passende Karte oder ziehe eine.',
    );
    _speak(vsBot
        ? 'Willkommen bei Lumo Cards! Du faengst an.'
        : 'Willkommen bei Lumo Cards! ${_player1Name} faengt an.');
  }

  /// Karte spielen (wenn moeglich).
  void playCard(LumoCard card) {
    final wasPlayer1 = _state.currentPlayerIndex == 0;
    final next = LumoCardsRules.applyPlay(
      state: _state,
      card: card,
      rng: _rng,
      questionPicker: LearningQuestionRepository.instance.random,
    );
    if (identical(next, _state)) return;
    _state = next;
    _speakForLastAction(playedByPlayer1: wasPlayer1, card: card);
    _playSfxForPlay(card, next);
    notifyListeners();
    _maybeRunBotTurn();
  }

  /// Karte ziehen.
  void drawCard({bool autoPlay = false}) {
    final wasPlayer1 = _state.currentPlayerIndex == 0;
    final next = LumoCardsRules.applyDraw(
      state: _state,
      rng: _rng,
      playIfPossible: autoPlay,
    );
    _state = next;
    _speak(wasPlayer1 ? 'Du ziehst eine Karte.' : 'Lumo zieht eine Karte.');
    LumoSound.instance.play(SoundEffect.cardDraw);
    notifyListeners();
    _maybeRunBotTurn();
  }

  /// Tier 3 Audio 2026-05-23: spielt den passenden SFX nachdem eine Karte
  /// gelegt wurde. Bei +2/+4 ueberlagert sich der Karten-Whoosh mit dem
  /// Storm-Effekt. Bei Spiel-Ende kommt zusaetzlich win/lose.
  void _playSfxForPlay(LumoCard card, LumoCardsGameState next) {
    switch (card.type) {
      case LumoCardType.starRain:
        LumoSound.instance.play(SoundEffect.plus2);
        break;
      case LumoCardType.superRain:
        LumoSound.instance.play(SoundEffect.plus4);
        break;
      case LumoCardType.number:
      case LumoCardType.lumoJump:
      case LumoCardType.colorMagic:
      case LumoCardType.whirlwind:
      case LumoCardType.thinkPause:
        LumoSound.instance.play(SoundEffect.cardPlay);
        break;
    }
    if (next.phase == GamePhase.gameOver) {
      LumoSound.instance.play(
        next.winnerIndex == 0 ? SoundEffect.win : SoundEffect.lose,
      );
    }
  }

  /// Nach Farbzauber: Farbe waehlen.
  void selectColor(LumoCardColor color) {
    final next = LumoCardsRules.applyColorChoice(
      state: _state,
      chosen: color,
    );
    _state = next;
    _speak('Neue Farbe: ${_colorName(color)}.');
    notifyListeners();
    _maybeRunBotTurn();
  }

  /// Lernfrage beantworten.
  void answerLearningQuestion(int chosenIndex) {
    final next = LumoCardsRules.applyLearningAnswer(
      state: _state,
      chosenIndex: chosenIndex,
    );
    final correct = next.players[next.currentPlayerIndex == 0 ? 0 : 1].stars >
        _state.players[_state.currentPlayerIndex].stars;
    _state = next;
    _speak(correct
        ? 'Richtig! Plus einen Stern.'
        : 'Nicht ganz. Schau nochmal beim naechsten Mal.');
    notifyListeners();
    _maybeRunBotTurn();
  }

  /// 'Bereit'-Button im Pass-and-Play-Overlay.
  void confirmHandover() {
    final next = LumoCardsRules.confirmHandover(_state);
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
    _maybeRunBotTurn();
  }

  /// Nochmal spielen.
  void restart() {
    _botTimer?.cancel();
    _startNewGame();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────
  // BOT-LOGIK
  // ──────────────────────────────────────────────────────────────────

  /// Wenn vsBot UND Lumo dran ist UND wir nicht in einer Wahl-Phase
  /// stecken: nach kurzer Denkpause Lumo's Zug ausfuehren.
  void _maybeRunBotTurn() {
    if (!vsBot) return;
    final s = _state;
    if (s.phase == GamePhase.gameOver) return;
    // Heinz Fix 2026-05-22: Im Solo-Modus haengt das Spiel, wenn nach
    // Lumo's Zug die phase auf passDevice wechselt und DU (Index 0) dran
    // bist. Das Pass-Overlay wird im Solo-Modus nicht angezeigt (man gibt
    // ja kein Tablet weiter) - also gab es nichts zu tippen, der Action-
    // Button erschien nicht (er braucht phase==playing). Loesung: fuer den
    // Menschen automatisch uebernehmen -> playing, damit dein
    // "Karte ziehen"-Button erscheint und du immer weiterspielen kannst.
    if (s.phase == GamePhase.passDevice && s.currentPlayerIndex == 0) {
      _state = LumoCardsRules.confirmHandover(s);
      notifyListeners();
      return;
    }
    if (s.currentPlayerIndex != 1) return; // Lumo ist Spieler 2
    // Im Solo-Modus: kein Pass-Overlay - direkt zu Lumo's Zug.
    if (s.phase == GamePhase.passDevice) {
      // Auto-handover.
      _state = LumoCardsRules.confirmHandover(s);
      notifyListeners();
      _scheduleBotMove();
      return;
    }
    if (s.phase == GamePhase.playing) {
      _scheduleBotMove();
    }
    // chooseColor und learningQuestion macht der Bot direkt im _doBotMove.
  }

  void _scheduleBotMove() {
    _botTimer?.cancel();
    // Denkpause damit es sich nach echtem Gegner anfuehlt.
    _botTimer = Timer(
      Duration(milliseconds: 900 + _rng.nextInt(700)),
      _doBotMove,
    );
  }

  void _doBotMove() {
    final s = _state;
    if (s.phase == GamePhase.gameOver) return;
    if (s.currentPlayerIndex != 1) return;

    // Phase chooseColor: Lumo waehlt eine Farbe (die haeufigste in
    // seiner Hand, oder zufaellig wenn Hand leer/gemischt).
    if (s.phase == GamePhase.chooseColor) {
      final color = _pickBotColor(s);
      _state = LumoCardsRules.applyColorChoice(state: s, chosen: color);
      _speak('Lumo waehlt ${_colorName(color)}.');
      notifyListeners();
      _maybeRunBotTurn();
      return;
    }

    // Phase learningQuestion: Lumo antwortet (richtig zu 60%).
    if (s.phase == GamePhase.learningQuestion) {
      final q = s.pendingLearningQuestion;
      if (q == null) return;
      final lumoCorrect = _rng.nextDouble() < 0.60;
      final chosen = lumoCorrect
          ? q.correctIndex
          : (q.correctIndex + 1 + _rng.nextInt(q.options.length - 1)) %
              q.options.length;
      _state = LumoCardsRules.applyLearningAnswer(
        state: s,
        chosenIndex: chosen,
      );
      _speak(lumoCorrect
          ? 'Lumo weiss die Antwort!'
          : 'Lumo hat sich vertan.');
      notifyListeners();
      _maybeRunBotTurn();
      return;
    }

    // Phase playing: beste spielbare Karte waehlen, sonst ziehen.
    final topCard = s.topCard;
    if (topCard == null) return;
    final best = _chooseBestPlay(s, topCard);
    if (best != null) {
      _state = LumoCardsRules.applyPlay(
        state: s,
        card: best,
        rng: _rng,
        questionPicker: LearningQuestionRepository.instance.random,
      );
      _speakForLastAction(playedByPlayer1: false, card: best);
      _playSfxForPlay(best, _state);
      notifyListeners();
      _maybeRunBotTurn();
    } else {
      _state = LumoCardsRules.applyDraw(
        state: s,
        rng: _rng,
        playIfPossible: true,
      );
      _speak('Lumo zieht eine Karte.');
      LumoSound.instance.play(SoundEffect.cardDraw);
      notifyListeners();
      _maybeRunBotTurn();
    }
  }

  /// Strategische Karten-Auswahl fuer den Bot.
  ///
  /// Heinz 2026-05-22: 'cleverer + strategischer'.
  /// Statt der ersten spielbaren Karte wertet der Bot jede Option per Score:
  ///  - Wild Draw 4: nur wenn keine andere Option ODER der Gegner schon
  ///    fast leer ist (Killer-Move). Sonst zurueckhalten als Joker.
  ///  - Wild: nur wenn keine Farbe matcht. Sonst Color-Karte spielen.
  ///  - Block-Karten (Skip/Reverse/+2): besonders hoch wenn der Gegner
  ///    schon 1-2 Karten hat -> Tempo rausnehmen.
  ///  - Zahlen: bevorzugt aus der Farbe in der wir VIELE Karten haben
  ///    (behalten Farbkontrolle) und hohe Zahlen zuerst (Punkt-Strafe
  ///    minimieren falls wir verlieren).
  LumoCard? _chooseBestPlay(LumoCardsGameState s, LumoCard topCard) {
    final playables = s.currentPlayer.hand
        .where((c) => LumoCardsRules.isPlayable(
              card: c,
              topCard: topCard,
              selectedColor: s.selectedColor,
            ))
        .toList();
    if (playables.isEmpty) return null;
    if (playables.length == 1) return playables.first;

    final oppLow = s.otherPlayer.hand.length <= 2;
    final hand = s.currentPlayer.hand;

    int colorCountInHand(LumoCardColor c) =>
        hand.where((h) => h.color == c).length;

    int score(LumoCard c) {
      switch (c.type) {
        case LumoCardType.superRain:
          // Wild Draw 4: heben fuer Notfall. Killer wenn Gegner low.
          return oppLow ? 92 : 8;
        case LumoCardType.colorMagic:
          // Wild: nur wenn wir KEINE Farbkarte haben die passt.
          final hasColorMatch = playables.any((p) =>
              !p.isWild &&
              (p.color == s.selectedColor || p.number == topCard.number));
          return hasColorMatch ? 12 : 75;
        case LumoCardType.lumoJump: // Skip
        case LumoCardType.whirlwind: // Reverse
        case LumoCardType.starRain: // +2
          return oppLow ? 88 : 58;
        case LumoCardType.thinkPause:
          return 48;
        case LumoCardType.number:
          // Behalte Farbkontrolle: bevorzugt die Farbe mit den meisten
          // Karten in unserer Hand. Plus hohe Zahlen zuerst.
          final dominance = colorCountInHand(c.color);
          final num = c.number ?? 0;
          return 30 + num + dominance * 3;
      }
    }

    playables.sort((a, b) => score(b).compareTo(score(a)));
    return playables.first;
  }

  /// Bot waehlt die haeufigste Farbe in seiner Hand.
  LumoCardColor _pickBotColor(LumoCardsGameState s) {
    final counts = <LumoCardColor, int>{
      for (final c in LumoCardColor.values) c: 0,
    };
    for (final card in s.currentPlayer.hand) {
      counts[card.color] = (counts[card.color] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  // ──────────────────────────────────────────────────────────────────
  // VOICE-KOMMENTARE
  // ──────────────────────────────────────────────────────────────────

  void _speak(String text) {
    if (!enableVoice) return;
    // Drossel: max 1 Spruch pro 1500ms, sonst wird zu viel geredet.
    final now = DateTime.now();
    if (now.difference(_lastSpeakAt).inMilliseconds < 1500) return;
    _lastSpeakAt = now;
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _speakForLastAction({required bool playedByPlayer1, required LumoCard card}) {
    final who = playedByPlayer1 ? 'Du' : 'Lumo';
    final color = _colorName(card.color);
    switch (card.type) {
      case LumoCardType.number:
        _speak(playedByPlayer1
            ? 'Sehr gut! $color ${card.number}.'
            : '$who legt $color ${card.number}.');
        break;
      case LumoCardType.lumoJump:
        _speak('Lumo-Sprung! Aussetzen.');
        break;
      case LumoCardType.starRain:
        _speak(playedByPlayer1
            ? 'Sternenregen! Lumo zieht zwei.'
            : 'Sternenregen! Du ziehst zwei Karten.');
        break;
      case LumoCardType.colorMagic:
        _speak('Farbzauber! Neue Farbe waehlen.');
        break;
      case LumoCardType.superRain:
        _speak(playedByPlayer1
            ? 'Super-Sternenregen! Lumo zieht vier.'
            : 'Super-Sternenregen! Du ziehst vier Karten.');
        break;
      case LumoCardType.whirlwind:
        _speak(playedByPlayer1
            ? 'Wirbelwind! Lumo zieht eine.'
            : 'Wirbelwind! Du ziehst eine Karte.');
        break;
      case LumoCardType.thinkPause:
        _speak('Denkpause! Eine Frage von mir.');
        break;
    }
  }

  String _colorName(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return 'Orange';
      case LumoCardColor.purple:
        return 'Lila';
      case LumoCardColor.blue:
        return 'Blau';
      case LumoCardColor.green:
        return 'Gruen';
    }
  }
}
