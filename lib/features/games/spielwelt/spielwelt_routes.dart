import '../../../domain/games/game_world.dart';

/// How a Spielwelt portal reaches its real destination.
enum SpielweltTargetKind { flutterScreen, nativeScene }

/// One row of the visible-portal contract:
/// `identity → title → cover → callback → route → real target`.
class SpielweltRoute {
  const SpielweltRoute({
    required this.identity,
    required this.title,
    required this.semanticTitle,
    required this.tagline,
    required this.coverAsset,
    required this.kind,
    required this.target,
    required this.targetDescription,
    this.gameId,
  });

  /// Stable portal id, also used as `spielwelt-portal-$identity`.
  final String identity;
  final String title;
  final String semanticTitle;
  final String tagline;

  /// Unique cover for this game. Never reused by another portal.
  final String coverAsset;
  final SpielweltTargetKind kind;

  /// Flutter widget name or the native `launch3D` scene key.
  final String target;
  final String targetDescription;
  final GameId? gameId;

  bool get isNative => kind == SpielweltTargetKind.nativeScene;
}

/// Tile-menu layout used on every size.
///
/// Heinz prefers the original image-tile hub (Lumo hero, adventure
/// button, glass cards) over the page-34 arch/plaza composition.
/// Wider canvases keep that design and add columns instead.
class SpielweltLayout {
  static const double threeColumnMinWidth = 560;
  static const double fourColumnMinWidth = 820;

  /// The arch/plaza reference hub is retired.
  static bool useReferenceHub(double width, [double height = 0]) => false;

  static bool isPortraitReference(double width, double height) => false;

  static int tileColumns(double width) {
    if (width >= fourColumnMinWidth) return 4;
    if (width >= threeColumnMinWidth) return 3;
    return 2;
  }
}

/// Canonical game worlds. Each portal identifies a real destination.
/// matches Heinz's 2013 list.
class SpielweltRoutes {
  SpielweltRoutes._();

  static const List<SpielweltRoute> all = [
    SpielweltRoute(
      identity: 'world',
      title: 'Lumo World',
      semanticTitle: 'Lumo World',
      tagline: 'Erkunden, Schätze finden, dein Dorf bauen und weiterziehen.',
      coverAsset: 'assets/lumo_design/spielwelt/cover_world.webp',
      kind: SpielweltTargetKind.nativeScene,
      target: 'world',
      targetDescription:
          'Eine Godot Open World mit Schatzinsel-Optik, freier Erkundung, Dorfwirtschaft und direktem Baumodus (launch3D scene=world)',
    ),
    SpielweltRoute(
      identity: 'logic',
      title: 'Logikspiele',
      semanticTitle: 'Logikspiele',
      tagline: 'Sudoku, Wörterwerkstatt und Zahlenbrücken.',
      coverAsset: 'assets/lumo_design/spielwelt/cover_logic.webp',
      kind: SpielweltTargetKind.flutterScreen,
      target: 'LogicGamesScreen',
      targetDescription:
          'Flutter Logikspiele mit 144 Aufgaben für die Klassen 1 bis 4',
    ),
    SpielweltRoute(
      identity: 'memory',
      title: 'Memory',
      semanticTitle: 'Memory',
      tagline: 'Finde die Paare!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_memory.jpg',
      kind: SpielweltTargetKind.flutterScreen,
      target: 'LumoMemoryScreen',
      targetDescription: 'Flutter Memory-Spiel',
      gameId: GameId.memory,
    ),
    SpielweltRoute(
      identity: 'cards',
      title: 'Cards',
      semanticTitle: 'Lumo Karten',
      tagline: 'Sammeln. Spielen. Staunen!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_cards.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'cards',
      targetDescription:
          'Godot Kartentisch: Sternenstich, Sternenleiter, Lumo-Quartett und Punktlandung '
          '(launch3D scene=cards)',
      gameId: GameId.cards,
    ),
    SpielweltRoute(
      identity: 'puzzle',
      title: 'Puzzle',
      semanticTitle: 'Puzzle',
      tagline: 'Stück für Stück die Welt entdecken!',
      coverAsset: 'assets/lumo_design/spielwelt/portal_puzzle.png',
      kind: SpielweltTargetKind.nativeScene,
      target: 'puzzle',
      targetDescription: 'Godot Puzzle-Atelier (launch3D scene=puzzle)',
      gameId: GameId.puzzle,
    ),
    SpielweltRoute(
      identity: 'jumpRun',
      title: 'Jump & Run',
      semanticTitle: 'Lumo Lauf',
      tagline: 'Spring. Laufe. Sei mutig!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_jump.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'run',
      targetDescription: 'Godot Lumo Lauf (launch3D scene=run)',
      gameId: GameId.jumpRun,
    ),
    SpielweltRoute(
      identity: 'rhythm',
      title: 'Rhythm',
      semanticTitle: 'Rhythm Party',
      tagline: 'Fühl den Beat!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_rhythm.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'rhythm',
      targetDescription: 'Godot Rhythm Party (launch3D scene=rhythm)',
      gameId: GameId.rhythm,
    ),
    SpielweltRoute(
      identity: 'chess',
      title: 'Schach',
      semanticTitle: 'Lumo Schach',
      tagline: 'Schach lernen mit Lumo – oder gegen ihn spielen',
      coverAsset: 'assets/lumo_design/spielwelt/cover_chess.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'chess',
      targetDescription: 'Godot Lumo Schach (launch3D scene=chess)',
    ),
    SpielweltRoute(
      identity: 'skypost',
      title: 'Sternenpost',
      semanticTitle: 'Lumos Sternenpost',
      tagline: 'Fliegen, Briefe liefern, Rätsel lösen',
      coverAsset: 'assets/lumo_design/spielwelt/cover_skypost.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'skypost',
      targetDescription: 'Godot Lumos Sternenpost (launch3D scene=skypost)',
    ),
    SpielweltRoute(
      identity: 'stars',
      title: 'Sternenjagd',
      semanticTitle: 'Lumo Sternenjagd',
      tagline: 'Fange Sterne in drei Wellen und verbessere deine Bestzeit!',
      coverAsset: 'assets/lumo_design/icons/star_gold.png',
      kind: SpielweltTargetKind.nativeScene,
      target: 'stars',
      targetDescription: 'Godot Sternenjagd (launch3D scene=stars)',
    ),
    SpielweltRoute(
      identity: 'kart',
      title: 'Lumo Kart',
      semanticTitle: 'Lumo Kart',
      tagline: 'Fahre mit Lumo um die Wette!',
      coverAsset: 'assets/lumo_design/gameplay/kart_sonnenhafen_preview.webp',
      kind: SpielweltTargetKind.nativeScene,
      target: 'kart',
      targetDescription: 'Godot Lumo Kart (launch3D scene=kart)',
      gameId: GameId.kart,
    ),
    SpielweltRoute(
      identity: 'connectFour',
      title: '4 Gewinnt',
      semanticTitle: 'Lumo 4 Gewinnt',
      tagline: 'Vier in einer Reihe · gegen Lumo oder zu zweit',
      coverAsset: 'assets/lumo_design/spielwelt/cover_connect.jpg',
      kind: SpielweltTargetKind.flutterScreen,
      target: 'LumoConnectFourScreen',
      targetDescription: 'Flutter 4 Gewinnt',
    ),
    SpielweltRoute(
      identity: 'quizShow',
      title: 'Quizshow',
      semanticTitle: 'Wer wird Lumo-Meister?',
      tagline: '20 Fragen · 3 Joker · bis 5.000 Sterne',
      coverAsset: 'assets/lumo_design/spielwelt/cover_quiz.jpg',
      kind: SpielweltTargetKind.flutterScreen,
      target: 'QuizShowContent',
      targetDescription: 'Flutter Wer wird Lumo-Meister?',
    ),
  ];

  static const identities = [
    'world',
    'logic',
    'memory',
    'cards',
    'puzzle',
    'jumpRun',
    'rhythm',
    'chess',
    'skypost',
    'stars',
    'kart',
    'connectFour',
    'quizShow',
  ];

  static SpielweltRoute byIdentity(String identity) =>
      all.firstWhere((route) => route.identity == identity);

  static String coverFor(String identity) => byIdentity(identity).coverAsset;
}
