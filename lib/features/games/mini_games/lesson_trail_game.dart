import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../app/app_state.dart';
import '../../../core/game_progress_repository.dart';
import '../../../domain/games/game_lesson_tasks.dart';
import '../../../domain/games/game_level_model.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../shared/lumo_game_pause_scope.dart';

/// Numbers, listening/reading and subject quizzes share pause/reward behavior,
/// while their task data and visual tools remain tied to each learning goal.
class LessonTrailGame extends StatefulWidget {
  const LessonTrailGame({super.key, required this.appState,
    required this.level, this.onResult});
  final LumoAppState appState;
  final GameLevel level;
  final ValueChanged<int>? onResult;
  @override
  State<LessonTrailGame> createState() => _LessonTrailGameState();
}

class _LessonTrailGameState extends State<LessonTrailGame> {
  final _clock = LumoGameTurnClock();
  final _tts = FlutterTts();
  final _words = <int>[];
  int _index = 0, _mistakes = 0;
  String? _selected;
  bool _correct = false, _finished = false, _saving = false;
  bool _awardIssued = false;
  String? _saveError;
  int get _total => widget.level.id == 13 ? 10 : 5;
  GameLessonTask get _task => GameLessonTasks.task(widget.level, _index);

  @override
  void initState() {
    super.initState();
    _clock.addListener(_pauseVoice);
  }

  void _pauseVoice() { if (_clock.value) unawaited(_stopVoice()); }
  Future<void> _stopVoice() async { try { await _tts.stop(); } catch (_) {} }

  Future<void> _speak() async {
    if (_clock.value || _finished) return;
    try {
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(.38);
      if (mounted && !_clock.value) await _tts.speak(_task.speech.isEmpty ? _task.cue : _task.speech);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Sprachausgabe ist gerade nicht verfügbar. Lies das Wort gemeinsam mit einem Erwachsenen.')));
    }
  }

  @override
  void dispose() {
    _clock.removeListener(_pauseVoice);
    _clock.dispose();
    unawaited(_stopVoice());
    super.dispose();
  }

  void _answer(String answer) {
    if (_clock.value || _correct || _finished) return;
    setState(() {
      _selected = answer;
      _correct = answer == _task.answer;
      if (!_correct) _mistakes++;
    });
  }

  void _restart() {
    if (_saving || _awardIssued) return;
    setState(() {
      _index = 0; _mistakes = 0; _selected = null; _correct = false;
      _finished = false; _saveError = null; _words.clear();
    });
  }

  Future<void> _next() async {
    if (_clock.value || !_correct || _finished) return;
    if (_index + 1 == _total) { await _finish(); return; }
    await _stopVoice();
    if (!mounted) return;
    setState(() { _index++; _selected = null; _correct = false; _words.clear(); });
  }

  Future<void> _finish() async {
    if (_finished || _saving) return;
    setState(() { _saving = true; _saveError = null; });
    final stars = math.min(widget.level.maxStars, _mistakes == 0 ? 3 : _mistakes <= 2 ? 2 : 1);
    final st = widget.appState.state;
    final name = st.childName.trim().isEmpty ? 'kind' : st.childName.trim()
        .toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    try {
      await const GameProgressRepository().recordResult(childId: 'local_${name}_${st.grade}',
        levelId: widget.level.id, starsEarned: stars);
      final stored = await const GameProgressRepository().loadStars('local_${name}_${st.grade}');
      if ((stored[widget.level.id] ?? 0) < stars) {
        throw StateError('Learning result was not persisted');
      }
      if (!_awardIssued) {
        _awardIssued = true;
        widget.appState.addStars(stars);
        widget.appState.addXp(_total * 8);
      }
      await widget.appState.flushRewards();
      _finished = true;
    } catch (_) {
      if (mounted) setState(() {
        _saving = false;
        _saveError = 'Das Ergebnis konnte noch nicht vollständig gespeichert werden. Bitte erneut versuchen.';
      });
      return;
    }
    if (!mounted) return;
    widget.onResult?.call(stars);
    await showDialog<void>(context: context, barrierDismissible: false,
      builder: (dialog) => LumoGameResultBack(child: AlertDialog(
        title: Text('Geschafft! $stars Sterne'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const LumoFoxPose(pose: LumoDesignFoxPose.trophyWink, size: 130),
          Text('Du hast $_total Aufgaben gelöst.\n${widget.level.learningGoal}'),
        ]),
        actions: [FilledButton(onPressed: () {
          Navigator.of(dialog).pop(); Navigator.of(context).pop();
        }, child: const Text('Zur Spielewelt'))],
      )));
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final forest = widget.level.miniType == GameMiniType.wordForest;
    final title = forest ? 'Lumos Wörterwald' : widget.level.miniType == GameMiniType.numberPath
        ? 'Lumos Zahlenweg' : 'Lumos Wissensreise';
    return LumoGamePauseScope(clock: _clock, onRestart: _restart,
      child: Scaffold(backgroundColor: LumoVisualTokens.night,
        body: LumoSceneBackground(scene: forest ? LumoScene.library : LumoScene.games,
          dimmed: true, child: SafeArea(child: Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              IconButton(onPressed: _clock.pause, tooltip: 'Pause', icon: const Icon(Icons.pause_rounded)),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              Text('${_index + 1} / $_total', style: const TextStyle(color: LumoVisualTokens.cyanBright)),
            ])),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 780),
                child: Column(children: [
                  Text(widget.level.title, style: const TextStyle(fontSize: 16, color: LumoVisualTokens.muted)),
                  const SizedBox(height: 8),
                  _JourneyPath(index: _index, total: _total, correct: _correct),
                  const SizedBox(height: 18),
                  LumoGlassCard(child: Column(children: [
                    Text(task.prompt, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    if (task.hour != null) Semantics(label: 'Analoge Uhr',
                      child: SizedBox(width: 180, height: 180,
                        child: CustomPaint(painter: _LearningClock(task.hour!, task.minute)))),
                    if (task.picture.isNotEmpty) Icon(_picture(task.picture), size: 94,
                      color: LumoVisualTokens.cyanBright),
                    if (task.cue.isNotEmpty) Padding(padding: const EdgeInsets.all(8),
                      child: Text(task.cue, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900))),
                    if (task.speech.isNotEmpty) OutlinedButton.icon(onPressed: _speak,
                      icon: const Icon(Icons.volume_up_rounded), label: const Text('Wort anhören')),
                    if (task.numbers.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                      children: [for (final n in task.numbers) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFF163B61),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: LumoVisualTokens.cyanBright)),
                        child: Text(n < 0 ? '?' : '$n', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)))]),
                    if (task.orderWords) ...[
                      const SizedBox(height: 14),
                      Semantics(liveRegion: true, child: Text(_words.map((i) => task.choices[i]).join(' '),
                        style: const TextStyle(fontSize: 24, color: LumoVisualTokens.cyanBright))),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                        children: [for (var i = 0; i < task.choices.length; i++) FilledButton.tonal(
                          onPressed: _correct || _clock.value || _words.contains(i) ? null : () => setState(() => _words.add(i)),
                          child: Text(task.choices[i], style: const TextStyle(fontSize: 21)))]),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        TextButton(onPressed: _correct ? null : () => setState(_words.clear), child: const Text('Neu ordnen')),
                        FilledButton(onPressed: _words.length == task.choices.length && !_correct
                            ? () => _answer(_words.map((i) => task.choices[i]).join(' ')) : null,
                          child: const Text('Satz prüfen')),
                      ]),
                    ] else ...[
                      const SizedBox(height: 20),
                      LayoutBuilder(builder: (context, constraints) {
                        final two = constraints.maxWidth > 420 && MediaQuery.textScalerOf(context).scale(18) < 30;
                        final width = two ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
                        return Wrap(spacing: 12, runSpacing: 12, children: [for (final option in task.choices)
                          SizedBox(width: width, child: FilledButton.tonal(
                            key: ValueKey('lesson-answer-$option'),
                            onPressed: _correct || _clock.value ? null : () => _answer(option),
                            style: FilledButton.styleFrom(minimumSize: const Size(48, 58),
                              backgroundColor: _selected == option ? (_correct ? const Color(0xFF12634F) : const Color(0xFF6B3349)) : const Color(0xFF143657)),
                            child: Text(option, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21))))]);
                      }),
                    ],
                    if (_selected != null) Padding(padding: const EdgeInsets.only(top: 16),
                      child: Semantics(liveRegion: true, child: Text(_correct ? task.explanation
                        : 'Versuche es noch einmal. ${task.explanation}', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, color: _correct ? const Color(0xFF9DF4D2) : const Color(0xFFFFD1A6))))),
                    if (_saveError != null) Text(_saveError!, style: const TextStyle(color: Color(0xFFFFD1A6))),
                    const SizedBox(height: 18),
                    FilledButton.icon(onPressed: _correct && !_saving && !_finished ? _next : null,
                      icon: Icon(_index + 1 == _total ? Icons.star_rounded : Icons.arrow_forward_rounded),
                      label: Text(_saving ? 'Wird gespeichert …' : _index + 1 == _total ? 'Ergebnis speichern' : 'Weiter auf dem Weg')),
                  ])),
                ]))))),
          ]))),
      ));
  }

  IconData _picture(String key) => switch (key) {
    'house' => Icons.home_rounded, 'fish' => Icons.set_meal_rounded,
    'ball' => Icons.sports_soccer_rounded, 'star' => Icons.star_rounded,
    'tree' => Icons.park_rounded, 'hat' => Icons.checkroom_rounded, 'egg' => Icons.egg_rounded,
    'money' => Icons.payments_rounded, 'animal' => Icons.pets_rounded,
    'rain' => Icons.water_drop_rounded, 'sun' => Icons.wb_sunny_rounded,
    'snow' => Icons.ac_unit_rounded, 'storm' => Icons.thunderstorm_rounded,
    'cloud' => Icons.cloud_rounded, 'plant' => Icons.local_florist_rounded,
    _ => Icons.auto_awesome_rounded,
  };
}

class _JourneyPath extends StatelessWidget {
  const _JourneyPath({required this.index, required this.total, required this.correct});
  final int index, total;
  final bool correct;
  @override
  Widget build(BuildContext context) => SizedBox(height: 125, child: Stack(children: [
    Positioned(left: 12, right: 12, bottom: 20, child: Container(height: 5,
      decoration: BoxDecoration(color: const Color(0xFF315B84), borderRadius: BorderRadius.circular(4)))),
    Positioned(left: 0, right: 0, bottom: 0, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (var i = 0; i < total; i++) CircleAvatar(radius: total > 5 ? 14 : 20,
        backgroundColor: i < index || i == index && correct ? const Color(0xFF267E74) : const Color(0xFF1E416B),
        child: Icon(i < index || i == index && correct ? Icons.star_rounded : Icons.circle_outlined,
          size: total > 5 ? 16 : 23, color: LumoVisualTokens.cyanBright))])),
    AnimatedAlign(duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 500),
      alignment: Alignment(-1 + 2 * index / (total - 1), -.6),
      child: const LumoFoxPose(pose: LumoDesignFoxPose.spielweltJump, size: 85)),
  ]));
}

class _LearningClock extends CustomPainter {
  _LearningClock(this.hour, this.minute);
  final int hour, minute;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.shortestSide / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF153554));
    canvas.drawCircle(c, r, Paint()..color = LumoVisualTokens.cyanBright..style = PaintingStyle.stroke..strokeWidth = 3);
    for (var n = 1; n <= 12; n++) {
      final angle = n * math.pi / 6 - math.pi / 2;
      final label = TextPainter(text: TextSpan(text: '$n', style: const TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 17)),
        textDirection: TextDirection.ltr)..layout();
      final at = c + Offset(math.cos(angle), math.sin(angle)) * r * .77;
      label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
    }
    void hand(double angle, double length, Color color, double width) => canvas.drawLine(c,
      c + Offset(math.cos(angle), math.sin(angle)) * r * length,
      Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);
    hand((hour % 12 + minute / 60) * math.pi / 6 - math.pi / 2, .48, Colors.white, 6);
    hand(minute * math.pi / 30 - math.pi / 2, .66, LumoVisualTokens.cyanBright, 4);
    canvas.drawCircle(c, 5, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant _LearningClock old) => hour != old.hour || minute != old.minute;
}
