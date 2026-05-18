import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/game_progress_repository.dart';
import '../../../domain/games/game_level_model.dart';

/// Fertige, build-stabile Lumo-Jump-Adventure-Version.
///
/// Wichtig:
/// - gleicher Einstiegspunkt wie vorher: `LumoJumpFlameScreen`
/// - spielbar mit links/rechts/springen/ducken/rollen
/// - Sterne, Frageblöcke und Boss-Truhe funktionieren
/// - Belohnung wird nur einmal ins Wallet übertragen
/// - keine unfertige Flame-/Parallax-Baustelle mehr im Build-Pfad
class LumoJumpFlameScreen extends StatefulWidget {
  const LumoJumpFlameScreen({
    super.key,
    required this.appState,
    required this.level,
  });

  final LumoAppState appState;
  final GameLevel level;

  @override
  State<LumoJumpFlameScreen> createState() => _LumoJumpFlameScreenState();
}

class _LumoJumpFlameScreenState extends State<LumoJumpFlameScreen>
    with TickerProviderStateMixin {
  static const int _lastTile = 8;
  static const Set<int> _starTiles = <int>{1, 3, 4, 6, 7};
  static const Set<int> _questionTiles = <int>{2, 5};
  static const int _bossTile = 8;

  late final AnimationController _hopCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _rollCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _idleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  final Set<int> _collectedStars = <int>{};
  final Set<int> _solvedQuestions = <int>{};
  int _tile = 0;
  int _earnedStars = 0;
  bool _facingLeft = false;
  bool _ducking = false;
  bool _rolling = false;
  bool _bossOpened = false;
  bool _rewardTransferred = false;
  String _hint = 'Sammle Sterne, löse Frageblöcke und öffne die Boss-Truhe.';

  @override
  void dispose() {
    _hopCtrl.dispose();
    _rollCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  int get _levelStars => _bossOpened && _solvedQuestions.length == _questionTiles.length ? 3 : 1;

  void _move(int delta) {
    if (_bossOpened) return;
    HapticFeedback.selectionClick();
    setState(() {
      _facingLeft = delta < 0;
      _tile = (_tile + delta).clamp(0, _bossTile).toInt();
      _hint = _hintForTile(_tile);
    });
    _collectStarIfNeeded();
    if (_questionTiles.contains(_tile) && !_solvedQuestions.contains(_tile)) {
      unawaited(_askQuestion(_tile));
    }
  }

  void _jump() {
    if (_bossOpened) return;
    HapticFeedback.lightImpact();
    _hopCtrl.forward(from: 0);
    setState(() => _hint = 'Guter Sprung! Lumo landet sicher.');
  }

  void _duck() {
    if (_bossOpened) return;
    HapticFeedback.lightImpact();
    setState(() {
      _ducking = true;
      _hint = 'Geduckt! So kommst du unter Hindernissen durch.';
    });
    Future<void>.delayed(const Duration(milliseconds: 460), () {
      if (mounted) setState(() => _ducking = false);
    });
  }

  void _roll() {
    if (_bossOpened || _rolling) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _rolling = true;
      _hint = 'Rolle! Lumo flitzt mutig weiter.';
    });
    _rollCtrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _rollCtrl.reset();
      setState(() => _rolling = false);
    });
  }

  void _collectStarIfNeeded() {
    if (!_starTiles.contains(_tile) || _collectedStars.contains(_tile)) return;
    setState(() {
      _collectedStars.add(_tile);
      _earnedStars += 3;
      _hint = '+3 Sterne gesammelt!';
    });
    HapticFeedback.lightImpact();
  }

  String _hintForTile(int tile) {
    if (_questionTiles.contains(tile) && !_solvedQuestions.contains(tile)) {
      return 'Frageblock! Löse die Aufgabe.';
    }
    if (tile == _bossTile) return 'Boss-Truhe erreicht. Öffne sie!';
    if (_starTiles.contains(tile) && !_collectedStars.contains(tile)) {
      return 'Ein Stern wartet hier!';
    }
    return 'Weiter so. Sammle Sterne und bleib neugierig.';
  }

  Future<void> _askQuestion(int tile) async {
    final question = _Question.forLevel(widget.level.id, tile, widget.appState.state.grade);
    final answer = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Frageblock', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          question.prompt,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          for (final choice in question.choices)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(choice),
                child: Text(choice),
              ),
            ),
        ],
      ),
    );
    if (!mounted || answer == null) return;
    if (answer == question.answer) {
      setState(() {
        _solvedQuestions.add(tile);
        _earnedStars += 8;
        _hint = 'Richtig! +8 Sterne für den Frageblock.';
      });
      widget.appState.update(widget.appState.state.copyWith(
        mood: LumoMood.celebrate,
        lumoMessage: 'Richtig gelöst!\nDas war stark.',
      ));
      HapticFeedback.mediumImpact();
    } else {
      setState(() => _hint = 'Fast. Versuch es gleich noch einmal.');
      widget.appState.update(widget.appState.state.copyWith(
        mood: LumoMood.comfort,
        lumoMessage: 'Ganz ruhig.\nSchau nochmal genau hin.',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted && !_solvedQuestions.contains(tile)) {
        unawaited(_askQuestion(tile));
      }
    }
  }

  Future<void> _openBossChest() async {
    if (_tile != _bossTile || _bossOpened) return;
    if (_solvedQuestions.length < _questionTiles.length) {
      setState(() => _hint = 'Löse zuerst alle Frageblöcke (${_solvedQuestions.length}/${_questionTiles.length}).');
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _bossOpened = true;
      _earnedStars += 25;
      _hint = 'Boss-Truhe geöffnet! +25 Sterne.';
    });
    await _transferRewardOnce();
  }

  Future<void> _transferRewardOnce() async {
    if (_rewardTransferred) return;
    _rewardTransferred = true;
    final st = widget.appState.state;
    widget.appState.update(st.copyWith(
      stars: st.stars + _earnedStars,
      xp: st.xp + _earnedStars * 2,
      mood: LumoMood.celebrate,
      lumoMessage: 'Lumo Jump geschafft!\n+$_earnedStars Sterne',
    ));
    unawaited(GameProgressRepository().recordResult(
      childId: _childId,
      levelId: widget.level.id,
      starsEarned: _levelStars,
    ));
  }

  Future<void> _finishAndClose() async {
    if (_bossOpened) {
      await _transferRewardOnce();
    }
    if (!mounted) return;
    Navigator.of(context).pop(_earnedStars);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _tile / _lastTile;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: LumoColors.ink700),
          onPressed: _finishAndClose,
        ),
        title: Text(
          'Lumo Jump • Level ${widget.level.id}',
          style: const TextStyle(fontWeight: FontWeight.w900, color: LumoColors.ink900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
              label: Text('$_earnedStars'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                borderRadius: BorderRadius.circular(99),
                color: LumoColors.orange,
                backgroundColor: Colors.white,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFBAE6FD), Color(0xFFE0F2FE), Color(0xFFFFF7ED)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: LumoShadow.card,
                  ),
                  child: Stack(
                    children: [
                      _WorldBackdrop(progress: progress),
                      _PathTiles(
                        currentTile: _tile,
                        collectedStars: _collectedStars,
                        solvedQuestions: _solvedQuestions,
                        bossOpened: _bossOpened,
                      ),
                      _LumoRunner(
                        tile: _tile,
                        facingLeft: _facingLeft,
                        ducking: _ducking,
                        rolling: _rolling,
                        hop: _hopCtrl,
                        roll: _rollCtrl,
                        idle: _idleCtrl,
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: _HintCard(text: _hint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _ControlPad(
              onLeft: () => _move(-1),
              onRight: () => _move(1),
              onJump: _jump,
              onDuck: _duck,
              onRoll: _roll,
              onChest: _openBossChest,
              chestEnabled: _tile == _bossTile,
              finished: _bossOpened,
              onFinish: _finishAndClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _Question {
  const _Question({required this.prompt, required this.choices, required this.answer});
  final String prompt;
  final List<String> choices;
  final String answer;

  factory _Question.forLevel(int levelId, int tile, int grade) {
    final seed = levelId * 31 + tile * 17 + grade;
    final rng = math.Random(seed);
    final a = 1 + rng.nextInt(8 + grade * 2);
    final b = 1 + rng.nextInt(8 + grade * 2);
    final sum = a + b;
    final values = <int>{sum, math.max(0, sum - 1), sum + 1, sum + 2}.toList();
    values.shuffle(rng);
    return _Question(
      prompt: 'Was ist $a + $b?',
      choices: values.map((v) => '$v').toList(),
      answer: '$sum',
    );
  }
}

class _WorldBackdrop extends StatelessWidget {
  const _WorldBackdrop({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WorldBackdropPainter(progress),
      child: const SizedBox.expand(),
    );
  }
}

class _WorldBackdropPainter extends CustomPainter {
  const _WorldBackdropPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final far = Paint()..color = const Color(0xFF86EFAC).withOpacity(.65);
    final near = Paint()..color = const Color(0xFF22C55E).withOpacity(.72);
    _mountains(canvas, size, far, size.height * .58, 180, progress * 70);
    _mountains(canvas, size, near, size.height * .69, 150, progress * 110);
    canvas.drawCircle(Offset(size.width * .84, size.height * .15), 30, Paint()..color = const Color(0xFFFCD34D));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * .28, size.height * .18), width: 110, height: 32),
      Paint()..color = Colors.white.withOpacity(.72),
    );
  }

  void _mountains(Canvas canvas, Size size, Paint paint, double baseY, double width, double offset) {
    final count = (size.width / width).ceil() + 3;
    for (var i = -1; i < count; i++) {
      final x = i * width - offset % width;
      canvas.drawPath(
        Path()
          ..moveTo(x, baseY)
          ..lineTo(x + width / 2, baseY - 90)
          ..lineTo(x + width, baseY)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldBackdropPainter oldDelegate) => oldDelegate.progress != progress;
}

class _PathTiles extends StatelessWidget {
  const _PathTiles({
    required this.currentTile,
    required this.collectedStars,
    required this.solvedQuestions,
    required this.bossOpened,
  });

  final int currentTile;
  final Set<int> collectedStars;
  final Set<int> solvedQuestions;
  final bool bossOpened;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final groundY = c.maxHeight * .68;
      final step = (c.maxWidth - 92) / _LumoJumpFlameScreenState._lastTile;
      return Stack(
        children: [
          Positioned(
            left: 36,
            right: 36,
            top: groundY + 34,
            child: Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF92400E), borderRadius: BorderRadius.circular(99))),
          ),
          for (var i = 0; i <= _LumoJumpFlameScreenState._lastTile; i++)
            Positioned(
              left: 30 + i * step,
              top: groundY + math.sin(i * .7) * 14,
              child: _TileBadge(
                index: i,
                active: currentTile == i,
                starVisible: _LumoJumpFlameScreenState._starTiles.contains(i) && !collectedStars.contains(i),
                questionSolved: solvedQuestions.contains(i),
                questionVisible: _LumoJumpFlameScreenState._questionTiles.contains(i),
                boss: i == _LumoJumpFlameScreenState._bossTile,
                bossOpened: bossOpened,
              ),
            ),
        ],
      );
    });
  }
}

class _TileBadge extends StatelessWidget {
  const _TileBadge({
    required this.index,
    required this.active,
    required this.starVisible,
    required this.questionVisible,
    required this.questionSolved,
    required this.boss,
    required this.bossOpened,
  });

  final int index;
  final bool active;
  final bool starVisible;
  final bool questionVisible;
  final bool questionSolved;
  final bool boss;
  final bool bossOpened;

  @override
  Widget build(BuildContext context) {
    final icon = boss
        ? (bossOpened ? Icons.workspace_premium_rounded : Icons.inventory_2_rounded)
        : questionVisible
            ? (questionSolved ? Icons.check_circle_rounded : Icons.quiz_rounded)
            : starVisible
                ? Icons.star_rounded
                : Icons.grass_rounded;
    final color = boss
        ? LumoColors.purple
        : questionVisible
            ? LumoColors.blue
            : starVisible
                ? LumoColors.gold
                : LumoColors.green;
    return AnimatedScale(
      scale: active ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: active ? LumoColors.orange : color.withOpacity(.45), width: active ? 4 : 2),
          boxShadow: LumoShadow.card,
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

class _LumoRunner extends StatelessWidget {
  const _LumoRunner({
    required this.tile,
    required this.facingLeft,
    required this.ducking,
    required this.rolling,
    required this.hop,
    required this.roll,
    required this.idle,
  });

  final int tile;
  final bool facingLeft;
  final bool ducking;
  final bool rolling;
  final Animation<double> hop;
  final Animation<double> roll;
  final Animation<double> idle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final groundY = c.maxHeight * .68;
      final step = (c.maxWidth - 92) / _LumoJumpFlameScreenState._lastTile;
      return AnimatedBuilder(
        animation: Listenable.merge([hop, roll, idle]),
        builder: (context, _) {
          final hopY = -math.sin(hop.value * math.pi) * 54;
          final idleY = math.sin(idle.value * math.pi) * 4;
          final angle = rolling ? roll.value * math.pi * 2 * (facingLeft ? -1 : 1) : 0.0;
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            left: 34 + tile * step,
            top: groundY - 64 + hopY + idleY + (ducking ? 18 : 0),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scaleX: facingLeft ? -1 : 1,
                child: _FoxBody(ducking: ducking),
              ),
            ),
          );
        },
      );
    });
  }
}

class _FoxBody extends StatelessWidget {
  const _FoxBody({required this.ducking});
  final bool ducking;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: ducking ? 50 : 70,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            right: 0,
            bottom: 12,
            child: Transform.rotate(
              angle: -.55,
              child: Container(
                width: 38,
                height: 18,
                decoration: BoxDecoration(color: const Color(0xFFFF8A1F), borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ),
          Container(
            width: 48,
            height: ducking ? 34 : 46,
            decoration: BoxDecoration(color: const Color(0xFFFF8A1F), borderRadius: BorderRadius.circular(22)),
          ),
          Positioned(
            top: ducking ? 4 : 0,
            child: Container(
              width: 48,
              height: 42,
              decoration: BoxDecoration(color: const Color(0xFFFFA23A), borderRadius: BorderRadius.circular(24)),
              child: const Center(child: Text('🦊', style: TextStyle(fontSize: 26))),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: LumoShadow.card,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: LumoColors.ink800),
      ),
    );
  }
}

class _ControlPad extends StatelessWidget {
  const _ControlPad({
    required this.onLeft,
    required this.onRight,
    required this.onJump,
    required this.onDuck,
    required this.onRoll,
    required this.onChest,
    required this.chestEnabled,
    required this.finished,
    required this.onFinish,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onJump;
  final VoidCallback onDuck;
  final VoidCallback onRoll;
  final VoidCallback onChest;
  final bool chestEnabled;
  final bool finished;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          _GameButton(icon: Icons.arrow_back_rounded, label: 'Links', onTap: onLeft),
          _GameButton(icon: Icons.arrow_forward_rounded, label: 'Rechts', onTap: onRight),
          _GameButton(icon: Icons.keyboard_arrow_up_rounded, label: 'Springen', onTap: onJump),
          _GameButton(icon: Icons.keyboard_arrow_down_rounded, label: 'Ducken', onTap: onDuck),
          _GameButton(icon: Icons.sync_rounded, label: 'Rollen', onTap: onRoll),
          _GameButton(
            icon: finished ? Icons.done_all_rounded : Icons.inventory_2_rounded,
            label: finished ? 'Fertig' : 'Truhe',
            onTap: finished ? onFinish : onChest,
            highlighted: chestEnabled || finished,
          ),
        ],
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  const _GameButton({required this.icon, required this.label, required this.onTap, this.highlighted = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: highlighted ? LumoColors.orange : LumoColors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}
