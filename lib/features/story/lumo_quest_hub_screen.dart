// ════════════════════════════════════════════════════════════════════════
// LUMO QUEST HUB — Auswahl der narrativen Lehrplan-Abenteuer.
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-06-03: "echtes neues Level gegenueber LernMax". Statt trockenem
// Drill bekommt das Kind Mini-Abenteuer mit eingebetteten Aufgaben:
// "Lumo's Apfelgarten", "Lumo's Schatzhoehle", ...
//
// Jeder Quest ist ein LumoStory-Objekt aus lumo_quest_library.dart. Tap auf
// eine Quest-Karte oeffnet den bestehenden LumoStoryReaderScreen direkt.
// Filter: Quests passend zur Klassenstufe des Kindes (+/- 1 Klasse).

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_quest_library.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../../widgets/premium/lumo_stage_header.dart';
import 'lumo_story_reader_screen.dart';

class LumoQuestHubScreen extends StatelessWidget {
  const LumoQuestHubScreen({super.key, required this.appState});

  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    final grade = appState.state.grade.clamp(1, 4).toInt();
    final quests = LumoQuestLibrary.forGrade(grade);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF7C2D12)),
        title: const Text(
          '🦊 Lumo Quest',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C2D12),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LumoMagicBackground(
        intensity: 1.1,
        starCount: 26,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // 2026-06-05 Iter 17/A4: LumoStageHeader prominent oben mit
          // Level + Sterne + Streak. Bisher nur Showcase, jetzt aktiv.
          LumoStageHeader(
            greeting: 'Hallo ${appState.state.childName.isEmpty ? "Held" : appState.state.childName}!',
            subtitle: 'Welche Quest startest du heute?',
            stars: appState.state.stars,
            xp: appState.state.xp,
            level: appState.state.level,
            streak: appState.learningStreakDays(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
          ),
          const SizedBox(height: 8),
          _intro(grade),
          const SizedBox(height: 16),
          for (final q in quests) ...[
            _QuestCard(quest: q, appState: appState),
            const SizedBox(height: 12),
          ],
          if (quests.isEmpty) _noQuestsForGrade(),
        ],
      ), // close ListView
      ), // close LumoMagicBackground
    );
  }

  Widget _intro(int grade) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🦊', style: TextStyle(fontSize: 42)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Komm mit auf Abenteuer!',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klasse $grade - jede Geschichte hat kleine Aufgaben.\nLoese sie und Lumo erzaehlt weiter.',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noQuestsForGrade() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: LumoColors.orange.withOpacity(0.30)),
      ),
      child: const Text(
        'Fuer deine Klasse gibt es noch keine Quests.\nFrag Lumo nochmal in ein paar Wochen!',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7C2D12),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.appState});

  final LumoQuest quest;
  final LumoAppState appState;

  static const _gradeAccents = <int, Color>{
    1: Color(0xFFFCA5A5),
    2: Color(0xFFFCD34D),
    3: Color(0xFF60A5FA),
    4: Color(0xFFA855F7),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _gradeAccents[quest.gradeLevel] ?? LumoColors.orange;
    final exerciseCount = quest.story.pages.where((p) => p.exercise != null).length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LumoStoryReaderScreen(
                story: quest.story,
                appState: appState,
                storyId: quest.id,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            border: Border.all(color: accent.withOpacity(0.50), width: 1.6),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(LumoRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(quest.emoji, style: const TextStyle(fontSize: 38)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(LumoRadius.pill),
                          ),
                          child: Text(
                            'Klasse ${quest.gradeLevel}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$exerciseCount Aufgaben',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C2D12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      quest.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7C2D12),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quest.summary,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                    if (quest.story.keyPoints.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final k in quest.story.keyPoints)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                k,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.play_circle_filled_rounded, color: accent, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}
