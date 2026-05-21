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

  // GlobalKeys auf die 6 Subject-Tiles.
  // Heinz 2026-05-21: 'Tutorial-Fuchs landet nicht auf den Buttons,
  // soll knapp neben der Ueberschrift springen.' Mit echten Render-
  // Box-Positionen statt nur Bildschirm-Fractions trifft Lumo die
  // Tile-Ueberschriften genau, auf jedem Geraet.
  final GlobalKey _kMathe = GlobalKey(debugLabel: 'tut_mathe');
  final GlobalKey _kDeutsch = GlobalKey(debugLabel: 'tut_deutsch');
  final GlobalKey _kQuiz = GlobalKey(debugLabel: 'tut_quiz');
  final GlobalKey _kSpiele = GlobalKey(debugLabel: 'tut_spiele');
  final GlobalKey _kLesen = GlobalKey(debugLabel: 'tut_lesen');
  final GlobalKey _kSachk = GlobalKey(debugLabel: 'tut_sachk');

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

  /// Lumo's Reise durch den Homescreen.
  /// Heinz 2026-05-21: 'Sprünge fixen - immer knapp neben der
  /// Überschrift'. Daher: GlobalKeys auf die echten Subject-Tiles +
  /// Sections. Der Companion liest zur Laufzeit die echte
  /// RenderBox-Position und positioniert Lumo direkt am Ziel-Widget.
  /// xFraction/yFraction bleiben als Fallback (z.B. fuer FABs).
  List<LumoTutorialStop> _buildTutorialPath() {
    return [
      // 1) Begruessung (Fraction: kein Header-Key)
      const LumoTutorialStop(
        xFraction: 0.75,
        yFraction: 0.18,
        message: 'Hallo! Ich bin Lumo. 🦊\n'
            'Ich zeig dir jetzt die ganze App.\n'
            'Folge mir Schritt fuer Schritt.',
        duration: Duration(milliseconds: 4500),
      ),
      // 2) Mathe-Tile
      LumoTutorialStop(
        targetKey: _kMathe,
        message: 'Tipp hier auf "Mathe mit Lumo"! ➕\n'
            'Wir rechnen zusammen Plus, Minus und mehr.\n'
            'Ich erklaere jeden Schritt.',
        duration: const Duration(milliseconds: 5000),
        jumpToReach: true,
      ),
      // 5) Deutsch-Tile
      LumoTutorialStop(
        targetKey: _kDeutsch,
        message: '"Deutsch mit Lumo" ist hier. ✏️\n'
            'Buchstaben schreiben, Woerter lesen, Diktat.\n'
            'Ich sag dir das Wort, du schreibst es.',
        duration: const Duration(milliseconds: 5000),
      ),
      // 6) Quizshow
      LumoTutorialStop(
        targetKey: _kQuiz,
        message: 'Die Quizshow! 🏆\n'
            '15 Fragen, drei Joker, am Ende echte Gutscheine.\n'
            'Trau dich!',
        duration: const Duration(milliseconds: 5000),
        jumpToReach: true,
      ),
      // 7) Spielewelt
      LumoTutorialStop(
        targetKey: _kSpiele,
        message: 'In der Spielewelt 🎮 gibt es viele Level.\n'
            'Renne, springe, sammle Sterne.\n'
            'Lernen darf Spass machen!',
        duration: const Duration(milliseconds: 5000),
      ),
      // 8) Lesen-Tile
      LumoTutorialStop(
        targetKey: _kLesen,
        message: '"Lesen mit Lumo" 📖\n'
            'Ich hoer dir beim Lesen zu.\n'
            'Wir lesen Geschichten Satz fuer Satz.',
        duration: const Duration(milliseconds: 5000),
        jumpToReach: true,
      ),
      // 9) Sachunterricht
      LumoTutorialStop(
        targetKey: _kSachk,
        message: 'Sachunterricht 🌍\n'
            'Tiere, Pflanzen, Wetter, Farben.\n'
            'Hier entdeckst du die Welt.',
        duration: const Duration(milliseconds: 5000),
      ),
      // 10) Abschluss - bewusst per Fraction (kein Tile am Bildschirm-
      //     Mittelpunkt, dort steht Lumo am Schluss "winkend").
      const LumoTutorialStop(
        xFraction: 0.50,
        yFraction: 0.50,
        message: 'Das war alles! 💛\n'
            'Tipp einfach ueberall drauf.\n'
            'Ich bin immer da wenn du mich brauchst.',
        duration: Duration(milliseconds: 4500),
        jumpToReach: true,
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
            key: _kMathe,
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
            key: _kDeutsch,
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
            key: _kQuiz,
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
            key: _kSpiele,
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
            key: _kLesen,
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
            key: _kSachk,
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
