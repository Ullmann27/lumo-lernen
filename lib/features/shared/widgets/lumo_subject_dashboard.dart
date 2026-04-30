import 'package:flutter/material.dart';
import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import 'lumo_big_cta_button.dart';
import 'lumo_daily_mission_card.dart';
import 'lumo_encourage_card.dart';
import 'lumo_hero_header.dart';
import 'lumo_level_strip.dart';
import 'lumo_subject_tile.dart';

/// Premium-Fach-Dashboard nach Referenzbild "Deutsch mit Lumo".
///
/// Komponiert Hero-Header, Level-Streifen, Tagesmission, grossen CTA-Button,
/// Themenkarten-Grid und Motivations-Karte zu einer kompletten scrollbaren
/// Lernseite.
class LumoSubjectDashboard extends StatelessWidget {
  const LumoSubjectDashboard({
    super.key,
    required this.appState,
    required this.subject,
    required this.subjectAccent,
    required this.subtitle,
    required this.greeting,
    required this.lumoMessage,
    required this.ctaLabel,
    required this.onCtaPressed,
    required this.topicTiles,
    this.dailyMissionTitle = 'Tägliche Mission',
    this.dailyMissionSubtitle = '3 Aufgaben abschließen',
    this.dailyMissionDone = 2,
    this.dailyMissionTotal = 3,
    this.dailyMissionRewardStars = 10,
    this.dailyMissionRewardXp = 50,
    this.encourageMessage = 'Du machst großartige Fortschritte! 🌟\nMorgen wartet eine neue Mission auf dich.',
    this.headerAccent = LumoColors.orange,
  });

  final LumoAppState appState;
  final String subject;
  final String subjectAccent;
  final String subtitle;
  final String greeting;
  final String lumoMessage;
  final String ctaLabel;
  final VoidCallback onCtaPressed;
  final List<LumoSubjectTile> topicTiles;
  final String dailyMissionTitle;
  final String dailyMissionSubtitle;
  final int dailyMissionDone;
  final int dailyMissionTotal;
  final int dailyMissionRewardStars;
  final int dailyMissionRewardXp;
  final String encourageMessage;
  final Color headerAccent;

  @override
  Widget build(BuildContext context) {
    final st = appState.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final tileColumns = availableWidth < 560 ? 1 : 2;

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            LumoHeroHeader(
              childName: st.childName,
              title: subject,
              titleAccent: subjectAccent,
              subtitle: subtitle,
              greeting: greeting,
              lumoMessage: lumoMessage,
              stars: st.stars,
              streakDays: 7,
              accent: headerAccent,
            ),
            const SizedBox(height: 12),
            LumoLevelStrip(
              level: st.level,
              currentXp: st.xp % 1200,
              xpForNextLevel: 1200,
              accent: headerAccent,
            ),
            const SizedBox(height: 10),
            LumoDailyMissionCard(
              title: dailyMissionTitle,
              subtitle: dailyMissionSubtitle,
              progressDone: dailyMissionDone,
              progressTotal: dailyMissionTotal,
              rewardStars: dailyMissionRewardStars,
              rewardXp: dailyMissionRewardXp,
              accent: headerAccent,
            ),
            const SizedBox(height: 16),
            LumoBigCtaButton(
              label: ctaLabel,
              onPressed: onCtaPressed,
              color: headerAccent,
            ),
            const SizedBox(height: 18),
            _TileGrid(tiles: topicTiles, columns: tileColumns),
            const SizedBox(height: 14),
            LumoEncourageCard(
              childName: st.childName,
              message: encourageMessage,
              accent: headerAccent,
            ),
          ],
        );
      },
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.columns});
  final List<LumoSubjectTile> tiles;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: tiles
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: t,
                ))
            .toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      final left = tiles[i];
      final right = (i + 1 < tiles.length) ? tiles[i + 1] : null;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right ?? const SizedBox.shrink()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}
