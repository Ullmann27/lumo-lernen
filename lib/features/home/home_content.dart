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

  /// Lumo's Reise durch den Homescreen.
  /// Heinz 2026-05-21: 'Fuchs muss viel mehr erklaeren und fix von Button
  /// zu Button springen'. Daher:
  ///  - genauere x/y-Positionen passend zum 2-Spalten-Subject-Grid
  ///    (linke Spalte ~0.27, rechte Spalte ~0.73)
  ///  - laengere Texte pro Stop (Heinz: 'viel mehr erklaeren')
  ///  - Verweildauer hoeher, damit Kind lesen + verstehen kann
  ///  - jumpToReach beim Wechsel der Reihe (klassische Leiter-Bewegung)
  List<LumoTutorialStop> _buildTutorialPath() {
    return const [
      // 1) Begruessung oben rechts
      LumoTutorialStop(
        xFraction: 0.78,
        yFraction: 0.16,
        message: 'Hallo! Ich bin Lumo. 🦊\n'
            'Ich zeig dir jetzt die ganze App.\n'
            'Folge mir Schritt fuer Schritt.',
        duration: Duration(milliseconds: 4500),
      ),
      // 2) Profil-Header links oben (Sterne + Mission)
      LumoTutorialStop(
        xFraction: 0.22,
        yFraction: 0.16,
        message: 'Hier oben siehst du deine Sterne.\n'
            'Jede richtige Antwort gibt dir einen.\n'
            'Sammle viele und Lumo freut sich!',
        duration: Duration(milliseconds: 5000),
      ),
      // 3) Daily Mission Strip
      LumoTutorialStop(
        xFraction: 0.50,
        yFraction: 0.30,
        message: 'Das ist deine taegliche Mission.\n'
            'Mach sie jeden Tag - dann wirst du immer besser.',
        duration: Duration(milliseconds: 4500),
        jumpToReach: true,
      ),
      // 4) Mathe-Tile (linke Spalte, Reihe 1)
      LumoTutorialStop(
        xFraction: 0.27,
        yFraction: 0.45,
        message: 'Tipp hier auf "Mathe mit Lumo"! ➕\n'
            'Wir rechnen zusammen Plus, Minus und mehr.\n'
            'Ich erklaere jeden Schritt.',
        duration: Duration(milliseconds: 5000),
        jumpToReach: true,
      ),
      // 5) Deutsch-Tile (rechte Spalte, Reihe 1)
      LumoTutorialStop(
        xFraction: 0.73,
        yFraction: 0.45,
        message: '"Deutsch mit Lumo" ist hier. ✏️\n'
            'Buchstaben schreiben, Woerter lesen, Diktat.\n'
            'Ich sag dir das Wort, du schreibst es.',
        duration: Duration(milliseconds: 5000),
      ),
      // 6) Quizshow (linke Spalte, Reihe 2)
      LumoTutorialStop(
        xFraction: 0.27,
        yFraction: 0.58,
        message: 'Die Quizshow! 🏆\n'
            '15 Fragen, drei Joker, am Ende echte Gutscheine.\n'
            'Trau dich!',
        duration: Duration(milliseconds: 5000),
        jumpToReach: true,
      ),
      // 7) Spielewelt (rechte Spalte, Reihe 2)
      LumoTutorialStop(
        xFraction: 0.73,
        yFraction: 0.58,
        message: 'In der Spielewelt 🎮 gibt es viele Level.\n'
            'Renne, springe, sammle Sterne.\n'
            'Lernen darf Spass machen!',
        duration: Duration(milliseconds: 5000),
      ),
      // 8) Lesen-Tile (linke Spalte, Reihe 3)
      LumoTutorialStop(
        xFraction: 0.27,
        yFraction: 0.72,
        message: '"Lesen mit Lumo" 📖\n'
            'Ich hoer dir beim Lesen zu.\n'
            'Wir lesen Geschichten Satz fuer Satz.',
        duration: Duration(milliseconds: 5000),
        jumpToReach: true,
      ),
      // 9) Sachunterricht (rechte Spalte, Reihe 3)
      LumoTutorialStop(
        xFraction: 0.73,
        yFraction: 0.72,
        message: 'Sachunterricht 🌍\n'
            'Tiere, Pflanzen, Wetter, Farben.\n'
            'Hier entdeckst du die Welt.',
        duration: Duration(milliseconds: 5000),
      ),
      // 10) Magic-Hub FAB (links unten lila)
      LumoTutorialStop(
        xFraction: 0.12,
        yFraction: 0.92,
        message: 'Der lila Stern unten links 🌟\n'
            'Da gibt es Geschichten, das Universum\n'
            'und meine Live-Magie.',
        duration: Duration(milliseconds: 5000),
        jumpToReach: true,
      ),
      // 11) Eltern-FAB (rechts unten orange) - falls vorhanden
      LumoTutorialStop(
        xFraction: 0.88,
        yFraction: 0.92,
        message: 'Hier kommen die Eltern hin. 👪\n'
            'Sie sehen wie gut du lernst\n'
            'und stellen die App ein.',
        duration: Duration(milliseconds: 5000),
      ),
      // 12) Abschluss in der Mitte
      LumoTutorialStop(
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
