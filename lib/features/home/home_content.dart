import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../widgets/fox/lumo_tutorial_companion.dart';
import '../games/games_content.dart';
import '../magic_hub/lumo_magic_hub_screen.dart';
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
            illustrationEmoji: '➕',
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
            illustrationEmoji: '✏️',
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
            illustrationEmoji: '📖',
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
            illustrationEmoji: '🌍',
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

        // ── Floating "Tutorial starten" Button (unten rechts) ────
        Positioned(
          right: 16,
          bottom: 18,
          child: _TutorialFab(
            visible: _tutorialBadgeVisible,
            onTap: _startTutorial,
          ),
        ),

        // ── Lumo Magic Hub FAB (Heinz' 4 Premium-Vorschlaege) ─────
        Positioned(
          left: 16,
          bottom: 18,
          child: _MagicHubFab(appState: widget.appState),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Magic Hub FAB - Zugang zu Lumo Story/Cosmos/Live/Mirror
// ════════════════════════════════════════════════════════════════════════
class _MagicHubFab extends StatefulWidget {
  const _MagicHubFab({required this.appState});
  final LumoAppState appState;

  @override
  State<_MagicHubFab> createState() => _MagicHubFabState();
}

class _MagicHubFabState extends State<_MagicHubFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.4 + _glow.value * 0.3),
                blurRadius: 16 + _glow.value * 12,
                spreadRadius: _glow.value * 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton(
        heroTag: 'magicHubFab',
        backgroundColor: const Color(0xFF7C3AED),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                LumoMagicHubScreen(appState: widget.appState),
          ),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// FAB-Button "Lumo zeigt's dir"
// ════════════════════════════════════════════════════════════════════════
class _TutorialFab extends StatefulWidget {
  const _TutorialFab({required this.visible, required this.onTap});
  final bool visible;
  final VoidCallback onTap;

  @override
  State<_TutorialFab> createState() => _TutorialFabState();
}

class _TutorialFabState extends State<_TutorialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final p = _pulse.value;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withOpacity(0.45 + p * 0.25),
                  blurRadius: 18 + p * 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                  color: Colors.white.withOpacity(0.5 + p * 0.2), width: 1.4),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🦊', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text(
                "Lumo zeigt's dir",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
