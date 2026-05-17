import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../domain/games/game_level_model.dart';

class LumoJumpAdventureGame extends StatelessWidget {
  const LumoJumpAdventureGame({
    super.key,
    required this.appState,
    required this.level,
  });

  final LumoAppState appState;
  final GameLevel level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lumo Jump: ${level.title}'),
      ),
      body: const Center(
        child: Text('Lumo Jump Prototype'),
      ),
    );
  }
}
