import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/games/game_world.dart';
import 'spielwelt_routes.dart';
import 'spielwelt_game_icon.dart';
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

  /// Direct economic village; independent of the classic Bauwelt's unlocks.
  /// The native Android bridge must still validate the child's actual launch.
  const SpielweltPortal.village({required this.onOpen})
      : game = null,
        state = const GameUnlockState(unlocked: true),
        semanticTitle = 'Dorf & Wirtschaft',
        specialId = 'village';

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
      case 'village':
        return 'Dorfwirtschaft';
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
        'village' => 'Versorge dein Dorf, baue Häuser und hilf deinen Nachbarn!',
        'quizShow' => '20 Fragen · 3 Joker · bis 5.000 Sterne',
        _ => game?.tagline ?? '',
      };
  bool get playable =>
      specialId != null || game?.availability == GameAvailability.playable;

  /// Vorleser- und Prüftext, falls er vom sichtbaren Titel abweicht.
  final String? semanticTitle;
}

/// The familiar game grid, presented as one calm blue stage. Each tile opens
/// its original game directly; neither artwork nor layout owns save state.
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
    this.stars = 0,
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
  final int stars;
  final bool reduceMotion;

  @override
  State<SpielweltHub> createState() => _SpielweltHubState();
}

class _SpielweltHubState extends State<SpielweltHub> {
  final LumoCharacterController _lumo = LumoCharacterController();

  static const _featuredOrder = [
    'kart',
    'village',
    'cards',
    'build',
    'puzzle',
    'memory',
    'jumpRun',
  ];

  @override
  void dispose() {
    _lumo.dispose();
    super.dispose();
  }

  List<SpielweltPortal> get _featured => [
        for (final identity in _featuredOrder)
          ...widget.portals.where((portal) => portal.identity == identity),
      ];

  List<SpielweltPortal> get _other => [
        for (final portal in widget.portals)
          if (!_featuredOrder.contains(portal.identity)) portal,
      ];

  Widget _grid(List<SpielweltPortal> portals, double width, int columns) {
    const gap = 12.0;
    final tileWidth = (width - gap * (columns - 1)) / columns;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final iconHeight = (tileWidth * .67).clamp(76.0, 139.0);
    final tileHeight = iconHeight + 54 * textScale;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final portal in portals)
          SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: _GameTile(
              key: ValueKey('spielwelt-portal-${portal.identity}'),
              portal: portal,
              reduceMotion: widget.reduceMotion,
              onTap: () {
                if (portal.state.unlocked && portal.playable) _lumo.cheer();
                portal.onOpen();
              },
            ),
          ),
      ],
    );
  }

  Widget _fox(double size) => LumoCharacter(
        key: const ValueKey('spielwelt-lumo'),
        pose: LumoDesignFoxPose.spielweltWave,
        celebratePose: LumoDesignFoxPose.spielweltJump,
        size: size,
        shadow: false,
        idleHops: false,
        intro: false,
        reduceMotion: widget.reduceMotion,
        controller: _lumo,
        onTap: _lumo.wave,
      );

  Widget _companion(double width, {required bool sideBySide}) {
    if (sideBySide) {
      final foxSize = (width * 1.12).clamp(170.0, 330.0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: foxSize * 1.03,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: foxSize * .24,
                  child: const CustomPaint(painter: _CompanionStagePainter()),
                ),
                Positioned(bottom: foxSize * .025, child: _fox(foxSize)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AdventureButton(onTap: widget.onAdventure),
          const SizedBox(height: 9),
          const Text(
            'Spring mit Lumo los',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Color(0xFFC4D8EF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    final compact = MediaQuery.sizeOf(context).height < 650;
    final foxSize = compact ? 80.0 : 108.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dein nächstes Abenteuer',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _AdventureButton(onTap: widget.onAdventure),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _fox(foxSize),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 1360.0);
          const padding = 16.0;
          final innerWidth = width - padding * 2;
          final wide =
              width >= 640 && MediaQuery.textScalerOf(context).scale(1) < 1.6;
          final heroWidth = wide ? (innerWidth * .29).clamp(178.0, 285.0) : 0.0;
          final gridWidth = wide ? innerWidth - heroWidth - 22 : innerWidth;
          final columns = wide ? 3 : SpielweltLayout.tileColumns(width);
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: Padding(
                // Keep the established key so the existing routing/capture
                // contract continues to identify the familiar tile hub.
                key: const ValueKey('spielwelt-narrow-hub'),
                padding: const EdgeInsets.fromLTRB(padding, 8, padding, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HubHeader(stars: widget.stars),
                    const SizedBox(height: 12),
                    if (wide)
                      Row(
                        key: const ValueKey('spielwelt-wide-stage'),
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: gridWidth,
                            child: _grid(_featured, gridWidth, columns),
                          ),
                          const SizedBox(width: 22),
                          SizedBox(
                            width: heroWidth,
                            child: _companion(heroWidth, sideBySide: true),
                          ),
                        ],
                      )
                    else ...[
                      _companion(innerWidth, sideBySide: false),
                      _grid(_featured, gridWidth, columns),
                    ],
                    if (_other.isNotEmpty) ...[
                      const SizedBox(height: 23),
                      const Text(
                        'Noch mehr Abenteuer',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD7EAFF),
                        ),
                      ),
                      const SizedBox(height: 11),
                      _grid(
                          _other,
                          innerWidth,
                          wide
                              ? math.min(4, _other.length)
                              : SpielweltLayout.tileColumns(width)),
                    ],
                    const SizedBox(height: 19),
                    _HubActions(
                      onParents: widget.onParents,
                      onProgress: widget.onProgress,
                      onSettings: widget.onSettings,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

/// Used by both the games page and its shell edges. No decorative landscape
/// sits behind labels; the dimensional floor is painted once, without blur.
class SpielweltBackdrop extends StatelessWidget {
  const SpielweltBackdrop({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2851), Color(0xFF07152F), Color(0xFF102C51)],
            stops: [0, .55, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _StageBackdropPainter()),
                ),
              ),
            ),
            if (child != null) child!,
          ],
        ),
      );
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Lumo Spielewelt',
              header: true,
              excludeSemantics: true,
              child: Row(
                children: [
                  Image.asset(
                    'assets/lumo_design/logo/logo_lumo.png',
                    width: 91,
                    height: 54,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Spielewelt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize:
                            MediaQuery.sizeOf(context).width < 380 ? 20 : 25,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: '$stars Sterne',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF07182F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B729F)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/lumo_design/icons/star_gold.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$stars',
                    key: const ValueKey('spielwelt-stars'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFE7A0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _GameTile extends StatefulWidget {
  const _GameTile({
    super.key,
    required this.portal,
    required this.onTap,
    required this.reduceMotion,
  });
  final SpielweltPortal portal;
  final VoidCallback onTap;
  final bool reduceMotion;

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile> {
  bool _pressed = false;
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final portal = widget.portal;
    final featured = portal.identity == 'kart';
    final open = portal.state.unlocked && portal.playable;
    final accent = featured ? const Color(0xFFFFCE50) : const Color(0xFF56D4FA);
    final status = !portal.playable
        ? 'Kommt bald'
        : portal.state.unlocked
            ? 'Spielen'
            : 'Noch gesperrt';
    final duration =
        widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 140);
    return Semantics(
      button: true,
      enabled: open,
      onTap: open ? widget.onTap : null,
      label:
          '${portal.semanticTitle ?? portal.title}. ${portal.tagline} $status',
      excludeSemantics: true,
      child: AnimatedScale(
        duration: duration,
        scale: _pressed ? .96 : 1,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: duration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: featured
                  ? const [
                      Color(0xFF385C7A),
                      Color(0xFF152D4F),
                      Color(0xFF131E34),
                    ]
                  : const [
                      Color(0xFF245D91),
                      Color(0xFF12365E),
                      Color(0xFF0A2446),
                    ],
              stops: const [0, .4, 1],
            ),
            border: Border.all(
              color: _highlighted
                  ? Colors.white
                  : accent.withOpacity(featured ? 1 : .62),
              width: featured || _highlighted ? 2 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x88020A18),
                blurRadius: 16,
                offset: Offset(0, _pressed ? 3 : 7),
              ),
              if (featured || _highlighted)
                BoxShadow(
                  color: accent.withOpacity(_highlighted ? .35 : .18),
                  blurRadius: 17,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(23),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onHover: (value) => setState(() => _highlighted = value),
              onFocusChange: (value) => setState(() => _highlighted = value),
              splashColor: accent.withOpacity(.22),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-.35, -.55),
                            radius: 1.2,
                            colors: [
                              accent.withOpacity(.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(9, 9, 9, 11),
                    child: Column(
                      children: [
                        Expanded(
                          child: SpielweltGameIcon(identity: portal.identity),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          portal.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!open)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xF20A1730),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              portal.playable
                                  ? Icons.lock_rounded
                                  : Icons.schedule,
                              size: 14,
                              color: const Color(0xFFFFD477),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              portal.playable ? 'Gesperrt' : 'Bald',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdventureButton extends StatelessWidget {
  const _AdventureButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEA8B), Color(0xFFFFC841), Color(0xFFF4AD25)],
            stops: [0, .5, 1],
          ),
          border: Border.all(color: const Color(0xFFFFF3BC), width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44F9B52F),
              blurRadius: 17,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('spielwelt-adventure'),
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 26,
                      color: Color(0xFF152647),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Auf ins Abenteuer!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF152647),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _HubActions extends StatelessWidget {
  const _HubActions({
    required this.onParents,
    required this.onProgress,
    required this.onSettings,
  });
  final VoidCallback onParents;
  final VoidCallback onProgress;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    Widget action(
      String id,
      IconData icon,
      String label,
      VoidCallback callback,
    ) =>
        Expanded(
          child: TextButton(
            key: ValueKey(id),
            onPressed: callback,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFCADEEF),
              minimumSize: const Size(48, 56),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: const Color(0xFF7CDCF1)),
                const SizedBox(height: 3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB307142C),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFF244B72)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          action(
            'spielwelt-parents',
            Icons.groups_rounded,
            'Elternbereich',
            onParents,
          ),
          action(
            'spielwelt-progress',
            Icons.bar_chart_rounded,
            'Fortschritt',
            onProgress,
          ),
          action(
            'spielwelt-settings',
            Icons.settings_rounded,
            'Einstellungen',
            onSettings,
          ),
        ],
      ),
    );
  }
}

class _CompanionStagePainter extends CustomPainter {
  const _CompanionStagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final top = Rect.fromLTWH(
      size.width * .04,
      0,
      size.width * .92,
      size.height * .62,
    );
    final rim = RRect.fromRectAndRadius(
      top.shift(Offset(0, size.height * .18)),
      Radius.circular(size.height * .4),
    );
    canvas.drawRRect(rim, Paint()..color = const Color(0xFF0B172C));
    canvas.drawOval(
      top,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF5085AA), Color(0xFF244C76), Color(0xFF112745)],
        ).createShader(top),
    );
    canvas.drawOval(
      top.deflate(3),
      Paint()
        ..color = const Color(0xFF4DA9CE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      top.deflate(11),
      Paint()
        ..color = const Color(0x883367A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CompanionStagePainter oldDelegate) => false;
}

class _StageBackdropPainter extends CustomPainter {
  const _StageBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Rect.fromCircle(
      center: Offset(size.width * .92, size.height * .27),
      radius: size.width * .65,
    );
    canvas.drawOval(
      blue,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x552E80BD), Color(0x003272AD)],
        ).createShader(blue),
    );
    final horizon = size.height * .52;
    final floor = Rect.fromLTWH(0, horizon, size.width, size.height - horizon);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x000D2651), Color(0x663A6C91), Color(0x000C244C)],
        ).createShader(floor),
    );
    for (var i = 0; i < 5; i++) {
      final y = horizon + math.pow(i / 4, 1.8) * floor.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Color.lerp(
            const Color(0x00000000),
            const Color(0x224DA6D3),
            i / 4,
          )!
          ..strokeWidth = 1,
      );
    }
    for (var i = -3; i <= 4; i++) {
      canvas.drawLine(
        Offset(size.width * .55, horizon),
        Offset(size.width * i * .35, size.height),
        Paint()
          ..color = const Color(0x104DA6D3)
          ..strokeWidth = 1,
      );
    }
    final arc = Rect.fromLTWH(
      -size.width * .22,
      -size.height * .12,
      size.width * 1.35,
      size.height * .88,
    );
    canvas.drawArc(
      arc,
      -.8,
      1.6,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x002CCBF2), Color(0x4856CBEA), Color(0x002CCBF2)],
        ).createShader(arc)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_StageBackdropPainter oldDelegate) => false;
}
