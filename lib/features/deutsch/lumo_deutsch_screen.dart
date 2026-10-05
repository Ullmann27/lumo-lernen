import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../learning_modules/lumo_phrases.dart';
import '../learning_modules/wort_diktat/wort_diktat_screen.dart';
import '../shared/widgets/lumo_premium_effects.dart' show LumoFloating;
import '../writing/lumo_writing_coach_screen.dart';
import 'deutsch_gap_sentences.dart';

/// Deutsch nach Heinz' Bild 04: Lückensatz mit Vorlesen, vier Bereiche
/// (Lesen, Wörter, Diktat, Schreibcoach) und der echte Tagesfortschritt.
class LumoDeutschScreen extends StatefulWidget {
  const LumoDeutschScreen({super.key, required this.appState, this.random});

  final LumoAppState appState;

  @visibleForTesting
  final math.Random? random;

  @override
  State<LumoDeutschScreen> createState() => _LumoDeutschScreenState();
}

class _LumoDeutschScreenState extends State<LumoDeutschScreen>
    with SingleTickerProviderStateMixin {
  static const _roundLength = 5;
  static const _unit = 'Lückensätze';

  late final math.Random _random = widget.random ?? math.Random();
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late List<GapSentence> _round;
  int _index = 0;
  int _firstTry = 0;
  bool _hadWrong = false;
  String? _wrongPick;
  bool _solved = false;
  Timer? _next;

  GapSentence get _sentence => _round[_index];
  bool get _finished => _index >= _round.length;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _next?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _newRound() {
    final pool = DeutschGapSentences.forGrade(widget.appState.state.grade)
      ..shuffle(_random);
    _round = pool.take(_roundLength).toList();
    _index = 0;
    _firstTry = 0;
    _resetSentence();
  }

  void _resetSentence() {
    _hadWrong = false;
    _wrongPick = null;
    _solved = false;
  }

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  void _speak() {
    try {
      LumoVoice.instance.speak(_sentence.spoken);
    } catch (_) {}
  }

  void _pick(String word) {
    if (_solved || _finished) return;
    final correct = word == _sentence.answer;
    HapticFeedback.lightImpact();
    unawaited(widget.appState.recordLearningAnswer(
      subject: 'Deutsch',
      unit: _unit,
      correct: correct,
    ));
    if (!correct) {
      setState(() {
        _hadWrong = true;
        _wrongPick = word;
      });
      _shake.forward(from: 0);
      try {
        LumoVoice.instance.speak(LumoPhrases.wrongGentle());
      } catch (_) {}
      return;
    }
    widget.appState.addRewards(stars: 1, xp: 5);
    unawaited(widget.appState.flushRewards().catchError((_) {}));
    setState(() {
      _solved = true;
      _wrongPick = null;
      if (!_hadWrong) _firstTry++;
    });
    try {
      LumoVoice.instance.speak(_sentence.solved);
    } catch (_) {}
    _next = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _index++;
        if (!_finished) _resetSentence();
      });
    });
  }

  void _leaveTo(LumoSection section) {
    Navigator.of(context).pop();
    if (section != LumoSection.learn) widget.appState.setSection(section);
  }

  void _open(Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  void _openReading() {
    Navigator.of(context).pop();
    widget.appState.update(widget.appState.state.copyWith(
      section: LumoSection.reading,
      subject: 'Lesen',
      unit: 'Aktives Lesen',
      mood: LumoMood.think,
      lumoMessage: 'Lies laut vor.\nIch höre dir zu\nund helfe freundlich.',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.library,
        showPlaceholderLabel: false,
        dimmed: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: LumoTopBar(appState: widget.appState),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _buildHero(),
                  _buildGapCard(),
                  _buildAreas(),
                  _buildToday(),
                ],
              ),
            ),
            LumoBottomNavigation(active: LumoSection.learn, onSelect: _leaveTo),
          ]),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = (width * .42).clamp(140.0, 230.0);
      final foxSize = height * 1.18;
      Widget fox =
          LumoFoxPose(pose: LumoDesignFoxPose.pointSide, size: foxSize);
      if (!_reduceMotion) {
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
            left: (width - foxSize) / 2 - width * .04,
            bottom: -foxSize * .1,
            child: RepaintBoundary(child: fox),
          ),
          Positioned(
            left: 10,
            top: height * .06,
            width: width * .3,
            child: Transform.rotate(
              angle: -.06,
              child: const LumoHeroBubble(
                title: 'Lies den Satz',
                text: 'und setze das Wort ein!',
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: height * .12,
            width: width * .26,
            child: Transform.rotate(
              angle: -.1,
              child: const LumoHeroBubble(
                text: 'Große Wörter.\nGroße Träume!',
                handwritten: true,
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _buildGapCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(
              _shake.isAnimating ? math.sin(_shake.value * math.pi * 4) * 7 : 0,
              0),
          child: child,
        ),
        child: LumoGlassCard(
          padding: const EdgeInsets.all(10),
          radius: 24,
          child: _finished ? _buildRoundDone() : _buildSentence(),
        ),
      ),
    );
  }

  Widget _buildSentence() {
    final sentence = _sentence;
    final gapWord = _solved ? sentence.answer : null;
    const textStyle = TextStyle(
      fontFamily: 'Nunito',
      color: LumoVisualTokens.white,
      fontSize: 20,
      height: 1.35,
      fontWeight: FontWeight.w900,
    );
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 108,
          height: 96,
          child: Stack(children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: sentence.image != null
                    ? Image.asset(sentence.image!, fit: BoxFit.cover)
                    : DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2E7BE0), Color(0xFF0B2A5A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(sentence.emoji,
                              style: const TextStyle(fontSize: 50)),
                        ),
                      ),
              ),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: Material(
                color: const Color(0xFF1E6FD9),
                shape: const CircleBorder(),
                child: IconButton(
                  key: const ValueKey('deutsch-speak'),
                  tooltip: 'Satz vorlesen',
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  onPressed: _speak,
                  icon:
                      const Icon(Icons.volume_up_rounded, color: Colors.white),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.menu_book_rounded,
                    color: LumoVisualTokens.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satz ${_index + 1} von ${_round.length}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(children: [
                          for (var i = 0; i < _round.length; i++)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i <= _index
                                    ? LumoVisualTokens.cyanBright
                                    : Colors.transparent,
                                border: Border.all(
                                    color: LumoVisualTokens.cyanBright),
                              ),
                            ),
                        ]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: LumoVisualTokens.glassRow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: LumoVisualTokens.cyan.withOpacity(.5)),
                  ),
                  child: const Column(children: [
                    Icon(Icons.star_rounded,
                        color: LumoVisualTokens.gold, size: 20),
                    Text(
                      '+5 XP',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.cyanBright,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Text.rich(
                key: const ValueKey('deutsch-sentence'),
                TextSpan(children: [
                  TextSpan(text: '${sentence.before} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 70),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: gapWord == null
                            ? LumoVisualTokens.navigation.withOpacity(.6)
                            : const Color(0xFF167A58),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: gapWord == null
                              ? LumoVisualTokens.cyan
                              : const Color(0xFF4BE0A5),
                          width: 1.4,
                        ),
                      ),
                      child: Text(gapWord ?? ' ',
                          textAlign: TextAlign.center, style: textStyle),
                    ),
                  ),
                  TextSpan(text: sentence.after),
                ]),
                style: textStyle,
              ),
            ],
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final word in sentence.options) _wordButton(word),
        ],
      ),
      if (_wrongPick != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '„$_wrongPick“ passt hier nicht. Lies den Satz noch einmal.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Color(0xFFFFB3C4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ]);
  }

  Widget _wordButton(String word) {
    final right = _solved && word == _sentence.answer;
    final wrong = word == _wrongPick;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('deutsch-word-$word'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(word),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: right
                  ? const [Color(0xFF1FA27A), Color(0xFF0F6B50)]
                  : wrong
                      ? const [Color(0xFF9B2C55), Color(0xFF6B1D3B)]
                      : const [Color(0xFF1C5BB8), Color(0xFF0E3A82)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: right
                  ? const Color(0xFF4BE0A5)
                  : wrong
                      ? const Color(0xFFFF6B8A)
                      : LumoVisualTokens.cyan.withOpacity(.6),
              width: 1.4,
            ),
          ),
          child: Text(
            word,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundDone() {
    return Row(children: [
      const LumoFoxPose(pose: LumoDesignFoxPose.cheer, size: 84),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Runde geschafft!',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '$_firstTry von ${_round.length} Sätzen beim ersten Versuch richtig.',
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('deutsch-new-round'),
              style: FilledButton.styleFrom(
                backgroundColor: LumoVisualTokens.cyan,
                foregroundColor: LumoVisualTokens.night,
              ),
              onPressed: () => setState(_newRound),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Neue Runde'),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAreas() {
    final areas = [
      (
        'Lesen',
        'Texte entdecken und verstehen',
        Icons.auto_stories_rounded,
        const Color(0xFFE08A26),
        _openReading,
      ),
      (
        'Wörter',
        'Wortschatz erweitern',
        Icons.abc_rounded,
        const Color(0xFF6A38D6),
        // Zurück in die Akademie, die dann die Deutsch-Themen zeigt.
        () => Navigator.of(context).pop(),
      ),
      (
        'Diktat',
        'Hören und schreiben',
        Icons.mic_rounded,
        const Color(0xFF14917F),
        () => _open(WortDiktatScreen(appState: widget.appState)),
      ),
      (
        'Schreibcoach',
        'Besser schreiben',
        Icons.edit_note_rounded,
        const Color(0xFFC63A86),
        () => _open(LumoWritingCoachScreen(appState: widget.appState)),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LayoutBuilder(builder: (context, constraints) {
        final textScale =
            MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
        final columns = constraints.maxWidth >= 340 && textScale <= 1.2 ? 4 : 2;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final area in areas)
            SizedBox(
              width: width,
              height: 128 * textScale,
              child: _AreaTile(
                title: area.$1,
                subtitle: area.$2,
                icon: area.$3,
                color: area.$4,
                onTap: area.$5,
              ),
            ),
        ]);
      }),
    );
  }

  Widget _buildToday() {
    final done = widget.appState.learningDailyDone();
    final goal = widget.appState.state.settings.dailyGoal.clamp(1, 500);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: LumoGlassCard(
        padding: const EdgeInsets.all(10),
        radius: 22,
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.event_available_rounded,
                      color: LumoVisualTokens.cyanBright, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Heute',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  '$done von $goal Aufgaben geschafft',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (done / goal).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xFF0B2A52),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        LumoVisualTokens.cyanBright),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: LumoHeroBubble(
              text: 'Du kannst das! Jede gelesene Seite bringt dich weiter.',
              handwritten: true,
            ),
          ),
          const LumoFoxPose(pose: LumoDesignFoxPose.thumbWink, size: 70),
        ]),
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title. $subtitle',
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('deutsch-area-${title.toLowerCase()}'),
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(color, Colors.white, .12)!,
                    Color.lerp(color, Colors.black, .3)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(.35)),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(.4), blurRadius: 12),
                ],
              ),
              child: Column(children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => Icon(icon,
                        size: math.min(c.maxHeight, c.maxWidth) * .9,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Color(0x99FFFFFF), blurRadius: 12),
                        ]),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 9.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}
