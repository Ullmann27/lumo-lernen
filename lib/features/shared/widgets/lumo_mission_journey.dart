import 'package:flutter/material.dart';
import '../../../app/app_state.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';

/// Real, persisted station progress. No sample rewards or invented duration.
class LumoMissionJourney extends StatelessWidget {
  const LumoMissionJourney(
      {super.key,
      required this.appState,
      required this.onSubject,
      this.onGames});
  final LumoAppState appState;
  final ValueChanged<String> onSubject;
  final VoidCallback? onGames;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final mission = appState.dailyMission;
        final error = appState.dailyMissionError;
        final ready = mission?.isComplete == true &&
            error == null &&
            mission?.clockUncertain == false;
        final reduced = appState.state.settings.reduceAnimations ||
            appState.state.settings.calmMode ||
            MediaQuery.disableAnimationsOf(context);
        return LumoGlassCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(children: [
                const Image(
                    image: AssetImage(
                        'assets/lumo_design/characters/fox_point.webp'),
                    width: 54,
                    height: 64,
                    fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          ready
                              ? 'Dein Spielwelt-Schlüssel ist bereit'
                              : 'Deine Tagesmission',
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const Text(
                          'Drei Stationen. Pausen und Hilfen gehören dazu.',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              color: LumoVisualTokens.muted)),
                    ])),
              ]),
              if (mission == null && error == null)
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator())
              else if (mission != null) ...[
                const SizedBox(height: 10),
                for (var i = 0; i < mission.stations.length; i++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                          color: const Color(0xFF132F50),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            key: ValueKey(
                                'mission-station-${mission.stations[i].subject}'),
                            minVerticalPadding: 10,
                            leading: Icon(
                                mission.stations[i].isComplete
                                    ? Icons.check_circle_rounded
                                    : Icons.diamond_outlined,
                                color: mission.stations[i].isComplete
                                    ? LumoVisualTokens.gold
                                    : LumoVisualTokens.cyanBright),
                            title: Text(mission.stations[i].subject,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            subtitle: Text(
                                '${mission.stations[i].completed} von ${mission.stations[i].target} Aufgaben gelöst',
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    color: LumoVisualTokens.muted)),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: LumoVisualTokens.cyanBright),
                            onTap: () => onSubject(mission.stations[i].subject),
                          ))),
                TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0,
                        end: mission.completedCount / mission.targetCount),
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 450),
                    builder: (_, value, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            color: ready
                                ? LumoVisualTokens.gold
                                : LumoVisualTokens.cyanBright,
                            backgroundColor: Colors.white.withOpacity(.1)))),
                const SizedBox(height: 8),
                Text(
                    '${mission.completedCount} von ${mission.targetCount} · Dein Fortschritt wird gespeichert.',
                    key: const ValueKey('home-mission-progress'),
                    style: const TextStyle(
                        fontFamily: 'Nunito', color: LumoVisualTokens.muted)),
              ],
              if (error != null || mission?.clockUncertain == true) ...[
                const SizedBox(height: 10),
                Text(
                    error ??
                        'Die Gerätezeit wurde zurückgestellt. Dein gespeicherter Fortschritt bleibt erhalten.',
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Nunito')),
                TextButton(
                    onPressed: appState.loadDailyMission,
                    child: const Text('Erneut prüfen')),
              ],
              if (ready && onGames != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                    key: const ValueKey('mission-game-access'),
                    onPressed: onGames,
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: const Text('Zur Spielewelt'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52))),
              ],
            ]));
      });
}
