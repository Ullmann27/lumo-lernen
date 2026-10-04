import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../journal/lumo_journal_screen.dart';
import '../learning/lumo_abc_tafel_screen.dart';
import '../learning/lumo_rechentricks_poster_screen.dart';
import '../live/lumo_live_pro_screen.dart';
import '../lumo_welt/lumo_welt_screen.dart';
import '../magic_hub/lumo_magic_hub_screen.dart';
import '../photo_lesson/lumo_photo_lesson_screen.dart';
import '../quiz/quiz_show_content.dart';
import '../reading/lumo_reading_buddy_screen.dart';
import '../rewards/achievements_wall_screen.dart';
import '../story/lumo_quest_hub_screen.dart';

/// The two main routes stay visible before progress and optional activities.
/// Every progress value comes from the current profile or persisted wallet.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.appState,
    required this.onSection,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  void _startPractice(String subject, {String? unit}) {
    final lastUnit = appState.learningProfile.lastTopics[subject];
    appState.update(appState.state.copyWith(
      subject: subject,
      unit: unit ?? lastUnit ?? 'Alle',
      mood: LumoMood.point,
      lumoMessage: 'Wir üben $subject. Ich helfe dir Schritt für Schritt.',
      sessionKind: LumoSessionKind.quickPractice,
    ));
    onSection(LumoSection.exercises);
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _startReading() {
    appState.update(appState.state.copyWith(
      subject: 'Lesen',
      unit: 'Aktives Lesen',
      mood: LumoMood.think,
      lumoMessage: 'Wir lesen gemeinsam, Satz für Satz.',
    ));
    onSection(LumoSection.reading);
  }

  int _correctFor(String subject) => appState
      .learningSkills()
      .values
      .where((record) => record.subject == subject)
      .fold(0, (total, record) => total + record.correct);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final state = appState.state;
          final name = state.childName.trim().isEmpty
              ? 'Lumo-Freund'
              : state.childName.trim();
          final recommendation = appState.topLearningRecommendation();
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final columns = wide ? 4 : 2;
              final actions = <Widget>[
                LumoColorTile(
                  key: const ValueKey('home-learn'),
                  title: 'Lernen',
                  subtitle: 'Deine Fächer und Aufgaben',
                  icon: Icons.menu_book_rounded,
                  color: LumoVisualTokens.learning,
                  onTap: () => onSection(LumoSection.learn),
                ),
                LumoColorTile(
                  key: const ValueKey('home-games'),
                  title: 'Spielen',
                  subtitle: 'Lumo Kart, Memory und mehr',
                  icon: Icons.sports_esports_rounded,
                  color: LumoVisualTokens.games,
                  onTap: () => onSection(LumoSection.games),
                ),
                LumoColorTile(
                  title: 'Tests',
                  subtitle: 'Wissen überprüfen',
                  icon: Icons.assignment_rounded,
                  color: LumoVisualTokens.tests,
                  onTap: () => onSection(LumoSection.tests),
                ),
                LumoColorTile(
                  title: 'Belohnungen',
                  subtitle: 'Sterne und Extras',
                  icon: Icons.star_rounded,
                  color: LumoVisualTokens.rewards,
                  onTap: () => onSection(LumoSection.rewards),
                ),
              ];
              return LumoSceneBackground(
                scene: LumoScene.home,
                backgroundAsset: 'assets/lumo_design/bg/bg_home.png',
                child: ListView(
                  key: const PageStorageKey('lumo-home-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hallo, $name!',
                                key: const ValueKey('home-greeting'),
                                style: LumoTextStyles.heading2.copyWith(
                                  color: LumoVisualTokens.white,
                                ),
                              ),
                              Text(
                                'Dein Lumo-Tag · ${state.grade}. Klasse',
                                style: LumoTextStyles.body.copyWith(
                                  color: LumoVisualTokens.muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const LumoSpeechBubble(
                                text: 'Bereit für ein neues Abenteuer?',
                              ),
                            ],
                          ),
                        ),
                        LumoFoxPose(
                          pose: LumoDesignFoxPose.kartWave,
                          size: wide ? 178 : 112,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('home-kart-banner'),
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => onSection(LumoSection.games),
                        child: LumoGlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sports_motorsports_rounded,
                                color: LumoVisualTokens.cyanBright,
                                size: 38,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lumo Kart',
                                      style: LumoTextStyles.heading2.copyWith(
                                        color: LumoVisualTokens.white,
                                      ),
                                    ),
                                    Text(
                                      'Lernen auf der Überholspur!',
                                      style: LumoTextStyles.body.copyWith(
                                        color: LumoVisualTokens.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: LumoVisualTokens.cyanBright),
                              const SizedBox(width: 8),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: LumoVisualTokens.cyan,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Text(
                                    'Neu!',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w900,
                                      color: LumoVisualTokens.night,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: wide ? 1.02 : .84,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: actions,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('home-explanation'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: LumoVisualTokens.cyanBright,
                        ),
                        onPressed: () => LumoCompanionRequests.instance
                            .requestAppExplanation(),
                        icon: const Icon(Icons.waving_hand_rounded, size: 20),
                        label: const Text("Lumo zeigt's dir"),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ProgressCard(appState: appState),
                    const SizedBox(height: 12),
                    LumoGlassCard(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: LumoSpeechBubble(
                              text: 'Du kannst das!',
                              handwritten: true,
                            ),
                          ),
                          LumoFoxPose(
                            pose: LumoDesignFoxPose.thumbWink,
                            size: wide ? 112 : 78,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Das passt heute zu dir',
                      style: LumoTextStyles.heading3.copyWith(
                        color: LumoVisualTokens.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RecommendationCard(
                      message: recommendation?.message ??
                          'Wähle ein Fach. Wir starten mit kleinen Schritten.',
                      label: recommendation?.cta ?? 'Kurze Lernrunde',
                      onTap: () => _startPractice(
                        recommendation?.subject ?? 'Mathematik',
                        unit: recommendation?.unit,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Deine Lernfächer',
                      style: LumoTextStyles.heading3.copyWith(
                        color: LumoVisualTokens.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ResponsiveCards(
                      columns: wide ? 2 : 1,
                      children: [
                        _SubjectCard(
                          subject: 'Mathematik',
                          subtitle: 'Zahlen, Rechnen und Formen',
                          icon: Icons.calculate_rounded,
                          color: const Color(0xFF93540C),
                          completed: _correctFor('Mathematik'),
                          onTap: () => _startPractice('Mathematik'),
                        ),
                        _SubjectCard(
                          subject: 'Deutsch',
                          subtitle: 'Buchstaben, Wörter und Sätze',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFF6D43AC),
                          completed: _correctFor('Deutsch'),
                          onTap: () => _startPractice('Deutsch'),
                        ),
                        _SubjectCard(
                          subject: 'Sachunterricht',
                          subtitle: 'Deine Welt entdecken',
                          icon: Icons.public_rounded,
                          color: const Color(0xFF087A6A),
                          completed: _correctFor('Sachunterricht'),
                          onTap: () => _startPractice('Sachunterricht'),
                        ),
                        _SubjectCard(
                          subject: 'Logik',
                          subtitle: 'Muster und knifflige Rätsel',
                          icon: Icons.extension_rounded,
                          color: const Color(0xFF326EAC),
                          completed: _correctFor('Logik'),
                          onTap: () => _startPractice('Logik'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      color: LumoVisualTokens.glass,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: BorderSide(
                          color: LumoVisualTokens.cyan.withOpacity(.4),
                        ),
                      ),
                      child: ExpansionTile(
                        key: const PageStorageKey('home-discover'),
                        title: Text(
                          'Mehr mit Lumo entdecken',
                          style: LumoTextStyles.heading3.copyWith(
                            color: LumoVisualTokens.white,
                          ),
                        ),
                        subtitle:
                            Text('Lesen, Abenteuer und deine Sammlung',
                                style: LumoTextStyles.body
                                    .copyWith(color: LumoVisualTokens.muted)),
                        leading: const Icon(Icons.explore_rounded,
                            color: LumoVisualTokens.cyan),
                        children: [
                          _extra('Lesen mit Lumo', 'Geschichten Satz für Satz',
                              Icons.menu_book_rounded, _startReading),
                          _extra(
                              'Quizshow',
                              'Fragen mit Jokern beantworten',
                              Icons.quiz_rounded,
                              () => _open(
                                  context, QuizShowContent(appState: appState))),
                          _extra(
                              'Lumo Kart',
                              'In der Spieleauswahl starten',
                              Icons.sports_motorsports_rounded,
                              () => onSection(LumoSection.games)),
                          _extra(
                              'ABC-Tafel',
                              'Buchstaben anhören und entdecken',
                              Icons.abc_rounded,
                              () => _open(context, const LumoAbcTafelScreen())),
                          _extra(
                              'Meine Rechentricks',
                              'Schlaue Wege beim Rechnen',
                              Icons.lightbulb_rounded,
                              () => _open(context,
                                  const LumoRechentricksPosterScreen())),
                          _extra(
                              'Meine Erfolge',
                              'Deine gesammelten Abzeichen',
                              Icons.emoji_events_rounded,
                              () => _open(context,
                                  AchievementsWallScreen(appState: appState))),
                          _extra(
                              'Lumo LIVE',
                              'Sprache und Foto-Hilfe',
                              Icons.mic_rounded,
                              () => _open(context,
                                  LumoLiveProScreen(appState: appState))),
                          _extra(
                              'Lumo Journal',
                              'Dein eigenes Tagebuch',
                              Icons.edit_note_rounded,
                              () => _open(context,
                                  LumoJournalScreen(appState: appState))),
                          _extra(
                              'Meine Welt',
                              'Deine Inseln wachsen beim Lernen',
                              Icons.landscape_rounded,
                              () => _open(
                                  context, LumoWeltScreen(appState: appState))),
                          _extra(
                              'Foto-Lektion',
                              'Übungen zu deinem Heft',
                              Icons.photo_camera_rounded,
                              () => _open(context,
                                  LumoPhotoLessonScreen(appState: appState))),
                          _extra(
                              'Laut lesen',
                              'Lumo hört dir auf Wunsch zu',
                              Icons.record_voice_over_rounded,
                              () => _open(context,
                                  LumoReadingBuddyScreen(appState: appState))),
                          _extra(
                              'Lumo Quest',
                              'Kleine Lernabenteuer',
                              Icons.auto_awesome_rounded,
                              () => _open(context,
                                  LumoQuestHubScreen(appState: appState))),
                          _extra(
                              'Lumo Zauberwelt',
                              'Geschichten und weitere Ideen',
                              Icons.auto_fix_high_rounded,
                              () => _open(context,
                                  LumoMagicHubScreen(appState: appState))),
                          _extra(
                              'Lumo 3D Welt',
                              'Deine Spiele in einer App',
                              Icons.view_in_ar_rounded,
                              () => onSection(LumoSection.games)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

  Widget _extra(
          String title, String subtitle, IconData icon, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: LumoVisualTokens.cyan),
        title: Text(title, style: const TextStyle(color: LumoVisualTokens.white)),
        subtitle:
            Text(subtitle, style: const TextStyle(color: LumoVisualTokens.muted)),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: LumoVisualTokens.cyan),
        onTap: onTap,
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    final state = appState.state;
    final dailyDone = appState.learningDailyDone();
    final dailyGoal = state.settings.dailyGoal.clamp(1, 500);
    return LumoGlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Tägliche Aufgaben',
          style: LumoTextStyles.heading3.copyWith(
            color: LumoVisualTokens.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 10, children: [
          _stat(Icons.star_rounded, '${state.stars} Sterne',
              LumoVisualTokens.gold),
          _stat(Icons.workspace_premium_rounded, 'Level ${state.level}',
              LumoVisualTokens.cyanBright),
          _stat(
              Icons.local_fire_department_rounded,
              '${appState.learningStreakDays()} ${appState.learningStreakDays() == 1 ? 'Lerntag' : 'Lerntage'} in Folge',
              LumoVisualTokens.rewards),
        ]),
        const SizedBox(height: 16),
        Text('Heute: $dailyDone von $dailyGoal Aufgaben',
            key: const ValueKey('home-daily-progress'),
            style:
                LumoTextStyles.body.copyWith(color: LumoVisualTokens.white)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (dailyDone / dailyGoal).clamp(0.0, 1.0),
            minHeight: 8,
            color: LumoVisualTokens.cyanBright,
            backgroundColor: LumoVisualTokens.navigation,
          ),
        ),
        const SizedBox(height: 10),
        Text('${state.xp % 400} / 400 XP bis Level ${state.level + 1}',
            key: const ValueKey('home-xp-progress'),
            style: LumoTextStyles.body.copyWith(
              fontSize: 12,
              color: LumoVisualTokens.muted,
            )),
      ]),
    );
  }

  Widget _stat(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(text,
              style:
                  LumoTextStyles.body.copyWith(color: LumoVisualTokens.white)),
        ],
      );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard(
      {required this.message, required this.label, required this.onTap});
  final String message;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LumoGlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            message,
            style: LumoTextStyles.body.copyWith(color: LumoVisualTokens.white),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: LumoVisualTokens.cyan,
              foregroundColor: LumoVisualTokens.night,
            ),
            onPressed: onTap,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(label),
          ),
        ]),
      );
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard(
      {required this.subject,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.completed,
      required this.onTap});
  final String subject;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LumoGlassCard(
        padding: EdgeInsets.zero,
        color: LumoVisualTokens.glassRow,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Icon(icon, color: color, size: 30),
          title: Text(
            subject,
            style: LumoTextStyles.heading3.copyWith(color: LumoVisualTokens.white),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$subtitle\n$completed ${completed == 1 ? 'Aufgabe' : 'Aufgaben'} geschafft',
              style: const TextStyle(color: LumoVisualTokens.muted),
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              size: 20, color: LumoVisualTokens.cyan),
          onTap: onTap,
        ),
      );
}

class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(children: [
        for (final child in children)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: child),
      ]);
    }
    return Column(children: [
      for (var index = 0; index < children.length; index += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: children[index]),
            const SizedBox(width: 10),
            Expanded(
                child: index + 1 < children.length
                    ? children[index + 1]
                    : const SizedBox.shrink()),
          ]),
        ),
    ]);
  }
}
