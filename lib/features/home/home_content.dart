import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../shared/widgets/lumo_living_world.dart';
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

  void _startPractice({
    required String subject,
    required String unit,
    required String message,
  }) {
    appState.update(appState.state.copyWith(
      subject: subject,
      unit: unit,
      mood: LumoMood.point,
      lumoMessage: message,
      sessionKind: LumoSessionKind.quickPractice,
    ));
    onSection(LumoSection.exercises);
  }

  @override
  Widget build(BuildContext context) {
    final childName = appState.state.childName.trim().isEmpty ? 'Lumo-Freund' : appState.state.childName.trim();
    // Lumo's lebendige Welt als Hintergrund: reagiert auf Tageszeit,
    // Jahreszeit und Lern-Fortschritt. Das, was diese App einzigartig macht.
    return LumoLivingWorld(
      starsEarned: appState.state.stars,
      child: LumoSubjectDashboard(
      appState: appState,
      subject: 'Hallo',
      subjectAccent: '$childName!',
      subtitle: 'Was möchtest du heute lernen?',
      greeting: 'Schön, dass du da bist!',
      lumoMessage: 'Heute warten\nspannende Aufgaben\nauf dich!',
      ctaLabel: 'Aufgabe starten',
      onCtaPressed: () => _startPractice(
        subject: 'Alle',
        unit: 'Alle',
        message: 'Ich suche dir\neine passende Aufgabe\naus.',
      ),
      headerAccent: LumoColors.orange,
      dailyMissionTitle: 'Tägliche Mission',
      dailyMissionSubtitle: 'Starte heute eine Lernrunde',
      dailyMissionDone: 1,
      dailyMissionTotal: 3,
      dailyMissionRewardStars: 10,
      dailyMissionRewardXp: 50,
      encourageMessage: 'Du machst großartige Fortschritte! Heute wartet eine neue Lernmission auf dich.',
      topicTiles: [
        LumoSubjectTile(
          title: 'Mathe mit Lumo',
          subtitle: 'Rechnen, Zählen und Knobeln',
          iconEmoji: 'M',
          illustrationEmoji: '+',
          accent: LumoColors.math,
          level: 3,
          starsCollected: 12,
          starsTotal: 20,
          onTap: () => _startPractice(
            subject: 'Mathematik',
            unit: 'Alle',
            message: 'Mathe startet.\nRuhig zählen,\ndann antworten.',
          ),
        ),
        LumoSubjectTile(
          title: 'Deutsch mit Lumo',
          subtitle: 'Lesen, Schreiben, Wörter entdecken',
          iconEmoji: 'D',
          illustrationEmoji: 'ABC',
          accent: LumoColors.purple,
          level: 2,
          starsCollected: 8,
          starsTotal: 20,
          onTap: () => onSection(LumoSection.learn),
        ),
        LumoSubjectTile(
          title: 'Lesen mit Lumo',
          subtitle: 'Spannende Geschichten vorlesen',
          iconEmoji: 'L',
          illustrationEmoji: 'Mic',
          accent: LumoColors.blue,
          level: 1,
          starsCollected: 3,
          starsTotal: 15,
          onTap: () {
            appState.update(appState.state.copyWith(
              subject: 'Lesen',
              unit: 'Aktives Lesen',
              mood: LumoMood.think,
              lumoMessage: 'Ich höre dir\nbeim Lesen zu.\nSatz für Satz.',
            ));
            onSection(LumoSection.reading);
          },
        ),
        LumoSubjectTile(
          title: 'Sachunterricht',
          subtitle: 'Tiere, Pflanzen und Wetter entdecken',
          iconEmoji: 'S',
          illustrationEmoji: 'Natur',
          accent: LumoColors.teal,
          level: 1,
          starsCollected: 2,
          starsTotal: 15,
          onTap: () => _startPractice(
            subject: 'Sachunterricht',
            unit: 'Tiere',
            message: 'Sachunterricht\nstartet jetzt.\nWir forschen zusammen.',
          ),
        ),
      ],
      ),
    );
  }
}
