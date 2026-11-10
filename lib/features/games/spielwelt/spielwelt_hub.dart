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
  String get title => switch (specialId) {
        'connectFour' => '4 Gewinnt',
        'quizShow' => 'Wer wird Lumo-Meister?',
        _ => game?.title ?? 'Lumo Spiel',
      };
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

/// Lage der Elemente im Bild 01 (1672 × 941) als Anteile von Breite/Höhe.
class _Frac {
  const _Frac(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

const double _refAspect = 1672 / 941;

/// Landscape / Fold-open-quer composition, close to reference page 34.
/// Slots were chosen so neighbouring portals do not overlap.
const Map<String, _Frac> _landscapeSlots = {
  'cards': _Frac(.235, .140, .145, .200),
  'puzzle': _Frac(.425, .085, .150, .200),
  'jumpRun': _Frac(.620, .140, .145, .200),
  'rhythm': _Frac(.760, .305, .145, .200),
  'memory': _Frac(.155, .305, .145, .200),
  'treasure': _Frac(.180, .525, .155, .185),
  'build': _Frac(.665, .525, .155, .185),
  'connectFour': _Frac(.200, .725, .185, .150),
  'quizShow': _Frac(.405, .725, .185, .150),
  'kart': _Frac(.615, .710, .225, .170),
};

/// Portrait Fold-open / tablet: same hierarchy, stretched vertically so
/// every portal stays at least 48 dp and nothing stacks on top of Lumo.
const Map<String, _Frac> _portraitSlots = {
  'cards': _Frac(.220, .125, .185, .145),
  'puzzle': _Frac(.408, .085, .185, .145),
  'jumpRun': _Frac(.600, .125, .185, .145),
  'rhythm': _Frac(.720, .290, .185, .145),
  'memory': _Frac(.095, .290, .185, .145),
  'treasure': _Frac(.130, .460, .200, .145),
  'build': _Frac(.670, .460, .200, .145),
  'connectFour': _Frac(.145, .670, .220, .145),
  'quizShow': _Frac(.390, .670, .220, .145),
  'kart': _Frac(.635, .655, .240, .165),
};

enum _PortalChrome { card, medallion, featured }

_PortalChrome _chromeFor(String identity, {required bool reference}) {
  if (!reference) return _PortalChrome.card;
  if (identity == 'kart' ||
      identity == 'connectFour' ||
      identity == 'quizShow') {
    return _PortalChrome.featured;
  }
  return _PortalChrome.medallion;
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
      final viewHeight = MediaQuery.sizeOf(context).height;
      // Fold7 open is 690×829 logical pixels in this app. A 720 px +
      // landscape-only check sent that canvas (and every tablet portrait)
      // back to the old phone grid. Width >= 600 keeps the page-34 hub
      // for Fold open, tablets and phone landscape.
      final reference = SpielweltLayout.useReferenceHub(width, viewHeight);
      final portrait =
          SpielweltLayout.isPortraitReference(width, viewHeight);
      return reference
          ? _buildReference(width, viewHeight, portrait: portrait)
          : _buildNarrow(width);
    });
  }

  // Fold offen, Tablet und Handy quer: zehn echte Zugänge wie Referenz 34.
  Widget _buildReference(double width, double viewHeight,
      {required bool portrait}) {
    final slots = portrait ? _portraitSlots : _landscapeSlots;
    const barFrac = 0.10;
    var height = portrait
        ? math.max(
            width / _refAspect,
            math.min(viewHeight * 0.96, width * 1.22),
          )
        : width / _refAspect;
    // The parent/settings bar needs at least 64 dp; grow the canvas rather
    // than squash it into an overflowing Column.
    height = math.max(height, 64 / barFrac);
    Widget at(_Frac f, Widget child) => Positioned(
          left: f.left * width,
          top: f.top * height,
          width: f.width * width,
          height: f.height * height,
          child: child,
        );
    final byId = {for (final p in widget.portals) p.identity: p};
    return KeyedSubtree(
      key: const ValueKey('spielwelt-reference-hub'),
      child: SizedBox(
        key: ValueKey(portrait
            ? 'spielwelt-portrait-reference-hub'
            : 'spielwelt-wide-reference-hub'),
        width: width,
        height: height,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: _Sparkles(clock: _clock)),
          at(
            portrait
                ? const _Frac(.012, .070, .078, .600)
                : const _Frac(.012, .085, .078, .680),
            _HubSideRail(
              onHome: widget.onHome,
              onLearn: widget.onLearn,
              onTests: widget.onTests,
              onProfile: widget.onProgress,
            ),
          ),
          at(
            portrait
                ? const _Frac(.280, .010, .440, .100)
                : const _Frac(.315, .010, .370, .120),
            _HubLogo(clock: _clock, compact: portrait),
          ),
          at(
            portrait
                ? const _Frac(.360, .455, .280, .090)
                : const _Frac(.380, .455, .240, .100),
            const _StoneStage(),
          ),
          at(
            portrait
                ? const _Frac(.355, .250, .290, .280)
                : const _Frac(.385, .250, .230, .310),
            Center(child: _fox((portrait ? .26 : .30) * height)),
          ),
          for (var i = 0; i < slots.entries.length; i++)
            if (byId[slots.entries.elementAt(i).key] != null)
              at(
                slots.entries.elementAt(i).value,
                _portal(
                  byId[slots.entries.elementAt(i).key]!,
                  i,
                  width: slots.entries.elementAt(i).value.width * width,
                  chrome: _chromeFor(
                    slots.entries.elementAt(i).key,
                    reference: true,
                  ),
                ),
              ),
          at(
            portrait
                ? const _Frac(.105, .880, .870, .100)
                : const _Frac(.105, .885, .870, .100),
            _HubBar(
              onParents: widget.onParents,
              onProgress: widget.onProgress,
              onSettings: widget.onSettings,
              showSlogans: false,
            ),
          ),
        ]),
      ),
    );
  }

  // Hochformat (Handy, Fold zu): Logo, Lumo mit Knopf, Portale in Spalten.
  Widget _buildNarrow(double width) {
    final columns = width >= 560 ? 3 : 2;
    const gap = 12.0;
    final tileWidth = (width - 24 - gap * (columns - 1)) / columns;
    final tileHeight = tileWidth * 0.86;
    final foxSize = math.min(width * .62, 300.0);
    return Padding(
      key: const ValueKey('spielwelt-narrow-hub'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: math.min(width * .42, 190),
          child: _HubLogo(clock: _clock, compact: true),
        ),
        SizedBox(
          height: foxSize * 1.02,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Positioned.fill(child: _Sparkles(clock: _clock)),
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
      ]),
    );
  }
}

class _HubSideRail extends StatelessWidget {
  const _HubSideRail({
    required this.onHome,
    required this.onLearn,
    required this.onTests,
    required this.onProfile,
  });

  final VoidCallback onHome;
  final VoidCallback onLearn;
  final VoidCallback onTests;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, String, VoidCallback?, bool)>[
      (Icons.home_rounded, 'Start', onHome, false),
      (Icons.school_rounded, 'Lernen', onLearn, false),
      (Icons.sports_esports_rounded, 'Spielen', null, true),
      (Icons.fact_check_rounded, 'Tests', onTests, false),
      (Icons.person_rounded, 'Profil', onProfile, false),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60A2A58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x9953DDFD)),
        boxShadow: const [
          BoxShadow(color: Color(0x66020A24), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final entry in entries)
              Semantics(
                button: entry.$3 != null,
                selected: entry.$4,
                label: entry.$2,
                child: InkWell(
                  key: ValueKey('spielwelt-rail-${entry.$2.toLowerCase()}'),
                  onTap: entry.$3,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
                    decoration: entry.$4
                        ? BoxDecoration(
                            color: const Color(0xFF21BCE8),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Color(0x8853DDFD), blurRadius: 12),
                            ],
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.$1,
                            size: 23,
                            color: entry.$4
                                ? const Color(0xFF061A3D)
                                : LumoVisualTokens.white),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            entry.$2,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: entry.$4
                                  ? const Color(0xFF061A3D)
                                  : LumoVisualTokens.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Logo ─────────────────────────────

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

class _GlassPortal extends StatefulWidget {
  const _GlassPortal({
    super.key,
    required this.portal,
    required this.clock,
    required this.phase,
    required this.onTap,
    this.chrome = _PortalChrome.card,
  });

  final SpielweltPortal portal;
  final Animation<double> clock;
  final double phase;
  final VoidCallback onTap;
  final _PortalChrome chrome;

  @override
  State<_GlassPortal> createState() => _GlassPortalState();
}

class _GlassPortalState extends State<_GlassPortal> {
  bool _pressed = false;

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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .96 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedBuilder(
            animation: widget.clock,
            builder: (context, child) {
              final wave =
                  math.sin((widget.clock.value + widget.phase) * 2 * math.pi);
              return Transform.translate(
                offset: Offset(0, wave * 2.5),
                child: child,
              );
            },
            child: _PortalChromeBox(
              chrome: widget.chrome,
              portal: portal,
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
    this.lockedChip,
  });

  final _PortalChrome chrome;
  final SpielweltPortal portal;
  final Widget preview;
  final Widget? lockedChip;

  @override
  Widget build(BuildContext context) {
    final title = _PortalCaption(title: portal.title, icon: portal.icon);
    return switch (chrome) {
      _PortalChrome.medallion => _medallion(title),
      _PortalChrome.featured => _featured(title),
      _PortalChrome.card => _card(),
    };
  }

  Widget _medallion(Widget title) {
    return Column(children: [
      Expanded(
        flex: 5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: LumoVisualTokens.gold.withOpacity(.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Color(0x88020A24),
                  blurRadius: 12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD86B), width: 3.4),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE9A6), Color(0xFFB8860B)],
                ),
              ),
              padding: const EdgeInsets.all(3.5),
              child: Stack(fit: StackFit.expand, children: [
                ClipOval(child: preview),
                if (lockedChip != null)
                  Positioned(top: 8, right: 8, child: lockedChip!),
              ]),
            ),
          ),
        ),
      ),
      title,
    ]);
  }

  Widget _featured(Widget title) {
    return Column(children: [
      Expanded(
        flex: 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: LumoVisualTokens.gold.withOpacity(.28),
                blurRadius: 16,
              ),
              const BoxShadow(
                color: Color(0x88020A24),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD86B), width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(fit: StackFit.expand, children: [
              preview,
              if (lockedChip != null)
                Positioned(top: 8, right: 8, child: lockedChip!),
            ]),
          ),
        ),
      ),
      title,
    ]);
  }

  Widget _card() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6653DDFD),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(fit: StackFit.expand, children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xCC1A5AA8), Color(0xE00A2A66)],
              ),
            ),
          ),
          Positioned.fill(
            bottom: 48,
            child: preview,
          ),
          Align(alignment: Alignment.bottomCenter, child: _PortalLabel(portal: portal)),
          const _GlassRim(),
          if (lockedChip != null)
            Positioned(top: 8, right: 8, child: lockedChip!),
        ]),
      ),
    );
  }
}

class _PortalCaption extends StatelessWidget {
  const _PortalCaption({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6082455),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xAAFFD86B)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: const Color(0xFFFFE08A), size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white,
              shadows: [Shadow(color: Color(0xAA000000), blurRadius: 4)],
            ),
          ),
        ),
      ]),
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
    final Widget image;
    if (portal.specialId == 'connectFour') {
      image = const _ConnectFourPreview();
    } else if (portal.specialId == 'quizShow') {
      image = Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF187EC3), Color(0xFF45278D), Color(0xFF061A48),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.auto_awesome_rounded,
              size: 38, color: Color(0xFFFFDF8E)),
          ),
        ),
        Image.asset(
          'assets/lumo_design/fox/fox_quiz_host_1982.webp',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ]);
    } else {
      image = Image.asset(
        _artFor(portal),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      );
    }
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

class _ConnectFourPreview extends StatelessWidget {
  const _ConnectFourPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF183E87), Color(0xFF071A3D)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: LayoutBuilder(builder: (context, c) {
          const columns = 7;
          const rows = 6;
          final cell = math.min(c.maxWidth / columns, c.maxHeight / rows);
          return Center(
            child: SizedBox(
              width: cell * columns,
              height: cell * rows,
              child: CustomPaint(painter: _ConnectFourBoardPainter()),
            ),
          );
        }),
      ),
    );
  }
}

class _ConnectFourBoardPainter extends CustomPainter {
  const _ConnectFourBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 7;
    const rows = 6;
    final cell = math.min(size.width / cols, size.height / rows);
    final board = Paint()..color = const Color(0xFF1661B8);
    final hole = Paint()..color = const Color(0xFF08224C);
    final cyan = Paint()..color = const Color(0xFF53DDFD);
    final gold = Paint()..color = const Color(0xFFFFD166);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * .18)),
      board,
    );
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final center = Offset((col + .5) * cell, (row + .5) * cell);
        var paint = hole;
        if ((row == 5 && col.isEven) || (row == 4 && col == 3)) paint = cyan;
        if ((row == 5 && col.isOdd) || (row == 4 && col == 2)) paint = gold;
        canvas.drawCircle(center, cell * .34, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectFourBoardPainter oldDelegate) => false;
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
      final disc = 50 * scale;
      return Container(
        margin: EdgeInsets.fromLTRB(8 * scale, 0, 8 * scale, 8 * scale),
        padding: EdgeInsets.fromLTRB(6 * scale, 5 * scale, 10 * scale, 5 * scale),
        decoration: BoxDecoration(
          color: const Color(0xCC082455),
          borderRadius: BorderRadius.circular(22 * scale),
          border: Border.all(color: const Color(0x6637D2FD)),
        ),
        child: Row(children: [
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B3A7E),
              border: Border.all(
                  color: LumoVisualTokens.cyanBright, width: 2.2 * scale),
              boxShadow: [
                BoxShadow(
                    color: LumoVisualTokens.cyan.withOpacity(.6),
                    blurRadius: 10 * scale),
              ],
            ),
            child: Icon(portal.icon,
                color: LumoVisualTokens.white, size: disc * .56),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  portal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: (portal.game == null ? 17 : 22) * scale,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                    shadows: const [
                      Shadow(color: Color(0xAA37D2FD), blurRadius: 8),
                    ],
                  ),
                ),
                Text(
                  portal.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.2),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11.5 * scale,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE6F4FF),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
    });
  }
}

class _GlassRim extends StatelessWidget {
  const _GlassRim();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xCC53DDFD), width: 2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.center,
              colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
            ),
          ),
        ),
      );
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
            child: LayoutBuilder(builder: (context, c) {
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
