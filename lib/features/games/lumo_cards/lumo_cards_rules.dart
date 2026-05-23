// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS — Regel-Engine
// ════════════════════════════════════════════════════════════════════════
// Reine Domain-Logik: isPlayable + Move-Application + Spezialkarten-Effekte.
// Keine Flutter-Abhaengigkeit -> 100% testbar.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'lumo_cards_deck.dart';
import 'lumo_cards_models.dart';

class LumoCardsRules {
  /// Pruefe ob `card` auf `topCard` mit aktueller `selectedColor`
  /// gelegt werden darf.
  ///
  /// Regeln:
  ///  - Wild-Karte (colorMagic) ist immer spielbar
  ///  - Gleiche Farbe wie selectedColor: spielbar
  ///  - Gleiche Zahl wie topCard (number==number): spielbar
  ///  - Gleicher Spezialtyp wie topCard: spielbar (z.B. starRain auf starRain)
  ///  - Sonst: NICHT spielbar
  static bool isPlayable({
    required LumoCard card,
    required LumoCard topCard,
    required LumoCardColor selectedColor,
  }) {
    if (card.isWild) return true;
    if (card.color == selectedColor) return true;
    if (card.type == LumoCardType.number &&
        topCard.type == LumoCardType.number &&
        card.number == topCard.number) {
      return true;
    }
    if (card.isSpecial &&
        topCard.isSpecial &&
        card.type == topCard.type) {
      return true;
    }
    return false;
  }

  /// Spielt eine Karte aus der Hand des aktuellen Spielers.
  ///
  /// Rueckgabe ist der neue State mit:
  ///  - Karte aus Hand entfernt
  ///  - Karte oben auf dem Ablagestapel
  ///  - Effekt der Spezialkarte angewendet (Gegner zieht / setzt aus / Farbwahl)
  ///  - phase entsprechend gesetzt (passDevice, chooseColor, learningQuestion,
  ///    gameOver)
  ///
  /// Wenn die Karte nicht spielbar ist, wird der State unveraendert
  /// zurueckgegeben.
  static LumoCardsGameState applyPlay({
    required LumoCardsGameState state,
    required LumoCard card,
    Random? rng,
  }) {
    if (state.phase != GamePhase.playing) return state;
    if (state.topCard == null) return state;
    if (!isPlayable(
      card: card,
      topCard: state.topCard!,
      selectedColor: state.selectedColor,
    )) {
      return state;
    }

    // Karte aus Hand entfernen.
    final newPlayers = List<LumoPlayer>.of(state.players);
    final currentHand = List<LumoCard>.of(state.currentPlayer.hand)
      ..removeWhere((c) => c.id == card.id);
    newPlayers[state.currentPlayerIndex] =
        state.currentPlayer.copyWith(hand: currentHand);

    // Auf Ablage legen.
    final newDiscard = List<LumoCard>.of(state.discardPile)..add(card);

    // Sieg?
    if (currentHand.isEmpty) {
      return state.copyWith(
        players: newPlayers,
        discardPile: newDiscard,
        selectedColor: card.color,
        phase: GamePhase.gameOver,
        winnerIndex: state.currentPlayerIndex,
        lastActionMessage:
            '${state.currentPlayer.name} hat alle Karten abgelegt!',
      );
    }

    // Effekt anwenden.
    switch (card.type) {
      case LumoCardType.number:
        return _passTurn(state.copyWith(
          players: newPlayers,
          discardPile: newDiscard,
          selectedColor: card.color,
          lastActionMessage:
              '${state.currentPlayer.name} legt ${card.color.name} ${card.number}.',
        ));

      case LumoCardType.lumoJump:
        // Skip-Karte. 2P: aktueller bleibt dran (phase=playing).
        // 3-4P: ueberspringt den naechsten Spieler in Richtung.
        if (state.players.length == 2) {
          return state.copyWith(
            players: newPlayers,
            discardPile: newDiscard,
            selectedColor: card.color,
            phase: GamePhase.playing,
            lastActionMessage:
                'Lumo-Sprung! ${state.otherPlayer.name} setzt aus.',
          );
        }
        final skippedName = state.players[state.nextPlayerIndex()].name;
        return _passTurn(
          state.copyWith(
            players: newPlayers,
            discardPile: newDiscard,
            selectedColor: card.color,
            lastActionMessage: 'Lumo-Sprung! $skippedName setzt aus.',
          ),
          steps: 2,
        );

      case LumoCardType.starRain:
        // +2-Karte. Naechster Spieler zieht 2 Karten.
        // 2P: zieht und ist sofort dran (steps=1).
        // 3-4P: zieht UND ueberspringt eigenen Zug (steps=2).
        final nextIdxRain = state.nextPlayerIndex();
        final (drawnRain, restDrawRain) = _safeDraw(
          state.drawPile,
          state.discardPile,
          2,
          rng,
        );
        final nextHandRain =
            List<LumoCard>.of(state.players[nextIdxRain].hand)
              ..addAll(drawnRain);
        newPlayers[nextIdxRain] =
            state.players[nextIdxRain].copyWith(hand: nextHandRain);
        final rainSteps = state.players.length == 2 ? 1 : 2;
        return _passTurn(
          state.copyWith(
            players: newPlayers,
            drawPile: restDrawRain,
            discardPile: newDiscard,
            selectedColor: card.color,
            lastActionMessage:
                'Sternenregen! ${state.players[nextIdxRain].name} zieht 2 Karten.',
          ),
          steps: rainSteps,
        );

      case LumoCardType.colorMagic:
        // Spieler waehlt neue Farbe -> phase = chooseColor.
        return state.copyWith(
          players: newPlayers,
          discardPile: newDiscard,
          phase: GamePhase.chooseColor,
          lastActionMessage:
              'Farbzauber! ${state.currentPlayer.name} waehlt eine Farbe.',
        );

      case LumoCardType.superRain:
        // +4-Karte. Naechster Spieler zieht 4, dann Farbwahl.
        // Skip nach Farbwahl wird in applyColorChoice (steps=2 fuer 3-4P)
        // gehandhabt, hier nur Karten ziehen + chooseColor-Phase.
        final nextIdxSuper = state.nextPlayerIndex();
        final (drawnSuper, restDrawSuper) = _safeDraw(
          state.drawPile,
          state.discardPile,
          4,
          rng,
        );
        final nextHandSuper =
            List<LumoCard>.of(state.players[nextIdxSuper].hand)
              ..addAll(drawnSuper);
        newPlayers[nextIdxSuper] =
            state.players[nextIdxSuper].copyWith(hand: nextHandSuper);
        return state.copyWith(
          players: newPlayers,
          drawPile: restDrawSuper,
          discardPile: newDiscard,
          phase: GamePhase.chooseColor,
          lastActionMessage:
              'Super-Sternenregen! ${state.players[nextIdxSuper].name} zieht 4 Karten - jetzt Farbe waehlen.',
        );

      case LumoCardType.whirlwind:
        // Reverse-Karte.
        // 2P: Gegner zieht 1 Karte, Zug wechselt (OLD-Verhalten).
        // 3-4P: Richtung flippt, naechster Spieler in NEUER Richtung.
        if (state.players.length == 2) {
          final (drawnWind, restDrawWind) = _safeDraw(
            state.drawPile,
            state.discardPile,
            1,
            rng,
          );
          final otherHandWind = List<LumoCard>.of(state.otherPlayer.hand)
            ..addAll(drawnWind);
          newPlayers[1 - state.currentPlayerIndex] =
              state.otherPlayer.copyWith(hand: otherHandWind);
          return _passTurn(state.copyWith(
            players: newPlayers,
            drawPile: restDrawWind,
            discardPile: newDiscard,
            selectedColor: card.color,
            lastActionMessage:
                'Wirbelwind! ${state.otherPlayer.name} zieht 1 Karte.',
          ));
        }
        // 3-4P: direction flippen + 1 Schritt
        return _passTurn(state.copyWith(
          players: newPlayers,
          discardPile: newDiscard,
          selectedColor: card.color,
          direction: -state.direction,
          lastActionMessage: 'Wirbelwind! Richtung wechselt.',
        ));

      case LumoCardType.thinkPause:
        // Oeffnet eine zufaellige Lernfrage.
        final q = _pickLearningQuestion(rng);
        return state.copyWith(
          players: newPlayers,
          discardPile: newDiscard,
          selectedColor: card.color,
          phase: GamePhase.learningQuestion,
          pendingLearningQuestion: q,
          lastActionMessage:
              'Denkpause! Lumo hat eine kleine Frage fuer ${state.currentPlayer.name}.',
        );
    }
  }

  /// Wendet die Farbwahl nach einer colorMagic-Karte an.
  ///
  /// Bei +4 (superRain) in 3-4P: das Opfer hat bereits 4 Karten gezogen
  /// und ueberspringt jetzt zusaetzlich seinen Zug -> steps=2.
  /// Bei Wild (colorMagic) oder bei +4 in 2P: normaler Zug-Wechsel
  /// (steps=1), was im 2P-Fall identisch zur alten Logik ist.
  static LumoCardsGameState applyColorChoice({
    required LumoCardsGameState state,
    required LumoCardColor chosen,
  }) {
    if (state.phase != GamePhase.chooseColor) return state;
    final isSuperRain = state.topCard?.type == LumoCardType.superRain;
    final steps =
        (state.players.length > 2 && isSuperRain) ? 2 : 1;
    return _passTurn(
      state.copyWith(
        selectedColor: chosen,
        phase: GamePhase.playing,
        lastActionMessage:
            '${state.currentPlayer.name} waehlt ${chosen.name}.',
      ),
      steps: steps,
    );
  }

  /// Beantwortet die Lernfrage. Richtig: +1 Stern, Spieler darf nochmal
  /// legen. Falsch: freundlicher Tipp, Zug endet.
  static LumoCardsGameState applyLearningAnswer({
    required LumoCardsGameState state,
    required int chosenIndex,
  }) {
    if (state.phase != GamePhase.learningQuestion) return state;
    final q = state.pendingLearningQuestion;
    if (q == null) return state;
    final correct = chosenIndex == q.correctIndex;

    final newPlayers = List<LumoPlayer>.of(state.players);
    if (correct) {
      newPlayers[state.currentPlayerIndex] =
          state.currentPlayer.copyWith(stars: state.currentPlayer.stars + 1);
      return state.copyWith(
        players: newPlayers,
        phase: GamePhase.playing,
        pendingLearningQuestion: null,
        lastActionMessage:
            'Richtig! ${state.currentPlayer.name} bekommt einen Stern und darf nochmal.',
      );
    } else {
      return _passTurn(state.copyWith(
        phase: GamePhase.playing,
        pendingLearningQuestion: null,
        lastActionMessage:
            'Schade. ${q.hint ?? "Beim naechsten Mal klappt es!"}',
      ));
    }
  }

  /// Spieler zieht eine Karte vom Stapel.
  ///
  /// Wenn die gezogene Karte direkt spielbar waere, behaelt der Spieler
  /// die Wahl - sie landet einfach in der Hand und der Zug endet, ausser
  /// `playIfPossible` ist true (dann wird sie automatisch gelegt).
  static LumoCardsGameState applyDraw({
    required LumoCardsGameState state,
    Random? rng,
    bool playIfPossible = false,
  }) {
    if (state.phase != GamePhase.playing) return state;

    final (drawn, restDraw) = _safeDraw(
      state.drawPile,
      state.discardPile,
      1,
      rng,
    );
    if (drawn.isEmpty) {
      // Kein Nachschub mehr - Zug einfach uebergeben.
      return _passTurn(state.copyWith(
        lastActionMessage: 'Keine Karten mehr zum Ziehen.',
      ));
    }

    final card = drawn.first;
    final newPlayers = List<LumoPlayer>.of(state.players);
    final newHand = List<LumoCard>.of(state.currentPlayer.hand)..add(card);
    newPlayers[state.currentPlayerIndex] =
        state.currentPlayer.copyWith(hand: newHand);

    if (playIfPossible &&
        state.topCard != null &&
        isPlayable(
          card: card,
          topCard: state.topCard!,
          selectedColor: state.selectedColor,
        )) {
      // Direkt legen.
      return applyPlay(
        state: state.copyWith(
          players: newPlayers,
          drawPile: restDraw,
        ),
        card: card,
        rng: rng,
      );
    }

    return _passTurn(state.copyWith(
      players: newPlayers,
      drawPile: restDraw,
      lastActionMessage: '${state.currentPlayer.name} zieht eine Karte.',
    ));
  }

  /// Bestaetigt das Tablet-Uebergeben (passDevice -> playing).
  static LumoCardsGameState confirmHandover(LumoCardsGameState state) {
    if (state.phase != GamePhase.passDevice) return state;
    return state.copyWith(phase: GamePhase.playing);
  }

  // ──────────────────────────────────────────────────────────────────
  // Private Helfer
  // ──────────────────────────────────────────────────────────────────

  /// Schaltet `steps` Spieler weiter in der aktuellen Richtung und
  /// setzt phase = passDevice.
  ///
  /// Bei 2 Spielern mit direction=1:
  ///   steps=1 -> currentPlayerIndex 0 ↔ 1 (identisch zum alten 1-Spieler-XOR)
  ///   steps=2 -> bleibt beim aktuellen Spieler (Skip in 2P)
  ///
  /// Bei 3-4 Spielern:
  ///   steps=1 -> normaler Zug
  ///   steps=2 -> ueberspringt einen Spieler (Skip / Draw-Opfer)
  ///
  /// Negative steps oder direction=-1 rotieren rueckwaerts (Reverse).
  static LumoCardsGameState _passTurn(
    LumoCardsGameState state, {
    int steps = 1,
  }) {
    final n = state.players.length;
    final dir = state.direction;
    // +n*4 als Polster gegen negative Modulos (Dart Modulo erlaubt zwar
    // negative Werte, aber dies vermeidet jede Subtilitaet).
    final nextIdx = (state.currentPlayerIndex + steps * dir + n * 4) % n;
    return state.copyWith(
      currentPlayerIndex: nextIdx,
      phase: GamePhase.passDevice,
    );
  }

  /// Zieht `count` Karten; falls Draw-Pile leer wird, wird der Discard
  /// (ohne Top-Karte) zurueck-gemischt.
  static (List<LumoCard>, List<LumoCard>) _safeDraw(
    List<LumoCard> drawPile,
    List<LumoCard> discardPile,
    int count,
    Random? rng,
  ) {
    var draw = drawPile;
    var discard = discardPile;
    final taken = <LumoCard>[];
    for (int i = 0; i < count; i++) {
      if (draw.isEmpty) {
        final (newDraw, newDiscard) = LumoCardsDeck.reshuffle(
          drawPile: draw,
          discardPile: discard,
          rng: rng,
        );
        draw = newDraw;
        discard = newDiscard;
        if (draw.isEmpty) break;
      }
      final (drawn, rest) = LumoCardsDeck.draw(draw, 1);
      taken.addAll(drawn);
      draw = rest;
    }
    return (taken, draw);
  }

  /// Kleiner lokaler Lernfragen-Pool fuer die Denkpause-Karte.
  /// Keine KI, klassenstufen-unabhaengig im MVP.
  static const List<LearningQuestion> _learningQuestions = [
    LearningQuestion(
      prompt: 'Wie viel ist 3 + 2?',
      options: ['4', '5', '6', '7'],
      correctIndex: 1,
      hint: '3 plus 2 ist 5.',
    ),
    LearningQuestion(
      prompt: 'Welche Zahl kommt nach 6?',
      options: ['5', '7', '8', '6'],
      correctIndex: 1,
      hint: 'Nach 6 kommt 7.',
    ),
    LearningQuestion(
      prompt: 'Welcher Buchstabe beginnt das Wort Sonne?',
      options: ['O', 'S', 'N', 'A'],
      correctIndex: 1,
      hint: 'Sonne beginnt mit S.',
    ),
    LearningQuestion(
      prompt: 'Wie viel ist 4 + 4?',
      options: ['6', '7', '8', '9'],
      correctIndex: 2,
      hint: '4 plus 4 ergibt 8.',
    ),
    LearningQuestion(
      prompt: 'Welche Farbe hat eine reife Banane?',
      options: ['Rot', 'Gelb', 'Blau', 'Gruen'],
      correctIndex: 1,
      hint: 'Eine reife Banane ist gelb.',
    ),
    LearningQuestion(
      prompt: 'Wie viel ist 9 - 3?',
      options: ['5', '6', '7', '8'],
      correctIndex: 1,
      hint: '9 minus 3 sind 6.',
    ),
    LearningQuestion(
      prompt: 'Welcher Buchstabe beginnt Apfel?',
      options: ['A', 'P', 'F', 'L'],
      correctIndex: 0,
      hint: 'Apfel beginnt mit A.',
    ),
    LearningQuestion(
      prompt: 'Wie viele Beine hat ein Hund?',
      options: ['2', '3', '4', '5'],
      correctIndex: 2,
      hint: 'Ein Hund hat 4 Beine.',
    ),
    LearningQuestion(
      prompt: 'Welche Zahl ist die groesste?',
      options: ['12', '8', '5', '9'],
      correctIndex: 0,
      hint: '12 ist die groesste der vier.',
    ),
    LearningQuestion(
      prompt: 'Wie viel ist 5 + 5?',
      options: ['9', '10', '11', '15'],
      correctIndex: 1,
      hint: '5 plus 5 ergibt 10.',
    ),
    LearningQuestion(
      prompt: 'Welche Form hat ein Ball?',
      options: ['Eckig', 'Rund', 'Spitz', 'Flach'],
      correctIndex: 1,
      hint: 'Ein Ball ist rund.',
    ),
    LearningQuestion(
      prompt: 'Wie viele Finger hat eine Hand?',
      options: ['3', '4', '5', '6'],
      correctIndex: 2,
      hint: 'Eine Hand hat 5 Finger.',
    ),
  ];

  static LearningQuestion _pickLearningQuestion(Random? rng) {
    final r = rng ?? Random();
    return _learningQuestions[r.nextInt(_learningQuestions.length)];
  }
}
