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
import '../../widgets/design/lumo_design_system.dart';
import 'lumo_story_reader_screen.dart';

class LumoQuestHubScreen extends StatelessWidget {
  const LumoQuestHubScreen({super.key, required this.appState});

  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    final grade = appState.state.grade.clamp(1, 4).toInt();
    final quests = LumoQuestLibrary.forGrade(grade);
    final inGrade = quests.where((q) => q.gradeLevel == grade).toList();
    // Some grades have no own-grade adventure yet. Never present an empty hub
    // when the library already has age-nearby stories.
    final primaryQuests = inGrade.isEmpty ? quests : inGrade;
    return Scaffold(
      backgroundColor: const Color(0xFF102841),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102841),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD873)),
          SizedBox(width: 8),
          Expanded(child: Text('Lumo Quest',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Nunito', fontSize: 22,
                fontWeight: FontWeight.w900, color: Colors.white),
          )),
        ]),
      ),
      extendBodyBehindAppBar: false,
      body: LumoSceneBackground(
        scene: LumoScene.library,
        dimmed: true,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            key: const ValueKey('quest-compact-progress'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xF0183656),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF67D9E5).withOpacity(.5)),
            ),
            child: Row(children: [
              const Icon(Icons.auto_stories_rounded,
                  color: Color(0xFF67D9E5), size: 27),
              const SizedBox(width: 10),
              Expanded(child: Text('Lernabenteuer · $grade. Klasse',
                style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
                  fontSize: 16, fontWeight: FontWeight.w900))),
              const Icon(Icons.star_rounded, color: Color(0xFFFFCB62), size: 21),
              const SizedBox(width: 4),
              Text('${appState.state.stars}',
                style: const TextStyle(color: Colors.white,
                  fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 8),
          _intro(grade),
          const SizedBox(height: 16),
          for (final q in primaryQuests) ...[
            _QuestCard(quest: q, appState: appState),
            const SizedBox(height: 12),
          ],
          if (inGrade.isNotEmpty && quests.any((quest) => quest.gradeLevel != grade))
            Card(
              color: const Color(0xF0183656),
              child: ExpansionTile(
                key: const PageStorageKey<String>('quest-other-grades'),
                title: const Text('Abenteuer anderer Klassen',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900, color: Colors.white)),
                subtitle: const Text('Weitere Geschichten freiwillig öffnen',
                  style: TextStyle(color: Color(0xFFD4EAF5))),
                leading: const Icon(Icons.library_books_rounded,
                    color: Color(0xFF67D9E5)),
                children: [
                  for (final q in quests.where((quest) => quest.gradeLevel != grade))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                      child: _QuestCard(quest: q, appState: appState),
                    ),
                ],
              ),
            ),
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
          colors: [Color(0xFF234C76), Color(0xFF974A92)],
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
          const LumoFoxPose(pose: LumoDesignFoxPose.spielweltWave, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dein nächstes Abenteuer',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Geschichten lesen, Aufgaben lösen und den nächsten Abschnitt entdecken.',
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
        color: const Color(0xFF103151),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: LumoColors.orange.withOpacity(0.30)),
      ),
      child: const Text(
        'Fuer deine Klasse gibt es noch keine Quests.\nFrag Lumo nochmal in ein paar Wochen!',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
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
        key: ValueKey('quest-start-${quest.id}'),
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
            color: const Color(0xF0153353),
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
                child: const LumoFoxPose(pose: LumoDesignFoxPose.bookPoint, size: 62),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                        Text(
                          '$exerciseCount Aufgaben',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
                        color: Colors.white,
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
                        color: Color(0xFFD4EAF5),
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
                                color: const Color(0xFF274967),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                k,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDBEBFA),
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
