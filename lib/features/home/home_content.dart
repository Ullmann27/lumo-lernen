import 'dart:async';

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
    this.drawBackground = true,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  /// Im App-Rahmen malt die Shell die Szene vollflächig.
  final bool drawBackground;

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
          final reduceMotion = state.settings.reduceAnimations ||
              state.settings.calmMode ||
              MediaQuery.disableAnimationsOf(context);
          final recommendation = appState.topLearningRecommendation();
          return LayoutBuilder(
            builder: (context, constraints) {
              final deviceWide = MediaQuery.sizeOf(context).width >= 720;
              final wide = deviceWide || constraints.maxWidth >= 720;
              final compact = constraints.maxWidth < 320;
              // Bild 01: vier Kacheln in einer Reihe; schmal oder mit großer
              // Schrift zwei pro Reihe, damit die Namen ganz lesbar bleiben.
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final columns = deviceWide
                  ? 4
                  : wide
                      ? 4
                      : constraints.maxWidth >= 340 && textScale <= 1.2
                          ? 4
                          : 2;
              final cardHeight = 240 * textScale.clamp(1.0, 1.5).toDouble();
              final actions = <Widget>[
                _HomeGlassActionTile(
                  key: const ValueKey('home-learn'),
                  title: 'Lernen',
                  subtitle: 'Mathe, Deutsch und mehr',
                  icon: Icons.menu_book_rounded,
                  iconAsset: 'assets/lumo_design/icons/book_open.png',
                  color: LumoVisualTokens.learning,
                  onTap: () => onSection(LumoSection.learn),
                ),
                _HomeGlassActionTile(
                  key: const ValueKey('home-games'),
                  title: 'Spielen',
                  subtitle: 'Lumo Kart, Memory und mehr',
                  icon: Icons.sports_esports_rounded,
                  iconAsset: 'assets/lumo_design/icons/gamepad.png',
                  color: LumoVisualTokens.games,
                  onTap: () => onSection(LumoSection.games),
                ),
                _HomeGlassActionTile(
                  key: const ValueKey('home-tests'),
                  title: 'Tests',
                  subtitle: 'Wissen überprüfen',
                  icon: Icons.assignment_rounded,
                  iconAsset: 'assets/lumo_design/icons/trophy_gold.png',
                  color: LumoVisualTokens.tests,
                  onTap: () => onSection(LumoSection.tests),
                ),
                _HomeGlassActionTile(
                  key: const ValueKey('home-rewards'),
                  title: 'Belohnungen',
                  subtitle: 'Sterne und Extras',
                  icon: Icons.star_rounded,
                  iconAsset: 'assets/lumo_design/icons/treasure_chest.png',
                  color: LumoVisualTokens.rewards,
                  onTap: () => onSection(LumoSection.rewards),
                ),
              ];
              final list = ListView(
                key: const PageStorageKey('lumo-home-scroll'),
                padding: EdgeInsets.fromLTRB(16, compact ? 4 : 12, 16, 24),
                children: [
                  _HomeEntrance(
                    reduceMotion: reduceMotion,
                    child: _HomeHero(
                      name: name,
                      compact: compact,
                      wide: wide,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 10),
                  _HomeEntrance(
                    reduceMotion: reduceMotion,
                    delay: const Duration(milliseconds: 60),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('home-kart-banner'),
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => onSection(LumoSection.games),
                        child: _KartBanner(compact: compact),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 12),
                  GridView.count(
                    crossAxisCount: columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: deviceWide && columns == 4
                        ? .88
                        : wide
                            ? 1.02
                            : columns == 4
                                ? .74
                                : textScale > 1.2
                                    ? .9
                                    : 1.1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < actions.length; i++)
                        _HomeEntrance(
                          reduceMotion: reduceMotion,
                          delay: Duration(milliseconds: 120 + i * 60),
                          child: actions[i],
                        ),
                    ],
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
                  if (constraints.maxWidth >= 360)
                    Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: SizedBox(
                            height: cardHeight,
                            child: _ProgressCard(
                              appState: appState,
                              reduceMotion: reduceMotion,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 10,
                          child: _MotivationCard(
                            reduceMotion: reduceMotion,
                            onLearn: () => onSection(LumoSection.learn),
                            height: cardHeight,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ProgressCard(
                      appState: appState,
                      reduceMotion: reduceMotion,
                    ),
                    const SizedBox(height: 12),
                    _MotivationCard(
                      reduceMotion: reduceMotion,
                      onLearn: () => onSection(LumoSection.learn),
                    ),
                  ],
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
                      subtitle: Text('Lesen, Abenteuer und deine Sammlung',
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
                            () => onSection(LumoSection.games),
                            key: const ValueKey('home-discover-kart')),
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
              return drawBackground
                  ? LumoSceneBackground(
                      scene: LumoScene.home,
                      showPlaceholderLabel: false,
                      dimmed: true,
                      child: list,
                    )
                  : list;
            },
          );
        },
      );

  Widget _extra(
          String title, String subtitle, IconData icon, VoidCallback onTap,
          {Key? key}) =>
      ListTile(
        key: key,
        leading: Icon(icon, color: LumoVisualTokens.cyan),
        title:
            Text(title, style: const TextStyle(color: LumoVisualTokens.white)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: LumoVisualTokens.muted)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: LumoVisualTokens.cyan),
        onTap: onTap,
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.appState,
    required this.reduceMotion,
  });

  final LumoAppState appState;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final state = appState.state;
    final dailyDone = appState.learningDailyDone();
    final dailyGoal = state.settings.dailyGoal.clamp(1, 500);
    return LumoGlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  color: LumoVisualTokens.cyanBright, size: 19),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Tägliche Aufgaben',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LumoTextStyles.heading3.copyWith(
                    color: LumoVisualTokens.white,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '$dailyDone / $dailyGoal',
                key: const ValueKey('home-daily-progress'),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: LumoVisualTokens.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < 3; index++)
            _DailyTaskRow(
              index: index,
              complete: dailyDone > index,
            ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (dailyDone / dailyGoal).clamp(0.0, 1.0),
              ),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: LumoVisualTokens.cyanBright,
                backgroundColor: LumoVisualTokens.navigation,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Heute: $dailyDone von $dailyGoal Aufgaben',
            style: LumoTextStyles.body.copyWith(
              fontSize: 10,
              color: LumoVisualTokens.muted,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              Text('${state.stars} Sterne',
                  style: _progressLabelStyle(LumoVisualTokens.gold)),
              Text('Level ${state.level}',
                  style: _progressLabelStyle(LumoVisualTokens.cyanBright)),
              Text(
                '${appState.learningStreakDays()} ${appState.learningStreakDays() == 1 ? 'Lerntag' : 'Lerntage'} in Folge',
                style: _progressLabelStyle(LumoVisualTokens.rewards),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${state.xp % 400} / 400 XP bis Level ${state.level + 1}',
            key: const ValueKey('home-xp-progress'),
            style: LumoTextStyles.body.copyWith(
              fontSize: 10,
              color: LumoVisualTokens.muted,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _progressLabelStyle(Color color) => TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w800,
        fontSize: 10,
        color: color,
      );
}

class _DailyTaskRow extends StatelessWidget {
  const _DailyTaskRow({required this.index, required this.complete});

  final int index;
  final bool complete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          key: ValueKey('home-daily-task-$index'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: LumoVisualTokens.glassRow.withOpacity(.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.18)),
          ),
          child: Row(
            children: [
              Icon(
                complete ? Icons.check_circle : Icons.circle_outlined,
                color: complete
                    ? LumoVisualTokens.cyanBright
                    : LumoVisualTokens.muted,
                size: 18,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Lernaufgabe ${index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LumoVisualTokens.white,
                  ),
                ),
              ),
              if (complete)
                const Icon(Icons.chevron_right_rounded,
                    color: LumoVisualTokens.cyan, size: 17),
            ],
          ),
        ),
      );
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({
    required this.reduceMotion,
    required this.onLearn,
    this.height = 240,
  });

  final bool reduceMotion;
  final VoidCallback onLearn;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: LumoGlassCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Expanded(
                      child: LumoHeroBubble(
                        text: '„Du kannst das!“',
                        handwritten: true,
                      ),
                    ),
                    _BreathingFox(
                      reduceMotion: reduceMotion,
                      child: const LumoFoxPose(
                        pose: LumoDesignFoxPose.thumbWink,
                        size: 68,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    backgroundColor: LumoVisualTokens.cyan,
                    foregroundColor: LumoVisualTokens.night,
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: onLearn,
                  child: const Text(
                    'Weiter lernen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BreathingFox extends StatefulWidget {
  const _BreathingFox({
    required this.child,
    required this.reduceMotion,
  });

  final Widget child;
  final bool reduceMotion;

  @override
  State<_BreathingFox> createState() => _BreathingFoxState();
}

class _BreathingFoxState extends State<_BreathingFox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
      value: widget.reduceMotion ? .5 : 0,
    );
    if (!widget.reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _BreathingFox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion == widget.reduceMotion) return;
    if (widget.reduceMotion) {
      _controller.stop();
      _controller.value = .5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final motion = widget.reduceMotion
              ? 0.0
              : Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: Offset(0, -4 * motion),
            child: Transform.scale(
              scale: 1 + .02 * motion,
              child: child,
            ),
          );
        },
      );
}

class _HomeEntrance extends StatefulWidget {
  const _HomeEntrance({
    required this.child,
    required this.reduceMotion,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool reduceMotion;
  final Duration delay;

  @override
  State<_HomeEntrance> createState() => _HomeEntranceState();
}

class _HomeEntranceState extends State<_HomeEntrance> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _showWhenReady();
  }

  @override
  void didUpdateWidget(covariant _HomeEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _timer?.cancel();
      _visible = true;
    } else if (oldWidget.reduceMotion && !widget.reduceMotion) {
      _visible = false;
      _showWhenReady();
    }
  }

  void _showWhenReady() {
    if (widget.reduceMotion || widget.delay == Duration.zero) {
      _visible = true;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _visible || widget.reduceMotion ? 1 : 0,
        duration: widget.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350),
        child: AnimatedSlide(
          offset: _visible || widget.reduceMotion
              ? Offset.zero
              : const Offset(0, .12),
          duration: widget.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
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
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Icon(icon, color: color, size: 30),
            title: Text(
              subject,
              style: LumoTextStyles.heading3
                  .copyWith(color: LumoVisualTokens.white),
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

/// Bild 01: Lumo winkt im Kart, links „Hallo!“, rechts der Spruch.
class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.name,
    required this.compact,
    required this.wide,
    required this.reduceMotion,
  });

  final String name;
  final bool compact;
  final bool wide;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Auf breiten, niedrigen Geräten (Fold quer) bleiben die Kacheln
          // im ersten Bild sichtbar.
          final screen = MediaQuery.sizeOf(context).height;
          final height = compact
              ? 150.0
              : (width * (wide ? .32 : .52))
                  .clamp(150.0, 290.0)
                  .clamp(0.0, screen * .3)
                  .clamp(120.0, 290.0)
                  .toDouble();
          final foxSize = height * (compact ? 1 : 1.12);
          return SizedBox(
            height: height,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: (width - foxSize) / 2 + width * .04,
                bottom: -foxSize * .04,
                child: RepaintBoundary(
                  child: _BreathingFox(
                    reduceMotion: reduceMotion,
                    child: LumoFoxPose(
                        pose: LumoDesignFoxPose.kartWave, size: foxSize),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: height * .06,
                width: width * (compact ? .5 : .34),
                child: Transform.rotate(
                  angle: -.05,
                  child: LumoHeroBubble(
                    key: const ValueKey('home-greeting'),
                    title: 'Hallo, $name!',
                    text: 'Bereit für ein neues Abenteuer?',
                  ),
                ),
              ),
              if (!compact)
                Positioned(
                  right: -4,
                  top: height * .4,
                  width: width * .25,
                  child: Transform.rotate(
                    angle: -.1,
                    child: const LumoHeroBubble(
                      text: 'Kleine Schritte\nGroße Zukunft!',
                      handwritten: true,
                    ),
                  ),
                ),
            ]),
          );
        },
      );
}

/// Banner „Lumo Kart – Lernen auf der Überholspur!“ mit Bild und „Neu!“.
class _KartBanner extends StatelessWidget {
  const _KartBanner({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => LumoGlassCard(
        padding: const EdgeInsets.all(8),
        radius: 22,
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 48,
              height: compact ? 36 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3C8DFF), Color(0xFF1846C8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(.6)),
              ),
              child: Icon(Icons.sports_score_rounded,
                  color: Colors.white, size: compact ? 22 : 30),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lumo Kart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LumoTextStyles.heading2.copyWith(
                      color: LumoVisualTokens.white,
                      fontSize: compact ? 16 : 22,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Lernen auf der Überholspur!',
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: LumoTextStyles.body.copyWith(
                      color: LumoVisualTokens.white,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: LumoVisualTokens.white),
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: LumoVisualTokens.white, size: 20),
              ),
            SizedBox(
              width: compact ? 70 : 120,
              height: compact ? 44 : 66,
              child: Stack(children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/lumo_design/cards/game_kart.png',
                      key: const ValueKey('home-kart-image'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sports_motorsports_rounded,
                        color: LumoVisualTokens.cyanBright,
                        size: 38,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: LumoVisualTokens.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Neu!',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: LumoVisualTokens.night,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      );
}


class _HomeGlassActionTile extends StatelessWidget {
  const _HomeGlassActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.iconAsset,
  });

  final IconData icon;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.hasBoundedHeight && constraints.maxHeight < 132;
          final iconSize =
              (constraints.maxWidth * .26).clamp(28.0, 54.0).toDouble();
          final backgroundTop =
              Color.lerp(LumoVisualTokens.glass, color, .14)!;
          final backgroundBottom =
              Color.lerp(LumoVisualTokens.navigation, color, .06)!;
          return Semantics(
            button: true,
            label: '$title. $subtitle',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onTap,
                child: Ink(
                  padding: EdgeInsets.all(compact ? 10 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [backgroundTop, backgroundBottom],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Color.lerp(
                        LumoVisualTokens.cyanBright,
                        color,
                        .22,
                      )!
                          .withOpacity(.82),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LumoVisualTokens.cyanBright.withOpacity(.17),
                        blurRadius: 22,
                        spreadRadius: -6,
                      ),
                      BoxShadow(
                        color: color.withOpacity(.13),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: color.withOpacity(.92),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(.55),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                padding: EdgeInsets.all(compact ? 7 : 10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(.16),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: color.withOpacity(.35),
                                  ),
                                ),
                                child: iconAsset == null
                                    ? Icon(icon,
                                        color: Colors.white, size: iconSize)
                                    : Image.asset(
                                        iconAsset!,
                                        width: iconSize,
                                        height: iconSize,
                                        fit: BoxFit.contain,
                                        excludeFromSemantics: true,
                                        errorBuilder: (_, __, ___) => Icon(
                                          icon,
                                          color: Colors.white,
                                          size: iconSize,
                                        ),
                                      ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: compact ? 14 : 18,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x6600D9FF),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 9.5 : 11.5,
                                color: Colors.white.withOpacity(.82),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: compact ? 28 : 34,
                          height: compact ? 28 : 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LumoVisualTokens.cyanBright.withOpacity(.18),
                            border: Border.all(
                              color: LumoVisualTokens.cyanBright.withOpacity(.65),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: LumoVisualTokens.white,
                            size: compact ? 16 : 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
