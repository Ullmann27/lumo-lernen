import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/games/game_world.dart';
import 'spielwelt_routes.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';

/// Ein Spielportal der Spielwelt: Spiel, Freischaltung und was beim Tippen
/// passiert. Ob es offen ist, sagt [state] aus der Domain, nie das Portal.
class SpielweltPortal {
  const SpielweltPortal({
    required this.game,
    required this.state,
    required this.onOpen,
    this.semanticTitle,
    this.specialId,
  });

  /// The quiz is a genuine route, never an alias for GameId.kart.
  const SpielweltPortal.quizShow({required this.onOpen})
      : game = null,
        state = const GameUnlockState(unlocked: true),
        semanticTitle = 'Wer wird Lumo-Meister?',
        specialId = 'quizShow';

  /// Vier Gewinnt is a first-class game in the hub reference, not a hidden
  /// extra-mode tile. It keeps its existing Flutter game/session intact.
  const SpielweltPortal.connectFour({required this.onOpen})
      : game = null,
        state = const GameUnlockState(unlocked: true),
        semanticTitle = 'Lumo 4 Gewinnt',
        specialId = 'connectFour';

  final GameDefinition? game;
  final GameUnlockState state;
  final VoidCallback onOpen;
  final String? specialId;

  String get identity => game?.id.name ?? specialId ?? 'special';
  /// Visible hub-tile label. Product names stay on [semanticTitle].
  String get title {
    switch (identity) {
      case 'quizShow':
        return 'Quizshow';
      case 'connectFour':
        return '4 Gewinnt';
      case 'rhythm':
        return 'Rhythm';
      default:
        break;
    }
    try {
      return SpielweltRoutes.byIdentity(identity).title;
    } catch (_) {
      return game?.title ?? 'Lumo Spiel';
    }
  }
  String get tagline => switch (specialId) {
        'connectFour' => 'Vier in einer Reihe · gegen Lumo oder zu zweit',
        'quizShow' => '20 Fragen · 3 Joker · bis 5.000 Sterne',
        _ => game?.tagline ?? '',
      };
  bool get playable =>
      specialId != null || game?.availability == GameAvailability.playable;
  IconData get icon => switch (specialId) {
        'connectFour' => Icons.grid_4x4_rounded,
        'quizShow' => Icons.emoji_events_rounded,
        _ => _iconFor(game!.id),
      };

  /// Vorleser- und Prüftext, falls er vom sichtbaren Titel abweicht.
  final String? semanticTitle;
}

/// Lumo Spielwelt nach Bild 01: Logo, sieben schwebende Glas-Portale,
/// Lumo in der Mitte, „Auf ins Abenteuer!“ und die Leiste unten.
class SpielweltHub extends StatefulWidget {
  const SpielweltHub({
    super.key,
    required this.portals,
    required this.onAdventure,
    required this.onHome,
    required this.onLearn,
    required this.onTests,
    required this.onParents,
    required this.onProgress,
    required this.onSettings,
    this.reduceMotion = false,
  });

  final List<SpielweltPortal> portals;
  final VoidCallback onAdventure;
  final VoidCallback onHome;
  final VoidCallback onLearn;
  final VoidCallback onTests;
  final VoidCallback onParents;
  final VoidCallback onProgress;
  final VoidCallback onSettings;
  final bool reduceMotion;

  @override
  State<SpielweltHub> createState() => _SpielweltHubState();
}

class _SpielweltHubState extends State<SpielweltHub>
    with SingleTickerProviderStateMixin {
  // Ein gemeinsamer Takt für Glühen, Funkeln und lebende Vorschauen.
  late final AnimationController _clock = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000));
  final LumoCharacterController _lumo = LumoCharacterController();

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _clock.repeat();
  }

  @override
  void didUpdateWidget(SpielweltHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _clock.isAnimating) {
      _clock.stop();
    } else if (!widget.reduceMotion && !_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _lumo.dispose();
    super.dispose();
  }

  Widget _portal(
    SpielweltPortal portal,
    int index, {
    double? width,
    _PortalChrome chrome = _PortalChrome.card,
  }) =>
      _GlassPortal(
        key: ValueKey('spielwelt-portal-${portal.identity}'),
        portal: portal,
        clock: _clock,
        phase: index / math.max(1, widget.portals.length),
        chrome: chrome,
        reduceMotion: widget.reduceMotion,
        onTap: () {
          if (portal.state.unlocked &&
              portal.playable) {
            _lumo.cheer();
          }
          portal.onOpen();
        },
      );

  Widget _fox(double size) => LumoCharacter(
        key: const ValueKey('spielwelt-lumo'),
        pose: LumoDesignFoxPose.spielweltWave,
        celebratePose: LumoDesignFoxPose.spielweltJump,
        size: size,
        shadow: false,
        reduceMotion: widget.reduceMotion,
        controller: _lumo,
        onTap: _lumo.cheer,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = MediaQuery.sizeOf(context).height;
      return _buildTiles(width, height);
    });
  }

  // Hochformat (Handy, Fold zu): Logo, Lumo mit Knopf, Portale in Spalten.
  Widget _buildTiles(double width, double viewportHeight) {
    final columns = SpielweltLayout.tileColumns(width);
    const gap = 12.0;
    final tileWidth = (width - 24 - gap * (columns - 1)) / columns;
    final tileHeight = tileWidth * 0.92;
    var foxSize = math.min(width * .62, 300.0);
    var logoHeight = math.min(width * .42, 190.0);
    // Leave a strip of the first tile row visible on short / landscape
    // canvases (Fold open landscape is only 560 dp tall).
    final peek = math.min(tileHeight * 0.62, viewportHeight * 0.32);
    const chrome = 10 + 60 + 16 + 28;
    final budget = viewportHeight - peek - chrome;
    final natural = logoHeight + foxSize * 1.08;
    if (viewportHeight.isFinite &&
        viewportHeight > 0 &&
        budget > 160 &&
        natural > budget) {
      final scale = (budget / natural).clamp(0.52, 1.0);
      logoHeight *= scale;
      foxSize *= scale;
    }
    final reduce = widget.reduceMotion;
    final content = Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: logoHeight,
        child: _HubLogo(clock: _clock, compact: true),
      ),
      SizedBox(
        height: foxSize * 1.08,
        child: Stack(alignment: Alignment.bottomCenter, children: [
          // Soft contact shadow + rim light sit behind Lumo, no blur stack.
          Positioned(
            bottom: foxSize * .02,
            child: IgnorePointer(
              child: Container(
                width: foxSize * 1.18,
                height: foxSize * .20,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(colors: [
                    Color(0x99010A22),
                    Color(0x00010A22),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: foxSize * .10,
            child: IgnorePointer(
              child: Container(
                width: foxSize * 0.98,
                height: foxSize * 1.02,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x8853DDFD),
                      Color(0x33FFD86B),
                      Color(0x00000000),
                    ],
                    stops: [0.32, 0.62, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            width: foxSize * 1.1,
            height: foxSize * .22,
            child: const _StoneStage(),
          ),
          Positioned(bottom: foxSize * .06, child: _fox(foxSize * .92)),
        ]),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 60,
        width: math.min(width - 24, 380),
        child: _AdventureButton(clock: _clock, onTap: widget.onAdventure),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: gap, runSpacing: gap, children: [
        for (var i = 0; i < widget.portals.length; i++)
          SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: _portal(widget.portals[i], i, width: tileWidth),
          ),
      ]),
      const SizedBox(height: 14),
      _HubBar(
        onParents: widget.onParents,
        onProgress: widget.onProgress,
        onSettings: widget.onSettings,
        showSlogans: width >= 360,
      ),
    ]);
    return Padding(
      key: const ValueKey('spielwelt-narrow-hub'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: reduce
                  ? const CustomPaint(
                      painter: _DepthLayerPainter(t: 0),
                      child: SizedBox.expand(),
                    )
                  : AnimatedBuilder(
                      animation: _clock,
                      builder: (context, _) => CustomPaint(
                        painter: _DepthLayerPainter(t: _clock.value),
                        child: const SizedBox.expand(),
                      ),
                    ),
            ),
          ),
        ),
        if (!reduce)
          Positioned.fill(child: _Sparkles(clock: _clock)),
        content,
      ]),
    );
  }
}

class _HubLogo extends StatelessWidget {
  const _HubLogo({required this.clock, required this.compact});
  final Animation<double> clock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Lumo Spielewelt',
      header: true,
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, c) {
        final subtitleSize = (c.maxWidth * .028).clamp(9.0, 15.0);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _OrbitPainter(clock)),
                ),
              ),
              Image.asset(
                'assets/lumo_design/spielwelt/logo_spielwelt.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.star_rounded,
                          size: subtitleSize * 1.2,
                          color: LumoVisualTokens.gold),
                    ),
                  Text(
                    const ['SPIELEN', 'ENTDECKEN', 'WACHSEN'][i],
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: subtitleSize,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                      shadows: const [
                        Shadow(color: Color(0xCC0A2A66), blurRadius: 6),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ]);
      }),
    );
  }
}

/// Goldene Umlaufbahn mit wanderndem Funken um das Logo.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.clock) : super(repaint: clock);
  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero).translate(0, -size.height * .02),
      width: size.width * .98,
      height: size.height * .62,
    );
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-.09);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = const SweepGradient(colors: [
        Color(0x00FFC94A),
        Color(0xFFFFD86B),
        Color(0x55FFC94A),
        Color(0xFFFFE9A6),
        Color(0x00FFC94A),
      ]).createShader(rect);
    canvas.drawOval(rect, ring);
    final t = clock.value * 2 * math.pi;
    final spark = Offset(
      rect.center.dx + math.cos(t) * rect.width / 2,
      rect.center.dy + math.sin(t) * rect.height / 2,
    );
    canvas.drawCircle(
        spark,
        7,
        Paint()
          ..color = const Color(0x88FFE08A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(spark, 2.6, Paint()..color = const Color(0xFFFFF6D8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}

// ─────────────────────────── Portale ───────────────────────────

IconData _iconFor(GameId id) => switch (id) {
      GameId.memory => Icons.psychology_alt_rounded,
      GameId.cards => Icons.style_rounded,
      GameId.puzzle => Icons.extension_rounded,
      GameId.jumpRun => Icons.directions_run_rounded,
      GameId.rhythm => Icons.music_note_rounded,
      GameId.treasure => Icons.explore_rounded,
      GameId.build => Icons.view_in_ar_rounded,
      GameId.kart => Icons.sports_motorsports_rounded,
    };

String _artFor(SpielweltPortal portal) {
  if (portal.identity == 'puzzle') {
    return 'assets/lumo_design/spielwelt/portal_puzzle.png';
  }
  final cover = SpielweltRoutes.coverFor(portal.identity);
  if (cover.isNotEmpty) return cover;
  return switch (portal.game?.id) {
    GameId.memory => 'assets/lumo_design/spielwelt/portal_memory.png',
    GameId.cards => 'assets/lumo_design/spielwelt/portal_cards.png',
    GameId.puzzle => 'assets/lumo_design/spielwelt/portal_puzzle.png',
    GameId.jumpRun => 'assets/lumo_design/spielwelt/portal_jump_run.png',
    GameId.rhythm => 'assets/lumo_design/spielwelt/portal_rhythm.png',
    GameId.treasure => 'assets/lumo_design/spielwelt/portal_schatzsuche.png',
    GameId.build => 'assets/lumo_design/spielwelt/portal_bauwelt.png',
    GameId.kart => 'assets/lumo_design/gameplay/kart_sonnenhafen_preview.webp',
    _ => 'assets/lumo_design/fox/fox_quiz_host_1982.webp',
  };
}

enum _PortalChrome { card }

class _GlassPortal extends StatefulWidget {
  const _GlassPortal({
    super.key,
    required this.portal,
    required this.clock,
    required this.phase,
    required this.onTap,
    this.chrome = _PortalChrome.card,
    this.reduceMotion = false,
  });

  final SpielweltPortal portal;
  final Animation<double> clock;
  final double phase;
  final VoidCallback onTap;
  final _PortalChrome chrome;
  final bool reduceMotion;

  @override
  State<_GlassPortal> createState() => _GlassPortalState();
}

class _GlassPortalState extends State<_GlassPortal> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final portal = widget.portal;
    final open = portal.state.unlocked;
    final playable = portal.playable;
    final status = !playable
        ? 'Kommt bald'
        : open
            ? 'Spielen'
            : 'Noch gesperrt';
    return Semantics(
      button: true,
      label: '${portal.semanticTitle ?? portal.title}. ${portal.tagline} $status',
      excludeSemantics: true,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _pressed ? 1 : 0),
          duration: widget.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          builder: (context, press, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0013)
                ..rotateX(0.055 * press)
                ..translate(0.0, 5.0 * press)
                ..scale(1 - 0.02 * press),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: widget.clock,
            builder: (context, child) {
              if (widget.reduceMotion) return child!;
              final wave =
                  math.sin((widget.clock.value + widget.phase) * 2 * math.pi);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateY(wave * 0.025)
                  ..translate(0.0, wave * 1.6),
                child: child,
              );
            },
            child: _PortalChromeBox(
              chrome: widget.chrome,
              portal: portal,
              pressed: _pressed,
              highlighted: _hovered || _focused,
              preview: _LivePreview(
                portal: portal,
                clock: widget.clock,
                phase: widget.phase,
              ),
              lockedChip: (!open || !playable)
                  ? _StatusChip(
                      locked: !open,
                      text: playable ? 'Gesperrt' : 'Bald',
                    )
                  : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
            ),
          ),
        ),
      ),
    );
  }
}


class _PortalChromeBox extends StatelessWidget {
  const _PortalChromeBox({
    required this.chrome,
    required this.portal,
    required this.preview,
    required this.pressed,
    required this.highlighted,
    required this.onHighlightChanged,
    required this.onTap,
    this.lockedChip,
  });

  final _PortalChrome chrome;
  final SpielweltPortal portal;
  final Widget preview;
  final bool pressed;
  final bool highlighted;
  final ValueChanged<bool> onHighlightChanged;
  final VoidCallback onTap;
  final Widget? lockedChip;

  @override
  Widget build(BuildContext context) {
    return _card();
  }

  Widget _card() {
    const radius = 26.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A8AE0),
            Color(0xFF134A9C),
            Color(0xFF071E52),
          ],
          stops: [0, 0.46, 1],
        ),
        border: Border.all(
          color: highlighted ? const Color(0xFFF5FDFF) : const Color(0xCC8EE9FF),
          width: highlighted ? 2.6 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x99010A22),
            blurRadius: pressed ? 6 : 18,
            offset: Offset(0, pressed ? 3 : 11),
          ),
          BoxShadow(
            color: highlighted
                ? const Color(0xCC53DDFD)
                : const Color(0x6637D2FD),
            blurRadius: highlighted ? 22 : (pressed ? 8 : 14),
            offset: Offset(0, pressed ? 2 : 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
            child: Column(children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x99010A22),
                      width: 1.4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(fit: StackFit.expand, children: [
                      preview,
                      if (lockedChip != null)
                        Positioned(top: 6, right: 6, child: lockedChip!),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              _PortalLabel(portal: portal),
            ]),
          ),
          const _GlassRim(),
          Positioned.fill(
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              splashColor: const Color(0x88FFFFFF),
              highlightColor: const Color(0x3353DDFD),
              onHighlightChanged: onHighlightChanged,
              onTap: onTap,
            ),
          ),
        ]),
      ),
    );
  }
}

/// Lebende Vorschau: jede Welt bewegt sich auf ihre Art.
class _LivePreview extends StatelessWidget {
  const _LivePreview(
      {required this.portal, required this.clock, required this.phase});
  final SpielweltPortal portal;
  final Animation<double> clock;
  final double phase;

  GameId? get game => portal.game?.id;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      _artFor(portal),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: clock,
        child: image,
        builder: (context, child) {
          final t = (clock.value + phase) % 1.0;
          final s = math.sin(t * 2 * math.pi);
          final Matrix4 m = switch (game) {
            // Karten drehen sich leicht.
            GameId.memory => Matrix4.identity()
              ..setEntry(3, 2, .0012)
              ..rotateY(s * .10)
              ..scale(1.08),
            // Karten schweben.
            GameId.cards => Matrix4.identity()
              ..translate(0.0, s * 3)
              ..scale(1.08),
            // Puzzleteile ziehen sich zusammen.
            GameId.puzzle => Matrix4.identity()..scale(1.06 + .03 * s),
            // Lumo läuft über die Inseln.
            GameId.jumpRun => Matrix4.identity()
              ..translate(s * 6, -(s.abs()) * 3)
              ..scale(1.1),
            // Musikfelder pulsieren im Takt (zwei Schläge pro Runde).
            GameId.rhythm =>
              Matrix4.identity()..scale(1.06 + .025 * math.sin(t * 8 * math.pi).abs()),
            // Bausteine wippen.
            GameId.build => Matrix4.identity()
              ..translate(0.0, -s.abs() * 3)
              ..scale(1.08),
            _ => Matrix4.identity()..scale(1.06),
          };
          return Stack(fit: StackFit.expand, children: [
            Transform(
              alignment: Alignment.center,
              transform: m,
              child: child,
            ),
            if (portal.specialId == 'quizShow' ||
                game == GameId.treasure ||
                game == GameId.rhythm)
              CustomPaint(
                painter: _GlitterPainter(
                  t: t,
                  color: game == GameId.rhythm
                      ? const Color(0xFFFF8BE8)
                      : const Color(0xFFFFE08A),
                ),
              ),
            // Weicher Übergang in das Glas unten.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [.55, 1],
                  colors: [Color(0x00000000), Color(0xDD0A2A66)],
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _GlitterPainter extends CustomPainter {
  _GlitterPainter({required this.t, required this.color});
  final double t;
  final Color color;

  static const _spots = [
    Offset(.52, .38),
    Offset(.62, .30),
    Offset(.44, .52),
    Offset(.70, .48),
    Offset(.35, .30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _spots.length; i++) {
      final a = math.sin((t * 3 + i / _spots.length) * 2 * math.pi);
      if (a <= 0) continue;
      final p = Offset(_spots[i].dx * size.width, _spots[i].dy * size.height);
      final r = 2 + 4 * a;
      final paint = Paint()..color = color.withOpacity(.85 * a);
      canvas.drawCircle(p, r * .5, paint);
      canvas.drawRect(Rect.fromCenter(center: p, width: r * 3, height: 1.2),
          paint);
      canvas.drawRect(Rect.fromCenter(center: p, width: 1.2, height: r * 3),
          paint);
    }
  }

  @override
  bool shouldRepaint(_GlitterPainter old) => old.t != t;
}

class _PortalLabel extends StatelessWidget {
  const _PortalLabel({required this.portal});
  final SpielweltPortal portal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final scale = (c.maxWidth / 260).clamp(.62, 1.15);
      final disc = 40 * scale;
      final play = 34 * scale;
      return Container(
        padding: EdgeInsets.fromLTRB(5 * scale, 5 * scale, 5 * scale, 5 * scale),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A62C0), Color(0xFF082455)],
          ),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: const Color(0xAA8EE9FF), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0x66010A22),
              blurRadius: 4 * scale,
              offset: Offset(0, 2 * scale),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B3A7E),
              border: Border.all(
                  color: LumoVisualTokens.cyanBright, width: 2.0 * scale),
              boxShadow: [
                BoxShadow(
                    color: LumoVisualTokens.cyan.withOpacity(.55),
                    blurRadius: 8 * scale),
              ],
            ),
            child: Icon(portal.icon,
                color: LumoVisualTokens.white, size: disc * .56),
          ),
          SizedBox(width: 7 * scale),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    portal.title,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17 * scale,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                      shadows: const [
                        Shadow(color: Color(0xAA37D2FD), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    portal.tagline,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.left,
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.2),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11 * scale,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE6F4FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6 * scale),
          Container(
            width: play,
            height: play,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7BEBFF), Color(0xFF1578D0)],
              ),
              border: Border.all(
                  color: const Color(0xEEFFFFFF), width: 1.4 * scale),
              boxShadow: [
                BoxShadow(
                  color: LumoVisualTokens.cyan.withOpacity(.5),
                  blurRadius: 7 * scale,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
            child: Icon(Icons.play_arrow_rounded,
                color: LumoVisualTokens.white, size: play * .68),
          ),
        ]),
      );
    });
  }
}

class _GlassRim extends StatelessWidget {
  const _GlassRim();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
        child: CustomPaint(
          painter: _GlassBevelPainter(),
          child: SizedBox.expand(),
        ),
      );
}

class _GlassBevelPainter extends CustomPainter {
  const _GlassBevelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(26));
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF7FFFFFF), Color(0xCC53DDFD), Color(0x99010A22)],
          stops: [0, 0.42, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      outer.deflate(2.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = const LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Color(0x66FFFFFF), Color(0x22010A22)],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipRRect(outer);
    final sheen = Rect.fromLTWH(3, 2, size.width - 6, size.height * 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheen, const Radius.circular(22)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
        ).createShader(sheen),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.locked, required this.text});
  final bool locked;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xE6061A44),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: LumoVisualTokens.gold),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(locked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
              size: 13, color: LumoVisualTokens.gold),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white,
              )),
        ]),
      );
}

// ─────────────────────── Knopf, Leiste, Deko ───────────────────────

class _AdventureButton extends StatefulWidget {
  const _AdventureButton({required this.clock, required this.onTap});
  final Animation<double> clock;
  final VoidCallback onTap;

  @override
  State<_AdventureButton> createState() => _AdventureButtonState();
}

class _AdventureButtonState extends State<_AdventureButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Auf ins Abenteuer!',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('spielwelt-adventure'),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .95 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedBuilder(
            animation: widget.clock,
            builder: (context, child) {
              final pulse =
                  (math.sin(widget.clock.value * 4 * math.pi) + 1) / 2;
              return Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF63E4FF),
                      Color(0xFF1E9BE8),
                      Color(0xFF1466C8)
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFBDF4FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: LumoVisualTokens.cyan.withOpacity(.45 + .3 * pulse),
                      blurRadius: 16 + 10 * pulse,
                      spreadRadius: 1 + 2 * pulse,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Stack(fit: StackFit.expand, children: [
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              LayoutBuilder(builder: (context, c) {
                final h = c.maxHeight.isFinite ? c.maxHeight : 56.0;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: h * .4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: h * .78),
                      SizedBox(width: h * .12),
                      Text(
                        'Auf ins Abenteuer!',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: h * .4,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Color(0x88083A80), blurRadius: 4),
                          ],
                        ),
                      ),
                    ]),
                  ),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HubBar extends StatelessWidget {
  const _HubBar({
    required this.onParents,
    required this.onProgress,
    required this.onSettings,
    required this.showSlogans,
  });

  final VoidCallback onParents;
  final VoidCallback onProgress;
  final VoidCallback onSettings;
  final bool showSlogans;

  @override
  Widget build(BuildContext context) {
    Widget slogan(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: LumoVisualTokens.white,
                )),
          ]),
        );
    Widget action(String key, IconData icon, String label, VoidCallback onTap) =>
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            key: ValueKey(key),
            onTap: onTap,
            radius: 36,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: LumoVisualTokens.cyanBright, size: 24),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: LumoVisualTokens.white,
                    )),
              ]),
            ),
          ),
        );
    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
      action('spielwelt-parents', Icons.groups_rounded, 'Elternbereich',
          onParents),
      action('spielwelt-progress', Icons.bar_chart_rounded, 'Fortschritt',
          onProgress),
      action('spielwelt-settings', Icons.settings_rounded, 'Einstellungen',
          onSettings),
    ]);
    final slogans = Row(mainAxisSize: MainAxisSize.min, children: [
      slogan(Icons.star_rounded, LumoVisualTokens.gold, 'Spielerisch lernen.'),
      slogan(Icons.eco_rounded, const Color(0xFF7BE08C), 'Neues entdecken.'),
      slogan(Icons.favorite_rounded, const Color(0xFFFF8A6B), 'Stärker werden.'),
    ]);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC061A44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x9937D2FD), width: 1.4),
        boxShadow: [
          BoxShadow(color: LumoVisualTokens.cyan.withOpacity(.22), blurRadius: 14),
        ],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final inline = showSlogans && c.maxWidth >= 640;
        if (inline) {
          return Row(children: [
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: slogans,
              ),
            ),
            FittedBox(fit: BoxFit.scaleDown, child: actions),
          ]);
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (showSlogans)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: slogans,
              ),
            actions,
          ]),
        );
      }),
    );
  }
}

/// Fels-Bühne unter Lumo mit Cyan-Schimmer an der Kante.
class _StoneStage extends StatelessWidget {
  const _StoneStage();

  @override
  Widget build(BuildContext context) =>
      const IgnorePointer(child: CustomPaint(painter: _StagePainter()));
}

class _StagePainter extends CustomPainter {
  const _StagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final top = Rect.fromLTWH(
        size.width * .04, size.height * .05, size.width * .92, size.height * .55);
    final body = Path()
      ..moveTo(top.left, top.center.dy)
      ..lineTo(top.left + size.width * .06, size.height)
      ..lineTo(top.right - size.width * .06, size.height)
      ..lineTo(top.right, top.center.dy)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF34405E), Color(0xFF141B33)],
          ).createShader(Offset.zero & size));
    canvas.drawOval(
        top,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFF7D8AA8), Color(0xFF4A5677), Color(0xFF2B3552)],
            stops: [0, .6, 1],
          ).createShader(top));
    canvas.drawOval(
        top,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x7737D2FD)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) => false;
}

/// Far/mid orbs that drift slower than the sparkles (cheap radial fills,
/// no BackdropFilter and no stacked blur).
class _DepthLayerPainter extends CustomPainter {
  const _DepthLayerPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final sway = t * 2 * math.pi;
    void orb(Offset c, double r, List<Color> colors) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: colors).createShader(
            Rect.fromCircle(center: c, radius: r),
          ),
      );
    }
    orb(
      Offset(size.width * (0.16 + 0.03 * math.sin(sway * 0.6)),
          size.height * 0.20),
      size.width * 0.34,
      const [Color(0x3348B4F0), Color(0x00000000)],
    );
    orb(
      Offset(size.width * (0.86 + 0.02 * math.cos(sway * 0.45)),
          size.height * 0.16),
      size.width * 0.24,
      const [Color(0x28FFD86B), Color(0x00000000)],
    );
    orb(
      Offset(size.width * 0.72,
          size.height * (0.58 + 0.025 * math.sin(sway * 0.35))),
      size.width * 0.40,
      const [Color(0x241050C0), Color(0x00000000)],
    );
  }

  @override
  bool shouldRepaint(_DepthLayerPainter old) => old.t != t;
}

/// Funkelnde Sterne über der Szene.
class _Sparkles extends StatelessWidget {
  const _Sparkles({required this.clock});
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: _SparklePainter(clock)),
        ),
      );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.clock) : super(repaint: clock);
  final Animation<double> clock;

  static final List<Offset> _points = () {
    final r = math.Random(7);
    return List.generate(26, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }();

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _points.length; i++) {
      final a = (math.sin((clock.value * 2 + i * .37) * 2 * math.pi) + 1) / 2;
      final p = Offset(_points[i].dx * size.width, _points[i].dy * size.height);
      final gold = i % 3 == 0;
      canvas.drawCircle(
          p,
          1.1 + 1.8 * a,
          Paint()
            ..color = (gold ? const Color(0xFFFFE08A) : const Color(0xFFBDF4FF))
                .withOpacity(.25 + .6 * a));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => false;
}

class _WoodSign extends StatelessWidget {
  const _WoodSign({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7A5435), Color(0xFF4E3220)],
            ),
            border: Border.all(color: const Color(0xFF2E1D12), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFF1DC),
                ),
              ),
              const Icon(Icons.favorite_border_rounded,
                  size: 14, color: Color(0xFFFFC27A)),
            ]),
          ),
        ),
      );
}

class _PaperBanner extends StatelessWidget {
  const _PaperBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Transform.rotate(
          angle: .06,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECDD),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0x88000000), blurRadius: 6),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B3B78),
                  ),
                ),
                const Icon(Icons.favorite_rounded,
                    size: 14, color: Color(0xFF1B6FE0)),
              ]),
            ),
          ),
        ),
      );
}

class _HandNote extends StatelessWidget {
  const _HandNote();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Transform.rotate(
          angle: -.22,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Kleine\nSpiele.\nGroße\nAbenteuer!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                height: 1.05,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEAF6FF),
                shadows: [Shadow(color: Color(0xAA37D2FD), blurRadius: 8)],
              ),
            ),
          ),
        ),
      );
}
