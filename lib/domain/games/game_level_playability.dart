import 'game_level_model.dart';

enum GamePlayRoute {
  starsPath,
  numberHouse,
}

abstract class GameLevelPlayability {
  GameLevelPlayability._();

  static GamePlayRoute routeFor(GameLevel level) {
    switch (level.miniType) {
      case GameMiniType.numberHouse:
        return GamePlayRoute.numberHouse;
      case GameMiniType.starsPath:
      case GameMiniType.numberPath:
      case GameMiniType.wordForest:
      case GameMiniType.mixedQuiz:
        return GamePlayRoute.starsPath;
    }
  }

  static bool usesFallback(GameLevel level) =>
      level.miniType != GameMiniType.starsPath &&
      level.miniType != GameMiniType.numberHouse;
}
