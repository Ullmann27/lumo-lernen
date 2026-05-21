// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS — Game Controller
// ════════════════════════════════════════════════════════════════════════
// Duenner ChangeNotifier-Wrapper um die immutable Regel-Engine. Haelt den
// aktuellen GameState, leitet alle Aktionen an LumoCardsRules weiter und
// notifiziert die UI.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'lumo_cards_deck.dart';
import 'lumo_cards_models.dart';
import 'lumo_cards_rules.dart';

class LumoCardsGameController extends ChangeNotifier {
  LumoCardsGameController({
    required String player1Name,
    required String player2Name,
    int? seed,
  })  : _rng = seed == null ? Random() : Random(seed),
        _player1Name = player1Name,
        _player2Name = player2Name {
    _startNewGame();
  }

  final Random _rng;
  final String _player1Name;
  final String _player2Name;

  static const int _initialHandSize = 7;

  late LumoCardsGameState _state;
  LumoCardsGameState get state => _state;

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
      lastActionMessage:
          '$_player1Name faengt an. Lege eine passende Karte oder ziehe eine.',
    );
  }

  /// Karte spielen (wenn moeglich).
  void playCard(LumoCard card) {
    final next = LumoCardsRules.applyPlay(
      state: _state,
      card: card,
      rng: _rng,
    );
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
  }

  /// Karte ziehen.
  void drawCard({bool autoPlay = false}) {
    final next = LumoCardsRules.applyDraw(
      state: _state,
      rng: _rng,
      playIfPossible: autoPlay,
    );
    _state = next;
    notifyListeners();
  }

  /// Nach Farbzauber: Farbe waehlen.
  void selectColor(LumoCardColor color) {
    final next = LumoCardsRules.applyColorChoice(
      state: _state,
      chosen: color,
    );
    _state = next;
    notifyListeners();
  }

  /// Lernfrage beantworten.
  void answerLearningQuestion(int chosenIndex) {
    final next = LumoCardsRules.applyLearningAnswer(
      state: _state,
      chosenIndex: chosenIndex,
    );
    _state = next;
    notifyListeners();
  }

  /// 'Bereit'-Button im Pass-and-Play-Overlay.
  void confirmHandover() {
    final next = LumoCardsRules.confirmHandover(_state);
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
  }

  /// Nochmal spielen.
  void restart() {
    _startNewGame();
    notifyListeners();
  }
}
