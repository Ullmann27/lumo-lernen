import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';

/// The pictures are already bundled with Lumo Lernen. No placeholder screens,
/// network images, account prompt or duplicate assets are required.
class LumoGameEntryArt {
  const LumoGameEntryArt._();

  static String titleFor(String scene) => switch (scene) {
        'kart' => 'Lumo Kart',
        'build' => 'Lumo Bauwelt',
        'puzzle' => 'Lumo Puzzle-Atelier',
        'rhythm' => 'Lumo Rhythm Party',
        'treasure' => 'Lumo Schatzsuche',
        'jump' => 'Lumo Abenteuer',
        _ => 'Lumo Spielewelt',
      };

  static String imageFor(String scene) => switch (scene) {
        'kart' => 'assets/lumo_design/gameplay/kart_sonnenhafen_preview.webp',
        'build' => 'assets/lumo_design/gameplay/build.png',
        'puzzle' => 'assets/lumo_design/gameplay/puzzle.png',
        'rhythm' => 'assets/lumo_design/gameplay/rhythm.png',
        'treasure' => 'assets/lumo_design/gameplay/treasure.png',
        'jump' => 'assets/lumo_design/bg/bg_games.png',
        _ => 'assets/lumo_design/bg/bg_games.png',
      };

  static String categoryFor(String scene) => switch (scene) {
        'kart' => '3D-RENNSPIEL',
        'build' => 'BAUABENTEUER',
        'puzzle' => 'PUZZLE-WELT',
        'rhythm' => 'MUSIKSPIEL',
        'treasure' => 'ENTDECKUNGSREISE',
        _ => 'SPIELWELT',
      };
}

/// These are stages of actual asynchronous app work, never fabricated
/// percentage values or an artificial timer.
enum LumoGameEntryPhase { saving, preparing, opening }

class LumoGameEntryOverlay extends StatelessWidget {
  const LumoGameEntryOverlay({
    super.key,
    required this.scene,
    required this.phase,
    this.reduceMotion = false,
  });

  final String scene;
  final LumoGameEntryPhase phase;
  final bool reduceMotion;

  String get _status => switch (phase) {
        LumoGameEntryPhase.saving => 'Deine Sterne werden gespeichert',
        LumoGameEntryPhase.preparing => 'Dein Spiel wird vorbereitet',
        LumoGameEntryPhase.opening => 'Die Spielwelt wird geöffnet',
      };

  @override
  Widget build(BuildContext context) {
    final title = LumoGameEntryArt.titleFor(scene);
    final image = LumoGameEntryArt.imageFor(scene);
    return Material(
      color: LumoVisualTokens.night,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Prevent a second launch while the bridge is busy.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              key: const ValueKey('game-entry-art'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const LumoSceneBackground(
                scene: LumoScene.games,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.23, 0.54, 0.79, 1.0],
                  colors: [
                    Color(0xD803193F),
                    Color(0x4D03193F),
                    Color(0x2003193F),
                    Color(0xDA03193F),
                    Color(0xF703193F),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                final short = constraints.maxHeight < 420;
                final horizontal = constraints.maxWidth > 620;
                final padding = short ? 10.0 : 20.0;
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 850),
                          child: _BrandBar(
                            title: title,
                            category: LumoGameEntryArt.categoryFor(scene),
                            compact: short,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: horizontal ? 520 : 490,
                          ),
                          child: Semantics(
                            liveRegion: true,
                            label: '$title. $_status. Bitte warten.',
                            child: LumoGlassCard(
                              padding: EdgeInsets.symmetric(
                                horizontal: short ? 14 : 22,
                                vertical: short ? 12 : 18,
                              ),
                              color: const Color(0xFF092C56),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _status,
                                    key: const ValueKey('game-entry-status'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: short ? 16 : 20,
                                      fontWeight: FontWeight.w900,
                                      color: LumoVisualTokens.white,
                                    ),
                                  ),
                                  SizedBox(height: short ? 8 : 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: TickerMode(
                                      enabled: !reduceMotion,
                                      child: const LinearProgressIndicator(
                                        key: ValueKey('game-entry-loading'),
                                        minHeight: 7,
                                        backgroundColor: Color(0xFF244468),
                                        color: LumoVisualTokens.cyanBright,
                                        semanticsLabel:
                                            'Ladevorgang läuft. Noch keine Prozentangabe.',
                                      ),
                                    ),
                                  ),
                                  if (!short) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Gleich geht dein Abenteuer los!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: LumoVisualTokens.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({
    required this.title,
    required this.category,
    required this.compact,
  });
  final String title;
  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 7 : 10,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xF008377A), Color(0xE9042450)],
          ),
          border: Border.all(
            color: LumoVisualTokens.cyanBright.withValues(alpha: 0.82),
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x6637D2FD), blurRadius: 19),
          ],
        ),
        child: Row(children: [
          Container(
            width: compact ? 38 : 48,
            height: compact ? 38 : 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LumoVisualTokens.glass,
              border: Border.all(color: LumoVisualTokens.cyan),
            ),
            child: Image.asset(
              'assets/lumo_design/fox/fox_avatar.png',
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sports_motorsports_rounded,
                color: LumoVisualTokens.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    key: const ValueKey('game-entry-title'),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: compact ? 20 : 29,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                      shadows: const [
                        Shadow(color: Color(0xFF247BC7), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                if (!compact)
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.cyanBright,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_rounded,
            color: LumoVisualTokens.gold,
            size: 26,
          ),
        ]),
      );
}

/// An OverlayEntry rather than another Navigator route: the existing page,
/// profile-generation guards, wallet order and Android Activity return are
/// unchanged. The overlay disappears on every outcome.
class LumoGameEntryHandle {
  LumoGameEntryHandle._(this._entry, this._phase);

  final OverlayEntry _entry;
  final ValueNotifier<LumoGameEntryPhase> _phase;
  bool _closed = false;

  static LumoGameEntryHandle? show(
    BuildContext context, {
    required String scene,
    required bool reduceMotion,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return null;
    final phase = ValueNotifier(LumoGameEntryPhase.saving);
    final entry = OverlayEntry(
      builder: (_) => ValueListenableBuilder<LumoGameEntryPhase>(
        valueListenable: phase,
        builder: (_, value, __) => LumoGameEntryOverlay(
          scene: scene,
          phase: value,
          reduceMotion: reduceMotion,
        ),
      ),
    );
    overlay.insert(entry);
    return LumoGameEntryHandle._(entry, phase);
  }

  void setPhase(LumoGameEntryPhase phase) {
    if (!_closed) _phase.value = phase;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _entry.remove();
    _entry.dispose();
    _phase.dispose();
  }
}
