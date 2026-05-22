// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS — Models
// ════════════════════════════════════════════════════════════════════════
// 2-Spieler-Karten-Ablegespiel mit Pass-and-Play am Tablet.
// Eigenes Lumo-Design, keine UNO-Bezüge.
//
// Keine Flutter-Abhaengigkeit hier - reine Domain, testbar isoliert.
// ════════════════════════════════════════════════════════════════════════

/// Die vier Lumo-Kartenfarben.
enum LumoCardColor { orange, purple, blue, green }

/// Kartentypen. `number` hat eine Zahl, alle anderen sind Spezialkarten.
enum LumoCardType {
  number,
  lumoJump,      // Skip - Gegner setzt aus
  starRain,      // Draw 2 - Gegner zieht 2
  colorMagic,    // Wild - Spieler waehlt neue Farbe
  superRain,     // Wild Draw 4 - Gegner zieht 4 + Spieler waehlt Farbe
  whirlwind,     // Reverse - bei 2P aequivalent zu Skip / Draw 1
  thinkPause,    // Lumo-USP - Lernfrage oeffnet sich
}

/// Spielphasen - steuern was die UI gerade zeigt.
enum GamePhase {
  playing,
  chooseColor,
  learningQuestion,
  passDevice,
  gameOver,
}

/// Eine einzelne Karte.
///
/// Bei `colorMagic` ist `color` der Default-Anzeigewert (z.B. orange) -
/// die Karte ist trotzdem auf jede Farbe spielbar. Nach dem Legen darf
/// der Spieler eine neue `selectedColor` waehlen.
class LumoCard {
  const LumoCard({
    required this.id,
    required this.color,
    required this.type,
    this.number,
    this.symbol,
  });

  final String id;
  final LumoCardColor color;
  final LumoCardType type;

  /// Bei type=number: 1..9. Sonst null.
  final int? number;

  /// Optionales dekoratives Symbol (Stern, Blume, Buch, Stift, Mond,
  /// Herz, Fuchs-Pfote) - nur visuell, beeinflusst die Regeln nicht.
  final String? symbol;

  bool get isSpecial => type != LumoCardType.number;

  /// 'Wild'-Karte (jede Farbe legbar).
  bool get isWild =>
      type == LumoCardType.colorMagic || type == LumoCardType.superRain;

  @override
  String toString() {
    if (type == LumoCardType.number) return '${color.name}-$number';
    return '${color.name}-${type.name}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LumoCard && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Ein Spieler. Im MVP genau zwei Spieler (Pass-and-Play).
class LumoPlayer {
  const LumoPlayer({
    required this.id,
    required this.name,
    required this.hand,
    this.stars = 0,
  });

  final String id;
  final String name;
  final List<LumoCard> hand;
  final int stars;

  LumoPlayer copyWith({List<LumoCard>? hand, int? stars}) => LumoPlayer(
        id: id,
        name: name,
        hand: hand ?? this.hand,
        stars: stars ?? this.stars,
      );
}

/// Komplettes Spielzustand. Immutable - jeder `applyMove` gibt einen neuen
/// State zurueck. Erleichtert das Testen und Undo (falls spaeter).
class LumoCardsGameState {
  const LumoCardsGameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.drawPile,
    required this.discardPile,
    required this.selectedColor,
    required this.phase,
    this.winnerIndex,
    this.lastActionMessage,
    this.pendingLearningQuestion,
  });

  final List<LumoPlayer> players;
  final int currentPlayerIndex;
  final List<LumoCard> drawPile;
  final List<LumoCard> discardPile;

  /// Die aktuell 'gueltige' Farbe. Normalerweise = topCard.color, nach
  /// einer Farbzauber-Karte aber die vom Spieler gewaehlte Farbe.
  final LumoCardColor selectedColor;

  final GamePhase phase;

  /// Nur gesetzt wenn phase == gameOver.
  final int? winnerIndex;

  /// Letzte Aktion als kurzer Text fuer den Turn-Banner.
  /// z.B. 'Sternenregen! Zoey zieht 2 Karten.'
  final String? lastActionMessage;

  /// Nur gesetzt wenn phase == learningQuestion.
  final LearningQuestion? pendingLearningQuestion;

  LumoCard? get topCard => discardPile.isEmpty ? null : discardPile.last;
  LumoPlayer get currentPlayer => players[currentPlayerIndex];
  LumoPlayer get otherPlayer => players[1 - currentPlayerIndex];

  LumoCardsGameState copyWith({
    List<LumoPlayer>? players,
    int? currentPlayerIndex,
    List<LumoCard>? drawPile,
    List<LumoCard>? discardPile,
    LumoCardColor? selectedColor,
    GamePhase? phase,
    int? winnerIndex,
    String? lastActionMessage,
    Object? pendingLearningQuestion = _sentinel,
  }) =>
      LumoCardsGameState(
        players: players ?? this.players,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        drawPile: drawPile ?? this.drawPile,
        discardPile: discardPile ?? this.discardPile,
        selectedColor: selectedColor ?? this.selectedColor,
        phase: phase ?? this.phase,
        winnerIndex: winnerIndex ?? this.winnerIndex,
        lastActionMessage: lastActionMessage ?? this.lastActionMessage,
        pendingLearningQuestion: pendingLearningQuestion == _sentinel
            ? this.pendingLearningQuestion
            : pendingLearningQuestion as LearningQuestion?,
      );
}

/// Kleines Sentinel-Muster damit copyWith zwischen "nicht aendern" und
/// "explizit auf null setzen" unterscheiden kann.
const Object _sentinel = Object();

/// Eine kleine Lernfrage fuer die Denkpause-Karte.
class LearningQuestion {
  const LearningQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.hint,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? hint;
}
