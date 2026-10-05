import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_asset_diagnostics.dart';
import '../../core/game_progress_repository.dart';
import '../../domain/games/game_level_catalog.dart';
import '../../domain/games/game_level_model.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../shared/widgets/lumo_premium_effects.dart' show LumoFloating;
import '../lumo3d/lumo3d_launcher.dart';
import 'flame/lumo_jump_game.dart';
import 'connect_four/lumo_connect_four_game.dart';
import 'dice_race/lumo_dice_race_game.dart';
import 'lumo_cards/lumo_cards_screen.dart';
import 'memory/lumo_memory_game.dart';
import 'mini_games/color_boxes_game.dart';
import 'mini_games/letter_fill_game.dart';
import 'mini_games/number_house_game.dart';
import 'mini_games/stars_path_game.dart';

/// Haupt-Screen der Lumo Spielewelt.
///
/// Zeigt:
///   - Top-Header mit Stern-Statistik und Block-Indikator
///   - Vertikal scrollende Level-Map mit 50 Levels auf gewundenem Pfad
///   - Aktives Level glueht (Lumo-Avatar sitzt darauf)
///   - Gesperrte Level mit Schloss-Icon
///   - Tap auf entsperrtes Level: zeigt Bottom-Sheet mit Level-Info
///     und startet das passende Mini-Game.
class GamesContent extends StatefulWidget {
  const GamesContent(
      {super.key,
      required this.appState,
      this.onSection,
      this.onGameReturn,
      this.drawBackground = true});

  final LumoAppState appState;

  /// Im App-Rahmen malt die Shell die Szene vollflächig.
  final bool drawBackground;
  final ValueChanged<LumoSection>? onSection;
  final Future<void> Function()? onGameReturn;

  @override
  State<GamesContent> createState() => _GamesContentState();
}

class _GamesContentState extends State<GamesContent> {
  static const _repo = GameProgressRepository();

  Map<int, int> _stars = const <int, int>{};
  bool _loaded = false;
  bool _launchingGame = false;
  int? _kartGrade;
  String? _kartSubject;

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]+'),
              '_',
            );
    return 'local_${safeName}_${st.grade}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.loadStars(_childId);
    final prefs = await SharedPreferences.getInstance();
    Map? options;
    try {
      final raw = prefs.getString('lumo_kart_launch_v1');
      if (raw != null) options = jsonDecode(raw) as Map;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _stars = s;
      final grade = options?['grade'];
      if (grade is int && grade >= 1 && grade <= 4) _kartGrade = grade;
      final subject = options?['subject'];
      if (const ['Mathematik', 'Deutsch', 'Sachunterricht', 'Logik']
          .contains(subject)) {
        _kartSubject = subject as String;
      }
      _loaded = true;
    });
  }

  Future<void> _saveKartOptions({int? grade, String? subject}) async {
    setState(() {
      _kartGrade = grade ?? _kartGrade ?? widget.appState.state.grade;
      _kartSubject = subject ?? _kartSubject ?? 'Mathematik';
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lumo_kart_launch_v1',
        jsonEncode({'grade': _kartGrade, 'subject': _kartSubject}));
  }

  void _onLevelTap(GameLevelRuntime rt) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _LevelDetailSheet(runtime: rt, onPlay: () => _launchLevel(rt)),
    );
  }

  Future<void> _launchAdventure() async {
    HapticFeedback.mediumImpact();
    // Adventure-Mode nutzt das erste Level-Objekt als Basis (Theme + ID),
    // aber laeuft als eigenstaendiges Plattform-Game. Sterne landen direkt
    // ins Wallet (totalEarnedStars via appState.update im Game selbst).
    final adventureLevel = GameLevelCatalog.levels.first;
    final earnedStars = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => LumoJumpFlameScreen(
          appState: widget.appState,
          level: adventureLevel,
        ),
      ),
    );
    if (earnedStars != null && earnedStars > 0) {
      await _load();
    }
  }

  Future<void> _launch3D(String scene) async {
    if (_launchingGame) return;
    setState(() => _launchingGame = true);
    HapticFeedback.mediumImpact();
    final state = widget.appState.state;
    try {
      final launched = await launchLumo3D(
        context,
        scene: scene,
        grade: _kartGrade ?? state.grade,
        subject: _kartSubject ??
            (state.subject == 'Deutsch' ? 'Deutsch' : 'Mathematik'),
        appState: widget.appState,
      );
      if (launched) await widget.onGameReturn?.call();
    } finally {
      if (mounted) setState(() => _launchingGame = false);
    }
    if (mounted) await _load();
  }

  Future<void> _launchMemory() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LumoMemoryScreen(appState: widget.appState),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _launchConnectFour() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LumoConnectFourScreen(appState: widget.appState),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _launchDiceRace() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LumoDiceRaceScreen(appState: widget.appState),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _launchLumoCards() async {
    HapticFeedback.mediumImpact();
    // Heinz 2026-05-21 'zu langweilig' -> Solo-Bot ist jetzt der
    // Default. Pass-and-Play (vsBot=false) ist spaeter ueber einen
    // sekundaeren Button erreichbar.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LumoCardsScreen(
          appState: widget.appState,
          player1Name: 'Du',
          player2Name: 'Lumo',
          vsBot: true,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _launchLevel(GameLevelRuntime rt) async {
    Navigator.of(context).pop(); // Sheet schliessen
    final level = rt.level;
    switch (level.miniType) {
      case GameMiniType.starsPath:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                StarsPathGame(appState: widget.appState, level: level),
          ),
        );
      case GameMiniType.numberHouse:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                NumberHouseGame(appState: widget.appState, level: level),
          ),
        );
      case GameMiniType.colorBoxes:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ColorBoxesGame(appState: widget.appState, level: level),
          ),
        );
      case GameMiniType.letterFill:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                LetterFillGame(appState: widget.appState, level: level),
          ),
        );
      case GameMiniType.numberPath:
      case GameMiniType.wordForest:
      case GameMiniType.mixedQuiz:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${level.miniType.germanLabel} - bald spielbar! Das Spiel kommt im naechsten Update.',
            ),
            backgroundColor: LumoColors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
    }
    // Nach Rueckkehr: Fortschritt neu laden damit neue Sterne sichtbar sind.
    await _load();
  }

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final runtime = _repo.buildRuntime(_stars);
    final totalStars = runtime.fold<int>(0, (sum, r) => sum + r.starsEarned);
    final maxStars = GameLevelCatalog.playableLevels.fold<int>(
      0,
      (s, l) => s + l.maxStars,
    );
    final unlockedCount = runtime.where((r) => !r.locked).length;

    final content = !_loaded
        ? const Center(
            child: CircularProgressIndicator(color: LumoVisualTokens.cyan),
          )
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _GamesHero(reduceMotion: _reduceMotion),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                sliver: SliverToBoxAdapter(
                  child: _GameGrid(
                    onMemory: _launchMemory,
                    onLumoCards: _launchLumoCards,
                    onConnectFour: _launchConnectFour,
                    onDiceRace: _launchDiceRace,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                sliver: SliverToBoxAdapter(
                  child: _KartWideCard(
                    launching: _launchingGame,
                    onPlay: () => _launch3D('kart'),
                    options: _kartOptions(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Text(
                    'Mehr Abenteuer',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _AdventureCard(onPlay: _launchAdventure),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: _VsLumoCard(
                    title: 'Wolkeninseln · 3D-Jump',
                    subtitle: 'Springe mit Lumo von Insel zu Insel',
                    emoji: '☁️',
                    gradient: const [
                      Color(0xFF41A993),
                      Color(0xFF237568),
                    ],
                    onPlay: () => _launch3D('jump'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _HeaderStrip(
                  totalStars: totalStars,
                  maxStars: maxStars,
                  unlockedCount: unlockedCount,
                  levelCount: runtime.length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                sliver: SliverToBoxAdapter(
                  child: _LevelMap(runtime: runtime, onTap: _onLevelTap),
                ),
              ),
            ],
          );
    return widget.drawBackground
        ? LumoSceneBackground(
            scene: LumoScene.games,
            showPlaceholderLabel: false,
            dimmed: true,
            child: content,
          )
        : content;
  }

  /// Klasse und Fach, mit denen das Kart startet (für ältere Kart-Stände).
  Widget _kartOptions() {
    Widget dropdown<T>({
      required Key key,
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?>? onChanged,
    }) =>
        DropdownButton<T>(
          key: key,
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: LumoVisualTokens.navigation,
          iconEnabledColor: LumoVisualTokens.cyanBright,
          underline: const SizedBox.shrink(),
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: LumoVisualTokens.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        );
    return Wrap(spacing: 14, runSpacing: 0, children: [
      dropdown<int>(
        key: const ValueKey('kart-grade'),
        value: _kartGrade ?? widget.appState.state.grade,
        items: [
          for (var grade = 1; grade <= 4; grade++)
            DropdownMenuItem(value: grade, child: Text('$grade. Klasse'))
        ],
        onChanged:
            _launchingGame ? null : (grade) => _saveKartOptions(grade: grade),
      ),
      dropdown<String>(
        key: const ValueKey('kart-subject'),
        value: _kartSubject ?? 'Mathematik',
        items: [
          for (final subject in const [
            'Mathematik',
            'Deutsch',
            'Sachunterricht',
            'Logik'
          ])
            DropdownMenuItem(value: subject, child: Text(subject))
        ],
        onChanged: _launchingGame
            ? null
            : (subject) => _saveKartOptions(subject: subject),
      ),
    ]);
  }
}

// ─────────────────── KOPF: Lumo Spielewelt (Bild 06) ───────────────────

class _GamesHero extends StatelessWidget {
  const _GamesHero({required this.reduceMotion});
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = (width * .5).clamp(170.0, 270.0);
      final foxSize = height * 1.12;
      Widget fox = LumoFoxPose(pose: LumoDesignFoxPose.armsOpen, size: foxSize);
      if (!reduceMotion) {
        fox = LumoFloating(
          amplitude: 4,
          duration: const Duration(milliseconds: 2600),
          child: fox,
        );
      }
      return SizedBox(
        height: height,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: width * .3,
            bottom: -foxSize * .08,
            child: RepaintBoundary(child: fox),
          ),
          Positioned(
            left: 14,
            top: height * .12,
            width: width * .44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Lumo Spielewelt',
                  excludeSemantics: true,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lumo\nSpielewelt',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 32,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: LumoVisualTokens.cyan, blurRadius: 14),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Transform.rotate(
                  angle: -.04,
                  child: const Text(
                    'Spannende Spiele.\nStarkes Wissen.\nMit Lumo!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Color(0xAA000000), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: height * .08,
            width: width * .3,
            child: Transform.rotate(
              angle: -.06,
              child: const LumoHeroBubble(
                text: 'Welches Spiel möchtest du heute spielen?',
                handwritten: true,
              ),
            ),
          ),
        ]),
      );
    });
  }
}

// ─────────────────── SPIELKARTEN 2×2 ───────────────────

class _GameGrid extends StatelessWidget {
  const _GameGrid({
    required this.onMemory,
    required this.onLumoCards,
    required this.onConnectFour,
    required this.onDiceRace,
  });

  final VoidCallback onMemory;
  final VoidCallback onLumoCards;
  final VoidCallback onConnectFour;
  final VoidCallback onDiceRace;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _GameTile(
        title: 'Memory mit Lumo',
        subtitle: 'Finde alle Paare!',
        art: const _MemoryArt(),
        onPlay: onMemory,
      ),
      _GameTile(
        title: 'Lumo Cards',
        subtitle: 'Karten-Duell gegen Lumo!',
        art: const _CardsArt(),
        onPlay: onLumoCards,
      ),
      _GameTile(
        title: 'Vier gewinnt',
        subtitle: 'Baue zuerst eine Reihe aus 4!',
        art: const _ConnectFourArt(),
        onPlay: onConnectFour,
      ),
      _GameTile(
        title: 'Würfel-Wettlauf',
        subtitle: 'Wer ist zuerst am Stern?',
        art: const _IconArt(
            Icons.casino_rounded, [Color(0xFF34D399), Color(0xFF0B7A5A)]),
        onPlay: onDiceRace,
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 10.0;
      final width = (constraints.maxWidth - gap) / 2;
      final height = (width * .7).clamp(118.0, 190.0) *
          MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final tile in tiles)
          SizedBox(width: width, height: height, child: tile),
      ]);
    });
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.title,
    required this.subtitle,
    required this.art,
    required this.onPlay,
  });

  final String title;
  final String subtitle;
  final Widget art;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPlay,
          child: Ink(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: LumoVisualTokens.glass.withOpacity(.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.6)),
              boxShadow: [
                BoxShadow(
                    color: LumoVisualTokens.cyan.withOpacity(.2),
                    blurRadius: 14),
              ],
            ),
            child: Row(children: [
              Expanded(
                flex: 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: art,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const _PlayPill(label: 'Spielen'),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: const LinearGradient(
            colors: [Color(0xFF2FA8F0), Color(0xFF1466C8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: LumoVisualTokens.cyanBright),
          boxShadow: [
            BoxShadow(
                color: LumoVisualTokens.cyan.withOpacity(.45), blurRadius: 10),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 20),
        ]),
      );
}

/// Lumo mit zwei leuchtenden Memory-Karten (Pfoten-Motiv wie im Bild).
class _MemoryArt extends StatelessWidget {
  const _MemoryArt();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B4BE8), Color(0xFF3A1C8C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(builder: (context, c) {
          final card = c.maxWidth * .36;
          Widget memoryCard(double angle) => Transform.rotate(
                angle: angle,
                child: Container(
                  width: card,
                  height: card * 1.25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3C8DFF), Color(0xFF1846C8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(color: Colors.white, width: 1.6),
                    boxShadow: const [
                      BoxShadow(color: Color(0x9953DDFD), blurRadius: 10),
                    ],
                  ),
                  child: Icon(Icons.pets_rounded,
                      color: Colors.white, size: card * .55),
                ),
              );
          return Stack(children: [
            Positioned(
              left: -c.maxWidth * .08,
              bottom: -c.maxHeight * .04,
              child: LumoFoxPose(
                  pose: LumoDesignFoxPose.thumbWink, size: c.maxHeight * .9),
            ),
            Positioned(
                right: card * .55,
                top: c.maxHeight * .14,
                child: memoryCard(-.18)),
            Positioned(
                right: 4, top: c.maxHeight * .32, child: memoryCard(.16)),
          ]);
        }),
      );
}

class _IconArt extends StatelessWidget {
  const _IconArt(this.icon, this.colors);
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) => Center(
            child: Icon(icon,
                size: c.biggest.shortestSide * .62,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x99FFFFFF), blurRadius: 14),
                ]),
          ),
        ),
      );
}

/// Drei echte Lumo-Cards-Karten im Fächer.
class _CardsArt extends StatelessWidget {
  const _CardsArt();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B2A8C), Color(0xFF121E5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight * .72;
          Widget card(String asset, double angle, double dx) => Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translate(dx)
                  ..rotateZ(angle),
                child: Image.asset(asset, height: h),
              );
          return Center(
            child: Stack(alignment: Alignment.center, children: [
              card('assets/lumo_cards/cards/back/card_back_default.png', -.35,
                  -h * .32),
              card('assets/lumo_cards/cards/red/red_7.png', 0, 0),
              card('assets/lumo_cards/cards/special/color_magic.png', .35,
                  h * .32),
            ]),
          );
        }),
      );
}

/// Kleines Vier-gewinnt-Brett aus Leuchtsteinen.
class _ConnectFourArt extends StatelessWidget {
  const _ConnectFourArt();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D6FE0), Color(0xFF123A8C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomPaint(
          painter: _ConnectFourPainter(),
          child: SizedBox.expand(),
        ),
      );
}

class _ConnectFourPainter extends CustomPainter {
  const _ConnectFourPainter();

  static const _pattern = [
    '.......',
    '...y...',
    '..ry...',
    '.yrry..',
    'ryyrrr.',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final cell =
        math.min((size.width - 2 * pad) / 7, (size.height - 2 * pad) / 5);
    final left = (size.width - cell * 7) / 2;
    final top = (size.height - cell * 5) / 2;
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var row = 0; row < _pattern.length; row++) {
      for (var col = 0; col < 7; col++) {
        final center =
            Offset(left + cell * (col + .5), top + cell * (row + .5));
        final color = switch (_pattern[row][col]) {
          'r' => const Color(0xFFFF4D6D),
          'y' => const Color(0xFFFFD84D),
          _ => const Color(0xFF0B2350),
        };
        if (_pattern[row][col] != '.') {
          canvas.drawCircle(
              center, cell * .48, glow..color = color.withOpacity(.6));
        }
        canvas.drawCircle(center, cell * .4, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────── LUMO KART (breit) ───────────────────

class _KartWideCard extends StatelessWidget {
  const _KartWideCard({
    required this.onPlay,
    required this.launching,
    required this.options,
  });

  final VoidCallback onPlay;
  final bool launching;
  final Widget options;

  @override
  Widget build(BuildContext context) {
    return LumoGlassCard(
      padding: const EdgeInsets.all(6),
      radius: 22,
      child: Column(children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('launch-lumo-kart'),
            borderRadius: BorderRadius.circular(16),
            onTap: launching ? null : onPlay,
            child: SizedBox(
              height: 128 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.7),
              child: Row(children: [
                Expanded(
                  flex: 11,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/lumo_design/cards/game_kart.png',
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorBuilder: (_, error, __) {
                        reportLumoAssetError(
                            'assets/lumo_design/cards/game_kart.png', error);
                        return const Center(
                            child: Icon(Icons.sports_motorsports_rounded,
                                size: 64, color: Color(0xFFFFC46B)));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Lumo Kart',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Lernen auf der Überholspur!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Semantics(
                        button: true,
                        label: 'Losfahren',
                        excludeSemantics: true,
                        child:
                            _PlayPill(label: launching ? 'Lädt …' : 'Spielen'),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: options,
        ),
      ]),
    );
  }
}

// ─────────────────── HEADER ───────────────────

class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip({
    required this.totalStars,
    required this.maxStars,
    required this.unlockedCount,
    required this.levelCount,
  });
  final int totalStars;
  final int maxStars;
  final int unlockedCount;
  final int levelCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
        radius: 20,
        child: Row(
          children: [
            const LumoFoxPose(pose: LumoDesignFoxPose.avatar, size: 52),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lumos Abenteuer',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$unlockedCount von $levelCount Lernlevels offen',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: LumoVisualTokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: LumoVisualTokens.gold, size: 24),
                    const SizedBox(width: 2),
                    Text(
                      '$totalStars',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'von $maxStars',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LumoVisualTokens.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── ADVENTURE-KARTE ───────────────────

class _AdventureCard extends StatefulWidget {
  const _AdventureCard({required this.onPlay});
  final VoidCallback onPlay;

  @override
  State<_AdventureCard> createState() => _AdventureCardState();
}

class _AdventureCardState extends State<_AdventureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final pulse = 0.92 + _ctrl.value * 0.08;
          return GestureDetector(
            onTap: widget.onPlay,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFFF97316), // orange
                    Color(0xFFEC4899), // pink
                    Color(0xFF7C3AED), // lila
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.4 * pulse),
                    blurRadius: 24 * pulse,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animierter Lumo-Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: pulse,
                        child: const Text('🦊', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEU',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('⭐', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lumos Jump Adventure · 2D',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x40000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Spring durch 5 Welten, sammle Sterne, knack die Truhe!',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFFF97316),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────── LEVEL-MAP ───────────────────

class _LevelMap extends StatelessWidget {
  const _LevelMap({required this.runtime, required this.onTap});
  final List<GameLevelRuntime> runtime;
  final ValueChanged<GameLevelRuntime> onTap;

  @override
  Widget build(BuildContext context) {
    // Gruppiert nach Block (1-5), je 10 Level, in gewundenem Pfad.
    final groups = <int, List<GameLevelRuntime>>{};
    for (final rt in runtime) {
      final block = GameLevelCatalog.blockOf(rt.level.id);
      groups.putIfAbsent(block, () => <GameLevelRuntime>[]).add(rt);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in groups.keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
            child: _BlockBanner(
              block: block,
              title: GameLevelCatalog.blockTitle(block),
            ),
          ),
          _PathSegment(levels: groups[block]!, onTap: onTap),
        ],
      ],
    );
  }
}

class _BlockBanner extends StatelessWidget {
  const _BlockBanner({required this.block, required this.title});
  final int block;
  final String title;

  Color _accent() {
    switch (block) {
      case 1:
        return LumoColors.orange;
      case 2:
        return LumoColors.blue;
      case 3:
        return LumoColors.purple;
      case 4:
        return LumoColors.teal;
      default:
        return LumoColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(LumoRadius.pill),
          ),
          child: Text(
            'Block $block',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: LumoVisualTokens.white,
          ),
        ),
      ],
    );
  }
}

/// Ein 10-Level-Pfad als gewundener Schlangenweg.
class _PathSegment extends StatelessWidget {
  const _PathSegment({required this.levels, required this.onTap});
  final List<GameLevelRuntime> levels;
  final ValueChanged<GameLevelRuntime> onTap;

  @override
  Widget build(BuildContext context) {
    // 2 Spalten, abwechselnd links/rechts versetzt fuer Schlangenpfad.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const cellHeight = 96.0;
        return SizedBox(
          height: cellHeight * levels.length / 2 + cellHeight,
          width: width,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, cellHeight * levels.length / 2 + cellHeight),
                painter: _PathPainter(
                  levelCount: levels.length,
                  width: width,
                  cellHeight: cellHeight,
                ),
              ),
              for (var i = 0; i < levels.length; i++)
                Positioned(
                  left: _xFor(i, width),
                  top: i * (cellHeight / 2),
                  child: _LevelCircle(
                    runtime: levels[i],
                    onTap: () => onTap(levels[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _xFor(int i, double width) {
    // Schlangen-Pfad: alle 2 Schritte wechseln zwischen 3 Spalten
    final lane = i % 4;
    const circleSize = 74.0;
    final centers = <double>[
      width * 0.20,
      width * 0.50,
      width * 0.80,
      width * 0.50,
    ];
    return centers[lane] - circleSize / 2;
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.levelCount,
    required this.width,
    required this.cellHeight,
  });
  final int levelCount;
  final double width;
  final double cellHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0xFFFFB347).withOpacity(0.4);
    // Punkte-Linie statt Linie - kindgerechter Pfad-Stil.
    final lanes = <double>[
      width * 0.20,
      width * 0.50,
      width * 0.80,
      width * 0.50,
    ];
    for (var i = 0; i < levelCount - 1; i++) {
      final startX = lanes[i % 4];
      final endX = lanes[(i + 1) % 4];
      final startY = i * (cellHeight / 2) + 37;
      final endY = (i + 1) * (cellHeight / 2) + 37;
      const steps = 6;
      for (var s = 1; s < steps; s++) {
        final t = s / steps;
        final x = startX + (endX - startX) * t;
        final y = startY + (endY - startY) * t;
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => false;
}

class _LevelCircle extends StatelessWidget {
  const _LevelCircle({required this.runtime, required this.onTap});
  final GameLevelRuntime runtime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = runtime.locked;
    final perfect = runtime.isPerfect;
    final isCurrent = runtime.isCurrent;
    const size = 74.0;
    final bg = locked
        ? const Color(0xFFE5E5E5)
        : (perfect ? LumoColors.gold : LumoColors.orange);
    final border = isCurrent ? LumoColors.gold : Colors.white;
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: isCurrent ? 4 : 3),
              boxShadow: [
                if (!locked)
                  BoxShadow(
                    color: bg.withOpacity(isCurrent ? 0.6 : 0.35),
                    blurRadius: isCurrent ? 18 : 10,
                    offset: const Offset(0, 4),
                    spreadRadius: isCurrent ? 1 : 0,
                  ),
              ],
            ),
            alignment: Alignment.center,
            child: locked
                ? const Icon(Icons.lock_rounded, color: Colors.white, size: 28)
                : isCurrent
                    ? const Text('🦊', style: TextStyle(fontSize: 36))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${runtime.level.id}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          if (runtime.starsEarned > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List<Widget>.generate(
                                  math.min(runtime.starsEarned, 3),
                                  (_) => const Text(
                                    '⭐',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
          if (!locked) ...[
            const SizedBox(height: 2),
            Text(
              runtime.level.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: LumoColors.ink700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────── DETAIL-SHEET ───────────────────

class _LevelDetailSheet extends StatelessWidget {
  const _LevelDetailSheet({required this.runtime, required this.onPlay});
  final GameLevelRuntime runtime;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final level = runtime.level;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LumoColors.orangeSurface,
                  borderRadius: BorderRadius.circular(LumoRadius.md),
                ),
                child: Text(
                  level.miniType.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${level.id}: ${level.title}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                      ),
                    ),
                    Text(
                      '${level.subject} · ${level.miniType.germanLabel}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(LumoRadius.sm),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level.learningGoal,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LumoColors.ink700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List<Widget>.generate(level.maxStars, (i) {
              final earned = i < runtime.starsEarned;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  earned ? '⭐' : '☆',
                  style: TextStyle(
                    fontSize: 28,
                    color: earned ? null : LumoColors.ink300,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LumoColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LumoRadius.pill),
                ),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onPlay();
              },
              child: const Text(
                'Level starten',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// MULTIPLAYER-SEKTION: 3 Spiele gegen Lumo als KI-Gegner
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch (Mai 2026):
//   - Memory mit Lumo (12 Paare, jedes genau 2x)
//   - Vier gewinnt mit Lumo (6x7 Brett, Lumo blockt + gewinnt)
//   - Wuerfel-Wettlauf (Mensch-aergere-dich-nicht light, 30 Felder)
// Statt der Kart-Karte. Lumo spielt jeweils aktiv mit, nicht nur Zufall.

class _VsLumoCard extends StatelessWidget {
  const _VsLumoCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.onPlay,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: gradient.last,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
