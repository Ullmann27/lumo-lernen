import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_asset_diagnostics.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
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
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF7EC), Color(0xFFF0F6FF)],
              ),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 540;
              final actions = [
                _HomeAction(
                  key: const ValueKey('home-learn'),
                  title: 'Lernen',
                  subtitle: 'Deine Fächer und Aufgaben',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF8B3B11),
                  surface: const Color(0xFFFFE6C7),
                  onTap: () => onSection(LumoSection.learn),
                ),
                _HomeAction(
                  key: const ValueKey('home-games'),
                  title: 'Spielen',
                  subtitle: 'Lumo Kart, Memory und mehr',
                  icon: Icons.sports_esports_rounded,
                  color: const Color(0xFF45328B),
                  surface: const Color(0xFFE5E0FF),
                  onTap: () => onSection(LumoSection.games),
                ),
              ];
              return ListView(
                key: const PageStorageKey('lumo-home-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hallo, $name!',
                              key: const ValueKey('home-greeting'),
                              style: LumoTextStyles.heading2),
                          const SizedBox(height: 4),
                          Text('Dein Lumo-Tag · ${state.grade}. Klasse',
                              style: LumoTextStyles.body),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipOval(
                      child: Image.asset('assets/images/lumo_fox.png',
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          excludeFromSemantics: true,
                          errorBuilder: (_, error, __) {
                        reportLumoAssetError(
                            'assets/images/lumo_fox.png', error);
                        return const SizedBox(width: 66, height: 66);
                      }),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (sideBySide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: actions.first),
                        const SizedBox(width: 12),
                        Expanded(child: actions.last),
                      ],
                    )
                  else ...[
                    actions.first,
                    const SizedBox(height: 10),
                    actions.last,
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('home-explanation'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: const Color(0xFF824115),
                      ),
                      onPressed: () => LumoCompanionRequests.instance
                          .requestAppExplanation(),
                      icon: const Icon(Icons.waving_hand_rounded, size: 20),
                      label: const Text("Lumo zeigt's dir"),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ProgressCard(appState: appState),
                  const SizedBox(height: 20),
                  const Text('Das passt heute zu dir',
                      style: LumoTextStyles.heading3),
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
                  const Text('Deine Lernfächer',
                      style: LumoTextStyles.heading3),
                  const SizedBox(height: 10),
                  _ResponsiveCards(
                    columns: sideBySide ? 2 : 1,
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
                    child: ExpansionTile(
                      key: const PageStorageKey('home-discover'),
                      title: const Text('Mehr mit Lumo entdecken',
                          style: LumoTextStyles.heading3),
                      subtitle:
                          const Text('Lesen, Abenteuer und deine Sammlung'),
                      leading: const Icon(Icons.explore_rounded,
                          color: LumoColors.teal),
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
                            () => _open(
                                context, const LumoRechentricksPosterScreen())),
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
              );
            }),
          );
        },
      );

  Widget _extra(
          String title, String subtitle, IconData icon, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: LumoColors.ink700),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withOpacity(.2)),
            ),
            child: Row(children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: LumoTextStyles.heading2.copyWith(color: color)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: LumoTextStyles.body
                            .copyWith(fontSize: 13, color: LumoColors.ink700)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: color, size: 22),
            ]),
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LumoColors.ink100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 16, runSpacing: 10, children: [
          _stat(Icons.star_rounded, '${state.stars} Sterne', LumoColors.math),
          _stat(Icons.workspace_premium_rounded, 'Level ${state.level}',
              LumoColors.purple),
          _stat(
              Icons.local_fire_department_rounded,
              '${appState.learningStreakDays()} ${appState.learningStreakDays() == 1 ? 'Lerntag' : 'Lerntage'} in Folge',
              LumoColors.teal),
        ]),
        const SizedBox(height: 16),
        Text('Heute: $dailyDone von $dailyGoal Aufgaben',
            key: const ValueKey('home-daily-progress'),
            style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (dailyDone / dailyGoal).clamp(0.0, 1.0),
            minHeight: 8,
            color: LumoColors.teal,
            backgroundColor: LumoColors.tealSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text('${state.xp % 400} / 400 XP bis Level ${state.level + 1}',
            key: const ValueKey('home-xp-progress'),
            style: LumoTextStyles.body.copyWith(fontSize: 12)),
      ]),
    );
  }

  Widget _stat(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
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
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message,
                style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: const Color(0xFF824115),
              ),
              onPressed: onTap,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(label),
            ),
          ]),
        ),
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
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Icon(icon, color: color, size: 30),
          title: Text(subject,
              style: LumoTextStyles.heading3.copyWith(color: color)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
                '$subtitle\n$completed ${completed == 1 ? 'Aufgabe' : 'Aufgaben'} geschafft'),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
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
