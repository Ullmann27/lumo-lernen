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

import '../../../core/lumo_voice.dart';
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
    );
    if (identical(next, _state)) return;
    _state = next;
    _speakForLastAction(playedByPlayer1: wasPlayer1, card: card);
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
    notifyListeners();
    _maybeRunBotTurn();
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

    // Phase playing: spielbare Karte suchen, sonst ziehen.
    final topCard = s.topCard;
    if (topCard == null) return;
    final playable = s.currentPlayer.hand.firstWhere(
      (c) => LumoCardsRules.isPlayable(
        card: c,
        topCard: topCard,
        selectedColor: s.selectedColor,
      ),
      orElse: () => const LumoCard(
        id: '__none__',
        color: LumoCardColor.orange,
        type: LumoCardType.number,
      ),
    );
    if (playable.id != '__none__') {
      _state = LumoCardsRules.applyPlay(
        state: s,
        card: playable,
        rng: _rng,
      );
      _speakForLastAction(playedByPlayer1: false, card: playable);
      notifyListeners();
      _maybeRunBotTurn();
    } else {
      _state = LumoCardsRules.applyDraw(
        state: s,
        rng: _rng,
        playIfPossible: true,
      );
      _speak('Lumo zieht eine Karte.');
      notifyListeners();
      _maybeRunBotTurn();
    }
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
