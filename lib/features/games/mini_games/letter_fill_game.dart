import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../domain/games/game_level_model.dart';
import 'mini_game_learning_screen.dart';

/// Existing catalog route. The shared task owner preserves this level's
/// generator, durable identifiers and reward formula across pause and resume.
class LetterFillGame extends StatelessWidget {
  const LetterFillGame(
      {super.key, required this.appState, required this.level});

  final LumoAppState appState;
  final GameLevel level;

  @override
  Widget build(BuildContext context) =>
      MiniGameLearningScreen(appState: appState, level: level);
}
