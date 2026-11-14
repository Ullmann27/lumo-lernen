import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../lumo3d/native_game_saves_screen.dart';

/// This optional entry belongs only to the existing adult settings area.
class NativeGameSavesCard extends StatelessWidget {
  const NativeGameSavesCard({
    super.key,
    required this.appState,
    this.refreshRevision = 0,
  });
  final LumoAppState appState;
  final int refreshRevision;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: LumoGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('3D-Spielstände',
                  style: TextStyle(
                      color: LumoVisualTokens.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Jedes Kinderprofil hat seinen eigenen Spielstand. '
                'Ältere Stände können Erwachsene hier getrennt zuordnen und öffnen.',
                style: TextStyle(color: LumoVisualTokens.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('native-game-saves-open'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          NativeGameSavesScreen(appState: appState)),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Spielstände verwalten'),
              ),
            ],
          ),
        ),
      );
}
