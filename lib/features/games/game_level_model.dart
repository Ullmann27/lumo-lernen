class GameLevelModel {
  const GameLevelModel(
    this.number,
    this.title,
    this.subtitle, {
    required this.unlocked,
    required this.stars,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool unlocked;
  final int stars;
}

const int kMinimumStarsForProgress = 2;

const List<GameLevelModel> kInitialGameLevels = <GameLevelModel>[
  GameLevelModel(1, 'Sterne sammeln', 'Mengen bis 10', unlocked: true, stars: 3),
  GameLevelModel(2, 'Sterne sammeln', 'Plus bis 10', unlocked: true, stars: 2),
  GameLevelModel(3, 'Rechenhaus bauen', 'Zahlzerlegung', unlocked: true, stars: 1),
  GameLevelModel(4, 'Zahlenweg', 'Zahlenfolge', unlocked: true, stars: 0),
  GameLevelModel(5, 'Zahlenweg', 'Plus-Schritte', unlocked: true, stars: 0),
  GameLevelModel(6, 'Wörterwald', 'Silben erkennen', unlocked: false, stars: 0),
  GameLevelModel(7, 'Wörterwald', 'Wort-Bild', unlocked: false, stars: 0),
  GameLevelModel(8, 'Rechenhaus bauen', 'Fehlende Zahl', unlocked: false, stars: 0),
  GameLevelModel(9, 'Sterne sammeln', 'Minus bis 10', unlocked: false, stars: 0),
  GameLevelModel(10, 'Lumo-Challenge', 'Gemischt', unlocked: false, stars: 0),
];
