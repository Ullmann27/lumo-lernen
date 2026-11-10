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

/// Layout breakpoint for the page-34 reference hub.
///
/// Fold7 open (690×829 logical in this app), tablets and phone landscape
/// must use the reference composition. Only true phone / cover-screen
/// widths fall back to the compact grid.
class SpielweltLayout {
  static const double referenceMinWidth = 600;

  static bool useReferenceHub(double width, [double height = 0]) =>
      width >= referenceMinWidth;

  static bool isPortraitReference(double width, double height) =>
      useReferenceHub(width) && height > width * 1.05;
}

/// Canonical ten-game Spielwelt. Order is the phone-grid hierarchy and
/// matches Heinz's 2013 list.
class SpielweltRoutes {
  SpielweltRoutes._();

  static const List<SpielweltRoute> all = [
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
      semanticTitle: 'Lumo Cards',
      tagline: 'Sammeln. Spielen. Staunen!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_cards.jpg',
      kind: SpielweltTargetKind.flutterScreen,
      target: 'LumoCardsShowcaseScreen',
      targetDescription: 'Flutter Lumo Cards (nie Sternenpfad)',
      gameId: GameId.cards,
    ),
    SpielweltRoute(
      identity: 'puzzle',
      title: 'Puzzle',
      semanticTitle: 'Puzzle',
      tagline: 'Stück für Stück die Welt entdecken!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_puzzle.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'puzzle',
      targetDescription: 'Godot Puzzle-Atelier (launch3D scene=puzzle)',
      gameId: GameId.puzzle,
    ),
    SpielweltRoute(
      identity: 'jumpRun',
      title: 'Jump & Run',
      semanticTitle: 'Jump & Run',
      tagline: 'Spring. Laufe. Sei mutig!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_jump.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'jump',
      targetDescription: 'Godot Wolkeninseln (launch3D scene=jump)',
      gameId: GameId.jumpRun,
    ),
    SpielweltRoute(
      identity: 'rhythm',
      title: 'Rhythm Party',
      semanticTitle: 'Rhythm Party',
      tagline: 'Fühl den Beat!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_rhythm.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'rhythm',
      targetDescription: 'Godot Rhythm Party (launch3D scene=rhythm)',
      gameId: GameId.rhythm,
    ),
    SpielweltRoute(
      identity: 'treasure',
      title: 'Schatzsuche',
      semanticTitle: 'Schatzsuche',
      tagline: 'Rätsel. Hinweise. Schätze!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_treasure.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'treasure',
      targetDescription: 'Godot Schatzsuche (launch3D scene=treasure)',
      gameId: GameId.treasure,
    ),
    SpielweltRoute(
      identity: 'build',
      title: 'Bauwelt',
      semanticTitle: 'Bauwelt',
      tagline: 'Bauen. Gestalten. Deiner Fantasie sind keine Grenzen gesetzt!',
      coverAsset: 'assets/lumo_design/spielwelt/cover_build.jpg',
      kind: SpielweltTargetKind.nativeScene,
      target: 'build',
      targetDescription: 'Godot Bauwelt (launch3D scene=build)',
      gameId: GameId.build,
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
      coverAsset: '',
      kind: SpielweltTargetKind.flutterScreen,
      target: 'LumoConnectFourScreen',
      targetDescription: 'Flutter 4 Gewinnt',
    ),
    SpielweltRoute(
      identity: 'quizShow',
      title: 'Wer wird Lumo-Meister?',
      semanticTitle: 'Wer wird Lumo-Meister?',
      tagline: '20 Fragen · 3 Joker · bis 5.000 Sterne',
      coverAsset: 'assets/lumo_design/fox/fox_quiz_host_1982.webp',
      kind: SpielweltTargetKind.flutterScreen,
      target: 'QuizShowContent',
      targetDescription: 'Flutter Wer wird Lumo-Meister?',
    ),
  ];

  static const identities = [
    'memory',
    'cards',
    'puzzle',
    'jumpRun',
    'rhythm',
    'treasure',
    'build',
    'kart',
    'connectFour',
    'quizShow',
  ];

  static SpielweltRoute byIdentity(String identity) =>
      all.firstWhere((route) => route.identity == identity);

  static String coverFor(String identity) {
    // Connect Four uses a painted 7×6 board, not another game's bitmap.
    if (identity == 'connectFour') return '';
    return byIdentity(identity).coverAsset;
  }
}
