import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../widgets/fox/lumo_tutorial_companion.dart';
import '../../widgets/premium/lumo_floating_action_dock.dart';
import '../games/games_content.dart';
import '../quiz/quiz_show_content.dart';
import '../shared/widgets/lumo_living_world.dart';
import '../shared/widgets/lumo_subject_dashboard.dart';
import '../shared/widgets/lumo_subject_tile.dart';
import '../teacher_mode/lumo_akademie_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({
    super.key,
    required this.appState,
    required this.onSection,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Tutorial-Companion Steuerung
  final GlobalKey<LumoTutorialCompanionState> _tutorialKey =
      GlobalKey<LumoTutorialCompanionState>();
  bool _tutorialBadgeVisible = true;

  void _startPractice({
    required String subject,
    required String unit,
    required String message,
  }) {
    widget.appState.update(widget.appState.state.copyWith(
      subject: subject,
      unit: unit,
      mood: LumoMood.point,
      lumoMessage: message,
      sessionKind: LumoSessionKind.quickPractice,
    ));
    widget.onSection(LumoSection.exercises);
  }

  void _openQuiz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizShowContent(appState: widget.appState),
      ),
    );
  }

  void _openGames(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamesContent(appState: widget.appState),
      ),
    );
  }

  void _startTutorial() {
    setState(() => _tutorialBadgeVisible = false);
    _tutorialKey.currentState?.start();
  }

  /// Lumo's Reise durch den Homescreen — von rechts nach links wandernd,
  /// dann reihenweise nach unten ueber alle Subject-Tiles.
  List<LumoTutorialStop> _buildTutorialPath() {
    return const [
      LumoTutorialStop(
        xFraction: 0.78,
        yFraction: 0.18,
        message: 'Hallo! Ich zeig dir alles in der App. Folge mir! 🦊',
        duration: Duration(milliseconds: 3000),
      ),
      LumoTutorialStop(
        xFraction: 0.28,
        yFraction: 0.18,
        message: 'Hier oben siehst du deine Sterne und Mission.',
        duration: Duration(milliseconds: 3500),
      ),
      LumoTutorialStop(
        xFraction: 0.30,
        yFraction: 0.40,
        message: 'Mathe mit Lumo — Zahlen und Knobeln.',
        duration: Duration(milliseconds: 3500),
        jumpToReach: true,
      ),
      LumoTutorialStop(
        xFraction: 0.75,
        yFraction: 0.40,
        message: 'Deutsch — Lesen und Schreiben lernen.',
        duration: Duration(milliseconds: 3300),
      ),
      LumoTutorialStop(
        xFraction: 0.30,
        yFraction: 0.58,
        message: 'Quizshow — 15 Fragen für echte Gutscheine! 🏆',
        duration: Duration(milliseconds: 3500),
        jumpToReach: true,
      ),
      LumoTutorialStop(
        xFraction: 0.75,
        yFraction: 0.58,
        message: 'Hier sind die Spiele. Renne, springe, lerne! 🎮',
        duration: Duration(milliseconds: 3500),
      ),
      LumoTutorialStop(
        xFraction: 0.30,
        yFraction: 0.76,
        message: 'Lesen mit Lumo — ich höre dir beim Lesen zu.',
        duration: Duration(milliseconds: 3300),
        jumpToReach: true,
      ),
      LumoTutorialStop(
        xFraction: 0.75,
        yFraction: 0.76,
        message: 'Sachunterricht — Tiere, Pflanzen, Wetter entdecken!',
        duration: Duration(milliseconds: 3300),
      ),
      LumoTutorialStop(
        xFraction: 0.88,
        yFraction: 0.88,
        message: 'Probier es einfach aus. Ich bin immer hier! 💛',
        duration: Duration(milliseconds: 2800),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final childName = widget.appState.state.childName.trim().isEmpty
        ? 'Lumo-Freund'
        : widget.appState.state.childName.trim();
    final dashboard = LumoLivingWorld(
      starsEarned: widget.appState.state.stars,
      child: LumoSubjectDashboard(
        appState: widget.appState,
        subject: 'Hallo',
        subjectAccent: '$childName!',
        subtitle: 'Was möchtest du heute lernen?',
        greeting: 'Schön, dass du da bist!',
        lumoMessage: 'Heute warten\nspannende Aufgaben\nauf dich!',
        ctaLabel: '🎓 Lumo Akademie öffnen',
        onCtaPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LumoAkademieScreen(appState: widget.appState),
          ),
        ),
        headerAccent: LumoColors.orange,
        dailyMissionTitle: 'Tägliche Mission',
        dailyMissionSubtitle: 'Starte heute eine Lernrunde',
        dailyMissionDone: 1,
        dailyMissionTotal: 3,
        dailyMissionRewardStars: 10,
        dailyMissionRewardXp: 50,
        encourageMessage:
            'Du machst großartige Fortschritte! Heute wartet eine neue Lernmission auf dich.',
        topicTiles: [
          LumoSubjectTile(
            title: 'Mathe mit Lumo',
            subtitle: 'Lumo erklärt Schritt-für-Schritt',
            iconEmoji: 'M',
            illustrationEmoji: '+',
            accent: LumoColors.math,
            level: 3,
            starsCollected: 12,
            starsTotal: 20,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LumoAkademieScreen(appState: widget.appState),
              ),
            ),
          ),
          LumoSubjectTile(
            title: 'Deutsch mit Lumo',
            subtitle: 'Buchstaben schreiben, Lesen, Wörter',
            iconEmoji: 'D',
            illustrationEmoji: 'ABC',
            accent: LumoColors.purple,
            level: 2,
            starsCollected: 8,
            starsTotal: 20,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LumoAkademieScreen(appState: widget.appState),
              ),
            ),
          ),
          LumoSubjectTile(
            title: 'Quizshow',
            subtitle: '15 Fragen, Joker und echte Gutscheine',
            iconEmoji: 'Q',
            illustrationEmoji: '🏆',
            accent: LumoColors.gold,
            level: 1,
            starsCollected: 0,
            starsTotal: 15,
            onTap: () => _openQuiz(context),
          ),
          LumoSubjectTile(
            title: 'Lumo Spielewelt',
            subtitle: '50 Level - Sterne sammeln und Abenteuer erleben',
            iconEmoji: 'S',
            illustrationEmoji: '🎮',
            accent: LumoColors.orange,
            level: 1,
            starsCollected: 0,
            starsTotal: 150,
            onTap: () => _openGames(context),
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
              widget.appState.update(widget.appState.state.copyWith(
                subject: 'Lesen',
                unit: 'Aktives Lesen',
                mood: LumoMood.think,
                lumoMessage:
                    'Ich höre dir\nbeim Lesen zu.\nSatz für Satz.',
              ));
              widget.onSection(LumoSection.reading);
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LumoAkademieScreen(appState: widget.appState),
              ),
            ),
          ),
        ],
      ),
    );

    // Stack-Overlay: Dashboard + Tutorial-Companion + "Tutorial starten"-FAB
    return Stack(
      children: [
        dashboard,

        // ── Wandernder Lumo-Tutorial-Begleiter ────────────────────
        Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: LumoTutorialCompanion(
              key: _tutorialKey,
              stops: _buildTutorialPath(),
              childName: childName,
              foxSize: 130,
              onCompleted: () {
                if (mounted) setState(() => _tutorialBadgeVisible = true);
              },
            ),
          ),
        ),

        // ── Premium Floating Action Dock (unten rechts) ────────
        // Heinz' Phase 5: LumoFloatingActionDock statt eigenem FAB.
        // Akademie als primary, Tutorial-Hilfe als sekundaer.
        if (_tutorialBadgeVisible)
          LumoFloatingActionDock(
            actions: [
              LumoDockAction(
                icon: Icons.help_outline_rounded,
                label: 'Tutorial',
                onTap: _startTutorial,
              ),
              LumoDockAction(
                icon: Icons.school_rounded,
                label: 'Akademie',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        LumoAkademieScreen(appState: widget.appState),
                  ),
                ),
                isPrimary: true,
              ),
            ],
          ),
      ],
    );
  }
}
