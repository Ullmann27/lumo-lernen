// ════════════════════════════════════════════════════════════════════════
// LUMO REACTION COMPANION — kleiner Lumo, der mit dem Kind mitreagiert
// ════════════════════════════════════════════════════════════════════════
// Heinz' Phase 3: 'Auf jedem Modul-Screen sichtbarer kleiner Lumo,
// der nach jeder Antwort reagiert (Daumen hoch / Kopf schief / Anfeuern).'
//
// Drei Stimmungen:
//   - LumoMood.idle:  ruhige 8-Frame Idle-Animation
//   - LumoMood.cheer: 8-Frame Jubel-Animation (cheer_01..08)
//   - LumoMood.think: Idle-Frames mit leicht geneigtem Kopf (Transform)
//
// Klein und gegated:
//   - LumoMagic? Nein - keine Aura, keine Overlays. Nur der Companion.
//   - Maximal 96px gross.
//   - Tap erweitert: aktuell nur Pulse-Feedback, spaeter Mini-Chat.
//   - MediaQuery.disableAnimations respektiert.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

enum LumoReactionMood { idle, cheer, think }

class LumoReactionCompanion extends StatefulWidget {
  const LumoReactionCompanion({
    super.key,
    this.mood = LumoReactionMood.idle,
    this.size = 80,
    this.onTap,
  });

  final LumoReactionMood mood;
  final double size;
  final VoidCallback? onTap;

  static const List<String> _idleFrames = [
    'assets/lumo_jump/fox/idle/fox_idle_01.png',
    'assets/lumo_jump/fox/idle/fox_idle_02.png',
    'assets/lumo_jump/fox/idle/fox_idle_03.png',
    'assets/lumo_jump/fox/idle/fox_idle_04.png',
    'assets/lumo_jump/fox/idle/fox_idle_05.png',
    'assets/lumo_jump/fox/idle/fox_idle_06.png',
    'assets/lumo_jump/fox/idle/fox_idle_07.png',
    'assets/lumo_jump/fox/idle/fox_idle_08.png',
  ];

  static const List<String> _cheerFrames = [
    'assets/lumo_sprite_pack/cheer/cheer_01.png',
    'assets/lumo_sprite_pack/cheer/cheer_02.png',
    'assets/lumo_sprite_pack/cheer/cheer_03.png',
    'assets/lumo_sprite_pack/cheer/cheer_04.png',
    'assets/lumo_sprite_pack/cheer/cheer_05.png',
    'assets/lumo_sprite_pack/cheer/cheer_06.png',
    'assets/lumo_sprite_pack/cheer/cheer_07.png',
    'assets/lumo_sprite_pack/cheer/cheer_08.png',
  ];

  @override
  State<LumoReactionCompanion> createState() => _LumoReactionCompanionState();
}

class _LumoReactionCompanionState extends State<LumoReactionCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _frameCtrl;
  late final AnimationController _bounceCtrl;
  int _frameIdx = 0;
  bool _precachedIdle = false;
  bool _precachedCheer = false;

  List<String> get _frames {
    switch (widget.mood) {
      case LumoReactionMood.cheer:
        return LumoReactionCompanion._cheerFrames;
      case LumoReactionMood.idle:
      case LumoReactionMood.think:
        return LumoReactionCompanion._idleFrames;
    }
  }

  Duration get _frameDuration {
    // Cheer schneller (lebhafter), Idle/Think ruhiger.
    return widget.mood == LumoReactionMood.cheer
        ? const Duration(milliseconds: 90)
        : const Duration(milliseconds: 130);
  }

  @override
  void initState() {
    super.initState();
    _frameCtrl = AnimationController(
      vsync: this,
      duration: _frameDuration * 8,
    )
      ..addListener(_onTick)
      ..repeat();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precachedIdle) {
      _precachedIdle = true;
      for (final p in LumoReactionCompanion._idleFrames) {
        precacheImage(AssetImage(p), context);
      }
    }
    final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disable) {
      _frameCtrl.stop();
    } else if (!_frameCtrl.isAnimating) {
      _frameCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LumoReactionCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      // Frame-Index zurueck auf Anfang, Controller mit neuer Duration
      // resetten, damit der Wechsel sichtbar wird (z.B. cheer-Burst).
      _frameIdx = 0;
      // Reduced-Motion respektieren: ohne diesen Check wuerde jeder
      // Mood-Wechsel den Controller wieder starten, obwohl der User
      // Animations deaktiviert hat (Codex P2 Accessibility-Regression).
      final disable =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      _frameCtrl
        ..stop()
        ..duration = _frameDuration * 8
        ..reset();
      if (!disable) {
        _frameCtrl.repeat();
      }
      if (widget.mood == LumoReactionMood.cheer) {
        // Cheer-Frames erst beim ersten Wechsel laden.
        if (!_precachedCheer) {
          _precachedCheer = true;
          for (final p in LumoReactionCompanion._cheerFrames) {
            precacheImage(AssetImage(p), context);
          }
        }
        if (!disable) {
          _bounceCtrl.forward(from: 0);
        }
      }
    }
  }

  @override
  void dispose() {
    _frameCtrl
      ..removeListener(_onTick)
      ..dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onTick() {
    final next = (_frameCtrl.value * 8).floor() % 8;
    if (next != _frameIdx && mounted) {
      setState(() => _frameIdx = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frames = _frames;
    final image = Image.asset(
      frames[_frameIdx.clamp(0, frames.length - 1)],
      height: widget.size,
      width: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Center(
        child: Text('🦊', style: TextStyle(fontSize: widget.size * 0.6)),
      ),
    );

    // Think: leicht geneigter Kopf (statischer Transform).
    Widget moodWrapped = image;
    if (widget.mood == LumoReactionMood.think) {
      moodWrapped = Transform.rotate(angle: -0.18, child: image);
    }

    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final t = _bounceCtrl.value;
        // Bei Mood-Wechsel zu cheer ein kleiner Pop-Effekt.
        final scale = widget.mood == LumoReactionMood.cheer
            ? 1.0 + (t * (1 - t) * 0.4)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: moodWrapped,
        ),
      ),
    );
  }
}
