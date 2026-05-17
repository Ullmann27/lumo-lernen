import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/game_progress_repository.dart';
import '../../domain/games/game_level_catalog.dart';
import '../../domain/games/game_level_playability.dart';
import '../../domain/games/game_level_model.dart';
import '../shared/widgets/lumo_living_world.dart';
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
  const GamesContent({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<GamesContent> createState() => _GamesContentState();
}

class _GamesContentState extends State<GamesContent> {
  static const _repo = GameProgressRepository();

  Map<int, int> _stars = const <int, int>{};
  List<GameLevelRuntime> _runtime = const <GameLevelRuntime>[];
  int _totalStars = 0;
  int _unlockedCount = 0;
  bool _loaded = false;

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.loadStars(_childId);
    if (!mounted) return;
    setState(() {
      _stars = s;
      _runtime = _repo.buildRuntime(_stars);
      _totalStars = _runtime.fold<int>(0, (sum, r) => sum + r.starsEarned);
      _unlockedCount = _runtime.where((r) => !r.locked).length;
      _loaded = true;
    });
  }

  void _onLevelTap(GameLevelRuntime rt) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelDetailSheet(
        runtime: rt,
        onPlay: () => _launchLevel(rt),
      ),
    );
  }

  Future<void> _launchLevel(GameLevelRuntime rt) async {
    Navigator.of(context).pop(); // Sheet schliessen
    final level = rt.level;
    switch (GameLevelPlayability.routeFor(level)) {
      case GamePlayRoute.starsPath:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StarsPathGame(
              appState: widget.appState,
              level: level,
            ),
          ),
        );
      case GamePlayRoute.numberHouse:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NumberHouseGame(
              appState: widget.appState,
              level: level,
            ),
          ),
        );
    }
    // Nach Rueckkehr: Fortschritt neu laden damit neue Sterne sichtbar sind.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final maxStars = GameLevelCatalog.levels.fold<int>(0, (s, l) => s + l.maxStars);

    return LumoLivingWorld(
      starsEarned: _totalStars,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: LumoColors.ink700),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
          ),
          title: const Text(
            'Lumo Spielewelt',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
              fontSize: 20,
            ),
          ),
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator(color: LumoColors.orange))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeaderStrip(
                      totalStars: _totalStars,
                      maxStars: maxStars,
                      unlockedCount: _unlockedCount,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                    sliver: SliverToBoxAdapter(
                      child: _LevelMap(
                        runtime: _runtime,
                        onTap: _onLevelTap,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────── HEADER ───────────────────

class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip({
    required this.totalStars,
    required this.maxStars,
    required this.unlockedCount,
  });
  final int totalStars;
  final int maxStars;
  final int unlockedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E6), Color(0xFFFFE5C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: LumoShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(LumoRadius.md),
              boxShadow: [
                BoxShadow(
                  color: LumoColors.gold.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text('🦊', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 14),
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
                    color: LumoColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$unlockedCount von 50 Levels offen',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: LumoColors.ink600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 4),
                Text(
                  '$totalStars',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
              ]),
              Text(
                'von $maxStars',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: LumoColors.ink500,
                ),
              ),
            ],
          ),
        ],
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
            color: LumoColors.ink900,
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
        final cellHeight = 96.0;
        return SizedBox(
          height: cellHeight * levels.length / 2 + cellHeight,
          width: width,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, cellHeight * levels.length / 2 + cellHeight),
                painter: _PathPainter(levelCount: levels.length, width: width, cellHeight: cellHeight),
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
  _PathPainter({required this.levelCount, required this.width, required this.cellHeight});
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
    final bg = locked ? const Color(0xFFE5E5E5) : (perfect ? LumoColors.gold : LumoColors.orange);
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
                                  (_) => const Text('⭐', style: TextStyle(fontSize: 10)),
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
                child: Text(level.miniType.emoji, style: const TextStyle(fontSize: 28)),
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
                  style: TextStyle(fontSize: 28, color: earned ? null : LumoColors.ink300),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onPlay();
              },
              child: const Text(
                'Level starten',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
