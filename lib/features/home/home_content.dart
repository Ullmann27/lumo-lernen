import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../shared/widgets/lumo_subject_dashboard.dart';
import '../shared/widgets/lumo_subject_tile.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.appState,
    required this.onSection,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  Widget build(BuildContext context) {
    final childName = appState.state.childName.trim().isEmpty ? 'Lumo-Freund' : appState.state.childName.trim();
    return LumoSubjectDashboard(
      appState: appState,
      subject: 'Hallo',
      subjectAccent: '$childName!',
      subtitle: 'Was moechtest du heute lernen?',
      greeting: 'Schoen, dass du da bist!',
      lumoMessage: 'Heute warten\nspannende Aufgaben\nauf dich!',
      ctaLabel: 'Aufgabe starten',
      onCtaPressed: () => onSection(LumoSection.exercises),
      headerAccent: LumoColors.orange,
      dailyMissionTitle: 'Taegliche Mission',
      dailyMissionSubtitle: 'Starte heute eine Lernrunde',
      dailyMissionDone: 1,
      dailyMissionTotal: 3,
      dailyMissionRewardStars: 10,
      dailyMissionRewardXp: 50,
      encourageMessage: 'Du machst grossartige Fortschritte! 🌟\nHeute wartet eine neue Lernmission auf dich.',
      topicTiles: [
        LumoSubjectTile(
          title: 'Mathe mit Lumo',
          subtitle: 'Rechnen, Zaehlen und Knobeln',
          iconEmoji: '🧮',
          illustrationEmoji: '➕',
          accent: LumoColors.math,
          level: 3,
          starsCollected: 12,
          starsTotal: 20,
          onTap: () => onSection(LumoSection.exercises),
        ),
        LumoSubjectTile(
          title: 'Deutsch mit Lumo',
          subtitle: 'Lesen, Schreiben, Woerter entdecken',
          iconEmoji: '📖',
          illustrationEmoji: '🔤',
          accent: LumoColors.purple,
          level: 2,
          starsCollected: 8,
          starsTotal: 20,
          onTap: () => onSection(LumoSection.learn),
        ),
        LumoSubjectTile(
          title: 'Lesen mit Lumo',
          subtitle: 'Spannende Geschichten vorlesen',
          iconEmoji: '📚',
          illustrationEmoji: '🎙️',
          accent: LumoColors.blue,
          level: 1,
          starsCollected: 3,
          starsTotal: 15,
          onTap: () => onSection(LumoSection.reading),
        ),
        LumoSubjectTile(
          title: 'Sachunterricht',
          subtitle: 'Tiere, Pflanzen und Wetter entdecken',
          iconEmoji: '🌱',
          illustrationEmoji: '🦋',
          accent: LumoColors.teal,
          level: 1,
          starsCollected: 2,
          starsTotal: 15,
          onTap: () {
            appState.update(appState.state.copyWith(
              subject: 'Sachkunde',
              unit: 'Tiere und Pflanzen',
              sessionKind: LumoSessionKind.quickPractice,
            ));
            onSection(LumoSection.exercises);
          },
        ),
      ],
    );
  }
}
