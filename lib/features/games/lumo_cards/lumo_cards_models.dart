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

/// Spieler-Typ: echtes Kind vs. KI-Bot.
enum LumoPlayerKind { human, bot }

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

/// Ein Spieler. 2-4 Spieler unterstuetzt.
class LumoPlayer {
  const LumoPlayer({
    required this.id,
    required this.name,
    required this.hand,
    this.stars = 0,
    this.score = 0,
    this.kind = LumoPlayerKind.human,
    this.avatarAssetPath,
  });

  final String id;
  final String name;
  final List<LumoCard> hand;
  final int stars;

  /// Gesamtpunkte ueber mehrere Runden (Heinz Mockup 'Round 3/10 Target 100').
  final int score;

  /// Mensch oder Bot? Bots werden vom Controller automatisch gesteuert.
  final LumoPlayerKind kind;

  /// Optionaler Avatar-PNG-Pfad. Wenn null wird ein generisches Emoji
  /// (Fuchs fuer Bot) verwendet.
  final String? avatarAssetPath;

  bool get isBot => kind == LumoPlayerKind.bot;

  LumoPlayer copyWith({
    List<LumoCard>? hand,
    int? stars,
    int? score,
  }) =>
      LumoPlayer(
        id: id,
        name: name,
        hand: hand ?? this.hand,
        stars: stars ?? this.stars,
        score: score ?? this.score,
        kind: kind,
        avatarAssetPath: avatarAssetPath,
      );
}

/// Komplettes Spielzustand. Immutable - jeder `applyMove` gibt einen neuen
/// State zurueck. Erleichtert das Testen und Undo (falls spaeter).
///
/// 2-4 Spieler werden unterstuetzt. `direction` steuert die Rotations-
/// richtung (1 = im Uhrzeigersinn, -1 = gegen). Reverse-Karte flippt.
class LumoCardsGameState {
  const LumoCardsGameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.drawPile,
    required this.discardPile,
    required this.selectedColor,
    required this.phase,
    this.direction = 1,
    this.winnerIndex,
    this.lastActionMessage,
    this.pendingLearningQuestion,
  });

  final List<LumoPlayer> players;
  final int currentPlayerIndex;
  final List<LumoCard> drawPile;
  final List<LumoCard> discardPile;

  /// Rotationsrichtung: +1 normal, -1 nach Reverse.
  /// Bei 2 Spielern verhaelt sich Reverse aequivalent zu Skip (der Zug
  /// kommt sofort zurueck).
  final int direction;

  /// Die aktuell 'gueltige' Farbe. Normalerweise = topCard.color, nach
  /// einer Farbzauber-Karte aber die vom Spieler gewaehlte Farbe.
  final LumoCardColor selectedColor;

  final GamePhase phase;

  /// Nur gesetzt wenn phase == gameOver.
  final int? winnerIndex;

  /// Letzte Aktion als kurzer Text fuer den Turn-Banner.
  final String? lastActionMessage;

  /// Nur gesetzt wenn phase == learningQuestion.
  final LearningQuestion? pendingLearningQuestion;

  LumoCard? get topCard => discardPile.isEmpty ? null : discardPile.last;
  LumoPlayer get currentPlayer => players[currentPlayerIndex];

  /// Naechster Spieler in der aktuellen Richtung (modulo Spieleranzahl).
  int nextPlayerIndex([int steps = 1]) {
    final n = players.length;
    return (currentPlayerIndex + steps * direction + n * 4) % n;
  }

  LumoPlayer get nextPlayer => players[nextPlayerIndex()];

  /// Backwards-compat fuer 2-Spieler-Modus: bei 2 Spielern ist der
  /// "andere" Spieler immer der naechste. Bei 3-4 Spielern ist es der
  /// naechste in Richtung - was meistens auch das ist was die +2/+4-
  /// Effekte treffen sollen.
  LumoPlayer get otherPlayer => nextPlayer;

  LumoCardsGameState copyWith({
    List<LumoPlayer>? players,
    int? currentPlayerIndex,
    List<LumoCard>? drawPile,
    List<LumoCard>? discardPile,
    LumoCardColor? selectedColor,
    GamePhase? phase,
    int? direction,
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
        direction: direction ?? this.direction,
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
